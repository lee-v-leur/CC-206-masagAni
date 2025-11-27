import 'dart:ui';
import 'package:flutter/material.dart';
import 'plot_manager.dart';
import 'profile.dart';
import 'discover.dart';
import 'welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'plot_details.dart';
import 'plot_details.dart';
import 'article.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0B8A12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'MasagAni',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage plots and profile',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.explore),
              title: const Text('Discover'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DiscoverScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const WelcomeScreen(title: 'masagAni'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  // tunable values for the Manage Plots button (edit these to adjust placement/height)
  double _manageButtonTop = 5.0; // space above the button
  double _manageButtonHeight = 30.0; // button height
  // tunable spacing above the title inside the Manage Plots card
  double _manageTitleTop = 0.0;
  // horizontal offsets (in pixels) for title and button
  double _manageTitleLeft = 0.0;
  double _manageButtonLeft = 0.0;

  // overlay cards will be loaded from Firestore for the signed-in user

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    const Color primaryGreen = Color(0xFF099509);
    const Color paleYellow = Color(0xFFF6EAA7);

    return Scaffold(
      drawer: const AppMenuDrawer(),
      backgroundColor: const Color(0xFFFEFEF1),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // hero + overlay stack
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // bg hero
                  SizedBox(
                    height: size.height * 0.45,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/home_bg.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.green[100]),
                    ),
                  ),

                  // top bar + logo
                  Positioned(
                    left: 12,
                    top: 17,
                    child: Builder(
                      builder: (ctx) {
                        return IconButton(
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                          icon: const Icon(Icons.menu, color: Colors.white),
                        );
                      },
                    ),
                  ),

                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Image.asset(
                          'assets/images/masagani_logoname.png',
                          height: 45,
                        ),
                      ),
                    ),
                  ),

                  // overlay: horizontally scrollable cards + dots (live from Firestore)
                  Positioned(
                    left: 15,
                    right: 15,
                    top: size.height * 0.12,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseAuth.instance.currentUser == null
                          ? const Stream.empty()
                          : FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .collection('plots')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Column(
                            children: [
                              SizedBox(
                                height: 160,
                                child: Center(
                                  child: Text(
                                    'No plots yet',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        }

                        const monthNames = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                          'Jul',
                          'Aug',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dec',
                        ];

                        return Column(
                          children: [
                            SizedBox(
                              height: 160,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: docs.length,
                                onPageChanged: (idx) =>
                                    setState(() => _currentPage = idx),
                                itemBuilder: (context, index) {
                                  final doc = docs[index];
                                  final data = doc.data();
                                  final title =
                                      (data['title'] as String?) ?? '';
                                  final variety =
                                      (data['type'] as String?) ?? '';
                                  final status =
                                      (data['status'] as String?) ?? '';
                                  final created =
                                      (data['createdAt'] as Timestamp?)
                                          ?.toDate() ??
                                      DateTime.now();
                                  final month = monthNames[created.month - 1];
                                  final day = created.day.toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  final healthy =
                                      status.toLowerCase() == 'healthy';

                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: TextStyle(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      9,
                                                      149,
                                                      9,
                                                    ),
                                                    fontFamily: 'Gotham',
                                                    fontSize: 25,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(height: 1),
                                                Text(
                                                  variety,
                                                  style: const TextStyle(
                                                    color: Color.fromRGBO(
                                                      9,
                                                      149,
                                                      9,
                                                      1,
                                                    ),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  month,
                                                  style: TextStyle(
                                                    color: const Color.fromRGBO(
                                                      9,
                                                      149,
                                                      9,
                                                      1,
                                                    ),
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  day,
                                                  style: TextStyle(
                                                    color: primaryGreen,
                                                    fontSize: 34,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  healthy
                                                      ? 'Status: Healthy'
                                                      : 'Status: $status',
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          PlotDetailsPage(
                                                            title: title,
                                                            variety: variety,
                                                            age:
                                                                (data['age']
                                                                    as String?) ??
                                                                '',
                                                            healthy: healthy,
                                                            plotId: doc.id,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: primaryGreen,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'View Details',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(docs.length, (i) {
                                final isActive = i == _currentPage;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: isActive ? 14 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? primaryGreen
                                        : Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.12,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                );
                              }),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // floating wheat icon
                  Positioned(
                    right: 28,
                    bottom: -22,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 244, 161, 9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color.fromRGBO(0, 180, 0, 9),
                            width: 5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.50),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Color.fromRGBO(255, 244, 161, 9),
                          child: Image.asset(
                            'assets/images/Widget_icon.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.agriculture,
                              color: primaryGreen,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // manage plot
              const SizedBox(height: 15),
              Transform.translate(
                offset: const Offset(0, 23),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // background card
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: paleYellow,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.28),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: _manageTitleTop),
                                      Transform.translate(
                                        offset: Offset(_manageTitleLeft, 0),
                                        child: Text(
                                          'Check on your plots!',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: primaryGreen,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: _manageButtonTop),
                                      Transform.translate(
                                        offset: Offset(_manageButtonLeft, 0),
                                        child: SizedBox(
                                          height: _manageButtonHeight,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const PlotManagerPage(),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFE9BE35,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'Manage Plots',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // positioned image that overflows below the card
                        Positioned(
                          right: 1.2,
                          bottom: -140,
                          child: SizedBox(
                            width: 320,
                            height: 440,
                            child: Image.asset(
                              'assets/images/Rectangle 38.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.agriculture,
                                    color: primaryGreen,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 52),

              // Learn more
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Learn More',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _infoCard(
                            'Rice Yellowing Syndrome',
                            'assets/images/educ/rys_home.jpg',
                          ),
                          const SizedBox(width: 12),
                          _infoCard(
                            'Rice Care 101: Keeping Your...',
                            'assets/images/educ/rice101.jpg',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String asset) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.asset(
                asset,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.green[50]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
  final List<Map<String, String>> _overlayCards = [
    {
      'title': 'Plot B',
      'subtitle': '20 weeks old',
      'dateMon': 'Aug',
      'dateDay': '31',
      'daysLeft': '03 days left until next\ncheck up',
    },
    {
      'title': 'Plot A',
      'subtitle': '18 weeks old',
      'dateMon': 'Jul',
      'dateDay': '12',
      'daysLeft': '07 days left until next\ncheck up',
    },
    {
      'title': 'Plot C',
      'subtitle': '12 weeks old',
      'dateMon': 'Sep',
      'dateDay': '06',
      'daysLeft': '11 days left until next\ncheck up',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    const Color primaryGreen = Color(0xFF099509);
    const Color paleYellow = Color(0xFFF6EAA7);

    return Scaffold(
      backgroundColor: const Color(0xFFFEFEF1),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // hero + overlay stack
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // bg hero
                  SizedBox(
                    height: size.height * 0.45,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/home_bg.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.green[100]),
                    ),
                  ),

                  // top bar + logo
                  Positioned(
                    left: 12,
                    top: 17,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.menu, color: Colors.white),
                    ),
                  ),

                  // Profile button (top-right)
                  Positioned(
                    right: 12,
                    top: 17,
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
                    ),
                  ),

                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Image.asset(
                          'assets/images/masagani_logoname.png',
                          height: 45,
                        ),
                      ),
                    ),
                  ),

                  // overlay: horizontally scrollable cards + dots
                  Positioned(
                    left: 15,
                    right: 15,
                    top: size.height * 0.12,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 160,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _overlayCards.length,
                            onPageChanged: (idx) =>
                                setState(() => _currentPage = idx),
                            itemBuilder: (context, index) {
                              final card = _overlayCards[index];
                              final plotTitle = card['title'] ?? 'Plot';
                              final plotAge = card['subtitle'] ?? '';
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    card['title'] ?? '',
                                                    style: TextStyle(
                                                      color: const Color.fromARGB(
                                                        255,
                                                        9,
                                                        149,
                                                        9,
                                                      ),
                                                      fontFamily: 'Gotham',
                                                      fontSize: 25,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    card['subtitle'] ?? '',
                                                    style: const TextStyle(
                                                      color: Color.fromRGBO(
                                                        9,
                                                        149,
                                                        9,
                                                        9,
                                                      ),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    card['dateMon'] ?? '',
                                                    style: TextStyle(
                                                      color: const Color.fromRGBO(
                                                        9,
                                                        149,
                                                        9,
                                                        1,
                                                      ),
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    card['dateDay'] ?? '',
                                                    style: TextStyle(
                                                      color: primaryGreen,
                                                      fontSize: 34,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    card['daysLeft'] ?? '',
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => PlotDetailsPage(
                                                          title: plotTitle,
                                                          variety: 'NSIC Rc 222',
                                                          age: plotAge,
                                                          healthy: true,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: primaryGreen,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'View Details',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 8),

                        // dots indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_overlayCards.length, (i) {
                            final isActive = i == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 14 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? primaryGreen
                                    : Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  // floating wheat icon
                  Positioned(
                    right: 28,
                    bottom: -22,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 244, 161, 9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color.fromRGBO(0, 180, 0, 9),
                            width: 5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.50),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Color.fromRGBO(255, 244, 161, 9),
                          child: Image.asset(
                            'assets/images/Widget_icon.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.agriculture,
                              color: primaryGreen,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // manage plot
              const SizedBox(height: 15),
              Transform.translate(
                offset: const Offset(0, 23),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // background card
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: paleYellow,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.28),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: _manageTitleTop),
                                      Transform.translate(
                                        offset: Offset(_manageTitleLeft, 0),
                                        child: Text(
                                          'Check on your plots!',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: primaryGreen,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: _manageButtonTop),
                                      Transform.translate(
                                        offset: Offset(_manageButtonLeft, 0),
                                        child: SizedBox(
                                          height: _manageButtonHeight,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const PlotManagerPage(),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFE9BE35,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'Manage Plots',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // positioned image that overflows below the card
                        Positioned(
                          right: 1.2,
                          bottom: -140,
                          child: SizedBox(
                            width: 320,
                            height: 440,
                            child: Image.asset(
                              'assets/images/Rectangle 38.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.agriculture,
                                    color: primaryGreen,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 52),

              // Learn more
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DiscoverScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Text(
                            'Learn More',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _infoCard(
                            'Rice Yellowing Syndrome',
                            'assets/images/educ/rys_home.jpg',
                          ),
                          const SizedBox(width: 12),
                          _infoCard(
                            'Rice Care 101: Keeping Your...',
                            'assets/images/educ/rice101.jpg',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String asset) {
    // Map card titles to full article titles
    String fullTitle;
    String author;
    String date;
    
    if (title.contains('Yellowing')) {
      fullTitle = 'Is It Just Heat Stress or Rice Yellowing Syndrome?';
      author = 'Keung, H.';
      date = 'December 1, 2022';
    } else {
      fullTitle = 'Simple Ways to Boost Rice Immunity Naturally';
      author = 'McKinley, A.';
      date = 'January 27, 2014';
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleScreen(
              image: asset,
              title: fullTitle,
              author: author,
              date: date,
              isFavorited: false,
              onToggleFavorite: () {},
            ),
          ),
        );
      },
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  asset,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.green[50]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
