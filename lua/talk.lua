function talk_parse(event, origin, params)
	local word1,word2
	for i,word in pairs(str_split(params[2]," ")) do
		if word ~= nil then
			if word1 ~= nil then
				if word2 ~= nil then
					local q=sql_query(
						"INSERT INTO `dictionary` (`Word1`, `Word2`, `Word3`, `DateAdded`) " ..
						"VALUES('"..sql_escape(word2).."','"..sql_escape(word1).."','"..sql_escape(word).."','"..os.time().."')"
					)
					sql_free(q)
				end
				word2 = word1		
			end
			word1 = word
		end
	end

end
register_callback("CHANNEL", "talk_parse")

function talk(channel, retmode)
	local word1,word2,word3
	local phrase
	while word1 == nil do
		for i,row in pairs(sql_query_fetch("SELECT `Word1` FROM `dictionary` ORDER BY RAND() LIMIT 0,1")) do
			print("Trying "..row.Word1.." as Word1.")
			local mid_count = sql_query_fetch("SELECT COUNT(*) FROM `dictionary` WHERE `Word3` = '"..sql_escape(row.Word1).."'")
			local beg_count = sql_query_fetch("SELECT COUNT(*) FROM `dictionary` WHERE `Word1` = '"..sql_escape(row.Word1).."'")
			if tonumber(mid_count[1]['COUNT(*)']) < 2 and tonumber(beg_count[1]['COUNT(*)']) > 4  then
				word1 = row.Word1
				for i,temp2 in pairs(sql_query_fetch("SELECT `Word2` FROM `dictionary` WHERE `Word1`='"..sql_escape(word1).."' ORDER BY RAND() LIMIT 0,1")) do
					print("Selected "..temp2.Word2.." as Word2.")
					word2 = temp2.Word2
				end
			end
		end
	end
	phrase = word1.." "..word2
	local dead = false
	repeat
		print("Searching for a Word3...")
                local count = sql_query_fetch("SELECT COUNT(*) FROM `dictionary` WHERE `Word1` = '"..sql_escape(word1).."' AND `Word2` = '"..sql_escape(word2).."'")
		if tonumber(count[1]['COUNT(*)']) > 0 then
			for i,word3 in pairs(sql_query_fetch("SELECT `Word3` FROM `dictionary` WHERE `Word1` = '"..sql_escape(word1).."' AND `Word2`='"..sql_escape(word2).."' ORDER BY RAND() LIMIT 0,1")) do
				print("Selecting "..word3.Word3.." as Word3.")
				phrase=phrase.." "..word3.Word3
				word1 = word2
				word2 = word3.Word3
			end
		else
			print("Couldn't find another word...")
			dead = true
		end
	until (phrase:len() >= 100 and math.random(10) == 1) or dead

	local isAction=false
	if phrase:sub(0,8)=="ACTION " then
		isAction=true
	end
	phrase = phrase:gsub("","")
	if isAction then
		phrase = ""..phrase..""
	end
	if retmode == nil then
		irc_msg(channel,phrase)
	else
		return phrase
	end
end
