function quote_callback(event, origin, params)
	if params[2]:sub(0,6) == "!quote" then
		quote(params[2]:sub(2), params[1])
	end
end
register_callback("CHANNEL", "quote_callback")

function quote(content,channel)
	print("quote("..content..","..channel..")")
	if content == "quote" then
		irc_msg(channel,randQuote())
	elseif content:sub(0,7) == "quote *" then
		irc_msg(channel,quoteByQuote(content:sub(8)))
	elseif content:sub(0,13) == "quote &latest" then
		irc_msg(channel,quoteLatest())
	elseif content:sub(0,7) == "quote #" then
		irc_msg(channel,quoteByIndex(content:sub(8)))
	elseif content:sub(0,9) == "quote add" then
		irc_msg(channel,forceQuote(content:sub(11)))
	end
end

function formatQuote(index,quote,time)
	if quote == nil then
		return "No quote found."
	else
		return "[#"..index.."] ["..os.date("%R %b%d '%g",time).."]".." "..quote
	end
end

function randQuote()
	local ret
	for i,row in pairs(sql_query_fetch("SELECT * FROM `quotes` ORDER BY RAND() LIMIT 0,1")) do
		ret = formatQuote(row.Index,row.Quote,row.Time)
	end
	return ret or formatQuote()
end

function quoteByQuote(qnick)
	local ret
	for i,row in pairs(sql_query_fetch(
		"SELECT * FROM `quotes` WHERE `Quote` REGEXP '.*"..sql_escape(qnick)..".*' ORDER BY RAND() LIMIT 0,1"
	)) do
		ret = formatQuote(row.Index,row.Quote,row.Time)
	end
	return ret or formatQuote()
end

function quoteLatest()
	local ret
	for i,row in pairs(sql_query_fetch("SELECT * FROM `quotes` ORDER BY `Index` DESC LIMIT 0,1")) do
		ret = formatQuote(row.Index,row.Quote,row.Time)
	end
	return ret or formatQuote()
end

function quoteByIndex(qindex)
	local ret
	for i,row in pairs(sql_query_fetch("SELECT * FROM `quotes` WHERE `Index` = '"..sql_escape(qindex).."' LIMIT 0,1")) do
		ret = formatQuote(row.Index,row.Quote,row.Time)
	end
	return ret or formatQuote()
end

function forceQuote(content)
	local time = os.time()
	sql_fquery("INSERT INTO `quotes` (`Quote`,`Time`) VALUES ('"..sql_escape(content).."','"..sql_escape(time).."')")
	return "Quote added. (#"..sql_insert_id()..")"
end

function delQuote(index)
	sql_fquery("UPDATE `quotes` SET `Delete` = '1' WHERE `Index` = '"..sql_escape(index).."'")
	return "Marked quote #"..index.." for deletion"
end
