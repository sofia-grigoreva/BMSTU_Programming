package main

func encode(utf32 []rune) []byte {
	utf8 := make([]byte, 0)

	for _, x := range utf32 {
		if x <= 0x7F {
			utf8 = append(utf8, byte(x))
		} else {
		    if x <= 0x7FF {
			utf8 = append(utf8, byte(0xC0+(x>>6)))
		    } else if x <= 0xFFFF {
			    utf8 = append(utf8, byte(0xE0+(x>>12)))
			    utf8 = append(utf8, byte(0x80+((x>>6)&0x3F)))
		    } else {
			    utf8 = append(utf8, byte(0xF0+(x>>18)))
			    utf8 = append(utf8, byte(0x80+((x>>12)&0x3F)))
			    utf8 = append(utf8, byte(0x80+((x>>6)&0x3F)))
		    }
		    utf8 = append(utf8, byte(0x80+(x&0x3F)))
		}
	}
	return utf8
}

func decode(utf8 []byte) []rune {
	utf32 := make([]rune, 0)
	for i := 0; i < len(utf8); {
		x := utf8[i]
		if x&0x80 == 0 {
			utf32 = append(utf32, rune(x))
			i++
		} else if x&0xE0 == 0xC0 {
			utf32 = append(utf32, rune(((int(x)&0x1F)<<6)+
				(int(utf8[i+1])&0x3F)))
			i += 2
		} else if x&0xF0 == 0xE0 {
			utf32 = append(utf32, rune(((int(x)&0x0F)<<12)+
				((int(utf8[i+1])&0x3F)<<6)+
				(int(utf8[i+2])&0x3F)))
			i += 3
		} else {
			utf32 = append(utf32, rune(((int(x)&0x07)<<18)+
				((int(utf8[i+1])&0x3F)<<12)+
				((int(utf8[i+2])&0x3F)<<6)+
				(int(utf8[i+3])&0x3F)))
			i += 4
		}
	}
	return utf32
}

func main() {
}
