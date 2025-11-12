import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/color_extractor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _currentImageUrl;
  Color _backgroundColor = Colors.blue;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _fadeController;
  late AnimationController _colorController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controller for image fade-in
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Animation controller for background color transitions
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Load first image on startup
    _fetchNewImage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  /// Fetches a new random image and updates the UI
  Future<void> _fetchNewImage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Reset fade animation
    _fadeController.reset();

    try {
      final imageUrl = await ApiService.fetchRandomImage();

      if (mounted) {
        setState(() {
          _currentImageUrl = imageUrl;
          _isLoading = false;
        });

        // Start fade-in animation
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Callback when dominant color is extracted from image
  void _onColorExtracted(Color color) {
    if (mounted && _backgroundColor != color) {
      final oldColor = _backgroundColor;
      _colorController.reset();

      // Animate color transition
      _colorController.addListener(() {
        if (mounted) {
          setState(() {
            _backgroundColor = Color.lerp(
              oldColor,
              color,
              _colorController.value,
            )!;
          });
        }
      });

      _colorController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final screenSize = MediaQuery.of(context).size;
    final imageSize = screenSize.width * 0.85;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: ColorExtractor.createGradient(_backgroundColor, brightness),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App title
                  Text(
                    'Random Image',
                    semanticsLabel: 'Random Image App',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: brightness == Brightness.dark
                          ? Colors.white
                          : Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Image container
                  _buildImageWidget(imageSize),

                  const SizedBox(height: 40),

                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Failed to load image. Please try again.',
                        semanticsLabel: 'Error loading image',
                        style: TextStyle(
                          color: brightness == Brightness.dark
                              ? Colors.red.shade300
                              : Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // "Another" button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _fetchNewImage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text(
                      'Another',
                      semanticsLabel: 'Load another random image',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the image widget with loading and error states
  Widget _buildImageWidget(double size) {
    if (_currentImageUrl == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading image',
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: _currentImageUrl!,
          key: ValueKey(_currentImageUrl), // Force rebuild on URL change
          fit: BoxFit.cover,
          width: size,
          height: size,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: Colors.grey.shade300,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            color: Colors.grey.shade300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          imageBuilder: (context, imageProvider) {
            // Extract dominant color when image loads successfully
            _extractColorFromProvider(imageProvider);

            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Extract color from image provider
  Future<void> _extractColorFromProvider(ImageProvider imageProvider) async {
    try {
      final color = await ColorExtractor.getDominantColorFromImage(imageProvider);
      _onColorExtracted(color);
    } catch (e) {
      debugPrint('Error extracting color: $e');
    }
  }
}