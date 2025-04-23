import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/sidebar.dart';
import '../models/place_model.dart';
import '../providers/place_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceManagementScreen extends StatefulWidget {
  const PlaceManagementScreen({Key? key}) : super(key: key);

  @override
  _PlaceManagementScreenState createState() => _PlaceManagementScreenState();
}

class _PlaceManagementScreenState extends State<PlaceManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController latController = TextEditingController();
  final TextEditingController longController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  String selectedCategory = "Churches";
  final List<String> categories = ["Churches", "Historical", "Restaurants", "Hotels"];

  @override
  void initState() {
    super.initState();
    // Fetch places when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaceProvider>().fetchPlaces();
    });
  }

  @override
  void dispose() {
    imageUrlController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    latController.dispose();
    longController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addPlace() async {
    if (!_formKey.currentState!.validate()) return;

    final place = PlaceModel(
      id: '', // Will be set by Firestore
      imageUrl: imageUrlController.text,
      title: titleController.text,
      description: descriptionController.text,
      category: selectedCategory,
      lat: latController.text,
      long: longController.text,
      likes: 0,
      likedBy: [],
      timestamp: DateTime.now(),
    );

    try {
      await context.read<PlaceProvider>().addPlace(place);
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Place added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding place: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    imageUrlController.clear();
    titleController.clear();
    descriptionController.clear();
    latController.clear();
    longController.clear();
    setState(() => selectedCategory = "Churches");
  }

  Future<void> _deletePlace(String placeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Place'),
        content: const Text('Are you sure you want to delete this place?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<PlaceProvider>().deletePlace(placeId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Place deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting place: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editPlace(PlaceModel place) async {
    // Create temporary controllers with existing values
    final editImageUrlController = TextEditingController(text: place.imageUrl);
    final editTitleController = TextEditingController(text: place.title);
    final editDescriptionController = TextEditingController(text: place.description);
    final editLatController = TextEditingController(text: place.lat.toString());
    final editLongController = TextEditingController(text: place.long.toString());
    String editCategory = place.category;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Edit Place',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextField("Image URL", editImageUrlController),
                        const SizedBox(height: 16),
                        _buildTextField("Title", editTitleController),
                        const SizedBox(height: 16),
                        _buildTextField("Description", editDescriptionController, maxLines: 3),
                        const SizedBox(height: 16),
                        StatefulBuilder(
                          builder: (context, setState) {
                            return DropdownButtonFormField<String>(
                              value: editCategory,
                              items: categories.map((category) {
                                return DropdownMenuItem(value: category, child: Text(category));
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => editCategory = value);
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Category',
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[200]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[200]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.blue[400]!),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                "Latitude",
                                editLatController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                "Longitude",
                                editLongController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState?.validate() ?? false) {
                                  Navigator.pop(context, true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Save Changes'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      try {
        final updatedPlace = PlaceModel(
          id: place.id,
          imageUrl: editImageUrlController.text,
          title: editTitleController.text,
          description: editDescriptionController.text,
          category: editCategory,
          lat: editLatController.text,
          long: editLongController.text,
          likes: place.likes,
          likedBy: place.likedBy,
          timestamp: place.timestamp,
        );

        await context.read<PlaceProvider>().updatePlace(updatedPlace);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Place updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating place: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Clean up controllers
    editImageUrlController.dispose();
    editTitleController.dispose();
    editDescriptionController.dispose();
    editLatController.dispose();
    editLongController.dispose();
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
                        'Place Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        width: 300,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search places...',
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
                            child: _buildAddPlaceForm(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 7,
                          child: Consumer<PlaceProvider>(
                            builder: (context, provider, child) {
                              var places = provider.places;
                              
                              // Filter places based on search query
                              if (_searchQuery.isNotEmpty) {
                                places = places.where((place) {
                                  return place.title.toLowerCase().contains(_searchQuery) ||
                                         place.category.toLowerCase().contains(_searchQuery);
                                }).toList();
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Icon(Icons.place, color: Colors.blue[600], size: 20),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                "Places List",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${places.length} Places',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(height: 1, color: Colors.grey[200]),
                                    if (places.isEmpty)
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.place_outlined,
                                                size: 48,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                _searchQuery.isEmpty 
                                                  ? 'No places added yet'
                                                  : 'No places found',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (_searchQuery.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Try adjusting your search',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      Expanded(
                                        child: ListView.separated(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          itemCount: places.length,
                                          separatorBuilder: (context, index) => 
                                              Divider(height: 1, color: Colors.grey[200]),
                                          itemBuilder: (context, index) {
                                            final place = places[index];
                                            return ListTile(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              leading: ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Image.network(
                                                  place.imageUrl,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: Colors.grey[100],
                                                      child: Icon(Icons.image, color: Colors.grey[400]),
                                                    );
                                                  },
                                                ),
                                              ),
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      place.title,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${place.lat}, ${place.long}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    place.description,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue[50],
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          place.category,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.blue[700],
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Icon(Icons.favorite, size: 14, color: Colors.red[400]),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${place.likes}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.edit_outlined, color: Colors.blue[600]),
                                                    onPressed: () => _editPlace(place),
                                                    tooltip: 'Edit place',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                    onPressed: () => _deletePlace(place.id),
                                                    tooltip: 'Delete place',
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
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

  Widget _buildAddPlaceForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.add_location, color: Colors.blue[600], size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "Add New Place",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField("Image URL", imageUrlController),
            const SizedBox(height: 16),
            _buildTextField("Title", titleController),
            const SizedBox(height: 16),
            _buildTextField("Description", descriptionController, maxLines: 3),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 16),
            _buildLocationFields(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
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

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedCategory,
          items: categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => selectedCategory = value);
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
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
        Expanded(
          child: _buildTextField(
            "Latitude",
            latController,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTextField(
            "Longitude",
            longController,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _addPlace,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          "Add Place",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
