lib.addCommand('callsign', {
    help = locale('commands.callsign.help'),
    params = {
        {
            name = 'callsign',
            type = 'string',
            help = locale('commands.callsign.params.callsign'),
        }
    },
}, function(source, args)
    local player = exports.qbx_core:GetPlayer(source)

    if not player or player.PlayerData.job.type ~= 'leo'  or player.PlayerData.job.type ~= 'ems' then return end

    player.Functions.SetMetaData('callsign', args.callsign)
end)