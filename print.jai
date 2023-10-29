#scope_file

#assert PRINTER_BUFFER_SIZE > 0 "Invalid PRINTER_BUFFER_SIZE. Must be positive and non zero.";

Printer :: struct
{
	buffer : [PRINTER_BUFFER_SIZE]u8;
	count  : s64;
	to_stderr : bool;

	write_byte :: inline (using printer : *Printer, byte : u8)
	{
		if printer
		{
			// Flush if we receive a 0, or if we filled the buffer
			if byte == 0 || count == PRINTER_BUFFER_SIZE
			{
				str : string = ---;
				str.data  = buffer.data;
				str.count = count;
				write_string (str, to_standard_error = to_stderr);
				count = 0;
			}

			if byte
			{
				buffer[count] = byte;
				count += 1;
			}
		}
	}
}

#scope_export

print :: inline (fmt_str : string, args : ..Any, to_stderr := false) -> length : s64
{
	printer : Printer;
	printer.to_stderr = to_stderr;

	return format (*printer, fmt_str, ..args);
}

println :: inline (fmt_str : string, args : ..Any, to_stderr := false) -> length : s64
{
	result := print (fmt_str, ..args, to_stderr = to_stderr);
	result += print ("\n", to_stderr = to_stderr);

	return result;
}

print :: inline (val : Any, to_stderr := false) -> length : s64
{
	return print ("%", val, to_stderr = to_stderr);
}

println :: inline (val : Any, to_stderr := false) -> length : s64
{
	return println ("%", val, to_stderr = to_stderr);
}
