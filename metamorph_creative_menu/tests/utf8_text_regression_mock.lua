local root=assert(arg[1])
local utf8_text=assert(dofile(root..'/files/core/utf8_text.lua'))

local function bytes(...) return string.char(...) end
local function assert_eq(actual, expected, message)
 if actual~=expected then
  error((message or 'mismatch')..': expected '..string.format('%q',expected)..' got '..string.format('%q',actual))
 end
end

assert_eq(utf8_text.truncate_bytes('abc',4),'abc','short ascii changed')
assert_eq(utf8_text.truncate_bytes('abcd',4),'abcd','boundary ascii changed')
assert_eq(utf8_text.truncate_bytes('abcde',4),'abcd','long ascii truncation failed')

local ru='абв'
assert_eq(utf8_text.truncate_bytes(ru,5),'аб','cyrillic boundary split')

local han=string.rep('漢',27)
local han_safe=utf8_text.truncate_bytes(han,80)
assert_eq(han_safe,string.rep('漢',26),'CJK boundary split')
assert(#han_safe==78,'CJK byte limit changed')

local emoji='abc'..'😀'
assert_eq(utf8_text.truncate_bytes(emoji,7),emoji,'emoji before boundary changed')
assert_eq(utf8_text.truncate_bytes(emoji,6),'abc','emoji crossing boundary split')

assert_eq(utf8_text.truncate_bytes('ok'..bytes(0xE2,0x82),80),'ok','truncated multibyte sequence leaked')
assert_eq(utf8_text.truncate_bytes('ok'..bytes(0xC0,0xAF)..'x',80),'ok','overlong encoding accepted')
assert_eq(utf8_text.truncate_bytes('ok'..bytes(0xED,0xA0,0x80)..'x',80),'ok','UTF-16 surrogate accepted')
assert_eq(utf8_text.truncate_bytes('ok'..bytes(0xF4,0x90,0x80,0x80)..'x',80),'ok','codepoint above U+10FFFF accepted')
assert_eq(utf8_text.truncate_bytes('ok'..bytes(0xE2,0x28,0xA1)..'x',80),'ok','invalid continuation accepted')

print('utf8_text=PASS ascii=true cyrillic=true cjk=true emoji=true malformed=true')
