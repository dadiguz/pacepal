# Agents.md — Decisiones de diseño y problemas resueltos

Guía para agentes de IA trabajando en PacePal. Antes de tocar lógica del contador de días, leer esta sección.

---

## 1. Fórmula del contador XX/66

### El problema (Bug #18)
El contador mostraba **00/66** después de completar una carrera. El root cause era un gap de timing: al terminar el run, `health.todayKm` subía inmediatamente (computed property), pero `appState.completedDays` todavía no había sido actualizado. El código hacía:

```swift
// INCORRECTO - da 00/66 en el timing gap
min(66, alreadyRanToday ? appState.completedDays : appState.completedDays + 1)
// completedDays=0, alreadyRanToday=true → min(66, 0) = 0 → "00/66"
```

### La fórmula correcta
**En palabras:** el contador muestra el día del reto en el que estás. Siempre es `diasCompletadosAntesDeHoy + 1`. Correr hoy no mueve el contador — lo mueve mañana.

**Matemáticamente:**
```
contador = max(1, min(66, diasCompletadosAntesDeHoy + 1))

donde:
  diasCompletadosAntesDeHoy = completedDays - (corrióHoy ? 1 : 0)
  corrióHoy = todayKm >= runThreshold
```

**En código Swift:**
```swift
max(1, min(66, health.todayKm >= appState.challengeLevel.runThreshold
    ? appState.completedDays
    : appState.completedDays + 1))
```

### Ejemplos que validan la fórmula
| Fecha | Corrió | completedDays | todayKm≥threshold | Contador |
|-------|--------|---------------|-------------------|----------|
| 12/04 | No     | 0             | false             | **01/66** |
| 13/04 | Sí     | 1             | true              | **01/66** |
| 14/04 | No     | 1             | false             | **02/66** |
| 15/04 | Sí     | 2             | true              | **02/66** |
| 16/04 | Sí     | 3             | true              | **03/66** |
| 17/04 | No     | 3             | false             | **04/66** |
| 18/04 | No     | 3             | false             | **04/66** |
| — (timing gap) | corriendo | 0 | true   | **01/66** ← max(1,...) lo salva |

### Reglas inamovibles
- **Nunca mostrar 00/66** — `max(1, ...)` lo garantiza
- **Correr hoy no cambia el número** — siempre es el mismo día hasta mañana
- **No usar lógica de fechas calendario** (`challengeStartDate`) para este contador — depende de `completedDays`
- El contador vive en dos lugares: `HomeView.swift` (energySection) y `RunTrackerView.swift` (`currentDay`). Deben usar la misma fórmula

### Archivos afectados
- `PacePal/Views/HomeView.swift` — línea ~759, dentro de `energySection`
- `PacePal/Views/RunTrackerView.swift` — `currentDay` computed property (~línea 46)

---

## 2. Naming — siempre "Pacepal"

El nombre correcto de la app es **Pacepal** — con P mayúscula y 'p' minúscula en 'pal'.

- ✅ Correcto: `Pacepal`
- ❌ Incorrecto: `PacePal`, `pacepal`, `PACEPAL`

Aplica en: títulos de vistas, strings visibles al usuario, comentarios, nombres de archivo nuevos, y cualquier texto que genere un agente de IA. El bundle ID y targets de Xcode pueden mantener su casing original (`io.dallio.PacePal`) ya que cambiarlos rompería la identidad del app.
