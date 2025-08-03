-- A (limited) bit32 compatibility module

if bit32 then
    return bit32
else
    return require "ccryptolib.internal.bit32_bitop"
end
