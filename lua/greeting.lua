-- callback for user joining a channel
function greeting_join_callback(event, origin, params)
	local nick = sql_escape(origin)
	local t = sql_query_fetch("SELECT `Greeting` FROM `greeting` WHERE `Nick` = '" .. nick .. "'")
	if #t > 0 and t[1].Greeting ~= nil and t[1].Greeting:len() > 0 then
		irc_msg(params[1], t[1].Greeting)
	end
end
register_callback("JOIN", "greeting_join_callback")

function greeting_set(event, origin, params)
	local nick = sql_escape(origin)
	local g = sql_escape(params[2])
	local t = sql_query_fetch("SELECT `ID` FROM `greeting` WHERE `Nick` = '"..nick.."'")
	if #t > 0 and event == "!setgreeting" then
		sql_query_fetch("UPDATE `greeting` SET `Greeting`='"..g.."' WHERE `Nick`='"..nick.."'")
	elseif event == "!setgreeting" then
		sql_query_fetch("INSERT INTO `greeting` SET `Greeting`='"..g.."', `Nick`='"..nick.."'")
	elseif event == "!unsetgreeting" then
		sql_query_fetch("DELETE FROM `greeting` WHERE `Nick`='"..nick.."'")
	end
	irc_msg(params[1], "Greeting updated for "..origin)
end
register_command("setgreeting", "greeting_set")
register_command("unsetgreeting", "greeting_set")
