import 'package:flutter/material.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/carousel.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/world_selector_buttons.dart';
import 'package:map_mvp_project/services/error_handler.dart';


/// A page that allows the user to select which "world" (scenario) to enter.
/// It uses a button row at the top (WorldSelectorButtons) and a carousel 
/// (CarouselWidget) in the main body to showcase selectable worlds.
class WorldSelectorPage extends StatelessWidget {
  const WorldSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      // 1) Log the start of the build phase for debugging.
      logger.i('Building WorldSelectorPage widget');

      // 2) Get total screen height, then subtract some top/bottom areas
      //    (e.g., an app bar of 56px and a top spacing of 40px in your layout).
      final double screenHeight = MediaQuery.of(context).size.height;
      final double availableHeight = screenHeight - 56 - 40;

      // 3) Log the computed values for debugging. 
      //    In dev mode, you can also check if the math is correct.
      logger.d('Screen height: $screenHeight, '
                'Available height for carousel: $availableHeight');

      // 4) Build the scaffold with a column:
      //    - A row of buttons at the top (WorldSelectorButtons).
      //    - An Expanded center area for the CarouselWidget.
      return Scaffold(
        body: Column(
          children: [
            // Buttons for selecting worlds or navigating away
            const WorldSelectorButtons(),
            // The carousel occupies the rest of the screen
            Expanded(
              child: Center(
                child: CarouselWidget(
                  availableHeight: availableHeight,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      // 5) If any error occurs during build, log the error and show fallback UI.
      logger.e('Error building WorldSelectorPage', error: e, stackTrace: stackTrace);
      return const Center(child: Text('Error loading World Selector'));
    }
  }
}