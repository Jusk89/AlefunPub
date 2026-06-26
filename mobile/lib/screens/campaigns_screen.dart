import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
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
                date: _campaignDateLabel(campaign),
                tag: _campaignTag(campaign),
                imageUrl: ApiService.resolveImageUrl(campaign.imageUrl),
                onTap: () => _showCampaignDetails(context, campaign),
              );
            },
          ),
        );
      },
    );
  }

  void _showCampaignDetails(BuildContext context, Campaign campaign) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CampaignDetailsSheet(
        campaign: campaign,
        tag: _campaignTag(campaign),
        dateLabel: _campaignDateLabel(campaign),
      ),
    );
  }
}

class _CampaignDetailsSheet extends StatelessWidget {
  const _CampaignDetailsSheet({
    required this.campaign,
    required this.tag,
    required this.dateLabel,
  });

  final Campaign campaign;
  final String tag;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiService.resolveImageUrl(campaign.imageUrl);
    final description = campaign.description.trim();

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.44,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 1.35,
                  child: imageUrl.isEmpty
                      ? Container(
                          color: AppColors.card,
                          child: const Icon(
                            Icons.campaign_rounded,
                            size: 76,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.card,
                            child: const Icon(
                              Icons.campaign_rounded,
                              size: 76,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(campaign.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Описание', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                description.isEmpty
                    ? 'Подробности появятся скоро.'
                    : description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        );
      },
    );
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
          'События и специальные предложения Alefun Pub',
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

String _campaignTag(Campaign campaign) {
  final title = campaign.title.toLowerCase();
  if (title.contains('ночь') ||
      title.contains('вечер') ||
      title.contains('музык') ||
      title.contains('концерт') ||
      title.contains('дискот')) {
    return 'Событие';
  }
  switch (campaign.targetGroup) {
    case 'inactive_clients':
      return 'Для гостей';
    case 'birthday_clients':
      return 'День рождения';
    case 'vip_clients':
      return 'VIP';
    case 'all_clients':
    default:
      return 'Афиша';
  }
}

String _campaignDateLabel(Campaign campaign) {
  final startDate = campaign.startDate;
  final endDate = campaign.endDate;
  if (startDate != null && endDate != null) {
    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }
  if (startDate != null) {
    return _formatDate(startDate);
  }
  return _formatDate(campaign.createdAt);
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
