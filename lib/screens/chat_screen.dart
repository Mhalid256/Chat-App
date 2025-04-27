import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registration_screen.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedInUser;// Use `User?` to allow for null values

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController= TextEditingController();
  late  String messageText;
  final _auth = FirebaseAuth.instance;


  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser; // `currentUser` is a synchronous getter
      if (user != null) {
        loggedInUser = user;
        print("User logged in: ${loggedInUser!.email}"); // Example: Print user email
      } else {
        print("No user is currently logged in.");
      }

      // void getMessages() async {
      //   final messages = await _firestore.collection('001').get();
      //   for(var messsage in messages.docs){
      //     print(messsage.data());
      //   }
      // }
      void messageStream()async{
        await for(var snapshot in _firestore.collection('001').snapshots()) {
          for (var messsage in snapshot.docs) {
                print(messsage.data());
              }
          }
        }
    } catch (e) {
      print("Error fetching current user: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
               _auth.signOut();
               Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
             StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('001').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(
                    backgroundColor: Colors.lightBlueAccent,
                  )); // Show loading indicator

                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}')); // Show error message
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No messages found.')); // Handle empty data
                }

                final messages = snapshot.data!.docs.reversed; // Access the list of documents
                List<Widget> messageBubbles = []; // Use `Widget` instead of `Text` for flexibility

                for (var message in messages) {
                  final messageData = message.data() as Map<String, dynamic>; // Access document data
                  final messageText = messageData['text'];
                  final messageSender = messageData['sender'];

                  final currentUser = loggedInUser.email;


                  final messageBubble =MessageBubble(
                      sender: messageSender,
                      text: messageText,
                      isMe: currentUser == messageSender,
                  );
                  messageBubbles.add(messageBubble);

                }

                return Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 20.0),
                    children: messageBubbles, // Use the list of widgets
                  ),
                );
              },
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _firestore.collection('001').add({
                        'text':messageText,
                        'sender':loggedInUser,
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class MessageBubble extends StatelessWidget {
  MessageBubble({required this.sender,required this.text,required this.isMe});
  final String sender;
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding:  EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(sender,style: TextStyle(
            fontSize: 12.0,
            color: Colors.black54,
          ),),
          Material(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0),bottomLeft: Radius.circular(30.0),bottomRight: Radius.circular(30.0)),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding:  EdgeInsets.symmetric(vertical: 20.0,horizontal: 10.0),
              child: Text(text ,
                style:TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                    fontSize: 15.0
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
