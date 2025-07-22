import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? userName;
  String greetingMessage = '';
  String formattedDate = '';
  String? _userUid;
  String? _userRole;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _recentMessages = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadUserData();
  }

  void _loadUserInfo() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final email = user.email ?? '';
      userName = email.split('@').first;
      _generateGreeting();
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userUid = prefs.getString('user_uid');
    _userRole = prefs.getString('user_role');

    if (_userUid != null) {
      _updateUnreadCount();
      _fetchRecentMessages();
    }
  }

  Future<void> _updateUnreadCount() async {
    if (_userUid == null) return;

    final query =
        _userRole == 'Doctor'
            ? FirebaseFirestore.instance
                .collection('messages')
                .where('doctorId', isEqualTo: _userUid)
                .where('read', isEqualTo: false)
            : FirebaseFirestore.instance
                .collection('messages')
                .where('patientId', isEqualTo: _userUid)
                .where('read', isEqualTo: false);

    final snapshot = await query.get();
    setState(() {
      _unreadCount = snapshot.docs.length;
    });
  }

  Future<void> _fetchRecentMessages() async {
    if (_userUid == null) return;

    final query =
        _userRole == 'Doctor'
            ? FirebaseFirestore.instance
                .collection('messages')
                .where('doctorId', isEqualTo: _userUid)
                .orderBy('timestamp', descending: true)
                .limit(3)
            : FirebaseFirestore.instance
                .collection('messages')
                .where('patientId', isEqualTo: _userUid)
                .orderBy('timestamp', descending: true)
                .limit(3);

    final snapshot = await query.get();
    setState(() {
      _recentMessages =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  Future<void> _markAsRead(String messageId) async {
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(messageId)
        .update({'read': true});
    _updateUnreadCount();
  }

  void _generateGreeting() {
    final hour = DateTime.now().hour;
    final now = DateTime.now();
    formattedDate = DateFormat('EEEE, MMMM d, y').format(now);

    if (hour < 12) {
      greetingMessage = 'Good morning';
    } else if (hour < 17) {
      greetingMessage = 'Good afternoon';
    } else {
      greetingMessage = 'Good evening';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFffeef8), Color(0xFFf8f0ff), Color(0xFFe8f5ff)],
          ),
        ),
        child: Column(
          children: [
            _buildStatusBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [_buildHeader(), _buildContent(context)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              '9:41',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
                fontFamily: 'SF Pro Display',
              ),
            ),
            Text(
              '🔋 100%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
                fontFamily: 'SF Pro Display',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$greetingMessage, ${userName?.capitalize() ?? 'User'}! 🌸',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.inbox,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => _showInboxDialog(context),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formattedDate,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [Color(0xFF4CAF50), Color(0x33FFFFFF)],
                        stops: [0.85, 0.85],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Center(
                          child: Text(
                            '85',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF333333),
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Overall Health Score',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Looking great this month!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Health Modules',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildHealthCard(
                'Cervical Health',
                '🔬',
                'Low Risk',
                () => Navigator.pushNamed(context, '/cervical'),
              ),
              _buildHealthCard(
                'Ovarian Cysts',
                '🫧',
                '2 Monitored',
                () => Navigator.pushNamed(context, '/ovarian'),
              ),
              _buildHealthCard(
                'My Profile',
                '👤',
                'Updated',
                () => Navigator.pushNamed(context, '/profile'),
              ),
              _buildHealthCard(
                'Appointments',
                '📅',
                'Next: Jun 15',
                () => Navigator.pushNamed(context, '/appointments'),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Recent Messages',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 15),
          if (_recentMessages.isEmpty)
            _buildRecommendationCard(
              '📩 No messages yet',
              'You have no recent messages. Your doctor will contact you here if needed.',
            ),
          ..._recentMessages.map((message) => _buildMessageCard(message)),
          const SizedBox(height: 15),
          if (_recentMessages.isNotEmpty)
            Center(
              child: TextButton(
                onPressed: () => _showInboxDialog(context),
                child: const Text(
                  'View All Messages',
                  style: TextStyle(
                    color: Color(0xFFff6b9d),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 30),
          const Text(
            'Health Updates',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 15),
          _buildRecommendationCard(
            '🎉 Great news!',
            'Your recent screening results came back normal. Keep up the great work with your preventive care!',
          ),
          _buildRecommendationCard(
            '📱 Reminder',
            'Your next cervical screening is due in 8 months. We\'ll send you a reminder closer to the date.',
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(
    String title,
    String icon,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 10,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 40, height: 1.2)),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
                fontFamily: 'SF Pro Display',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                fontFamily: 'SF Pro Display',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            spreadRadius: 8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final timestamp = message['timestamp'] as Timestamp?;
    final isUnread = message['read'] == false;
    final isFromDoctor = _userRole != 'Doctor';

    return GestureDetector(
      onTap: () {
        if (isUnread) _markAsRead(message['id']);
        _showMessageDetailsDialog(message);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFfff0f5) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isUnread ? const Color(0xFFff6b9d) : Colors.grey.shade200,
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isFromDoctor ? Icons.medical_services : Icons.person,
              color: const Color(0xFFff6b9d),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFromDoctor ? 'From Doctor' : 'To Patient',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['content'] ?? 'No content',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timestamp != null
                        ? DateFormat('MMM d, h:mm a').format(timestamp.toDate())
                        : 'Unknown time',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFff6b9d),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showInboxDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Inbox'),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.6,
              child: _InboxContent(
                userUid: _userUid,
                userRole: _userRole,
                onMessageSent: () {
                  _fetchRecentMessages();
                  _updateUnreadCount();
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showMessageDetailsDialog(Map<String, dynamic> message) {
    final timestamp = message['timestamp'] as Timestamp?;
    final isFromDoctor = _userRole != 'Doctor';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isFromDoctor ? 'Message from Doctor' : 'Your Message'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message['content'] ?? 'No content',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    timestamp != null
                        ? DateFormat(
                          'MMMM d, y - h:mm a',
                        ).format(timestamp.toDate())
                        : 'Unknown time',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            actions: [
              if (isFromDoctor)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showReplyDialog(message['doctorId']);
                  },
                  child: const Text('Reply'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showReplyDialog(String? doctorId) {
    final TextEditingController _messageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Send Message'),
            content: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Your message',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_messageController.text.trim().isEmpty) return;

                  await FirebaseFirestore.instance.collection('messages').add({
                    'patientId': _userUid,
                    'doctorId': doctorId,
                    'content': _messageController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                    'read': false,
                    'senderRole': 'Patient',
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message sent!'),
                      backgroundColor: Color(0xFFff6b9d),
                    ),
                  );

                  _fetchRecentMessages();
                  _updateUnreadCount();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFff6b9d),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send'),
              ),
            ],
          ),
    );
  }
}

class _InboxContent extends StatefulWidget {
  final String? userUid;
  final String? userRole;
  final VoidCallback onMessageSent;

  const _InboxContent({
    required this.userUid,
    required this.userRole,
    required this.onMessageSent,
  });

  @override
  State<_InboxContent> createState() => _InboxContentState();
}

class _InboxContentState extends State<_InboxContent> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _fetchDoctorIdAndMessages();
  }

  Future<void> _fetchDoctorIdAndMessages() async {
    if (widget.userUid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final patientDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userUid)
              .get();
      if (patientDoc.exists) {
        final patientData = patientDoc.data() as Map<String, dynamic>;
        _doctorId = patientData['assignedDoctorId'];
      }

      if (_doctorId == null) {
        final conversations =
            await FirebaseFirestore.instance
                .collection('conversations')
                .where('patientId', isEqualTo: widget.userUid)
                .limit(1)
                .get();
        if (conversations.docs.isNotEmpty) {
          _doctorId = conversations.docs.first['doctorId'];
        }
      }

      if (_doctorId == null) {
        setState(() {
          _messages = [];
          _isLoading = false;
        });
        return;
      }

      final conversationId = '${widget.userUid}_$_doctorId';

      final messagesQuery =
          await FirebaseFirestore.instance
              .collection('conversations')
              .doc(conversationId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .get();

      setState(() {
        _messages =
            messagesQuery.docs
                .map(
                  (doc) => {
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  },
                )
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching messages: $e');
      setState(() {
        _messages = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc('${widget.userUid}_$_doctorId')
          .collection('messages')
          .doc(messageId)
          .update({'read': true});
      _fetchDoctorIdAndMessages();
      widget.onMessageSent();
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  void _showSendMessageDialog() {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Message to Doctor'),
            content: TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Your message',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (messageController.text.trim().isEmpty) return;

                  try {
                    final conversationId = '${widget.userUid}_$_doctorId';
                    await FirebaseFirestore.instance
                        .collection('conversations')
                        .doc(conversationId)
                        .set({
                          'patientId': widget.userUid,
                          'doctorId': _doctorId,
                          'lastMessageTime': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));

                    await FirebaseFirestore.instance
                        .collection('conversations')
                        .doc(conversationId)
                        .collection('messages')
                        .add({
                          'content': messageController.text.trim(),
                          'timestamp': FieldValue.serverTimestamp(),
                          'read': false,
                          'senderRole': 'Patient',
                          'senderId': widget.userUid,
                        });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message sent!'),
                        backgroundColor: Color(0xFFff6b9d),
                      ),
                    );

                    _fetchDoctorIdAndMessages();
                    widget.onMessageSent();
                  } catch (e) {
                    print('Error sending message: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to send message'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFff6b9d),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _showSendMessageDialog,
            icon: const Icon(Icons.send, size: 18),
            label: const Text('New Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFff6b9d),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _messages.isEmpty
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No messages yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
            : Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final timestamp = message['timestamp'] as Timestamp?;
                  final isUnread = message['read'] == false;
                  final isFromMe = message['senderRole'] == 'Patient';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isUnread && !isFromMe
                              ? const Color(0xFFfff0f5) // Light pink for unread
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isUnread && !isFromMe
                                ? const Color(
                                  0xFFff6b9d,
                                ) // Pink border for unread
                                : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isFromMe ? 'You' : 'Doctor',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isFromMe
                                        ? const Color(
                                          0xFFff6b9d,
                                        ) // Pink for "You"
                                        : Colors
                                            .blue
                                            .shade700, // Blue for "Doctor"
                              ),
                            ),
                            if (isUnread && !isFromMe)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFff6b9d),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white, // White background for content
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            message['content']?.toString() ?? 'Content missing',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(
                                0xFF333333,
                              ), // Darker text for readability
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              timestamp != null
                                  ? DateFormat(
                                    'MMM d, h:mm a',
                                  ).format(timestamp.toDate())
                                  : 'Unknown time',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (!isFromMe)
                              TextButton(
                                onPressed: _showSendMessageDialog,
                                child: const Text(
                                  'Reply',
                                  style: TextStyle(color: Color(0xFFff6b9d)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      ],
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
