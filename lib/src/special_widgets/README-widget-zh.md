# 🎭 特殊元件

這裡有幾個幫你簡化 Flutter 常見 UI 實作的實用元件。

## 🃏 JokerReveal

### 這是什麼？
`JokerReveal` 是一個條件元件，根據布林值決定顯示哪個元件。很適合用在場景切換、權限狀態或任何需要根據條件顯示不同內容的地方。

### 特色
- **直接模式**：直接給兩個元件
- **懶加載模式**：用 builder，只有需要時才建立元件
- **延伸方法**：可以直接在布林值上用

### 用法範例

#### 基本用法
```dart
JokerReveal(
  condition: isLoggedIn,
  whenTrue: UserDashboard(),
  whenFalse: LoginScreen(),
)
```

#### 懶加載
如果你想延後建立比較耗資源的元件：

```dart
JokerReveal.lazy(
  condition: isDataLoaded,
  whenTrueBuilder: (context) => DataVisualization(data),
  whenFalseBuilder: (context) => LoadingSpinner(),
)
```

#### 布林值延伸
更流暢的寫法：

```dart
isEnabled.reveal(
  whenTrue: ActiveButton(),
  whenFalse: DisabledButton(),
)

// 或用懶加載
isExpanded.lazyReveal(
  whenTrueBuilder: (context) => ExpandedView(),
  whenFalseBuilder: (context) => CollapsedView(),
)
```

## 🎪 JokerTrap

### 這是什麼？
`JokerTrap` 幫你在元件從樹上移除時自動釋放控制器，避免記憶體洩漏，也讓資源管理更簡單。

### 特色
- **自動釋放**常見控制器
- **可同時管理多個控制器**
- **流暢 API**：用延伸方法就能用

### 支援的控制器類型
- `ChangeNotifier`
- `TextEditingController`
- `ScrollController`
- `AnimationController`
- `StreamSubscription`
- `Disposable`
- `AsyncDisposable`

### 用法範例

#### 一個控制器
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

## 為什麼要用這些元件？

- **程式碼更乾淨**：少寫樣板，專心寫邏輯
- **效能更好**：懶加載只在需要時才建立元件
- **資源管理更安全**：控制器自動釋放
- **條件判斷更直覺**：布林值延伸讓程式碼更易讀