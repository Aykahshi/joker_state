# 🎪 Ring Cue Master - Circus 事件總線

## 📚 概述

Ring Cue Master 是一個輕量級、類型安全的事件總線系統，專為 Flutter 應用程式設計，可與 CircusRing 依賴注入容器無縫協作。它允許應用程式的不同部分在沒有直接依賴關係的情況下進行通信，採用發布-訂閱模式。

## ✨ 特點

- 🔍 **類型安全的事件**：事件完全類型化，確保編譯時安全
- 🚀 **輕鬆整合**：直接與 CircusRing 依賴注入配合使用
- 🧩 **解耦架構**：無需直接引用即可實現組件間通信
- 🔄 **多總線支援**：為不同領域創建獨立事件總線

## 🏁 入門指南

### 基本用法

```dart
import 'package:circus_framework/circus_framework.dart';

// 定義一個事件 - 可以是任何類別
class UserLoggedInEvent {
  final String userId;
  final String username;
  
  UserLoggedInEvent(this.userId, this.username);
}

// 透過 CircusRing 擴展使用默認事件總線
void main() {
  // 監聽事件
  Circus.onCue<UserLoggedInEvent>((event) {
    print('使用者已登入: ${event.username}');
  });
  
  // 發送事件
  Circus.cue(UserLoggedInEvent('123', 'john_doe'));
}
```

### 選擇性：擴展基礎 Cue 類別

為了更好的追蹤和工具支持，您可以擴展基礎 `Cue` 類別：

```dart
import 'package:circus_framework/circus_framework.dart';

class UserLoggedInCue extends Cue {
  final String userId;
  final String username;
  
  UserLoggedInCue(this.userId, this.username);
}

// 現在您可以使用它並自動追蹤時間戳
void sendLoginEvent() {
  Circus.cue(UserLoggedInCue('123', 'john_doe'));
}
```

## 🎭 進階用法

### 創建多個事件總線

您可以為應用程式的不同部分創建多個事件總線：

```dart
// 為身份驗證事件創建專用事件總線
final authBus = Circus.ringMaster(tag: 'auth');

// 為支付事件創建專用事件總線
final paymentBus = Circus.ringMaster(tag: 'payment');

// 在特定總線上監聽
authBus.listen<UserLoggedInCue>((event) {
  print('認證事件：使用者在 ${event.timestamp} 登入');
});

// 在特定總線上發送事件
paymentBus.sendCue(PaymentCompletedCue(amount: 99.99));

// 使用 CircusRing 擴展的替代語法
Circus.onCue<UserLoggedInCue>((event) {
  // 處理事件
}, 'auth');

Circus.cue(UserLoggedInCue('123', 'john_doe'), 'auth');
```

### 手動總線管理

您可以直接訪問和管理事件總線：

```dart
// 獲取默認總線的引用
final cueMaster = Circus.ringMaster();

// 訂閱事件
final subscription = cueMaster.listen<NetworkStatusChangeCue>((event) {
  updateNetworkStatus(event.isConnected);
});

// 檢查是否有監聽器
if (cueMaster.hasListeners<AppLifecycleCue>()) {
  cueMaster.sendCue(AppLifecycleCue.resumed);
}

// 不再需要時記得取消訂閱
subscription.cancel();

// 重置特定事件類型（關閉流並移除所有監聽器）
cueMaster.reset<NetworkStatusChangeCue>();

// 不再需要時釋放整個總線
cueMaster.dispose();
```

## 🔧 與 CircusRing 的整合

RingCueMaster 設計為與 CircusRing 依賴注入無縫協作：

```dart
// 註冊自定義實現
class MyCustomCueMaster implements CueMaster {
  // 自定義實現
}

// 註冊您的自定義實現
Circus.hire(MyCustomCueMaster(), tag: 'custom');

// 使用相同的擴展訪問它
final customBus = Circus.ringMaster('custom');
```

## 📝 最佳實踐

1. **明確定義事件類型**：保持事件類別專注於特定領域
2. **取消訂閱**：當小部件被釋放時，始終取消訂閱
3. **使用命名空間總線**：為不同領域創建獨立總線
4. **避免循環依賴**：不要創建循環事件鏈
5. **保持事件輕量**：避免通過事件傳遞大型物件

## 🚨 常見陷阱

- 忘記釋放事件總線可能導致記憶體洩漏
- 在不同領域使用相同的事件類型可能導致混淆
- 在事件中傳遞大型物件可能影響性能
- 循環事件鏈可能導致無限循環