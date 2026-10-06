import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صفحة المطور'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Image fallback gracefully if not found
            ClipOval(
              child: Image.asset(
                'src/assets/amro.jpeg',
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 150,
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 80, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Amro Alshurafy',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 16),
            const Card(
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'مطور تطبيقات ومواقع ويب شغوف بتقنية المعلومات، متخصص في تطوير تطبيقات Flutter وبناء حلول رقمية عملية تلبي احتياجات المستخدمين. أمتلك خبرة في تصميم وتطوير تطبيقات متكاملة، تشمل أنظمة إدارة، تطبيقات خدمية، ومشاريع ويب تفاعلية.\n\n'
                  'عملت على عدة مشاريع واقعية مثل تطبيقات تنظيم المراسلات، الأدلة السياحية، وأنظمة معالجة الصور، ومواقع المرافق الحيوية مثل الفنادق, بالإضافة إلى العديد من المشاريع البرمجية التي تعكس مهاراتي في البرمجة وتصميم واجهات المستخدم.\n\n'
                  'أسعى دائماً إلى تقديم تجارب استخدام بسيطة، سريعة، وفعالة، مع التركيز على الجودة والأداء العالي. أؤمن أن التقنية ليست مجرد أكواد، بل أدوات لصنع حلول حقيقية تُحدث فرقاً في حياة الناس.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'تواصل معي:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.email, size: 40, color: Colors.redAccent),
                  onPressed: () => _launchUrl('mailto:amroalshurafy@gmail.com'),
                  tooltip: 'Email',
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: Icon(Icons.code, size: 40, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => _launchUrl('https://github.com/OZiL712'),
                  tooltip: 'GitHub',
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.camera_alt, size: 40, color: Colors.purpleAccent),
                  onPressed: () => _launchUrl('https://www.instagram.com/4o7.x'),
                  tooltip: 'Instagram',
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
