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
  const UploadARObjectScreen({super.key});

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
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
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
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.view_in_ar,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Add New AR Object",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField("Title", _titleController),
            const SizedBox(height: 20),
            _buildTextField("Description", _descriptionController, maxLines: 3),
            const SizedBox(height: 20),
            _buildLocationFields(),
            const SizedBox(height: 32),
            _buildFileUploadSection(),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 0,
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isUploading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    else
                      Icon(Icons.cloud_upload),
                    const SizedBox(width: 8),
                    Text(_isUploading ? "Uploading..." : "Upload AR Object"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3D Model File',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (_fileName != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Selected File: $_fileName",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _pickFile,
          icon: Icon(
            Icons.upload_file_outlined,
            size: 20,
          ),
          label: Text(_fileName == null ? 'Select .glb File' : 'Change File'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
            foregroundColor: Theme.of(context).colorScheme.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.view_in_ar,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "AR Objects List",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ar_objects').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.view_in_ar_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _arSearchQuery.isEmpty 
                            ? "No AR Objects uploaded yet"
                            : "No AR Objects found",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_arSearchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Try adjusting your search",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final filteredDocs = _arSearchQuery.isEmpty
                    ? docs
                    : docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title']?.toString().toLowerCase() ?? '';
                        return title.contains(_arSearchQuery);
                      }).toList();

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    indent: 24,
                    endIndent: 24,
                  ),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Untitled';
                    final description = data['description'] ?? 'No description';
                    final latitude = data['latitude']?.toString() ?? '';
                    final longitude = data['longitude']?.toString() ?? '';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.view_in_ar,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$latitude, $longitude',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                color: Theme.of(context).colorScheme.primary,
                                onPressed: () => _editARObject(doc.id, data),
                                tooltip: 'Edit AR object',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Theme.of(context).colorScheme.error,
                                onPressed: () => _deleteARObject(doc.id),
                                tooltip: 'Delete AR object',
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Future<void> _editARObject(String id, Map<String, dynamic> data) async {
    // Create temporary controllers for the modal form
    final titleController = TextEditingController(text: data['title'] ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');
    final latController = TextEditingController(text: data['latitude']?.toString() ?? '');
    final longController = TextEditingController(text: data['longitude']?.toString() ?? '');
    
    Uint8List? newFileBytes;
    String? newFileName;
    final existingFileUrl = data['file_url'];

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Edit AR Object',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField("Title", titleController),
              const SizedBox(height: 16),
              _buildTextField("Description", descriptionController, maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField("Latitude", latController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("Longitude", longController)),
                ],
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (newFileName != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Selected File: $newFileName",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['glb'],
                          withData: true,
                        );

                        if (result != null) {
                          setState(() {
                            newFileBytes = result.files.single.bytes;
                            newFileName = result.files.single.name;
                          });
                        }
                      },
                      icon: Icon(Icons.file_upload_outlined, size: 20),
                      label: Text(newFileName == null ? 'Select New .glb File' : 'Change File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
                        foregroundColor: Theme.of(context).colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'title': titleController.text,
              'description': descriptionController.text,
              'latitude': latController.text,
              'longitude': longController.text,
              'fileBytes': newFileBytes,
              'fileName': newFileName,
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    // Clean up the temporary controllers
    titleController.dispose();
    descriptionController.dispose();
    latController.dispose();
    longController.dispose();

    if (result != null) {
      try {
        setState(() => _isUploading = true);

        // If a new file was picked, upload it
        final fileUrl = result['fileBytes'] != null
            ? await _uploadFileBytes(result['fileBytes'], result['fileName'])
            : existingFileUrl;

        // Update the document in Firestore
        await FirebaseFirestore.instance.collection('ar_objects').doc(id).update({
          'title': result['title'],
          'description': result['description'],
          'latitude': double.parse(result['latitude']),
          'longitude': double.parse(result['longitude']),
          'file_url': fileUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AR Object updated successfully!', style: TextStyle(color: Theme.of(context).colorScheme.onTertiary)),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating AR Object: $e', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deleteARObject(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text(
              'Delete AR Object',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this AR object? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('ar_objects').doc(id).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AR Object deleted successfully!', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting AR Object: $e', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<String> _uploadFileBytes(Uint8List fileBytes, String fileName) async {
    final uri = Uri.parse(cloudinaryUrl);
    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonResponse = json.decode(responseData);

    final fileUrl = jsonResponse['secure_url'];

    if (fileUrl == null) throw Exception("No file URL returned");

    return fileUrl;
  }
}
