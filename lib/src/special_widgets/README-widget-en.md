# 🎭 Special Widgets

A collection of utility widgets to simplify common UI patterns in Flutter applications.

## 🃏 JokerReveal

### What is it? 🤔
`JokerReveal` is a conditional widget that shows one of two widgets based on a boolean condition. It's perfect for toggle scenarios, permission states, or any situation where you need to conditionally display different content.

### Features ✨
- **Direct mode**: Immediately provide both widgets
- **Lazy mode**: Use builders to create widgets only when needed
- **Extension method**: Use directly on boolean values

### Usage Examples 📝

#### Basic Usage
```dart
JokerReveal(
  condition: isLoggedIn,
  whenTrue: UserDashboard(),
  whenFalse: LoginScreen(),
)
```

#### Lazy Construction
When you want to defer the creation of potentially expensive widgets:

```dart
JokerReveal.lazy(
  condition: isDataLoaded,
  whenTrueBuilder: (context) => DataVisualization(data),
  whenFalseBuilder: (context) => LoadingSpinner(),
)
```

#### Boolean Extension
For a more fluent API:

```dart
isEnabled.reveal(
  whenTrue: ActiveButton(),
  whenFalse: DisabledButton(),
)

// Or with lazy loading
isExpanded.lazyReveal(
  whenTrueBuilder: (context) => ExpandedView(),
  whenFalseBuilder: (context) => CollapsedView(),
)
```

## 🎪 JokerTrap

### What is it? 🤔
`JokerTrap` automatically disposes controllers when a widget is removed from the tree, preventing memory leaks and simplifying resource management.

### Features ✨
- **Automatic disposal** of common controller types
- **Support for multiple controllers** at once
- **Fluent API** via extensions

### Supported Controllers 🎮
- `ChangeNotifier`
- `TextEditingController`
- `ScrollController`
- `AnimationController`
- `StreamSubscription`
- `Disposable`
- `AsyncDisposable`

### Usage Examples 📝

#### Single Controller
```dart
final controller = TextEditingController();

return controller.trapeze(
  TextField(
    controller: controller,
    decoration: InputDecoration(labelText: 'Username'),
  ),
);
```

#### Multiple Controllers
```dart
final nameController = TextEditingController();
final emailController = TextEditingController();

return [nameController, emailController].trapeze(
  Column(
    children: [
      TextField(controller: nameController),
      TextField(controller: emailController),
    ],
  ),
);
```

## Why Use These Widgets? 🎯

- **Cleaner code**: Reduce boilerplate and focus on business logic
- **Better performance**: Lazy loading creates widgets only when needed
- **Safer resource management**: Automatically dispose controllers
- **More readable conditionals**: Boolean extensions provide fluent, readable code