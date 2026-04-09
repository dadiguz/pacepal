# Backlog P2 - Futuras mejoras

## Orden de ejecucion

| # | Tarea | Prioridad | Estado |
|---|-------|-----------|--------|
| 1 | Editor foto + stickers para compartir | Media | Pendiente |
| 2 | Soporte millas (km/mi) | Media | Pendiente |
| 3 | Estado Sleep del monito | Media | Pendiente |
| 4 | Mini-juego easter egg (estilo dino Chrome) | Baja | Pendiente |

---

## 1. Editor Foto + Stickers para Compartir
**Prioridad:** Media | **Complejidad:** Alta

Segunda opcion de compartir: tomar una foto y agregar stickers del monito y stats.

- [ ] Opcion "Tomar foto" en el modal de compartir logro (junto a "Compartir asi")
- [ ] Abrir camara o photo picker
- [ ] Canvas de edicion con la foto de fondo
- [ ] Stickers arrastrables: monito (pose actual), badge de km corridos, badge del dia
- [ ] Render del composite a imagen final
- [ ] Compartir via share sheet

---

## 2. Soporte Millas (km/mi)
**Prioridad:** Media | **Complejidad:** Baja-Media

- [ ] Agregar opcion en Settings para elegir unidad de distancia (km o millas)
- [ ] Persistir preferencia en UserDefaults
- [ ] Convertir todas las visualizaciones de distancia (HomeView, HistoryView, Widget, Tracker)
- [ ] Mantener almacenamiento interno siempre en km, solo convertir al mostrar

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

## 4. Mini-juego Easter Egg (estilo Dino de Chrome)
**Prioridad:** Baja | **Complejidad:** Media-Alta

Juego oculto tipo endless runner con el monito del usuario, similar al dinosaurio de Chrome cuando no hay internet.

- [ ] Trigger: algun gesto oculto o condicion especial (ej. tap multiple en el monito, o cuando no hay conexion)
- [ ] Pantalla fullscreen con scroll lateral infinito
- [ ] El monito corre automaticamente, el usuario toca para saltar
- [ ] Obstaculos generados aleatoriamente (conos, charcos, vallas)
- [ ] Scoring por distancia recorrida
- [ ] Velocidad incrementa gradualmente
- [ ] Pixel art consistente con el estilo visual de la app
- [ ] High score guardado en UserDefaults
- [ ] Strings en es/en
