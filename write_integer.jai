BINARY_BASE            :: "01";
DECIMAL_BASE           :: "0123456789";
HEXADECIMAL_BASE       :: "0123456789abcdef";
UPPER_HEXADECIMAL_BASE :: "0123456789ABCDEF";

write_bool :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	return write_bool (buffer, any_to_bool (arg.value));
}

write_bool :: inline (buffer : *$T, value : bool) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	if value
		return write_string (buffer, "true");
	return write_string (buffer, "false");
}

write_binary :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	i := 0;
	if flagged (arg.flags, .PRINT_BASE)
		i += write_string (buffer, "0b");

	min_width := -1;
	if arg.precision >= 0
		min_width = arg.precision;
	else if !flagged (arg.flags, .LEFT_JUSTIFY) && flagged (arg.flags, .PAD_WITH_ZEROES)
		min_width = arg.width - i;

	i += write_u64 (buffer, any_to_u64 (arg.value), min_width, BINARY_BASE);

	return i;
}

write_decimal :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	i := 0;
	unsigned_value, negative := any_to_integer (arg.value);
	if negative
		i += write_string (buffer, "-");
	else if flagged (arg.flags, .FORCE_SIGN)
		i += write_string (buffer, "+");
	else if flagged (arg.flags, .ALIGN_SIGN)
		i += write_string (buffer, " ");

	min_width := -1;
	if arg.precision >= 0
		min_width = arg.precision;
	else if !flagged (arg.flags, .LEFT_JUSTIFY) && flagged (arg.flags, .PAD_WITH_ZEROES)
		min_width = arg.width - i;

	i += write_u64 (buffer, unsigned_value, min_width);

	return i;
}

write_hexadecimal :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	i := 0;
	if flagged (arg.flags, .PRINT_BASE)
	{
		if arg.specifier == #char "X"
			i += write_string (buffer, "0X");
		else
			i += write_string (buffer, "0x");
	}
	min_width := -1;
	if arg.precision >= 0
		min_width = arg.precision;
	else if !flagged (arg.flags, .LEFT_JUSTIFY) && flagged (arg.flags, .PAD_WITH_ZEROES)
		min_width = arg.width - i;

	if arg.specifier == #char "X"
		i += write_u64 (buffer, any_to_u64 (arg.value), min_width, UPPER_HEXADECIMAL_BASE);
	else
		i += write_u64 (buffer, any_to_u64 (arg.value), min_width, HEXADECIMAL_BASE);

	return i;
}

write_pointer :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	if !any_to_ptr (arg.value)
		return write_string (buffer, "null");
	i := 0;
	if arg.specifier == #char "X"
		i += write_string (buffer, "0X");
	else
		i += write_string (buffer, "0x");
	min_width := -1;
	if arg.precision >= 0
		min_width = arg.precision;
	else if !flagged (arg.flags, .LEFT_JUSTIFY) && flagged (arg.flags, .PAD_WITH_ZEROES)
		min_width = arg.width - i;
	if arg.specifier == #char "P"
		i += write_u64 (buffer, cast (u64) any_to_ptr (arg.value), min_width, UPPER_HEXADECIMAL_BASE);
	else
		i += write_u64 (buffer, cast (u64) any_to_ptr (arg.value), min_width, HEXADECIMAL_BASE);

	return i;
}

write_s64 :: inline (buffer : *$T, value : s64, min_width := -1, $$base := DECIMAL_BASE) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	sign := cast (s64) (value < 0);
	unsigned_value := cast, no_check (u64) value;
	if sign
	{
		write_char (buffer, #char "-");
		unsigned_value = cast (u64) -value;
	}

	return sign + write_u64 (buffer, unsigned_value, min_width - sign, base);
}

write_u64 :: inline (buffer : *$T, value : u64, min_width := -1, $$base := DECIMAL_BASE) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	length := 0;
	tmp := value;
	while tmp > 0 || length < min_width || (min_width < 0 && length == 0)
	{
		tmp /= cast (u64) base.count;
		length += 1;
	}
	tmp_buffer : [64]u8 = ---;
	for < i : length - 1..0
	{
		tmp_buffer[i] = base[value % cast (u64) base.count];
		value /= cast (u64) base.count;
	}
	str : string = ---;
	str.data = tmp_buffer.data;
	str.count = length;

	return write_string (buffer, str);
}
