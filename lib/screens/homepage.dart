import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
	const HomePage({super.key});

	@override
	State<HomePage> createState() => _HomePageState();
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
											errorBuilder: (_, __, ___) => Container(color: Colors.green[100]),
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
														onPageChanged: (idx) => setState(() => _currentPage = idx),
														itemBuilder: (context, index) {
															final card = _overlayCards[index];
																							return Container(
																								margin: const EdgeInsets.symmetric(horizontal: 6),
																								// reduce top padding a bit so title sits higher in the card
																								padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
																decoration: BoxDecoration(
																	color: Colors.white.withOpacity(0.5),
																	borderRadius: BorderRadius.circular(15),
																	boxShadow: [
																		BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 6)),
																	],
																),
																child: Column(
																	crossAxisAlignment: CrossAxisAlignment.start,
																	children: [
																		Row(
																			mainAxisAlignment: MainAxisAlignment.spaceBetween,
																			children: [
																				Column(
																					crossAxisAlignment: CrossAxisAlignment.start,
																					children: [
																						Text(card['title'] ?? '', style: TextStyle(color: const Color.fromARGB(255, 9, 149, 9), fontFamily: 'Gotham' , fontSize: 25, fontWeight: FontWeight.w900)),
																						const SizedBox(height: 1),
																						Text(card['subtitle'] ?? '', style: const TextStyle(color: Color.fromRGBO(9, 149, 9, 9), fontSize: 12)),
																					],
																				),
																				Column(
																					crossAxisAlignment: CrossAxisAlignment.end,
																					children: [
																						Text(card['dateMon'] ?? '', style: TextStyle(color: const Color.fromRGBO(9, 149, 9, 1), fontSize: 18, fontWeight: FontWeight.bold)),
																						Text(card['dateDay'] ?? '', style: TextStyle(color: primaryGreen, fontSize: 34, fontWeight: FontWeight.bold)),
																					],
																				),
																			],
																		),
																		const SizedBox(height: 10),
																		Expanded(
																			child: Row(
																				children: [
																					Expanded(
																						child: Text(card['daysLeft'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 14)),
																					),
																					ElevatedButton(
																						onPressed: () {},
																						style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
																						child: const Text('View Details', style: TextStyle(color: Colors.white)),
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
																color: isActive ? primaryGreen : Colors.white.withOpacity(0.6),
																borderRadius: BorderRadius.circular(8),
																boxShadow: isActive
																		? [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 2))]
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
										child: Container(
											width: 64,
											height: 64,
											decoration: BoxDecoration(
												color: const Color.fromRGBO(255, 244, 161, 9),
												shape: BoxShape.circle,
												border: Border.all(color: const Color.fromRGBO(0, 180, 0, 9), width: 5),
												boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.50), blurRadius: 4)],
											),
																						child: CircleAvatar(
																								radius: 28,
																								backgroundColor: Color.fromRGBO(255, 244, 161, 9),
																								child: Image.asset(
																									'assets/images/Widget_icon.png',
																									width: 40,
																									height: 40,
																									fit: BoxFit.contain,
																									errorBuilder: (context, error, stackTrace) => Icon(Icons.agriculture, color: primaryGreen, size: 28),
																								),
																						),
										),
									),
								],
							),

							// move Manage Plots up so it overlaps hero and add stronger shadow
							const SizedBox(height: 15),
							Transform.translate(
								offset: const Offset(0, 23),
								child: Padding(
									padding: const EdgeInsets.symmetric(horizontal: 18),
									child: Container(
										width: double.infinity,
										decoration: BoxDecoration(
											color: paleYellow,
											borderRadius: BorderRadius.circular(16),
											boxShadow: [
												BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 8)),
											],
										),
										padding: const EdgeInsets.all(16),
										child: Row(
											children: [
												Expanded(
													child: Column(
														crossAxisAlignment: CrossAxisAlignment.start,
														children: [
															SizedBox(height: _manageTitleTop),
															Transform.translate(
																offset: Offset(_manageTitleLeft, 3),
																child: Text('Check on your plots!', style: TextStyle(fontSize: 18, color: primaryGreen, fontWeight: FontWeight.w700)),
															),
															SizedBox(height: _manageButtonTop),
															Transform.translate(
																offset: Offset(_manageButtonLeft, 3),
																child: SizedBox(
																	height: _manageButtonHeight,
																	child: ElevatedButton(
																		onPressed: () {},
																		style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
																		child: const Text('Manage Plots', style: TextStyle(color: Colors.white)),
																	),
																),
															),
														],
													),
												),
												const SizedBox(width: 12),
												SizedBox(
													width: 120,
													height: 130,
													child: Image.asset(
														'assets/images/manageplot_home.png',
														fit: BoxFit.contain,
														errorBuilder: (_, __, ___) => Container(
															decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
															child: const Center(child: Icon(Icons.agriculture, color: primaryGreen, size: 34)),
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
										const Text('Learn More', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
										const SizedBox(height: 12),
										SizedBox(
											height: 110,
											child: ListView(
												scrollDirection: Axis.horizontal,
												children: [
													_infoCard('Rice Yellowing Syndrome', 'assets/images/educ/rys_home.jpg'),
													const SizedBox(width: 12),
													_infoCard('Rice Care 101: Keeping Your...', 'assets/images/educ/rice101.jpg'),
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
		const Color primaryGreen = Color(0xFF099509);
		return Container(
			width: 180,
			decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)]),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Expanded(
						child: ClipRRect(
							borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
							child: Image.asset(
								asset,
								width: double.infinity,
								fit: BoxFit.cover,
								errorBuilder: (_, __, ___) => Container(color: Colors.green[50]),
							),
						),
					),
					Padding(
						padding: const EdgeInsets.all(8.0),
						child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87)),
					),
				],
			),
		);
	}
}
