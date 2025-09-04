import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class UtmBrightTitle extends StatelessWidget {
  const UtmBrightTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.baloo2(
      fontSize: 42, // 更大
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 3.0, // 横向字间距更宽
    );

    final sloganStyle = GoogleFonts.patrickHand(
      fontSize: 20,
      color: const Color(0xFF333333),
    );

    final uStyle = GoogleFonts.baloo2(
      fontSize: 25,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 第一行: UTMBRIGHT
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFD62828), Color(0xFFB51B1B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text('UTM', style: titleStyle),
            ),
            const SizedBox(width: 6), // 左右多一点空隙
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFF7B500), Color(0xFFFCBF49)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text('BRIGHT', style: titleStyle),
            ),
          ],
        ),

        const SizedBox(height: 0.5), // 两行间距更小

        // 第二行: Just Bright for U
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Just Bright for ', style: sloganStyle),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFF7B500), Color(0xFFFCBF49)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text('U', style: uStyle),
            ),
          ],
        ),
      ],
    );
  }
}
