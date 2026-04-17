APP     = NetPulse
VERSION = 1.0.0

.PHONY: build run package clean

build:
	swift build -c release

run:
	swift run

package: build
	bash Scripts/package.sh

clean:
	swift package clean
	rm -rf $(APP).app $(APP).dmg AppIcon.icns _dmg_stage
