-- create table to remember which libraries we've already added to the path
if _my_libs == nil then
	_my_libs = {}
end

-- function to easily add directories to path
function add_lib_dir(name)
	if _my_libs[name] == nil then
		package.path = name.."/?.lua;"..(package.path or "")
		package.cpath = name.."/?.so;"..(package.cpath or "")
		_my_libs[name] = true
		print("Path updated to include '"..name.."'.")
	else
		print("Path already contains '"..name.."'.")
	end
end

-- add paths to required libraries
add_lib_dir("libs/LuaXml")
add_lib_dir("libs/luasocket")
add_lib_dir("libs/json")
add_lib_dir("libs/luasec")
add_lib_dir("libs/lpeg-0.12")
add_lib_dir("libs/luabase64")

-- load bot scripts
dofile("lua/functions.lua")
dofile("lua/stack.lua")
dofile("lua/error.lua")
dofile("lua/msg.lua")
dofile("lua/connect.lua")
dofile("lua/greeting.lua")
dofile("lua/talk.lua")
dofile("lua/quotes.lua")
dofile("lua/bitly.lua")
dofile("lua/last.lua")
dofile("lua/spam.lua")
dofile("lua/weather.lua")
dofile("lua/remember.lua")
dofile("lua/dickbutt.lua")
dofile("lua/caps.lua")
dofile("lua/help.lua")
dofile("lua/stats.lua")
dofile("lua/seen.lua")
dofile("lua/roll.lua")
dofile("lua/duel.lua")
dofile("lua/imgur.lua")
dofile("lua/comic.lua")
