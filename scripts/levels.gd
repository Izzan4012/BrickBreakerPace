extends RefCounted
## Layout level. Tiap baris 9 karakter.
## b p g o r = brick biasa (biru, ungu, hijau, oranye, merah)
## B P       = brick keras 2x pukul (retak setelah pukulan pertama)
## S         = brick baja 3x pukul
## X         = brick hazard, tidak bisa dihancurkan
## *         = brick bintang, pasti menjatuhkan power-up
## .         = kosong

const LAYOUTS := [
	[
		"bbbbbbbbb",
		"rrrr*rrrr",
		"ooooooooo",
		"ggggggggg",
	],
	[
		"..ppppp..",
		".BBBBBBB.",
		"rr*rrr*rr",
		"ggggggggg",
		"o.o.o.o.o",
	],
	[
		"SSS...SSS",
		"bbb...bbb",
		"ppp.*.ppp",
		"ggggggggg",
		"X.ooooo.X",
		"rrrrrrrrr",
	],
	[
		"....*....",
		"...ppp...",
		"..BBBBB..",
		".ggggggg.",
		"ooooooooo",
		"X.X...X.X",
		"rrrrrrrrr",
	],
	[
		"rbrbrbrbr",
		"P.P.*.P.P",
		"gogogogog",
		"S.S.S.S.S",
		"bbbbbbbbb",
		"ooo*X*ooo",
	],
]


static func count() -> int:
	return LAYOUTS.size()


static func get_layout(index: int) -> Array:
	return LAYOUTS[index % LAYOUTS.size()]
