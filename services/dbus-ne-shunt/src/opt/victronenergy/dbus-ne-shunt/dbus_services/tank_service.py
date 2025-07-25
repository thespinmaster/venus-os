from dbus_base_service import dbus_base_service
from dbus_constants import dbus_constants

class tank_service(dbus_base_service):


    def __init__(self, name, port, fluidType, classAndVrmInstance, capacity):

        self._registerCore(
            port,
            paths =  {
                '/Capacity': {'initial': capacity,'writable': True},
                '/CustomName': {'initial': name,'writable': True},
                '/FluidType': {'initial': fluidType, 'writable': False},
                '/Level': {'initial': 8, 'writable': True},
            },
            classAndVrmInstance = classAndVrmInstance,
            )