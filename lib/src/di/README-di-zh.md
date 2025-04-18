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

```dart
// 移除特定依賴
Circus.fire<UserRepository>();

// 非同步移除
await Circus.fireAsync<NetworkService>();

// 移除全部依賴（會處理非同步清理）
await Circus.fireAll();
```

### 🃏 Joker 整合

CircusRing 跟 Joker 狀態系統可以直接搭配：

```dart
// 註冊一個 Joker 狀態
Circus.summon<int>(0, tag: 'counter');

// 拿已註冊的 Joker
final counter = Circus.spotlight<int>(tag: 'counter');

// 更新狀態
counter.trick(1);

// 移除 Joker
Circus.vanish<int>(tag: 'counter');
```

## ⚙️ 日誌

CircusRing 會自動記錄註冊、查找、釋放等事件。
- **自動日誌**：debug 模式下自動啟用，release/profile 模式會關掉。
- **免設定**：不用自己設。

## 💡 最佳實踐

1. **🏷️ 標籤要一致**：用標籤區分時，命名要有規律。
2. **📊 依賴關係要明確**：用 `bindDependency` 綁定元件依賴。
3. **🗑️ 資源要正確釋放**：需要清理的類建議實作 `Disposable` 或 `AsyncDisposable`。
4. **🏭 短暫物件用工廠**：不需共用的物件用 `contract`。
5. **⏳ 優先用懶加載**：高成本但不一定會用到的資源建議用 `hireLazily`。