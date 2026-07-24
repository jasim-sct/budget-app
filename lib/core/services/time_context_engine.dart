import 'package:flutter/material.dart';

enum TimeOfDaySegment {
  morning,
  afternoon,
  evening,
}

enum MonthPhase {
  start, // Days 1-7
  mid,   // Days 8-23
  end,   // Days 24-31
}

class TimeContextState {
  final TimeOfDaySegment timeSegment;
  final MonthPhase monthPhase;
  final String greeting;
  final String timeAdvice;
  final String phaseAdvice;

  const TimeContextState({
    required this.timeSegment,
    required this.monthPhase,
    required this.greeting,
    required this.timeAdvice,
    required this.phaseAdvice,
  });
}

class TimeContextEngine {
  static TimeContextState getCurrentContext({DateTime? overrideNow}) {
    final now = overrideNow ?? DateTime.now();
    final hour = now.hour;
    final day = now.day;
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;

    TimeOfDaySegment timeSegment;
    String greeting;
    String timeAdvice;

    if (hour >= 5 && hour < 12) {
      timeSegment = TimeOfDaySegment.morning;
      greeting = 'Good Morning';
      timeAdvice = 'Here is your safe spending limit and priority items for today.';
    } else if (hour >= 12 && hour < 18) {
      timeSegment = TimeOfDaySegment.afternoon;
      greeting = 'Good Afternoon';
      timeAdvice = 'Check your current spending velocity to stay on track today.';
    } else {
      timeSegment = TimeOfDaySegment.evening;
      greeting = 'Good Evening';
      timeAdvice = 'Review today\'s total spending summary and daily cash flow.';
    }

    MonthPhase monthPhase;
    String phaseAdvice;

    if (day <= 7) {
      monthPhase = MonthPhase.start;
      phaseAdvice = 'Early month: Great time to review envelope allocations and savings goals.';
    } else if (day > lastDayOfMonth - 7) {
      monthPhase = MonthPhase.end;
      phaseAdvice = 'Late month: Review your savings rate and month-end forecast.';
    } else {
      monthPhase = MonthPhase.mid;
      phaseAdvice = 'Mid month: Maintain steady spending pace across your envelopes.';
    }

    return TimeContextState(
      timeSegment: timeSegment,
      monthPhase: monthPhase,
      greeting: greeting,
      timeAdvice: timeAdvice,
      phaseAdvice: phaseAdvice,
    );
  }
}
