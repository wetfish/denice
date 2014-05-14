function quote_cmd(event,origin,params) -- content,channel)
	if params[2] == nil or params[2] == "" then
		irc_msg(params[1],randQuote())
	elseif params[2]:sub(0,1) == "*" then
		irc_msg(params[1],quoteByQuote(params[2]:sub(2)))
	elseif params[2]:sub(0,7) == "&latest" then
		irc_msg(params[1],quoteLatest())
	elseif params[2]:sub(0,1) == "#" then
		irc_msg(params[1],quoteByIndex(params[2]:sub(2)))
	elseif params[2]:sub(0,3) == "add" then
		irc_msg(params[1],forceQuote(params[2]:sub(5)))
	end
end
register_command("quote", "quote_cmd")

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
