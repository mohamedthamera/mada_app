import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../../core/widgets/widgets.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _selected = -1;
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    final options = ['الإجابة الأولى', 'الإجابة الثانية', 'الإجابة الثالثة'];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('اختبار سريع', style: AppTextStyle.title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText('السؤال 1 من 5', style: AppTextStyle.caption),
              const SizedBox(height: AppSpacing.sm),
              const AppText('ما أفضل طريقة للتعلم الفعال؟',
                  style: AppTextStyle.title),
              const SizedBox(height: AppSpacing.lg),
              ...List.generate(
                options.length,
                (index) => AppCard(
                  child: RadioListTile<int>(
                    value: index,
                    // ignore: deprecated_member_use
                    groupValue: _selected,
                    title: AppText(options[index], style: AppTextStyle.body),
                    // ignore: deprecated_member_use
                    onChanged: _answered
                        ? null
                        : (value) => setState(() => _selected = value ?? -1),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'تحقق من الإجابة',
                onPressed: _selected == -1
                    ? null
                    : () => setState(() => _answered = true),
              ),
              if (_answered)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.md),
                  child: AppText('إجابة صحيحة! أحسنت.',
                      style: AppTextStyle.body),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

