import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_test/model/Education_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'model/ProjectGrid.dart';
import 'model/certificate_card.dart'; // Importing the CertificateCard class
import 'package:dev_icons/dev_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(1440, 900), // Design size for web browsers
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(),
        );
      },
    );
  }
}

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

  Widget _buildNavigationButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w), // Added padding
        child: Row(
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
                  color: _selectedIndex == 0 ? Colors.blue : Colors.black,
                  fontSize: 18.sp,
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
                  color: _selectedIndex == 1 ? Colors.blue : Colors.black,
                  fontSize: 18.sp,
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
                "Achievement",
                style: TextStyle(
                  color: _selectedIndex == 2 ? Colors.blue : Colors.black,
                  fontSize: 18.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
              child: Text(
                "Education",
                style: TextStyle(
                  color: _selectedIndex == 3 ? Colors.blue : Colors.black,
                  fontSize: 18.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCardContent() {
    return [
      FadeInUpBig(
        key: UniqueKey(),
        duration: const Duration(milliseconds: 1600),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50.r, // Adjusted for responsive design
                backgroundImage: AssetImage(
                    'assets/bang dream.gif'), // Update this path to your profile picture
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              "Windstrom5",
              style: TextStyle(
                color: Color.fromARGB(255, 5, 5, 5),
                fontSize: 25.sp,
                fontFamily: 'Tenada',
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              "Yogyakarta, Indonesia",
              style: TextStyle(
                color: Color.fromARGB(255, 5, 5, 5),
                fontSize: 15.sp,
                fontFamily: 'HACKED',
              ),
            ),
            SizedBox(height: 40.h), // Adjusted to add more space
            Text(
              "Hello, I'm Angga Nugraha, a dedicated Full Stack developer based in Yogyakarta.\n"
              "I'm an enthusiast in technology and innovation, particularly in gaming technology.\n",
              style: TextStyle(
                color: Color.fromARGB(255, 5, 5, 5),
                fontSize: 15.sp,
                fontFamily: 'Merriweather-Light',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            Text(
              "Familiar With",
              style: TextStyle(
                color: Color.fromARGB(255, 5, 5, 5),
                fontSize: 15.sp,
                fontFamily: 'Merriweather-Light',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  DevIcons.vuejsPlainWordmark,
                  size: 40.sp,
                  color: Colors.green, // Vue.js color
                ),
                SizedBox(width: 15.w),
                Icon(
                  DevIcons.kotlinPlainWordmark,
                  size: 40.sp,
                  color: Colors.purple, // Kotlin color
                ),
                SizedBox(width: 15.w),
                Icon(
                  DevIcons.laravelPlainWordmark,
                  size: 40.sp,
                  color: Colors.blue, // Laravel color
                ),
                SizedBox(width: 15.w),
                Icon(
                  DevIcons.codeigniterPlainWordmark,
                  size: 40.sp,
                  color: Colors.orange, // CodeIgniter color
                ),
                SizedBox(width: 15.w),
                Icon(
                  DevIcons.postgresqlPlainWordmark,
                  size: 40.sp,
                  color: Colors.blue, // PostgreSQL color
                ),
                SizedBox(width: 15.w),
                Icon(
                  DevIcons.javaPlainWordmark,
                  size: 40.sp,
                  color: Colors.red, // Java color
                ),
                SizedBox(width: 15.w),
                Icon(
                  DevIcons.mysqlPlainWordmark,
                  size: 40.sp,
                  color: Colors.black, // MySQL color
                ),
                SizedBox(width: 15.w),
              ],
            ),
            SizedBox(height: 40.h),
            Text(
              "You can connect with me via",
              style: TextStyle(
                color: Color.fromARGB(255, 5, 5, 5),
                fontSize: 15.sp,
                fontFamily: 'Merriweather-Light',
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    _launchURL(
                        'https://discordapp.com/users/411135817449340929');
                  },
                  child: Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.discord,
                        color: Colors.blue, // Discord color
                        size: 24.r,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        "Discord",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 15.sp,
                          fontFamily: 'Merriweather-Light',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20.w),
                GestureDetector(
                  onTap: () async {
                    _launchURL(
                        'https://steamcommunity.com/profiles/76561198881808539');
                  },
                  child: Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.steam,
                        color: Colors.black, // Steam color
                        size: 24.r,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        "Steam",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15.sp,
                          fontFamily: 'Merriweather-Light',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 40.h),
            Text(
              "or visit all of my projects via",
              style: TextStyle(
                color: Colors.black,
                fontSize: 15.sp,
                fontFamily: 'Merriweather-Light',
              ),
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: () {
                _launchURL('https://github.com/Windstrom5');
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.github,
                    size: 24.r,
                    color: Colors.black, // GitHub color
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    "GitHub",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15.sp,
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
                    platform: Icon(FontAwesomeIcons.globe, color: Colors.blue),
                    url: "https://github.com/Windstrom5/Go-Fit-android",
                    imageUrl:
                        "https://raw.githubusercontent.com/Windstrom5/Go-Fit-android/master/app/src/main/res/drawable/logo.png",
                  ),
                  ProjectGrid(
                    name: "Go Fit Android",
                    language: "Kotlin",
                    platform:
                        Icon(FontAwesomeIcons.android, color: Colors.green),
                    url: "https://github.com/Windstrom5/go_fit",
                    imageUrl:
                        "https://raw.githubusercontent.com/Windstrom5/Go-Fit-android/master/app/src/main/res/drawable/logo.png",
                  ),
                  ProjectGrid(
                    name: "WorkHubs",
                    language: "Kotlin",
                    platform:
                        Icon(FontAwesomeIcons.android, color: Colors.green),
                    url: "https://github.com/Windstrom5/Workhubs-Android-App",
                    imageUrl:
                        "https://raw.githubusercontent.com/Windstrom5/Workhubs-Android-App/master/app/src/main/res/drawable/logo.png",
                  ),
                  ProjectGrid(
                    name: "NihonGo",
                    language: "Kotlin",
                    platform:
                        Icon(FontAwesomeIcons.android, color: Colors.green),
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
                  CertificateCard(
                    certificateName:
                        "Researcher Management and Leadership Training",
                    organizationName: "University of Colorado System",
                    imagePath: "assets/Coursera WHAJ3WB5FKZB_page-0001.jpg",
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
                  EducationCard(
                      name: "SDN 001 Sungai Kunjang",
                      location: "Samarinda",
                      years: "assets/Coursera WHAJ3WB5FKZB_page-0001.jpg",
                      imagePath:
                          "assets/sdn.jpg",
                      mapsUrl:
                          "https://www.google.com/maps/place/SD+Negeri+001/@-0.498135,117.1203361,17z/data=!3m1!4b1!4m6!3m5!1s0x2df67efe8db30583:0x5f632eb0108b6f42!8m2!3d-0.498135!4d117.122911!16s%2Fg%2F11b7q6zjzb?entry=ttu"),
                  EducationCard(
                      name: "SMPN 16 Loa Bakung",
                      location: "Samarinda",
                      years: "assets/Coursera WHAJ3WB5FKZB_page-0001.jpg",
                      imagePath:
                          "assets/smpn.jpg",
                      mapsUrl:
                          "https://www.google.com/maps/place/SMP+Negeri+16+Samarinda/@-0.5315706,117.0882096,17z/data=!3m1!4b1!4m6!3m5!1s0x2df67fd303b28c2b:0x65e7eeb487ccff3e!8m2!3d-0.5315706!4d117.0907845!16s%2Fg%2F11fn9fmj3c?entry=ttu"),
                  EducationCard(
                      name: "SMAN 08",
                      location: "Samarinda",
                      years: "assets/Coursera WHAJ3WB5FKZB_page-0001.jpg",
                      imagePath:
                          "assets/sman.jpg",
                      mapsUrl:
                          "https://www.google.com/maps/place/SMA+Negeri+8+Samarinda/@-0.5289858,117.1087201,17z/data=!3m1!4b1!4m6!3m5!1s0x2df67e2537a0009d:0x8f54a57b881beb8a!8m2!3d-0.5289858!4d117.111295!16s%2Fg%2F1hbpx3flk?entry=ttu"),
                  EducationCard(
                      name: "Universitas Atma Jaya Yogyakarta - Informatika",
                      location: "D.I. Yogyakarta",
                      years: "assets/Coursera WHAJ3WB5FKZB_page-0001.jpg",
                      imagePath:
                          "assets/atma.jpg",
                      mapsUrl:
                          "https://www.google.com/maps/place/Universitas+Atma+Jaya+Yogyakarta+-+Kampus+3+Gedung+Bonaventura+Babarsari/@-7.7794195,110.4135542,17z/data=!3m1!4b1!4m6!3m5!1s0x2e7a59f1fb2f2b45:0x20986e2fe9c79cdd!8m2!3d-7.7794195!4d110.4161291!16s%2Fg%2F11cfg5l4w?entry=ttu"),
                ],
              ),
            ],
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
              SizedBox(height: 80.h),
              Padding(
                padding: EdgeInsets.only(top: 5.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 1600),
                      child: Center(
                        child: Text(
                          "Welcome To My Portfolio",
                          style: TextStyle(
                            fontFamily: 'Retro',
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 40.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Center(
                child: FadeInUp(
                  duration: const Duration(milliseconds: 1600),
                  child: Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    width: 800.w, // Adjusted width to fit content
                    height: 500.h, // Fixed height
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildNavigationButtons(), // Placed here
                        SizedBox(height: 20.h),
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
