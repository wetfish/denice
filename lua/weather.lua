function weather_callback(event, origin, params)
	local msg_parts = str_split_max(params[2], " ",2)
	if msg_parts[1] == "!weather" then
		weather(msg_parts[2], origin, params[1])
	end
end
register_callback("CHANNEL", "weather_callback")

function weather(zip,user,channel)
    local http = require("socket.http")
	local json = require('json')
	
	if zip == nil or zip:len() == 0 then
		irc_msg(channel,user..": please specify a location")
		return
	end

	local metachar = {b=string.char(2),o=string.char(15),a=string.char(1)}

	local unit_req = "u=f"
	if zip:find("-c") ~= nil then
		unit_req = "u=c"
		zip = zip:gsub("-c ?","")
	end

	local woe_s = "http://where.yahooapis.com/v1/places.q("..url_encode(zip)..")?appid=QbEjA07V34EJy1A.6Q9_x532DTrZGqXMNt1Et0arLk.IDubUeLhfwYyizjPSvjmiah6LDLzpaA--&format=json"
    local woe_b = http.request(woe_s)
    local woe_t = json.decode(woe_b)
	if woe_t.places == nil or woe_t.places.place == nil then
		irc_msg(channel,"That place doesn't exist!")
		return
	end
	local woeid = woe_t.places.place[1].woeid;

	local weather_s = "http://weather.yahooapis.com/forecastrss?w="..woeid.."&"..unit_req
	local weather_b = http.request(weather_s)
	local weather_t = xml.eval(weather_b)
	weather_t = weather_t[1]
	weather_t.getNodes = getNodes

	local dayMap={Sun='Sunday',Mon='Monday',Tue='Tuesday',Wed='Wednesday',
		Thu='Thursday',Fri='Friday',Sat='Saturday'}
	local loc = weather_t:getNodes("yweather:location")[1]
	local city = loc['city']
	local region = loc['region']
	if city == nil then
		irc_msg(channel,"An error occurred!")
		return
	end
	local current = weather_t:getNodes("item",1):getNodes("yweather:condition",1)
	local units = weather_t:getNodes("yweather:units",1)
	local temp = current['temp'].." "..units['temperature']
	local cond = current['text']
	local humi = weather_t:getNodes("yweather:atmosphere", 1)['humidity'].."%"
	local wind = weather_t:getNodes("yweather:wind", 1)['speed'].." "..units['speed']
	
	local place_name = city
	if region ~= nil and region:len() > 0 then
		place_name = place_name .. ", " .. region
	end
	irc_msg(channel,metachar.b.."Weather for "..place_name..metachar.o)
	irc_msg(channel,">> "..metachar.b.."Currently:"..metachar.o.." "..cond.." | "..temp..
		" | Humidity "..humi.." | Wind "..wind)
	local fi = 0

	local forecasts = weather_t:getNodes("item",1):getNodes("yweather:forecast")
	for i,v in pairs(forecasts) do
		fi = fi + 1
		v.getNodes = getNodes
		local day  = v['day']
		day = dayMap[day]
		local high = v['high'].." "..units['temperature']
		local low  = v['low'].." "..units['temperature']
		local cond = v['text']
		irc_msg(channel,">> "..metachar.b..day..metachar.o..": "..cond..
			" | High "..high.." | Low "..low)
		if fi >= 3 then
			break
		end
	end
	if r ~= nil then
		irc_msg(channel,r)
	end
end
