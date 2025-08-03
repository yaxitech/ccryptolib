local bit32 = {}

-- Convert to 32-bit unsigned integer
local function tobit(x)
    return x & 0xFFFFFFFF
end

-- Clamp shifts to 0–31 (bit32 uses only lower 5 bits)
local function clamp_shift(disp)
    return disp & 31
end

-- Normalize and convert all arguments to 32-bit unsigned integers
local function normalize_args(args)
    local t = {}
    for i = 1, #args do
        t[i] = tobit(args[i])
    end
    return t
end

-- Bitwise AND of all arguments
function bit32.band(...)
    local args = normalize_args({ ... })
    local result = 0xFFFFFFFF
    for i = 1, #args do
        result = result & args[i]
    end
    return tobit(result)
end

-- Bitwise OR of all arguments
function bit32.bor(...)
    local args = normalize_args({ ... })
    local result = 0
    for i = 1, #args do
        result = result | args[i]
    end
    return tobit(result)
end

-- Bitwise XOR of all arguments
function bit32.bxor(...)
    local args = normalize_args({ ... })
    local result = 0
    for i = 1, #args do
        result = result ~ args[i]
    end
    return tobit(result)
end

-- Bitwise NOT
function bit32.bnot(x)
    return tobit(~tobit(x))
end

-- Logical left shift: shifts bits left, fills with 0s on the right
function bit32.lshift(x, disp)
    x = tobit(x)
    disp = clamp_shift(disp)
    return tobit(x << disp)
end

-- Logical right shift: shifts bits right, fills with 0s on the left
function bit32.rshift(x, disp)
    x = tobit(x)
    disp = clamp_shift(disp)
    return tobit(x >> disp)
end

-- Arithmetic right shift: preserves sign bit for negative numbers
function bit32.arshift(x, disp)
    x = tobit(x)
    disp = clamp_shift(disp)
    -- Sign-extend from 32-bit
    if (x & 0x80000000) ~= 0 then
        -- Negative number: replicate sign bits
        return tobit(((x >> disp) | ((0xFFFFFFFF << (32 - disp)))))
    else
        -- Positive number: same as logical shift
        return tobit(x >> disp)
    end
end

-- Left rotate: circular shift to the left
function bit32.lrotate(x, disp)
    x = tobit(x)
    disp = clamp_shift(disp)
    return tobit((x << disp) | (x >> (32 - disp)))
end

-- Right rotate: circular shift to the right
function bit32.rrotate(x, disp)
    x = tobit(x)
    disp = clamp_shift(disp)
    return tobit((x >> disp) | (x << (32 - disp)))
end

-- Extract bits: returns the unsigned value of field [field, field+width-1]
function bit32.extract(x, field, width)
    x = tobit(x)
    width = width or 1
    assert(field >= 0 and field < 32, "field must be in [0, 31]")
    assert(width >= 1 and field + width <= 32, "width must be in [1, 32 - field]")
    return (x >> field) & ((1 << width) - 1)
end

-- Replace bits: replaces bit field [field, field+width-1] in x with bits from v
function bit32.replace(x, v, field, width)
    x = tobit(x)
    v = tobit(v)
    width = width or 1
    assert(field >= 0 and field < 32, "field must be in [0, 31]")
    assert(width >= 1 and field + width <= 32, "width must be in [1, 32 - field]")

    local mask = ((1 << width) - 1) << field
    return tobit((x & ~mask) | ((v << field) & mask))
end

return bit32