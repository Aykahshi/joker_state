## 🎪 基本用法

### 建立 Joker 或 Presenter

- JokerState 提供了簡潔的 `Joker` 容器；若想在 BLoC、MVC 或 MVVM 架構中清晰分離邏輯，就改用 `Presenter`。它建立在 `Joker` 之上，並加入了 `onInit`、`onReady`、`onDone` 這三大生命週期掛勾，讓你能輕鬆管理初始化、UI 就緒與清理步驟，不再被樣板程式碼綁住。

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

### JokerStage / Presenter.perform

觀察 Joker 或 Presenter 的整個狀態：

```dart
// 使用 Joker
JokerStage<User>(
  joker: userJoker,
  builder: (context, user) => Text('${user.name}: ${user.age}'),
)
// 使用 Presenter (透過擴充方法)
myPresenter.perform(
   builder: (context, state) => Text('狀態: $state'),
)
```

### JokerFrame / Presenter.focusOn

只觀察狀態的某一部分，避免不必要的重建：

```dart
// 使用 Joker
JokerFrame<User, String>(
  joker: userJoker,
  selector: (user) => user.name,
  builder: (context, name) => Text('姓名: $name'),
)
// 使用 Presenter (透過擴充方法)
userPresenter.focusOn<String>(
  selector: (userProfile) => userProfile.name,
  builder: (context, name) => Text('姓名: $name'),
)
```

### JokerTroupe

用 Dart Records 把多個 Joker 狀態組合在一起：

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
```

### JokerPortal 和 JokerCast

讓 Joker 可以在整個小部件樹裡被存取：

```dart
// 在小部件樹頂部提供 Joker
JokerPortal<int>(
  tag: 'counter',
  joker: counterJoker,
  child: MaterialApp(...),
)

// 在任何地方取用 Joker
JokerCast<int>(
  tag: 'counter',
  builder: (context, count) => Text('計數: $count'),
)

// 或用擴展
Text('計數: ${context.joker<int>(tag: 'counter').state}')
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

## 🎪 用 CircusRing 做依賴注入

Joker 和 Presenter 跟 CircusRing 可以整合，方便全域狀態管理：

```dart
// 註冊 Joker (使用 summon)
Circus.summon<int>(0, tag: 'counter');

// 註冊 Presenter (使用 hire)
final presenter = MyPresenter(initialState, tag: 'myPresenter');
Circus.hire<MyPresenter>(presenter, tag: 'myPresenter');

// 任何地方都能取用
final counterJoker = Circus.spotlight<int>(tag: 'counter');
final myPresenter = Circus.find<MyPresenter>(tag: 'myPresenter');

// 用完記得移除 (CircusRing 會根據 keepAlive 處理銷毀)
Circus.vanish<int>(tag: 'counter'); // 如果 keepAlive 為 false 則會銷毀
Circus.fire<MyPresenter>(tag: 'myPresenter'); // 如果 keepAlive 為 false 則會銷毀
```

## 📚 擴展方法

這些擴展讓你的程式碼更簡潔：

```dart
// Joker/Presenter 直接產生小部件
counterJoker.perform(...);
counterPresenter.perform(...);

userPresenter.focusOn<String>(...);

// 組合多個 Joker 狀態
[nameJoker, ageJoker, activeJoker].assemble<UserProfile>(...);
```

## 🧹 生命週期管理

- **監聽器自動銷毀**：預設 (`keepAlive: false`) 下，`Joker` 和 `Presenter` 會在最後一個監聽器移除時，用 microtask 自動安排銷毀。
- **銷毀可取消**：如果在 microtask 執行前又加回監聽器，銷毀會被取消。
- **`keepAlive`**：設 `keepAlive: true` 可阻止基於監聽器的自動銷毀。實例會一直存在，直到被明確銷毀或由 CircusRing 移除（見下文）。
- **手動銷毀**：你隨時可以自己呼叫 `joker.dispose()` 或 `presenter.dispose()`。
- **Widget 整合**：像 `JokerStage`、`JokerFrame` 這些小部件會自動管理監聽器。小部件移除時監聽器也會移除，若 `keepAlive` 為 false，可能會觸發自動銷毀。
- **與 CircusRing 的互動 (v3.0.0+)**：當透過 `Circus.fire*` 或 `Circus.vanish` 移除 `Joker` 或 `Presenter` 時，CircusRing **將會** 呼叫該實例的 `dispose()` 方法，**前提是 `keepAlive` 為 `false`**。如果 `keepAlive` 為 `true`，CircusRing 只會將其實例從註冊表中移除，你需要手動管理銷毀。

## 🧪 最佳實踐

1. **用 selector (`focusOn`)**：只選取需要的狀態部分，最小化重建。
2. **批次更新**：合併相關的狀態變更。
3. **標記你的實例**: 使用 CircusRing 時務必加上 tag，特別是通用型別。
4. **`keepAlive`**：對於全域或需要持久存在的狀態 (Joker 或 Presenter)，使用 `keepAlive: true`。請記得若被 CircusRing 移除後可能需要手動銷毀。
5. **顯式銷毀**: 對於不由 widgets 或 CircusRing 管理的實例（特別是 `keepAlive: true` 的），請手動呼叫 `dispose()`。