local okansicolors,ansicolors = pcall( require, 'ansicolors' )
local okreadline,readline = pcall( require, 'readline' )
local C

if not okansicolors then
	print( 'Lua REPL by iskolbin' )
	print( 'install ansicolors for better experience (luarocks install ansicolors)' )
	ansicolors = function(...)
		return table.concat{...}
	end
	C = function() return '' end
else
	C = function(s) return s end
	print( ansicolors( C'%{bright white}' .. 'Lua ' .. C'%{yellow}' .. 'REPL '.. '%{white}' .. 'by iskolbin' .. C'%{reset}' ))
end

print( ansicolors( C'%{dim}' .. _VERSION .. C'%{reset}' ))

if not okreadline then
	print( 'install readline for better experience (luarocks install readline)')
	readline = { readline = function( promt )
		io.write( promt or '' )
		local s = io.read()
		return s
	end }
end

local function processArg( arg, saved, ident )
	if arg == nil or arg == true or arg == false then
		return ansicolors( C'%{cyan}'.. tostring( arg ) .. C'%{reset}' )
	else
		local t = type( arg )
		if t == 'string' then
			return ansicolors( C'%{bright blue}' .. tostring( arg ) .. C'%{reset}' )
		elseif t == 'number' then
			return ansicolors( C'%{yellow}' .. tostring( arg ) .. C'%{reset}')
		elseif t == 'function' then
			local info = debug.getinfo( arg )
			if info.what == 'C' then
				return ansicolors( C'%{magenta}' .. 'C-function' .. C'%{reset}' )
			else
				return ansicolors( C'%{green}' .. 'function' .. C'%{bright}' .. '/' .. info.nparams .. C'%{reset}' )
			end
		elseif t == 'userdata' or t == 'thread' then
			return ansicolors( C'%{magenta}' .. tostring( arg ) .. C'%{reset}' )
		else -- if t == 'table'
			if saved[arg] then
				return ansicolors( C'%{bright}' .. '__REC__')
			else
				saved[arg] = arg
				
				local mt = getmetatable( arg )
				if mt ~= nil and mt.__tostring then
					return C'%{bright}' .. mt.__tostring( arg ) .. C'%{reset}'
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

local mem = collectgarbage'count'
local x = {}
local tablesize = collectgarbage'count' - mem
x[1] = 0
local itemsize = collectgarbage'count' - mem - tablesize
mem = collectgarbage'count'
x = {z = 0}
local hashsize = collectgarbage'count' - mem - tablesize
x = nil

print('tablesize', 1024*tablesize, 'indexsize', 1024*itemsize, 'hashsize', 1024*hashsize )

local input, multiline = '', false
while true do
	ansicolors( C'%{bright}' )
	input = input .. readline.readline(multiline and '>> ' or '> ')
	ansicolors( C'%{reset}' )

	if input:sub(1,1) == '=' then
		input = 'return ' .. input:sub(2)
	end
	
	local callable, err = loadstring( input )
	if err then
		if err:sub(-10) ~= [[near <eof>]] then
			print( ansicolors(C'%{red dim}' .. 'Bad input: ' .. C'%{red bright}' .. err .. '%{reset}') )
			input, multiline = '', false
		else
			input, multiline = input .. '\n', true
		end
	else
		input, multiline = '', false
		local t0 = os.clock()
		local mem = collectgarbage'count'
		local result = {pcall( callable )}
		local mem1 = collectgarbage'count'
		local runtime = ('\t%s[%g s][%g B]'):format( C'%{white dim}', os.clock() - t0, 1024*( mem1 - mem - tablesize - itemsize*#result))
		local n = #result
		if result[1] == true then
			if n == 1 then
				print( ansicolors( C'%{green dim}' .. 'Ok'  .. runtime .. C'%{reset}' ))
			elseif n == 2 then
				print( ansicolors (C'%{dim}' .. processArg(result[2],{},0) .. runtime .. '%{reset}'))
			else
				for i = 2, n-1 do
					print( ansicolors(C'%{dim}' .. (i-1) .. ': ' .. C'%{bright}' .. processArg(result[i],{},0) .. '%{reset}'))
				end
				print( ansicolors(C'%{dim}' .. (n-1) .. ': ' .. C'%{bright}' .. processArg(result[n],{},0) .. runtime .. '%{reset}'))
			end
		else
			print(ansicolors( C'%{red dim}' .. 'Error: ' .. C'%{red bright}' .. result[2] ))
		end
	end
end

