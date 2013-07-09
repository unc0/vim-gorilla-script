// binary
0b101011
-0B111111
0b100.01001
0B122345 // wrong

// octal
0o124_222_222
-0O1271231
0o133_71.3_21
0O128888 // wrong

// hex
0x12f0_0000
-0X1888
0x13fe_6c2e.124a_fee
0x12gg // wrong

// redix
20r1ghjk
-30R1ghJk_HHI
20r1efjk.ijae
40R1fhadkfjeix_SAJDF // wrong

// decimal
1_000_000
-1_000_000
+1_000_000_ms
-1_000e+8_kph
a -1_000e+8_kph
a+1_000e+8_kph
a1_000_000 // wrong
100egg // wrong

// float
1_000_000.012_666e-5_m2
-2_803_710.012_666e+15_m
2.5L // wrong

Infinity NaN

// don't highlight number in identifier
// FIXME i don't know how to fix this...
let md5 = foo
