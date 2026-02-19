-- نموذج من الدورات
insert into courses (
  title_ar,
  title_en,
  desc_ar,
  desc_en,
  category_id,
  level,
  thumbnail_url,
  rating_avg,
  rating_count
) values
(
  'مقدمة في البرمجة',
  'Intro to Programming',
  'تعلم أساسيات البرمجة من الصفر مع تمارين عملية ومشاريع صغيرة.',
  'Learn programming fundamentals from scratch with hands-on exercises.',
  gen_random_uuid(),
  'مبتدئ',
  'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800',
  4.6,
  120
),
(
  'تطوير تطبيقات الجوال بـ Flutter',
  'Flutter Mobile Development',
  'دورة شاملة لبناء تطبيقات iOS و Android باستخدام Flutter و Dart.',
  'Build iOS and Android apps with Flutter and Dart.',
  gen_random_uuid(),
  'متوسط',
  'https://images.unsplash.com/photo-1551650975-87deedd944c3?w=800',
  4.8,
  85
),
(
  'التصميم الجرافيكي باستخدام Figma',
  'Graphic Design with Figma',
  'تصميم واجهات المستخدم والموشن جرافيك والمشاريع التعاونية.',
  'UI design, motion graphics and collaborative projects.',
  gen_random_uuid(),
  'مبتدئ',
  'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=800',
  4.7,
  64
),
(
  'التسويق الرقمي ووسائل التواصل',
  'Digital Marketing & Social Media',
  'استراتيجيات التسويق الإلكتروني وإدارة الحملات والإعلانات.',
  'Digital marketing strategies, campaigns and advertising.',
  gen_random_uuid(),
  'متوسط',
  'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800',
  4.5,
  92
),
(
  'تحليل البيانات بـ Python',
  'Data Analysis with Python',
  'استخدام Pandas و NumPy و Matplotlib لتحليل البيانات والتقارير.',
  'Use Pandas, NumPy and Matplotlib for data analysis.',
  gen_random_uuid(),
  'متقدم',
  'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800',
  4.9,
  45
),
(
  'الذكاء الاصطناعي والتعلم الآلي',
  'AI and Machine Learning',
  'أساسيات التعلم الآلي ونماذج التعلم العميق وتطبيقاتها العملية.',
  'Machine learning fundamentals and deep learning applications.',
  gen_random_uuid(),
  'متقدم',
  'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800',
  4.9,
  38
),
(
  'التصوير الفوتوغرافي والإضاءة',
  'Photography and Lighting',
  'أساسيات التصوير والإضاءة وتعديل الصور واحتراف الكاميرا.',
  'Photography basics, lighting and photo editing.',
  gen_random_uuid(),
  'مبتدئ',
  'https://images.unsplash.com/photo-1452587925148-ce544e77e70d?w=800',
  4.6,
  71
),
(
  'إدارة المشاريع الاحترافية',
  'Professional Project Management',
  'منهجيات Agile و Scrum وإدارة الفرق وتخطيط المشاريع.',
  'Agile, Scrum, team management and project planning.',
  gen_random_uuid(),
  'متوسط',
  'https://images.unsplash.com/photo-1552664730-d307ca884978?w=800',
  4.7,
  56
);

