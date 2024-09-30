import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:partyplanner/sqlite/party_database.dart';
import 'package:partyplanner/extensions/extensions.dart';
import 'package:partyplanner/models/party.dart';

class PartyListTile extends StatefulWidget {
  const PartyListTile({
    super.key,
    required this.party,
  });

  final Party party;

  @override
  State<PartyListTile> createState() => _PartyListTileState();
}

class _PartyListTileState extends State<PartyListTile> {


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: widget.party.date.isBefore(DateTime.now())
          ? Colors.red[100]
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
        ),
        child: CupertinoListTile(
          title: Text(
            widget.party.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            widget.party.description,
            maxLines: 3,
          ),
          additionalInfo: Visibility(
            child:           Text(
            widget.party.date.isBefore(DateTime.now())
              ? 'Expired'
              : 'Active',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          visible: widget.party.date.isBefore(DateTime.now()),
          ),
          trailing: Text(
            widget.party.date.toString().split(' ')[0],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
