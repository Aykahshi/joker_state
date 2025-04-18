# ⏱️ 計時控制

這裡提供一些管理 Flutter 應用裡「跟時間有關」行為的實用工具。

## 🚦 CueGate

### 這是什麼？
`CueGate` 是一個計時控制器，幫你管理像是用戶連續操作、API 呼叫、動畫等頻繁事件。它有兩種主要模式：

- **去抖動 (Debounce)**：等輸入停下來一段時間才執行動作
- **節流 (Throttle)**：限制動作執行的頻率

### 特色
- **API 很簡單**：建立、用法都很直覺
- **兩種模式**：針對不同場景選 debounce 或 throttle
- **狀態追蹤**：可以查動作有沒有排程中
- **資源管理方便**：釋放、清理都很簡單

### 什麼時候該用哪種？

#### 去抖動 (Debounce)
- 邊打字邊搜尋：等用戶停下來再查
- 視窗調整大小：等調整完再處理
- 表單驗證：用戶輸入完再驗證

#### 節流 (Throttle)
- 捲動事件：限制處理頻率
- 點擊防連點：避免重複觸發
- 即時數據更新：控制更新頻率

### 用法範例

#### 基本去抖動
等用戶停下來再搜尋：

```dart
final searchGate = CueGate.debounce(delay: Duration(milliseconds: 300));

TextField(
  onChanged: (text) {
    searchGate.trigger(() {
      // 執行搜尋
      searchService.search(text);
    });
  },
)
```

#### 基本節流
限制按鈕點擊頻率：

```dart
final likeGate = CueGate.throttle(interval: Duration(milliseconds: 500));

ElevatedButton(
  onPressed: () {
    likeGate.trigger(() {
      // 執行按讚
      postService.like(postId);
    });
  },
  child: Text('讚'),
)
```

#### 取消已排程動作
```dart
// 取消還沒執行的 debounce 動作
searchGate.cancel();

// 檢查有沒有排程中的 debounce 動作
if (searchGate.isScheduled) {
  // 顯示「搜尋中...」
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

### 這是什麼？
`CueGateMixin` 讓你在 StatefulWidget 裡直接用 debounce/throttle，不用自己管理資源。

### 特色
- **不用手動建立/釋放**：生命週期自動處理
- **API 更簡單**：要用時直接呼叫
- **時間可隨時調整**：延遲/間隔都能改

### 用法範例

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
            // 300ms 內沒動作才搜尋
            debounceTrigger(() {
              setState(() {
                results = searchService.search(text);
              });
            }, Duration(milliseconds: 300));
          },
        ),
        // ...結果列表...
        ElevatedButton(
          onPressed: () {
            // 最多每秒刷新一次
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

## 為什麼要用計時控制？

- **用戶體驗更好**：避免卡頓、過度觸發
- **省資源**：減少不必要的 API 呼叫和計算
- **省電**：減少裝置負擔
- **網路更有效率**：請求能批次處理
- **程式碼更乾淨**：計時邏輯更直覺