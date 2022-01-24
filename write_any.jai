write_any :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
{
	return write_any (buffer, arg.value);
}

write_any :: inline (buffer : *$T, ptr : *void, info : *Type_Info, indentation_level := 0, is_nested := false) -> length : s64
{
	any : Any = ---;
	any.value_pointer = ptr;
	any.type = info;

	return write_any (buffer, any, indentation_level, is_nested);
}

write_any :: (buffer : *$T, any : Any, indentation_level := 0, is_nested := false) -> length : s64
{
	index := 0;
	index += write_chars (buffer, #char "\t", indentation_level);

	info := any.type;
	if #complete info.type ==
	{
	case .STRING;
		if is_nested
		{
			index += write_char (buffer, #char "\"");
			index += write_string_escaped (buffer, any_to_string (any));
			index += write_char (buffer, #char "\"");

			return index;
		}
		return index + write_string (buffer, any_to_string (any));

	case .BOOL;
		return index + write_bool (buffer, any_to_bool (any));

	case .INTEGER;
		info_int := cast (*Type_Info_Integer) info;
		if info_int.signed
			return index + write_s64 (buffer, any_to_s64 (any));
		else
			return index + write_u64 (buffer, any_to_u64 (any));

	case .FLOAT;
		return index + write_f64 (buffer, any_to_f64 (any));

	case .POINTER;
		ptr := any_to_ptr (any);
		if ptr
		{
			index += write_string (buffer, "0x");
			index += write_u64 (buffer, cast (u64) ptr, base = HEXADECIMAL_BASE);

			return index;
		}

		return write_string (buffer, "null");

	case .ENUM;
		info_enum := cast (*Type_Info_Enum) info;
		info_integer := cast (*Type_Info_Integer) info_enum.internal_type;
		enum_value := any_to_s64 (any.value_pointer, info_integer);

		if info_enum.enum_type_flags & .FLAGS
		{
			flags_value := cast (u64) enum_value;
			flags_printed : u64;
			first := true;
			for info_enum.values
			{
				value := cast (u64) it;
				flag := flags_value & value;
				if flag != value then flag = 0;
				if flag == 0 then continue;
				if !(flag & ~flags_printed) then continue;
				flags_printed |= flag;

				if !first
					index += write_string (buffer, " | ");
				index += write_string (buffer, info_enum.names[it_index]);
				first = false;
			}

			out_of_range := flags_value & ~flags_printed;
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
			name_index := -1;
			for info_enum.values
			{
				if it == enum_value
				{
					name_index = it_index;

					break;
				}
			}

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
		print_member_names := false;
		{
			previous_type : *Type_Info;
			highest_offset := -1;
			for info_struct.members
			{
				if it.offset_in_bytes <= highest_offset
					continue;
				highest_offset = it.offset_in_bytes;
				if previous_type && it.type != previous_type
				{
					print_member_names = true;

					break;
				}
				previous_type = it.type;
			}
		}
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
			if print_member_names
			{
				index += write_string (buffer, it.name);
				index += write_string (buffer, " : ");
			}
			index += write_any (buffer, any.value_pointer + it.offset_in_bytes, it.type, is_nested = true);
			newline = !is_nested && find_first_occurence (it.notes, "Fmt_Newline") != -1;
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
				index += write_any (buffer, ", ");
			ptr := data + i * info_array.element_type.runtime_size;
			index += write_any (buffer, ptr, info_array.element_type, is_nested = true);
		}
		index += write_string (buffer, " ]");

		return index;

	case .VARIANT;
		info_variant := cast (*Type_Info_Variant) info;
		variant := any;
		variant.type = info_variant.variant_of;

		return index + write_any (buffer, variant);

	case .TYPE;
		return index + write_type (buffer, <<cast (**Type_Info) any.value_pointer);
	
	case .ANY;
		return index + write_any (buffer, <<cast (*Any) any.value_pointer);

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

	return index + write_string (buffer, "(unhandled type)");
}

write_relative_pointer_size :: inline (buffer : *$T, size : s64) -> length : s64
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

write_type :: (buffer : *$T, info : *Type_Info) -> length : s64
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

		return i + write_type (buffer, info_pointer.pointer_to);

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
		else if flagged (info_struct.struct_flags, .UNION)
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
				index += write_string (buffer, param.name);

				if param.offset_into_constant_storage >= 0
				{
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
		index += write_type (buffer, info_array.element_type);

		return index;

	case .PROCEDURE;
		info_procedure := cast (*Type_Info_Procedure) info;
		index := 0;
		index += write_string (buffer, "(");
		for info_procedure.argument_types
		{
			if it_index != 0
				index += write_string (buffer, ", ");
			index += write_type (buffer, it);
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
				index += write_type (buffer, it);
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

	return write_string (buffer, "(unhandled type)");
}
