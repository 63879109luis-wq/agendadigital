// ============================================================
// models/Universe.js — Modelo del sistema de gamificación
// ============================================================
// Define la estructura del "universo" personal de cada estudiante.
// Es el sistema de gamificación de la app: al completar tareas
// y usar el OCR, el estudiante gana recursos para explorar
// su galaxia y colonizar planetas.
//
// Estructura:
//   Universe (la galaxia del usuario)
//     └─ planets[] (array de planetas, subdocumentos)
// ============================================================

const mongoose = require('mongoose');

// ── Sub-esquema de Planeta ──────────────────────────────────
// Cada planeta es un subdocumento embebido dentro del universo.
// Se usa PlanetSchema dentro de UniverseSchema (sin colección propia).
const PlanetSchema = new mongoose.Schema({
    name: { type: String, required: true }, // Nombre del planeta (ej: "Nova Prime")
    type: {
        type:     String,
        enum:     ['terrestre', 'gaseoso', 'helado', 'volcánico', 'desértico'],
        required: true
        // El tipo determina su color, tamaño y recursos disponibles
    },
    size:  { type: Number, required: true }, // Diámetro del planeta en km
    x:     { type: Number, required: true }, // Coordenada X en el mapa galáctico (-100 a 100)
    y:     { type: Number, required: true }, // Coordenada Y en el mapa galáctico (-100 a 100)
    color: { type: String, required: true }, // Gradiente CSS para pintar el planeta en pantalla
                                             // (ej: 'linear-gradient(135deg, #1b8a5a, #2c3e50)')
    resources:  [{ type: String }],          // Recursos que puede extraer el planeta (ej: ['Agua', 'Hierro'])
    population: { type: Number, default: 0 }, // Población del planeta (crece con infraestructura)

    // Construcciones en el planeta. Cada infraestructura tiene nombre y nivel.
    infrastructure: [{
        name:  { type: String },
        level: { type: Number, default: 1 } // Nivel 1 = básico, puede subir de nivel
    }],

    discovered_at: { type: Date, default: Date.now } // Cuándo fue descubierto/creado el planeta
});

// ── Esquema principal del Universo ─────────────────────────
const UniverseSchema = new mongoose.Schema({
    // Propietario del universo. unique: true significa que
    // cada usuario tiene EXACTAMENTE UN universo.
    owner: {
        type:     mongoose.Schema.Types.ObjectId,
        ref:      'User',
        required: true,
        unique:   true
    },

    name: { type: String, required: true }, // Nombre de la galaxia (ej: "Galaxia de Juan")
    seed: { type: String, required: true }, // Semilla aleatoria usada para generar el universo
                                            // (permite reproducibilidad si se quiere regenerar igual)

    // Recursos globales del universo (moneda del juego)
    resources: {
        energy: { type: Number, default: 100 }, // Energía disponible (se gasta al colonizar planetas)
        matter: { type: Number, default: 50 }   // Materia disponible (se gasta en infraestructura)
    },

    // Array de planetas descubiertos. Usa el sub-esquema PlanetSchema definido arriba.
    // El planeta inicial (capital) siempre es terrestre y se crea al registrarse.
    planets: [PlanetSchema],

    created_at: { type: Date, default: Date.now } // Fecha de creación del universo
});

// ── Exportar el modelo ──────────────────────────────────────
// Crea la colección "universes" en MongoDB.
module.exports = mongoose.model('Universe', UniverseSchema);
