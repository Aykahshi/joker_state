## 🚀 基本用法

### 建立 Joker

```dart
// 最簡單的計數器狀態
final counter = Joker<int>(0);

// 預設會自動通知
counter.trick(1);  // 狀態變了，監聽器會收到通知

// 手動通知模式
final manualCounter = Joker<int>(0, autoNotify: false);
manualCounter.whisper(42);  // 只改值不通知
manualCounter.yell();       // 需要時再手動通知

// 沒監聽器也能一直存在的 Joker
final persistentJoker = Joker<String>("data", keepAlive: true);
```

### 在 Flutter 裡用 Joker

```dart
// 最簡單的計數器小部件
counter.perform(
  builder: (context, count) => Text('計數: $count'),
);

// 只取狀態的某一部分
userJoker.observe<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('姓名: $name'),
);
```

## 🎪 核心概念

### 狀態怎麼改

Joker 提供多種方法讓你更新狀態：

```dart
// 自動通知（預設）
counter.trick(42);                      // 直接賦值
counter.trickWith((state) => state + 1); // 用函數轉換
await counter.trickAsync(fetchValue);    // 非同步更新

// 手動通知
counter.whisper(42);                     // 只改值不通知
counter.whisperWith((s) => s + 1);       // 靜默轉換
counter.yell();                          // 需要時再通知
```

### 批次更新

多個狀態變更可以合併成一次通知：

```dart
user.batch()
  .apply((u) => u.copyWith(name: '張三'))
  .apply((u) => u.copyWith(age: 30))
  .commit();  // 只通知一次監聽器
```

## 🌉 小部件生態系統

### JokerStage

觀察 Joker 的整個狀態：

```dart
JokerStage<User>(
  joker: userJoker,
  builder: (context, user) => Text('${user.name}: ${user.age}'),
)
```

### JokerFrame

只觀察狀態的某一部分，避免不必要的重建：

```dart
JokerFrame<User, String>(
  joker: userJoker,
  selector: (user) => user.name,
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

Joker 跟 CircusRing 可以整合，方便全域狀態管理：

```dart
// 註冊 Joker
Circus.summon<int>(0, tag: 'counter');
Circus.recruit<User>(User(), tag: 'user'); // 手動模式

// 任何地方都能取用
final counterJoker = Circus.spotlight<int>(tag: 'counter');

// 安全取用
final userJoker = Circus.trySpotlight<User>(tag: 'user');

// 用完記得移除
Circus.vanish<int>(tag: 'counter');
```

## 📚 擴展方法

這些擴展讓你的程式碼更簡潔：

```dart
// Joker 直接產生小部件
counterJoker.perform(
  builder: (context, count) => Text('計數: $count'),
);

userJoker.observe<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('姓名: $name'),
);

// 組合多個 Joker 狀態
[nameJoker, ageJoker, activeJoker].assemble<UserProfile>(
  converter: (values) => (
    values[0] as String,
    values[1] as int,
    values[2] as bool
  ),
  builder: (context, profile) => ProfileCard(profile),
);
```

## 🧹 生命週期管理

- **監聽器自動釋放**：預設 (`keepAlive: false`) 下，最後一個監聽器移除時，Joker 會用 microtask 自動安排釋放。
- **釋放可取消**：如果在 microtask 執行前又加回監聽器，釋放會被取消。
- **keepAlive**：設 `keepAlive: true`，Joker 會一直存在，直到你手動釋放或用 CircusRing 移除（如果有註冊）。
- **手動釋放**：你隨時可以呼叫 `joker.dispose()`。
- **Widget 整合**：像 `JokerStage`、`JokerFrame` 這些小部件會自動管理監聽器。小部件移除時，監聽器也會移除，若 `keepAlive` 為 false，Joker 可能會自動釋放。

## 🧪 最佳實踐

1. **用 selector**：只選你需要的狀態，減少重建。
2. **批次更新**：相關變更合併，避免多次重建。
3. **Joker 要標記**：用 CircusRing 時記得加 tag。
4. **`keepAlive`**：全域或需長存的 Joker 請設 `keepAlive: true`。
5. **顯式釋放**：沒被小部件或 CircusRing 管理的 Joker，特別是 `keepAlive: true`，請手動釋放。

## 🏆 跟其他方案比較

| 特性 | Joker | Provider | BLoC | GetX |
|---------|-------|----------|------|------|
| 學習曲線 | 低 | 中等 | 高 | 低 |
| 樣板代碼 | 最少 | 少 | 多 | 少 |
| 可測試性 | 高 | 高 | 高 | 中等 |
| 性能 | 良好 | 良好 | 優秀 | 良好 |
| 複雜性 | 簡單 | 中等 | 複雜 | 簡單 |