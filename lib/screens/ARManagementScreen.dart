import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../components/sidebar.dart';
import 'dart:typed_data';

class UploadARObjectScreen extends StatefulWidget {
  @override
  _UploadARObjectScreenState createState() => _UploadARObjectScreenState();
}

class _UploadARObjectScreenState extends State<UploadARObjectScreen> {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _filePath;
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isUploading = false;

  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/ds8esjc0y/raw/upload";
  final String uploadPreset = "flutter_upload";

  Future<void> _pickFile() async {
    setState(() => _isUploading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['glb'],
        withData: kIsWeb,
      );

      if (result != null) {
        setState(() {
          _fileName = result.files.single.name;
          if (kIsWeb) {
            _fileBytes = result.files.single.bytes;
            _filePath = null;
          } else {
            _filePath = result.files.single.path;
            _fileBytes = null;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadFile() async {
    if ((_filePath == null && _fileBytes == null) ||
        _latController.text.isEmpty ||
        _longController.text.isEmpty ||
        _titleController.text.isEmpty ||
        _fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide all required information')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uri = Uri.parse(cloudinaryUrl);
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _fileBytes!,
          filename: _fileName,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _filePath!,
        ));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      final fileUrl = jsonResponse['secure_url'];

      if (fileUrl == null) throw Exception("No file URL returned");

      await FirebaseFirestore.instance.collection('ar_objects').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'latitude': double.parse(_latController.text),
        'longitude': double.parse(_longController.text),
        'file_url': fileUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload successful!'), backgroundColor: Colors.green),
      );

      setState(() {
        _latController.clear();
        _longController.clear();
        _titleController.clear();
        _descriptionController.clear();
        _filePath = null;
        _fileBytes = null;
        _fileName = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Sidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AR Objects Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        width: 300,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search AR objects...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue[400]!),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            child: _buildUploadForm(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 7,
                          child: _buildRecentARObjectsList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Upload New 3D Object",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            _buildTextField("Title", _titleController),
            const SizedBox(height: 16),
            _buildTextField("Description", _descriptionController, maxLines: 3),
            const SizedBox(height: 16),
            _buildLocationFields(),
            const SizedBox(height: 24),
            if (_fileName != null)
              Text("Selected File: $_fileName", style: TextStyle(color: Colors.blue)),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: Icon(Icons.upload_file),
              label: Text('Select .glb File'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadFile,
              icon: _isUploading
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.cloud_upload),
              label: Text(_isUploading ? "Uploading..." : "Upload AR Object"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildLocationFields() {
    return Row(
      children: [
        Expanded(child: _buildTextField("Latitude", _latController)),
        SizedBox(width: 10),
        Expanded(child: _buildTextField("Longitude", _longController)),
      ],
    );
  }

  Widget _buildRecentARObjectsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ar_objects').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text("No AR Objects yet"));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['title'] ?? 'Untitled'),
              subtitle: Text("${data['latitude']}, ${data['longitude']}"),
              leading: Icon(Icons.view_in_ar),
            );
          },
        );
      },
    );
  }
}
