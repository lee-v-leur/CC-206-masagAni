import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'favorites.dart';
import 'article.dart';
import 'profile.dart';
import 'homepage.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  bool _showFilterOverlay = false;
  final GlobalKey _filterIconKey = GlobalKey();

  // Filter options
  String _sortBy = 'mostRecent';
  final Set<String> _selectedDiseases = {};
  final Set<String> _selectedLanguages = {};

  // Initial filter state
  String _initialSortBy = 'mostRecent';
  Set<String> _initialDiseases = {};
  Set<String> _initialLanguages = {};

  // Favorited articles tracking
  final Map<String, Map<String, String>> _favoritedArticles = {};
  bool _isLoadingFavorites = true;

  // Featured disease articles for carousel
  final List<_ArticleData> _featuredDiseases = [
    _ArticleData(
      image: 'assets/images/diseases/rys/ryspaddy.png',
      title: 'Rice Yellowing Syndrome',
      author: '',
      displayDate: '',
      published: DateTime(2023, 6, 15),
      diseaseTags: {'yellowing'},
    ),
    _ArticleData(
      image: 'assets/images/diseases/rys/sheathcover.jpg',
      title: 'Sheath Blight Disease',
      author: '',
      displayDate: '',
      published: DateTime(2023, 6, 14),
      diseaseTags: {'sheath'},
    ),
    _ArticleData(
      image: 'assets/images/educ/brown-spot-disease.jpg',
      title: 'Spotting Brown Spot Disease Before It Spreads',
      author: 'Rodriguez, L.',
      displayDate: 'March 8, 2018',
      published: DateTime(2018, 3, 8),
      diseaseTags: {'brownspot'},
    ),
  ];

  // Sample articles data
  final List<_ArticleData> _allArticles = [
    _ArticleData(
      image: 'assets/images/educ/boost-rice-immunity.jpg',
      title: 'Simple Ways to Boost Rice Immunity Naturally',
      author: 'McKinley, A.',
      displayDate: 'January 27, 2014',
      published: DateTime(2014, 1, 27),
      diseaseTags: {'general'},
    ),
    _ArticleData(
      image: 'assets/images/educ/stronger-rice-plants.jpg',
      title: 'Proper Soil Care for Stronger Rice Plants',
      author: 'Junior, Q.',
      displayDate: 'April 16, 2011',
      published: DateTime(2011, 4, 16),
      diseaseTags: {'general'},
    ),
    _ArticleData(
      image: 'assets/images/educ/is-it-just-heat.jpg',
      title: 'Is It Just Heat Stress or Rice Yellowing Syndrome?',
      author: 'Keung, H.',
      displayDate: 'December 1, 2022',
      published: DateTime(2022, 12, 1),
      diseaseTags: {'yellowing'},
    ),
    _ArticleData(
      image: 'assets/images/educ/brown-spot-disease.jpg',
      title: 'Spotting Brown Spot Disease Before It Spreads',
      author: 'Rodriguez, L.',
      displayDate: 'March 8, 2018',
      published: DateTime(2018, 3, 8),
      diseaseTags: {'brownspot'},
    ),
    _ArticleData(
      image: 'assets/images/diseases/rys/ryspaddy.png',
      title: 'Rice Yellowing Syndrome',
      author: '',
      displayDate: '',
      published: DateTime(2023, 6, 15),
      diseaseTags: {'yellowing'},
    ),
    _ArticleData(
      image: 'assets/images/diseases/rys/sheathcover.jpg',
      title: 'Sheath Blight Disease',
      author: '',
      displayDate: '',
      published: DateTime(2023, 6, 14),
      diseaseTags: {'sheath'},
    ),
  ];

  List<_ArticleData> get _filteredArticles {
    var list = List<_ArticleData>.from(_allArticles);
    // Filter by disease tags if any selected
    if (_selectedDiseases.isNotEmpty) {
      list = list
          .where((a) => a.diseaseTags.any((t) => _selectedDiseases.contains(t)))
          .toList();
    }
    // Sort
    list.sort(
      (a, b) => _sortBy == 'mostRecent'
          ? b.published.compareTo(a.published)
          : a.published.compareTo(b.published),
    );
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in, cannot load favorites');
      setState(() => _isLoadingFavorites = false);
      return;
    }

    print('Loading favorites from Firestore for user: ${user.uid}');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('articles')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        print('Loaded ${data.length} favorites from Firestore');
        setState(() {
          _favoritedArticles.clear();
          data.forEach((key, value) {
            if (value is Map) {
              _favoritedArticles[key] = {
                'image': value['image']?.toString() ?? '',
                'author': value['author']?.toString() ?? '',
                'date': value['date']?.toString() ?? '',
              };
            }
          });
          _isLoadingFavorites = false;
        });
      } else {
        print('No favorites document found in Firestore');
        setState(() => _isLoadingFavorites = false);
      }
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() => _isLoadingFavorites = false);
    }
  }

  Future<void> _toggleFavorite(
    String title,
    String image,
    String author,
    String date,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final bool isRemoving = _favoritedArticles.containsKey(title);

    setState(() {
      if (isRemoving) {
        _favoritedArticles.remove(title);
      } else {
        _favoritedArticles[title] = {
          'image': image,
          'author': author,
          'date': date,
        };
      }
    });

    // Save to Firestore - update individual field instead of replacing whole document
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('articles');

      if (isRemoving) {
        print('Removing bookmark: $title');
        await docRef.update({title: FieldValue.delete()});
      } else {
        print('Adding bookmark: $title');
        await docRef.set({
          title: {'image': image, 'author': author, 'date': date},
        }, SetOptions(merge: true));
      }
      print('Bookmark saved successfully');
    } catch (e) {
      print('Error toggling favorite in discover.dart: $e');
    }
  }

  List<Widget> _buildDiseaseCards() {
    return _featuredDiseases.map((disease) {
      final bool isFav = _favoritedArticles.containsKey(disease.title);
      return _FavoriteCard(
        image: disease.image,
        title: disease.title,
        author: disease.author,
        date: disease.displayDate,
        favoritedArticles: _favoritedArticles,
        onToggleFavoriteGlobal: _toggleFavorite,
        onRefresh: _loadFavorites,
      );
    }).toList();
  }

  bool get _hasFilterChanges {
    return _sortBy != _initialSortBy ||
        !_setsEqual(_selectedDiseases, _initialDiseases) ||
        !_setsEqual(_selectedLanguages, _initialLanguages);
  }

  bool _setsEqual(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFFEFEF1);
    const Color primaryGreen = Color(0xFF099509);

    return Scaffold(
      drawer: const AppMenuDrawer(),
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar with menu icon
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (ctx) {
                            return IconButton(
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                              icon: const Icon(
                                Icons.menu,
                                color: primaryGreen,
                                size: 28,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FavoritesScreen(
                                  favoritedArticles: _favoritedArticles,
                                  onToggleFavorite: _toggleFavorite,
                                ),
                              ),
                            ).then((_) => _loadFavorites());
                          },
                          icon: const Icon(
                            Icons.bookmark,
                            color: primaryGreen,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Discover title with filter icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discover',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Your daily dose of agri wisdom.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          key: _filterIconKey,
                          onTap: () {
                            setState(() {
                              _showFilterOverlay = !_showFilterOverlay;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.tune,
                              color: primaryGreen,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Featured diseases carousel
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Featured Diseases',
                      style: TextStyle(
                        color: Color(0xFF8BC34A),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 200,
                    child: PageView(
                      controller: _pageController,
                      padEnds: false,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: _buildDiseaseCards(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _featuredDiseases.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? const Color(0xFF8BC34A)
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'For You',
                      style: TextStyle(
                        color: Color(0xFF8BC34A),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: _filteredArticles
                          .map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ArticleCard(
                                image: a.image,
                                title: a.title,
                                author: a.author,
                                date: a.displayDate,
                                isFavorited: _favoritedArticles.containsKey(
                                  a.title,
                                ),
                                onToggleFavorite: () => _toggleFavorite(
                                  a.title,
                                  a.image,
                                  a.author,
                                  a.displayDate,
                                ),
                                favoritedArticles: _favoritedArticles,
                                onToggleFavoriteGlobal: _toggleFavorite,
                                onRefresh: _loadFavorites,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Filter overlay
          if (_showFilterOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showFilterOverlay = false),
                child: Container(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 120,
                        right: 24,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 260,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFilterSection('Sort By', [
                                  _buildRadioOption(
                                    'Most Recent',
                                    'mostRecent',
                                  ),
                                  _buildRadioOption('Oldest', 'oldest'),
                                ]),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE0E0E0),
                                ),
                                _buildFilterSection('Disease', [
                                  _buildCheckboxOption(
                                    'Rice Yellowing Syndrome',
                                    'yellowing',
                                  ),
                                  _buildCheckboxOption(
                                    'Sheath Blight',
                                    'sheath',
                                  ),
                                  _buildCheckboxOption(
                                    'Brown Spot Disease',
                                    'brownspot',
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _hasFilterChanges
                                          ? () {
                                              setState(() {
                                                _showFilterOverlay = false;
                                                _initialSortBy = _sortBy;
                                                _initialDiseases = Set.from(
                                                  _selectedDiseases,
                                                );
                                                _initialLanguages = Set.from(
                                                  _selectedLanguages,
                                                );
                                              });
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _hasFilterChanges
                                            ? const Color(0xFFB2E0B2)
                                            : const Color(0xFFBDBDBD),
                                        foregroundColor: _hasFilterChanges
                                            ? const Color(0xFF005300)
                                            : const Color(0xFF424242),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
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
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label, String value) {
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              _sortBy == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: _sortBy == value
                  ? const Color(0xFF099509)
                  : Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxOption(String label, String value) {
    final isSelected = _selectedDiseases.contains(value);
    return GestureDetector(
      onTap: () => setState(
        () => isSelected
            ? _selectedDiseases.remove(value)
            : _selectedDiseases.add(value),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: isSelected ? const Color(0xFF099509) : Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final String image;
  final String title;
  final String author;
  final String date;
  final Map<String, Map<String, String>> favoritedArticles;
  final Function(String, String, String, String) onToggleFavoriteGlobal;
  final VoidCallback? onRefresh;

  const _FavoriteCard({
    required this.image,
    required this.title,
    required this.author,
    required this.date,
    required this.favoritedArticles,
    required this.onToggleFavoriteGlobal,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFav = favoritedArticles.containsKey(title);
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleScreen(
              image: image,
              title: title,
              author: author,
              date: date,
              isFavorited: isFav,
              onToggleFavorite: () =>
                  onToggleFavoriteGlobal(title, image, author, date),
              favoritedArticles: favoritedArticles,
              onToggleFavoriteGlobal: onToggleFavoriteGlobal,
            ),
          ),
        );
        onRefresh?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.green[200],
                  child: const Icon(Icons.image, size: 64, color: Colors.white),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (author.trim().isNotEmpty && date.trim().isNotEmpty) ...[
                      Text(
                        '$author • $date',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final String image;
  final String title;
  final String author;
  final String date;
  final bool isFavorited;
  final VoidCallback onToggleFavorite;
  final Map<String, Map<String, String>> favoritedArticles;
  final Function(String, String, String, String) onToggleFavoriteGlobal;
  final VoidCallback? onRefresh;

  const _ArticleCard({
    required this.image,
    required this.title,
    required this.author,
    required this.date,
    required this.isFavorited,
    required this.onToggleFavorite,
    required this.favoritedArticles,
    required this.onToggleFavoriteGlobal,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleScreen(
              image: image,
              title: title,
              author: author,
              date: date,
              isFavorited: isFavorited,
              onToggleFavorite: onToggleFavorite,
              favoritedArticles: favoritedArticles,
              onToggleFavoriteGlobal: onToggleFavoriteGlobal,
            ),
          ),
        );
        onRefresh?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.asset(
                image,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.green[200],
                  child: const Icon(Icons.image, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (author.trim().isNotEmpty && date.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '$author  •  $date',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: onToggleFavorite,
                child: Icon(
                  isFavorited ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.green[700],
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleData {
  final String image;
  final String title;
  final String author;
  final String displayDate;
  final DateTime published;
  final Set<String> diseaseTags;

  const _ArticleData({
    required this.image,
    required this.title,
    required this.author,
    required this.displayDate,
    required this.published,
    required this.diseaseTags,
  });
}
