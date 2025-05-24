import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final String appUrl = 'https://sites.google.com/view/lorentz3/moneypie';

  void _launchURL(String url) async {
    debugPrint("trying launching $url");
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Couldn't open URL"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About this app')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'MoneePi',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text('Version: 1.0.0'),
            const SizedBox(height: 16),
            const Text('Maintainer: Lorentz'),
            GestureDetector(
              onTap: () => _launchURL(appUrl),
              child: Text(
                appUrl,
                style: TextStyle(color: Colors.blue[800]),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "This app is developed for personal use. It's offline, no data is shared with third parties.",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
