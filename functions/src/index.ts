import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Inisialisasi Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

/**
 * Mengirim pengumuman umum ke semua pengguna (wali murid).
 * Dipicu oleh panggilan dari aplikasi admin.
 */
export const sendGeneralAnnouncement = functions
    .region("asia-southeast1") // Sesuaikan region dengan proyek Anda
    .https.onCall(async (data: any, context: functions.https.CallableContext) => {
      // Pastikan yang memanggil adalah admin
      if (context.auth?.token.role !== "admin") {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Fungsi ini hanya untuk admin.",
        );
      }

      const title: string = data.title;
      const body: string = data.body;

      const usersSnapshot = await db.collection("users")
          .where("role", "==", "user").get();
      if (usersSnapshot.empty) {
        console.log("Tidak ada user ditemukan.");
        return {success: true, sentCount: 0};
      }

      const allTokens: string[] = [];
      for (const userDoc of usersSnapshot.docs) {
        const tokensSnapshot = await userDoc.ref.collection("tokens").get();
        if (!tokensSnapshot.empty) {
          tokensSnapshot.forEach((tokenDoc) => {
            allTokens.push(tokenDoc.id);
          });
        }
      }

      if (allTokens.length === 0) {
        console.log("Tidak ada token perangkat ditemukan.");
        return {success: true, sentCount: 0};
      }

      const message = {
        notification: {title, body},
        tokens: allTokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Pesan terkirim ke ${response.successCount} perangkat.`);

      return {success: true, sentCount: response.successCount};
    });

/**
 * Mengirim notifikasi pengingat pembayaran.
 * Berjalan otomatis setiap hari jam 9 pagi.
 */
export const sendPaymentReminders = functions
    .region("asia-southeast1")
    .pubsub.schedule("every day 09:00")
    .timeZone("Asia/Jakarta")
    .onRun(async (context: functions.EventContext): Promise<null> => {
      const now = new Date();
      const reminderDate = new Date();
      reminderDate.setDate(now.getDate() + 3);

      const querySnapshot = await db.collection("payments")
          .where("status", "==", "unpaid")
          .where("dueDate", ">=", now)
          .where("dueDate", "<=", reminderDate)
          .get();

      if (querySnapshot.empty) {
        console.log("Tidak ada tagihan yang perlu diingatkan hari ini.");
        return null;
      }

      const promises = querySnapshot.docs.map(async (doc) => {
        const payment = doc.data() as {
            userId: string,
            month: string,
            dueDate: admin.firestore.Timestamp
        };
        const tokensSnapshot = await db.collection("users").doc(payment.userId)
            .collection("tokens").get();

        if (tokensSnapshot.empty) return;

        const tokens = tokensSnapshot.docs.map((tokenDoc) => tokenDoc.id);
        const dueDate = payment.dueDate.toDate().toLocaleDateString("id-ID");
        const message = {
          notification: {
            title: "Pengingat Pembayaran SPP",
            body: `Tagihan SPP bulan ${payment.month} akan jatuh tempo pada ${dueDate}. Segera lakukan pembayaran.`,
          },
          tokens: tokens,
        };
        return admin.messaging().sendEachForMulticast(message);
      });

      await Promise.all(promises);
      console.log("Notifikasi pengingat pembayaran berhasil dikirim.");
      return null;
    });

/**
 * Menerapkan denda keterlambatan pada tagihan yang sudah jatuh tempo.
 * Berjalan otomatis setiap hari jam 01:00 pagi.
 */
export const applyLateFees = functions
    .region("asia-southeast1")
    .pubsub.schedule("every day 01:00")
    .timeZone("Asia/Jakarta")
    .onRun(async (context: functions.EventContext): Promise<null> => {
      const now = new Date();
      const dendaAmount = 10000;

      const querySnapshot = await db.collection("payments")
          .where("status", "in", ["unpaid", "overdue"])
          .where("dueDate", "<", now)
          .where("dendaDiterapkan", "==", false)
          .get();

      if (querySnapshot.empty) {
        console.log("Tidak ada tagihan yang perlu dikenakan denda.");
        return null;
      }

      const batch = db.batch();
      querySnapshot.forEach((doc) => {
        console.log(`Menerapkan denda ke tagihan ID: ${doc.id}`);
        const paymentRef = db.collection("payments").doc(doc.id);
        batch.update(paymentRef, {
          denda: dendaAmount,
          dendaDiterapkan: true,
        });
      });

      await batch.commit();
      console.log(`Denda berhasil diterapkan pada ${querySnapshot.size} tagihan.`);
      return null;
    });

/**
 * Mengonfirmasi pembayaran, menghitung kelebihan/kekurangan,
 * dan memperbarui saldo pengguna.
 * Dipicu oleh panggilan dari aplikasi admin.
 */
export const confirmPaymentAndManageBalance = functions
    .region("asia-southeast1")
    .https.onCall(async (data: any, context: functions.https.CallableContext): Promise<{message: string}> => {
      if (context.auth?.token.role !== "admin") {
        throw new functions.https.HttpsError(
            "permission-denied", "Hanya admin yang bisa menjalankan fungsi ini.",
        );
      }

      const paymentId: string = data.paymentId;
      const actualAmountPaid: number = data.actualAmountPaid;
      const paymentRef = db.collection("payments").doc(paymentId);

      return db.runTransaction(async (transaction) => {
        const paymentDoc = await transaction.get(paymentRef);
        if (!paymentDoc.exists) {
          throw new functions.https.HttpsError("not-found", "Tagihan tidak ditemukan.");
        }

        const paymentData = paymentDoc.data() as {
            amount: number,
            denda: number,
            userId: string
        };
        const totalBill = (paymentData.amount || 0) + (paymentData.denda || 0);

        if (actualAmountPaid < totalBill) {
          throw new functions.https.HttpsError(
              "invalid-argument",
              `Pembayaran kurang. Tagihan: ${totalBill}, Dibayar: ${actualAmountPaid}.`,
          );
        }

        transaction.update(paymentRef, {
          status: "paid",
          isVerified: true,
        });

        const difference = actualAmountPaid - totalBill;

        if (difference > 0) {
          const userRef = db.collection("users").doc(paymentData.userId);
          transaction.update(userRef, {
            saldo: admin.firestore.FieldValue.increment(difference),
          });
          return {
            message: `Pembayaran berhasil. Saldo sebesar ${difference} ditambahkan.`,
          };
        }

        return {message: "Pembayaran berhasil dikonfirmasi."};
      });
    });
/**
 * Mengirim notifikasi ke satu pengguna spesifik berdasarkan UID.
 * Dipicu oleh panggilan dari aplikasi admin.
 */
export const sendDirectNotification = functions
    .region("asia-southeast1")
    .https.onCall(async (data: any, context: functions.https.CallableContext) => {
      // Pastikan pemanggil adalah admin
      if (context.auth?.token.role !== "admin") {
        throw new functions.https.HttpsError(
            "permission-denied", "Fungsi ini hanya untuk admin.",
        );
      }

      const targetUserId: string = data.userId;
      const title: string = data.title;
      const body: string = data.body;

      if (!targetUserId || !title || !body) {
        throw new functions.https.HttpsError(
            "invalid-argument", "Data (userId, title, body) tidak lengkap.",
        );
      }

      // Ambil semua token dari pengguna target
      const tokensSnapshot = await db.collection("users")
          .doc(targetUserId).collection("tokens").get();

      if (tokensSnapshot.empty) {
        console.log(`Tidak ada token ditemukan untuk user: ${targetUserId}`);
        return {success: false, message: "Pengguna tidak memiliki perangkat terdaftar."};
      }

      const tokens = tokensSnapshot.docs.map((doc) => doc.id);

      const message = {
        notification: {title, body},
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Notifikasi terkirim ke ${response.successCount} perangkat milik user ${targetUserId}.`);

      return {success: true, message: "Notifikasi berhasil dikirim."};
    });