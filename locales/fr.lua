local Translations = {
    error = {
        canceled = 'Annulé',
        impossible = 'Action Impossible...',
        no_player = 'Aucun joueur proche',
        no_firstaid = 'Vous avez besoin d\'un kit de premier secours',
        no_bandage = 'Vous avez besoin d\'un bandage',
        beds_taken = 'Les lits sont tous occupés...',
        possessions_taken = 'Tout vos objets ont été saisis...',
        cant_help = 'Vous ne pouvez pas aider cette personne...',
        not_ems = 'Vous n\'êtes pas EMS',
    },
    success = {
        revived = 'Vous avez réanimé quelqu\'un',
        healthy_player = 'La personne est en bonne santé',
        helped_player = 'Vous avez aidé la personne',
        being_helped = 'Quelqu\'un vous aide...'
    },
    info = {
        civ_died = 'Civil décédé',
        civ_down = 'Civil blessé',
        civ_call = 'Appel Civil',
        wep_unknown = 'Inconnu',
        respawn_txt = 'RÉAPPARAITRE DANS: ~r~%{deathtime}~s~ SECONDES',
        respawn_revive = 'MAINTENEZ [~r~E~s~] POUR %{holdtime} SECONDES POUR RÉAPPARAITRE PO $~r~%{cost}~s~',
        bleed_out = 'VOUS ALLEZ VOUS VIDER DE VOTRE SANG DANS: ~r~%{time}~s~ SECONDES',
        bleed_out_help = 'VOUS ALLEZ VOUS VIDER DE VOTRE SANG DANS: ~r~%{time}~s~ SECONDES, VOUS POUVEZ ÊTRE AIDÉ',
        request_help = 'APPUYEZ SUR [~r~G~s~] POUR DEMANDER DE L\'AIDE',
        help_requested = 'LES EMS ONT ÉTÉ NOTIFIÉ',
        amb_plate = 'AMBU', -- Should only be 4 characters long due to the last 4 being a random 4 digits
        heli_plate = 'LIFE', -- Should only be 4 characters long due to the last 4 being a random 4 digits
        status = 'Check Status',
        is_staus = 'Est %{status}',
        healthy = 'Vous êtes maintenant en parfaite santé !',
        safe = 'Coffre de l\'hopital',
        pb_hospital = 'Hopital de Pillbox',
        ems_alert = 'Alerte EMS - %{text}',
        mr = 'M.',
        mrs = 'Mme.',
        dr_needed = 'Un docteur est demandé a l\'hopital de Pillbox',
        dr_alert = 'Doctor has already been notified',
        ems_report = 'Rapport EMS',
        message_sent = 'Message à envoyer',
        check_health = 'Verifier la santé de quelqu\'un',
        heal_player = 'Soigner quelqu\'un',
        revive_player = 'Réanimer une personne',
    },
    mail = {
        sender = 'Hopital de Pillbox',
        subject = 'Coût Hopital',
        message = 'Cher(e) %{gender} %{lastname}, <br /><br />Par la présente, vous avez reçu un e-mail avec les coûts de la dernière visite à l\'hôpital.<br />Le coût final est: <strong>$%{costs}</strong><br /><br />Nous-vous souhaitons un bon rétablissement !'
    },
    menu = {
        amb_vehicles = 'Véhicules ambulanciers',
        status = 'Etat de santé',
    },
    text = {
        pstash_button = '[E] - Coffre Personnel',
        pstash = 'Coffre personnel',
        onduty_button = '[E] - Prendre son service',
        offduty_button = '[E] - Quitter son service',
        duty = 'En/Hors Service',
        armory_button = '[E] - Armurerie',
        armory = 'Armurerie',
        veh_button = '[E] - Prendre / Ranger un vehicule',
        elevator_roof = '[E] - Prendre l\'ascenseur jusqu\'au toit',
        elevator_main = '[E] - Prendre l\'ascenseur',
        el_roof = 'Take the elevator to the roof',
        el_main = 'Take the elevator to the main floor',
        call_doc = '[E] - Appeler un docteur',
        call = 'Appeler',
        check_in = '[E] - S\'hospitaliser',
        check = 'Enregistrement',
        lie_bed = '[E] - Pour s\'allonger dans un lit',
        bed = 'Lay in bed',
        put_bed = 'Placer le citoyen dans son lit',
        bed_out = '[E] - Pour sortir du lit..',
        alert = 'Alert!'
    },
    progress = {
        ifaks = 'Prend un Kit de Soin Individuel...',
        bandage = 'Utilise un Bandage...',
        painkillers = 'Prend des anti-douleurs...',
        revive = 'Réanime la personne...',
        healing = 'Soigne les blessures...',
        checking_in = 'S\'enregistre...',
    }
}

if GetConvar('qb_locale', 'en') == 'fr' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
