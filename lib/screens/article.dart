import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late bool _isFavorited;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.isFavorited;
  }

  Future<void> _localToggleFavorite() async {
    setState(() {
      _isFavorited = !_isFavorited;
    });
    widget.onToggleFavorite();

    // Also save to backend
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in, cannot save bookmark');
      return;
    }
    print('Saving bookmark for: ${widget.title}, favorited: $_isFavorited');

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('articles');

      if (_isFavorited) {
        await docRef.set({
          widget.title: {
            'image': widget.image,
            'author': widget.author,
            'date': widget.date,
          },
        }, SetOptions(merge: true));
      } else {
        // Check if document exists before trying to update
        final doc = await docRef.get();
        if (doc.exists) {
          await docRef.update({widget.title: FieldValue.delete()});
        }
      }
    } catch (e) {
      print('Error in article _localToggleFavorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFFEFEF1);
    const Color darkGreen = Color(0xFF2E7D32);

    // Check which disease article this is
    final bool isRYS = widget.title == 'Rice Yellowing Syndrome';
    final bool isBrownSpot = widget.title.toLowerCase().contains('brown spot');
    final bool isSheathBlight = widget.title.toLowerCase().contains(
      'sheath blight',
    );
    final bool isDiseaseArticle = isRYS || isBrownSpot || isSheathBlight;

    // Determine if this article should show symptoms section
    final bool shouldShowSymptoms =
        !widget.title.toLowerCase().contains('care') &&
        !widget.title.toLowerCase().contains('boost') &&
        !widget.title.toLowerCase().contains('manage');

    // Get related articles based on current article
    final List<Map<String, String>> relatedArticles = _getRelatedArticles(
      widget.title,
    );

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
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                            children: [
                              TextSpan(
                                text: _isTranslated
                                    ? 'Ang Rice Yellowing Syndrome (RYS) ay isang umuusbong na kompleks ng sakit sa halaman na nakaaapekto sa '
                                    : 'Rice Yellowing Syndrome (RYS) is an emerging plant disease complex affecting ',
                              ),
                              const TextSpan(
                                text: 'Oryza sativa',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              TextSpan(
                                text: _isTranslated
                                    ? ' sa iba\'t ibang rehiyon na nagtatanim ng palay. Hindi ito kagaya ng karaniwang impeksiyon na dulot ng iisang virus; ang RYS ay isang '
                                    : ' in multiple rice-growing regions. Unlike single-virus infections, RYS is a ',
                              ),
                              const TextSpan(
                                text: 'mixed-infection syndrome',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              TextSpan(
                                text: _isTranslated
                                    ? ' na karaniwang kinasasangkutan ng '
                                    : ', most commonly involving ',
                              ),
                              const TextSpan(
                                text: 'Rice Ragged Stunt Virus (RRSV)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              TextSpan(text: _isTranslated ? ' at ' : ' and '),
                              const TextSpan(
                                text: 'Rice Grassy Stunt Virus (RGSV)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              TextSpan(
                                text: _isTranslated
                                    ? '. Ang dalawang virus na ito ay ipinapasa ng '
                                    : '. These viruses are transmitted by the ',
                              ),
                              const TextSpan(
                                text: 'brown planthopper (Nilaparvata lugens)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              TextSpan(
                                text: _isTranslated
                                    ? ', isang pangunahing peste ng palay na ang ekolohiya ay may direktang impluwensya sa pagkalat at tindi ng sakit.\n\nKinikilala ang RYS sa pamamagitan ng paninilaw ng dahon, paghina ng paglaki ng halaman, deformadong mga istruktura ng halaman, at malaking pagbaba ng ani. Dahil kahawig nito ang mga sintomas ng kakulangan sa sustansya at iba pang viral diseases, nagiging hamon ang tamang pag-diagnose at madalas na hindi ito natutukoy hanggang malawak na ang pinsala.'
                                    : ', a major rice pest whose ecology directly influences the spread and severity of the disease. RYS is characterized by leaf discoloration, impaired vegetative development, malformed plant structures, and major grain yield losses. Because symptoms overlap with nutrient deficiencies and other viral diseases, RYS poses diagnostic challenges and often goes unrecognized until damage becomes widespread.',
                              ),
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
                        Text(
                          _isTranslated ? 'Mga Sanhi' : 'Causes',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isTranslated
                              ? 'Hindi dulot ng isang pathogen ang RYS; nabubuo ito dahil sa sabayang impeksiyon, na kadalasang kinasasangkutan ng RRSV at RGSV:'
                              : 'RYS is not caused by a single pathogen; instead, it results from co-infection, most frequently by RRSV and RGSV:',
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
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
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            _isTranslated
                                ? '• Nagdudulot ng ragged o nagniniwang gilid ng dahon, baluktot na paglaki, at balingasong mga palay.\n\n• Pinapahina ang pagbuo ng butil dahil sa pagkasira ng tisyu at problema sa paglipat ng sustansya.'
                                : '• Causes ragged or serrated leaf margins, twisted growth, and deformed panicles.\n\n• Reduces grain development due to impaired translocation and tissue distortion.',
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
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
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            _isTranslated
                                ? '• Nagdudulot ng sobrang pagsasanga, maputla o naninilaw na dahon, at matinding pagkabansot.\n\n• Maaaring magkaroon ng maraming sanga ngunit kakaunti o walang spikelets na nabubuo.'
                                : '• Induces excessive tillering, pale green or yellowish leaves, and severe stunting.\n\n• Infected plants may produce abundant tillers but very few or no panicles.',
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        RichText(
                          textAlign: TextAlign.justify,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                            children: [
                              TextSpan(
                                text: _isTranslated
                                    ? 'Kapag sabay na naapektuhan ang isang halaman ng dalawang virus, tumitindi ang kanilang epekto, na nagreresulta sa mas malalang sintomas kaysa kung isa lamang ang kumikilos. Ito ang dahilan kung bakit tinatawag itong syndrome at hindi simpleng sakit na dulot ng virus.\n\nParehong ipinapasa ng '
                                    : 'When both viruses infect the same plant, their physiological impacts intensify, resulting in more severe symptoms than either virus would cause independently. This interaction is what defines the condition as a syndrome rather than a conventional viral disease.\n\nBoth viruses are transmitted by the ',
                              ),
                              const TextSpan(
                                text: 'brown planthopper (BPH)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              TextSpan(
                                text: _isTranslated
                                    ? ' ang dalawang virus, kaya nagiging posible ang sabayang impeksiyon habang ito ay sumisipsip sa halaman. Ang mataas na populasyon ng BPH, na naaapektuhan ng klima, pamamahala sa bukid, at maling paggamit ng pestisidyo, ay nagpapataas ng insidente ng RYS.'
                                    : ', allowing simultaneous infection to occur during feeding. High BPH populations, influenced by climate, field management, and pesticide misuse, significantly increase RYS incidence.',
                              ),
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
                                  imagePath:
                                      'assets/images/diseases/rys/ryscause.png',
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
                      ] else if (isBrownSpot) ...[
                        // Brown Spot Disease content
                        _buildDiseaseIntro(
                          'Brown Spot is a major fungal disease of Oryza sativa, caused by Bipolaris oryzae (syn. Helminthosporium oryzae), and is considered one of the most damaging leaf diseases in rice production systems. Although not new, it remains highly persistent due to its ability to survive on infected seeds, plant debris, and in nutrient-poor soils.',
                        ),
                        const SizedBox(height: 14),
                        _buildDiseaseIntro(
                          'Brown Spot affects rice at all growth stages, from seedling establishment to grain filling, leading to poor stand, reduced leaf area, weakened plant physiology, and significant yield decline. Because its symptoms resemble those of nutrient deficiency—especially potassium deficiency—Brown Spot may be misdiagnosed in early phases, resulting in delayed management and wider field impact.',
                        ),
                        const SizedBox(height: 28),
                      ] else if (isSheathBlight) ...[
                        // Sheath Blight Disease content
                        _buildDiseaseIntro(
                          'Sheath Blight is a major fungal disease of Oryza sativa, caused by Rhizoctonia solani, and is considered one of the most economically damaging diseases in intensified rice production systems. Although long recognized, it remains difficult to control due to its wide host range, ability to persist in soil, and rapid spread through dense canopies.',
                        ),
                        const SizedBox(height: 14),
                        _buildDiseaseIntro(
                          'Sheath Blight affects rice from tillering to reproductive stages, leading to lodged plants, reduced grain filling, weakened stems, and significant yield losses. Because early symptoms can resemble nutrient-related sheath discoloration or insect injury, Sheath Blight is often underestimated until lesions expand rapidly across the crop.',
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

                      // Causes section (for disease articles)
                      if (shouldShowSymptoms) ...[
                        Text(
                          _isTranslated ? 'Mga Sanhi' : 'Causes',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (isBrownSpot) ...[
                          _buildDiseaseIntro(
                            'Brown Spot is caused by the necrotrophic fungus Bipolaris oryzae (formerly Helminthosporium oryzae or Cochliobolus miyabeanus). This pathogen thrives on weakened, stressed, or nutrient-deficient rice plants, especially when nitrogen and silica levels are low. B. oryzae initiates seedborne or soilborne inoculum, germinates on damp leaf surfaces, and penetrates host tissue through stomata or direct cuticle breach. Once inside, it secretes host-selective toxins that induce necrosis, leading to characteristic brown lesions on leaves, leaf sheaths, and glumes.',
                          ),
                          const SizedBox(height: 14),
                          _buildDiseaseIntro(
                            'As the infection progresses, mature conidia are formed on the lesion surface and dispersed by wind, water splash, or human handling. Under prolonged leaf wetness (8–12 hours) and moderate temperatures (20–30°C), secondary cycles occur rapidly, amplifying disease pressure. Epidemics are particularly severe in rainfed lowlands or unfavorable upland conditions where soil fertility is marginal. In such environments, Brown Spot not only causes widespread foliar damage but also infects the grain directly, reducing both quality and marketability. Over time, repeated cycles in poorly managed fields sustain the fungus in crop residues and seed stocks, enabling recurrence in subsequent planting seasons.',
                          ),
                          const SizedBox(height: 28),
                        ] else if (isSheathBlight) ...[
                          _buildDiseaseIntro(
                            'Sheath Blight is caused by the soil-borne fungus Rhizoctonia solani AG-1 IA. Unlike pathogens that rely primarily on airborne spores, R. solani persists as sclerotia in soil, stubble, and organic matter between cropping seasons. Upon flooding or high soil moisture, sclerotia germinate and produce mycelium that floats on water films or spreads along the plant base. Infection typically begins on the lower leaf sheaths near the waterline, where the fungus establishes an initial lesion. From there, it forms a thick, white mycelial mat that climbs upward on the plant and spreads laterally to adjacent tillers via leaf-to-leaf contact.',
                          ),
                          const SizedBox(height: 14),
                          _buildDiseaseIntro(
                            'R. solani thrives in conditions of high humidity, dense plant canopies, and excessive nitrogen application. Overfertilization with nitrogen encourages lush vegetative growth but also increases canopy closure, reducing air circulation and light penetration. This microenvironment favors rapid mycelial proliferation. The pathogen damages host cells by secreting enzymes and toxins, leading to water-soaked lesions that eventually turn tan to gray with brown borders. Under severe infections, leaf blades become necrotic and collapse, sometimes resulting in lodging. The disease is self-sustaining: new sclerotia are produced on infected tissues and fall back to the soil or remain in stubble, perpetuating the cycle in subsequent crops.',
                          ),
                          const SizedBox(height: 28),
                        ] else if (isRYS) ...[
                          _buildDiseaseIntro(
                            'Rice Yellowing Syndrome (RYS) results from a complex interplay of viral and environmental factors, not a single pathogen. It is strongly associated with Rice Ragged Stunt Virus (RRSV), Rice Grassy Stunt Virus (RGSV), and Orange Leaf Phytoplasma, though additional agents may be involved. These pathogens disrupt nutrient mobilization, hormone balance, and photosynthetic activity, leading to chlorosis, stunting, and excessive tillering.',
                          ),
                          const SizedBox(height: 14),
                          _buildDiseaseIntro(
                            'Transmission occurs mainly through the Brown Planthopper (BPH), Nilaparvata lugens, a highly mobile insect vector capable of carrying multiple pathogens. When BPH populations are high—often triggered by warm, humid weather and lush vegetative growth from nitrogen-heavy fertilization—infection spreads rapidly across fields. The syndrome is especially severe in rainfed lowlands where water management is inconsistent and planting dates overlap, facilitating continuous vector activity.',
                          ),
                          const SizedBox(height: 28),
                        ],
                      ],

                      // Symptoms section (only for disease articles)
                      if (shouldShowSymptoms) ...[
                        Text(
                          _isTranslated ? 'Mga Sintomas' : 'Symptoms',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (isBrownSpot) ...[
                          Text(
                            _isTranslated
                                ? 'Narito ang mga pangunahing palatandaan ng Brown Spot:'
                                : 'These are the primary indicators of Brown Spot disease:',
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
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
                                    text:
                                        '• Brown Leaf Spots (Kayumangging Peklat sa Dahon) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Small to large oval or circular lesions with dark brown borders and gray to tan centers, commonly appearing on older leaves.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                        '• Leaf Blight (Pagkalanta ng Dahon) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Extensive necrosis leading to premature leaf senescence and reduced photosynthetic area, especially under severe infection.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                        '• Seedling Rot (Pagkabulok ng Punla) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Brown to black lesions on seed coats, coleoptiles, and young roots, resulting in poor germination and stunted seedlings.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                        '• Reduced Tillering (Kulang sa Sanga) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Limited tiller production due to overall plant weakening and nutrient stress.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                        '• Poor Grain Filling (Mahinang Pagbubutil) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Infection of panicles and glumes leads to incomplete or malformed grains, reducing overall yield and quality.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ] else if (isSheathBlight) ...[
                          Text(
                            _isTranslated
                                ? 'Narito ang mga pangunahing palatandaan ng Sheath Blight:'
                                : 'These are the primary indicators of Sheath Blight disease:',
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
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
                                    text:
                                        '• Water-Soaked Lesions on Leaf Sheaths (Mga Batik sa Dayami ng Dahon) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Initial greenish-gray lesions near the waterline, later expanding upward and becoming tan to brown with dark irregular borders.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                        '• White Fungal Mat (Puting Sapot) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Dense white to pale gray mycelium visible on infected sheaths during humid conditions, facilitating disease spread.\n\n',
                                  ),
                                  TextSpan(
                                    text: '• Lodging (Pagkahiga ng Palay) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Weakened stems and sheaths cause plants to topple, especially in dense stands with heavy panicles.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                        '• Upward Spread to Leaf Blades (Pag-akyat ng Sakit) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Lesions extend from sheaths to leaf blades, leading to large necrotic areas and accelerated leaf senescence.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                        '• Incomplete Grain Filling (Mahinang Pagbubutil) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Disrupted nutrient flow results in poor grain development and yield loss.\n\n',
                                  ),
                                  TextSpan(
                                    text:
                                        '• Sclerotia Formation (Itim na Bilog-Bilog) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Small, dark, hard sclerotia form on infected tissues and serve as survival structures for the fungus.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ] else if (isRYS) ...[
                          Text(
                            _isTranslated
                                ? 'Narito ang limang pangunahing palatandaan ng RYS:'
                                : 'These are the five hallmark indicators, including their Filipino terms to reflect field-level usage:',
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
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
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  height: 1.8,
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                        '• Yellow Leaves (Naninilaw na Dahon) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _isTranslated
                                        ? 'Pantay o patse-patseng paninilaw, kadalasang nagsisimula sa ibabang dahon at umaakyat.\n\n'
                                        : 'Uniform or patchy yellowing, typically starting from the lower leaves and progressing upward.\n\n',
                                  ),
                                  const TextSpan(
                                    text:
                                        '• Stunted Growth (Pandak o Kulang sa Paglaki) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _isTranslated
                                        ? 'Pag-ikli ng internodes at kabuuang tangkad, minsan ay nagdudulot ng sobrang pandak na halaman.\n\n'
                                        : 'Internode shortening and reduced plant height, sometimes resulting in severely dwarfed plants.\n\n',
                                  ),
                                  const TextSpan(
                                    text: '• Excess Tillers (Sobrang Sanga) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _isTranslated
                                        ? 'Labis na pagsasanga na nagbibigay ng mukhang mabuhok o parang damo ang halaman.\n\n'
                                        : 'Abnormally high tiller production that gives the plant a bushy or grassy appearance.\n\n',
                                  ),
                                  const TextSpan(
                                    text:
                                        '• Twisted Leaves (Baluktot na Dahon) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _isTranslated
                                        ? 'Pagkakabaluktot o pagrolyo ng dahon, lalo na kapag naimpeksiyon ng RRSV.\n\n'
                                        : 'Leaf rolling, twisting, or distortion, especially under RRSV influence.\n\n',
                                  ),
                                  const TextSpan(
                                    text:
                                        '• Empty Grains (Walang Laman na Butil) – ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkGreen,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _isTranslated
                                        ? 'Nagkakaroon ng palay ngunit hindi napupuno ang mga spikelet, na nagreresulta sa mataas na sterility at pagbagsak ng ani.'
                                        : 'Panicles that develop but fail to fill grains, leading to high sterility and yield collapse.',
                                  ),
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
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
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

                      // Epidemiology and Global sections (disease articles)
                      if (isBrownSpot) ...[
                        Text(
                          _isTranslated ? 'Epidemiolohiya' : 'Epidemiology',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildDiseaseIntro(
                          'Brown Spot epidemics are driven by the interaction of seedborne and soilborne inoculum, environmental conditions, and host susceptibility. The fungus overwinters on crop residues, infected seed, and alternate weed hosts. When susceptible seeds are planted, early seedling infections provide a source of inoculum that spreads through conidia dispersed by wind, rain splash, or irrigation water. Prolonged periods of leaf wetness (≥8 hours) combined with moderate temperatures (20–30°C) are critical for conidial germination and penetration.',
                        ),
                        const SizedBox(height: 14),
                        _buildDiseaseIntro(
                          'Disease severity is exacerbated by nutrient deficiencies, particularly nitrogen and silicon, which weaken plant defenses. Rainfed lowlands, upland rice systems with marginal soils, and areas with erratic rainfall patterns are especially prone to severe Brown Spot outbreaks. Secondary infection cycles occur rapidly under conducive conditions, leading to widespread foliar damage and grain infection. In addition, the pathogen can persist on weed hosts and volunteer rice plants, maintaining inoculum levels between cropping seasons. Poor seed health practices, such as using infected seed or failing to treat seed before planting, perpetuate the disease cycle and increase epidemic risk.',
                        ),
                        const SizedBox(height: 28),

                        Text(
                          _isTranslated
                              ? 'Pandaigdigang at Paglaganap sa Pilipinas'
                              : 'Global and Philippine Occurrence',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildDiseaseIntro(
                          'Brown Spot occurs in virtually all rice-growing regions worldwide, from Asia to Africa, Latin America, and parts of the United States. It is a chronic problem in rainfed lowland and upland ecosystems where soil fertility is suboptimal. In Asia, countries such as India, Bangladesh, Thailand, Vietnam, Indonesia, and the Philippines regularly report Brown Spot as a yield-limiting factor, particularly during seasons with erratic rainfall or drought stress.',
                        ),
                        const SizedBox(height: 14),
                        _buildDiseaseIntro(
                          'In the Philippines, Brown Spot is endemic across rice-producing provinces. It is most problematic in rainfed areas with nutrient-poor soils, such as upland rice systems in Mindanao and marginally fertile lowlands in Visayas and Luzon. The disease is often observed during the wet season when leaf wetness is prolonged, but it can also flare up during dry spells that stress plants and make them more susceptible to infection. The Philippine Rice Research Institute (PhilRice) and the Department of Agriculture have documented recurring Brown Spot outbreaks, emphasizing the need for improved seed health, balanced fertilization, and resistant varieties to manage this persistent disease.',
                        ),
                        const SizedBox(height: 28),
                      ] else if (isSheathBlight) ...[
                        Text(
                          _isTranslated ? 'Epidemiolohiya' : 'Epidemiology',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildDiseaseIntro(
                          'Sheath Blight epidemics are driven by soilborne inoculum in the form of sclerotia, which survive in soil and crop residues between seasons. Upon flooding, sclerotia float to the water surface and germinate, producing mycelium that infects the lower leaf sheaths. Initial infections typically occur near the waterline during the tillering to booting stages. From there, the fungus spreads upward and laterally via mycelial growth and leaf-to-leaf contact, especially in dense canopies with high humidity.',
                        ),
                        const SizedBox(height: 14),
                        _buildDiseaseIntro(
                          'Key factors promoting Sheath Blight include: (1) high plant density and excessive nitrogen fertilization, which lead to lush vegetative growth and canopy closure; (2) prolonged periods of high humidity and warm temperatures (25–32°C); and (3) continuous flooding that facilitates sclerotial germination and mycelial spread. The disease is often more severe in high-yielding, modern varieties that have dense canopies. Under optimal conditions for the pathogen, lesions expand rapidly, coalesce, and cause extensive sheath and leaf blade necrosis. The cycle perpetuates as new sclerotia form on infected tissues and return to the soil, ensuring recurrence in subsequent crops.',
                        ),
                        const SizedBox(height: 28),

                        Text(
                          _isTranslated
                              ? 'Pandaigdigang at Paglaganap sa Pilipinas'
                              : 'Global and Philippine Occurrence',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildDiseaseIntro(
                          'Sheath Blight is a major constraint to rice production worldwide, with significant impacts in Asia, particularly in irrigated lowland systems. It is endemic in countries such as China, India, Japan, Korea, Vietnam, Thailand, Indonesia, and the Philippines. The disease thrives in intensive rice cultivation systems where high-yielding varieties, dense planting, and heavy nitrogen application are common practices.',
                        ),
                        const SizedBox(height: 14),
                        _buildDiseaseIntro(
                          'In the Philippines, Sheath Blight is prevalent in irrigated lowlands across Central Luzon, Western Visayas, and other major rice-producing regions. The disease is a recurring problem during the wet season when humidity is high and canopy density is greatest. PhilRice and the Department of Agriculture have identified Sheath Blight as one of the top biotic constraints to rice yield. Management efforts focus on optimizing nitrogen use, improving canopy ventilation through proper spacing and water management, and deploying moderately resistant varieties. Despite these efforts, Sheath Blight remains a persistent challenge, particularly in high-input, high-yield production systems.',
                        ),
                        const SizedBox(height: 28),
                      ] else if (isRYS) ...[
                        Text(
                          _isTranslated ? 'Epidemiolohiya' : 'Epidemiology',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        RichText(
                          textAlign: TextAlign.justify,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                            children: [
                              TextSpan(
                                text: _isTranslated
                                    ? 'Malapit na nakaugnay ang epidemiolohiya ng RYS sa populasyon ng '
                                    : 'The epidemiology of RYS is tightly connected to ',
                              ),
                              const TextSpan(
                                text: 'BPH',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              TextSpan(
                                text: _isTranslated
                                    ? '. Tumataas ang paglitaw ng sakit kapag laganap ang mga kundisyong pabor sa pagdami ng populasyon gaya ng:'
                                    : ' ecology. Outbreaks align with conditions that favor vector population growth:',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            _isTranslated
                                ? '• mainit na klima,\n\n• mataas na halumigmig,\n\n• tuluy-tuloy o magkadikit na pagtatanim ng palay,\n\n• labis na paggamit ng nitrogen, at\n\n• maling paggamit ng pestisidyo na pumapatay sa natural na kaaway ng BPH.'
                                : '• warm temperatures,\n\n• high humidity,\n\n• continuous or overlapping rice cropping,\n\n• excessive nitrogen fertilization, and\n\n• pesticide misuse that eliminates natural predators.',
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isTranslated
                              ? 'Dahil nananatili ang mga virus sa populasyon ng BPH, kahit kaunting bilang ng mga insekto ay sapat upang magsimula ng impeksiyon sa bukid. Kapag marami ang populasyon, maaari itong kumalat sa loob lamang ng ilang linggo.'
                              : 'Because both viruses persist within BPH populations, even low numbers of viruliferous insects can initiate field-level infections. In the presence of abundant vectors, rapid disease spread can occur within weeks.',
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          _isTranslated
                              ? 'Paglitaw sa Mundo at sa Pilipinas'
                              : 'Global and Philippine Occurrence',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          _isTranslated
                              ? 'Sa Pandaigdigang Antas'
                              : 'Global Occurrence',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isTranslated
                              ? 'Naidokumento ang RYS sa iba\'t ibang bansang nagtatanim ng palay sa Asya, lalo na sa mga lugar na may pabagu-bagong populasyon ng BPH. Ang mga rehiyong gumagamit ng intensive rice–rice cropping systems ay mas madaling tamaan dahil tuloy-tuloy ang presensya ng host at virus.'
                              : 'RYS has been documented in multiple rice-producing countries in Asia, particularly where BPH densities fluctuate seasonally. Regions with intensive rice-rice cropping systems are more susceptible due to continuous vector–host contact.',
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          _isTranslated
                              ? 'Unang Pagkakatukoy sa Pilipinas'
                              : 'First Detection in the Philippines',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          textAlign: TextAlign.justify,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.8,
                            ),
                            children: [
                              TextSpan(
                                text: _isTranslated ? 'Inirekord ng ' : 'The ',
                              ),
                              const TextSpan(
                                text:
                                    'International Rice Research Institute (IRRI)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              TextSpan(
                                text: _isTranslated
                                    ? ' ang unang kumpirmadong kaso ng RYS sa bansa sa pamamagitan ng molecular testing na nagpakita ng sabayang impeksiyon ng RGSV at RRSV sa mga halaman na may sintomas.\n\nDahil sa katuklasang ito, nakita ang kahalagahan ng pagkilala sa RYS mula sa tungro at nutrient deficiencies, na dati\'y nagdulot ng maling diagnosis.\n\nKasunod nito, napansin ang mabilis na pagkalat ng sakit sa '
                                    : ' recorded the first confirmed RYS case in the Philippines through molecular testing that revealed RGSV–RRSV co-infection in symptomatic rice plants. The discovery highlighted the importance of differentiating RYS from tungro and nutrient-related yellowing, which had previously led to misdiagnoses.\n\nFollowing this detection, field observations in ',
                              ),
                              const TextSpan(
                                text: 'CALABARZON',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              TextSpan(
                                text: _isTranslated
                                    ? ' at iba pang rehiyon na may pagtaas ng populasyon ng BPH. Naglunsad ang Department of Agriculture ng mga pagsasanay at kampanya upang makatulong sa mga magsasaka sa pagtukoy at pamamahala ng sakit.\n\nAng pagtuklas na ito ay nagmarka ng isang mahalagang pagbabago sa plant health surveillance at nagpatunay na may bagong kompleks na banta sa sistemang produksyon ng palay sa Pilipinas.'
                                    : ' and other regions noted rapid disease spread associated with BPH surges. The Department of Agriculture initiated awareness and training programs to help farmers recognize the syndrome and implement control measures.\n\nThis detection marked a critical shift in plant health surveillance, emphasizing the arrival of a new, complex viral threat to Philippine rice systems.',
                              ),
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
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                height: 120,
                                                color: Colors.green[200],
                                              ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.6,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                        if (isBrownSpot) ...[
                          Text(
                            _isTranslated
                                ? 'Agarang Mga Hakbang'
                                : 'Immediate Rescue Measures',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            _isTranslated
                                ? '1. Alisin ang mga Apektadong Punla'
                                : '1. Remove Infected Seedlings',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Tanggalin at sunugin ang mga punlang may malubhang impeksyon upang mabawasan ang pinagmulan ng sakit sa taniman.'
                                  : 'Remove and burn heavily infected seedlings to reduce inoculum sources in the field.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _isTranslated
                                ? '2. Pahusayin ang Nutrisyon ng Halaman'
                                : '2. Improve Plant Nutrition',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Maglagay ng tamang dami ng nitrogenong pataba at silica upang mapalakas ang depensa ng halaman laban sa B. oryzae.'
                                  : 'Apply balanced nitrogen and silica fertilization to strengthen plant defenses against B. oryzae.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _isTranslated
                                ? '3. Mag-apply ng Fungicide'
                                : '3. Apply Fungicides',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Gumamit ng rehistradong fungicide tulad ng tricyclazole, carbendazim, o propiconazole batay sa lokong rekomendasyon at mga gabay sa paggamit.'
                                  : 'Use registered fungicides such as tricyclazole, carbendazole, or propiconazole following local recommendations and application guidelines.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _isTranslated
                                ? '4. Gumamit ng Malusog na Binhi'
                                : '4. Use Healthy Seeds',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Piliin ang mga sertipikadong binhi at tratuhin ang mga ito gamit ang hot water o kemikal na seed treatment upang patayin ang pathogen.'
                                  : 'Select certified seeds and treat them with hot water or chemical seed treatments to eliminate seed-borne pathogens.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _isTranslated
                                ? '5. Pamahalaan ang mga Natitirang Pananim'
                                : '5. Manage Crop Residues',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Araruhin o sunugin ang mga natitira sa ani upang mabawasan ang patuloy na pinagmulan ng inoculum sa lupa.'
                                  : 'Plow under or burn crop residues to reduce carry-over inoculum in the soil.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ] else if (isSheathBlight) ...[
                          Text(
                            _isTranslated
                                ? 'Agarang Mga Hakbang'
                                : 'Immediate Rescue Measures',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            _isTranslated
                                ? '1. Pamahalaan ang mga Nakahigang Halaman'
                                : '1. Manage Lodged Areas',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Tanggalin o gupitin ang mga talagang malubhang nakahigang halaman upang mapahusay ang daloy ng hangin at mabawasan ang mycelial spread.'
                                  : 'Remove or cut severely lodged plants to improve air circulation and reduce mycelial spread.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _isTranslated
                                ? '2. Pahusayin ang Bentilasyon ng Canopy'
                                : '2. Improve Canopy Aeration',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Gumamit ng tamang spacing at iwasan ang sobrang nitrogen upang mabawasan ang siksikan ng canopy.'
                                  : 'Use proper spacing and avoid excessive nitrogen to reduce canopy density.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _isTranslated
                                ? '3. Mag-apply ng Fungicide'
                                : '3. Apply Fungicides',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Gumamit ng rehistradong fungicide tulad ng azoxystrobin, validamycin, o hexaconazole sa panahon ng active tillering hanggang booting stage.'
                                  : 'Use registered fungicides such as azoxystrobin, validamycin, or hexaconazole during active tillering to booting stage.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _isTranslated
                                ? '4. I-optimize ang Fertilizer Application'
                                : '4. Optimize Fertilizer Application',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Iwasan ang sobrang nitrogen at magbalanse ng potassium at phosphorus upang mapalakas ang halaman nang hindi tumataas ang susceptibility.'
                                  : 'Avoid excessive nitrogen and balance potassium and phosphorus to strengthen plants without increasing susceptibility.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _isTranslated
                                ? '5. Pamahalaan ang Tubig'
                                : '5. Manage Water',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Gumamit ng alternate wetting and drying (AWD) o iba pang diskarteng water management upang mabawasan ang tuloy-tuloy na baha na nakakatulong sa pagkalat ng sclerotia.'
                                  : 'Use alternate wetting and drying (AWD) or other water management strategies to reduce continuous flooding that facilitates sclerotial germination.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ] else if (isRYS) ...[
                          Text(
                            _isTranslated
                                ? 'Agarang Mga Hakbang'
                                : 'Immediate Rescue Measures',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            _isTranslated
                                ? '1. Alisin ang mga Apektadong Halaman'
                                : '1. Remove Infected Plants.',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Bunutin ang mga halamang may malinaw na sintomas at itapon ang mga ito nang malayo sa taniman. Nakababawas ito sa posibilidad ng pagkalat ng sakit.'
                                  : 'Pull out plants showing clear symptoms and dispose of them away from the field. This lowers the chance of the disease spreading.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _isTranslated
                                ? '2. Kontrolin ang mga Insektong Nagpapakalat ng Sakit'
                                : '2. Control the Insects That Spread the Disease',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Ang RYS ay konektado sa mga leafhopper at planthopper. Gumamit lamang ng insecticide kapag kinakailangan at i-rotate ang mga kemikal upang maiwasan ang imunidad. Makakatulong din ang mga likas na mandaragit ng mga naturang insekto sa pagkontrol ng kanilang populasyon.'
                                  : 'RYS is linked to leafhoppers and planthoppers. Use insecticides only when needed and rotate chemicals to avoid resistance. Natural predators can also help control vector populations.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _isTranslated
                                ? '3. Pagandahin ang Nutrisyon ng Halaman'
                                : '3. Improve Plant Nutrition.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Ang balanseng pataba, lalo na ang potasa at silikon, ay nakatutulong sa mga halaman na makayanan ang impeksiyon. Iwasan ang sobrang nitrogeno dahil ito\'y nakaaakit ng insekto at nagpapahina sa resistensya ng halaman.'
                                  : 'Balanced fertilizer, especially potassium and silicon, helps plants cope with infection. Avoid too much nitrogen, which attracts insects and weakens plant resistance.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _isTranslated
                                ? '4. Panatilihing Tuloy-tuloy Ang Daloy ng Tubig'
                                : '4. Keep Water Levels Steady.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Panatilihin ang mababaw ngunit tuloy-tuloy na pagdaloy ng tubig. Nakababawas ito ng stress sa halaman at nililimitahan nito sa paggalaw ang mga insektong nagdadala ng sakit.'
                                  : 'Maintain shallow, continuous flooding during outbreaks. This reduces stress on plants and helps limit vector movement.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _isTranslated
                                ? '5. Magsagawa ng Maagang Anihan Kapag Mabilis Nang Kumakalat ang Sakit'
                                : '5. Harvest Early if Damage Is Spreading Fast',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Kung mabilis na lumalala ang RYS sa bukirin at apektado na ang grain filling, magsagawa agad ng maagang anihan upang mailigtas pa ang anumang butil na maaari pang maisalba. Ang paghihintay nang mas matagal ay maaaring magresulta sa kakaunting ani.'
                                  : 'If RYS is rapidly advancing across the field and grain filling is already compromised, perform an early harvest to save whatever viable grains remain. Waiting too long may lead to almost zero yield.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            _isTranslated
                                ? '6. Itala ang Lawak at Tindi ng Pinsala'
                                : '7. Document the Affected Area and Severity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              _isTranslated
                                  ? 'Tignan kung:\n• saan nagsimula ang mga sintomas,\n\n• gaano ito kabilis kumalat, at\n\n• aling bahagi ng taniman ang pinakaapektado.\n\nMakakatulong ito sa pagpaplano ng susunod na pagtatanim, pagkuha ng tulong mula sa pamahalaan, at pangangasiwa ng bukid sa hinaharap, kahit ang agarang layunin ay pagsalba lamang ng natitirang ani.'
                                  : 'Record:\n• where the symptoms started,\n\n• how fast they spread, and\n\n• which plots were most affected.\n\nThis helps in planning replanting, accessing government aid, and guiding future field management, even if the immediate goal is salvage.',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
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

                        if (isBrownSpot)
                          const Text(
                            'Dawe, D. (2000). Rice research and production in the 21st century: The "Brown Spot" problem. Journal of Agriculture in the Tropics and Subtropics, 101(1), 1–16.\n\nInternational Rice Research Institute (IRRI). (2013). Brown Spot of Rice. Rice Knowledge Bank. Retrieved from https://www.knowledgebank.irri.org/training/fact-sheets/pest-management/diseases/item/brown-spot\n\nLore, J. S., Hunjan, M. S., & Kaur, H. (2012). Management of brown spot of rice caused by Bipolaris oryzae. Plant Disease Research, 27(2), 156–162.\n\nMew, T. W., & Gonzales, P. (2002). A Handbook of Rice Seedborne Fungi. International Rice Research Institute and Science Publishers, Inc.\n\nOu, S. H. (1985). Rice Diseases (2nd ed.). Commonwealth Mycological Institute, Kew, Surrey, England.\n\nPadmanabhan, S. Y. (1973). The Great Bengal Famine. Annual Review of Phytopathology, 11, 11–26.\n\nPhilippine Rice Research Institute (PhilRice). (2020). Brown Spot Disease Management Guide. Retrieved from https://www.philrice.gov.ph/\n\nSavary, S., Willocquet, L., Elazegui, F. A., Castilla, N. P., & Teng, P. S. (2000). Rice pest constraints in tropical Asia: Quantification of yield losses due to rice pests in a range of production situations. Plant Disease, 84(3), 357–369.\n\nSharma, T. R., Das, A., Thakur, S., & Devanna, B. N. (2016). Genomic insights into rice brown spot resistance. Molecular Plant-Microbe Interactions, 29(7), 499–514.\n\nZeigler, R. S., & Barclay, A. (2008). The relevance of rice. Rice, 1(1), 3–10.',
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.black87,
                              height: 1.7,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else if (isSheathBlight)
                          const Text(
                            'Groth, D. E. (2008). Effects of cultivar resistance and single fungicide application on rice sheath blight, yield, and quality. Crop Protection, 27(7), 1125–1130.\n\nLee, F. N., & Rush, M. C. (1983). Rice sheath blight: A major rice disease. Plant Disease, 67(7), 829–832.\n\nMarshal, D., & Rush, M. C. (1980). Infection cushion formation on rice sheaths by Rhizoctonia solani. Phytopathology, 70(10), 947–950.\n\nOu, S. H. (1985). Rice Diseases (2nd ed.). Commonwealth Mycological Institute, Kew, Surrey, England.\n\nPhilippine Rice Research Institute (PhilRice). (2019). Sheath Blight Disease Management Guide. Retrieved from https://www.philrice.gov.ph/\n\nSavary, S., Castilla, N. P., Willocquet, L., & Elazegui, F. A. (2001). Quantification and modeling of crop losses: A review of purposes. Annual Review of Phytopathology, 39, 357–390.\n\nSharma, A., McClung, A. M., Pinson, S. R. M., Kepiro, J. L., Shank, A. R., & Tabien, R. E. (2009). Genetic mapping of sheath blight resistance QTLs within tropical japonica rice cultivars. Crop Science, 49(1), 256–264.\n\nTzeng, D. D., DeVay, J. E., & Wakeman, R. J. (1990). Influence of nitrogen and plant age on the severity of rice sheath blight. Plant Disease, 74(1), 1–4.\n\nZhang, C. Q., Xu, Z. G., Wang, D. W., & Yang, J. Y. (2012). Advances in research on sheath blight of rice. Acta Agronomica Sinica, 38(10), 1711–1722.',
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.black87,
                              height: 1.7,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else if (isRYS)
                          const Text(
                            'Agris FAO. (n.d.). Yellowing syndrome of rice: Etiology, current status and future challenges. Retrieved from https://agris.fao.org/search/en/providers/125429/records/6851870f53e52c13fc771b08\n\nAgris FAO. (n.d.). Rice yellowing syndrome in Southeast Asia. Retrieved from https://agris.fao.org/search/en/providers/122430/records/64724e60e17b74d2224fc3df\n\nCalabarzon Department of Agriculture. (2023). Pagsasanay ng DA-4A RCPC: Tugon sa lumalaganap na rice yellowing disease. Retrieved from https://calabarzon.da.gov.ph/pagsasanay-ng-da-4a-rcpc-tugon-sa-lumalaganap-na-rice-yellowing-disease/\n\nHibino, H. (1996). Yellowing syndrome of rice: Etiology, current status and future challenges. Advances in Disease Vector Research, pp. 357–368. Retrieved from https://books.google.com.ph/books?hl=en&lr=&id=-eYxYP4jC5MC&oi=fnd&pg=PA357&dq=rice+yellowing+syndrome\n\nInternational Rice Research Institute. (2022). What is rice yellowing syndrome? IRRI identifies the first case in the Philippines. Rice News Today. Retrieved from https://ricenewstoday.com/what-is-rice-yellowing-syndrome-irri-identifies-the-first-case-in-the-philippines/\n\nSritag Journal. (2022). Innovative techniques in agriculture: Effects of viral diseases on rice production. Retrieved from https://d1wqtxts1xzle7.cloudfront.net/88375789/SRITAG-02-00045-libre.pdf\n\nZhang, S., Li, X., & Nguyen, V. (2015). Yellowing syndrome of rice: Etiology, current status, and future challenges. ResearchGate. https://www.researchgate.net/publication/288941856_Yellowing_syndrome_of_rice_Etiology_current_status_and_future_challenges',
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.black87,
                              height: 1.7,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          const SizedBox.shrink(),
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
                                  'assets/images/educ/rice101.jpg',
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
                                      'assets/images/diseases/rys/sheathcover.jpg',
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
                                      'assets/images/educ/rys_home.jpg',
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
                        if (isRYS) ...[
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
                              icon: Icon(
                                Icons.translate,
                                color: _isTranslated
                                    ? darkGreen
                                    : Colors.black87,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: _localToggleFavorite,
                            icon: Icon(
                              _isFavorited
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
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

  Widget _buildDiseaseIntro(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.8),
    );
  }

  List<Map<String, String>> _getRelatedArticles(String currentTitle) {
    final allArticles = [
      {
        'image': 'assets/images/diseases/rys/sheathcover.jpg',
        'title': 'Hidden Under the Leaves: Detecting Sheath Blight Early',
        'author': 'Campbell, J.',
        'date': 'February 22, 2015',
      },
      {
        'image': 'assets/images/diseases/rys/ryspaddy.png',
        'title': 'Is It Just Heat Stress or Rice Yellowing Syndrome?',
        'author': 'Keung, H.',
        'date': 'December 1, 2022',
      },
      {
        'image': 'assets/images/educ/boost-rice-immunity.jpg',
        'title': 'Simple Ways to Boost Rice Immunity Naturally',
        'author': 'McKinley, A.',
        'date': 'January 27, 2014',
      },
      {
        'image': 'assets/images/educ/stronger-rice-plants.jpg',
        'title': 'Proper Soil Care for Stronger Rice Plants',
        'author': 'Junior, Q.',
        'date': 'April 16, 2011',
      },
      {
        'image': 'assets/images/diseases/rys/ryssymp.jpg',
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
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
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

  const _ImageGallery({required this.initialIndex, required this.imagePaths});

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
