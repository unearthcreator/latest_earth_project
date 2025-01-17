import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/models/world_config.dart';

/// A carousel that displays up to 10 cards for indices 0..9.
/// - If the user has a WorldConfig with `carouselIndex == i`, we show that title.
/// - Else show "Unearth".
/// 
/// When the *centered* card is tapped, we invoke [onCenteredCardTapped].
/// The parent (WorldSelectorPage) handles the navigation logic.
class CarouselWidget extends StatefulWidget {
  final double availableHeight;
  final int initialIndex;
  final List<WorldConfig> worldConfigs;

  /// Callback: user tapped the currently centered card => pass index out.
  final void Function(BuildContext context, int index)? onCardTapped;

  const CarouselWidget({
    Key? key,
    required this.availableHeight,
    this.initialIndex = 4,
    required this.worldConfigs,
    this.onCardTapped,
  }) : super(key: key);

  @override
  _CarouselWidgetState createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    logger.i('CarouselWidget initialized with starting index=$_currentIndex');
  }

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: 10,
      options: CarouselOptions(
        initialPage: _currentIndex,
        height: widget.availableHeight * 0.9,
        enlargeCenterPage: true,
        enlargeStrategy: CenterPageEnlargeStrategy.scale,
        enableInfiniteScroll: false,
        viewportFraction: 0.35,
        onPageChanged: (idx, reason) {
          setState(() => _currentIndex = idx);
          logger.i('Carousel changed -> idx=$idx, reason=$reason');
        },
      ),
      itemBuilder: (context, index, realIdx) {
        final isSelected = index == _currentIndex;
        final double opacity = isSelected ? 1.0 : 0.2;

        // Find the corresponding world config, if available
        final world = _findWorldForIndex(index);

        return GestureDetector(
          onTap: () {
            logger.i('Card at index $index tapped.');
            widget.onCardTapped?.call(context, index);
          },
          child: Opacity(
            opacity: opacity,
            child: AspectRatio(
              aspectRatio: 1 / 1.3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Title at the top
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        world?.name ?? 'Unearth', // Default to "Unearth"
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Image in the center, ensuring no cutoff
                    Expanded(
                      child: _buildImage(world),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the image widget for the given world configuration.
  Widget _buildImage(WorldConfig? world) {
    final imagePath = _getImagePath(world);
    if (imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FractionallySizedBox(
          widthFactor: 0.7,
          heightFactor: 0.7,
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  /// Finds the corresponding WorldConfig for the given index, if available.
  WorldConfig? _findWorldForIndex(int idx) {
    for (final w in widget.worldConfigs) {
      if (w.carouselIndex == idx) return w;
    }
    return null;
  }

  /// Gets the image path based on the world configuration.
  String? _getImagePath(WorldConfig? world) {
    if (world == null) return null;

    final mapType = world.mapType.toLowerCase(); // e.g., "satellite" or "standard"
    final theme = world.manualTheme?.toLowerCase() ?? 'day'; // Default to 'day'

    if (mapType == 'satellite') {
      return 'assets/earth_snapshot/Satellite-${theme[0].toUpperCase()}${theme.substring(1)}.png';
    } else {
      return 'assets/earth_snapshot/${theme[0].toUpperCase()}${theme.substring(1)}.png';
    }
  }
}