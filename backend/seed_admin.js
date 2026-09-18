// seed_admin.js — Crea el usuario administrador en MongoDB
// Ejecutar: node seed_admin.js
const mongoose = require('mongoose');
const bcrypt   = require('bcryptjs');
const User     = require('./models/User');

async function create() {
    try {
        await mongoose.connect('mongodb://localhost:27017/german_busch_db');
        console.log('✅ Conectado a MongoDB');

        // Eliminar admin anterior si existe
        const deleted = await User.deleteOne({ email: 'admin@sistema.edu' });
        if (deleted.deletedCount) console.log('ℹ️  Admin anterior eliminado');

        const salt           = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('admin123', salt);

        const admin = new User({
            name:     'Administrador',
            email:    'admin@sistema.edu',
            password: hashedPassword,
            role:     'admin',
            grade:    '',
        });

        await admin.save();
        console.log('');
        console.log('✅ ══════════════════════════════════════════════');
        console.log('   Usuario ADMIN creado exitosamente:');
        console.log('   📧 Email    : admin@sistema.edu');
        console.log('   🔑 Contraseña: admin123');
        console.log('   👤 Rol      : admin');
        console.log('══════════════════════════════════════════════');
        console.log('');
        console.log('  Ahora inicia sesión en Flutter Chrome con esas credenciales.');
        console.log('  El sistema redirigirá automáticamente al Panel Administrativo.');
        console.log('');
    } catch (e) {
        console.error('❌ Error al crear admin:', e.message);
    } finally {
        await mongoose.disconnect();
        process.exit(0);
    }
}

create();
