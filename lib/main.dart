import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'model/ProjectGrid.dart';
import 'model/certificate_card.dart'; // Importing the CertificateCard class
import 'package:dev_icons/dev_icons.dart';
void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    ));

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  List<Widget> _buildCardContent() {
    return [
      FadeInUpBig(
        key: UniqueKey(),
        duration: const Duration(milliseconds: 1600),
        child: Column(
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage(
                    'assets/bang dream.gif'), // Update this path to your profile picture
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Windstrom5",
              style: TextStyle(
                color: Color.fromARGB(255, 5, 5, 5),
                fontSize: 25,
                fontFamily: 'Tenada',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Yogyakarta, Indonesia",
              style: TextStyle(
                color: Color.fromARGB(255, 5, 5, 5),
                fontSize: 15,
                fontFamily: 'HACKED',
              ),
            ),
            const SizedBox(height: 40), // Adjusted to add more space
            const Text(
              "Hello, I'm Angga Nugraha, a dedicated Full Stack developer based in Yogyakarta.\n"
              "I'm an enthusiast in technology and innovation, particularly in gaming technology.\n",
              style: TextStyle(
                color: Color.fromARGB(255, 5, 5, 5),
                fontSize: 15,
                fontFamily: 'Merriweather-Light',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text("Familiar With",              
            style: TextStyle(
                color: Color.fromARGB(255, 5, 5, 5),
                fontSize: 15,
                fontFamily: 'Merriweather-Light',
              ),
              textAlign: TextAlign.center,),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  DevIcons.vuejsPlainWordmark,
                  size:40,
                  color: Colors.green, // Discord color
                ),
                SizedBox(width: 15),
                Icon(
                  DevIcons.kotlinPlainWordmark,
                  size:40,
                  color: Colors.purple, // Discord color
                ),
                SizedBox(width: 15),
                Icon(
                  DevIcons.laravelPlainWordmark,
                  size:40,
                  color: Colors.blue, // Discord color
                ),
                SizedBox(width: 15),
                Icon(
                  DevIcons.codeigniterPlainWordmark,
                  size:40,
                  color: Colors.orange, // Discord color
                ),
                SizedBox(width: 15),
                Icon(
                  DevIcons.postgresqlPlainWordmark,
                  size:40,
                  color: Colors.blue, // Discord color
                ),
                SizedBox(width: 15),
                Icon(
                  DevIcons.javaPlainWordmark,
                  size:40,
                  color: Colors.red, // Discord color
                ),
                SizedBox(width: 15),
                Icon(
                  DevIcons.mysqlPlainWordmark,
                  size:40,
                  color: Colors.black, // Discord color
                ),
                SizedBox(width: 15),
              ],
            ),
            const SizedBox(height: 40), 
            const Text(
              "You can connect with me via",
              style: TextStyle(
                color: Color.fromARGB(255, 5, 5, 5),
                fontSize: 15,
                fontFamily: 'Merriweather-Light',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    _launchURL(
                        'https://discordapp.com/users/411135817449340929');
                  },
                  child: const Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.discord,
                        color: Colors.blue, // Discord color
                      ),
                      SizedBox(width: 5),
                      Text(
                        "Discord",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 15,
                          fontFamily: 'Merriweather-Light',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () async {
                    _launchURL(
                        'https://steamcommunity.com/profiles/76561198881808539');
                  },
                  child: const Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.steam,
                        color: Colors.black, // Steam color
                      ),
                      SizedBox(width: 5),
                      Text(
                        "Steam",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'Merriweather-Light',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40), 
            const Text(
              "or visit all of my projects via",
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Merriweather-Light',
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                _launchURL('https://github.com/Windstrom5');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.github,
                    color: Colors.black, // GitHub color
                  ),
                  SizedBox(width: 5),
                  Text(
                    "GitHub",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'Merriweather-Light',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Center(
        child: FadeInUpBig(
          key: UniqueKey(),
          duration: const Duration(milliseconds: 1600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                mainAxisSpacing: 20.0,
                crossAxisSpacing: 20.0,
                children: const [
                  ProjectGrid(
                    name: "Go Fit",
                    language: "HTML, CSS, and JavaScript",
                    platform: Icon(FontAwesomeIcons.globe,color: Colors.blue),
                    url: "https://github.com/Windstrom5/Go-Fit-android",
                    imageUrl:
                        "https://raw.githubusercontent.com/Windstrom5/Go-Fit-android/master/app/src/main/res/drawable/logo.png",
                  ),
                  ProjectGrid(
                    name: "Go Fit Android",
                    language: "Kotlin",
                    platform: Icon(FontAwesomeIcons.android,color: Colors.green),
                    url: "https://github.com/Windstrom5/go_fit",
                    imageUrl:
                        "https://raw.githubusercontent.com/Windstrom5/Go-Fit-android/master/app/src/main/res/drawable/logo.png",
                  ),
                  ProjectGrid(
                    name: "WorkHubs",
                    language: "Kotlin",
                    platform: Icon(FontAwesomeIcons.android,color: Colors.green),
                    url: "https://github.com/Windstrom5/Workhubs-Android-App",
                    imageUrl:
                        "https://raw.githubusercontent.com/Windstrom5/Workhubs-Android-App/master/app/src/main/res/drawable/logo.png",
                  ),
                  ProjectGrid(
                    name: "NihonGo",
                    language: "Kotlin",
                    platform: Icon(FontAwesomeIcons.android,color: Colors.green),
                    url: "https://github.com/Windstrom5/backend_tugas_akhir",
                    imageUrl:
                        "https://raw.githubusercontent.com/Windstrom5/nihonGO/master/app/src/main/res/drawable/logo.png",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      Center(
        child: FadeInUpBig(
          key: UniqueKey(),
          duration: const Duration(milliseconds: 1600),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
            ),
            width: 800, // Adjusted width to fit content
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Certificates",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                  mainAxisSpacing: 20.0,
                  crossAxisSpacing: 20.0,
                  children: const [
                    CertificateCard(
                      certificateName:
                          "Researcher Management and Leadership Training",
                      organizationName: "University of Colorado System",
                      imagePath: "assets/Coursera WHAJ3WB5FKZB_page-0001.jpg",
                    ),
                    // Add more CertificateCard widgets here as needed
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height, // Fixed height
        // decoration: const BoxDecoration(
        //   gradient: LinearGradient(
        //     colors: [
        //       Color(0xFF8B0000), // Darker Retro Red
        //       Color(0xFFB5651D), // Darker Retro Orange
        //       Color(0xFF0E4C75), // Darker Retro Cyan
        //       Color(0xFF6A0DAD), // Darker Retro Purple
        //     ],
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //   ),
        // ),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.jpg'), // Your GIF asset
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 80),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 1600),
                      child: const Center(
                        child: Text(
                          "Welcome To My Portfolio",
                          style: TextStyle(
                            fontFamily: 'Retro',
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 40,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: FadeInUp(
                  duration: const Duration(milliseconds: 1600),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    width: 800, // Adjusted width to fit content
                    height: 500, // Fixed height
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedIndex = 0;
                                });
                              },
                              child: Text(
                                "Home",
                                style: TextStyle(
                                  color: _selectedIndex == 0
                                      ? Colors.blue
                                      : Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedIndex = 1;
                                });
                              },
                              child: Text(
                                "Projects",
                                style: TextStyle(
                                  color: _selectedIndex == 1
                                      ? Colors.blue
                                      : Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedIndex = 2;
                                });
                              },
                              child: Text(
                                "Achivement",
                                style: TextStyle(
                                  color: _selectedIndex == 2
                                      ? Colors.blue
                                      : Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _buildCardContent()[_selectedIndex],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
