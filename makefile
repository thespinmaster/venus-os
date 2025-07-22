.PHONY : ./services/virtual-gps ./services/dbus-relay-board ./services/dbus-ne-shunt ./services/test-service ./services/test-install ./feed/package all


none:
	@echo "building none... specify the ipk folder to build"

all: virtual-gps1 dbus-relay-board1 dbus-ne-shunt1 test-service1 test-install1 package
	@echo "building all targets"

virtual-gps: virtual-gps1 package
virtual-gps1:
	@echo "building virtual-gps"
	cd ./feed && opkg-build -o root -g root ../services/virtual-gps ./

dbus-ne-shunt: dbus-ne-shunt package
dbus-ne-shunt1:
	@echo "building dbus-ne-shunt"
	cd ./feed && opkg-build -o root -g root ../services/dbus-ne-shunt ./

test-service: test-service1 package
test-service1:
	@echo "building test-service"
	cd ./feed && opkg-build -o root -g root ../services/test-service/test-service ./

test-install: test-install1 package
test-install1:
	@echo "building test-install"
	cd ./feed && opkg-build -o root -g root ../services/test-install/src ./

dbus-relay-board: dbus-relay-board1 package
dbus-relay-board1:
	@echo "building dbus-relay-board"
	cd ./feed && opkg-build -o root -g root ../services/dbus-relay-board ./

package:
	@echo "building package index"
	cd ./feed && opkg-make-index ./ -p Packages


