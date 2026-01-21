from inetboxapp import InetboxApp
from enum import Enum


class WaterTemp(Enum):
    Off = 0
    Eco = 40
    High = 60
    Boost = 200


class EnergyMix(Enum):
    gas = "gas"
    mix = "mix"
    electricity = "electricity"


class ElectricPowerLevel(Enum):
    Off = 0
    El1 = 900
    El2 = 1800


class HeatingMode(Enum):
    Off = "off"
    Eco = "eco"
    High = "high"


class AirconOperatingMode(Enum):
    Off = "off"
    Vent = "vent"
    Cool = "cool"
    Hot = "hot"
    Auto = "auto"


class AirconVentMode(Enum):
    Low = "low"
    Medium = "mid"
    High = "high"
    Night = "night"
    Auto = "auto"


class Inetbox:

    def __init__(self, app: InetboxApp):
        self.app = app

    def get_alive(self):
        return self.app.get_status("alive")

    def get_target_room_temp(self):
        return self.app.get_status("target_temp_room")

    def get_target_water_temp(self):
        return self.app.get_status("target_temp_water")

    def get_energy_mix(self) -> str:
        return self.app.get_status("energy_mix")

    def get_electric_power_level(self) -> str:
        return self.app.get_status("electric_power_level")

    def get_heating_mode(self) -> str:
        return self.app.get_status("heating_mode")

    def get_aircon_operating_mode(self) -> str:
        return self.app.get_status("aircon_operating_mode")

    def get_aircon_vent_mode(self) -> str:
        return self.app.get_status("aircon_vent_mode")

    def get_aircon_temp(self) -> float:
        return self.app.get_status("target_temp_aircon")

    def get_room_temp(self) -> float:
        return self.app.get_status("current_temp_room")

    def get_water_temp(self) -> float:
        return self.app.get_status("current_temp_water")

    # TRUMA heater operation-mode (0,1 = off / 7 = running)
    def get_operating_mode(self) -> str:
        return self.app.get_status("operating_status")

    # TRUMA error codes
    def get_error_code(self) -> int:
        return self.app.get_status("error_code")

    # Software-Release-No
    def get_release(self) -> str:
        return self.app.get_status("release")

    #########################################################
    # setters
    #########################################################

    # set target room temperature
    # temperature in °C (0, 5-30°C)
    def set_room_temp(self, temperature: float):
        self.app.set_status("target_temp_room", temperature)

    # set target water temperature (= off, eco, high, boost)
    # 0, 40, 60, 200
    def set_water_temp(self, temperature: WaterTemp):
        self.app.set_status("target_temp_water", temperature)

    # set mode of operation
    # gas, mix, electricity
    def set_energy_mix(self, mix: EnergyMix):
        self.app.set_status("energy_mix", mix)

    # set electrical max. consumption
    # 0, 900 (EL1), 1800 (EL2)
    def set_electric_power_level(self, level: ElectricPowerLevel):
        self.app.set_status("el_power_level", level)

    # set fan state (off only accepted, if room heater off)
    # off, eco, high
    def set_heating_mode(self, mode: HeatingMode):
        self.app.set_status("heating_mode", mode)

    # set aircon operating mode
    # off, vent, cool, hot, auto
    def set_aircon_operating_mode(self, mode: AirconOperatingMode):
        self.app.set_status("aircon_operating_mode", mode)

    # set aircon vent mode
    # low, mid, high, night, auto
    def set_aircon_vent_mode(self, mode: AirconVentMode):
        self.app.set_status("aircon_vent_mode", mode)

    # set target aircon temperature
    # temperature in °C (16-30°C)
    def set_aircon_temp(self, temperature: float):
        self.app.set_status("target_temp_aircon", temperature)
