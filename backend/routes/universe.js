// ============================================================
// routes/universe.js — Rutas del sistema de universo/gamificación
// ============================================================
// Gestiona la galaxia personal de cada estudiante.
// Al registrarse, cada usuario obtiene automáticamente un universo
// con 4 planetas generados proceduralmente (de forma aleatoria pero
// controlada con configuraciones predefinidas).
//
// El sistema de gamificación motiva al estudiante:
//   - Completar tareas → gana recursos (energía, materia)
//   - Usar OCR        → desbloquea nuevos planetas
//   - Los recursos permiten colonizar y mejorar planetas
//
// Rutas disponibles:
//   GET  /api/universe/:userId         → Obtener (o crear) el universo del usuario
//   POST /api/universe/reset/:userId   → Regenerar el universo desde cero
//   POST /api/universe/planet          → Agregar un nuevo planeta al universo
// ============================================================

const express  = require('express');
const router   = express.Router();
const Universe = require('../models/Universe');
const User     = require('../models/User');

// ============================================================
// ─── Funciones generadoras procedurales ─────────────────────
// Estas funciones crean planetas y universos de forma aleatoria
// pero con parámetros controlados según el tipo de planeta.
// ============================================================

// Listas de nombres base para generar nombres de planetas aleatorios
const PLANET_PREFIXES = ['Astra', 'Caelum', 'Nova', 'Zephyr', 'Krypton', 'Vesper', 'Helios', 'Nebula', 'Pandora', 'Kronos', 'Orion', 'Vega', 'Polaris', 'Sirio', 'Rigel'];
const PLANET_SUFFIXES = ['Prime', 'Major', 'Minor', 'IX', 'IV', 'Beta', 'Delta', 'Nexus', 'Sigma', 'Epsilon', 'Zeta', 'Gamma'];

// Combina un prefijo y sufijo aleatorio: ej. "Nova Nexus", "Helios Prime"
const generateRandomName = () => {
    const prefix = PLANET_PREFIXES[Math.floor(Math.random() * PLANET_PREFIXES.length)];
    const suffix = PLANET_SUFFIXES[Math.floor(Math.random() * PLANET_SUFFIXES.length)];
    return `${prefix} ${suffix}`;
};

// ── Configuración de planetas por tipo ─────────────────────
// Cada tipo de planeta tiene rango de tamaño, paleta de colores
// y lista de recursos disponibles para extraer.
const planetConfigByType = {
    terrestre: {
        minSize: 6000,  // Tamaño mínimo en km de diámetro
        maxSize: 15000, // Tamaño máximo en km de diámetro
        colors: [       // Gradientes CSS para el diseño visual del planeta
            'linear-gradient(135deg, #1b8a5a, #2c3e50)',
            'linear-gradient(135deg, #2e8b57, #4682b4)',
            'linear-gradient(135deg, #16a085, #2980b9)'
        ],
        resources: ['Agua', 'Hierro', 'Oxígeno', 'Silicio', 'Carbono']
    },
    gaseoso: {
        minSize: 50000,  // Los planetas gaseosos son mucho más grandes
        maxSize: 140000,
        colors: [
            'linear-gradient(135deg, #e65c00, #F9D423)',
            'linear-gradient(135deg, #d35400, #c0392b)',
            'linear-gradient(135deg, #8e44ad, #2c3e50)'
        ],
        resources: ['Helio-3', 'Hidrógeno', 'Metano', 'Amoníaco']
    },
    helado: {
        minSize: 8000,
        maxSize: 30000,
        colors: [
            'linear-gradient(135deg, #4facfe, #00f2fe)',
            'linear-gradient(135deg, #74ebd5, #9ecee7)',
            'linear-gradient(135deg, #a1c4fd, #c2e9fb)'
        ],
        resources: ['Agua Helada', 'Metano', 'Cristales de Frío', 'Nitrógeno']
    },
    volcánico: {
        minSize: 4000,  // Los planetas volcánicos son los más pequeños
        maxSize: 12000,
        colors: [
            'linear-gradient(135deg, #ff416c, #ff4b2b)',
            'linear-gradient(135deg, #870000, #190a05)',
            'linear-gradient(135deg, #e65c00, #3a0007)'
        ],
        resources: ['Magma', 'Obsidiana', 'Azufre', 'Hierro', 'Níquel']
    },
    desértico: {
        minSize: 5000,
        maxSize: 20000,
        colors: [
            'linear-gradient(135deg, #f3a152, #eec77e)',
            'linear-gradient(135deg, #e67e22, #f1c40f)',
            'linear-gradient(135deg, #ca8a04, #78350f)'
        ],
        resources: ['Silicio', 'Cristales de Energía', 'Cobre', 'Arena de Cristal']
    }
};

// ── Función: generar un planeta con propiedades aleatorias ──
// @param type      - Tipo de planeta ('terrestre', 'gaseoso', etc.)
// @param index     - Índice (no usado actualmente, reservado para lógica futura)
// @param isCapital - Si es true, será el planeta capital del usuario (posición central 0,0)
// @param ownerName - Nombre del dueño, usado para el nombre del planeta capital
const generatePlanet = (type, index, isCapital = false, ownerName = '') => {
    const config = planetConfigByType[type];
    
    // ── Nombre del planeta ────────────────────────────────
    // El capital lleva el nombre del usuario: ej. "Busch Juan Prime"
    // Los demás son nombres aleatorios de la lista
    let name = '';
    if (isCapital) {
        name = ownerName ? `Busch ${ownerName} Prime` : 'Busch Prime';
    } else {
        name = generateRandomName();
    }

    // ── Tamaño del planeta ────────────────────────────────
    // Número aleatorio dentro del rango min-max del tipo
    const size = Math.floor(Math.random() * (config.maxSize - config.minSize + 1)) + config.minSize;
    
    // ── Coordenadas en el mapa galáctico ─────────────────
    // El planeta capital siempre está en el centro (0, 0)
    // Los demás están en posiciones aleatorias entre 20 y 100
    // (con signo + o - aleatoriamente para distribuirlos en los 4 cuadrantes)
    let x = 0;
    let y = 0;
    if (!isCapital) {
        x = (Math.random() > 0.5 ? 1 : -1) * (Math.floor(Math.random() * 80) + 20);
        y = (Math.random() > 0.5 ? 1 : -1) * (Math.floor(Math.random() * 80) + 20);
    }

    // ── Color del planeta ─────────────────────────────────
    // Seleccionar aleatoriamente uno de los gradientes CSS del tipo
    const color = config.colors[Math.floor(Math.random() * config.colors.length)];

    // ── Recursos del planeta ──────────────────────────────
    // Mezclar aleatoriamente los recursos disponibles y tomar 2 a 4 de ellos
    const shuffled        = [...config.resources].sort(() => 0.5 - Math.random());
    const planetResources = shuffled.slice(0, Math.floor(Math.random() * 3) + 2);

    return {
        name,
        type,
        size,
        x,
        y,
        color,
        resources:      planetResources,
        population:     isCapital ? 1000 : 0,  // Capital empieza con 1000 habitantes
        infrastructure: isCapital ? [           // Capital empieza con 2 estructuras base
            { name: 'Base de Operaciones', level: 1 },
            { name: 'Generador de Energía', level: 1 }
        ] : [],
        discovered_at: new Date()
    };
};

// ── Función: generar el universo inicial del usuario ────────
// Crea la configuración completa del universo con 4 planetas:
//   - 1 planeta terrestre (capital, en el centro)
//   - 1 planeta volcánico
//   - 1 planeta helado
//   - 1 planeta gaseoso
const generateInitialUniverse = (userId, userName) => {
    // Semilla única: string aleatorio de 10 caracteres en mayúsculas
    // Identifica de forma única esta generación del universo
    const seed          = Math.random().toString(36).substring(2, 12).toUpperCase();
    const universeName  = `Galaxia de ${userName || 'Explorador'}`;

    const planets = [
        generatePlanet('terrestre', 0, true, userName), // Planeta capital (isCapital = true)
        generatePlanet('volcánico', 1),                 // Planeta de recursos minerales
        generatePlanet('helado',    2),                 // Planeta exótico
        generatePlanet('gaseoso',   3)                  // Planeta gigante gaseoso
    ];

    return {
        owner:     userId,
        name:      universeName,
        seed,
        resources: {
            energy: 100, // Recursos iniciales para que el usuario pueda empezar a jugar
            matter: 50
        },
        planets
    };
};

// ============================================================
// ─── Endpoints de la API ────────────────────────────────────
// ============================================================

// ── GET /api/universe/:userId ───────────────────────────────
// Obtiene el universo del usuario. Si no tiene uno (primer acceso),
// lo genera automáticamente con la función generateInitialUniverse().
// Este patrón se llama "get or create".
router.get('/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        console.log(`🌌 Solicitando universo para usuario: ${userId}`);

        // Buscar el universo existente del usuario
        let universe = await Universe.findOne({ owner: userId });

        if (!universe) {
            // El usuario no tiene universo aún → generar uno nuevo
            console.log(`🆕 Universo no encontrado. Generando nuevo universo para usuario: ${userId}`);
            
            // Buscar el nombre del usuario para personalizar el universo
            const user     = await User.findById(userId);
            const userName = user ? user.name : 'Explorador';

            const universeData = generateInitialUniverse(userId, userName);
            universe           = new Universe(universeData);
            await universe.save();
            console.log(`✅ Universo generado con éxito: "${universe.name}"`);
        }

        res.json(universe);
    } catch (error) {
        console.error('❌ Error al obtener/crear universo:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── POST /api/universe/reset/:userId ───────────────────────
// Regenera (reinicia) el universo del usuario desde cero.
// Elimina el universo actual y genera uno completamente nuevo.
// El usuario pierde todos sus planetas y progreso anterior.
router.post('/reset/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        console.log(`♻️ Regenerando universo para usuario: ${userId}`);

        // Verificar que el usuario existe antes de proceder
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // Eliminar el universo existente (si hay uno)
        await Universe.deleteOne({ owner: userId });

        // Generar y guardar un universo completamente nuevo
        const universeData = generateInitialUniverse(userId, user.name);
        const universe     = new Universe(universeData);
        await universe.save();

        console.log(`✅ Universo regenerado con éxito: "${universe.name}"`);
        res.json({ success: true, message: 'Universo regenerado con éxito', universe });
    } catch (error) {
        console.error('❌ Error al regenerar universo:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── POST /api/universe/planet ───────────────────────────────
// Agrega un nuevo planeta al universo del usuario.
// Se puede usar con parámetros personalizados o dejar que los genere
// el sistema proceduralmente.
// Body requerido: userId
// Body opcional:  name, type, size, x, y, color, resources
router.post('/planet', async (req, res) => {
    try {
        const { userId, name, type, size, x, y, color, resources } = req.body;
        
        if (!userId) {
            return res.status(400).json({ error: 'El ID de usuario (userId) es requerido' });
        }

        // Verificar que el usuario tiene un universo donde agregar el planeta
        const universe = await Universe.findOne({ owner: userId });
        if (!universe) {
            return res.status(404).json({ error: 'Universo no encontrado para este usuario' });
        }

        // Validar el tipo de planeta → si no es válido, usar 'desértico' por defecto
        const validTypes  = ['terrestre', 'gaseoso', 'helado', 'volcánico', 'desértico'];
        const planetType  = type && validTypes.includes(type) ? type : 'desértico';
        const config      = planetConfigByType[planetType];

        // Usar los parámetros enviados o generar valores procedurales si no se enviaron
        const finalName   = name || generateRandomName();
        const finalSize   = size || (Math.floor(Math.random() * (config.maxSize - config.minSize + 1)) + config.minSize);
        
        // Coordenadas: usar las enviadas o generar posición aleatoria en los 4 cuadrantes
        const finalX      = x !== undefined ? Number(x) : (Math.random() > 0.5 ? 1 : -1) * (Math.floor(Math.random() * 80) + 20);
        const finalY      = y !== undefined ? Number(y) : (Math.random() > 0.5 ? 1 : -1) * (Math.floor(Math.random() * 80) + 20);
        
        // Color: usar el enviado o seleccionar uno aleatorio de la paleta del tipo
        const finalColor  = color || config.colors[Math.floor(Math.random() * config.colors.length)];
        
        // Recursos: usar los enviados o seleccionar 3 recursos aleatorios del tipo
        const finalResources = resources && Array.isArray(resources) ? resources : 
            [...config.resources].sort(() => 0.5 - Math.random()).slice(0, 3);

        // Construir el objeto del nuevo planeta
        const newPlanet = {
            name:           finalName,
            type:           planetType,
            size:           finalSize,
            x:              finalX,
            y:              finalY,
            color:          finalColor,
            resources:      finalResources,
            population:     0,          // Nuevo planeta empieza sin habitantes
            infrastructure: [],         // Sin infraestructura inicial
            discovered_at:  new Date()
        };

        // Añadir el planeta al array de planetas del universo y guardar
        universe.planets.push(newPlanet);
        await universe.save();

        console.log(`🪐 Nuevo planeta "${finalName}" agregado al universo de ${userId}`);
        res.status(201).json({ success: true, planet: newPlanet, universe });
    } catch (error) {
        console.error('❌ Error al agregar planeta:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── Exportar el router ──────────────────────────────────────
// server.js lo monta bajo el prefijo /api/universe
module.exports = router;
