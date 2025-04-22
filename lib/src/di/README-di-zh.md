# 🎪 CircusRing

CircusRing 是一個輕量、靈活的 Flutter 依賴注入容器，讓你管理物件、生命週期和元件關係都變得很直覺。

## 🌟 概述

這套解決方案主要是幫你簡化 Flutter 專案裡的依賴註冊、查找和管理。API 設計得很直觀，支援多種實例化方式，讓你用起來更順手。

## ✨ 特色

- **🧩 多種註冊方式**：
    - 單例（即時或延遲）
    - 非同步單例
    - 工廠模式（每次都給新實例）
    - "fenix" 模式自動重綁
- **🔄 依賴關係管理**：
    - 可以明確綁定元件間的依賴
    - 防止還被依賴的元件被移除
    - 元件移除時自動清理資源
- **🔍 靈活查找**：
    - 依型別查找（可加標籤）
    - 同步、非同步都支援
    - 也能只靠標籤查找
- **♻️ 資源管理**：
    - 自動處理 Disposable 或 ChangeNotifier
    - 支援 AsyncDisposable 非同步釋放
- **🧠 狀態管理整合**：
    - 跟 Joker 狀態系統無縫整合
    - 有專門處理 Joker 的 API

## 📝 怎麼用

### 🌐 全域存取

CircusRing 採單例模式，直接用 `Circus` 這個 getter 就能拿到：

```dart
import 'package:your_package/circus_ring.dart';

final ring = Circus;
```

### 📥 註冊依賴

- 想要用 BLoC、MVC 或 MVVM 來組織您的業務邏輯嗎？只要註冊 `Presenter`，它繼承自 `Joker`，並提供 `onInit`、`onReady`、`onDone` 生命週期掛勾，讓您分層管理初始化、就緒與清理邏輯，從此告別冗長樣板。

```dart
// 註冊單例
Circus.hire<UserRepository>(UserRepositoryImpl());

// 同型別多實例用標籤區分
Circus.hire<ApiClient>(ProductionApiClient(), tag: 'prod');
Circus.hire<ApiClient>(MockApiClient(), tag: 'test');

// 懶加載單例
Circus.hireLazily<Database>(() => Database.connect());

// 非同步單例
Circus.hireLazilyAsync<NetworkService>(() async => await NetworkService.initialize());

// 工廠模式
Circus.contract<UserModel>(() => UserModel());

// 註冊 Presenter（適用於 BLoC/MVC/MVVM 架構）
final presenter = MyPresenter(initialState, tag: 'myPresenter');
Circus.hire<MyPresenter>(presenter, tag: 'myPresenter');

// 註冊簡單的 Joker (使用 summon)
Circus.summon<int>(0, tag: 'counter');
```

### 🔎 查找依賴

```dart
// 直接拿單例
final userRepo = Circus.find<UserRepository>();

// 拿有標籤的單例
final apiClient = Circus.find<ApiClient>('prod');

// 懶加載單例
final db = Circus.find<Database>();

// 非同步單例
final networkService = await Circus.findAsync<NetworkService>();

// 拿 Presenter
final presenter = Circus.find<MyPresenter>(tag: 'myPresenter');

// 拿 Joker (使用 spotlight)
final counter = Circus.spotlight<int>(tag: 'counter');

// 安全查找（找不到就回傳 null）
final maybeRepo = Circus.tryFind<UserRepository>();
```

### 🔗 綁定依賴

```dart
// 讓 UserRepository 依賴 ApiClient
Circus.bindDependency<UserRepository, ApiClient>();
// 只要 UserRepository 還在，ApiClient 就不會被移除
```

### 🧹 清理資源

**🚨 重要銷毀邏輯變更 (v3.0.0):**
`CircusRing` 的 `fire*` 方法 (`fire`, `fireByTag`, `fireAll`, `fireAsync`) 現在會**主動銷毀**被移除的 `Joker` 和 `Presenter` 實例，**除非**它們的 `keepAlive` 屬性為 `true`。這與 v2.x 的行為不同（v2.x 從不銷毀 Joker）。

```dart
// 移除標準 Disposable (觸發 dispose)
Circus.fire<UserRepository>();

// 非同步移除 AsyncDisposable (觸發 async dispose)
await Circus.fireAsync<NetworkService>();

// 移除 Joker 或 Presenter (tag: 'myTag', keepAlive: false)
// 這「會」觸發它的 dispose() 方法
Circus.fire<MyPresenter>(tag: 'myTag'); 
Circus.vanish<int>(tag: 'counter'); // vanish 內部呼叫 fire

// 移除 Joker 或 Presenter (tag: 'myTagKeepAlive', keepAlive: true)
// 這「不會」觸發它的 dispose() 方法。需要手動銷毀。
Circus.fire<MyPresenter>(tag: 'myTagKeepAlive'); 

// 移除全部依賴（會處理非同步清理，並尊重 Joker/Presenter 的 keepAlive）
await Circus.fireAll();
```

### 🃏 Joker 整合

CircusRing 跟 Joker 狀態系統可以直接搭配：

```dart
// 註冊一個 Joker 狀態 (預設 keepAlive: false)
Circus.summon<int>(0, tag: 'counter'); 

// 註冊一個要保持存活的 Joker 狀態
Circus.summon<String>("persistent", tag: 'session', keepAlive: true);

// 拿已註冊的 Joker
final counter = Circus.spotlight<int>(tag: 'counter');
final session = Circus.spotlight<String>(tag: 'session');

// 更新狀態
counter.trick(1);

// 移除 Jokers
Circus.vanish<int>(tag: 'counter'); // 從 ring 移除「並」呼叫 dispose()
Circus.vanish<String>(tag: 'session'); // 從 ring 移除，「不會」呼叫 dispose()

// keepAlive 的 Joker 需要手動銷毀
session.dispose(); 
```

## ⚙️ 日誌

CircusRing 會自動記錄註冊、查找、釋放等事件。
- **自動日誌**：debug 模式下自動啟用，release/profile 模式會關掉。
- **免設定**：不用自己設。

## 💡 最佳實踐

1. **🏷️ 標籤要一致**：用標籤區分時，命名要有規律。
2. **📊 依賴關係要明確**：用 `bindDependency` 綁定元件依賴。
3. **🗑️ 資源要正確釋放**：標準資源建議實作 `Disposable` 或 `AsyncDisposable`。對於 `Joker` 或 `Presenter`，需決定是否需要 `keepAlive: true`。請記得 `CircusRing` 會銷毀 `keepAlive: false` 的實例。
4. **🏭 短暫物件用工廠**：不需共用的物件用 `contract`。
5. **⏳ 優先用懶加載**：高成本但不一定會用到的資源建議用 `hireLazily`。