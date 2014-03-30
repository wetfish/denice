function bitly(url)
	local bitlyLogin = "le1ca"
	local bitlyKey   = "R_e7190844e2bb3d15f8e4bbff68e40988"
	local s = "http://api.bit.ly/v3/shorten?longUrl="..url_encode(url).."&login="..bitlyLogin.."&apiKey="..bitlyKey
	local http = require("socket.http")
	local b = http.request(s)
	local json = require('json')
    local jsonTable = json.decode(b)
    return jsonTable.data.url;
end
