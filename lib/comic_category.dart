import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'comic_detail.dart';

class ComicCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  // Constructor menerima lemparan data ID & Nama Kategori
  const ComicCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ComicCategoryPage> createState() => _ComicCategoryPageState();
}

class _ComicCategoryPageState extends State<ComicCategoryPage> {
  List _comics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComicsByCategory();
  }

  // Mengambil data komik yang terfilter lewat category_id
  Future<void> _fetchComicsByCategory() async {
    final url = Uri.parse(
      "https://ubaya.cloud/flutter/160423046/comic_category.php?category_id=${widget.categoryId}",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _comics = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _comics = [];
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
          SnackBar(
            content: Text("Gagal memuat komik: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kategori: ${widget.categoryName}"),
        backgroundColor: const Color.fromARGB(255, 103, 58, 183),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 103, 58, 183),
              ),
            )
          : _comics.isEmpty
          ? const Center(child: Text("Tidak ada komik di kategori ini."))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: _comics.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  final comic = _comics[index];
                  final String posterName = comic['poster'] ?? "";

                  return Card(
                    elevation: 3,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              comicId: int.parse(comic['id'].toString()),
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: posterName.isNotEmpty
                                ? Image.asset(
                                    '../lib/images/poster/$posterName.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                          // Judul Komik
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              comic['title'] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
