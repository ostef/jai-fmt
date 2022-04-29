write_any :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	return write_any (buffer, arg, false);
}

write_any :: inline (buffer : *$T, ptr : *void, type : *Type_Info, is_nested : bool) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	arg : Fmt_Arg (T);
	arg.value.value_pointer = ptr;
	arg.value.type = type;
	return write_any (buffer, arg, is_nested);
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
			return index + write_arg (buffer, copy_arg (arg, new_func = write_string, add_flags = .QUOTED));
		return index + write_arg (buffer, copy_arg (arg, new_func = write_string));

	case .BOOL;
		return index + write_arg (buffer, copy_arg (arg, new_func = write_bool));

	case .INTEGER;
		return index + write_arg (buffer, copy_arg (arg, new_func = write_decimal));

	case .FLOAT;
		return index + write_arg (buffer, copy_arg (arg, new_func = write_float_fixed));

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
		return write_struct (buffer, arg, is_nested);

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
		value := <<cast (*u64) any.value_pointer;
		if value
		{
			index += write_string (buffer, "procedure 0x");
			index += write_u64 (buffer, value, base = HEXADECIMAL_BASE);
		}
		else
			index += write_string (buffer, "null");

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

#scope_file

follow_pointer :: inline (ptr : *void, info : *Type_Info) -> *void, *Type_Info
{
	if info.type != .POINTER
		return ptr, info;
	info_ptr := cast (*Type_Info_Pointer) info;
	new_ptr : *void;
	if info_ptr.relative_pointer_size
		new_ptr = relative_to_absolute_ptr (ptr, info_ptr.relative_pointer_size);
	else
		new_ptr = <<cast (**void) ptr;
	if new_ptr
		return new_ptr, info_ptr.pointer_to;

	return ptr, info;
}

#scope_export

write_struct :: (buffer : *$T, arg : Fmt_Arg (T), is_nested : bool) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	index := write_string (buffer, "{");
	highest_offset := -1;
	newline := false;
	info_struct := cast (*Type_Info_Struct) arg.value.type;
	has_tag : bool;
	union_tag : s64;
	for info_struct.members
	{
		if it.offset_in_bytes <= highest_offset
			continue;
		unclosed_format    := false;
		found_ignore_note  := false;
		found_fmt_note     := false;
		found_newline_note := false;
		found_follow_note  := false;
		found_tag_note     := false;
		found_tag_union_note := false;
		fmt_str := "";
		// Look for notes
		for note : it.notes
		{
			if note == "Fmt_Ignore"
				found_ignore_note = true;
			else if starts_with (note, "Fmt(")
			{
				if note[note.count - 1] != #char ")"
					unclosed_format = true;
				else
				{
					found_fmt_note = true;
					fmt_str = advance (note, "Fmt(".count);
					fmt_str.count -= 1;
				}
			}
			else if note == "Fmt_Newline"
				found_newline_note = true;
			else if note == "Fmt_Follow_Ptr"
				found_follow_note = true;
			else if note == "Fmt_Tag"
				found_tag_note = true;
			else if note == "Fmt_Tagged_Union"
				found_tag_union_note = true;
		}

		ptr  := arg.value.value_pointer + it.offset_in_bytes;
		info := it.type;
		if found_follow_note
			ptr, info = follow_pointer (ptr, info);
		if found_tag_note
		{
			info_enum := cast (*Type_Info_Enum) it.type;
			if info_enum.type == .ENUM && !flagged (info_enum.enum_type_flags, .FLAGS)
			{
				has_tag = true;
				union_tag = any_to_s64 (ptr, info_enum.internal_type);
			}
		}
		if found_ignore_note
			continue;
		if highest_offset == -1
			index += write_string (buffer, " ");
		else if newline
			index += write_string (buffer, ",\n  ");
		else
			index += write_string (buffer, ", ");

		if flagged (arg.flags, .PRINT_MEMBER_NAMES)
		{
			index += write_string (buffer, it.name);
			index += write_string (buffer, " : ");
		}

		member_arg : Fmt_Arg (T);
		if found_fmt_note
			read_member_arg (*member_arg, fmt_str, ptr, info);
		else
			member_arg = copy_arg (arg, ptr = ptr, type = info);
		if has_tag && found_tag_union_note && it.type.type == .STRUCT
		&& flagged ((cast (*Type_Info_Struct) it.type).textual_flags, .UNION)
		{
			member_arg = copy_arg (member_arg, new_func = write_tagged_union);
			member_arg.union_tag = union_tag;
		}
		// @Cleanup @Note (stefan): Because we don't have an is_nested parameter
		// in write_arg, we simulate nestedness by adding the SINGLE_LINE and QUOTED
		// flags. The problem with that is for cases where nesting is not exactly
		// the same as using these flags, the behaviour might not be correct.
		// This is kind of a hack right now, but I don't know if we'll actually
		// change this in the future. We used to call write_any, but the recent
		// addition of Fmt() notes on struct members forces us to use write_arg
		// instead, since write_any does not care about the specifier.
		member_arg.flags |= .SINGLE_LINE;
		member_arg.flags |= .QUOTED;
		if unclosed_format
			index += write_string (buffer, "(unclosed Fmt note)");
		else if !member_arg.write_func
			index += write_string (buffer, "(invalid specifier)");
		else
			index += write_arg (buffer, member_arg);
		newline = !flagged (arg.flags, .SINGLE_LINE) && !is_nested && found_newline_note;
		highest_offset = it.offset_in_bytes;
	}
	if highest_offset != -1
		index += write_string (buffer, " ");
	index += write_string (buffer, "}");

	return index;
}

write_tagged_union :: (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	info_struct := cast (*Type_Info_Struct) arg.value.type;
	if arg.union_tag < 0 || arg.union_tag >= info_struct.members.count
		return write_string (buffer, "(invalid union tag)");
	newline := false;
	it := info_struct.members[arg.union_tag];
	
	unclosed_format   := false;
	found_fmt_note    := false;
	found_follow_note := false;
	fmt_str := "";
	// Look for notes
	for note : it.notes
	{
		if note == "Fmt_Ignore"
			return write_string (buffer, "(ignored)");
		else if starts_with (note, "Fmt(")
		{
			if note[note.count - 1] != #char ")"
				unclosed_format = true;
			else
			{
				found_fmt_note = true;
				fmt_str = advance (note, "Fmt(".count);
				fmt_str.count -= 1;
			}
		}
		else if note == "Fmt_Follow_Ptr"
			found_follow_note = true;
	}

	ptr  := arg.value.value_pointer + it.offset_in_bytes;
	info := it.type;
	if found_follow_note
		ptr, info = follow_pointer (ptr, info);

	member_arg : Fmt_Arg (T);
	if found_fmt_note
		read_member_arg (*member_arg, fmt_str, ptr, info);
	else
		member_arg = copy_arg (arg, ptr = ptr, type = info, new_func = write_any);
	// @Cleanup @Note (stefan): Because we don't have an is_nested parameter
	// in write_arg, we simulate nestedness by adding the SINGLE_LINE and QUOTED
	// flags. The problem with that is for cases where nesting is not exactly
	// the same as using these flags, the behaviour might not be correct.
	// This is kind of a hack right now, but I don't know if we'll actually
	// change this in the future. We used to call write_any, but the recent
	// addition of Fmt() notes on struct members forces us to use write_arg
	// instead, since write_any does not care about the specifier.
	member_arg.flags |= .SINGLE_LINE;
	member_arg.flags |= .QUOTED;
	if unclosed_format
		return write_string (buffer, "(unclosed Fmt note)");
	else if !member_arg.write_func
		return write_string (buffer, "(invalid specifier)");
	return write_arg (buffer, member_arg);
}
