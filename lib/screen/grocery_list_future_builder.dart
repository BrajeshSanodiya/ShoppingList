import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grocery_snap/screen/add_grocery.dart';
import 'package:grocery_snap/data/categories.dart';
import 'package:grocery_snap/models/grocery_item.dart';
import 'package:http/http.dart' as http;

class GroceryListFutureBuilder extends StatefulWidget {
  const GroceryListFutureBuilder({super.key});

  @override
  State<GroceryListFutureBuilder> createState() => _GroceryListFutureBuilderState();
}

class _GroceryListFutureBuilderState extends State<GroceryListFutureBuilder> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
      'grocerysnap-com-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list.json',
    );

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception("Failed to fetch data. Please try again later.");
    }
    if (response.body == 'null') {
      return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category =
          categories.entries
              .firstWhere(
                (catItem) => catItem.value.name == item.value['category'],
              )
              .value;

      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }

    return loadedItems;
  }

  void callAddButton() async {
    final newItem = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => const AddGrocery()));

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _undoDelete(int index, GroceryItem item) async {
    final url = Uri.https(
      'grocerysnaps-com-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list.json',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'applicaton/json'},
        body: json.encode({
          'name': item.name,
          'quantity': item.quantity,
          'category': item.category.name,
        }),
      );

      if (response.statusCode >= 400) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: const Text("Failed to Undo data"),
          ),
        );
        return;
      }
      if (response.body == 'null') {
        // setState(() {
        //   _isLoading = false;
        // });
        return;
      }

      setState(() {
        _groceryItems.insert(index, item);
      });
    } catch (error) {
      // setState(() {
      //   _error = "Something went wrong here. Please try again later.";
      // });
    }
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
      'grocerysnap-com-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list/${item.id}.json',
    );

    try {
      final response = await http.delete(url);

      if (response.statusCode >= 400) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: const Text(
              "Something went wrong, Please try again later.",
            ),
          ),
        );
        setState(() {
          _groceryItems.insert(index, item);
        });
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: const Text("Deleted Successfully."),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                _undoDelete(index, item);
              },
            ),
          ),
        );
      }
    } catch (error) {
      // setState(() {
      //   _error = "Something went wrong here. Please try again later.";
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Groceries"),
        actions: [IconButton(onPressed: callAddButton, icon: Icon(Icons.add))],
      ),
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No items added yet.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return Dismissible(
                onDismissed: (direction) {
                  _removeItem(snapshot.data![index]);
                },
                key: ValueKey(snapshot.data![index].id),
                child: ListTile(
                  title: Text(snapshot.data![index].name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: snapshot.data![index].category.color,
                  ),
                  trailing: Text(snapshot.data![index].quantity.toString()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
