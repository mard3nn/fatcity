if SERVER then
    util.AddNetworkString("ZB_RockTheVote_start")
    util.AddNetworkString("ZB_RockTheVote_vote")
    util.AddNetworkString("ZB_RockTheVote_voteCLreg")
    util.AddNetworkString("ZB_RockTheVote_end")
    util.AddNetworkString("RTVMenu")

    zb = zb or {}
    local kd_golosa = {}
    local golosa = {}
    zb.votestarted = false
    local playervote = {}

    local vse_karti = {}
    zb.currentVoteMaps = {}

    local chernyy_spisok = {
        ["gm_construct"] = true, ["gm_flatgrass"] = true, ["gm_altarskforest"] = true,
        ["gm_renostruct_v2"] = true, ["gm_renostruct_v2_night"] = true,
        ["gm_city_of_silence"] = true, ["ttt_hogwarts"] = true,
    }
    local razreshennye_prefiksy = {
        ["ttt"] = true, ["hmcd"] = true, ["mu"] = true, ["ze"] = false,
        ["zs"] = true, ["tdm"] = true, ["zb"] = false, ["zbattle"] = false,
        ["gm"] = true, ["ph"] = true, ["cs"] = true, ["de"] = true
    }

    local function obnovit_karti()
        table.Empty(vse_karti)
        local maps = file.Find("maps/*.bsp", "GAME")
        for _, map in ipairs(maps) do
            map = map:sub(1, -5)
            local mapstr = map:Split("_")
            if (razreshennye_prefiksy[mapstr[1]] or not string.find(map, "_")) and not chernyy_spisok[map] then
                table.insert(vse_karti, map)
            end
        end
    end

    hook.Add("InitPostEntity", "zb_ObnovitKarti", function()
        zb.votestarted = false
        obnovit_karti()
    end)

    -- Приём голоса
    net.Receive("ZB_RockTheVote_vote", function(len, ply)
        if not zb.votestarted then return end
        if kd_golosa[ply:EntIndex()] and kd_golosa[ply:EntIndex()] > CurTime() then return end
        kd_golosa[ply:EntIndex()] = CurTime() + 1

        local playerIdx = ply:EntIndex()
        local sid64 = ply:SteamID64()
        local karta = net.ReadString()
        if not karta or karta == "" then return end

        local valid = (karta == "random" or karta == "stay" or table.HasValue(zb.currentVoteMaps, karta))
        if not valid then return end

        local predKarta = playervote[playerIdx]
        if predKarta and golosa[predKarta] then
            for i, v in ipairs(golosa[predKarta]) do
                if v == sid64 then
                    table.remove(golosa[predKarta], i)
                    break
                end
            end
            if #golosa[predKarta] == 0 then golosa[predKarta] = nil end
        end

        golosa[karta] = golosa[karta] or {}
        table.insert(golosa[karta], sid64)
        playervote[playerIdx] = karta

        net.Start("ZB_RockTheVote_voteCLreg")
            net.WriteTable(golosa)
        net.Broadcast()
    end)

    local golosovanie_zaversheno = false

    function zb.EndRTV()
        if golosovanie_zaversheno then return end
        golosovanie_zaversheno = true

        local podschet = {}
        for karta, igroki in pairs(golosa) do
            podschet[karta] = #igroki
        end

        local karta_pobeditel = nil
        local maxGolosov = 0
        for karta, kolvo in pairs(podschet) do
            if kolvo > maxGolosov then
                maxGolosov = kolvo
                karta_pobeditel = karta
            elseif kolvo == maxGolosov and karta < (karta_pobeditel or "") then
                karta_pobeditel = karta
            end
        end

        if not karta_pobeditel or karta_pobeditel == "stay" then
            zb.votestarted = false
            hook.Remove("Think", "RTVThink")
            net.Start("ZB_RockTheVote_end")
                net.WriteString("stay")
            net.Broadcast()
            table.Empty(golosa)
            table.Empty(playervote)
            zb.ClearRTVVotes()
            return
        end

        if karta_pobeditel == "random" then
            net.Start("ZB_RockTheVote_end")
                net.WriteString("random")
            net.Broadcast()
            timer.Simple(3, function()
                local realMap = vse_karti[math.random(#vse_karti)]
                if not realMap then realMap = "gm_construct" end
                table.Empty(golosa)
                table.Empty(playervote)
                RunConsoleCommand("changelevel", realMap)
            end)
            return
        end

        -- Обычная карта
        if not table.HasValue(vse_karti, karta_pobeditel) then
            karta_pobeditel = "gm_construct"
        end

        net.Start("ZB_RockTheVote_end")
            net.WriteString(karta_pobeditel)
        net.Broadcast()

        timer.Simple(3, function()
            table.Empty(golosa)
            table.Empty(playervote)
            RunConsoleCommand("changelevel", karta_pobeditel)
        end)
    end

    --[[     ⠀⠲⢲⢦⣐⠂⠤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⠈⠃⠁⠀⠨⠆⣀⠀⠀⠀--HMMMM?⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠱⠢⡀⠀⠀⠀⠀⠀--Interesting...⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⡄⠀⠀⠀⠀⢄⢘⡷⠒⣻⣆⠀⠀⠈⡢⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⠟⠀⠀⠀⠀⣰⡌⠀⠀⣿⣿⡇⠀⠀⠀⠱⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⣠⠀⠀⠀⠀⣂⢃⠀⠀⠈⢛⠇⠀⠀⢄⣄⡈⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⣷⡶⢶⡄⠀⠀⠎⠵⡶⠒⠉⠇⠀⠀⠁⣹⡶⠄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⠂⠀⢀⡋⠿⠖⠡⠤⠤⠤⠤⠄⠒⠊⠁⢼⣤⠄⠀⡑⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢅⡴⠆⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
            ⠀⠀⠱⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠲⠊⠄⡈⠀⠀⠀⠀⠀
        ]]

    local rtvtime = 0
    function zb.ThinkRTV()
        if not zb.votestarted then return end
        if rtvtime < CurTime() then zb.EndRTV() end
    end

    function zb.StartRTV()
        if zb.votestarted then return end
        obnovit_karti()
        rtvtime = CurTime() + 30

        golosovanie_zaversheno = false --ыыыы флаг ванючий, тебя забыл поставить и всё наебнулось
        table.Empty(golosa)
        table.Empty(playervote)

        local vseValidnye = table.Copy(vse_karti)

        if #vseValidnye == 0 then
            table.insert(vseValidnye, "gm_construct")
        end
        table.insert(vseValidnye, "random")
        zb.currentVoteMaps = vseValidnye

        net.Start("ZB_RockTheVote_start")
            net.WriteTable(vseValidnye)
            net.WriteFloat(rtvtime)
        net.Broadcast()

        zb.votestarted = true
        hook.Add("Think", "RTVThink", zb.ThinkRTV)
    end

    function zb.RTVMenu(ply)
        net.Start("RTVMenu") net.Send(ply)
    end

    COMMANDS.forcertv = {function(ply, args)
        if not ply:IsAdmin() then ply:ChatPrint("Нету доступа!") return end
        zb.StartRTV(0)
    end, 0}

    local rtv_golosa_komandy = {}
    function zb.ClearRTVVotes()
        rtv_golosa_komandy = {}
        timer.Remove("RTVTimeout")
    end

    function zb.CheckRTVVotes(needPrint)
        local nuzhno = math.ceil(#player.GetAll() / 2)
        if table.Count(rtv_golosa_komandy) >= nuzhno then
            if needPrint then
                for _, v in player.Iterator() do
                    v:ChatPrint("Достаточно голосов для смены карты, голосование за новую карту будет в следуйщем раунде!")
                end
            end
            return true
        end
        return false
    end

    COMMANDS.rtv = {function(ply, args)
        if zb.votestarted then
            zb.RTVMenu(ply)
            return
        end
        local sid = ply:SteamID()
        if rtv_golosa_komandy[sid] then
            rtv_golosa_komandy[sid] = nil
            ply:ChatPrint("Вы забрали твой голос за смену карты!")
            return
        end
        rtv_golosa_komandy[sid] = true
        local nuzhno = math.ceil(#player.GetAll() / 2)
        local ostalos = nuzhno - table.Count(rtv_golosa_komandy)
        for _, v in player.Iterator() do
            if ostalos > 0 then
                v:ChatPrint(ply:Nick() .. " Проголосовал за смену карты " .. ostalos .. " ещё нужно, пропишите !rtv чтобы забрать голос за смену карты") --понял тип это русская локализация, всё для наших игроков :3
            end
        end
        if zb.CheckRTVVotes(true) then return end
    end, 0}

    hook.Add("ShutDown", "ResetRTVVotes", zb.ClearRTVVotes)
    hook.Add("PostGamemodeLoaded", "InitRTV", zb.ClearRTVVotes)

    hook.Add("PlayerDisconnected", "RTVDisconnect", function(ply)
        if rtv_golosa_komandy[ply:SteamID()] then
            rtv_golosa_komandy[ply:SteamID()] = nil
            timer.Simple(0.1, function() zb.CheckRTVVotes(false) end)
        end
    end)
end