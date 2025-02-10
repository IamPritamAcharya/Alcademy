import 'package:flutter/material.dart';
import 'package:port/pages/amenities/amenities_list.dart';
import 'package:port/pages/amenities/pagination_controls.dart';
import 'package:port/pages/amenities/search_bar.dart';
import 'package:port/pages/amenities/tag_filter_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AmenitiesPage extends StatefulWidget {
  @override
  _AmenitiesPageState createState() => _AmenitiesPageState();
}

class _AmenitiesPageState extends State<AmenitiesPage> {
  late Future<void> _dataFuture;
  List<dynamic> _allAmenities = [];
  List<dynamic> _filteredAmenities = [];
  List<String> _tags = [];
  int _currentPage = 1;
  int _itemsPerPage = 10;
  String _searchQuery = '';
  String _selectedTag = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dataFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString('amenities_data');

      if (cachedData != null) {
        _parseAmenities(json.decode(cachedData));
      } else {
        await _fetchAndCacheAmenities();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Initialization Error: $e');
    }
  }

  Future<void> _fetchAndCacheAmenities() async {
    final url =
        'https://raw.githubusercontent.com/Academia-IGIT/DATA_hub/main/amenities.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('amenities_data', json.encode(data));
        _parseAmenities(data);
      } else {
        debugPrint('Error: Failed to load data');
        throw Exception('Failed to load data');
      }
    } catch (e) {
      debugPrint('Fetch Error: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  void _parseAmenities(dynamic data) {
    try {
      final amenities = (data as List).map((item) {
        return {
          'name': item['name'] ?? 'Unknown',
          'tag': item['tag'] ?? 'Unknown',
          'images': (item['images'] as List<dynamic>? ?? []).cast<String>(),
          'description': item['description'] ?? '',
        };
      }).toList();

      setState(() {
        _allAmenities = amenities;
        _filteredAmenities = List.from(amenities);
        _tags = amenities.map((e) => e['tag'] as String).toSet().toList();
      });
    } catch (e) {
      debugPrint('Parsing Error: $e');
      throw Exception('Error parsing data: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredAmenities = _allAmenities
          .where((item) =>
              (_selectedTag.isEmpty ||
                  item['tag']
                      .toLowerCase()
                      .contains(_selectedTag.toLowerCase())) &&
              (item['name']
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  item['tag']
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())))
          .toList();
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        title: const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1D1E),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (_filteredAmenities.isEmpty) {
            return const Center(
              child: Text(
                'No amenities found.',
                style: TextStyle(color: Colors.white),
              ),
            );
          } else {
            final totalPages =
                (_filteredAmenities.length / _itemsPerPage).ceil();
            final paginatedAmenities = _filteredAmenities
                .skip((_currentPage - 1) * _itemsPerPage)
                .take(_itemsPerPage)
                .toList();

            return SingleChildScrollView(
              child: Column(
                children: [
                  SearchBar1(
                    onSearch: (query) {
                      setState(() {
                        _searchQuery = query;
                        _applyFilters();
                      });
                    },
                  ),
                  TagFilterBar(
                    tags: _tags,
                    selectedTag: _selectedTag,
                    onTagSelected: (tag) {
                      setState(() {
                        _selectedTag = tag;
                        _applyFilters();
                      });
                    },
                  ),
                  AmenitiesList(items: paginatedAmenities),
                  PaginationControls(
                    currentPage: _currentPage,
                    totalPages: totalPages,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
