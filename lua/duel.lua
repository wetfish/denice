if duel_cooldown == nil then
	duel_cooldown = {}
end

function duelchar_callback(event, origin, params)
	local args = str_split_max(params[2], " ", 3)
	if #args ~= 3 then
		irc_msg(params[1], "Usage: !duelchar <class> <specialty> <character title>")
		return
	end

	if params[1] == get_config("bot:nick") then
		params[1] = origin
	end
	
	local class = args[1]:upper()
	local spec  = args[2]:upper()
	local title = args[3]

	local stats = sql_query_fetch("SELECT `ac`,`attack`,`damage`,`hp` FROM `duelclasses` WHERE `class`='" .. sql_escape(class) .. "'")
	if stats == nil or #stats == 0 then
		irc_msg(params[1], "The class you selected is not valid")
		return
	end
	stats = stats[1]

	if spec == "ARMOR" then
		stats.ac = stats.ac + 3
	elseif spec == "ATTACK" then
		stats.attack = stats.attack + 3
	elseif spec == "DAMAGE" then
		stats.damage = stats.damage + 3
	elseif spec == "HEALTH" then
		stats.hp = stats.hp + 3
	else
		irc_msg(params[1], "The specialty you selected is not valid")
		return
	end

	sql_fquery("DELETE FROM `duelchars` WHERE `nick`='"..sql_escape(origin).."'")
	sql_fquery("DELETE FROM `duelstats` WHERE `player1`='"..sql_escape(origin).."' OR `player2`='"..sql_escape(origin).."'")

	class = class:lower()

	sql_fquery(
		"INSERT INTO `duelchars` (`nick`,`title`,`armor`,`attack`,`damage`,`level`,`xp`,`hp`,`class`) VALUES " ..
		"('"..sql_escape(origin).."', '"..sql_escape(title).."', '"..stats.ac.."', '"..stats.attack.."', '"..stats.damage.."', '1', '0', '"..stats.hp.."', '"..sql_escape(class).."')"
	)

	irc_msg(params[1], "Welcome, "..origin..", "..title.."! Your stats are: "..stats.ac.." ARMOR / "..stats.attack.." ATTACK / "..stats.damage.." DAMAGE / "..stats.hp .." HEALTH")

end
register_command("duelchar", "duelchar_callback")

function duelhelp_callback(event, origin, params)
	local class_t   = sql_query_fetch("SELECT `class`,`ac`,`attack`,`damage`,`hp` FROM `duelclasses`")

	irc_msg(origin, "== CREATING A CHARACTER ==")
	irc_msg(origin, "To duel, you must make a character with the !duelchar command.")
	irc_msg(origin, "You use it to select a class, a specialty, and a title for your character.")
	irc_msg(origin, "Each class comes with base ARMOR, ATTACK, DAMAGE, and HEALTH stats.")
	irc_msg(origin, "Your specialty allows you to increase one of these stats by +3.")
	irc_msg(origin, "Your title is displayed after your nick, e.g. '"..origin.." the Wise'.")
	irc_msg(origin, "The character creation syntax is: !duelchar <class> <specialty> <character title>")
	irc_msg(origin, "The classes you can choose are: ")
	for i,c in pairs(class_t) do
		irc_msg(origin, "  - " .. c.class .. " (" .. c.ac .. " ARMOR / " .. c.attack .. " ATTACK / " .. c.damage .. " DAMAGE / " .. c.hp .. " HEALTH) ")
	end
	irc_msg(origin, "The specialties you can choose are: ARMOR ATTACK DAMAGE HEALTH")
	irc_msg(origin, " ")

	irc_msg(origin, "== DUELING ==")
	irc_msg(origin, "You may only duel someone who has also made a character.")
	irc_msg(origin, "To do so, simply use the command !duel <nick>")
	irc_msg(origin, "The outcome of the battle is decided by random chance combined with the players' stats.")
	irc_msg(origin, "A turn-by-turn description of the battle will be shown in #duel, but the outcome will also displayed in the channel the battle was initiated in.")
	irc_msg(origin, "The characters will fight to the death and the winner will gain +1 XP. However, no XP is awarded for defeating an opponent less than half your level.")
	irc_msg(origin, "Both characters will be restored to full HEALTH after the fight.")
	irc_msg(origin, " ")

	irc_msg(origin, "== LEVELING UP ==")
	irc_msg(origin, "When your XP reaches 10 + (LEVEL - 1)/2 you may level up.")
	irc_msg(origin, "Leveling up allows you to increase one of your stats by +1.")
	irc_msg(origin, "To do so, use !duellevel <stat> (the stats are the same as those you can choose as specialties.)")
	irc_msg(origin, "You can check your level progress by performing !duellevel without a stat as an argument.")	
	irc_msg(origin, " ")
end
register_command("duelhelp", "duelhelp_callback")

function duel_callback(event, origin, params)
	local p1_nick = origin
	local p2_nick = cleanSpace(params[2])

	if duel_cooldown[origin] ~= nil and duel_cooldown[origin] > os.time() - 60 then
		irc_msg(params[1], origin.. " : you must wait " .. (60 - (os.time() - duel_cooldown[origin])) .. " seconds to duel again.")
		return
	end

	duel_cooldown[origin] = os.time()

	local p1_stats = sql_query_fetch("SELECT `armor`,`attack`,`damage`,`level`,`xp`,`hp`,`title`,`class` FROM `duelchars` WHERE `nick`='"..sql_escape(p1_nick).."'")
	local p2_stats = sql_query_fetch("SELECT `armor`,`attack`,`damage`,`level`,`xp`,`hp`,`title`,`class` FROM `duelchars` WHERE `nick`='"..sql_escape(p2_nick).."'")

	if p1_stats == nil or #p1_stats == 0 then
		irc_msg(params[1], origin.. ": you must create a character! Try using !duelhelp.")
		return
	end

	if p2_stats == nil or #p2_stats == 0 then
		irc_msg(params[1], origin.." : you cannot duel "..params[2].." because they do not have a character!")
		return
	end

	p1_stats = p1_stats[1]
	p2_stats = p2_stats[1]

	p1_maxhp = p1_stats.hp
	p2_maxhp = p2_stats.hp
	p1_blood = 0
	p2_blood = 0

	irc_msg("#duel", p1_nick .. ", " .. p1_stats.title .. ", (level " .. p1_stats.level .. " " .. p1_stats.class .. ") has challenged " .. p2_nick .. ", " .. p2_stats.title ..
		", (level " .. p2_stats.level .. " " .. p2_stats.class .. ") to a duel!")

	while tonumber(p1_stats.hp) > 0 and tonumber(p2_stats.hp) > 0 do
		local p1_roll = math.random(1,20) + p1_stats.attack
		local p2_roll = math.random(1,20) + p2_stats.attack

		local p1_dmg = math.random(1,6) + p1_stats.damage
		local p2_dmg = math.random(1,6) + p2_stats.damage		

		if p1_roll > tonumber(p2_stats.armor) then
			local append = ""
			p2_stats.hp = p2_stats.hp - p1_dmg
			if p2_stats.hp < math.floor(p2_maxhp / 2) and p2_blood == 0 then
				p2_blood = 1
				append = " " .. p2_nick .. " is now bloodied!"
			end
			irc_msg("#duel", p1_nick .. " hits " .. p2_nick .. " for " .. p1_dmg .. " damage!"..append)
		else
			irc_msg("#duel", p1_nick .. " misses a blow at " .. p2_nick .. ".")
		end

		if p2_roll > tonumber(p1_stats.armor) then
			local append = ""
			p1_stats.hp = p1_stats.hp - p2_dmg
			if p1_stats.hp < math.floor(p1_maxhp / 2) and p1_blood == 0 then
				p1_blood = 1
				append = " " .. p1_nick .. " is now bloodied!"
			end
			irc_msg("#duel", p2_nick .. " hits " .. p1_nick .. " for " .. p2_dmg .. " damage!"..append)
		else
			irc_msg("#duel", p2_nick .. " misses a blow at " .. p1_nick .. ".")
		end

	end

	local battle_str = ""

	local stat_row = sql_query_fetch("SELECT * FROM `duelstats` WHERE (`player1`='"..sql_escape(p1_nick).."' AND `player2`='"..sql_escape(p2_nick).."') OR (`player2`='"..sql_escape(p1_nick).."' AND `player1`='"..sql_escape(p2_nick).."')")
	if stat_row == nil or #stat_row == 0 then
		stat_row = {}
		sql_fquery("INSERT INTO `duelstats` (`player1`,`player2`,`p1wins`,`p2wins`) VALUES ('"..sql_escape(p1_nick).."','"..sql_escape(p2_nick).."','0','0')")
		stat_row.index = sql_insert_id()
		stat_row.player1 = p1_nick
		stat_row.player2 = p2_nick
		stat_row.p1wins = 0
		stat_row.p2wins = 0
	else
		stat_row = stat_row[1]
	end

	if tonumber(p1_stats.hp) > tonumber(p2_stats.hp) then
		battle_str = p1_nick .. ", " .. p1_stats.title .. ", has defeated " .. p2_nick .. " by " .. (p1_stats.hp - p2_stats.hp) .. " HP!"
		if p1_stats.level / 2 <= tonumber(p2_stats.level) then
			p1_stats.xp = p1_stats.xp + 1
			battle_str = battle_str .. " " .. p1_nick .. " now has " .. p1_stats.xp .. "/" .. math.floor(10+(p1_stats.level-1)/2) .. " XP."
			sql_fquery("UPDATE `duelchars` SET `xp`=`xp`+1 WHERE `nick`='"..sql_escape(p1_nick).."'")
		end

		if stat_row.player1 == p1_nick then
			sql_fquery("UPDATE `duelstats` SET `p1wins`=`p1wins`+1 WHERE `index`='"..stat_row.index.."'")
			stat_row.p1wins = stat_row.p1wins + 1
			battle_str = battle_str .. " " .. p1_nick .. "'s record against " ..  p2_nick .. " is " .. stat_row.p1wins .. " wins, " .. stat_row.p2wins .. " losses."
		else
			sql_fquery("UPDATE `duelstats` SET `p2wins`=`p2wins`+1 WHERE `index`='"..stat_row.index.."'")			
			stat_row.p2wins = stat_row.p2wins + 1
			battle_str = battle_str .. " " .. p1_nick .. "'s record against " .. p2_nick .. " is " .. stat_row.p2wins .. " wins, " .. stat_row.p1wins .. " losses."
		end
	elseif tonumber(p1_stats.hp) < tonumber(p2_stats.hp) then
		battle_str = p2_nick .. ", " .. p2_stats.title .. ", has defeated " .. p1_nick .. " by " .. (p2_stats.hp - p1_stats.hp) .. " HP!"
		if p2_stats.level / 2 <= tonumber(p1_stats.level) then
			p2_stats.xp = p2_stats.xp + 1
			battle_str = battle_str .. " " .. p2_nick .. " now has " .. p2_stats.xp .. "/" .. math.floor(10+(p2_stats.level-1)/2) .. " XP."
			sql_fquery("UPDATE `duelchars` SET `xp`=`xp`+1 WHERE `nick`='"..sql_escape(p2_nick).."'")
		end
	
		if stat_row.player1 == p2_nick then
			sql_fquery("UPDATE `duelstats` SET `p1wins`=`p1wins`+1 WHERE `index`='"..stat_row.index.."'")
			stat_row.p1wins = stat_row.p1wins + 1
			battle_str = battle_str .. " " .. p2_nick .. "'s record against " .. p1_nick .. " is " .. stat_row.p1wins .. " wins, " .. stat_row.p2wins .. " losses."
		else
			sql_fquery("UPDATE `duelstats` SET `p2wins`=`p2wins`+1 WHERE `index`='"..stat_row.index.."'")			
			stat_row.p2wins = stat_row.p2wins + 1
			battle_str = battle_str .. " " .. p2_nick .. "'s record against " .. p1_nick .. " is " .. stat_row.p2wins .. " wins, " .. stat_row.p1wins .. " losses."
		end
	else
		battle_str = "The match ends in a draw!"
	end

	irc_msg("#duel", battle_str)
	if params[1] ~= "#duel" then
		irc_msg(params[1], battle_str)
	end


end
register_command("duel", "duel_callback")

function duellevel_callback(event, origin, params)
	local stats = sql_query_fetch("SELECT * FROM `duelchars` WHERE `nick`='"..sql_escape(origin).."'")

	if params[1] == get_config("bot:nick") then
		params[1] = origin
	end

	if stats == nil or #stats == 0 then
		irc_msg(params[1], origin.. " : you do not have a character!")
		return
	else
		stats = stats[1]
	end

	local req_xp = math.floor((stats.level - 1) / 2) + 10

	if params[2] == nil or params[2] == "" then
		irc_msg(params[1], origin .. ", " .. stats.title .. " - level " .. stats.level .. " " .. stats.class .. " - " ..
			stats.armor .. " ARMOR / " .. stats.attack .. " ATTACK / " ..  stats.damage .. " DAMAGE / " .. stats.hp .. " HEALTH - " ..
			stats.xp .. "/" .. req_xp .. " XP")
	else
		params[2] = cleanSpace(params[2]:upper())
		if req_xp <= tonumber(stats.xp) then
			local column = ""
			if params[2] == "ARMOR" then
				column = "armor"
				stats.armor = stats.armor + 1
			elseif params[2] == "ATTACK" then
				column = "attack"
				stats.attack = stats.attack + 1
			elseif params[2] == "DAMAGE" then
				column = "damage"
				stats.damage = stats.damage + 1
			elseif params[2] == "HEALTH" then
				column = "hp"
				stats. hp = stats.hp + 1
			else
				irc_msg(params[1], origin .. " : that is not a valid stat to level up")
			end

			if column ~= "" then
				stats.xp = stats.xp - req_xp
				stats.level = stats.level + 1
				req_xp = math.floor((stats.level - 1) / 2) + 10
				sql_fquery("UPDATE `duelchars` SET `level`=`level`+1, `xp`='"..stats.xp.."', `"..column.."`=`"..column.."`+1 WHERE `nick`='"..sql_escape(origin).."'")
				irc_msg(params[1], origin .. ", " .. stats.title .. " - level " .. stats.level .. " " .. stats.class .. " - " ..
					stats.armor .. " ARMOR / " .. stats.attack .. " ATTACK / " ..  stats.damage .. " DAMAGE / " .. stats.hp .. " HEALTH - " ..
					stats.xp .. "/" .. req_xp .. " XP")
			end
		else
			irc_msg(params[1], origin .. " : you need " ..(req_xp - stats.xp) .. " more XP to level up.")
		end
	end
end
register_command("duellevel", "duellevel_callback")

function duellist_callback(event, origin, params)
	local t = sql_query_fetch("SELECT `nick`,`title`,`level`,`class` FROM `duelchars` ORDER BY `level` DESC")
	local str = "Characters registered: "

	if params[1] == get_config("bot:nick") then
		params[1] = origin
	end

	for i,v in pairs(t) do
		str = str .. v.nick .. ", " .. v.title .." - level " .. v.level .." ".. v.class .." / "

		if str:len() > 200 then
			if i == #t then
				str = str:sub(1, str:len() - 3)
			end
			irc_msg(params[1], str)
			str = ""
		end
	end

	if str:len() > 0 then
		str = str:sub(1, str:len() - 3)
		irc_msg(params[1], str)
	end
end
register_command("duellist", "duellist_callback")
