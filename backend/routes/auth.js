// ============================================================
// routes/auth.js — Rutas de autenticación
// ============================================================
// Maneja el registro de nuevos usuarios y el inicio de sesión.
// Usa bcryptjs para encriptar y verificar contraseñas de forma
// segura (nunca se guarda la contraseña en texto plano).
//
// Rutas disponibles:
//   POST /api/auth/register  → Crear cuenta nueva
//   POST /api/auth/login     → Iniciar sesión
// ============================================================

const express = require('express');
const router  = express.Router();
const bcrypt  = require('bcryptjs'); // Librería para encriptar contraseñas con hash
const User    = require('../models/User');

// ── POST /api/auth/register ─────────────────────────────────
// Crea un nuevo usuario en la base de datos.
// Pasos:
//   1. Verifica que no exista otro usuario con el mismo email
//   2. Encripta la contraseña con bcrypt (salt rounds = 10)
//   3. Guarda el usuario en MongoDB
//   4. Devuelve el usuario creado SIN la contraseña
router.post('/register', async (req, res) => {
    try {
        const { name, email, password, role, grade } = req.body;

        // Paso 1: Verificar si ya existe un usuario con ese email
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            // HTTP 400 = Bad Request (el cliente envió datos inválidos)
            return res.status(400).json({ error: 'El usuario ya existe' });
        }

        // Paso 2: Encriptar la contraseña
        // genSalt(10) genera una "sal" aleatoria con 10 rondas de complejidad.
        // Hash más alto = más seguro pero más lento. 10 es el estándar recomendado.
        const salt           = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Paso 3: Crear y guardar el usuario con la contraseña encriptada
        const user = new User({
            name,
            email,
            password: hashedPassword, // Se guarda el hash, NUNCA la contraseña original
            role,
            grade
        });

        await user.save(); // Persiste el documento en MongoDB

        // Paso 4: Construir la respuesta sin incluir la contraseña
        // toObject() convierte el documento Mongoose a un objeto JS plano
        const userResponse = user.toObject();
        delete userResponse.password; // Eliminar contraseña de la respuesta por seguridad

        // HTTP 201 = Created (recurso creado exitosamente)
        res.status(201).json(userResponse);
    } catch (error) {
        console.error('Registration Error:', error);
        res.status(400).json({ error: error.message });
    }
});

// ── POST /api/auth/login ────────────────────────────────────
// Verifica las credenciales del usuario e inicia sesión.
// Pasos:
//   1. Busca el usuario por email en la base de datos
//   2. Compara la contraseña ingresada con el hash guardado
//   3. Si coinciden, devuelve los datos del usuario (sin contraseña)
//
// NOTA: Esta implementación es simple (sin JWT tokens).
//       En producción real se debería añadir JWT para sesiones seguras.
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        console.log(`🔑 Intento de login para: ${email}`);

        // Paso 1: Buscar usuario por email
        const user = await User.findOne({ email });

        if (!user) {
            console.log(`❌ Usuario no encontrado: ${email}`);
            // HTTP 401 = Unauthorized. Se usa el mismo mensaje para ambos errores
            // (email no encontrado y contraseña incorrecta) para no dar pistas a atacantes.
            return res.status(401).json({ error: 'Credenciales inválidas' });
        }

        // Paso 2: Comparar la contraseña enviada con el hash almacenado.
        // bcrypt.compare() encripta el password y lo compara con el hash de forma segura.
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            console.log(`❌ Contraseña incorrecta para: ${email}`);
            return res.status(401).json({ error: 'Credenciales inválidas' });
        }

        console.log(`✅ Login exitoso: ${email}`);

        // Paso 3: Devolver datos del usuario sin la contraseña
        const userResponse = user.toObject();
        delete userResponse.password; // Eliminar contraseña de la respuesta por seguridad

        // ── SYNC DE MATERIAS PARA DOCENTES ────────────────────────
        // Si el usuario es docente, sincronizar automáticamente las materias
        // asignadas formalmente desde el modelo Materia (docenteId).
        // Esto garantiza que la app Flutter siempre reciba la lista actualizada
        // sin importar si el admin usó el panel web o editó el campo manual.
        if (user.role === 'teacher') {
            try {
                const Materia = require('../models/Materia');
                const assignedMaterias = await Materia.find(
                    { docenteId: user._id, activa: true },
                    'nombre'
                ).lean();

                if (assignedMaterias.length > 0) {
                    // Construir string CSV con las materias del modelo formal
                    const materiasFromModel = assignedMaterias.map(m => m.nombre.trim()).join(',');

                    // Combinar con User.materias si existe (evitar duplicados)
                    const existingMaterias = userResponse.materias
                        ? userResponse.materias.split(',').map(s => s.trim()).filter(Boolean)
                        : [];
                    const combined = [...new Set([
                        ...assignedMaterias.map(m => m.nombre.trim()),
                        ...existingMaterias
                    ])];
                    userResponse.materias = combined.join(',');
                    console.log(`📚 Docente ${email} — materias sincronizadas: ${userResponse.materias}`);
                }
            } catch (syncErr) {
                // No interrumpir el login si falla la sincronización
                console.warn('⚠️ No se pudieron sincronizar materias del docente:', syncErr.message);
            }
        }

        // HTTP 200 = OK (éxito)
        res.json(userResponse);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ── Exportar el router ──────────────────────────────────────
// server.js lo monta bajo el prefijo /api/auth
module.exports = router;
