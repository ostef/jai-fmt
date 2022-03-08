#scope_file

jai :: #import "Compiler";

Printer :: struct
{
	write_byte :: inline (printer : *Printer, byte : u8)
	{
		if printer
		{
			str : string = ---;
			str.data  = *byte;
			str.count = 1;
			write_string (str);
		}
	}
}

#scope_export

print :: inline (fmt_str : string, args : ..Any) -> length : s64
{
	printer : Printer;

	return fmt_buffered (*printer, fmt_str, ..args);
}

println :: inline (fmt_str : string, args : ..Any) -> length : s64
{
	result := print (fmt_str, ..args);
	result += print ("\n");

	return result;
}

print_var :: (var : Code) #expand
{
	name := #run (code : Code) -> string
	{
		root, ok := jai.compiler_get_nodes (code);
		if !root || root.kind != .IDENT
			return "";
		ident := cast (*jai.Code_Ident) root;

		return ident.name;
	} (var);

	if name
		println ("% = %", name, #insert var);
	else
		println ("%", #insert var);
}
