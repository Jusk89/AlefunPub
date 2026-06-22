import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../providers/auth_provider.dart';
import '../services/campaign_service.dart';
import '../theme/app_colors.dart';
import '../widgets/campaign_card.dart';
import 'login_screen.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final _campaignService = CampaignService();

  late Future<List<Campaign>> _campaignsFuture;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _campaignsFuture = _campaignService.getCampaigns();
  }

  Future<void> _refresh() async {
    setState(() {
      _campaignsFuture = _campaignService.getCampaigns();
    });

    try {
      await _campaignsFuture;
    } catch (_) {
      // FutureBuilder renders the friendly error state.
    }
  }

  void _retry() {
    setState(() {
      _campaignsFuture = _campaignService.getCampaigns();
    });
  }

  void _redirectToLogin() {
    if (_isRedirecting) {
      return;
    }

    _isRedirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await AuthScope.of(context, listen: false).logout();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        LoginScreen.routeName,
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Campaign>>(
      future: _campaignsFuture,
      builder: (context, snapshot) {
        final error = snapshot.error;
        if (error is DioException && error.response?.statusCode == 401) {
          _redirectToLogin();
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        if (snapshot.hasError) {
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _refresh,
            child: _CampaignsError(onRetry: _retry),
          );
        }

        final campaigns = snapshot.data ?? [];
        if (campaigns.isEmpty) {
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _refresh,
            child: const _CampaignsEmpty(),
          );
        }

        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
            itemCount: campaigns.length + 1,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? 20 : 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _CampaignsHeader();
              }

              final campaign = campaigns[index - 1];
              return CampaignCard(
                title: campaign.title,
                description: campaign.description,
                date: _formatDate(campaign.createdAt),
                tag: _targetGroupLabel(campaign.targetGroup),
                imageUrl: campaign.imageUrl,
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String _targetGroupLabel(String targetGroup) {
    switch (targetGroup) {
      case 'inactive_clients':
        return 'Для гостей';
      case 'birthday_clients':
        return 'День рождения';
      case 'vip_clients':
        return 'VIP';
      case 'all_clients':
      default:
        return 'Акция';
    }
  }
}

class _CampaignsHeader extends StatelessWidget {
  const _CampaignsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Афиши', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Акции, события и специальные предложения Alefun Pub',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _CampaignsEmpty extends StatelessWidget {
  const _CampaignsEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      children: [
        const _CampaignsHeader(),
        const SizedBox(height: 80),
        const Icon(
          Icons.campaign_outlined,
          size: 64,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          'Сейчас нет активных афиш',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _CampaignsError extends StatelessWidget {
  const _CampaignsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      children: [
        const _CampaignsHeader(),
        const SizedBox(height: 80),
        const Icon(
          Icons.wifi_off_rounded,
          size: 64,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          'Не удалось загрузить афиши',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Проверьте подключение и попробуйте еще раз.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'ПОВТОРИТЬ',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
