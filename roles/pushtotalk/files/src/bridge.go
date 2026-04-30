package main

import (
	"fmt"
	"strings"
	"sync"
	"unsafe"

	"github.com/gordonklaus/portaudio"
)

const (
	sampleRate   = 48000
	channels     = 2
	framesPerBuf = 256
	bufferSize   = sampleRate * channels
)

type AudioBridge struct {
	inputDev     *portaudio.DeviceInfo
	outputDev    *portaudio.DeviceInfo
	inputStream  *portaudio.Stream
	outputStream *portaudio.Stream
	ring         *RingBuffer
	paused       bool
	mu           sync.RWMutex
}

func NewAudioBridge(inputName, outputName string) (*AudioBridge, error) {
	if err := portaudio.Initialize(); err != nil {
		return nil, fmt.Errorf("portaudio init: %w", err)
	}

	inputDev, err := findDevice(inputName, true)
	if err != nil {
		portaudio.Terminate()
		return nil, fmt.Errorf("input device: %w", err)
	}

	outputDev, err := findDevice(outputName, false)
	if err != nil {
		portaudio.Terminate()
		return nil, fmt.Errorf("output device: %w", err)
	}

	return &AudioBridge{
		inputDev:  inputDev,
		outputDev: outputDev,
		ring:      NewRingBuffer(bufferSize),
		paused:    true,
	}, nil
}

func (b *AudioBridge) Start() error {
	b.mu.Lock()
	defer b.mu.Unlock()

	inParams := portaudio.StreamParameters{
		Input: portaudio.StreamDeviceParameters{
			Device:   b.inputDev,
			Channels: channels,
			Latency:  b.inputDev.DefaultLowInputLatency,
		},
		SampleRate:      sampleRate,
		FramesPerBuffer: framesPerBuf,
	}

	outParams := portaudio.StreamParameters{
		Output: portaudio.StreamDeviceParameters{
			Device:   b.outputDev,
			Channels: channels,
			Latency:  b.outputDev.DefaultLowOutputLatency,
		},
		SampleRate:      sampleRate,
		FramesPerBuffer: framesPerBuf,
	}

	inStream, err := portaudio.OpenStream(inParams, func(in []float32) {
		b.mu.RLock()
		paused := b.paused
		b.mu.RUnlock()

		if paused {
			return
		}
		b.ring.Write(in)
	})
	if err != nil {
		return fmt.Errorf("open input stream: %w", err)
	}

	outStream, err := portaudio.OpenStream(outParams, func(out []float32) {
		b.mu.RLock()
		paused := b.paused
		b.mu.RUnlock()

		if paused {
			for i := range out {
				out[i] = 0
			}
			return
		}
		b.ring.Read(out)
	})
	if err != nil {
		inStream.Close()
		return fmt.Errorf("open output stream: %w", err)
	}

	if err := inStream.Start(); err != nil {
		inStream.Close()
		outStream.Close()
		return fmt.Errorf("start input stream: %w", err)
	}
	if err := outStream.Start(); err != nil {
		inStream.Close()
		outStream.Close()
		return fmt.Errorf("start output stream: %w", err)
	}

	b.inputStream = inStream
	b.outputStream = outStream
	return nil
}

func (b *AudioBridge) Pause() {
	b.mu.Lock()
	b.paused = true
	b.mu.Unlock()
}

func (b *AudioBridge) Resume() {
	b.mu.Lock()
	b.paused = false
	b.mu.Unlock()
}

func (b *AudioBridge) Close() {
	b.mu.Lock()
	defer b.mu.Unlock()

	if b.inputStream != nil {
		b.inputStream.Stop()
		b.inputStream.Close()
		b.inputStream = nil
	}
	if b.outputStream != nil {
		b.outputStream.Stop()
		b.outputStream.Close()
		b.outputStream = nil
	}
	portaudio.Terminate()
}

func findDevice(name string, isInput bool) (*portaudio.DeviceInfo, error) {
	if name == "" {
		if isInput {
			return portaudio.DefaultInputDevice()
		}
		return portaudio.DefaultOutputDevice()
	}

	devices, err := portaudio.Devices()
	if err != nil {
		return nil, err
	}

	for _, dev := range devices {
		if !strings.Contains(dev.Name, name) {
			continue
		}
		if isInput && dev.MaxInputChannels > 0 {
			return dev, nil
		}
		if !isInput && dev.MaxOutputChannels > 0 {
			return dev, nil
		}
	}

	return nil, fmt.Errorf("no %s device matching %q found", map[bool]string{true: "input", false: "output"}[isInput], name)
}

var _ = unsafe.Sizeof(0)
