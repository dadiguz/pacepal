import Foundation

// MARK: - Language

enum AppLang: String, CaseIterable {
    case es, en

    /// Display name in its own language (always shown native)
    var displayName: String {
        switch self {
        case .es: return "Español"
        case .en: return "English"
        }
    }

    private static let key = "appLanguageOverride"

    static var current: AppLang {
        if let saved = UserDefaults.standard.string(forKey: key),
           let lang = AppLang(rawValue: saved) {
            return lang
        }
        let preferred = Locale.preferredLanguages.first ?? "es"
        let code = String(preferred.prefix(2))
        return AppLang(rawValue: code) ?? .es
    }

    static func setCurrent(_ lang: AppLang?) {
        if let lang {
            UserDefaults.standard.set(lang.rawValue, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
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
        _common, _challengeLevel, _questionnaire,
        _onboarding, _paywall, _healthPerm, _notifPerm, _widgetPrompt,
        _charSelect, _home, _history, _settings, _tutorial, _notifications,
        _achievements, _archetypes, _medal, _tips, _tipDetails, _tracker, _locationPerm, _forceUpdate,
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

// MARK: - Challenge level

private let _challengeLevel: [String: [AppLang: String]] = [
    "level.habito.label":         [.es: "Hábito",      .en: "Habit"],
    "level.habito.subtitle":      [.es: "Construye el hábito",   .en: "Build the habit"],
    "level.resistencia.label":    [.es: "Resistencia", .en: "Endurance"],
    "level.resistencia.subtitle": [.es: "Balance ideal",         .en: "Ideal balance"],
    "level.rendimiento.label":    [.es: "Rendimiento", .en: "Performance"],
    "level.rendimiento.subtitle": [.es: "Máximo desafío",        .en: "Maximum challenge"],
]

// MARK: - Questionnaire

private let _questionnaire: [String: [AppLang: String]] = [
    "q.intro_title_part1":      [.es: "¿Quieres personalizar tu ", .en: "Want to personalize your "],
    "q.intro_title_highlight":  [.es: "reto",                      .en: "challenge"],
    "q.intro_title_part2":      [.es: "?",                         .en: "?"],
    "q.intro_subtitle":         [.es: "Responde 4 preguntas rápidas y te digo qué nivel se adapta mejor a ti. Esto determina cuánto debes correr cada día.", .en: "Answer 4 quick questions and I'll tell you which level fits you best. This determines how far you need to run each day."],
    "q.intro_cta":              [.es: "¡Responder!",               .en: "Let's go!"],
    "q.next":                   [.es: "Siguiente",                 .en: "Next"],
    "q.done":                   [.es: "Ver resultado",             .en: "See result"],
    "q.back":                   [.es: "Atrás",                     .en: "Back"],
    "q.skip":                   [.es: "Saltar",                    .en: "Skip"],
    "q1.question":              [.es: "¿Qué tan seguido corres?",     .en: "How often do you run?"],
    "q1.a":                     [.es: "Nunca o casi nunca",           .en: "Never or rarely"],
    "q1.b":                     [.es: "1-2 veces por semana",         .en: "1-2 times a week"],
    "q1.c":                     [.es: "3 o más veces por semana",     .en: "3+ times a week"],

    "q2.question":              [.es: "¿Cuánto sueles correr?",       .en: "How far do you usually run?"],
    "q2.a":                     [.es: "Menos de 2 km",                .en: "Less than 2 km"],
    "q2.b":                     [.es: "2 a 5 km",                     .en: "2 to 5 km"],
    "q2.c":                     [.es: "Más de 5 km",                  .en: "More than 5 km"],

    "q3.question":              [.es: "¿Qué tan exigente quieres el reto?", .en: "How demanding should the challenge be?"],
    "q3.a":                     [.es: "Relajado, para crear el hábito",   .en: "Relaxed, just build the habit"],
    "q3.b":                     [.es: "Normal, un buen balance",           .en: "Moderate, a good balance"],
    "q3.c":                     [.es: "Intenso, quiero exigirme",          .en: "Intense, I want to push myself"],

    "q4.question":              [.es: "¿Cuál es tu meta principal?",  .en: "What is your main goal?"],
    "q4.a":                     [.es: "Convertir correr en hábito",   .en: "Make running a habit"],
    "q4.b":                     [.es: "Mejorar mi resistencia",       .en: "Improve my endurance"],
    "q4.c":                     [.es: "Rendir al máximo",             .en: "Perform at my best"],

    "q.result_title":           [.es: "Tu nivel recomendado",         .en: "Your recommended level"],
    "q.result_body_habito":     [.es: "Solo necesitas correr 0.1 km al día para que cuente. Perfecto para construir el hábito sin presión.",
                                 .en: "Just 0.1 km a day counts as a completed day. Perfect for building the habit without pressure."],
    "q.result_body_resistencia":[.es: "0.5 km al día marca el día como completado. El balance ideal para corredores regulares.",
                                 .en: "0.5 km a day marks the day as completed. The ideal balance for regular runners."],
    "q.result_body_rendimiento":[.es: "Necesitas correr 1 km al día para que cuente. Para quienes ya corren fuerte y quieren un reto real.",
                                 .en: "You need to run 1 km a day for it to count. For those who already run hard and want a real challenge."],
    "q.stat_min_day":           [.es: "mín/día",                      .en: "min/day"],
    "q.stat_energy":            [.es: "energía",                      .en: "energy"],
    "q.result_badge":           [.es: "TU NIVEL",                     .en: "YOUR LEVEL"],
    "q.result_change":          [.es: "Cambiar nivel",                .en: "Change level"],
    "q.result_confirm":         [.es: "Empezar con este nivel",       .en: "Start with this level"],
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
    "paywall.err_purchase":            [.es: "No se pudo completar la compra.", .en: "The purchase could not be completed."],
    "paywall.err_generic":             [.es: "Ocurrió un error. Inténtalo de nuevo.", .en: "Something went wrong. Please try again."],
    "paywall.err_restore_none":        [.es: "No encontramos una suscripción activa.", .en: "No active subscription found."],
    "paywall.err_restore_failed":      [.es: "No se pudo restaurar la compra.", .en: "Could not restore purchase."],
]

// MARK: - Health Permission

private let _healthPerm: [String: [AppLang: String]] = [
    "health.title_part1":       [.es: "Conecta con",            .en: "Connect with"],
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
    "health.activate_button":   [.es: "Conectar con Apple Health", .en: "Connect with Apple Health"],
    "health.open_settings":     [.es: "Abrir Ajustes",       .en: "Open Settings"],
    "health.retry":             [.es: "Intentar de nuevo",    .en: "Try again"],
    "health.skip":              [.es: "Omitir por ahora",     .en: "Skip for now"],
]

// MARK: - Location Permission

private let _locationPerm: [String: [AppLang: String]] = [
    "location_perm.title_part1":      [.es: "Mide cada\n",             .en: "Measure every\n"],
    "location_perm.title_highlight":  [.es: "paso que corres.",        .en: "step you run."],
    "location_perm.subtitle":         [.es: "Usamos GPS para registrar tu distancia en tiempo real, aunque no tengas Apple Watch o HealthKit.",
                                       .en: "We use GPS to track your distance in real time, even without Apple Watch or HealthKit."],
    "location_perm.pill_gps":         [.es: "GPS en tiempo real",      .en: "Real-time GPS"],
    "location_perm.pill_readonly":    [.es: "Solo lectura",            .en: "Read only"],
    "location_perm.activate_button":  [.es: "Activar ubicación",       .en: "Enable location"],
    "location_perm.skip":             [.es: "Omitir por ahora",        .en: "Skip for now"],
]

// MARK: - Force Update

private let _forceUpdate: [String: [AppLang: String]] = [
    "force_update.title":    [.es: "%@ está exigiendo que actualices la app",
                              .en: "%@ is demanding you update the app"],
    "force_update.subtitle": [.es: "Actualiza para obtener todas las mejoras y seguir corriendo.",
                              .en: "Update to get all the improvements and keep running."],
    "force_update.button":   [.es: "Actualizar ahora",
                              .en: "Update now"],
]

// MARK: - Run Tracker

private let _tracker: [String: [AppLang: String]] = [
    "tracker.track_run":               [.es: "¡Corre!",                 .en: "Run!"],
    "tracker.km":                      [.es: "km",                      .en: "km"],
    "tracker.label_pace":              [.es: "RITMO",                   .en: "PACE"],
    "tracker.label_day":               [.es: "DÍA",                     .en: "DAY"],
    "tracker.label_time":              [.es: "TIEMPO",                  .en: "TIME"],
    "tracker.label_kilometers":        [.es: "kilómetros",              .en: "kilometers"],
    "tracker.hold_to_start":           [.es: "Mantén presionado para iniciar", .en: "Hold to start"],
    "tracker.start_button":            [.es: "INICIO",                  .en: "START"],
    "tracker.stop_button":             [.es: "PARAR",                   .en: "STOP"],
    "tracker.hold_toast":              [.es: "Mantén presionado",        .en: "Hold to confirm"],
    "tracker.indoor":                  [.es: "Interior",                 .en: "Indoor"],
    "tracker.outdoor":                 [.es: "Exterior",                 .en: "Outdoor"],
    "tracker.auto_pause":              [.es: "Auto-pausa",               .en: "Auto-Pause"],
    "tracker.auto_paused_toast":       [.es: "Pausa automática",         .en: "Auto-paused"],
    "tracker.location_permission_title_part1":  [.es: "Activa el\n",     .en: "Enable\n"],
    "tracker.location_permission_title_highlight": [.es: "GPS.",         .en: "GPS."],
    "tracker.location_permission_body":  [.es: "PacePal usa tu ubicación para medir distancia y ritmo en tiempo real al correr al aire libre.", .en: "PacePal uses your location to measure distance and pace in real time when running outdoors."],
    "tracker.location_permission_allow": [.es: "Activar GPS",           .en: "Enable GPS"],
    "tracker.location_permission_cancel":[.es: "Mejor no",              .en: "Not now"],
    "tracker.motion_permission_title_part1":  [.es: "Corre en\n",        .en: "Run\n"],
    "tracker.motion_permission_title_highlight": [.es: "interiores.",   .en: "indoors."],
    "tracker.motion_permission_body":    [.es: "PacePal usa el podómetro de tu iPhone para medir distancia sin GPS.", .en: "PacePal uses your iPhone's pedometer to measure distance without GPS."],
    "tracker.motion_permission_allow":   [.es: "Activar podómetro",     .en: "Enable pedometer"],
    "tracker.motion_permission_cancel":  [.es: "Mejor no",              .en: "Not now"],
    "tracker.done":                    [.es: "Listo",                   .en: "Done"],
    "tracker.finish":                  [.es: "Detener",                 .en: "Stop"],
    "tracker.finish_confirm_title":    [.es: "¿Terminar carrera?",      .en: "Finish run?"],
    "tracker.finish_confirm_body":     [.es: "Se guardará la distancia recorrida.", .en: "The distance will be saved."],
    "tracker.finish_confirm_yes":      [.es: "Terminar",                .en: "Finish"],
    "tracker.finish_confirm_cancel":   [.es: "Cancelar",               .en: "Cancel"],
    "tracker.discard_confirm_title":   [.es: "¿Descartar carrera?",    .en: "Discard run?"],
    "tracker.discard_confirm_body":    [.es: "La distancia no se guardará.", .en: "The distance won't be saved."],
    "tracker.discard_confirm_yes":     [.es: "Descartar",              .en: "Discard"],
    "tracker.location_title":          [.es: "Ubicación necesaria",    .en: "Location needed"],
    "tracker.location_body":           [.es: "Activa la ubicación para medir tu distancia.", .en: "Enable location to measure your distance."],
    "tracker.location_open_settings":  [.es: "Abrir Ajustes",          .en: "Open Settings"],
    "tracker.location_cancel":         [.es: "Cancelar",               .en: "Cancel"],
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
    "share.button":             [.es: "Compartir",           .en: "Share"],
    "tip.dismiss":              [.es: "Entendido",           .en: "Got it"],
    "tip.badge":                [.es: "TIP DÍA %d",         .en: "DAY %d TIP"],
    "tip.section_title":        [.es: "Tips",                .en: "Tips"],
    "tip.locked":               [.es: "Día %d",              .en: "Day %d"],
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
    "home.day_complete_float":  [.es: "+1 día completado",            .en: "+1 day completed"],
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
    "settings.pattern":             [.es: "Patrón",            .en: "Pattern"],
    "settings.level_title":         [.es: "Nivel del reto",    .en: "Challenge level"],
    "settings.language_title":      [.es: "Idioma",            .en: "Language"],
    "settings.language_subtitle":   [.es: "Cambia el idioma de la app", .en: "Change app language"],
    "settings.language_auto":       [.es: "Automático (dispositivo)", .en: "Automatic (device)"],
]

// MARK: - Tutorial

private let _tutorial: [String: [AppLang: String]] = [
    "tutorial.energy_title": [.es: "Tu energía",    .en: "Your energy"],
    "tutorial.energy_body":  [.es: "Baja con el tiempo. Si llega a 0% tu compañero se agota y tendrás que elegir uno nuevo.",
                              .en: "Drops over time. If it reaches 0% your companion collapses and you'll have to choose a new one."],
    "tutorial.km_title":     [.es: "Kilómetros",    .en: "Kilometers"],
    "tutorial.km_body":      [.es: "Cada km suma %d%% de energía. Alcanza el mínimo diario de tu nivel para marcar el día como completado ✓",
                              .en: "Each km adds %d%% energy. Hit your level's daily minimum to mark the day as completed ✓"],
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
    "notif.critical_body":     [.es: "De inmediato, ¡está a punto de quedarse sin energía!", .en: "Right now, it's about to run out of energy!"],
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

// MARK: - Daily Tips (66 days)

private let _tips: [String: [AppLang: String]] = [
    // Days 1-10: Getting started / beginner advice
    "tip.1":  [.es: "Hoy solo tienes que salir. No importa la distancia, lo que importa es empezar.",
               .en: "Today you just have to get out. Distance doesn't matter, starting does."],
    "tip.2":  [.es: "Corre a un ritmo en el que puedas mantener una conversación. Si jadeas, ve más lento.",
               .en: "Run at a pace where you can hold a conversation. If you're gasping, slow down."],
    "tip.3":  [.es: "No te compares con nadie. Tu único rival es el tú de ayer.",
               .en: "Don't compare yourself to anyone. Your only rival is yesterday's you."],
    "tip.4":  [.es: "Caminar entre intervalos de carrera está perfecto. Es parte del proceso.",
               .en: "Walking between running intervals is perfectly fine. It's part of the process."],
    "tip.5":  [.es: "Elige una hora fija para correr cada día. La rutina crea el hábito.",
               .en: "Pick a fixed time to run each day. Routine builds the habit."],
    "tip.6":  [.es: "Tus zapatillas son tu herramienta más importante. Asegúrate de que sean cómodas.",
               .en: "Your shoes are your most important tool. Make sure they're comfortable."],
    "tip.7":  [.es: "Una semana corriendo. Tu cuerpo ya se está adaptando aunque no lo notes.",
               .en: "One week running. Your body is already adapting even if you don't notice."],
    "tip.8":  [.es: "Hidrátate antes de salir. Un vaso de agua 30 minutos antes marca la diferencia.",
               .en: "Hydrate before heading out. A glass of water 30 minutes before makes a difference."],
    "tip.9":  [.es: "Escucha a tu cuerpo. Si algo duele, no lo ignores, ajusta el ritmo.",
               .en: "Listen to your body. If something hurts, don't ignore it, adjust your pace."],
    "tip.10": [.es: "10 días seguidos. Estás construyendo algo grande. No pares.",
               .en: "10 days in a row. You're building something big. Don't stop."],

    // Days 11-20: Form, breathing, warm-up
    "tip.11": [.es: "Calienta al menos 3 minutos antes de correr. Tus músculos te lo agradecerán.",
               .en: "Warm up for at least 3 minutes before running. Your muscles will thank you."],
    "tip.12": [.es: "Intenta respirar por la nariz y exhalar por la boca. Encuentra tu ritmo respiratorio.",
               .en: "Try breathing in through your nose and out through your mouth. Find your breathing rhythm."],
    "tip.13": [.es: "Mantén los hombros relajados y las manos sueltas. La tensión gasta energía.",
               .en: "Keep your shoulders relaxed and hands loose. Tension wastes energy."],
    "tip.14": [.es: "Pasos cortos y frecuentes son mejor que zancadas largas. Cuida tus articulaciones.",
               .en: "Short, frequent steps are better than long strides. Protect your joints."],
    "tip.15": [.es: "Estira después de correr, nunca antes. Los músculos calientes se estiran mejor.",
               .en: "Stretch after running, never before. Warm muscles stretch better."],
    "tip.16": [.es: "Mira al frente, no al suelo. Tu postura mejora y respiras mejor.",
               .en: "Look ahead, not at the ground. Your posture improves and you breathe better."],
    "tip.17": [.es: "Si te cuesta respirar, prueba el patrón 3-2: tres pasos inhala, dos pasos exhala.",
               .en: "If breathing is hard, try the 3-2 pattern: three steps inhale, two steps exhale."],
    "tip.18": [.es: "Corre erguido, como si un hilo tirara de tu cabeza hacia arriba.",
               .en: "Run tall, as if a string is pulling your head upward."],
    "tip.19": [.es: "Un buen calentamiento incluye caminata rápida, rotación de tobillos y rodillas altas.",
               .en: "A good warm-up includes brisk walking, ankle rotations, and high knees."],
    "tip.20": [.es: "Ya llevas 20 días. La constancia es tu superpoder, y lo estás demostrando.",
               .en: "You're at 20 days. Consistency is your superpower, and you're proving it."],

    // Days 21-30: Nutrition, hydration, rest
    "tip.21": [.es: "Come algo ligero 1-2 horas antes de correr. Un plátano o unas tostadas van genial.",
               .en: "Eat something light 1-2 hours before running. A banana or toast works great."],
    "tip.22": [.es: "El descanso es parte del entrenamiento. Tus músculos se fortalecen mientras descansas.",
               .en: "Rest is part of training. Your muscles get stronger while you rest."],
    "tip.23": [.es: "Bebe agua durante todo el día, no solo antes de correr.",
               .en: "Drink water throughout the day, not just before running."],
    "tip.24": [.es: "Si sientes las piernas pesadas, un día de carrera suave está bien. No todo tiene que ser intenso.",
               .en: "If your legs feel heavy, an easy run day is fine. Not everything has to be intense."],
    "tip.25": [.es: "Mitad del reto. Cuida tu alimentación: proteínas para recuperar, carbohidratos para la energía.",
               .en: "Halfway there. Watch your nutrition: protein to recover, carbs for energy."],
    "tip.26": [.es: "Dormir bien es tan importante como correr. Apunta a 7-8 horas por noche.",
               .en: "Sleeping well is as important as running. Aim for 7-8 hours per night."],
    "tip.27": [.es: "Evita comidas pesadas justo antes de correr. Tu estómago necesita tranquilidad.",
               .en: "Avoid heavy meals right before running. Your stomach needs calm."],
    "tip.28": [.es: "Un mes corriendo. Tu metabolismo ya está cambiando. ¡Sigue así!",
               .en: "A month of running. Your metabolism is already changing. Keep it up!"],
    "tip.29": [.es: "Los días de descanso activo (caminar, estirar) ayudan a la recuperación sin perder el ritmo.",
               .en: "Active rest days (walking, stretching) help recovery without losing momentum."],
    "tip.30": [.es: "Si corres de mañana, un café 30 minutos antes puede darte un buen impulso.",
               .en: "If you run in the morning, a coffee 30 minutes before can give you a nice boost."],

    // Days 31-40: Injury prevention, weather, gear
    "tip.31": [.es: "Revisa tus zapatillas. Si tienen más de 500 km, considera cambiarlas.",
               .en: "Check your shoes. If they have more than 500 km, consider replacing them."],
    "tip.32": [.es: "En días de calor, corre temprano o al atardecer. Evita las horas de sol fuerte.",
               .en: "On hot days, run early or at sunset. Avoid peak sun hours."],
    "tip.33": [.es: "Fortalece tobillos y rodillas con ejercicios simples. La prevención es la mejor medicina.",
               .en: "Strengthen ankles and knees with simple exercises. Prevention is the best medicine."],
    "tip.34": [.es: "Vístete como si hiciera 10 grados más de lo que marca el termómetro. Entrarás en calor rápido.",
               .en: "Dress as if it's 10 degrees warmer than the thermometer says. You'll warm up fast."],
    "tip.35": [.es: "Si llueve, no te detengas. Correr bajo la lluvia puede ser una experiencia increíble.",
               .en: "If it rains, don't stop. Running in the rain can be an amazing experience."],
    "tip.36": [.es: "Usa ropa transpirable. El algodón absorbe el sudor y te hace sentir más pesado.",
               .en: "Wear breathable clothes. Cotton absorbs sweat and makes you feel heavier."],
    "tip.37": [.es: "Si sientes un tirón, para y estira suavemente. Forzar una lesión nunca vale la pena.",
               .en: "If you feel a pull, stop and stretch gently. Forcing an injury is never worth it."],
    "tip.38": [.es: "Varía tus rutas. Terrenos diferentes fortalecen músculos diferentes.",
               .en: "Vary your routes. Different terrains strengthen different muscles."],
    "tip.39": [.es: "En días fríos, calienta un poco más antes de salir. Los músculos fríos se lesionan más fácil.",
               .en: "On cold days, warm up a bit longer. Cold muscles are more prone to injury."],
    "tip.40": [.es: "40 días. Más de la mitad del camino. Tu cuerpo y mente ya son de corredor.",
               .en: "40 days. More than halfway. Your body and mind are already those of a runner."],

    // Days 41-50: Speed, distance, mental game
    "tip.41": [.es: "Prueba a variar tu ritmo: 1 minuto rápido, 2 minutos suave. Así ganas velocidad.",
               .en: "Try varying your pace: 1 minute fast, 2 minutes easy. That's how you gain speed."],
    "tip.42": [.es: "Cuando la mente diga 'para', responde con 'un minuto más'. Siempre puedes dar un poco más.",
               .en: "When your mind says 'stop', answer with 'one more minute'. You can always give a bit more."],
    "tip.43": [.es: "Aumenta la distancia gradualmente. No más del 10% por semana para evitar lesiones.",
               .en: "Increase distance gradually. No more than 10% per week to avoid injuries."],
    "tip.44": [.es: "Corre con música que te motive. El ritmo correcto puede hacerte volar.",
               .en: "Run with music that motivates you. The right beat can make you fly."],
    "tip.45": [.es: "En las subidas, acorta el paso y mantén el esfuerzo. No intentes mantener el mismo ritmo.",
               .en: "On hills, shorten your stride and maintain effort. Don't try to keep the same pace."],
    "tip.46": [.es: "Visualiza la meta antes de salir. Verte cruzando la línea te da poder mental.",
               .en: "Visualize the finish before heading out. Seeing yourself crossing the line gives mental power."],
    "tip.47": [.es: "Los días malos también cuentan. Salir cuando no quieres es donde se forja el hábito.",
               .en: "Bad days count too. Going out when you don't want to is where the habit is forged."],
    "tip.48": [.es: "Enfócate en el esfuerzo, no en la velocidad. El progreso viene solo.",
               .en: "Focus on effort, not speed. Progress will come on its own."],
    "tip.49": [.es: "Siete semanas corriendo. La mayoría hubiera abandonado. Tú sigues aquí.",
               .en: "Seven weeks running. Most would have quit. You're still here."],
    "tip.50": [.es: "Prueba correr sin música un día. Escucha tu respiración y tus pasos. Es meditación en movimiento.",
               .en: "Try running without music one day. Listen to your breathing and steps. It's meditation in motion."],

    // Days 51-58: Cool-down, advanced tips, mindset
    "tip.51": [.es: "Después de correr, camina 5 minutos para enfriar. Tu corazón te lo agradecerá.",
               .en: "After running, walk 5 minutes to cool down. Your heart will thank you."],
    "tip.52": [.es: "Estira los cuádriceps, gemelos e isquiotibiales después de cada carrera. Solo 5 minutos bastan.",
               .en: "Stretch your quads, calves, and hamstrings after every run. Just 5 minutes is enough."],
    "tip.53": [.es: "Corre por sensaciones, no solo por números. Tu cuerpo sabe más que el reloj.",
               .en: "Run by feel, not just by numbers. Your body knows more than the watch."],
    "tip.54": [.es: "Un rodillo de espuma después de correr ayuda a soltar la tensión muscular.",
               .en: "A foam roller after running helps release muscle tension."],
    "tip.55": [.es: "Solo 11 días más. Ya eres un corredor. Esto ya no es un reto, es tu estilo de vida.",
               .en: "Only 11 days left. You're already a runner. This is no longer a challenge, it's your lifestyle."],
    "tip.56": [.es: "El enfriamiento es tan importante como el calentamiento. No lo saltes.",
               .en: "Cooling down is as important as warming up. Don't skip it."],
    "tip.57": [.es: "Cuando termines de correr, respira profundo 5 veces. Calma tu sistema nervioso.",
               .en: "When you finish running, take 5 deep breaths. Calm your nervous system."],
    "tip.58": [.es: "Celebra cada salida, no solo las marcas personales. Salir ya es ganar.",
               .en: "Celebrate every outing, not just personal records. Showing up is winning."],

    // Days 59-66: Celebration, milestones, looking ahead
    "tip.59": [.es: "Piensa en cómo te sentías el día 1. Mira cuánto has crecido desde entonces.",
               .en: "Think about how you felt on day 1. Look how much you've grown since then."],
    "tip.60": [.es: "Comparte tu progreso con alguien. Inspirar a otros multiplica tu logro.",
               .en: "Share your progress with someone. Inspiring others multiplies your achievement."],
    "tip.61": [.es: "Solo 5 días más. Cada kilómetro que corras ahora es pura victoria.",
               .en: "Just 5 more days. Every kilometer you run now is pure victory."],
    "tip.62": [.es: "Correr ya es parte de ti. Cuando terminen los 66 días, no vas a querer parar.",
               .en: "Running is already part of you. When the 66 days end, you won't want to stop."],
    "tip.63": [.es: "Piensa en tu próximo objetivo después del reto. Una carrera de 5K, quizás.",
               .en: "Think about your next goal after the challenge. A 5K race, maybe."],
    "tip.64": [.es: "A dos días del final. Lo que construiste nadie te lo quita.",
               .en: "Two days from the end. What you built, no one can take away."],
    "tip.65": [.es: "Mañana es el último día. Pero el hábito que creaste es para siempre.",
               .en: "Tomorrow is the last day. But the habit you created is forever."],
    "tip.66": [.es: "Día 66. Lo lograste. No fue fácil, pero lo hiciste. Ahora sigue corriendo, porque esto es solo el comienzo.",
               .en: "Day 66. You did it. It wasn't easy, but you made it. Now keep running, because this is just the beginning."],
]

private let _tipDetails: [String: [AppLang: String]] = [
    // Days 1-10
    "tip.1.detail": [
        .es: "No necesitas correr **5 km** ni batir ningún récord. Solo **ponte los tenis**, sal por la puerta y muévete. Aunque sean **500 metros** caminando rápido, hoy cuenta. **El primer paso siempre es el más difícil**, y ya lo diste.",
        .en: "You don't need to run **5K** or break any record. Just **lace up your shoes**, step outside, and move. Even if it's **500 meters** of brisk walking, today counts. **The first step is always the hardest**, and you already took it."
    ],
    "tip.2.detail": [
        .es: "Esto se llama **ritmo conversacional** y es la base del running. Si puedes hablar con alguien mientras corres, vas a un buen ritmo. Si no puedes terminar una frase sin ahogarte, **bájale**. No hay prisa, tu resistencia se construye **poco a poco**.",
        .en: "This is called **conversational pace** and it's the foundation of running. If you can talk to someone while running, you're at a good pace. If you can't finish a sentence without gasping, **slow down**. There's no rush, your endurance builds **little by little**."
    ],
    "tip.3.detail": [
        .es: "Es natural ver a otros corredores y sentir que vas lento. Pero **cada cuerpo es diferente** y cada uno empezó en un momento distinto. Lo que importa es que hoy puedes hacer algo que hace una semana no hacías. **Ese es tu progreso real**.",
        .en: "It's natural to see other runners and feel like you're slow. But **every body is different** and everyone started at a different time. What matters is that today you can do something you couldn't a week ago. **That's your real progress**."
    ],
    "tip.4.detail": [
        .es: "Muchos corredores profesionales empezaron con **intervalos de caminar y trotar**. No es trampa, es estrategia. Prueba correr **2 minutos** y caminar **1**, o lo que te resulte cómodo. Con el tiempo esos intervalos serán más largos **de forma natural**.",
        .en: "Many professional runners started with **walk-jog intervals**. It's not cheating, it's strategy. Try running **2 minutes** and walking **1**, or whatever feels comfortable. Over time those running intervals will **naturally get longer**."
    ],
    "tip.5.detail": [
        .es: "Tu cerebro necesita asociar **un momento del día** con correr para que se vuelva automático. Puede ser al despertar, a la hora de la comida o al salir del trabajo. Lo importante es que sea **el mismo horario todos los días**. Después de unas semanas, tu cuerpo ya lo pedirá solo.",
        .en: "Your brain needs to associate **a time of day** with running for it to become automatic. It can be when you wake up, at lunch, or after work. The key is **the same time every day**. After a few weeks, your body will ask for it on its own."
    ],
    "tip.6.detail": [
        .es: "No necesitas las más caras ni las de moda. Necesitas unas que **se ajusten bien a tu pie**, con buen soporte y amortiguación. Ve a una **tienda especializada** si puedes. Un buen par de zapatillas **previene lesiones** y hace que correr sea mucho más agradable.",
        .en: "You don't need the most expensive or trendiest ones. You need shoes that **fit your foot well**, with good support and cushioning. Visit a **specialty store** if you can. A good pair of shoes **prevents injuries** and makes running much more enjoyable."
    ],
    "tip.7.detail": [
        .es: "Aunque tus piernas sientan algo de dolor, es normal. Tu **sistema cardiovascular** ya está mejorando, tus músculos están creando **nuevas fibras** y tu cerebro está liberando **endorfinas** con más facilidad. La adaptación lleva tiempo, pero ya empezó. **Confía en el proceso**.",
        .en: "Even if your legs feel some soreness, that's normal. Your **cardiovascular system** is already improving, your muscles are building **new fibers**, and your brain is releasing **endorphins** more easily. Adaptation takes time, but it's already started. **Trust the process**."
    ],
    "tip.8.detail": [
        .es: "La deshidratación reduce tu rendimiento y aumenta el riesgo de **calambres**. No esperes a tener sed para tomar agua. Un vaso de agua **media hora antes** de salir prepara tu cuerpo. Si corres más de **30 minutos**, lleva agua contigo o planea una ruta con fuentes.",
        .en: "Dehydration reduces your performance and increases the risk of **cramps**. Don't wait until you're thirsty to drink water. A glass of water **half an hour before** heading out prepares your body. If you run for more than **30 minutes**, bring water or plan a route with fountains."
    ],
    "tip.9.detail": [
        .es: "Hay una diferencia entre el **dolor muscular normal** de adaptación y una molestia que indica lesión. El primero es general y mejora al calentar. El segundo es **agudo, puntual y empeora** al correr. Si sientes el segundo, baja el ritmo. **Un día de precaución puede salvarte semanas**.",
        .en: "There's a difference between **normal muscle soreness** from adaptation and discomfort that signals injury. The first is general and improves as you warm up. The second is **sharp, localized, and worsens** with running. If you feel the latter, slow down. **One day of caution can save you weeks**."
    ],
    "tip.10.detail": [
        .es: "**Diez días** puede no sonar a mucho, pero estadísticamente la mayoría de la gente abandona antes de llegar aquí. **Tú no**. Estás en el grupo de los que persisten, y eso dice mucho de tu carácter. Cada día que sumas hace **más fuerte tu hábito**.",
        .en: "**Ten days** might not sound like much, but statistically most people quit before reaching this point. **You didn't**. You're in the group that persists, and that says a lot about your character. Every day you add makes **your habit stronger**."
    ],

    // Days 11-20
    "tip.11.detail": [
        .es: "Un calentamiento prepara tus **articulaciones**, eleva tu temperatura corporal y aumenta el **flujo sanguíneo** a los músculos. Puedes caminar rápido, hacer rotaciones de tobillos o rodillas altas. Solo **3 minutos** reducen mucho el riesgo de molestias.",
        .en: "A warm-up prepares your **joints**, raises your body temperature, and increases **blood flow** to your muscles. You can walk briskly, do ankle rotations, or high knees. Just **3 minutes** greatly reduce the risk of discomfort."
    ],
    "tip.12.detail": [
        .es: "La respiración es algo que muchos corredores principiantes ignoran. No hay una fórmula perfecta, pero **inhalar por la nariz** filtra y calienta el aire, mientras **exhalar por la boca** ayuda a soltar el CO2 rápido. Experimenta y encuentra lo que te funcione mejor.",
        .en: "Breathing is something many beginner runners overlook. There's no perfect formula, but **inhaling through your nose** filters and warms the air, while **exhaling through your mouth** helps release CO2 quickly. Experiment and find what works best for you."
    ],
    "tip.13.detail": [
        .es: "Cuando te cansas, el cuerpo tiende a tensarse: subes los hombros, aprietas los puños, frunces el ceño. Todo eso **consume energía** que podrías usar para correr. De vez en cuando, **sacude las manos**, baja los hombros y **relaja la mandíbula**.",
        .en: "When you get tired, your body tends to tense up: you raise your shoulders, clench your fists, furrow your brow. All of that **burns energy** you could use for running. Every now and then, **shake your hands**, lower your shoulders, and **relax your jaw**."
    ],
    "tip.14.detail": [
        .es: "Las zancadas largas ponen más impacto en tus rodillas. **Pasos más cortos y rápidos** (cadencia alta) distribuyen mejor la fuerza y **reducen lesiones**. Intenta que tus pies aterricen **debajo de tu cuerpo**, no por delante. Se siente raro al principio pero tu cuerpo lo agradecerá.",
        .en: "Long strides put more impact on your knees. **Shorter, quicker steps** (high cadence) distribute force better and **reduce injuries**. Try to land your feet **under your body**, not in front. It feels weird at first but your body will thank you."
    ],
    "tip.15.detail": [
        .es: "Estirar músculos fríos puede causar **micro-desgarros**. Después de correr, tus músculos están **calientes y flexibles**, que es el momento perfecto para estirar. Enfócate en pantorrillas, cuádriceps, isquiotibiales y cadera. Mantén cada estiramiento **20-30 segundos** sin rebotar.",
        .en: "Stretching cold muscles can cause **micro-tears**. After running, your muscles are **warm and flexible**, the perfect time to stretch. Focus on calves, quads, hamstrings, and hips. Hold each stretch for **20-30 seconds** without bouncing."
    ],
    "tip.16.detail": [
        .es: "Tu cabeza pesa unos **5 kg**. Si la inclinas hacia abajo, todo tu torso se encorva y respiras peor. Mantén la **mirada al horizonte**, el pecho abierto y los hombros atrás. Notarás que puedes **respirar más profundo** y correr con menos esfuerzo.",
        .en: "Your head weighs about **5 kg**. If you tilt it down, your whole torso hunches and you breathe worse. Keep your **gaze on the horizon**, chest open, and shoulders back. You'll notice you can **breathe deeper** and run with less effort."
    ],
    "tip.17.detail": [
        .es: "El **patrón 3-2** sincroniza tu respiración con tus pasos. Inhala durante **tres pasos**, exhala durante **dos**. Esto te da un ritmo constante y distribuye mejor el esfuerzo. Si 3-2 es mucho, prueba **2-2** o **2-1**.",
        .en: "The **3-2 pattern** syncs your breathing with your steps. Inhale for **three steps**, exhale for **two**. This gives you a steady rhythm and distributes effort better. If 3-2 is too much, try **2-2** or **2-1**."
    ],
    "tip.18.detail": [
        .es: "Imagina que alguien tira de un **hilo invisible** desde la coronilla de tu cabeza. Eso alinea tu columna, abre tu pecho y permite que tu **diafragma** trabaje bien. **Una postura neutral** es la más eficiente para correr.",
        .en: "Imagine someone pulling an **invisible string** from the crown of your head. That aligns your spine, opens your chest, and lets your **diaphragm** work properly. **A neutral posture** is the most efficient for running."
    ],
    "tip.19.detail": [
        .es: "Empieza caminando rápido **1-2 minutos**, luego haz **10 rotaciones** de cada tobillo, **10 elevaciones** de rodilla y algunos balanceos de pierna. Esto **activa los músculos** y lubrica las articulaciones. Un buen calentamiento puede ser la diferencia entre una buena carrera y una molestia.",
        .en: "Start with **1-2 minutes** of brisk walking, then do **10 rotations** of each ankle, **10 knee raises**, and some leg swings. This **activates your muscles** and lubricates your joints. A good warm-up can be the difference between a great run and discomfort."
    ],
    "tip.20.detail": [
        .es: "**Tres semanas** creando un hábito. Los científicos dicen que toma **21 días** formar uno, pero la ciencia real dice que para hábitos complejos como correr se necesitan más cerca de **66 días**. Por eso estás aquí. **Vas por buen camino**.",
        .en: "**Three weeks** building a habit. Scientists say it takes **21 days** to form one, but real science says complex habits like running need closer to **66 days**. That's why you're here. **You're on the right track**."
    ],

    // Days 21-30
    "tip.21.detail": [
        .es: "Correr con el estómago vacío puede dejarte sin energía. Pero comer demasiado te dará malestar. Un **snack ligero** como un plátano, unas tostadas con miel o frutos secos **1-2 horas antes** es lo ideal. **Encuentra lo que le funciona a tu cuerpo**.",
        .en: "Running on an empty stomach can leave you out of energy. But eating too much will cause discomfort. A **light snack** like a banana, toast with honey, or nuts **1-2 hours before** is ideal. **Find what works for your body**."
    ],
    "tip.22.detail": [
        .es: "Tus músculos no se fortalecen mientras corres, sino **mientras descansas**. Durante el descanso se reparan las micro-fibras rotas y se reconstruyen **más fuertes**. Un día sin correr **no es perder el tiempo**, es invertir en tu progreso.",
        .en: "Your muscles don't get stronger while running, but **while resting**. During rest, broken micro-fibers repair and rebuild **stronger**. A day without running **isn't wasting time**, it's investing in your progress."
    ],
    "tip.23.detail": [
        .es: "Tu cuerpo necesita agua para **regular la temperatura**, transportar nutrientes y eliminar desechos. Si solo bebes antes de correr, llegas con un **déficit acumulado**. Lleva una botella contigo durante el día y toma **sorbos regulares**.",
        .en: "Your body needs water to **regulate temperature**, transport nutrients, and eliminate waste. If you only drink before running, you arrive with an **accumulated deficit**. Carry a bottle with you during the day and take **regular sips**."
    ],
    "tip.24.detail": [
        .es: "No todas las carreras tienen que ser intensas. Los corredores experimentados **alternan días duros con días suaves**. Si tus piernas están pesadas, haz una carrera **corta y lenta**. El objetivo es **mantener el hábito activo** sin castigar tu cuerpo.",
        .en: "Not every run has to be intense. Experienced runners **alternate hard days with easy days**. If your legs feel heavy, do a **short, slow run**. The goal is **keeping the habit alive** without punishing your body."
    ],
    "tip.25.detail": [
        .es: "A estas alturas tu cuerpo gasta más energía. Las **proteínas** (pollo, huevo, legumbres) reparan los músculos. Los **carbohidratos** (arroz, pasta, fruta) te dan energía. No necesitas una dieta especial, solo come **variado y suficiente**.",
        .en: "At this point your body spends more energy. **Proteins** (chicken, eggs, legumes) repair muscles. **Carbs** (rice, pasta, fruit) give you energy. You don't need a special diet, just eat **varied and enough**."
    ],
    "tip.26.detail": [
        .es: "El sueño es cuando tu cuerpo produce **hormona del crecimiento**, repara tejidos y consolida la **memoria muscular**. Dormir mal se nota: piernas pesadas, mente lenta, menos motivación. Prioriza **7-8 horas** de sueño como priorizas tu carrera.",
        .en: "Sleep is when your body produces **growth hormone**, repairs tissue, and consolidates **muscle memory**. Poor sleep shows: heavy legs, slow mind, less motivation. Prioritize **7-8 hours** of sleep like you prioritize your run."
    ],
    "tip.27.detail": [
        .es: "Una comida pesada tarda **2-3 horas** en digerirse. Si corres con el estómago lleno, la sangre se queda en el sistema digestivo. Resultado: **calambres, náuseas** y una carrera miserable. Come ligero o espera al menos **2 horas** después de una comida grande.",
        .en: "A heavy meal takes **2-3 hours** to digest. If you run with a full stomach, blood stays in your digestive system. Result: **cramps, nausea**, and a miserable run. Eat light or wait at least **2 hours** after a big meal."
    ],
    "tip.28.detail": [
        .es: "**Un mes** es un logro enorme. Tu corazón bombea **más sangre** por latido, tus pulmones absorben **más oxígeno**, tus mitocondrias son más eficientes. Aunque no lo veas en el espejo, por dentro **tu cuerpo es una máquina diferente**.",
        .en: "**One month** is a huge achievement. Your heart pumps **more blood** per beat, your lungs absorb **more oxygen**, your mitochondria are more efficient. Even if you don't see it in the mirror, inside **your body is a different machine**."
    ],
    "tip.29.detail": [
        .es: "El **descanso activo** mantiene la circulación sin el impacto de correr. Una caminata de **20 minutos**, estiramientos suaves o yoga ligero ayudan a recuperarte **más rápido** que quedarte en el sofá. **Moverte sin esfuerzo** es la mejor receta.",
        .en: "**Active rest** keeps circulation going without the impact of running. A **20-minute walk**, gentle stretching, or light yoga help you recover **faster** than staying on the couch. **Moving without strain** is the best recipe."
    ],
    "tip.30.detail": [
        .es: "La **cafeína** mejora el rendimiento: aumenta el estado de alerta y reduce la percepción de esfuerzo. Un café solo **30 minutos antes** puede hacer que tu carrera se sienta más fácil. Pero no exageres: demasiada cafeína causa **ansiedad y deshidratación**.",
        .en: "**Caffeine** improves performance: it increases alertness and reduces perceived effort. A black coffee **30 minutes before** can make your run feel easier. But don't overdo it: too much caffeine causes **anxiety and dehydration**."
    ],

    // Days 31-40
    "tip.31.detail": [
        .es: "Las zapatillas pierden **amortiguación** con el uso, aunque se vean bien por fuera. Después de **500-700 km**, la espuma ya no absorbe el impacto igual. Si notas más dolor en rodillas o espinillas, puede ser señal de que **es hora de cambiarlas**.",
        .en: "Running shoes lose **cushioning** with use, even if they look fine outside. After **500-700 km**, the foam no longer absorbs impact the same way. If you notice more knee or shin pain, it might be a sign **it's time to replace them**."
    ],
    "tip.32.detail": [
        .es: "El **calor extremo** fuerza a tu cuerpo a enfriar la piel y mover los músculos al mismo tiempo. Corre **temprano** (antes de las 9) o al **atardecer** (después de las 7). Si no puedes evitar el calor, **baja el ritmo y lleva agua**.",
        .en: "**Extreme heat** forces your body to cool your skin and power your muscles simultaneously. Run **early** (before 9 AM) or at **sunset** (after 7 PM). If you can't avoid the heat, **slow down and carry water**."
    ],
    "tip.33.detail": [
        .es: "Correr fortalece los músculos grandes pero puede dejar débiles los **estabilizadores**. Ejercicios como elevaciones de talón y sentadillas a una pierna toman solo **5 minutos**. Hazlos **2-3 veces por semana** y tus articulaciones te lo agradecerán.",
        .en: "Running strengthens large muscles but can leave **stabilizers** weak. Exercises like heel raises and single-leg squats take just **5 minutes**. Do them **2-3 times a week** and your joints will thank you."
    ],
    "tip.34.detail": [
        .es: "Al correr generas calor rápidamente. Si te abrigas demasiado, terminarás sudando en exceso. La **regla de los 10 grados** funciona: si afuera hay 15°C, vístete como si hubiera 25°C. En los primeros minutos sentirás frío, pero **pronto estarás perfecto**.",
        .en: "When you start running, you generate heat quickly. If you overdress, you'll sweat too much. The **10-degree rule** works: if it's 15°C outside, dress as if it's 25°C. You'll feel cold at first, but **soon you'll be just right**."
    ],
    "tip.35.detail": [
        .es: "Muchos corredores descubren que **la lluvia es su clima favorito**. El aire es más fresco, hay menos gente y la sensación de **libertad es única**. Solo asegúrate de usar ropa que no absorba agua y ten cuidado con superficies resbalosas.",
        .en: "Many runners discover that **rain is their favorite weather**. The air is cooler, fewer people around, and the feeling of **freedom is unique**. Just make sure to wear clothes that don't absorb water and be careful on slippery surfaces."
    ],
    "tip.36.detail": [
        .es: "Las **telas técnicas** (poliéster, nylon) mueven el sudor lejos de tu piel, manteniéndote seco. El **algodón** absorbe la humedad y la retiene, te hace sentir pesado y causa rozaduras. **Vale la pena invertir en ropa técnica**.",
        .en: "**Technical fabrics** (polyester, nylon) wick sweat away from your skin, keeping you dry. **Cotton** absorbs moisture and holds it, making you feel heavy and causing chafing. **It's worth investing in technical clothing**."
    ],
    "tip.37.detail": [
        .es: "Un tirón muscular es una **señal de alerta**, no un reto a superar. Si sigues corriendo, un desgarro menor puede convertirse en uno mayor. **Para, estira suave, camina a casa**. Más vale **un día perdido que un mes** de recuperación.",
        .en: "A muscle pull is a **warning signal**, not a challenge to overcome. If you keep running, a minor tear can become a major one. **Stop, stretch gently, walk home**. Better **one lost day than a month** of recovery."
    ],
    "tip.38.detail": [
        .es: "Correr siempre por la misma ruta trabaja los mismos músculos. Cambiar a un parque con subidas, un **sendero de tierra** o correr en dirección contraria **activa músculos diferentes**. Además, las **rutas nuevas** mantienen tu mente estimulada.",
        .en: "Always running the same route works the same muscles. Switching to a park with hills, a **dirt trail**, or running in reverse **activates different muscles**. Plus, **new routes** keep your mind stimulated."
    ],
    "tip.39.detail": [
        .es: "Los músculos fríos son **menos elásticos** y más propensos a desgarros. En días fríos, dedica **5-7 minutos** al calentamiento en vez de los 3 habituales. Empieza dentro de casa con movimientos articulares, luego **camina rápido antes de trotar**.",
        .en: "Cold muscles are **less elastic** and more prone to tears. On cold days, spend **5-7 minutes** warming up instead of the usual 3. Start indoors with joint movements, then **walk briskly before jogging**."
    ],
    "tip.40.detail": [
        .es: "**40 días** de carrera continua es algo que **menos del 5%** de la gente logra. Tu capacidad pulmonar ha mejorado, tu frecuencia cardíaca ha bajado, tus piernas son más fuertes. **Ya no estás probando si puedes. Ya lo estás haciendo**.",
        .en: "**40 consecutive days** of running is something **less than 5%** of people achieve. Your lung capacity has improved, your heart rate has dropped, your legs are stronger. **You're no longer testing if you can. You're already doing it**."
    ],

    // Days 41-50
    "tip.41.detail": [
        .es: "Los **intervalos** son la forma más eficiente de mejorar tu velocidad. Corre rápido un rato corto, descansa trotando, y repite. Tu corazón aprende a bombear **más sangre**, tus músculos a usar **más oxígeno** y tu ritmo mejora sin que te des cuenta.",
        .en: "**Intervals** are the most efficient way to improve your speed. Run fast for a short burst, recover by jogging, and repeat. Your heart learns to pump **more blood**, your muscles to use **more oxygen**, and your pace improves without you noticing."
    ],
    "tip.42.detail": [
        .es: "La **fatiga mental** llega antes que la física. Cuando tu cerebro dice que ya no puedes, tu cuerpo generalmente tiene un **40% más** de capacidad. Un minuto más entrena tu **voluntad** tanto como tus piernas. **No te rindas al primer instinto de parar**.",
        .en: "**Mental fatigue** arrives before physical fatigue. When your brain says you're done, your body usually has **40% more** capacity. One more minute trains your **willpower** as much as your legs. **Don't give in to the first instinct to stop**."
    ],
    "tip.43.detail": [
        .es: "La **regla del 10%** es un principio probado. Si esta semana corriste **10 km**, la siguiente no deberías pasar de **11 km**. Aumentos bruscos son la causa número uno de **lesiones por sobreuso**. La paciencia aquí es **velocidad a largo plazo**.",
        .en: "The **10% rule** is a proven principle. If you ran **10 km** this week, next week don't go over **11 km**. Sudden increases are the number one cause of **overuse injuries**. Patience here is **long-term speed**."
    ],
    "tip.44.detail": [
        .es: "La música con **150-180 BPM** coincide con una cadencia ideal de running. Canciones rápidas te energizan en los intervalos y las lentas te ayudan a recuperar. **Crea una playlist** para correr y notarás cómo tu cuerpo **se sincroniza con el ritmo**.",
        .en: "Music at **150-180 BPM** matches an ideal running cadence. Fast songs energize you during intervals and slow ones help recovery. **Create a playlist** for running and notice how your body **syncs with the beat**."
    ],
    "tip.45.detail": [
        .es: "En las subidas, tu instinto es mantener el mismo ritmo, pero eso dispara tu frecuencia cardíaca. **Acorta el paso**, inclínate ligeramente hacia adelante y mantén el mismo **nivel de esfuerzo**, no de velocidad. **Llegarás arriba con energía**.",
        .en: "On hills, your instinct is to keep the same pace, but that spikes your heart rate. **Shorten your stride**, lean slightly forward, and maintain the same **effort level**, not speed. **You'll reach the top with energy**."
    ],
    "tip.46.detail": [
        .es: "La **visualización** activa las mismas redes neuronales que la acción real. Antes de salir, cierra los ojos **30 segundos** e imagínate corriendo fuerte y sintiéndote ligero. Este **ejercicio mental** te prepara para rendir **mejor de lo que crees**.",
        .en: "**Visualization** activates the same neural networks as the real action. Before heading out, close your eyes for **30 seconds** and imagine yourself running strong and feeling light. This **mental exercise** prepares you to perform **better than you think**."
    ],
    "tip.47.detail": [
        .es: "Cualquiera puede correr cuando se siente motivado. **El verdadero hábito** se construye en los días de lluvia, cansancio o flojera. Cuando sales a pesar de las excusas, le dices a tu cerebro que **esto no es opcional**. Esos son los días que **más cuentan**.",
        .en: "Anyone can run on days they feel motivated. **The real habit** is built on rainy, tired, or lazy days. When you head out despite the excuses, you're telling your brain **this isn't optional**. Those are the days that **count the most**."
    ],
    "tip.48.detail": [
        .es: "Obsesionarse con el reloj genera **ansiedad** y te hace correr en tensión. **Corre por cómo te sientes**: si hoy te sientes bien, fluye. Si estás cansado, sé gentil. El cuerpo no rinde igual todos los días. **La velocidad viene con la constancia**.",
        .en: "Obsessing over the clock creates **anxiety** and makes you run tense. **Run by how you feel**: if today feels good, flow. If you're tired, be gentle. Your body doesn't perform the same every day. **Speed comes with consistency**."
    ],
    "tip.49.detail": [
        .es: "**Siete semanas** es más de lo que la mayoría de programas para principiantes duran. Piensa en todos los días que no querías salir y **lo hiciste de todas formas**. Esa disciplina se traslada a todo en tu vida. Correr te hace **más fuerte como persona**.",
        .en: "**Seven weeks** is longer than most beginner programs last. Think about all the days you didn't want to go out and **did it anyway**. That discipline transfers to everything in your life. Running makes you **stronger as a person**."
    ],
    "tip.50.detail": [
        .es: "Sin música, audiolibros ni podcasts, solo quedan tus pensamientos, tu respiración y tus pisadas. Es una forma de **mindfulness** que muchos corredores avanzados practican. Te conecta con tu cuerpo y puedes descubrir un **ritmo interior** que no sabías que tenías.",
        .en: "Without music, audiobooks, or podcasts, all that's left is your thoughts, your breathing, and your footsteps. It's a form of **mindfulness** that many advanced runners practice. It connects you with your body and you may discover an **inner rhythm** you didn't know you had."
    ],

    // Days 51-58
    "tip.51.detail": [
        .es: "Parar de golpe hace que la sangre se acumule en las piernas, causando **mareos**. Caminar **5 minutos** permite que tu frecuencia cardíaca baje gradualmente. Piénsalo como aterrizar un avión: **necesitas una pista de desaceleración**.",
        .en: "Stopping suddenly causes blood to pool in your legs, causing **dizziness**. Walking for **5 minutes** lets your heart rate come down gradually. Think of it like landing a plane: **you need a deceleration runway**."
    ],
    "tip.52.detail": [
        .es: "**Cuádriceps**, isquiotibiales, **gemelos** y cadera son los cuatro grupos que más trabajan al correr. Estirar cada uno **30 segundos** después de la carrera reduce la **rigidez del día siguiente** y mejora tu rango de movimiento con el tiempo.",
        .en: "**Quads**, hamstrings, **calves**, and hips are the four groups that work hardest when running. Stretching each for **30 seconds** after your run reduces **next-day stiffness** and improves your range of motion over time."
    ],
    "tip.53.detail": [
        .es: "Los números (ritmo, distancia, calorías) son útiles a largo plazo, pero no deberían dictar cada carrera. Tu **percepción del esfuerzo** es un indicador muy confiable. Aprende a **escuchar las señales de tu cuerpo** y ajusta tu rendimiento de forma intuitiva.",
        .en: "Numbers (pace, distance, calories) are useful long-term, but shouldn't dictate every run. Your **perceived effort** is a very reliable indicator. Learn to **listen to your body's signals** and adjust your performance intuitively."
    ],
    "tip.54.detail": [
        .es: "El **rodillo de espuma** aplica presión sobre los tejidos blandos, liberando nudos y mejorando la circulación. Pásalo por pantorrillas, cuádriceps e isquiotibiales durante **1-2 minutos** por grupo. Puede doler un poco, pero **el alivio vale la pena**.",
        .en: "A **foam roller** applies pressure on soft tissue, releasing knots and improving circulation. Roll over calves, quads, and hamstrings for **1-2 minutes** per group. It might hurt a bit, but **the relief is worth it**."
    ],
    "tip.55.detail": [
        .es: "La mayoría empieza cosas y no las termina. Tú estás a **11 días** de completar un desafío que cambia la vida. Ya corres sin pensarlo, tu cuerpo lo espera y tu mente lo necesita. Correr **ya es parte de quién eres**.",
        .en: "Most people start things and don't finish them. You're **11 days** from completing a life-changing challenge. You already run without thinking, your body expects it, and your mind needs it. Running **is already part of who you are**."
    ],
    "tip.56.detail": [
        .es: "Mucha gente termina de correr y se tumba. Pero tu cuerpo necesita una **transición**. Caminar unos minutos y estirar suave ayuda a evacuar el **ácido láctico**, reduce la inflamación y **acelera la recuperación**. Dale a tu cuerpo ese respeto.",
        .en: "Many people finish running and lie down. But your body needs a **transition**. Walking a few minutes and stretching helps clear **lactic acid**, reduces inflammation, and **speeds up recovery**. Give your body that respect."
    ],
    "tip.57.detail": [
        .es: "Después de correr, tu sistema nervioso está acelerado. **Cinco respiraciones profundas** activan el sistema parasimpático: el modo de **descanso y recuperación**. Inhala **4 segundos**, sostén **4**, exhala **6**. Sentirás la diferencia al instante.",
        .en: "After running, your nervous system is revved up. **Five deep breaths** activate the parasympathetic system: **rest and recovery** mode. Inhale **4 seconds**, hold **4**, exhale **6**. You'll feel the difference instantly."
    ],
    "tip.58.detail": [
        .es: "A veces olvidamos que simplemente **salir a correr ya es una victoria**. No todos los días serán épicos. Algunos serán lentos, cortos o difíciles. Pero **cada uno de ellos cuenta**. Celebra el acto de moverte, no solo los números.",
        .en: "Sometimes we forget that simply **going out to run is already a victory**. Not every day will be epic. Some will be slow, short, or hard. But **every single one counts**. Celebrate the act of moving, not just the numbers."
    ],

    // Days 59-66
    "tip.59.detail": [
        .es: "El día 1 probablemente estabas nervioso e inseguro. Ahora corres con **confianza**, tu cuerpo es **más fuerte** y tu mente **más resistente**. Esa transformación no es solo física. **Cambiaste tu relación contigo mismo**.",
        .en: "On day 1 you were probably nervous and unsure. Now you run with **confidence**, your body is **stronger**, and your mind **more resilient**. That transformation isn't just physical. **You changed your relationship with yourself**."
    ],
    "tip.60.detail": [
        .es: "Cuando compartes tu progreso, no es presumir, es **inspirar**. Alguien en tu vida puede estar pensando en empezar a correr y tu ejemplo puede ser **el empujón que necesita**. Comparte, celebra y deja que otros celebren contigo.",
        .en: "When you share your progress, it's not bragging, it's **inspiring**. Someone in your life might be thinking about starting to run, and your example could be **the push they need**. Share, celebrate, and let others celebrate with you."
    ],
    "tip.61.detail": [
        .es: "**Cinco días**. Solo cinco. Cada kilómetro que corras ahora tiene un peso especial. No porque sea diferente, sino porque lo haces sabiendo que estás a punto de completar **algo extraordinario**. Saborea cada paso.",
        .en: "**Five days**. Just five. Every kilometer you run now carries special weight. Not because it's different, but because you're doing it knowing you're about to complete **something extraordinary**. Savor every step."
    ],
    "tip.62.detail": [
        .es: "Los primeros días corrías por el reto. Ahora corres porque **lo necesitas**, porque tu cuerpo lo pide y porque tu día no se siente completo sin esos kilómetros. **El reto termina, pero tu carrera como corredor apenas empieza**.",
        .en: "The first days you ran for the challenge. Now you run because **you need it**, because your body asks for it, and your day doesn't feel complete without those kilometers. **The challenge ends, but your journey as a runner is just beginning**."
    ],
    "tip.63.detail": [
        .es: "Después de 66 días tienes la base para cualquier cosa: un **5K**, un **10K**, o simplemente seguir corriendo por placer. **Inscribirte en una carrera** te da un objetivo concreto y la emoción de correr con otros. Date ese regalo.",
        .en: "After 66 days you have the foundation for anything: a **5K**, a **10K**, or simply continuing to run for pleasure. **Signing up for a race** gives you a concrete goal and the thrill of running with others. Give yourself that gift."
    ],
    "tip.64.detail": [
        .es: "**64 días** de trabajo, sudor, días buenos y días malos. Todo eso te pertenece. **Nadie puede quitarte** la disciplina que construiste, la resistencia que ganaste ni la confianza que ahora tienes. Este logro es **tuyo para siempre**.",
        .en: "**64 days** of work, sweat, good days and bad days. All of that belongs to you. **No one can take away** the discipline you built, the endurance you gained, or the confidence you now have. This achievement is **yours forever**."
    ],
    "tip.65.detail": [
        .es: "Mañana cruzas la meta, pero **el hábito ya se formó**. Lo que hiciste en estos 65 días reconectó tu cerebro: las **rutas neuronales** del hábito de correr ya están grabadas. Mañana no es un final, es la confirmación de que **eres un corredor**.",
        .en: "Tomorrow you cross the finish line, but **the habit is already formed**. What you did in these 65 days rewired your brain: the **neural pathways** of the running habit are now engraved. Tomorrow isn't an ending, it's confirmation that **you're a runner**."
    ],
    "tip.66.detail": [
        .es: "**66 días**. El número mágico para formar un **hábito de por vida**. Cruzaste la meta de uno de los retos más difíciles que existen. Ahora tienes la prueba de que puedes lograr lo que te propongas. **Sigue corriendo, sigue creciendo, sigue siendo imparable**.",
        .en: "**66 days**. The magic number to form a **lifelong habit**. You crossed the finish line of one of the hardest challenges there is. Now you have proof you can achieve anything you set your mind to. **Keep running, keep growing, keep being unstoppable**."
    ],
]
