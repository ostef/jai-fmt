Basic :: #import "Basic";
#import "Fmt";

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
	x, y : T;

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

test_print :: (n : s64, expected : string, fmt_str : string, args : ..Any) -> ko : s64
{
	str := fmt (context.allocator, fmt_str, ..args);
	if str != expected
	{
		Basic.print ("[%]: Expected '%', got '%'.\n", n, expected, str);
		Basic.print ("fmt_str was: '%'.\n", fmt_str);
		Basic.print ("[%]: KO.\n", n);

		return 1;
	}
	Basic.print ("[%]: OK.\n", n);

	return 0;
}

test_string :: () -> ko : s64
{
	Basic.print ("Test %%s:\n");
	ko := 0;
	i := 0;
	ko += test_print (i, "(null)", "{:s}", "");
	i += 1;
	ko += test_print (i, "    (null)", "{:10s}", "");
	i += 1;
	ko += test_print (i, "(null)", "{:010s}", "");
	i += 1;
	ko += test_print (i, "    (null)", "{:10s}", "");
	i += 1;
	ko += test_print (i, "(nu", "{:.3s}", "");
	i += 1;
	ko += test_print (i, "Hello\\nSailor", "{:\\s}", "Hello\nSailor");
	i += 1;
	ko += test_print (i, "Hello", "{:\\.5s}", "Hello\nSailor");
	i += 1;
	ko += test_print (i, "   Hello Sailor", "{:15s}", "Hello Sailor");
	i += 1;
	ko += test_print (i, "          Hello", "{:15.5s}", "Hello Sailor");
	i += 1;
	ko += test_print (i, "          Hello Sailor", "{:15.5s} Sailor", "Hello");
	i += 1;
	Basic.print ("%%s, % KOs.\n", ko);
	Basic.print ("============================\n");

	return ko;
}

test_decimal :: () -> ko : s64
{
	Basic.print ("Test %%i:\n");
	ko := 0;
	i := 0;
	ko += test_print (i, "0", "{:i}", 0);
	i += 1;
	ko += test_print (i, "10", "{:i}", 10);
	i += 1;
	ko += test_print (i, "-10", "{:i}", -10);
	i += 1;
	ko += test_print (i, "-9223372036854775808", "{:i}", S64_MIN);
	i += 1;
	ko += test_print (i, "9223372036854775807", "{:i}", S64_MAX);
	i += 1;
	ko += test_print (i, "18446744073709551615", "{:i}", U64_MAX);
	i += 1;
	ko += test_print (i, "-000000010", "{:010i}", -10);
	i += 1;
	ko += test_print (i, "00010", "{:010.5i}", 10);
	i += 1;
	ko += test_print (i, "-00010", "{:010.5i}", -10);
	i += 1;
	ko += test_print (i, "-00010", "{:010.*i}", 5, -10);
	i += 1;
	ko += test_print (i, "-00010", "{:0*.*i}", 10, 5, -10);
	i += 1;
	ko += test_print (i, "-00010", "{:03.5i}", -10);
	i += 1;
	ko += test_print (i, "42", "{:<i}", 42);
	i += 1;
	ko += test_print (i, "42   ", "{:<5i}", 42);
	i += 1;
	ko += test_print (i, "42        ", "{:<*i}", 10, 42);
	i += 1;
	ko += test_print (i, "42   ", "{:<05i}", 42);
	i += 1;
	ko += test_print (i, "42        ", "{:<0*i}", 10, 42);
	i += 1;
	ko += test_print (i, "42", "{:.0i}", 42);
	i += 1;
	ko += test_print (i, "", "{:.0i}", 0);
	i += 1;
	ko += test_print (i, "42", "{:.i}", 42);
	i += 1;
	ko += test_print (i, "", "{:.i}", 0);
	i += 1;
	ko += test_print (i, "+10", "{:+i}", 10);
	i += 1;
	ko += test_print (i, " 10", "{: i}", 10);
	i += 1;
	ko += test_print (i, "-10", "{:+i}", -10);
	i += 1;
	ko += test_print (i, "10", "{:i}", Test_Enum.C);
	i += 1;
	Basic.print ("%%i, % KOs.\n", ko);
	Basic.print ("============================\n");

	return ko;
}

test_binary :: () -> ko : s64
{
	Basic.print ("Test %%b:\n");
	ko := 0;
	i := 0;
	ko += test_print (i, "0", "{:b}", 0);
	i += 1;
	ko += test_print (i, "101010", "{:b}", 0b101010);
	i += 1;
	ko += test_print (i, "1111111111111111111111111111111111111111111111111111111111111111", "{:b}", 0xffffffffffffffff);
	i += 1;
	ko += test_print (i, "0b0", "{:#b}", 0);
	i += 1;
	ko += test_print (i, "", "{:.0b}", 0);
	i += 1;
	ko += test_print (i, "", "{:.b}", 0);
	i += 1;
	ko += test_print (i, "0b", "{:#.b}", 0);
	i += 1;
	ko += test_print (i, "0b00011001", "{:#.8b}", 0b11001);
	i += 1;
	ko += test_print (i, "0b011001", "{:#08b}", 0b11001);
	i += 1;
	ko += test_print (i, "00011001", "{:08b}", 0b11001);
	i += 1;
	ko += test_print (i, "11001           ", "{:<16b}", 0b11001);
	i += 1;
	ko += test_print (i, "11001", "{:+b}", 0b11001);
	i += 1;
	ko += test_print (i, "11001", "{: b}", 0b11001);
	i += 1;
	ko += test_print (i, "0b00011001", "{:#10.8b}", 0b11001);
	i += 1;
	ko += test_print (i, "      0b00011001", "{:#16.8b}", 0b11001);
	i += 1;
	ko += test_print (i, "0b00011001", "{:#016.8b}", 0b11001);
	i += 1;
	Basic.print ("%%b, % KOs.\n", ko);
	Basic.print ("============================\n");

	return ko;
}

test_hexadecimal :: () -> ko : s64
{
	Basic.print ("Test %%x:\n");
	ko := 0;
	i := 0;
	ko += test_print (i, "0", "{:x}", 0);
	i += 1;
	ko += test_print (i, "badbeef", "{:x}", 0xbadbeef);
	i += 1;
	ko += test_print (i, "ffffffffffffffff", "{:x}", 0xffffffffffffffff);
	i += 1;
	ko += test_print (i, "0x0", "{:#x}", 0);
	i += 1;
	ko += test_print (i, "", "{:.0x}", 0);
	i += 1;
	ko += test_print (i, "", "{:.x}", 0);
	i += 1;
	ko += test_print (i, "0x", "{:#.x}", 0);
	i += 1;
	ko += test_print (i, "0x0badbeef", "{:#.8x}", 0xbadbeef);
	i += 1;
	ko += test_print (i, "0xbadbeef", "{:#08x}", 0xbadbeef);
	i += 1;
	ko += test_print (i, "0badbeef", "{:08x}", 0xbadbeef);
	i += 1;
	ko += test_print (i, "badbeef         ", "{:<16x}", 0xbadbeef);
	i += 1;
	ko += test_print (i, "badbeef", "{:+x}", 0xbadbeef);
	i += 1;
	ko += test_print (i, "badbeef", "{: x}", 0xbadbeef);
	i += 1;
	ko += test_print (i, "0x0badbeef", "{:#10.8x}", 0xbadbeef);
	i += 1;
	ko += test_print (i, "      0x0badbeef", "{:#16.8x}", 0xbadbeef);
	i += 1;
	ko += test_print (i, "0x0badbeef", "{:#016.8x}", 0xbadbeef);
	i += 1;
	ko += test_print (i, "1", "{:x}", Test_Flags.A);
	i += 1;
	Basic.print ("%%x, % KOs.\n", ko);
	Basic.print ("============================\n");

	return ko;
}

test_float_fixed :: () -> s64
{
	Basic.print ("Test %%f:\n");
	ko := 0;
	i := 0;
	ko += test_print (i, "1.234", "{:f}", 1.234);
	i += 1;
	ko += test_print (i, "1.234", "{:.3f}", 1.234);
	i += 1;
	ko += test_print (i, "1", "{:.f}", 1.234);
	i += 1;
	ko += test_print (i, "10", "{:f}", 9.9999999);
	i += 1;
	ko += test_print (i, "-10", "{:f}", -9.9999999);
	i += 1;
	ko += test_print (i, "10", "{:.f}", 9.9999999);
	i += 1;
	ko += test_print (i, "0000010", "{:07.3f}", 9.9999999);
	i += 1;
	ko += test_print (i, "     10", "{:7.3f}", 9.9999999);
	i += 1;
	ko += test_print (i, "NaN", "{:f}", F32_NAN);
	i += 1;
	ko += test_print (i, "   NaN", "{:6f}", F32_NAN);
	i += 1;
	ko += test_print (i, "Inf", "{:f}", F32_POSITIVE_INFINITY);
	i += 1;
	ko += test_print (i, "+Inf", "{:+f}", F32_POSITIVE_INFINITY);
	i += 1;
	ko += test_print (i, "    +Inf", "{:+8f}", F32_POSITIVE_INFINITY);
	i += 1;
	ko += test_print (i, "+Inf", "{:+02f}", F32_POSITIVE_INFINITY);
	i += 1;
	ko += test_print (i, "-Inf", "{:f}", F32_NEGATIVE_INFINITY);
	i += 1;
	ko += test_print (i, "NaN", "{:f}", F64_NAN);
	i += 1;
	ko += test_print (i, "Inf", "{:f}", F64_POSITIVE_INFINITY);
	i += 1;
	ko += test_print (i, "-Inf", "{:f}", F64_NEGATIVE_INFINITY);
	i += 1;
	ko += test_print (i, "   NaN", "{:6f}", F32_NAN);
	i += 1;
	ko += test_print (i, "   NaN", "{:06f}", F32_NAN);
	i += 1;
	Basic.print ("%%f, % KOs.\n", ko);
	Basic.print ("============================\n");

	return ko;
}

test_float_exp :: () -> s64
{
	Basic.print ("Test %%e:\n");
	ko := 0;
	i := 0;
	ko += test_print (i, "0e+00", "{:e}", 0.0);
	i += 1;
	ko += test_print (i, "-0e+00", "{:e}", -0.0);
	i += 1;
	ko += test_print (i, "0e+00", "{:.e}", 0.0);
	i += 1;
	ko += test_print (i, "0e+00", "{:.3e}", 0.0);
	i += 1;
	ko += test_print (i, "0e+00", "{:4.3e}", 0.0);
	i += 1;
	ko += test_print (i, "0E+00", "{:E}", 0.0);
	i += 1;
	ko += test_print (i, "1e+01", "{:e}", 10.0);
	i += 1;
	ko += test_print (i, "00000000001e+01", "{:015.3e}", 10.0);
	i += 1;
	ko += test_print (i, "1e+01", "{:.3e}", 10.0);
	i += 1;
	ko += test_print (i, "-1e+01", "{:.3e}", -10.0);
	i += 1;
	ko += test_print (i, "+1e+01", "{:+.3e}", 10.0);
	i += 1;
	ko += test_print (i, " 1e+01", "{: .3e}", 10.0);
	i += 1;
	ko += test_print (i, "           1e+01", "{:16.3e}", 10.0);
	i += 1;
	ko += test_print (i, "1e+01           ", "{:<16.3e}", 10.0);
	i += 1;
	ko += test_print (i, "000000000001e+01", "{:016.3e}", 10.0);
	i += 1;
	ko += test_print (i, "0000001e+01", "{:011.3e}", 10.0);
	i += 1;
	ko += test_print (i, "NaN", "{:e}", F32_NAN);
	i += 1;
	ko += test_print (i, "   NaN", "{:6e}", F32_NAN);
	i += 1;
	ko += test_print (i, "Inf", "{:e}", F32_POSITIVE_INFINITY);
	i += 1;
	ko += test_print (i, "+Inf", "{:+e}", F32_POSITIVE_INFINITY);
	i += 1;
	ko += test_print (i, "    +Inf", "{:+8e}", F32_POSITIVE_INFINITY);
	i += 1;
	ko += test_print (i, "+Inf", "{:+02e}", F32_POSITIVE_INFINITY);
	i += 1;
	ko += test_print (i, "-Inf", "{:e}", F32_NEGATIVE_INFINITY);
	i += 1;
	ko += test_print (i, "NaN", "{:e}", F64_NAN);
	i += 1;
	ko += test_print (i, "Inf", "{:e}", F64_POSITIVE_INFINITY);
	i += 1;
	ko += test_print (i, "-Inf", "{:e}", F64_NEGATIVE_INFINITY);
	i += 1;
	ko += test_print (i, "   NaN", "{:6e}", F32_NAN);
	i += 1;
	ko += test_print (i, "   NaN", "{:06e}", F32_NAN);
	i += 1;
	Basic.print ("%%e, % KOs.\n", ko);
	Basic.print ("============================\n");

	return ko;
}

test_float_hex :: () -> s64
{
	Basic.print ("Test %%a:\n");
	ko := 0;
	i := 0;
	ko += test_print (i, "0x0.000000p1", "{:a}", 0.0);
	i += 1;
	ko += test_print (i, "-0x0.000000p1", "{:a}", -0.0);
	i += 1;
	ko += test_print (i, "0X0.000000P1", "{:A}", 0.0);
	i += 1;
	ko += test_print (i, "0x1.200000p3", "{:a}", 10.0);
	i += 1;
	ko += test_print (i, "0x1p3", "{:.a}", 10.0);
	i += 1;
	ko += test_print (i, "0x1.200p3", "{:.3a}", 10.0);
	i += 1;
	ko += test_print (i, "0x0000001.200p3", "{:015.3a}", 10.0);
	i += 1;
	ko += test_print (i, "NaN", "{:a}", F32_NAN);
	i += 1;
	ko += test_print (i, "Inf", "{:a}", F32_POSITIVE_INFINITY);
	i += 1;
	ko += test_print (i, "-Inf", "{:a}", F32_NEGATIVE_INFINITY);
	i += 1;
	ko += test_print (i, "NaN", "{:a}", F64_NAN);
	i += 1;
	ko += test_print (i, "Inf", "{:a}", F64_POSITIVE_INFINITY);
	i += 1;
	ko += test_print (i, "-Inf", "{:a}", F64_NEGATIVE_INFINITY);
	i += 1;
	Basic.print ("%%a, % KOs.\n", ko);
	Basic.print ("============================\n");

	return ko;
}

test_arg_index :: () -> ko : s64
{
	Basic.print ("Test arg index:\n");
	ko := 0;
	i := 0;
	ko += test_print (i, "0", "{0}", 0);
	i += 1;
	ko += test_print (i, "(no argument provided)", "{10}", 0);
	i += 1;
	ko += test_print (i, "(invalid argument index)", "{-10}", 0);
	i += 1;
	ko += test_print (i, "2", "{2}", 0, 1, 2, 3);
	i += 1;
	ko += test_print (i, "+0002", "{2:+0*d}", 5, 1, 2, 3);
	i += 1;
	ko += test_print (i, "+0002 1", "{2:+0*d} {:d}", 5, 1, 2, 3);
	i += 1;
	Basic.print ("arg index, % KOs.\n", ko);
	Basic.print ("============================\n");

	return ko;
}

test_any :: () -> ko : s64
{
	Basic.print ("Test %%:\n");
	ko := 0;
	i := 0;
	ko += test_print (i, "0", "%", 0);
	i += 1;
	ko += test_print (i, "(no argument provided)", "%");
	i += 1;
	ko += test_print (i, "10", "%", 10);
	i += 1;
	ko += test_print (i, "null", "%", null);
	i += 1;
	ko += test_print (i, "0x12345", "%", cast (*void) 0x12345);
	i += 1;
	ko += test_print (i, "1", "%", 0x1);
	i += 1;
	ko += test_print (i, "1", "%", 0b1);
	i += 1;
	ko += test_print (i, "Hello Sailor!", "%", "Hello Sailor!");
	i += 1;
	ko += test_print (i, "1.234", "%", 1.234);
	i += 1;
	ko += test_print (i, "1.797693e308", "%", F64_MAX);
	i += 1;

	ko += test_print (i, "A", "%", Test_Enum.A);
	i += 1;
	ko += test_print (i, "B", "%", Test_Enum.B);
	i += 1;
	ko += test_print (i, "C", "%", Test_Enum.C);
	i += 1;
	ko += test_print (i, "Test_Enum (69105)", "%", cast, no_check (Test_Enum) 69105);
	i += 1;

	ko += test_print (i, "0x0", "%", cast (Test_Flags) 0x0);
	i += 1;
	ko += test_print (i, "A", "%", Test_Flags.A);
	i += 1;
	ko += test_print (i, "A | B", "%", Test_Flags.A | .B);
	i += 1;
	ko += test_print (i, "A | B | 0x8", "%", Test_Flags.A | .B | cast, no_check (Test_Flags) 0x08);
	i += 1;

	ko += test_print (i, "Test_Enum", "%", Test_Enum);
	i += 1;
	ko += test_print (i, "Test_Flags", "%", Test_Flags);
	i += 1;

	ko += test_print (i, "Test_Poly_Struct (T = s64, N = 100)", "%", Test_Poly_Struct (s64, 100));
	i += 1;
	ko += test_print (i, "void", "%", void);
	i += 1;
	ko += test_print (i, "Type", "%", Type);
	i += 1;
	ko += test_print (i, "[]Test_Enum", "%", []Test_Enum);
	i += 1;
	ko += test_print (i, "[10]Test_Enum", "%", [10]Test_Enum);
	i += 1;
	ko += test_print (i, "[..]Test_Enum", "%", [..]Test_Enum);
	i += 1;

	ko += test_print (i, "(s64, *s64, *Test_Enum, Test_Poly_Struct (T = Type, N = 500)) -> (bool, string)", "%", Test_Proc);
	i += 1;

	Foo :: struct
	{
		a : string;
		b : int;
		c : float;
	}

	ko += test_print (i, "{ 0, 0 }", "%", Vec2f.{ 0, 0 });
	i += 1;
	ko += test_print (i, "{ 10, 0 }", "%", Vec2f.{ 10, 0 });
	i += 1;
	ko += test_print (i, "{ a : \"Foo\\nBar\\nBaz\", b : 0, c : 1.234 }", "%", Foo.{ "Foo\nBar\nBaz", 0, 1.234 });
	i += 1;
	ko += test_print (i, "\n{ 1, 0, 0,\n  0, 1, 0,\n  0, 0, 1 }", "\n%", MAT3F_IDENTITY);
	i += 1;

	ko += test_print (i, "[ (6) 0, 1, 2, 3, 4, 5 ]", "%", s64.[ 0, 1, 2, 3, 4, 5 ]);
	i += 1;

	ko += test_print (i, "[ (2) { 0, 0, 0, 0, 0, 0, 0, 0, 0 }, { 1, 0, 0, 0, 1, 0, 0, 0, 1 } ]", "%", Mat3f.[ MAT3F_ZERO, MAT3F_IDENTITY ]);
	i += 1;

	array : [..]Vec2f;
	array.allocator = context.allocator;
	Basic.array_add (*array, VEC2F_ZERO);
	Basic.array_add (*array, Vec2f.{ 10, 0 });
	Basic.array_add (*array, Vec2f.{ 1.234, 5.678 });

	ko += test_print (i, "[ (..3) { 0, 0 }, { 10, 0 }, { 1.234, 5.678 } ]", "%", array);
	i += 1;

	Basic.print ("%%, % KOs.\n", ko);
	Basic.print ("============================\n");

	return ko;
}

test_other :: () -> ko : s64
{
	Basic.print ("Test other:\n");
	ko := 0;
	i := 0;
	ko += test_print (i, "%", "%%");
	i += 1;
	ko += test_print (i, "{", "{{");
	i += 1;
	ko += test_print (i, "(unclosed format)", "{");
	i += 1;
	ko += test_print (i, "(invalid specifier)", "{:010.5}", 10);
	i += 1;
	ko += test_print (i, "hello (invalid specifier)   sailor", "hello {: +<010}   sailor");
	i += 1;
	ko += test_print (i, "(invalid specifier)", "{:z}", 10);
	i += 1;
	ko += test_print (i, "(no argument provided)", "%");
	i += 1;
	ko += test_print (i, "(no argument provided)", "{10}");
	i += 1;
	ko += test_print (i, "(invalid argument index)", "{-10}");
	i += 1;
	ko += test_print (i, "-10", "{:.-10i}", -10);
	i += 1;
	ko += test_print (i, "(unclosed format)", "{:.-10i");
	i += 1;
	ko += test_print (i, "(invalid specifier)", "{:}");
	i += 1;
	ko += test_print (i, "(invalid specifier)", "{:-+ kol}");
	i += 1;
	ko += test_print (i, "-10", "{}", -10);
	i += 1;
	ko += test_print (i, "àâéèêëîïôùûüæœ⺀⺠", "àâéèêëîïôùûüæœ⺀⺠");
	i += 1;
	Basic.print ("other, % KOs.\n", ko);
	Basic.print ("============================\n");

	return ko;
}

test_linalg :: inline () -> ko : s64
{
	Basic.print ("Test linalg:\n");
	ko := 0;
	i := 0;

	ko += test_print (i, "( 1.234, 5.6785 )", "{:v}", Vec2f.{ 1.234, 5.6785 });
	i += 1;
	ko += test_print (i, "( 1.234, 5.678, 9.1011 )", "{:v}", Vec3f.{ 1.234, 5.678, 9.1011 });
	i += 1;
	ko += test_print (i, "\n( 1, 0, 0,\n  0, 1, 0,\n  0, 0, 1 )", "\n{:m}", MAT3F_IDENTITY);
	i += 1;
	ko += test_print (i, "\n( 1, 0, 0,\n  0, 1, 0,\n  0, 0, 1 )", "\n{:m}", [3]f32.[ f32.[ 1, 0, 0 ], f32.[ 0, 1, 0 ], f32.[ 0, 0, 1 ] ]);
	i += 1;
	ko += test_print (i, "(not a matrix type)", "{:m}", "Hello");
	i += 1;
	ko += test_print (i, "\n( 001.000, 000.000, 000.000,\n  000.000, 001.000, 000.000,\n  000.000, 000.000, 001.000 )", "\n{:~07.3m}", MAT3F_IDENTITY);
	i += 1;
	ko += test_print (i, "( 001.000, 000.000, 000.000, 000.000, 001.000, 000.000, 000.000, 000.000, 001.000 )", "{:~$07.3m}", MAT3F_IDENTITY);
	i += 1;
	ko += test_print (i, "\n( 1.234,\n  5.6785 )", "\n{:m}", Vec2f.{ 1.234, 5.6785 });
	i += 1;
	ko += test_print (i, "\n( 1.234,\n  5.678,\n  9.1011 )", "\n{:m}", Vec3f.{ 1.234, 5.678, 9.1011 });
	i += 1;

	Basic.print ("linalg, % KOs.\n", ko);
	Basic.print ("============================\n");

	return ko;
}

main :: ()
{
	ko := 0;
	ko += test_string ();
	ko += test_decimal ();
	ko += test_binary ();
	ko += test_hexadecimal ();
	ko += test_float_fixed ();
	ko += test_float_exp ();
	ko += test_float_hex ();
	ko += test_arg_index ();
	ko += test_any ();
	ko += test_other ();
	ko += test_linalg ();
	Basic.print ("Test print:\n");
	len1 := print ("Hello Sailor!\n{:m}\n{:10.3f}\n", MAT3F_IDENTITY, 1.234);
	str := fmt (context.allocator, "Hello Sailor!\n{:m}\n{:10.3f}\n", MAT3F_IDENTITY, 1.234);
	if len1 != str.count
		Basic.print ("print returned a length of %, but % was expected.\n", len1, str.count);
	Basic.print ("============================\n");
	Basic.print ("     % KOs total.\n", ko);
}
