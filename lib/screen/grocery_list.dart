import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grocery_snap/screen/add_grocery.dart';
import 'package:grocery_snap/data/categories.dart';
import 'package:grocery_snap/models/grocery_item.dart';
import 'package:grocery_snap/screen/edit_grocery.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    _isLoading = true;
    final url = Uri.https(
      'grocerysnap-com-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list.json',
    );
    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = "Failed to fetch data. Please try again later.";
        });
        return;
      }
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
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
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = "Something went wrong here. Please try again later.";
      });
    }
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

  void callEditButton(int itemIndex, GroceryItem editItem) async {
    final Map<String, dynamic> updatedValue = await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (ctx) => EditGrocery(
              index: itemIndex,
              item: editItem,
              removeItem: _removeItem,
            ),
      ),
    );

    if (!updatedValue.containsKey('index') ||
        !updatedValue.containsKey('item')) {
      return;
    }

    final int index = updatedValue['index'];
    final GroceryItem item = updatedValue['item'];
    final List<GroceryItem> updatedList = [];
    for (var i = 0; i < _groceryItems.length; i++) {
      if (i == index) {
        updatedList.add(item);
      } else {
        updatedList.add(_groceryItems[i]);
      }
    }

    setState(() {
      _groceryItems = updatedList;
    });
  }

  void _undoDelete(int index, GroceryItem item) async {
    final url = Uri.https(
      'grocerysnap-com-default-rtdb.asia-southeast1.firebasedatabase.app',
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
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> resData = json.decode(response.body);
      setState(() {
        _groceryItems.insert(
          index,
          GroceryItem(
            id: resData['name'],
            name: item.name,
            quantity: item.quantity,
            category: item.category,
          ),
        );
      });
    } catch (error) {
      setState(() {
        _error = "Something went wrong here. Please try again later.";
      });
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
    print(url);
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
      setState(() {
        _error = "Something went wrong here. Please try again later.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet.'));
    if (_isLoading == true) {
      content = const Center(child: CircularProgressIndicator());
    }
    if (_groceryItems.isNotEmpty) {
      content = ListView.separated(
        itemCount: _groceryItems.length,
        separatorBuilder: (context, index) {
          return Divider();
        },
        itemBuilder: (context, index) {
          return Dismissible(
            background: Container(
              color: Theme.of(context).colorScheme.error.withAlpha(180),
            ),
            onDismissed: (direction) {
              _removeItem(_groceryItems[index]);
            },
            key: ValueKey(_groceryItems[index].id),
            child: ListTile(
              onTap: () {
                callEditButton(index, _groceryItems[index]);
              },
              title: Text(_groceryItems[index].name),
              leading: Container(
                width: 24,
                height: 24,
                color: _groceryItems[index].category.color,
              ),
              trailing: Text(_groceryItems[index].quantity.toString()),
            ),
          );
        },
      );
    }
    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Your Groceries"),
        actions: [IconButton(onPressed: callAddButton, icon: Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
