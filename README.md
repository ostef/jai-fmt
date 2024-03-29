# Fmt

String formatting module written in Jai.

# Dependencies
Fmt depends on my port of [Ryū: Fast float to string conversion](https://github.com/ostef/jai-ryu). The to_shortest and string to float conversions are not imported.  
This dependency can be removed via the IMPORT_RYU program parameter.

# Usage
Formatting arguments follow this pattern:  
`{[arg_index][:[flags][width][.precision][specifier]]}`  
If no specifier is present, the type information of the value is used to decide what to print. `%` can be used instead of empty curly braces.
For aggregate types (arrays, structs), the formatting options are passed to the nested members all the way down, unless the struct member has a Fmt note on it, specifying the formatting string.  

## Flags:
* `>`: right justify. Ignored if width is not set. This is the default, and the flag has a value of 0; this exists just for consistency with `<`,
* `<`: left justify. Ignored if width is not set,
* `+`: print a '+' in front of positive signed integer and float values,
* `' '`: align signed integers and floats, printing a ' ' in front of positive values,
* `_`: same as above, for use where you can't have spaces like in notes,
* `0`: pad integer and float values with '0' instead of ' ', ignored if `<` is set,
* `#`: print the base prefix for integer values, '0x' or '0X' for hex, '0b' for binary,
* `~`: for fixed and exponent form floating point numbers, leave trailing zeroes after decimal point. By default, trailing zeroes are trimmed,
* `\\`: print escape sequences for non printable characters,
* `'`: same as `\\`, but also print surrounding single quotes for characters, double quotes for strings,
* `$`: print on one line, for strings and characters, this is the same as the `\\` flag, ignoring `@Fmt_New_Line` notes if found,
* `,`: print on multiple lines, for arrays and structs types, if an `@Fmt_Same_Line` note is found, don't print a newline character,
* `!`: print struct member names

## Width:
Valid width values are positive integer values, or a * character to retrieve the width from the next argument that is provided.

## Precision:
Valid precision values are positive or negative integer values, or a * character to retrieve the precision from the next argument that is provided.

## Specifiers:
* `c`: print Unicode codepoint,
* `s`: print UTF-8 string,
* `B`: print boolean value, anything non-zero is treated as true,
* `b`: print 64-bit unsigned integer in binary,
* `i`: print 64-bit signed or unsigned integer in decimal,
* `d`: same as above,
* `x`: print 64-bit unsigned integer in lowercase hexadecimal,
* `X`: print 64-bit unsigned integer in uppercase hexadecimal,
* `p`: print pointers as lowercase hexadecimal 64-bit unsigned integer, print 'null' if the value is null,
* `P`: print pointers as uppercase hexadecimal 64-bit unsigned integer, print 'null' if the value is null,
* `f`: print 64-bit floating point number in fixed form (uses Ryu d2fixed conversion, if imported),
* `e`: print 64-bit floating point number in lowercase exponent form (uses Ryu d2exp conversion, if imported),
* `E`: print 64-bit floating point number in uppercase exponent form (uses Ryu d2exp conversion, if imported),
* `g`: print the shortest representation of a 64-bit floating point number between fixed and exponent lowercase form,
* `G`: print the shortest representation of a 64-bit floating point number between fixed and exponent uppercase form,
* `t`: print a `Type` or type information as a type. For other values, print the value's type.

## Error cases:
* If the format is not closed, '(unclosed format)' is printed,
* If the specifier is invalid, '(invalid specifier)' is printed,
* If the provided argument index is not a valid unsigned integer, '(invalid argument index)' is printed,
* If there are not enough arguments, '(no argument provided)' is printed,
* For floating point specifiers, if Ryu is not imported, '(Ryu not imported)' is printed,
* For most specifiers, if the argument cannot be converted to the correct type, the default value is printed (0 for integer and float types, empty string for strings).

These are the main procedures:
```jai
format :: inline (buffer : *$T, fmt_str : string, args : ..Any) -> length : s64
```
```jai
format :: inline (fmt_str : string, args : ..Any) -> string #must
```
```jai
format :: inline (allocator : Allocator, fmt_str : string, args : ..Any) -> string #must
```
```jai
print :: inline (fmt_str : string, args : ..Any) -> length : s64
```
```jai
println :: inline (fmt_str : string, args : ..Any) -> length : s64
```
```jai
print :: inline (val : Any) -> length : s64
```
```jai
println :: inline (val : Any) -> length : s64
```

The return value of these functions is the number of UTF-8 units (bytes) needed for the final string, not the actual number of bytes that have been written.

Calling `format` with a null buffer is valid, and it effectively computes the final length of the resulting UTF-8 string. The type `T` cannot be void though, so if you want to pass null, cast it to a valid buffer type pointer, like `Fmt_Buffer`.

The procedures that write to a buffer are at export scope, so you can use them without having to call `format`. Same for parsing a format string, and writing an argument with field width handling (`write_arg`).

# Extensibility
`format` accepts a polymorphic buffer as argument.
This makes it possible, for example, to directly print the characters to the desired output instead of allocating a temporary buffer and writing to it (see printing functions in `print.jai`).
This also allows the caller to use a dynamically growing buffer instead of computing the final length of the string by calling `format` with a null buffer and then allocating a buffer of sufficient size like in the non-buffered `format` procedure.
The buffer type `T` has to be a struct that have at least one procedure inside with the following name and signature:
```jai
write_byte :: (buffer : *T, byte : u8)
```
The rules of polymorphism allow `write_byte` to not be constant.  
It is valid to call `write_byte` with a null `buffer`, in which case calling `write_byte` should be a no-op.  
A byte value of 0 indicates that the end of the formatting have been reached. This means that if your buffer is a flushing buffer, it should flush when it receives 0. The 0 should not be written to the buffer.

# Additional formatting options
* `@Fmt_Ignore` note on struct members: do not print the struct member if this note is found,  
* `@Fmt_New_Line` note on struct members: if not nested, a newline will be printed after the member on which this note is on is printed.
An example of printing a nested struct member might be when printing an array of a struct type. When this is the case, `@Fmt_New_Line` is ignored.
* `@Fmt_Same_Line` note on struct members: when the multi line `,` flag is used, don't print a newline after the member.
* `@Fmt(...)` note on struct members: instead of passing the formatting options to the member, the formatting string inside the parentheses is used to format the struct member.  
The formatting string in this case cannot have an argument index and as such should not contain `:` to separate the argument index with the formatting options. It also cannot have `*` instead of numbers for width and precision. If the parentheses are not provided, the note is ignored.  
* `@Fmt_Follow_Ptr` note on struct members: if the member is of pointer type, follow the pointer and print the pointed value if the pointer is non-null,  
* `@Fmt_Tag` note on struct member: tells Fmt that the member is a tag used to discriminate which union member is valid (see `@Fmt_Tagged_Union` note).  
Fot this note to work, the member has to be of enum (non-flags) type, with each enum member's value being the index of the corresponding member in the union,  
* `@Fmt_Tagged_Union` note on struct member: tells Fmt that the member is a union which value is discriminated by the value of the last member which had a `@Fmt_Tag` note.

## Tagged Union Example
```jai
Tagged_Union :: struct
{
	Kind :: enum
	{
		INT    :: 0;
		FLOAT  :: 1;
		STRING :: 2;
	}

	kind : Kind;	@Fmt_Tag
	// This must be a declaration for notes to work
	// (i.e. an identifier followed by a colon)
	using val : union
	{
		as_int : int;		// Member of index 0, which is the value of Kind.INT
		as_float : float;	// Member of index 1, which is the value of Kind.FLOAT
		as_string : string;	// Member of index 2, which is the value of Kind.STRING
	};	@Fmt_Tagged_Union
}
```
