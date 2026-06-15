import 'package:flutter/material.dart';

import '../widgets/campaign_card.dart';

class CampaignsScreen extends StatelessWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      itemCount: _campaigns.length + 1,
      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 20 : 16),
      itemBuilder: (context, index) {
        if (index == 0) {
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

        final campaign = _campaigns[index - 1];
        return CampaignCard(
          title: campaign.title,
          description: campaign.description,
          date: campaign.date,
          tag: campaign.tag,
          icon: campaign.icon,
        );
      },
    );
  }
}

class _CampaignMock {
  const _CampaignMock({
    required this.title,
    required this.description,
    required this.date,
    required this.tag,
    required this.icon,
  });

  final String title;
  final String description;
  final String date;
  final String tag;
  final IconData icon;
}

const _campaigns = [
  _CampaignMock(
    title: 'Греческая ночь',
    description: 'Вечер средиземноморской кухни, закусок в стол и авторских напитков.',
    date: '21 июня, 19:00',
    tag: 'Событие',
    icon: Icons.local_dining_rounded,
  ),
  _CampaignMock(
    title: 'Живая музыка',
    description: 'Акустический вечер в зале Alefun Pub. Бронируйте стол заранее.',
    date: 'Каждую пятницу',
    tag: 'Событие',
    icon: Icons.music_note_rounded,
  ),
  _CampaignMock(
    title: 'Скидка 20%',
    description: 'Скидка на закуски и салаты для гостей бонусной программы.',
    date: 'До 30 июня',
    tag: 'Акция',
    icon: Icons.percent_rounded,
  ),
  _CampaignMock(
    title: 'Первый подарок',
    description: 'Получите приветственный подарок после первого заказа в приложении.',
    date: 'Для новых гостей',
    tag: 'Акция',
    icon: Icons.card_giftcard_rounded,
  ),
];
