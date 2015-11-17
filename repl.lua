local ansicolors = require'ansicolors'
--local readline = require'readline'

local cprint = function(...) 
	print( ansicolors( ... ))
	ansicolors('%{reset}')
end

if not readline then
	readline = { readline = function( promt )
		io.write( promt or '' )
		local s = io.read()
		return s
	end }
end

local function processArg( arg, saved, ident )
	if arg == nil or arg == true or arg == false then
		return ansicolors( '%{cyan}'.. tostring( arg ) .. '%{reset}' )
	else
		local t = type( arg )
		if t == 'string' then
			return ansicolors( '%{bright blue}' .. tostring( arg ) .. '%{reset}' )
		elseif t == 'number' then
			return ansicolors( '%{yellow}' .. tostring( arg ) .. '%{reset}')
		elseif t == 'function' then
			local info = debug.getinfo( arg )
			if info.what == 'C' then
				return ansicolors( '%{magenta}C-' .. tostring( arg ) .. '%{reset}' )
			else
				return ansicolors( '%{green}' .. tostring( arg ) .. '%{bright}/' .. info.nparams .. '%{reset}' )
			end
		elseif t == 'userdata' or t == 'thread' then
			return ansicolors( '%{magenta}' .. tostring( arg ) .. '%{reset}' )
		else -- if t == 'table'
			if saved[arg] then
				return ansicolors( '%{bright}__REC__')
			else
				saved[arg] = arg
				
				local mt = getmetatable( arg )
				if mt ~= nil and mt.__tostring then
					return '%{bright}' .. mt.__tostring( arg ) .. '%{reset}'
				end
				
				local ret = {}
				local na = #arg
				for i = 1, na do
					ret[i] = processArg( arg[i], saved, ident )
				end
				local tret = {}
				local nt = 0
				for k, v in pairs(arg) do
					if not ret[k] then
						nt = nt + 1
						tret[nt] = (' '):rep(ident+1) .. processArg( k, saved, ident + 1 ) .. ' = ' .. processArg( v, saved, ident + 1 )
					end
				end
				local retc = table.concat( ret, ',' )
				local tretc = table.concat( tret, ',\n' )
				if tretc ~= '' then
					tretc = '\n' .. tretc
				end
				return '{' .. retc .. ( retc ~= '' and tretc ~= '' and ',' or '') .. tretc .. '}'
			end
		end
	end
end

local input, multiline = '', false
while true do
	ansicolors( '%{bright}' )
	input = input .. readline.readline(multiline and '>> ' or '> ')
	ansicolors( '%{reset}' )

	if input:sub(1,1) == '=' then
		input = 'return ' .. input:sub(2)
	end
	
	local callable, err = loadstring( input )
	if err then
		if err:sub(-10) ~= [[near <eof>]] then
			cprint( ('%{red dim}Bad input: %{red bright}' .. err ))
			input, multiline = '', false
		else
			input, multiline = input .. '\n', true
		end
	else
		input, multiline = '', false
		local result = {pcall( callable )}
		local n = #result
		if result[1] == true then
			if n == 1 then
				cprint( '%{green dim}Ok' )
			elseif n == 2 then
				cprint('%{dim}' .. processArg(result[2],{},0))
			else
				for i = 2, n do
					cprint( '%{bright}' .. (i-1) .. ': %{dim}' .. processArg(result[i],{},0))
				end
			end
		else
			cprint(('%{red dim}Error: %{red bright}' .. result[2] ))
		end
	end
end

