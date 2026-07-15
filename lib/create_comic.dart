import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateComicPage extends StatefulWidget {
  const CreateComicPage({super.key});

  @override
  State<CreateComicPage> createState() => _CreateComicPageState();
}

class _CreateComicPageState extends State<CreateComicPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  List _categories = [];
  final Set<int> _selectedCategories = {};

  Uint8List? _posterBytes;
  final List<Uint8List> _pageBytes = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final url = Uri.parse(
      "https://ubaya.cloud/flutter/160423046/categories.php",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _categories = data['data'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat kategori: $e")),
        );
      }
    }
  }

  void _showPicker(bool forPoster) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  _pickImage(ImageSource.gallery, forPoster);
                  Navigator.of(bc).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  _pickImage(ImageSource.camera, forPoster);
                  Navigator.of(bc).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, bool forPoster) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1080,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (forPoster) {
          _posterBytes = bytes;
        } else {
          _pageBytes.add(bytes);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_posterBytes == null) {
      _showMessage("Poster harus dipilih.");
      return;
    }
    if (_selectedCategories.isEmpty) {
      _showMessage("Pilih minimal satu kategori.");
      return;
    }
    if (_pageBytes.isEmpty) {
      _showMessage("Upload minimal satu halaman.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;

      final createResp = await http.post(
        Uri.parse("https://ubaya.cloud/flutter/160423046/create_comic.php"),
        body: {
          "title": _titleController.text.trim(),
          "description": _descController.text.trim(),
          "categories": _selectedCategories.join(","),
          "poster": base64Encode(_posterBytes!),
          "user_id": userId.toString(),
        },
      );

      final data = jsonDecode(createResp.body);
      if (data['status'] != 'success') {
        _showMessage(data['message'] ?? "Gagal membuat komik.");
        setState(() => _isLoading = false);
        return;
      }

      final chapterId = data['data']['chapter_id'].toString();
      for (int i = 0; i < _pageBytes.length; i++) {
        await http.post(
          Uri.parse("https://ubaya.cloud/flutter/160423046/add_page.php"),
          body: {
            "chapter_id": chapterId,
            "page": (i + 1).toString(),
            "image": base64Encode(_pageBytes[i]),
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Komik berhasil dibagikan!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showMessage("Terjadi kesalahan: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Komik Baru"),
        backgroundColor: const Color.fromARGB(255, 103, 58, 183),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Judul Komik",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Judul harus diisi";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "Deskripsi",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                keyboardType: TextInputType.multiline,
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 20),

              const Text(
                "Poster",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _posterBytes != null
                  ? Image.memory(_posterBytes!, height: 200)
                  : Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showPicker(true),
                icon: const Icon(Icons.upload),
                label: const Text("Pilih Poster"),
              ),
              const SizedBox(height: 20),

              const Text(
                "Kategori",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                children: _categories.map((cat) {
                  final id = int.parse(cat['id'].toString());
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _selectedCategories.contains(id),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedCategories.add(id);
                            } else {
                              _selectedCategories.remove(id);
                            }
                          });
                        },
                      ),
                      Text(cat['nama']),
                      const SizedBox(width: 12),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Text(
                "Halaman Komik (${_pageBytes.length})",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_pageBytes.isNotEmpty)
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pageBytes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Image.memory(_pageBytes[index], height: 140),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () {
                                setState(() => _pageBytes.removeAt(index));
                              },
                              child: Container(
                                color: Colors.black54,
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showPicker(false),
                icon: const Icon(Icons.collections),
                label: const Text("Tambah Halaman"),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "BAGIKAN KOMIK",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}