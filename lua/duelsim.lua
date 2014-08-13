function duelsim()

	local classes = {}

	function round(num, idp)
	  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
	end

	function count(table)
		local n = 0
		for i in pairs(table) do
			n = n + 1
		end
		return n
	end

	function deepcopy(orig)
	    local orig_type = type(orig)
	    local copy
	    if orig_type == 'table' then
	        copy = {}
	        for orig_key, orig_value in next, orig, nil do
	            copy[deepcopy(orig_key)] = deepcopy(orig_value)
	        end
	        setmetatable(copy, deepcopy(getmetatable(orig)))
	    else
	        copy = orig
	    end
	    return copy
	end

	function add_class(name, armor, attack, damage, health)
		classes[name] = {}
		classes[name].armor  = armor
		classes[name].attack = attack
		classes[name].damage = damage
		classes[name].health = health
	end
	
	function sim_duel(class1, class2)
	
		local p1_stats = deepcopy(classes[class1])
		local p2_stats = deepcopy(classes[class2])
	
		while tonumber(p1_stats.health) > 0 and tonumber(p2_stats.health) > 0 do
			local p1_roll = math.random(1,20) 
			local p2_roll = math.random(1,20)
	
			local p1_dmg = math.random(1,10) + p1_stats.damage
			local p2_dmg = math.random(1,10) + p2_stats.damage
			
			if p1_roll == 20 then
				p1_dmg = 10 + p1_stats.damage + 1
			end
			
			if p2_roll == 20 then
				p2_dmg = 10 + p1_stats.damage + 1
			end
	
			if p1_roll == 20 or p1_roll + p1_stats.attack > tonumber(p2_stats.armor) then
				p2_stats.health = p2_stats.health - p1_dmg
			end
	
			if p2_roll == 20 or p2_roll + p2_stats.attack > tonumber(p1_stats.armor) then
				p1_stats.health = p1_stats.health - p2_dmg
			end
	
		end
	
		if tonumber(p1_stats.health) > tonumber(p2_stats.health) then
			return 1
		elseif tonumber(p1_stats.health) < tonumber(p2_stats.health) then
			return 2
		else
			return 0
		end
		
	end
	
	function sim_n_duels(class1, class2, n)
		local c1_wins = 0
		local c2_wins = 0
		for i=1,n do
			local result = sim_duel(class1, class2)
			if result == 1 then
				c1_wins = c1_wins + 1
			elseif result == 2 then
				c2_wins = c2_wins + 1
			end
		end
		local c1_perc = round(c1_wins/n,4) * 100
		local c2_perc = round(c2_wins/n,4) * 100
		return c1_wins, c2_wins
	end
	
	function challenge(class1, class2)
		local p1_a, p2_a = sim_n_duels(class1, class2, 500)
		local p2_b, p1_b = sim_n_duels(class2, class1, 500)
		
		local p1_perc = round((p1_a + p1_b) / 1000 * 100, 2)
		local p2_perc = round((p2_a + p2_b) / 1000 * 100, 2)
		local draw    = 100 - p1_perc - p2_perc
		
		return string.format("%s: %2.2f%% / %s: %2.2f%% / %s: %2.2f%%", class1, p1_perc, class2, p2_perc, "draw", draw)
	end
	
	return {add_class = add_class, challenge = challenge}

end

function duelsim_cmd(event, origin, params)
	if origin ~= get_config("bot:master") then
		return
	end

	local args = str_split(params[2], " ")
	
	if #args ~= 2 then
		return
	end

	local p1 = cleanSpace(args[1])
	local p2 = cleanSpace(args[2])

	local s1 = sql_query_fetch("SELECT `armor`, `attack`, `damage`, `hp` FROM `duelchars` WHERE `nick` = '"..sql_escape(p1).."'")[1]
	local s2 = sql_query_fetch("SELECT `armor`, `attack`, `damage`, `hp` FROM `duelchars` WHERE `nick` = '"..sql_escape(p2).."'")[1]

	if s1 == nil or s2 == nil then
		return
	end

	local d = duelsim()
	d.add_class(p1, s1.armor, s1.attack, s1.damage, s1.hp)
	d.add_class(p2, s2.armor, s2.attack, s2.damage, s2.hp)

	irc_msg(params[1], d.challenge(p1, p2))

end
register_command("duelsim", "duelsim_cmd")
