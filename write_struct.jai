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
	for info_struct.members
	{
		if it.offset_in_bytes <= highest_offset
			continue;
		unclosed_format    := false;
		found_fmt_note     := false;
		found_newline_note := false;
		found_follow_note  := false;
		fmt_str := "";
		// Look for notes
		for note : it.notes
		{
			if note == "Fmt_Ignore"
				continue it;
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
		}

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
		ptr  := arg.value.value_pointer + it.offset_in_bytes;
		info := it.type;
		if found_follow_note
			ptr, info = follow_pointer (ptr, info);
		member_arg : Fmt_Arg (T);
		if found_fmt_note
			read_member_arg (*member_arg, fmt_str, ptr, info);
		else
			member_arg = copy_arg (arg, ptr = ptr, type = info);
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
