commands:Register("skins", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end

    local menuOptions = {}
    local registeredCategories = {}

    for i = 1, #SkinsData do
        local category = SkinsData[i].name:split("|")[1]:trim()
        if not registeredCategories[category] then
            registeredCategories[category] = true
            table.insert(menuOptions, { category, "sw_selectcategory_skin \"" .. category .. "\"" })
        end
    end

    local menuid = "skin_menu_" .. os.time()
    menus:RegisterTemporary(menuid, FetchTranslation("skins.menu.title"),
        config:Fetch("skins.color"), menuOptions)

    player:HideMenu()
    player:ShowMenu(menuid)
end)
commands:RegisterAlias("skins", "ws")

commands:Register("selectcategory_skin", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local menuOptions = {}
    local weaponCategory = args[1]

    for i = 1, #SkinsData do
        if SkinsData[i].name:find("|") then
            local category = SkinsData[i].name:split("|")[1]:trim()
            if category == weaponCategory then
                local name = SkinsData[i].name:split("|")[2]:trim()
                table.insert(menuOptions, { name, "sw_selectskin \"" .. SkinsData[i].id .. "\"" })
            end
        end
    end

    local menuid = "select_skin_menu_" .. os.time()
    menus:RegisterTemporary(menuid, weaponCategory, config:Fetch("skins.color"), menuOptions)

    print(menuid)
    print(weaponCategory)
    print(menuOptions)

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("selectskin", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local skinid = args[1]
    if not SkinsWeaponIdx[skinid] then return end

    local menuid = "select_skin_menu_" .. os.time()
    menus:RegisterTemporary(menuid, SkinsWeaponIdx[skinid].name, config:Fetch("skins.color"), {
        { FetchTranslation("skins.menu.equipfor"),   "sw_skin_equipfor \"" .. skinid .. "\"" },
        { FetchTranslation("skins.menu.setseed"),    "sw_skin_setseedfor \"" .. skinid .. "\"" },
        { FetchTranslation("skins.menu.setwear"),    "sw_skin_setwearfor \"" .. skinid .. "\"" },
        { FetchTranslation("skins.menu.setnametag"), "sw_skin_setnametag \"" .. skinid .. "\" menu" },
        { FetchTranslation("core.menu.back"),        "sw_selectcategory_skin \"" .. SkinsWeaponIdx[skinid].name:split("|")[1]:trim() .. "\"" }
    })

    print(skinid)
    print(menuid)
    print(SkinsWeaponIdx[skinid].name)

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("skin_equipfor", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local skinid = args[1]
    if not SkinsWeaponIdx[skinid] then return end

    local data = GetPlayerSkins(player)

    local menuid = "equipfor_skin_menu_" .. os.time()

    menus:RegisterTemporary(menuid, SkinsWeaponIdx[skinid].name .. " - " .. FetchTranslation("skins.menu.equip"),
        config:Fetch("skins.color"), {
            { "[" .. (table.has(data.ct, skinid) and "✔️" or "❌") .. "] " .. FetchTranslation("skins.menu.ct"), "sw_skin_equip \"" .. skinid .. "\" ct" },
            { "[" .. (table.has(data.t, skinid) and "✔️" or "❌") .. "] " .. FetchTranslation("skins.menu.t"), "sw_skin_equip \"" .. skinid .. "\" t" },
            { FetchTranslation("core.menu.back"), "sw_selectskin \"" .. skinid .. "\"" }
        })

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("skin_equip", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 2 then return end

    local skinid = args[1]
    if not SkinsWeaponIdx[skinid] then return end

    local team = args[2]
    if team ~= "t" and team ~= "ct" then return end

    local data = GetPlayerSkins(player)
    local equipped = table.has(data[team], skinid)

    UpdatePlayerSkins(player, team, skinid)
    ReplyToCommand(playerid, config:Fetch("skins.prefix"),
        FetchTranslation(equipped and "skins.unequip" or "skins.equip"):gsub("{NAME}", SkinsWeaponIdx[skinid].name):gsub(
            "{TEAM}", FetchTranslation("skins.menu." .. team)))

    player:ExecuteCommand("sw_skin_equipfor \"" .. skinid .. "\"")
end)

commands:Register("skin_setseedfor", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local skinid = args[1]
    if not SkinsWeaponIdx[skinid] then return end

    local menuid = "select_seed_menu_" .. os.time()
    menus:RegisterTemporary(menuid, SkinsWeaponIdx[skinid].name, config:Fetch("skins.color"), {
        { FetchTranslation("skins.menu.random"), "sw_skin_setseed \"" .. skinid .. "\" random" },
        { FetchTranslation("skins.menu.manual"), "sw_skin_setseed \"" .. skinid .. "\" manual" },
        { FetchTranslation("core.menu.back"),    "sw_selectskin \"" .. skinid .. "\"" }
    })

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("skin_setseed", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc < 2 then return end

    local skinid = args[1]
    if not SkinsWeaponIdx[skinid] then return end

    local mode = args[2]
    if mode == "manual" then
        local seed = tonumber(args[3] or 0)
        if args[3] and seed then
            if seed < 0 or seed > 1000 then
                return ReplyToCommand(playerid, config:Fetch("skins.prefix"),
                    FetchTranslation("skins.invalid"):gsub("{LIMIT}", "0-1000"):gsub("{CATEGORY}", "seed"))
            end

            player:SetVar("skins.manualseed", false)
            UpdatePlayerSkinsData(player, skinid, "seed", seed)
            ReplyToCommand(playerid, config:Fetch("skins.prefix"),
                FetchTranslation("skins.update"):gsub("{CATEGORY}", "seed"):gsub("{VALUE}", seed))

            if string.find(SkinsWeaponIdx[skinid].category, "pistol") then
                UpdateSkinsOnSlot(player, gear_slot_t.GEAR_SLOT_PISTOL)
            else
                UpdateSkinsOnSlot(player, gear_slot_t.GEAR_SLOT_RIFLE)
            end

            player:ExecuteCommand("sw_selectskin \"" .. skinid .. "\"")
            if player:GetVar("skins.timerid") then
                StopTimer(player:GetVar("skins.timerid"))
                player:SetVar("skins.timerid", nil)
            end
        else
            player:SetVar("skins.manualseed", true)
            local timerid = SetTimer(4500, function()
                player:SendMsg(MessageType.Center,
                    FetchTranslation("skins.type_in_chat"):gsub("{COLOR}", config:Fetch("skins.color")):gsub(
                        "{CATEGORY}", "seed"):gsub("{LIMIT}", "0-1000"))
            end)
            player:SetVar("skins.skinid", skinid)
            player:SetVar("skins.timerid", timerid)
            player:HideMenu()
            player:SendMsg(MessageType.Center,
                FetchTranslation("skins.type_in_chat"):gsub("{COLOR}", config:Fetch("skins.color")):gsub(
                    "{CATEGORY}", "seed"):gsub("{LIMIT}", "0-1000"))
        end
    else
        math.randomseed(math.floor(server:GetTickCount()))
        local seed = math.random(0, 1000)

        UpdatePlayerSkinsData(player, skinid, "seed", seed)

        ReplyToCommand(playerid, config:Fetch("skins.prefix"),
            FetchTranslation("skins.update"):gsub("{CATEGORY}", "seed"):gsub("{VALUE}", seed))
    end
end)

commands:Register("skin_setwearfor", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local skinid = args[1]
    if not SkinsWeaponIdx[skinid] then return end

    local menuid = "select_seed_menu_" .. os.time()
    menus:RegisterTemporary(menuid, SkinsWeaponIdx[skinid].name, config:Fetch("skins.color"), {
        { "Factory New",                         "sw_skin_setwear \"" .. skinid .. "\" manual 0.0" },
        { "Minimal Wear",                        "sw_skin_setwear \"" .. skinid .. "\" manual 0.08" },
        { "Field Tested",                        "sw_skin_setwear \"" .. skinid .. "\" manual 0.16" },
        { "Well-Worn",                           "sw_skin_setwear \"" .. skinid .. "\" manual 0.40" },
        { "Battle-Scared",                       "sw_skin_setwear \"" .. skinid .. "\" manual 0.45" },
        { FetchTranslation("skins.menu.random"), "sw_skin_setwear \"" .. skinid .. "\" random" },
        { FetchTranslation("skins.menu.manual"), "sw_skin_setwear \"" .. skinid .. "\" manual" },
        { FetchTranslation("core.menu.back"),    "sw_selectskin \"" .. skinid .. "\"" }
    })

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("skin_setwear", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc < 2 then return end

    local skinid = args[1]
    if not SkinsWeaponIdx[skinid] then return end

    local mode = args[2]
    if mode == "manual" then
        local wear = tonumber(args[3] or 0.0)
        if args[3] and wear then
            if wear < 0.0 or wear > 1.0 then
                return ReplyToCommand(playerid, config:Fetch("skins.prefix"),
                    FetchTranslation("skins.invalid"):gsub("{LIMIT}", "0.0-1.0"):gsub("{CATEGORY}", "wear"))
            end

            player:SetVar("skins.manualwear", false)
            UpdatePlayerSkinsData(player, skinid, "wear", wear)
            ReplyToCommand(playerid, config:Fetch("skins.prefix"),
                FetchTranslation("skins.update"):gsub("{CATEGORY}", "wear"):gsub("{VALUE}", wear))


            player:ExecuteCommand("sw_selectskin \"" .. skinid .. "\"")

            if player:GetVar("skins.timerid") then
                StopTimer(player:GetVar("skins.timerid"))
                player:SetVar("skins.timerid", nil)
            end
        else
            player:SetVar("skins.manualwear", true)
            local timerid = SetTimer(4500, function()
                player:SendMsg(MessageType.Center,
                    FetchTranslation("skins.type_in_chat"):gsub("{COLOR}", config:Fetch("skins.color")):gsub(
                        "{CATEGORY}", "wear"):gsub("{LIMIT}", "0.0-1.0"))
            end)
            player:SetVar("skins.skinid", skinid)
            player:SetVar("skins.timerid", timerid)
            player:HideMenu()
            player:SendMsg(MessageType.Center,
                FetchTranslation("skins.type_in_chat"):gsub("{COLOR}", config:Fetch("skins.color")):gsub(
                    "{CATEGORY}", "wear"):gsub("{LIMIT}", "0.0-1.0"))
        end
    else
        math.randomseed(math.floor(server:GetTickCount()))
        local wear = math.random()

        UpdatePlayerSkinsData(player, skinid, "wear", wear)

        if string.find(SkinsWeaponIdx[skinid].category, "pistol") then
            UpdateSkinsOnSlot(player, gear_slot_t.GEAR_SLOT_PISTOL)
        else
            UpdateSkinsOnSlot(player, gear_slot_t.GEAR_SLOT_RIFLE)
        end

        ReplyToCommand(playerid, config:Fetch("skins.prefix"),
            FetchTranslation("skins.update"):gsub("{CATEGORY}", "wear"):gsub("{VALUE}", wear))
    end
end)

commands:Register("skin_setnametag", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc < 2 then return end

    local skinid = args[1]
    if not SkinsWeaponIdx[skinid] then return end

    local mode = args[2]
    if mode == "menu" then
        player:SetVar("skins.manualnametag", true)
        local timerid = SetTimer(4500, function()
            player:SendMsg(MessageType.Center,
                FetchTranslation("skins.type_in_chat"):gsub("{COLOR}", config:Fetch("skins.color")):gsub(
                    "{CATEGORY}", "nametag"):gsub("{LIMIT}", FetchTranslation("skins.clear")))
        end)
        player:SetVar("skins.skinid", skinid)
        player:SetVar("skins.timerid", timerid)
        player:HideMenu()
        player:SendMsg(MessageType.Center,
            FetchTranslation("skins.type_in_chat"):gsub("{COLOR}", config:Fetch("skins.color")):gsub(
                "{CATEGORY}", "nametag"):gsub("{LIMIT}", FetchTranslation("skins.clear")))
    else
        local input = args[2]
        if not player:GetVar("skins.manualnametag") then return end

        if input == "clear" then input = "" end

        player:SetVar("skins.manualnametag", false)
        UpdatePlayerSkinsData(player, skinid, "nametag", input)
        ReplyToCommand(playerid, config:Fetch("skins.prefix"),
            FetchTranslation("skins.update"):gsub("{CATEGORY}", "nametag"):gsub("{VALUE}",
                input == "" and FetchTranslation("skins.none") or input))

        if string.find(SkinsWeaponIdx[skinid].category, "pistol") then
            UpdateSkinsOnSlot(player, gear_slot_t.GEAR_SLOT_PISTOL)
        else
            UpdateSkinsOnSlot(player, gear_slot_t.GEAR_SLOT_RIFLE)
        end

        player:ExecuteCommand("sw_selectskin \"" .. skinid .. "\"")

        if player:GetVar("skins.timerid") then
            StopTimer(player:GetVar("skins.timerid"))
            player:SetVar("skins.timerid", nil)
        end
    end
end)


commands:Register("wp", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if player:IsFakeClient() then return end

    UpdateSkinsOnSlot(player, gear_slot_t.GEAR_SLOT_RIFLE)
    UpdateSkinsOnSlot(player, gear_slot_t.GEAR_SLOT_PISTOL)

    ReplyToCommand(playerid, config:Fetch("skins.prefix"), FetchTranslation("skins.refreshed"))
end)
