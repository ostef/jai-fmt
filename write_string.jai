write_char :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	index := 0;
	if flagged (arg.flags, .QUOTED)
		index += write_string (buffer, "'");
	if flagged (arg.flags, .QUOTED) || flagged (arg.flags, .PRINT_ESCAPE_SEQUENCES) || flagged (arg.flags, .SINGLE_LINE)
		index += write_char_escaped (buffer, cast (u32) any_to_u64 (arg.value));
	else
		index += write_char (buffer, cast (u32) any_to_u64 (arg.value));
	if flagged (arg.flags, .QUOTED)
		index += write_string (buffer, "'");

	return index;
}

write_byte :: inline (buffer : *$T, byte : u8) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	// We send 0 to buffer.write_byte to indicate the end of the
	// string, so here we filter out 0s.
	if byte == 0
		return 0;
	buffer.write_byte (buffer, byte);

	return 1;
}

write_char :: inline (buffer : *$T, codepoint : u32) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	utf8_sequence : [4]u8 = ---;
	utf8_length := utf8_encode (utf8_sequence, codepoint);
	for i : 0..utf8_length - 1
		write_byte (buffer, utf8_sequence[i]);

	return utf8_length;
}

write_char_escaped :: inline (buffer : *$T, codepoint : u32) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	if codepoint ==
	{
	case 0x00;
		return write_string (buffer, "\\0");
	case 0x07;	// Alert
		return write_string (buffer, "\\a");
	case 0x08;	// Backspace
		return write_string (buffer, "\\b");
	case 0x0c;	// Formfeed Page Break
		return write_string (buffer, "\\f");
	case #char "\n";
		return write_string (buffer, "\\n");
	case #char "\r";
		return write_string (buffer, "\\r");
	case #char "\t";
		return write_string (buffer, "\\t");
	case 0x0b;	// Vertical Tab
		return write_string (buffer, "\\v");
	case #char "\\";
		return write_string (buffer, "\\\\");
	}

	return write_char (buffer, codepoint);
}

write_chars :: inline (buffer : *$T, codepoint : u32, count : s64) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	if count <= 0
		return 0;
	i := 0;
	for 0..count - 1
		i += write_char (buffer, codepoint);

	return i;
}

write_string :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	str := any_to_string (arg.value);
	if !str.data && !flagged (arg.flags, .QUOTED)
		return write_string (buffer, "(null)", arg.precision);

	index := 0;
	if flagged (arg.flags, .QUOTED)
		index += write_string (buffer, "\"");
	if flagged (arg.flags, .QUOTED) || flagged (arg.flags, .PRINT_ESCAPE_SEQUENCES) || flagged (arg.flags, .SINGLE_LINE)
		index += write_string_escaped (buffer, str, arg.precision);
	else
		index += write_string (buffer, str, arg.precision);
	if flagged (arg.flags, .QUOTED)
		index += write_string (buffer, "\"");

	return index;
}

// @Note (stefan): Strings are UTF-8, so we directly print byte per byte instead of calling
// write_char, which would convert from UTF-8 to UTF-8 and give invalid results.
write_string :: inline (buffer : *$T, str : string, max_length := -1) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	length := str.count;
	if max_length >= 0 && length > max_length
		length = max_length;
	for i : 0..length - 1
		write_byte (buffer, str[i]);

	return length;
}

write_string_escaped :: inline (buffer : *$T, str : string, max_length := -1) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	if max_length < 0 then max_length = str.count;
	length := 0;
	for i : 0..max_length - 1
	{
		if str[i] ==
		{
		case 0x00;
			length += write_string (buffer, "\\0");
		case 0x07;	// Alert
			length += write_string (buffer, "\\a");
		case 0x08;	// Backspace
			length += write_string (buffer, "\\b");
		case 0x0c;	// Formfeed Page Break
			length += write_string (buffer, "\\f");
		case #char "\n";
			length += write_string (buffer, "\\n");
		case #char "\r";
			length += write_string (buffer, "\\r");
		case #char "\t";
			length += write_string (buffer, "\\t");
		case 0x0b;	// Vertical Tab
			length += write_string (buffer, "\\v");
		case #char "\\";
			length += write_string (buffer, "\\\\");
		case;
			length += write_byte (buffer, str[i]);
		}
	}

	return length;
}
