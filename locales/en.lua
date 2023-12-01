local Translations = {
    error = {
        canceled = 'Canceled',
        impossible = 'Action Impossible...',
        no_player = 'No Player Nearby',
        no_firstaid = 'You need a First Aid Kit',
        no_bandage = 'You need a Bandage',
        beds_taken = 'Beds are occupied...',
        possessions_taken = 'All your possessions have been taken...',
        cant_help = 'You can\'t help this person...',
        not_ems = 'You are not EMS or not signed in',
    },
    success = {
        revived = 'You revived a person',
        healthy_player = 'Player is Healthy',
        helped_player = 'You helped the person',
        being_helped = 'You are being helped...'
    },
    info = {
        civ_died = 'Civilian Died',
        civ_down = 'Civilian Down',
        civ_call = 'Civilian Call',
        respawn_txt = 'RESPAWN IN: ~r~%{deathtime}~s~ SECONDS',
        respawn_revive = 'HOLD [~r~E~s~] FOR %{holdtime} SECONDS TO RESPAWN FOR $~r~%{cost}~s~',
        bleed_out = 'YOU WILL BLEED OUT IN: ~r~%{time}~s~ SECONDS',
        bleed_out_help = 'YOU WILL BLEED OUT IN: ~r~%{time}~s~ SECONDS, YOU CAN BE HELPED',
        request_help = 'PRESS [~r~G~s~] TO REQUEST HELP',
        help_requested = 'EMS PERSONNEL HAVE BEEN NOTIFIED',
        amb_plate = 'AMBU', -- Should only be 4 characters long due to the last 4 being a random 4 digits
        heli_plate = 'LIFE', -- Should only be 4 characters long due to the last 4 being a random 4 digits
        status = 'Status Check',
        is_staus = 'Is %{status}',
        healthy = 'You are completely healthy again!',
        safe = 'Hospital Safe',
        pb_hospital = 'Pillbox Hospital',
        ems_alert = 'EMS Alert - %{text}',
        mr = 'Mr.',
        mrs = 'Mrs.',
        dr_needed = 'A doctor is needed at Pillbox Hospital',
        dr_alert = 'Doctor has already been notified',
        ems_report = 'EMS Report',
        message_sent = 'Message to be sent',
        check_health = 'Check a Players Health',
        heal_player = 'Heal a Player',
        revive_player = 'Revive a Player',
    },
    mail = {
        sender = 'Pillbox Hospital',
        subject = 'Hospital Costs',
        message = 'Dear %{gender} %{lastname}, <br /><br />Hereby you received an email with the costs of the last hospital visit.<br />The final costs have become: <strong>$%{costs}</strong><br /><br />We wish you a quick recovery!'
    },
    menu = {
        amb_vehicles = 'Ambulance Vehicles',
        status = 'Health Status',
    },
    text = {
        pstash_button = '[E] - Personal stash',
        pstash = 'Personal stash',
        onduty_button = '[E] - Go On Duty',
        offduty_button = '[E] - Go Off Duty',
        duty = 'On/Off Duty',
        armory_button = '[E] - Armory',
        armory = 'Armory',
        veh_button = '[E] - Grab / Store Vehicle',
        elevator_roof = '[E] - Take the elevator to the roof',
        elevator_main = '[E] - Take the elevator down',
        el_roof = 'Take the elevator to the roof',
        el_main = 'Take the elevator to the main floor',
        call_doc = '[E] - Call doctor',
        call = 'Call',
        check_in = '[E] Check in',
        check = 'Check In',
        lie_bed = '[E] - To lay in bed',
        bed = 'Lay in bed',
        put_bed = 'Place citizen in bed',
        bed_out = '[E] - To get out of bed..',
        alert = 'Alert!'
    },
    progress = {
        ifaks = 'Taking ifaks...',
        bandage = 'Using Bandage...',
        painkillers = 'Taking Painkillers...',
        revive = 'Reviving Person...',
        healing = 'Healing Wounds...',
        checking_in = 'Checking in...',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
