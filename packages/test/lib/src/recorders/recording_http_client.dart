import 'package:mineral/services.dart';
// ignore: implementation_imports
import 'package:mineral/src/infrastructure/services/http/header.dart' as infra;

import 'bot_actions.dart';
import 'recorded_action.dart';

/// In-memory [HttpClientContract] that records every outgoing request and
/// translates the well-known Discord REST routes into [RecordedAction]s.
///
/// Anything that does not match a known route becomes a 200/empty response so
/// that handlers proceed without crashing — failing fast on novel routes
/// would leak Discord's REST surface into user tests.
final class RecordingHttpClient implements HttpClientContract {
  final BotActions _actions;
  int _autoId = 1000;

  RecordingHttpClient(this._actions);

  @override
  HttpClientStatus get status => HttpClientStatusImpl();

  @override
  HttpInterceptor get interceptor => HttpInterceptorImpl();

  @override
  HttpClientConfig get config =>
      throw UnimplementedError('RecordingHttpClient.config is not exposed');

  @override
  Future<Response<T>> get<T>(RequestContract r) => _handle<T>('GET', r);

  @override
  Future<Response<T>> post<T>(RequestContract r) => _handle<T>('POST', r);

  @override
  Future<Response<T>> put<T>(RequestContract r) => _handle<T>('PUT', r);

  @override
  Future<Response<T>> patch<T>(RequestContract r) => _handle<T>('PATCH', r);

  @override
  Future<Response<T>> delete<T>(RequestContract r) => _handle<T>('DELETE', r);

  @override
  Future<Response<T>> send<T>(RequestContract r) =>
      _handle<T>(r.method ?? 'SEND', r);

  Future<Response<T>> _handle<T>(String method, RequestContract r) async {
    final segments = r.url.pathSegments;
    final body = r.body;
    final reason = _readAuditReason(r);
    final responseBody = _interpret(method, segments, body, reason);
    return _StubResponse<T>(method, r.url, responseBody);
  }

  Map<String, dynamic> _interpret(
    String method,
    List<String> segments,
    Object? body,
    String? reason,
  ) {
    final map = body is Map<String, dynamic> ? body : const <String, dynamic>{};

    // /interactions/{id}/{token}/callback
    if (segments.length == 4 &&
        segments[0] == 'interactions' &&
        segments[3] == 'callback' &&
        method == 'POST') {
      return _recordInteractionCallback(segments[1], segments[2], map);
    }

    // /channels/{channelId}/messages — POST send, edit/delete on /{id}
    if (segments.length >= 3 &&
        segments[0] == 'channels' &&
        segments[2] == 'messages') {
      if (segments.length == 3 && method == 'POST') {
        return _recordChannelSend(segments[1], map);
      }
      if (segments.length == 4) {
        if (method == 'PATCH') {
          _actions.record(
            MessageEdited(
              channelId: segments[1],
              messageId: segments[3],
              content: _extractContent(map['components']),
            ),
          );
        } else if (method == 'DELETE') {
          _actions.record(
            MessageDeleted(channelId: segments[1], messageId: segments[3]),
          );
        }
      }
      return const {};
    }

    // /guilds/{guildId}/bans/{memberId}
    if (segments.length == 4 &&
        segments[0] == 'guilds' &&
        segments[2] == 'bans' &&
        method == 'PUT') {
      final secs = map['delete_message_seconds'];
      _actions.record(
        MemberBanned(
          guildId: segments[1],
          memberId: segments[3],
          reason: reason,
          deleteSince: secs is int ? Duration(seconds: secs) : null,
        ),
      );
      return const {};
    }

    // /guilds/{guildId}/members/{memberId}/roles/{roleId}
    if (segments.length == 6 &&
        segments[0] == 'guilds' &&
        segments[2] == 'members' &&
        segments[4] == 'roles') {
      if (method == 'PUT') {
        _actions.record(
          RoleAssigned(
            guildId: segments[1],
            memberId: segments[3],
            roleId: segments[5],
            reason: reason,
          ),
        );
      } else if (method == 'DELETE') {
        _actions.record(
          RoleRemoved(
            guildId: segments[1],
            memberId: segments[3],
            roleId: segments[5],
            reason: reason,
          ),
        );
      }
      return const {};
    }

    return const {};
  }

  Map<String, dynamic> _recordInteractionCallback(
    String id,
    String token,
    Map<String, dynamic> body,
  ) {
    final type = body['type'];
    final data = body['data'];
    final dataMap = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};

    if (type == 9) {
      _actions.record(
        ModalShown(
          interactionId: id,
          token: token,
          customId: dataMap['custom_id'] as String? ?? '',
          title: dataMap['title'] as String?,
        ),
      );
      return const {};
    }

    final flags = dataMap['flags'];
    final ephemeral = flags is int && (flags & (1 << 6)) != 0;
    final components = _readComponents(dataMap['components']);

    _actions.record(
      InteractionReply(
        interactionId: id,
        token: token,
        content: _extractContent(dataMap['components']),
        ephemeral: ephemeral,
        components: components,
      ),
    );
    return const {};
  }

  Map<String, dynamic> _recordChannelSend(
    String channelId,
    Map<String, dynamic> body,
  ) {
    final components = _readComponents(body['components']);
    _actions.record(
      SentMessage(
        channelId: channelId,
        content: _extractContent(body['components']),
        components: components,
      ),
    );
    final id = (_autoId++).toString();
    return {
      'id': id,
      'channel_id': channelId,
      'content': _extractContent(body['components']) ?? '',
      'author': {
        'id': '0',
        'username': 'mineral_test',
        'discriminator': '0',
        'bot': true,
      },
      'embeds': const [],
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  String? _extractContent(Object? components) {
    if (components is! List) {
      return null;
    }
    final buf = StringBuffer();
    _walkText(components, buf);
    return buf.isEmpty ? null : buf.toString();
  }

  void _walkText(List<dynamic> components, StringBuffer buf) {
    for (final raw in components) {
      if (raw is! Map) {
        continue;
      }
      final type = raw['type'];
      if (type == 10 && raw['content'] is String) {
        if (buf.isNotEmpty) {
          buf.write('\n');
        }
        buf.write(raw['content'] as String);
      }
      final nested = raw['components'];
      if (nested is List) {
        _walkText(nested, buf);
      }
      final items = raw['items'];
      if (items is List) {
        _walkText(items, buf);
      }
    }
  }

  List<Map<String, dynamic>> _readComponents(Object? components) {
    if (components is List) {
      return components
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList();
    }
    return const [];
  }

  String? _readAuditReason(RequestContract r) {
    for (final h in r.headers) {
      if (h.key == 'X-Audit-Log-Reason' && h.value.isNotEmpty) {
        return Uri.decodeComponent(h.value);
      }
    }
    return null;
  }
}

final class _StubResponse<T> implements Response<T> {
  @override
  final int statusCode = 200;

  @override
  final Set<infra.Header> headers = const {};

  @override
  final String bodyString = '{}';

  @override
  final Uri uri;

  @override
  final String? reasonPhrase = null;

  @override
  final String method;

  @override
  final T body;

  _StubResponse(this.method, this.uri, Map<String, dynamic> bodyMap)
    : body = bodyMap as T;
}
