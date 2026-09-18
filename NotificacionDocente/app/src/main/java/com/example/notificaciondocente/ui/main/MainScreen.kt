package com.example.notificaciondocente.ui.main

import android.content.Context
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.notificaciondocente.NotificacionReceiver
import com.example.notificaciondocente.theme.NotificacionDocenteTheme

// ─── Paleta de colores ───────────────────────────────────────────────────────
private val AzulOscuro   = Color(0xFF0D1B2A)
private val AzulMedio    = Color(0xFF1B2F4E)
private val AzulAccento  = Color(0xFF2979FF)
private val DoradoAccento = Color(0xFFFFB300)
private val BlancoPuro   = Color(0xFFFFFFFF)
private val GrisClaro    = Color(0xFFB0BEC5)

// ─── Pantalla principal ──────────────────────────────────────────────────────
@Composable
fun MainScreen(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    var notificacionEnviada by remember { mutableStateOf(false) }
    var scale by remember { mutableStateOf(1f) }
    val animatedScale by animateFloatAsState(
        targetValue = scale,
        animationSpec = tween(150),
        label = "btn_scale",
        finishedListener = { scale = 1f }
    )

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(AzulOscuro, AzulMedio)
                )
            )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {

            // ── Cabecera ──────────────────────────────────────────────────
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(top = 32.dp)
            ) {
                // Ícono de docente
                Box(
                    modifier = Modifier
                        .size(100.dp)
                        .clip(CircleShape)
                        .background(AzulAccento.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = "🎓", fontSize = 52.sp)
                }

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = "Portal Docente",
                    color = BlancoPuro,
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Sistema de Notificaciones",
                    color = GrisClaro,
                    fontSize = 14.sp,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }

            // ── Tarjeta de alerta de calificaciones ───────────────────────
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(
                    containerColor = AzulMedio
                ),
                elevation = CardDefaults.cardElevation(8.dp)
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Encabezado de la tarjeta
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .clip(CircleShape)
                                .background(DoradoAccento.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(text = "⚠️", fontSize = 22.sp)
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = "Fecha Límite",
                            color = DoradoAccento,
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    Divider(
                        modifier = Modifier.padding(vertical = 16.dp),
                        color = Color.White.copy(alpha = 0.1f)
                    )

                    // Mensaje principal
                    Text(
                        text = "📢 Señor docente,",
                        color = BlancoPuro,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold,
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        text = "la entrega de calificaciones es una fecha límite para subir.",
                        color = GrisClaro,
                        fontSize = 15.sp,
                        textAlign = TextAlign.Center,
                        lineHeight = 22.sp
                    )
                    Spacer(modifier = Modifier.height(16.dp))

                    // Chip de estado
                    Surface(
                        shape = RoundedCornerShape(50.dp),
                        color = DoradoAccento.copy(alpha = 0.15f),
                        modifier = Modifier.wrapContentSize()
                    ) {
                        Text(
                            text = "📅  Período de calificaciones activo",
                            color = DoradoAccento,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                        )
                    }
                }
            }

            // ── Botón de notificación ─────────────────────────────────────
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(bottom = 32.dp)
            ) {
                if (notificacionEnviada) {
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = Color(0xFF1B5E20).copy(alpha = 0.8f),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 16.dp)
                    ) {
                        Text(
                            text = "✅ ¡Notificación enviada con éxito!",
                            color = Color(0xFFA5D6A7),
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(12.dp),
                            fontWeight = FontWeight.Medium
                        )
                    }
                }

                Button(
                    onClick = {
                        scale = 0.92f
                        enviarNotificacion(context)
                        notificacionEnviada = true
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp)
                        .scale(animatedScale),
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = AzulAccento
                    ),
                    elevation = ButtonDefaults.buttonElevation(8.dp)
                ) {
                    Text(
                        text = "🔔  Enviar Notificación Ahora",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = BlancoPuro
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                Text(
                    text = "La notificación aparecerá en la barra de estado",
                    color = GrisClaro,
                    fontSize = 12.sp,
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

private fun enviarNotificacion(context: Context) {
    NotificacionReceiver.mostrarNotificacionCalificaciones(context)
}

@Preview(showBackground = true, widthDp = 393, heightDp = 851, name = "Pixel 7")
@Composable
fun MainScreenPreview() {
    NotificacionDocenteTheme { MainScreen() }
}
