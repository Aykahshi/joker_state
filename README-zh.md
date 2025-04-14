[![English](https://img.shields.io/badge/Language-Chinese-blueviolet?style=for-the-badge)](README.md)

# 🃏 JokerState

一個輕量級的 Flutter 響應式狀態管理解決方案，無縫整合依賴注入。JokerState 通過其 `Joker` API 和配套小部件提供靈活的狀態容器，且需要的樣板代碼極少。

[![pub package](https://img.shields.io/pub/v/joker_state.svg)](https://pub.dev/packages/joker_state)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 特點

- 🧠 **響應式狀態管理** - 當狀態變化時通知監聽器的智能容器
- 💉 **依賴注入** - 具有 CircusRing API 的直覺式服務定位器
- 🎭 **靈活的小部件整合** - 多種適用於不同 UI 模式的配套小部件
- 🪄 **選擇性重建** - 對哪些更新重建您的 UI 有精細控制
- 🔄 **批次更新** - 將多個狀態變更分組為單一通知
- 🏗️ **Record 支援** - 使用 Dart Records 組合多個狀態
- 🧩 **模組化設計** - 可以只使用您需要的功能或整個生態系統

## 開始使用

將 JokerState 添加到您的 `pubspec.yaml`：

```yaml
dependencies:
  joker_state: ^latest_version
```

然後導入軟件包：

```dart
import 'package:joker_state/joker_state.dart';
```

## 核心概念

### 🎭 Joker：響應式狀態容器

`Joker<T>` 是一個繼承自 `ChangeNotifier` 的響應式狀態容器：

```dart
// 創建一個自動通知的 Joker（預設）
final counter = Joker<int>(0);

// 更新狀態並通知所有監聽器
counter.trick(1);

// 使用轉換函數更新
counter.trickWith((current) => current + 1);

// 使用單一通知批次處理多個更新
counter.batch()
  .apply((s) => s * 2)
  .apply((s) => s + 10)
  .commit();
```

要進行精細控制，請使用手動通知模式：

```dart
// 創建時禁用自動通知
final manualCounter = Joker<int>(0, autoNotify: false);

// 靜默更新
manualCounter.whisper(5);
manualCounter.whisperWith((s) => s + 1);

// 準備好時手動觸發監聽器
manualCounter.yell();
```

### 🎪 CircusRing：依賴注入

CircusRing 是一個輕量級的依賴容器，用於 Jokers 和其他服務：

```dart
// 全局單例訪問器
final ring = Circus;

// 註冊一個單例
ring.hire(UserRepository());

// 註冊一個延遲加載的單例
ring.hireLazily(() => NetworkService());

// 註冊一個工廠（每次請求一個新實例）
ring.contract(() => ApiClient());

// 之後尋找實例
final repo = Circus.find<UserRepository>();
```

CircusRing 與 Joker 的整合：

```dart
// 註冊一個 Joker（需要標籤）
Circus.summon<int>(0, tag: 'counter');

// 尋找已註冊的 Joker
final counter = Circus.spotlight<int>(tag: 'counter');

// 完成後移除 Joker
Circus.vanish<int>(tag: 'counter');
```

### 🎭 UI 整合

JokerState 提供多種小部件類型來與您的 UI 整合：

#### JokerStage

當狀態的任何部分變化時重建：

```dart
final userJoker = Joker<User>(User(name: 'Alice', age: 30));

JokerStage<User>(
  joker: userJoker,
  builder: (context, user) => Text('Name: ${user.name}, Age: ${user.age}'),
)
```

或使用更流暢的 API：

```dart
userJoker.perform(
  builder: (context, user) => Text('Name: ${user.name}, Age: ${user.age}'),
)
```

#### JokerFrame

基於狀態的特定部分進行選擇性重建：

```dart
userJoker.observe<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
)
```

#### JokerTroupe

使用 Dart Records 組合多個 Jokers：

```dart
final name = Joker<String>('Alice');
final age = Joker<int>(30);
final active = Joker<bool>(true);

typedef UserRecord = (String name, int age, bool active);

[name, age, active].assemble<UserRecord>(
  converter: (values) => (values[0] as String, values[1] as int, values[2] as bool),
  builder: (context, user) {
    final (name, age, active) = user;
    return Column(
      children: [
        Text('Name: $name'),
        Text('Age: $age'),
        Icon(active ? Icons.check : Icons.close),
      ],
    );
  },
)
```

#### JokerPortal 和 JokerCast

通過小部件樹提供和訪問 Jokers：

```dart
// 將 Joker 插入小部件樹
JokerPortal<int>(
  joker: counterJoker,
  child: MyApp(),
)

// 之後，從任何後代訪問它
JokerCast<int>(
  builder: (context, count) => Text('Count: $count'),
)

// 或使用擴展直接訪問
Text('Count: ${context.joker<int>().state}')
```

## 進階功能

### 🔄 副作用

監聽狀態變化的副作用：

```dart
// 監聽所有變化
final cancel = counter.listen((previous, current) {
  print('Changed from $previous to $current');
});

// 有條件監聽
counter.listenWhen(
  listener: (prev, curr) => showToast('Milestone reached!'), 
  shouldListen: (prev, curr) => curr > 100 && (prev ?? 0) <= 100,
);

// 完成後取消
cancel();
```

### 💉 CircusRing 依賴關係

建立依賴關係：

```dart
// 記錄 UserRepository 依賴於 ApiService
Circus.bindDependency<UserRepository, ApiService>();

// 現在當 UserRepository 註冊時，ApiService 不能被移除
```

### 🧹 資源管理

Joker 和 CircusRing 都處理適當的清理：

```dart
// 當小部件被移除時自動清理
JokerStage<User>(
  joker: userJoker,
  autoDispose: true, // 預設
  builder: (context, user) => Text(user.name),
)

// 手動清理
userJoker.dispose();
Circus.fire<ApiClient>();
```

## 範例

完整的計數器範例：

```dart
import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  // 全局註冊 Joker
  Circus.summon<int>(0, tag: 'counter');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 尋找已註冊的 Joker
    final counter = Circus.spotlight<int>(tag: 'counter');
    
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('JokerState Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You have pushed the button this many times:'),
              // 只有當狀態變化時才重建
              counter.perform(
                builder: (context, count) => Text(
                  '$count',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          // 更新狀態
          onPressed: () => counter.trickWith((state) => state + 1),
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
```

## 附加資訊

JokerState 設計為輕量級、靈活且強大 - 在一個連貫的套件中提供響應式狀態管理和依賴注入。

### 何時使用 JokerState

- 您想要一個比 BLoC 或其他複雜狀態解決方案更簡單的替代方案
- 您需要響應式 UI 更新且樣板代碼最少
- 您需要在必要時進行手動控制的靈活性
- 您需要整合的依賴管理
- 您偏好清晰、直接的狀態操作，而不是抽象概念

## 授權

MIT