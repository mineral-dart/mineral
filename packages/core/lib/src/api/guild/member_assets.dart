import 'package:mineral/src/api/common/image_asset.dart';

final class MemberAssets {
  final ImageAsset? avatar;
  final ImageAsset? avatarDecoration;
  final ImageAsset? banner;

  MemberAssets({
    required this.avatar,
    required this.avatarDecoration,
    required this.banner,
  });
}
