import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'qr_scanner_page.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(attendance());
}

class attendance extends StatefulWidget {
  @override
  State<attendance> createState() => _attendanceState();
}

class _attendanceState extends State<attendance> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Code Event Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<String?>(
        future: _getStoredPhoneNumber(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data != null) {
            return HomePage(phoneNumber: snapshot.data!);
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }

  Future<String?> _getStoredPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phoneNumber');
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  void _submitUserDetails() async {
    final phoneNumber = _phoneController.text.trim();
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (phoneNumber.isNotEmpty && fullName.isNotEmpty && email.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phoneNumber', phoneNumber);
      await prefs.setString('fullName', fullName);
      await prefs.setString('email', email);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(phoneNumber: phoneNumber)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all details')),
      );
    }
  }

  bool isChecked = false;

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/rwk.png', // Add your image here
                height: 100,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Enter your full name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Enter your email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Enter your phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isChecked = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'By continuing, you agree to Pinterest\'s ',
                        style: TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _launchURL('https://heartfulness.org/in/terms');
                              },
                          ),
                          TextSpan(
                            text: ' and ',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _launchURL('https://heartfulness.org/in/privacy-policy');
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  if (!isChecked) {
                    // Show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please accept the terms and conditions to proceed.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    _submitUserDetails();
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String phoneNumber;

  HomePage({required this.phoneNumber});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> events = [];
  String fullName = '';
  String email = '';
  String phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _loadData();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString('fullName') ?? '';
      email = prefs.getString('email') ?? '';
      phoneNumber = prefs.getString('phoneNumber') ?? '';
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      events = prefs.getStringList('events') ?? [];
    });
  }

  Future<void> _saveEvent(String event) async {
    final prefs = await SharedPreferences.getInstance();
    events.add(event);
    await prefs.setStringList('events', events);
    setState(() {});
  }

  void _onQRScanned(String scannedText) {
    // Decode the scanned text and replace 'x' with space
    final decodedText = _caesarCipher(scannedText, -3).replaceAll("x", " ");

    // First check for 'Session' keyword
    if (!decodedText.contains("Session")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid QR Code!')),
      );
      return;
    }

    // Then check for 'heart' keyword
    if (decodedText.contains("heart")) {
      // Get session name by removing 'heart' and trimming the string
      final sessionName = decodedText.replaceAll("heart", "").trim();

      // Check for duplicate session names
      if (events.contains(sessionName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Duplicate session name!')),
        );
      } else {
        // Add session without time validation
        _saveEvent(sessionName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event: $sessionName added!')),
        );
      }
    } else {
      // Process the event with time validation
      final startTime = decodedText.substring(0, 5);
      final eventText = decodedText.substring(5, decodedText.length - 5);
      final endTime = decodedText.substring(decodedText.length - 5);

      print('Session Name: $eventText');
      print('Start Time: $startTime');
      print('End Time: $endTime');

      if (_isWithinTimeRange(startTime, endTime)) {
        // Check for duplicate session names (ignoring time)
        if (events.contains(eventText)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Duplicate session name!')),
          );
        } else {
          _saveEvent(eventText);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Event: $eventText added!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid QR code: Time outside the valid range')),
        );
      }
    }
  }

  bool _isWithinTimeRange(String startTime, String endTime) {
    final now = DateTime.now();
    final format = DateFormat("HH:mm");

    try {
      final start = format.parse(startTime);
      final end = format.parse(endTime);

      final startTimeWithDate = DateTime(now.year, now.month, now.day, start.hour, start.minute);
      final endTimeWithDate = DateTime(now.year, now.month, now.day, end.hour, end.minute);
      final currentTimeWithDate = now;

      return currentTimeWithDate.isAfter(startTimeWithDate) && currentTimeWithDate.isBefore(endTimeWithDate);
    } catch (e) {
      print('Error parsing time: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $fullName'),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('User Details'),
                    content: Text('Full Name: $fullName\nEmail: $email\nPhone: $phoneNumber'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Image.asset(
              'images/rwk.png', // Add your image here
              height: 100,
            ),
          ),
          Text(
            'All your attended sessions will be visible here',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 10),
          if (events.length > 7)
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Certificate'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 100, color: Colors.green),
                          Text('Eligible for Certificate'),
                          Text('Full Name: $fullName'),
                          Text('Email: $email'),
                          Text('Phone: $phoneNumber'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Congratulations!!'),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(30.0), // Curved edges
                  ),
                  child: Text(events[index], style: TextStyle(fontSize: 18)),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QRScannerPage()),
          );
          if (result != null && result is String) {
            _onQRScanned(result);
          }
        },
        child: Icon(Icons.qr_code_scanner),
      ),
    );
  }

  String _caesarCipher(String text, int shift) {
    final int alphaLength = 26;
    final int asciiPrintables = 95;

    return String.fromCharCodes(text.runes.map((char) {
      if (char >= 65 && char <= 90) {
        return ((char - 65 + shift) % alphaLength + alphaLength) % alphaLength + 65;
      } else if (char >= 97 && char <= 122) {
        return ((char - 97 + shift) % alphaLength + alphaLength) % alphaLength + 97;
      } else if (char >= 32 && char <= 126) {
        return ((char - 32 + shift) % asciiPrintables + asciiPrintables) % asciiPrintables + 32;
      } else {
        return char;
      }
    }).toList());
  }
}
