# Fmt

String formatting module written in Jai.

# Dependencies
Fmt depends on my port of [Ryū: Fast float to string conversion](https://github.com/ostef/jai-ryu). The to_shortest and string to float conversions are not imported.

# Usage
Fmt supports arbitrary arguments by using `%` to specify an argument slot.
When using `%`, the type of the result will be retrieved from the type information of the argument, and the `write_any` function will be used.  
It also supports more complex formatting options using curly braces.
This is the format of the formatting options:  
`{[arg_index][:[flags][width][.precision]specifier]}`  
If `:` is not specified, type information is used to decide what to print. The argument index is optional, meaning an empty format `{}` is the same as `%`.

## Valid flags are:
* <: right justify. Ignored if width is not set. This is the default,
* \>: left justify. Ignored if width is not set,
* +: print a '+' in front of positive signed integer values,
* ' ': align signed integers, printing a ' ' in front of positive values,
* 0: pad integer and float values with '0' instead of ' ', ignored if > is set,
* #: print the base prefix for integer values, '0x' or '0X' for hex, '0b' for binary,
* \\: print escape sequences for non printable characters,
* ~: for fixed and exponent form floating point numbers, leave trailing zeroes after decimal point. By default, trailing zeroes are trimmed,
* $: for matrix types, print on one line.

## Valid width are:
Positive integer values, or a * character to retrieve the width from the next argument that is provided.

## Valid precisions are:
Positive or negative integer values, or a * character to retrieve the precision from the next argument that is provided.

## Valid specifiers are:
* `c`: print Unicode codepoint,
* `s`: print UTF-8 string,
* `B`: print boolean value, anything non-zero is treated as true,
* `b`: print 64-bit unsigned integer in binary,
* `i`: print 64-bit signed or unsigned integer in decimal,
* `d`: same as above,
* `x`: print 64-bit unsigned integer in lowercase hexadecimal,
* `X`: print 64-bit unsigned integer in uppercase hexadecimal,
* `p`: print pointer as hexadecimal unsigned 64-bit integer, same as %#x,
* `f`: print 64-bit floating point number in fixed form (uses Ryu d2fixed conversion),
* `e`: print 64-bit floating point number in lowercase exponent form (uses Ryu d2exp conversion),
* `E`: print 64-bit floating point number in uppercase exponent form (uses Ryu d2exp conversion),
* `g`: print the shortest representation of a 64-bit floating point number between fixed and exponent lowercase form,
* `G`: print the shortest representation of a 64-bit floating point number between fixed and exponent uppercase form,
* `a`: print 64-bit or 32-bit floating point number in sign + mantissa + exponent lowercase hexadecimal form,
* `A`: print 64-bit or 32-bit floating point number in sign + mantissa + exponent uppercase hexadecimal form,
* `v`: print a vector type. Whether a type is a valid vector type is determined by looking at the type information at runtime.
Formatting options get passed to the values of the vector.
Valid vector types are integers, floats, fixed size arrays of integers and floats, and structs that have only integers or floats array or non array members. Elements must be contiguous and of the same size (not yet checked for, if this is not true bad things will happen).
* `m`: print a matrix type. Unless specified otherwise, the NxM matrix is printed on N lines. Whether a type is a valid vector type is determined by looking at the type information at runtime.
Formatting options get passed to the values of the matrix.
Valid matrix types are integers, floats, fixed size arrays of valid vector types, and structs that have only valid vector types members. Elements must be contiguous and of the same size (not yet checked for, if this is not true bad things will happen).

## Error cases:
* If the format is not closed, '(unclosed format)' is printed,
* If the specifier is invalid, '(invalid specifier)' is printed,
* If the provided argument index is not a valid unsigned integer, '(invalid argument index)' is printed,
* If the provided argument index is outside the range of provided arguments, or there are not enough arguments, '(no argument provided)' is printed,
* If the argument cannot be converted to the specifier type, the default value is printed (0 for integer and float types, empty string for strings),
* For `v` and `m` specifiers, if the type of the argument is not a valid vector or matrix type, '(not a vector type)' or '(not a matrix type)' is printed. This is not consistent with other specifiers, so this might change in the future.

Fmt accepts a polymorphic buffer as argument.
This makes it possible, for example, to directly print the characters to the desired output instead of allocating a temporary buffer and writing to it (see `print.jai`).
This also allows the user to use a dynamically growing buffer instead of computing the final length of the string by calling `format_buffered` with a null buffer and then allocating a buffer of sufficient size like in the `format` procedure.
The buffer type `T` has to be a struct that have at least one procedure inside with the following name and signature:
```jai
	write_byte :: (*T, u8)
```
The rules of polymorphism allow `write_byte` to not be constant (not tested).

These are the main procedures:
```jai
fmt_buffered :: format_buffered;
format_buffered :: inline (buffer : *$T, fmt_str : string, args : ..Any) -> length : s64
```
```jai
fmt :: format;
format :: inline (allocator : Allocator, fmt_str : string, args : ..Any) -> string #must
```
```jai
print :: inline (fmt_str : string, args : ..Any) -> length : s64
```
```jai
println :: inline (fmt_str : string, args : ..Any) -> length : s64
```
```jai
print :: inline (value : $T) -> length : s64
```
```jai
println :: inline (value : $T) -> length : s64
```
