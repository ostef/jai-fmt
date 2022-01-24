#scope_file

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

print :: inline (value : $T) -> length : s64
{
	printer : Printer;

	return fmt_buffered (*printer, "%", value);
}

println :: inline (value : $T) -> length : s64
{
	printer : Printer;

	return fmt_buffered (*printer, "%\n", value);
}
