import 'package:flutter/material.dart';

class UtmBrightTitle extends StatelessWidget {
  const UtmBrightTitle({super.key, this.withAnimation = true});

  final bool withAnimation;

  @override
  Widget build(BuildContext context) {
    return withAnimation
        ? const AnimatedUtmBrightTitle()
        : const StaticUtmBrightTitle();
  }
}

class StaticUtmBrightTitle extends StatelessWidget {
  const StaticUtmBrightTitle({super.key});

  @override
  Widget build(BuildContext context) {
    // 只替换字体部分，保持其他所有代码不变
    final titleStyle = TextStyle(
      fontFamily: 'Reselu',
      fontSize: 50,
      fontWeight: FontWeight.bold,
      height: 1.0,
      letterSpacing: 2.9,
      shadows: [
        Shadow(
          offset: Offset(3.0, 3.0),
          blurRadius: 6.0,
          color: Colors.black.withOpacity(1.0),
        ),
        Shadow(
          offset: Offset(1.0, 1.0),
          blurRadius: 3.0,
          color: Colors.black.withOpacity(0.4),
        ),
      ],
    );

    final sloganStyle = TextStyle(
      fontFamily: 'Grillin',
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF555555),
      height: 1.0,
      shadows: [
        Shadow(
          offset: Offset(1.0, 1.0),
          blurRadius: 3.0,
          color: Colors.black.withOpacity(0.3),
        ),
      ],
    );

    return Container(
      // 添加顶部填充使整个标题向下移动
      padding: const EdgeInsets.only(top: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 主标题行
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // UTM部分 - 红色渐变
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color.fromARGB(255, 209, 33, 33), Color(0xFFFF5E5E)],
                  stops: [0.0, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text('UTM', style: titleStyle),
              ),
              const SizedBox(width: 8),
              // BRIGHT部分 - 金色渐变
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    const LinearGradient(
                      colors: [
                        Color.fromARGB(250, 43, 40, 7),
                        Color.fromARGB(255, 251, 160, 2),
                        Color(0xFFFF5E5E),
                      ],
                      stops: [0.0, 0.5, 1.0],
                      begin: Alignment.bottomRight,
                      end: Alignment.topLeft,
                    ).createShader(
                      // 扩展渐变区域以确保完全覆盖，特别是右侧
                      Rect.fromLTRB(
                        bounds.left - 2,
                        bounds.top - 2,
                        bounds.right + 2, // 右侧多扩展一些，覆盖T字母
                        bounds.bottom + 2,
                      ),
                    ),
                child: Text('BRIGHT', style: titleStyle),
              ),
            ],
          ),

          // 减小主标题和副标题之间的间距
          const SizedBox(height: 4),

          // 副标题行 - 确保所有文字都有颜色
          Container(
            // 添加底部间距，让副标题不紧贴底部
            margin: const EdgeInsets.only(bottom: 15.0), // 添加底部间距
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color.fromARGB(255, 32, 32, 32),
                  Color.fromARGB(255, 16, 0, 247),
                ],
                stops: [0.0, 1.0],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ).createShader(bounds),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Just Bright for ', style: sloganStyle),
                  Text(
                    'U',
                    style: sloganStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedUtmBrightTitle extends StatefulWidget {
  const AnimatedUtmBrightTitle({super.key});

  @override
  State<AnimatedUtmBrightTitle> createState() => _AnimatedUtmBrightTitleState();
}

class _AnimatedUtmBrightTitleState extends State<AnimatedUtmBrightTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: const StaticUtmBrightTitle(),
      ),
    );
  }

  // ADD THIS DISPOSE METHOD
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
