-- Stack (for Lua 5.1)
-- from http://snippets.luacode.org/?p=snippets/stack_97
function NewStack(t)
    local Stack = {
        push = function(self, ...)
            for _, v in ipairs{...} do
                self[#self+1] = v
            end
        end,
        pop = function(self, num)
            local num = num or 1
            if num > #self then
                error("underflow in NewStack-created stack")
            end
            local ret = {}
            for i = num, 1, -1 do
                ret[#ret+1] = table.remove(self)
            end
            return unpack(ret)
        end
    }
    return setmetatable(t or {}, {__index = Stack})
end
