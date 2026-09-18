package com.example.notificaciondocente

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import com.example.notificaciondocente.theme.NotificacionDocenteTheme

class MainActivity : ComponentActivity() {

    // Launcher para solicitar permiso de notificaciones (Android 13+)
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            // Permiso concedido: mostrar notificación inmediatamente al inicio
            NotificacionReceiver.mostrarNotificacionCalificaciones(this)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Verificar y solicitar permiso de notificaciones en Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            when {
                ContextCompat.checkSelfPermission(
                    this, Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED -> {
                    // Ya tiene permiso: mostrar notificación
                    NotificacionReceiver.mostrarNotificacionCalificaciones(this)
                }
                else -> {
                    // Solicitar permiso
                    requestPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                }
            }
        } else {
            // Android < 13: no requiere permiso explícito, mostrar notificación
            NotificacionReceiver.mostrarNotificacionCalificaciones(this)
        }

        enableEdgeToEdge()
        setContent {
            NotificacionDocenteTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MainNavigation()
                }
            }
        }
    }
}
