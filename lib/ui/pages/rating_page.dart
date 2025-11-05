import 'package:flutter/material.dart';

import '../../controllers/engagement_controller.dart';
import '../../core/localization/app_localizations.dart';

class RatingPage extends StatefulWidget {
  const RatingPage({
    super.key,
    required this.engagementController,
  });

  final EngagementController engagementController;

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  late final TextEditingController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController(
      text: widget.engagementController.feedbackNotifier.value,
    );
    _feedbackController.addListener(
      () => widget.engagementController.setFeedback(_feedbackController.text),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('ratingTitle')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.translate('ratingHeadline'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<int>(
              valueListenable: widget.engagementController.ratingNotifier,
              builder: (context, rating, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    final isActive = value <= rating;
                    return IconButton(
                      iconSize: 44,
                      onPressed: () =>
                          widget.engagementController.setRating(value),
                      icon: Icon(
                        isActive
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              t.translate('ratingFeedbackLabel'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: t.translate('ratingFeedbackHint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.translate('ratingThanks'))),
                );
              },
              icon: const Icon(Icons.send_rounded),
              label: Text(t.translate('submit')),
            ),
          ],
        ),
      ),
    );
  }
}
