import 'package:flutter/material.dart';
import 'package:partyplanner/sqlite/party_database.dart';
import 'package:partyplanner/models/party.dart';
import 'package:partyplanner/screens/add_party_screen.dart';
import 'package:partyplanner/widgets/party_list_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  List<Party> partys = [];

  Future<void> getAllParty() async {
    setState(() => isLoading = true);

    partys = await PartyDatabase.instance.readAllParties();

    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    getAllParty();
  }

  @override
  void dispose() {
    PartyDatabase.instance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Party List'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildPartyList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddPartyScreen(),
            ),
          );

          getAllParty();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPartyList() {
    return ListView.builder(
      itemCount: partys.length,
      itemBuilder: (context, index) {
        final party = partys[index];

        return GestureDetector(
            onTap: () async {
              if (party.date.isBefore(DateTime.now())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Party has already passed'),
                  ),
                );
                return;
              }
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddPartyScreen(
                    party: party,
                  ),
                ),
              );

              getAllParty();
            },
            child: PartyListTile(party: party));
      },
    );
  }
}
