## 🚀 基本用法

### 創建Joker

```dart
// 簡單計數器狀態
final counter = Joker<int>(0);

// 默認啟用自動通知
counter.trick(1);  // 更新為1並通知監聽器

// 手動模式
final manualCounter = Joker<int>(0, autoNotify: false);
manualCounter.whisper(42);  // 靜默更新
manualCounter.yell();       // 手動通知
```

### 在Flutter中使用Joker

```dart
// 簡單計數器小部件
counter.perform(
  builder: (context, count) => Text('計數: $count'), 
);

// 選擇狀態的特定部分
userJoker.observe<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('姓名: $name'),
);
```

## 🎪 核心概念

### 狀態修改

Joker提供不同的方法來更新狀態：

```dart
// 自動通知模式（默認）
counter.trick(42);                      // 直接賦值
counter.trickWith((state) => state + 1); // 使用函數轉換
await counter.trickAsync(fetchValue);    // 異步更新

// 手動模式
counter.whisper(42);                     // 靜默更新
counter.whisperWith((s) => s + 1);       // 靜默轉換
counter.yell();                          // 手動通知
```

### 批量更新

將多個更新分組為單個通知：

```dart
user.batch()
  .apply((u) => u.copyWith(name: '張三'))
  .apply((u) => u.copyWith(age: 30))
  .commit();  // 只通知一次監聽器
```

## 🌉 小部件生態系統

### JokerStage

觀察Joker的整個狀態：

```dart
JokerStage<User>(
  joker: userJoker,
  builder: (context, user) => Text('${user.name}: ${user.age}'),
)
```

### JokerFrame

觀察狀態的特定部分以避免不必要的重建：

```dart
JokerFrame<User, String>(
  joker: userJoker,
  selector: (user) => user.name,
  builder: (context, name) => Text('姓名: $name'),
)
```

### JokerTroupe

使用Dart Records將多個Jokers組合到單個小部件中：

```dart
// 定義組合狀態類型
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

使Jokers在整個小部件樹中可訪問：

```dart
// 在小部件樹的頂部
JokerPortal<int>(
  tag: 'counter',
  joker: counterJoker,
  child: MaterialApp(...),
)

// 在小部件樹的任何位置
JokerCast<int>(
  tag: 'counter',
  builder: (context, count) => Text('計數: $count'),
)

// 或者使用擴展
Text('計數: ${context.joker<int>(tag: 'counter').state}')
```

## 🎭 副作用和監聽器

在不重建UI的情況下響應狀態變化：

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

// 之後：停止監聽
cancel();
```

## 🎪 使用CircusRing進行依賴注入

Joker與CircusRing集成用於全局狀態管理：

```dart
// 註冊Joker
Circus.summon<int>(0, tag: 'counter');
Circus.recruit<User>(User(), tag: 'user'); // 手動模式

// 在任何地方檢索
final counterJoker = Circus.spotlight<int>(tag: 'counter');

// 安全檢索
final userJoker = Circus.trySpotlight<User>(tag: 'user');

// 完成後移除
Circus.vanish<int>(tag: 'counter');
```

## 📚 擴展方法

流暢的擴展使代碼更易讀：

```dart
// 直接從Joker實例創建小部件
counterJoker.perform(
  builder: (context, count) => Text('計數: $count'),
);

userJoker.observe<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('姓名: $name'),
);

// 創建JokerTroupe
[nameJoker, ageJoker, activeJoker].assemble<UserProfile>(
  converter: (values) => (
    values[0] as String, 
    values[1] as int, 
    values[2] as bool
  ),
  builder: (context, profile) => ProfileCard(profile),
);
```

## 🧪 最佳實踐

1. **使用選擇器**：通過只選擇需要的狀態部分來最小化重建
2. **批量更新**：將相關變更分組以避免多次重建
3. **標記Joker**：使用CircusRing時始終使用標記
4. **自動釋放**：啟用autoDispose（默認）進行自動清理

## 🏆 與其他解決方案的比較

| 特性 | Joker | Provider | BLoC | GetX |
|---------|-------|----------|------|------|
| 學習曲線 | 低 | 中等 | 高 | 低 |
| 樣板代碼 | 最少 | 少 | 多 | 少 |
| 可測試性 | 高 | 高 | 高 | 中等 |
| 性能 | 良好 | 良好 | 優秀 | 良好 |
| 複雜性 | 簡單 | 中等 | 複雜 | 簡單 |