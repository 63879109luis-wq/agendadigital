// ============================================================
// routes/notifications.js — Notificaciones push con FCM
// ============================================================
// Rutas para gestionar el envío de notificaciones push
// usando Firebase Admin SDK (HTTP v1 API).
//
// Rutas disponibles:
//   POST /api/notifications/token      → Guardar FCM token de un dispositivo
//   POST /api/notifications/send       → Enviar notif a un usuario (por userId)
//   POST /api/notifications/send-topic → Broadcast a un topic
// ============================================================

const express   = require('express');
const router    = express.Router();
const admin     = require('firebase-admin');
const UserToken = require('../models/UserToken');

// ── POST /api/notifications/token ──────────────────────────
// Registra (o actualiza) el token FCM de un dispositivo.
// Body: { userId, fcmToken, platform? }
router.post('/token', async (req, res) => {
    try {
        const { userId, fcmToken, platform = 'android' } = req.body;

        if (!userId || !fcmToken) {
            return res.status(400).json({ error: 'userId y fcmToken son requeridos' });
        }

        // Upsert: si el token ya existe, actualizarlo; si no, crearlo
        const tokenDoc = await UserToken.findOneAndUpdate(
            { fcmToken },                                          // Buscar por token
            { userId, fcmToken, platform, updatedAt: new Date() }, // Actualizar
            { upsert: true, new: true }                           // Crear si no existe
        );

        console.log(`📱 Token FCM guardado para usuario: ${userId}`);
        res.json({ message: 'Token registrado exitosamente', token: tokenDoc });
    } catch (error) {
        console.error('❌ Error guardando token FCM:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── POST /api/notifications/send ───────────────────────────
// Envía una notificación push a todos los dispositivos de un usuario.
// Body: { userId, title, body, data? }
router.post('/send', async (req, res) => {
    try {
        const { userId, title, body, data = {} } = req.body;

        if (!userId || !title || !body) {
            return res.status(400).json({ error: 'userId, title y body son requeridos' });
        }

        // Obtener todos los tokens del usuario
        const tokens = await UserToken.find({ userId }).select('fcmToken -_id');
        if (tokens.length === 0) {
            return res.status(404).json({ error: 'No se encontraron dispositivos para este usuario' });
        }

        const fcmTokens = tokens.map(t => t.fcmToken);
        console.log(`📤 Enviando notificación a ${fcmTokens.length} dispositivo(s) del usuario: ${userId}`);

        // Enviar a todos los dispositivos del usuario (multicast)
        const message = {
            notification: { title, body },
            data:         { ...data, userId }, // Datos extra para la app
            tokens:       fcmTokens,
            android: {
                priority: 'high',
                notification: {
                    channelId: 'tareas_channel',
                    color:     '#FFC107',
                    priority:  'max',
                    sound:     'default',
                }
            }
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`✅ Enviadas: ${response.successCount}, Fallidas: ${response.failureCount}`);

        // Limpiar tokens inválidos (dispositivos desinstalaron la app)
        const invalidTokens = [];
        response.responses.forEach((resp, idx) => {
            if (!resp.success) {
                const code = resp.error?.code;
                if (code === 'messaging/invalid-registration-token' ||
                    code === 'messaging/registration-token-not-registered') {
                    invalidTokens.push(fcmTokens[idx]);
                }
            }
        });

        if (invalidTokens.length > 0) {
            await UserToken.deleteMany({ fcmToken: { $in: invalidTokens } });
            console.log(`🗑️ Eliminados ${invalidTokens.length} tokens inválidos`);
        }

        res.json({
            message:  'Notificación enviada',
            success:  response.successCount,
            failures: response.failureCount,
        });
    } catch (error) {
        console.error('❌ Error enviando notificación:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── POST /api/notifications/send-topic ─────────────────────
// Envía una notificación a todos los suscriptores de un topic.
// Útil para avisos generales (ej: "todos los estudiantes").
// Body: { topic, title, body, data? }
router.post('/send-topic', async (req, res) => {
    try {
        const { topic, title, body, data = {} } = req.body;

        if (!topic || !title || !body) {
            return res.status(400).json({ error: 'topic, title y body son requeridos' });
        }

        const message = {
            topic,
            notification: { title, body },
            data,
            android: {
                priority: 'high',
                notification: {
                    channelId: 'tareas_channel',
                    color:     '#FFC107',
                    sound:     'default',
                }
            }
        };

        const msgId = await admin.messaging().send(message);
        console.log(`📡 Notificación a topic "${topic}" enviada: ${msgId}`);
        res.json({ message: 'Notificación broadcast enviada', messageId: msgId });
    } catch (error) {
        console.error('❌ Error en broadcast:', error.message);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
