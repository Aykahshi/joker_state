# 🎪 Ring Cue Master - Circus 事件總線

## 📚 概述

Ring Cue Master 是一套輕量、類型安全的事件總線系統，專為 Flutter 應用設計，能和 CircusRing 依賴注入無縫搭配。它讓應用不同部分可以「不用直接依賴」就能互相溝通，採用發佈-訂閱模式。

## ✨ 特色

- 🔍 **類型安全事件**：事件有型別，編譯時就能檢查安全性
- 🚀 **整合容易**：直接和 CircusRing 依賴注入配合
- 🧩 **架構解耦**：元件間不用互相引用也能溝通
- 🔄 **多事件總線**：可為不同領域建立獨立事件總線

## 🏁 入門

### 基本用法

```dart
import 'package:circus_framework/circus_framework.dart';

// 定義一個事件（其實就是一個類別）
class UserLoggedInEvent {
  final String userId;
  final String username;
  UserLoggedInEvent(this.userId, this.username);
}

// 用 CircusRing 擴展的預設事件總線
void main() {
  // 監聽事件
  Circus.onCue<UserLoggedInEvent>((event) {
    print('使用者已登入: ${event.username}');
  });
  // 發送事件
  Circus.cue(UserLoggedInEvent('123', 'john_doe'));
}
```

### 進階：擴充 Cue 類別

如果你想要更好追蹤或工具支援，可以繼承 `Cue`：

```dart
import 'package:circus_framework/circus_framework.dart';

class UserLoggedInCue extends Cue {
  final String userId;
  final String username;
  UserLoggedInCue(this.userId, this.username);
}

// 這樣就能自動帶時間戳
void sendLoginEvent() {
  Circus.cue(UserLoggedInCue('123', 'john_doe'));
}
```

## 🎭 進階用法

### 多個事件總線

你可以為不同領域建立多個事件總線：

```dart
// 建立專屬於認證的事件總線
final authBus = Circus.ringMaster(tag: 'auth');
// 建立專屬於支付的事件總線
final paymentBus = Circus.ringMaster(tag: 'payment');

// 在特定總線監聽
authBus.listen<UserLoggedInCue>((event) {
  print('認證事件：使用者在 ${event.timestamp} 登入');
});
// 在特定總線發送事件
paymentBus.sendCue(PaymentCompletedCue(amount: 99.99));

// 也可以用 CircusRing 擴展語法
Circus.onCue<UserLoggedInCue>((event) {
  // 處理事件
}, 'auth');
Circus.cue(UserLoggedInCue('123', 'john_doe'), 'auth');
```

### 手動管理事件總線

你也可以直接操作事件總線：

```dart
// 拿預設總線的引用
final cueMaster = Circus.ringMaster();

// 訂閱事件
final subscription = cueMaster.listen<NetworkStatusChangeCue>((event) {
  updateNetworkStatus(event.isConnected);
});

// 檢查有沒有監聽器
if (cueMaster.hasListeners<AppLifecycleCue>()) {
  cueMaster.sendCue(AppLifecycleCue.resumed);
}

// 不用時記得取消訂閱
subscription.cancel();

// 重置特定事件型別（關閉流並移除監聽器）
cueMaster.reset<NetworkStatusChangeCue>();

// 不用時釋放整個總線
cueMaster.dispose();
```

## 🔧 和 CircusRing 的整合

RingCueMaster 天生就能和 CircusRing 依賴注入搭配：

```dart
// 註冊自訂事件總線
class MyCustomCueMaster implements CueMaster {
  // ...自訂內容...
}
Circus.hire(MyCustomCueMaster(), tag: 'custom');
// 用同樣方式取用
final customBus = Circus.ringMaster('custom');
```

## 📝 最佳實踐

1. **事件型別要明確**：每個事件類別專注一個領域
2. **記得取消訂閱**：元件釋放時要取消監聽
3. **用命名空間**：不同領域用不同事件總線
4. **避免循環依賴**：不要讓事件互相無限觸發
5. **事件內容要精簡**：不要傳太大物件

## 🚨 常見陷阱

- 忘記釋放事件總線會造成記憶體洩漏
- 不同領域用同一事件型別容易混淆
- 事件內容太大會影響效能
- 事件互相觸發可能造成無限循環