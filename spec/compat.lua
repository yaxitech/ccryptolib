local function compat(assert)
    --#region expect

    local expectCompat = {}

    local ExpectClass = {}
    ExpectClass.__index = ExpectClass

    function ExpectClass:eq(other)
        assert.same(self.value, other)
    end

    function ExpectClass:equals(other)
        return self:eq(other)
    end

    -- Callable behavior for expect(value)
    setmetatable(expectCompat, {
        __call = function(_, value)
            local obj = setmetatable({}, ExpectClass)
            obj.value = value
            return obj
        end
    })

    -- https://github.com/cc-tweaked/CC-Tweaked/blob/5a9e21c/projects/core/src/test/resources/test-rom/mcfly.lua#L409 (MPL-2.0)
    function expectCompat.error(fun, ...)
        local ok, res = pcall(fun, ...)
        local _, line = pcall(error, "", 2)
        if ok then error("expected function to error") end
        if res:sub(1, #line) == line then
            res = res:sub(#line + 1)
        elseif res:sub(1, 7) == "pcall: " then
            res = res:sub(8)
        end
        return expectCompat(res)
    end

    --#endregion expect

    --#region sleep

    function sleep(...)
    end

    --#endregion sleep

    return {
        expect = expectCompat,
        sleep = sleep
    }
end

return compat
