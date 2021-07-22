-- commands/player.lua by Bonyoze

BSU:RegisterCommand({
    name = "god",
    aliases = { "build" },
    description = "Enters the target(s) into god mode (they cannot receive damage or inflict damage on players)",
    usage = "[<players, defaults to self>]",
    category = "player",
    exec = function(ply, args)
        ply:GodEnable()
        ply:SetNWBool("inGodmode", true)
        
        BSU:SendPlayerInfoMsg(ply, { bsuChat._text(" entered god mode for themself") })
    end
})

BSU:RegisterCommand({
    name = "ungod",
    aliases = { "pvp" },
    description = "Exits the target(s) from god mode (they can now receive damage or inflict damage on players again)",
    usage = "[<players, defaults to self>]",
    category = "player",
    exec = function(ply, args)
        ply:GodDisable()
        ply:SetNWBool("inGodmode", false)

        BSU:SendPlayerInfoMsg(ply, { bsuChat._text(" exited god mode for themself") })
    end
})




--  << admin commands >> --

BSU:RegisterCommand({
    name = "nameColor",
    aliases = { "uniqueColor" },
    description = "Sets the target(s) a unique name color (not supplying the color argument will take away the unique name color if they have it)",
    usage = "[<players, defaults to self>] [<color>]",
    category = "player",
    hasPermission = function(ply)
        return BSU:PlayerIsSuperAdmin()
    end,
    exec = function(ply, args)
        --BSU:SetPlayerUniqueColor(ply, args.color)

    end
})

--[[ BSU:RegisterCommand({
    name = "freeze",
    aliases = { "freeze" },
    description = "Freezes a player.",
    usage = "[<players, defaults to none>]",
    category = "player",
    hasPermission = function(ply)
        return BSU:PlayerIsStaff()
    end,
    exec = function(ply, args)
        local target = -- once we get the command poopoo fart ass shit set up when we can do this
        if not target:IsFlagSet(FL_FROZEN) then
            if target:HasGodMode() then ply.preFreezeGodMode = true end
                target:Lock()
                BSU:SendPlayerInfoMsg(target, { bsuChat._text(" was frozen by ")})
    end
})]]--
