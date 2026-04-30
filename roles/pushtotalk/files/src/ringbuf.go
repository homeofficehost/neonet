package main

type RingBuffer struct {
	buf  []float32
	read int
	write int
	size int
}

func NewRingBuffer(samples int) *RingBuffer {
	return &RingBuffer{
		buf:  make([]float32, samples),
		size: samples,
	}
}

func (rb *RingBuffer) Write(samples []float32) {
	for _, s := range samples {
		rb.buf[rb.write] = s
		rb.write++
		if rb.write >= rb.size {
			rb.write = 0
		}
	}
}

func (rb *RingBuffer) Read(out []float32) {
	for i := range out {
		out[i] = rb.buf[rb.read]
		rb.read++
		if rb.read >= rb.size {
			rb.read = 0
		}
	}
}
