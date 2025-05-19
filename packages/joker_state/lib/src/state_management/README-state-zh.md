## 🎪 基本用法

### 建立 Joker 或 Presenter
- JokerState 提供了簡潔的 `Joker` 容器，並實作了 `Listenable` 接口，讓你可以在 Flutter 中輕鬆使用。
- `Presenter`。建立在 `RxInterface` 之上，並加入了 `onInit`、`onReady`、`onDone` 這三大生命週期掛勾，讓你能輕鬆管理生命週期，也能簡單的實現 `Clean Architecture` 等架構。

```dart
// 最簡單的計數器狀態 (Joker)
final counterJoker = Joker<int>(0);

// 帶有生命週期的計數器控制器 (Presenter)
class CounterPresenter extends Presenter<int> {
  CounterPresenter() : super(0);
  void increment() => trickWith((s) => s + 1);
  @override void onInit() { print('Presenter 初始化!'); }
  @override void onDone() { print('Presenter 清理完畢!'); }
}
final counterPresenter = CounterPresenter();

// Joker直接使用 setter
counterJoker.state = 1;

// Presenter使用 trick
counterPresenter.trick(1);

// keepAlive 選項
final persistentPresenter = CounterPresenter(keepAlive: true);

// autoNotify 選項
final manualPresenter = CounterPresenter(autoNotify: false);
```

### 在 Flutter 裡用 Joker/Presenter

```dart
// 最簡單的方式: perform()
counterJoker.perform(
  builder: (context, count) => Text('計數: $count'),
);

counterPresenter.perform(
  builder: (context, count) => Text('Presenter 計數: $count'),
);

// 用 focusOn() 只觀察狀態的一部分
userPresenter.focusOn<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('姓名: $name'),
);
```

## 🎪 核心概念

### 狀態怎麼改

Presenter 提供多種方法讓你更新狀態：

```dart
// 自動通知（預設）
counterPresenter.trick(42);                       // 直接賦值
counterPresenter.trickWith((state) => state + 1); // 用函數轉換
await counterPresenter.trickAsync(fetchValue);    // 非同步更新

// 手動通知
manualPresenter.whisper(42);                     // 只改值不通知
manualPresenter.whisperWith((s) => s + 1);       // 靜默轉換
manualPresenter.yell();                          // 需要時再通知
```

### 批次更新

多個狀態變更可以合併成一次通知：

```dart
userJoker.batch()
  .apply((u) => u.copyWith(name: '張三'))
  .apply((u) => u.copyWith(age: 30))
  .commit();  // 只通知一次監聽器
```

## 🌉 小部件生態系統

### Joker.perform / Presenter.perform

觀察 Joker 或 Presenter 的整個狀態來重建小部件：

```dart
// 使用 Joker 擴充方法
userJoker.perform(
  builder: (context, user) => Text('${user.name}: ${user.age}'),
)
// 使用 Presenter 擴充方法
myPresenter.perform(
   builder: (context, state) => Text('狀態: $state'),
)
```

### Joker.focusOn / Presenter.focusOn

只觀察狀態的某一部分，避免不必要的重建：

```dart
// 使用 Joker 擴充方法
userJoker.focusOn<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('姓名: $name'),
)
// 使用 Presenter 擴充方法
userPresenter.focusOn<String>(
  selector: (userProfile) => userProfile.name,
  builder: (context, name) => Text('姓名: $name'),
)
```

### Presenter.focusOnMulti

觀察多個狀態的多個部分，避免不必要的重建：

```dart
userPresenter.focusOnMulti(
  selectors: [
    (userProfile) => userProfile.name, 
    (userProfile) => userProfile.age, 
  ],
  builder: (context, [name, age]) => Text('Name: $name, Age: $age'),
);
```

### JokerTroupe / PresenterTroupe

用 Dart Records 把多個 Joker/Presenter 狀態組合在一起：

```dart
// 定義組合狀態型別
typedef UserProfile = (String name, int age, bool isActive);

JokerTroupe<UserProfile>(
  jokers: [nameJoker, ageJoker, activeJoker],
  converter: (values) => (
    values[0] as String,
    values[1] as int,
    values[2] as bool,
  ),
  builder: (context, profile) {
    final (name, age, active) = profile;
    return ListTile(
      title: Text(name),
      subtitle: Text('年齡: $age'),
      trailing: Icon(active ? Icons.check : Icons.close),
    );
  },
)

PresenterTroupe<UserProfile>(
  jokers: [nameJoker, ageJoker, activeJoker],
  converter: (values) => (
    values[0] as String,
    values[1] as int,
    values[2] as bool,
  ),
  builder: (context, profile) {
    final (name, age, active) = profile;
    return ListTile(
      title: Text(name),
      subtitle: Text('年齡: $age'),
      trailing: Icon(active ? Icons.check : Icons.close),
    );
  },
)

// 使用擴充方法
[nameJoker, ageJoker, activeJoker].assemble<UserProfile>(
  converter: (values) => (
    values[0] as String,
    values[1] as int,
    values[2] as bool,
  ),
  builder: (context, profile) {
    final (name, age, active) = profile;
    return ListTile(
      title: Text(name),
      subtitle: Text('年齡: $age'),
      trailing: Icon(active ? Icons.check : Icons.close),
    );
  },
)
```

## 🎭 副作用與監聽

不重建 UI 也能監聽狀態變化：

```dart
// 監聽狀態變化執行副作用
presenter.effect(
  child: Container(), // 子小部件
  effect: (context, state) { // 當狀態變化時執行的副作用
    print('effect:${state.value}');
    // 例如：顯示 snackbar，導航等
  },
  runOnInit: false, // 是否在小部件首次構建時運行效果
  effectWhen: (prev, curr) {
    // 是否在狀態變化時運行效果
    return (prev.value ~/ 5) != (curr.value ~/ 5);
  },
);
```