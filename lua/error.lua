-- Send error reports to master
function error_callback(event, origin, params)
	my_master = get_config("bot:master")
	irc_msg(my_master, "ERROR EVENT:")
	-- error messages may have multiple lines
	for i,v in pairs(str_split(params[1], "\n")) do
		irc_msg(my_master, " > "..v)
	end
end
register_callback("ERROR", "error_callback")
