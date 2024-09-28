--- @param player Player
function LoadSkinsPlayerData(player)
    if player:IsFakeClient() then return end
    if not db:IsConnected() then return end

    db:QueryParams("select * from skins where steamid = '@steamid' limit 1", { steamid = player:GetSteamID() },
        function(err, result)
            if #err > 0 then
                return print("ERROR: " .. err)
            end

            if #result == 0 then
                player:SetVar("skins.t", "[]")
                player:SetVar("skins.ct", "[]")
                player:SetVar("skins.data", "{}")
            else
                player:SetVar("skins.t", result[1].t)
                player:SetVar("skins.ct", result[1].ct)
                player:SetVar("skins.data", result[1].skins_data)
            end
        end)
end

--- @param player Player
function GetPlayerSkins(player)
    return {
        t = (json.decode(player:GetVar("skins.t") or "[]") or {}),
        ct = (json.decode(player:GetVar("skins.ct") or "[]") or {}),
        data = (json.decode(player:GetVar("skins.data") or "{}") or {})
    }
end

--- @param player Player
--- @param team "t"|"ct"
--- @param skinidx string
function UpdatePlayerSkins(player, team, skinidx)
    if player:IsFakeClient() then return end
    if not db:IsConnected() then return end
    if team ~= "t" and team ~= "ct" then return end

    local skinsData = player:GetVar("skins." .. team)
    if not skinsData then skinsData = "[]" end
    skinsData = json.decode(skinsData)
    if not skinsData then skinsData = {} end

    local found = nil
    for i = 1, #skinsData do
        if skinsData[i] == skinidx then
            found = i
            break
        end
    end

    if found == nil then
        for i = 1, #skinsData do
            if SkinsWeaponIdx[skinsData[i]].weaponid == SkinsWeaponIdx[skinidx].weaponid then
                table.remove(skinsData, i)
                break
            end
        end

        table.insert(skinsData, skinidx)
    else
        table.remove(skinsData, found)
    end

    player:SetVar("skins." .. team, json.encode(skinsData))

    local params = {
        steamid = player:GetSteamID(),
        t = "[]",
        ct = "[]",
    }

    db:QueryParams(
        "insert ignore into skins (steamid, t, ct, skins_data) values ('@steamid', '@t', '@ct', '{}')",
        params
    )

    params = {
        steamid = player:GetSteamID(),
        team = team,
        data = json.encode(skinsData)
    }

    db:QueryParams("update skins set `@team` = '@data' where `steamid` = '@steamid' limit 1", params)
end

--- @param player Player
--- @param skinidx string
--- @param field "seed"|"wear"|"nametag"
--- @param value number|string
function UpdatePlayerSkinsData(player, skinidx, field, value)
    if player:IsFakeClient() then return end
    if not db:IsConnected() then return end

    if not player:GetVar("skins.data") then
        player:SetVar("skins.data", "{}")
    end

    local skinsData = json.decode(player:GetVar("skins.data") or "{}") or {}
    if not skinsData[skinidx] then
        math.randomseed(math.floor(server:GetTickCount()))
        skinsData[skinidx] = {
            wear = 0.0,
            seed = math.random(0, 1000),
            nametag = ""
        }
    end

    if skinsData[skinidx][field] then
        skinsData[skinidx][field] = value
    end

    player:SetVar("skins.data", json.encode(skinsData))

    db:QueryParams(
        "insert ignore into skins (steamid, t, ct, skins_data) values ('@steamid', '[]', '[]', '{}')",
        { steamid = player:GetSteamID() }
    )

    db:QueryParams("update skins set skins_data = '@skinsdata' where steamid = '@steamid' limit 1",
        { skinsdata = json.encode(skinsData), steamid = player:GetSteamID() })
end

--- @param ptr string
--- @return Player|nil
function FindPlayerByPointer(ptr)
    for i = 1, playermanager:GetPlayerCap() do
        local player = GetPlayer(i - 1)
        if player then
            if not player:IsFakeClient() then
                if player:CBaseEntity():ToPtr() == ptr then
                    return player
                end
            end
        end
    end
    return nil
end

--- @param weaponfw Weapon
--- @param weapon CBasePlayerWeapon
--- @param paint_index number
--- @param seed number
--- @param wear number
--- @param nametag string
function GiveWeaponSkin(weaponfw, weapon, paint_index, seed, wear, nametag)
    weapon.Parent.FallbackPaintKit = paint_index
    weapon.Parent.FallbackSeed = seed
    weapon.Parent.FallbackWear = wear
    if nametag ~= "" then weapon.Parent.AttributeManager.Item.CustomName = nametag end

    weapon.Parent.AttributeManager.Item.NetworkedDynamicAttributes:SetOrAddAttributeValueByName(
        "set item texture prefab", paint_index + 0.0)
    weapon.Parent.AttributeManager.Item.NetworkedDynamicAttributes:SetOrAddAttributeValueByName(
        "set item texture seed", seed + 0.0)
    weapon.Parent.AttributeManager.Item.NetworkedDynamicAttributes:SetOrAddAttributeValueByName(
        "set item texture wear", wear)

    weapon.Parent.AttributeManager.Item.AttributeList:SetOrAddAttributeValueByName(
        "set item texture prefab", paint_index + 0.0)
    weapon.Parent.AttributeManager.Item.AttributeList:SetOrAddAttributeValueByName(
        "set item texture seed", seed + 0.0)
    weapon.Parent.AttributeManager.Item.AttributeList:SetOrAddAttributeValueByName(
        "set item texture wear", wear)

    weaponfw:SetDefaultAttributes()
end

--- @param player Player
--- @param slot number
function UpdateSkinsOnSlot(player, slot)
    if player:IsFakeClient() then return end

    local weapons = player:GetWeaponManager():GetWeapons()
    if not player:CBasePlayerPawn():IsValid() then return end
    local activeWeaponIdx = player:CBasePlayerPawn().WeaponServices.ActiveWeapon.Parent.AttributeManager.Item.ItemDefinitionIndex

    for i = 1, #weapons do
        --- @type Weapon
        local weapon = weapons[i]
        if weapon:CCSWeaponBaseVData().GearSlot == slot then
            local weaponidx = weapon:CBasePlayerWeapon().Parent.AttributeManager.Item.ItemDefinitionIndex
            local isactive = (activeWeaponIdx == weaponidx)
            local classname = ItemDefIdx[weaponidx]

            weapon:Remove()
            player:GetWeaponManager():GiveWeapon(classname)

            if isactive then
                NextTick(function()
                    player:ExecuteCommand("slot" .. slot)
                end)
            end
        end
    end
end

function table.has(tbl, element)
    for i = 1, #tbl do
        if tbl[i] == element then
            return true
        end
    end
    return false
end
