[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](README.md)

# 🃏 JokerState

**⚠️ v4.0.0 重大變更提醒：** 
- `CircusRing` 現在是獨立的 Package，雖在 JokerState 中仍然可用，但不再專為 Joker 提供整合擴展，請使用 [circus_ring](https://pub.dev/packages/circus_ring) 包。
- `RingCueMaster` 現在藉助 `rx_dart`，提供更優秀的 Event bus 系統。
- `JokerStage`, `JokerFrame` 建構子變為私有，請使用 `perform`, `focusOn` API。
- 現在 `Joker`, `Presenter` 都基於 `RxInterface`，提供更靈活的狀態管理方式與更好的效能。
- `RxInterface` 基於 `BehaviorSubject`，並在內部基於 `Timer`，提供更好的 autoDispose 處理。
- `JokerPortal`, `JokerCast` 已棄用，請使用 CircusRing API 結合 `Presenter` 實現無 `context` 的狀態管理。
- `JokerReveal` 已棄用，請使用 Dart 原生的語言特性來實現條件渲染。
- `JokerTrap` 已棄用，請使用 `Presenter` 的 `onDone`，或 `StatefulWidget` 的 `dispose` 方法來管理控制器。

JokerState 是一套基於 `rx_dart` 的輕量級 Flutter 響應式狀態管理工具，並整合了依賴注入 [circus_ring](https://pub.dev/packages/circus_ring)。
只要用 `Joker`, `Presenter`, `CircusRing` API 就能靈活管理狀態，大量減少樣板程式碼。

[![pub package](https://img.shields.io/pub/v/joker_state.svg)](https://pub.dev/packages/joker_state)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 特色

- 🧠 **響應式狀態管理**：自動重建小部件，執行副作用。
- 💉 **依賴注入**：用 CircusRing API，簡單搞定依賴注入。
- 🪄 **選擇性重建**：你可以細緻控制哪些狀態變動會觸發 UI 重建。
- 🔄 **批次更新**：多個狀態變更可以合併成一次通知。
- 🏗️ **Record 支援**：用 Dart Records 組合多個狀態。
- 🧩 **模組化設計**：只導入你需要的功能，或整包一起用都行。
- 📢 **事件總線**：RingCueMaster 提供類型安全的事件系統。
- ⏱️ **時間控制**：防抖動、節流等時間控制工具。

## 快速開始

在 `pubspec.yaml` 加入 JokerState：

```yaml
dependencies:
  joker_state: ^latest_version
```

然後匯入套件：

```dart
import 'package:joker_state/joker_state.dart';
```

## 核心概念

### 🎭 Joker：局部響應式狀態容器

`Joker<T>` 基於 `RxInterface` ，提供局部響應式狀態容器。它的生命週期主要靠監聽器和 `keepAlive` 參數來管理，同時提供 `whisper` API 用於手動控制， 以及 `batch` API 用於批次更新。

```dart
// 建立一個 Joker，預設會自動通知
final counter = Joker<int>(0);

// 更新狀態並通知所有監聽器
counter.trick(1);

// 用函數轉換更新
counter.trickWith((current) => current + 1);

// 或是更簡單的
counter.state = 1;
```

### ✨ Presenter

`Presenter<T>` 是 Joker 的進階版本，基於額外提供 `onInit`、`onReady`、`onDone` 生命週期掛勾，提供開發者更精細的操作並能輕鬆實現 BLoC、MVC、MVVM 模式。

```dart
class MyCounterPresenter extends Presenter<int> {
  MyCounterPresenter() : super(0);

  @override
  void onInit() { /* 初始化操作 */ }

  @override
  void onReady() { /* 可以安全地與 WidgetsBinding 互動 */ }

  @override
  void onDone() { /* 清理資源 */ }

  void increment() => trickWith((s) => s + 1);
}

// 使用:
final myPresenter = MyCounterPresenter();
myPresenter.increment();
// dispose() 會自動呼叫 onDone()
myPresenter.dispose(); 
```

### 🎪 CircusRing：依賴注入

CircusRing 是一個輕量級的依賴容器，現已拆分為獨立的 [circus_ring](https://pub.dev/packages/circus_ring)，但在 JokerState 中仍然可用。


### 🎭 簡易的響應式 UI 整合

JokerState 提供多種小部件，方便你把狀態和 UI 結合：

#### 最簡單的使用方式

```dart
// 使用 Joker
final userJoker = Joker<User>(...);
userJoker.perform(
  builder: (context, user) => Text('Name: ${user.name}'),
)

// 使用 Presenter
final myPresenter = MyPresenter(...);
myPresenter.perform(
  builder: (context, state) => Text('State: $state'),
)
```

更詳細的使用方式請見 [State Management](https://github.com/Aykahshi/joker_state/blob/master/packages/joker_state/lib/src/state_management/README-state-zh.md)。

### 📢 RingCueMaster：事件總線系統

用於元件間溝通的類型安全事件總線：

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
Circus.sendCue(UserLoggedIn(currentUser));
```

更詳細的使用方式請見 [Event Bus](https://github.com/Aykahshi/joker_state/blob/master/packages/joker_state/lib/src/event_bus/README-event-bus-zh.md)。

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

更詳細的使用方式請見 [Timing Controls](https://github.com/Aykahshi/joker_state/blob/master/packages/joker_state/lib/src/timing_control/README-gate-zh.md)。

## 進階功能

### 🔄 副作用

監聽狀態變化並執行副作用：

```dart
final counter = Joker<int>(0);

counter.effect(
  child: Container(),
  effect: (context, state) {
    print('State changed: $state');
  },
  runOnInit: true,
  effectWhen: (prev, val) => (prev!.value ~/ 5) != (val.value ~/ 5),
);
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