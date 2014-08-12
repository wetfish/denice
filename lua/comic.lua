if comic_memory == nil then
	comic_memory = {}
end

function comic_callback(event, origin, params)
	local spec_f = io.open(get_config("comic:workdir").."spec", "w")
	for i,v in ipairs(comic_memory) do
		spec_f:write(v.user .. ": " .. v.message .. "\n")
	end
	spec_f:close()

	os.execute(get_config("comic:script"))

	function comic_upload_callback(url, channel)
		if url ~= nil then
			irc_msg(channel, "Here's your comic: " .. url)
		else
			irc_msg(channel, "Couldn't make a comic, sorry")
		end
	end

	imgur_upload(get_config("comic:output"), comic_upload_callback, get_config("comic:channel"))
end
register_command("comic", "comic_callback")

function comic_remember(event, origin, params)
	if params[1] ~= get_config("comic:channel") then
		return
	end

	while #comic_memory > tonumber(get_config("comic:count")) do
		table.remove(comic_memory,1)
	end

	comic_memory[#comic_memory+1] = {user=origin, message=params[2]}
	print("comic memory has " .. (#comic_memory) .." entries")
end
register_callback("CHANNEL", "comic_remember")
