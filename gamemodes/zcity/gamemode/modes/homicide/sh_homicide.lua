local MODE = MODE
MODE.name = "hmcd"
MODE.PrintName = "Homicide"

--\\
MODE.TraitorExpectedAmtBits = 13
--//

--\\Sub Roles
MODE.ConVarName_SubRole_Traitor_SOE = "hmcd_subrole_traitor_soe"
MODE.ConVarName_SubRole_Traitor = "hmcd_subrole_traitor"

if(CLIENT)then
	MODE.ConVar_SubRole_Traitor_SOE = CreateClientConVar(MODE.ConVarName_SubRole_Traitor_SOE, "traitor_default_soe", true, true, "Select traitor role in State of Emergency homicide mode")
	MODE.ConVar_SubRole_Traitor = CreateClientConVar(MODE.ConVarName_SubRole_Traitor, "traitor_default", true, true, "Select murder role in Standard homicide modes")
end

--; TODO
--; Инженер - шахид бомба + иеды

MODE.SubRoles = {
	--=\\Предатель
	--==\\
	--; https://youtu.be/zP7ux8WsYYI?si=S-Uw2EAehGR5WD3D
	["traitor_default"] = {
		Name = "Дефоко",
		Description = [[Стандартный.
Ты долго готовился к этому.
Ты экипирован различным оружием, ядами и взрывчаткой, гранатами, твоим любимым тяжёлым ножом и сигнальным пистолетом Zoraki, чтобы помочь тебе убивать.]],
		Objective = "Ты вооружён предметами, ядами, взрывчаткой и оружием, спрятанными в твоих карманах. Убей всех здесь.",
		SpawnFunction = function(ply)
			local wep = ply:Give("weapon_zoraki")
			
			timer.Simple(1, function()
				wep:ApplyAmmoChanges(2)
			end)
			
			ply:Give("weapon_buck200knife")	
			ply:Give("weapon_hg_rgd_tpik")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_shuriken")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_traitor_ied")
			ply:Give("weapon_traitor_poison1")
			ply:Give("weapon_traitor_suit")
			ply:Give("weapon_hg_jam")
			-- ply:Give("weapon_traitor_poison2")
			-- ply:Give("weapon_traitor_poison3")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_default_soe"] = {
		Name = "Дефоко",
		Description = [[Стандартный.
Ты долго готовился к этому моменту.
Ты экипирован различным оружием, ядами и взрывчаткой, гранатами, твоим любимым тяжёлым ножом и глушённым пистолетом с дополнительным магазином, чтобы помочь тебе убивать.]],
		Objective = "Ты вооружён предметами, ядами, взрывчаткой и оружием, спрятанными в твоих карманах. Убей всех здесь.",
		SpawnFunction = function(ply)
			if not IsValid(ply) then return end
			local p22 = ply:Give("weapon_p22")
			if not IsValid(p22) then return end
			ply:GiveAmmo(p22:GetMaxClip1() * 1, p22:GetPrimaryAmmoType(), true)
			
			hg.AddAttachmentForce(ply, p22, "supressor4")
			ply:Give("weapon_sogknife")	
			ply:Give("weapon_hg_rgd_tpik")
			-- ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_traitor_ied")
			ply:Give("weapon_traitor_poison2")
			ply:Give("weapon_traitor_poison3")
			
			ply.organism.recoilmul = 1
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory",inv)
		end,
	},
	--==//
	
	--==\\
	["traitor_infiltrator"] = {
		Name = "Инфильтратор",
		Description = [[Может сворачивать шеи людям со спины.
Может полностью маскироваться под других игроков, если они в регдолле.
Не имеет оружия или инструментов, кроме ножа, эпипена и дымовой гранаты.
Для тех, кто любит играть в шахматы.]],
		Objective = "Ты эксперт по отвлечению внимания. Будь осторожен и убивай по одному",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_infiltrator_soe"] = {
		Name = "Инфильтратор",
		Description = [[Может сворачивать шеи людям со спины.
Может полностью маскироваться под других игроков, если они в регдолле.
Имеет дымовую гранату, рацию, нож, электрошокер с 2 дополнительными зарядными головками и эпипен.
Для тех, кто любит играть в шахматы.]],
		Objective = "Ты эксперт по отвлечению внимания. Будь осторожен и убивай по одному",
		SpawnFunction = function(ply)
			local taser = ply:Give("weapon_taser")
			
			ply:GiveAmmo(taser:GetMaxClip1() * 2, taser:GetPrimaryAmmoType(), true)
			ply:Give("weapon_sogknife")
			-- ply:Give("weapon_hg_rgd_tpik")
			-- ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			
			ply.organism.recoilmul = 1
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	--==//
	
	--==\\
	--; СДЕЛАТЬ ЕМУ ЛУТ ДРУГИХ ИГРОКОВ ДАЖЕ ПОКА У НИХ НЕТ ПУШКИ В РУКАХ
	--; Сделать ему вырубание по вагус нерву
	["traitor_assasin"] = {
		Name = "Ассасин",
		Description = [[Может быстро обезоруживать людей с любого ракурса.
Обезоруживает быстрее со спины.
Обезоруживает быстрее спереди, если жертва в регдолле.
Искусен в стрельбе из оружия.
Имеет дополнительную выносливость (+ 80 единиц по сравнению с другими предателями).
Экипирован рацией.
Для тех, кто любит играть в шашки.]],
		Objective = "Ты эксперт по оружию и обезоруживанию. Обезоружь стрелка и используй его оружие против других",
		SpawnFunction = function(ply)
			-- ply:Give("weapon_sogknife")	
			-- ply:Give("weapon_adrenaline")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_hg_shuriken")
			
			ply.organism.recoilmul = 0.8
			ply.organism.stamina.max = 300
			--local inv = ply:GetNetVar("Inventory", {}) // ПОЧЕМУ КТО-ТО ЗАКОММЕНТИЛ ЭТО
			--inv["Weapons"]["hg_flashlight"] = true
			
			--ply:SetNetVar("Inventory", inv) // НО НЕ ЭТО???
		end,
	},
	["traitor_assasin_soe"] = {
		Name = "Ассасин",
		Description = [[Может быстро обезоруживать людей с любого ракурса.
Обезоруживает быстрее со спины.
Обезоруживает быстрее спереди, если жертва в регдолле.
Искусен в стрельбе из оружия.
Имеет дополнительную выносливость (+ 80 единиц по сравнению с другими предателями).
Экипирован рацией, ножом, эпипеном и фонариком.
Для тех, кто любит играть в шашки.]],
		Objective = "Ты эксперт по оружию и обезоруживанию. Обезоружь стрелка и используй его оружие против других",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")	
			ply:Give("weapon_adrenaline")
			-- ply:Give("weapon_walkie_talkie")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_hg_shuriken")
			
			ply.organism.recoilmul = 0.4
			ply.organism.stamina.max = 300
			--local inv = ply:GetNetVar("Inventory", {}) // ПОЧЕМУ КТО-ТО ЗАКОММЕНТИЛ ЭТО
			--inv["Weapons"]["hg_flashlight"] = true
			
			--ply:SetNetVar("Inventory", inv) // НО НЕ ЭТО???
		end,
	},
	--==//
	
	--==\\
	["traitor_chemist"] = {
		Name = "Химик",
		Description = [[Имеет множество химических агентов, эпипен и нож.
Устойчив в определённой степени ко всем упомянутым химическим агентам.
Может обнаруживать наличие и концентрацию химических агентов в воздухе.]],
		Objective = "Ты химик, который решил использовать свои знания, чтобы причинять вред другим. Отрави всё.",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_traitor_poison1")
			ply:Give("weapon_traitor_poison2")
			ply:Give("weapon_traitor_poison3")
			ply:Give("weapon_traitor_poison4")
			ply:Give("weapon_traitor_poison_consumable")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
			CleanChemicalsOfPlayer(ply)
		end,
	},
	--==//
	-- ["traitor_demoman"] = {
		-- Name = "Подрывник",
		-- Description = [[Имеет множество взрывчатых веществ.
-- Может заминировать определённые предметы
-- (Радио, некоторые расходники и т.д.)]],
		-- Objective = "Ты лучший химик, который решил использовать знания, чтобы причинять вред другим.",
		-- SpawnFunction = function(ply)
			-- ply:Give("weapon_sogknife")
			-- ply:Give("weapon_adrenaline")
			-- ply:Give("weapon_hg_rgd_tpik")
			-- ply:Give("weapon_hg_pipebomb_tpik")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_traitor_ied")
			-- ply:Give("weapon_walkie_talkie")
			
			-- ply.organism.stamina.max = 220
			-- local inv = ply:GetNetVar("Inventory", {})
			-- inv["Weapons"]["hg_flashlight"] = true
			
			-- ply:SetNetVar("Inventory", inv)
		-- end,
	-- },
	["traitor_zombie"] = {
		Name = "Зомби",
		Description = [[Может бесшумно заражать других игроков.
Заражённых игроков может вылечить доктор.
Если все игроки будут вылечены, зомби проиграет.
Вместо смерти будет случайно перемещён в тело другого заражённого игрока.
Не имеет оружия или каких-либо инструментов.
Несмотря на то, что является зомби, выглядит как обычный человек.]],
		Objective = "Ты зомби. Зарази всех, чтобы победить. Избегай доктора.",
		SpawnFunction = function(ply)
			-- ply:Give("weapon_sogknife")	
			-- ply:Give("weapon_adrenaline")
			
			-- ply.organism.stamina.max = 220
			-- local inv = ply:GetNetVar("Inventory", {})
			-- inv["Weapons"]["hg_flashlight"] = true
			
			-- ply:SetNetVar("Inventory", inv)
		end,
	},
	--=//
}
--//

--\\Professions
MODE.ProfessionsRoundTypes = {
	["standard"] = true,
	["soe"] = true,
}

MODE.Professions = {
	["doctor"] = {
		Name = "Доктор",
		SpawnFunction = function(ply)	--; TODO СДЕЛАТЬ ЧТОБЫ РАБОТАЛО
			--; Это плохая практика - выдавать профессиям оружие или инструменты
		end,
	},
	["huntsman"] = {
		Name = "Охотник",
		SpawnFunction = function(ply)
			--; Это плохая практика - выдавать профессиям оружие или инструменты
		end,
	},
	["engineer"] = {
		Name = "Инженер",
		SpawnFunction = function(ply)
			--; Это плохая практика - выдавать профессиям оружие или инструменты
		end,
	},
	["cook"] = {
		Name = "Повар",
		SpawnFunction = function(ply)
			--; Это плохая практика - выдавать профессиям оружие или инструменты
		end,
	},
	["builder"] = {
		Name = "Строитель",
		SpawnFunction = function(ply)
			--; Это плохая практика - выдавать профессиям оружие или инструменты
		end,
	},
}
--//

--\\
--; Названия перменных чуть чуть конченные получились, нужно будет подумать как улучшить
--; ужас
MODE.FadeScreenTime = 1.5
MODE.DefaultRoundStartTime = 6
MODE.RoleChooseRoundStartTime = 10

MODE.RoleChooseRoundTypes = {
	["standard"] = {
		TraitorDefaultRole = "traitor_default",
		Traitor = {
			["traitor_default"] = true,
			["traitor_infiltrator"] = true,
			["traitor_chemist"] = true,
			["traitor_assasin"] = true,
			--; ОБЪЕДЕНИТЬ ХИМИКА И ДИВЕРСАНТА!!! наверное
			-- ["traitor_demoman"] = true,
		},
		Professions = {
			["doctor"] = {
				Chance = 1,
			},
			["huntsman"] = {
				Chance = 1,
			},
			["engineer"] = {
				Chance = 1,
			},
			["cook"] = {
				Chance = 1,
			},
			["builder"] = {
				Chance = 1,
			},
		},
	},
	["soe"] = {
		TraitorDefaultRole = "traitor_default_soe",
		Traitor = {
			["traitor_default_soe"] = true,
			["traitor_infiltrator_soe"] = true,
			-- ["traitor_chemist_soe"] = true,
			["traitor_assasin_soe"] = true,
			-- ["traitor_demoman_soe"] = true,
		},
		Professions = {
			["doctor"] = {
				Chance = 1,
			},
			["huntsman"] = {
				Chance = 1,
			},
			["engineer"] = {
				Chance = 1,
			},
			["cook"] = {
				Chance = 1,
			},
		},
	},
}
--//

MODE.Roles = {}
MODE.Roles.soe = {
	traitor = {
		name = "Предатель",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Невиновный",
		color = Color(158,0,190)
	},

	innocent = {
		name = "Невиновный",
		color = Color(0,120,190)
	},
}

MODE.Roles.standard = {
	traitor = {
		objective = "Ты долго готовился к этому. Убей всех.",
		name = "Убийца",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Наблюдатель",
		color = Color(158,0,190)
	},

	innocent = {
		name = "Наблюдатель",
		color = Color(0,120,190)
	},
}

MODE.Roles.wildwest = {
	traitor = {
		objective = "Ты долго готовился к этому. Убей всех.",
		name = "Убийца",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Наблюдатель",
		color = Color(159,85,0)
	},

	innocent = {
		name = "Наблюдатель",
		color = Color(159,85,0)
	},
}

MODE.Roles.gunfreezone = {
	traitor = {
		name = "Убийца",
		color = Color(190,0,0)
	},

	gunner = {
		name = "Невиновный",
		color = Color(0,120,190)
	},

	innocent = {
		name = "Невиновный",
		color = Color(0,120,190)
	},
}

MODE.Roles.supermario = {
	traitor = {
		objective = "Ты злой Марио! Прыгай вокруг и расправляйся со всеми.",
		name = "Марио-предатель",
		color = Color(190,0,0)
	},

	gunner = {
		objective = "Ты герой Марио! Используй свою способность прыгать, чтобы остановить предателя.",
		name = "Марио-герой",
		color = Color(158,0,190)
	},

	innocent = {
		objective = "Ты Марио-наблюдатель, выживай и избегай ловушек предателя!",
		name = "Невиновный Марио",
		color = Color(0,120,190)
	},
}

function MODE.GetPlayerTraceToOther(ply, aim_vector, dist)
	local trace = hg.eyeTrace(ply, dist, nil, aim_vector)
	
	if(trace)then
		local aim_ent = trace.Entity
		local other_ply = nil
		
		if(IsValid(aim_ent))then
			if(aim_ent:IsPlayer())then
				other_ply = aim_ent
			elseif(aim_ent:IsRagdoll())then
				if(IsValid(aim_ent.ply))then
					other_ply = aim_ent.ply
				end
			end
		end
		
		return aim_ent, other_ply, trace
	else
		return nil
	end
end