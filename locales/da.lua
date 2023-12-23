local Translations = {
    error = {
        canceled = 'Annulleret',
        impossible = 'Handling umulig...',
        no_player = 'Ingen spiller i nærheden',
        no_firstaid = 'Du har brug for en førstehjælpskasse',
        no_bandage = 'Du har brug for et bandage',
        beds_taken = 'Senge er optaget...',
        possessions_taken = 'Alle dine ejendele er taget...',
        cant_help = 'Du kan ikke hjælpe denne person...',
        not_ems = 'Du er ikke EMS eller ikke logget ind',
    },
    success = {
        revived = 'Du genoplivede en person',
        healthy_player = 'Spilleren er sund',
        helped_player = 'Du hjalp personen',
        being_helped = 'Du bliver hjulpet...'
    },
    info = {
        civ_died = 'Borger død',
        civ_down = 'Borger nede',
        civ_call = 'Borger opkald',
        respawn_txt = 'GENOPSTÅ OM: ~r~%{deathtime}~s~ SEKUNDER',
        respawn_revive = 'HOLD [~r~E~s~] I %{holdtime} SEKUNDER FOR AT GENOPSTÅ FOR $~r~%{cost}~s~',
        bleed_out = 'DU VIL BLØDE UD OM: ~r~%{time}~s~ SEKUNDER',
        bleed_out_help = 'DU VIL BLØDE UD OM: ~r~%{time}~s~ SEKUNDER, DU KAN BLIVE HJULPET',
        request_help = 'TRYK [~r~G~s~] FOR AT ANMODE OM HJÆLP',
        help_requested = 'EMS-PERSONALE ER UNDERRETTET',
        amb_plate = 'AMBU', -- Skal kun være 4 tegn lang på grund af de sidste 4 er vilkårlige 4 cifre
        heli_plate = 'LIFE', -- Skal kun være 4 tegn lang på grund af de sidste 4 er vilkårlige 4 cifre
        status = 'Status tjek',
        is_staus = 'Er %{status}',
        healthy = 'Du er helt rask igen!',
        safe = 'Hospital Sikkert',
        pb_hospital = 'Pillbox Hospital',
        ems_alert = 'EMS Alarm - %{text}',
        mr = 'Hr.',
        mrs = 'Fru',
        dr_needed = 'En læge er nødvendig på Pillbox Hospital',
        dr_alert = 'Lægen er allerede underrettet',
        ems_report = 'EMS Rapport',
        message_sent = 'Besked skal sendes',
        check_health = 'Tjek en spillers sundhed',
        heal_player = 'Helbred en spiller',
        revive_player = 'Genopliv en spiller',
    },
    mail = {
        sender = 'Pillbox Hospital',
        subject = 'Hospitalsomkostninger',
        message = 'Kære %{gender} %{lastname}, <br /><br />Hermed modtager du en e-mail med omkostningerne ved det sidste hospitalsbesøg.<br />De endelige omkostninger er: <strong>$%{costs}</strong><br /><br />Vi ønsker dig en hurtig bedring!'
    },
    
    menu = {
        amb_vehicles = 'Ambulance Køretøjer',
        status = 'Sundhedsstatus',
    },
    text = {
        pstash_button = '[E] - Personlig skjulested',
        pstash = 'Personlig skjulested',
        onduty_button = '[E] - Gå på vagt',
        offduty_button = '[E] - Gå ud af vagt',
        duty = 'På/Ud af Vagt',
        armory_button = '[E] - Våbenlager',
        armory = 'Våbenlager',
        veh_button = '[E] - Hent / Opbevar Køretøj',
        elevator_roof = '[E] - Tag elevatoren til taget',
        elevator_main = '[E] - Tag elevatoren ned',
        el_roof = 'Tag elevatoren til taget',
        el_main = 'Tag elevatoren til hovedetagen',
        call_doc = '[E] - Kald læge',
        call = 'Ring',
        check_in = '[E] Check ind',
        check = 'Check Ind',
        lie_bed = '[E] - Læg dig i sengen',
        bed = 'Lig i sengen',
        put_bed = 'Placer borgeren i sengen',
        bed_out = '[E] - Kom ud af sengen..',
        alert = 'Alarm!'
    },
    progress = {
        ifaks = 'Tager ifaks...',
        bandage = 'Bruger bandage...',
        painkillers = 'Tager smertestillende...',
        revive = 'Genopliver person...',
        healing = 'Heler sår...',
        checking_in = 'Tjekker ind...',
    }
}
Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
