# 🎪 CircusRing

一個輕量級、靈活的 Flutter 應用依賴注入容器。

## 🌟 概述

CircusRing 是一個依賴管理解決方案，旨在簡化 Flutter 應用中的物件創建、生命週期管理和元件關係。它提供了一套直觀的 API 用於註冊、查找和管理依賴，支援多種實例化策略。

## ✨ 特性

- **🧩 多種註冊類型**:
    - 單例（即時和延遲）
    - 非同步單例
    - 工廠（每次請求新實例）
    - 使用 "fenix" 模式自動重新綁定

- **🔄 依賴關係管理**:
    - 明確綁定元件之間的依賴關係
    - 防止移除仍被其他元件依賴的元件
    - 元件移除時清理資源

- **🔍 靈活檢索**:
    - 基於類型的查找（可選標籤）
    - 同步和非同步依賴解析
    - 基於標籤的查找（無需知道元件類型）

- **♻️ 資源管理**:
    - 自動處理實現了 Disposable 或 ChangeNotifier 的資源
    - 通過 AsyncDisposable 支援非同步資源釋放

- **🧠 狀態管理整合**:
    - 與 Joker 狀態管理系統無縫整合
    - 提供專門用於處理 Joker 實例的擴展

## 📝 使用方法

### 🌐 全局訪問

CircusRing 遵循單例模式，可以通過全局 `Circus` getter 訪問:

```dart
import 'package:your_package/circus_ring.dart';

// 訪問全局實例
final ring = Circus;
```

### 📥 註冊依賴

```dart
// 註冊單例實例
Circus.hire<UserRepository>(UserRepositoryImpl());

// 使用標籤註冊同一類型的多個實例
Circus.hire<ApiClient>(ProductionApiClient(), tag: 'prod');
Circus.hire<ApiClient>(MockApiClient(), tag: 'test');

// 註冊懶加載單例
Circus.hireLazily<Database>(() => Database.connect());

// 註冊非同步單例
Circus.hireLazilyAsync<NetworkService>(() async => 
  await NetworkService.initialize()
);

// 註冊工廠（每次新實例）
Circus.contract<UserModel>(() => UserModel());
```

### 🔎 查找依賴

```dart
// 獲取單例
final userRepo = Circus.find<UserRepository>();

// 獲取帶標籤的單例
final apiClient = Circus.find<ApiClient>('prod');

// 獲取或創建懶加載單例
final db = Circus.find<Database>();

// 獲取非同步單例
final networkService = await Circus.findAsync<NetworkService>();

// 安全檢索（未找到時返回 null）
final maybeRepo = Circus.tryFind<UserRepository>();
```

### 🔗 依賴綁定

```dart
// 使 UserRepository 依賴於 ApiClient
Circus.bindDependency<UserRepository, ApiClient>();

// 現在，只要 UserRepository 存在，ApiClient 就不能被移除
```

### 🧹 清理資源

```dart
// 移除特定依賴
Circus.fire<UserRepository>();

// 非同步移除（用於非同步可釋放資源）
await Circus.fireAsync<NetworkService>();

// 移除所有依賴
Circus.fireAll();

// 非同步清理所有依賴
await Circus.fireAllAsync();
```

### 🃏 Joker 整合

CircusRing 與 Joker 狀態管理系統整合：

```dart
// 註冊一個 Joker 狀態
Circus.summon<int>(0, tag: 'counter');

// 獲取已註冊的 Joker
final counter = Circus.spotlight<int>(tag: 'counter');

// 更新狀態
counter.trick(1); 

// 移除 Joker
Circus.vanish<int>(tag: 'counter');
```

## ⚙️ 配置

```dart
// 啟用除錯日誌
Circus.config(enableLogs: true);
```

## 💡 最佳實踐

1. **🏷️ 一致使用標籤**：使用標籤區分實例時，應保持一致的命名規範。

2. **📊 明確管理依賴關係**：使用 `bindDependency` 記錄並強制實施元件之間的依賴關係。

3. **🗑️ 正確釋放資源**：為需要清理的類實現 `Disposable` 或 `AsyncDisposable`。

4. **🏭 為短暫物件使用工廠**：對於不需要共享的短暫物件，使用 `contract`。

5. **⏳ 優先使用懶加載**：對於創建代價高但可能不會使用的資源，使用 `hireLazily`。