local CATEGORY_NAME = "Perspective Utility"

CreateConVar("hacker_mode", 1, { FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Set hacker mode (0 for Halos SpecialEffect, 1 for 3D2D SpecialEffect)")
CreateConVar("hacker_show_names", 1, { FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Show player names (0 for off, 1 for on)")
hacker_mode = GetConVar("hacker_mode"):GetInt()
hacker_show_names = GetConVar("hacker_show_names"):GetInt()

if SERVER then
    util.AddNetworkString("SpecialEffect")
    util.AddNetworkString("SpecialEffects")
    util.AddNetworkString("RemoveSpecialEffectOnDeaths")
    util.AddNetworkString("RemoveDeadPlayers")
    util.AddNetworkString("ClearSpecialEffects")
    util.AddNetworkString("ClearEffects")
    util.AddNetworkString("UpdateShowNames")
    util.AddNetworkString("UpdateHackerMode")

    hook.Add("PlayerInitialSpawn", "UpdateShowNames", function(ply)
        net.Start("UpdateShowNames")
        net.WriteInt(GetConVar("hacker_show_names"):GetInt(), 32)
        net.Send(ply)
    end)

    hook.Add("PlayerInitialSpawn", "UpdateHackerMode", function(ply)
        net.Start("UpdateHackerMode")
        net.WriteInt(GetConVar("hacker_mode"):GetInt(), 32)
        net.Send(ply)
    end)

    SetGlobalInt("hacker_mode", hacker_mode)
    SetGlobalInt("hacker_show_names", hacker_show_names)

	hook.Add("PlayerDeath", "ClearEffectsOnDeath", function(victim, inflictor, attacker)
        local hackerMode = GetConVar("hacker_mode"):GetInt()

        if hackerMode == 0 then
            net.Start("ClearSpecialEffects")
            net.Send(victim)
        elseif hackerMode == 1 then
            net.Start("ClearEffects")
            net.Send(victim)
        end
    end)
end

if CLIENT then
    net.Receive("UpdateShowNames", function()
        showNames = net.ReadInt(32)
    end)

    net.Receive("UpdateHackerMode", function()
        showNames = net.ReadInt(32)
    end)

    SetGlobalInt("hacker_mode", hacker_mode)
    SetGlobalInt("hacker_show_names", hacker_show_names)

    surface.CreateFont("PlayerName", {
        font = "Source Han Sans SC Heavy",
        size = 24,
        weight = 500,
        extended = true,
        antialias = true,
    })

    local hackerMode = GetGlobalInt("hacker_mode", 0)
    local showNames = GetGlobalInt("hacker_show_names", 1)

    if hackerMode == 0 then
        net.Receive("SpecialEffect", function()
            local playerMap = {}

            for _, ply in ipairs(player.GetAll()) do
                if ply:Alive() then
                    playerMap[ply:UserID()] = ply
                end
            end

            if showNames == 1 then
                hook.Add("HUDPaint", "DrawPlayerNames", function()
                    for _, ply in ipairs(player.GetAll()) do
                        if ply:Alive() and ply ~= LocalPlayer() then
                            local pos = ply:GetPos() + Vector(0, 0, 80) -- Adjust the position to be above the player's head
                            pos = pos:ToScreen() -- Convert the position from 3D world space to 2D screen space
                            draw.SimpleText(ply:Nick(), "PlayerName", pos.x, pos.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        end
                    end
                end)
            end

            hook.Add("PreDrawHalos", "AddNewSpecialHalos", function()
                local alivePlayers = {}
                local localPlayer = LocalPlayer()

                for userID, ply in pairs(playerMap) do
                    if ply:Alive() and ply ~= localPlayer then -- Skip the local player
                        table.insert(alivePlayers, ply)
                    end
                end

                halo.Add(alivePlayers, Color(255, 50, 50), 0, 0, 3, true, true)
            end)
        end)

        net.Receive("ClearSpecialEffects", function()
            hook.Remove("PreDrawHalos", "AddNewSpecialHalos")
            hook.Remove("HUDPaint", "DrawPlayerNames")
            playerMap = {}
        end)

    elseif hackerMode == 1 then
        local playerMap = {}

        net.Receive("SpecialEffects", function()
            for _, ply in ipairs(player.GetAll()) do
                if ply:Alive() then
                    playerMap[ply:UserID()] = ply
                end
            end

            if showNames == 1 then
                hook.Add("HUDPaint", "DrawPlayerNames", function()
                    for _, ply in ipairs(player.GetAll()) do
                        if ply:Alive() and ply ~= LocalPlayer() then
                            local pos = ply:GetPos() + Vector(0, 0, 80) -- Adjust the position to be above the player's head
                            pos = pos:ToScreen() -- Convert the position from 3D world space to 2D screen space
                            draw.SimpleText(ply:Nick(), "PlayerName", pos.x, pos.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        end
                    end
                end)
            end

            hook.Add("PreDrawHalos", "PlayerHalos", function()
                local alivePlayers = {}
                local localPlayer = LocalPlayer()

                for userID, ply in pairs(playerMap) do
                    if ply:Alive() and ply ~= localPlayer then -- Skip the local player
                        table.insert(alivePlayers, ply)
                    end
                end

                halo.Add(alivePlayers, Color(255, 50, 50), 0, 0, 3, true, true)
            end)

            hook.Add("PostDrawOpaqueRenderables", "PlayerBorders", function()
                local client = LocalPlayer()

                -- Stencil work is done in postdrawopaquerenderables, where surface doesn't work correctly
                -- Workaround via 3D2D
                local ang = client:EyeAngles()
                local pos = client:EyePos() + ang:Forward() * 10

                ang = Angle(ang.p + 90, ang.y, 0)

                render.ClearStencil()
                render.SetStencilEnable(true)
                render.SetStencilWriteMask(255)
                render.SetStencilTestMask(255)
                render.SetStencilReferenceValue(15)
                render.SetStencilFailOperation(STENCILOPERATION_KEEP)
                render.SetStencilZFailOperation(STENCILOPERATION_REPLACE)
                render.SetStencilPassOperation(STENCILOPERATION_KEEP)
                render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
                render.SetBlend(0)

                local ents = player.GetAll()

                for _, ply in ipairs(ents) do
                    if ply:Alive() and ply ~= LocalPlayer() then
                        ply:DrawModel()
                    end
                end

                render.SetBlend(1)
                render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)

                cam.Start3D2D(pos, ang, 1)

                surface.SetDrawColor(255, 50, 50)
                surface.DrawRect(-ScrW(), -ScrH(), ScrW() * 2, ScrH() * 2)

                cam.End3D2D()

                for _, ply in ipairs(ents) do
                    if ply:Alive() and ply ~= LocalPlayer() then
                        ply:DrawModel()
                    end
                end

                render.SetStencilEnable(false)
            end)
        end)

        net.Receive("ClearEffects", function()
            hook.Remove("PostDrawOpaqueRenderables", "PlayerBorders")
            hook.Remove("HUDPaint", "DrawPlayerNames")
            playerMap = {}
        end)
    end
end

function ulx.activateNewSpecialEffect(calling_ply, target_plys, shouldClear)
    local GM = gmod.GetGamemode()
    local affected_plys = target_plys or {}

    if #affected_plys == 0 then
        table.insert(affected_plys, calling_ply)
    end

    local players = player.GetAll()
    local hackerMode = GetConVar("hacker_mode"):GetInt()

    for _, ply in ipairs(affected_plys) do
        if shouldClear then
            if hackerMode == 0 then
                net.Start("ClearSpecialEffects")
            elseif hackerMode == 1 then
                net.Start("ClearEffects")
            end
        else
            if hackerMode == 0 then
                net.Start("SpecialEffect")
            elseif hackerMode == 1 then
                net.Start("SpecialEffects")
            end
        end

        net.WriteTable(players)
        net.Send(ply)
    end

    if shouldClear then
        ulx.fancyLogAdmin(calling_ply, "#A cleared test function for #T", target_plys)
    else
        ulx.fancyLogAdmin(calling_ply, "#A activated test function for #T", target_plys)
    end

    if GetConVar("gamemode"):GetString() == "murder" then
        hook.Add("OnStartRound", "murdercleareffects", function()
            for _, ply in ipairs(affected_plys) do
                local hackerMode = GetConVar("hacker_mode"):GetInt()
                if hackerMode == 0 then
                    net.Start("ClearSpecialEffects")
                    net.Send(ply)
                elseif hackerMode == 1 then
                    net.Start("ClearEffects")
                    net.Send(ply)
                end
            end
        end)

    elseif GetConVar("gamemode"):GetString() == "terrortown" then
        hook.Add("TTTPrepareRound", "tttcleareffects", function()
            for _, ply in ipairs(affected_plys) do
                local hackerMode = GetConVar("hacker_mode"):GetInt()
                if hackerMode == 0 then
                    net.Start("ClearSpecialEffects")
                    net.Send(ply)
                elseif hackerMode == 1 then
                    net.Start("ClearEffects")
                    net.Send(ply)
                end
            end
        end)
    end
end

local activateNewSpecialEffect = ulx.command(CATEGORY_NAME, "ulx hacker", ulx.activateNewSpecialEffect, "!hacker")
activateNewSpecialEffect:addParam { type = ULib.cmds.PlayersArg, ULib.cmds.optional }
activateNewSpecialEffect:defaultAccess(ULib.ACCESS_SUPERADMIN)
activateNewSpecialEffect:help("Activate perspective feature.")
activateNewSpecialEffect:setOpposite("ulx clearhacker", { _, _, true }, "!clearhacker")
