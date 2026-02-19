import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart';
import '../../../core/widgets/widgets.dart';

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key});

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Text('شهادة إتمام الدورة'),
        ),
      ),
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'certificate.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('الشهادات', style: AppTextStyle.title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              AppCard(
                child: Column(
                  children: [
                    const AppIcon(emoji: '🏅', size: 72),
                    const SizedBox(height: AppSpacing.md),
                    const AppText('شهادة إكمال الدورة',
                        style: AppTextStyle.title),
                    const SizedBox(height: AppSpacing.sm),
                    AppText(
                      'يمكنك مشاركة الشهادة أو حفظها كـ PDF',
                      style: AppTextStyle.body,
                      color: AppColors.textSecondary,
                      align: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    QrImageView(
                      data: 'https://mada.app/verify/ABC123',
                      size: 120,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'تصدير PDF',
                onPressed: _exportPdf,
                icon: Icons.picture_as_pdf,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

