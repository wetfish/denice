spam_cooldown = {}

function spam_callback(event, origin, params)

	if spam_cooldown[origin] ~= nil and spam_cooldown[origin] > os.time() - 120 then
		irc_msg(params[1], "Don't get too excited, " .. origin)
		return
	end

	if event == "!spam" then
		spam(params[2], origin, params[1])
	elseif event == "!rainbow" then
		rainbow(params[2], origin, params[1])
	elseif event == "!bigrainbow" then
		bigrainbow(params[2], origin, params[1])
	elseif event == "!biggerrainbow" then
		biggerrainbow(params[2], origin, params[1])
	elseif event == "!warning" then
		warning(params[2], origin, params[1])
	end

	spam_cooldown[origin] = os.time()

end
register_command("spam", "spam_callback")
register_command("rainbow", "spam_callback")
register_command("bigrainbow", "spam_callback")
register_command("biggerrainbow", "spam_callback")
register_command("warning", "spam_callback")

function spam(word,user,target)
	local buffer,buffer2 = "",""
	while buffer2:len() < 400 do
		for i,v in pairs(str_split(word," ")) do
			local c1,c2 = math.random(0,15),math.random(0,15)
			while c1==c2 do
				c2 = math.random(0,15)
			end
			if c1 < 10 then
				c1 = "0" .. c1
			end
			if c2 < 10 then
				c2 = "0" .. c2
			end
			buffer2 = buffer2 .. string.char(3) .. c1 .. "," .. c2 .. v .. string.char(15) .. " "
		end
	end
	irc_msg(target,buffer2:gsub("^%s*(.-)%s*$","%1"))
end

function rainbow(word,user,target)
	local f = io.popen("toilet -f term -F gay --irc -w " .. get_config("bot:spamwidth")  .. " > /tmp/denice_rainbow","w")
	f:write(word)
	f:close()
	local f = io.open("/tmp/denice_rainbow", "r")
	for line in f:lines() do
			irc_raw("PRIVMSG "..target.." :"..line)
	end
end

function bigrainbow(word,user,target)
	if word:len() > 256 then
		word=user.." is a big gay fag!"
	end
	local f = io.popen("toilet -f future -F gay --irc -w "  .. get_config("bot:spamwidth")  .. " > /tmp/denice_rainbow","w")
	f:write(word)
	f:close()
	local f = io.open("/tmp/denice_rainbow", "r")
	for line in f:lines() do
			irc_raw("PRIVMSG "..target.." :"..line)
	end
	f:close()
end

function biggerrainbow(word,user,target)
        if word:len() > 128 then
                word=user.." is a big gay fag!"
        end
        local f = io.popen("toilet -f mono9 -F gay --irc -w "  .. get_config("bot:spamwidth")  .. " > /tmp/denice_rainbow","w")
        f:write(word)
        f:close()
        local f = io.open("/tmp/denice_rainbow", "r")
        for line in f:lines() do
        	irc_raw("PRIVMSG "..target.." :"..line)
			--irc_msg(target,line:gsub("\n",""))
		end
        f:close()
end

function warning(word,user,target)
	irc_msg(target, irc_color("[B][I][U]/!\\[/U] " .. word .. " [U]/!\\[/U][/I][/B]"))
end
