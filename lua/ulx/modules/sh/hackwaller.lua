local CATEGORY_NAME = "Perspective Utility"

if SERVER then
    util.AddNetworkString("SpecialEffect")
    util.AddNetworkString("SpecialEffects")
    util.AddNetworkString("RemoveSpecialEffectOnDeaths")
    util.AddNetworkString("RemoveDeadPlayers")
    util.AddNetworkString("ClearSpecialEffects")
    util.AddNetworkString("ClearEffects")

    CreateConVar("hacker_mode", 0, { FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Set hacker mode (0 for Halos SpecialEffect, 1 for 3D2D SpecialEffect)")

    hacker_mode = GetConVar("hacker_mode"):GetInt()

    SetGlobalInt("hacker_mode", hacker_mode)
end

function ulx.activateNewSpecialEffect(calling_ply, target_plys)
    local GM = gmod.GetGamemode()
    local affected_plys = target_plys or {}

    if #affected_plys == 0 then
        table.insert(affected_plys, calling_ply)
    end

    local players = player.GetAll()

    local hackerMode = GetConVar("hacker_mode"):GetInt()

    for _, ply in ipairs(affected_plys) do
        if hackerMode == 0 then
            net.Start("SpecialEffect")
        elseif hackerMode == 1 then
            net.Start("SpecialEffects")
        end

        net.WriteTable(players)
        net.Send(ply)
    end

    ulx.fancyLogAdmin(calling_ply, "#A activated test feature for #T", target_plys)

    if GetConVarString("gamemode") == "murder" then
        hook.Add("OnStartRound", "EffectOnNewRound", function()
            for _, ply in ipairs(affected_plys) do
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

function ulx.clearNewSpecialEffect(calling_ply, target_plys)
    local affected_plys = target_plys or {}
    local hackerMode = GetConVar("hacker_mode"):GetInt()

    if #affected_plys == 0 then
        table.insert(affected_plys, calling_ply)
    end

    for _, ply in ipairs(affected_plys) do
        if hackerMode == 0 then
            net.Start("ClearSpecialEffects")
            net.Send(ply)
        elseif hackerMode == 1 then
            net.Start("ClearEffects")
            net.Send(ply)
        end
    end

    ulx.fancyLogAdmin(calling_ply, "#A cleared test feature for #T", target_plys)
end

local activateNewSpecialEffect = ulx.command(CATEGORY_NAME, "ulx hacker", ulx.activateNewSpecialEffect, "!hacker")
activateNewSpecialEffect:addParam { type = ULib.cmds.PlayersArg, ULib.cmds.optional }
activateNewSpecialEffect:defaultAccess(ULib.ACCESS_SUPERADMIN)
activateNewSpecialEffect:help("Activate perspective feature.")
activateNewSpecialEffect:setOpposite("ulx clearhacker", { _, _, true }, "!clearhacker")

local clearNewSpecialEffect = ulx.command(CATEGORY_NAME, "ulx clearhacker", ulx.clearNewSpecialEffect, "!clearhacker")
clearNewSpecialEffect:addParam { type = ULib.cmds.PlayersArg, ULib.cmds.optional }
clearNewSpecialEffect:defaultAccess(ULib.ACCESS_SUPERADMIN)
clearNewSpecialEffect:help("Clear perspective feature.")

if CLIENT then
    local hackerMode = GetGlobalInt("hacker_mode", 0)

    if hackerMode == 0 then
        net.Receive("SpecialEffect", function()
            local playerMap = {}

            for _, ply in ipairs(player.GetAll()) do
                if ply:Alive() then
                    playerMap[ply:UserID()] = ply
                end
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
            playerMap = {}
        end)

        net.Receive("RemoveSpecialEffectOnDeaths", function()
            local victim = net.ReadEntity()
            for i, ply in ipairs(players) do
                if ply == victim then
                    table.remove(players, i)
                    break
                end
            end
        end)

        net.Receive("RemoveDeadPlayers", function()
            local deadPlayer = net.ReadEntity()
            for i, ply in ipairs(players) do
                if ply == deadPlayer then
                    table.remove(players, i)
                    break
                end
            end
        end)
    end
end

if CLIENT then
    local hackerMode = GetGlobalInt("hacker_mode", 1)

    if hackerMode == 1 then
        local playerMap = {}

        net.Receive("SpecialEffects", function()
            for _, ply in ipairs(player.GetAll()) do
                if ply:Alive() then
                    playerMap[ply:UserID()] = ply
                end
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
                    if ply:Alive() then
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
                    if ply:Alive() then
                        ply:DrawModel()
                    end
                end

                render.SetStencilEnable(false)
            end)
        end)

        net.Receive("ClearEffects", function()
            hook.Remove("PostDrawOpaqueRenderables", "PlayerBorders")
            playerMap = {}
        end)
    end
end
