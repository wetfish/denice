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
	local stack = NewStack()
	local phrase = ""
	local iterations = 0
	local done = false
	local done2 = false
	
	local target = 20
	local max_iterations = 512
	
	while (not done2 or #stack < target) and (iterations < max_iterations) do
		if done then
			done2 = true
		end
		if #stack == 0 then
			done = false
			done2 = false
			-- select first word
			local rows = sql_query_fetch("SELECT `Word1`,`Word2`,`Word3` FROM `dictionary` ORDER BY RAND() LIMIT 0,1")
			local w1 = rows[1].Word1
			local w2 = rows[1].Word2
			local w3 = rows[1].Word3
			local num_steps = 0
			local hit_end = false
			local t = NewStack()
			t:push(w3)
			t:push(w2)
			t:push(w1)
			-- attempt to build backward
			while not hit_end and num_steps < 100 do
				local _w2 = t:pop()
				local _w3 = t:pop()
				t:push(_w3)
				t:push(_w2)
				local rows = sql_query_fetch(
					"SELECT `Word1` FROM `dictionary` WHERE `Word2` = '"..sql_escape(_w2).."' "..
					"AND `Word3`='"..sql_escape(_w3).."' ORDER BY RAND() LIMIT 0,1"
				)
				if #rows == 0 then
					hit_end = true
				else
					t:push(rows[1].Word1)
				end
				num_steps = num_steps + 1
			end
			-- push the contents of temp stack onto main stack in reverse order
			while #t > 0 do
				stack:push(t:pop())
			end
		elseif #stack == 1 then
			-- start over
			stack:pop()
		else
			-- we should have at least 3 words at this point
			local w2 = stack:pop()
			local w1 = stack:pop()
			stack:push(w1)
			stack:push(w2)
			local rows = sql_query_fetch(
				"SELECT `Word3` FROM `dictionary` WHERE `Word1` = '"..sql_escape(w1).."' "..
				"AND `Word2` = '"..sql_escape(w2).."' ORDER BY RAND() LIMIT 0,2"
			)
			if #rows > 1 then
				stack:push(rows[1].Word3)
			elseif done and #rows > 0 then
				stack:push(rows[1].Word3)
			elseif not done then
					print("Popping 1 off the stack")
					stack:pop()	
					
					if iterations > max_iterations*.75 then
						done = true
						stack:pop()
					end
			else
				print("Done now")
				done2 = true
			end
		end
		iterations = iterations + 1
	end
	print("Done building stack (iterations="..iterations..")")
	
	-- take stack down
	while #stack > 0 do
		local w = stack:pop()
		if phrase:len() > 0 then
			phrase = w .. " " .. phrase
		else
			phrase = w
		end
	end

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
