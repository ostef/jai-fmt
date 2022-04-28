Basic :: #import "Basic";
#import "Fmt";
#import "stb_sprintf";

PROFILE_COUNT :: 10000;

profile : bool;
total_tests : s64;

test_print :: (expected : string, fmt_str : string, args : ..Any, location := #caller_location) -> ko : s64
{
	total_tests += 1;
	str := fmt (context.allocator, fmt_str, ..args);
	if str != expected
	{
		println ("[Ln %]: Expected '%', got '%'.", location.line_number, expected, str);
		println ("fmt_str was: '%'.", fmt_str);
		println ("[Ln %]: KO.", location.line_number);

		return 1;
	}
	println ("[Ln %]: OK.", location.line_number);
	if profile
	{
		buff : [1024]u8 = ---;
		total_time : f64;
		for 0..PROFILE_COUNT - 1
		{
			fmt_buff := make_fmt_buffer (buff);
			start := Basic.get_time ();
			len := fmt (*fmt_buff, fmt_str, ..args);
			end := Basic.get_time ();
			total_time += (end - start) * 1000;
		}
		println ("[Ln %]: Average time: % ms. fmt_str was '%'.", location.line_number, total_time / PROFILE_COUNT, fmt_str);
	}

	return 0;
}

test_string :: () -> ko : s64
{
	println ("Test :s");
	ko := 0;
	ko += test_print ("null", "{:s}", "");
	ko += test_print ("      null", "{:10s}", "");
	ko += test_print ("null", "{:010s}", "");
	ko += test_print ("      null", "{:10s}", "");
	ko += test_print ("nul", "{:.3s}", "");
	ko += test_print ("Hello\\nSailor", "{:\\s}", "Hello\nSailor");
	ko += test_print ("Hello", "{:\\.5s}", "Hello\nSailor");
	ko += test_print ("   Hello Sailor", "{:15s}", "Hello Sailor");
	ko += test_print ("          Hello", "{:15.5s}", "Hello Sailor");
	ko += test_print ("          Hello Sailor", "{:15.5s} Sailor", "Hello");
	ko += test_print (" \"Hello Sailor\"", "{:'15s}", "Hello Sailor");
	ko += test_print ("a", "{:c}", #char "a");
	ko += test_print ("'a'", "{:'c}", #char "a");
	ko += test_print ("              a", "{:15c}", #char "a");
	ko += test_print ("            'a'", "{:'15c}", #char "a");
	ko += test_print ("é", "{:c}", #char "é");
	ko += test_print ("⺠", "{:c}", #char "⺠");
	ko += test_print ("'⺠'", "{:'c}", #char "⺠");
	println ("% KOs.", ko);
	println ("============================");

	return ko;
}

test_decimal :: () -> ko : s64
{
	print ("Test :i");
	ko := 0;
	ko += test_print ("0", "{:i}", 0);
	ko += test_print ("10", "{:i}", 10);
	ko += test_print ("-10", "{:i}", -10);
	ko += test_print ("-9223372036854775808", "{:i}", S64_MIN);
	ko += test_print ("9223372036854775807", "{:i}", S64_MAX);
	ko += test_print ("18446744073709551615", "{:i}", U64_MAX);
	ko += test_print ("-000000010", "{:010i}", -10);
	ko += test_print ("00010", "{:010.5i}", 10);
	ko += test_print ("-00010", "{:010.5i}", -10);
	ko += test_print ("-00010", "{:010.*i}", 5, -10);
	ko += test_print ("-00010", "{:0*.*i}", 10, 5, -10);
	ko += test_print ("-00010", "{:03.5i}", -10);
	ko += test_print ("42", "{:<i}", 42);
	ko += test_print ("42   ", "{:<5i}", 42);
	ko += test_print ("42        ", "{:<*i}", 10, 42);
	ko += test_print ("42   ", "{:<05i}", 42);
	ko += test_print ("42        ", "{:<0*i}", 10, 42);
	ko += test_print ("42", "{:.0i}", 42);
	ko += test_print ("", "{:.0i}", 0);
	ko += test_print ("42", "{:.i}", 42);
	ko += test_print ("", "{:.i}", 0);
	ko += test_print ("+10", "{:+i}", 10);
	ko += test_print (" 10", "{: i}", 10);
	ko += test_print ("-10", "{:+i}", -10);
	ko += test_print ("10", "{:i}", Test_Enum.C);
	println ("% KOs.", ko);
	println ("============================");

	return ko;
}

test_binary :: () -> ko : s64
{
	println ("Test :b");
	ko := 0;
	ko += test_print ("0", "{:b}", 0);
	ko += test_print ("101010", "{:b}", 0b101010);
	ko += test_print ("1111111111111111111111111111111111111111111111111111111111111111", "{:b}", 0xffffffffffffffff);
	ko += test_print ("0b0", "{:#b}", 0);
	ko += test_print ("", "{:.0b}", 0);
	ko += test_print ("", "{:.b}", 0);
	ko += test_print ("0b", "{:#.b}", 0);
	ko += test_print ("0b00011001", "{:#.8b}", 0b11001);
	ko += test_print ("0b011001", "{:#08b}", 0b11001);
	ko += test_print ("00011001", "{:08b}", 0b11001);
	ko += test_print ("11001           ", "{:<16b}", 0b11001);
	ko += test_print ("11001", "{:+b}", 0b11001);
	ko += test_print ("11001", "{: b}", 0b11001);
	ko += test_print ("0b00011001", "{:#10.8b}", 0b11001);
	ko += test_print ("      0b00011001", "{:#16.8b}", 0b11001);
	ko += test_print ("0b00011001", "{:#016.8b}", 0b11001);
	println ("% KOs.", ko);
	println ("============================");

	return ko;
}

test_hexadecimal :: () -> ko : s64
{
	println ("Test :x");
	ko := 0;
	ko += test_print ("0", "{:x}", 0);
	ko += test_print ("badbeef", "{:x}", 0xbadbeef);
	ko += test_print ("ffffffffffffffff", "{:x}", 0xffffffffffffffff);
	ko += test_print ("0x0", "{:#x}", 0);
	ko += test_print ("", "{:.0x}", 0);
	ko += test_print ("", "{:.x}", 0);
	ko += test_print ("0x", "{:#.x}", 0);
	ko += test_print ("0x0badbeef", "{:#.8x}", 0xbadbeef);
	ko += test_print ("0xbadbeef", "{:#08x}", 0xbadbeef);
	ko += test_print ("0badbeef", "{:08x}", 0xbadbeef);
	ko += test_print ("badbeef         ", "{:<16x}", 0xbadbeef);
	ko += test_print ("badbeef", "{:+x}", 0xbadbeef);
	ko += test_print ("badbeef", "{: x}", 0xbadbeef);
	ko += test_print ("0x0badbeef", "{:#10.8x}", 0xbadbeef);
	ko += test_print ("      0x0badbeef", "{:#16.8x}", 0xbadbeef);
	ko += test_print ("0x0badbeef", "{:#016.8x}", 0xbadbeef);
	ko += test_print ("1", "{:x}", Test_Flags.A);
	ko += test_print ("null", "{:p}", 0);
	ko += test_print ("0x1234", "{:p}", cast (*void) 0x1234);
	println ("% KOs.", ko);
	println ("============================");

	return ko;
}

test_float_fixed :: () -> s64
{
	println ("Test :f");
	ko := 0;
	ko += test_print ("1.234", "{:f}", 1.234);
	ko += test_print ("1.234", "{:.3f}", 1.234);
	ko += test_print ("1", "{:.f}", 1.234);
	ko += test_print ("10", "{:f}", 9.9999999);
	ko += test_print ("-10", "{:f}", -9.9999999);
	ko += test_print ("10", "{:.f}", 9.9999999);
	ko += test_print ("10", "{:~.f}", 9.9999999);
	ko += test_print ("1000000000000", "{:.f}", 1000000000000);
	ko += test_print ("0000010", "{:07.3f}", 9.9999999);
	ko += test_print ("     10", "{:7.3f}", 9.9999999);
	ko += test_print ("NaN", "{:f}", F32_NAN);
	ko += test_print ("   NaN", "{:6f}", F32_NAN);
	ko += test_print ("Inf", "{:f}", F32_POSITIVE_INFINITY);
	ko += test_print ("+Inf", "{:+f}", F32_POSITIVE_INFINITY);
	ko += test_print ("    +Inf", "{:+8f}", F32_POSITIVE_INFINITY);
	ko += test_print ("+Inf", "{:+02f}", F32_POSITIVE_INFINITY);
	ko += test_print ("-Inf", "{:f}", F32_NEGATIVE_INFINITY);
	ko += test_print ("NaN", "{:f}", F64_NAN);
	ko += test_print ("Inf", "{:f}", F64_POSITIVE_INFINITY);
	ko += test_print ("-Inf", "{:f}", F64_NEGATIVE_INFINITY);
	ko += test_print ("   NaN", "{:6f}", F32_NAN);
	ko += test_print ("   NaN", "{:06f}", F32_NAN);
	println ("% KOs.", ko);
	println ("============================");

	return ko;
}

test_float_exp :: () -> s64
{
	println ("Test :e");
	ko := 0;
	ko += test_print ("0e+00", "{:e}", 0.0);
	ko += test_print ("-0e+00", "{:e}", -0.0);
	ko += test_print ("0e+00", "{:.e}", 0.0);
	ko += test_print ("0e+00", "{:.3e}", 0.0);
	ko += test_print ("0e+00", "{:4.3e}", 0.0);
	ko += test_print ("0E+00", "{:E}", 0.0);
	ko += test_print ("1e+01", "{:e}", 10.0);
	ko += test_print ("00000000001e+01", "{:015.3e}", 10.0);
	ko += test_print ("1e+01", "{:.3e}", 10.0);
	ko += test_print ("-1e+01", "{:.3e}", -10.0);
	ko += test_print ("+1e+01", "{:+.3e}", 10.0);
	ko += test_print (" 1e+01", "{: .3e}", 10.0);
	ko += test_print ("           1e+01", "{:16.3e}", 10.0);
	ko += test_print ("1e+01           ", "{:<16.3e}", 10.0);
	ko += test_print ("000000000001e+01", "{:016.3e}", 10.0);
	ko += test_print ("0000001e+01", "{:011.3e}", 10.0);
	ko += test_print ("NaN", "{:e}", F32_NAN);
	ko += test_print ("   NaN", "{:6e}", F32_NAN);
	ko += test_print ("Inf", "{:e}", F32_POSITIVE_INFINITY);
	ko += test_print ("+Inf", "{:+e}", F32_POSITIVE_INFINITY);
	ko += test_print ("    +Inf", "{:+8e}", F32_POSITIVE_INFINITY);
	ko += test_print ("+Inf", "{:+02e}", F32_POSITIVE_INFINITY);
	ko += test_print ("-Inf", "{:e}", F32_NEGATIVE_INFINITY);
	ko += test_print ("NaN", "{:e}", F64_NAN);
	ko += test_print ("Inf", "{:e}", F64_POSITIVE_INFINITY);
	ko += test_print ("-Inf", "{:e}", F64_NEGATIVE_INFINITY);
	ko += test_print ("   NaN", "{:6e}", F32_NAN);
	ko += test_print ("   NaN", "{:06e}", F32_NAN);
	println ("% KOs.", ko);
	println ("============================");

	return ko;
}

test_arg_index :: () -> ko : s64
{
	println ("Test arg index");
	ko := 0;
	ko += test_print ("0", "{0}", 0);
	ko += test_print ("(no argument provided)", "{10}", 0);
	ko += test_print ("(invalid argument index)", "{-10}", 0);
	ko += test_print ("2", "{2}", 0, 1, 2, 3);
	ko += test_print ("+0002", "{2:+0*d}", 5, 1, 2, 3);
	ko += test_print ("+0002 1", "{2:+0*d} {:d}", 5, 1, 2, 3);
	println ("% KOs.", ko);
	println ("============================");

	return ko;
}

test_any :: () -> ko : s64
{
	println ("Test any");
	ko := 0;
	ko += test_print ("0", "%", 0);
	ko += test_print ("(no argument provided)", "%");
	ko += test_print ("10", "%", 10);
	ko += test_print ("null", "%", null);
	ko += test_print ("0x12345", "%", cast (*void) 0x12345);
	ko += test_print ("1", "%", 0x1);
	ko += test_print ("1", "%", 0b1);
	ko += test_print ("Hello Sailor!", "%", "Hello Sailor!");
	ko += test_print ("1.234", "%", 1.234);
	ko += test_print ("179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368", "%", F64_MAX);

	ko += test_print ("A", "%", Test_Enum.A);
	ko += test_print ("B", "%", Test_Enum.B);
	ko += test_print ("C", "%", Test_Enum.C);
	ko += test_print ("Test_Enum (69105)", "%", cast, no_check (Test_Enum) 69105);

	ko += test_print ("0x0", "%", cast (Test_Flags) 0x0);
	ko += test_print ("A", "%", Test_Flags.A);
	ko += test_print ("A | B", "%", Test_Flags.A | .B);
	ko += test_print ("A | B | 0x8", "%", Test_Flags.A | .B | cast, no_check (Test_Flags) 0x08);

	ko += test_print ("Test_Enum", "%", Test_Enum);
	ko += test_print ("Test_Flags", "%", Test_Flags);

	ko += test_print ("Test_Poly_Struct (T = s64, N = 100)", "{:!}", Test_Poly_Struct (s64, 100));
	ko += test_print ("Test_Poly_Struct (s64, 100)", "%", Test_Poly_Struct (s64, 100));
	ko += test_print ("void", "%", void);
	ko += test_print ("Type", "%", Type);
	ko += test_print ("[]Test_Enum", "%", []Test_Enum);
	ko += test_print ("[10]Test_Enum", "%", [10]Test_Enum);
	ko += test_print ("[..]Test_Enum", "%", [..]Test_Enum);

	ko += test_print ("(s64, *s64, *Test_Enum, Test_Poly_Struct (T = Type, N = 500)) -> (bool, string)", "{:!}", Test_Proc);
	ko += test_print ("(s64, *s64, *Test_Enum, Test_Poly_Struct (Type, 500)) -> (bool, string)", "%", Test_Proc);
	ko += test_print ("null", "{:t}", cast (*Type_Info) null);
	ko += test_print ("[]~s16 u8", "{:t}", []~s16 u8);
	ko += test_print ("[]~s16 u8", "{:t}", type_info ([]~s16 u8));
	proc := test_print;
	proc = null;
	ko += test_print ("null", "%", proc);


	ko += test_print ("{       +0.000,       +0.000 }", "%", Vec2f.{ 0, 0 });
	ko += test_print ("{      +10.000,       +0.000 }", "%", Vec2f.{ 10, 0 });
	ko += test_print ("\n{ 1, 0, 0,\n  0, 1, 0,\n  0, 0, 1 }", "\n%", MAT3F_IDENTITY);

	ko += test_print ("[ (6) 0, 1, 2, 3, 4, 5 ]", "%", s64.[ 0, 1, 2, 3, 4, 5 ]);

	ko += test_print ("[ (2) { 0, 0, 0, 0, 0, 0, 0, 0, 0 }, { 1, 0, 0, 0, 1, 0, 0, 0, 1 } ]", "%", Mat3f.[ MAT3F_ZERO, MAT3F_IDENTITY ]);

	array : [..]Vec2f;
	array.allocator = context.allocator;
	Basic.array_add (*array, VEC2F_ZERO);
	Basic.array_add (*array, Vec2f.{ 10, 0 });
	Basic.array_add (*array, Vec2f.{ 1.234, 5.678 });

	ko += test_print ("[ (..3) {       +0.000,       +0.000 }, {      +10.000,       +0.000 }, {       +1.234,       +5.678 } ]", "%", array);

	println ("% KOs.", ko);
	println ("============================");

	return ko;
}

test_other :: () -> ko : s64
{
	println ("Test other");
	ko := 0;
	ko += test_print ("%", "%%");
	ko += test_print ("{", "{{");
	ko += test_print ("(unclosed format)", "{");
	ko += test_print ("00010", "{:010.5}", 10);
	ko += test_print ("hello (no argument provided)   sailor", "hello {: +<010}   sailor");
	ko += test_print ("(invalid specifier)", "{:z}", 10);
	ko += test_print ("(no argument provided)", "%");
	ko += test_print ("(no argument provided)", "{10}");
	ko += test_print ("(invalid argument index)", "{-10}");
	ko += test_print ("-10", "{:.-10i}", -10);
	ko += test_print ("(unclosed format)", "{:.-10i");
	ko += test_print ("(no argument provided)", "{:}");
	ko += test_print ("(invalid specifier)", "{:-+ kol}");
	ko += test_print ("-10", "{}", -10);
	ko += test_print ("⺠", "{:c}", #char "⺠");
	ko += test_print ("àâéèêëîïôùûüæœ⺀⺠", "àâéèêëîïôùûüæœ⺀⺠");
	ko += test_print ("Type_Info", "{:t}", Type_Info);
	ko += test_print ("string", "{:t}", string);
	ko += test_print ("string~s16", "{:t}", string~s16);
	ko += test_print ("Type_Info", "{:t}", type_info (Type_Info));
	ko += test_print ("*Type_Info", "{:t}", type_info (*Type_Info));
	ko += test_print ("*void", "{:t}", null);
	ko += test_print ("s64", "{:t}", 10);
	ko += test_print ("string", "{:t}", "Hello Sailor");
	ko += test_print ("*u8", "{:t}", "Hello Sailor".data);
	println ("% KOs.", ko);
	println ("============================");

	return ko;
}

test_struct :: inline () -> ko : s64
{
	println ("Test struct");
	ko := 0;

	ko += test_print ("{       +1.234,       +5.679 }", "{}", Vec2f.{ 1.234, 5.6785 });
	ko += test_print ("{ 1.234, 5.678, 9.1011 }", "{}", Vec3f.{ 1.234, 5.678, 9.1011 });
	ko += test_print ("\n{ 1, 0, 0,\n  0, 1, 0,\n  0, 0, 1 }", "\n{}", MAT3F_IDENTITY);
	ko += test_print ("\n{ 001.000, 000.000, 000.000,\n  000.000, 001.000, 000.000,\n  000.000, 000.000, 001.000 }", "\n{:~07.3}", MAT3F_IDENTITY);
	ko += test_print ("{ 001.000, 000.000, 000.000, 000.000, 001.000, 000.000, 000.000, 000.000, 001.000 }", "{:~$07.3}", MAT3F_IDENTITY);

	Foo :: struct
	{
		a : string; @Fmt_Newline
		b : int; @Fmt_Newline
		c : float; @Fmt_Newline
	}

	ko += test_print ("{ \"Foo\\nBar\\nBaz\",\n  0,\n  1.234 }", "%", Foo.{ "Foo\nBar\nBaz", 0, 1.234 });
	ko += test_print ("{ \"Foo\\nBar\\nBaz\", 0, 1.234 }", "{:$}", Foo.{ "Foo\nBar\nBaz", 0, 1.234 });
	ko += test_print ("{ a : \"Foo\\nBar\\nBaz\",\n  b : 0,\n  c : 1.234 }", "{:!}", Foo.{ "Foo\nBar\nBaz", 0, 1.234 });
	
	ko += test_print ("[ (2) { \"Foo\\nBar\\nBaz\", 0, 1.234 }, { \"Hello Sailor!\", 69105, 3.1415 } ]", "{}", Foo.[ .{ "Foo\nBar\nBaz", 0, 1.234 }, .{ "Hello Sailor!", 69105, 3.1415 } ]);
	ko += test_print ("[ (2) { a : \"Foo\\nBar\\nBaz\", b : 0, c : 1.234 }, { a : \"Hello Sailor!\", b : 69105, c : 3.1415 } ]", "{:!}", Foo.[ .{ "Foo\nBar\nBaz", 0, 1.234 }, .{ "Hello Sailor!", 69105, 3.1415 } ]);
	ko += test_print ("{     +123.457,       +0.000 }", "{}", Vec2f.{ cast (f32) 123.456789, 0 });
	ko += test_print ("{     +123.000,     +456.000 }", "{}", Vec2i.{ 123, 456 });
	ko += test_print ("{       +0.000,       +0.000 }", "{}", Vec2 (string).{ "Hello", "Sailor" });

	Bar :: struct
	{
		z : int;	@Fmt_Ignore
		a : string;	@Fmt(123.456o
		b : int;	@Fmt(123.456o)
		c : int;	@Fmt_Ignore
		d : float;	@Fmt(123.456o)
		e : *Foo;	@Fmt_Follow_Ptr
	}

	a_foo := Foo.{ "Foo\nBar\nBaz", 0, 1.234 };
	a_bar := Bar.{ 5, "Bad specifier", 10, 11, 12, null };
	ko += test_print ("{ a : (unclosed Fmt note), b : (invalid specifier), d : (invalid specifier), e : null }", "{:!}", a_bar);
	a_bar.e = *a_foo;
	ko += test_print ("{ (unclosed Fmt note), (invalid specifier), (invalid specifier), { \"Foo\\nBar\\nBaz\", 0, 1.234 } }", "%", a_bar);

	Baz :: struct
	{
		a : int;	@Fmt_Ignore
		b : int;	@Fmt_Ignore
		c : int;	@Fmt_Ignore
		d : int;	@Fmt_Ignore
	}

	ko += test_print ("{}", "%", Baz.{});

	Tagged_Union :: struct
	{
		Kind :: enum
		{
			INT;
			FLOAT;
			BOOL;
			STRING;
		}

		kind : Kind;	@Fmt_Tag
		using val : union
		{
			as_int : int;
			as_float : float;	@Fmt(.3)
			as_bool : bool;	@Fmt_Ignore
			as_string : string;
		}; @Fmt_Tagged_Union
	}

	{
		a : Tagged_Union;
		a.kind = .INT;
		a.as_int = 10;
		ko += test_print ("{ INT, 10 }", "%", a);
		b : Tagged_Union;
		b.kind = .FLOAT;
		b.as_float = 123.456;
		ko += test_print ("{ FLOAT, 123.456 }", "%", b);
		c : Tagged_Union;
		c.kind = .STRING;
		c.as_string = "Hello Sailor!";
		ko += test_print ("{ STRING, \"Hello Sailor!\" }", "%", c);
		d : Tagged_Union;
		d.kind = .BOOL;
		d.as_bool = false;
		ko += test_print ("{ BOOL, (ignored) }", "%", d);
	}

	Invalid_Tagged_Union :: struct
	{
		Kind :: enum
		{
			A;
			B;
			C;
		}

		bad_kind : int;	@Fmt_Tag
		good_kind : Kind;	@Fmt_Tag
		bad_val : struct
		{
			a : int;
			b : int;
		};	@Fmt_Tagged_Union
	}

	ko += test_print ("{ 10, B, { 10, 12 } }", "%", Invalid_Tagged_Union.{ 10, .B, .{ 10, 12 } });

	Multi_Tagged_Union :: struct
	{
		Kind :: enum
		{
			A;
			B;
			C;
		}

		first_kind : Kind;	@Fmt_Tag
		first_val : union
		{
			a : int;
			b : float;
			c : string;
		};	@Fmt_Tagged_Union
		first_val2 : union
		{
			a : int;
			b : float;
			c : string;
		};	@Fmt_Tagged_Union
		second_kind : Kind;	@Fmt_Tag @Fmt_Ignore
		second_val : union
		{
			a : int;
			b : float;
			c : string;
		};	@Fmt_Tagged_Union
	}

	{
		val : Multi_Tagged_Union;
		val.first_kind = .A;
		val.first_val.a = 10;
		val.first_val2.a = 12;
		val.second_kind = .C;
		val.second_val.c = "Hello";
		ko += test_print ("{ A, 10, 12, \"Hello\" }", "%", val);
	}

	println ("% KOs.", ko);
	println ("============================");

	return ko;
}

main :: ()
{
	cmd := Basic.get_command_line_arguments ();
	for cmd
	{
		if it == "profile"
		{
			profile = true;

			break;
		}
	}

	// Testing invalid buffer types.
	Almost_Correct_Buffer :: struct
	{
		// buffer is a *void, should be *Almost_Correct_Buffer
		write_byte :: (buffer : *void, byte : u8)
		{

		}
	}
	// Uncomment below for compiler error:
	//write_f64 (null, 10);	// null is of type *void, which is not a valid buffer type
	//write_f64 (*MAT3F_IDENTITY, 10);
	//write_f64 (cast (*Almost_Correct_Buffer) null, 10);

	// Non constant write_byte procedure compiles fine.
	Non_Const_Buffer :: struct
	{
		write_byte := (buffer : *Non_Const_Buffer, byte : u8)
		{}
	}
	non_const_buff : Non_Const_Buffer;
	write_f64 (*non_const_buff, 10);

	ko := 0;
	ko += test_string ();
	ko += test_decimal ();
	ko += test_binary ();
	ko += test_hexadecimal ();
	ko += test_float_fixed ();
	ko += test_float_exp ();
	ko += test_arg_index ();
	ko += test_any ();
	ko += test_other ();
	ko += test_struct ();
	//Basic.print ("Test print:\n");
	//len1 := print ("Hello Sailor!\n{:}\n{:10.3f}\n", MAT3F_IDENTITY, 1.234);
	//str := fmt (context.allocator, "Hello Sailor!\n{:}\n{:10.3f}\n", MAT3F_IDENTITY, 1.234);
	//if len1 != str.count
	//	Basic.print ("print returned a length of %, but % was expected.\n", len1, str.count);
	println (" %/% tests SUCCESSFUL,\n % FAILURES.", total_tests - ko, total_tests, ko);

	//a_var := 10;
	//print_var (a_var);
	//print_var ("Hello");
}

//================================================================================================

f32 :: float32;
f64 :: float64;

 S8_MIN :  s8 :                       -128;
 S8_MAX :  s8 :                        127;
 U8_MAX :  u8 :                        255;
S16_MIN : s16 :                    -32_768;
S16_MAX : s16 :                     32_767;
U16_MAX : u16 :                     65_535;
S32_MIN : s32 :             -2_147_483_648;
S32_MAX : s32 :              2_147_483_647;
U32_MAX : u32 :              4_294_967_295;
S64_MIN : s64 : -9_223_372_036_854_775_808;
S64_MAX : s64 :  9_223_372_036_854_775_807;
U64_MAX : u64 : 18_446_744_073_709_551_615;

F32_MIN :: 0h0080_0000;
F32_MAX :: 0h7f7f_ffff;
F32_MIN_SUBNORMAL :: 0h0000_0001;
F32_MAX_SUBNORMAL :: 0h007f_ffff;
F32_POSITIVE_INFINITY :: 0h7f80_0000;
F32_NEGATIVE_INFINITY :: 0hff80_0000;
F32_NAN :: 0h7fc0_0000;
F32_EPSILON :: 0h3400_0000;

F32_MANTISSA_BITS :: 23;
F32_EXPONENT_BITS :: 8;
F32_EXPONENT_BIAS :: 127;

F64_MIN :: 0h0010_0000_0000_0000;
F64_MAX :: 0h7fef_ffff_ffff_ffff;
F64_MIN_SUBNORMAL :: 0h0000_0000_0000_0001;
F64_MAX_SUBNORMAL :: 0h000f_ffff_ffff_ffff;
F64_POSITIVE_INFINITY :: 0h7ff0_0000_0000_0000;
F64_NEGATIVE_INFINITY :: 0hfff0_0000_0000_0000;
F64_NAN :: 0h7ff8_0000_0000_0000;
F64_EPSILON :: 0h3cb0_0000_0000_0000;

F64_MANTISSA_BITS :: 52;
F64_EXPONENT_BITS :: 11;
F64_EXPONENT_BIAS :: 1023;

Test_Enum :: enum
{
	A :: -1;
	B :: 0;
	C :: 10;
	D :: 1234;
}

Test_Flags :: enum_flags
{
	A :: 0x01;
	B :: 0x02;
	C :: 0x04;
}

Test_Poly_Struct :: struct (T : Type, N : int)
{
	vals : [N]T;
}

Test_Proc :: #type (int, *int, *Test_Enum, Test_Poly_Struct (Type, 500)) -> bool, string;

Mat3f :: struct
{
	r0c0 : f32; r0c1 : f32; r0c2 : f32; @Fmt_Newline
	r1c0 : f32; r1c1 : f32; r1c2 : f32; @Fmt_Newline
	r2c0 : f32; r2c1 : f32; r2c2 : f32; @Fmt_Newline

	#place r0c0;
	c0r0, c1r0, c2r0 : f32;
	c0r1, c1r1, c2r1 : f32;
	c0r2, c1r2, c2r2 : f32;

	#place r0c0;
	rows : [3]Vec3f;

	#place r0c0;
	r0 : Vec3f;
	r1 : Vec3f;
	r2 : Vec3f;

	#place r0c0;
	n : [3][3]f32;
}

MAT3F_ZERO :: Mat3f.{
	0, 0, 0,
	0, 0, 0,
	0, 0, 0
};

MAT3F_IDENTITY :: Mat3f.{
	1, 0, 0,
	0, 1, 0,
	0, 0, 1
};

Vec2 :: struct (T : Type)
{
	x, y : T;	@Fmt(+~12.3f)

	#place x;
	w, h : T;

	#place x;
	width, height : T;

	#place x;
	n : [2]T;
}

Vec2f :: Vec2 (f32);
Vec2i :: Vec2 (s32);

VEC2F_ZERO :: Vec2f.{ 0, 0 };
VEC2F_ONE  :: Vec2f.{ 1, 1 };

Vec3f :: struct
{
	x, y, z : f32;

	#place x;
	r, g, b : f32;

	#place x;
	pitch, yaw, roll : f32;

	#place x;
	xy : Vec2f;

	#place y;
	yz : Vec2f;

	#place x;
	n : [3]f32;
}

VEC3F_ZERO :: Vec3f.{ 0, 0, 0 };
VEC3F_ONE  :: Vec3f.{ 1, 1, 1 };
