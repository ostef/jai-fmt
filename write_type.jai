write_type :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	info := arg.value.type;
	if info.type == .TYPE || info == type_info (*Type_Info)
	|| info.type == .POINTER && is_substruct_of ((cast (*Type_Info_Pointer) info).pointer_to, type_info (Type_Info))
		return write_type (buffer, <<cast (**Type_Info) arg.value.value_pointer, flagged (arg.flags, .PRINT_MEMBER_NAMES));

	return write_type (buffer, arg.value.type, flagged (arg.flags, .PRINT_MEMBER_NAMES));
}

write_type :: (buffer : *$T, info : *Type_Info, print_member_names := false) -> length : s64
#modify { reject_non_buffer_types (T); }
{
	if !info
		return write_string (buffer, "null");

	if #complete info.type ==
	{
	case .VOID;
		return write_string (buffer, "void");

	case .STRING;
		return write_string (buffer, "string");

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

					ptr := info_struct.constant_storage.data + param.offset_into_constant_storage;
					index += write_any (buffer, ptr, param.type, true);
				}
			}

			index += write_string (buffer, ")");
		}

		return index;

	case .VARIANT;
		return write_string (buffer, (cast (*Type_Info_Variant) info).name);

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
