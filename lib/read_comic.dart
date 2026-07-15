import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReadComicPage extends StatefulWidget {
  final int chapterId;
  final int chapterNum;

  const ReadComicPage({
    super.key,
    required this.chapterId,
    required this.chapterNum,
  });

  @override
  State<ReadComicPage> createState() => _ReadComicPageState();
}

class _ReadComicPageState extends State<ReadComicPage> {
  List _pages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComicPages();
  }

  Future<void> _fetchComicPages() async {
    final url = Uri.parse(
      "https://ubaya.cloud/flutter/160423046/read_comic.php?chapter_id=${widget.chapterId}",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _pages = data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat halaman: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 480
            ? 480.0
            : constraints.maxWidth;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                    title: Text("Chapter ${widget.chapterNum}"),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  body: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.deepPurple,
                          ),
                        )
                      : _pages.isEmpty
                      ? const Center(
                          child: Text(
                            "Belum ada halaman di chapter ini.",
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _pages.length,
                          itemBuilder: (context, index) {
                            final String page = _pages[index]['page'];

                            return Image.network(
                              'https://ubaya.cloud/flutter/160423046/$page',
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 250,
                                  color: Colors.grey[900],
                                  child: const Center(
                                    child: Text(
                                      "Gambar tidak dapat dimuat.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
