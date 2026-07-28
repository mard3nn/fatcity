local function proverka(self, ent, ply)
    if not ply:ZCTools_GetAccess() then return false end 
    if not IsValid(ent) then return false end
    if ent:IsPlayer() then return true end
    local pEnt = hg.RagdollOwner(ent)
    if ent:IsRagdoll() and pEnt and pEnt:IsPlayer() and pEnt:Alive() then return true end
end

local function ZashitaPrint(msg)
    PrintMessage(HUD_PRINTTALK, "[ZASHITA] " .. msg)
    print("[ZASHITA] " .. msg)
end

--ыыывпывпывп я даун конченый и буду ныть чтобывп этооа чаААт! Д!!Ж!!!ББ!Т!
--ведь я просто ывыфвывфцй и длйа менйа очеень слоожно сделатт проверккк наа АДМИНКУУУАаыва С принтам!
properties.Add("notify", {
    MenuLabel = "Notify",
    Order = 1,
    MenuIcon = "icon16/note_add.png",
    Filter = proverka,
    Action = function(self, ent)
        Derma_StringRequest(
            "Notify " .. ent:GetPlayerName(),
            "Write a message",
            "",
            function(text)
                self:MsgStart()
                    net.WriteEntity(ent)
                    net.WriteString(text)
                self:MsgEnd()
            end
        )
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        local text = net.ReadString()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать notify на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        ent:Notify(text, 0)
    end
})

local RazreshennoeOruzhie = {
    "weapon_pistol",
    "weapon_shotgun",
    "weapon_smg1",
    "weapon_ar2",
    "weapon_357",
    "weapon_crowbar",
    "weapon_stunstick",
}

properties.Add("givegun", {
    MenuLabel = "Give",
    Order = 2,
    MenuIcon = "icon16/gun.png",
    Filter = proverka,
    Action = function(self, ent)
        Derma_StringRequest(
            "Give " .. ent:GetPlayerName(),
            "Write a entity class name",
            "",
            function(text)
                self:MsgStart()
                    net.WriteEntity(ent)
                    net.WriteString(text)
                self:MsgEnd()
            end
        )
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        local text = net.ReadString()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать givegun на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent

        local spawned = ent:Give(text)
        if not IsValid(spawned) then return end
        spawned:Use(ent)
    end
})

properties.Add("strip", {
    MenuLabel = "Strip",
    Order = 3,
    MenuIcon = "icon16/basket_delete.png",
    Filter = proverka,
    Action = function(self, ent)
        Derma_Query(
            "The player will be stripped down to only their fists.",
            "Are you sure?",
            "Yes",
            function()
                self:MsgStart()
                    net.WriteEntity(ent)
                self:MsgEnd()
            end,
            "No"
        )
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать strip на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        ent:StripWeapons()
        ent:Give("weapon_hands_sh")
    end
})

properties.Add("fullstrip", {
    MenuLabel = "Full Strip",
    Order = 4,
    MenuIcon = "icon16/lorry_delete.png",
    Filter = proverka,
    Action = function(self, ent)
        Derma_Query(
            "All weapons, including fists, will be stripped.",
            "Are you sure?",
            "Yes",
            function()
                self:MsgStart()
                    net.WriteEntity(ent)
                self:MsgEnd()
            end,
            "No"
        )
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать fullstrip на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        ent:StripWeapons()
    end
})

properties.Add("reset_org", {
    MenuLabel = "Reset organism",
    Order = 5,
    MenuIcon = "icon16/heart_add.png",
    Filter = proverka,
    Action = function(self, ent)
        Derma_Query(
            "Organism will be new like a respawn",
            "Are you sure?",
            "Yes",
            function()
                self:MsgStart()
                    net.WriteEntity(ent)
                self:MsgEnd()
            end,
            "No"
        )
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать reset_org на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        hg.organism.Clear(ent.organism)
    end
})

properties.Add("freeze", {
    MenuLabel = "Freeze",
    Order = 6,
    MenuIcon = "icon16/control_pause_blue.png",
    Filter = function(self, ent, ply)
        if not ply:ZCTools_GetAccess() then return false end
        if not IsValid(ent) then return false end
        local pEnt = hg.RagdollOwner(ent) or ent
        self.MenuLabel = pEnt:IsPlayer() and pEnt:IsFrozen() and "Unfreeze" or "Freeze"
        self.MenuIcon = pEnt:IsPlayer() and pEnt:IsFrozen() and "icon16/control_pause.png" or "icon16/control_pause_blue.png"
        if ent:IsPlayer() then return true end
        if ent:IsRagdoll() and pEnt and pEnt:IsPlayer() and pEnt:Alive() then return true end
    end,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать freeze на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        ent:Freeze(not ent:IsFrozen())
    end
})

properties.Add("snatch", {
    MenuLabel = "Snatch",
    Order = 7,
    MenuIcon = "icon16/cross.png",
    Filter = function(self, ent, ply)
        if not CurrentRound then return false end
        return proverka(self, ent, ply)
    end,
    Action = function(self, ent)
        Derma_Query(
            "If no players are around, he will simply disappear.",
            "Are you sure?",
            "Yes",
            function()
                self:MsgStart()
                    net.WriteEntity(ent)
                self:MsgEnd()
            end,
            "No"
        )
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать snatch на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        local bot = ents.Create("bot_fear")
        bot.Victim = ent
        bot:Spawn()
    end
})

properties.Add("ragdollize", {
    MenuLabel = "Stun/Get up",
    Order = 8,
    MenuIcon = "icon16/anchor.png",
    Filter = proverka,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать ragdollize на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        if not IsValid(ent.FakeRagdoll) then
            hg.LightStunPlayer(ent, 5)
        else
            hg.FakeUp(ent)
        end
    end
})

properties.Add("vomit", {
    MenuLabel = "Make vomit",
    Order = 9,
    MenuIcon = "pluv/pluv51.png",
    Filter = proverka,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать vomit на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        hg.organism.Vomit(ent)
    end
})

properties.Add("lobotomize", {
    MenuLabel = "Lobotomize",
    Order = 10,
    MenuIcon = "pluv/pluv51.png",
    Filter = proverka,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать lobotomize на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        ent.organism.brain = ent.organism.brain + 0.05
        ply:ChatPrint("Lobotomized brain to " .. math.Round(ent.organism.brain * 100) .. "%")
        print(ply:Nick() .. " сделал лоботомиююююююю " .. ent:Nick() .. " (мозг теперь ыыывпкурп " .. math.Round(ent.organism.brain * 100) .. "%)")
        if ent.organism.brain >= 0.25 and ent.organism.brain < 0.3 then
            ply:ChatPrint("Consciousness loss on the next lobotomization!")
        end
    end
})



properties.Add("killsilent", {
    MenuLabel = "Kill (Silent)",
    Order = 11,
    MenuIcon = "icon16/cross.png",
    Filter = proverka,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать killsilent на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        ent:Kill()
    end
})

properties.Add("removeply", {
    MenuLabel = "Remove",
    Order = 12,
    MenuIcon = "icon16/cross.png",
    Filter = proverka,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать removeply на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        ent:KillSilent()
        ent:Remove()
    end
})

properties.Add("setplayerclass", {
    MenuLabel = "Set player class",
    Order = 15,
    MenuIcon = "vgui/entities/npc_nukude_proto_h",
    Filter = proverka,
    MenuOpen = function(self, option, ent, tr)
        local submenu = option:AddSubMenu()
        for name, _ in pairs(player.classList) do
            local opt = submenu:AddOption(name)
            opt:SetRadio(true)
            opt:SetChecked(ent.PlayerClassName == name)
            opt:SetIsCheckable(true)
            opt.OnChecked = function(s, checked)
                self:MsgStart()
                    net.WriteEntity(ent)
                    net.WriteString(name)
                self:MsgEnd()
            end
        end
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        local class = net.ReadString()

        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался setplayerclass без прав (обход)")
            return
        end

        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or hg.GetCurrentCharacter(ent) or ent
        if not (IsValid(ent) and ent:IsPlayer() and player.classList[class]) then return end

        ent:SetPlayerClass(class)
    end
})

properties.Add("break_limb", {
    MenuLabel = "Break Limb",
    Order = 13,
    MenuIcon = "pluv/pluv51.png",
    Filter = proverka,
    MenuOpen = function(self, option, ent, tr)
        ent = hg.RagdollOwner(ent) or hg.GetCurrentCharacter(ent) or ent
        local submenu = option:AddSubMenu()
        local neck = submenu:AddOption("Neck")
        neck:SetRadio(true)
        neck:SetIsCheckable(true)
        neck.OnChecked = function(s, checked) self:BreakLimb(ent, 0) end

        local larm = submenu:AddOption("Left Arm")
        larm:SetRadio(true)
        larm:SetIsCheckable(true)
        larm.OnChecked = function(s, checked) self:BreakLimb(ent, 1) end

        local rarm = submenu:AddOption("Right Arm")
        rarm:SetRadio(true)
        rarm:SetIsCheckable(true)
        rarm.OnChecked = function(s, checked) self:BreakLimb(ent, 2) end

        local lleg = submenu:AddOption("Left Leg")
        lleg:SetRadio(true)
        lleg:SetIsCheckable(true)
        lleg.OnChecked = function(s, checked) self:BreakLimb(ent, 3) end

        local rleg = submenu:AddOption("Right Leg")
        rleg:SetRadio(true)
        rleg:SetIsCheckable(true)
        rleg.OnChecked = function(s, checked) self:BreakLimb(ent, 4) end

        local spine1 = submenu:AddOption("Spine 1")
        spine1:SetRadio(true)
        spine1:SetIsCheckable(true)
        spine1.OnChecked = function(s, checked) self:BreakLimb(ent, 5) end

        local spine2 = submenu:AddOption("Spine 2")
        spine2:SetRadio(true)
        spine2:SetIsCheckable(true)
        spine2.OnChecked = function(s, checked) self:BreakLimb(ent, 6) end

        local spine3 = submenu:AddOption("Spine 3")
        spine3:SetRadio(true)
        spine3:SetIsCheckable(true)
        spine3.OnChecked = function(s, checked) self:BreakLimb(ent, 7) end
    end,
    BreakLimb = function(self, ent, id)
        self:MsgStart()
            net.WriteEntity(ent)
            net.WriteUInt(id, 8)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        local limb = net.ReadUInt(8)
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать break_limb на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or hg.GetCurrentCharacter(ent) or ent
        local dmgInfo = DamageInfo()
        if limb == 0 then
            hg.BreakNeck(ent)
        elseif limb == 1 then
            hg.organism.input_list.larmup(ent.organism, 0, 1, dmgInfo)
        elseif limb == 2 then
            hg.organism.input_list.rarmup(ent.organism, 0, 1, dmgInfo)
        elseif limb == 3 then
            hg.organism.input_list.llegup(ent.organism, 0, 1, dmgInfo)
        elseif limb == 4 then
            hg.organism.input_list.rlegup(ent.organism, 0, 1, dmgInfo)
        elseif limb == 5 then
            hg.organism.input_list.spine1(ent.organism, 0, 1, dmgInfo)
        elseif limb == 6 then
            hg.organism.input_list.spine2(ent.organism, 0, 1, dmgInfo)
        elseif limb == 7 then
            hg.organism.input_list.spine3(ent.organism, 0, 1, dmgInfo)
        end
    end
})

--████  █   █ ████  ███    █   █ ████  █   █ █████  ███  █   █    ████  ████   ███  █████  ███   ███  █████ █   █ █ 
--█   █ █   █ █   █  █     █  █  █   █  █ █    █   █   █  █ █     █   █ █   █ █   █   █   █   █ █     █     ██  █ █ 
--████  █   █ ████   █     ███   ████    █     █   █   █   █      ████  ████  █   █   █   █   █ █  ██ ████  █ █ █ █ 
--█  █  █   █ █   █  █     █  █  █  █    █     █   █   █   █      █     █  █  █   █   █   █   █ █   █ █     █  ██   
--█   █  ███  ████  ███    █   █ █   █   █     █    ███    █      █     █   █  ███    █    ███   ███  █████ █   █ █ 

properties.Add("amputate_limb", {
    MenuLabel = "Amputate Limb",
    Order = 14,
    MenuIcon = "effects/arc9_eft/evil.png",
    Filter = proverka,
    MenuOpen = function(self, option, ent, tr)
        ent = hg.RagdollOwner(ent) or hg.GetCurrentCharacter(ent) or ent
        local submenu = option:AddSubMenu()
        local head = submenu:AddOption("Head")
        head:SetRadio(true)
        head:SetIsCheckable(true)
        head.OnChecked = function(s, checked) self:AmputateLimb(ent, 0) end

        local larm = submenu:AddOption("Left Arm")
        larm:SetRadio(true)
        larm:SetIsCheckable(true)
        larm.OnChecked = function(s, checked) self:AmputateLimb(ent, 1) end

        local rarm = submenu:AddOption("Right Arm")
        rarm:SetRadio(true)
        rarm:SetIsCheckable(true)
        rarm.OnChecked = function(s, checked) self:AmputateLimb(ent, 2) end

        local lleg = submenu:AddOption("Left Leg")
        lleg:SetRadio(true)
        lleg:SetIsCheckable(true)
        lleg.OnChecked = function(s, checked) self:AmputateLimb(ent, 3) end

        local rleg = submenu:AddOption("Right Leg")
        rleg:SetRadio(true)
        rleg:SetIsCheckable(true)
        rleg.OnChecked = function(s, checked) self:AmputateLimb(ent, 4) end
    end,
    AmputateLimb = function(self, ent, id)
        self:MsgStart()
            net.WriteEntity(ent)
            net.WriteUInt(id, 8)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        local limb = net.ReadUInt(8)
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать amputate_limb на " .. (IsValid(ent) and ent:Nick() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        if limb == 0 then
            if SERVER and not ent.noHead then
                hg.ExplodeHead(ent)
            end
        elseif limb == 1 then
            hg.organism.AmputateLimb(ent.organism, "larm")
        elseif limb == 2 then
            hg.organism.AmputateLimb(ent.organism, "rarm")
        elseif limb == 3 then
            hg.organism.AmputateLimb(ent.organism, "lleg")
        elseif limb == 4 then
            hg.organism.AmputateLimb(ent.organism, "rleg")
        end
    end
})

local function doorCheck(self, ent, ply)
    if not ply:IsAdmin() then return false end
    if not IsValid(ent) then return false end
    if not ent:GetClass():lower():find("door") then return false end
    return true
end

properties.Add("door_toggle", {
    MenuLabel = "Toggle Door",
    Order = 7,
    MenuIcon = "icon16/door.png",
    Filter = doorCheck,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать door_toggle на " .. (IsValid(ent) and ent:GetClass() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent:Fire("toggle")
    end
})

properties.Add("door_lock", {
    MenuLabel = "Lock Door",
    Order = 8,
    MenuIcon = "icon16/lock.png",
    Filter = doorCheck,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать door_lock на " .. (IsValid(ent) and ent:GetClass() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent:Fire("lock")
    end
})

properties.Add("door_unlock", {
    MenuLabel = "Unlock Door",
    Order = 9,
    MenuIcon = "icon16/lock_open.png",
    Filter = doorCheck,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать door_unlock на " .. (IsValid(ent) and ent:GetClass() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        ent:Fire("unlock")
    end
})

local defaultinv = {
    Weapons = {},
    Ammo = {},
    Armor = {},
    Attachments = {}
}

local function Respawn(ply, body)
    if ply:Alive() then ply:Kill() end
    ply.gottarespawn = true
    timer.Simple(0.1, function()
        ply:Spawn()
        timer.Simple(0.1, function()
            ply.inventory = table.Copy(body.inventory or defaultinv)
            ply:SetNetVar("Inventory", ply.inventory)
            ply:SetNetVar("Armor", body:GetNetVar("Armor", {}))
            ply:SetNetVar("HideArmorRender", body:GetNetVar("HideArmorRender", false))
            body:SetNetVar("Armor", {})
            body:SetNetVar("HideArmorRender", false)

            for k, v in pairs(ply.inventory["Weapons"]) do
                if v == true or not IsValid(v) then continue end
                v:SetParent(ply)
                v:SetOwner(ply)
                v:Use(ply)
            end
            for k, v in pairs(ply.inventory["Ammo"]) do
                ply:SetAmmo(v, k)
            end
            ply:Give("weapon_hands_sh")
            hg.Fake(ply, body)
            hg.LightStunPlayer(ply)

            timer.Simple(0.1, function()
                if body.CurAppearance then
                    local color = body:GetNWVector("PlayerColor", vector_origin)
                    body.CurAppearance.AColor = Color(color[1] * 255, color[2] * 255, color[3] * 255)
                    ply:SetPlayerColor(color)
                    hg.Appearance.ForceApplyAppearance(ply, body.CurAppearance)
                    ply:SetModel(body:GetModel())
                else
                    local Appearance = ply.CurAppearance or hg.Appearance.GetRandomAppearance()
                    Appearance.AColthes = ""
                    ply:SetNetVar("Accessories", "")
                    ply:SetModel(body:GetModel())
                    ply:SetSubMaterial()
                    ply:SetPlayerColor(ply:GetNWVector("PlayerColor", vector_origin))
                end
                ply:Give("weapon_hands_sh")
            end)
        end)
    end)
end
hg.RespawnIntoBody = Respawn

properties.Add("respawn_ply_in_rag", {
    MenuLabel = "Respawn Player",
    Order = 1,
    MenuIcon = "icon16/heart.png",
    Filter = function(self, ent, ply)
        if not ply:ZCTools_GetAccess() then return false end
        if not IsValid(ent) then return false end
        local pEnt = hg.RagdollOwner(ent) or ent
        if pEnt:IsRagdoll() then return true end
    end,
    Action = function(self, ent)
        hg.DermaPlayerQuery(function(ply)
            self:MsgStart()
                net.WriteEntity(ent)
                net.WriteEntity(ply)
            self:MsgEnd()
        end)
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        local sPly = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать respawn_ply_in_rag на " .. (IsValid(ent) and ent:GetClass() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        Respawn(sPly, ent)
    end
})

properties.Add("respawn_lply_in_rag", {
    MenuLabel = "Spawn Self",
    Order = 2,
    MenuIcon = "icon16/heart.png",
    Filter = function(self, ent, ply)
        if not ply:ZCTools_GetAccess() then return false end
        if not IsValid(ent) then return false end
        local pEnt = hg.RagdollOwner(ent) or ent
        if pEnt:IsRagdoll() then return true end
    end,
    Action = function(self, ent)
        Derma_Query(
            "You will take over this body, and respawn as this character.",
            "Are you sure?",
            "Yes",
            function()
                self:MsgStart()
                    net.WriteEntity(ent)
                    net.WriteEntity(LocalPlayer())
                self:MsgEnd()
            end,
            "No"
        )
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        local sPly = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать respawn_lply_in_rag на " .. (IsValid(ent) and ent:GetClass() or "хуй знает кто это") .. " (обход)")
            return
        end
        if not self:Filter(ent, ply) then return end
        Respawn(sPly, ent)
    end
})

--█████ 
--   █  
--  █   
-- █    
--█████ 

properties.Add("respawn_ragply_in_rag", {
    MenuLabel = "Spawn RagOwner",
    Order = 3,
    MenuIcon = "icon16/heart.png",
    Filter = function(self, ent, ply)
        if not ply:ZCTools_GetAccess() then return false end
        if not IsValid(ent) then return false end
        local pEnt = hg.RagdollOwner(ent) or ent
        if pEnt:IsRagdoll() then return true end
    end,
    Action = function(self, ent)
        Derma_Query(
            "The Player of this ragdoll will be respawned into his body",
            "Are you sure?",
            "Yes",
            function()
                self:MsgStart()
                    net.WriteEntity(ent)
                self:MsgEnd()
            end,
            "No"
        )
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not ply:IsAdmin() then
            ZashitaPrint(ply:Nick() .. " пытался использовать respawn_ragply_in_rag на " .. (IsValid(ent) and ent:GetClass() or "хуй знает кто это") .. " (обход)")
            return
        end
        local sPly = ent.ply
        if not self:Filter(ent, ply) then return end
        if not sPly then return end
        Respawn(sPly, ent)
    end
})


hook.Add("CanProperty", "Zashita_Properties", function(ply, property, ent)
    if not ply:IsAdmin() then return false end
end)

--if not ply:IsAdmin() then
	--if not ply:IsAdmin() then
		--if not ply:IsAdmin() then
			--if not ply:IsAdmin() then
				--if not ply:IsAdmin() then
					--if not ply:IsAdmin() then
				--end
			--end	
		--end	
	--end	
--end	