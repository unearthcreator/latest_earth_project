import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/earth_pages/earth_map_page.dart';

/// A carousel displaying cards. Each card can be tapped to trigger an action:
/// - Only the centered (current) card performs actions when tapped.
///    - If index == 4 and it's centered, go to EarthMapPage.
///    - Otherwise, if it's centered but not index==4, we log "Tapped unearth card".
/// - Tapping a non-centered card does nothing but logs a message.
class CarouselWidget extends StatefulWidget {
  final double availableHeight;

  const CarouselWidget({super.key, required this.availableHeight});

  @override
  _CarouselWidgetState createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  // Start centered on the "History Tour" card (index=4) just as an example.
  int _currentIndex = 4;

  @override
  Widget build(BuildContext context) {
    logger.i('Building CarouselWidget');

    return CarouselSlider.builder(
      itemCount: 10,
      options: CarouselOptions(
        initialPage: _currentIndex,
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
        // The card is fully opaque if it's the current (centered) card; otherwise more translucent.
        final double opacity = (index == _currentIndex) ? 1.0 : 0.2;

        return GestureDetector(
          onTap: () {
            logger.i('Card at index $index tapped.');
            
            // Only respond if this card is the current (centered) one.
            if (index == _currentIndex) {
              // If it's the "History Tour" card (index=4)
              if (index == 4) {
                logger.i('Navigating to EarthMapPage (History Tour).');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EarthMapPage()),
                );
              } else {
                // It's a centered card, but not "History Tour", so "unearth" scenario
                logger.i('Tapped unearth Card at index $index.');
                // Future logic for creation, if you want to navigate or open a dialog, etc.
              }
            } else {
              // Tapped a non-centered card, do nothing special
              logger.i('Tapped card at index $index but it is not centered. No action.');
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
                // Show "History Tour" if index=4, otherwise "Unearth".
                child: Center(
                  child: Text(
                    (index == 4) ? 'History Tour' : 'Unearth',
                    style: const TextStyle(
                      fontSize: 24.0,
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