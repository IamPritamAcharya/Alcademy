import 'package:flutter/material.dart';

class SearchBar1 extends StatelessWidget {
  final Function(String) onSearch;

  const SearchBar1({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search amenities...',
          hintStyle:
              TextStyle(fontFamily: 'ProductSans', color: Colors.white54),
          prefixIcon: Icon(Icons.search, color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.white54),
          ),
          filled: true,
          fillColor: const Color(0xFF1A1D1E),
        ),
        style: TextStyle(fontFamily: 'ProductSans', color: Colors.white),
        onChanged: onSearch,
      ),
    );
  }
}
