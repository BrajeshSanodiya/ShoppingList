
import 'package:flutter/material.dart';
import 'package:grocery_snap/data/categories.dart';
import 'package:grocery_snap/models/category.dart';
import 'package:grocery_snap/models/grocery_item.dart';

class AddGrocery extends StatefulWidget {
  const AddGrocery({super.key});

  @override
  State<AddGrocery> createState() {
    return _AddGroceryState();
  }
}

class _AddGroceryState extends State<AddGrocery> {
  final _formKey = GlobalKey<FormState>();

  var _enterName = '';
  var _enterQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;

  void _saveItem() {
    _formKey.currentState!.validate();
    _formKey.currentState!.save();
    // final url = Uri.https('grocerysnap-com-default-rtdb.asia-southeast1.firebasedatabase.app','shopping-list.json');


    // http.post(url, headers:{
    //   'Content-Type':'applicaton/json'
    // }, body: json.encode({
    //   'name':_enterName,
    //   'quantity':_enterQuantity,
    //   'category':_selectedCategory.name
    // }));

    Navigator.of(context).pop(
      GroceryItem(
        id: DateTime.now().toString(),
        name: _enterName,
        quantity: _enterQuantity,
        category: _selectedCategory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Grocery")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
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
                            int.tryParse(value)! <= 1) {
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
                    onPressed: () {
                      if (_formKey.currentState != null) {
                        _formKey.currentState!.reset();
                        _selectedCategory = categories[Categories.vegetables]!;
                      }
                    },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(onPressed: _saveItem, child: Text('Add Item')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
