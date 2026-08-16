
local allowedchars = {
	"ах",
	"АХ",
	"гхх",
	"ГХ",
	"АХХХ",
}

local audible_pain = {
	"ААААГХ.. БЛЯЯ.. БОЛИТ.",
	"Я БОЛЬШЕ НЕ МОГУ ЭТО ТЕРПЕТЬ!",
    "ПРЕКРАТИ ЭТО, ПРЕКРАТИ ЭТО, ПРЕКРАТИ ЭТО!!",
    "ПОЧЕМУ ЭТО НЕ ПРЕКРАЩАЕТСЯ!..",
    "Убей меня.. ПОЖАЛУЙСТА.",
    "Зачем я родился, чтобы чувствовать это, зачем...",
    "Я бы на всё пошёл, чтобы это прекратилось... НА ВСЁ.",
    "Это не жизнь, это ПЫТКА",
    "Мне всё равно, просто ПРЕКРАТИ БОЛЬ",
    "Ничто не имеет значения, КРОМЕ ТОГО, ЧТОБЫ ЭТО ПРЕКРАТИЛОСЬ...",
    "Каждая секунда — это вечность БОЛИ.",
    "СМЕРТЬ БЫЛА БЫ МИЛОСТЬЮ СЕЙЧАС...",
    "Хотя бы мгновение без боли..",
	"ВОТ БЫ СЕЙЧАС ОБЕЗБОЛА, БЛЯТЬ.",
}

local sharp_pain = {
	"АААХХ",
	"АААХ",
	"ААааАХ",
	"ААааАХ",
	"ААааАААГХ",
	"ААааАХ",
	"ААаАааХ",
	"АААААааХ",
	"ААааАХХХХ",
	"ААаАА",
	"АААААа",
	"ААААаАААаааагхх",
	"АААааАа",
	"АааААагхф",
	"ааАааАфф",
	"аааххх",
	"АААааГХХХ",
	"АААааААХХ",
	"АААааАААААаГХХХХ",
	"АААааАААААаГХАААХХХ",
	"АААааАААААаГХХААААААХХ",
	"АААааАААААаГХХХХ",
	"АААааАААааАААаГХХХХ",
	"АААааАААааАААаАААААААГХХХХ",
	"АААааАААААаГХХХХ",
	"АААааАААААААААХХХ",
	"АААааАААААаГХАаааХХ",
	"АААааАААААаАаааааААААХХ",
	"АААааАААААаААААААААДГХХХХ",
	"АААааАААааАААаАААААААААААААГГГГГГАГХХХХ",
	"АААааАААааАААаААААААААААААААААААХ",
}

hg.sharp_pain = sharp_pain

local random_phrase = {
	"Здесь как-то прохладно...",
	"Всё кажется слишком тихим...",
	"Дышать сейчас на удивление приятно.",
	"Что, если эта тишина продлится вечно?",
	"Почему ничего не происходит?",
}

local fear_hurt_ironic = {
	"Наверное, в этом есть урок... если я выживу.",
	"Мой будущий биограф не поверит в эту часть.",
	"Ну что ж, глупый способ умереть.",
	"По крайней мере, моя жизнь не была скучной.",
	"Заметка на будущее: никогда так не делать.",
	"Это не самый худший день для смерти.",
}

local fear_phrases = {
	"Не так уж и плохо... правда?",
	"Я не хочу так умереть.",
	"Неужели вот так всё закончится?",
	"Это плохо.",
	"Неужели вот так всё закончится?",
	"Я не хочу так умереть.",
	"Хотел бы я иметь выход.",
	"Я жалею о многом.",
	"Этого не может быть.",
	"Не могу поверить, что это происходит со мной.",
	"Мне следовало отнестись к этому серьёзнее.",
	"Что, если я не выживу..?",
	"Это хуже, чем я думал.",
	"Это так несправедливо.",
	"Я не могу сдаться.",
	"Я никогда не думал, что это будет так.",
	"Мне стоило прислушаться к инстинктам.",
	"Дыши. Просто дыши.",
	"Холодные руки...",
}

local is_aimed_at_phrases = {
    "О Боже... Это такой конец.",
    "Нельзя двигаться..",
    "Неужели я действительно так умру?",
    "Надо было бежать. Почему я не убежал?",
    "Пожалуйста, не нажимай на курок. Пожалуйста.",
    "Я вижу палец на спусковом крючке.",
    "Я не хочу умирать. Не так.",
    "Если я начну умолять, станет только хуже?",
    "Этого не может быть реальностью. Этого не может быть.",
    "Кто-нибудь, помогите мне. Пожалуйста. Кто-нибудь.",
    "Я не хочу умирать в таком месте.",
    "Я не хочу, чтобы моей последней мыслью был страх.",
    "Я не хочу умирать.",
}

local near_death_poetic = {
	"Я пытаюсь встать... но просто не могу...",
	"Дыхание — просто поверхностные глотки пустоты...",
	"Уже не понять, открыты у меня глаза или нет...",
	"Последнее, что я попробую — собственная кровь и медь.",
	"Взгляд всё время соскальзывает с предметов.",
	"Не могу вспомнить, как двигать ногами.",
	"Всё отдаётся эхом внутри черепа.",
	"Чтобы моргнуть, нужно слишком много времени.",
	"Пальцы не смыкаются ни на чём.",
	"Я не могу дышать...",
	"Сожаления теперь бессмысленны.",
}

local near_death_positive = {
	"Я не хочу умирать.",
	"Я должен выжить.",
	"Ещё есть шанс.",
	"Я не могу позволить страху победить.",
	"Ещё одна попытка.",
	"Я отказываюсь умирать здесь.",
	"Так... надо подумать.",
	"Просто не двигайся. От движений становится хуже.",
	"Дыши медленно. Паника не поможет.",
	"Всё не кончено, пока не кончено.",
	"Боль — это просто сигнал. Игнорируй его!",
	"Если это конец... по крайней мере, будет быстро.",
	"Я переживал и похуже. Наверное.",
	"Я представлял это иначе.",
}

local broken_limb = {
	"БЛЯТЬ. БЛЯТЬ. ОНО ТОЧНО СЛОМАНО!!",
	"Я ЧУВСТВУЮ, КАК КОСТИ ДВИГАЮТСЯ!",
	"ОНО, СУКА, СЛОМАНО. НАВЕРНОЕ..",
	"От одной мысли об этом больно. Точно сломано.",
	"Не думаю, что оно тут должно сгибаться.",
	"Твою мать, Оно сломано.",
	"Я не вижу открытого перелома, но чувствую, что сломал что-то.",
}

local dislocated_limb = {
	"Да, оно не должно так сгибаться.",
	"Мне нужно вправить эту кость обратно.",
	"Нет... Я должен вправить её обратно.",
	"Так сильно болит..",
	"Моя конечность не на месте.",
}

local hungry_a_bit = {
    "Мгх, я голоден...",
    "Вот бы сейчас покушать...",
    "Я голоден...",
    "Мне стоит что-нибудь съесть.",
}

local very_hungry = {
    "Живот... Угх...",
    "Если я не поем, мне станет ещё хуже...",
    "Желудок... Чёрт... Меня тошнит.",
}

local after_unconscious = {
    "Что случилось? Так больно...",
	"Где я? Почему так больно...",
	"Я-я думал, что умру...",
	"Моя голова... Что произошло?",
	"Я чуть не умер только что?",
	"Было такое чувство, будто я умер.",
	"Небеса не приняли меня?",
	"Сукааа... голова раскалывается...",
	"Сейчас будет трудно встать... но надо...",
	"Знакомое место... Или нет?..",
	"Я никогда не хахочу пережить это снова...",
}

local slight_braindamage_phraselist = {
	"Я не понимаю...",
	"Это не имеет смысла...",
	"Где я?",
	"А? Что это..?",
	"Я не знаю, что происходит...",
	"Алло?",
	"Угххх ооохххх... ахх...",
	"Что... происходит?",
}

local braindamage_phraselist = {
	"Бббээ.. гдээ а мгх?!",
	"Бммэээ... мэхк...",
	"Мм--хххх. Ммм?",
	"Гхмгх уххх...",
	"Ахгг...мг?",
	"Хггхх... Д-Дммх.",
	"Лмммпхф, мп-хф!",
	"Хэээлллххппхп...",
	"Нгхх... Гмх?",
	"Ггг... Бгх..",
	"Бхрхраихн.",
}

local cold_phraselist = {
	"Становится очень холодно..",
	"Слишком холодно для меня.",
	"Меня трясёт, твою мать.",
	"Жуткий холод снаружи..",
	"Нужно чем-то согреться...",
	"Мне довольно холодно...",
	"Меня тошнит от этого холода, бля."
}

local freezing_phraselist = {
	"Я.. не.. не ч-чув-ствую св-воё т-тело..",
	"Я не ч-чую св-вои ноги...",
	"Я з-за-мер-заю..",
	"У-у ме-ня л-лицо о-неме-ло..",
	"Хо-ло-дно..",
	"Я.. ни-иче-го не чу-вствую..",
}

local numb_phraselist = {
	"Уже не.. холодно..",
	"Ощущается тепло..?",
	"Кажется, я в порядке... кажется...",
	"Наконец-то тепло...",
	"Мне снова тепло... Странно...",
	"Я только что замерзал... Теперь нет?",
}

local hot_phraselist = {
	"Я весь в поту..",
	"Эта жара меня убивает..",
	"Моя одежда пропитана потом, сука.",
	"Мой пот воняет. Мне правда стоит остыть...",
	"Слишком жарко, блин.",
	"Меня сильно разогревает...",
	"Почему здесь так жарко?",
}

local heatstroke_phraselist = {
	"МНЕ НУЖНА ВОДА!!",
	"Пожалуйста... воду...",
	"У меня кружится голова... Бляя-",
	"МОЯ ГОЛОВА!- Она болит..",
	"У меня голова раскалывается..",
}

local heatvomit_phraselist = {
	"Эта жара..- меня сейчас вырвет-",
	"Угххх... Меня сейчас вырвет-",
	"Бля.. Оугххх.. Мне плохо-"
}

local hg_showthoughts = ConVarExists("hg_showthoughts") and GetConVar("hg_showthoughts") or CreateClientConVar("hg_showthoughts", "1", true, true, "Toggle thoughts of your character", 0, 1)

function string.Random(length)
	local length = tonumber(length)

    if length < 1 then return end

    local result = {}

    for i = 1, length do
        result[i] = allowedchars[math.random(#allowedchars)]
    end

    return table.concat(result)
end

function hg.nothing_happening(ply)
	if not IsValid(ply) then return end

	return ply.organism and ply.organism.fear < -0.6
end

function hg.fearful(ply)
	if not IsValid(ply) then return end

	return ply.organism and ply.organism.fear > 0.5
end

function hg.likely_to_phrase(ply)
	local org = ply.organism

	local pain = org.pain
	local brain = org.brain
	local blood = org.blood
	local fear = org.fear
	local temperature = org.temperature
	local broken_dislocated = org.just_damaged_bone and ((org.just_damaged_bone - CurTime()) < -3)

	return (broken_dislocated) and 5
		or (pain > 65) and 5
		or (temperature < 31 and 0.5)
		or (temperature > 38 and 0.5)
		or (blood < 3000 and 0.3)
		--or (fear > 0.5 and 0.7)
		or (brain > 0.1 and brain * 5)
		or (fear < -0.5 and 0.05)
		or -0.1
end

function IsAimedAt(ply)
    return ply.aimed_at or 0
end

local function get_status_message(ply)
	if not IsValid(ply) then
		if CLIENT then
			ply = lply
		else
			return
		end
	end

	local nomessage = hook.Run("HG_CanThoughts", ply) --ply.PlayerClassName == "Gordon" || ply.PlayerClassName == "Combine"
	if nomessage ~= nil and nomessage == false then return "" end

    if ply:GetInfoNum("hg_showthoughts", 1) == 0 then return "" end

	local org = ply.organism
	
	if not org or not org.brain then return "" end

	local pain = org.pain
	local brain = org.brain
	local temperature = org.temperature
	local blood = org.blood
	local hungry = org.hungry
	local broken_dislocated = org.just_damaged_bone and ((org.just_damaged_bone + 3 - CurTime()) < -3)

	if broken_dislocated and org.just_damaged_bone then
		org.just_damaged_bone = nil
	end
	
	local broken_notify = (org.rarm == 1) or (org.larm == 1) or (org.rleg == 1) or (org.lleg == 1)
	local dislocated_notify = (org.rarm == 0.5) or (org.larm == 0.5) or (org.rleg == 0.5) or (org.lleg == 0.5)
	local after_unconscious_notify = org.after_otrub

	if not isnumber(pain) then return "" end

	local str = ""

	local most_wanted_phraselist
	
	if temperature < 35 then
		most_wanted_phraselist = temperature > 31 and cold_phraselist or (temperature < 28 and numb_phraselist or freezing_phraselist)
	elseif temperature > 38 then
		most_wanted_phraselist = temperature < 40 and hot_phraselist or heatstroke_phraselist
	end

	if not most_wanted_phraselist and hungry and hungry > 25 and math.random(3) == 1 then
		most_wanted_phraselist = hungry > 45 and very_hungry or hungry_a_bit
	end

	if (blood < 3100) or (pain > 75) or (broken_dislocated) or (broken_notify) or (dislocated_notify) then
		if pain > 75 and (broken_dislocated) then
			most_wanted_phraselist = math.random(2) == 1 and audible_pain or (broken_notify and broken_limb or dislocated_limb)
		elseif pain > 75 then
			most_wanted_phraselist = audible_pain
		elseif broken_dislocated then
			most_wanted_phraselist = (broken_notify and broken_limb or dislocated_limb)
		end

		if pain > 100 then
			most_wanted_phraselist = sharp_pain
		end

		if not most_wanted_phraselist then
			if (broken_dislocated_notify) and (blood < 3100) then
				most_wanted_phraselist = blood < 2900 and (near_death_poetic) or (math.random(2) == 1 and (broken_notify and broken_limb or dislocated_limb) or near_death_poetic)
			--elseif(broken_dislocated_notify)then
				--most_wanted_phraselist = (broken_notify and broken_limb or dislocated_limb)
			elseif(blood < 3100)then
				most_wanted_phraselist = near_death_poetic
			end
		end
	elseif after_unconscious_notify then
		most_wanted_phraselist = after_unconscious
	elseif hg.nothing_happening(ply) then
		most_wanted_phraselist = random_phrase

		if hungry and hungry > 25 and math.random(5) == 1 then
			most_wanted_phraselist = hungry > 45 and very_hungry or hungry_a_bit
		end
	elseif hg.fearful(ply) then
		most_wanted_phraselist = ((IsAimedAt(ply) > 0.9) and is_aimed_at_phrases or (math.random(10) == 1 and fear_hurt_ironic or fear_phrases))
	end

	if brain > 0.1 then
		most_wanted_phraselist = brain < 0.2 and slight_braindamage_phraselist or braindamage_phraselist
	end
	
	if most_wanted_phraselist then
		str = most_wanted_phraselist[math.random(#most_wanted_phraselist)]

		return str
	else
		return ""
	end
end

local allowedlist_types = {
	heatvomit = heatvomit_phraselist,
}

function hg.get_phraselist(ply, type)
	if not IsValid(ply) then
		if CLIENT then
			ply = lply
		else
			return
		end
	end
	
	local nomessage = ply.PlayerClassName == "Gordon" || ply.PlayerClassName == "Combine"

	if nomessage then return "" end
    if ply:GetInfoNum("hg_showthoughts", 1) == 0 then return "" end

	local org = ply.organism	
	if not org or not org.brain then return "" end

	if not isstring(type) or not allowedlist_types[type] then return "" end

	local needed_list = allowedlist_types[type]

	local str = needed_list[math.random(#needed_list)]
	return str
end

function hg.get_status_message(ply)
	local txt = get_status_message(ply)

	return txt
end
