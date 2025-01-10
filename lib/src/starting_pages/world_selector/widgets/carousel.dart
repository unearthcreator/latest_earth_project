import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/earth_pages/earth_map_page.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/earth_creator/earth_creator.dart';

import 'package:map_mvp_project/models/world_config.dart'; // so we can access WorldConfig

/// A carousel that displays up to 10 cards, each corresponding to an
/// index from 0..9. If the [worldConfigs] list contains a WorldConfig
/// whose carouselIndex == the card index, we show that world’s title;
/// otherwise we show "Unearth" or "History Tour" if index == 4.
class CarouselWidget extends StatefulWidget {
  final double availableHeight;
  final int initialIndex;
  final List<WorldConfig> worldConfigs;

  /// This callback is invoked if the *centered* card is tapped.
  /// E.g., WorldSelectorPage will handle the actual navigation logic.
  final void Function(int index)? onCenteredCardTapped;

  const CarouselWidget({
    Key? key,
    required this.availableHeight,
    this.initialIndex = 4,
    required this.worldConfigs,
    this.onCenteredCardTapped,
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
    logger.i('CarouselWidget initState -> starting at index=$_currentIndex');
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
          logger.i('Carousel page changed -> idx=$idx, reason=$reason');
        },
      ),
      itemBuilder: (context, index, realIdx) {
        final double opacity = (index == _currentIndex) ? 1.0 : 0.2;

        // see if there's an existing world for that card
        final existingWorld = _findWorldForIndex(index);
        final cardTitle = (index == 4)
            ? 'History Tour'
            : existingWorld?.name ?? 'Unearth';

        return GestureDetector(
          onTap: () {
            logger.i('Card at index $index tapped.');
            if (index == _currentIndex) {
              // Tell the parent "user tapped the centered card"
              widget.onCenteredCardTapped?.call(index);
            } else {
              logger.i('Tapped card #$index but it’s not centered -> no action');
            }
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
                child: Center(
                  child: Text(
                    cardTitle,
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

  WorldConfig? _findWorldForIndex(int idx) {
    for (final w in widget.worldConfigs) {
      if (w.carouselIndex == idx) return w;
    }
    return null;
  }
}