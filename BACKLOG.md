# Backlog - Sesion 2026-04-07

## Orden de ejecucion

| # | Tarea | Prioridad | Estado |
|---|-------|-----------|--------|
| 1 | Fix boton HealthKit (5a) | Critica | ✅ Completado |
| 2 | Revisar logica 66 dias (4) | Alta | ✅ Completado |
| 3 | Tracker de carrera in-app (5b) | Critica | ✅ Completado |
| 4 | Cuestionario inicial pre-compra (6) | Alta | ✅ Completado |
| 17 | Mapa de progreso 66 dias (sustituye heatmap) | Media | Movido a P2 |
| 16 | Apple Watch app (energia, monito, tracking) | Alta | Pendiente |
| 18 | Bug: contador 00/66 tras correr + no dispara logro/animacion | Critica | ✅ Completado |
| 19 | Prueba visual: ojos tipo Pokemon en el monito | Baja | Pendiente |
| 5 | Internacionalizacion ingles (1) | Alta | ✅ Completado |
| 6 | Estado Sleep del monito (3) | Media | Movido a P2 |
| 7 | Medalla 66 dias (2) | Media | ✅ Done |
| 8 | Soporte millas (km/mi) | Media | Movido a P2 |
| 9 | Fondo negro seleccionable | Baja | ✅ Completado |
| 10 | Paletas de color custom para monitos | Baja | ✅ Completado |
| 11 | Cambio de idioma en Settings | Media | ✅ Completado |
| 12 | Compartir logro (share) | Media | ✅ Completado |
| 13 | Tips diarios de correr (12) | Media | ✅ Completado |
| 14 | Parpadeo rojo al colapsar (13) | Baja | ✅ Completado |
| 15 | Editor foto + stickers para compartir (14) | Baja | Movido a P2 |

---

## 1. Internacionalizacion (i18n) - Idioma Ingles ✅
**Prioridad:** Alta | **Complejidad:** Media-Alta | **Estado:** Completado

- [x] Sistema de localizacion con diccionario Swift inline (`Localized.swift`) — `L()` para app, `WL()` para widget
- [x] `AppLang` enum extensible a futuros idiomas (solo agregar case + traducciones)
- [x] Extraidos todos los textos de: Views, AppState, RunningPhrases, NotificationManager, Widget, PetTypes
- [x] Traducido al ingles: UI completa, 300 frases motivacionales, 23 logros, tutorial, widget, archetypes
- [x] Idioma se selecciona automaticamente segun el dispositivo
- [ ] Pendiente: Localizar `Info.plist` (NSHealthShareUsageDescription, NSHealthUpdateUsageDescription)

> **NOTA PARA AGENTS:** Cualquier texto nuevo que se agregue al proyecto debe incluirse en **todos los idiomas disponibles** (es/en) en `Localized.swift` usando `L()`. Nunca hardcodear strings en español o inglés directamente en las vistas.

---

## 2. Medalla 66 Dias (Asset + Logica) ✅
**Prioridad:** Media | **Complejidad:** Media | **Estado:** Done

- [x] Medalla pixel-art (liston azul cobalto #1B50E5 + circulo dorado) como accesorio sobre el mono
- [x] Sistema de accesorios extensible (`PetAccessory` enum) en PetCanvasView
- [x] Se otorga al cerrar modal del dia 66 → `grantMedal()`
- [x] Energia permanente (decay = 0): `energy(at:)` retorna 1.0, widget tambien
- [x] Tutorial post-logro: `MedalTutorialOverlay` con icono, titulo y explicacion
- [x] Badge dorado `medal.fill` junto al contador de dias en HomeView
- [x] energyTimeLabel muestra "Energia permanente" en vez del countdown
- [x] Mono en pose `.idle` con parpadeo, sin brillos dorados, medalla con sparkle blanco animado
- [x] Botones debug: dar/quitar medalla en SettingsView
- [x] Se resetea al cambiar personaje
- [x] Strings en es/en

---

## 3. Estado "Sleep" del Monito
**Prioridad:** Media | **Complejidad:** Media

- [ ] Agregar pose `.sleep` al sistema de poses
- [ ] Si la app no se ha abierto en 1+ hora, el monito aparece dormido al abrir
- [ ] Se despierta si: el usuario lo toca, pasan ~10 segundos, o se inicia una carrera
- [ ] Condicion: solo entra en sleep si energia > 50%
- [ ] Agregar boton debug (`#if DEBUG`) para forzar estado sleep
- [ ] Animacion de transicion sleep -> idle (despertar)

---

## 4. Revision Logica de 66 Dias + Skip Days ✅
**Prioridad:** Alta | **Complejidad:** Media | **Estado:** Completado

### Resultado de la auditoria

Se encontraron 6 problemas. Todo el sistema cuenta dias **calendario** desde `challengeStartDate`, no dias completados con carrera:

| # | Problema | Archivo | Linea |
|---|----------|---------|-------|
| 1 | dayNum, achievements, grid: todo cuenta desde challengeStartDate sin importar si corriste | AppState:330, HomeView:442, HistoryView:31 | |
| 2 | Grid fijo en 66 cuadros — si hay skips deberia mostrar mas (66 completos + N skips) | HistoryView:178 `0..<totalDays` | |
| 3 | Achievements se disparan por dia calendario — Dia 7 se desbloquea a los 7 dias aunque no hayas corrido | AppState:330-331 | |
| 4 | Threshold inconsistente — HistoryView usa 0.5 km, HealthManager usa 0.05 km | HistoryView:4 vs HealthManager:98 | |
| 5 | Fecha estimada no considera skips — asume 1 completado por dia calendario futuro | HistoryView:45-56 | |
| 6 | Widget muestra dia calendario en vez de dias completados | AppState:440 | |

### Fixes necesarios

- [ ] **Unificar threshold** a 0.5 km en `HealthManager.fetchRunStats` (linea 98: cambiar `> 0.05` a `>= 0.5`)
- [ ] **Achievements por dias completados** — `pendingAchievement` en AppState debe contar dias con >= 0.5 km, no dias calendario. Requiere que AppState tenga acceso al conteo de dias completados (inyectar desde HealthManager o calcular)
- [ ] **Grid dinamico** — HistoryView debe mostrar `max(66, diasCalendarioTranscurridos)` cuadros. Los dias completados llevan check, los skips llevan X, los futuros quedan grises. El progreso (barra, contador) se basa en completados/66
- [ ] **HomeView dayNum** — cambiar `DIA: XX/66` para que muestre dias completados, no calendario
- [ ] **Projected finish** — calcular basado en tasa real de completados: `remaining / (completedCount / diasTranscurridos)`
- [ ] **Widget sync** — `syncToWidget` debe enviar dias completados en vez de dia calendario
- [ ] **Medalla y skips** — cuando el usuario tiene la medalla (66 dias completados), los dias sin carrera no deben mostrarse como taches/missed en el historico
- [ ] **Extraer valores hardcoded a configuracion** — los valores como km-por-% de energia, threshold minimo de km, dias del challenge (66), decay rate, etc. deben vivir en un struct de configuracion centralizado (ej. `ChallengeConfig`), no hardcoded en el codigo. Esto permite que el cuestionario inicial los ajuste segun las respuestas del usuario

---

## 6. Cuestionario Inicial Pre-Compra ✅
**Prioridad:** Alta | **Complejidad:** Media | **Estado:** Completado

Cuestionario corto que se muestra antes de la compra para personalizar las reglas del challenge segun el nivel del usuario.

- [ ] Pantalla de cuestionario con pocas preguntas (3-5 max), por ejemplo:
  - Que tan seguido corres actualmente? (Nunca / 1-2 veces/semana / 3+ veces/semana)
  - Cual es tu distancia tipica? (< 2 km / 2-5 km / 5+ km)
  - Que tan exigente quieres el reto? (Relajado / Normal / Intenso)
- [ ] Las respuestas ajustan los valores en `ChallengeConfig`: km-por-% de energia, decay rate, threshold minimo, etc.
- [ ] Guardar configuracion resultante en UserDefaults/AppState
- [ ] Se muestra una sola vez (antes de iniciar el challenge)
- [ ] Opcion en Settings para repetir el cuestionario (resetea config)
- [ ] Strings en es/en

> **Depende de:** Tarea 4 (extraer valores hardcoded a `ChallengeConfig`)

---

## 5. Fix App Store Rejection + Tracking de Carrera In-App ✅

### 5a. Fix Guideline 5.1.1(iv)
**Prioridad:** Critica | **Complejidad:** Baja | **Estado:** Completado

- [x] Cambiar boton "Activar Apple Health" por "Continuar" o "Siguiente"
- [x] Hacer que HealthKit sea opcional (skip permitido)

### 5b. Tracker de carrera in-app
**Prioridad:** Critica | **Complejidad:** Alta | **Estado:** Completado

- [x] Agregar boton "Track Run" en HomeView
- [x] Pantalla fullscreen al presionar con:
  - [x] KM corridos en grande (tipografia bold, centrado)
  - [x] Monito corriendo animado si se registran KM
  - [x] Monito cansado/sudando si se detiene
  - [x] Boton para finalizar carrera
- [x] Usar CoreLocation para tracking de distancia (no depende de HealthKit)
- [x] Los KM trackeados se suman a la energia igual que los de HealthKit
- [x] Permite que la app funcione sin permisos de HealthKit

---

## 7. Soporte Millas (km/mi)
**Prioridad:** Media | **Complejidad:** Baja-Media

- [ ] Agregar opcion en Settings para elegir unidad de distancia (km o millas)
- [ ] Persistir preferencia en UserDefaults
- [ ] Convertir todas las visualizaciones de distancia (HomeView, HistoryView, Widget, Tracker)
- [ ] Mantener almacenamiento interno siempre en km, solo convertir al mostrar

---

## 8. Fondo Negro Seleccionable ✅
**Prioridad:** Baja | **Complejidad:** Baja | **Estado:** Completado

- [x] Tile "Negro" en BackgroundPickerSheet (index 1, siempre desbloqueado, junto al Original)
- [x] `AppBackground` maneja `"solid_black"` como fondo negro puro
- [x] Textos/iconos usan estilos claros (misma logica que photo backgrounds via `hasPhotoBackground`)
- [x] Strings en es/en (`settings.black`)

---

## 9. Paletas de Color Custom para Monitos
**Prioridad:** Baja | **Complejidad:** Por definir

- [ ] Agregar paletas de color especificas (por definir cuales)
- [ ] Integrar en CharacterSelectView o Settings como opcion de personalizacion

---

## 10. Cambio de Idioma en Settings ✅
**Prioridad:** Media | **Complejidad:** Baja | **Estado:** Completado

- [x] Selector de idioma en SettingsView (Automático / Español / English)
- [x] Persistido en UserDefaults (`appLanguageOverride`), `AppLang.current` respeta override sobre dispositivo
- [x] UI se refresca al cerrar el picker (via `.id(langRefresh)` en HomeView y SettingsView)
- [x] Strings en es/en (`settings.language_title`, `settings.language_subtitle`, `settings.language_auto`)

---

## 11. Compartir (Share) ✅
**Prioridad:** Media | **Complejidad:** Media | **Estado:** Completado

- [x] Boton "Compartir" en el modal de logros (solo primera vez, no en replay)
- [x] Genera imagen 1080x1920 con: fondo del logro, badge del dia, frase, monito animado, branding PacePal
- [x] Share sheet nativo via `UIActivityViewController`
- [x] Strings en es/en (`share.button`)

---

## 12. Tips Diarios de Correr ✅
**Prioridad:** Media | **Complejidad:** Alta | **Estado:** Completado

- [x] 66 tips de running en es/en (tecnica, hidratacion, calentamiento, descanso, motivacion, etc.)
- [x] Modal tipo logro con fondo oscuro (#2B2420) que aparece una vez al dia al abrir la app
- [x] Tip se muestra despues de achievements (si hay achievement pendiente, aparece primero)
- [x] Nueva pose `.teaching` — monito con lentes (marcos gray alrededor de ojos + puente) y escribiendo
- [x] `seenTips: Set<Int>` en AppState, persistido en UserDefaults
- [x] Seccion "Tips" en SettingsView con lista scrolleable (desbloqueados vs locked)
- [x] Boton debug para resetear tips
- [x] Strings en es/en (`tip.badge`, `tip.dismiss`, `tip.section_title`, `tip.locked`)

---

## 13. Parpadeo Rojo al Colapsar
**Prioridad:** Baja | **Complejidad:** Baja

Cuando el monito esta colapsando (energia = 0 / pose `.dead`), el fondo parpadea rojo como alerta visual.

- [ ] Detectar estado de colapso (energy <= 0)
- [ ] Overlay rojo semi-transparente con animacion de pulso/parpadeo sobre el fondo actual
- [ ] Sutil (no agresivo) — opacidad baja con easing suave
- [ ] Se detiene cuando la energia sube de 0

---

## 17. Mapa de Progreso 66 Días (sustituye heatmap)
**Prioridad:** Media | **Complejidad:** Media | **Estado:** Movido a P2

> Ver BACKLOG_P2.md

---

## 16. Apple Watch App
**Prioridad:** Alta | **Complejidad:** Alta | **Estado:** Pendiente

App companion para Apple Watch que replica funcionalidad clave del iPhone.

- [ ] Target watchOS en el proyecto (WatchKit App + Extension)
- [ ] Mostrar energia actual del monito
- [ ] Monito pixel art animado (pose segun energia)
- [ ] Boton para iniciar/detener tracking de carrera
- [ ] Tracking de distancia via CoreLocation en watch
- [ ] Sincronizar datos de carrera con la app de iPhone (WatchConnectivity)
- [ ] Complicaciones: energia del monito, km del dia
- [ ] Strings en es/en

> **Depende de:** Tracker de carrera in-app (5b) ✅

---

## 14. Editor Foto + Stickers para Compartir
**Prioridad:** Baja | **Complejidad:** Alta

Segunda opcion de compartir: tomar una foto y agregar stickers del monito y stats.

- [ ] Opcion "Tomar foto" en el modal de compartir logro (junto a "Compartir asi")
- [ ] Abrir camara o photo picker
- [ ] Canvas de edicion con la foto de fondo
- [ ] Stickers arrastrables: monito (pose actual), badge de km corridos, badge del dia
- [ ] Render del composite a imagen final
- [ ] Compartir via share sheet

---

## 18. Bug: Contador 00/66 Tras Correr + No Dispara Logro ni Animacion
**Prioridad:** Critica | **Complejidad:** Media

### Descripcion del bug
El usuario inicio el reto en domingo sin correr. El lunes (dia 1 calendario) corrio.
- La barra de energia se marco correctamente como completada
- El historico mostro el dia 1 con check y "1 completado"
- Los tips se mostraron correctamente
- Pero el contador principal mostro **00/66** en vez de 01/66
- No se disparo la animacion de felicitacion
- No aparecio el logro del primer dia completado

### Causa probable
El `dayNum` o `completedCount` en HomeView/AppState se calcula en algun momento anterior a que el run se sincronice, o hay un problema de timing entre cuando HealthKit/CoreLocation reporta el run y cuando AppState actualiza el estado de UI.

### Fixes necesarios
- [ ] Identificar donde se calcula `completedCount` / el valor que alimenta el contador `XX/66`
- [ ] Asegurarse de que el conteo se recalcule despues de que un run queda guardado (tanto HealthKit como tracker in-app)
- [ ] Verificar que `pendingAchievement` se evalua despues del recalculo, no antes
- [ ] Verificar que la animacion de felicitacion se dispara cuando `completedCount` sube de N a N+1
- [ ] Caso edge: primer dia del reto (0 → 1 completado) debe disparar logro "Dia 1"

---

## 19. Prueba Visual: Ojos Tipo Pokemon en el Monito
**Prioridad:** Baja | **Complejidad:** Baja

Explorar como se ve el monito con ojos estilo Pokemon (grandes, expresivos, con pupila y brillo).

- [ ] Implementar variante de ojos en `PetCanvasView` (o struct separado `PokemonEyes`)
- [ ] Ojos grandes con pupila negra circular, iris de color, brillo blanco en esquina superior
- [ ] Probar en al menos 2-3 personajes para ver consistencia visual
- [ ] Agregar toggle en Settings (debug o permanente segun resultado)
- [ ] Decidir si se adopta o se descarta segun resultado visual
