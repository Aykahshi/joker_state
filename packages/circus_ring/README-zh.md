# 🎪 CircusRing

**CircusRing** 是一個輕量、靈活的 Flutter 依賴注入容器，讓你管理物件、生命週期和元件關係都變得很直覺。

## ✨ 特色

- **🧩 多種註冊方式**：
    - 單例（即時或延遲）
    - 非同步單例
    - 工廠模式（每次都給新實例）
    - "`fenix`" 模式自動重新產生實例
- **🔄 依賴關係管理**：
    - 可以明確綁定元件間的依賴
    - 防止還被依賴的元件被移除
    - 元件移除時自動清理資源
- **🔍 靈活查找**：
    - 依型別查找（可加標籤）
    - 同步、非同步都支援
    - 也能只靠 `Tag` 查找
- **♻️ 資源管理**：
    - 自動處理 `Disposable` 或 `ChangeNotifier`
    - 支援 `AsyncDisposable` 非同步釋放

## 📝 怎麼用

### 🌐 全域存取

CircusRing 是全局單例，可以直接透過 `Circus` 或 `Ring` 來輕易取用：

```dart
import 'package:joker_state/circus_ring.dart';

final instance = Circus.find<T>();
final instance = Ring.find<T>();
```

### 📥 註冊依賴

`CircusRing` 提供多種註冊方式，你甚至可以提供一個 `alias`，這在實作架構時很有用。

```dart
// 簡單的註冊單例，並直接返回該實例
// 沒錯，所以你可以直接這樣使用
// final repository = Circus.hire<UserRepository>();
Circus.hire(UserRepository());

// 同型別多實例用標籤區分，適合用於多 flavor 的開發場景
Circus.hire<ApiClient>(ProductionApiClient(), tag: 'prod');
Circus.hire<ApiClient>(MockApiClient(), tag: 'test');

// 懶加載單例
Circus.hireLazily<Database>(() => Database.initialize());

// 非同步單例
Circus.hireLazilyAsync<NetworkService>(() async => await NetworkService.initialize());

// 工廠模式
Circus.contract<UserModel>(() => UserModel());

// "fenix" 模式自動重新產生實例
Circus.hireLazily<UserModel>(() => UserModel(), fenix: true);

// "alias" 模式，傳入想作為 alias 的 `Type`， CircusRing 會幫你處理好一切
Circus.hire<UserRepository>(UserRepositoryImpl(), alias: UserRepository);
```

### 🔎 查找依賴

`CircusRing` 可以輕鬆找到註冊的依賴，而這一切都只是 `Map`， 所以速度超快！

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

// 利用 Tag 查找
final client = Circus.findByTag('mockClient');

// 安全的 Tag 查找，找不到就回傳 null
final maybeClient = Circus.tryFindByTag('mockClient');
```

### 🔗 綁定依賴
`CircusRing` 提供了 `bindDependency` 方法來綁定依賴關係，確保依賴的物件不會被意外移除。

```dart
// 讓 UserRepository 依賴 ApiClient
Circus.bindDependency<UserRepository, ApiClient>();
// 只要 UserRepository 還在，ApiClient 就不會被移除
```

### 🧹 清理資源

`CircusRing` 提供了多種清理方法，包括同步和非同步清理，如果你想要你的依賴在移除時自動釋放資源，請讓你的依賴實現 `Disposable` 或 `AsyncDisposable`。

```dart
// 移除標準 Disposable (觸發 dispose)
Circus.fire<UserRepository>();

// 非同步移除 AsyncDisposable (觸發 async dispose)
await Circus.fireAsync<NetworkService>();

// 移除全部依賴，也會一併處理非同步清理
await Circus.fireAll();
```

## ⚙️ 友善的 Debug 功能
`CircusRing` 預設透過 `kDebugMode` 來控制 Debug 訊息輸出，但你也可以透過 `enableLogs` 來控制。

```dart
Circus.enableLogs = true; // 啟用 Debug 訊息
Circus.enableLogs = false; // 關閉 Debug 訊息
```