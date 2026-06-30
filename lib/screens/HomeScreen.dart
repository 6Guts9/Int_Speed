import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/SpeedTestController.dart';
import '../theme/app_theme.dart';
import '../widgets/speed_gauge.dart';
import '../widgets/result_card.dart';
import '../widgets/network_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            _buildServerInfo(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildGaugeSection(context),
                    const SizedBox(height: 24),
                    _buildErrorBanner(context),
                    _buildResultCards(context),
                    const SizedBox(height: 24),
                    _buildQualityBadge(context),
                    const SizedBox(height: 24),
                    _buildHistory(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Speed Test',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const NetworkBadge(),
        ],
      ),
    );
  }
  Widget _buildServerInfo(BuildContext context) {
    final controller = context.watch<SpeedTestController>();
    if (controller.serverName.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded,
              color: AppTheme.textMuted, size: 12),
          const SizedBox(width: 4),
          Text(
            controller.serverName,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
  // ── Gauge + GO button ─────────────────────────────────────────
  Widget _buildGaugeSection(BuildContext context) {
    final controller = context.watch<SpeedTestController>();
    return Column(
      children: [
        SpeedGauge(
          speed: controller.currentSpeed,
          phase: controller.phase,
        ),
        const SizedBox(height: 24),
        _buildGoButton(context, controller),
      ],
    );
  }

  Widget _buildGoButton(
      BuildContext context, SpeedTestController controller) {
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

    final bool isError = controller.hasError;

    return GestureDetector(
      onTap: controller.hasError ? controller.reset : controller.startTest,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isError
                ? [AppTheme.accentRed, AppTheme.accentPink]
                : [AppTheme.accentBlue, AppTheme.accentPurple],
          ),
          boxShadow: [
            BoxShadow(
              color: (isError ? AppTheme.accentRed : AppTheme.accentBlue)
                  .withOpacity(0.35),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            isError ? 'RETRY' : (controller.isDone ? 'RERUN' : 'GO'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ── Error banner ──────────────────────────────────────────────
  Widget _buildErrorBanner(BuildContext context) {
    final controller = context.watch<SpeedTestController>();
    if (!controller.hasError) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: controller.hasError ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.accentRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentRed.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.accentRed, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                controller.errorMessage ?? 'Something went wrong.',
                style: const TextStyle(
                  color: AppTheme.accentRed,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Result cards ──────────────────────────────────────────────
  Widget _buildResultCards(BuildContext context) {
    final controller = context.watch<SpeedTestController>();

    return Row(
      children: [
        ResultCard(
          icon: Icons.network_ping_rounded,
          iconColor: AppTheme.accentPurple,
          label: 'Ping',
          value: controller.isDone
              ? controller.ping.toStringAsFixed(0)
              : '--',
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

  // ── Quality badge ─────────────────────────────────────────────
  // Shows "Excellent / Good / Fair / Poor" based on download speed
  Widget _buildQualityBadge(BuildContext context) {
    final controller = context.watch<SpeedTestController>();
    if (!controller.isDone) return const SizedBox.shrink();

    final color = AppTheme.speedQualityColor(controller.downloadSpeed);
    final label = AppTheme.speedQualityLabel(controller.downloadSpeed);

    return AnimatedOpacity(
      opacity: controller.isDone ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: color, size: 8),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── History ───────────────────────────────────────────────────
  Widget _buildHistory(BuildContext context) {
    final controller = context.watch<SpeedTestController>();
    if (controller.lastResult == null) return const SizedBox.shrink();

    final result = controller.lastResult!;
    final qualityColor =
    AppTheme.speedQualityColor(result.DownloadSpeed);

    return AnimatedOpacity(
      opacity: controller.isDone ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: AppTheme.border,
              margin: const EdgeInsets.only(bottom: 16)),
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
            child: Column(
              children: [
                Row(
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
                      '${result.DownloadSpeed.toStringAsFixed(1)} Mbps',
                      'Download',
                    ),
                    _historyDivider(),
                    _historyItem(
                      Icons.upload_rounded,
                      AppTheme.accentPink,
                      '${result.UploadSpeed.toStringAsFixed(1)} Mbps',
                      'Upload',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quality indicator bar at the bottom of the card
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [qualityColor.withOpacity(0.3), qualityColor],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyItem(
      IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
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

  Widget _historyDivider() =>
      Container(width: 1, height: 40, color: AppTheme.border);
}