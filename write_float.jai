#scope_file

ryu :: #import "Ryu" (IMPORT_FLOAT_TO_SHORTEST = false, IMPORT_STRING_TO_FLOAT = false);

#scope_export

// @Note (stefan):
// The following floating point conversion routines use the Ryū: printf algorithms.
// The precision parameter is capped to a maximum of 16, because 16 is enough precision
// to uniquely identify a double precision floating point value, while being small
// enough to be read back in using Ryu string_to_f64 since it accepts at most 17
// total digits in the mantissa, and we have at most 17 digits with a precision
// of 16 in exponent form (not true when using fixed form since we can have more than 1
// digits before the decimal separator).
// This is also convenient because we can use temporary buffers on the stack and not
// worry about whether the buffer is big enough for arbitrary precision values.

write_f64 :: inline (buffer : *$T, value : f64, precision : u32 = 6) -> length : s64
#modify { T = reject_non_buffer_types (T); }
{
	if precision > 16
		precision = 16;
	ryu_fmt : ryu.Format;
	ryu_fmt.precision = precision;
	ryu_fmt.flags |= .REMOVE_TRAILING_ZEROES;

	exp_buffer : [50]u8 = ---;
	exp_length := ryu.f64_to_exp_buffered (value, ryu_fmt, exp_buffer.data);
	fixed_buffer : [500]u8 = ---;
	fixed_length := ryu.f64_to_fixed_buffered (value, ryu_fmt, fixed_buffer.data);

	str : string = ---;
	if exp_length < fixed_length
	{
		str.data = exp_buffer.data;
		str.count = exp_length;
	}
	else
	{
		str.data = fixed_buffer.data;
		str.count = fixed_length;
	}

	return write_string (buffer, str);
}

write_float_fixed :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { T = reject_non_buffer_types (T); }
{
	ryu_fmt : ryu.Format;
	if flagged (arg.flags, .PAD_WITH_ZEROES) && !flagged (arg.flags, .LEFT_JUSTIFY) && arg.width > 0
		ryu_fmt.min_width = cast (u32) arg.width;
	ryu_fmt.precision = 6;
	if arg.precision >= 0
		ryu_fmt.precision = cast (u32) arg.precision;
	if ryu_fmt.precision > 16
		ryu_fmt.precision = 16;
	if flagged (arg.flags, .FORCE_SIGN)
		ryu_fmt.flags |= .FORCE_SIGN;
	else if flagged (arg.flags, .ALIGN_SIGN)
		ryu_fmt.flags |= .ALIGN_SIGN;
	ryu_fmt.flags |= .FORCE_SIGN_ON_EXPONENT;
	if !flagged (arg.flags, .LEAVE_TRAILING_ZEROES)
		ryu_fmt.flags |= .REMOVE_TRAILING_ZEROES;

	temp_buffer : [500]u8 = ---;
	str : string = ---;
	str.data = temp_buffer.data;
	str.count = ryu.f64_to_fixed_buffered (any_to_f64 (arg.value), ryu_fmt, temp_buffer.data);

	return write_string (buffer, str);
}

write_float_exp :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { T = reject_non_buffer_types (T); }
{
	ryu_fmt : ryu.Format;
	if flagged (arg.flags, .PAD_WITH_ZEROES) && !flagged (arg.flags, .LEFT_JUSTIFY) && arg.width > 0
		ryu_fmt.min_width = cast (u32) arg.width;
	ryu_fmt.precision = 6;
	if arg.precision >= 0
		ryu_fmt.precision = cast (u32) arg.precision;
	if ryu_fmt.precision > 16
		ryu_fmt.precision = 16;
	if flagged (arg.flags, .FORCE_SIGN)
		ryu_fmt.flags |= .FORCE_SIGN;
	else if flagged (arg.flags, .ALIGN_SIGN)
		ryu_fmt.flags |= .ALIGN_SIGN;
	if is_upper (arg.specifier)
		ryu_fmt.flags |= .UPPERCASE;
	ryu_fmt.flags |= .FORCE_SIGN_ON_EXPONENT;
	if !flagged (arg.flags, .LEAVE_TRAILING_ZEROES)
		ryu_fmt.flags |= .REMOVE_TRAILING_ZEROES;

	temp_buffer : [50]u8 = ---;
	str : string = ---;
	str.data = temp_buffer.data;
	str.count = ryu.f64_to_exp_buffered (any_to_f64 (arg.value), ryu_fmt, temp_buffer.data);

	return write_string (buffer, str);
}

write_float_shortest :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { T = reject_non_buffer_types (T); }
{
	ryu_fmt : ryu.Format;
	if flagged (arg.flags, .PAD_WITH_ZEROES) && !flagged (arg.flags, .LEFT_JUSTIFY) && arg.width > 0
		ryu_fmt.min_width = cast (u32) arg.width;
	ryu_fmt.precision = 6;
	if arg.precision >= 0
		ryu_fmt.precision = cast (u32) arg.precision;
	if ryu_fmt.precision > 16
		ryu_fmt.precision = 16;
	if flagged (arg.flags, .FORCE_SIGN)
		ryu_fmt.flags |= .FORCE_SIGN;
	else if flagged (arg.flags, .ALIGN_SIGN)
		ryu_fmt.flags |= .ALIGN_SIGN;
	ryu_fmt.flags |= .FORCE_SIGN_ON_EXPONENT;
	if !flagged (arg.flags, .LEAVE_TRAILING_ZEROES)
		ryu_fmt.flags |= .REMOVE_TRAILING_ZEROES;

	exp_buffer : [50]u8 = ---;
	exp_length := ryu.f64_to_exp_buffered (any_to_f64 (arg.value), ryu_fmt, exp_buffer.data);
	fixed_buffer : [500]u8 = ---;
	fixed_length := ryu.f64_to_fixed_buffered (any_to_f64 (arg.value), ryu_fmt, fixed_buffer.data);

	str : string = ---;
	if exp_length < fixed_length
	{
		str.data = exp_buffer.data;
		str.count = exp_length;
	}
	else
	{
		str.data = fixed_buffer.data;
		str.count = fixed_length;
	}

	return write_string (buffer, str);
}

write_float_hex :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { T = reject_non_buffer_types (T); }
{
	base   : string = ---;
	prefix : string = ---;
	if arg.specifier == #char "A"
	{
		base = UPPER_HEXADECIMAL_BASE;
		prefix = "0X";
	}
	else
	{
		base = HEXADECIMAL_BASE;
		prefix = "0x";
	}

	sign     : bool;
	exponent : u64;
	mantissa : u64;
	bias     : s64;
	// Decompose IEEE value
	if arg.value.type.runtime_size ==
	{
	case 4;
		value := any_to_f32 (arg.value);
		sign, exponent, mantissa = ieee_decompose (value);
		// Extend exponent
		if exponent == ((1 << F32_EXPONENT_BITS) - 1)
			exponent = U64_MAX;
		bias = F32_EXPONENT_BIAS;
	case 8;
		value := any_to_f64 (arg.value);
		sign, exponent, mantissa = ieee_decompose (value);
		// Extend exponent
		if exponent == ((1 << F64_EXPONENT_BITS) - 1)
			exponent = U64_MAX;
		bias = F64_EXPONENT_BIAS;
	}

	if exponent == U64_MAX && mantissa != 0
		return write_string (buffer, "NaN");
	i := 0;
	if sign
		i += write_string (buffer, "-");
	else if flagged (arg.flags, .FORCE_SIGN)
		i += write_string (buffer, "+");
	else if flagged (arg.flags, .ALIGN_SIGN)
		i += write_string (buffer, " ");
	if exponent == U64_MAX
		return i + write_string (buffer, "Inf");
	i += write_string (buffer, prefix);
	if flagged (arg.flags, .PAD_WITH_ZEROES) && !flagged (arg.flags, .LEFT_JUSTIFY)
	{
		total_length := i + 2;
		if arg.precision >= 0
			total_length += arg.precision + 1;
		if exponent
			total_length += decimal_length (cast (s64) exponent - bias, base = 16);
		else
			total_length += 1;
		fill_width := arg.width - total_length;
		i += write_chars (buffer, #char "0", fill_width);
	}
	if exponent
		i += write_string (buffer, "1");
	else
		i += write_string (buffer, "0");
	precision := 6;
	if arg.precision >= 0 then precision = arg.precision;
	if precision > 0
	{
		i += write_string (buffer, ".");
		pow : u64 = 1;
		while mantissa / (pow * 16) > 0
			pow *= 16;
		for 0..precision - 1
		{
			digit : u64;
			if pow
			{
				digit = mantissa / pow;
				digit %= 16;
			}
			write_char (buffer, base[digit]);
			i += 1;
			pow /= 16;
		}
	}
	if arg.specifier == #char "A"
		i += write_string (buffer, "P");
	else
		i += write_string (buffer, "p");
	if exponent
		i += write_s64 (buffer, cast (s64) exponent - bias, base = base);
	else
		i += write_string (buffer, "1");

	return i;
}
