import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as a2c;
import 'package:partyplanner/sqlite/party_database.dart';
import 'package:partyplanner/models/party.dart';
import 'package:partyplanner/models/guest.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart' as FlutterEmailSender;
import 'package:url_launcher/url_launcher.dart';

final _formKey = GlobalKey<FormState>();

class AddPartyScreen extends StatefulWidget {
  const AddPartyScreen({
    super.key,
    this.party,
  });

  final Party? party;

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  DateTime _date = DateTime.now();
  List<Guest> _guests = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _dateController = TextEditingController();
    if (widget.party != null) {
      _titleController.text = widget.party!.title;
      _descriptionController.text = widget.party!.description;
      _date = widget.party!.date;
      _dateController.text = DateFormat('MMM d, yyyy').format(_date);
      _loadGuests();
    } else {
      _dateController.text = DateFormat('MMM d, yyyy').format(_date);
    }
  }

  Future<void> _loadGuests() async {
    if (widget.party != null) {
      _guests = await PartyDatabase.instance.readGuestsForParty(widget.party!.id!);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> addParty() async {
    final party = Party(
      title: _titleController.text,
      description: _descriptionController.text,
      date: _date,
    );

    final createdParty = await PartyDatabase.instance.createParty(party);
    for (var guest in _guests) {
      await PartyDatabase.instance.createGuest(guest.copy(partyId: createdParty.id!));
    }
    
    // Separate calendar and email actions
    // bool calendarSuccess = await addToCalendar(createdParty);
    // await sendInvitations(createdParty);
    
    // if (calendarSuccess) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Party added and event added to calendar')),
    //   );
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Party added but failed to add event to calendar')),
    //   );
    // }
  }
Future<void> updateParty() async {
    final party = widget.party!.copy(
      title: _titleController.text,
      description: _descriptionController.text,
      date: _date,
    );

    await PartyDatabase.instance.updateParty(party);
    for (var guest in _guests) {
      await PartyDatabase.instance.createGuest(guest.copy(partyId: party.id!)); 
    }
    await sendUpdates(party);
    addToCalendar(party);

  }

  Future<void> removeGuest(Guest guest) async {
    await PartyDatabase.instance.deleteGuest(guest.id!);
    setState(() {
      _guests.remove(guest);
    });
  }
  Future<void> sendInvitations(Party party) async {
    final String subject = Uri.encodeComponent('Invitation: ${party.title}');
    final String body = Uri.encodeComponent(
      'You are invited to ${party.title} on ${DateFormat('MMM d, yyyy').format(party.date)}.\n\n${party.description}'
    );
    final String recipients = _guests.map((guest) => guest.email).join(',');
    
    final String mailtoUrl = 'mailto:$recipients?subject=$subject&body=$body';

    try {
      print('Attempting to launch URL: $mailtoUrl'); // Debug print
      if (await canLaunchUrl(Uri.parse(mailtoUrl))) {
        await launchUrl(Uri.parse(mailtoUrl));
        print('Email client opened successfully'); // Debug print
      } else {
        print('Cannot launch URL: $mailtoUrl'); // Debug print
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open email client')),
        );
      }
    } catch (e) {
      print('Error launching URL: $e'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
  Future<void> sendUpdates(Party party) async {
    final String subject = Uri.encodeComponent('Update: ${party.title}');
    final String body = Uri.encodeComponent(
      'The details for ${party.title} have been updated.\n\nNew Date: ${DateFormat('MMM d, yyyy').format(party.date)}\n\n${party.description}'
    );
    final String recipients = _guests.map((guest) => guest.email).join(',');
    
    final String mailtoUrl = 'mailto:$recipients?subject=$subject&body=$body';

    if (await canLaunch(mailtoUrl)) {
      await launch(mailtoUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email client opened with updates')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open email client')),
      );
    }
  }

  Future<bool> addToCalendar(Party party) async {
    final a2c.Event event = a2c.Event(
      title: party.title,
      description: party.description,
      startDate: party.date,
      endDate: party.date.add(const Duration(hours: 2)),
      allDay: false,
    );

    try {
      bool success = await a2c.Add2Calendar.addEvent2Cal(event);
      print('Calendar event added: $success'); // Debug print
      return success;
    } catch (e) {
      print('Error adding event to calendar: $e'); // Debug print
      return false;
    }
  }

  // void _addGuest() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       String name = '';
  //       String email = '';
  //       return AlertDialog(
  //         title: const Text('Add Guest'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextField(
  //               decoration: const InputDecoration(labelText: 'Name'),
  //               onChanged: (value) => name = value,
  //             ),
  //             TextField(
  //               decoration: const InputDecoration(labelText: 'Email'),
  //               onChanged: (value) => email = value,
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             child: const Text('Cancel'),
  //             onPressed: () => Navigator.of(context).pop(),
  //           ),
  //           TextButton(
  //             child: const Text('Add'),
  //             onPressed: () {
  //               if (name.isNotEmpty && email.isNotEmpty) {
  //                 setState(() {
  //                   _guests.add(Guest(
  //                     partyId: widget.party?.id ?? 0,
  //                     name: name,
  //                     email: email,
  //                   ));
  //                 });
  //                 Navigator.of(context).pop();
  //               }
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Future<void> _addGuest() async {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        final fullContact = await FlutterContacts.getContact(contact.id);
        if (fullContact != null) {
          final name = fullContact.displayName;
          final email = fullContact.emails.isNotEmpty ? fullContact.emails.first.address : '';
          
          setState(() {
            _guests.add(Guest(
              partyId: widget.party?.id ?? 0,
              name: name,
              email: email,
            ));
          });
        }
      }
  }

  void _editGuest(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = _guests[index].name;
        String email = _guests[index].email;
        return AlertDialog(
          title: const Text('Edit Guest'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                controller: TextEditingController(text: name),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Email'),
                controller: TextEditingController(text: email),
                onChanged: (value) => email = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                setState(() {
                  _guests[index] = _guests[index].copy(
                    name: name,
                    email: email,
                  );
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.party != null ? 'Edit Party' : 'Add Party'),
        actions: [
          if (widget.party != null)
            IconButton(
              onPressed: () async {
                await PartyDatabase.instance.deleteParty(widget.party!.id!);
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value?.isEmpty ?? true ? 'Please provide a title' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value?.isEmpty ?? true ? 'Please provide a description' : null,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(3000),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _date = pickedDate;
                      _dateController.text = DateFormat('MMM d, yyyy').format(_date);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Please select a date' : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Guests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _guests.length,
                itemBuilder: (context, index) {
                  final guest = _guests[index];
                  return ListTile(
                    title: Text(guest.name),
                    subtitle: Text(guest.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editGuest(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            removeGuest(guest);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              ElevatedButton(
                onPressed: _addGuest,
                child: const Text('Add Guest'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (widget.party != null) {
                      await updateParty();
                    } else {
                      await addParty();
                    }
                    Navigator.of(context).pop();
                  }
                },
                child: Text(widget.party != null ? 'Update Party' : 'Add Party'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  bool success = await addToCalendar(Party(
                    title: 'Test Event',
                    description: 'This is a test event',
                    date: DateTime.now(),
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calendar test: ${success ? 'Success' : 'Failed'}')),
                  );
                },
                child: Text('Test Calendar'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await sendInvitations(Party(
                    title: 'Test Party',
                    description: 'This is a test party',
                    date: DateTime.now(),
                  ));
                },
                child: Text('Test Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}