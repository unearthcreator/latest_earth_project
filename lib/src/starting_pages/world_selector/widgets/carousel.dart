import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/earth_pages/earth_map_page.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/earth_creator/earth_creator.dart';

import 'package:map_mvp_project/models/world_config.dart'; // <— so we can see WorldConfig

/// A carousel displaying cards. Each card can be tapped to trigger an action:
/// - If the card == the currently centered index:
///   - If index == 4 -> go to EarthMapPage (History Tour).
///   - Otherwise -> go to EarthCreatorPage, passing index as the "slot."
/// - Tapping a non-centered card just logs a message (no action).
class CarouselWidget extends StatefulWidget {
  final double availableHeight;

  /// The starting index to center on when the carousel first appears.
  /// If not provided, defaults to 4 in this example.
  final int initialIndex;

  /// The list of existing worlds from Hive, so we can check if a given
  /// carousel card index already has a WorldConfig.
  final List<WorldConfig> worldConfigs;

  const CarouselWidget({
    Key? key,
    required this.availableHeight,
    this.initialIndex = 4,
    required this.worldConfigs,
  }) : super(key: key);

  @override
  _CarouselWidgetState createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  /// We store the current index in state so we can highlight the centered card.
  /// We’ll init it to the incoming `initialIndex`.
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    // Start the carousel at the provided initial index
    _currentIndex = widget.initialIndex;
    logger.i('CarouselWidget initState -> starting at index=$_currentIndex');
  }

  @override
  Widget build(BuildContext context) {
    logger.i('Building CarouselWidget with _currentIndex=$_currentIndex');

    return CarouselSlider.builder(
      itemCount: 10,
      options: CarouselOptions(
        initialPage: _currentIndex,          // Use our state-based index
        height: widget.availableHeight * 0.9,
        enlargeCenterPage: true,
        enlargeStrategy: CenterPageEnlargeStrategy.scale,
        enableInfiniteScroll: false,
        viewportFraction: 0.35,
        onPageChanged: (index, reason) {
          setState(() {
            _currentIndex = index;
          });
          logger.i('Carousel page changed to index $index, reason: $reason');
        },
      ),
      itemBuilder: (context, index, realIdx) {
        // If this card == the centered index => fully opaque; else more translucent.
        final double opacity = (index == _currentIndex) ? 1.0 : 0.2;

        // 1) Check if there's a WorldConfig for this `index`.
        //    If yes, we'll display the stored `name`. Otherwise, "Unearth"
        final existingWorld = _findWorldForIndex(index);
        final cardTitle = (index == 4) 
            ? 'History Tour'
            : (existingWorld != null) 
                ? existingWorld.name  // The user-chosen world name
                : 'Unearth';          // No world found => "Unearth"

        return GestureDetector(
          onTap: () {
            logger.i('Card at index $index tapped.');
            if (index == _currentIndex) {
              if (index == 4) {
                // "History Tour" card
                logger.i('Navigating to EarthMapPage (History Tour).');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EarthMapPage()),
                );
              } else {
                // "Unearth" scenario => pass that index to EarthCreatorPage
                logger.i('Navigating to EarthCreatorPage with index=$index.');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EarthCreatorPage(carouselIndex: index),
                  ),
                );
              }
            } else {
              // Tapped a non-centered card => no action
              logger.i(
                'Tapped card at index $index but it is not centered. No action taken.',
              );
            }
          },
          child: Opacity(
            opacity: opacity,
            child: AspectRatio(
              aspectRatio: 1 / 1.3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  color: Colors.blueAccent,
                ),
                // Show either the "History Tour", existing world's name, or "Unearth"
                child: Center(
                  child: Text(
                    cardTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Helper to find if there's already a WorldConfig with `carouselIndex == index`.
  WorldConfig? _findWorldForIndex(int index) {
    for (final world in widget.worldConfigs) {
      if (world.carouselIndex == index) {
        return world;
      }
    }
    return null;
  }
}
