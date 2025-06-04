import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/sidebar.dart';
import '../models/place_model.dart';
import '../providers/place_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/responsive.dart';
import '../utils/text_scale.dart';

class PlaceManagementScreen extends StatefulWidget {
  const PlaceManagementScreen({super.key});

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
  final bool _isLoading = false;
  String? _error;
  bool _isSidebarVisible = true;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    // Dispose all controllers
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
        SnackBar(
          content: Text('Place added successfully', style: TextStyle(color: Theme.of(context).colorScheme.onTertiary)),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding place: $e', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset(); // Resets validation state
    imageUrlController.clear();
    titleController.clear();
    descriptionController.clear();
    latController.clear();
    longController.clear();
    setState(() => selectedCategory = "Churches"); // Reset to default category
  }

  Future<void> _deletePlace(String placeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Place', style: Theme.of(context).textTheme.titleLarge),
        content: Text('Are you sure you want to delete this place?', style: Theme.of(context).textTheme.bodyLarge),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<PlaceProvider>().deletePlace(placeId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Place deleted successfully', style: TextStyle(color: Theme.of(context).colorScheme.onTertiary)),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting place: $e', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _editPlace(PlaceModel place) async {
    final editImageUrlController = TextEditingController(text: place.imageUrl);
    final editTitleController = TextEditingController(text: place.title);
    final editDescriptionController = TextEditingController(text: place.description);
    final editLatController = TextEditingController(text: place.lat.toString());
    final editLongController = TextEditingController(text: place.long.toString());
    String editCategory = place.category;

    final formKey = GlobalKey<FormState>(); // Key for the form inside the dialog

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Consistent border radius
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5, // Adjust width as needed
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Place',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Form(
                key: formKey,
                child: SingleChildScrollView( // Ensure content is scrollable if it overflows
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField("Image URL", editImageUrlController, contextForDialog: context), // Pass context for theming
                      const SizedBox(height: 16),
                      _buildTextField("Title", editTitleController, contextForDialog: context),
                      const SizedBox(height: 16),
                      _buildTextField("Description", editDescriptionController, maxLines: 3, contextForDialog: context),
                      const SizedBox(height: 16),
                      StatefulBuilder( // To update DropdownButtonFormField within the dialog
                        builder: (BuildContext context, StateSetter setState) {
                          return DropdownButtonFormField<String>(
                            value: editCategory,
                            items: categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category, style: Theme.of(context).textTheme.bodyLarge),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => editCategory = value);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Category',
                              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                              contextForDialog: context
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              "Longitude",
                              editLongController,
                              keyboardType: TextInputType.number,
                              contextForDialog: context
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
                            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState?.validate() ?? false) {
                                Navigator.pop(context, true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
      )
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
          timestamp: place.timestamp, // Keep original timestamp
        );

        await context.read<PlaceProvider>().updatePlace(updatedPlace);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Place updated successfully', style: TextStyle(color: Theme.of(context).colorScheme.onTertiary)),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating place: $e', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    editImageUrlController.dispose();
    editTitleController.dispose();
    editDescriptionController.dispose();
    editLatController.dispose();
    editLongController.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = !Responsive.isDesktop(context);
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: isSmallScreen ? Sidebar(isVisible: true) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSmallScreen) Sidebar(isVisible: _isSidebarVisible),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isSmallScreen)
                        IconButton(
                          icon: Icon(Icons.menu),
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                        ),
                      if (!isSmallScreen)
                        IconButton(
                          icon: Icon(_isSidebarVisible ? Icons.menu_open : Icons.menu),
                          onPressed: _toggleSidebar,
                        ),
                      Expanded(
                        child: Text(
                          'Place Management',
                          style: TextScale.scale(
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            context,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isSmallScreen ? 200 : 300,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          style: TextScale.scale(
                            Theme.of(context).textTheme.bodyLarge,
                            context,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search places...',
                            hintStyle: TextScale.scale(
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).hintColor
                              ),
                              context,
                            ),
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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: isSmallScreen ? 8 : 12
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 24.0),
                    child: screenWidth < 768
                      ? SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildAddPlaceForm(context),
                              SizedBox(height: 24),
                              Container(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: _buildPlacesList(context),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: screenWidth < 1200 ? 4 : 3,
                              child: SingleChildScrollView(
                                child: _buildAddPlaceForm(context),
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 16 : 24),
                            Expanded(
                              flex: screenWidth < 1200 ? 6 : 7,
                              child: _buildPlacesList(context),
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

  Widget _buildAddPlaceForm(BuildContext context) {
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
        key: _formKey,
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
                  Icon(Icons.add_location_alt, 
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Add New Place",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField("Image URL", imageUrlController),
            const SizedBox(height: 20),
            _buildTextField("Title", titleController),
            const SizedBox(height: 20),
            _buildTextField("Description", descriptionController, maxLines: 3),
            const SizedBox(height: 20),
            _buildCategoryDropdown(context),
            const SizedBox(height: 20),
            _buildLocationFields(context),
            const SizedBox(height: 32),
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType, BuildContext? contextForDialog}) {
    final currentContext = contextForDialog ?? context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(currentContext).textTheme.labelLarge?.copyWith(
            color: Theme.of(currentContext).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: Theme.of(currentContext).textTheme.bodyLarge?.copyWith(
            color: Theme.of(currentContext).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(currentContext).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(currentContext).colorScheme.outline.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(currentContext).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(currentContext).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(currentContext).colorScheme.error,
              ),
            ),
            hintStyle: TextStyle(
              color: Theme.of(currentContext).colorScheme.onSurface.withOpacity(0.5),
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

  Widget _buildCategoryDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedCategory,
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(
                category,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => selectedCategory = value);
            }
          },
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
          ),
          icon: Icon(
            Icons.arrow_drop_down_circle_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
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

  Widget _buildLocationFields(BuildContext context) { // Accept BuildContext
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

  Widget _buildSubmitButton(BuildContext context) { // Accept BuildContext
    return Container(
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
        onPressed: _addPlace,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt, 
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              "Add Place",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacesList(BuildContext context) {
    return Consumer<PlaceProvider>(
      builder: (context, provider, child) {
        var places = provider.places;

        if (_searchQuery.isNotEmpty) {
          places = places.where((place) {
            return place.title.toLowerCase().contains(_searchQuery) ||
                   place.category.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.place,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Places List",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${places.length} Places',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                            ? 'No places added yet'
                            : 'No places found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                        Divider(height: 1, color: Theme.of(context).dividerColor),
                    itemBuilder: (context, index) {
                      final place = places[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).shadowColor.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                place.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.image,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      size: 32,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${place.lat}, ${place.long}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.tertiary,
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
                                place.description,
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
                                  onPressed: () => _editPlace(place),
                                  tooltip: 'Edit place',
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
                                  onPressed: () => _deletePlace(place.id),
                                  tooltip: 'Delete place',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
