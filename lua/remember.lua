function remember_callback(event, origin, params)
	if event == "!remember" then
		--remember(params[2], origin, params[1])
		remember(params[2], origin, origin)
	elseif event == "!forget" then
		--forget(params[2], origin, params[1])
		forget(params[2], origin, origin)
	end
end
register_command("remember", "remember_callback")
register_command("forget", "remember_callback")

function validReq(s)
	if s:gsub("%%",""):len() > 2 then
		return true
	end
	return false
end

function remember(s,w,t)
	if s == nil or not validReq(s) then
		local cur = sql_query("SELECT DISTINCT `Title` FROM `remember` ORDER BY `Title` ASC")
		if sql_errno() ~= 0 then
			print(sql_error())
		end
		local outstr = "I know about: "
		while true do
			local row = sql_fetch_row(cur)
			if row == nil then break end
			outstr=outstr..row['Title']..", "
			if outstr:len() > 320 then
				irc_msg(t,outstr)
				outstr = ""
			end
		end
		sql_free(cur)
		outstr=outstr:sub(1,-2)
		irc_msg(t,outstr)
		return
	end
	local indexOfEquals = s:find("=")
	if indexOfEquals ~= nil then
		local title = s:sub(1,indexOfEquals-1)
		title = cleanSpace(title)
		local content = s:sub(indexOfEquals+1)
		content = cleanSpace(content)
		irc_msg(t, w..": I'll remember that '"..title.."' is '"..content.."' :)")
		sql_fquery("INSERT INTO `remember` (`Title`,`Content`) VALUES ('"..sql_escape(title).."','"..sql_escape(content).."')")
	else
		local inc=0
		local cur = sql_query("SELECT * FROM `remember` WHERE `Title` LIKE '%"..sql_escape(cleanSpace(s)).."%'")
		while true do
			local row = sql_fetch_row(cur)
			if row == nil then break end
			inc = inc + 1
			irc_msg(t,w..": "..row['Title'].." = "..row['Content'])
		end
		sql_free(cur)
		if inc == 0 then
			irc_msg(t,w..": I don't remember that! :(")
		end
	end
end

function forget(s,w,t)
	if s==nil then return end
	if s:find("%%") ~= nil and  w ~= get_config("bot:master") then return end
	local indexOfEquals = s:find("=")
	if indexOfEquals ~= nil then
		local title = s:sub(1,indexOfEquals-1)
                title = cleanSpace(title)
                local content = s:sub(indexOfEquals+1)
                content = cleanSpace(content)
		sql_fquery("DELETE FROM `remember` WHERE `Title` LIKE '"..sql_escape(title).."' AND `Content` LIKE '"..sql_escape(content).."'")
		irc_msg(t,w..": Okay, I forgot that.")
	end
end
