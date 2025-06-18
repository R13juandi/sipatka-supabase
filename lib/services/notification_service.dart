import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Minta Izin Notifikasi dari Pengguna
    await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // 2. Konfigurasi notifikasi lokal (untuk foreground)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings);

    // 3. Setup listener untuk pesan masuk
    _setupMessageListeners();
  }

  void _setupMessageListeners() {
    // Listener untuk saat aplikasi dalam keadaan terbuka (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Menerima pesan foreground: ${message.notification?.title}');
      if (message.notification != null) {
        _showLocalNotification(message.notification!);
      }
    });

    // Listener untuk saat aplikasi di background dan notifikasi di-tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notifikasi di-tap: ${message.data}');
      // Di sini Anda bisa menavigasikan pengguna ke halaman tertentu
    });
  }

  // Menampilkan notifikasi lokal
  void _showLocalNotification(RemoteNotification notification) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sipatka_channel_id', // ID channel
      'Notifikasi SIPATKA',   // Nama channel
      channelDescription: 'Channel untuk notifikasi aplikasi SIPATKA',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
    );
  }

  // Mendapatkan token FCM unik untuk perangkat
  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }

  // Menyimpan token ke Firestore
  Future<void> saveTokenToFirestore(String userId) async {
    final token = await getFCMToken();
    if (token != null) {
      final tokensRef = _firestore.collection('users').doc(userId).collection('tokens').doc(token);
      await tokensRef.set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("Token FCM disimpan untuk user: $userId");
    }
  }
}