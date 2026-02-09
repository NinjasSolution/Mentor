import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/mentor_model.dart';
import '../../services/mentor_service.dart';
import 'mentor_profile_screen.dart';

class MentorList extends StatefulWidget {
  const MentorList({super.key});

  @override
  State<MentorList> createState() => _MentorListState();
}

class _MentorListState extends State<MentorList> {
  final MentorService _mentorService = MentorService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Perfect Mentor')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for Mentor, Topics...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MentorModel>>(
              stream: _mentorService.getApprovedMentors(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No mentors available.'));

                final filteredMentors = snapshot.data!.where((mentor) {
                  final query = _searchQuery.toLowerCase();
                  return (mentor.name?.toLowerCase() ?? '').contains(query) || mentor.skills.join(', ').toLowerCase().contains(query);
                }).toList();

                return AnimationLimiter(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75),
                    itemCount: filteredMentors.length,
                    itemBuilder: (context, index) {
                      final mentor = filteredMentors[index];
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        columnCount: 2,
                        child: ScaleAnimation(
                          child: FadeInAnimation(
                            child: MentorCard(mentor: mentor),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MentorCard extends StatelessWidget {
  final MentorModel mentor;
  const MentorCard({Key? key, required this.mentor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MentorProfileScreen(mentor: mentor))),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Hero(
                tag: mentor.userId,
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: mentor.profilePicUrl != null ? NetworkImage(mentor.profilePicUrl!) : null,
                  child: mentor.profilePicUrl == null ? const Icon(Icons.person, size: 45, color: Colors.blue) : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(mentor.name ?? 'Mentor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(mentor.skills.join(', '), style: TextStyle(color: Colors.grey[600], fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text('4.9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
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
