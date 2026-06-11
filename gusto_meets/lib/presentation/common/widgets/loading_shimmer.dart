import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TerraceCardShimmer extends StatelessWidget {
  const TerraceCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.grey),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 120, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
