# 🎭 Special Widgets

Here are some utility widgets to make common Flutter UI patterns much easier.

## 🃏 JokerReveal

### What is it?
`JokerReveal` is a conditional widget that shows one of two widgets based on a boolean. It's great for toggling between screens, handling permissions, or any situation where you want to show different content depending on a condition.

### Features
- **Direct mode**: Pass both widgets up front
- **Lazy mode**: Use builders to create widgets only when needed
- **Extension method**: Use directly on boolean values for a more fluent API

### Usage Examples

#### Basic Usage
```dart
JokerReveal(
  condition: isLoggedIn,
  whenTrue: UserDashboard(),
  whenFalse: LoginScreen(),
)
```

#### Lazy Construction
If you want to delay building widgets that might be expensive:

```dart
JokerReveal.lazy(
  condition: isDataLoaded,
  whenTrueBuilder: (context) => DataVisualization(data),
  whenFalseBuilder: (context) => LoadingSpinner(),
)
```

#### Boolean Extension
A more fluent way to write it:

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

### What is it?
`JokerTrap` automatically disposes controllers when a widget is removed from the tree, so you don't have to worry about memory leaks or manual cleanup.

### Features
- **Automatic disposal** of common controller types
- **Manage multiple controllers at once**
- **Fluent API** via extensions

### Supported Controllers
- `ChangeNotifier`
- `TextEditingController`
- `ScrollController`
- `AnimationController`
- `StreamSubscription`
- `Disposable`
- `AsyncDisposable`

### Usage Examples

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

## Why Use These Widgets?

- **Cleaner code**: Less boilerplate, focus on your logic
- **Better performance**: Lazy loading only builds widgets when needed
- **Safer resource management**: Controllers are disposed automatically
- **More readable conditionals**: Boolean extensions make your code easier to read