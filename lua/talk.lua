function talk_parse(event, origin, params)
	local word1,word2
	for i,word in pairs(str_split(params[2]," ")) do
		if word ~= nil then
			if word1 ~= nil then
				if word2 ~= nil then
					local q=sql_query(
						"INSERT INTO `dictionary` (`Word1`, `Word2`, `Word3`, `DateAdded`) " ..
						"VALUES('"..sql_escape(word2).."','"..sql_escape(word1).."','"..sql_escape(word).."','"..os.time().."')"
					)
					sql_free(q)
				end
				word2 = word1		
			end
			word1 = word
		end
	end

end
register_callback("CHANNEL", "talk_parse")

function extend_tree(working_node, data_table)
	local w1 = working_node.parent.value
	local w2 = working_node.value
	
	if working_node.depth + 1 > data_table.max_depth then
		if working_node.depth > data_table.best_depth then
			data_table.best_depth = working_node.depth
			data_table.end_nodes[#(data_table.end_nodes)+1] = working_node
		end
		return
	end
	
	if #(data_table.end_nodes)+1 > data_table.max_entries then
		return
	end
	
	local rows = sql_query_fetch(
		"SELECT `Index`,`Word3` FROM `dictionary` WHERE `Word1` = '"..sql_escape(w1).."' "..
		"AND `Word2` = '"..sql_escape(w2).."' ORDER BY RAND() LIMIT 0,2"
	)

	if #rows > 1 and data_table.hit_nodes[rows[2].Index] == nil then
		local new_node = {subnodes={},parent=working_node,value=rows[2].Word3,depth=working_node.depth+1}
		working_node.subnodes[#(working_node.subnodes)+1] = new_node
		data_table.hit_nodes[rows[2].Index] = true
		extend_tree(new_node, data_table)
	end
	
	if #rows > 0 and data_table.hit_nodes[rows[1].Index] == nil then
		local new_node = {subnodes={},parent=working_node,value=rows[1].Word3,depth=working_node.depth+1}
		working_node.subnodes[#(working_node.subnodes)+1] = new_node
		data_table.hit_nodes[rows[1].Index] = true
		extend_tree(new_node, data_table)
	else
		if working_node.depth > data_table.best_depth * .75 then
			data_table.best_depth = working_node.depth
			data_table.end_nodes[#(data_table.end_nodes)+1] = working_node
		end
	end
end

function climb_tree(leaf)
	local phrase = ""
	while leaf ~= nil do
		if leaf.value ~= nil then
			if phrase:len() then
				phrase = leaf.value .. " " .. phrase
			else
				phrase = leaf.value
			end
		end
		leaf = leaf.parent
	end
	return phrase
end

function talk(channel, retmode)
	local word1,word2,word3
	local stack = NewStack()
	local phrase = ""
	local iterations = 0
	local done = false
	local done2 = false
	
	local data_table = {hit_nodes={}, node_count=0, end_nodes={}, max_depth=35, best_depth=0, max_entries=10}
	local working_node
	local root_node
	
	-- create initial run
	local rows = sql_query_fetch("SELECT `Word1`,`Word2`,`Word3` FROM `dictionary` ORDER BY RAND() LIMIT 0,1")
	local w1 = rows[1].Word1
	local w2 = rows[1].Word2
	local w3 = rows[1].Word3
	local num_steps = 0
	local hit_end = false
	local t = NewStack()
	t:push(w3)
	t:push(w2)
	t:push(w1)
	-- attempt to build backward
	while not hit_end and num_steps < 100 do
		local _w2 = t:pop()
		local _w3 = t:pop()
		t:push(_w3)
		t:push(_w2)
		local rows = sql_query_fetch(
			"SELECT `Index`,`Word1` FROM `dictionary` WHERE `Word2` = '"..sql_escape(_w2).."' "..
			"AND `Word3`='"..sql_escape(_w3).."' ORDER BY RAND() LIMIT 0,1"
		)
		if #rows == 0 then
			hit_end = true
		else
			t:push(rows[1].Word1)
			data_table.hit_nodes[rows[1].Index] = true
		end
		num_steps = num_steps + 1
	end
	-- push the contents of temp stack into main tree in reverse order
	root_node = {subnodes={},parent=nil,value=nil,depth=0}
	working_node = root_node
	tree_depth = 0
	while #t > 0 do
		new_node = {subnodes={},parent=working_node,value=t:pop(),depth=working_node.depth+1}
		working_node.subnodes[#(working_node.subnodes)+1] = new_node
		working_node = new_node
		tree_depth = tree_depth + 1
	end
	extend_tree(working_node, data_table)
	
	phrase = climb_tree(data_table.end_nodes[math.random(1,#(data_table.end_nodes))])

	
	local isAction=false
	if phrase:sub(0,8)=="ACTION " then
		isAction=true
	end
	phrase = phrase:gsub("","")
	if isAction then
		phrase = ""..phrase..""
	end
	if retmode == nil then
		irc_msg(channel,phrase)
	else
		return phrase
	end

end
