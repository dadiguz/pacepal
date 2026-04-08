# Backlog - Sesion 2026-04-07

## Orden de ejecucion

| # | Tarea | Prioridad | Estado |
|---|-------|-----------|--------|
| 1 | Fix boton HealthKit (5a) | Critica | Pendiente |
| 2 | Revisar logica 66 dias (4) | Alta | Pendiente |
| 3 | Tracker de carrera in-app (5b) | Critica | Pendiente |
| 4 | Internacionalizacion ingles (1) | Alta | Pendiente |
| 5 | Estado Sleep del monito (3) | Media | Pendiente |
| 6 | Medalla 66 dias (2) | Media | Pendiente |

---

## 1. Internacionalizacion (i18n) - Idioma Ingles
**Prioridad:** Alta | **Complejidad:** Media-Alta

- [ ] Crear sistema de localizacion con `Localizable.strings` (es/en)
- [ ] Crear helper o extension de `String` para hacer el sistema extensible a futuros idiomas
- [ ] Extraer todos los textos hardcodeados de Views, AppState, RunningPhrases, NotificationManager, Widget
- [ ] Traducir al ingles: UI, frases motivacionales, logros, tutoriales, textos del widget
- [ ] Actualizar `Info.plist` con descripciones en ambos idiomas
- [ ] El idioma se selecciona automaticamente segun el dispositivo

---

## 2. Medalla 66 Dias (Asset + Logica)
**Prioridad:** Media | **Complejidad:** Media

- [ ] Disenar/agregar asset de medalla con liston azul y dorado con el numero "66"
- [ ] Se otorga al completar 66 dias completos del reto
- [ ] Efecto especial: al obtenerla, el monito ya no pierde energia (decay = 0)
- [ ] Agregar pantalla de tutorial post-logro explicando la medalla y su beneficio
- [ ] Mostrar medalla en HomeView o perfil como badge permanente

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

## 4. Revision Logica de 66 Dias + Skip Days
**Prioridad:** Alta | **Complejidad:** Media

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

---

## 5. Fix App Store Rejection + Tracking de Carrera In-App

### 5a. Fix Guideline 5.1.1(iv)
**Prioridad:** Critica | **Complejidad:** Baja

- [ ] Cambiar boton "Activar Apple Health" por "Continuar" o "Siguiente"
- [ ] Hacer que HealthKit sea opcional (skip permitido)

### 5b. Tracker de carrera in-app
**Prioridad:** Critica | **Complejidad:** Alta

- [ ] Agregar boton "Track Run" en HomeView
- [ ] Pantalla fullscreen al presionar con:
  - [ ] KM corridos en grande (tipografia bold, centrado)
  - [ ] Monito corriendo animado si se registran KM
  - [ ] Monito cansado/sudando si se detiene
  - [ ] Boton para finalizar carrera
- [ ] Usar CoreLocation para tracking de distancia (no depende de HealthKit)
- [ ] Los KM trackeados se suman a la energia igual que los de HealthKit
- [ ] Permite que la app funcione sin permisos de HealthKit
