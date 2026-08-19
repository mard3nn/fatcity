if not ulx then return end

local CATEGORY_NAME = "Voting"

if SERVER then
    util.AddNetworkString("ulx_votemode")
end

local function voteModeDone(t)
    local results = t.results
    local winner
    local winnernum = 0
    for id, numvotes in pairs(results) do
        if numvotes > winnernum then
            winner = id
            winnernum = numvotes
        end
    end

    local str
    if not winner then
        str = "Результаты голосования: Никакой режим не выиграл, потому что никто не проголосовал!"
    else
        local mode = zb.modes[t.options[winner]]
        if mode and mode.CanLaunch and mode:CanLaunch() then
            str = "Результаты голосования: Режим '" .. t.options[winner] .. "' выиграл. (" .. winnernum .. "/" .. t.voters .. ")"
            NextRound(t.options[winner])
        else
            str = "Результаты голосования: Режим '" .. t.options[winner] .. "' не может быть запущен."
        end
    end
    ULib.tsay(_, str)
    ulx.logString(str)
    Msg(str .. "\n")
end

function ulx.votemode(calling_ply, ...)
    calling_ply.CoolDownVote = calling_ply.CoolDownVote or 0
    if calling_ply.CoolDownVote > CurTime() then -- if calling_ply.CoolDownVote or 0 > CurTime() then Useless wtf
        ULib.tsayError(calling_ply, "Подождите ".. ( math.Round( calling_ply.CoolDownVote - CurTime(), 1 ) ) .." перед созданием нового голосования", true)    
    return end
    calling_ply.CoolDownVote = CurTime() + 180

    local argv = {...}

    if ulx.voteInProgress then
        ULib.tsayError(calling_ply, "Результаты голосования: Голосование уже идет. Пожалуйста, дождитесь окончания текущего.", true)
        return
    end

    for i = 2, #argv do
        if ULib.findInTable(argv, argv[i], 1, i - 1) then
            ULib.tsayError(calling_ply, "Режим " .. argv[i] .. " был указан дважды. Пожалуйста, попробуйте еще раз.")
            return
        end
    end

    for _, modeName in ipairs(argv) do
        local mode = zb.modes[modeName]
        if not (mode and mode.CanLaunch and mode:CanLaunch()) then
            ULib.tsayError(calling_ply, "Режим '" .. modeName .. "' не может быть запущен.")
            return
        end
    end

    if #argv > 1 then
        ulx.doVote("Change mode to..", argv, voteModeDone, _, _, _, argv, calling_ply)
        ulx.fancyLogAdmin(calling_ply, "#A начал голосование за режимы с вариантами выбор #s", argv[1])
    elseif #argv == 1 then
        ulx.doVote("Change mode to " .. argv[1] .. "?", {"Yes", "No"}, function(t)
            local yesVotes = t.results[1] or 0
            local noVotes = t.results[2] or 0
            if yesVotes > noVotes then
                voteModeDone({results = {[1] = yesVotes}, options = argv, voters = t.voters})
            else
                ULib.tsay(_, "Результаты голосования: Изменение режима на '" .. argv[1] .. "' было отклонено.")
                ulx.logString("Результаты голосования: Изменение режима на '" .. argv[1] .. "' было отклонено.")
                Msg("Результаты голосования: Изменение режима на '" .. argv[1] .. "' было отклонено.\n")
            end
        end, _, _, _, argv, calling_ply)
        ulx.fancyLogAdmin(calling_ply, "#A начал голосование за режим #s", argv[1])
    else
        ULib.tsayError(calling_ply, "Ты должен указать хотя бы один режим для голосования.", true)
    end
end

local votemode = ulx.command(CATEGORY_NAME, "ulx votemode", ulx.votemode, "!votemode")
votemode:addParam{type = ULib.cmds.StringArg, completes = {"tdm", "gwars", "riot", "criresp", "defense", "hl2dm", "dm", "cstrike" }, hint = "mode", ULib.cmds.restrictToCompletes, ULib.cmds.takeRestOfLine, repeat_min = 1, repeat_max = 10}
votemode:defaultAccess(ULib.ACCESS_ADMIN)
votemode:help("Начал публичное голосование за изменение режима.")

if SERVER then ulx.convar("votemodeSuccessratio", "0.5", _, ULib.ACCESS_ADMIN) end
if SERVER then ulx.convar("votemodeMinvotes", "3", _, ULib.ACCESS_ADMIN) end