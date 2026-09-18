/* ═══════════════════════════════════════════════════
   SISTEMA ACADÉMICO — Panel Administrativo
   app.js — Interactividad y lógica del panel
════════════════════════════════════════════════════ */

'use strict';

// ── Navegación entre páginas ──────────────────────
function navigate(page, el) {
    // Ocultar todas las páginas
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    // Mostrar la página seleccionada
    const target = document.getElementById('page-' + page);
    if (target) target.classList.add('active');

    // Actualizar nav items
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    if (el) el.classList.add('active');

    // Cerrar sidebar en móvil
    if (window.innerWidth <= 768) {
        document.getElementById('sidebar').classList.remove('open');
        document.getElementById('overlay').classList.remove('active');
    }

    // Animar tarjetas de la nueva página
    initCardAnimations();

    // Inicializar módulo correspondiente
    const moduloMap = {
        agenda: () => setTimeout(initAgenda, 80),
        administradores: () => setTimeout(() => renderTabla('admins'), 80),
        docentes: () => setTimeout(() => renderTabla('docentes'), 80),
        estudiantes: () => setTimeout(() => renderTabla('estudiantes'), 80),
        materias: () => setTimeout(() => renderTabla('materias'), 80),
        actividades: () => setTimeout(() => renderTabla('actividades'), 80),
        calificaciones: () => setTimeout(initCalificaciones, 80),
        reportes: () => setTimeout(initReportes, 80),
        configuracion: () => setTimeout(initConfiguracion, 80),
        inscripcion: () => setTimeout(initInscripcion, 80),
    };
    if (moduloMap[page]) moduloMap[page]();
}

// ── Sidebar toggle (mobile) ───────────────────────
function toggleSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('overlay');
    sidebar.classList.toggle('open');
    overlay.classList.toggle('active');
}

// ── Dropdown: Usuario ─────────────────────────────
function toggleUserMenu() {
    const dd = document.getElementById('userDropdown');
    const chevron = document.getElementById('chevronIcon');
    const isOpen = dd.classList.contains('open');

    closeAllDropdowns();

    if (!isOpen) {
        dd.classList.add('open');
        chevron.style.transform = 'rotate(180deg)';
        document.getElementById('overlay').classList.add('active');
    }
}

// ── Dropdown: Notificaciones ──────────────────────
function toggleNotifications() {
    const panel = document.getElementById('notifPanel');
    const isOpen = panel.classList.contains('open');

    closeAllDropdowns();

    if (!isOpen) {
        panel.classList.add('open');
        document.getElementById('overlay').classList.add('active');
    }
}

// ── Cerrar todos los dropdowns ────────────────────
function closeAllDropdowns() {
    document.getElementById('userDropdown').classList.remove('open');
    document.getElementById('notifPanel').classList.remove('open');
    document.getElementById('chevronIcon').style.transform = 'rotate(0deg)';
    // Solo quitar overlay si sidebar no está abierto en móvil
    const sidebar = document.getElementById('sidebar');
    if (!sidebar.classList.contains('open')) {
        document.getElementById('overlay').classList.remove('active');
    }
}

// ── Limpiar notificaciones ────────────────────────
function clearNotifications() {
    const list = document.getElementById('notifList');
    list.innerHTML = '<div style="padding: 20px; text-align: center; color: var(--text-muted); font-size: 12px;">No hay notificaciones nuevas</div>';
    const badge = document.getElementById('notifBadge');
    badge.style.display = 'none';
    showToast('Notificaciones limpiadas ✓');
}

// ── Toast notification ────────────────────────────
let toastTimeout;
function showToast(message) {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.classList.add('show');

    clearTimeout(toastTimeout);
    toastTimeout = setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

// ── Animación de contadores ───────────────────────
function animateCounter(el, target, duration = 1200) {
    let start = 0;
    const step = target / (duration / 16);
    const timer = setInterval(() => {
        start += step;
        if (start >= target) {
            start = target;
            clearInterval(timer);
        }
        el.textContent = Math.floor(start);
    }, 16);
}

// ── Inicializar contadores al cargar ─────────────
function initCounters() {
    const counters = [
        { id: 'stat-materias', value: 12 },
        { id: 'stat-docentes', value: 28 },
        { id: 'stat-estudiantes', value: 342 },
        { id: 'stat-actividades', value: 56 },
    ];

    counters.forEach(c => {
        const el = document.getElementById(c.id);
        if (el) animateCounter(el, c.value);
    });
}

// ── Búsqueda simple ───────────────────────────────
function initSearch() {
    const input = document.getElementById('searchInput');
    if (!input) return;

    input.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            const q = input.value.trim();
            if (q) showToast(`Buscando: "${q}"...`);
        }
    });
}

// ── Actualizar hora/fecha en tiempo real ──────────
function updateClock() {
    const now = new Date();
    const opts = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
    // (Used for future date display widgets)
}

// ── Keyboard shortcuts ────────────────────────────
function initKeyboardShortcuts() {
    document.addEventListener('keydown', (e) => {
        // Escape: cerrar dropdowns
        if (e.key === 'Escape') {
            closeAllDropdowns();
            document.getElementById('sidebar').classList.remove('open');
            document.getElementById('overlay').classList.remove('active');
        }
        // Ctrl+K: focus search
        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            document.getElementById('searchInput').focus();
        }
    });
}

// ── Simular actualización de datos en tiempo real ─
function simulateRealtime() {
    setInterval(() => {
        // Simular pequeños cambios en estudiantes
        const el = document.getElementById('stat-estudiantes');
        if (el && Math.random() > 0.95) {
            const current = parseInt(el.textContent);
            animateCounter(el, current + 1, 500);
        }
    }, 10000);
}

// ── Tooltips simples para íconos del nav ──────────
function initTooltips() {
    // Los tooltips se manejan via CSS title attributes
    document.querySelectorAll('.nav-item').forEach(item => {
        const span = item.querySelector('span');
        if (span) item.setAttribute('title', span.textContent);
    });
}

// ── Highlight de búsqueda en tabla ────────────────
function initTableSearch() {
    const input = document.getElementById('searchInput');
    if (!input) return;

    input.addEventListener('input', () => {
        const q = input.value.toLowerCase().trim();
        if (!q) return;

        document.querySelectorAll('.entregas-table tbody tr').forEach(row => {
            const text = row.textContent.toLowerCase();
            row.style.opacity = text.includes(q) ? '1' : '0.3';
        });
    });

    input.addEventListener('blur', () => {
        document.querySelectorAll('.entregas-table tbody tr').forEach(row => {
            row.style.opacity = '1';
        });
    });
}

// ── Animación de entrada para tarjetas ────────────
function initCardAnimations() {
    // Solo animar tarjetas dentro de la página activa
    const activePage = document.querySelector('.page.active');
    if (!activePage) return;

    const cards = activePage.querySelectorAll('.stat-card, .card');
    cards.forEach((card, i) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(12px)';
        card.style.transition = 'opacity 0.4s ease, transform 0.4s ease';
        setTimeout(() => {
            card.style.opacity = '1';
            card.style.transform = 'translateY(0)';
        }, i * 60);
    });
}

// ═══════════════════════════════════════════════════
//  MÓDULOS CRUD — Motor genérico de datos
// ═══════════════════════════════════════════════════

/* ── Datos iniciales de cada módulo ── */
const DB = {
    admins: [
        { id: 1, nombre: 'Juan Carlos Flores', email: 'jflores@colegio.edu', ci: '7654321', telefono: '+591 70001111', estado: 'Activo', obs: 'Administrador principal', fecha: '22/06/2026' },
        { id: 2, nombre: 'María Quispe', email: 'mquispe@colegio.edu', ci: '8123456', telefono: '+591 70002222', estado: 'Activo', obs: '', fecha: '10/07/2026' },
    ],
    docentes: [
        { id: 1, nombre: 'Prof. Carlos Ruiz', email: 'cruiz@colegio.edu', ci: '5678901', telefono: '+591 71001001', especialidad: 'Matemáticas', materias: 'Matemáticas I, Álgebra', estado: 'Activo', obs: '' },
        { id: 2, nombre: 'Prof. Ana López', email: 'alopez@colegio.edu', ci: '6789012', telefono: '+591 71002002', especialidad: 'Lenguaje', materias: 'Lenguaje y Literatura', estado: 'Activo', obs: '' },
        { id: 3, nombre: 'Prof. Miguel Torres', email: 'mtorres@colegio.edu', ci: '7890123', telefono: '+591 71003003', especialidad: 'Informática', materias: 'Programación I, Redes', estado: 'Activo', obs: '' },
    ],
    estudiantes: [
        { id: 1, nombre: 'Camila Mamani', ci: '11223344', semestre: '3.° Secundaria', email: 'cmamani@est.edu', telefono: '+591 72001001', tutor: 'Rosa Mamani', tutorTel: '+591 72009001', estado: 'Activo', direccion: 'Av. 6 de Agosto', nacimiento: '2005-03-12', obs: '' },
        { id: 2, nombre: 'Luis Condori', ci: '22334455', semestre: '2.° Secundaria', email: 'lcondori@est.edu', telefono: '+591 72002002', tutor: 'Pedro Condori', tutorTel: '+591 72009002', estado: 'Activo', direccion: 'Calle Lanza 23', nacimiento: '2006-07-22', obs: '' },
        { id: 3, nombre: 'Sofía Quisbert', ci: '33445566', semestre: '5.° Secundaria', email: 'squisbert@est.edu', telefono: '+591 72003003', tutor: 'Elena Quisbert', tutorTel: '+591 72009003', estado: 'Activo', direccion: 'Villa Copacabana', nacimiento: '2003-11-05', obs: '' },
        { id: 4, nombre: 'Diego Ticona', ci: '44556677', semestre: '1.° Secundaria', email: 'dticona@est.edu', telefono: '+591 72004004', tutor: 'Juana Ticona', tutorTel: '+591 72009004', estado: 'Activo', direccion: 'El Alto Z.11', nacimiento: '2007-01-30', obs: '' },
    ],
    materias: [
        { id: 1, nombre: 'Matemáticas I', semestre: '1.° Secundaria', docente: 'Prof. Carlos Ruiz', estudiantes: '30', horas: '4', aula: 'Aula 101', desc: 'Aritmética y álgebra básica.' },
        { id: 2, nombre: 'Lenguaje y Literatura', semestre: '1.° Secundaria', docente: 'Prof. Ana López', estudiantes: '28', horas: '3', aula: 'Aula 102', desc: 'Comprensión lectora y redacción.' },
        { id: 3, nombre: 'Programación I', semestre: '3.° Secundaria', docente: 'Prof. Miguel Torres', estudiantes: '25', horas: '5', aula: 'Lab. Inf.', desc: 'Fundamentos de programación.' },
        { id: 4, nombre: 'Redes de Computadoras', semestre: '5.° Secundaria', docente: 'Prof. Miguel Torres', estudiantes: '22', horas: '4', aula: 'Lab. Redes', desc: 'Protocolos y topologías de red.' },
    ],
    actividades: [
        { id: 1, nombre: 'Examen Parcial 1', tipo: 'Examen', materia: 'Matemáticas I', docente: 'Prof. Carlos Ruiz', fecha: '2026-07-15', puntos: '100', estado: 'Cerrada', semestre: '1.° Semestre', desc: 'Examen de aritmética básica.' },
        { id: 2, nombre: 'Tarea: CSS Grid', tipo: 'Tarea', materia: 'Programación I', docente: 'Prof. Miguel Torres', fecha: '2026-07-22', puntos: '50', estado: 'Activa', semestre: '3.° Semestre', desc: 'Implementar layout con CSS Grid.' },
        { id: 3, nombre: 'Proyecto Final', tipo: 'Proyecto', materia: 'Redes de Computadoras', docente: 'Prof. Miguel Torres', fecha: '2026-08-10', puntos: '200', estado: 'Pendiente', semestre: '5.° Semestre', desc: 'Diseño de topología de red.' },
    ],
};

let editandoId = {}; // {admins: null, docentes: null, ...}

/* ── Configuración por módulo ── */
const MOD_CFG = {
    admins: {
        modal: 'admin', titulo: 'Administrador',
        campos: ['nombre', 'email', 'ci', 'telefono', 'pass', 'estado', 'obs'],
        requeridos: ['nombre', 'email', 'ci'],
        renderRow: (r, i) => `
            <tr>
                <td>${i + 1}</td>
                <td><div class="mod-user-cell"><div class="mod-avatar" style="background:linear-gradient(135deg,#3b82f6,#8b5cf6)">${r.nombre[0]}</div><span>${r.nombre}</span></div></td>
                <td>${r.email}</td><td>${r.ci}</td><td>${r.telefono || '—'}</td>
                <td>${badgeEstado(r.estado)}</td><td>${r.fecha || '—'}</td>
                <td>${accionesBtns('admins', r.id)}</td>
            </tr>`,
        filtrar: (r) => {
            const q = (document.getElementById('searchAdmin')?.value || '').toLowerCase();
            const est = document.getElementById('filterAdminEstado')?.value || '';
            return (!q || (r.nombre + r.email + r.ci).toLowerCase().includes(q)) && (!est || r.estado === est);
        },
        leer: (id) => ({
            nombre: g('admin-nombre'), email: g('admin-email'), ci: g('admin-ci'),
            telefono: g('admin-telefono'), estado: g('admin-estado'), obs: g('admin-obs'),
            fecha: id ? DB.admins.find(x => x.id === id)?.fecha : new Date().toLocaleDateString('es-ES'),
        }),
        cargar: (r) => { s('admin-nombre', r.nombre); s('admin-email', r.email); s('admin-ci', r.ci); s('admin-telefono', r.telefono || ''); s('admin-estado', r.estado); s('admin-obs', r.obs || ''); },
    },
    docentes: {
        modal: 'docente', titulo: 'Docente',
        requeridos: ['nombre', 'email', 'ci', 'especialidad'],
        renderRow: (r, i) => `
            <tr>
                <td>${i + 1}</td>
                <td><div class="mod-user-cell"><div class="mod-avatar" style="background:linear-gradient(135deg,#10b981,#06b6d4)">${r.nombre.split(' ').slice(-1)[0][0]}</div><span>${r.nombre}</span></div></td>
                <td>${r.email}</td><td>${r.ci}</td>
                <td><span class="tipo-badge" style="background:#1e2d4a;color:#a78bfa">${r.especialidad}</span></td>
                <td><small style="color:var(--text-muted)">${r.materias || '—'}</small></td>
                <td>${r.telefono || '—'}</td><td>${badgeEstado(r.estado)}</td>
                <td>${accionesBtns('docentes', r.id)}</td>
            </tr>`,
        filtrar: (r) => {
            const q = (document.getElementById('searchDocente')?.value || '').toLowerCase();
            const esp = document.getElementById('filterDocenteEspecialidad')?.value || '';
            const est = document.getElementById('filterDocenteEstado')?.value || '';
            return (!q || (r.nombre + r.email + r.ci + r.especialidad).toLowerCase().includes(q)) && (!esp || r.especialidad === esp) && (!est || r.estado === est);
        },
        leer: () => ({ nombre: g('docente-nombre'), email: g('docente-email'), ci: g('docente-ci'), telefono: g('docente-telefono'), especialidad: g('docente-especialidad'), materias: g('docente-materias'), estado: g('docente-estado'), obs: g('docente-obs'), pass: g('docente-pass') }),
        cargar: (r) => { s('docente-nombre', r.nombre); s('docente-email', r.email); s('docente-ci', r.ci); s('docente-telefono', r.telefono || ''); s('docente-especialidad', r.especialidad); s('docente-materias', r.materias || ''); s('docente-estado', r.estado); s('docente-obs', r.obs || ''); s('docente-pass', ''); s('docente-pass-confirm', ''); const sb = document.getElementById('doc-pass-strength'); if (sb) { sb.querySelector('.pass-strength-fill').style.width = '0'; sb.querySelector('.pass-strength-label').textContent = ''; } const mb = document.getElementById('doc-pass-match'); if (mb) mb.textContent = ''; },
    },
    estudiantes: {
        modal: 'estudiante', titulo: 'Estudiante',
        requeridos: ['nombre', 'ci', 'semestre'],
        renderRow: (r, i) => `
            <tr>
                <td>${i + 1}</td>
                <td><div class="mod-user-cell"><div class="mod-avatar" style="background:linear-gradient(135deg,#f59e0b,#ef4444)">${r.nombre[0]}</div><span>${r.nombre}</span></div></td>
                <td>${r.ci}</td>
                <td><span class="tipo-badge" style="background:#1e2d4a;color:#f59e0b">${r.semestre}</span></td>
                <td>${r.tutor || '—'}</td><td>${r.tutorTel || '—'}</td><td>${r.email || '—'}</td>
                <td>${badgeEstado(r.estado)}</td>
                <td>${accionesBtns('estudiantes', r.id)}</td>
            </tr>`,
        filtrar: (r) => {
            const q = (document.getElementById('searchEstudiante')?.value || '').toLowerCase();
            const sem = document.getElementById('filterEstudianteSemestre')?.value || '';
            const est = document.getElementById('filterEstudianteEstado')?.value || '';
            return (!q || (r.nombre + r.ci + r.tutor).toLowerCase().includes(q)) && (!sem || r.semestre === sem) && (!est || r.estado === est);
        },
        leer: (id) => ({ nombre: g('estudiante-nombre'), ci: g('estudiante-ci'), semestre: g('estudiante-semestre'), nacimiento: g('estudiante-nacimiento'), email: g('estudiante-email'), telefono: g('estudiante-telefono'), tutor: g('estudiante-tutor'), tutorTel: g('estudiante-tutor-tel'), estado: g('estudiante-estado'), direccion: g('estudiante-direccion'), obs: g('estudiante-obs'), pass: g('estudiante-pass') }),
        cargar: (r) => { s('estudiante-nombre', r.nombre); s('estudiante-ci', r.ci); s('estudiante-semestre', r.semestre); s('estudiante-nacimiento', r.nacimiento || ''); s('estudiante-email', r.email || ''); s('estudiante-telefono', r.telefono || ''); s('estudiante-tutor', r.tutor || ''); s('estudiante-tutor-tel', r.tutorTel || ''); s('estudiante-estado', r.estado); s('estudiante-direccion', r.direccion || ''); s('estudiante-obs', r.obs || ''); s('estudiante-pass', ''); s('estudiante-pass-confirm', ''); const sb = document.getElementById('est-pass-strength'); if (sb) { sb.querySelector('.pass-strength-fill').style.width = '0'; sb.querySelector('.pass-strength-label').textContent = ''; } const mb = document.getElementById('est-pass-match'); if (mb) mb.textContent = ''; },
    },
    materias: {
        modal: 'materia', titulo: 'Materia',
        requeridos: ['nombre', 'semestre'],
        renderRow: (r, i) => `
            <tr>
                <td>${i + 1}</td>
                <td><strong style="color:var(--text-primary)">${r.nombre}</strong></td>
                <td><span class="tipo-badge" style="background:#2a1e4a;color:#a78bfa">${r.semestre}</span></td>
                <td>${r.docente || '—'}</td>
                <td><span class="prioridad-badge" style="background:#1a3a2a;color:#10b981">${r.estudiantes || 0}</span></td>
                <td>${r.horas || '—'} hrs</td>
                <td><small style="color:var(--text-muted)">${(r.desc || '').slice(0, 40)}${(r.desc || '').length > 40 ? '...' : ''}</small></td>
                <td>${accionesBtns('materias', r.id)}</td>
            </tr>`,
        filtrar: (r) => {
            const q = (document.getElementById('searchMateria')?.value || '').toLowerCase();
            const sem = document.getElementById('filterMateriaSemestre')?.value || '';
            return (!q || (r.nombre + r.docente).toLowerCase().includes(q)) && (!sem || r.semestre === sem);
        },
        leer: () => ({ nombre: g('materia-nombre'), semestre: g('materia-semestre'), docente: g('materia-docente'), horas: g('materia-horas'), estudiantes: g('materia-estudiantes'), aula: g('materia-aula'), desc: g('materia-desc') }),
        cargar: (r) => { s('materia-nombre', r.nombre); s('materia-semestre', r.semestre); s('materia-docente', r.docente || ''); s('materia-horas', r.horas || ''); s('materia-estudiantes', r.estudiantes || ''); s('materia-aula', r.aula || ''); s('materia-desc', r.desc || ''); },
    },
    actividades: {
        modal: 'actividad', titulo: 'Actividad',
        requeridos: ['nombre', 'tipo', 'materia'],
        renderRow: (r, i) => {
            const tc = { Tarea: { bg: '#1a3a2a', c: '#34d399' }, Examen: { bg: '#1e3350', c: '#a78bfa' }, Práctica: { bg: '#3a2a1e', c: '#fbbf24' }, Proyecto: { bg: '#1a2f5a', c: '#60a5fa' }, Cuestionario: { bg: '#2a1e4a', c: '#c084fc' } }[r.tipo] || { bg: '#1e2d4a', c: '#8ba3c7' };
            const ec = { Activa: { bg: '#dcfce7', c: '#16a34a' }, Cerrada: { bg: '#fee2e2', c: '#ef4444' }, Pendiente: { bg: '#fef3c7', c: '#d97706' } }[r.estado] || { bg: '#dbeafe', c: '#2563eb' };
            return `<tr>
                <td>${i + 1}</td>
                <td><strong style="color:var(--text-primary)">${r.nombre}</strong></td>
                <td><span class="tipo-badge" style="background:${tc.bg};color:${tc.c}">${r.tipo}</span></td>
                <td>${r.materia}</td><td>${r.docente || '—'}</td>
                <td>${r.fecha || '—'}</td>
                <td><span class="prioridad-badge" style="background:#1a3a2a;color:#10b981">${r.puntos || 0} pts</span></td>
                <td><span class="estado-badge" style="background:${ec.bg};color:${ec.c}">● ${r.estado}</span></td>
                <td>${accionesBtns('actividades', r.id)}</td>
            </tr>`;
        },
        filtrar: (r) => {
            const q = (document.getElementById('searchActividad')?.value || '').toLowerCase();
            const tp = document.getElementById('filterActividadTipo')?.value || '';
            const est = document.getElementById('filterActividadEstado')?.value || '';
            return (!q || (r.nombre + r.materia + r.docente).toLowerCase().includes(q)) && (!tp || r.tipo === tp) && (!est || r.estado === est);
        },
        leer: () => ({ nombre: g('actividad-nombre'), tipo: g('actividad-tipo'), materia: g('actividad-materia'), docente: g('actividad-docente'), fecha: g('actividad-fecha'), puntos: g('actividad-puntos'), estado: g('actividad-estado'), semestre: g('actividad-semestre'), desc: g('actividad-desc') }),
        cargar: (r) => { s('actividad-nombre', r.nombre); s('actividad-tipo', r.tipo); s('actividad-materia', r.materia); s('actividad-docente', r.docente || ''); s('actividad-fecha', r.fecha || ''); s('actividad-puntos', r.puntos || ''); s('actividad-estado', r.estado); s('actividad-semestre', r.semestre || ''); s('actividad-desc', r.desc || ''); },
    },
};

/* ── Backend Connection (Node.js API) ── */
const API_BASE = 'http://localhost:3001/api';

async function cargarUsuariosDesdeBackend() {
    try {
        const res = await fetch(`${API_BASE}/admin/users`);
        if (!res.ok) return;
        const users = await res.json();
        
        const ests = [];
        const docs = [];
        const adms = [];

        users.forEach(u => {
            if (u.role === 'student') {
                ests.push({
                    id: u._id,
                    nombre: u.name,
                    email: u.email,
                    ci: u.ci || '—',
                    semestre: u.grade || '1.° Semestre',
                    telefono: u.telefono || '',
                    tutor: u.tutor || '',
                    tutorTel: u.tutorTel || '',
                    estado: 'Activo',
                    direccion: u.direccion || '',
                    obs: ''
                });
            } else if (u.role === 'teacher') {
                docs.push({
                    id: u._id,
                    nombre: u.name,
                    email: u.email,
                    ci: u.ci || '—',
                    especialidad: u.especialidad || u.grade || 'General',
                    materias: u.materias || '',
                    telefono: u.telefono || '',
                    estado: 'Activo',
                    obs: ''
                });
            } else if (u.role === 'admin') {
                adms.push({
                    id: u._id,
                    nombre: u.name,
                    email: u.email,
                    ci: u.ci || '—',
                    telefono: u.telefono || '',
                    estado: 'Activo',
                    obs: '',
                    fecha: u.created_at ? new Date(u.created_at).toLocaleDateString('es-ES') : '—'
                });
            }
        });

        if (ests.length > 0) DB.estudiantes = ests;
        if (docs.length > 0) DB.docentes = docs;
        if (adms.length > 0) DB.admins = adms;

        renderTabla('estudiantes');
        renderTabla('docentes');
        renderTabla('admins');
        
        const elEst = document.getElementById('stat-estudiantes');
        if (elEst && ests.length > 0) elEst.textContent = ests.length;
        const elDoc = document.getElementById('stat-docentes');
        if (elDoc && docs.length > 0) elDoc.textContent = docs.length;
    } catch (err) {
        // Backend no disponible — el panel sigue funcionando en modo local
        console.info('ℹ️ Backend no disponible, usando datos locales:', err.message);
    }
}

// Cargar usuarios desde MongoDB al iniciar
cargarUsuariosDesdeBackend();

/* ── Helpers ── */
function g(id) { const el = document.getElementById(id); return el ? el.value.trim() : ''; }
function s(id, val) { const el = document.getElementById(id); if (el) el.value = val ?? ''; }

// Verifica si un ID es un ObjectId válido de MongoDB (24 chars hexadecimales)
function esObjectIdMongo(id) {
  return typeof id === 'string' && /^[a-f\d]{24}$/i.test(id);
}

function badgeEstado(estado) {
    const map = { Activo: '#dcfce7|#16a34a', Inactivo: '#fee2e2|#ef4444', Egresado: '#dbeafe|#2563eb' };
    const [bg, c] = (map[estado] || '#f1f5f9|#64748b').split('|');
    return `<span class="estado-badge" style="background:${bg};color:${c}">● ${estado}</span>`;
}

function accionesBtns(modulo, id) {
    return `<div class="accion-btns">
        <button class="accion-icon-btn edit" title="Editar" onclick="abrirEditar('${modulo}','${id}')">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/></svg>
        </button>
        <button class="accion-icon-btn delete" title="Eliminar" onclick="eliminar('${modulo}','${id}')">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/></svg>
        </button>
    </div>`;
}

/* ── Render tabla genérico ── */
function renderTabla(modulo) {
    const cfg = MOD_CFG[modulo];
    const tbody = document.getElementById(`tbody-${modulo}`);
    const info = document.getElementById(`info-${modulo}`);
    if (!tbody) return;

    const filtrados = DB[modulo].filter(cfg.filtrar);

    if (filtrados.length === 0) {
        tbody.innerHTML = `<tr><td colspan="10" style="text-align:center;padding:40px;color:var(--text-muted)">No se encontraron registros. <button class="card-link" onclick="openModal('${cfg.modal}')">+ Agregar primero</button></td></tr>`;
    } else {
        tbody.innerHTML = filtrados.map((r, i) => cfg.renderRow(r, i)).join('');
    }
    if (info) info.textContent = `${filtrados.length} de ${DB[modulo].length} registros`;
}

/* ── Modal: Abrir nuevo ── */
function openModal(tipo) {
    const modulo = tipo === 'admin' ? 'admins' : tipo + 's';
    editandoId[modulo] = null;
    const cfg = MOD_CFG[modulo];
    const titleEl = document.getElementById(`modal-${tipo}-title`);
    if (titleEl) titleEl.textContent = `Nuevo ${cfg.titulo}`;
    // Limpiar campos
    document.querySelectorAll(`#modal-${tipo} input, #modal-${tipo} select, #modal-${tipo} textarea`).forEach(el => {
        if (el.type === 'hidden') return;
        if (el.tagName === 'SELECT') el.selectedIndex = 0;
        else el.value = '';
    });
    document.getElementById(`modal-backdrop-${tipo}`)?.classList.add('open');
    document.getElementById(`modal-${tipo}`)?.classList.add('open');
}

/* ── Modal: Abrir editar ── */
function abrirEditar(modulo, id) {
    const cfg = MOD_CFG[modulo];
    const tipo = cfg.modal;
    const reg = DB[modulo].find(r => r.id == id);
    if (!reg) return;
    editandoId[modulo] = id;
    const titleEl = document.getElementById(`modal-${tipo}-title`);
    if (titleEl) titleEl.textContent = `Editar ${cfg.titulo}`;
    cfg.cargar(reg);
    document.getElementById(`modal-backdrop-${tipo}`)?.classList.add('open');
    document.getElementById(`modal-${tipo}`)?.classList.add('open');
}

/* ── Modal: Cerrar ── */
function closeModal(tipo) {
    document.getElementById(`modal-backdrop-${tipo}`)?.classList.remove('open');
    document.getElementById(`modal-${tipo}`)?.classList.remove('open');
}

/* ── Guardar (crear o editar) ── */
async function guardar(modulo) {
    const cfg = MOD_CFG[modulo];
    const datos = cfg.leer(editandoId[modulo]);

    // Validar requeridos
    for (const campo of (cfg.requeridos || [])) {
        if (!datos[campo]) {
            showToast(`⚠️ El campo "${campo}" es obligatorio`);
            return;
        }
    }

    // Validar contraseña en módulo estudiantes y docentes
    if (modulo === 'estudiantes' || modulo === 'docentes') {
        const prefijo = modulo === 'estudiantes' ? 'estudiante' : 'docente';
        const pass    = g(`${prefijo}-pass`);
        const confirm = g(`${prefijo}-pass-confirm`);
        if (pass || (!editandoId[modulo])) {
            if (pass && pass.length < 6) {
                showToast('⚠️ La contraseña debe tener al menos 6 caracteres');
                return;
            }
            if (pass && pass !== confirm) {
                showToast('⚠️ Las contraseñas no coinciden');
                return;
            }
        }
        if (!pass && editandoId[modulo]) {
            const anterior = DB[modulo].find(r => r.id == editandoId[modulo]);
            if (anterior) datos.pass = anterior.pass || '';
        }
    }

    // Si es módulo de usuarios, guardar en backend MongoDB
    if (modulo === 'estudiantes' || modulo === 'docentes' || modulo === 'admins') {
        const role = modulo === 'estudiantes' ? 'student' : modulo === 'docentes' ? 'teacher' : 'admin';
        const grade = modulo === 'estudiantes' ? datos.semestre : modulo === 'docentes' ? datos.especialidad : '';

        const payload = {
            name: datos.nombre,
            email: datos.email,
            password: datos.pass || '123456',
            role: role,
            grade: grade,
            ci: datos.ci,
            telefono: datos.telefono,
            tutor: datos.tutor,
            tutorTel: datos.tutorTel,
            especialidad: datos.especialidad,
            direccion: datos.direccion,
            materias: datos.materias
        };

        // Solo hacer PUT si el ID es un ObjectId real de MongoDB.
        // Si el registro fue creado localmente (ID numérico), siempre hacer POST para crearlo en el backend.
        const isEdit = !!editandoId[modulo] && esObjectIdMongo(String(editandoId[modulo]));
        const url = isEdit ? `${API_BASE}/admin/users/${editandoId[modulo]}` : `${API_BASE}/admin/users`;
        const method = isEdit ? 'PUT' : 'POST';

        try {
            const res = await fetch(url, {
                method: method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            const result = await res.json();

            if (!res.ok) {
                showToast(`❌ Error: ${result.error || 'No se pudo guardar el usuario'}`);
                return;
            }

            datos.id = result._id;
            showToast(`✅ ${cfg.titulo} guardado en MongoDB — ¡Ya puede ingresar en la App Móvil!`);
        } catch (e) {
            // Backend no disponible — guardar solo en local sin molestar al usuario
            console.warn('Backend no disponible, guardando solo en local:', e.message);
            // No mostramos toast de error; el registro se guarda igual en DB local
        }
    }

    if (editandoId[modulo]) {
        // Editar local
        const idx = DB[modulo].findIndex(r => r.id == editandoId[modulo]);
        if (idx !== -1) DB[modulo][idx] = { ...DB[modulo][idx], ...datos };
    } else {
        // Crear local
        const nuevoId = datos.id || (Math.max(0, ...DB[modulo].map(r => typeof r.id === 'number' ? r.id : 0)) + 1);
        DB[modulo].unshift({ ...datos, id: nuevoId });
    }

    closeModal(cfg.modal);
    renderTabla(modulo);
    editandoId[modulo] = null;
}

// ── Contraseña: mostrar/ocultar ───────────────────
function togglePassVis(inputId, btn) {
    const input = document.getElementById(inputId);
    if (!input) return;
    const isPassword = input.type === 'password';
    input.type = isPassword ? 'text' : 'password';
    // Cambiar ícono (ojo abierto / cerrado)
    btn.innerHTML = isPassword
        ? `<svg class="eye-icon" width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24M1 1l22 22"/></svg>`
        : `<svg class="eye-icon" width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"/></svg>`;
}

// ── Contraseña: indicador de fortaleza ────────────
function checkPassStrength(inputId, barId) {
    const pass = document.getElementById(inputId)?.value || '';
    const bar = document.getElementById(barId);
    if (!bar) return;
    const fill = bar.querySelector('.pass-strength-fill');
    const label = bar.querySelector('.pass-strength-label');

    let score = 0;
    if (pass.length >= 6) score++;
    if (pass.length >= 10) score++;
    if (/[A-Z]/.test(pass)) score++;
    if (/[0-9]/.test(pass)) score++;
    if (/[^A-Za-z0-9]/.test(pass)) score++;

    const levels = [
        { pct: '0%', color: 'transparent', text: '' },
        { pct: '25%', color: '#ef4444', text: 'Muy débil' },
        { pct: '50%', color: '#f59e0b', text: 'Débil' },
        { pct: '65%', color: '#eab308', text: 'Regular' },
        { pct: '82%', color: '#22c55e', text: 'Fuerte' },
        { pct: '100%', color: '#10b981', text: 'Muy fuerte' },
    ];
    const lvl = pass.length === 0 ? levels[0] : levels[Math.min(score, 5)];
    fill.style.width = lvl.pct;
    fill.style.background = lvl.color;
    label.textContent = lvl.text;
    label.style.color = lvl.color;
}

// ── Contraseña: verificar coincidencia ────────────
function checkPassMatch(passId, confirmId, msgId) {
    const pass = document.getElementById(passId)?.value || '';
    const confirm = document.getElementById(confirmId)?.value || '';
    const msg = document.getElementById(msgId);
    if (!msg) return;
    if (!confirm) { msg.textContent = ''; return; }
    if (pass === confirm) {
        msg.textContent = '✓ Las contraseñas coinciden';
        msg.style.color = '#10b981';
    } else {
        msg.textContent = '✗ Las contraseñas no coinciden';
        msg.style.color = '#ef4444';
    }
}

/* ── Eliminar ── */
async function eliminar(modulo, id) {
    const cfg = MOD_CFG[modulo];
    if (!confirm(`¿Eliminar este ${cfg.titulo.toLowerCase()}? Esta acción no se puede deshacer.`)) return;

    if (modulo === 'estudiantes' || modulo === 'docentes' || modulo === 'admins') {
        // Solo llamar al backend si el ID es un ObjectId real de MongoDB
        if (esObjectIdMongo(id)) {
            try {
                await fetch(`${API_BASE}/admin/users/${id}`, { method: 'DELETE' });
            } catch (e) {
                console.error('Error al eliminar en backend:', e);
            }
        }
    }

    DB[modulo] = DB[modulo].filter(r => r.id != id);
    renderTabla(modulo);
    showToast(`🗑️ ${cfg.titulo} eliminado`);
}

/* ── Exportar CSV ── */
function exportarModulo(modulo, nombre) {
    const datos = DB[modulo];
    if (!datos.length) { showToast('No hay datos para exportar'); return; }
    const cols = Object.keys(datos[0]).filter(k => k !== 'id');
    const rows = [cols, ...datos.map(r => cols.map(c => `"${r[c] ?? ''}"`))];
    const csv = rows.map(r => r.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url;
    a.download = `${nombre.toLowerCase()}_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    showToast(`📥 ${nombre} exportado como CSV`);
}

// ═══════════════════════════════════════════════════
//  AGENDA DE EVENTOS — Datos y lógica
// ═══════════════════════════════════════════════════


const TIPO_COLORS = {
    'Reunión': { bg: '#1e3a5f', text: '#60a5fa', border: '#3b82f6' },
    'Examen': { bg: '#1e3350', text: '#a78bfa', border: '#8b5cf6' },
    'Entrega': { bg: '#1a3a2a', text: '#34d399', border: '#10b981' },
    'Charla': { bg: '#3a2a1e', text: '#fbbf24', border: '#f59e0b' },
    'Académico': { bg: '#1e3a2a', text: '#6ee7b7', border: '#10b981' },
};

const PRIORIDAD_COLORS = {
    'Alta': { bg: '#fee2e2', text: '#ef4444' },
    'Media': { bg: '#fef3c7', text: '#d97706' },
    'Baja': { bg: '#dcfce7', text: '#16a34a' },
};

const ESTADO_COLORS = {
    'Confirmado': { bg: '#dcfce7', text: '#16a34a' },
    'Pendiente': { bg: '#fef3c7', text: '#d97706' },
    'Programado': { bg: '#dbeafe', text: '#2563eb' },
};

// Dataset de eventos
let agendaEventos = [
    {
        id: 1, nombre: 'Reunión de docentes',
        descripcion: 'Reunión mensual de planificación académica. Reunión para revisar el avance de las actividades académicas, evaluar resultados del mes y planificar las estrategias para el próximo periodo.',
        tipo: 'Reunión', fecha: '2026-07-02', hora: '10:00',
        lugar: 'Sala de reuniones', prioridad: 'Alta', estado: 'Confirmado',
        organizador: 'Administrador',
        participantes: [
            { nombre: 'Prof. Carlos Ruiz', rol: 'Docente' },
            { nombre: 'Prof. Ana López', rol: 'Docente' },
            { nombre: 'Prof. Miguel Torres', rol: 'Docente' },
        ],
    },
    {
        id: 2, nombre: 'Examen de Matemáticas',
        descripcion: 'Examen parcial del segundo trimestre de la asignatura de Matemáticas para el aula 101.',
        tipo: 'Examen', fecha: '2026-07-03', hora: '10:45',
        lugar: 'Aula 101', prioridad: 'Media', estado: 'Pendiente',
        organizador: 'Prof. Carlos Ruiz',
        participantes: [{ nombre: 'Prof. Carlos Ruiz', rol: 'Docente' }],
    },
    {
        id: 3, nombre: 'Entrega de trabajo',
        descripcion: 'Entrega del trabajo de investigación del grupo de metodología de investigación.',
        tipo: 'Entrega', fecha: '2026-07-04', hora: '11:30',
        lugar: 'Plataforma virtual', prioridad: 'Baja', estado: 'Programado',
        organizador: 'Prof. Ana López',
        participantes: [{ nombre: 'Prof. Ana López', rol: 'Docente' }],
    },
    {
        id: 4, nombre: 'Charla Inteligencia Artificial',
        descripcion: 'Charla magistral sobre IA impartida para todas las carreras.',
        tipo: 'Charla', fecha: '2026-07-05', hora: '14:00',
        lugar: 'Auditorio Principal', prioridad: 'Alta', estado: 'Confirmado',
        organizador: 'Invitado Especial',
        participantes: [{ nombre: 'Invitado Especial', rol: 'Expositor' }],
    },
    {
        id: 5, nombre: 'Inicio de clases',
        descripcion: 'Inicio oficial del segundo semestre. Se realizará en todos los aulas.',
        tipo: 'Académico', fecha: '2026-07-07', hora: '07:30',
        lugar: 'Todos los aulas', prioridad: 'Alta', estado: 'Confirmado',
        organizador: 'Administración',
        participantes: [{ nombre: 'Administración', rol: 'Organizador' }],
    },
    {
        id: 6, nombre: 'Consejo Académico',
        descripcion: 'Reunión del consejo académico institucional.',
        tipo: 'Reunión', fecha: '2026-07-09', hora: '09:00',
        lugar: 'Sala de consejo', prioridad: 'Media', estado: 'Pendiente',
        organizador: 'Director Académico',
        participantes: [{ nombre: 'Director Académico', rol: 'Director' }],
    },
];

let eventoEditandoId = null;

// Inicializa la agenda cuando se navega a ella
function initAgenda() {
    // Fecha
    const dateEl = document.getElementById('agendaDate');
    if (dateEl) {
        const now = new Date();
        const opts = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
        dateEl.textContent = now.toLocaleDateString('es-ES', opts);
    }
    renderAgendaTable(agendaEventos);
}

// Renderiza la tabla de eventos
function renderAgendaTable(eventos) {
    const tbody = document.getElementById('agendaTableBody');
    if (!tbody) return;

    if (eventos.length === 0) {
        tbody.innerHTML = `<tr><td colspan="9" style="text-align:center;padding:40px;color:var(--text-muted)">No se encontraron eventos</td></tr>`;
        document.getElementById('paginationInfo').textContent = 'Mostrando 0 eventos';
        return;
    }

    tbody.innerHTML = eventos.map((ev, idx) => {
        const tc = TIPO_COLORS[ev.tipo] || TIPO_COLORS['Reunión'];
        const pc = PRIORIDAD_COLORS[ev.prioridad] || PRIORIDAD_COLORS['Media'];
        const ec = ESTADO_COLORS[ev.estado] || ESTADO_COLORS['Pendiente'];
        const fechaObj = new Date(ev.fecha + 'T' + ev.hora);
        const fechaStr = fechaObj.toLocaleDateString('es-ES', { day: '2-digit', month: '2-digit', year: 'numeric' });
        const horaStr = ev.hora;
        const colorBar = tc.border;

        return `
        <tr class="agenda-row" onclick="mostrarDetalle(${ev.id})" data-id="${ev.id}">
            <td><div class="row-color-bar" style="background:${colorBar}"></div></td>
            <td>
                <div class="ev-name-cell">
                    <span class="ev-name">${ev.nombre}</span>
                    <span class="ev-desc-short">${ev.descripcion.slice(0, 50)}...</span>
                </div>
            </td>
            <td>
                <span class="tipo-badge" style="background:${tc.bg};color:${tc.text};border:1px solid ${tc.border}20">${ev.tipo}</span>
            </td>
            <td>
                <div class="fecha-cell">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor" style="opacity:.6"><path d="M9 11H7v2h2v-2zm4 0h-2v2h2v-2zm4 0h-2v2h2v-2zm2-7h-1V2h-2v2H8V2H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V9h14v11z"/></svg>
                    ${fechaStr}<br><small style="opacity:.7">${horaStr} AM</small>
                </div>
            </td>
            <td class="lugar-cell">${ev.lugar}</td>
            <td>
                <span class="prioridad-badge" style="background:${pc.bg};color:${pc.text}">${ev.prioridad}</span>
            </td>
            <td>
                <span class="estado-badge" style="background:${ec.bg};color:${ec.text}">● ${ev.estado}</span>
            </td>
            <td class="organizador-cell">${ev.organizador}</td>
            <td>
                <div class="accion-btns">
                    <button class="accion-icon-btn edit" title="Editar" onclick="event.stopPropagation(); editarEvento(${ev.id})">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/></svg>
                    </button>
                    <button class="accion-icon-btn delete" title="Eliminar" onclick="event.stopPropagation(); eliminarEvento(${ev.id})">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/></svg>
                    </button>
                </div>
            </td>
        </tr>`;
    }).join('');

    document.getElementById('paginationInfo').textContent =
        `Mostrando 1 a ${eventos.length} de ${agendaEventos.length} eventos`;
}

// Mostrar detalle del evento
function mostrarDetalle(id) {
    const ev = agendaEventos.find(e => e.id === id);
    if (!ev) return;

    // Highlight fila activa
    document.querySelectorAll('.agenda-row').forEach(r => r.classList.remove('active-row'));
    const row = document.querySelector(`.agenda-row[data-id="${id}"]`);
    if (row) row.classList.add('active-row');

    const tc = TIPO_COLORS[ev.tipo] || TIPO_COLORS['Reunión'];
    const ec = ESTADO_COLORS[ev.estado] || ESTADO_COLORS['Pendiente'];
    const fechaObj = new Date(ev.fecha + 'T' + ev.hora);
    const fechaStr = fechaObj.toLocaleDateString('es-ES', { day: '2-digit', month: '2-digit', year: 'numeric' });

    const participantesHtml = ev.participantes.map(p => `
        <div class="participante-item">
            <div class="part-avatar">${p.nombre.split(' ').map(w => w[0]).slice(0, 2).join('')}</div>
            <div class="part-info">
                <span class="part-name">${p.nombre}</span>
                <span class="part-rol">${p.rol}</span>
            </div>
        </div>
    `).join('');

    document.getElementById('panelBody').innerHTML = `
        <div class="panel-evento-header">
            <div class="panel-ev-avatar" style="background:${tc.bg};border:2px solid ${tc.border}">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="${tc.text}"><path d="M17 12h-5v5h5v-5zM16 1v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2h-1V1h-2zm3 18H5V8h14v11z"/></svg>
            </div>
            <div class="panel-ev-meta">
                <span class="panel-ev-tipo" style="color:${tc.text}">${ev.tipo}</span>
                <span class="panel-ev-nombre">${ev.nombre}</span>
                <span class="panel-ev-sub">${ev.descripcion.slice(0, 70)}...</span>
            </div>
        </div>

        <div class="panel-info-grid">
            <div class="panel-info-item">
                <span class="pi-label">Tipo de evento</span>
                <span class="pi-value">
                    <span class="tipo-badge" style="background:${tc.bg};color:${tc.text}">${ev.tipo}</span>
                </span>
            </div>
            <div class="panel-info-item">
                <span class="pi-label">Estado</span>
                <span class="pi-value">
                    <span class="estado-badge" style="background:${ec.bg};color:${ec.text}">● ${ev.estado}</span>
                </span>
            </div>
            <div class="panel-info-item">
                <span class="pi-label">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><path d="M9 11H7v2h2v-2zm4 0h-2v2h2v-2zm4 0h-2v2h2v-2zm2-7h-1V2h-2v2H8V2H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V9h14v11z"/></svg>
                    Fecha y hora
                </span>
                <span class="pi-value">${fechaStr} — ${ev.hora} AM</span>
            </div>
            <div class="panel-info-item">
                <span class="pi-label">Organización</span>
                <span class="pi-value">${ev.organizador}</span>
            </div>
            <div class="panel-info-item">
                <span class="pi-label">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>
                    Lugar
                </span>
                <span class="pi-value">${ev.lugar}</span>
            </div>
        </div>

        <div class="panel-section-title">Descripción</div>
        <p class="panel-descripcion">${ev.descripcion}</p>

        <div class="panel-section-title">Participantes (${ev.participantes.length})</div>
        <div class="panel-participantes">${participantesHtml}</div>

        <div class="panel-section-title">Acciones</div>
        <div class="panel-acciones">
            <button class="btn-panel-edit" onclick="editarEvento(${ev.id})">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/></svg>
                Editar evento
            </button>
            <button class="btn-panel-delete" onclick="eliminarEvento(${ev.id})">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/></svg>
                Eliminar evento
            </button>
            <button class="btn-panel-cancel" onclick="cerrarDetalle()">✕ Cerrar</button>
        </div>

        <div class="panel-section-title">Actividad reciente</div>
        <div class="panel-actividad-log">
            <div class="log-item">
                <span class="log-dot green"></span>
                <div class="log-info">
                    <span>Evento creado por Administrador</span>
                    <span class="log-time">10:20 AM</span>
                </div>
            </div>
            <div class="log-item">
                <span class="log-dot blue"></span>
                <div class="log-info">
                    <span>Participante añadido: Prof. Carlos Ruiz</span>
                    <span class="log-time">10:22 AM</span>
                </div>
            </div>
            <div class="log-item">
                <span class="log-dot yellow"></span>
                <div class="log-info">
                    <span>Estado actualizado a ${ev.estado}</span>
                    <span class="log-time">10:35 AM</span>
                </div>
            </div>
        </div>
    `;

    // Mostrar panel
    document.getElementById('eventoDetailPanel').classList.add('visible');
}

function cerrarDetalle() {
    document.getElementById('eventoDetailPanel').classList.remove('visible');
    document.querySelectorAll('.agenda-row').forEach(r => r.classList.remove('active-row'));
}

// Filtrar eventos
function filterAgenda() {
    const tipo = document.getElementById('filterTipo')?.value || '';
    const estado = document.getElementById('filterEstado')?.value || '';
    const orden = document.getElementById('filterOrden')?.value || 'fecha';
    const dir = document.getElementById('filterDir')?.value || 'asc';
    const busq = (document.getElementById('agendaSearch')?.value || '').toLowerCase();

    let filtrados = agendaEventos.filter(ev => {
        const matchTipo = !tipo || ev.tipo === tipo;
        const matchEstado = !estado || ev.estado === estado;
        const matchBusq = !busq || ev.nombre.toLowerCase().includes(busq) ||
            ev.organizador.toLowerCase().includes(busq) ||
            ev.lugar.toLowerCase().includes(busq);
        return matchTipo && matchEstado && matchBusq;
    });

    filtrados.sort((a, b) => {
        let va, vb;
        if (orden === 'fecha') { va = a.fecha + a.hora; vb = b.fecha + b.hora; }
        else if (orden === 'prioridad') {
            const pord = { Alta: 0, Media: 1, Baja: 2 };
            va = pord[a.prioridad] ?? 1; vb = pord[b.prioridad] ?? 1;
        }
        else { va = a.nombre; vb = b.nombre; }

        if (va < vb) return dir === 'asc' ? -1 : 1;
        if (va > vb) return dir === 'asc' ? 1 : -1;
        return 0;
    });

    renderAgendaTable(filtrados);
}

// Modal Nuevo / Editar Evento
function openNuevoEventoModal() {
    eventoEditandoId = null;
    document.getElementById('modalEventoTitle').textContent = 'Nuevo Evento';
    document.getElementById('evNombre').value = '';
    document.getElementById('evTipo').value = '';
    document.getElementById('evFecha').value = '';
    document.getElementById('evHora').value = '';
    document.getElementById('evLugar').value = '';
    document.getElementById('evPrioridad').value = 'Media';
    document.getElementById('evDescripcion').value = '';
    document.getElementById('evOrganizador').value = 'Administrador';
    document.getElementById('evEstado').value = 'Pendiente';

    document.getElementById('modalBackdrop').classList.add('open');
    document.getElementById('modalEvento').classList.add('open');
}

function editarEvento(id) {
    const ev = agendaEventos.find(e => e.id === id);
    if (!ev) return;
    eventoEditandoId = id;

    document.getElementById('modalEventoTitle').textContent = 'Editar Evento';
    document.getElementById('evNombre').value = ev.nombre;
    document.getElementById('evTipo').value = ev.tipo;
    document.getElementById('evFecha').value = ev.fecha;
    document.getElementById('evHora').value = ev.hora;
    document.getElementById('evLugar').value = ev.lugar;
    document.getElementById('evPrioridad').value = ev.prioridad;
    document.getElementById('evDescripcion').value = ev.descripcion;
    document.getElementById('evOrganizador').value = ev.organizador;
    document.getElementById('evEstado').value = ev.estado;

    document.getElementById('modalBackdrop').classList.add('open');
    document.getElementById('modalEvento').classList.add('open');
}

function closeNuevoEventoModal() {
    document.getElementById('modalBackdrop').classList.remove('open');
    document.getElementById('modalEvento').classList.remove('open');
}

function guardarEvento() {
    const nombre = document.getElementById('evNombre').value.trim();
    const tipo = document.getElementById('evTipo').value;
    if (!nombre || !tipo) {
        showToast('⚠️ Completa los campos obligatorios');
        return;
    }

    const ev = {
        id: eventoEditandoId || (Date.now()),
        nombre,
        tipo,
        fecha: document.getElementById('evFecha').value || new Date().toISOString().split('T')[0],
        hora: document.getElementById('evHora').value || '08:00',
        lugar: document.getElementById('evLugar').value || '—',
        prioridad: document.getElementById('evPrioridad').value,
        descripcion: document.getElementById('evDescripcion').value || nombre,
        organizador: document.getElementById('evOrganizador').value || 'Administrador',
        estado: document.getElementById('evEstado').value,
        participantes: [{ nombre: document.getElementById('evOrganizador').value || 'Administrador', rol: 'Organizador' }],
    };

    if (eventoEditandoId) {
        const idx = agendaEventos.findIndex(e => e.id === eventoEditandoId);
        if (idx !== -1) agendaEventos[idx] = ev;
        showToast('✅ Evento actualizado correctamente');
    } else {
        agendaEventos.unshift(ev);
        showToast('✅ Evento creado correctamente');
    }

    closeNuevoEventoModal();
    filterAgenda();
    if (eventoEditandoId) mostrarDetalle(ev.id);
    eventoEditandoId = null;
}

function eliminarEvento(id) {
    if (!confirm('¿Eliminar este evento?')) return;
    agendaEventos = agendaEventos.filter(e => e.id !== id);
    cerrarDetalle();
    filterAgenda();
    showToast('🗑️ Evento eliminado');
}

function exportarAgenda() {
    const rows = [
        ['Nombre', 'Tipo', 'Fecha', 'Hora', 'Lugar', 'Prioridad', 'Estado', 'Organizador'],
        ...agendaEventos.map(e => [e.nombre, e.tipo, e.fecha, e.hora, e.lugar, e.prioridad, e.estado, e.organizador])
    ];
    const csv = rows.map(r => r.map(c => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url; a.download = 'agenda_eventos.csv'; a.click();
    showToast('📥 Agenda exportada como CSV');
}

// ── INIT ──────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    console.log('🎓 Sistema Académico — Panel Administrativo iniciado');

    initCounters();
    initSearch();
    initKeyboardShortcuts();
    initTooltips();
    initTableSearch();
    simulateRealtime();

    // Pequeño delay para las animaciones de cards
    setTimeout(initCardAnimations, 100);

    // Greeting en toast
    setTimeout(() => {
        const hour = new Date().getHours();
        const greeting = hour < 12 ? 'Buenos días' : hour < 18 ? 'Buenas tardes' : 'Buenas noches';
        showToast(`${greeting}, Administrador 👋`);
    }, 800);
});

// ═══════════════════════════════════════════════════
//  MÓDULO CALIFICACIONES
// ═══════════════════════════════════════════════════

// Datos de ejemplo como respaldo cuando el backend no está disponible
const califData = [
    { id: 1, estudiante: 'Luis Flores', materia: 'Prog. Web', actividad: 'Tarea 1', nota: 95, obs: 'Excelente trabajo' },
    { id: 2, estudiante: 'Ana Gómez', materia: 'Prog. Web', actividad: 'Tarea 1', nota: 88, obs: 'Revisar CSS' },
    { id: 3, estudiante: 'Pedro Ruiz', materia: 'Bases Datos', actividad: 'Examen 1', nota: 72, obs: 'Mejorar consultas' },
    { id: 4, estudiante: 'Sofía Torres', materia: 'Prog. Web', actividad: 'Tarea 1', nota: 100, obs: 'Perfecto' },
    { id: 5, estudiante: 'Carlos Mora', materia: 'Redes', actividad: 'Lab 1', nota: 45, obs: 'Prácticas más' },
    { id: 6, estudiante: 'María Chávez', materia: 'Bases Datos', actividad: 'Examen 1', nota: 91, obs: 'Muy bien' },
    { id: 7, estudiante: 'Diego Ticona', materia: 'Redes', actividad: 'Lab 1', nota: 38, obs: 'Necesita refuerzo' },
    { id: 8, estudiante: 'Camila Mamani', materia: 'Prog. Web', actividad: 'Proyecto 1', nota: 83, obs: 'Buen avance' },
];

let califFiltroMateria = '';
window._califDataActual = califData; // Dataset activo (backend o ejemplo)

// ── Cargar calificaciones reales desde el backend ─────────────
async function cargarCalificacionesDesdeBackend() {
    try {
        // Consultar tanto las calificaciones de Agenda (app móvil) como de Tasks
        const [resAgenda, resTasks] = await Promise.allSettled([
            fetch(`${API_BASE}/agenda/graded`),
            fetch(`${API_BASE}/tasks/graded`)
        ]);

        let allRecords = [];

        // 1. Procesar calificaciones de Agenda (donde califica el docente en el simulador)
        if (resAgenda.status === 'fulfilled' && resAgenda.value.ok) {
            const agendaData = await resAgenda.value.json();
            if (Array.isArray(agendaData)) {
                agendaData.forEach(item => {
                    const gradeVal = item.grade ?? item.grading?.grade;
                    if (gradeVal !== undefined && gradeVal !== null) {
                        allRecords.push({
                            id:         item._id,
                            estudiante: (item.userId && item.userId.name) ? item.userId.name : 'Estudiante',
                            docente:    (item.gradedBy && item.gradedBy.name) ? item.gradedBy.name : (item.grading?.teacherId ? 'Docente' : ''),
                            materia:    item.subject || 'Sin materia',
                            actividad:  item.title || 'Tarea de Agenda',
                            nota:       Number(gradeVal),
                            obs:        item.teacherComment || item.grading?.teacherComment || '',
                            tipo:       'agenda',
                            fecha:      item.gradedAt || item.grading?.gradedAt || null
                        });
                    }
                });
            }
        }

        // 2. Procesar calificaciones de Tasks
        if (resTasks.status === 'fulfilled' && resTasks.value.ok) {
            const tasksData = await resTasks.value.json();
            if (Array.isArray(tasksData)) {
                tasksData.forEach(item => {
                    if (item.grade !== undefined && item.grade !== null) {
                        allRecords.push({
                            id:         item._id,
                            estudiante: (item.userId && item.userId.name) ? item.userId.name : 'Estudiante',
                            docente:    (item.gradedBy && item.gradedBy.name) ? item.gradedBy.name : '',
                            materia:    item.subject || 'Sin materia',
                            actividad:  item.title || 'Tarea',
                            nota:       Number(item.grade),
                            obs:        item.teacherComment || '',
                            tipo:       'task',
                            fecha:      item.gradedAt || null
                        });
                    }
                });
            }
        }

        if (allRecords.length === 0) {
            console.log('ℹ️ No hay calificaciones reales aún en MongoDB, mostrando datos de ejemplo.');
            return null;
        }

        console.log(`✅ Calificaciones cargadas desde MongoDB: ${allRecords.length} registros (Agenda + Tasks)`);
        return allRecords;

    } catch (err) {
        console.warn('⚠️ Error al consultar calificaciones del backend:', err.message);
        return null;
    }
}

// ── Actualizar tabs de filtro con materias reales ─────────────
function actualizarTabsMaterias(datos) {
    const tabsContainer = document.getElementById('califTabs');
    if (!tabsContainer) return;
    const materias = [...new Set(datos.map(c => c.materia).filter(m => m && m !== '—'))];
    if (materias.length === 0) return;
    tabsContainer.innerHTML = `<button class="calif-tab active" data-materia="" onclick="filtrarCalif(this, '')">Todas</button>`;
    materias.forEach(mat => {
        tabsContainer.innerHTML += `<button class="calif-tab" data-materia="${mat}" onclick="filtrarCalif(this, '${mat}')">${mat}</button>`;
    });
}

async function initCalificaciones() {
    califFiltroMateria = '';
    document.querySelectorAll('.calif-tab').forEach(t => t.classList.remove('active'));
    const firstTab = document.querySelector('.calif-tab[data-materia=""]');
    if (firstTab) firstTab.classList.add('active');

    // Mostrar indicador de carga
    const tbody = document.getElementById('tbody-calificaciones');
    if (tbody) {
        tbody.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:30px;color:var(--text-muted)">
            ⏳ Cargando calificaciones del backend...</td></tr>`;
    }

    // Intentar cargar desde el backend MongoDB
    const datosBackend = await cargarCalificacionesDesdeBackend();
    const datosFinales = (datosBackend && datosBackend.length > 0) ? datosBackend : califData;

    // Si hay datos reales, actualizar los tabs de filtro por materia
    if (datosBackend && datosBackend.length > 0) {
        actualizarTabsMaterias(datosBackend);
        document.querySelectorAll('.calif-tab').forEach(t => t.classList.remove('active'));
        const allTab = document.querySelector('.calif-tab[data-materia=""]');
        if (allTab) allTab.classList.add('active');
    }

    // Guardar para uso en filtros y exportación
    window._califDataActual = datosFinales;

    renderCalifTabla(datosFinales);
    actualizarDistribucion(datosFinales);
    actualizarStats(datosFinales);
}

function filtrarCalif(btn, materia) {
    califFiltroMateria = materia;
    document.querySelectorAll('.calif-tab').forEach(t => t.classList.remove('active'));
    btn.classList.add('active');

    // Usar los datos activos (backend o ejemplo)
    const base = window._califDataActual || califData;
    const filtrados = materia
        ? base.filter(c => c.materia === materia)
        : base;

    renderCalifTabla(filtrados);
    actualizarDistribucion(filtrados);
    actualizarStats(filtrados);
}

function getNotaStyle(nota) {
    if (nota >= 90) return { bg: '#0d2b1f', color: '#10b981', label: '🟢' };
    if (nota >= 71) return { bg: '#2a2010', color: '#f59e0b', label: '🟡' };
    if (nota >= 51) return { bg: '#1e2a3a', color: '#60a5fa', label: '🔵' };
    return { bg: '#2a1018', color: '#ef4444', label: '🔴' };
}

function renderCalifTabla(datos) {
    const tbody = document.getElementById('tbody-calificaciones');
    const info = document.getElementById('info-calificaciones');
    if (!tbody) return;

    if (datos.length === 0) {
        tbody.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:40px;color:var(--text-muted)">No hay calificaciones para esta materia.</td></tr>`;
        if (info) info.textContent = '0 registros';
        return;
    }

    tbody.innerHTML = datos.map(c => {
        const st = getNotaStyle(c.nota);
        return `<tr>
            <td>
                <div class="mod-user-cell">
                    <div class="mod-avatar" style="background:linear-gradient(135deg,#10b981,#3b82f6)">${c.estudiante[0]}</div>
                    <span>${c.estudiante}</span>
                </div>
            </td>
            <td><span class="tipo-badge" style="background:#1e2d4a;color:#60a5fa">${c.materia}</span></td>
            <td>${c.actividad}</td>
            <td><span class="calif-nota-badge" style="background:${st.bg};color:${st.color};border:1px solid ${st.color}40">
                    ${c.nota} / 100
                </span>
            </td>
            <td>
                ${c.docente ? `<small style="color:var(--accent-primary);font-weight:500">👩‍🏫 ${c.docente}</small><br>` : ''}
                <small style="color:var(--text-muted)">${c.obs || '—'}</small>
            </td>
        </tr>`;
    }).join('');

    if (info) info.textContent = `${datos.length} de ${(window._califDataActual || califData).length} calificaciones`;
}

function actualizarStats(datos) {
    if (!datos.length) return;
    const promedio = (datos.reduce((s, c) => s + c.nota, 0) / datos.length).toFixed(1);
    const aprobados = datos.filter(c => c.nota >= 51).length;
    const reprobados = datos.filter(c => c.nota < 51).length;

    const elProm = document.getElementById('califPromedio');
    const elApro = document.getElementById('califAprobados');
    const elRepr = document.getElementById('califReprobados');
    if (elProm) elProm.textContent = promedio;
    if (elApro) elApro.textContent = aprobados;
    if (elRepr) elRepr.textContent = reprobados;
}

function actualizarDistribucion(datos) {
    const total = datos.length || 1;
    const sob = datos.filter(c => c.nota >= 90).length;
    const bue = datos.filter(c => c.nota >= 71 && c.nota < 90).length;
    const rie = datos.filter(c => c.nota < 51).length;

    const animate = (barId, countId, count) => {
        const bar = document.getElementById(barId);
        const count_el = document.getElementById(countId);
        if (count_el) count_el.textContent = count;
        if (bar) {
            bar.style.width = '0%';
            setTimeout(() => {
                bar.style.transition = 'width 0.8s cubic-bezier(0.4,0,0.2,1)';
                bar.style.width = Math.round((count / total) * 100) + '%';
            }, 80);
        }
    };

    animate('barSobresaliente', 'countSobresaliente', sob);
    animate('barBueno', 'countBueno', bue);
    animate('barRiesgo', 'countRiesgo', rie);
}

function exportarCalificaciones() {
    const base = window._califDataActual || califData;
    const datos = califFiltroMateria
        ? base.filter(c => c.materia === califFiltroMateria)
        : base;
    if (!datos.length) { showToast('No hay datos para exportar'); return; }
    const cols = ['estudiante', 'materia', 'actividad', 'nota', 'obs'];
    const rows = [cols, ...datos.map(r => cols.map(c => `"${r[c] ?? ''}"`))];
    const csv = rows.map(r => r.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url;
    a.download = `calificaciones_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    showToast('📥 Calificaciones exportadas como CSV');
}

// ═══════════════════════════════════════════════════
//  MÓDULO REPORTES
// ═══════════════════════════════════════════════════

const reportesData = {
    'Bimestre 1': {
        materias: [
            { id: 'ProgWeb', nombre: 'Prog. Web', val: 87, classBar: 'blue-bar', classText: 'blue-text' },
            { id: 'BasesDatos', nombre: 'Bases Datos', val: 74, classBar: 'green-bar', classText: 'green-text' },
            { id: 'Redes', nombre: 'Redes', val: 62, classBar: 'yellow-bar', classText: 'yellow-text' },
            { id: 'SO', nombre: 'S.O.', val: 91, classBar: 'purple-bar', classText: 'purple-text' },
            { id: 'Ingles', nombre: 'Inglés', val: 78, classBar: 'red-bar', classText: 'red-text' },
        ],
        actividades: {
            completadas: { count: 100, heightPct: 85 },
            progreso: { count: 80, heightPct: 68 },
            pendientes: { count: 40, heightPct: 35 },
        },
        resumen: {
            promedio: '78.4%',
            mejor: 'S.O. (91%)',
            menor: 'Redes (62%)',
            cumplimiento: '81.8%',
            texto: 'Durante el <strong>Bimestre 1</strong>, el rendimiento general del estudiantado se mantiene favorable con un promedio ponderado de 78.4%. La materia con mayor desempeño es <strong>Sistemas Operativos (91%)</strong>, mientras que <strong>Redes (62%)</strong> requiere un plan de apoyo enfocado en laboratorios prácticos. Se registraron 220 actividades totales, con un nivel de cumplimiento del 81.8%.'
        }
    },
    'Bimestre 2': {
        materias: [
            { id: 'ProgWeb', nombre: 'Prog. Web', val: 92, classBar: 'blue-bar', classText: 'blue-text' },
            { id: 'BasesDatos', nombre: 'Bases Datos', val: 81, classBar: 'green-bar', classText: 'green-text' },
            { id: 'Redes', nombre: 'Redes', val: 70, classBar: 'yellow-bar', classText: 'yellow-text' },
            { id: 'SO', nombre: 'S.O.', val: 88, classBar: 'purple-bar', classText: 'purple-text' },
            { id: 'Ingles', nombre: 'Inglés', val: 83, classBar: 'red-bar', classText: 'red-text' },
        ],
        actividades: {
            completadas: { count: 125, heightPct: 90 },
            progreso: { count: 60, heightPct: 50 },
            pendientes: { count: 25, heightPct: 22 },
        },
        resumen: {
            promedio: '82.8%',
            mejor: 'Prog. Web (92%)',
            menor: 'Redes (70%)',
            cumplimiento: '88.1%',
            texto: 'En el <strong>Bimestre 2</strong>, se evidenció un incremento positivo en el promedio general alcanzando 82.8%. <strong>Programación Web (92%)</strong> fue la materia sobresaliente. La tasa de entregas oportunas ascendió al 88.1% con 125 actividades completadas.'
        }
    },
    'Bimestre 3': {
        materias: [
            { id: 'ProgWeb', nombre: 'Prog. Web', val: 85, classBar: 'blue-bar', classText: 'blue-text' },
            { id: 'BasesDatos', nombre: 'Bases Datos', val: 88, classBar: 'green-bar', classText: 'green-text' },
            { id: 'Redes', nombre: 'Redes', val: 79, classBar: 'yellow-bar', classText: 'yellow-text' },
            { id: 'SO', nombre: 'S.O.', val: 94, classBar: 'purple-bar', classText: 'purple-text' },
            { id: 'Ingles', nombre: 'Inglés', val: 80, classBar: 'red-bar', classText: 'red-text' },
        ],
        actividades: {
            completadas: { count: 110, heightPct: 80 },
            progreso: { count: 70, heightPct: 58 },
            pendientes: { count: 30, heightPct: 28 },
        },
        resumen: {
            promedio: '85.2%',
            mejor: 'S.O. (94%)',
            menor: 'Redes (79%)',
            cumplimiento: '85.7%',
            texto: 'Durante el <strong>Bimestre 3</strong>, se consolidó la estabilidad académica. Destacan los logros en <strong>Sistemas Operativos (94%)</strong> y <strong>Bases de Datos (88%)</strong>. El plan de tutorías en Redes mostró mejoras significativas subiendo a 79%.'
        }
    },
    'Bimestre 4': {
        materias: [
            { id: 'ProgWeb', nombre: 'Prog. Web', val: 95, classBar: 'blue-bar', classText: 'blue-text' },
            { id: 'BasesDatos', nombre: 'Bases Datos', val: 90, classBar: 'green-bar', classText: 'green-text' },
            { id: 'Redes', nombre: 'Redes', val: 84, classBar: 'yellow-bar', classText: 'yellow-text' },
            { id: 'SO', nombre: 'S.O.', val: 96, classBar: 'purple-bar', classText: 'purple-text' },
            { id: 'Ingles', nombre: 'Inglés', val: 87, classBar: 'red-bar', classText: 'red-text' },
        ],
        actividades: {
            completadas: { count: 140, heightPct: 95 },
            progreso: { count: 45, heightPct: 38 },
            pendientes: { count: 15, heightPct: 14 },
        },
        resumen: {
            promedio: '90.4%',
            mejor: 'S.O. (96%)',
            menor: 'Redes (84%)',
            cumplimiento: '92.5%',
            texto: 'El <strong>Bimestre 4</strong> concluyó con excelentes resultados globales superando el 90.4% de promedio. El 92.5% de las actividades se culminaron satisfactoriamente antes del cierre de gestión.'
        }
    }
};

function initReportes() {
    const sel = document.getElementById('reporteBimestreSelect');
    const val = sel ? sel.value : 'Bimestre 1';
    cambiarBimestreReporte(val);
}

function cambiarBimestreReporte(bimestreKey) {
    const data = reportesData[bimestreKey] || reportesData['Bimestre 1'];

    // Titulo
    const tituloEl = document.getElementById('reporteBimestreTitulo');
    if (tituloEl) tituloEl.textContent = bimestreKey;

    // Animación de barras de materias
    data.materias.forEach(m => {
        const barEl = document.getElementById(`repBar${m.id}`);
        const valEl = document.getElementById(`repVal${m.id}`);
        if (valEl) valEl.textContent = `${m.val}%`;
        if (barEl) {
            barEl.style.width = '0%';
            setTimeout(() => {
                barEl.style.transition = 'width 0.8s cubic-bezier(0.4, 0, 0.2, 1)';
                barEl.style.width = `${m.val}%`;
            }, 60);
        }
    });

    // Column chart actividades
    const act = data.actividades;

    // Completadas
    const colValComp = document.getElementById('colValCompletadas');
    const colBarComp = document.getElementById('colBarCompletadas');
    const legComp = document.getElementById('legendCompletadas');
    if (colValComp) colValComp.textContent = act.completadas.count;
    if (legComp) legComp.textContent = act.completadas.count;
    if (colBarComp) {
        colBarComp.style.height = '0%';
        setTimeout(() => {
            colBarComp.style.transition = 'height 0.8s cubic-bezier(0.4, 0, 0.2, 1)';
            colBarComp.style.height = `${act.completadas.heightPct}%`;
        }, 60);
    }

    // Progreso
    const colValProg = document.getElementById('colValProgreso');
    const colBarProg = document.getElementById('colBarProgreso');
    const legProg = document.getElementById('legendProgreso');
    if (colValProg) colValProg.textContent = act.progreso.count;
    if (legProg) legProg.textContent = act.progreso.count;
    if (colBarProg) {
        colBarProg.style.height = '0%';
        setTimeout(() => {
            colBarProg.style.transition = 'height 0.8s cubic-bezier(0.4, 0, 0.2, 1)';
            colBarProg.style.height = `${act.progreso.heightPct}%`;
        }, 60);
    }

    // Pendientes
    const colValPend = document.getElementById('colValPendientes');
    const colBarPend = document.getElementById('colBarPendientes');
    const legPend = document.getElementById('legendPendientes');
    if (colValPend) colValPend.textContent = act.pendientes.count;
    if (legPend) legPend.textContent = act.pendientes.count;
    if (colBarPend) {
        colBarPend.style.height = '0%';
        setTimeout(() => {
            colBarPend.style.transition = 'height 0.8s cubic-bezier(0.4, 0, 0.2, 1)';
            colBarPend.style.height = `${act.pendientes.heightPct}%`;
        }, 60);
    }

    // Resumen ejecutivo
    const res = data.resumen;
    const resProm = document.getElementById('resPromedioGeneral');
    const resMej = document.getElementById('resMejorMateria');
    const resMen = document.getElementById('resMenorMateria');
    const resCum = document.getElementById('resTasaCumplimiento');
    const resTxt = document.getElementById('resumenTexto');

    if (resProm) resProm.textContent = res.promedio;
    if (resMej) resMej.textContent = res.mejor;
    if (resMen) resMen.textContent = res.menor;
    if (resCum) resCum.textContent = res.cumplimiento;
    if (resTxt) resTxt.innerHTML = res.texto;
}

function exportarReportePDF() {
    showToast('📄 Generando reporte PDF...');
    setTimeout(() => {
        window.print();
    }, 600);
}

// ═══════════════════════════════════════════════════
//  MÓDULO CONFIGURACIÓN
// ═══════════════════════════════════════════════════

function initConfiguracion() {
    // Activar primera pestaña por defecto
    const tabs = document.querySelectorAll('.config-tab');
    if (tabs.length > 0 && !document.querySelector('.config-tab.active')) {
        switchConfigTab('general', tabs[0]);
    }
}

function switchConfigTab(tabName, btnEl) {
    // Desactivar todas las pestañas y contenidos
    document.querySelectorAll('.config-tab').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.config-tab-content').forEach(c => c.classList.remove('active'));

    // Activar seleccionado
    if (btnEl) btnEl.classList.add('active');
    const targetContent = document.getElementById(`tab-config-${tabName}`);
    if (targetContent) targetContent.classList.add('active');
}

function guardarConfiguracion(e, seccion) {
    if (e) e.preventDefault();
    showToast(`✅ Configuración de ${seccion} guardada correctamente`);
}

function crearBackupSistema() {
    showToast('📦 Generando copia de seguridad del sistema...');
    setTimeout(() => {
        const dummyData = "BACKUP_SISTEMA_ACADEMICO_2026";
        const blob = new Blob([dummyData], { type: 'application/octet-stream' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `backup_sistema_${new Date().toISOString().split('T')[0]}.bak`;
        a.click();
        showToast('📥 Copia de seguridad descargada con éxito');
    }, 1200);
}

function limpiarCacheSistema() {
    showToast('🧹 Limpiando archivos en caché...');
    setTimeout(() => {
        showToast('✨ Caché del sistema optimizado y limpio');
    }, 1000);
}

function checkAuthStatus() {
    const isLoggedIn = localStorage.getItem('isLoggedIn') || sessionStorage.getItem('isLoggedIn');
    if (isLoggedIn !== 'true') {
        window.location.href = 'login.html';
    }
}

function handleLoginSubmit(e) {
    if (e && e.preventDefault) e.preventDefault();
    const remember = document.getElementById('panelRememberMe');
    if (remember && remember.checked) {
        localStorage.setItem('isLoggedIn', 'true');
    }
    sessionStorage.setItem('isLoggedIn', 'true');

    const overlay = document.getElementById('loginScreenOverlay');
    if (overlay) overlay.classList.add('hidden');
    showToast('👋 ¡Bienvenido de nuevo, Administrador!');
}

function logout(e) {
    if (e && e.preventDefault) e.preventDefault();
    localStorage.removeItem('isLoggedIn');
    sessionStorage.removeItem('isLoggedIn');
    sessionStorage.removeItem('adminEmail');

    if (typeof closeAllDropdowns === 'function') closeAllDropdowns();
    window.location.href = 'login.html';
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', checkAuthStatus);
} else {
    checkAuthStatus();
}

// ════════════════════════════════════════════════════════
//  3D CANVAS ANIMATION ENGINE (Bubbles + Walking People)
// ════════════════════════════════════════════════════════
let _canvasAnimId = null;

function init3DLoginCanvas(canvasId) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;
    const cx = canvas.getContext('2d');
    let W = 0, H = 0;

    function resize() {
        W = canvas.width  = window.innerWidth;
        H = canvas.height = window.innerHeight;
    }
    window.addEventListener('resize', () => { resize(); rebuild(); });
    resize();

    function rnd(a, b) { return a + Math.random() * (b - a); }

    class Bubble {
        constructor(scattered) { this._spawn(scattered); }
        _spawn(scat) {
            this.r  = rnd(8, 72);
            this.x  = rnd(this.r, Math.max(W - this.r, this.r + 1));
            this.y  = scat ? rnd(-this.r, H + this.r) : H + rnd(this.r, this.r + 250);
            this.vy = -rnd(0.15, 0.6);
            this.wp = rnd(0, Math.PI * 2);
            this.wf = rnd(0.006, 0.018);
            this.wa = rnd(0.3, 1.1);
            const isBlue = Math.random() > 0.3;
            this.hue = isBlue ? rnd(200, 250) : rnd(34, 52);
            this.sat = rnd(55, 88);
            this.opa = rnd(0.04, 0.22);
        }
        update() {
            this.y += this.vy;
            this.wp += this.wf;
            this.x += Math.sin(this.wp) * this.wa;
            if (this.y + this.r < 0) this._spawn(false);
        }
        draw() {
            const { x, y, r, hue, sat, opa } = this;
            const g = cx.createRadialGradient(x - r*0.33, y - r*0.36, r*0.04, x, y, r);
            g.addColorStop(0, `hsla(${hue+20},${sat+14}%,90%,${opa*1.55})`);
            g.addColorStop(0.44, `hsla(${hue},${sat}%,56%,${opa})`);
            g.addColorStop(1, `hsla(${hue-12},${sat-9}%,16%,${opa*0.16})`);
            cx.save();
            cx.beginPath(); cx.arc(x, y, r, 0, Math.PI*2);
            cx.fillStyle = g; cx.fill();
            const hl = cx.createRadialGradient(x - r*0.33, y - r*0.34, 0, x - r*0.26, y - r*0.26, r*0.52);
            hl.addColorStop(0, `rgba(255,255,255,${opa*1.4})`);
            hl.addColorStop(0.5, `rgba(255,255,255,${opa*0.35})`);
            hl.addColorStop(1, `rgba(255,255,255,0)`);
            cx.beginPath(); cx.arc(x, y, r, 0, Math.PI*2);
            cx.fillStyle = hl; cx.fill();
            cx.restore();
        }
    }

    const STUDENT_SHIRTS = ['#2563eb','#059669','#dc2626','#d97706','#0891b2','#7c3aed'];
    const TEACHER_SHIRTS = ['#4c1d95','#1e3a5f','#065f46'];

    function drawPerson(x, y, scale, type, wc, dir, alpha, shirt) {
        cx.save();
        cx.globalAlpha = Math.min(alpha, 1);
        cx.translate(x, y);
        cx.scale(dir * scale, scale);

        const legA = Math.sin(wc) * 30;
        const armA = Math.sin(wc + Math.PI) * 26;
        const bob  = Math.abs(Math.sin(wc * 2)) * 1.8;
        const SKIN = '#fbbf24', PANTS = '#1e293b', SHOE = '#0f172a';

        cx.translate(0, -bob);

        // Shadow
        cx.save();
        cx.translate(2, 83 + bob * 0.6);
        cx.scale(1.0, 0.22);
        const shg = cx.createRadialGradient(0,0,0,0,0,24);
        shg.addColorStop(0, 'rgba(0,0,0,0.32)');
        shg.addColorStop(1, 'rgba(0,0,0,0)');
        cx.beginPath(); cx.ellipse(0,0,24,8,0,0,Math.PI*2);
        cx.fillStyle = shg; cx.fill();
        cx.restore();

        // Back leg
        _leg(cx, -5, 52, legA, PANTS, SHOE);

        // Body
        cx.fillStyle = shirt;
        cx.beginPath();
        cx.moveTo(-11, 19); cx.bezierCurveTo(-14,22,-14,38,-13,54);
        cx.lineTo(13, 54);  cx.bezierCurveTo(14,38,14,22,11,19);
        cx.closePath(); cx.fill();

        if (type === 'student') {
            // Backpack
            cx.fillStyle = '#1e40af';
            cx.fillRect(-21, 21, 11, 24);
            cx.strokeStyle = '#60a5fa'; cx.lineWidth = 1.2;
            cx.beginPath(); cx.moveTo(-19,27); cx.lineTo(-10,27); cx.moveTo(-19,38); cx.lineTo(-10,38); cx.stroke();
        } else {
            // Tie & Book
            cx.fillStyle = 'white';
            cx.beginPath(); cx.moveTo(-4,19); cx.lineTo(0,28); cx.lineTo(4,19); cx.fill();
            cx.fillStyle = '#dc2626';
            cx.beginPath(); cx.moveTo(-2.8,24); cx.lineTo(2.8,24); cx.lineTo(3.5,43); cx.lineTo(0,50); cx.lineTo(-3.5,43); cx.fill();
            cx.fillRect(-23, 30, 13, 18);
        }

        // Arms
        _arm(cx, -11, 22, armA + 14, shirt, SKIN);
        _arm(cx, 11, 22, -armA + 14, shirt, SKIN);

        // Front leg
        _leg(cx, 5, 52, -legA, PANTS, SHOE);

        // Head
        cx.fillStyle = SKIN; cx.fillRect(-3.5, 10, 7, 10);
        cx.beginPath(); cx.arc(0, 4, 13, 0, Math.PI*2); cx.fill();

        // Hair
        cx.save();
        cx.beginPath(); cx.arc(0, 4, 13, 0, Math.PI*2); cx.clip();
        cx.fillStyle = type === 'student' ? '#1e293b' : '#6b7280';
        cx.beginPath(); cx.arc(0, 4, 13, -Math.PI*0.87, -Math.PI*0.13); cx.lineTo(0,4); cx.fill();
        cx.restore();

        // Eyes & Smile
        cx.fillStyle = '#1e293b';
        cx.beginPath(); cx.ellipse(-4.5, 5, 2.1, 2.4, 0, 0, Math.PI*2); cx.ellipse(4.5, 5, 2.1, 2.4, 0, 0, Math.PI*2); cx.fill();
        cx.beginPath(); cx.arc(0, 7, 5.5, 0.22, Math.PI - 0.22); cx.strokeStyle = '#92400e'; cx.lineWidth = 1.3; cx.stroke();

        cx.restore();
    }

    function _leg(c, bx, by, angle, color, shoeColor) {
        c.save(); c.translate(bx, by); c.rotate(angle * Math.PI / 180);
        c.strokeStyle = color; c.lineWidth = 5.5; c.lineCap = 'round';
        c.beginPath(); c.moveTo(0,0); c.lineTo(0,27); c.stroke();
        c.translate(0, 27); c.rotate(-angle * Math.PI / 180 * 0.38);
        c.fillStyle = shoeColor;
        c.beginPath(); c.ellipse(5, 1, 7.5, 3.5, 0, 0, Math.PI*2); c.fill();
        c.restore();
    }

    function _arm(c, bx, by, angle, sleeveColor, skinColor) {
        c.save(); c.translate(bx, by); c.rotate(angle * Math.PI / 180);
        c.strokeStyle = sleeveColor; c.lineWidth = 4.5; c.lineCap = 'round';
        c.beginPath(); c.moveTo(0,0); c.lineTo(0,20); c.stroke();
        c.beginPath(); c.arc(0, 20, 3.5, 0, Math.PI*2); c.fillStyle = skinColor; c.fill();
        c.restore();
    }

    let bubbles = [], people = [];

    function rebuild() {
        bubbles = [];
        for (let i = 0; i < 50; i++) bubbles.push(new Bubble(true));

        people = [];
        const gy = H - 14;
        function spawn(type, dir, idx) {
            const depth = rnd(0.5, 0.98);
            const sc = depth * 0.87;
            const shirts = type === 'student' ? STUDENT_SHIRTS : TEACHER_SHIRTS;
            return {
                type, dir, sc, y: gy - Math.round(78 * sc),
                shirt: shirts[idx % shirts.length],
                x: rnd(0, W), speed: rnd(0.4, 0.82) * depth,
                wc: rnd(0, Math.PI*2), wcSpd: rnd(0.042, 0.072),
                alpha: 0.45 + depth * 0.48
            };
        }
        for (let i = 0; i < 5; i++) people.push(spawn('student', 1, i));
        people.push(spawn('student', -1, 5));
        for (let i = 0; i < 3; i++) people.push(spawn('teacher', -1, i));
        for (let i = 3; i < 5; i++) people.push(spawn('teacher', 1, i));
        people.sort((a,b) => a.y - b.y);
    }

    rebuild();

    if (_canvasAnimId) cancelAnimationFrame(_canvasAnimId);

    function frame() {
        cx.clearRect(0, 0, W, H);
        const bg = cx.createRadialGradient(W*0.78, H*0.12, 0, W*0.5, H*0.5, W*1.05);
        bg.addColorStop(0, '#0d1d40'); bg.addColorStop(0.42, '#060b18'); bg.addColorStop(1, '#030610');
        cx.fillStyle = bg; cx.fillRect(0, 0, W, H);

        for (const b of bubbles) { b.update(); b.draw(); }

        const gy = H - 14;
        cx.save(); cx.globalAlpha = 0.24;
        const lineG = cx.createLinearGradient(0,0,W,0);
        lineG.addColorStop(0, 'rgba(0,0,0,0)'); lineG.addColorStop(0.5, '#60a5fa'); lineG.addColorStop(1, 'rgba(0,0,0,0)');
        cx.strokeStyle = lineG; cx.lineWidth = 1.8;
        cx.beginPath(); cx.moveTo(0, gy); cx.lineTo(W, gy); cx.stroke();
        cx.restore();

        for (const p of people) {
            p.wc += p.wcSpd; p.x += p.speed * p.dir;
            if (p.dir === 1 && p.x > W + 140) p.x = -140;
            else if (p.dir === -1 && p.x < -140) p.x = W + 140;
            drawPerson(p.x, p.y, p.sc, p.type, p.wc, p.dir, p.alpha, p.shirt);
        }

        _canvasAnimId = requestAnimationFrame(frame);
    }

    frame();
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', checkAuthStatus);
} else {
    checkAuthStatus();
}


// ═══════════════════════════════════════════════════
//  MÓDULO INSCRIPCIÓN — Datos y lógica
// ═══════════════════════════════════════════════════

/* ── Dataset de inscripciones ── */
let DB_inscripciones = [
    { id: 1, nombre: 'María José López', ci: '12345678', curso: '1° de Secundaria', gestion: 'Gestión 2025', fecha: '22 May 2025', hora: '10:30 AM', tutor: 'Carmen López', tutorTel: '+591 76543210', estado: 'Pendiente', obs: '', nivel: 'Secundaria', revisadoPor: '' },
    { id: 2, nombre: 'Carlos Ramírez', ci: '87654321', curso: '3° de Secundaria', gestion: 'Gestión 2025', fecha: '22 May 2025', hora: '09:15 AM', tutor: 'Jorge Ramírez', tutorTel: '+591 72345678', estado: 'Pendiente', obs: '', nivel: 'Secundaria', revisadoPor: '' },
    { id: 3, nombre: 'Valeria Sánchez', ci: '11223344', curso: '2° de Secundaria', gestion: 'Gestión 2025', fecha: '21 May 2025', hora: '04:45 PM', tutor: 'Ana Sánchez', tutorTel: '+591 71234567', estado: 'Aprobada', obs: 'Documentos completos', nivel: 'Secundaria', revisadoPor: 'Administrador' },
    { id: 4, nombre: 'Juan Fernández', ci: '44556677', curso: '4° de Secundaria', gestion: 'Gestión 2025', fecha: '21 May 2025', hora: '11:20 AM', tutor: 'María Fernández', tutorTel: '+591 70987654', estado: 'Aprobada', obs: '', nivel: 'Secundaria', revisadoPor: 'Administrador' },
    { id: 5, nombre: 'Lucía Méndez', ci: '99887766', curso: '5° de Secundaria', gestion: 'Gestión 2025', fecha: '20 May 2025', hora: '03:10 PM', tutor: 'Roberto Méndez', tutorTel: '+591 79876543', estado: 'Rechazada', obs: 'Falta certificado de nacimiento', nivel: 'Secundaria', revisadoPor: 'Administrador' },
    { id: 6, nombre: 'Andrés Flores', ci: '33221100', curso: '6° de Secundaria', gestion: 'Gestión 2025', fecha: '19 May 2025', hora: '08:00 AM', tutor: 'Patricia Flores', tutorTel: '+591 77001122', estado: 'Aprobada', obs: '', nivel: 'Secundaria', revisadoPor: 'Administrador' },
    { id: 7, nombre: 'Sofía Torrez', ci: '55443322', curso: '1° de Secundaria', gestion: 'Gestión 2025', fecha: '18 May 2025', hora: '02:30 PM', tutor: 'Luis Torrez', tutorTel: '+591 75443322', estado: 'Rechazada', obs: 'No cumple edad mínima', nivel: 'Secundaria', revisadoPor: 'Administrador' },
];

let inscEditandoId = null;

/* ── Inicializar módulo ── */
async function initInscripcion() {
    // Cargar inscripciones desde MongoDB primero
    try {
        const res = await fetch(`${API_BASE}/inscripciones`);
        if (res.ok) {
            const fromMongo = await res.json();
            if (fromMongo.length > 0) {
                // Mapear al formato local (id = _id de MongoDB)
                DB_inscripciones = fromMongo.map(r => ({
                    id: r._id,
                    nombre: r.nombre || '—',
                    ci: r.ci || '—',
                    curso: r.curso || '—',
                    gestion: r.gestion || 'Gestión 2025',
                    fecha: r.fecha || '—',
                    hora: r.hora || '—',
                    tutor: r.tutor || '',
                    tutorTel: r.tutorTel || '',
                    estado: r.estado || 'Pendiente',
                    obs: r.obs || '',
                    nivel: r.nivel || 'Secundaria',
                    revisadoPor: r.revisadoPor || '',
                    asignatura: r.asignatura || '',
                }));
            }
        }
    } catch (e) {
        console.info('ℹ️ Backend no disponible, usando inscripciones locales');
    }

    switchInscTab('resumen');
    renderInscTablaResumen();
    renderInscTabla('nuevas');
    renderInscHistorial();
    renderInscPendientes();
    animarInscCounters();
    setTimeout(animarInscDonut, 300);
    // Vincular con módulo Estudiantes
    setTimeout(renderEstudiantesVinculados, 100);
}

function animarInscCounters() {
    const vals = [
        { id: 'insc-stat-nuevas', val: DB_inscripciones.length },
        { id: 'insc-stat-pendientes', val: DB_inscripciones.filter(i => i.estado === 'Pendiente').length },
        { id: 'insc-stat-aprobadas', val: DB_inscripciones.filter(i => i.estado === 'Aprobada').length },
        { id: 'insc-stat-rechazadas', val: DB_inscripciones.filter(i => i.estado === 'Rechazada').length },
    ];
    vals.forEach(({ id, val }) => {
        const el = document.getElementById(id);
        if (el) animateCounter(el, val, 900);
    });
}

function animarInscDonut() {
    // Animación CSS: los segmentos tienen stroke-dashoffset inicial en 289
    // Se actualiza inline para animación suave
    const total = DB_inscripciones.length || 32;
    const aprobadas = DB_inscripciones.filter(i => i.estado === 'Aprobada').length;
    const pendientes = DB_inscripciones.filter(i => i.estado === 'Pendiente').length;
    const circ = 2 * Math.PI * 46; // ≈ 289

    const segA = document.querySelector('.seg-aprobadas');
    const segP = document.querySelector('.seg-pendientes');
    const segR = document.querySelector('.seg-rechazadas');
    if (!segA) return;

    const pctA = aprobadas / total;
    const pctP = pendientes / total;
    const arcA = circ * pctA;
    const arcP = circ * pctP;
    const arcR = circ * (1 - pctA - pctP);

    segA.setAttribute('stroke-dasharray', `${arcA.toFixed(1)} ${circ.toFixed(1)}`);
    segA.setAttribute('stroke-dashoffset', circ.toFixed(1));

    segP.setAttribute('stroke-dasharray', `${arcP.toFixed(1)} ${circ.toFixed(1)}`);
    segP.setAttribute('stroke-dashoffset', ((circ - arcA) + circ * 0).toFixed(1));

    if (segR) {
        segR.setAttribute('stroke-dasharray', `${arcR.toFixed(1)} ${circ.toFixed(1)}`);
        segR.setAttribute('stroke-dashoffset', ((circ - arcA - arcP)).toFixed(1));
    }

    // Actualizar texto central
    const textEl = document.querySelector('.insc-donut-chart text:last-child');
    if (textEl) textEl.textContent = total;
}

/* ── Tabs del módulo ── */
function switchInscTab(tab) {
    const tabs = ['resumen', 'nuevas', 'pendientes', 'historial', 'configuracion-insc'];
    tabs.forEach(t => {
        const btn = document.getElementById(`insc-tab-${t === 'configuracion-insc' ? 'configuracion' : t}`);
        const content = document.getElementById(`insc-content-${t}`);
        if (btn) btn.classList.toggle('active', t === tab);
        if (content) content.style.display = t === tab ? 'block' : 'none';
    });

    if (tab === 'nuevas') renderInscTabla('nuevas');
    if (tab === 'pendientes') renderInscPendientes();
    if (tab === 'historial') renderInscHistorial();
}

/* ── Badge de estado inscripción ── */
function inscBadge(estado) {
    const map = {
        'Pendiente': 'background:#3a2c1a;color:#f59e0b;border:1px solid rgba(245,158,11,0.3)',
        'Aprobada':  'background:#1a3a2a;color:#10b981;border:1px solid rgba(16,185,129,0.3)',
        'Rechazada': 'background:#3a1a1a;color:#ef4444;border:1px solid rgba(239,68,68,0.3)',
    };
    const s = map[estado] || 'background:#1e2d4a;color:#8ba3c7';
    return `<span style="${s};padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600">${estado}</span>`;
}

/* ── Avatar inicial ── */
function inscAvatar(nombre, color) {
    const initials = nombre.split(' ').slice(0, 2).map(w => w[0]).join('');
    return `<div style="width:32px;height:32px;border-radius:50%;background:${color};display:flex;align-items:center;justify-content:center;font-weight:700;font-size:12px;color:white;flex-shrink:0">${initials}</div>`;
}

const AVATAR_COLORS = ['#3b82f6','#10b981','#f59e0b','#ef4444','#8b5cf6','#ec4899','#06b6d4'];

/* ── Tabla resumen (5 recientes) ── */
function renderInscTablaResumen() {
    const tbody = document.getElementById('insc-tbody-recientes');
    if (!tbody) return;
    const recientes = [...DB_inscripciones].slice(0, 5);
    tbody.innerHTML = recientes.map((r, i) => `
        <tr>
            <td>
                <div style="display:flex;align-items:center;gap:10px">
                    ${inscAvatar(r.nombre, AVATAR_COLORS[i % AVATAR_COLORS.length])}
                    <div>
                        <div style="font-weight:600;font-size:13px;color:var(--text-primary)">${r.nombre}</div>
                        <div style="font-size:11px;color:var(--text-muted)">C.I: ${r.ci}</div>
                    </div>
                </div>
            </td>
            <td>
                <div style="font-size:13px;color:var(--text-primary)">${r.curso}</div>
                <div style="font-size:11px;color:var(--text-muted)">${r.gestion}</div>
            </td>
            <td>
                <div style="font-size:13px;color:var(--text-primary)">${r.fecha}</div>
                <div style="font-size:11px;color:var(--text-muted)">${r.hora}</div>
            </td>
            <td>${inscBadge(r.estado)}</td>
            <td>
                <div style="display:flex;gap:6px;align-items:center">
                    <button class="accion-icon-btn edit" title="Ver detalle" onclick="verInscripcion('${r.id}')"
                        style="background:rgba(59,130,246,0.1);color:#3b82f6;border:1px solid rgba(59,130,246,0.2)">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"/></svg>
                    </button>
                    <button class="accion-icon-btn" title="Más opciones" onclick="masOpcionesInsc('${r.id}', this)"
                        style="background:rgba(139,92,246,0.1);color:#8b5cf6;border:1px solid rgba(139,92,246,0.2)">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/></svg>
                    </button>
                </div>
            </td>
        </tr>
    `).join('');
}

/* ── Tabla completa (tab Nuevas) ── */
function renderInscTabla() {
    const tbody = document.getElementById('tbody-inscripciones');
    const infoEl = document.getElementById('info-inscripciones');
    if (!tbody) return;

    const q = (document.getElementById('searchInscNuevas')?.value || '').toLowerCase();
    const nivel = document.getElementById('filterInscNuevaNivel')?.value || '';

    const filtrados = DB_inscripciones.filter(r =>
        (!q || (r.nombre + r.ci + r.curso + r.tutor).toLowerCase().includes(q)) &&
        (!nivel || r.nivel === nivel)
    );

    if (!filtrados.length) {
        tbody.innerHTML = `<tr><td colspan="7" style="text-align:center;padding:40px;color:var(--text-muted)">No se encontraron inscripciones. <button class="card-link" onclick="abrirNuevaInscripcion()">+ Nueva inscripción</button></td></tr>`;
    } else {
        tbody.innerHTML = filtrados.map((r, i) => `
            <tr>
                <td>${i + 1}</td>
                <td>
                    <div class="mod-user-cell">
                        ${inscAvatar(r.nombre, AVATAR_COLORS[i % AVATAR_COLORS.length])}
                        <div>
                            <div style="font-weight:600;font-size:13px">${r.nombre}</div>
                            <div style="font-size:11px;color:var(--text-muted)">C.I: ${r.ci}</div>
                        </div>
                    </div>
                </td>
                <td><span class="tipo-badge" style="background:#1e2d4a;color:#a78bfa">${r.curso}</span></td>
                <td><div style="font-size:13px">${r.fecha}</div><div style="font-size:11px;color:var(--text-muted)">${r.hora}</div></td>
                <td>${r.tutor || '—'}</td>
                <td>${inscBadge(r.estado)}</td>
                <td>
                    <div class="accion-btns">
                        ${r.estado === 'Pendiente' ? `
                        <button class="accion-icon-btn edit" title="Aprobar" onclick="aprobarInsc('${r.id}')" style="background:rgba(16,185,129,0.1);color:#10b981;border:1px solid rgba(16,185,129,0.3)">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>
                        </button>
                        <button class="accion-icon-btn delete" title="Rechazar" onclick="rechazarInsc('${r.id}')">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/></svg>
                        </button>` : ''}
                        <button class="accion-icon-btn edit" title="Editar" onclick="editarInscripcion('${r.id}')">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/></svg>
                        </button>
                        <button class="accion-icon-btn delete" title="Eliminar" onclick="eliminarInsc('${r.id}')">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/></svg>
                        </button>
                    </div>
                </td>
            </tr>
        `).join('');
    }
    if (infoEl) infoEl.textContent = `${filtrados.length} de ${DB_inscripciones.length} registros`;
}

/* ── Tarjetas de pendientes ── */
function renderInscPendientes() {
    const container = document.getElementById('insc-pendientes-list');
    if (!container) return;
    const q = (document.getElementById('searchInscPendientes')?.value || '').toLowerCase();
    const pendientes = DB_inscripciones.filter(r =>
        r.estado === 'Pendiente' &&
        (!q || (r.nombre + r.ci + r.curso).toLowerCase().includes(q))
    );
    if (!pendientes.length) {
        container.innerHTML = `<div style="text-align:center;padding:60px 20px;color:var(--text-muted)">✅ No hay inscripciones pendientes de revisión.</div>`;
        return;
    }
    container.innerHTML = pendientes.map((r, i) => `
        <div class="insc-pending-card">
            <div class="insc-pending-card-left">
                ${inscAvatar(r.nombre, AVATAR_COLORS[i % AVATAR_COLORS.length])}
                <div>
                    <strong style="font-size:14px;color:var(--text-primary)">${r.nombre}</strong>
                    <div style="font-size:12px;color:var(--text-muted)">C.I: ${r.ci} · Tutor: ${r.tutor}</div>
                    <div style="font-size:12px;color:var(--text-muted)">${r.curso} — ${r.gestion}</div>
                    <div style="font-size:11px;color:var(--text-muted);margin-top:2px">📅 ${r.fecha} ${r.hora}</div>
                </div>
            </div>
            <div style="display:flex;gap:8px;flex-shrink:0">
                <button onclick="aprobarInsc('${r.id}')" style="background:linear-gradient(135deg,#10b981,#059669);color:white;border:none;padding:8px 18px;border-radius:10px;font-size:12px;font-weight:600;cursor:pointer">
                    ✓ Aprobar
                </button>
                <button onclick="rechazarInsc('${r.id}')" style="background:linear-gradient(135deg,#ef4444,#b91c1c);color:white;border:none;padding:8px 18px;border-radius:10px;font-size:12px;font-weight:600;cursor:pointer">
                    ✕ Rechazar
                </button>
                <button onclick="editarInscripcion('${r.id}')" style="background:rgba(139,92,246,0.15);color:#8b5cf6;border:1px solid rgba(139,92,246,0.3);padding:8px 14px;border-radius:10px;font-size:12px;font-weight:600;cursor:pointer">
                    Editar
                </button>
            </div>
        </div>
    `).join('');
}

/* ── Tabla historial ── */
function renderInscHistorial() {
    const tbody = document.getElementById('tbody-insc-historial');
    if (!tbody) return;
    const q = (document.getElementById('searchInscHistorial')?.value || '').toLowerCase();
    const est = document.getElementById('filterInscHistorialEstado')?.value || '';
    const filtrados = DB_inscripciones.filter(r =>
        (!q || (r.nombre + r.ci + r.curso).toLowerCase().includes(q)) &&
        (!est || r.estado === est)
    );
    if (!filtrados.length) {
        tbody.innerHTML = `<tr><td colspan="7" style="text-align:center;padding:40px;color:var(--text-muted)">Sin registros.</td></tr>`;
        return;
    }
    tbody.innerHTML = filtrados.map((r, i) => `
        <tr>
            <td>${i + 1}</td>
            <td><div class="mod-user-cell">${inscAvatar(r.nombre, AVATAR_COLORS[i % AVATAR_COLORS.length])}<span>${r.nombre}</span></div></td>
            <td>${r.curso}</td>
            <td>${r.fecha}</td>
            <td>${inscBadge(r.estado)}</td>
            <td><small style="color:var(--text-muted)">${r.revisadoPor || '—'}</small></td>
            <td>
                <div class="accion-btns">
                    <button class="accion-icon-btn edit" title="Editar" onclick="editarInscripcion('${r.id}')">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/></svg>
                    </button>
                    <button class="accion-icon-btn delete" title="Eliminar" onclick="eliminarInsc('${r.id}')">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/></svg>
                    </button>
                </div>
            </td>
        </tr>
    `).join('');
}

/* ── Aprobar / Rechazar ── */
async function aprobarInsc(id) {
    const r = DB_inscripciones.find(x => x.id == id);
    if (!r) return;
    r.estado = 'Aprobada';
    r.revisadoPor = 'Administrador';

    // ── Persistir aprobación en MongoDB ──────────────────────
    try {
        if (typeof r.id === 'string' && /^[a-f\d]{24}$/i.test(r.id)) {
            await fetch(`${API_BASE}/inscripciones/${r.id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ estado: 'Aprobada', revisadoPor: 'Administrador' })
            });
        }
    } catch(e) { console.warn('Backend no disponible al aprobar:', e.message); }

    // ── Vinculación: registrar automáticamente en módulo Estudiantes ──
    const yaExiste = DB.estudiantes.some(e => e.ci === r.ci);
    if (!yaExiste) {
        const nuevoId = Math.max(0, ...DB.estudiantes.map(e => typeof e.id === 'number' ? e.id : 0)) + 1;
        const cursoNorm = r.curso
            .replace('1° de Secundaria', '1.° Secundaria')
            .replace('2° de Secundaria', '2.° Secundaria')
            .replace('3° de Secundaria', '3.° Secundaria')
            .replace('4° de Secundaria', '4.° Secundaria')
            .replace('5° de Secundaria', '5.° Secundaria')
            .replace('6° de Secundaria', '6.° Secundaria')
            .replace('1° de Primaria', '1.° Secundaria')
            .replace(/de Primaria|de Secundaria/g, 'Secundaria');
        DB.estudiantes.unshift({
            id: nuevoId,
            nombre: r.nombre,
            ci: r.ci,
            semestre: cursoNorm || '1.° Secundaria',
            email: '',
            telefono: '',
            tutor: r.tutor || '',
            tutorTel: r.tutorTel || '',
            estado: 'Activo',
            direccion: '',
            nacimiento: '',
            obs: `Inscripción aprobada — ${r.gestion}`,
            _inscripcionId: r.id
        });
        // Actualizar contador del dashboard
        const elEst = document.getElementById('stat-estudiantes');
        if (elEst) elEst.textContent = DB.estudiantes.length;
        showToast(`✅ Inscripción aprobada · ${r.nombre} fue registrado en Módulo Estudiantes`);
    } else {
        showToast(`✅ Inscripción de ${r.nombre} aprobada`);
    }

    _refreshInscAll();
}

function rechazarInsc(id) {
    const r = DB_inscripciones.find(x => x.id == id);
    if (!r) return;
    r.estado = 'Rechazada';
    r.revisadoPor = 'Administrador';
    _refreshInscAll();
    showToast(`❌ Inscripción de ${r.nombre} rechazada`);
}

function eliminarInsc(id) {
    const r = DB_inscripciones.find(x => x.id == id);
    if (!r) return;
    if (!confirm(`¿Eliminar la inscripción de ${r.nombre}?`)) return;
    DB_inscripciones = DB_inscripciones.filter(x => x.id != id);
    _refreshInscAll();
    showToast('🗑️ Inscripción eliminada');
}

function verInscripcion(id) {
    const r = DB_inscripciones.find(x => x.id == id);
    if (!r) return;
    showToast(`📋 ${r.nombre} — ${r.curso} — Estado: ${r.estado}`);
}

function masOpcionesInsc(id, btn) {
    const r = DB_inscripciones.find(x => x.id == id);
    if (!r) return;
    if (r.estado === 'Pendiente') aprobarInsc(id);
    else showToast(`ℹ️ Inscripción: ${r.nombre} — ${r.estado}`);
}

function _refreshInscAll() {
    renderInscTablaResumen();
    renderInscTabla();
    renderInscPendientes();
    renderInscHistorial();
    animarInscCounters();
    animarInscDonut();
    renderEstudiantesVinculados();
}

/* ══════════════════════════════════════════════════
   VINCULACIÓN: Estudiantes matriculados en Inscripción
   Muestra los estudiantes de DB.estudiantes en el módulo
   de Inscripción para una vista integrada.
══════════════════════════════════════════════════ */
function renderEstudiantesVinculados() {
    const container = document.getElementById('insc-estudiantes-vinculados');
    if (!container) return;

    const estudiantes = DB.estudiantes;
    const total = estudiantes.length;
    const activos = estudiantes.filter(e => e.estado === 'Activo').length;

    // Mapear inscripciones aprobadas para cruzar datos
    const inscAprobadas = DB_inscripciones.filter(i => i.estado === 'Aprobada');
    const ciAprobados = new Set(inscAprobadas.map(i => i.ci));

    if (!total) {
        container.innerHTML = `<div style="text-align:center;padding:40px;color:var(--text-muted)">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="currentColor" style="opacity:0.3;margin-bottom:12px"><path d="M5 13.18v4L12 21l7-3.82v-4L12 17l-7-3.82zM12 3L1 9l11 6 11-6-11-6z"/></svg>
            <p>No hay estudiantes matriculados aún.</p>
            <button class="card-link" onclick="navigate('estudiantes', document.getElementById('nav-estudiantes'))">Ir al módulo Estudiantes</button>
        </div>`;
        return;
    }

    const COLORS = ['#3b82f6','#10b981','#f59e0b','#ef4444','#8b5cf6','#ec4899','#06b6d4'];
    const filas = estudiantes.slice(0, 8).map((e, i) => {
        const tieneInsc = ciAprobados.has(e.ci);
        const badgeVinculo = tieneInsc
            ? `<span style="background:rgba(16,185,129,0.15);color:#10b981;border:1px solid rgba(16,185,129,0.3);padding:2px 8px;border-radius:12px;font-size:10px;font-weight:600">✓ Via Inscripción</span>`
            : `<span style="background:rgba(59,130,246,0.12);color:#60a5fa;border:1px solid rgba(59,130,246,0.2);padding:2px 8px;border-radius:12px;font-size:10px;font-weight:600">Registro directo</span>`;
        const initials = e.nombre.split(' ').slice(0,2).map(w=>w[0]).join('');
        const avatar = `<div style="width:30px;height:30px;border-radius:50%;background:${COLORS[i%COLORS.length]};display:flex;align-items:center;justify-content:center;font-weight:700;font-size:11px;color:white;flex-shrink:0">${initials}</div>`;
        return `<tr>
            <td><div style="display:flex;align-items:center;gap:8px">${avatar}<div><div style="font-weight:600;font-size:12px;color:var(--text-primary)">${e.nombre}</div><div style="font-size:10px;color:var(--text-muted)">C.I: ${e.ci}</div></div></div></td>
            <td><span style="background:#1e2d4a;color:#a78bfa;padding:2px 8px;border-radius:10px;font-size:11px">${e.semestre}</span></td>
            <td>${e.tutor || '—'}</td>
            <td>${badgeVinculo}</td>
            <td>
                <button class="accion-icon-btn edit" title="Ver en módulo Estudiantes" onclick="irAEstudiante('${e.ci}')" style="background:rgba(59,130,246,0.1);color:#3b82f6;border:1px solid rgba(59,130,246,0.2)">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><path d="M19 19H5V5h7V3H5c-1.11 0-2 .9-2 2v14c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2v-7h-2v7zM14 3v2h3.59l-9.83 9.83 1.41 1.41L19 6.41V10h2V3h-7z"/></svg>
                </button>
            </td>
        </tr>`;
    }).join('');

    container.innerHTML = `
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px;flex-wrap:wrap;gap:8px">
            <div style="display:flex;align-items:center;gap:12px">
                <div style="display:flex;align-items:center;gap:6px">
                    <span style="background:rgba(16,185,129,0.15);color:#10b981;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600">${activos} activos</span>
                    <span style="background:rgba(59,130,246,0.15);color:#60a5fa;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600">${ciAprobados.size} via inscripción</span>
                </div>
            </div>
            <button onclick="navigate('estudiantes', document.getElementById('nav-estudiantes'))" style="background:linear-gradient(135deg,#3b82f6,#8b5cf6);color:white;border:none;padding:7px 16px;border-radius:10px;font-size:12px;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:6px">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M5 13.18v4L12 21l7-3.82v-4L12 17l-7-3.82zM12 3L1 9l11 6 11-6-11-6z"/></svg>
                Ver módulo Estudiantes
            </button>
        </div>
        <div style="overflow-x:auto">
            <table style="width:100%;border-collapse:collapse;font-size:12px">
                <thead><tr style="border-bottom:1px solid var(--border)">
                    <th style="padding:8px 10px;text-align:left;color:var(--text-muted);font-size:10px;font-weight:600;text-transform:uppercase">Estudiante</th>
                    <th style="padding:8px 10px;text-align:left;color:var(--text-muted);font-size:10px;font-weight:600;text-transform:uppercase">Curso</th>
                    <th style="padding:8px 10px;text-align:left;color:var(--text-muted);font-size:10px;font-weight:600;text-transform:uppercase">Tutor</th>
                    <th style="padding:8px 10px;text-align:left;color:var(--text-muted);font-size:10px;font-weight:600;text-transform:uppercase">Origen</th>
                    <th style="padding:8px 10px;text-align:left;color:var(--text-muted);font-size:10px;font-weight:600;text-transform:uppercase">Ir a</th>
                </tr></thead>
                <tbody id="insc-est-tbody">${filas}</tbody>
            </table>
        </div>
        ${total > 8 ? `<div style="text-align:center;padding:12px 0 0;border-top:1px solid var(--border);margin-top:10px">
            <button onclick="navigate('estudiantes', document.getElementById('nav-estudiantes'))" style="background:transparent;color:var(--text-muted);border:none;font-size:12px;cursor:pointer">Ver los ${total} estudiantes →</button>
        </div>` : ''}
    `;
}

/* ── Ir a módulo Estudiantes y resaltar CI ── */
function irAEstudiante(ci) {
    navigate('estudiantes', document.getElementById('nav-estudiantes'));
    // Filtrar por CI en el buscador
    setTimeout(() => {
        const inp = document.getElementById('searchEstudiante');
        if (inp) { inp.value = ci; renderTabla('estudiantes'); }
        showToast(`🔍 Buscando estudiante CI: ${ci} en Módulo Estudiantes`);
    }, 150);
}

/* ── Abrir modal nueva inscripción ── */
function abrirNuevaInscripcion() {
    inscEditandoId = null;
    document.querySelectorAll('#modal-inscripcion input, #modal-inscripcion select, #modal-inscripcion textarea').forEach(el => {
        if (el.tagName === 'SELECT') el.selectedIndex = 0;
        else el.value = '';
    });
    document.getElementById('modal-inscripcion-title').textContent = 'Nueva Inscripción';
    document.getElementById('insc-gestion').value = 'Gestión 2025';
    document.getElementById('modal-backdrop-inscripcion').classList.add('open');
    document.getElementById('modal-inscripcion').classList.add('open');
}

function editarInscripcion(id) {
    const r = DB_inscripciones.find(x => x.id == id);
    if (!r) return;
    inscEditandoId = id;
    document.getElementById('modal-inscripcion-title').textContent = 'Editar Inscripción';
    document.getElementById('insc-nombre').value = r.nombre;
    document.getElementById('insc-ci').value = r.ci;
    document.getElementById('insc-curso').value = r.curso;
    document.getElementById('insc-gestion').value = r.gestion;
    document.getElementById('insc-tutor').value = r.tutor;
    document.getElementById('insc-tutor-tel').value = r.tutorTel || '';
    document.getElementById('insc-asignatura').value = r.asignatura || '';
    document.getElementById('insc-estado').value = r.estado;
    document.getElementById('insc-obs').value = r.obs || '';
    document.getElementById('modal-backdrop-inscripcion').classList.add('open');
    document.getElementById('modal-inscripcion').classList.add('open');
}

/* ── Guardar inscripción ── */
async function guardarInscripcion() {
    const nombre = document.getElementById('insc-nombre')?.value.trim();
    const ci = document.getElementById('insc-ci')?.value.trim();
    const curso = document.getElementById('insc-curso')?.value.trim();
    const tutor = document.getElementById('insc-tutor')?.value.trim();
    const asignatura = document.getElementById('insc-asignatura')?.value.trim();

    if (!nombre || !ci || !curso || !tutor) {
        showToast('⚠️ Completa los campos obligatorios (*)'); return;
    }

    const nivel = curso.includes('Secundaria') ? 'Secundaria' : 'Otros';

    const ahora = new Date();
    const fecha = ahora.toLocaleDateString('es-ES', { day: '2-digit', month: 'short', year: 'numeric' });
    const hora = ahora.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });

    const payload = {
        nombre, ci, curso, nivel, asignatura,
        gestion: document.getElementById('insc-gestion')?.value.trim() || 'Gestión 2025',
        tutor,
        tutorTel: document.getElementById('insc-tutor-tel')?.value.trim() || '',
        estado: inscEditandoId
            ? (document.getElementById('insc-estado')?.value || 'Pendiente')
            : 'Pendiente',
        obs: document.getElementById('insc-obs')?.value.trim() || '',
        fecha, hora,
    };

    // ── Persistir en MongoDB ──────────────────────────────────
    let mongoId = null;
    try {
        if (inscEditandoId && typeof inscEditandoId === 'string' && /^[a-f\d]{24}$/i.test(inscEditandoId)) {
            // Editar en MongoDB
            const res = await fetch(`${API_BASE}/inscripciones/${inscEditandoId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            const result = await res.json();
            if (res.ok) {
                mongoId = inscEditandoId;
                showToast('✏️ Inscripción actualizada en MongoDB');
            } else {
                showToast(`⚠️ ${result.error || 'Error al actualizar'}`);
            }
        } else {
            // Crear en MongoDB
            const res = await fetch(`${API_BASE}/inscripciones`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            const result = await res.json();
            if (res.ok) {
                mongoId = result._id;
                showToast('✅ Inscripción guardada en MongoDB');
            } else {
                showToast(`⚠️ ${result.error || 'Error al guardar'}`);
            }
        }
    } catch (e) {
        console.warn('Backend no disponible, guardando solo en local:', e.message);
    }

    // ── Actualizar DB local ───────────────────────────────────
    if (inscEditandoId) {
        const idx = DB_inscripciones.findIndex(x => x.id == inscEditandoId);
        if (idx !== -1) {
            DB_inscripciones[idx] = { ...DB_inscripciones[idx], ...payload };
        }
        if (!mongoId) showToast('✏️ Inscripción actualizada localmente');
    } else {
        const nuevoId = mongoId || (Math.max(0, ...DB_inscripciones.map(x => x.id)) + 1);
        DB_inscripciones.unshift({ id: nuevoId, revisadoPor: '', ...payload });
        if (!mongoId) showToast('✅ Inscripción creada localmente');
    }

    closeModal('inscripcion');
    inscEditandoId = null;
    _refreshInscAll();
}

/* ══════════════════════════════════════════════════
   AUTOCOMPLETE — Buscador de Estudiantes en Inscripción
   Muestra estudiantes de DB.estudiantes al escribir en
   el campo "Nombre del Estudiante" y auto-rellena datos.
══════════════════════════════════════════════════ */

const AC_COLORS = [
    'linear-gradient(135deg,#3b82f6,#1d4ed8)',
    'linear-gradient(135deg,#10b981,#059669)',
    'linear-gradient(135deg,#f59e0b,#d97706)',
    'linear-gradient(135deg,#8b5cf6,#6d28d9)',
    'linear-gradient(135deg,#ec4899,#be185d)',
    'linear-gradient(135deg,#06b6d4,#0e7490)',
    'linear-gradient(135deg,#ef4444,#b91c1c)',
];

// Bandera para evitar que el onblur cierre la lista antes de procesar el click
let _acPreventBlur = false;

function filtrarEstudiantesAutoComplete(query) {
    const list = document.getElementById('insc-autocomplete-list');
    if (!list) return;

    const q = (query || '').trim().toLowerCase();
    const todos = DB.estudiantes || [];

    // Filtrar por nombre o CI
    const filtrados = q.length === 0
        ? todos.slice(0, 8)                                    // sin query → mostrar primeros 8
        : todos.filter(e =>
            e.nombre.toLowerCase().includes(q) ||
            String(e.ci || '').toLowerCase().includes(q)
          ).slice(0, 10);

    if (filtrados.length === 0) {
        list.innerHTML = `<div class="insc-ac-empty">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" style="opacity:.3;margin-bottom:4px"><path d="M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"/></svg>
            <p>No se encontraron estudiantes${q ? ` para "<strong>${q}</strong>"` : ''}</p>
            <small style="color:#4d6a8f">Regístralos primero en el módulo Estudiantes</small>
        </div>`;
        list.classList.add('open');
        return;
    }

    list.innerHTML = filtrados.map((e, i) => {
        const initials = e.nombre.split(' ').slice(0, 2).map(w => w[0] || '').join('').toUpperCase();
        const bg = AC_COLORS[i % AC_COLORS.length];
        const curso = e.semestre || '—';
        const ci = e.ci || '—';

        // Resaltar coincidencia
        const resaltarNombre = q
            ? e.nombre.replace(new RegExp(`(${q.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')})`, 'gi'),
                '<mark style="background:rgba(59,130,246,0.25);color:#93c5fd;border-radius:2px;padding:0 1px">$1</mark>')
            : e.nombre;

        // Usar data-attr en lugar de onmousedown inline para mayor confiabilidad
        return `<div class="insc-ac-item" data-est-id="${e.id || i}"
            onmousedown="_acPreventBlur=true;seleccionarEstudianteAC(this.dataset.estId)">
            <div class="insc-ac-avatar" style="background:${bg}">${initials}</div>
            <div class="insc-ac-info">
                <div class="insc-ac-nombre">${resaltarNombre}</div>
                <div class="insc-ac-meta">C.I: ${ci}${e.tutor ? ' · Tutor: ' + e.tutor : ''}</div>
            </div>
            <span class="insc-ac-badge">${curso}</span>
        </div>`;
    }).join('');

    list.classList.add('open');
}

function seleccionarEstudianteAC(idEstudiante) {
    _acPreventBlur = false;
    // Buscar el estudiante en DB por id (string o número)
    const est = DB.estudiantes.find(e => String(e.id) === String(idEstudiante))
             || DB.estudiantes[Number(idEstudiante)];
    if (!est) {
        console.warn('No se encontró estudiante con id:', idEstudiante);
        return;
    }

    // Rellenar campos del modal
    const setVal = (id, val) => {
        const el = document.getElementById(id);
        if (el) el.value = val ?? '';
    };

    setVal('insc-nombre',    est.nombre);
    setVal('insc-ci',        est.ci || '');
    setVal('insc-tutor',     est.tutor || '');
    setVal('insc-tutor-tel', est.tutorTel || '');

    // Intentar seleccionar el curso en el <select>
    const cursoSelect = document.getElementById('insc-curso');
    if (cursoSelect && est.semestre) {
        // Mapear formato del DB a las opciones del select
        const mapeo = {
            '1.° Secundaria': '1° de Secundaria',
            '2.° Secundaria': '2° de Secundaria',
            '3.° Secundaria': '3° de Secundaria',
            '4.° Secundaria': '4° de Secundaria',
            '5.° Secundaria': '5° de Secundaria',
            '6.° Secundaria': '6° de Secundaria',
        };
        const cursoMapeado = mapeo[est.semestre] || est.semestre;
        let found = false;
        // Intentar coincidencia exacta primero
        for (let opt of cursoSelect.options) {
            if (opt.value === cursoMapeado || opt.text === cursoMapeado) {
                cursoSelect.value = opt.value;
                found = true;
                break;
            }
        }
        // Si no coincide exactamente, buscar por inclusión parcial
        if (!found) {
            const semestreLC = (est.semestre || '').toLowerCase();
            for (let opt of cursoSelect.options) {
                if (opt.text.toLowerCase().includes(semestreLC.replace('°', '').trim()) ||
                    semestreLC.includes(opt.text.toLowerCase().replace('de ', '').trim())) {
                    cursoSelect.value = opt.value;
                    break;
                }
            }
        }
    }

    // Cerrar dropdown
    cerrarAutoComplete();

    // Efecto visual: resaltar el campo nombre + otros campos rellenados
    const camposRellenados = ['insc-nombre', 'insc-ci', 'insc-tutor', 'insc-tutor-tel'];
    camposRellenados.forEach(id => {
        const el = document.getElementById(id);
        if (el && el.value) {
            el.style.borderColor = '#10b981';
            el.style.boxShadow = '0 0 0 2px rgba(16,185,129,0.18)';
            setTimeout(() => {
                el.style.borderColor = '';
                el.style.boxShadow = '';
            }, 2200);
        }
    });

    showToast(`✅ Estudiante seleccionado: ${est.nombre}`);
}

function cerrarAutoComplete() {
    if (_acPreventBlur) return; // No cerrar si estamos procesando un click
    const list = document.getElementById('insc-autocomplete-list');
    if (list) list.classList.remove('open');
}

// Al abrir modal: limpiar autocomplete y resetear campos
const _origAbrirNuevaInscripcion = abrirNuevaInscripcion;
abrirNuevaInscripcion = function() {
    _origAbrirNuevaInscripcion();
    _acPreventBlur = false;
    cerrarAutoComplete();
    // Asegurar que el CI vuelva a ser vacío
    const ci = document.getElementById('insc-ci');
    if (ci) ci.value = '';
};
