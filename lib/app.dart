import 'package:flutter/material.dart';
import 'audio_manager.dart';
import 'theme.dart';
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

  void _switchTab(int idx) {
    setState(() => _tabIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.5, -1),
            end: Alignment(0.5, 1),
            colors: [
              Color(0xFF1a1a1a),
              Color(0xFF0d0d0d),
              Color(0xFF050505),
              Color(0xFF111111),
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildOrb(
              top: -60, right: -60,
              size: 280,
              opacity: 0.12,
            ),
            _buildOrb(
              bottom: 100, left: -40,
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
                        LibraryView(
                          currentIdx: _audio.currentIdx,
                          onPlay: (i) => _audio.playTrack(i),
                        ),
                        PlayerView(audio: _audio),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_tabIndex == 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: MiniPlayer(
                  audio: _audio,
                  onTap: () => _switchTab(1),
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
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
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
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          _buildTab('Библиотека', 0),
          _buildTab('Плеер', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int idx) {
    final active = _tabIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
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
