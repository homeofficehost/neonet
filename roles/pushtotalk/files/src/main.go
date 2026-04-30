package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	bridge, err := NewAudioBridge("", "BlackHole")
	if err != nil {
		log.Fatalf("Failed to create audio bridge: %v", err)
	}

	if err := bridge.Start(); err != nil {
		log.Fatalf("Failed to start audio bridge: %v", err)
	}

	fmt.Println("audiobridge: started, waiting for signals")
	fmt.Println("  SIGUSR1 = open bridge (mic ON)")
	fmt.Println("  SIGUSR2 = close bridge (mic OFF)")
	fmt.Println("  SIGTERM/SIGINT = shutdown")

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGUSR1, syscall.SIGUSR2, syscall.SIGTERM, syscall.SIGINT)

	for sig := range sigCh {
		switch sig {
		case syscall.SIGUSR1:
			fmt.Printf("[%s] SIGUSR1 received → opening bridge\n", time.Now().Format("15:04:05"))
			bridge.Resume()
		case syscall.SIGUSR2:
			fmt.Printf("[%s] SIGUSR2 received → closing bridge\n", time.Now().Format("15:04:05"))
			bridge.Pause()
		case syscall.SIGTERM, syscall.SIGINT:
			fmt.Printf("[%s] %s received → shutting down\n", time.Now().Format("15:04:05"), sig)
			bridge.Close()
			os.Exit(0)
		}
	}
}
