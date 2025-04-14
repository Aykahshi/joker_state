import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinite Scroll Pagination Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const InfiniteScrollExample(),
    );
  }
}

class InfiniteScrollExample extends StatefulWidget {
  const InfiniteScrollExample({super.key});

  @override
  State<InfiniteScrollExample> createState() => _InfiniteScrollExampleState();
}

class _InfiniteScrollExampleState extends State<InfiniteScrollExample> {
  late Joker<List<ListItem>> listJoker;

  int currentPage = 1;

  bool isLoading = false;

  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();

    scrollController = ScrollController();

    // In this example, we create Joker by just creating a new instance without CircusRing
    listJoker = Joker<List<ListItem>>([]);

    scrollController.addListener(_scrollListener);

    _loadMoreItems();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (!isLoading) {
        _loadMoreItems();
      }
    }
  }

  Future<void> _loadMoreItems() async {
    // Stop loading if list already has 100 items
    if (listJoker.state.length >= 100) return;

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    final newItems = List.generate(
      20,
      (index) => ListItem(
        id: (currentPage - 1) * 20 + index + 1,
        title: 'Item ${(currentPage - 1) * 20 + index + 1}',
      ),
    );

    listJoker.trickWith((currentList) => [...currentList, ...newItems]);

    setState(() {
      currentPage++;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    listJoker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Scroll Pagination Example'),
      ),
      body: listJoker.perform(
        // Disable auto-dispose to make testing easier
        autoDispose: false,
        builder: (context, items) {
          return ListView.builder(
            controller: scrollController,
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == items.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('End of list'),
                  ),
                );
              }

              final item = items[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${item.id}'),
                ),
                title: Text(item.title),
                subtitle: Text('Item content #${item.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class ListItem {
  final int id;
  final String title;

  ListItem({
    required this.id,
    required this.title,
  });
}
