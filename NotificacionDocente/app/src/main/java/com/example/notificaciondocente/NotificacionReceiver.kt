package com.example.notificaciondocente

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat

class NotificacionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        mostrarNotificacionCalificaciones(context)
    }

    companion object {
        const val CHANNEL_ID = "canal_calificaciones"
        const val NOTIF_ID = 1001

        fun mostrarNotificacionCalificaciones(context: Context) {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Crear canal (requerido en Android 8+)
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Calificaciones Docente",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Recordatorios de entrega de calificaciones"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)

            val notificacion = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("⚠️ Recordatorio de Calificaciones")
                .setContentText("Señor docente, la entrega de calificaciones tiene fecha límite próxima.")
                .setStyle(
                    NotificationCompat.BigTextStyle()
                        .bigText(
                            "📚 Señor docente, la entrega de calificaciones " +
                            "es una fecha límite para subir.\n\n" +
                            "Por favor, no olvide registrar las notas de sus estudiantes " +
                            "antes de que venza el plazo establecido."
                        )
                )
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()

            notificationManager.notify(NOTIF_ID, notificacion)
        }
    }
}
