function imgur_upload(filename, callback_func, callback_data)
	local http  = require("ssl.https")
	local json  = require("json")
	local ltn12 = require("ltn12") 
	local response = {}

	local filehandle = io.open(filename, "rb")
	local postdata = filehandle:read("*all")
	filehandle:close()

	local headers = {
		['Authorization']   = "Client-ID " .. get_config("imgur:clientid"),
		['Content-Type']    = "image/jpeg",
		['Content-Length']  = postdata:len()
	}

	r,c,h = http.request{
		url     = get_config("imgur:endpoint") .. "upload.json",
		method  = "POST",
		headers = headers,
		source  = ltn12.source.string(postdata),
		sink    = ltn12.sink.table(response)
	}
	response = json.decode(table.concat(response))

	if c == 200 then
		callback_func("http://i.imgur.com/" .. response.data.id .. ".jpg", callback_data)
	else
		callback_func(nil, callback_data)
	end
end

--function imgur_cmd(event, origin, params)
--	if origin ~= get_config("bot:master") then
--		return
--	end
--
--	function cb(url, data)
--		irc_msg(data, url)
--	end
--
--	imgur_upload(params[2], cb, params[1])
--end

--register_command("imgurtest", "imgur_cmd")
