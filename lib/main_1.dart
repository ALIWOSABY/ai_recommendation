import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Planner',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const GetStarted(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GetStarted extends StatelessWidget {
  const GetStarted({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Started'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SecondPage()),
            );
          },
          child: const Text('Get started!'),
        ),
      ),
    );
  }
}

class SecondPage extends StatefulWidget {
  const SecondPage({Key? key}) : super(key: key);

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  final TextEditingController _budgetController = TextEditingController();
  String? _selectedStartDes;
  String? _selectedEndDes;
  String? _selectedDuration;

  final List<String> _destinations = [
    "Riyadh", "Makkah", "Qassim", "Madinah", "Dammam",
    "Abha", "Jazan", "Tabuk", "Hail", "Al-Jawf",
    "Najran", "Arar", "Albaha"
  ];

  final List<String> _durations = ["1 week", "2 weeks", "3 weeks", "1 month"];

  Future<void> _submitTravelPlan() async {
    String message = _buildTravelMessage();
    String travelPlan = await _fetchChatResponse(message);

    if (travelPlan.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ThirdPage(
            travelPlan: travelPlan,
            startDestination: _selectedStartDes ?? '',
            endDestination: _selectedEndDes ?? '',
          ),
        ),
      );
    }
  }

  String _buildTravelMessage() {
    return '''
      suggest an itinerary from $_selectedStartDes to $_selectedEndDes for $_selectedDuration with a ${_budgetController.text}\$ budget. 
      Include popular restaurants and cafes worth visiting, as well as accommodation (villa or hotel) that is geographically close to attractions. 
      Each day should include nearby attractions, cafes, and restaurants. 
      Please provide URLs for suggested places.
    ''';
  }

  Future<String> _fetchChatResponse(String message) async {
    const apiKey = 'AIzaSyDjbsK_hJSqVbl8lp4JditFVm3wA9tJEx8';
    const endpoint = 'https://console.cloud.google.com/apis/credentials?project=thematic-axle-422617-k6';

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': message},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['choices'][0]['message']['content'].toString();
    } else {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Your Trip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStartDes,
              onChanged: (value) {
                setState(() {
                  _selectedStartDes = value;
                });
              },
              items: _destinations.map((dest) {
                return DropdownMenuItem<String>(
                  value: dest,
                  child: Text(dest),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'Start Destination'),
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedEndDes,
              onChanged: (value) {
                setState(() {
                  _selectedEndDes = value;
                });
              },
              items: _destinations.map((dest) {
                return DropdownMenuItem<String>(
                  value: dest,
                  child: Text(dest),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'End Destination'),
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedDuration,
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value;
                });
              },
              items: _durations.map((duration) {
                return DropdownMenuItem<String>(
                  value: duration,
                  child: Text(duration),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'Duration'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Budget (\$)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _submitTravelPlan,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class ThirdPage extends StatelessWidget {
  final String travelPlan;
  final String startDestination;
  final String endDestination;

  const ThirdPage({
    Key? key,
    required this.travelPlan,
    required this.startDestination,
    required this.endDestination,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Plan Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your Travel Plan:',
              style: const TextStyle(fontSize: 20.0),
            ),
            const SizedBox(height: 16.0),
            Text(
              travelPlan,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                _launchMaps(startDestination, endDestination);
              },
              child: const Text('Open Map'),
            ),
          ],
        ),
      ),
    );
  }

  void _launchMaps(String start, String end) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=$start&destination=$end';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
