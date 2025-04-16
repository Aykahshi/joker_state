# ⏱️ 計時控制

提供管理 Flutter 應用程式中與時間相關行為的實用工具集合。

## 🚦 CueGate

### 這是什麼？ 🤔
`CueGate` 是一個計時控制器，協助管理頻繁事件，如用戶交互、API 呼叫或動畫。它提供兩種主要模式：

- **去抖動 (Debounce)**：延遲執行動作，直到輸入停止指定時間
- **節流 (Throttle)**：限制動作執行的頻率

### 特色功能 ✨
- **簡潔的 API**：易於創建和使用
- **兩種操作模式**：針對不同場景的去抖動和節流
- **狀態追蹤**：檢查動作是否已排程
- **資源管理**：輕鬆釋放和清理狀態

### 何時使用各模式？ 🎯

#### 去抖動 (Debounce)
- **邊打字邊搜尋**：等待用戶停止輸入
- **調整大小處理器**：等待調整大小完成
- **表單驗證**：用戶完成輸入後再驗證

#### 節流 (Throttle)
- **捲動事件處理**：限制處理頻率
- **點擊處理**：防止意外雙擊
- **即時數據更新**：控制更新頻率

### 使用範例 📝

#### 基本去抖動
等待用戶停止輸入後再搜尋：

```dart
final searchGate = CueGate.debounce(delay: Duration(milliseconds: 300));

TextField(
  onChanged: (text) {
    searchGate.trigger(() {
      // 執行搜尋操作
      searchService.search(text);
    });
  },
)
```

#### 基本節流
限制「讚」按鈕可被按下的頻率：

```dart
final likeGate = CueGate.throttle(interval: Duration(milliseconds: 500));

ElevatedButton(
  onPressed: () {
    likeGate.trigger(() {
      // 註冊讚操作
      postService.like(postId);
    });
  },
  child: Text('讚'),
)
```

#### 取消已排程動作
```dart
// 取消待處理的去抖動動作
searchGate.cancel();

// 檢查是否有待處理的去抖動動作
if (searchGate.isScheduled) {
  // 顯示「搜尋中...」指示器
}
```

#### 清理
```dart
@override
void dispose() {
  searchGate.dispose();
  super.dispose();
}
```

## 🎭 CueGateMixin

### 這是什麼？ 🤔
`CueGateMixin` 是一種便捷方式，可以直接將去抖動和節流功能添加到 `StatefulWidget` 中，無需手動管理資源。

### 特色功能 ✨
- **無需手動創建/釋放**：處理 CueGate 生命週期
- **簡化 API**：僅在需要時呼叫方法
- **動態調整時間**：可隨時更改延遲/間隔

### 使用範例 📝

```dart
class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with CueGateMixin {
  final controller = TextEditingController();
  List<String> results = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: (text) {
            // 在 300ms 無活動後去抖動搜尋
            debounceTrigger(() {
              setState(() {
                results = searchService.search(text);
              });
            }, Duration(milliseconds: 300));
          },
        ),
        
        // 結果列表...
        
        ElevatedButton(
          onPressed: () {
            // 節流刷新，最多每秒一次
            throttleTrigger(() {
              setState(() {
                results = searchService.refresh();
              });
            }, Duration(seconds: 1));
          },
          child: Text('刷新'),
        ),
      ],
    );
  }
}
```

## 為什麼使用計時控制？ 🎯

- **更好的用戶體驗**：防止界面卡頓和過度操作
- **資源效率**：減少不必要的 API 呼叫和計算
- **節省電池**：最小化行動裝置上的工作量
- **網絡優化**：批處理請求以獲得更好的性能
- **乾淨的程式碼**：使用聲明式方法簡化計時邏輯