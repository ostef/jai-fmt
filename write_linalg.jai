write_vector :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
{
	is_vector, n, element_info := get_vector_info (arg.value.type);
	if !is_vector
		return write_string (buffer, "(not a vector type)");

	index := 0;
	index += write_string (buffer, "( ");
	for i : 0..n - 1
	{
		current := arg;
		current.write_func = #bake_constants write_float_shortest (T = T);
		current.value.value_pointer = arg.value.value_pointer + i * element_info.runtime_size;
		current.value.type = element_info;

		index += write_arg (buffer, current);
		if i != n - 1
			index += write_string (buffer, ", ");
	}
	index += write_string (buffer, " )");

	return index;
}

write_matrix :: inline (buffer : *$T, arg : Fmt_Arg (T)) -> length : s64
{
	is_matrix, m, n, element_info := get_matrix_info (arg.value.type);
	if !is_matrix
		return write_string (buffer, "(not a matrix type)");

	index := 0;
	index += write_string (buffer, "( ");
	for i : 0..m - 1
	{
		for j : 0..n - 1
		{
			current := arg;
			current.write_func = #bake_constants write_float_shortest (T = T);
			current.value.value_pointer = arg.value.value_pointer + i * n * element_info.runtime_size + j * element_info.runtime_size;
			current.value.type = element_info;

			index += write_arg (buffer, current);
			if j != n - 1
				index += write_string (buffer, ", ");
		}
		if i != m - 1
		{
			if !flagged (arg.flags, .SINGLE_LINE)
				index += write_string (buffer, ",\n  ");
			else
				index += write_string (buffer, ", ");
		}
	}
	index += write_string (buffer, " )");

	return index;
}

// @Speed (stefan): These procedures below are always called when we print matrices or vectors.
// In a real codebase, you usually have a handful of vector and matrix types, so it might be
// a good idea to cache the type infos that we computed were vector/matrix types into an array,
// so we can look it up instead of calling these. If there is a cache miss, then you either
// called write_vector/matrix with a new type that is in fact a correct type for the first time,
// or you called it with the wrong type. The first scenario only happens once per type, and the
// second we don't care that much if it is slow, because it is an error by the caller (or our
// functions can't detect that the type is in fact a vector or matrix).

get_vector_info :: (info : *Type_Info) -> is_vector : bool, n : s64, element_info : *Type_Info
{
	if info.type ==
	{
	case .INTEGER; #through;
	case .FLOAT;
		return true, 1, info;
	case .ARRAY;
		array_info := cast (*Type_Info_Array) info;
		if array_info.array_type != .FIXED
			return false, 0, null;
		if array_info.element_type.type != .INTEGER
			&& array_info.element_type.type != .FLOAT
			return false, 0, null;
		return true, array_info.array_count, array_info.element_type;

	case .STRUCT;
		struct_info := cast (*Type_Info_Struct) info;
		element_info : *Type_Info;
		for struct_info.members
		{
			member_is_vector, n, member_elem_info := get_vector_info (it.type);
			if !member_is_vector
				return false, 0, null;
			if element_info && element_info != member_elem_info
				return false, 0, null;
			element_info = member_elem_info;
		}
		if !element_info
			return false, 0, null;
		return true, struct_info.runtime_size / element_info.runtime_size, element_info;
	}

	return false, 0, null;
}

get_matrix_info :: (info : *Type_Info) -> is_matrix : bool, m : s64, n : s64, element_info : *Type_Info
{
	if info.type ==
	{
	case .INTEGER; #through;
	case .FLOAT;
		return true, 1, 1, info;
	case .ARRAY;
		array_info := cast (*Type_Info_Array) info;
		if array_info.array_type != .FIXED
			return false, 0, 0, null;
		is_vector, n, element_info := get_vector_info (array_info.element_type);
		if !is_vector
			return false, 0, 0, null;
		return true, array_info.array_count, n, element_info;

	case .STRUCT;
		max_n : s64;
		struct_info := cast (*Type_Info_Struct) info;
		element_info : *Type_Info;
		for struct_info.members
		{
			member_is_matrix, member_m, member_n, member_elem_info := get_matrix_info (it.type);
			if !member_is_matrix
				return false, 0, 0, null;
			if element_info && element_info != member_elem_info
				return false, 0, 0, null;
			element_info = member_elem_info;
			if member_n > max_n then max_n = member_n;
		}
		if !element_info
			return false, 0, 0, null;
		total_elem_count := struct_info.runtime_size / element_info.runtime_size;
		return true, total_elem_count / max_n, max_n, element_info;
	}

	return false, 0, 0, null;
}
