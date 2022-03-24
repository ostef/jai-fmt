#load "utils.jai";
#load "any.jai";
#load "print.jai";

#load "write_string.jai";
#load "write_integer.jai";
#load "write_float.jai";
#load "write_any.jai";

#scope_module

f32 :: float32;
f64 :: float64;

#scope_export

// Format:
// * % will print the argument based on the type information
// * {[arg_index][:[flags][width][.precision][specifier]]} for more advanced formatting options
// width can be '*' instead of an unsigned integer, to read the value from the args array.
// precision can be '*' instead of an integer, to read the value from the args array.

// Valid specifiers are:
// - c: print Unicode codepoint,
// - s: print UTF-8 string,
// - B: print boolean value, anything non-zero is treated as true,
// - b: print 64-bit unsigned integer in binary,
// - i: print 64-bit signed or unsigned integer in decimal,
// - d: same as above,
// - x: print 64-bit unsigned integer in lowercase hexadecimal,
// - X: print 64-bit unsigned integer in uppercase hexadecimal,
// - p: print pointer as hexadecimal unsigned 64-bit integer, print null if zero
// - f: print 64-bit floating point number in fixed form (uses Ryu d2fixed conversion),
// - e: print 64-bit floating point number in lowercase exponent form (uses Ryu d2exp conversion),
// - E: print 64-bit floating point number in uppercase exponent form (uses Ryu d2exp conversion),
// - g: print the shortest representation of a 64-bit floating point number between fixed and exponent lowercase form,
// - G: print the shortest representation of a 64-bit floating point number between fixed and exponent uppercase form,
// - t: print a Type or type information as a type. For other values, print the value's type.

Fmt_Buffer :: struct
{
	write_byte :: inline (buffer : *Fmt_Buffer, byte : u8)
	{
		if buffer && buffer.count < buffer.capacity
		{
			buffer.data[buffer.count] = byte;
			buffer.count += 1;
		}
	}

	data : *u8;
	count : s64;
	capacity : s64;
}

make_fmt_buffer :: inline (array : []u8) -> Fmt_Buffer #must
{
	result : Fmt_Buffer;
	result.data = array.data;
	result.capacity = array.count;

	return result;
}

make_fmt_buffer :: inline (str : string) -> Fmt_Buffer #must
{
	result : Fmt_Buffer;
	result.data = str.data;
	result.capacity = str.count;

	return result;
}

reject_non_buffer_types :: inline (info : *Type_Info) -> *Type_Info #must
{
	if info.type != .STRUCT
		return null;
	info_struct := cast (*Type_Info_Struct) info;
	for info_struct.members
	{
		if it.name == "write_byte"
		{
			if it.type.type != .PROCEDURE
				return null;
			info_proc := cast (*Type_Info_Procedure) it.type;
			if info_proc.argument_types.count != 2 || info_proc.return_types.count != 0
				return null;
			if info_proc.argument_types[0].type != .POINTER
				return null;
			info_arg0 := cast (*Type_Info_Pointer) info_proc.argument_types[0];
			if info_arg0.relative_pointer_size != 0 || info_arg0.pointer_to != info
				return null;
			if info_proc.argument_types[1] != type_info (u8)
				return null;

			return info;
		}
	}

	return null;
}

Fmt_Flags :: enum_flags
{
	NONE                   :: 0x000;
	RIGHT_JUSTIFY          :: 0x000;	// Default
	LEFT_JUSTIFY           :: 0x001;
	FORCE_SIGN             :: 0x002;	// Print a '+' in front of positive signed integer values
	ALIGN_SIGN             :: 0x004;	// Align signed integers, printing a ' ' in front of positive values
	PAD_WITH_ZEROES        :: 0x008;	// Pad integer and float values with '0' instead of ' ', ignored if LEFT_JUSTIFY is set
	PRINT_BASE             :: 0x010;	// Print the base prefix for integer values, '0x' or '0X' for hex, '0b' for binary
	LEAVE_TRAILING_ZEROES  :: 0x020;	// For fixed and exponent form floating point numbers, leave trailing zeroes after decimal point
	PRINT_ESCAPE_SEQUENCES :: 0x040;	// Print escape sequences for non printable characters
	QUOTED                 :: 0x080;	// Surround with quotes for character or string specifiers, and print on one line
	SINGLE_LINE            :: 0x100;	// Print on one line
	PRINT_MEMBER_NAMES     :: 0x200;	// Print struct member names
}

Fmt_Arg :: struct (Buffer_Type : Type)
{
	This_Type :: #this;

	Write_Func :: #type (buffer : *Buffer_Type, arg : This_Type) -> length : s64;

	SPECIFIER_KEYS  :: "csBbidxXpPfeEgGt";
	SPECIFIER_FUNCS :: Write_Func.[
		#bake_constants write_char (T = Buffer_Type),
		#bake_constants write_string (T = Buffer_Type),
		#bake_constants write_bool (T = Buffer_Type),
		#bake_constants write_binary (T = Buffer_Type),
		#bake_constants write_decimal (T = Buffer_Type),
		#bake_constants write_decimal (T = Buffer_Type),
		#bake_constants write_hexadecimal (T = Buffer_Type),
		#bake_constants write_hexadecimal (T = Buffer_Type),
		#bake_constants write_pointer (T = Buffer_Type),
		#bake_constants write_pointer (T = Buffer_Type),
		#bake_constants write_float_fixed (T = Buffer_Type),
		#bake_constants write_float_exp (T = Buffer_Type),
		#bake_constants write_float_exp (T = Buffer_Type),
		#bake_constants write_float_shortest (T = Buffer_Type),
		#bake_constants write_float_shortest (T = Buffer_Type),
		#bake_constants write_type (T = Buffer_Type)
	];

	arg_index  := -1;
	flags      : Fmt_Flags;
	width      := -1;
	precision  := -1;
	specifier  : u8;
	write_func : Write_Func;
	value      : Any;
}

#scope_file

FLAG_KEYS   :: "<>+ _0#~\\'$!";
FLAG_VALUES :: Fmt_Flags.[
	.LEFT_JUSTIFY,
	.RIGHT_JUSTIFY,
	.FORCE_SIGN,
	.ALIGN_SIGN,
	.ALIGN_SIGN,
	.PAD_WITH_ZEROES,
	.PRINT_BASE,
	.LEAVE_TRAILING_ZEROES,
	.PRINT_ESCAPE_SEQUENCES,
	.QUOTED,
	.SINGLE_LINE,
	.PRINT_MEMBER_NAMES
];

#scope_export

copy_arg :: inline (
	arg : Fmt_Arg ($T),
	ptr : *void = null,
	type : *Type_Info = null,
	new_func : arg.Write_Func = null,
	new_specifier : u8 = 0,
	add_flags : Fmt_Flags = .NONE
) -> Fmt_Arg (T)
#modify { T = reject_non_buffer_types (T); }
{
	result := arg;
	if ptr
		result.value.value_pointer = ptr;
	if type
		result.value.type = type;
	if new_func
		result.write_func = new_func;
	if new_specifier
		result.specifier = new_specifier;
	if add_flags
		result.flags |= add_flags;

	return result;
}

// @Cleanup (stefan): De-duplicate the code in read_member_arg and read_arg
read_member_arg :: inline (
	result : *Fmt_Arg ($T),
	fmt_str : string,
	ptr : *void,
	type : *Type_Info
) -> s64
#modify { T = reject_non_buffer_types (T); }
#no_abc
{
	result.value.value_pointer = ptr;
	result.value.type = type;
	len := fmt_str.count;
	i := 0;
	// Read optional flags
	while i < len
	{
		found_flag := false;
		for fi : 0..FLAG_KEYS.count - 1
		{
			if fmt_str[i] == FLAG_KEYS[fi]
			{
				result.flags |= FLAG_VALUES[fi];
				found_flag = true;
				i += 1;

				break;
			}
		}
		if !found_flag then break;
	}
	// Read optional width
	if i < len && is_digit (fmt_str[i])
	{
		value, skip := string_to_u64 (advance (fmt_str, i));
		i += skip;
		result.width = cast (s64) value;
	}
	// Read optional precision
	if i < len && fmt_str[i] == #char "."
	{
		i += 1;
		result.precision = 0;
		if i < fmt_str.count
		{
			value, skip := string_to_s64 (advance (fmt_str, i));
			i += skip;
			result.precision = value;
		}
	}
	// Read optional specifier
	if i < len
	{
		result.specifier = fmt_str[i];
		i += 1;
		// Get write function
		for si : 0..result.SPECIFIER_KEYS.count - 1
		{
			if result.specifier == result.SPECIFIER_KEYS[si]
			{
				result.write_func = result.SPECIFIER_FUNCS[si];

				break;
			}
		}
	}
	else
		result.write_func = write_any;

	return i;
}

read_arg :: inline (
	result : *Fmt_Arg ($T),
	fmt_str : string,
	arg_index : s64,
	args : ..Any
) ->
	fmt_skip : s64 #must,
	arg_skip : s64 #must
#modify { T = reject_non_buffer_types (T); }
#no_abc
{
	arg_skip := 0;
	i := 0;
	specified := false;
	// Find the end of the format
	len := i;
	while len < fmt_str.count && fmt_str[len] != #char "}"
		len += 1;
	if i < len && fmt_str[i] == #char ":"
	{
		specified = true;
		i += 1;
	}
	// Read optional argument index
	if i < len && !specified
	{
		value, skip := string_to_u64 (advance (fmt_str, i));
		while i < len
		{
			if fmt_str[i] == #char ":"
			{
				specified = true;
				i += 1;
				break;
			}
			else if fmt_str[i] == #char "}"
			{
				i += 1;
				break;
			}
			i += 1;
		}
		if skip == 0
			result.arg_index = -2;
		else
			result.arg_index = cast (s64) value;
	}
	if !specified
	{
		result.write_func = write_any;
		if result.arg_index == -1
		{
			result.arg_index = arg_index + arg_skip;
			arg_skip += 1;
		}
		i = len;
		if i < fmt_str.count
			i += 1;

		return i, arg_skip;
	}

	// Read optional flags
	while i < len
	{
		found_flag := false;
		for fi : 0..FLAG_KEYS.count - 1
		{
			if fmt_str[i] == FLAG_KEYS[fi]
			{
				result.flags |= FLAG_VALUES[fi];
				found_flag = true;
				i += 1;

				break;
			}
		}
		if !found_flag then break;
	}
	// Read optional width
	if i < len && fmt_str[i] == #char "*"
	{
		i += 1;
		if arg_index + arg_skip < args.count
			result.width = any_to_s64 (args[arg_index + arg_skip]);
		arg_skip += 1;
	}
	else if i < len && is_digit (fmt_str[i])
	{
		value, skip := string_to_u64 (advance (fmt_str, i));
		i += skip;
		result.width = cast (s64) value;
	}
	// Read optional precision
	if i < len && fmt_str[i] == #char "."
	{
		i += 1;
		result.precision = 0;
		if i < fmt_str.count && fmt_str[i] == #char "*"
		{
			i += 1;
			if arg_index + arg_skip < args.count
				result.precision = any_to_s64 (args[arg_index + arg_skip]);
			arg_skip += 1;
		}
		else if i < fmt_str.count
		{
			value, skip := string_to_s64 (advance (fmt_str, i));
			i += skip;
			result.precision = value;
		}
	}
	if i < len
	{
		result.specifier = fmt_str[i];
		i += 1;
		// Get write function
		for si : 0..result.SPECIFIER_KEYS.count - 1
		{
			if result.specifier == result.SPECIFIER_KEYS[si]
			{
				result.write_func = result.SPECIFIER_FUNCS[si];

				break;
			}
		}
	}
	else
		result.write_func = write_any;
	i = len;
	if i < fmt_str.count
		i += 1;
	// We read width and precision, so we set the arg_index here
	// since we're sure the arg_skip won't change anymore.
	if result.arg_index == -1
	{
		result.arg_index = arg_index + arg_skip;
		arg_skip += 1;
	}

	return i, arg_skip;
}

#scope_file

write_arg_to_temp_buffer :: inline (buffer : []u8, arg : Fmt_Arg ($T)) -> length : s64
#modify { T = reject_non_buffer_types (T); }
{
	#assert size_of (Fmt_Arg (T)) == size_of (Fmt_Arg (Fmt_Buffer));

	temp_buffer : Fmt_Buffer = ---;
	temp_buffer.data = buffer.data;
	temp_buffer.count = 0;
	temp_buffer.capacity = buffer.count;
	temp_arg : Fmt_Arg (Fmt_Buffer);
	memcpy (*temp_arg, *arg, size_of (Fmt_Arg (T)));
#if T != Fmt_Buffer
{
	if temp_arg.specifier
	{
		// Get write function from the specifier, since we can't interchange write funcs of different types.
		for si : 0..temp_arg.SPECIFIER_KEYS.count - 1
		{
			if temp_arg.specifier == temp_arg.SPECIFIER_KEYS[si]
			{
				temp_arg.write_func = temp_arg.SPECIFIER_FUNCS[si];

				break;
			}
		}
	}
	else
		temp_arg.write_func = write_any;
}

	return temp_arg.write_func (*temp_buffer, temp_arg);
}

#scope_export

write_arg :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64 #must
#modify { T = reject_non_buffer_types (T); }
{
	if !arg.write_func
		return 0;

	i := 0;
	// Handle field width. This calls write_func two times, the
	// first time being to retrieve the final length without
	// field width. If we managed to write everything to a temporary
	// buffer, we just copy what we wrote instead of calling write_func
	// a second time.
	if arg.width > 0 && (!flagged (arg.flags, .PAD_WITH_ZEROES) || flagged (arg.flags, .LEFT_JUSTIFY))
	{
		temp_buffer : [690]u8 = ---;
		length := write_arg_to_temp_buffer (temp_buffer, arg);
		if !flagged (arg.flags, .LEFT_JUSTIFY)
			i += write_chars (buffer, #char " ", arg.width - length);
		if length <= temp_buffer.count
			i += write_string (buffer, make_string (temp_buffer.data, length));
		else
			i += arg.write_func (buffer, arg);
		if flagged (arg.flags, .LEFT_JUSTIFY)
			i += write_chars (buffer, #char " ", arg.width - length);
	}
	else
		i += arg.write_func (buffer, arg);

	return i;
}

fmt :: format;
format :: inline (buffer : *$T, fmt_str : string, args : ..Any) -> length : s64
#modify { T = reject_non_buffer_types (T); }
{
	buffer_index := 0;
	fmt_index    := 0;
	arg_index    := 0;
	while fmt_index < fmt_str.count
	{
		if fmt_str[fmt_index] == #char "%" || fmt_str[fmt_index] == #char "{"
		{
			fmt_index += 1;
			if fmt_index == fmt_str.count || fmt_str[fmt_index] != fmt_str[fmt_index - 1]
			{
				arg : Fmt_Arg (T);
				fmt_skip := 0;
				arg_skip := 0;
				unclosed := false;
				if fmt_str[fmt_index - 1] == #char "{"
				{
					fmt_skip, arg_skip = read_arg (*arg, advance (fmt_str, fmt_index), arg_index, ..args);
					unclosed = fmt_str[fmt_index + fmt_skip - 1] != #char "}";
				}
				else
				{
					arg.write_func = write_any;
					arg.arg_index = arg_index;
					arg_skip = 1;
				}
				fmt_index += fmt_skip;
				arg_index += arg_skip;
				if unclosed
					buffer_index += write_string (buffer, "(unclosed format)");
				else if !arg.write_func
					buffer_index += write_string (buffer, "(invalid specifier)");
				else if arg.arg_index >= args.count
					buffer_index += write_string (buffer, "(no argument provided)");
				else if arg.arg_index < 0
					buffer_index += write_string (buffer, "(invalid argument index)");
				else if arg.arg_index < args.count
				{
					arg.value = args[arg.arg_index];
					buffer_index += write_arg (buffer, arg);
				}

				continue;
			}
		}
		buffer_index += write_byte (buffer, fmt_str[fmt_index]);
		fmt_index    += 1;
	}

	return buffer_index;
}

format :: inline (allocator : Allocator, fmt_str : string, args : ..Any) -> string #must
{
	buffer : Fmt_Buffer;
	buffer.capacity = format (cast (*Fmt_Buffer) null, fmt_str, ..args);
	if buffer.capacity == 0
		return "";
	buffer.data  = cast (*u8) allocator.proc (.ALLOCATE, buffer.capacity, 0, null, allocator.data);
	str : string = ---;
	str.data = buffer.data;
	str.count = format (*buffer, fmt_str, ..args);

	return str;
}
