import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/components/label.dart';
import 'package:mineral/src/api/common/components/text_display.dart';

/// A builder for constructing Discord modal dialogs (popup forms).
///
/// The [ModalBuilder] provides a fluent API for creating interactive modal dialogs
/// that collect user input through [TextInput] fields, [SelectMenu] components,
/// and informational [TextDisplay] elements using Discord's modal specification.
///
/// Modals are popup forms that appear when triggered by interactions (like button clicks)
/// and require user input before submission. Each modal must have a unique [customId]
/// for tracking submissions.
///
/// ## Usage
///
/// Create a modal and add input components using method chaining:
///
/// ```dart
/// final modal = ModalBuilder('user_feedback')
///   ..setTitle('Share Your Feedback')
///   ..addTextInput(
///     customId: 'feedback_text',
///     label: 'Your Feedback',
///     style: TextInputStyle.paragraph,
///     placeholder: 'Tell us what you think...',
///     minLength: 10,
///     maxLength: 500,
///     isRequired: true,
///   )
///   ..addTextInput(
///     customId: 'email',
///     label: 'Email (Optional)',
///     style: TextInputStyle.short,
///     placeholder: 'your.email@example.com',
///     isRequired: false,
///   );
///
/// // Show the modal in response to an interaction
/// await interaction.showModal(modal);
/// ```
///
/// ## Features
///
/// - **Text Inputs**: Short single-line or paragraph multi-line text fields
/// - **Select Menus**: Dropdown selection components for choosing from options
/// - **Text Display**: Non-editable informational text
/// - **Validation**: Built-in min/max length validation for text inputs
/// - **Flexible Layout**: Automatic component organization with labels and descriptions
///
/// ## Examples
///
/// ### Simple feedback form
///
/// ```dart
/// final modal = ModalBuilder('feedback_form')
///   .setTitle('Quick Feedback')
///   .addTextInput(
///     customId: 'message',
///     label: 'Your Message',
///     style: TextInputStyle.paragraph,
///     placeholder: 'What would you like to tell us?',
///     maxLength: 1000,
///   );
/// ```
///
/// ### User registration form
///
/// ```dart
/// final modal = ModalBuilder('user_registration')
///   .setTitle('Create Your Profile')
///   .addText('Please fill in all required fields below:')
///   .addTextInput(
///     customId: 'username',
///     label: 'Username',
///     style: TextInputStyle.short,
///     placeholder: 'Choose a unique username',
///     minLength: 3,
///     maxLength: 20,
///     isRequired: true,
///     description: 'Must be 3-20 characters',
///   )
///   .addTextInput(
///     customId: 'display_name',
///     label: 'Display Name',
///     style: TextInputStyle.short,
///     placeholder: 'How should we display your name?',
///     maxLength: 32,
///     isRequired: true,
///   )
///   .addTextInput(
///     customId: 'bio',
///     label: 'Bio',
///     style: TextInputStyle.paragraph,
///     placeholder: 'Tell us about yourself...',
///     maxLength: 500,
///     isRequired: false,
///     description: 'Optional - max 500 characters',
///   );
/// ```
///
/// ### Support ticket form with select menu
///
/// ```dart
/// final categoryMenu = SelectMenu(
///   customId: 'ticket_category',
///   placeholder: 'Choose a category',
///   options: [
///     SelectMenuOption(label: 'Technical Issue', value: 'tech'),
///     SelectMenuOption(label: 'Billing Question', value: 'billing'),
///     SelectMenuOption(label: 'Feature Request', value: 'feature'),
///     SelectMenuOption(label: 'Other', value: 'other'),
///   ],
/// );
///
/// final modal = ModalBuilder('support_ticket')
///   .setTitle('Open Support Ticket')
///   .addText('We\'re here to help! Please provide details about your issue.')
///   .addSelectMenu(
///     customId: 'category',
///     label: 'Issue Category',
///     menu: categoryMenu,
///     description: 'Select the category that best matches your issue',
///   )
///   .addTextInput(
///     customId: 'subject',
///     label: 'Subject',
///     style: TextInputStyle.short,
///     placeholder: 'Brief summary of your issue',
///     maxLength: 100,
///     isRequired: true,
///   )
///   .addTextInput(
///     customId: 'description',
///     label: 'Detailed Description',
///     style: TextInputStyle.paragraph,
///     placeholder: 'Please provide as much detail as possible...',
///     minLength: 20,
///     maxLength: 2000,
///     isRequired: true,
///   );
/// ```
///
/// ### Pre-filled form (editing existing data)
///
/// ```dart
/// final modal = ModalBuilder('edit_profile')
///   .setTitle('Edit Profile')
///   .addTextInput(
///     customId: 'bio',
///     label: 'Biography',
///     style: TextInputStyle.paragraph,
///     value: existingUser.bio, // Pre-fill with existing value
///     maxLength: 500,
///   )
///   .addTextInput(
///     customId: 'location',
///     label: 'Location',
///     style: TextInputStyle.short,
///     value: existingUser.location, // Pre-fill with existing value
///     maxLength: 50,
///   );
/// ```
///
/// ## Best Practices
///
/// - **Keep it focused**: Modals should be quick to fill out (5 fields or fewer)
/// - **Clear labels**: Use descriptive labels that explain what input is expected
/// - **Helpful placeholders**: Provide example text in placeholders
/// - **Appropriate validation**: Set reasonable min/max lengths for text inputs
/// - **Descriptions**: Use descriptions for complex or optional fields
/// - **Pre-fill when editing**: Use the `value` parameter to pre-populate fields
/// - **Handle all cases**: Always handle both successful submissions and dismissals
///
/// See also:
/// - [TextInput] for text input field configuration
/// - [SelectMenu] for dropdown selection components
/// - [TextInputStyle] for input style options (short vs paragraph)
final class ModalBuilder {
  final List<ModalComponent> _components = [];

  final String _customId;
  String? _title;

  /// Creates a new [ModalBuilder] with the specified [customId].
  ///
  /// The [customId] is used to identify this modal when handling submissions.
  /// It must be unique within your application's modal interactions.
  ///
  /// Example:
  /// ```dart
  /// final modal = ModalBuilder('feedback_form');
  /// ```
  ModalBuilder(this._customId);

  /// Adds a select menu (dropdown) to the modal.
  ///
  /// Creates a labeled dropdown selection component that allows users to choose
  /// from predefined options. The [menu] must be a fully configured [SelectMenu]
  /// instance with options.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final roleMenu = SelectMenu(
  ///   customId: 'user_role',
  ///   placeholder: 'Choose your role',
  ///   options: [
  ///     SelectMenuOption(label: 'Developer', value: 'dev', emoji: '💻'),
  ///     SelectMenuOption(label: 'Designer', value: 'design', emoji: '🎨'),
  ///     SelectMenuOption(label: 'Manager', value: 'mgr', emoji: '📊'),
  ///   ],
  ///   minValues: 1,
  ///   maxValues: 1,
  /// );
  ///
  /// modal.addSelectMenu(
  ///   label: 'Select Your Role',
  ///   menu: roleMenu,
  ///   description: 'This helps us personalize your experience',
  /// );
  /// ```
  void addSelectMenu({
    required String label,
    required SelectMenu menu,
    String? description,
  }) {
    _components.add(
      Label(label: label, component: menu, description: description),
    );
  }

  /// Adds non-editable text to the modal.
  ///
  /// Creates a text display component that shows informational text without
  /// user input. Useful for instructions, warnings, or contextual information.
  ///
  /// The [text] supports Discord markdown formatting for rich text display.
  ///
  /// ## Example
  ///
  /// ```dart
  /// modal
  ///   ..addText('**Important**: Please read the guidelines before submitting.')
  ///   ..addText('All fields marked with * are required.')
  ///   ..addTextInput(
  ///     customId: 'feedback',
  ///     label: 'Your Feedback *',
  ///     style: TextInputStyle.paragraph,
  ///   );
  /// ```
  void addText(String text) {
    _components.add(TextDisplay(text));
  }

  /// Adds a text input field to the modal.
  ///
  /// Creates a labeled text input component that allows users to enter text.
  /// The [customId] identifies this input when the modal is submitted.
  ///
  /// ## Examples
  ///
  /// ### Short text input (single-line)
  ///
  /// ```dart
  /// modal.addTextInput(
  ///   customId: 'username',
  ///   label: 'Username',
  ///   style: TextInputStyle.short,
  ///   placeholder: 'Enter your username',
  ///   minLength: 3,
  ///   maxLength: 20,
  ///   isRequired: true,
  /// );
  /// ```
  ///
  /// ### Paragraph input (multi-line)
  ///
  /// ```dart
  /// modal.addTextInput(
  ///   customId: 'feedback',
  ///   label: 'Your Feedback',
  ///   style: TextInputStyle.paragraph,
  ///   placeholder: 'Tell us what you think...',
  ///   minLength: 10,
  ///   maxLength: 500,
  ///   isRequired: true,
  ///   description: 'Please be specific and constructive',
  /// );
  /// ```
  ///
  /// ### Pre-filled input (for editing)
  ///
  /// ```dart
  /// modal.addTextInput(
  ///   customId: 'bio',
  ///   label: 'Biography',
  ///   style: TextInputStyle.paragraph,
  ///   value: currentUser.bio, // Pre-fill with existing value
  ///   maxLength: 500,
  ///   description: 'Update your profile bio',
  /// );
  /// ```
  void addTextInput({
    required String customId,
    required String label,
    TextInputStyle style = TextInputStyle.short,
    String? placeholder,
    String? value,
    int? minLength,
    int? maxLength,
    bool? isRequired,
    String? description,
  }) {
    final textInput = TextInput(
      customId,
      style: style,
      placeholder: placeholder,
      value: value,
      minLength: minLength,
      maxLength: maxLength,
      isRequired: isRequired,
    );

    _components.add(
      Label(label: label, component: textInput, description: description),
    );
  }

  /// Sets the modal's title.
  ///
  /// The title appears at the top of the modal dialog and should clearly
  /// describe the modal's purpose. Discord displays this prominently in
  /// the modal header.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final modal = ModalBuilder('user_feedback')
  ///   .setTitle('Share Your Feedback')
  ///   .addTextInput(
  ///     customId: 'message',
  ///     label: 'Message',
  ///     style: TextInputStyle.paragraph,
  ///   );
  /// ```
  ///
  void setTitle(String title) {
    _title = title;
  }

  Map<String, dynamic> build() {
    return {
      'custom_id': _customId,
      'title': _title,
      'components': _components.map((e) => e.toJson()).toList(),
    };
  }
}
