# 🎪 Ring Cue Master - Circus 事件總線

## 📚 概述

Ring Cue Master 是一套輕量、類型安全的事件總線系統，專為 Flutter 應用設計，能和 CircusRing 依賴注入無縫搭配。它讓應用不同部分可以「不用直接依賴」就能互相溝通，採用發佈-訂閱模式。

## ✨ 特色

- 🔍 **類型安全事件**：事件有型別，編譯時就能檢查安全性。
- 🚀 **整合容易**：直接和 CircusRing 依賴注入配合，`RingCueMaster` 作為預設的事件總線實現。
- 🧩 **架構解耦**：元件間不用互相引用也能溝通。
- 🔄 **多事件總線**：可為不同領域建立獨立的 `RingCueMaster` 實例。
- 🎯 **Dart Stream 驅動**：底層使用 `StreamController.broadcast`，提供標準且強大的事件流處理能力。

## 🏁 入門

### 基本用法

```dart
import 'package:joker_state/cue_master.dart';

// 1. 定義一個事件（可以是一個簡單的類別）
class UserLoggedInEvent {
  final String userId;
  final String username;
  UserLoggedInEvent(this.userId, this.username);
}

// 2. 使用 CircusRing 擴展的預設事件總線
void main() {
  // 監聽事件
  // Circus.onCue 會使用預設的 RingCueMaster 實例
  Circus.onCue<UserLoggedInEvent>((event) {
    print('使用者已登入: ${event.username} (ID: ${event.userId})');
  });

  // 發送事件
  // Circus.cue 也會使用預設的 RingCueMaster 實例
  Circus.cue(UserLoggedInEvent('123', 'john_doe'));
}
```

### 進階：擴充 Cue 類別

如果你想要事件自動帶有時間戳，或者未來需要更多通用事件元數據，可以繼承 Cue 基類：

```dart
import 'package:joker_state/cue_master.dart';

// 繼承 Cue 的事件將自動獲得 timestamp 屬性
class UserLoggedInCue extends Cue {
  final String userId;
  final String username;
  UserLoggedInCue(this.userId, this.username);

  @override
  String toString() { // 推薦覆寫 toString 以便於調試
    return 'UserLoggedInCue(userId: $userId, username: $username, timestamp: $timestamp)';
  }
}

void sendLoginEvent() {
  final event = UserLoggedInCue('456', 'jane_doe');
  print('準備發送事件: $event');
  Circus.cue(event); // 發送帶有時間戳的事件
}

void setupListener() {
  Circus.onCue<UserLoggedInCue>((cue) {
    print('收到登入提示: ${cue.username} 在 ${cue.timestamp} 登入。');
  });
}
```

### 進階：多個事件總線
你可以為應用程式的不同領域或模組建立多個隔離的事件總線實例。每個實例都是一個 RingCueMaster。

```dart
// 透過 Circus.ringMaster 獲取或創建帶有標籤的 RingCueMaster 實例
final authBus = Circus.ringMaster(tag: 'auth'); // 專屬於認證的事件總線
final paymentBus = Circus.ringMaster(tag: 'payment'); // 專屬於支付的事件總線

// 定義特定領域的 Cue
class PaymentCompletedCue extends Cue {
  final double amount;
  PaymentCompletedCue({required this.amount});
}

// 在特定總線監聽
authBus.listen<UserLoggedInCue>((event) {
  print('[AuthBus] 認證事件：使用者 ${event.username} 在 ${event.timestamp} 登入');
});

// 在特定總線發送事件
paymentBus.sendCue(PaymentCompletedCue(amount: 99.99));

// 也可以用 CircusRing 的便捷擴展語法，並指定 tag
Circus.onCue<UserLoggedInCue>((event) {
  print('[CircusFacade-Auth] 使用者 ${event.username} 登入');
}, tag: 'auth'); // 指定監聽 'auth' 總線

Circus.cue(UserLoggedInCue('789', 'another_user'), tag: 'auth'); // 指定在 'auth' 總線發送
```

### 與時間控制工具 (`CueGate`) 整合

`CueGate` 可以和 `RingCueMaster` 強大地結合，以控制事件的觸發頻率。例如，您可以輕易地在透過事件總線發送用戶輸入前，對其進行防抖動處理。

```dart
// 1. 定義事件
class SearchQueryChanged { final String query; SearchQueryChanged(this.query); }

// 2. 創建一個防抖動控制器
final searchGate = CueGate.debounce(delay: const Duration(milliseconds: 300));

// 3. 在 UI 中，於輸入改變時觸發控制器
//    控制器確保只有在用戶停止輸入後才發送事件。
onChanged: (text) {
  searchGate.trigger(() {
    Circus.cue(SearchQueryChanged(text)); // 發送經過防抖動處理的事件
  });
}

// 4. 監聽器（例如，在 Presenter 中）將以受控的頻率接收事件
Circus.onCue<SearchQueryChanged>((event) {
  print('Debounced search query: ${event.query}');
  // 現在執行實際的搜索操作
});
```

```dart
// 獲取預設的 RingCueMaster 實例
final cueMaster = Circus.ringMaster();

// 定義一些事件
class NetworkStatusChangeCue extends Cue {
  final bool isConnected;
  NetworkStatusChangeCue(this.isConnected);
}
class AppLifecycleCue extends Cue {
  final String state; // e.g., "resumed", "paused"
  AppLifecycleCue(this.state);
}

// 訂閱事件
final subscription = cueMaster.listen<NetworkStatusChangeCue>((event) {
  // updateNetworkStatus(event.isConnected);
  print('網路狀態改變: ${event.isConnected ? "已連接" : "已斷開"}');
});

// 發送事件
cueMaster.sendCue(NetworkStatusChangeCue(true));

// 檢查有沒有監聽器
if (cueMaster.hasListeners<AppLifecycleCue>()) {
  print('AppLifecycleCue 有監聽者。');
  cueMaster.sendCue(AppLifecycleCue("resumed"));
} else {
  print('AppLifecycleCue 目前沒有監聽者。');
}

// 不用時記得取消訂閱，以避免記憶體洩漏
subscription.cancel();
print('NetworkStatusChangeCue 的訂閱已取消。');

// 重置特定事件型別的流（關閉該事件類型的流並移除所有監聽器）
cueMaster.reset<NetworkStatusChangeCue>();
print('NetworkStatusChangeCue 事件流已重置。');

// 當事件總線不再需要時（例如，在 Widget 的 dispose 方法中，或者應用程式關閉時），
// 釋放整個總線以關閉所有流並清理資源。
cueMaster.dispose();
print('預設的 RingCueMaster 已釋放。');
```

## 🔧 和 CircusRing 的整合
RingCueMaster 是 CircusRing 依賴注入系統的自然組成部分。CircusRing 通常會為你管理 RingCueMaster 實例的生命週期。

```dart
import 'package:circus_ring/circus_ring.dart'; // 假設這是您的 CircusRing 包
import 'package:your_project/ring_cue_master.dart'; // 您的 RingCueMaster 和 CueMaster
import 'package:your_project/circus_ring_cue_master_extension.dart'; // 您的擴展

// ... (事件定義如 NotificationReceivedCue) ...

void main() async {
  final circus = CircusRing.instance; // 或者使用 Circus / Ring 別名

  // 1. 獲取/創建預設的事件總線 (RingCueMaster 實例)
  // getCueMaster 會在首次調用時創建並用 CircusRing.hire<CueMaster> 註冊它
  final CueMaster defaultBus = circus.getCueMaster();
  defaultBus.listen<NotificationReceivedCue>((cue) {
    print("Default Bus: ${cue.message}");
  });
  circus.sendCue(NotificationReceivedCue("來自預設總線的消息！"));

  // 2. 獲取/創建帶標籤的 RingCueMaster 實例
  final CueMaster notificationBus = circus.getCueMaster(tag: 'notifications');
  notificationBus.sendCue(NotificationReceivedCue("您有一條來自'通知'總線的新消息！"));

  // 3. 註冊並使用完全自訂的 CueMaster 實現
  //    確保您的自訂實現也實現了 Disposable (如果需要 CircusRing 自動釋放)
  class MySpecializedCueMaster implements CueMaster, Disposable {
    final String id;
    MySpecializedCueMaster(this.id);
    // ... 自訂的事件處理邏輯 ...
    @override
    Stream<T> on<T>() { print('$id: on<$T>()'); return Stream.empty(); }
    @override
    bool sendCue<T>(T cue) { print('$id: sendCue($cue)'); return true; }
    @override
    StreamSubscription<T> listen<T>(void Function(T cue) fn) { print('$id: listen<$T>()'); return Stream.empty().listen(fn); }
    @override
    bool hasListeners<T>() { print('$id: hasListeners<$T>()'); return false; }
    @override
    bool reset<T>() { print('$id: reset<$T>()'); return false; }
    @override
    void dispose() { print('$id: MySpecializedCueMaster disposing...'); }
  }

  final mySpecialBusInstance = MySpecializedCueMaster('special_bus_id');
  // 使用 CircusRing.hire 直接註冊自訂實例
  circus.hire<CueMaster>(mySpecialBusInstance, tag: 'special_bus', alias: CueMaster);

  final CueMaster retrievedSpecialBus = circus.find<CueMaster>('special_bus'); // 或者 getCueMaster
  retrievedSpecialBus.sendCue(NotificationReceivedCue("來自特殊總線的消息！"));

  // 生命週期管理：
  // 當您調用 circus.fire<CueMaster>(tag: 'notifications') 或 circus.disposeCueMaster(tag: 'notifications') 時，
  // 'notifications' 總線的 RingCueMaster 實例的 dispose() 方法會被自動調用。
  circus.disposeCueMaster(tag: 'notifications');
  print("'notifications' bus disposed: ${!circus.isHired<CueMaster>('notifications')}");

  // circus.fireAll() 會釋放所有已註冊的 Disposable 實例，包括所有 CueMaster。
  await circus.fireAll();
  print("All buses disposed after fireAll.");
}
```

