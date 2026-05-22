local platform = {
    
    os = "unknown",
    arch = "unknown"
}

platform.get = function()
    -- LuaJIT shortcut
	if jit and jit.os and jit.arch then
		platform.os = string.lower(jit.os)
		platform.arch = string.lower(jit.arch)
	end
    
    p("Architecture: ", platform.arch, " OS:", platform.os)
end

return platform