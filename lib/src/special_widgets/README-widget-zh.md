# 🎭 特殊元件

提供簡化 Flutter 應用程式中常見 UI 模式的實用元件集合。

## 🃏 JokerReveal

### 這是什麼？ 🤔
`JokerReveal` 是一個條件元件，根據布林值條件顯示兩個元件中的一個。它非常適合用於切換場景、權限狀態或任何需要條件性顯示不同內容的情況。

### 特色功能 ✨
- **直接模式**：立即提供兩個元件
- **懶加載模式**：使用建構器僅在需要時創建元件
- **延伸方法**：直接在布林值上使用

### 使用範例 📝

#### 基本用法
```dart
JokerReveal(
  condition: isLoggedIn,
  whenTrue: UserDashboard(),
  whenFalse: LoginScreen(),
)
```

#### 懶加載建構
當你想延遲創建可能耗資源的元件時：

```dart
JokerReveal.lazy(
  condition: isDataLoaded,
  whenTrueBuilder: (context) => DataVisualization(data),
  whenFalseBuilder: (context) => LoadingSpinner(),
)
```

#### 布林值延伸
更流暢的 API 使用方式：

```dart
isEnabled.reveal(
  whenTrue: ActiveButton(),
  whenFalse: DisabledButton(),
)

// 或使用懶加載
isExpanded.lazyReveal(
  whenTrueBuilder: (context) => ExpandedView(),
  whenFalseBuilder: (context) => CollapsedView(),
)
```

## 🎪 JokerTrap

### 這是什麼？ 🤔
`JokerTrap` 在元件從元件樹移除時自動釋放控制器，防止記憶體洩漏並簡化資源管理。

### 特色功能 ✨
- **自動釋放**常見控制器類型
- **支援同時管理多個控制器**
- **流暢的 API** 透過延伸方法

### 支援的控制器類型 🎮
- `ChangeNotifier`
- `TextEditingController`
- `ScrollController`
- `AnimationController`
- `StreamSubscription`
- `Disposable`
- `AsyncDisposable`

### 使用範例 📝

#### 單一控制器
```dart
final controller = TextEditingController();

return controller.trapeze(
  TextField(
    controller: controller,
    decoration: InputDecoration(labelText: '使用者名稱'),
  ),
);
```

#### 多個控制器
```dart
final nameController = TextEditingController();
final emailController = TextEditingController();

return [nameController, emailController].trapeze(
  Column(
    children: [
      TextField(controller: nameController),
      TextField(controller: emailController),
    ],
  ),
);
```

## 為什麼使用這些元件？ 🎯

- **更乾淨的程式碼**：減少樣板代碼，專注於業務邏輯
- **更好的效能**：懶加載僅在需要時創建元件
- **更安全的資源管理**：自動釋放控制器
- **更易讀的條件表達**：布林值延伸提供流暢、易讀的程式碼