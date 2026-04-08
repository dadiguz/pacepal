import Foundation

// MARK: - Language

enum AppLang: String, CaseIterable {
    case es, en

    static var current: AppLang {
        let code = Locale.current.language.languageCode?.identifier ?? "es"
        return AppLang(rawValue: code) ?? .es
    }
}

// MARK: - Lookup

/// Returns the localized string for `key` in the current device language.
/// Falls back to Spanish if the key or language is missing.
func L(_ key: String) -> String {
    _allStrings[key]?[AppLang.current] ?? _allStrings[key]?[.es] ?? key
}

/// Returns the localized format string for `key`, substituting `args`.
func L(_ key: String, _ args: CVarArg...) -> String {
    let template = L(key)
    return args.isEmpty ? template : String(format: template, arguments: args)
}

// MARK: - All strings
// Organized by screen. To add a language, add a new case to AppLang
// and include the translation for each key.

private let _allStrings: [String: [AppLang: String]] = {
    var d: [String: [AppLang: String]] = [:]
    for section in [
        _common, _difficulty,
        _onboarding, _paywall, _healthPerm, _notifPerm, _widgetPrompt,
        _charSelect, _home, _history, _settings, _tutorial, _notifications,
        _achievements, _archetypes, _medal,
    ] {
        d.merge(section) { _, new in new }
    }
    return d
}()

// MARK: - Common

private let _common: [String: [AppLang: String]] = [
    "common.km":                [.es: "km",          .en: "km"],
    "common.day":               [.es: "Día",         .en: "Day"],
    "common.day_n":             [.es: "Día %d",      .en: "Day %d"],
]

// MARK: - Difficulty

private let _difficulty: [String: [AppLang: String]] = [
    "difficulty.casual_label":    [.es: "🧸 Pequeñín",            .en: "🧸 Casual"],
    "difficulty.pro_label":       [.es: "🐺 Pro",                 .en: "🐺 Pro"],
    "difficulty.casual_subtitle": [.es: "La energía dura 7 días", .en: "Energy lasts 7 days"],
    "difficulty.pro_subtitle":    [.es: "La energía dura 36 horas", .en: "Energy lasts 36 hours"],
]

// MARK: - Onboarding

private let _onboarding: [String: [AppLang: String]] = [
    "onboarding.title_part1":    [.es: "Tu compañero\nde ",  .en: "Your\n"],
    "onboarding.title_highlight": [.es: "66 días",           .en: "66-day"],
    "onboarding.title_part3":    [.es: " te espera.",        .en: " companion awaits."],
    "onboarding.subtitle":       [.es: "Corre. Mantenlo vivo.", .en: "Run. Keep it alive."],
    "onboarding.choose_button":  [.es: "Elegir mi compañero",  .en: "Choose my companion"],
]

// MARK: - Paywall

private let _paywall: [String: [AppLang: String]] = [
    "paywall.feature_challenge_title": [.es: "Reto de 66 días",   .en: "66-Day Challenge"],
    "paywall.feature_challenge_desc":  [.es: "El tiempo justo para convertirlo en hábito", .en: "Just the right time to build a habit"],
    "paywall.feature_health_title":    [.es: "Apple Health",       .en: "Apple Health"],
    "paywall.feature_health_desc":     [.es: "Tus km se sincronizan solos", .en: "Your km sync automatically"],
    "paywall.feature_streaks_title":   [.es: "Rachas y progreso", .en: "Streaks & Progress"],
    "paywall.feature_streaks_desc":    [.es: "Cada día del reto en tu historial", .en: "Every challenge day in your history"],
    "paywall.headline_keep_part1":     [.es: "Mantén a ",         .en: "Keep "],
    "paywall.headline_keep_part2":     [.es: " con vida.",        .en: " alive."],
    "paywall.headline_start_part1":    [.es: "Empieza tu ",       .en: "Start your "],
    "paywall.headline_start_highlight": [.es: "prueba gratis",    .en: "free trial"],
    "paywall.headline_start_part3":    [.es: " hoy mismo.",       .en: " today."],
    "paywall.free_trial_badge":        [.es: "7 días gratis",     .en: "7 days free"],
    "paywall.cancel_anytime":          [.es: "Cancela cuando quieras", .en: "Cancel anytime"],
    "paywall.price_today":             [.es: "HOY",               .en: "TODAY"],
    "paywall.price_free":              [.es: "GRATIS",            .en: "FREE"],
    "paywall.price_trial_days":        [.es: "7 días de prueba",  .en: "7-day trial"],
    "paywall.price_trial_desc":        [.es: "7 días de prueba",  .en: "7-day trial"],
    "paywall.price_after":             [.es: "DESPUÉS",           .en: "THEN"],
    "paywall.price_per_year":          [.es: "al año",            .en: "per year"],
    "paywall.processing":              [.es: "Procesando...",     .en: "Processing..."],
    "paywall.start_trial":             [.es: "Comenzar prueba gratuita", .en: "Start free trial"],
    "paywall.restoring":               [.es: "Buscando compra...", .en: "Looking for purchase..."],
    "paywall.restore":                 [.es: "Restaurar compra",  .en: "Restore purchase"],
]

// MARK: - Health Permission

private let _healthPerm: [String: [AppLang: String]] = [
    "health.title_part1":       [.es: "Conecta con\n",        .en: "Connect with\n"],
    "health.title_highlight":   [.es: "Apple Health.",         .en: "Apple Health."],
    "health.subtitle_part1":    [.es: "Así sabemos cuándo corres\ny ", .en: "This is how we know when you run\nand "],
    "health.subtitle_highlight": [.es: "tu compañero cobra vida.", .en: "your companion comes to life."],
    "health.pill_distance":     [.es: "Distancia",            .en: "Distance"],
    "health.pill_readonly":     [.es: "Solo lectura",         .en: "Read only"],
    "health.third_party_hint_1": [.es: "Si usas ",             .en: "If you use "],
    "health.third_party_hint_2": [.es: ", ",                   .en: ", "],
    "health.third_party_hint_3": [.es: " u otra app, activa la sync con Apple Health para que tus carreras cuenten.",
                                  .en: " or another app, enable Apple Health sync so your runs count."],
    "health.unavailable_title": [.es: "Apple Health no\nestá disponible", .en: "Apple Health\nnot available"],
    "health.denied_title_part1": [.es: "Acceso a Health\n",   .en: "Health access\n"],
    "health.denied_title_part2": [.es: "no activado.",        .en: "not enabled."],
    "health.unavailable_body":  [.es: "Apple Health no está disponible en este dispositivo. Pacepal requiere un iPhone con Apple Health para funcionar.",
                                 .en: "Apple Health is not available on this device. Pacepal requires an iPhone with Apple Health to work."],
    "health.denied_body":       [.es: "Sin acceso, Pacepal no puede detectar tus carreras y tu compañero no podrá crecer contigo.\n\nVe a Ajustes → Privacidad → Salud → Pacepal y activa Distancia en caminata y carrera.",
                                 .en: "Without access, Pacepal can't detect your runs and your companion won't be able to grow with you.\n\nGo to Settings → Privacy → Health → Pacepal and enable Walking + Running Distance."],
    "health.requesting":        [.es: "Esperando permiso...", .en: "Waiting for permission..."],
    "health.activate_button":   [.es: "Continuar",            .en: "Continue"],
    "health.open_settings":     [.es: "Abrir Ajustes",       .en: "Open Settings"],
    "health.retry":             [.es: "Intentar de nuevo",    .en: "Try again"],
]

// MARK: - Notification Permission

private let _notifPerm: [String: [AppLang: String]] = [
    "notif_perm.title_part1":      [.es: "Que nada te haga\n",  .en: "Don't let anything\n"],
    "notif_perm.title_highlight":   [.es: "perderle el ritmo.", .en: "break your rhythm."],
    "notif_perm.subtitle_part1":    [.es: "Te avisamos cuando tu compañero\npierda energía para que ",
                                     .en: "We'll let you know when your companion\nloses energy so "],
    "notif_perm.subtitle_highlight": [.es: "nunca se quede solo.", .en: "it's never alone."],
    "notif_perm.pill_alerts":       [.es: "Alertas de energía",  .en: "Energy alerts"],
    "notif_perm.pill_motivation":   [.es: "Motivación diaria",   .en: "Daily motivation"],
    "notif_perm.requesting":        [.es: "Esperando permiso...", .en: "Waiting for permission..."],
    "notif_perm.activate_button":   [.es: "Activar notificaciones", .en: "Enable notifications"],
    "notif_perm.skip":              [.es: "Omitir por ahora",    .en: "Skip for now"],
]

// MARK: - Widget Prompt

private let _widgetPrompt: [String: [AppLang: String]] = [
    "widget_prompt.energy_label":  [.es: "Energía",        .en: "Energy"],
    "widget_prompt.mood_happy":    [.es: "Contento",       .en: "Happy"],
    "widget_prompt.title_part1":   [.es: "Tenlo siempre\n", .en: "Keep it always\n"],
    "widget_prompt.title_highlight": [.es: "a la vista.",   .en: "in sight."],
    "widget_prompt.subtitle":      [.es: "Agrega el widget a tu pantalla principal\ny mira su estado sin abrir la app.",
                                    .en: "Add the widget to your home screen\nand check its status without opening the app."],
    "widget_prompt.step1":         [.es: "Mantén presionado el home screen", .en: "Long press on your home screen"],
    "widget_prompt.step2":         [.es: "Toca el botón  +  de la esquina",  .en: "Tap the  +  button in the corner"],
    "widget_prompt.step3":         [.es: "Busca Pacepal y elige el widget",  .en: "Search for Pacepal and choose a widget"],
    "widget_prompt.got_it":        [.es: "Entendido",      .en: "Got it"],
    "widget_prompt.not_now":       [.es: "Ahora no",       .en: "Not now"],
    "widget_prompt.km_today":      [.es: "%.1f km hoy",    .en: "%.1f km today"],
    "widget_prompt.day_of_66":     [.es: "Día %d de 66",   .en: "Day %d of 66"],
]

// MARK: - Character Select

private let _charSelect: [String: [AppLang: String]] = [
    "char_select.title":      [.es: "Elige tu compañero de 66 días", .en: "Choose your 66-day companion"],
    "char_select.tagline":    [.es: "Te acompañará en cada kilómetro", .en: "It'll be with you every kilometer"],
    "char_select.name_prompt": [.es: "¿Cómo se llama tu compañero?", .en: "What's your companion's name?"],
    "char_select.name_error":  [.es: "¡Necesita un nombre!",         .en: "It needs a name!"],
    "char_select.name_max":    [.es: "Máximo %d letras",             .en: "Max %d characters"],
    "char_select.confirm":     [.es: "Confirmar",                    .en: "Confirm"],
    "char_select.generate":    [.es: "Generar",                      .en: "Generate"],
    "char_select.select":      [.es: "Seleccionar",                  .en: "Select"],
]

// MARK: - Home

private let _home: [String: [AppLang: String]] = [
    "home.no_energy":           [.es: "Sin energía",         .en: "No energy"],
    "home.time_minutes":        [.es: "%dm restantes",       .en: "%dm remaining"],
    "home.time_hours":          [.es: "%dh restantes",       .en: "%dh remaining"],
    "home.time_hours_minutes":  [.es: "%dh %dm restantes",   .en: "%dh %dm remaining"],
    "home.hp":                  [.es: "HP",                  .en: "HP"],
    "home.day_counter":         [.es: "DÍA: %@/66",         .en: "DAY: %@/66"],
    "home.km":                  [.es: "km",                  .en: "km"],
    "home.game_over":           [.es: "%@ se quedó sin energía...", .en: "%@ ran out of energy..."],
    "home.retry":               [.es: "Volver a intentarlo", .en: "Try again"],
    "home.achievement_dismiss": [.es: "¡Vamos!",            .en: "Let's go!"],
    "home.achievement_badge":   [.es: "DÍA %d / 66",       .en: "DAY %d / 66"],
    "home.stat_runs":           [.es: "Carreras",           .en: "Runs"],
    "home.stat_total_km":       [.es: "km totales",         .en: "Total km"],
    "home.stat_best_streak":    [.es: "Mejor racha",        .en: "Best streak"],
    "home.achievements_title":  [.es: "LOGROS",             .en: "ACHIEVEMENTS"],
    // Mood texts (with %@ for pet name)
    "home.mood_hype":           [.es: "¡%@ está en su mejor momento!", .en: "%@ is at its best!"],
    "home.mood_happy":          [.es: "%@ está feliz, ¡sigamos!",     .en: "%@ is happy, let's keep going!"],
    "home.mood_jump":           [.es: "%@ tiene energía, ¿corremos?", .en: "%@ has energy, shall we run?"],
    "home.mood_idle":           [.es: "%@ está listo para correr",    .en: "%@ is ready to run"],
    "home.mood_angry":          [.es: "Está exigiendo que corras",    .en: "It's demanding that you run"],
    "home.mood_sad":            [.es: "La energía se acaba... ¡sal a correr!", .en: "Energy is running out... go run!"],
    "home.mood_dizzy":          [.es: "%@ está a punto de colapsar...", .en: "%@ is about to collapse..."],
    "home.mood_dead":           [.es: "%@ está exhausto... ¡ve a correr!", .en: "%@ is exhausted... go run!"],
    "home.mood_default":        [.es: "%@ está listo",                .en: "%@ is ready"],
]

// MARK: - History

private let _history: [String: [AppLang: String]] = [
    "history.title":              [.es: "Reto 66 Días",       .en: "66-Day Challenge"],
    "history.day_progress":       [.es: "Día %d/%d",          .en: "Day %d/%d"],
    "history.challenge_complete": [.es: "¡Reto completado!",  .en: "Challenge complete!"],
    "history.completed":          [.es: "Completados",        .en: "Completed"],
    "history.missed":             [.es: "Faltas",             .en: "Missed"],
    "history.streak":             [.es: "Racha",              .en: "Streak"],
    "history.estimated_finish":   [.es: "Fin estimado: %@",   .en: "Estimated finish: %@"],
    "history.state_completed":    [.es: "Completado ✓",       .en: "Completed ✓"],
    "history.state_missed":       [.es: "Sin actividad",      .en: "No activity"],
    "history.state_in_progress":  [.es: "En progreso",        .en: "In progress"],
    "history.state_upcoming":     [.es: "Próximamente",       .en: "Upcoming"],
    // Weekday headers
    "history.weekday_sun":        [.es: "D",  .en: "S"],
    "history.weekday_mon":        [.es: "L",  .en: "M"],
    "history.weekday_tue":        [.es: "M",  .en: "T"],
    "history.weekday_wed":        [.es: "M",  .en: "W"],
    "history.weekday_thu":        [.es: "J",  .en: "T"],
    "history.weekday_fri":        [.es: "V",  .en: "F"],
    "history.weekday_sat":        [.es: "S",  .en: "S"],
]

// MARK: - Settings

private let _settings: [String: [AppLang: String]] = [
    "settings.title":               [.es: "Ajustes",          .en: "Settings"],
    "settings.tutorial_title":      [.es: "Ver tutorial",     .en: "View tutorial"],
    "settings.tutorial_subtitle":   [.es: "Repasa cómo funciona la energía", .en: "Review how energy works"],
    "settings.background_title":    [.es: "Cambiar fondo",    .en: "Change background"],
    "settings.background_subtitle": [.es: "Personaliza el fondo de tu pantalla", .en: "Customize your screen background"],
    "settings.sounds_title":        [.es: "Sonidos",          .en: "Sounds"],
    "settings.sounds_subtitle":     [.es: "Efectos de sonido del compañero", .en: "Companion sound effects"],
    "settings.premium_active":      [.es: "Premium activo",   .en: "Premium active"],
    "settings.premium_manage":      [.es: "Gestiona tu suscripción en App Store", .en: "Manage your subscription in App Store"],
    "settings.premium_activate":    [.es: "Activar Premium",  .en: "Activate Premium"],
    "settings.premium_price":       [.es: "7 días gratis · %@ al año", .en: "7 days free · %@ per year"],
    "settings.reset_title":         [.es: "Restablecer compañero", .en: "Reset companion"],
    "settings.reset_subtitle":      [.es: "Elige un nuevo mono desde cero", .en: "Choose a new pet from scratch"],
    "settings.reset_confirm":       [.es: "Restablecer",      .en: "Reset"],
    "settings.cancel":              [.es: "Cancelar",          .en: "Cancel"],
    "settings.reset_message":       [.es: "Se borrará tu progreso y podrás elegir un nuevo compañero.",
                                     .en: "Your progress will be erased and you can choose a new companion."],
    "settings.backgrounds_title":   [.es: "Fondos",           .en: "Backgrounds"],
    "settings.backgrounds_subtitle": [.es: "Desbloqueas nuevos fondos al alcanzar cada logro",
                                      .en: "You unlock new backgrounds by reaching each milestone"],
    "settings.original":            [.es: "Original",          .en: "Original"],
    "settings.black":               [.es: "Negro",             .en: "Black"],
]

// MARK: - Tutorial

private let _tutorial: [String: [AppLang: String]] = [
    "tutorial.energy_title": [.es: "Tu energía",    .en: "Your energy"],
    "tutorial.energy_body":  [.es: "Baja con el tiempo. Si llega a 0% tu compañero se agota y tendrás que elegir uno nuevo.",
                              .en: "Drops over time. If it reaches 0% your companion collapses and you'll have to choose a new one."],
    "tutorial.km_title":     [.es: "Kilómetros",    .en: "Kilometers"],
    "tutorial.km_body":      [.es: "Cada km que corres suma 10% de energía. ¡Corre 4 km diarios para mantener a tu compañero al máximo!",
                              .en: "Each km you run adds 10% energy. Run 4 km daily to keep your companion at full power!"],
    "tutorial.skip":         [.es: "Saltar",         .en: "Skip"],
    "tutorial.done":         [.es: "Entendido ✓",    .en: "Got it ✓"],
    "tutorial.next":         [.es: "Siguiente →",    .en: "Next →"],
]

// MARK: - Notifications

private let _notifications: [String: [AppLang: String]] = [
    "notif.demanding_title":   [.es: "%@ está exigiendo que corras",     .en: "%@ is demanding that you run"],
    "notif.demanding_body":    [.es: "Tienes que salir a correr o perderá energía", .en: "You need to go run or it'll lose energy"],
    "notif.low_energy_title":  [.es: "La energía de %@ se acaba",       .en: "%@'s energy is running out"],
    "notif.low_energy_body":   [.es: "¡Sal a correr ahora antes de que colapse!", .en: "Go run now before it collapses!"],
    "notif.collapsing_title":  [.es: "%@ está a punto de colapsar",     .en: "%@ is about to collapse"],
    "notif.collapsing_body":   [.es: "Está en estado crítico. ¡Corre o lo perderás todo!", .en: "It's in critical condition. Run or you'll lose everything!"],
    "notif.critical_title":    [.es: "Tu %@ necesita que corras",       .en: "Your %@ needs you to run"],
    "notif.critical_body":     [.es: "De inmediato, ¡está a punto de quedarse sin energía!", .en: "Right now — it's about to run out of energy!"],
    "notif.fallback":          [.es: "¡Sal a correr!",                  .en: "Go for a run!"],
]

// MARK: - Achievements

private let _achievements: [String: [AppLang: String]] = [
    // Day 1
    "achievement.1.part1":  [.es: "Día 1. ",       .en: "Day 1. "],
    "achievement.1.part2":  [.es: "Empezaste cuando era más fácil quedarte. Eso ya es ", .en: "You started when it was easier to stay. That's already "],
    "achievement.1.part3":  [.es: "más que la mayoría.", .en: "more than most."],
    // Day 4
    "achievement.4.part1":  [.es: "4 días seguidos. ", .en: "4 days in a row. "],
    "achievement.4.part2":  [.es: "Tu cuerpo ya siente el ritmo ", .en: "Your body already feels the rhythm "],
    "achievement.4.part3":  [.es: "en los pies.", .en: "in your feet."],
    // Day 7
    "achievement.7.part1":  [.es: "Una semana completa. ", .en: "One full week. "],
    "achievement.7.part2":  [.es: "Tu cuerpo empieza a recordar el camino y ", .en: "Your body starts to remember the path and "],
    "achievement.7.part3":  [.es: "quiere más.", .en: "wants more."],
    // Day 10
    "achievement.10.part1": [.es: "10 días. ", .en: "10 days. "],
    "achievement.10.part2": [.es: "La disciplina ya no es esfuerzo, ", .en: "Discipline is no longer effort, "],
    "achievement.10.part3": [.es: "se está instalando sola.", .en: "it's installing itself."],
    // Day 13
    "achievement.13.part1": [.es: "13 días. ", .en: "13 days. "],
    "achievement.13.part2": [.es: "Casi dos semanas de ", .en: "Almost two weeks of "],
    "achievement.13.part3": [.es: "movimiento real y constante.", .en: "real, consistent movement."],
    // Day 16
    "achievement.16.part1": [.es: "16 días. ", .en: "16 days. "],
    "achievement.16.part2": [.es: "Ya no tienes que convencerte de salir. El hábito ", .en: "You no longer have to convince yourself to go out. The habit "],
    "achievement.16.part3": [.es: "ya es tuyo.", .en: "is already yours."],
    // Day 19
    "achievement.19.part1": [.es: "19 días. ", .en: "19 days. "],
    "achievement.19.part2": [.es: "Cada mañana que elegiste moverte en lugar de quedarte ", .en: "Every morning you chose to move instead of staying "],
    "achievement.19.part3": [.es: "cuenta.", .en: "counts."],
    // Day 22
    "achievement.22.part1": [.es: "22 días. ", .en: "22 days. "],
    "achievement.22.part2": [.es: "Tres semanas completas de ", .en: "Three full weeks of "],
    "achievement.22.part3": [.es: "correr sin excusas.", .en: "running with no excuses."],
    // Day 25
    "achievement.25.part1": [.es: "25 días. ", .en: "25 days. "],
    "achievement.25.part2": [.es: "Ya pasaste la mitad del reto. No hay marcha atrás, ", .en: "You've passed half the challenge. No turning back, "],
    "achievement.25.part3": [.es: "no paras.", .en: "don't stop."],
    // Day 28
    "achievement.28.part1": [.es: "28 días. ", .en: "28 days. "],
    "achievement.28.part2": [.es: "Un mes entero de decisiones correctas, una tras otra.", .en: "A whole month of right decisions, one after another."],
    // Day 31
    "achievement.31.part1": [.es: "31 días. ", .en: "31 days. "],
    "achievement.31.part2": [.es: "El primer mes completo quedó atrás. Cada kilómetro fue ", .en: "The first full month is behind you. Every kilometer was "],
    "achievement.31.part3": [.es: "tuyo.", .en: "yours."],
    // Day 34
    "achievement.34.part1": [.es: "34 días. ", .en: "34 days. "],
    "achievement.34.part2": [.es: "La mayoría ya se rindió hace tiempo. ", .en: "Most people gave up long ago. "],
    "achievement.34.part3": [.es: "Tú sigues corriendo.", .en: "You keep running."],
    // Day 37
    "achievement.37.part1": [.es: "37 días. ", .en: "37 days. "],
    "achievement.37.part2": [.es: "Más de la mitad del camino recorrido. El final ya ", .en: "More than halfway there. The finish line "],
    "achievement.37.part3": [.es: "se acerca.", .en: "is getting closer."],
    // Day 40
    "achievement.40.part1": [.es: "40 días. ", .en: "40 days. "],
    "achievement.40.part2": [.es: "Eres constancia, disciplina y ", .en: "You are consistency, discipline, and "],
    "achievement.40.part3": [.es: "movimiento puro.", .en: "pure movement."],
    // Day 43
    "achievement.43.part1": [.es: "43 días. ", .en: "43 days. "],
    "achievement.43.part2": [.es: "Cada salida, cada kilómetro, es ", .en: "Every outing, every kilometer, is "],
    "achievement.43.part3": [.es: "una victoria tuya.", .en: "a victory of yours."],
    // Day 46
    "achievement.46.part1": [.es: "46 días. ", .en: "46 days. "],
    "achievement.46.part2": [.es: "A solo ", .en: "Just "],
    "achievement.46.part3": [.es: "20 días ", .en: "20 days "],
    "achievement.46.part4": [.es: "de cruzar la meta. Aguanta.", .en: "from crossing the finish line. Hold on."],
    // Day 49
    "achievement.49.part1": [.es: "49 días. ", .en: "49 days. "],
    "achievement.49.part2": [.es: "Siete semanas de ", .en: "Seven weeks of "],
    "achievement.49.part3": [.es: "pura determinación y ganas.", .en: "pure determination and drive."],
    // Day 52
    "achievement.52.part1": [.es: "52 días. ", .en: "52 days. "],
    "achievement.52.part2": [.es: "La recta final ya ", .en: "The final stretch "],
    "achievement.52.part3": [.es: "está muy cerca.", .en: "is very close."],
    // Day 55
    "achievement.55.part1": [.es: "55 días. ", .en: "55 days. "],
    "achievement.55.part2": [.es: "Solo 11 días más entre tú y la meta. ", .en: "Only 11 more days between you and the goal. "],
    "achievement.55.part3": [.es: "No sueltes ahora.", .en: "Don't let go now."],
    // Day 58
    "achievement.58.part1": [.es: "58 días. ", .en: "58 days. "],
    "achievement.58.part2": [.es: "Ya puedes sentirla. ", .en: "You can feel it. "],
    "achievement.58.part3": [.es: "La meta está justo ahí.", .en: "The finish line is right there."],
    // Day 61
    "achievement.61.part1": [.es: "61 días. ", .en: "61 days. "],
    "achievement.61.part2": [.es: "Solo 5 días más entre tú y los 66. ", .en: "Only 5 more days between you and 66. "],
    "achievement.61.part3": [.es: "Tú puedes.", .en: "You can do it."],
    // Day 64
    "achievement.64.part1": [.es: "64 días. ", .en: "64 days. "],
    "achievement.64.part2": [.es: "La línea de meta ", .en: "The finish line "],
    "achievement.64.part3": [.es: "está a dos pasos.", .en: "is two steps away."],
    // Day 66
    "achievement.66.part1": [.es: "66 días. ", .en: "66 days. "],
    "achievement.66.part2": [.es: "Elegiste salir cuando todo decía quedarte. Corriste cuando pensabas que no podías. ",
                             .en: "You chose to go out when everything said stay. You ran when you thought you couldn't. "],
    "achievement.66.part3": [.es: "Rompiste la meta ", .en: "You broke the goal "],
    "achievement.66.part4": [.es: "y lo construiste. ", .en: "and built it. "],
    "achievement.66.part5": [.es: "Ahora sigue corriendo.", .en: "Now keep running."],
    // Short phrases for the list
    "achievement.1.short":  [.es: "Día 1. Empezaste.",       .en: "Day 1. You started."],
    "achievement.4.short":  [.es: "4 días. Ya tienes el ritmo en los pies.", .en: "4 days. You've got the rhythm in your feet."],
    "achievement.7.short":  [.es: "Una semana. Tu cuerpo empieza a recordar.", .en: "One week. Your body starts to remember."],
    "achievement.10.short": [.es: "10 días. La disciplina se está instalando.", .en: "10 days. Discipline is installing itself."],
    "achievement.13.short": [.es: "13 días. Casi dos semanas de movimiento real.", .en: "13 days. Almost two weeks of real movement."],
    "achievement.16.short": [.es: "16 días. El hábito ya es tuyo.", .en: "16 days. The habit is already yours."],
    "achievement.19.short": [.es: "19 días. Cada salida cuenta.", .en: "19 days. Every outing counts."],
    "achievement.22.short": [.es: "22 días. Tres semanas completas corriendo.", .en: "22 days. Three full weeks running."],
    "achievement.25.short": [.es: "25 días. A mitad del reto. No paras.", .en: "25 days. Halfway there. Don't stop."],
    "achievement.28.short": [.es: "28 días. Un mes de decisiones correctas.", .en: "28 days. A month of right decisions."],
    "achievement.31.short": [.es: "31 días. El mes completo quedó atrás.", .en: "31 days. The full month is behind you."],
    "achievement.34.short": [.es: "34 días. La mayoría ya se rindió. Tú sigues.", .en: "34 days. Most gave up. You keep going."],
    "achievement.37.short": [.es: "37 días. Más de la mitad. El final se acerca.", .en: "37 days. Past halfway. The end is near."],
    "achievement.40.short": [.es: "40 días. Eres constancia en movimiento.", .en: "40 days. You are consistency in motion."],
    "achievement.43.short": [.es: "43 días. Cada salida es una victoria.", .en: "43 days. Every outing is a victory."],
    "achievement.46.short": [.es: "46 días. A solo 20 días de lograrlo.", .en: "46 days. Just 20 days from making it."],
    "achievement.49.short": [.es: "49 días. Siete semanas de pura determinación.", .en: "49 days. Seven weeks of pure determination."],
    "achievement.52.short": [.es: "52 días. La recta final está cerca.", .en: "52 days. The final stretch is near."],
    "achievement.55.short": [.es: "55 días. A solo 11 días. No sueltes ahora.", .en: "55 days. Just 11 days. Don't let go now."],
    "achievement.58.short": [.es: "58 días. Ya puedes verla. La meta está ahí.", .en: "58 days. You can see it. The goal is there."],
    "achievement.61.short": [.es: "61 días. 5 días más. Tú puedes.", .en: "61 days. 5 more days. You can do it."],
    "achievement.64.short": [.es: "64 días. La línea de meta está a la vuelta.", .en: "64 days. The finish line is around the corner."],
    "achievement.66.short": [.es: "66 días. Elegiste salir cuando todo decía quedarte. Corriste cuando pensabas que no podías. Rompiste la meta y lo construiste. Ahora sigue corriendo.",
                             .en: "66 days. You chose to go out when everything said stay. You ran when you thought you couldn't. You broke the goal and built it. Now keep running."],
]

// MARK: - Archetype label (extension here so L() is visible; PetTypes.swift is shared with widget)

extension PetAnimalType {
    var archetypeLabel: String { L("archetype.\(rawValue)") }
}

// MARK: - Archetypes (pet nature labels)

private let _archetypes: [String: [AppLang: String]] = [
    "archetype.bunny":    [.es: "Veloz",       .en: "Swift"],
    "archetype.cat":      [.es: "Ágil",        .en: "Agile"],
    "archetype.bear":     [.es: "Fuerza",      .en: "Strength"],
    "archetype.raccoon":  [.es: "Adaptable",   .en: "Adaptable"],
    "archetype.mouse":    [.es: "Veloz",       .en: "Swift"],
    "archetype.frog":     [.es: "Potencia",    .en: "Power"],
    "archetype.duck":     [.es: "Resistente",  .en: "Resilient"],
    "archetype.axolotl":  [.es: "Resiliente",  .en: "Tough"],
    "archetype.smooth":   [.es: "Libre",       .en: "Free"],
    "archetype.capuchin": [.es: "Dinámico",    .en: "Dynamic"],
    "archetype.mandrill": [.es: "Salvaje",     .en: "Wild"],
    "archetype.fox":      [.es: "Estratega",   .en: "Strategist"],
    "archetype.lion":     [.es: "Dominante",   .en: "Dominant"],
    "archetype.domo":     [.es: "Imparable",   .en: "Unstoppable"],
    "archetype.pou":      [.es: "Constante",   .en: "Steady"],
    "archetype.dog":      [.es: "Leal",        .en: "Loyal"],
    "archetype.tiger":    [.es: "Feroz",       .en: "Fierce"],
    "archetype.panda":    [.es: "Tenaz",       .en: "Tenacious"],
    "archetype.corgi":    [.es: "Alegre",      .en: "Cheerful"],
    "archetype.dragon":   [.es: "Legendario",  .en: "Legendary"],
]

// MARK: - Medal (66-day completion)

private let _medal: [String: [AppLang: String]] = [
    "medal.tutorial_title":    [.es: "¡Medalla desbloqueada!",   .en: "Medal unlocked!"],
    "medal.tutorial_body":     [.es: "Completaste el reto de 66 días. Tu compañero ya no pierde energía. ¡Sigue corriendo!",
                                .en: "You completed the 66-day challenge. Your companion no longer loses energy. Keep running!"],
    "medal.tutorial_dismiss":  [.es: "¡Increíble!",             .en: "Amazing!"],
    "medal.energy_permanent":  [.es: "Energía permanente",      .en: "Permanent energy"],
]
