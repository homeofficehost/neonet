.PHONY: build clean install

BINARY := audiobridge
SRCDIR := $(CURDIR)
BUILDDIR := $(SRCDIR)/build
INSTALLDIR := /usr/local/bin

CGO_CFLAGS := -I/opt/homebrew/include
CGO_LDFLAGS := -L/opt/homebrew/lib -lportaudio

build:
	@mkdir -p $(BUILDDIR)
	CGO_ENABLED=1 CGO_CFLAGS="$(CGO_CFLAGS)" CGO_LDFLAGS="$(CGO_LDFLAGS)" \
		go build -o $(BUILDDIR)/$(BINARY) .
	@echo "Built: $(BUILDDIR)/$(BINARY)"

codesign: build
	codesign --force --sign - --timestamp=none $(BUILDDIR)/$(BINARY)
	@echo "Signed: $(BUILDDIR)/$(BINARY)"

install: codesign
	install -m 755 $(BUILDDIR)/$(BINARY) $(INSTALLDIR)/$(BINARY)
	@echo "Installed: $(INSTALLDIR)/$(BINARY)"

clean:
	rm -rf $(BUILDDIR)
