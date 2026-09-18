const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');

async function create() {
    try {
        await mongoose.connect('mongodb://localhost:27017/german_busch_db');
        
        // Eliminar el usuario existente para forzar la recreación con contraseña encriptada
        await User.deleteOne({ email: 'demo@gb.edu.bo' });
        console.log('ℹ️ Usuario demo anterior eliminado');

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('123', salt);

        const user = new User({
            name: "Invitado Demo",
            email: "demo@gb.edu.bo",
            password: hashedPassword,
            role: "student",
            grade: "6to Secundaria"
        });

        await user.save();
        console.log('✅ Usuario demo creado con contraseña encriptada (123) con éxito');
    } catch (e) {
        console.error('❌ Error al crear usuario:', e);
    } finally {
        process.exit();
    }
}
create();
