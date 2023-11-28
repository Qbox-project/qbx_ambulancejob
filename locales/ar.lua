local Translations = {
    error = {
        canceled = 'ألغيت',
        impossible = 'غير ممكن',
        no_player = 'لا يوجد لاعب بالجوار',
        no_firstaid = 'أنت بحاجة إلى حقيبة إسعافات أولية',
        no_bandage = 'أنت بحاجة إلى ضمادات',
        beds_taken = 'الأسرة مشغولة',
        possessions_taken = 'تم أخذ جميع ممتلكاتك',
        cant_help = 'لا يمكنك مساعدة هذا الشخص',
        not_ems = 'لست بمسعف',
    },
    success = {
        revived = 'لقد أحيت شخصًا',
        healthy_player = 'اللاعب بصحة جيدة',
        helped_player = 'لقد ساعدت الشخص',
        being_helped = 'يتم مساعدتك'
    },
    info = {
        civ_died = 'موت مواطن',
        civ_down = 'سقوط مواطن',
        civ_call = 'اتصال مواطن',
        respawn_txt = '~r~%{deathtime}~w~ ﻝﻼﺧ ﺕﻮﻤﻟﺍ',
        respawn_revive = '[~r~Hold E~w~] %{holdtime}~w~ ﻥﻭﺎﺒﺳﺭ $~r~%{cost}~s~',
        bleed_out = 'ﺔﻴﻧﺎﺛ ~r~%{time}~w~ :ﻲﻓ ﻑﺰﻨﺗ ﻑﻮﺳ',
        bleed_out_help = 'ﻚﺗﺪﻋﺎﺴﻣ ﻦﻜﻤﻳ ﻭ ﺔﻴﻧﺎﺛ ~r~%{time}~w~ :ﻲﻓ ﻑﺰﻨﺗ ﻑﻮﺳ',
        request_help = '[~r~G~s~] - ﺓﺪﻋﺎﺴﻤﻟﺍ ﺐﻠﻄﻟ',
        help_requested = 'ﺓﺪﻋﺎﺴﻤﻟﺍ ﺐﻠﻃ ﻢﺗ',
        amb_plate = 'AMBU', -- Should only be 4 characters long due to the last 4 being a random 4 digits
        heli_plate = 'LIFE', -- Should only be 4 characters long due to the last 4 being a random 4 digits
        status = 'فحص الحالة',
        is_staus = '%{status} انه',
        healthy = 'أنت بصحة جيدة مرة أخرى',
        safe = 'مستشفى آمن',
        pb_hospital = 'Pillbox Hospital',
        ems_alert = 'ﻪﻴﺒﻨﺗ - %{text}',
        mr = 'السيد.',
        mrs = 'السيدة.',
        dr_needed = 'مطلوب طبيب في مستشفى بيل بوكس',
        ems_report = 'تقرير الاسعاف',
        message_sent = 'سيتم إرسال الرسالة',
        check_health = 'تحقق من صحة اللاعبين',
        heal_player = 'مساعدة شخص',
        revive_player = 'إحياء شخص',
    },
    mail = {
        sender = 'مستشفى بيلبوكس',
        subject = 'تكاليف المستشفى',
        message = 'مرحبا %{gender} %{lastname}, <br /><br />بموجب هذا تلقيت رسالة بريد إلكتروني بتكاليف الزيارة الأخيرة للمستشفى<br />أصبحت التكاليف النهائية: <strong>$%{costs}</strong><br /><br />نتمنى لك الشفاء العاجل'
    },
    menu = {
        amb_vehicles = 'سيارات المستشفى',
        close = '⬅ اغلاق',
    },
    text = {
        pstash_button = '[E] - ﺔﻴﺼﺨﺸﻟﺍ ﺔﻧﺰﺨﻟﺍ',
        pstash = 'ﺔﻴﺼﺨﺸﻟﺍ ﺔﻧﺰﺨﻟﺍ',
        onduty_button = '[E] - ﺔﻣﺪﺨﻟﺍ ﻝﻮﺧﺩ',
        offduty_button = '~r~E~w~ - ﺔﻣﺪﺨﻟﺍ ﻦﻣ ﺝﻭﺮﺨﻟﺍ',
        duty = 'ﺔﻣﺪﺨﻟﺍ ﺔﻟﺎﺣ',
        armory_button = '[E] - ﺔﻧﺰﺨﻟﺍ',
        armory = 'ﺔﻧﺰﺨﻟﺍ',
        veh_button = '[E] - ﺝﺍﺮﻐﻟﺍ',
        elevator_roof = '[E] - ﺢﻄﺴﻟﺍ ﻰﻟﺇ ﺪﻌﺼﻤﻟﺍ ﺬﺧ',
        elevator_main = '[E] - ﻞﻔﺳﻷ ﺪﻌﺼﻤﻟﺍ ﺬﺧ',
        el_roof = 'Take the elevator to the roof',
        el_main = 'Take the elevator to the main floor',
        call_doc = '[E] - ﺭﻮﺘﻛﺪﻟﺎﺑ ﻞﺼﺗﺍ',
        call = 'ﻞﺼﺗﺍ',
        check_in = '[E] - ﻖﻘﺤﺗ',
        check = 'ﻖﻘﺤﺗ',
        lie_bed = '[E] - ﺮﻳﺮﺴﻟﺍ ﻰﻠﻋ ﺀﺎﻘﻠﺘﺳﺍ',
        bed = 'Lay in bed',
        put_bed = 'Place citizen in bed',
        bed_out = '[E] - ﺮﻳﺮﺴﻟﺍ ﻦﻣ ﺽﻮﻬﻨﻟﺍ',
        alert = 'Alert!'
    },
    progress = {
        ifaks = 'أخذ حبوب',
        bandage = 'استخدام الضمادات',
        painkillers = 'أخذ المسكنات',
        revive = 'إحياء الشخص',
        healing = 'شفاء الجروح',
        checking_in = 'تسجيل الدخول',
    }
}

if GetConvar('qb_locale', 'en') == 'ar' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
