metachar      = {b=string.char(2),o=string.char(15),a=string.char(1)}
lastfm_table  = {}
lastfm_apikey = '7ae41b20066f4855dcd1a878e590b985'

function last_callback(event, origin, params)
	local msg_parts = str_split_max(params[2], " ",2)
	if msg_parts[1] == "!np" then
		lastfm_np2(msg_parts[2],origin,params[1])
	elseif msg_parts[1] == "!last" then
		lastfm_account(msg_parts[2],origin,params[1])
	elseif msg_parts[1] == "!tags" then
		lastfm_tags(msg_parts[2],origin,params[1])
	elseif msg_parts[1] == "!similar" then
		lastfm_similar(msg_parts[2],origin,params[1])
	elseif msg_parts[1] == "!tagged" then
		lastfm_tagged(msg_parts[2],origin,params[1])
	elseif msg_parts[1] == "!compare" then
		lastfm_compare(msg_parts[2],origin,params[1])
	elseif msg_parts[1] == "!myartists" then
		lastfm_myartists(amsg_parts[2],origin,params[1])
	end
end
register_callback("CHANNEL", "last_callback")

function getNodes(t,nodeName,first)
	local returnNodes = {}
	for i,v in pairs(t) do
		if type(v) == "table" and v[0] == nodeName then
			if first then
				if type(v) == "table" then
					v.getNodes = getNodes
				end
				return v
			end
			table.insert(returnNodes,v)
		end
	end
	return returnNodes
end

function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str	
end

function lastfm_load()
	local configTable   = {}
	local f = io.open("lastnicks.txt","r")
	repeat
		local l = f:read('*line')
		if l == nil then break end
		local propEnd,dataStart = l:find(": ")
		local nick = l:sub(1,propEnd-1)
		local user = l:sub(dataStart+1)
		configTable[nick] = user
	until l == nil
	f:close()
	return configTable
end

lastfm_table = lastfm_load()

function lastfm_save(configTable)
	local f =io.open("lastnicks.txt","w")
	for nick,user in pairs(configTable) do
		f:write(nick..": "..user.."\n")
	end
	f:close()
end

function lastfm_getuser(nick)
	if lastfm_table[nick] ~= nil then
		return lastfm_table[nick]
	else
		return nick
	end
end

function lastfm_exec(method,params)
	local s = "http://ws.audioscrobbler.com/2.0/?method="..method
	for i,v in pairs(params) do
		s = s .. "&"..i.."="..url_encode(v)
	end
	s = s.."&api_key="..lastfm_apikey
	s = s.."&raw=true"
	local http = require("socket.http")
	local xml = require("LuaXml")
	local b = http.request(s)
	
	if b ~= nil then
		local t = xml.eval(b)
		t.getNodes = getNodes
		return t
	end
end

function lastfm_np2(nick,user,channel)
	lastfm_np(nick,user,channel,true)
end

function lastfm_np(nick,user,channel,with_link)
	if nick == nil then
		nick = user.nick
	end
	local t = lastfm_exec("user.getrecenttracks",{limit=1,user=lastfm_getuser(nick)})
	if t ~= nil then
		local nowPlaying = t:getNodes("track",1)['nowplaying']
		local artistName = t:getNodes("track",1)
		if artistName.getNodes ~= nil then
			artistName = artistName:getNodes("artist",1)[1]
		else
			irc_msg(channel,"Couldn't get now playing information for "..metachar.b..nick..metachar.o..".")
			return
		end
		local trackName  = t:getNodes("track",1)
		local trackStreamable = false
		local trackUrl = false
		if trackName.getNodes ~= nil then
			if trackName:getNodes("streamable",1)[1] == "1" then
				trackStreamable = true
			end
			trackUrl = trackName:getNodes("url",1)[1]
			trackName = trackName:getNodes("name",1)[1]
		else
			irc_msg(channel,"Couldn't get now playing information for "..metachar.b..nick..metachar.o..".")
			return
		end
		
		if nowPlaying == "true" then
			t2 = lastfm_exec("artist.gettoptags",{artist=artistName})
			local tagList = ""
			if t2 ~= nil then
				local allTags = t2:getNodes("tag")
				local j = 1
				for i,v in pairs(allTags) do
					if type(v) == "table" then
						local tagName = getNodes(v,"name",1)[1]
						tagList = tagList..tagName..", "
						if j >= 3 then
							break
						end
						j = j+1
					end
				end
				if tagList ~= nil then
					tagList = tagList:sub(1,-3)
					tagList = " ("..tagList..")"
				end
			end
			local append = ""
			if with_link then
				append = ""
				if trackStreamable then
					append = append.." // "..metachar.b.."Streamable at last.fm."..metachar.o
				end
				append = append.." // "..bitly(trackUrl)
			end
			irc_msg(channel,metachar.b .. nick .. metachar.o .. " is listening to " .. metachar.b .. trackName .. metachar.o .. " by " .. metachar.b .. artistName .. metachar.o .. "."..tagList..append)
		else
			irc_msg(channel,metachar.b .. nick .. metachar.o .. " isn't listening to anything right now.")
		end
	else
		irc_msg(channel,"Couldn't get now playing information for "..metachar.b..nick..metachar.o..".")
	end
end

function lastfm_account(user,nick,channel)
	if user ~= nil then
		lastfm_table[nick.nick]=user
		irc_msg(channel,"Set username for '"..nick.nick.."' to '"..user.."'")
		lastfm_save(lastfm_table)
	else
		irc_msg(channel,"Usage: !last <username>")
	end
end

function lastfm_tags(artist,nick,channel)
	if artist ~= nil then
		t = lastfm_exec("artist.gettoptags",{artist=artist,autocorrect=1})
		if t ~= nil then
			local allTags = t:getNodes("tag")
			local artist = t['artist']
			if artist == nil then
				irc_msg(channel,"Couldn't find that artist.")
				return
			end
			local tagList = ""
			local j = 1
			for i,v in pairs(allTags) do
				if type(v) == "table" then
					local tagName = getNodes(v,"name",1)[1]
					tagList = tagList..tagName..", "
					if j >= 10 then
						break
					end
					j = j+1
				end
			end
			tagList = tagList:sub(1,-3)
			irc_msg(channel,"Tags for "..metachar.b..artist..metachar.o..": "..tagList)
		else
			irc_msg(channel,"Couldn't get tags for "..metachar.b..artist..metachar.o..".")
		end
	else
		irc_msg(channel,"Usage: !tags <artist name>")
	end
end

function lastfm_similar(artist,nick,channel)
	if artist ~= nil then
		t = lastfm_exec("artist.getsimilar",{artist=artist,autocorrect=1})
		if t ~= nil then
			local allSimilar = t:getNodes("artist")
			local artist = t['artist']
			local similarList = ""
			local j = 1
			for i,v in pairs(allSimilar) do
				if type(v) == "table" then
					local artistName = getNodes(v,"name",1)[1]
					similarList=similarList..artistName..", "
					if j >= 10 then
						break
					end
					j = j+1
				end
			end
			similarList = similarList:sub(1,-3)
			irc_msg(channel,"Similar artists for "..metachar.b..artist..metachar.o..": "..similarList)
		else
			irc_msg(channel,"Couldn't get similar artists for "..metachar.b..artist..metachar.o..".")
		end
	else
		irc_msg(channel,"Usage: !similar <artist name>")
	end
end

function lastfm_tagged(tag,nick,channel)
	if tag ~= nil then
		t = lastfm_exec("tag.getTopArtists",{tag=tag})
		if t ~= nil then
			local allTagged = t:getNodes("artist")
			local taggedList = ""
			local j = 1
			for i,v in pairs(allTagged) do
				if type(v) == "table" then
					local taggedName = getNodes(v,"name",1)[1]
					taggedList = taggedList..taggedName..", "
					if j >= 10 then
						break
					end
					j = j+1
				end
			end
			taggedList = taggedList:sub(1,-3)
			irc_msg(channel,"Artists tagged "..metachar.b..tag..metachar.o..": "..taggedList)
		else
			irc_msg(channel,"Couldn't get artists tagged "..metachar.b..tag..metachar.o..".")
		end
	else
		irc_msg(channel,"Usage: !tagged <tag name>")
	end
end

function lastfm_compare(args,nick,channel)
	if args ~= nil then
		args = str_split(args," ")
		if args[2] == nil then
			args[2] = nick.nick
		end
		local user1 = lastfm_getuser(args[2])
		local user2 = lastfm_getuser(args[1])
		t = lastfm_exec("tasteometer.compare",{type1='user',type2='user',value1=user1,value2=user2})
		if t ~= nil then
			local t = t:getNodes("result",1)
			t.getNodes = getNodes
			local score = t:getNodes("score",1)[1]
			if score == nil then
				irc_msg(channel,"Error calculating compatibility.")
				return
			end
			score = string.format("%.2f",score*100).."%"
			local artists = t:getNodes("artists",1):getNodes("artist")
			local artistsList = ""
			for i,v in pairs(artists) do
				if type(v) == "table" then
					local artistName = getNodes(v,"name",1)[1]
					artistsList=artistsList..artistName..", "
				end
			end
			if artistsList ~= "" then
				artistsList = " ("..artistsList:sub(1,-3)..")"
			end
			irc_msg(channel,metachar.b..user1..metachar.o.." and "..metachar.b..user2..metachar.o.." are "..score.." compatible."..artistsList)
		else
			irc_msg(channel,"An error occurred while trying to compare "..metachar.b..user1..metachar.o.." and "..metachar.b..user2..metachar.o..".")
		end
	else
		irc_msg(channel,"Usage: !compare <user> [user]")
	end
end

function lastfm_myartists(args,user,channel)
	local period = "overall"
	local nick = nil
	if args ~= nil then
		for i,v in pairs(str_split_max(args," ",2)) do
			if v:sub(1,1) == "-" then
				period=v:sub(2)
			else
				nick = v
			end
		end
	end
        if nick == nil then
                nick = user.nick
        end
        local t = lastfm_exec("user.gettopartists",{user=lastfm_getuser(nick),period=period})
	if t ~= nil then
		local allArtists = t:getNodes("artist")
		local artistList = ""
		local j = 1
		for i,v in pairs(allArtists) do
			if type(v) == "table" then
				local artistName = getNodes(v,"name",1)[1]
				local plays = getNodes(v,"playcount",1)[1]
				artistList = artistList..artistName.." ("..plays.."), "
				if j >= 10 then
					break
				end
				j = j+1
			end
		end
		artistList = artistList:sub(1,-3)
		irc_msg(channel,"Top artists ("..period..") for user "..metachar.b..nick..metachar.o..": "..artistList)
	else
		irc_msg(channel,"Couldn't get top artists for user "..metachar.b..nick..metachar.o..".")
	end
end

