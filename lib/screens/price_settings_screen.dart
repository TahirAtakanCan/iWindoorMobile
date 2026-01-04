import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/profile.dart';

class PriceSettingsScreen extends StatefulWidget {
  const PriceSettingsScreen({super.key});

  @override
  State<PriceSettingsScreen> createState() => _PriceSettingsScreenState();
}

class _PriceSettingsScreenState extends State<PriceSettingsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Profile>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _profilesFuture = _apiService.getAllProfilesForConfig();
    });
  }

  void _showEditDialog(Profile profile) {
    final priceController = TextEditingController(text: profile.pricePerMeter.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${profile.name} Fiyatı"),
        content: TextField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Birim Fiyat (TL/m)",
            suffixText: "TL",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              double? newPrice = double.tryParse(priceController.text.replaceAll(',', '.'));
              if (newPrice == null) return;

              Navigator.pop(context); // Dialogu kapat
              
              bool success = await _apiService.updateProfilePrice(profile.id, newPrice);
              if (success) {
                _refreshList(); // Listeyi yenile
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fiyat güncellendi!")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata oluştu!")));
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Birim Fiyat Ayarları")),
      body: FutureBuilder<List<Profile>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Listelenecek profil bulunamadı."));
          }

          final profiles = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: profiles.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.inventory_2, color: Colors.blue.shade800),
                ),
                title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Kod: PR-${profile.id}"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200)
                  ),
                  child: Text(
                    "${profile.pricePerMeter} TL",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                ),
                onTap: () => _showEditDialog(profile),
              );
            },
          );
        },
      ),
    );
  }
}