local Translations = {
    error = {
        canceled = 'Cancelado',
        impossible = 'Acción imposible...',
        no_player = 'No hay ningún jugador cerca',
        no_firstaid = 'Necesitas un kit de primeros auxilios',
        no_bandage = 'Necesitas una benda',
        beds_taken = 'Las camas están ocupadas...',
        possessions_taken = 'Todas tus posesiones han sido confiscadas...',
        cant_help = 'No puedes ayudar a esta persona...',
        not_ems = 'No eres EMS',
    },
    success = {
        revived = 'Persona reanimada',
        healthy_player = 'El paciente ya está saludable',
        helped_player = 'Has ayudado a la persona',
        being_helped = 'Estás siendo tratado...'
    },
    info = {
        civ_died = 'Civil muerto',
        civ_down = 'Civil caído',
        civ_call = 'Llamada de civil',
        respawn_txt = 'REAPARECERAS EN %{deathtime} SEGUNDOS',
        respawn_revive = 'MANTÉN [E] DURANTE %{holdtime} SEGUNDOS PARA SER REVIVIDO POR $%{cost}',
        bleed_out = 'TE DESANGRARAS EN %{time} SEGUNDOS',
        bleed_out_help = 'TE DESANGRARAS EN %{time} SEGUNDOS, PUEDES SER AYUDADO',
        request_help = 'PULSA [G] PARA PEDIR AYUDA',
        help_requested = 'EMS EN CAMINO',
        amb_plate = 'LSMD', -- Should only be 4 characters long due to the last 4 being a random 4 digits
        heli_plate = 'LSMD', -- Should only be 4 characters long due to the last 4 being a random 4 digits
        status = 'Revisión de estado',
        is_staus = 'es %{status}',
        healthy = '¡Ya estás completamente saludable de nuevo!',
        safe = 'Caja fuerte de hopital',
        pb_hospital = 'Hospital Pillbox',
        ems_alert = 'Alerta EMS - %{text}',
        mr = 'Dr.',
        mrs = 'Dra.',
        dr_needed = 'Se necesita un doctor en el hospital',
        ems_report = 'Reporte EMS',
        message_sent = 'Mensaje enviado',
        check_health = 'Revisar salud de jugador',
        heal_player = 'Curar jugador',
        revive_player = 'Reanimar jugador',
    },
    mail = {
        sender = 'Hospital Pillbox',
        subject = 'Costos de hospital',
        message = 'Querido %{gender} %{lastname}, <br /><br />Le adjuntamos la factura con los costos de su última estancia en el hospital.<br />El costo total es de: <strong>$%{costs}</strong><br /><br />¡Le deseamos una pronta recuperación!'
    },
    menu = {
        amb_vehicles = 'Vehículos EMS',
        status = 'Estado de salud',
    },
    text = {
        pstash_button = '[E] - Stash personal',
        pstash = 'Stash personal',
        onduty_button = '[E] - Entrar en servicio',
        offduty_button = '[E] - Salir de servicio',
        duty = 'En/fuera de servicio',
        armory_button = '[E] - Armería',
        armory = 'Armería',
        veh_button = '[E] - Sacar / guardar vehículo',
        elevator_roof = '[E] - Tomar el elevador al último piso',
        elevator_main = '[E] - Tomar el elevador hacía abajo',
        el_roof = 'Tomar el elevador al último piso',
        el_main = 'Take the elevator to the main floor',
        call_doc = '[E] - Llamar doctor',
        call = 'Llamar',
        check_in = '[E] Hacer check-in',
        check = 'Check-in',
        lie_bed = '[E] - Para acostarse en la cama',
        bed = 'Acostarse en la cama',
        put_bed = 'Acostar al ciudadano en la cama',
        bed_out = '[E] - Para salir de la cama..',
        alert = 'Alert!'
    },
    progress = {
        ifaks = 'Tomando ifaks...',
        bandage = 'Usando vendas...',
        painkillers = 'Tomando pastillas para el dolor...',
        revive = 'Reanimando persona..',
        healing = 'Curando heridas...',
        checking_in = 'Realizando revisión...',
    }
}

if GetConvar('qb_locale', 'en') == 'es' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
