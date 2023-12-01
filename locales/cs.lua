local Translations = {
    error = {
        canceled = 'Zrušeno',
        impossible = 'Akce nemožná...',
        no_player = 'Žádný hráč poblíž',
        no_firstaid = 'Potřebujete lékárničku',
        no_bandage = 'Potřebujete obvaz',
        beds_taken = 'Lůžka jsou obsazená...',
        possessions_taken = 'Všechny vaše věci byly odebrány...',
        cant_help = 'Nemůžete pomoci této osobě...',
        not_ems = 'Nejste zdravotnický pracovník nebo nejste přihlášen',
    },
    success = {
        revived = 'Oživili jste osobu',
        healthy_player = 'Hráč je zdravý',
        helped_player = 'Pomohli jste osobě',
        being_helped = 'Dostáváte pomoc...'
    },
    info = {
        civ_died = 'Civilista zemřel',
        civ_down = 'Civilista je na zemi',
        civ_call = 'Volání civilisty',
        respawn_txt = 'OŽIVENÍ ZA: ~r~%{deathtime}~s~ SEKUND',
        respawn_revive = 'DRŽTE [~r~E~s~] PO DOBU %{holdtime} SEKUND PRO OŽIVENÍ ZA $~r~%{cost}~s~',
        bleed_out = 'VYKRVÁCÍTE ZA: ~r~%{time}~s~ SEKUND',
        bleed_out_help = 'VYKRVÁCÍTE ZA: ~r~%{time}~s~ SEKUND, MŮŽETE BÝT POMOCEN',
        request_help = 'STISKNĚTE [~r~G~s~] PRO ŽÁDOST O POMOC',
        help_requested = 'ZDRAVOTNICKÝ PERSONÁL BYL UPOZORNĚN',
        amb_plate = 'SANI', -- Mělo by být dlouhé pouze 4 znaky kvůli posledním 4 náhodným číslicím
        heli_plate = 'ŽIVOT', -- Mělo by být dlouhé pouze 4 znaky kvůli posledním 4 náhodným číslicím
        status = 'Kontrola stavu',
        is_staus = 'Je %{status}',
        healthy = 'Jste zcela zdravý!',
        safe = 'Nemocnice je bezpečná',
        pb_hospital = 'Nemocnice Pillbox',
        ems_alert = 'Upozornění zdravotnické služby - %{text}',
        mr = 'Pan',
        mrs = 'Paní',
        dr_needed = 'V nemocnici Pillbox je potřeba doktor',
        dr_alert = 'Doktor byl již upozorněn',
        ems_report = 'Zpráva zdravotnické služby',
        message_sent = 'Zpráva k odeslání',
        check_health = 'Zkontrolovat zdraví hráče',
        heal_player = 'Vyléčit hráče',
        revive_player = 'Oživit hráče',
    },
    mail = {
        sender = 'Nemocnice Pillbox',
        subject = 'Náklady na nemocnici',
        message = 'Vážený %{gender} %{lastname}, <br /><br />Zde dostáváte e-mail s náklady na poslední návštěvu nemocnice.<br />Konečné náklady se staly: <strong>$%{costs}</strong><br /><br />Přejeme vám rychlé uzdravení!'
    },
    menu = {
        amb_vehicles = 'Sanitky',
        status = 'Zdravotní stav',
    },
    text = {
        pstash_button = '[E] - Osobní skrýš',
        pstash = 'Osobní skrýš',
        onduty_button = '[E] - Jít na službu',
        offduty_button = '[E] - Jít ze služby',
        duty = 'Na službě/Ze služby',
        armory_button = '[E] - Zbrojnice',
        armory = 'Zbrojnice',
        veh_button = '[E] - Vzít / Uložit vozidlo',
        elevator_roof = '[E] - Vzít výtah na střechu',
        elevator_main = '[E] - Vzít výtah dolů',
        el_roof = 'Vzít výtah na střechu',
        el_main = 'Vzít výtah do hlavního patra',
        call_doc = '[E] - Zavolat doktora',
        call = 'Volání',
        check_in = '[E] Přihlásit se',
        check = 'Přihlásit se',
        lie_bed = '[E] - Lehnout si do postele',
        bed = 'Lehnout si do postele',
        put_bed = 'Uložení občana do postele',
        bed_out = '[E] - Vstát z postele..',
        alert = 'Upozornění!'
    },
    progress = {
        ifaks = 'Beru ifaky...',
        bandage = 'Používám obvaz...',
        painkillers = 'Beru léky proti bolesti...',
        revive = 'Oživuji osobu...',
        healing = 'Léčím rány...',
        checking_in = 'Přihlašuji se...',
    }
}


if GetConvar('qb_locale', 'en') == 'cs' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
--translate by stepan_valic