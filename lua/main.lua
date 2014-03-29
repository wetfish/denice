package.path = "libs/LuaXml/?.lua;"..(package.path or "")
package.cpath = "libs/LuaXml/?.so;"..(package.cpath or "")

dofile("lua/functions.lua")
dofile("lua/stack.lua")
dofile("lua/error.lua")
dofile("lua/msg.lua")
dofile("lua/connect.lua")
dofile("lua/join.lua")
dofile("lua/talk.lua")
dofile("lua/quotes.lua")
dofile("lua/last.lua")

function debug_callback(event, origin, params)
	print(event.." ("..origin..")")
	for i,v in pairs(params) do
		print(" "..i..": "..v)
	end
end
register_callback("NOTICE", "debug_callback")
register_callback("433", "debug_callback")
