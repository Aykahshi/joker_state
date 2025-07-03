[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](README.md)

# 🃏 JokerState

**⚠️ 重大重構提醒：**
- **不再依賴 RxDart**：本套件已完全重構，移除了對 `rxdart` 的依賴。
- **基於 ChangeNotifier**：核心現在基於 Flutter 原生的 `ChangeNotifier` 構建，API 更簡單、輕量且行為可預測。
- **簡化 API**：`Joker` 和 `Presenter` 現在共享一個共通的基底類別 `JokerAct`，簡化了整體架構。
- **新的依賴注入方法**：透過 `BuildContext` 進行的依賴注入已得到簡化。使用 `context.joker<T>()` 讀取實例，使用 `context.watchJoker<T>()` 來監聽變更。

JokerState 是一套基於 `ChangeNotifier` 的輕量級 Flutter 響應式狀態管理工具，並整合了依賴注入功能。
只要用 `Joker`、`Presenter` 和 UI 綁定小部件，就能靈活管理狀態，並大量減少樣板程式碼。

[![pub package](https://img.shields.io/pub/v/joker_state.svg)](https://pub.dev/packages/joker_state)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 特色

- 🧠 **響應式狀態管理**：由 `ChangeNotifier` 驅動，自動重建小部件並執行副作用。
- 💉 **簡易的依賴注入**：輕鬆地將 `Joker` 或 `Presenter` 實例提供給小部件樹。
- 🪄 **選擇性重建**：精細控制觸發 UI 更新的條件，以優化效能。
- 🔄 **批次更新**：將多個狀態變更合併為單一次的 UI 通知。
- 🏗️ **Record 支援**：使用 `JokerTroupe` 將多個狀態組合成一個視圖。
- 🧩 **模組化設計**：狀態邏輯與 UI 小部件之間有清晰的分離。
- 📢 **事件總線**：提供類型安全的事件系統，用於解耦通信。
- ⏱️ **時間控制**：提供防抖動和節流工具，以管理頻繁事件。

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

`Joker<T>` 是一個基於 `ChangeNotifier` 的輕量級狀態容器，非常適合管理簡單的局部狀態。其生命週期由監聽器和 `keepAlive` 參數管理。

```dart
// 建立一個 Joker (預設會自動通知)
final counter = Joker<int>(0);

// 更新狀態並通知所有監聽器
counter.trick(1);

// 或直接使用 setter
counter.state = 2;

// 使用函數更新
counter.trickWith((current) => current + 1);
```

### ✨ Presenter：帶有生命週期的狀態管理

`Presenter<T>` 是 `Joker` 的進階版本。它包含了生命週期掛鉤 (`onInit`, `onReady`, `onDone`)，使其成為處理複雜業務邏輯和實現 BLoC 或 MVVM 等模式的理想選擇。

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

### 🎪 JokerRing & CircusRing：依賴注入

#### 使用 `JokerRing` 進行基於 Context 的依賴注入
使用 `JokerRing` 將 `Joker` 或 `Presenter` 提供給小部件樹。子孫小部件隨後可以使用 context 擴充方法來存取該實例。

```dart
// 1. 提供 Joker/Presenter
JokerRing<int>(
  act: myPresenter,
  child: MyScreen(),
);

// 2. 在子孫小部件中存取它
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 使用 watchJoker 來監聽變更並重建
    final count = context.watchJoker<int>().value;

    return Scaffold(
      body: Text('Count: $count'),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 使用 joker() 來獲取實例而不監聽
          // 將其轉換為具體類型以存取其方法
          final presenter = context.joker<int>() as MyCounterPresenter;
          presenter.increment();
        },
      ),
    );
  }
}
```

#### 使用 `CircusRing` 進行無 Context 的依賴注入
當您需要在 Widget Tree 外部（例如在服務或另一個 `Presenter` 中）存取依賴項時，可以將 `CircusRing` 作為服務定位器使用。

```dart
// 1. 註冊依賴項（例如，在 main.dart 中）
Circus.hire<ApiService>(ApiService());

// 2. 在任何地方找到依賴項，無需 BuildContext
class AuthPresenter extends Presenter<AuthState> {
  final _apiService = Circus.find<ApiService>();

  Future<void> login(String user, String pass) async {
    final result = await _apiService.login(user, pass);
    // ... 更新狀態
  }
}
```

### 🎭 簡易的響應式 UI 整合

JokerState 在任何 `JokerAct` (`Joker` 或 `Presenter`) 上提供了擴充方法，以實現無縫的 UI 整合。

```dart
// 當狀態改變時重建一個小部件
counterJoker.perform(
  builder: (context, count) => Text('計數: $count'),
);

// 僅在狀態的特定部分改變時才重建
userJoker.focusOn<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('姓名: $name'),
);
```

更詳細的用法請參閱 [State Management](https://github.com/Aykahshi/joker_state/blob/master/packages/joker_state/lib/src/state_management/README-state-zh.md)。

### 📢 事件總線 & ⏱️ 時間控制

本套件還包含一個強健的、類型安全的事件總線 (`RingCueMaster`) 和用於節流和防抖動的時間控制工具 (`CueGate`)。這些工具獨立於狀態管理核心，但能與之良好地整合。

**範例：使用 `CueGate` 和 `RingCueMaster` 對搜索查詢進行防抖動**

```dart
// 定義一個搜索事件
class SearchQueryChanged {
  final String query;
  SearchQueryChanged(this.query);
}

// 創建一個防抖動控制器
final searchGate = CueGate.debounce(delay: const Duration(milliseconds: 300));

// 在你的 UI 中：
TextField(
  onChanged: (text) {
    // 觸發控制器。只有在停止輸入 300 毫秒後，動作才會執行。
    searchGate.trigger(() {
      // 透過事件總線發送事件
      Circus.cue(SearchQueryChanged(text));
    });
  },
);

// 在你的 Presenter 或其他服務中，監聽經過防抖動處理的事件：
class SearchPresenter extends Presenter<List<String>> {
  SearchPresenter() : super([]) {
    // 監聽經過防抖動的搜索查詢
    Circus.onCue<SearchQueryChanged>((event) {
      _performSearch(event.query);
    });
  }

  void _performSearch(String query) {
    // ... 你的搜索邏輯
  }
}
```

更多詳細資訊，請參閱 `lib` 目錄中它們各自的 README 文件。

## 何時使用 JokerState

- 您想要一個比複雜狀態管理解決方案更簡單的替代方案。
- 您需要以最少的樣板程式碼實現響應式 UI 更新。
- 您希望同時擁有自動和手動狀態通知的靈活性。
- 您需要一個簡單、整合的依賴注入解決方案。
- 您偏好清晰、直接的狀態操作。

## 授權

MIT
