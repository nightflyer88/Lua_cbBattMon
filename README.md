# LUA CB Battery Monitor

In combination with a central box, this app represents the power supply in a telemetry window. It shows the two batteries with voltage, current, used capacity and battery level in percent. With autoreset function, so that the used capacity in the central box is automatically reset after recharging the batteries.

In combination with an RC switch, a small standby current flows, which can not be measured by the central box. The app now checks the approximate capacity on power-up, using the battery-specific discharge curve, and corrects it down if necessary. This is an additional security after several months of standby, and specifies the display.

In the settings simply select the battery type (LiPo, Li-ion, Nixx) and cell number, as well as the respective sensors for battery 1/2. Under "Device overview > CBOX" at the item "Reset switch Min/Max", select the virtual switch "CB_autoReset (CBr)" so that the central box is automatically reset. It is also possible to set an alarm when the level falls below a defined value.

![screen000](https://raw.githubusercontent.com/nightflyer88/Lua_CbBattMon/master/img/Screen000.bmp)
![screen001](https://raw.githubusercontent.com/nightflyer88/Lua_CbBattMon/master/img/Screen001.bmp)
![screen002](https://raw.githubusercontent.com/nightflyer88/Lua_CbBattMon/master/img/Screen002.bmp)
![screen003](https://raw.githubusercontent.com/nightflyer88/Lua_CbBattMon/master/img/Screen003.bmp)

```
Version history:
V1.1    21.10.18    add LiFePo Battery type, optimize LiPo percent list
V1.0    02.06.18    initial release
```
