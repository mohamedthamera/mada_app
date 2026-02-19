import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mada_mobile/features/home/presentation/home_screen.dart';
import 'package:mada_mobile/features/courses/presentation/course_providers.dart';
import 'package:shared/shared.dart';

void main() {
  testWidgets('Home shows featured section', (tester) async {
    final mockCourses = [
      Course(
        id: '1',
        titleAr: 'دورة 1',
        titleEn: 'Course 1',
        descAr: 'وصف',
        descEn: 'Desc',
        categoryId: 'cat',
        level: 'مبتدئ',
        thumbnailUrl: 'https://example.com/img.png',
        ratingAvg: 4.5,
        ratingCount: 10,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coursesProvider.overrideWith((ref) async => mockCourses),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('دورات مميزة'), findsOneWidget);
  });
}

