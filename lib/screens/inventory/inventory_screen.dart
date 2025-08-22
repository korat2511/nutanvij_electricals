import 'package:flutter/material.dart';
import 'package:nutanvij_electricals/screens/inventory/edit_transpoerter_screen.dart';
import 'package:nutanvij_electricals/screens/inventory/tranporter_card.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_strings.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/site_validation_utils.dart';
import '../../core/utils/transporter_validations_utils.dart';
import '../../models/transporter.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import 'create_transporter.dart';
import 'providers/inventory_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final inventoryProvider = context.read<InventoryProvider>();
      final userProvider = context.read<UserProvider>();
      inventoryProvider.loadTransporters(context, userProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final userProvider = context.read<UserProvider>();

    final canCreateTransporter = TansporterValidationUtils.canCreateTransporter(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        onMenuPressed: () => NavigationUtils.pop(context),
        title: AppStrings.transporters,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => inventoryProvider.loadTransporters(context, userProvider),
                child: Builder(
                  builder: (context) {
                    if (inventoryProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (inventoryProvider.error != null) {
                      return Center(
                        child: Text(
                          inventoryProvider.error!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      );
                    }
                    if (inventoryProvider.transporters.isEmpty) {
                      return Center(
                        child: Text(
                          'No sites found',
                          style: AppTypography.bodyMedium,
                        ),
                      );
                    }

                    final sites = inventoryProvider.transporters;
                    return ListView.builder(
                      controller: ScrollController()
                        ..addListener(() {
                          if (!inventoryProvider.isLoadingMore &&
                              inventoryProvider.hasMoreData) {
                            inventoryProvider.loadMoreTransporters(context, userProvider);
                          }
                        }),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      itemCount: sites.length + (inventoryProvider.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (inventoryProvider.isLoadingMore && index == sites.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final transporter = sites[index];
                        return TransporterCard(
                          transporter: transporter,
                          canEdit: canCreateTransporter, // 👈 Only show edit if true
                          onEdit: () async {
                            final shouldRefresh = await NavigationUtils.push(
                              context,
                              EditTransporterScreen(transporter: transporter),
                            );
                            if (shouldRefresh == true) {
                              final inventoryProvider = context.read<InventoryProvider>();
                              final userProvider = context.read<UserProvider>();
                              inventoryProvider.loadTransporters(context, userProvider);
                            }

                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: canCreateTransporter
          ? Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 8.0),
        child: CustomButton(
          text: AppStrings.create_transporters,
          width: 160,
          height: 48,
          onPressed: () async {
            final shouldRefresh = await NavigationUtils.push(context, CreateTransporterScreen());

            //TODO
            if (shouldRefresh == true) {
              inventoryProvider.loadTransporters(context, userProvider);            }
          },
        ),
      )
          : null,
    );
  }
}


