import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

// ===================== PALETTE (ใหม่) =====================
const kNavy = Color(0xFF2E5077); // ข้อความหลัก, จุด active, ไอคอนหลัก
const kTeal = Color(0xFF4DA1A9); // ปุ่มหลัก
const kMint = Color(0xFF79D7BE); // ไฮไลต์รอง/เฉดรอง
const kIvory = Color(0xFFF6F4F0); // ข้อความบนปุ่ม/พื้นอ่อน

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  late final AnimationController
  _pageAnim; // ใช้ trigger เอฟเฟกต์ตอนเปลี่ยนหน้า
  late final AnimationController _bgPulse; // พัลส์เบา ๆ ให้แบ็กกราวด์มีชีวิต
  int _index = 0;

  // Theme gradients page
  final List<List<Color>> _gradients = const [
    [Color(0xFFB3E5FC), Color(0xFF81C784)],
    [Color(0xFFFFF59D), Color(0xFFFFCC80)],
    [Color(0xFFD1C4E9), Color(0xFF90CAF9)],
    [Color(0xFFB2DFDB), Color(0xFFC5E1A5)],
  ];

  final _pages = const [
    _OnboardPageData(
      title: 'สุขภาพดี เริ่มต้นวันนี้',
      desc:
          'แอปนี้ช่วยติดตามสุขภาพและความเป็นอยู่ของคุณ\nทั้งการนอน อารมณ์ และโภชนาการ',
    ),
    _OnboardPageData(
      title: 'ดูแลตัวเองง่าย ๆ',
      desc: 'ติดตามตัวชี้วัดสำคัญ\nอัพเดตรายวันและรับรางวัลแรงใจเล็ก ๆ',
    ),
    _OnboardPageData(
      title: 'ปรับแผนให้เหมาะกับคุณ',
      desc:
          'อายุ เพศ น้ำหนัก และเป้าหมาย\n(ลดน้ำหนัก / รักษาสุขภาพ / เพิ่มพลัง ฯลฯ)',
    ),
    _OnboardPageData(
      title: 'รู้จักสุขภาพคุณมากขึ้น',
      desc:
          'มอนิเตอร์สถิติประจำวัน\nตั้งเป้าหมายใหม่ และเห็นความก้าวหน้าชัดเจนขึ้น',
    ),
  ];

  Future<void> _finish() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _bgPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageAnim.dispose();
    _bgPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // สีกราเดียนต์หน้า “ปัจจุบัน”
    final colors = _gradients[_index % _gradients.length];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // วงกลมฟุ้ง ๆ เคลื่อนไหวช้า ๆ ด้านหลัง (ตกแต่งบรรยากาศ)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _bgPulse,
                  builder: (_, __) {
                    final t = _bgPulse.value;
                    return CustomPaint(
                      painter: _SoftBubblesPainter(
                        t: t,
                        baseColor: colors.last.withOpacity(0.25),
                      ),
                    );
                  },
                ),
              ),

              // เนื้อหา
              Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (i) {
                        setState(() => _index = i);
                        _pageAnim.forward(from: 0); // รีสตาร์ทเอฟเฟกต์
                      },
                      itemBuilder: (_, i) {
                        final p = _pages[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 40), // ↑ เพิ่มระยะห่างด้านบน
                              // ฉากไอคอนหลัก + ไอคอนลอย (แทนรูปภาพ)
                              Expanded(
                                flex: 3, // ↑ เพิ่ม flex ให้ส่วนไอคอนใหญ่ขึ้น
                                child: _IconScene(
                                  index: i,
                                  controller: _pageAnim,
                                ),
                              ),
                              const SizedBox(height: 20), // ↑ เพิ่มระยะห่าง

                              // จุดบอกหน้าแบบ spring นิด ๆ
                              _Dots(length: _pages.length, index: _index),

                              const SizedBox(height: 24), // ↑ เพิ่มระยะห่าง

                              // Title & Description ใช้ AnimatedSwitcher ให้ลื่นขึ้นตอนเปลี่ยนหน้า
                              Flexible( // ↑ ใช้ Flexible แทน widget ปกติ
                                child: Column(
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 350),
                                      switchInCurve: Curves.easeOutQuad,
                                      switchOutCurve: Curves.easeInQuad,
                                      child: Text(
                                        p.title,
                                        key: ValueKey('title_$i'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: kNavy,
                                          fontSize: 28, // ↑ เพิ่มขนาดหัวเรื่อง
                                          letterSpacing: .2,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 350),
                                      switchInCurve: Curves.easeOutQuad,
                                      switchOutCurve: Curves.easeInQuad,
                                      child: Text(
                                        p.desc,
                                        key: ValueKey('desc_$i'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: kNavy,
                                          fontSize: 18, // ↓ ลดขนาดเนื้อความเล็กน้อย
                                          height: 1.6, // ↑ เพิ่ม line height
                                          fontWeight: FontWeight.w500, // ↑ เพิ่มน้ำหนักตัวอักษร
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32), // ↑ เพิ่มระยะห่างด้านล่าง
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // ปุ่มแอคชัน มี slide-in + hover/press scale
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32), // ↑ เพิ่ม bottom padding
                    child: AnimatedBuilder(
                      animation: _pageAnim,
                      builder: (_, __) {
                        final slide =
                            Tween<Offset>(
                              begin: const Offset(0, .15),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _pageAnim,
                                curve: const Interval(
                                  .2,
                                  1,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                            );
                        final fade = CurvedAnimation(
                          parent: _pageAnim,
                          curve: const Interval(.2, 1, curve: Curves.easeOut),
                        );

                        return SlideTransition(
                          position: slide,
                          child: FadeTransition(
                            opacity: fade,
                            child: Column(
                              children: [
                                _BouncyButton(
                                  label: _index == _pages.length - 1
                                      ? 'เริ่มใช้งาน'
                                      : 'NEXT',
                                  icon: _index == _pages.length - 1
                                      ? Icons.rocket_launch_rounded
                                      : Icons.arrow_forward_rounded,
                                  background: kTeal, // เปลี่ยนสีปุ่มหลัก
                                  onTap: _next,
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPageData {
  final String title;
  final String desc;
  const _OnboardPageData({required this.title, required this.desc});
}

/// ฉากแสดง “ชุดไอคอน” ต่อหน้า + แอนิเมชันลอย/หมุน/สไลด์เข้า
class _IconScene extends StatelessWidget {
  final int index;
  final AnimationController controller;
  const _IconScene({required this.index, required this.controller});

  // กำหนดชุดไอคอนตามหน้า
  List<IconData> get _primaryIcons {
    switch (index) {
      case 0:
        return [Icons.favorite_rounded, Icons.self_improvement_rounded];
      case 1:
        return [Icons.task_alt_rounded, Icons.emoji_events_rounded];
      case 2:
        return [Icons.monitor_weight_rounded, Icons.track_changes_rounded];
      default:
        return [Icons.query_stats_rounded, Icons.trending_up_rounded];
    }
  }

  List<IconData> get _floatingIcons {
    switch (index) {
      case 0:
        return [
          Icons.nightlight_rounded,
          Icons.bedtime_rounded,
          Icons.mood_rounded,
          Icons.restaurant_rounded,
          Icons.local_drink_rounded,
        ];
      case 1:
        return [
          Icons.flag_circle_rounded,
          Icons.check_circle_rounded,
          Icons.local_fire_department_rounded,
          Icons.calendar_month_rounded,
          Icons.star_rate_rounded,
        ];
      case 2:
        return [
          Icons.wc_rounded,
          Icons.cake_rounded,
          Icons.fitness_center_rounded,
          Icons.directions_run_rounded,
          Icons.health_and_safety_rounded,
        ];
      default:
        return [
          Icons.timeline_rounded,
          Icons.bar_chart_rounded,
          Icons.pie_chart_rounded,
          Icons.stacked_line_chart_rounded,
          Icons.bolt_rounded,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final slideIn = Tween<Offset>(
      begin: const Offset(0, .2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
    final fadeIn = CurvedAnimation(parent: controller, curve: Curves.easeOut);

    return SlideTransition(
      position: slideIn,
      child: FadeTransition(
        opacity: fadeIn,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final center = Offset(size.width / 2, size.height / 2);

            return Stack(
              children: [
                // ไอคอน “กลาง” ขนาดใหญ่ + หมุนช้า ๆ
                _SpinningIconRing(
                  icons: _primaryIcons,
                  radius: size.shortestSide * 0.24, // ↑ ใหญ่ขึ้นเล็กน้อย
                ),

                // ไอคอน “ลอยรอบ ๆ” ขนาดเล็ก
                ...List.generate(_floatingIcons.length, (i) {
                  // วางตำแหน่งแบบกระจายรอบวง
                  final angle = (i / _floatingIcons.length) * 2 * math.pi;
                  final baseR = size.shortestSide * 0.36; // ↑ วงกว้างขึ้น
                  return _FloatingIcon(
                    icon: _floatingIcons[i],
                    center: center,
                    baseRadius: baseR,
                    angle: angle,
                    // delay เบา ๆ ให้ไม่ขยับพร้อมกันเป๊ะ
                    phaseShift: i * 0.35,
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ไอคอนหมุนวนรอบจุดศูนย์กลางแบบ slow spin (โชว์ 2–3 อันใหญ่)
class _SpinningIconRing extends StatefulWidget {
  final List<IconData> icons;
  final double radius;
  const _SpinningIconRing({required this.icons, required this.radius});

  @override
  State<_SpinningIconRing> createState() => _SpinningIconRingState();
}

class _SpinningIconRingState extends State<_SpinningIconRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spin,
      builder: (_, __) {
        return Center(
          child: SizedBox(
            width: widget.radius * 2.8,
            height: widget.radius * 2.0,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(widget.icons.length, (i) {
                final t =
                    (i / widget.icons.length) * 2 * math.pi +
                    _spin.value * 2 * math.pi;
                final dx = math.cos(t) * widget.radius;
                final dy = math.sin(t) * (widget.radius * 0.5);
                final scale = 0.92 + 0.08 * math.sin(t); // ซูมเข้าออกเบา ๆ
                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        color: kIvory.withOpacity(.92), // พื้นอ่อนตามพาเลต
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kNavy.withOpacity(.10),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(
                        20,
                      ), // ↑ padding เพิ่มเล็กน้อย
                      child: Icon(
                        widget.icons[i],
                        size: 48, // ↑ ไอคอนใหญ่ขึ้น
                        color: kNavy, // ใช้สีน้ำเงินหลัก
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

/// ไอคอนเล็ก ๆ ลอยขึ้นลง (sin wave) + หมุนเอียงนิด ๆ
class _FloatingIcon extends StatefulWidget {
  final IconData icon;
  final Offset center;
  final double baseRadius;
  final double angle;
  final double phaseShift;
  const _FloatingIcon({
    required this.icon,
    required this.center,
    required this.baseRadius,
    required this.angle,
    required this.phaseShift,
  });

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
      lowerBound: 0,
      upperBound: 1,
    )..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, __) {
        final t = (_float.value + widget.phaseShift) * 2 * math.pi;
        final bob = math.sin(t) * 10; // ลอยขึ้นลง 10 px
        final r = widget.baseRadius + math.cos(t) * 6; // ขยับรัศมีเล็กน้อย
        final dx = widget.center.dx + math.cos(widget.angle) * r;
        final dy = widget.center.dy + math.sin(widget.angle) * r + bob;
        final rot = math.sin(t) * 0.15; // เอียงนิด ๆ

        return Positioned(
          left: dx - 18,
          top: dy - 18,
          child: Transform.rotate(
            angle: rot,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: kIvory.withOpacity(.95), // พื้นอ่อน
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kNavy.withOpacity(.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(widget.icon, size: 22, color: kNavy),
            ),
          ),
        );
      },
    );
  }
}

/// ปุ่มหลักที่เด้ง (bouncy) ตอนกด
class _BouncyButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  const _BouncyButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.background,
  });

  @override
  State<_BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<_BouncyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 0.08, // scale down ~8%
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapCancel: () => _press.reverse(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) {
          final scale = 1 - _press.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: kTeal.withOpacity(.35),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 16, // ↓ ลดขนาดข้อความปุ่ม
                      fontWeight: FontWeight.w700,
                      color: kIvory,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    widget.icon,
                    color: kIvory,
                    size: 18, // ↓ ลดขนาดไอคอน
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int length;
  final int index;
  const _Dots({required this.length, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final active = i == index;
        return TweenAnimationBuilder<double>(
          key: ValueKey('dot_$i$active'),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          tween: Tween(begin: active ? 0.0 : 1.0, end: active ? 1.0 : 0.0),
          builder: (_, t, __) {
            final size = 9 + 5 * t; // ↑ จุดใหญ่ขึ้นเล็กน้อย
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? kNavy : kIvory.withOpacity(.8),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: kNavy.withOpacity(.35),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            );
          },
        );
      }),
    );
  }
}

/// เพนต์วงกลมฟุ้ง ๆ ข้างหลัง (background ornaments)
class _SoftBubblesPainter extends CustomPainter {
  final double t; // 0..1 จาก _bgPulse
  final Color baseColor;
  _SoftBubblesPainter({required this.t, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    final bubbles = <_Bubble>[
      _Bubble(Offset(size.width * .2, size.height * .2), 90),
      _Bubble(Offset(size.width * .85, size.height * .25), 70),
      _Bubble(Offset(size.width * .2, size.height * .75), 80),
      _Bubble(Offset(size.width * .8, size.height * .8), 100),
    ];

    for (var i = 0; i < bubbles.length; i++) {
      final b = bubbles[i];
      final pulse = 1 + .03 * math.sin((t * 2 * math.pi) + i);
      paint.color = baseColor.withOpacity(.5 - i * 0.08);
      canvas.drawCircle(b.center, b.radius * pulse, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoftBubblesPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.baseColor != baseColor;
}

class _Bubble {
  final Offset center;
  final double radius;
  _Bubble(this.center, this.radius);
}
