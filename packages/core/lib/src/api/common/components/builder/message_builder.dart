import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/components/container.dart';
import 'package:mineral/src/api/common/components/text_display.dart';

/// A builder for constructing Discord messages using message components v2.
///
/// The [MessageBuilder] provides a fluent API for composing messages with [TextDisplay],
/// interactive elements [Button], [SelectMenu], media [AttachedFile], [MediaGallery],
/// and layout components [Section], [Container], [Separator] using Discord's
/// message components v2 specification.
///
/// ## Usage
///
/// Create a builder and add components using the cascade operator or method chaining:
///
/// ```dart
/// final builder = MessageBuilder()
///   ..addText('# Welcome to our guild!')
///   ..addSeparator()
///   ..addText('Please read the rules before posting.')
///   ..addButtons([
///     MessageButton.primary('accept_rules', label: 'Accept Rules'),
///     MessageButton.secondary('learn_more', label: 'Learn More'),
///   ]);
///
/// builder.addText("-# PS: Dont forget to have fun!");
///
/// // Send the message
/// await channel.send(builder);
/// ```
///
/// ## Features
///
/// - **Text & Formatting**: Add markdown-formatted text and separators
/// - **Interactive Components**: Buttons and select menus for user interaction
/// - **Media**: Attach files and create image galleries
/// - **Layout**: Organize content with sections and containers
/// - **Composition**: Combine multiple builders or copy existing ones
///
/// ## Examples
///
/// ### Simple text message
///
/// ```dart
/// final message = MessageBuilder.text('Hello, world!');
/// ```
///
/// ### Message with buttons
///
/// ```dart
/// final builder = MessageBuilder()
///   ..addText('Choose an option:')
///   ..addButtons([
///     MessageButton.primary('option_1', label: 'Option 1'),
///     MessageButton.secondary('option_2', label: 'Option 2'),
///     MessageButton.danger('cancel', label: 'Cancel'),
///   ]);
/// ```
///
/// ### Message with file attachments
///
/// ```dart
/// // Using MediaItem
/// final mediaFromFile = MediaItem.fromFile(File('assets/logo.png'), 'logo.png');
/// final mediaFromNetwork = MediaItem.fromNetwork('https://example.com/image.jpg');
///
/// final builder = MessageBuilder()
///   ..addText('Check out these images:')
///   ..addFile(await AttachedFile.fromMediaItem(mediaFromFile))
///   ..addFile(await AttachedFile.fromMediaItem(mediaFromNetwork));
///
/// // Or use the convenience factory
/// final builder2 = MessageBuilder()
///   ..addText('Another way:')
///   ..addFile(AttachedFile.fromFile(File('assets/logo.png'), 'logo.png'))
///   ..addFile(await AttachedFile.fromNetwork('https://example.com/image.jpg', 'image.jpg));
/// ```
///
/// ### Using containers for visual grouping
///
/// ```dart
/// final container = MessageBuilder()
///   ..addText('This is inside a container')
///   ..addText('With multiple lines')
///   ..addText('And even interactive components')
///   ..addButton(MessageButton.primary('click_me', label: 'Click Me!'));
///
/// final builder = MessageBuilder()
///   ..addText('Main message')
///   ..addContainer(
///     builder: container,
///     color: Color.blue,
///     spoiler: false,
///   );
/// ```
final class MessageBuilder {
  final List<MessageComponent> _components = [];

  /// Creates an empty [MessageBuilder].
  MessageBuilder();

  /// Creates a [MessageBuilder] with initial text content.
  ///
  /// This factory constructor is a convenience for creating a builder with
  /// a single text component.
  ///
  /// Example:
  /// ```dart
  /// final builder = MessageBuilder.text('Hello, world!');
  ///
  /// // Equivalent to:
  /// final builder = MessageBuilder()..addText('Hello, world!');
  /// ```
  factory MessageBuilder.text(String text) {
    return MessageBuilder()..addText(text);
  }

  /// Adds a single button to the message.
  ///
  /// Each button is automatically wrapped in an [ActionRow].
  ///
  /// Example:
  /// ```dart
  /// builder.addButton(
  ///   MessageButton.primary('confirm', label: 'Confirm'),
  /// );
  /// ```
  ///
  /// See also:
  /// - [addButtons] to add multiple buttons in a single row
  /// - [Button] for button types and options
  void addButton(Button button) {
    final row = ActionRow(components: [button]);
    _components.add(row);
  }

  /// Adds multiple buttons in a single row.
  ///
  /// Discord supports up to 5 buttons per action row. If you need more buttons,
  /// call this method multiple times to create separate rows.
  ///
  /// Example:
  /// ```dart
  /// builder.addButtons([
  ///   MessageButton.primary('yes', label: 'Yes'),
  ///   MessageButton.secondary('no', label: 'No'),
  ///   MessageButton.danger('cancel', label: 'Cancel'),
  /// ]);
  /// ```
  ///
  /// Throws an [ArgumentError] if more than 5 buttons are provided.
  ///
  /// See also:
  /// - [addButton] to add a single button
  void addButtons(List<Button> buttons) {
    if (buttons.length > 5) {
      throw ArgumentError.value(
        buttons.length,
        'buttons',
        'A row can contain at most 5 buttons (received ${buttons.length}).',
      );
    }

    final row = ActionRow(components: buttons);
    _components.add(row);
  }

  /// Adds a container with nested content.
  ///
  /// Containers provide visual grouping with optional color theming and
  /// spoiler protection. The nested [builder] must not contain components that
  /// are top-level-only like [AttachedFile] or [Section].
  ///
  /// Example:
  /// ```dart
  /// final nested = MessageBuilder()
  ///   ..addText('This content is in a container')
  ///   ..addText('With a blue background');
  ///
  /// builder.addContainer(
  ///   builder: nested,
  ///   color: Color.blue,
  ///   spoiler: false,
  /// );
  /// ```
  void addContainer({
    required MessageBuilder builder,
    Color? color,
    bool? spoiler,
  }) {
    _components.add(Container(color, spoiler, builder));
  }

  /// Attaches a file to the message.
  ///
  /// Files can be attached from local files or network URLs using various
  /// [AttachedFile] factory constructors. Each file attachment can include
  /// optional metadata such as spoiler flags, dimensions, and descriptions.
  ///
  /// Example:
  /// ```dart
  /// // From local file
  /// builder.addFile(
  ///   AttachedFile.fromFile(
  ///     File('assets/document.pdf'),
  ///     'document.pdf',
  ///     description: 'Monthly report',
  ///   ),
  /// );
  ///
  /// // From network URL
  /// builder.addFile(
  ///   await AttachedFile.fromNetwork(
  ///     'https://example.com/image.png',
  ///     'image.png',
  ///     spoiler: true,
  ///   ),
  /// );
  ///
  /// // From MediaItem
  /// final mediaItem = MediaItem.fromFile(File('assets/logo.png'), 'logo.png');
  /// builder.addFile(await AttachedFile.fromMediaItem(mediaItem));
  /// ```
  ///
  /// See also:
  /// - [addGallery] for displaying multiple images in a grid
  /// - [AttachedFile.fromFile] for attaching local files
  /// - [AttachedFile.fromNetwork] for downloading and attaching remote files
  /// - [AttachedFile.fromMediaItem] for converting [MediaItem] instances
  void addFile(AttachedFile file) {
    _components.add(file);
  }

  /// Adds a media gallery to the message.
  ///
  /// Galleries display multiple images in a grid layout, providing a more
  /// compact and visually appealing way to show multiple media items. This
  /// method directly accepts a list of [MediaItem] instances.
  ///
  /// Discord supports up to 10 items per gallery. The gallery must contain
  /// at least one item.
  ///
  /// Example:
  /// ```dart
  /// // Create gallery from local files
  /// builder.addGallery([
  ///   MediaItem.fromFile(File('assets/image1.png'), 'image1.png'),
  ///   MediaItem.fromFile(File('assets/image2.png'), 'image2.png'),
  ///   MediaItem.fromFile(File('assets/image3.png'), 'image3.png'),
  /// ]);
  ///
  /// // Mix local and network sources with metadata
  /// builder.addGallery([
  ///   MediaItem.fromFile(
  ///     File('assets/local.png'),
  ///     'local.png',
  ///     description: 'Local image',
  ///   ),
  ///   MediaItem.fromNetwork(
  ///     'https://example.com/remote.jpg',
  ///     description: 'Remote image',
  ///     spoiler: true,
  ///   ),
  /// ]);
  /// ```
  ///
  /// Throws:
  /// - [ArgumentError] if the list is empty
  /// - [ArgumentError] if the list contains more than 10 items
  ///
  /// See also:
  /// - [addFile] for single file attachments
  /// - [MediaItem.fromFile] for creating media items from local files
  /// - [MediaItem.fromNetwork] for creating media items from URLs
  void addGallery(List<MediaItem> items) {
    _components.add(MediaGallery(items: items));
  }

  /// Adds a section to the message.
  ///
  /// A section is a top-level layout component that allows you to contextually
  /// associate text content with an optional accessory component (either a button
  /// or a thumbnail). Sections are useful for organizing related content with
  /// interactive or visual elements.
  ///
  /// The section's [builder] should contain only text components. The optional accessory
  /// can be either a [button] or a [thumbnail], but not both.
  ///
  /// Example:
  /// ```dart
  /// // Section with text only
  /// builder.addSection(
  ///   builder: MessageBuilder()
  ///     ..addText('## Important Notice')
  ///     ..addText('Please read this carefully.'),
  /// );
  ///
  /// // Section with text and button accessory
  /// builder.addSection(
  ///   builder: MessageBuilder()
  ///     ..addText('**New Feature Available**')
  ///     ..addText('Click to learn more about our latest update.'),
  ///   button: MessageButton.link('https://example.com', label: 'Learn More'),
  /// );
  ///
  /// // Section with text and thumbnail accessory
  /// builder.addSection(
  ///   builder: MessageBuilder()
  ///     ..addText('## User Profile')
  ///     ..addText('John Doe - Senior Developer'),
  ///   thumbnail: Thumbnail(
  ///     MediaItem.fromNetwork('https://example.com/avatar.png'),
  ///   ),
  /// );
  /// ```
  ///
  /// Throws:
  /// - [FormatException] if the section contains non-text components
  /// - [FormatException] if both button and thumbnail are provided
  ///
  /// See also:
  /// - [addContainer] for general-purpose containers that support any component type
  /// - [Section] for section configuration details
  /// - [Button] for button types and options
  /// - [Thumbnail] for thumbnail accessory options
  void addSection({
    required MessageBuilder builder,
    Button? button,
    Thumbnail? thumbnail,
  }) {
    for (final component in builder._components) {
      if (component is! TextDisplay) {
        throw FormatException('Section components must be text only');
      }
    }

    _components.add(
      Section(builder: builder, button: button, thumbnail: thumbnail),
    );
  }

  /// Adds a select menu (dropdown) to the message.
  ///
  /// Select menus allow users to choose from a list of options. Discord supports
  /// various types of select menus including text, user, role, channel, and mentionable.
  ///
  /// Example:
  /// ```dart
  /// // Channel select menu
  /// builder.addSelectMenu(
  ///   SelectMenu.channel(
  ///     'channel_select',
  ///     channelTypes: [ChannelType.guildText, ChannelType.guildVoice],
  ///     placeholder: 'Choose a channel',
  ///   ),
  /// );
  ///
  /// // String select menu
  /// builder.addSelectMenu(
  ///   SelectMenu.string(
  ///     'color_select',
  ///     options: [
  ///       SelectMenuOption('Red', 'red'),
  ///       SelectMenuOption('Blue', 'blue'),
  ///       SelectMenuOption('Green', 'green'),
  ///     ],
  ///   ),
  /// );
  /// ```
  ///
  /// See also:
  /// - [SelectMenu] for select menu types and configuration
  void addSelectMenu(SelectMenu menu) {
    final row = ActionRow(components: [menu]);
    _components.add(row);
  }

  /// Adds a visual separator between content sections.
  ///
  /// Separators help organize message content by creating visual breaks.
  /// They can be shown or hidden and support different spacing sizes.
  ///
  /// Example:
  /// ```dart
  /// builder
  ///   ..addText('First section')
  ///   ..addSeparator(spacing: SeparatorSize.medium)
  ///   ..addText('Second section')
  ///   ..addSeparator(show: false, spacing: SeparatorSize.large)
  ///   ..addText('Third section');
  /// ```
  ///
  /// Parameters:
  /// - [show]: Whether to display the separator line (default: true)
  /// - [spacing]: The amount of vertical space (default: [SeparatorSize.small])
  void addSeparator({
    bool show = true,
    SeparatorSize spacing = SeparatorSize.small,
  }) {
    _components.add(Separator(show, spacing));
  }

  /// Adds text content to the message.
  ///
  /// Supports Discord markdown formatting including bold, italic, code blocks,
  /// headers, lists, and more.
  ///
  /// Example:
  /// ```dart
  /// builder
  ///   ..addText('# This is a header')
  ///   ..addText('**Bold text** and *italic text*')
  ///   ..addText('`inline code` and ```code block```')
  ///   ..addText(
  ///     '- List item 1\n'
  ///     '- List item 2\n'
  ///     '- List item 3',
  ///   );
  /// ```
  ///
  /// See also:
  /// - [MessageBuilder.text] factory constructor for convenience
  void addText(String text) {
    _components.add(TextDisplay(text));
  }

  /// Appends all components from another builder to the end of this one.
  ///
  /// This is useful for composing messages from reusable parts or
  /// combining multiple builder instances.
  ///
  /// Example:
  /// ```dart
  /// final header = MessageBuilder()
  ///   ..addText('# Welcome!')
  ///   ..addSeparator();
  ///
  /// final footer = MessageBuilder()
  ///   ..addSeparator()
  ///   ..addText('Thank you for reading!');
  ///
  /// final message = MessageBuilder()
  ///   ..appendFrom(header)
  ///   ..addText('Main content here')
  ///   ..appendFrom(footer);
  /// ```
  ///
  /// See also:
  /// - [prependFrom] to add components at the beginning
  /// - [copyWith] to create a new builder with combined components
  void appendFrom(MessageBuilder builder) {
    _components.addAll(builder._components);
  }

  /// Converts the builder to a JSON representation for the Discord API.
  ///
  /// This method is typically called internally when sending messages and
  /// should not need to be called directly in most cases.
  ///
  /// Returns a list of JSON objects representing all components in the builder.
  List<Map<String, dynamic>> build() {
    return _components.map((e) => e.toJson()).toList();
  }

  /// Creates a copy of this builder with all its components.
  ///
  /// The returned builder is a new instance with the same components,
  /// but modifications to either builder won't affect the other.
  ///
  /// Example:
  /// ```dart
  /// final original = MessageBuilder()
  ///   ..addText('Original content');
  ///
  /// final duplicate = original.copy()
  ///   ..addText('Additional content');
  ///
  /// // original still only has one text component
  /// // duplicate has two text components
  /// ```
  ///
  /// See also:
  /// - [copyWith] to create a copy combined with another builder
  MessageBuilder copy() {
    return MessageBuilder().._components.addAll(_components);
  }

  /// Creates a new builder combining this builder's components with another's.
  ///
  /// The returned builder contains all components from this builder followed
  /// by all components from the provided [builder]. Neither original builder
  /// is modified.
  ///
  /// Example:
  /// ```dart
  /// final header = MessageBuilder.text('# Title');
  /// final body = MessageBuilder.text('Content');
  ///
  /// final combined = header.copyWith(body);
  /// // combined has both title and content
  /// // header and body remain unchanged
  /// ```
  ///
  /// See also:
  /// - [copy] to create a simple copy without merging
  /// - [appendFrom] to modify this builder instead of creating a new one
  MessageBuilder copyWith(MessageBuilder builder) {
    return MessageBuilder()
      .._components.addAll(_components)
      .._components.addAll(builder._components);
  }

  /// Prepends all components from another builder to the beginning of this one.
  ///
  /// This is useful when you want to add a header or prefix to an existing
  /// message builder.
  ///
  /// Example:
  /// ```dart
  /// final header = MessageBuilder()
  ///   ..addText('# Announcement')
  ///   ..addSeparator();
  ///
  /// final message = MessageBuilder()
  ///   ..addText('Important content here');
  ///
  /// message.prependFrom(header);
  /// // message now has header content first, then the original content
  /// ```
  ///
  /// See also:
  /// - [appendFrom] to add components at the end
  /// - [copyWith] to create a new builder instead of modifying this one
  void prependFrom(MessageBuilder builder) {
    _components.insertAll(0, builder._components);
  }
}
