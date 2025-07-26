.PHONY : ./services/network-gps ./services/dbus-relay-board ./services/dbus-ne-shunt ./services/test-service ./services/test-install ./feed/package all

none:
	@echo "building none... specify the ipk folder to build"

all: network-gps-build dbus-relay-board-build dbus-ne-shunt-build test-service-build test-install-build package
	@echo "building all targets"

network-gps: network-gps-build package
network-gps-build:
	@echo "building network-gps"
	cd ./feed && opkg-build -o root -g root ../services/network-gps/src ./

dbus-ne-shunt: dbus-ne-shunt-build package
dbus-ne-shunt-build:
	@echo "building dbus-ne-shunt"
	cd ./feed && opkg-build -o root -g root ../services/dbus-ne-shunt/src ./

test-service: test-service-build package
test-service-build:
	@echo "building test-service"
	cd ./feed && opkg-build -o root -g root ../services/test-service/src ./

test-install: test-install-build package
test-install-build:
	@echo "building test-install"
	cd ./feed && opkg-build -o root -g root ../services/test-install/src ./

dbus-relay-board: dbus-relay-board-build package
dbus-relay-board-build:
	@echo "building dbus-relay-board"
	cd ./feed && opkg-build -o root -g root ../services/dbus-relay-board/src ./

package:
	@echo "building package index"
	cd ./feed && opkg-make-index ./ -p Packages


