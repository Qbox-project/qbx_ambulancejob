local Translations = {
    error = {
        canceled = 'Peruutettu',
        impossible = 'Toiminto mahdoton...',
        no_player = 'Ei pelaajia lähettyvillä',
        no_firstaid = 'Tarvitset ensiapupakkauksen',
        no_bandage = 'Tarvitset sideharson',
        beds_taken = 'Kaikki sängyt ovat varattuja...',
        possessions_taken = 'Omaisuutesi on otettu talteen...',
        cant_help = 'Henkilöä ei voi enään auttaa...',
        not_ems = 'Et ole ensihoitaja',
    },
    success = {
        revived = 'Elvytit henkilön!',
        healthy_player = 'Henkilö on terve!"',
        helped_player = 'Autoit henkilöä!',
        being_helped = 'Sinua ollaan auttamassa...'
    },
    info = {
        civ_died = 'Siviili on kuollut',
        civ_down = 'Siviili on tajuton',
        civ_call = 'Siviilipuhelu',
        respawn_txt = 'Teholle pääsy: ~r~%{deathtime}~s~ sekuntia',
        respawn_revive = 'Pidä [~r~E~s~] pohjassa  %{holdtime} sekunnin ajan päästäksesi teholle hintaan $~r~%{cost}~s~',
        bleed_out = 'Vuodat kuiviin ~r~%{time}~s~ sekunnin kuluttua',
        bleed_out_help = 'Vuodat kuiviin ~r~%{time}~s~ sekunnin kuluttua, sinua voidaan vielä auttaa!',
        request_help = 'Paina [~r~G~s~] pyytääksesi apua!',
        help_requested = 'Ensihoitoa on ilmoitettu!',
        amb_plate = 'HUSL', -- Should only be 4 characters long due to the last 4 being a random 4 digits
        heli_plate = 'KOPU', -- Should only be 4 characters long due to the last 4 being a random 4 digits
        status = 'Voinnin tarkastus',
        is_staus = 'On %{status}',
        healthy = 'Olet taas täysin terve!',
        safe = 'Sairaalan varustekaappi',
        pb_hospital = 'Sairaala',
        ems_alert = 'Ensihoidon hälytys %{text}',
        mr = 'Herra',
        mrs = 'Rouva.',
        dr_needed = 'Lääkäriä tarvitaan sairaalalla',
        dr_alert = 'Doctor has already been notified',
        ems_report = 'Ensihoidon ilmoitus',
        message_sent = 'Viesti lähetettäväksi',
        check_health = 'Tarkasta henkilön kunto',
        heal_player = 'Hoida henkilöä',
        revive_player = 'Elvytä henkilöä',
    },
    mail = {
        sender = 'Sairaala',
        subject = 'Hoidon lasku',
        message = 'Hyvä %{gender} %{lastname}, <br /><br /> Viimeisimmän sairaalakäynnin hoidon lasku on nyt annettu teille.<br /> Laskun summaksi tuli: <strong>%{costs}€</strong><br /><br />Toivomme Teille pikaista paranemista! <br /> Ystävällisin terveisin, <br /> Sairaalan henkilökunta '
    },
    menu = {
        amb_vehicles = 'Ajoneuvot',
        status = 'Health Status',
    },
    text = {
        pstash_button = '[E] - Henkilökohtainen kaappi',
        pstash = 'Henkilökohtainen kaappi',
        onduty_button = '[E] - Astu vuoroon',
        offduty_button = '~r~E~w~ - Astu pois vuorosta',
        duty = 'Vuoroon/pois vuorosta',
        armory_button = '[E] - Varasto',
        armory = 'Varasto',
        veh_button = '[E] - Ajoneuvot',
        elevator_roof = '[E] - Ota hissi katolle',
        elevator_main = '[E] - Ota hissi alas',
        el_roof = 'Take the elevator to the roof',
        el_main = 'Take the elevator to the main floor',
        call_doc = '[E] - Kutsu paikalle henkilökunta',
        call = 'Kutsu',
        check_in = '[E] - Mene hoitoon',
        check = 'Hoito',
        lie_bed = '[E] - Makaa sängyssä',
        bed = 'Lay in bed',
        put_bed = 'Aseta kansalainen sänkyyn',
        bed_out = '[E] - Nouse ylös sängystä..',
        alert = 'Alert!'
    },
    progress = {
        ifaks = 'Syödään lääkkeitä...',
        bandage = 'Käytetään sideharsoa...',
        painkillers = 'Syödään kipulääkkeitä...',
        revive = 'Elvytetään henkilöä...',
        healing = 'Hoidetaan haavoja...',
        checking_in = 'Pääset hoitoon...',
    }
}

if GetConvar('qb_locale', 'en') == 'fi' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
