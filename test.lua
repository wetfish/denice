
function test_callback(event, origin, params)
	print("event:    " .. event)
	print("origin:   " .. origin)
	for i,v in pairs(params) do
		print("param["..i.."]: " .. v)
	end
	print()
end
register_callback("CHANNEL", "test_callback")

function connect_callback(event, origin, params)
	print("now connected to irc :)")
end
register_callback("CONNECT", "connect_callback")
