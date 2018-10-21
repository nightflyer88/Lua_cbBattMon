--[[
    ---------------------------------------------------------
    In combination with a central box, this app represents the 
    power supply in a telemetry window. It shows the two batteries 
    with voltage, current, used capacity and battery level in percent. 
    With autoreset function, so that the used capacity in the 
    central box is automatically reset after recharging the batteries.
    
    User has a possibility to set an alarm with desired point
    with audio-file if desired.
    
    Requires DC/DS-14/16/24 with firmware 4.22 or up.
    ---------------------------------------------------------

    V1.1    21.10.18    add LiFePo Battery type, optimize LiPo percent list
    V1.0    02.06.18    initial release

--]]

-- App version
local cbBattversion="1.1"

----------------------------------------------------------------------
-- Locals for the application
local lang
local cell1_V,cell1_A,cell1_mAh,cell1_Perc=0,0,0,-1
local cell2_V,cell2_A,cell2_mAh,cell2_Perc=0,0,0,-1
local playDone=false
local cellCnt,cellCap,alarmVal,alarmFile=0,0,0,false
local V_sensorBatt1,A_sensorBatt1,mAh_sensorBatt1={},{},{}
local V_sensorBatt2,A_sensorBatt2,mAh_sensorBatt2={},{},{}
local lastVolt1,lastVolt2=0,0
local volt1Reset,volt2Reset=0,0
local cellTyp,voltageDisplay
local percentList={}

----------------------------------------------------------------------
-- Battery type list
local cellTypList={"LiPo","Li-ion","LiFePo","Nixx"}

----------------------------------------------------------------------
-- Table for binding cell-voltage to percentage
local function readPercentList(index)
    if index==1 then        --LiPo
        percentList =                                                
        {
        {3.000, 0},           
        {3.250, 5},
        {3.500, 10},
        {3.675, 15},
        {3.696, 20},
        {3.718, 25},
        {3.737, 30},
        {3.753, 35},
        {3.772, 40},
        {3.789, 45},
        {3.807, 50},
        {3.827, 55},
        {3.850, 60},
        {3.881, 65},
        {3.916, 70},
        {3.948, 75},
        {3.987, 80},
        {4.042, 85},
        {4.085, 90},
        {4.115, 95},
        {4.150, 100}            
        }
    elseif index==2 then    --Li-ion
        percentList =
        {
        {3.250, 0},
        {3.300, 5},
        {3.327, 10},
        {3.355, 15},
        {3.377, 20},
        {3.395, 25},
        {3.435, 30},
        {3.490, 40},
        {3.630, 60},
        {3.755, 75},
        {3.790, 80},
        {3.840, 85},
        {3.870, 90},
        {3.915, 95},
        {4.050, 100}
        }
    elseif index==3 then    --LiFePo
        percentList =
        {
        {2.80,0},
        {3.06,5},
        {3.14,10},
        {3.17,15},
        {3.19,20},
        {3.20,25},
        {3.21,30},
        {3.22,35},
        {3.23,40},
        {3.24,45},
        {3.25,50},
        {3.25,55},
        {3.26,60},
        {3.26,65},
        {3.27,70},
        {3.28,75},
        {3.28,80},
        {3.29,85},
        {3.29,90},
        {3.29,95},
        {3.30,100}
        }
    elseif index==4 then    --Nixx
        percentList =                                                
        {
        {0.900, 0},           
        {0.970, 5},
        {1.040, 10},
        {1.090, 15},
        {1.120, 20},
        {1.140, 25},
        {1.155, 30},
        {1.175, 40},
        {1.205, 60},
        {1.220, 75},
        {1.230, 80},
        {1.250, 85},
        {1.280, 90},
        {1.330, 95},
        {1.420, 100}            
        }
    end
end

----------------------------------------------------------------------
-- Read translations
local function setLanguage()
    local lng=system.getLocale()
    local file=io.readall("Apps/cbBattMon/cbBattMon.jsn")
    local obj=json.decode(file)
    if(obj) then
        lang=obj[lng] or obj[obj.default]
    end
end

----------------------------------------------------------------------
-- Draw gauge
local function Gauge(ox,oy,cellPerc)
    -- Fuel bar 
    lcd.drawRectangle (ox,53+oy,20,11)
    lcd.drawRectangle (ox,41+oy,20,11)  
    lcd.drawRectangle (ox,29+oy,20,11)  
    lcd.drawRectangle (ox,17+oy,20,11)  
    lcd.drawRectangle (ox,5+oy,20,11)
    -- Bar chart
    if(cellPerc >= 0) then
        if cellPerc > 50 then
            lcd.setColor(0,200,0)  -- green 
        elseif cellPerc > 20 then
            lcd.setColor(255,128,0)  -- orange
        else
            lcd.setColor(200,0,0)  -- red
        end
        local nSolidBar=math.floor(cellPerc / 20)
        local nFracBar=(cellPerc-nSolidBar * 20) / 20
        local i
        -- Solid bars
        for i=0,nSolidBar-1,1 do 
            lcd.drawFilledRectangle (1+ox,54-i*12+oy,18,9) 
        end  
        -- Fractional bar
        local y=math.ceil(54-nSolidBar*12+(1-nFracBar)*9)
        lcd.drawFilledRectangle (1+ox,y+oy,18,9*nFracBar)
        lcd.setColor(0,0,0)  -- black 
    end
end

----------------------------------------------------------------------
-- Draw the telemetry windows
local function dispBatt(width,height)
    -- draw battery 1
    if (cell1_Perc==-1) then
        lcd.drawText(50-lcd.getTextWidth(FONT_BOLD,"-%"),2,"-%",FONT_BOLD)
        else
        lcd.drawText(50-lcd.getTextWidth(FONT_BOLD,string.format("%.0f%%",cell1_Perc)),2,string.format("%.0f%%",cell1_Perc),FONT_BOLD)
        lcd.drawText(50-lcd.getTextWidth(FONT_MINI,string.format("%.0fmAh",cell1_mAh)),23,string.format("%.0fmAh",cell1_mAh),FONT_MINI)  
        lcd.drawText(50-lcd.getTextWidth(FONT_MINI,string.format("%.2fA",cell2_A)),53,string.format("%.2fA",cell1_A),FONT_MINI)    
        if voltageDisplay==1 then
            lcd.drawText(50-lcd.getTextWidth(FONT_MINI,string.format("%.2fV",cell1_V)),38,string.format("%.2fV",cell1_V),FONT_MINI)
        else
            lcd.drawText(50-lcd.getTextWidth(FONT_MINI,string.format("%.2fV",cell1_V*cellCnt)),38,string.format("%.2fV",cell1_V*cellCnt),FONT_MINI)
        end
    end
    Gauge(54,0,cell1_Perc)
    
    -- draw battery 2
    if (cell2_Perc==-1) then
        lcd.drawText(100,2,"-%",FONT_BOLD)
        else
        lcd.drawText(100,2,string.format("%.0f%%",cell2_Perc),FONT_BOLD)
        lcd.drawText(100,23,string.format("%.0fmAh",cell2_mAh),FONT_MINI)
        lcd.drawText(100,53,string.format("%.2fA",cell2_A),FONT_MINI)
        if voltageDisplay==1 then
            lcd.drawText(100,38,string.format("%.2fV",cell2_V),FONT_MINI)
        else
            lcd.drawText(100,38,string.format("%.2fV",cell2_V*cellCnt),FONT_MINI)
        end
    end
    Gauge(76,0,cell2_Perc)
end
----------------------------------------------------------------------
-- Store settings when changed by user
local function sensorChanged_Batt1_V(value)
    V_sensorBatt1[1]=sensorsAvailable[value].id
    V_sensorBatt1[2]=sensorsAvailable[value].param
    V_sensorBatt1[3]=value
    system.pSave("V_batt1",V_sensorBatt1)
end

local function sensorChanged_Batt1_A(value)
    A_sensorBatt1[1]=sensorsAvailable[value].id
    A_sensorBatt1[2]=sensorsAvailable[value].param
    A_sensorBatt1[3]=value
    system.pSave("A_batt1",A_sensorBatt1)
end

local function sensorChanged_Batt1_mAh(value)
    mAh_sensorBatt1[1]=sensorsAvailable[value].id
    mAh_sensorBatt1[2]=sensorsAvailable[value].param
    mAh_sensorBatt1[3]=value
    system.pSave("mAh_batt1",mAh_sensorBatt1)
end

local function sensorChanged_Batt2_V(value)
    V_sensorBatt2[1]=sensorsAvailable[value].id
    V_sensorBatt2[2]=sensorsAvailable[value].param
    V_sensorBatt2[3]=value
    system.pSave("V_batt2",V_sensorBatt2)
end

local function sensorChanged_Batt2_A(value)
    A_sensorBatt2[1]=sensorsAvailable[value].id
    A_sensorBatt2[2]=sensorsAvailable[value].param
    A_sensorBatt2[3]=value
    system.pSave("A_batt2",A_sensorBatt2)
end

local function sensorChanged_Batt2_mAh(value)
    mAh_sensorBatt2[1]=sensorsAvailable[value].id
    mAh_sensorBatt2[2]=sensorsAvailable[value].param
    mAh_sensorBatt2[3]=value
    system.pSave("mAh_batt2",mAh_sensorBatt2)
end

local function cellCntChanged(value)
    cellCnt=value
    system.pSave("cellCnt",cellCnt)
end

local function cellTypChanged(value)
    cellTyp=value
    system.pSave("cellTyp",cellTyp)
    readPercentList(cellTyp)
end

local function cellCapChanged(value)
    cellCap=value
    system.pSave("cellCap",cellCap)
end

local function voltageDisplayChanged(value)
    voltageDisplay=value
    system.pSave("voltageDisplay",voltageDisplay)
end

local function alarmValChanged(value)
    alarmVal=value
    system.pSave("alarmVal",alarmVal)
end

local function alarmFileChanged(value)
    alarmFile=value
    system.pSave("alarmFile",alarmFile)
end

----------------------------------------------------------------------
-- Draw the main form (Application inteface)
local function initForm(subform)
    -- List of Battery display
    local voltageDisplayList={lang.singleCell,lang.totalBattery}
    
    -- List sensors only if menu is active to preserve memory at runtime 
    -- (measured up to 25% save if menu is not opened)
    sensorsAvailable={}
    local sensors=system.getSensors()
    local sensList={}
    local descr=""
    -- Add sensors
    for index,sensor in ipairs(sensors) do 
        if(sensor.param==0) then
            descr=sensor.label
            else
            sensList[#sensList+1]=string.format("%s-%s",descr,sensor.label)
            sensorsAvailable[#sensorsAvailable+1]=sensor
        end
    end
    
    local form,addRow,addLabel=form,form.addRow,form.addLabel
    local addIntbox,addSelectbox=form.addIntbox,form.addSelectbox
    local addInputbox,addCheckbox=form.addInputbox,form.addCheckbox
    local addAudioFilebox,setButton=form.addAudioFilebox,form.setButton
    local addTextbox=form.addTextbox
    
    -- General setting
    addRow(1)
    addLabel({label=lang.labelGeneralSettings,font=FONT_BOLD})
    
    addRow(2)
    addLabel({label=lang.cellCount,width=220})
    addIntbox(cellCnt,0,24,0,0,1,cellCntChanged)
    
    addRow(2)
    addLabel({label=lang.batteryTyp,width=220})
    addSelectbox(cellTypList,cellTyp,true,cellTypChanged)
    
    addRow(2)
    addLabel({label=lang.batteryCapacity})
    addIntbox(cellCap,0,9999,0,0,10,cellCapChanged)
    
    addRow(2)
    addLabel({label=lang.voltageDisplay,width=170})
    addSelectbox(voltageDisplayList,voltageDisplay,false,voltageDisplayChanged)
    
    -- Sensor settings battery 1
    addRow(1)
    addLabel({label=lang.sensorSettingsBatt1,font=FONT_BOLD})
    
    addRow(2)
    addLabel({label=lang.sensor_V})
    addSelectbox(sensList,V_sensorBatt1[3],true,sensorChanged_Batt1_V)
    
    addRow(2)
    addLabel({label=lang.sensor_A})
    addSelectbox(sensList,A_sensorBatt1[3],true,sensorChanged_Batt1_A)
    
    addRow(2)
    addLabel({label=lang.sensor_mAh})
    addSelectbox(sensList,mAh_sensorBatt1[3],true,sensorChanged_Batt1_mAh)
    
    -- Sensor settings battery 2
    addRow(1)
    addLabel({label=lang.sensorSettingsBatt2,font=FONT_BOLD})
    
    addRow(2)
    addLabel({label=lang.sensor_V})
    addSelectbox(sensList,V_sensorBatt2[3],true,sensorChanged_Batt2_V)
    
    addRow(2)
    addLabel({label=lang.sensor_A})
    addSelectbox(sensList,A_sensorBatt2[3],true,sensorChanged_Batt2_A)
    
    addRow(2)
    addLabel({label=lang.sensor_mAh})
    addSelectbox(sensList,mAh_sensorBatt2[3],true,sensorChanged_Batt2_mAh)
    
    -- Alarm settings
    addRow(1)
    addLabel({label=lang.labelAlarm,font=FONT_BOLD})
    
    addRow(2)
    addLabel({label=lang.alarmValue,width=220})
    addIntbox(alarmVal,0,99,0,0,1,alarmValChanged)
    
    addRow(2)
    addLabel({label=lang.voiceFile})
    addAudioFilebox(alarmFile,alarmFileChanged)
    
    addRow(1)
    addLabel({label="Powered by M.Lehmann V"..cbBattversion.." ",font=FONT_MINI,alignRight=true})
end

----------------------------------------------------------------------
-- Count percentage from cell voltage
local function percCell(cellVoltage)
    local result = 0
    local cellfull, cellempty = percentList[#percentList][1], percentList[1][1]
    
    if(cellVoltage >= cellfull)then                                            
      result = 100
    elseif(cellVoltage <= cellempty)then
      result = 0
    else
        for i, v in ipairs(percentList) do     
            -- Interpolate values                             
            if v[ 1 ] >= cellVoltage and i > 1 then
                local lastVal = percentList[i-1]
                result = (cellVoltage - lastVal[1]) / (v[1] - lastVal[1])
                result = result * (v[2] - lastVal[2]) + lastVal[2]
                break
            end
        end
    end
    result = math.modf(result)
    return result
end

----------------------------------------------------------------------
-- Runtime functions,read sensor,convert to percentage
local function loop()
    
    local sensor={}
    sensor=system.getSensorValueByID(V_sensorBatt1[1], V_sensorBatt1[2])
    if(sensor and sensor.valid) then
        cell1_V=sensor.value/cellCnt
        if(cell1_V >= lastVolt1*1.02)then
            volt1Reset=1
            print("1")
        end
    end
    
    sensor=system.getSensorValueByID(A_sensorBatt1[1], A_sensorBatt1[2])
    if(sensor and sensor.valid) then
        cell1_A=sensor.value 
    end
    
    sensor=system.getSensorValueByID(mAh_sensorBatt1[1], mAh_sensorBatt1[2])
    if(sensor and sensor.valid) then
        cell1_mAh=sensor.value 
        cell1_Perc=(1-(cell1_mAh/cellCap))*100
        local tmpCellPerc=percCell(cell1_V)
        if(cell1_Perc-tmpCellPerc>15)then
            cell1_Perc=tmpCellPerc
        end
    end
    
    local sensor=system.getSensorValueByID(V_sensorBatt2[1], V_sensorBatt2[2])
    if(sensor and sensor.valid) then
        cell2_V=sensor.value/cellCnt
        if(cell2_V >= lastVolt2*1.02)then
            volt2Reset=1
            print("2")
        end
    end
    
    sensor=system.getSensorValueByID(A_sensorBatt2[1], A_sensorBatt2[2])
    if(sensor and sensor.valid) then
        cell2_A=sensor.value 
    end
    
    sensor=system.getSensorValueByID(mAh_sensorBatt2[1], mAh_sensorBatt2[2])
    if(sensor and sensor.valid) then
        cell2_mAh=sensor.value 
        cell2_Perc=(1-(cell2_mAh/cellCap))*100
        local tmpCellPerc=percCell(cell2_V)
        if(cell2_Perc-tmpCellPerc>15)then
            cell2_Perc=tmpCellPerc
        end
        
        -- Alarm
        local lowerCellPerc=0
        if(cell1_Perc<cell2_Perc)then
            lowerCellPerc=cell1_Perc
        else
            lowerCellPerc=cell2_Perc
        end

        if(not playDone and alarmVal > 0 and lowerCellPerc <= alarmVal and alarmFile ~= "...") then
            system.playFile(alarmFile,AUDIO_QUEUE)
            system.playNumber(lowerCellPerc,0,"%")
            playDone=true   
        end

        if(lowerCellPerc > alarmVal) then
            playDone=false
        end
    end
    
    if(volt1Reset==1 and volt2Reset==1)then
        -- reset CB
        print("Reset")
        system.setControl(1,1,0)
        volt1Reset=0
        volt2Reset=0
        system.pSave("lastVolt1",(cell1_V*10))
        system.pSave("lastVolt2",(cell2_V*10))
    else
        system.setControl(1,-1,0)
    end
    
    system.pSave("volt1Reset",volt1Reset)
    system.pSave("volt2Reset",volt2Reset)
    
end
----------------------------------------------------------------------
-- Application initialization
local function init()
    local pLoad,registerForm,registerTelemetry=system.pLoad,system.registerForm,system.registerTelemetry
    
    -- read parameters
    V_sensorBatt1=pLoad("V_batt1",{0,0,0})
    A_sensorBatt1=pLoad("A_batt1",{0,0,0})
    mAh_sensorBatt1=pLoad("mAh_batt1",{0,0,0})
    V_sensorBatt2=pLoad("V_batt2",{0,0,0})
    A_sensorBatt2=pLoad("A_batt2",{0,0,0})
    mAh_sensorBatt2=pLoad("mAh_batt2",{0,0,0})
    cellCnt=pLoad("cellCnt",0)
    cellTyp=pLoad("cellTyp",1)
    cellCap=pLoad("cellCap",0)
    readPercentList(cellTyp)
    voltageDisplay=pLoad("voltageDisplay",1)
    alarmVal=pLoad("alarmVal",0)
    alarmFile=pLoad("alarmFile","...")
    
    -- register form
    registerForm(1,MENU_APPS,lang.appName,initForm)
    registerTelemetry(1,lang.appName,2,dispBatt)
    
    -- init CB reset
    system.registerControl(1,"CB_autoReset", "CBr")
    system.setControl(1,-1,0)
    lastVolt1=pLoad("lastVolt1",0)/10
    lastVolt2=pLoad("lastVolt2",0)/10
    volt1Reset=pLoad("volt1Reset",0)
    volt2Reset=pLoad("volt2Reset",0)
end
----------------------------------------------------------------------
setLanguage()
return {init=init,loop=loop,author="M.Lehmann",version=cbBattversion,name=lang.appName}
