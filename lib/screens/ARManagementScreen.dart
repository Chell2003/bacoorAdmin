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
  // Search controller for AR objects list (optional, but good for consistency)
  final TextEditingController _arSearchController = TextEditingController();
  String _arSearchQuery = '';


  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/ds8esjc0y/raw/upload";
  final String uploadPreset = "flutter_upload";

  Future<void> _pickFile() async {
    setState(() => _isUploading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['glb'], // Ensure only .glb files are selectable
        withData: kIsWeb, // Necessary for web to get bytes directly
      );

      if (result != null) {
        setState(() {
          _fileName = result.files.single.name;
          if (kIsWeb) {
            _fileBytes = result.files.single.bytes; // Store bytes for web
            _filePath = null; // Not applicable for web
          } else {
            _filePath = result.files.single.path; // Store path for mobile/desktop
            _fileBytes = null; // Not applicable here
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
        SnackBar(
          content: Text('Please provide all required information', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        ),
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
        'userId': FirebaseAuth.instance.currentUser?.uid, // Store user ID for ownership/filtering
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload successful!', style: TextStyle(color: Theme.of(context).colorScheme.onTertiary)),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
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
        SnackBar(
          content: Text('Upload failed: $e', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _longController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _arSearchController.dispose(); // Dispose the new search controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        style: Theme.of(context).textTheme.headline5?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        width: 300,
                        child: TextField(
                          controller: _arSearchController,
                          onChanged: (value) {
                            setState(() {
                              _arSearchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search AR objects...',
                            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).hintColor),
                            prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Form( // Assuming you might want validation later, so Form is good.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Upload New 3D Object",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            _buildTextField("Title", _titleController),
            const SizedBox(height: 16),
            _buildTextField("Description", _descriptionController, maxLines: 3),
            const SizedBox(height: 16),
            _buildLocationFields(),
            const SizedBox(height: 24),
            if (_fileName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "Selected File: $_fileName",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: Icon(Icons.upload_file, size: 20),
              label: Text('Select .glb File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadFile,
              icon: _isUploading
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                  : Icon(Icons.cloud_upload, size: 20),
              label: Text(_isUploading ? "Uploading..." : "Upload AR Object"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(48), // Ensure it spans width
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
          // Add validator if needed
        ),
      ],
    );
  }

  Widget _buildLocationFields() {
    return Row(
      children: [
        Expanded(child: _buildTextField("Latitude", _latController)),
        const SizedBox(width: 16), // Consistent spacing
        Expanded(child: _buildTextField("Longitude", _longController)),
      ],
    );
  }

  Widget _buildRecentARObjectsList() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), // Consistent padding
            child: Text(
              "Uploaded AR Objects",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ar_objects').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "No AR Objects yet",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  );
                }
                final docs = snapshot.data!.docs;
                // Apply search filter if query is not empty
                final filteredDocs = _arSearchQuery.isEmpty
                    ? docs
                    : docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title']?.toString().toLowerCase() ?? '';
                        return title.contains(_arSearchQuery);
                      }).toList();

                if (filteredDocs.isEmpty && _arSearchQuery.isNotEmpty) {
                   return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "No AR Objects found for '$_arSearchQuery'",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }


                return ListView.builder( // Changed to ListView.builder as per existing structure
                  padding: const EdgeInsets.symmetric(vertical: 8), // Padding for the list
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    return Column( // Wrap ListTile and Divider
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Consistent padding
                          leading: Icon(Icons.view_in_ar, color: Theme.of(context).colorScheme.primary, size: 28),
                          title: Text(
                            data['title'] ?? 'Untitled',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                          ),
                          subtitle: Text(
                            "${data['latitude']}, ${data['longitude']}",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          // Optional: Add trailing delete/edit icons if needed in future
                        ),
                        if (index < filteredDocs.length -1) // Add divider for all but last item
                           Divider(height: 1, color: Theme.of(context).dividerColor, indent: 16, endIndent: 16),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
