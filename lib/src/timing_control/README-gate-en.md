# ⏱️ Timing Control

A collection of utilities to manage timing-related behaviors in Flutter applications.

## 🚦 CueGate

### What is it? 🤔
`CueGate` is a timing controller that helps manage frequent events like user interactions, API calls, or animations. It provides two primary modes:

- **Debounce**: Delays an action until input stops for a specified duration
- **Throttle**: Limits how often an action can execute

### Features ✨
- **Simple API**: Easy to create and use
- **Two operation modes**: Debounce and throttle for different scenarios
- **State tracking**: Check if actions are scheduled
- **Resource management**: Easy disposal and state cleanup

### When to Use Each Mode? 🎯

#### Debounce
- **Search-as-you-type**: Wait until user stops typing
- **Resize handlers**: Wait until resizing finishes
- **Form validation**: Validate after user completes input

#### Throttle
- **Scroll event handlers**: Limit processing frequency
- **Click handlers**: Prevent accidental double-clicks
- **Real-time data updates**: Control update frequency

### Usage Examples 📝

#### Basic Debounce
Wait until user stops typing before searching:

```dart
final searchGate = CueGate.debounce(delay: Duration(milliseconds: 300));

TextField(
  onChanged: (text) {
    searchGate.trigger(() {
      // Perform search operation
      searchService.search(text);
    });
  },
)
```

#### Basic Throttle
Limit how often a "like" button can be pressed:

```dart
final likeGate = CueGate.throttle(interval: Duration(milliseconds: 500));

ElevatedButton(
  onPressed: () {
    likeGate.trigger(() {
      // Register like action
      postService.like(postId);
    });
  },
  child: Text('Like'),
)
```

#### Canceling Scheduled Actions
```dart
// Cancel a pending debounce action
searchGate.cancel();

// Check if there's a pending debounce action
if (searchGate.isScheduled) {
  // Show "Searching..." indicator
}
```

#### Cleanup
```dart
@override
void dispose() {
  searchGate.dispose();
  super.dispose();
}
```

## 🎭 CueGateMixin

### What is it? 🤔
`CueGateMixin` is a convenient way to add debounce and throttle capabilities directly to a `StatefulWidget` without manual resource management.

### Features ✨
- **No manual creation/disposal**: Handles CueGate lifecycle
- **Simplified API**: Just call methods when needed
- **Dynamic timing**: Change delay/interval on-the-fly

### Usage Examples 📝

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
            // Debounce search after 300ms of inactivity
            debounceTrigger(() {
              setState(() {
                results = searchService.search(text);
              });
            }, Duration(milliseconds: 300));
          },
        ),
        
        // Results list...
        
        ElevatedButton(
          onPressed: () {
            // Throttle refresh to max once per second
            throttleTrigger(() {
              setState(() {
                results = searchService.refresh();
              });
            }, Duration(seconds: 1));
          },
          child: Text('Refresh'),
        ),
      ],
    );
  }
}
```

## Why Use Timing Controls? 🎯

- **Better UX**: Prevent stuttering interfaces and excessive operations
- **Resource efficiency**: Reduce unnecessary API calls and computations
- **Battery saving**: Minimize work on mobile devices
- **Network optimization**: Batch requests for better performance
- **Clean code**: Simplified timing logic with declarative approach