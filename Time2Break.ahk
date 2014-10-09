#NoEnv
#SingleInstance force
; #Include Gdip.ahk	;if you do not have it in your lib. Uncomment this line.
SetWorkingDir %A_ScriptDir%
; SetBatchLines, -1

If !pToken := Gdip_Startup(){
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}
OnExit, Exit

healthTimeUpLimit:=4500 ;健康时间上限
healthTimeSet:=3600	;健康时间设定
healthTimeDownLimit:=-1800
StatuOld:="resting"
restJudge:=45000	;休息判定(ms)

transparence:=63	;遮罩透明度

eventQueue:=Array()

TimeNow:=healthTimeSet	; 当前所在时间点
; TimeNow:=-1
StatuNow:="active"	; 当前状态[active][resting]
StatuHealth:="health"
; 休息时间设定
; 恢复至设定的健康时间所需休息的时间(从0健康时间起算)
restTimeSet:=300

recoverTime:=healthTimeSet//restTimeSet	; 每休息单位时间所恢复的健康时间

; 在健康时间为负数时，恢复健康时间的速率
unhealthMutil:=0.6	;非健康时间倍率

SetTimer, poll, -1
SetTimer, oneSec, 1000

freq:=0
DllCall("QueryPerformanceFrequency", "Int64P", freq)

gui1W:=A_ScreenWidth
gui1H:=A_ScreenHeight

Gui, 1:-Caption +hwndhgui1 +E0x80000 +E0x20 +AlwaysOnTop +Owner
Gui, 1:Show, x0 y0 w%gui1W% h%gui1H% NA

Gui, 2:-Caption +hwndhgui2 +E0x80000 +E0x20 +AlwaysOnTop +Owner
Gui, 2:Show, x10 y10 w200 h123 NA


hbm1 := CreateDIBSection(gui1W, gui1H)
hdc1 := CreateCompatibleDC()
obm1 := SelectObject(hdc1, hbm1)
G1:=Gdip_GraphicsFromHDC(hdc1)
Gdip_SetSmoothingMode(G1, 4)


hBackbm1 := CreateDIBSection(gui1W, gui1H)
hBackDC1 := CreateCompatibleDC()
oBackbm1 := SelectObject(hBackDC1, hBackbm1)
GBack1:=Gdip_GraphicsFromHDC(hBackDC1)
Gdip_SetCompositingMode(GBack1, 1)

Gdip_FillRectangleWithColor(GBack1, transparence<<24, 0, 0, gui1W, gui1H)
Bitblt(hdc1,0, 0,gui1W,gui1H,hBackDC1,0,0)
displayTxt("劳憩有度")

UpdateLayeredWindow(hgui1, hdc1, ,,,,255)

Sleep, 1000

Return

; Esc::
Exit:
Gdip_Shutdown(pToken)
ExitApp

poll:
while(eventQueue.maxIndex()>0)
{
	eventQueue[1].()
	eventQueue.Remove(1)
}
SetTimer, poll, -50
Return

oneSec:
if(A_TimeIdlePhysical>restJudge){
	StatuNow:="resting"
}Else{
	StatuNow:="active"
}

if(StatuNow="active"){
	if(TimeNow>healthTimeDownLimit)
		TimeNow-=1
	Else if(A_Sec=1 or A_sec=2)
		SoundBeep, 240, 400
	if(TimeNow<0)
		eventQueue.Insert(func("displayUpdate"))
	Else if(StatuOld="resting" and StatuNow="active")
		eventQueue.Insert(func("displayClear"))
}else if(StatuNow="resting"){
	if(TimeNow<0){
		TimeNow+=recoverTime*unhealthMutil
	}else if(TimeNow<healthTimeUpLimit){
		TimeNow+=recoverTime
	}
	if(TimeNow<healthTimeUpLimit)
		eventQueue.Insert(func("displayUpdate"))
}
StatuOld:=StatuNow
Return



displayUpdate()
{
	global
	if(TimeNow<0){
		if(transparence!=50+(170*TimeNow)//healthTimeDownLimit)	;需更新透明度
		{
			transparence:=50+(170*TimeNow)//healthTimeDownLimit
			Gdip_FillRectangleWithColor(GBack1, transparence<<24, 0, 0, gui1W, gui1H)
		}
		Bitblt(hdc1,0, 0,gui1W,gui1H,hBackDC1,0,0)
		if(StatuNow="active"){
			if(TimeNow>healthTimeDownLimit)
				displayTxt("请注意休息")
			Else
				displayTxt("**请注意休息**")
		}Else{
			displayTxt("-正在休息-")
		}
		displayTime()
		UpdateLayeredWindow(hgui1, hdc1, ,,,,255)
	}Else if(StatuNow="resting"){
		if(transparence!=0)	;需更新透明度
		{
			transparence:=0
			Gdip_FillRectangleWithColor(GBack1, transparence, 0, 0, gui1W, gui1H)
		}
		Bitblt(hdc1,0, 0,gui1W,gui1H,hBackDC1,0,0)
		displayTxt("-正在休息-")
		displayTime()
		UpdateLayeredWindow(hgui1, hdc1, ,,,,255)
	}
}


Gdip_FillRectangleWithColor(byref G, color, x, y, w, h)
{
	pBrush:=Gdip_BrushCreateSolid(color)
	Gdip_FillRectangle(G, pBrush, x, y, w, h)
	Gdip_DeleteBrush(pBrush)
}


displayTxt(txt)
{
	global G1,rc_h,rc_w
	option:=" center cbbcc0000 Bold r4 s32"
	rc:=Gdip_TextToGraphics(G1, txt, "x0 y0 w100p" option , "Arial",A_ScreenWidth,64,1)
	parseRC(rc)
	Gdip_TextToGraphics(G1, txt, "x" (A_ScreenWidth-rc_w) " y" (A_ScreenHeight-rc_h-80) option, "Arial",rc_w,rc_h)
}


displayTime()
{
	global G1,TimeNow,rc_w,rc_h,healthTimeDownLimit
	option:=" cbbaabbaa Bold r4 s16"
	if(TimeNow>=0){
		txt:="健康时间剩余" Round(TimeNow) "秒"
	} Else if(TimeNow>=healthTimeDownLimit+1){
		if(StatuNow="active")
		txt:="非健康时间已达" Round(-TimeNow) "秒"
		Else
		txt:="非健康时间剩余" Round(-TimeNow) "秒"
	} Else{
		txt:="非健康时间已超过" -healthTimeDownLimit "秒"
	}
	rc:=Gdip_TextToGraphics(G1, txt, "x0 y0 w100p" option , "Arial",A_ScreenWidth,40,1)
	parseRC(rc)
	Gdip_TextToGraphics(G1, txt, "x" (A_ScreenWidth-rc_w) " y" (A_ScreenHeight-rc_h-60) option, "Arial",rc_w,rc_h)
}


displayClear()
{
	global
	Gdip_GraphicsClear(G1)
	UpdateLayeredWindow(hgui1, hdc1, ,,,,255)
}


parseRC(rc)
{
	global rc_w,rc_h
	Loop, Parse, rc, |
	{
		if(A_Index=3)
			rc_w:=A_LoopField
		if(A_Index=4)
			rc_h:=A_LoopField
	}
	rc_w+=0
	rc_h+=0
}

timer(period,_func_)
{
	global freq
	static tic:=0,toc:=0,target,func
	func:=_func_
	target:=period*freq
	
	_timer1_:
	if(toc=0)
		DllCall("QueryPerformanceCounter", "Int64P", tic)
	DllCall("QueryPerformanceCounter", "Int64P", toc)
	timeP:=toc-tic
	if(timeP>=target)
	{
		toc:=0
		func.()
	}
	Else
	{
		temp:=target-timeP
		if(temp>10000000)
		next:=-1000
		else if(temp>5000000)
		next:=-500
		else if(temp>1000000)
		next:=-50
		else if(temp>200000)
		next:=-7
		else
		next:=-1
		SetTimer, _timer1_, % next
	}
	Return
}
