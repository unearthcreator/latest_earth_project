import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/models/world_config.dart';

/// A carousel that displays up to 10 cards for indices 0..9.
/// - If the user has a WorldConfig with `carouselIndex == i`, we show that title.
/// - If i == 4, we show "History Tour".
/// - Else show "Unearth".
/// 
/// When the *centered* card is tapped, we invoke [onCenteredCardTapped].
/// The parent (WorldSelectorPage) handles the navigation logic.
class CarouselWidget extends StatefulWidget {
  final double availableHeight;
  final int initialIndex;
  final List<WorldConfig> worldConfigs;

  /// Callback: user tapped the currently centered card => pass index out.
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
    logger.i('CarouselWidget initState -> starting index=$_currentIndex');
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
        final double opacity = (index == _currentIndex) ? 1.0 : 0.2;

        // Does a WorldConfig exist for this card index?
        final world = _findWorldForIndex(index);

        // Decide the card title
        final cardTitle = (index == 4)
            ? 'History Tour'
            : world?.name ?? 'Unearth';

        return GestureDetector(
          onTap: () {
            logger.i('Card at index $index tapped.');
            // Only do something if it’s the centered card
            if (index == _currentIndex) {
              widget.onCenteredCardTapped?.call(index);
            } else {
              logger.i('Not centered -> no action');
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