import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legal_desk/theme/app_theme.dart';

class ActCard extends StatelessWidget {
  final String title;
  final String? year;
  final VoidCallback onTap;

  const ActCard({
    super.key,
    required this.title,
    this.year,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: AppColors.saffron, width: 3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.saffron.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.gavel, color: AppColors.saffron, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (year != null && year!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      year!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
