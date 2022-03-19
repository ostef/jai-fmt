#scope_module

// This was originally in a separate module, but we want Fmt to be as independant as possible.

 S8_MIN :  s8 :                       -128;
 S8_MAX :  s8 :                        127;
 U8_MAX :  u8 :                        255;
S16_MIN : s16 :                    -32_768;
S16_MAX : s16 :                     32_767;
U16_MAX : u16 :                     65_535;
S32_MIN : s32 :             -2_147_483_648;
S32_MAX : s32 :              2_147_483_647;
U32_MAX : u32 :              4_294_967_295;
S64_MIN : s64 : -9_223_372_036_854_775_808;
S64_MAX : s64 :  9_223_372_036_854_775_807;
U64_MAX : u64 : 18_446_744_073_709_551_615;

decimal_length :: inline (value : $T, $$base : u64 = 10) -> s64 #must
#no_context
{
	unsigned_value : u64;
	if value < 0
		unsigned_value = cast (u64) -value;
	else
		unsigned_value = cast (u64) value;
	length := 0;
	while unsigned_value > 0 || length == 0
	{
		unsigned_value /= base;
		length += 1;
	}
	if value < 0 then length += 1;

	return length;
}

find_first_occurence :: inline (array : []$T, val : T) -> s64 #must
{
	for array
	{
		if it == val
			return it_index;
	}

	return -1;
}

make_string :: inline (data : *u8, count : s64) -> string #must
{
	result : string = ---;
	result.data  = data;
	result.count = count;

	return result;
}

starts_with :: inline (str : string, with : string) -> bool #must
#no_context
#no_abc
{
	if str.count < with.count
		return false;
	for i : 0..with.count - 1
	{
		if str[i] != with[i]
			return false;
	}

	return true;
}

is_digit :: inline (codepoint : u32) -> bool #must
#no_context
{
	return codepoint >= #char "0" && codepoint <= #char "9";
}

is_upper :: inline (codepoint : u32) -> bool #must
#no_context
{
	return codepoint >= #char "A" && codepoint <= #char "Z";
}

advance :: inline (val : string, count := 1) -> string #must
#no_context
{
	if count < 0 then count = 0;
	if count > val.count then count = val.count;

	result : string = ---;
	result.data  = val.data + count;
	result.count = val.count - count;

	return result;
}

flagged :: (val : $T, flag : T) -> bool #must
#expand
{
	return (val & flag) == flag;
}

remove_flag :: (val : $T, flag : T) -> T #must
#expand
{
	return val & ~flag;
}

string_to_u64 :: inline (str : string) -> value : u64 #must, bytes_read : s64
{
	i := 0;
	result : u64;
	while i < str.count && is_digit (str[i])
	{
		result *= 10;
		result += cast (u64) str[i] - #char "0";
		i += 1;
	}

	return result, i;
}

string_to_s64 :: inline (str : string) -> value : s64 #must, bytes_read : s64
{
	if str.count == 0 then return 0, 0;

	i := 0;
	sign := 1;
	if str[0] == #char "-" || str[0] == #char "+"
	{
		sign = cast (s64) (str[0] == #char "+") * 2 - 1;
		i += 1;
	}
	unsigned_value, bytes_read := string_to_u64 (advance (str, i));
	if bytes_read == 0 then return 0, 0;
	signed_value := sign * cast (s64) unsigned_value;

	return signed_value, i + bytes_read;
}

UNICODE_INVALID : u32 : 0xfffd;
UNICODE_MAX     : u32 : 0x0010_ffff;

utf8_encode :: inline (buffer : []u8, codepoint : u32) -> length : s64, written : s64
#no_abc
{
	i := codepoint;
	MASK : u8 : 0x3f;
	written := 0;

	if i <= (1 << 7) - 1
	{
		if buffer.count > 0
		{
			buffer[0] = cast (u8) codepoint;
			written += 1;
		}

		return 1, written;
	}
	else if i <= (1 << 11) - 1
	{
		if buffer.count > 0
		{
			buffer[0] = 0xc0 |  cast (u8) (codepoint >> 6);
			written += 1;
		}
		if buffer.count > 1
		{
			buffer[1] = 0x80 | (cast (u8) (codepoint) & MASK);
			written += 1;
		}

		return 2, written;
	}
	else if i > UNICODE_MAX || (i >= 0xd800 && i <= 0xdfff)
	{
		codepoint = UNICODE_INVALID;
		if buffer.count > 0
		{
			buffer[0] = 0xe0 |  cast (u8) (codepoint >> 12);
			written += 1;
		}
		if buffer.count > 1
		{
			buffer[1] = 0x80 | (cast (u8) (codepoint >> 6) & MASK);
			written += 1;
		}
		if buffer.count > 2
		{
			buffer[2] = 0x80 | (cast (u8) (codepoint) & MASK);
			written += 1;
		}

		return 3, written;
	}
	else if i <= (1 << 16) - 1
	{
		if buffer.count > 0
		{
			buffer[0] = 0xe0 |  cast (u8) (codepoint >> 12);
			written += 1;
		}
		if buffer.count > 1
		{
			buffer[1] = 0x80 | (cast (u8) (codepoint >> 6) & MASK);
			written += 1;
		}
		if buffer.count > 2
		{
			buffer[2] = 0x80 | (cast (u8) (codepoint) & MASK);
			written += 1;
		}

		return 3, written;
	}
	else
	{
		if buffer.count > 0
		{
			buffer[0] = 0xf0 |  cast (u8) (codepoint >> 18);
			written += 1;
		}
		if buffer.count > 1
		{
			buffer[1] = 0x80 | (cast (u8) (codepoint >> 12) & MASK);
			written += 1;
		}
		if buffer.count > 2
		{
			buffer[2] = 0x80 | (cast (u8) (codepoint >> 6) & MASK);
			written += 1;
		}
		if buffer.count > 3
		{
			buffer[3] = 0x80 | (cast (u8) (codepoint) & MASK);
			written += 1;
		}

		return 4, written;
	}
}

utf8_encoding_length :: inline (codepoint : u32) -> s64 #must
{
	if codepoint <= 0x7f
		return 1;
	else if codepoint <= 0x7ff
		return 2;
	else if codepoint <= 0xffff
		return 3;
	else if codepoint <= 0x1fffff
		return 4;

	return 0;
}
