import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'article.dart';

class FavoritesScreen extends StatefulWidget {
  final Map<String, Map<String, String>> favoritedArticles;
  final Function(String, String, String, String) onToggleFavorite;

  const FavoritesScreen({
    super.key,
    required this.favoritedArticles,
    required this.onToggleFavorite,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Map<String, Map<String, String>> _favorites = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _favorites = widget.favoritedArticles;
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('articles')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _favorites.clear();
          data.forEach((key, value) {
            if (value is Map) {
              _favorites[key] = {
                'image': value['image']?.toString() ?? '',
                'author': value['author']?.toString() ?? '',
                'date': value['date']?.toString() ?? '',
              };
            }
          });
          _isLoading = false;
        });
      } else {
        setState(() {
          _favorites = widget.favoritedArticles;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _favorites = widget.favoritedArticles;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFFEFEF1);
    const Color primaryGreen = Color(0xFF099509);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: primaryGreen,
                  size: 28,
                ),
              ),
            ),

            // Favorites title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Favorites',
                style: TextStyle(
                  color: Color(0xFF8BC34A),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            
            const SizedBox(height: 16),

            // List of favorite articles
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF099509),
                      ),
                    )
                  : _favorites.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text(
                          'You haven\'t added anything to favorites yet.\n\nTap the bookmark icon on articles in the Discover page to save them here!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        final entry = favoritedArticles.entries.elementAt(
                          index,
                        );
                        final entry = favoritedArticles.entries.elementAt(index);
                        final title = entry.key;
                        final article = entry.value;
                        return _FavoriteArticleCard(
                          image: article['image']!,
                          title: title,
                          author: article['author']!,
                          date: article['date']!,
                          onToggleFavorite: () {
                            widget.onToggleFavorite(
                              title,
                              article['image']!,
                              article['author']!,
                              article['date']!,
                            );
                            setState(() {
                              _favorites.remove(title);
                            });
                          },
                          favoritedArticles: _favorites,
                          onToggleFavoriteGlobal: widget.onToggleFavorite,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteArticleCard extends StatelessWidget {
  final String image;
  final String title;
  final String author;
  final String date;
  final VoidCallback onToggleFavorite;
  final Map<String, Map<String, String>> favoritedArticles;
  final Function(String, String, String, String) onToggleFavoriteGlobal;

  const _FavoriteArticleCard({
    required this.image,
    required this.title,
    required this.author,
    required this.date,
    required this.onToggleFavorite,
    required this.favoritedArticles,
    required this.onToggleFavoriteGlobal,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleScreen(
              image: image,
              title: title,
              author: author,
              date: date,
              isFavorited: true,
              onToggleFavorite: onToggleFavorite,
              favoritedArticles: favoritedArticles,
              onToggleFavoriteGlobal: onToggleFavoriteGlobal,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Article thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                image,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 88,
                  height: 88,
                  color: Colors.green[200],
                  child: const Icon(Icons.image, size: 32, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Article details
            Expanded(
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

            // Bookmark icon
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: onToggleFavorite,
                child: const Icon(
                  Icons.bookmark,
                  color: Color(0xFF099509),
                  size: 24,
                ),
              ),
            ),
          ],
        children: [
          // Article thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              image,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 88,
                height: 88,
                color: Colors.green[200],
                child: const Icon(Icons.image, size: 32, color: Colors.white),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Article details
          Expanded(
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
                const SizedBox(height: 8),
                Text(
                  '$author  •  $date',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Bookmark icon
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: onToggleFavorite,
              child: const Icon(
                Icons.bookmark,
                color: Color(0xFF099509),
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
