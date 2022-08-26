#scope_module

// This was originally in a separate module, but we want Fmt to be as independant as possible.

is_substruct_of :: (info : *Type_Info, of : *Type_Info_Struct, nested := false) -> bool #must
{
	if info.type != .STRUCT
		return false;

	info_struct := cast (*Type_Info_Struct) info;
	while true
	{
		if info_struct == of
			return nested;

		if info_struct.members.count == 0
			break;

		member := *info_struct.members[0];
		if !flagged (member.flags, .USING)
			break;

		if member.type.type == .STRUCT
		{
			info_struct = cast (*Type_Info_Struct) member.type;
			nested = true;

			continue;
		}
		else if member.type.type == .POINTER
		{
			info_pointer := cast (*Type_Info_Pointer) member.type;

			return is_substruct_of (info_pointer.pointer_to, of, true);
		}

		break;
	}

	return false;
}

relative_to_absolute_ptr :: inline (ptr : *void, size : s64) -> *void #must
{
	offset : s64;
	if size ==
	{
	case 1;
		relative := <<cast (*s8) ptr;
		if !relative
			return null;
		offset = relative ^ 0x80;

	case 2;
		relative := <<cast (*s64) ptr;
		if !relative
			return null;
		offset = relative ^ 0x8000;

	case 4;
		relative := <<cast (*s32) ptr;
		if !relative
			return null;
		offset = relative ^ 0x80000000;

	case 8;
		relative := <<cast (*s64) ptr;
		if !relative
			return null;
		offset = relative ^ 0x8000000000000000;

	case;	// Invalid size!
		return null;
	}

	return ptr + offset;
}

any_to_u64 :: inline (ptr : *void, info : *Type_Info) -> value : u64 #must, ok : bool
{
	any : Any = ---;
	any.value_pointer = ptr;
	any.type = info;
	value, ok := any_to_u64 (any);

	return value, ok;
}

any_to_u64 :: inline (any : Any) -> value : u64 #must, ok : bool
{
	info := cast (*Type_Info_Integer) any.type;
	if info.type == .ENUM
		info = (cast (*Type_Info_Enum) info).internal_type;
	if info.type == .VARIANT
		info = cast (*Type_Info_Integer) (cast (*Type_Info_Variant) info).variant_of;

	if info.type ==
	{
	case .BOOL;
		value := <<cast (*bool) any.value_pointer;

		return cast (u64) value, true;

	case .INTEGER;
		value : u64 = ---;
		if info.runtime_size ==
		{
		case 1;
			if info.signed
				value = cast, no_check (u64) (<<cast (*s8) any.value_pointer);
			else
				value = cast, no_check (u64) (<<cast (*u8) any.value_pointer);

		case 2;
			if info.signed
				value = cast, no_check (u64) (<<cast (*s16) any.value_pointer);
			else
				value = cast, no_check (u64) (<<cast (*u16) any.value_pointer);

		case 4;
			if info.signed
				value = cast, no_check (u64) (<<cast (*s32) any.value_pointer);
			else
				value = cast, no_check (u64) (<<cast (*u32) any.value_pointer);

		case 8;
			if info.signed
				value = cast, no_check (u64) (<<cast (*s64) any.value_pointer);
			else
				value = cast, no_check (u64) (<<cast (*u64) any.value_pointer);
		case;	// Corrupt type info!
			return 0, false;
		}

		return value, true;
	}

	return 0, false;
}

any_to_integer :: inline (ptr : *void, info : *Type_Info) -> unsigned_value : u64 #must, negative : bool, ok : bool
{
	any : Any = ---;
	any.value_pointer = ptr;
	any.type = info;
	unsigned_value, negative, ok := any_to_integer (any);

	return unsigned_value, negative, ok;
}

any_to_integer :: inline (any : Any) -> unsigned_value : u64 #must, negative : bool, ok : bool
{
	info := cast (*Type_Info_Integer) any.type;
	if info.type == .ENUM
		info = (cast (*Type_Info_Enum) info).internal_type;
	if info.type == .VARIANT
		info = cast (*Type_Info_Integer) (cast (*Type_Info_Variant) info).variant_of;

	if info.type != .INTEGER
		return 0, false, false;

	value : u64 = ---;
	negative : bool = ---;
	if info.signed
	{
		signed_value, ok := any_to_s64 (any);
		if !ok then return 0, false, false;

		if signed_value < 0
		{
			value = cast (u64) -signed_value;
			negative = true;
		}
		else
		{
			value = cast (u64) signed_value;
			negative = false;
		}
	}
	else
	{
		unsigned_value, ok := any_to_u64 (any);
		if !ok then return 0, false, false;

		value = unsigned_value;
		negative = false;
	}
	
	return value, negative, true;
}

any_to_s64 :: inline (ptr : *void, info : *Type_Info) -> value : s64 #must, ok : bool
{
	any : Any = ---;
	any.value_pointer = ptr;
	any.type = info;
	value, ok := any_to_s64 (any);

	return value, ok;
}

any_to_s64 :: inline (any : Any) -> value : s64 #must, ok : bool
{
	info := cast (*Type_Info_Integer) any.type;
	if info.type == .ENUM
		info = (cast (*Type_Info_Enum) info).internal_type;
	if info.type == .VARIANT
		info = cast (*Type_Info_Integer) (cast (*Type_Info_Variant) info).variant_of;

	if info.type ==
	{
	case .BOOL;
		value := <<cast (*bool) any.value_pointer;

		return cast (s64) value, true;
	case .INTEGER;
		value : s64 = ---;
		if info.runtime_size ==
		{
		case 1;
			if info.signed
				value = cast, no_check (s64) (<<cast (*s8) any.value_pointer);
			else
				value = cast, no_check (s64) (<<cast (*u8) any.value_pointer);

		case 2;
			if info.signed
				value = cast, no_check (s64) (<<cast (*s16) any.value_pointer);
			else
				value = cast, no_check (s64) (<<cast (*u16) any.value_pointer);

		case 4;
			if info.signed
				value = cast, no_check (s64) (<<cast (*s32) any.value_pointer);
			else
				value = cast, no_check (s64) (<<cast (*u32) any.value_pointer);

		case 8;
			if info.signed
				value = cast, no_check (s64) (<<cast (*s64) any.value_pointer);
			else
				value = cast, no_check (s64) (<<cast (*u64) any.value_pointer);

		case;	// Corrupted type info!
			return 0, false;
		}

		return value, true;
	}
	return 0, false;
}

any_to_f32 :: inline (ptr : *void, info : *Type_Info) -> value : f32 #must, ok : bool
{
	any : Any = ---;
	any.value_pointer = ptr;
	any.type = info;
	value, ok := any_to_f32 (any);

	return value, ok;
}

any_to_f32 :: inline (any : Any) -> value : f32 #must, ok : bool
{
	info := cast (*Type_Info_Float) any.type;
	if info.type == .VARIANT
		info = cast (*Type_Info_Float) (cast (*Type_Info_Variant) info).variant_of;

	if info.type ==
	{
	case .BOOL; #through;
	case .INTEGER;
		return cast (f32) any_to_s64 (any), true;

	case .FLOAT;
		value : f32 = ---;
		if info.runtime_size ==
		{
		case 4;
			value = <<cast (*f32) any.value_pointer;

		case 8;
			value = cast (f32) (<<cast (*f64) any.value_pointer);

		case;	// Corrupted type info!
			return 0, false;
		}
		return value, true;
	}

	return 0.0, false;
}

any_to_f64 :: inline (ptr : *void, info : *Type_Info) -> value : f64 #must, ok : bool
{
	any : Any = ---;
	any.value_pointer = ptr;
	any.type = info;
	value, ok := any_to_f64 (any);

	return value, ok;
}

any_to_f64 :: inline (any : Any) -> value : f64 #must, ok : bool
{
	info := cast (*Type_Info_Float) any.type;
	if info.type == .VARIANT
		info = cast (*Type_Info_Float) (cast (*Type_Info_Variant) info).variant_of;
	if info.type ==
	{
	case .BOOL; #through;
	case .INTEGER;
		return cast (f64) any_to_s64 (any), true;

	case .FLOAT;
		value : f64 = ---;
		if info.runtime_size ==
		{
		case 4;
			value = cast (f64) (<<cast (*f32) any.value_pointer);

		case 8;
			value = <<cast (*f64) any.value_pointer;

		case;	// Corrupted type info!
			return 0, false;
		}

		return value, true;
	}

	return 0.0, false;
}

any_to_bool :: inline (ptr : *void, info : *Type_Info) -> value : bool #must, ok : bool
{
	any : Any = ---;
	any.value_pointer = ptr;
	any.type = info;
	value, ok := any_to_bool (any);

	return value, ok;
}

any_to_bool :: inline (any : Any) -> value : bool #must, ok : bool
{
	value, ok := any_to_s64 (any);

	return value != 0, ok;
}

any_to_string :: inline (ptr : *void, info : *Type_Info) -> value : string #must, ok : bool
{
	any : Any = ---;
	any.value_pointer = ptr;
	any.type = info;
	value, ok := any_to_string (any);

	return value, ok;
}

any_to_string :: inline (any : Any) -> value : string #must, ok : bool
{
	info := cast (*Type_Info_String) any.type;
	if info.type == .VARIANT
		info = cast (*Type_Info_String) (cast (*Type_Info_Variant) info).variant_of;
	if info.type != .STRING
		return "", false;

	value : string = ---;
	if info.relative_pointer_size ==
	{
	case 0;
		value = <<cast (*string) any.value_pointer;

	case 1;
		value.count = cast (s64) (<<cast (*s8) any.value_pointer);
		value.data  = relative_to_absolute_ptr (any.value_pointer + info.relative_pointer_size, info.relative_pointer_size);

	case 2;
		value.count = cast (s64) (<<cast (*s16) any.value_pointer);
		value.data  = relative_to_absolute_ptr (any.value_pointer + info.relative_pointer_size, info.relative_pointer_size);

	case 4;
		value.count = cast (s64) (<<cast (*s32) any.value_pointer);
		value.data  = relative_to_absolute_ptr (any.value_pointer + info.relative_pointer_size, info.relative_pointer_size);

	case 8;
		value.count = <<cast (*s64) any.value_pointer;
		value.data  = relative_to_absolute_ptr (any.value_pointer + info.relative_pointer_size, info.relative_pointer_size);

	case;	// Corrupted type info!
		return "", false;
	}

	return value, true;
}

any_to_ptr :: inline (ptr : *void, info : *Type_Info) -> value : *void #must, ok : bool
{
	any : Any = ---;
	any.value_pointer = ptr;
	any.type = info;
	value, ok := any_to_ptr (any);

	return value, ok;
}

any_to_ptr :: inline (any : Any) -> value : *void #must, ok : bool
{
	info := cast (*Type_Info_Pointer) any.type;
	if info.type == .VARIANT
		info = cast (*Type_Info_Pointer) (cast (*Type_Info_Variant) info).variant_of;
	if info.type != .POINTER
		return null, false;

	value : *void = ---;
	if info.relative_pointer_size ==
	{
	case 0;
		value = <<cast (**void) any.value_pointer;

	case 1; #through;
	case 2; #through;
	case 4; #through;
	case 8;
		value = relative_to_absolute_ptr (any.value_pointer, info.relative_pointer_size);

	case;	// Corrupted type info!
		return null, false;
	}

	return value, true;
}

any_get_array_count :: inline (ptr : *void, info : *Type_Info) -> s64, ok : bool
{
	any : Any = ---;
	any.value_pointer = ptr;
	any.type = info;
	value, ok := any_get_array_count (any);

	return value, ok;
}

any_get_array_count :: inline (any : Any) -> s64, ok : bool
{
	info := cast (*Type_Info_Array) any.type;
	if info.type == .VARIANT
		info = cast (*Type_Info_Array) (cast (*Type_Info_Variant) info).variant_of;
	if info.type != .ARRAY
		return 0, false;

	if #complete info.array_type ==
	{
	case .FIXED;
		return info.array_count, true;

	case .VIEW; #through;
	case .RESIZABLE;
		if info.relative_pointer_size ==
		{
		case 1;
			return cast (s64) (<<cast (*s8) any.value_pointer), true;

		case 2;
			return cast (s64) (<<cast (*s16) any.value_pointer), true;

		case 4;
			return cast (s64) (<<cast (*s32) any.value_pointer), true;

		case 8; #through;
		case 0;
			return <<cast (*s64) any.value_pointer, true;
		}
	}

	return 0, false;
}

any_get_array_data :: inline (ptr : *void, info : *Type_Info) -> *void, ok : bool
{
	any : Any = ---;
	any.value_pointer = ptr;
	any.type = info;
	value, ok := any_get_array_data (any);

	return value, ok;
}

any_get_array_data :: inline (any : Any) -> *void, ok : bool
{
	info := cast (*Type_Info_Array) any.type;
	if info.type == .VARIANT
		info = cast (*Type_Info_Array) (cast (*Type_Info_Variant) info).variant_of;
	if info.type != .ARRAY
		return null, false;

	if #complete info.array_type ==
	{
	case .FIXED;
		return any.value_pointer, true;

	case .VIEW; #through;
	case .RESIZABLE;
		if info.relative_pointer_size ==
		{
		case 0;
			return <<cast (**void) (any.value_pointer + size_of (s64)), true;

		case 1; #through;
		case 2; #through;
		case 4; #through;
		case 8;
			return relative_to_absolute_ptr (any.value_pointer + info.relative_pointer_size, info.relative_pointer_size), true;
		}
	}

	return null, false;
}
