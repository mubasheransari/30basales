import 'package:flutter/material.dart';

class WatermarkTiledSmall extends StatelessWidget {
  const WatermarkTiledSmall({super.key, this.tileScale = 1.0});
  // Bigger value => smaller tile (3.0 draws the image at 1/3 size)
  final double tileScale;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/basales.png'),
              repeat: ImageRepeat.repeat, // tile infinitely
              fit: BoxFit.none, // no scaling by fit
              // Make watermark subtle & dark-ish
              colorFilter: ColorFilter.mode(
             Colors.grey.withOpacity(0.10), //  Colors.black.withOpacity(0.06),
                BlendMode.srcIn,
              ),
              scale: tileScale,
              alignment: Alignment.topLeft,
            ),
          ),
        ),
      ),
    );
  }
}