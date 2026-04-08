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
**Prioridad:** Alta | **Complejidad:** Baja

- [ ] Auditar que el reto requiere 66 dias completos (con carrera), no 66 dias calendario
- [ ] Si el usuario hace skip, el grid historico muestra ese dia vacio pero sigue contando
- [ ] Ejemplo: 1 skip = 67 cuadritos en el grid (66 completos + 1 skip)
- [ ] Verificar que logros se disparan por dias completados, no dias transcurridos
- [ ] Verificar que la fecha estimada de finalizacion se ajusta con los skips

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
