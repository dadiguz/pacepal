# PacePal

Aplicacion iOS gamificada que convierte el habito de correr en una aventura con mascotas virtuales. Completa el reto de 66 dias para formar tu habito de running.

## Concepto

Tu mascota virtual gana energia cuando corres y la pierde con el tiempo si dejas de hacerlo. Mantener viva y feliz a tu mascota es tu motivacion diaria para salir a correr.

## Caracteristicas

- **Mascotas procedurales** - 20 tipos de animales con pixel art 24x24, cada mascota es unica gracias a su ADN generativo (~40 parametros)
- **Sistema de energia** - 1 km = 10% de energia. Decae en 7 dias (casual) o 36 horas (pro)
- **Reto de 66 dias** - 23 logros desbloqueables con poses y fondos unicos
- **Widget** - Pequeno y mediano para ver tu mascota y stats desde el home screen
- **Notificaciones** - Alertas cuando la energia de tu mascota baja, con sprite adjunto
- **Historial** - Grid de 66 dias con estadisticas de rachas y kilometros
- **Sonido 8-bit** - Efectos y musica retro

## Tech Stack

| Framework | Uso |
|-----------|-----|
| SwiftUI | UI completa (iOS 17+) |
| SwiftData | Persistencia de personajes |
| HealthKit | Lectura de carreras |
| WidgetKit | Widgets de home screen |
| StoreKit 2 | Suscripcion premium |
| UserNotifications | Alertas de energia |
| AVFoundation | Sonido y musica |

Sin dependencias externas. 100% frameworks de Apple.

## Estructura del Proyecto

```
PacePal/
├── PacePalApp.swift            # Entry point
├── AppState.swift              # Estado central (energia, reto, UI)
├── PurchaseManager.swift       # StoreKit 2
├── NotificationManager.swift   # Notificaciones con sprite
├── SoundManager.swift          # Audio 8-bit
├── RunningPhrases.swift        # 80+ frases motivacionales
├── Engine/
│   ├── PetDNA.swift            # Genetica procedural + presets
│   ├── PetTypes.swift          # Enums (animales, poses, cuerpos)
│   ├── PetPalette.swift        # 18 paletas de colores
│   └── PetGridBuilder.swift    # Renderizado pixel art 24x24
├── Health/
│   └── HealthManager.swift     # Queries a HealthKit
├── Persistence/
│   └── SavedCharacter.swift    # Modelo SwiftData
├── Views/
│   ├── HomeView.swift          # Pantalla principal
│   ├── CharacterSelectView.swift
│   ├── OnboardingView.swift
│   ├── HealthPermissionView.swift
│   ├── PaywallView.swift
│   ├── HistoryView.swift       # Grid de 66 dias
│   ├── SettingsView.swift
│   ├── PetCanvasView.swift     # Renderizado del sprite
│   ├── TutorialOverlayView.swift
│   └── SplashView.swift
└── PacePalWidget/              # Extension de widget
```

## Sistema de Energia

| Energia | Estado | Pose |
|---------|--------|------|
| 0% | Muerto | `.dead` |
| 1-14% | Mareado | `.dizzy` |
| 15-25% | Triste | `.sad` |
| 26-50% | Enojado | `.angry` |
| 51-90% | Normal | `.idle` |
| 91-95% | Feliz | `.happy` |
| 96-98% | Saltando | `.jump` |
| 99-100% | Euforia | `.hype` |

## Reto de 66 Dias

23 logros repartidos a lo largo de 66 dias (cada 3-4 dias). Cada logro desbloquea un fondo unico y una pose celebratoria. El dia 66 es la culminacion del reto.

## Requisitos

- iOS 17.0+
- Xcode 15+

## App Group

`group.io.dallio.PacePal` - Compartido entre app principal y widget.
