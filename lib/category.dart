import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'comic_category.dart'; // Import halaman list komik tujuan

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Mengambil daftar kategori dari database ubaya.cloud
  Future<void> _fetchCategories() async {
    final url = Uri.parse("https://ubaya.cloud/flutter/160423046/categories.php");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _categories = data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat kategori: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Kategori Komik"),
        backgroundColor: const Color.fromARGB(255, 103, 58, 183),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 103, 58, 183)))
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3, // Proporsi kotak kartu kategori
                ),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.deepPurple.shade50,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // Navigasi ke ComicListPage membawa data id dan nama kategori yang diklik
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ComicCategoryPage(
                              categoryId: int.parse(cat['id'].toString()),
                              categoryName: cat['nama'],
                            ),
                          ),
                        );
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.collections_bookmark, size: 40, color: Color.fromARGB(255, 103, 58, 183)),
                            const SizedBox(height: 8),
                            Text(
                              cat['nama'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 103, 58, 183),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}