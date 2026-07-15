import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditComicPage extends StatefulWidget {
  final int comicId;
  const EditComicPage({super.key, required this.comicId});

  @override
  State<EditComicPage> createState() => _EditComicPageState();
}

class _EditComicPageState extends State<EditComicPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  List _categories = [];
  final Set<int> _selectedCategories = {};

  String _currentPoster = "";
  Uint8List? _newPosterBytes;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final catResp = await http.get(
        Uri.parse("https://ubaya.cloud/flutter/160423046/categories.php"),
      );
      final catData = jsonDecode(catResp.body);
      if (catData['status'] == 'success') {
        _categories = catData['data'];
      }

      final detailResp = await http.get(
        Uri.parse(
          "https://ubaya.cloud/flutter/160423046/detail_comic.php?comic_id=${widget.comicId}",
        ),
      );
      final detailData = jsonDecode(detailResp.body);
      if (detailData['status'] == 'success') {
        final comic = detailData['data']['comic'];
        _titleController.text = comic['title'] ?? "";
        _descController.text = comic['description'] ?? "";
        _currentPoster = comic['poster'] ?? "";
        for (var id in (comic['category_ids'] ?? [])) {
          _selectedCategories.add(int.parse(id.toString()));
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage("Gagal memuat data: $e");
    }
  }

  void _showPicker() {
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
                  _pickImage(ImageSource.gallery);
                  Navigator.of(bc).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(bc).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1080,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _newPosterBytes = bytes);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      _showMessage("Pilih minimal satu kategori.");
      return;
    }

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;

      final response = await http.post(
        Uri.parse("https://ubaya.cloud/flutter/160423046/update_comic.php"),
        body: {
          "comic_id": widget.comicId.toString(),
          "user_id": userId.toString(),
          "title": _titleController.text.trim(),
          "description": _descController.text.trim(),
          "categories": _selectedCategories.join(","),
          "poster": _newPosterBytes != null ? base64Encode(_newPosterBytes!) : "",
        },
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showMessage(data['message'] ?? "Gagal memperbarui komik.");
        setState(() => _isSaving = false);
      }
    } catch (e) {
      _showMessage("Terjadi kesalahan: $e");
      setState(() => _isSaving = false);
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
        title: const Text("Edit Komik"),
        backgroundColor: const Color.fromARGB(255, 103, 58, 183),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 103, 58, 183),
              ),
            )
          : SingleChildScrollView(
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _newPosterBytes != null
                        ? Image.memory(_newPosterBytes!, height: 200)
                        : _currentPoster.isNotEmpty
                        ? Image.network(
                            "https://ubaya.cloud/flutter/160423046/$_currentPoster",
                            height: 200,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
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
                      onPressed: _showPicker,
                      icon: const Icon(Icons.upload),
                      label: const Text("Ganti Poster"),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Kategori",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "SIMPAN PERUBAHAN",
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