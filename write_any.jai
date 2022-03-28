write_any :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	return write_any (buffer, arg, false);
}

write_any :: (buffer : *$T, arg : Fmt_Arg (T), is_nested : bool) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	index := 0;
	any := arg.value;
	info := any.type;
	if #complete info.type ==
	{
	case .STRING;
		if is_nested
		{
			index += write_arg (buffer, copy_arg (arg, new_func = write_string, add_flags = .QUOTED));

			return index;
		}
		return index + write_arg (buffer, copy_arg (arg, new_func = write_string));

	case .BOOL;
		return index + write_arg (buffer, copy_arg (arg, new_func = write_bool));

	case .INTEGER;
		return index + write_arg (buffer, copy_arg (arg, new_func = write_decimal));

	case .FLOAT;
		return index + write_arg (buffer, copy_arg (arg, new_func = write_float_shortest));

	case .POINTER;
		return index + write_arg (buffer, copy_arg (arg, new_func = write_pointer));

	case .ENUM;
		info_enum := cast (*Type_Info_Enum) info;
		info_integer := cast (*Type_Info_Integer) info_enum.internal_type;
		enum_value := any_to_s64 (any.value_pointer, info_integer);
		if flagged (info_enum.enum_type_flags, .FLAGS)
		{
			flags_value := cast (u64) enum_value;
			flags_printed : u64;
			first := true;
			for info_enum.values
			{
				value := cast (u64) it;
				if !flagged (flags_value, value) || flagged (flags_printed, value)
					continue;
				flags_printed |= value;
				if !first
					index += write_string (buffer, " | ");
				index += write_string (buffer, info_enum.names[it_index]);
				first = false;
			}

			out_of_range := remove_flag (flags_value, flags_printed);
			if out_of_range != 0 || first
			{
				if !first
					index += write_string (buffer, " | ");
				index += write_string (buffer, "0x");
				index += write_u64 (buffer, out_of_range, base = HEXADECIMAL_BASE);
			}
		}
		else
		{
			name_index := find_first_occurence (info_enum.values, enum_value);
			if name_index == -1
			{
				index += write_string (buffer, info_enum.name);
				index += write_string (buffer, " (");
				index += write_s64 (buffer, enum_value);
				index += write_string (buffer, ")");
			}
			else
			{
				index += write_string (buffer, info_enum.names[name_index]);
			}
		}

		return index;

	case .STRUCT;
		info_struct := cast (*Type_Info_Struct) info;
		index += write_string (buffer, "{ ");
		highest_offset := -1;
		newline := false;
		for info_struct.members
		{
			if it.offset_in_bytes <= highest_offset
				continue;
			if highest_offset != -1
			{
				if newline
					index += write_string (buffer, ",\n  ");
				else
					index += write_string (buffer, ", ");
			}
			if flagged (arg.flags, .PRINT_MEMBER_NAMES)
			{
				index += write_string (buffer, it.name);
				index += write_string (buffer, " : ");
			}
			found_fmt_note := false;
			fmt_str := "";
			for note : it.notes
			{
				if starts_with (note, "Fmt(") && note[note.count - 1] == #char ")"
				{
					found_fmt_note = true;
					fmt_str = advance (note, "Fmt(".count);
					fmt_str.count -= 1;

					break note;
				}
			}
			ptr := any.value_pointer + it.offset_in_bytes;
			member_arg : Fmt_Arg (T);
			if found_fmt_note
				read_member_arg (*member_arg, fmt_str, ptr, it.type);
			else
				member_arg = copy_arg (arg, ptr = ptr, type = it.type);
			// @Cleanup @Note (stefan): Because we don't have an is_nested parameter
			// in write_arg, we simulate nestedness by adding the SINGLE_LINE
			// flag. The problem with that is for cases where nesting is not exactly
			// the same as using SINGLE_LINE, the behaviour might not be correct.
			// This is kind of a hack right now, but I don't know if we'll actually
			// change this in the future. We used to call write_any, but the recent
			// addition of Fmt() notes on struct members forces us to use write_arg
			// instead, since write_any does not care about the specifier.
			member_arg.flags |= .SINGLE_LINE;
			member_arg.flags |= .QUOTED;	// See above
			if !member_arg.write_func
				index += write_string (buffer, "(invalid specifier)");
			else
				index += write_arg (buffer, member_arg);
			newline = !flagged (arg.flags, .SINGLE_LINE) && !is_nested && find_first_occurence (it.notes, "Fmt_Newline") != -1;
			highest_offset = it.offset_in_bytes;
		}
		index += write_string (buffer, " }");

		return index;

	case .ARRAY;
		info_array := cast (*Type_Info_Array) info;
		count := any_get_array_count (any);
		data  := any_get_array_data (any);
		index += write_string (buffer, "[ (");
		if info_array.array_type == .RESIZABLE
			index += write_string (buffer, "..");
		index += write_s64 (buffer, count);
		index += write_string (buffer, ") ");
		for i : 0..count - 1
		{
			if i != 0
				index += write_string (buffer, ", ");
			ptr := data + i * info_array.element_type.runtime_size;
			index += write_any (buffer, copy_arg (arg, ptr = ptr, type = info_array.element_type), is_nested = true);
		}
		index += write_string (buffer, " ]");

		return index;

	case .VARIANT;
		return index + write_any (buffer, copy_arg (arg, type = (cast (*Type_Info_Variant) info).variant_of));

	case .TYPE;
		return index + write_type (buffer, <<cast (**Type_Info) any.value_pointer, flagged (arg.flags, .PRINT_MEMBER_NAMES));
	
	case .ANY;
		new_any := <<cast (*Any) any.value_pointer;

		return index + write_any (buffer, copy_arg (arg, ptr = new_any.value_pointer, type = new_any.type));

	case .PROCEDURE;
		index += write_string (buffer, "procedure 0x");
		index += write_u64 (buffer, <<cast (*u64) any.value_pointer, base = HEXADECIMAL_BASE);

		return index;

	case .CODE; #through;
	case .VOID; #through;
	case .OVERLOAD_SET; #through;
	case .POLYMORPHIC_VARIABLE;
		return index + write_string (buffer, "(unhandled type)");
	}

	// We handle all types, so if we get here then type info is corrupt.
	return index + write_string (buffer, "(corrupt type info)");
}

write_relative_pointer_size :: inline (buffer : *$T, size : s64) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	if size ==
	{
	case 1;
		return write_string (buffer, "~s8");
	case 2;
		return write_string (buffer, "~s16");
	case 4;
		return write_string (buffer, "~s32");
	case 8;
		return write_string (buffer, "~s64");
	}
	return 0;
}

write_type :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	info := arg.value.type;
	if info.type == .TYPE
	|| info.type == .POINTER && is_substruct_of ((cast (*Type_Info_Pointer) info).pointer_to, type_info (Type_Info))
		return write_type (buffer, <<cast (**Type_Info) arg.value.value_pointer, flagged (arg.flags, .PRINT_MEMBER_NAMES));
	return write_type (buffer, arg.value.type, flagged (arg.flags, .PRINT_MEMBER_NAMES));
}

write_type :: (buffer : *$T, info : *Type_Info, print_member_names := false) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	if #complete info.type ==
	{
	case .VOID;
		return write_string (buffer, "void");

	case .STRING;
		info_str := cast (*Type_Info_String) info;
		i := write_string (buffer, "string");
		i += write_relative_pointer_size (buffer, info_str.relative_pointer_size);

		return i;

	case .BOOL;
		return write_string (buffer, "bool");

	case .INTEGER;
		info_int := cast (*Type_Info_Integer) info;
		if info_int.runtime_size ==
		{
		case 1;
			if info_int.signed
				return write_string (buffer, "s8");
			else
				return write_string (buffer, "u8");

		case 2;
			if info_int.signed
				return write_string (buffer, "s16");
			else
				return write_string (buffer, "u16");

		case 4;
			if info_int.signed
				return write_string (buffer, "s32");
			else
				return write_string (buffer, "u32");

		case 8;
			if info_int.signed
				return write_string (buffer, "s64");
			else
				return write_string (buffer, "u64");
		}

	case .FLOAT;
		if info.runtime_size ==
		{
		case 4;
			return write_string (buffer, "f32");

		case 8;
			return write_string (buffer, "f64");
		}

	case .POINTER;
		info_pointer := cast (*Type_Info_Pointer) info;
		i := write_string (buffer, "*");
		if info_pointer.relative_pointer_size
		{
			i += write_relative_pointer_size (buffer, info_pointer.relative_pointer_size);
			i += write_string (buffer, " ");
		}

		return i + write_type (buffer, info_pointer.pointer_to, print_member_names);

	case .ENUM;
		info_enum := cast (*Type_Info_Enum) info;
		if info_enum.name
			return write_string (buffer, info_enum.name);
		else
			return write_string (buffer, "(anonymous enum)");

	case .STRUCT;
		info_struct := cast (*Type_Info_Struct) info;
		index := 0;
		if info_struct.name
			index += write_string (buffer, info_struct.name);
		else if flagged (info_struct.textual_flags, .UNION)
			index += write_string (buffer, "(anonymous union)");
		else
			index += write_string (buffer, "(anonymous struct)");
		if info_struct.polymorph_source_struct
		{
			index += write_string (buffer, " (");
			for * param : info_struct.specified_parameters
			{
				if it_index != 0
					index += write_string (buffer, ", ");
				if print_member_names
					index += write_string (buffer, param.name);

				if param.offset_into_constant_storage >= 0
				{
					if print_member_names
						index += write_string (buffer, " = ");
					index += write_any (buffer, info_struct.constant_storage_buffer + param.offset_into_constant_storage, param.type);
				}
			}
			index += write_string (buffer, ")");
		}

		return index;

	case .VARIANT;
		info_variant := cast (*Type_Info_Variant) info;

		return write_string (buffer, info_variant.name);

	case .ARRAY;
		info_array := cast (*Type_Info_Array) info;
		index := 0;
		if #complete info_array.array_type ==
		{
		case .FIXED;
			index += write_string (buffer, "[");
			index += write_s64 (buffer, info_array.array_count);
			index += write_string (buffer, "]");
		case .VIEW;
			index += write_string (buffer, "[]");
		case .RESIZABLE;
			index += write_string (buffer, "[..]");
		}
		index += write_type (buffer, info_array.element_type, print_member_names);

		return index;

	case .PROCEDURE;
		info_procedure := cast (*Type_Info_Procedure) info;
		index := 0;
		index += write_string (buffer, "(");
		for info_procedure.argument_types
		{
			if it_index != 0
				index += write_string (buffer, ", ");
			index += write_type (buffer, it, print_member_names);
		}
		index += write_string (buffer, ")");

		if info_procedure.return_types
		{
			index += write_string (buffer, " -> ");
			if info_procedure.return_types.count > 1
				index += write_string (buffer, "(");
			for info_procedure.return_types
			{
				if it_index != 0
					index += write_string (buffer, ", ");
				index += write_type (buffer, it, print_member_names);
			}
			if info_procedure.return_types.count > 1
				index += write_string (buffer, ")");
		}
		proc_flags := info_procedure.procedure_flags;
		if flagged (proc_flags, .IS_ELSEWHERE)
			index += write_string (buffer, "#elsewhere");
		if flagged (proc_flags, .IS_COMPILE_TIME)
			index += write_string (buffer, "#compiler");
		if flagged (proc_flags, .IS_C_CALL)
			index += write_string (buffer, "#c_call");
		if flagged (proc_flags, .IS_INTRINSIC)
			index += write_string (buffer, "#intrinsic");

		return index;

	case .CODE;
		return write_string (buffer, "Code");

	case .TYPE;
		return write_string (buffer, "Type");

	case .ANY;
		return write_string (buffer, "Any");
	
	case .OVERLOAD_SET; #through;
	case .POLYMORPHIC_VARIABLE;
		return write_string (buffer, "(unhandled type)");
	}

	// We handle all types, so if we get here then type info is corrupt.
	return write_string (buffer, "(corrupt type info)");
}

write_any :: inline (buffer : *$T, ptr : *void, type : *Type_Info) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	arg : Fmt_Arg (T);
	arg.value.value_pointer = ptr;
	arg.value.type = type;

	return write_any (buffer, arg);
}
