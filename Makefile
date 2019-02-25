EXECUTABLE_NAME = templar
REPO = https://github.com/SpectralDragon/Templar/tree/master
VERSION = 1.0.0

PREFIX = /usr/local
INSTALL_PATH = $(PREFIX)/bin/$(EXECUTABLE_NAME)
BUILD_PATH = .build/release/$(EXECUTABLE_NAME)
CURRENT_PATH = $(PWD)
RELEASE_TAR = $(REPO)/archive/$(VERSION).tar.gz

.PHONY: install build uninstall publish release

install: build
	mkdir -p $(PREFIX)/bin
	cp -f $(BUILD_PATH) $(INSTALL_PATH)

build:
	swift build --disable-sandbox -c release -Xswiftc -static-stdlib

uninstall:
	rm -f $(INSTALL_PATH)

publish: zip_binary bump_brew
	echo "published $(VERSION)"

bump_brew:
	brew update
	brew bump-formula-pr --url=$(RELEASE_TAR) templar

zip_binary: build
	zip -j $(EXECUTABLE_NAME).zip $(BUILD_PATH)

release:
	sed -i '' 's|\(static let version = "\)\(.*\)\("\)|\1$(VERSION)\3|' Sources/templar/main.swift

	git add .
	git commit -m "Update to $(VERSION)"
	git tag $(VERSION)