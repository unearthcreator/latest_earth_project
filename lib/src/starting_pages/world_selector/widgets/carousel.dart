import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/earth_pages/earth_map_page.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/earth_creator/earth_creator.dart';

/// A carousel displaying cards. Each card can be tapped to trigger an action:
/// - If the card is the currently centered one:
///   - If index == 4 => go to EarthMapPage (History Tour).
///   - Otherwise => go to EarthCreatorPage, passing index as the carousel slot.
/// - Tapping a non-centered card logs a message (no action).
class CarouselWidget extends StatefulWidget {
  final double availableHeight;

  /// The starting index to center on when the carousel first appears.
  /// If not provided, defaults to 4 in this example.
  final int initialIndex;

  const CarouselWidget({
    Key? key,
    required this.availableHeight,
    this.initialIndex = 4,
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
        // If this card == the centered index => fully opaque; else more translucent
        final double opacity = (index == _currentIndex) ? 1.0 : 0.2;

        return GestureDetector(
          onTap: () {
            logger.i('Card at index $index tapped.');
            if (index == _currentIndex) {
              if (index == 4) {
                logger.i('Navigating to EarthMapPage (History Tour).');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EarthMapPage()),
                );
              } else {
                // "Unearth" scenario => pass that index to the EarthCreatorPage
                logger.i('Navigating to EarthCreatorPage with index=$index.');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EarthCreatorPage(carouselIndex: index),
                  ),
                );
              }
            } else {
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
                // Show "History Tour" if index==4, else "Unearth".
                child: Center(
                  child: Text(
                    (index == 4) ? 'History Tour' : 'Unearth',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}