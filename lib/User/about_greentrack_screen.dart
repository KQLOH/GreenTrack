import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutGreenTrackScreen extends StatelessWidget {
  const AboutGreenTrackScreen({super.key});

  static const Color _primary = Color(0xFF2D7A4F);
  static const Color _dark = Color(0xFF1A4731);
  static const Color _bg = Color(0xFFF0F6F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A4731), Color(0xFF2D7A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'About GreenTrack',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7EEDB0),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Color(0xFF1A4731),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'GreenTrack',
                        style: GoogleFonts.dmSerifDisplay(
                          color: Colors.white,
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Track recycling. Build greener habits.',
                        style: GoogleFonts.dmSans(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _headerChip('Version 1.0.0'),
                          _headerChip('Flutter'),
                          _headerChip('Supabase'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _infoCard(
                    icon: Icons.auto_stories_rounded,
                    iconBg: const Color(0xFFE8F5EE),
                    iconColor: const Color(0xFF3DAB6A),
                    title: 'Our Story',
                    child: Text(
                      'GreenTrack began with a simple idea: recycling should be easier to track, easier to understand, and more motivating for everyday users. Our team noticed that many people wanted to recycle more consistently, but often lacked clear information, measurable progress, and a sense of achievement.\n\n'
                          'What started as a small concept gradually developed into a more complete platform. GreenTrack introduced recycling record submissions, approval workflows, dashboard analytics, nearby station discovery, and monthly goals to help users turn small eco-friendly actions into long-term habits.\n\n'
                          'Today, GreenTrack reflects our belief that sustainability becomes more powerful when it is visible, rewarding, and part of daily life.',
                      style: GoogleFonts.dmSans(
                        color: Colors.grey.shade700,
                        height: 1.6,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _infoCard(
                    icon: Icons.flag_rounded,
                    iconBg: const Color(0xFFFBF3E3),
                    iconColor: const Color(0xFFE8A020),
                    title: 'Mission & Vision',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _miniText(
                          'Mission',
                          'To make recycling more practical, measurable, and rewarding through digital tools that encourage sustainable habits.',
                        ),
                        const SizedBox(height: 12),
                        _miniText(
                          'Vision',
                          'To support a future where individuals and communities can easily monitor their environmental impact and take greener action every day.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _infoCard(
                    icon: Icons.timeline_rounded,
                    iconBg: const Color(0xFFE8F0FA),
                    iconColor: const Color(0xFF4A90D9),
                    title: 'Key Milestones',
                    child: Column(
                      children: const [
                        _MilestoneTile(
                          title: 'Idea & Research',
                          subtitle:
                          'Identified recycling awareness, habit tracking, and station accessibility as core problems.',
                        ),
                        _MilestoneTile(
                          title: 'Prototype Development',
                          subtitle:
                          'Built user flows for profile management, recycling submissions, and admin verification.',
                        ),
                        _MilestoneTile(
                          title: 'Dashboard & Goals',
                          subtitle:
                          'Introduced analytics, monthly goals, and impact tracking to make user progress visible.',
                        ),
                        _MilestoneTile(
                          title: 'Station & Rewards Expansion',
                          subtitle:
                          'Added favourite stations, location discovery, and reward-driven engagement features.',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _infoCard(
                    icon: Icons.widgets_rounded,
                    iconBg: const Color(0xFFF1EAFE),
                    iconColor: const Color(0xFF9B6FD4),
                    title: 'Core Features',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _FeatureChip(label: 'Recycle Tracking'),
                        _FeatureChip(label: 'Dashboard Analytics'),
                        _FeatureChip(label: 'Monthly Goals'),
                        _FeatureChip(label: 'Station Discovery'),
                        _FeatureChip(label: 'Favourite Stations'),
                        _FeatureChip(label: 'Rewards & Points'),
                        _FeatureChip(label: 'Admin Approval'),
                        _FeatureChip(label: 'User Profile'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _infoCard(
                    icon: Icons.groups_rounded,
                    iconBg: const Color(0xFFE8F5EE),
                    iconColor: const Color(0xFF3DAB6A),
                    title: 'Project Credits',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GreenTrack was developed as an academic mobile application project focused on sustainability, usability, and environmental awareness.',
                          style: GoogleFonts.dmSans(
                            color: Colors.grey.shade700,
                            height: 1.6,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9F8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE3EEE6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _detailRow('Project Type', 'Academic Assignment'),
                              const SizedBox(height: 8),
                              _detailRow('Framework', 'Flutter'),
                              const SizedBox(height: 8),
                              _detailRow('Backend', 'Supabase'),
                              const SizedBox(height: 8),
                              _detailRow('Version', '1.0.0'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A4731), Color(0xFF2D7A4F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.eco_rounded,
                          color: Color(0xFF7EEDB0),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Small actions can create lasting impact.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GreenTrack encourages every user to turn recycling into a consistent and meaningful habit.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: _dark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _miniText(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            color: _dark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: GoogleFonts.dmSans(
            color: Colors.grey.shade700,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: _dark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLast;

  const _MilestoneTile({
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFF3DAB6A),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: const Color(0xFFDDEADF),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF1A4731),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;

  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3EEE6)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: const Color(0xFF1A4731),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}