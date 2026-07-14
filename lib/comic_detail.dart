import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'read_comic.dart';

class DetailPage extends StatefulWidget {
  final int comicId;
  const DetailPage({super.key, required this.comicId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Map? _comic;
  List _chapters = [];
  List _comments = [];
  bool _isLoading = true;
  int _currentUserId = 0;
  int _selectedRating = 5;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchComicDetail();
  }

  Future<void> _fetchComicDetail() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('user_id') ?? 0;

    final url = Uri.parse(
      "https://ubaya.cloud/flutter/160423046/detail_comic.php?comic_id=${widget.comicId}",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _comic = data['data']['comic'];
            _chapters = data['data']['chapters'];
            _comments = data['data']['comments'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat detail: $e")));
    }
  }

  Future<void> _submitInteraction(String action) async {
    final url = Uri.parse(
      "https://ubaya.cloud/flutter/160423046/add_rating_comment.php",
    );
    Map<String, String> bodyData = {
      "action": action,
      "comic_id": widget.comicId.toString(),
      "user_id": _currentUserId.toString(),
    };

    if (action == 'rate') {
      bodyData['rate'] = _selectedRating.toString();
    } else {
      bodyData['comment'] = _commentController.text;
    }

    try {
      final response = await http.post(url, body: bodyData);
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.green,
          ),
        );
        if (action == 'comment') _commentController.clear();
        _fetchComicDetail();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error eksekusi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    final poster = _comic?['poster'] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text(_comic?['title'] ?? "Detail Komik"),
        backgroundColor: const Color.fromARGB(255, 103, 58, 183),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row Atas: Poster dan Data Informasi Singkat
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 130,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: poster.isNotEmpty
                      ? Image.asset(
                          '../lib/images/poster/$poster.png',
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 50),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _comic?['title'] ?? "",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Genre: ${_comic?['categories'] ?? '-'}",
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${_comic?['average_rating'] ?? 0}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            " (${_comic?['total_ratings'] ?? 0} ulasan)",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              "Sinopsis",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _comic?['description'] ?? "Tidak ada deskripsi.",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const Divider(height: 32),
            const Text(
              "Berikan Ratingmu",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                DropdownButton<int>(
                  value: _selectedRating,
                  items: [1, 2, 3, 4, 5]
                      .map(
                        (val) => DropdownMenuItem(
                          value: val,
                          child: Text("$val Bintang"),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedRating = val!),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _submitInteraction('rate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    "Kirim Rating",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            const Text(
              "Daftar Chapter",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _chapters.isEmpty
                ? const Text(
                    "Belum ada chapter tersedia.",
                    style: TextStyle(color: Colors.grey),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _chapters.length,
                    itemBuilder: (context, idx) {
                      final chapter = _chapters[idx];
                      return ListTile(
                        leading: const Icon(
                          Icons.chrome_reader_mode,
                          color: Colors.deepPurple,
                        ),
                        title: Text("Chapter ${chapter['chapter']}"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReadComicPage(
                                chapterId: chapter['id'], // contoh: 4
                                chapterNum: chapter['chapter'], // contoh: 43
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
            const Divider(height: 32),

            // Komentar Section
            const Text(
              "Komentar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: "Tulis opinimu...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: () => _submitInteraction('comment'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _comments.isEmpty
                ? const Text(
                    "Jadilah yang pertama berkomentar!",
                    style: TextStyle(color: Colors.grey),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    itemBuilder: (context, idx) {
                      final c = _comments[idx];
                      final pPic = c['profile_pic'] ?? "";
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: pPic.isNotEmpty
                              ? AssetImage(
                                  '../lib/images/profile_pic/$pPic.png',
                                )
                              : null,
                          child: pPic.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        title: Text(
                          c['username'] ?? "Anonim",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(c['comment'] ?? ""),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
