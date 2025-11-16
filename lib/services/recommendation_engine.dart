import '../models/emotion_log.dart';
import '../models/activity_model.dart';

class RecommendationEngine {
  List<ActivityModel> generateRecommendations(EmotionLog log) {
    final Set<ActivityModel> recommendations = {};
    final Map<String, double> categoryScores = {
      'Reflection': 0,
      'Emotional Processing': 0,
      'Connection': 0,
      'Movement': 0,
      'Mindfulness': 0,
      'Recovery': 0,
      'Focus': 0,
      'Inspiration': 0,
    };

    // Mood-Based Scoring
    switch (log.mood) {
      case 'Sad😞':
      case 'Empty☹':
        categoryScores['Emotional Processing'] = 1.0;
        categoryScores['Reflection'] =
            (categoryScores['Reflection'] ?? 0) + 0.8;
        break;
      case 'Angry😠':
        categoryScores['Movement'] = 1.0;
        categoryScores['Mindfulness'] =
            (categoryScores['Mindfulness'] ?? 0) + 0.5;
        break;
      case 'Anxious😥':
        categoryScores['Mindfulness'] = 1.0;
        categoryScores['Recovery'] = (categoryScores['Recovery'] ?? 0) + 0.6;
        break;
      case 'Happy😁':
        categoryScores['Connection'] = 1.0;
        categoryScores['Inspiration'] =
            (categoryScores['Inspiration'] ?? 0) + 0.7;
        break;
      case 'Calm😌':
        categoryScores['Focus'] = (categoryScores['Focus'] ?? 0) + 0.5;
        categoryScores['Reflection'] =
            (categoryScores['Reflection'] ?? 0) + 0.5;
        break;
    }

    // Primary Emotion
    switch (log.primaryEmotion) {
      case 'Self-Doubt😣':
        categoryScores['Reflection'] =
            (categoryScores['Reflection'] ?? 0) + 0.7;
        categoryScores['Inspiration'] =
            (categoryScores['Inspiration'] ?? 0) + 0.3;
        break;
      case 'Resentment😒':
        categoryScores['Emotional Processing'] =
            (categoryScores['Emotional Processing'] ?? 0) + 0.8;
        break;
      case 'Overwhelm🤯':
        categoryScores['Mindfulness'] =
            (categoryScores['Mindfulness'] ?? 0) + 1.0;
        break;
      case 'Joy😄':
      case 'Excitement🤩':
        categoryScores['Connection'] =
            (categoryScores['Connection'] ?? 0) + 0.6;
        categoryScores['Inspiration'] =
            (categoryScores['Inspiration'] ?? 0) + 0.5;
        break;
      case 'Confidence😎':
        categoryScores['Focus'] = (categoryScores['Focus'] ?? 0) + 1.0;
        break;
      case 'Love🥰':
        categoryScores['Connection'] =
            (categoryScores['Connection'] ?? 0) + 1.0;
        break;
    }

    // Sleep Quality
    if (log.sleepQuality != null) {
      if (log.sleepQuality! < 5) {
        categoryScores['Recovery'] = (categoryScores['Recovery'] ?? 0) + 1.0;
        categoryScores['Mindfulness'] =
            (categoryScores['Mindfulness'] ?? 0) + 0.5;
      } else if (log.sleepQuality! > 8) {
        categoryScores['Movement'] = (categoryScores['Movement'] ?? 0) + 0.5;
      }
    }

    // Body Feeling
    switch (log.bodyFeeling) {
      case 'Fatigued😪':
      case 'Sore🤕':
        categoryScores['Recovery'] = (categoryScores['Recovery'] ?? 0) + 1.0;
        break;
      case 'Energetic💃':
        categoryScores['Movement'] = (categoryScores['Movement'] ?? 0) + 1.0;
        break;
      case 'Unwell🤧':
        categoryScores['Recovery'] = (categoryScores['Recovery'] ?? 0) + 1.0;
        categoryScores['Mindfulness'] =
            (categoryScores['Mindfulness'] ?? 0) + 0.4;
        break;
    }

    // Nutrition
    if (log.nutrition != null && log.nutrition != 'Yes, I ate well ✅') {
      categoryScores['Recovery'] = (categoryScores['Recovery'] ?? 0) + 0.6;
    }

    // Support Needed
    if (log.supportNeeded != null) {
      for (var support in log.supportNeeded!) {
        if (support.contains('Motivation')) {
          categoryScores['Inspiration'] =
              (categoryScores['Inspiration'] ?? 0) + 1.0;
        }
        if (support.contains('Stress Relief')) {
          categoryScores['Mindfulness'] =
              (categoryScores['Mindfulness'] ?? 0) + 1.0;
        }
        if (support.contains('Emotional Processing')) {
          categoryScores['Emotional Processing'] =
              (categoryScores['Emotional Processing'] ?? 0) + 1.0;
        }
        if (support.contains('Mental Clarity')) {
          categoryScores['Focus'] = (categoryScores['Focus'] ?? 0) + 1.0;
        }
        if (support.contains('Energy Boost')) {
          categoryScores['Movement'] = (categoryScores['Movement'] ?? 0) + 1.0;
        }
      }
    }

    // Music Intent
    switch (log.musicIntent) {
      case 'Help Me Process 🎶':
        categoryScores['Emotional Processing'] =
            (categoryScores['Emotional Processing'] ?? 0) + 0.5;
        break;
      case 'Lift My Spirits 🎵':
        categoryScores['Inspiration'] =
            (categoryScores['Inspiration'] ?? 0) + 0.5;
        break;
      case 'Deepen My Mood 🎼':
        categoryScores['Reflection'] =
            (categoryScores['Reflection'] ?? 0) + 0.3;
        break;
    }

    // Daily Goal
    if (log.dailyGoal != null) {
      recommendations.add(
        ActivityModel(
          title: log.dailyGoal!,
          type: 'User Goal',
          isAutoTracked: _isAutoTrackable(log.dailyGoal!),
        ),
      );
    }

    // Activity Pools
    final activityPool = {
      'Reflection': [
        _act('Write a Journal Entry 📓', false),
        _act('Read Something Inspiring 📖', false),
      ],
      'Emotional Processing': [
        _act('Music + Journaling Session 🎧📓', false),
        _act('Talk to Someone Safe 🧑‍🤝‍🧑', false),
      ],
      'Connection': [
        _act('Call a Friend ☎', false),
        _act('Send a Gratitude Text 💬', false),
      ],
      'Movement': [
        _act('Take a Walk 🚶‍♂', true),
        _act('Dance for 10 Minutes 💃', false),
      ],
      'Mindfulness': [
        _act('Guided Meditation 🧘‍♀️', false),
        _act('Deep Breathing Exercise 🌬', false),
      ],
      'Recovery': [_act('Power Nap 💤', false), _act('Hydrate Well 💧', false)],
      'Focus': [
        _act('Declutter Your Space 🧹', false),
        _act('Focus Sprint for 15 mins 🎯', false),
      ],
      'Inspiration': [
        _act('Watch a Motivational Video 🎥', false),
        _act('Look at Old Wins 🏆', false),
      ],
    };

    // Final Recommendation Logic
    final sortedCategories =
        categoryScores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedCategories.take(5)) {
      final category = entry.key;
      final acts = activityPool[category] ?? [];
      for (var act in acts.take(1)) {
        recommendations.add(act);
      }
    }

    return recommendations.take(8).toList();
  }

  ActivityModel _act(String title, bool auto) {
    return ActivityModel(title: title, type: 'Wellness', isAutoTracked: auto);
  }

  bool _isAutoTrackable(String goal) {
    return goal.contains('Walk') ||
        goal.contains('Steps') ||
        goal.contains('Screen Time');
  }
}
