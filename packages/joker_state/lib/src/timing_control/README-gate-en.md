# ⏱️ Timing Control

Here are some handy utilities to help you manage timing-related behaviors in your Flutter app.

## 🚦 CueGate

### What is it?
`CueGate` is a timing controller that helps you handle frequent events—like user input, API calls, or animations—without hassle. It gives you two main modes:

- **Debounce**: Waits until input stops for a set time before running an action
- **Throttle**: Limits how often an action can run

### Features
- **Simple API**: Easy to set up and use
- **Two modes**: Pick debounce or throttle for your scenario
- **State tracking**: Check if an action is scheduled
- **Easy cleanup**: Dispose and reset with no fuss

### When should you use each mode?

#### Debounce
- **Search as you type**: Wait until the user stops typing
- **Resize handlers**: Wait until resizing is done
- **Form validation**: Validate after the user finishes input

#### Throttle
- **Scroll events**: Limit how often you process scrolls
- **Click handlers**: Prevent double-taps or rapid clicks
- **Real-time updates**: Control how often you update data

### Usage Examples

#### Basic Debounce
Wait until the user stops typing before searching:

```dart
final searchGate = CueGate.debounce(delay: Duration(milliseconds: 300));

TextField(
  onChanged: (text) {
    searchGate.trigger(() {
      // Do the search
      searchService.search(text);
    });
  },
)
```

#### Basic Throttle
Limit how often a button can be pressed:

```dart
final likeGate = CueGate.throttle(interval: Duration(milliseconds: 500));

ElevatedButton(
  onPressed: () {
    likeGate.trigger(() {
      // Register the like
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
  // Show a "Searching..." indicator
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

### What is it?
`CueGateMixin` lets you add debounce and throttle directly to a `StatefulWidget`—no manual resource management needed.

### Features
- **No manual setup/cleanup**: Lifecycle is handled for you
- **Simple API**: Just call the methods when you need them
- **Change timing anytime**: Adjust delay/interval on the fly

### Usage Example

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
            // Debounce search: only run after 300ms of inactivity
            debounceTrigger(() {
              setState(() {
                results = searchService.search(text);
              });
            }, Duration(milliseconds: 300));
          },
        ),
        // ...results list...
        ElevatedButton(
          onPressed: () {
            // Throttle refresh: at most once per second
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

## Why Use Timing Controls?

- **Better UX**: Prevent laggy interfaces and too many operations
- **Resource efficiency**: Cut down on unnecessary API calls and computations
- **Battery friendly**: Less work for mobile devices
- **Network optimization**: Batch requests for better performance
- **Cleaner code**: Timing logic is easier to read and maintain