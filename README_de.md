# LUA CB Akkumonitor

In Kombination mit einer Central Box stellt diese App die Stromversorgung übersichtlich in einem Telemetriefenster dar. Es werden die beiden Akkus mit Spannung, Strom, entnommene Kapazität, sowie Akkufüllstand in Prozent angezeigt. Mit Autoreset Funktion, damit die verbrauchte Kapazität in der Central Box nach dem nachladen der Akkus automatisch zurückgesetzt wird. 

In Kombination mit einem RC Switch, fliesst ein kleiner Standby Strom der jedoch durch die Central Box nicht gemessen werden kann, die App prüft nun beim einschalten anhand der Akkuspezifischen Entladekurve die ungefähre Kapazität, und korrigiert diese wenn nötig nach unten. Diese ist nach mehreren Monaten Standby eine zusätzliche Sicherheit, und präzisiert die Anzeige.

In den Einstellungen einfach den Akkutyp (LiPo, Li-ion, Nixx) und Zellenzahl auswählen, sowie die jeweiligen Sensoren für Akku 1/2. Unter "Geräteübersicht > CBOX" beim Punkt "Resetschalter Min/Max" den Virtuellen Schalter "CB_autoReset (CBr)" auswählen, damit die Central Box automatischen zurückgesetzt wird. Es besteht auch die Möglichkeit einen Alarm zu setzten wenn der Füllstand einen definierten Wert unterschreitet.

![screen000](https://raw.githubusercontent.com/nightflyer88/Lua_CbBattMon/master/img/Screen000.bmp)
![screen001](https://raw.githubusercontent.com/nightflyer88/Lua_CbBattMon/master/img/Screen001.bmp)
![screen002](https://raw.githubusercontent.com/nightflyer88/Lua_CbBattMon/master/img/Screen002.bmp)
![screen003](https://raw.githubusercontent.com/nightflyer88/Lua_CbBattMon/master/img/Screen003.bmp)

```
Versionen:
V1.1    21.10.18    LiFePo Akkutyp hinzugefügt, LiPo Prozentliste überarbeitet
V1.0    02.06.18    initial release
```
