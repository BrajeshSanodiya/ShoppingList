import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grocery_snap/data/categories.dart';
import 'package:grocery_snap/models/category.dart';
import 'package:grocery_snap/models/grocery_item.dart';
import 'package:http/http.dart' as http;

class EditGrocery extends StatefulWidget {
  const EditGrocery({super.key, required this.item, required this.index, required this.removeItem(GroceryItem item)});

  final GroceryItem item;
  final int index;
  final void Function(GroceryItem item) removeItem;

  @override
  State<EditGrocery> createState() {
    return _EditGroceryState();
  }
}

class _EditGroceryState extends State<EditGrocery> {
  final _formKey = GlobalKey<FormState>();
  var _isSending = false;

  var _enterName = '';
  var _enterQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;

  @override
  void initState() {
    super.initState();
    _enterName = widget.item.name;
    _enterQuantity = widget.item.quantity;
    _selectedCategory = widget.item.category;
  }

  void _updateItem() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isSending = true;
    });

    final url = Uri.https(
      'grocerysnap-com-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shopping-list/${widget.item.id}.json',
    );

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'applicaton/json'},
      body: json.encode({
        'name': _enterName,
        'quantity': _enterQuantity,
        'category': _selectedCategory.name,
      }),
    );

    final Map<String, dynamic> resData = json.decode(response.body);

    if (!context.mounted) {
      return;
    }
    final Map<String, dynamic> returnValue={
      'index': widget.index,
      'item' : GroceryItem(
        id: resData['name'],
        name: _enterName,
        quantity: _enterQuantity,
        category: _selectedCategory,
      ),
      };
    
    Navigator.of(context).pop( returnValue );
  }




  @override
  Widget build(BuildContext context) {
  
    return Scaffold(
      appBar: AppBar(title: Text("Edit Grocery")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                initialValue: _enterName,
                decoration: const InputDecoration(label: Text('Name')),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Must be between 1 and 50 chracters';
                  }
                  return null;
                },
                onSaved: (newValue) {
                  _enterName = newValue!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text('Quantitiy'),
                      ),
                      initialValue: _enterQuantity.toString(),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! < 1) {
                          return 'Must enter valid, positive number';
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        _enterQuantity = int.parse(newValue!);
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(width: 6),
                                Text(category.value.name),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: (){
                      Navigator.of(context).pop();
                      widget.removeItem(widget.item);
                    },
                    child: const Text('Delete'),
                  ),
                  ElevatedButton(
                    onPressed: _isSending ? null : _updateItem,
                    child:
                        _isSending
                            ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(),
                            )
                            : const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
