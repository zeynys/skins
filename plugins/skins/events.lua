AddEventHandler("OnPluginStart", function(event)
    db = Database("skins")
    if not db:IsConnected() then return end

    db:QueryBuilder():Table("skins"):Create({
        steamid = "string|max:128|unique",
        t = "string|max:128",
        ct = "string|max:128",
        skins_data = "json|default:{}"
    }):Execute(function (err, result)
        if #err > 0 then
            print("ERROR: " .. err)
        end
    end)

    local jsonData = json.decode(files:Read(GetPluginPath(GetCurrentPluginName()) .. "/data/skins.json"))
    if not jsonData then return end

    for i = 1, #jsonData do
        if jsonData[i].category.id ~= "sfui_invpanel_filter_melee" and jsonData[i].category.id ~= "sfui_invpanel_filter_gloves" then
            table.insert(SkinsData,
                {
                    id = jsonData[i].id,
                    paint_index = tonumber(jsonData[i].paint_index),
                    name = jsonData[i].name,
                    weaponid = jsonData[i].weapon.id
                })

            SkinsWeaponIdx[jsonData[i].id] = {
                paint_index = tonumber(jsonData[i].paint_index),
                name = jsonData[i].name,
                weaponid = jsonData[i].weapon.id,
                category = jsonData[i].category.id,
                defidx = ItemDefIndex[jsonData[i].weapon.id]
            }
        end
    end

    for i = 1, playermanager:GetPlayerCap() do
        local player = GetPlayer(i - 1)
        if player then
            LoadSkinsPlayerData(player)
        end
    end

    config:Create("skins", {
        prefix = "[{lime}Skins{default}]",
        color = "00B869",
    })
end)

AddEventHandler("OnPlayerConnectFull", function(event)
    local playerid = event:GetInt("userid")
    local player = GetPlayer(playerid)
    if not player then return end

    LoadSkinsPlayerData(player)
end)

AddEventHandler("OnClientChat", function(event, playerid, text, teamonly)
    local player = GetPlayer(playerid)
    if not player then return end

    if player:GetVar("skins.manualseed") == true then
        if tonumber(text) then
            player:ExecuteCommand("sw_skin_setseed \"" ..
                player:GetVar("skins.skinid") .. "\" manual " .. text)

            event:SetReturn(false)
            return EventResult.Handled
        end
    elseif player:GetVar("skins.manualwear") == true then
        if tonumber(text) then
            player:ExecuteCommand("sw_skin_setwear \"" ..
                player:GetVar("skins.skinid") .. "\" manual " .. text)

            event:SetReturn(false)
            return EventResult.Handled
        end
    elseif player:GetVar("skins.manualnametag") == true then
        player:ExecuteCommand("sw_skin_setnametag \"" ..
            player:GetVar("skins.skinid") .. "\" \"" .. text .. "\"")

        event:SetReturn(false)
        return EventResult.Handled
    end

    return EventResult.Continue
end)

AddEventHandler("OnEntityCreated", function(event, entityptr)
    local designername = CEntityInstance(entityptr).Entity.DesignerName

    if designername ~= "weapon_knife" and designername:find("weapon") then
        NextTick(function()
            local ownerentity = CBaseEntity(entityptr).OwnerEntity
            if not ownerentity:IsValid() then return end
            local originalcontroller = CCSPlayerPawnBase(ownerentity:ToPtr()).OriginalController
            if not originalcontroller:IsValid() then return end
            --- @type Player|nil
            local player = GetPlayer(originalcontroller.Parent:EntityIndex() - 1)
            if not player then return end
            if player:IsFakeClient() then return end
            if not player:CBaseEntity():IsValid() then return end

            local playerdata = GetPlayerSkins(player)
            local team = (player:CBaseEntity().TeamNum == Team.T and "t" or "ct")
            local weaponidx = CBasePlayerWeapon(entityptr).Parent.AttributeManager.Item.ItemDefinitionIndex

            if #playerdata[team] > 0 then
                local skinsdata = playerdata[team]

                for i = 1, #skinsdata do
                    if SkinsWeaponIdx[skinsdata[i]].defidx == weaponidx then
                        local paint_index = SkinsWeaponIdx[skinsdata[i]].paint_index
                        local seed = (playerdata.data[skinsdata[i]] or { seed = math.random(0, 1000) }).seed
                        local wear = (playerdata.data[skinsdata[i]] or { wear = 0.0 }).wear
                        local nametag = (playerdata.data[skinsdata[i]] or { nametag = "" }).nametag

                        local weapons = player:GetWeaponManager():GetWeapons()
                        for j = 1, #weapons do
                            --- @type Weapon
                            local weapon = weapons[j]
                            if weapon:CBasePlayerWeapon():ToPtr() == entityptr:ToPtr() then
                                GiveWeaponSkin(weapon, CBasePlayerWeapon(entityptr), paint_index, seed, wear, nametag)
                            end
                        end
                    end
                end
            end
        end)
    end
end)
