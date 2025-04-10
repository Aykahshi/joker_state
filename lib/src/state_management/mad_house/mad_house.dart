import 'package:flutter/widgets.dart';

/// Callback function type for MadHouse state changes
typedef MadHouseStateChanged<T> = void Function(T value);

/// MadHouse - A global state container using InheritedWidget
///
/// MadHouse provides a globally accessible state for larger application scopes,
/// complementing the more focused, lightweight Joker state management.

/// MadHouse is a global state management solution using InheritedWidget
///
/// Usage examples:
///
/// Basic setup:
/// ```dart
/// // Define your app state model
/// class AppState {
///   final String username;
///   final bool isDarkMode;
///   final String selectedLanguage;
///
///   AppState({
///     required this.username,
///     required this.isDarkMode,
///     required this.selectedLanguage,
///   });
///
///   // Create a new instance with updated properties
///   AppState copyWith({
///     String? username,
///     bool? isDarkMode,
///     String? selectedLanguage,
///   }) {
///     return AppState(
///       username: username ?? this.username,
///       isDarkMode: isDarkMode ?? this.isDarkMode,
///       selectedLanguage: selectedLanguage ?? this.selectedLanguage,
///     );
///   }
/// }
///
/// // Setup MadKeeper at the root of your app
/// void main() {
///   runApp(
///     MadKeeper<AppState>(
///       initialState: AppState(
///         username: 'Guest',
///         isDarkMode: false,
///         selectedLanguage: 'en',
///       ),
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
///
/// Accessing the state:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   // Read the state directly
///   final appState = MadHouse.of<AppState>(context).state;
///
///   return MaterialApp(
///     title: 'MadHouse Demo',
///     theme: appState.isDarkMode ? ThemeData.dark() : ThemeData.light(),
///     home: HomePage(),
///   );
/// }
/// ```
///
/// Using the context extension:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   // Access state using the extension method
///   final appState = context.madState<AppState>();
///
///   return Scaffold(
///     appBar: AppBar(
///       title: Text('Welcome, ${appState.username}'),
///     ),
///     body: Center(
///       child: Text('Current language: ${appState.selectedLanguage}'),
///     ),
///   );
/// }
/// ```
///
/// Updating the state:
/// ```dart
/// // Using MadController to update state
/// void _toggleTheme(BuildContext context) {
///   final controller = context.madController<AppState>();
///   final currentState = controller.state;
///
///   controller.updateState(
///     currentState.copyWith(isDarkMode: !currentState.isDarkMode)
///   );
/// }
///
/// // Or using updateStateWith for more concise updates
/// void _toggleTheme(BuildContext context) {
///   context.madController<AppState>().updateStateWith(
///     (state) => state.copyWith(isDarkMode: !state.isDarkMode)
///   );
/// }
/// ```
///
/// Using MadHouseBuilder for reactive UI:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(title: Text('Settings')),
///     body: Column(
///       children: [
///         // This widget will rebuild only when the state changes
///         MadHouseBuilder<AppState>(
///           builder: (context, state) {
///             return SwitchListTile(
///               title: Text('Dark Mode'),
///               value: state.isDarkMode,
///               onChanged: (value) {
///                 context.madController<AppState>().updateStateWith(
///                   (state) => state.copyWith(isDarkMode: value)
///                 );
///               },
///             );
///           },
///         ),
///
///         MadHouseBuilder<AppState>(
///           builder: (context, state) {
///             return DropdownButton<String>(
///               value: state.selectedLanguage,
///               items: ['en', 'es', 'fr', 'de'].map((lang) {
///                 return DropdownMenuItem(
///                   value: lang,
///                   child: Text(lang),
///                 );
///               }).toList(),
///               onChanged: (value) {
///                 if (value != null) {
///                   context.madController<AppState>().updateStateWith(
///                     (state) => state.copyWith(selectedLanguage: value)
///                   );
///                 }
///               },
///             );
///           },
///         ),
///       ],
///     ),
///   );
/// }
/// ```
///
/// Using MadHouse with Joker:
/// ```dart
/// // MadHouse for app-wide state
/// // Joker for component-specific state
///
/// @override
/// Widget build(BuildContext context) {
///   // Global state from MadHouse
///   final appState = context.madState<AppState>();
///
///   // Local counter state with Joker
///   final counterJoker = Joker<int>(0);
///
///   return Scaffold(
///     appBar: AppBar(
///       title: Text('${appState.username}\'s Counter'),
///     ),
///     body: Column(
///       children: [
///         // Use JokerStage for local state
///         counterJoker.perform((context, count) {
///           return Text(
///             'Count: $count',
///             style: TextStyle(fontSize: 24),
///           );
///         }),
///
///         Row(
///           mainAxisAlignment: MainAxisAlignment.center,
///           children: [
///             ElevatedButton(
///               onPressed: () => counterJoker.trick(counterJoker.state + 1),
///               child: Icon(Icons.add),
///             ),
///             SizedBox(width: 16),
///             ElevatedButton(
///               onPressed: () {
///                 // Update global state when count reaches 10
///                 if (counterJoker.state >= 10) {
///                   context.madController<AppState>().updateStateWith(
///                     (state) => state.copyWith(username: 'Master Counter')
///                   );
///                   counterJoker.trick(0);
///                 }
///               },
///               child: Text('Unlock Achievement'),
///             ),
///           ],
///         ),
///       ],
///     ),
///   );
/// }
/// ```

class MadHouse<T> extends InheritedWidget {
  /// Creates a MadHouse widget
  ///
  /// [child]: Widget that will have access to this state
  /// [state]: The global state to be shared
  /// [onChange]: Optional callback that gets triggered when state changes
  const MadHouse({
    super.key,
    required this.state,
    required super.child,
    this.onChange,
  });

  /// The global state maintained by this MadHouse
  final T state;

  /// Optional callback for when state changes
  final MadHouseStateChanged<T>? onChange;

  /// Get the current MadHouse instance from context
  static MadHouse<T> of<T>(BuildContext context) {
    final MadHouse<T>? result =
        context.dependOnInheritedWidgetOfExactType<MadHouse<T>>();

    if (result == null) {
      throw FlutterError(
          'MadHouse.of() called with a context that does not contain a MadHouse<$T>.\n'
          'No MadHouse<$T> ancestor could be found starting from the context that was passed '
          'to MadHouse.of<$T>(). This can happen because you do not have a MadHouse<$T> '
          'widget in the widget tree above the widget that called MadHouse.of<$T>().');
    }
    return result;
  }

  /// Try to get the current MadHouse instance from context (nullable version)
  static MadHouse<T>? tryOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MadHouse<T>>();
  }

  @override
  bool updateShouldNotify(MadHouse<T> oldWidget) {
    final shouldUpdate = state != oldWidget.state;
    if (shouldUpdate && onChange != null) {
      onChange!(state);
    }
    return shouldUpdate;
  }
}
