import 'package:flutter/material.dart';
import 'audio_manager.dart';
import 'theme.dart';
import 'widgets/browse_view.dart';
import 'widgets/library_view.dart';
import 'widgets/player_view.dart';
import 'widgets/mini_player.dart';

class DeePMHome extends StatefulWidget {
  const DeePMHome({super.key});
  @override
  State<DeePMHome> createState() => _DeePMHomeState();
}

class _DeePMHomeState extends State<DeePMHome> {
  final AudioManager _audio = AudioManager();
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _audio.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  void _openPlayer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => PlayerScreen(audio: _audio),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx = _audio.currentIdx < 0 ? 0 : _audio.currentIdx;
    final hueShift = (idx * 37) % 360;
    final tint =
        HSLColor.fromAHSL(0.04, hueShift.toDouble(), 0.3, 0.5).toColor();
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-0.5, -1),
            end: const Alignment(0.5, 1),
            colors: [
              Color.lerp(const Color(0xFF1a1a1a), tint, 0.6)!,
              const Color(0xFF0d0d0d),
              const Color(0xFF050505),
              Color.lerp(const Color(0xFF111111), tint, 0.4)!,
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildOrb(
              top: -60 + (idx % 3) * 20.0,
              right: -60 + (idx % 2) * 30.0,
              size: 280,
              opacity: 0.12,
            ),
            _buildOrb(
              bottom: 100 + (idx % 4) * 15.0,
              left: -40 + (idx % 3) * 25.0,
              size: 220,
              opacity: 0.10,
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildTabs(),
                  Expanded(
                    child: IndexedStack(
                      index: _tabIndex,
                      children: [
                        LibraryView(audio: _audio),
                        BrowseView(audio: _audio),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MiniPlayer(
                audio: _audio,
                onTap: _openPlayer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double opacity,
  }) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(opacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.white, Color(0xFF888888)],
        ).createShader(bounds),
        child: Text(
          'DeePM',
          style: AppColors.syne(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          _buildTab('Библиотека', 0),
          _buildTab('Обзор', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int idx) {
    final active = _tabIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
