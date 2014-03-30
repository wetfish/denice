function remember_callback(event, origin, params)
	local msg_parts = str_split_max(params[2], " ",2)
	if msg_parts[1] == "!remember" then
		remember(msg_parts[2], origin, params[1])
	elseif msg_parts[1] == "!forget" then
		forget(msg_parts[2], origin, params[1])
	end
end
register_callback("CHANNEL", "remember_callback")

function validReq(s)
	if s:gsub("%%",""):len() > 2 then
		return true
	end
	return false
end

function remember(s,w,t)
	if s == nil or not validReq(s) then
		local cur = sql_query("SELECT DISTINCT `Title` FROM `remember` ORDER BY `Title` ASC")
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
		sql_fquery("DELETE FROM `remember` WHERE `Title` LIKE '"..esc(title).."' AND `Content` LIKE '"..esc(content).."'")
		irc_msg(t,w..": Okay, I forgot that.")
	end
end
