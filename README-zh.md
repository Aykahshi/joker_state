[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](README.md)

# 🃏 JokerState

**⚠️ v2.0.0 重大變更提醒：** Joker 的生命週期和 CircusRing 的釋放行為有了重要調整。升級前，建議先看看[變更日誌](CHANGELOG.md)和下方更新說明。

JokerState 是一套輕量級的 Flutter 響應式狀態管理工具，還直接整合了依賴注入。你只要用 `Joker` API 和幾個配套小部件，就能靈活管理狀態，樣板程式碼也很少。

[![pub package](https://img.shields.io/pub/v/joker_state.svg)](https://pub.dev/packages/joker_state)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 特色

- 🧠 **響應式狀態管理**：狀態一變，監聽器馬上收到通知。
- 💉 **依賴注入**：用 CircusRing API，服務註冊和取得都很直覺。
- 🎭 **小部件整合彈性高**：多種小部件，UI 怎麼變都能配合。
- 🪄 **選擇性重建**：你可以細緻控制哪些狀態變動會觸發 UI 重建。
- 🔄 **批次更新**：多個狀態變更可以合併成一次通知。
- 🏗️ **Record 支援**：用 Dart Records 組合多個狀態。
- 🧩 **模組化設計**：只用你需要的功能，或整包一起用都行。
- 📢 **事件總線**：RingCueMaster 提供類型安全的事件系統。
- 🎪 **特殊 Widgets**：像 JokerReveal、JokerTrap 這類實用小部件。
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

### 🎭 Joker：響應式狀態容器

`Joker<T>` 是一個繼承自 `ChangeNotifier` 的響應式狀態容器。它的生命週期主要靠監聽器和 `keepAlive` 參數來管理。

```dart
// 建立一個 Joker，預設會自動通知
final counter = Joker<int>(0);

// 更新狀態並通知所有監聽器
counter.trick(1);

// 用函數轉換更新
counter.trickWith((current) => current + 1);

// 批次處理多個更新，只通知一次
counter.batch()
  .apply((s) => s * 2)
  .apply((s) => s + 10)
  .commit();

// 建立一個即使沒監聽器也會持續存在的 Joker
final persistentState = Joker<String>("initial", keepAlive: true);
```

如果你想自己控制通知時機，可以用手動通知模式：

```dart
// 建立時關閉自動通知
final manualCounter = Joker<int>(0, autoNotify: false);

// 靜默更新
manualCounter.whisper(5);
manualCounter.whisperWith((s) => s + 1);

// 準備好時再手動通知監聽器
manualCounter.yell();
```

**生命週期說明：** 預設 (`keepAlive: false`) 下，當最後一個監聽器被移除時，Joker 會用 microtask 自動安排釋放。如果你又加回監聽器，釋放會自動取消。若希望 Joker 一直存在，請設 `keepAlive: true`。

### 🎪 CircusRing：依賴注入

CircusRing 是一個輕量級的依賴容器。它的 `fire*` 方法現在會根據情況自動釋放資源。

```dart
// 全域單例存取器
final ring = Circus;

// 註冊單例（Disposable 範例）
ring.hire(MyDisposableService());

// 註冊延遲加載的單例
ring.hireLazily(() => NetworkService());

// 註冊工廠，每次請求都給新實例
ring.contract(() => ApiClient());

// 之後取得實例
final service = Circus.find<MyDisposableService>();
```

CircusRing 跟 Joker 的整合：

```dart
// 註冊一個 Joker（要加 tag）
Circus.summon<int>(0, tag: 'counter');

// 取得已註冊的 Joker
final counter = Circus.spotlight<int>(tag: 'counter');

// 移除 Joker（只從註冊表移除，不會釋放 Joker）
Circus.vanish<int>(tag: 'counter');

// Joker 什麼時候釋放，由監聽器/keepAlive 決定。
```

**釋放說明：** `Circus.fire*` 只會釋放非 Joker，且有實作 `Disposable`、`AsyncDisposable` 或 `ChangeNotifier` 的實例。Joker 實例永遠不會被 CircusRing 釋放，它們自己管理生命週期。

### 🎭 UI 整合

JokerState 提供多種小部件，方便你把狀態和 UI 結合：

#### JokerStage

只要狀態有變，這個小部件就會重建：

```dart
final userJoker = Joker<User>(User(name: 'Alice', age: 30));

JokerStage<User>(
  joker: userJoker,
  builder: (context, user) => Text('Name: ${user.name}, Age: ${user.age}'),
)
```

你也可以用更流暢的 API：

```dart
userJoker.perform(
  builder: (context, user) => Text('Name: ${user.name}, Age: ${user.age}'),
)
```

#### JokerFrame

只針對狀態的某一部分重建：

```dart
userJoker.observe<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
)
```

#### JokerTroupe

用 Dart Records 組合多個 Joker 狀態：

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

讓 Joker 可以在小部件樹中被提供和取得。**如果是像 `int` 或 `String` 這種通用型別，記得用 `tag` 避免混淆。**

```dart
// 把 Joker 放進小部件樹
JokerPortal<int>(
  joker: counterJoker,
  tag: 'counter', // tag 很重要！
  child: MyApp(),
)

// 之後在任何子元件都能取得
JokerCast<int>(
  tag: 'counter', // 要用同一個 tag！
  builder: (context, count) => Text('Count: $count'),
)

// 或用擴展直接取得
Text('Count: ${context.joker<int>(tag: 'counter').state}')
```

### 🎪 特殊小部件

#### JokerReveal

根據布林值條件顯示不同小部件：

```dart
// 直接給元件
JokerReveal(
  condition: isLoggedIn,
  whenTrue: ProfileScreen(),
  whenFalse: LoginScreen(),
)

// 懶加載
JokerReveal.lazy(
  condition: isLoading,
  whenTrueBuilder: (context) => LoadingIndicator(),
  whenFalseBuilder: (context) => ContentView(),
)

// 或用擴展方法
isLoggedIn.reveal(
  whenTrue: ProfileScreen(),
  whenFalse: LoginScreen(),
)
```

#### JokerTrap

小部件從樹上移除時，自動幫你釋放控制器：

```dart
// 一個控制器
textController.trapeze(
  TextField(controller: textController),
)

// 多個控制器
[textController, scrollController, animationController].trapeze(
  ComplexWidget(),
)
```

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