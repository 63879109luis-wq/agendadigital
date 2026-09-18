const mongoose = require('mongoose');
const User = require('./models/User');
const Agenda = require('./models/Agenda');

async function seed() {
    try {
        await mongoose.connect('mongodb://localhost:27017/german_busch_db');
        const user = await User.findOne({ email: 'demo@gb.edu.bo' });
        if (!user) {
            console.error('❌ Usuario demo no encontrado');
            return;
        }

        const existingHomework = await Agenda.findOne({ userId: user._id.toString(), type: 'homework' });
        if (!existingHomework) {
            const homework = new Agenda({
                userId: user._id.toString(),
                title: "Matemáticas - Ejercicios de Geometría",
                description: "Resolver los problemas 1 al 10 del capítulo 3 y subir la solución en PDF.",
                date: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000), // En 2 días
                type: "homework",
                is_completed: false
            });
            await homework.save();
            console.log('✅ Tarea (homework) de geometría creada con éxito para el estudiante');
        } else {
            console.log('ℹ️ El estudiante ya tiene al menos una tarea pendiente');
        }
    } catch (e) {
        console.error('❌ Error al sembrar tarea:', e);
    } finally {
        process.exit();
    }
}
seed();
