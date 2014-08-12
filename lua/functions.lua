-- global variable for xml lib
xml = require('LuaXml')

-- select words above threshold size and add to a table
function big_words(str, thresh)
	local r = {}
	for i,word in pairs(str_split(str, " ")) do
		if word:len() >= thresh then
			r[#r+1] = word
		end
	end
	return r
end

-- split string by separator
function str_split(str, sep)
    if str == nil then
        return {}
    else
        local sep, fields = sep or " ", {}
        local str = str.." "
        local index = 1
        while index <= str:len() do
                local piece_end = str:find(sep, index)
                if piece_end == nil then
                        piece_end = str:len()
                end
                fields[#fields+1] = str:sub(index, piece_end - 1)
                index = piece_end + 1
        end
        return fields
    end
end

-- merge all but first (max-1) entries in table returned by str_split
function str_split_max(str, sep, max)
	local t1 = {}
	for i,v in pairs(str_split(str, sep)) do
		if #t1 < max then
			t1[i] = v
		else
			t1[#t1] = t1[#t1]..sep..v
		end
	end
	return t1
end

-- helper function for xml parsing
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

-- trim leading or trailing spaces
function cleanSpace(s)
	return s:gsub("^ +",""):gsub(" +$","")
end

-- url encode a string
function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str	
end
