## 🃏 使用 JokerState 進行狀態管理

本文件詳細介紹了 JokerState 的狀態管理功能，其核心現已基於 Flutter 的 `ChangeNotifier` 構建。

### 建立狀態持有者：Joker vs. Presenter

- **`Joker<T>`**：一個簡單、輕量的狀態容器，非常適合局部狀態。您可以將它視為功能更豐富的 `ValueNotifier`。
- **`Presenter<T>`**：一個具有明確生命週期（`onInit`、`onReady`、`onDone`）的進階狀態持有者。它專為複雜的業務邏輯設計，在這些場景中您需要管理資源或執行設定/清理操作。

`Joker` 和 `Presenter` 都繼承自一個共通的基底類別 `JokerAct<T>`。

```dart
// 使用 Joker 建立簡單的計數器狀態
final counterJoker = Joker<int>(0, keepAlive: true);

// 使用 Presenter 建立帶有生命週期的計數器控制器
class CounterPresenter extends Presenter<int> {
  CounterPresenter() : super(0, keepAlive: true);

  void increment() => trickWith((s) => s + 1);

  @override
  void onInit() {
    print('Presenter 初始化完畢！');
    super.onInit();
  }

  @override
  void onDone() {
    print('Presenter 清理完畢！');
    super.onDone();
  }
}
final counterPresenter = CounterPresenter();
```

### 更新狀態

狀態可以透過多種方式更新，取決於 `autoNotify` 是否啟用（預設為啟用）。

```dart
// --- 自動通知 (autoNotify: true) ---

// 直接賦值 (僅限 Joker)
counterJoker.state = 1;

// 使用 trick() - 對 Joker 和 Presenter 都有效
counterPresenter.trick(1);

// 使用函數更新
counterPresenter.trickWith((state) => state + 1);

// 非同步更新
await counterPresenter.trickAsync(fetchValue);

// --- 手動通知 (autoNotify: false) ---
final manualJoker = Joker(0, autoNotify: false);

manualJoker.whisper(42);              // 靜默地更改值
manualJoker.whisperWith((s) => s + 1); // 靜默地轉換
manualJoker.yell();                   // 手動通知監聽器
```

### 批次更新

對於手動通知模式，您可以將多個變更分組為單一更新。

```dart
final userJoker = Joker<User>(User(name: 'initial'), autoNotify: false);

userJoker.batch()
  .apply((u) => u.copyWith(name: 'John Doe'))
  .apply((u) => u.copyWith(age: 30))
  .commit(); // 只通知監聽器一次
```

## 🌉 UI 整合

### 使用 `JokerRing` 進行依賴注入

使用 `JokerRing` 將 `Joker` 或 `Presenter` 提供給小部件樹。

```dart
JokerRing<int>(
  act: counterPresenter,
  child: YourWidgetTree(),
);
```

### 在小部件中存取狀態

使用 `BuildContext` 的擴充方法來存取已提供的狀態持有者。

- `context.watchJoker<T>()`：監聽變更並重建小部件。返回 `JokerAct<T>` 實例。
- `context.joker<T>()`：讀取實例而不進行監聽。適用於在 `onPressed` 等事件處理器中呼叫方法。

```dart
// 在 build 方法中：

// 顯示數值（當數值變更時會重建）
final count = context.watchJoker<int>().value;
Text('計數: $count');

// 呼叫方法（不會導致重建）
onPressed: () {
  final presenter = context.joker<int>() as CounterPresenter;
  presenter.increment();
}
```

### 使用 `CircusRing` 進行無上下文存取

當您需要在 Widget Tree 外部（例如在 `Presenter` 或服務層中）存取依賴項時，可以直接使用 `CircusRing`。這遵循了服務定位器（Service Locator）模式。

1.  **Hire (註冊) 依賴項**：
    通常在您的 `main.dart` 中，於應用程式運行前完成。

    ```dart
    // 註冊一個 ApiService 的單例實例
    CircusRing.hire<ApiService>(singleton: ApiService());
    ```

2.  **Find (定位) 依賴項**：
    在應用程式的任何地方存取該實例，無需 `BuildContext`。

    ```dart
    class AuthPresenter extends Presenter<AuthState> {
      // 找到依賴項
      final _apiService = CircusRing.find<ApiService>();

      Future<void> login(String user, String pass) async {
        final result = await _apiService.login(user, pass);
        // ... 更新狀態
      }
    }
    ```

### 將狀態綁定到小部件

在任何 `JokerAct` 實例上使用方便的擴充方法，將其綁定到您的 UI。

#### `perform()`
每當狀態變更時重建小部件。

```dart
counterJoker.perform(
  builder: (context, count) => Text('計數: $count'),
);
```

#### `focusOn()`
僅當狀態的選定部分變更時才重建小部件。這對於效能優化至關重要。

```dart
userJoker.focusOn<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('姓名: $name'),
);
```

#### `watch()`
響應狀態變更以執行副作用（例如顯示 `SnackBar` 或導航），而無需重建子小部件。

```dart
messageJoker.watch(
  onStateChange: (context, message) {
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  },
  child: YourPageContent(), // 這個 child 不會重建
);
```

#### `rehearse()`
`perform` 和 `watch` 的結合體。它會從單一狀態流中重建 UI *並* 執行副作用。

```dart
counterJoker.rehearse(
  builder: (context, count) => Text('計數: $count'),
  onStateChange: (context, count) {
    if (count % 10 == 0) {
      print('達到 10 的倍數！');
    }
  },
);
```

#### `assemble()`
使用 Dart Records 將多個 `JokerAct` 實例合併到單一的 builder 中。如果任何來源的 `JokerAct` 發生變更，該小部件將會重建。

```dart
typedef UserProfile = (String name, int age);

[nameJoker, ageJoker].assemble<UserProfile>(
  converter: (values) => (values[0] as String, values[1] as int),
  builder: (context, profile) {
    final (name, age) = profile;
    return Text('$name 的年齡是 $age 歲。');
  },
);
```
