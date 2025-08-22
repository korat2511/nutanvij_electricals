import 'package:flutter/material.dart';
import 'package:nutanvij_electricals/screens/inventory/providers/transporter_fair_provider.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/user_provider.dart';
import 'add_transport_fair_bottomsheet.dart';
import 'download_report_screen.dart';

class TransporterFairScreen extends StatefulWidget {
  final int transporterId;

  const TransporterFairScreen({
    Key? key,
    required this.transporterId,
  }) : super(key: key);

  @override
  State<TransporterFairScreen> createState() => _TransporterFairScreenState();
}

class _TransporterFairScreenState extends State<TransporterFairScreen> {
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userProvider = context.read<UserProvider>();
      context.read<TransporterFairProvider>().fetchTransporterFairs(
            context,
            widget.transporterId,
            userProvider,
          );
    });
  }

  void _openAddFairBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return AddTransporterFairBottomSheet(
          transporterId: widget.transporterId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Transporter Fair"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Download Report",
            onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DownloadReportScreen(transporterId: widget.transporterId,),
                ),
              );
            },

          ),
        ],
      ),
      body: Consumer<TransporterFairProvider>(
        builder: (context, provider, child) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }

          if (provider.transporterFairs.isEmpty) {
            return const Center(child: Text("No fairs found"));
          }

          return ListView.builder(
            itemCount: provider.transporterFairs.length,
            itemBuilder: (context, index) {
              final transporter = provider.transporterFairs[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: AppColors.background,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: ExpansionTile(
                  backgroundColor: Colors.white,
                  collapsedBackgroundColor: Colors.white,
                  iconColor: Colors.black,
                  collapsedIconColor: Colors.black,
                  title: Text(
                    transporter.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(transporter.phone),
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Email: ${transporter.email}"),
                          Text("Address: ${transporter.address}"),
                          Text("Company: ${transporter.company ?? "-"}"),
                          Text("Pancard: ${transporter.pancard}"),
                          const SizedBox(height: 10),
                          const Text(
                            "Fairs:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          ...transporter.fairs.map((fair) => Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: ListTile(
                                  tileColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(
                                        color: Colors.black12, width: 0.6),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  leading: const Icon(Icons.local_shipping,
                                      color: Colors.blueGrey),
                                  title: Text(
                                    "${fair.fromLocation ?? '-'} → ${fair.toLocation ?? '-'}",
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    "Date: ${fair.date} | Status: ${fair.paymentStatus == 1 ? "Paid" : "Pending"}",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  trailing: Text(
                                    "₹${fair.fair}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddFairBottomSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }

}
