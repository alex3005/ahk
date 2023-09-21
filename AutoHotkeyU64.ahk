;version 9/15/23
;PACS: NB
;Computer:  NB IR 
;Capture2Text should be set to Y clipboard N popup
;Capture2Text must be within the Autohotkey working directory
;In OCR1, set the whitelist to enabled:  0123456789./



^!r::reload
^!e::edit
^!x::exitapp
SetTitleMatchMode, 1
SetTitleMatchMode, slow
DetectHiddenWindows On
init_this_file() {
    static _ := init_this_file()
	Run, %A_WorkingDir%\Capture2Text\Capture2Text.exe
	SoundBeep
Return
}





^!d::
	Capturectdi()
	Return

^!c::   ;capture ctdi and dose
	Capturectdi()
	Capturedose()
	Return

WheelRight::   ;capture ctdi and dose
	Capturectdi()
	Capturedose()
	Return

RButton::   ;double right copy script
	ifWinNotActive Nuance
	{
	send {RButton}
	Return
	}

	if RButtonCount > 0 ; SetTimer already started, so we log the keypress instead.
	{
	RButtonCount += 1
	return
	}
	RButtonCount = 1
	SetTimer, TimerRButton, 300 ; Wait for more presses within a 500 millisecond window.
return

TimerRButton:    ;double right copy script
	SetTimer, TimerRButton, off
	if (RButtonCount > 1)
	{
	T := !T
	If T
	{
	Send ^c
	SoundPlay, *48
	ToolTip, copied
	}
	else
	{
	Send ^v
	ToolTip, 
	SoundPlay, *16
	}
	}
else
	Send {RButton}
	RButtonCount = 0
return



WheelLeft::
	if WheelLeftCount > 0 ; SetTimer already started, so we log the keypress instead.
	{
	WheelLeftCount += 1
	return
	}
	WheelLeftCount = 1
	SetTimer, TimerWheelLeft, 500 ; Wait for more presses within a 500 millisecond window.
	return

TimerWheelLeft:
	SetTimer, TimerWheelLeft, off
	if WheelLeftCount > 1
	Capturecomparison()
	WheelLeftCount = 0
return



!c::
	Capturecomparison()
	Return


MButton::    ;toggle scrolling mode
   Click down
   return

XButton1::   ;next field
	WinActivate Nuance
	Send {tab}
	return

LWin & F3::   ;sign report
	SoundBeep
	WinActivate PowerScribe
	Send {F12}
	return

LWin & F6::
	WinActivate Powerscribe
	Send {tab}
	return

LWin & F4::
	WinActivate Powerscribe
	Send +{tab}
	return

^XButton1::    ;  Control-XB1 = add history
	Sleep, 600
	WinActivate Nuance
	Send hshshs{enter}
	return


!XButton1::   ;  Alt=XB1 = opens prior report
	sleep, 400
	WinWait Philips
	ControlClick, x28 y252, Philips
	ControlClick, x22 y268, Philips
	ControlClick, x19 y282, Philips
	sleep, 500
	WinMove Clinical, , 0, 986, 953, 899
	Return

XButton2::   ;sign report
	SoundBeep
	WinActivate Nuance
	Send {F12}
	return




;====FUNCTIONS===========

;===Initializer,  Dose window has to be a standard height.

PasteThis(text)             ;makes text appear immediately in PS
{
    Static tmp_clip, tmp_clip2
    While, tmp_clip <> tmp_clip2
        Sleep, 10 ;restoration not yet finished
    tmp_clip := ClipboardAll ; preserve Clipboard
    ClipBoard := text
    While, tmp_clip2 <> text        
        tmp_clip2 := ClipBoard ;validate clipboard
    Send, ^v
    SetTimer, restoration, -500
    Return ;don't waste time waiting for restoration
    restoration:
    ClipBoard := tmp_clip ; restore the clipboard
    While, tmp_clip <> tmp_clip2        
        tmp_clip2 := ClipBoardAll ;validate clipboard
    tmp_clip:="", tmp_clip2:=""
    Return
}

OcrString(x1,y1,x2,y2)
{
	CoordMode, Mouse, Screen
	MouseClick, left, x1, y1
	sleep, 100
	Send, #q
	sleep, 100
	MouseClick, left, x2, y2
	sleep, 300
	Max := 0
	Loop, parse, clipboard, `n, `r     ;finds the highest value
	{
		str := StrReplace(A_LoopField, "?", "7")
		str := StrReplace(str, "T", "7")
		str := StrReplace(str, "S", "5")
		str := RegExReplace(str, "[^0-9.]+")
		if str is Number
		if( str > Max)
		Max := str
	}
	Return Max
}


Ocr(x1,y1,x2,y2)
{
	CoordMode, Mouse, Screen
	MouseClick, left, x1, y1
	sleep, 100
	Send, #q
	sleep, 100
	MouseClick, left, x2, y2
	sleep, 300
	Max := 0
	Loop, parse, clipboard, `n, `r     ;finds the highest value
	{
		str := StrReplace(A_LoopField, "?", "7")
		str := StrReplace(str, "T", "7")
		str := StrReplace(str, "S", "5")
		str := RegExReplace(str, "[^0-9.]+")
		if str is Number
		if( str > Max)
		Max := str
	}
	Return Max
}


Capturectdi()
{
	CoordMode, Mouse, Screen
	CoordMode, Pixel, Screen
	WinActivate Philips
	PixelGetColor, PixColor, 1580, 425
	if (PixColor=0x402715)   ; detects if philips report
		Max2 := Ocr(1868, 1130, 2016, 1642)
	else if (PixColor=0x1A100D)    ; SDI VV
		Max2 := Ocr(2209, 1120, 2324, 1183)
	else   ;SDI FF
		Max2 := Ocr(2205, 1314, 2395, 1395)
	WinActivate Nuance
	Send, % Max2
	SoundBeep
	Send {tab}
Return
}

Capturedose()
{
	CoordMode, Mouse, Screen
	CoordMode, Pixel, Screen
	WinActivate Philips
	Sleep, 200
	PixelGetColor, PixColor, 1580, 425
	if (PixColor=0x402715)   ; NBMC / VV
		Max2 := Ocr(1825, 610, 1993, 673)
	else if (PixColor=0x1A100D)   ;  SDI vacaville
		Max2 := Ocr(2212, 760, 2382, 833)
	else   ; SDI FF
		Max2 := Ocr(2205, 1235, 2395, 1395)
	WinActivate Nuance
	Send, % Max2
	SoundBeep
	Send {tab}
Return
}

Capturecomparison()   ; returns the Comparison date of the report
{
	WinWait Philips
	WinGetText, text
	WinActivate Nuance
	Loop, parse, text, `n, `r
	if (A_Index > 30 or Done)
	if (RegExMatch(A_LoopField, ";  Acc") != 0)
{
	Send % SubStr(A_LoopField,1,10)
	Send {Space}
}
	SoundBeep
	Return
}

;====QUICK REPLACE===========


::fcf::
PasteThis("Lung nodules altogether <6 mm in size present.  Per Fleischner criteria: no follow-up is necessary in low risk patients; one year follow-up CT is optional in high risk patients.")
Return

::tstc::
PasteThis("Hypodensities too small to characterize are present.")
Return

::lr2::
PasteThis("Lung-RADS 2: Benign appearance or behavior.  Recommend continued annual screening with low dose CT in 12 months.")
Return

::lr1::
PasteThis("Lung-RADS 1: Negative.  Recommend continued annual screening with low dose CT in 12 months.")
Return
