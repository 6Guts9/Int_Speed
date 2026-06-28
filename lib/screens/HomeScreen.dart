import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/SpeedTestController.dart';
import '../theme/app_theme.dart';
//import '../widgets/speed_gauge.dart';
import '../widgets/result_card.dart';
import '../widgets/network_badge.dart';

class Homescreen extends StatelessWidget {
  const Homescreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildGaugeSection(context),
                    const SizedBox(height: 24),
                    _buildResultCards(context),
                    const SizedBox(height: 24),
                    _buildHistory(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //top bar
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'Speed Test',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          NetworkBadge(),
        ],
      ),
    );
  }

  // ── Gauge and go button ────────────────────────────────────────
  Widget _buildGaugeSection(BuildContext context) {
    final controller = context.watch<SpeedTestController>();

    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
          ),
          child: const Center(
            child: Text('not done yet XD',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted)),
          ),
        ),
        // SpeedGauge(
        //   speed: controller.currentSpeed,
        //   phase: controller.phase,
        // ),
        const SizedBox(height: 24),
        _buildGoButton(context, controller),
      ],
    );
  }

  Widget _buildGoButton(BuildContext context, SpeedTestController controller) {
    //  show a stop/spinner indicator
    if (controller.isTesting) {
      return GestureDetector(
        onTap: controller.reset,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfacelight,
            border: Border.all(color: AppTheme.border, width: 1.5),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.accentBlue,
              ),
            ),
          ),
        ),
      );
    }

    // show GO button
    return GestureDetector(
      onTap: controller.startTest,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.accentBlue, AppTheme.accentPurple],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentBlue.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'GO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ── Result cards row ─────────────────────────────────────────
  Widget _buildResultCards(BuildContext context) {
    final controller = context.watch<SpeedTestController>();

    return Row(
      children: [
        ResultCard(
          icon: Icons.network_ping_rounded,
          iconColor: AppTheme.accentPurple,
          label: 'Ping',
          value: controller.isDone ? controller.ping.toStringAsFixed(0) : '--',
          unit: 'ms',
        ),
        const SizedBox(width: 10),
        ResultCard(
          icon: Icons.download_rounded,
          iconColor: AppTheme.accentBlue,
          label: 'Download',
          value: controller.isDone
              ? controller.downloadSpeed.toStringAsFixed(1)
              : '--',
          unit: 'Mbps',
        ),
        const SizedBox(width: 10),
        ResultCard(
          icon: Icons.upload_rounded,
          iconColor: AppTheme.accentPink,
          label: 'Upload',
          value: controller.isDone
              ? controller.uploadSpeed.toStringAsFixed(1)
              : '--',
          unit: 'Mbps',
        ),
      ],
    );
  }

// history
  Widget _buildHistory(BuildContext context) {
    final controller = context.watch<SpeedTestController>();

    // Only show history once there's a completed result
    if (controller.lastResult == null) return const SizedBox.shrink();

    final result = controller.lastResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        Container(
          height: 1,
          color: AppTheme.border,
          margin: const EdgeInsets.only(bottom: 16),
        ),
        const Text(
          'LAST RESULT',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _historyItem(
                Icons.network_ping_rounded,
                AppTheme.accentPurple,
                '${result.Ping.toStringAsFixed(0)} ms',
                'Ping',
              ),
              _historyDivider(),
              _historyItem(
                Icons.download_rounded,
                AppTheme.accentBlue,
                result.DownloadSpeed.toStringAsFixed(1),
                'Down  Mbps',
              ),
              _historyDivider(),
              _historyItem(
                Icons.upload_rounded,
                AppTheme.accentPink,
                result.UploadSpeed.toStringAsFixed(1),
                'Up  Mbps',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _historyItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _historyDivider() {
    return Container(width: 1, height: 40, color: AppTheme.border);
  }
}
