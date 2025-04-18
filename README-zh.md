[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](README.md)

# 🃏 JokerState

**⚠️ Breaking Changes in v2.0.0:** Joker 生命週期和 CircusRing 釋放行為有重大變更。升級前請查閱 [變更日誌](CHANGELOG.md) 和下方更新後的文檔。

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
- 📢 **Event Bus 系統** - 使用 RingCueMaster 的類型安全事件
- 🎪 **特殊 Widgets** - 額外的實用Widget，如 JokerReveal 和 JokerTrap
- ⏱️ **時間控制** - 用於控制操作執行的防抖動和節流機制

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

`Joker<T>` 是一個繼承自 `ChangeNotifier` 的響應式狀態容器。其生命週期現在主要由其監聽器和 `keepAlive` 標誌管理。

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

// 創建一個即使沒有監聽器也保持活動狀態的 Joker
final persistentState = Joker<String>("initial", keepAlive: true);
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

**生命週期：** 預設情況下 (`keepAlive: false`)，當最後一個監聽器被移除時，Joker 會通過 `Future.microtask` 自動安排自身的釋放。再次添加監聽器會取消此安排。設置 `keepAlive: true` 可禁用此自動釋放。

### 🎪 CircusRing：依賴注入

CircusRing 是一個輕量級的依賴容器。其 `fire*` 方法現在執行**條件式釋放 (conditional disposal)**。

```dart
// 全局單例訪問器
final ring = Circus;

// 註冊一個單例 (Disposable 範例)
ring.hire(MyDisposableService());

// 註冊一個延遲加載的單例
ring.hireLazily(() => NetworkService());

// 註冊一個工廠（每次請求一個新實例）
ring.contract(() => ApiClient());

// 之後尋找實例
final service = Circus.find<MyDisposableService>();
```

CircusRing 與 Joker 的整合：

```dart
// 註冊一個 Joker（需要標籤）
Circus.summon<int>(0, tag: 'counter');

// 尋找已註冊的 Joker
final counter = Circus.spotlight<int>(tag: 'counter');

// 移除一個 Joker（僅從註冊表中移除，不會釋放 Joker）
Circus.vanish<int>(tag: 'counter'); 

// Joker 自身的生命週期（監聽器/keepAlive）決定了它何時釋放。
```

**釋放：** `Circus.fire*` 方法 **僅會** 釋放**非 Joker** 且實現了 `Disposable`、`AsyncDisposable` 或 `ChangeNotifier` 的實例。`Joker` 實例**永遠不會**被 CircusRing 釋放；它們管理自己的生命週期。

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

通過小部件樹提供和訪問 Jokers。**請記住，在提供/訪問像 `int` 或 `String` 這樣的通用類型時，使用 `tag` 以避免歧義。**

```dart
// 將 Joker 插入小部件樹
JokerPortal<int>(
  joker: counterJoker,
  tag: 'counter', // Tag 在此至關重要！
  child: MyApp(),
)

// 之後，從任何後代訪問它
JokerCast<int>(
  tag: 'counter', // 使用相同的 tag！
  builder: (context, count) => Text('Count: $count'),
)

// 或使用擴展直接訪問
Text('Count: ${context.joker<int>(tag: 'counter').state}')
```

### 🎪 特殊小部件

#### JokerReveal

根據布爾表達式有條件地顯示小部件：

```dart
// 直接小部件
JokerReveal(
  condition: isLoggedIn,
  whenTrue: ProfileScreen(),
  whenFalse: LoginScreen(),
)

// 延遲構建
JokerReveal.lazy(
  condition: isLoading,
  whenTrueBuilder: (context) => LoadingIndicator(),
  whenFalseBuilder: (context) => ContentView(),
)

// 或使用擴展方法在布爾值上
isLoggedIn.reveal(
  whenTrue: ProfileScreen(),
  whenFalse: LoginScreen(),
)
```

#### JokerTrap

當小部件從樹中移除時自動處理控制器的釋放：

```dart
// 單個控制器
textController.trapeze(
  TextField(controller: textController),
)

// 多個控制器
[textController, scrollController, animationController].trapeze(
  ComplexWidget(),
)
```

### 📢 RingCueMaster：事件總線系統

用於組件之間通信的類型安全事件總線：

```dart
// 定義事件類型
class UserLoggedIn extends Cue {
  final User user;
  UserLoggedIn(this.user);
}

// 訪問全局事件總線
final cueMaster = Circus.ringMaster();

// 監聽事件
final subscription = Circus.onCue<UserLoggedIn>((event) {
  print('用戶 ${event.user.name} 在 ${event.timestamp} 登入');
});

// 發送事件
Circus.cue(UserLoggedIn(currentUser));

// 完成後取消訂閱
subscription.cancel();
```

### ⏱️ CueGate：時間控制

使用防抖動和節流機制管理操作的時間：

```dart
// 創建一個防抖動閘門
final debouncer = CueGate.debounce(delay: Duration(milliseconds: 300));

// 在事件處理器中使用
TextField(
  onChanged: (value) {
    debouncer.trigger(() => performSearch(value));
  },
),
// 創建一個節流閘門
final throttler = CueGate.throttle(interval: Duration(seconds: 1));

// 限制 UI 更新
scrollController.addListener(() {
  throttler.trigger(() => updatePositionIndicator());
});

// 在 StatefulWidget 中，使用 mixin 自動清理
class SearchView extends StatefulWidget {
// ...
}

class _SearchViewState extends State<SearchView> with CueGateMixin {
  void _handleSearchInput(String query) {
    debounceTrigger(
      () => _performSearch(query),
      Duration(milliseconds: 300),
    );
  }

  void _handleScroll() {
    throttleTrigger(
      () => _updateScrollPosition(),
      Duration(milliseconds: 100),
    );
  }

// 清理由 mixin 自動處理
}
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

- **Joker**：基於監聽器和 `keepAlive` 管理自己的生命週期。
- **CircusRing**：在移除時有條件地釋放非 Joker 資源。
- **手動清理**：務必手動 `dispose()` 未由其他地方管理的 Jokers 或其他資源（尤其是 `keepAlive: true` 的 Jokers）。

```dart
// Joker 範例
final persistentJoker = Joker<int>(0, keepAlive: true);
// ... 使用 joker ...
persistentJoker.dispose(); // 需要手動釋放

// CircusRing 範例 (Disposable)
Circus.hire(MyDisposableService());
// ... 使用 service ...
Circus.fire<MyDisposableService>(); // Service 會被 fire() 釋放

// CircusRing 範例 (Joker)
final managedJoker = Circus.summon<int>(0, tag: 'temp');
// ... 使用 joker ...
Circus.vanish<int>(tag: 'temp'); // 僅從 ring 中移除
// 如果沒有剩餘的監聽器，managedJoker 會自行釋放 (預設 keepAlive: false)
```

## 範例

完整的計數器範例：

```dart
import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 直接註冊 Joker 並獲取實例
    final counter = Circus.summon<int>(tag: 'counter');
    
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
- 您需要一個類型安全的事件總線用於解耦通信
- 您需要與狀態管理良好配合的實用小部件

## 授權

MIT