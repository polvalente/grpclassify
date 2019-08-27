to_gray() {
	convert $1 -set colorspace Gray -separate -average $1.jpg
}
