import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutanvij_electricals/screens/inventory/transporter_fair_screen.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/transporter.dart';

class TransporterCard extends StatelessWidget {
  final Transporter transporter;
  final VoidCallback? onEdit; // Callback for edit action
  final bool canEdit; // <-- New flag for condition

  const TransporterCard({
    Key? key,
    required this.transporter,
    this.onEdit,
    this.canEdit = true, // default true (show edit button)

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransporterFairScreen(
              transporterId: transporter.id,
            ),
          ),
        );

      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.background,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name, Company & Edit button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transporter.name,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          transporter.company,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // ✅ Show edit button only if allowed
                  if (canEdit && onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      onPressed: onEdit,
                      tooltip: "Edit Transporter",
                    ),

                ],
              ),
              const SizedBox(height: 6),

              // Phone
              Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    transporter.phone,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Email
              Row(
                children: [
                  const Icon(Icons.email, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      transporter.email,
                      style: AppTypography.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      transporter.address,
                      style: AppTypography.bodyMedium.copyWith(color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Vehicle type & Fare
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Vehicle: ${transporter.vehicleType}",
                    style: AppTypography.bodySmall,
                  ),
                  Text(
                    "Fare: ₹${transporter.fair}",
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
