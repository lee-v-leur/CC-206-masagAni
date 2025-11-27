import 'package:flutter/material.dart';

class ArticleScreen extends StatefulWidget {
  final String image;
  final String title;
  final String author;
  final String date;
  final bool isFavorited;
  final VoidCallback onToggleFavorite;
  final Map<String, Map<String, String>>? favoritedArticles;
  final Function(String, String, String, String)? onToggleFavoriteGlobal;

  const ArticleScreen({
    super.key,
    required this.image,
    required this.title,
    required this.author,
    required this.date,
    required this.isFavorited,
    required this.onToggleFavorite,
    this.favoritedArticles,
    this.onToggleFavoriteGlobal,
  });

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  bool _isTranslated = false;

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFFEFEF1);
    const Color darkGreen = Color(0xFF2E7D32);
    
    // Check if this is the Rice Yellowing Syndrome article
    final bool isRYS = widget.title == 'Rice Yellowing Syndrome';
    
    // Determine if this article should show symptoms section
    final bool shouldShowSymptoms = !widget.title.toLowerCase().contains('care') && 
                                     !widget.title.toLowerCase().contains('boost') &&
                                     !widget.title.toLowerCase().contains('manage');

    // Get related articles based on current article
    final List<Map<String, String>> relatedArticles = _getRelatedArticles(widget.title);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header image with overlay
                Stack(
                  children: [
                    // Background image
                    Image.asset(
                      widget.image,
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 280,
                        color: Colors.green[200],
                        child: const Icon(
                          Icons.image,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),

                        child: const Icon(Icons.image, size: 64, color: Colors.white),
                      ),
                    ),
                    
                    // Title overlay at bottom
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            if (widget.date.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.date,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                
                // Author info
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    widget.author,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                
                // Article content
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRYS) ...[
                        // Rice Yellowing Syndrome content
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                            children: [
                              TextSpan(text: 'Rice Yellowing Syndrome (RYS) is an emerging plant disease complex affecting '),
                              TextSpan(
                                text: 'Oryza sativa',
                                style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                              ),
                              TextSpan(text: ' in multiple rice-growing regions. Unlike single-virus infections, RYS is a '),
                              TextSpan(
                                text: 'mixed-infection syndrome',
                                style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                              ),
                              TextSpan(text: ', most commonly involving '),
                              TextSpan(
                                text: 'Rice Ragged Stunt Virus (RRSV)',
                                style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Rice Grassy Stunt Virus (RGSV)',
                                style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                              ),
                              TextSpan(text: '. These viruses are transmitted by the '),
                              TextSpan(
                                text: 'brown planthopper (Nilaparvata lugens)',
                                style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                              ),
                              TextSpan(text: ', a major rice pest whose ecology directly influences the spread and severity of the disease. RYS is characterized by leaf discoloration, impaired vegetative development, malformed plant structures, and major grain yield losses. Because symptoms overlap with nutrient deficiencies and other viral diseases, RYS poses diagnostic challenges and often goes unrecognized until damage becomes widespread.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Paddy image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/diseases/rys/rysph1.png',
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              color: Colors.green[200],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        
                        // Causes section
                        const Text(
                          'Causes',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'RYS is not caused by a single pathogen; instead, it results from co-infection, most frequently by RRSV and RGSV:',
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        
                        const Text(
                          'Rice Ragged Stunt Virus (RRSV)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text(
                            '• Causes ragged or serrated leaf margins, twisted growth, and deformed panicles.\n\n• Reduces grain development due to impaired translocation and tissue distortion.',
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        const Text(
                          'Rice Grassy Stunt Virus (RGSV)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text(
                            '• Induces excessive tillering, pale green or yellowish leaves, and severe stunting.\n\n• Infected plants may produce abundant tillers but very few or no panicles.',
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        
                        RichText(
                          textAlign: TextAlign.justify,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                            children: [
                              TextSpan(text: 'When both viruses infect the same plant, their physiological impacts intensify, resulting in more severe symptoms than either virus would cause independently. This interaction is what defines the condition as a syndrome rather than a conventional viral disease.\n\nBoth viruses are transmitted by the '),
                              TextSpan(
                                text: 'brown planthopper (BPH)',
                                style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                              ),
                              TextSpan(text: ', allowing simultaneous infection to occur during feeding. High BPH populations, influenced by climate, field management, and pesticide misuse, significantly increase RYS incidence.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Cause image - clickable for fullscreen
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _FullScreenImage(
                                  imagePath: 'assets/images/diseases/rys/ryscause.png',
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/diseases/rys/ryscause.png',
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 200,
                                color: Colors.green[200],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Source: https://www.researchgate.net/profile/Il-Ryong-Choi/publication/288941856_Yellowing_syndrome_of_rice_Etiology_current_status_and_future_challenges/links/56b3f5d508ae5deb2657e7a4/Yellowing-syndrome-of-rice-Etiology-current-status-and-future-challenges.pdf',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 28),
                      ] else ...[
                        const Text(
                          'Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.',
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Symptoms section (only for disease articles)
                      if (shouldShowSymptoms) ...[
                        Text(
                          'Symptoms',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        
                        if (isRYS) ...[
                          const Text(
                            'These are the five hallmark indicators, including their Filipino terms to reflect field-level usage:',
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 14),
                          
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: RichText(
                              textAlign: TextAlign.justify,
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  height: 1.8,
                                ),
                                children: [
                                  TextSpan(
                                    text: '• Yellow Leaves (Naninilaw na Dahon) – ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                                  ),
                                  TextSpan(text: 'Uniform or patchy yellowing, typically starting from the lower leaves and progressing upward.\n\n'),
                                  TextSpan(
                                    text: '• Stunted Growth (Pandak o Kulang sa Paglaki) – ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                                  ),
                                  TextSpan(text: 'Internode shortening and reduced plant height, sometimes resulting in severely dwarfed plants.\n\n'),
                                  TextSpan(
                                    text: '• Excess Tillers (Sobrang Sanga) – ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                                  ),
                                  TextSpan(text: 'Abnormally high tiller production that gives the plant a bushy or grassy appearance.\n\n'),
                                  TextSpan(
                                    text: '• Twisted Leaves (Baluktot na Dahon) – ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                                  ),
                                  TextSpan(text: 'Leaf rolling, twisting, or distortion, especially under RRSV influence.\n\n'),
                                  TextSpan(
                                    text: '• Empty Grains (Walang Laman na Butil) – ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                                  ),
                                  TextSpan(text: 'Panicles that develop but fail to fill grains, leading to high sterility and yield collapse.'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Diagnosis images side by side
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => _ImageGallery(
                                          initialIndex: 0,
                                          imagePaths: const [
                                            'assets/images/diseases/rys/rysdiagnosis.jpg',
                                            'assets/images/diseases/rys/ryscomp.jpg',
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/diseases/rys/rysdiagnosis.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 200,
                                        color: Colors.green[200],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => _ImageGallery(
                                          initialIndex: 1,
                                          imagePaths: const [
                                            'assets/images/diseases/rys/rysdiagnosis.jpg',
                                            'assets/images/diseases/rys/ryscomp.jpg',
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/diseases/rys/ryscomp.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 200,
                                        color: Colors.green[200],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Source: DA RFO 1- Ilocos Region',
                            style: TextStyle(fontSize: 10, color: Colors.black54, fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 28),
                        ] else ...[
                          const Text(
                            'Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper',
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                      
                      // Epidemiology and Global sections (RYS only)
                      if (isRYS) ...[
                        const Text(
                          'Epidemiology',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        RichText(
                          textAlign: TextAlign.justify,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                            children: [
                              TextSpan(text: 'The epidemiology of RYS is tightly connected to '),
                              TextSpan(
                                text: 'BPH ecology',
                                style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                              ),
                              TextSpan(text: '. Outbreaks align with conditions that favor vector population growth:'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text(
                            '• warm temperatures,\n\n• high humidity,\n\n• continuous or overlapping rice cropping,\n\n• excessive nitrogen fertilization, and\n\n• pesticide misuse that eliminates natural predators.',
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Because both viruses persist within BPH populations, even low numbers of viruliferous insects can initiate field-level infections. In the presence of abundant vectors, rapid disease spread can occur within weeks.',
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 28),
                        
                        const Text(
                          'Global and Philippine Occurrence',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        
                        const Text(
                          'Global Occurrence',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'RYS has been documented in multiple rice-producing countries in Asia, particularly where BPH densities fluctuate seasonally. Regions with intensive rice-rice cropping systems are more susceptible due to continuous vector–host contact.',
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 18),
                        
                        const Text(
                          'First Detection in the Philippines',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          textAlign: TextAlign.justify,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                            children: [
                              TextSpan(text: 'The '),
                              TextSpan(
                                text: 'International Rice Research Institute (IRRI)',
                                style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                              ),
                              TextSpan(text: ' recorded the first confirmed RYS case in the Philippines through molecular testing that revealed RGSV–RRSV co-infection in symptomatic rice plants. The discovery highlighted the importance of differentiating RYS from tungro and nutrient-related yellowing, which had previously led to misdiagnoses.\n\nFollowing this detection, field observations in '),
                              TextSpan(
                                text: 'CALABARZON',
                                style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                              ),
                              TextSpan(text: ' and other regions noted rapid disease spread associated with BPH surges. The Department of Agriculture initiated awareness and training programs to help farmers recognize the syndrome and implement control measures.\n\nThis detection marked a critical shift in plant health surveillance, emphasizing the arrival of a new, complex viral threat to Philippine rice systems.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        
                        // Image Gallery
                        if (isRYS) ...[
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => _ImageGallery(
                                          initialIndex: 0,
                                          imagePaths: const [
                                            'assets/images/diseases/rys/ricetips.jpg',
                                            'assets/images/diseases/rys/ryscover.png',
                                            'assets/images/diseases/rys/ryss1.png',
                                            'assets/images/diseases/rys/ryssymp.jpg',
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/diseases/rys/ricetips.jpg',
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 120,
                                        color: Colors.green[200],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => _ImageGallery(
                                          initialIndex: 1,
                                          imagePaths: const [
                                            'assets/images/diseases/rys/ricetips.jpg',
                                            'assets/images/diseases/rys/ryscover.png',
                                            'assets/images/diseases/rys/ryss1.png',
                                            'assets/images/diseases/rys/ryssymp.jpg',
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/diseases/rys/ryscover.png',
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 120,
                                        color: Colors.green[200],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => _ImageGallery(
                                          initialIndex: 2,
                                          imagePaths: const [
                                            'assets/images/diseases/rys/ricetips.jpg',
                                            'assets/images/diseases/rys/ryscover.png',
                                            'assets/images/diseases/rys/ryss1.png',
                                            'assets/images/diseases/rys/ryssymp.jpg',
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          'assets/images/diseases/rys/ryss1.png',
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            height: 120,
                                            color: Colors.green[200],
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              '+1',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                        ],
                        
                        // Immediate Rescue Measures
                        if (isRYS) ...[
                          const Text(
                            'Immediate Rescue Measures',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          
                          const Text(
                            '1. Remove Infected Plants.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              'Pull out plants showing clear symptoms and dispose of them away from the field. This lowers the chance of the disease spreading.',
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          const Text(
                            '2. Control the Insects That Spread the Disease',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              'RYS is linked to leafhoppers and planthoppers. Use insecticides only when needed and rotate chemicals to avoid resistance. Natural predators can also help control vector populations.',
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          const Text(
                            '3. Improve Plant Nutrition.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              'Balanced fertilizer, especially potassium and silicon, helps plants cope with infection. Avoid too much nitrogen, which attracts insects and weakens plant resistance.',
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          const Text(
                            '4. Keep Water Levels Steady.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              'Maintain shallow, continuous flooding during outbreaks. This reduces stress on plants and helps limit vector movement.',
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          const Text(
                            '5. Harvest Early if Damage Is Spreading Fast',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              'If RYS is rapidly advancing across the field and grain filling is already compromised, perform an early harvest to save whatever viable grains remain. Waiting too long may lead to almost zero yield.',
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          const Text(
                            '7. Document the Affected Area and Severity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              'Record:\n• where the symptoms started,\n\n• how fast they spread, and\n\n• which plots were most affected.\n\nThis helps in planning replanting, accessing government aid, and guiding future field management, even if the immediate goal is salvage.',
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                        
                        const Text(
                          'References',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Agris FAO. (n.d.). Yellowing syndrome of rice: Etiology, current status and future challenges. Retrieved from https://agris.fao.org/search/en/providers/125429/records/6851870f53e52c13fc771b08\n\nAgris FAO. (n.d.). Rice yellowing syndrome in Southeast Asia. Retrieved from https://agris.fao.org/search/en/providers/122430/records/64724e60e17b74d2224fc3df\n\nCalabarzon Department of Agriculture. (2023). Pagsasanay ng DA-4A RCPC: Tugon sa lumalaganap na rice yellowing disease. Retrieved from https://calabarzon.da.gov.ph/pagsasanay-ng-da-4a-rcpc-tugon-sa-lumalaganap-na-rice-yellowing-disease/\n\nHibino, H. (1996). Yellowing syndrome of rice: Etiology, current status and future challenges. Advances in Disease Vector Research, pp. 357–368. Retrieved from https://books.google.com.ph/books?hl=en&lr=&id=-eYxYP4jC5MC&oi=fnd&pg=PA357&dq=rice+yellowing+syndrome\n\nInternational Rice Research Institute. (2022). What is rice yellowing syndrome? IRRI identifies the first case in the Philippines. Rice News Today. Retrieved from https://ricenewstoday.com/what-is-rice-yellowing-syndrome-irri-identifies-the-first-case-in-the-philippines/\n\nSritag Journal. (2022). Innovative techniques in agriculture: Effects of viral diseases on rice production. Retrieved from https://d1wqtxts1xzle7.cloudfront.net/88375789/SRITAG-02-00045-libre.pdf\n\nZhang, S., Li, X., & Nguyen, V. (2015). Yellowing syndrome of rice: Etiology, current status, and future challenges. ResearchGate. https://www.researchgate.net/publication/288941856_Yellowing_syndrome_of_rice_Etiology_current_status_and_future_challenges',
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.black87,
                            height: 1.7,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      
                      // Image grid
                      if (!isRYS)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/educ/rice_field.jpg',
                                height: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 160,
                                  color: Colors.green[200],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'assets/images/educ/sheath_blight.jpg',
                                    height: 76,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 76,
                                      color: Colors.green[200],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'assets/images/educ/rice_immunity.jpg',
                                    height: 76,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 76,
                                      color: Colors.green[200],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isRYS) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.',
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      // Related Articles section
                      const Text(
                        'Related Articles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8BC34A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Related articles list
                      ...relatedArticles.map((article) {
                        final articleTitle = article['title']!;
                        final isFav =
                            widget.favoritedArticles?.containsKey(
                              articleTitle,
                            ) ??
                            false;
                      
                      // Related articles list
                      ...relatedArticles.map((article) {
                        final articleTitle = article['title']!;
                        final isFav = widget.favoritedArticles?.containsKey(articleTitle) ?? false;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _RelatedArticleCard(
                            image: article['image']!,
                            title: articleTitle,
                            author: article['author']!,
                            date: article['date']!,
                            isFavorited: isFav,
                            onToggleFavorite:
                                widget.onToggleFavoriteGlobal != null
                                ? () => widget.onToggleFavoriteGlobal!(
                                    articleTitle,
                                    article['image']!,
                                    article['author']!,
                                    article['date']!,
                                  )
                                : () {},
                            favoritedArticles: widget.favoritedArticles,
                            onToggleFavoriteGlobal:
                                widget.onToggleFavoriteGlobal,
                          ),
                        );
                      }).toList(),

                            onToggleFavorite: widget.onToggleFavoriteGlobal != null
                                ? () => widget.onToggleFavoriteGlobal!(
                                      articleTitle,
                                      article['image']!,
                                      article['author']!,
                                      article['date']!,
                                    )
                                : () {},
                            favoritedArticles: widget.favoritedArticles,
                            onToggleFavoriteGlobal: widget.onToggleFavoriteGlobal,
                          ),
                        );
                      }).toList(),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          
          // Top bar with back and bookmark buttons
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    
                    // Action buttons
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: widget.onToggleFavorite,
                            icon: Icon(
                              widget.isFavorited
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              widget.isFavorited ? Icons.bookmark : Icons.bookmark_border,
                              color: Colors.black87,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() {
                                _isTranslated = !_isTranslated;
                              });
                            },
                            icon: const Icon(
                              Icons.translate,
                              color: Colors.black87,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
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

  
  List<Map<String, String>> _getRelatedArticles(String currentTitle) {
    final allArticles = [
      {
        'image': 'assets/images/educ/sheath_blight.jpg',
        'title': 'Hidden Under the Leaves: Detecting Sheath Blight Early',
        'author': 'Campbell, J.',
        'date': 'February 22, 2015',
      },
      {
        'image': 'assets/images/educ/heat_stress.jpg',
        'title': 'Is It Just Heat Stress or Rice Yellowing Syndrome?',
        'author': 'Keung, H.',
        'date': 'December 1, 2022',
      },
      {
        'image': 'assets/images/educ/rice_immunity.jpg',
        'title': 'Simple Ways to Boost Rice Immunity Naturally',
        'author': 'McKinley, A.',
        'date': 'January 27, 2014',
      },
      {
        'image': 'assets/images/educ/soil_care.jpg',
        'title': 'Proper Soil Care for Stronger Rice Plants',
        'author': 'Junior, Q.',
        'date': 'April 16, 2011',
      },
      {
        'image': 'assets/images/educ/brown_spot.jpg',
        'title': 'Spotting Brown Spot Disease Before It Spreads',
        'author': 'Rodriguez, L.',
        'date': 'March 8, 2018',
      },
    ];

    
    // Filter out the current article and return up to 3 related articles
    return allArticles
        .where((article) => article['title'] != currentTitle)
        .take(3)
        .toList();
  }
}

class _RelatedArticleCard extends StatelessWidget {
  final String image;
  final String title;
  final String author;
  final String date;
  final bool isFavorited;
  final VoidCallback onToggleFavorite;
  final Map<String, Map<String, String>>? favoritedArticles;
  final Function(String, String, String, String)? onToggleFavoriteGlobal;

  const _RelatedArticleCard({
    required this.image,
    required this.title,
    required this.author,
    required this.date,
    required this.isFavorited,
    required this.onToggleFavorite,
    this.favoritedArticles,
    this.onToggleFavoriteGlobal,
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
              isFavorited: isFavorited,
              onToggleFavorite: onToggleFavorite,
              favoritedArticles: favoritedArticles,
              onToggleFavoriteGlobal: onToggleFavoriteGlobal,
            ),
          ),
        );
      },
      child: Container(
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
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.asset(
                image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$author  •  $date',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
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
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imagePath;

  const _FullScreenImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 64),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageGallery extends StatefulWidget {
  final int initialIndex;
  final List<String> imagePaths;

  const _ImageGallery({
    required this.initialIndex,
    required this.imagePaths,
  });

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.asset(
                    widget.imagePaths[index],
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.error, color: Colors.white, size: 64),
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 32,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.imagePaths.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
