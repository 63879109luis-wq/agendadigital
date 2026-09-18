// ============================================================
// models/UserToken.js — Tokens FCM de dispositivos
// ============================================================
// Guarda el token FCM de cada usuario para poder enviarle
// notificaciones push desde el backend.
// Un usuario puede tener múltiples dispositivos (múltiples tokens).
// ============================================================

const mongoose = require('mongoose');

const UserTokenSchema = new mongoose.Schema({
    // ID del usuario dueño del token
    userId: {
        type:     String,
        required: true,
        index:    true
    },

    // Token FCM del dispositivo (generado por Firebase en el dispositivo)
    fcmToken: {
        type:     String,
        required: true,
        unique:   true   // Cada token es único por dispositivo
    },

    // Plataforma del dispositivo
    platform: {
        type:    String,
        enum:    ['android', 'ios', 'web'],
        default: 'android'
    },

    // Fechas de registro y última actualización
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now }
});

// Actualizar updatedAt en cada save
UserTokenSchema.pre('save', function (next) {
    this.updatedAt = new Date();
    next();
});

module.exports = mongoose.model('UserToken', UserTokenSchema);
