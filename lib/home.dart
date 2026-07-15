// lib/home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'category.dart';
import 'comic_detail.dart';
import 'search_comic.dart';
import 'create_comic.dart';
import 'edit_profile.dart';
import 'my_comics.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _username = "";
  String _profilePic = "";
  List _comics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchAllComics();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "User";
      _profilePic = prefs.getString('profile_pic') ?? "";
    });
  }

  Future<void> _fetchAllComics() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse("https://ubaya.cloud/flutter/160423046/comics.php");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _comics = data['data'];
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Komiku - Semua Komik"),
        backgroundColor: const Color.fromARGB(255, 103, 58, 183),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllComics,
            tooltip: "Refresh Komik",
          ),
        ],
      ),

      drawer: Drawer(
        child: Column(
          children: [
            // Header Akun User
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 103, 58, 183),
              ),
              accountName: Text(
                _username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: const Text(""),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _profilePic.isNotEmpty
                    ? NetworkImage(
                        'https://ubaya.cloud/flutter/160423046/$_profilePic',
                      )
                    : null,
                child: _profilePic.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: Color.fromARGB(255, 103, 58, 183),
                      )
                    : null,
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.manage_accounts,
                color: Color.fromARGB(255, 103, 58, 183),
              ),
              title: const Text("Edit Profil"),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                );
                if (result == true) {
                  _loadUserData();
                }
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.home,
                color: Color.fromARGB(255, 103, 58, 183),
              ),
              title: const Text("Semua Komik"),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.category,
                color: Color.fromARGB(255, 103, 58, 183),
              ),
              title: const Text("Lihat per Kategori"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.search,
                color: Color.fromARGB(255, 103, 58, 183),
              ),
              title: const Text("Cari Komik"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.add_box, color: Colors.green),
              title: const Text("Bagikan Komik Baru"),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateComicPage(),
                  ),
                );
                if (result == true) {
                  _fetchAllComics();
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.library_books, color: Colors.green),
              title: const Text("Komik Saya"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyComicsPage()),
                );
              },
            ),

            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: _logout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 103, 58, 183),
              ),
            )
          : _comics.isEmpty
          ? const Center(child: Text("Tidak ada komik yang tersedia."))
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
                  final String poster = comic['poster'] ?? "";

                  return Card(
                    elevation: 3,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              comicId: int.parse(comic['id'].toString()),
                            ),
                          ),
                        );
                        _fetchAllComics();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: poster.isNotEmpty
                                ? Image.network(
                                    'https://ubaya.cloud/flutter/160423046/$poster',
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
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  comic['title'] ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.orange,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      "${comic['average_rating'] ?? 0}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
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