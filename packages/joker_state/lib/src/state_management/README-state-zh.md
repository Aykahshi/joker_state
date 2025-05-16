## 🎪 基本用法

### 建立 Joker 或 Presenter

- JokerState 提供了簡潔的 `Joker` 容器，可以輕鬆掌握區域變數，實現精細的重建控制。
- `Presenter`。建立在 `BehaviorSubject` 之上，並加入了 `onInit`、`onReady`、`onDone` 這三大生命週期掛勾，讓你能輕鬆管理生命週期，也能簡單的實現 `Clean Architecture` 等架構。

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

// 常見操作對兩者都適用:
counterJoker.trick(1);
counterPresenter.increment(); 

// keepAlive 選項
final persistentJoker = Joker<String>("data", keepAlive: true);
final persistentPresenter = CounterPresenter(keepAlive: true);
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

Joker 提供多種方法讓你更新狀態：

```dart
// 自動通知（預設）
counterJoker.trick(42);                      // 直接賦值
counterJoker.trickWith((state) => state + 1); // 用函數轉換
await counterJoker.trickAsync(fetchValue);    // 非同步更新

// 手動通知
counterJoker.whisper(42);                     // 只改值不通知
counterJoker.whisperWith((s) => s + 1);       // 靜默轉換
counterJoker.yell();                          // 需要時再通知
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
// 監聽所有變化
final cancel = counterJoker.listen((previous, current) {
  print('計數從$previous變為$current');
});

// 條件監聽
final cancel = counterJoker.listenWhen(
  listener: (prev, curr) => print('計數增加了！'),
  shouldListen: (prev, curr) => curr > (prev ?? 0),
);

// 不用時記得取消監聽
cancel();
```