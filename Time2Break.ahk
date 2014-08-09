#NoEnv
#SingleInstance force
; #Include Gdip.ahk	;if you do not have it in your lib. Uncomment this line.
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1

If !pToken := Gdip_Startup(){
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}
OnExit, Exit

healthTimeUpLimit:=5400 ;健康时间上限
healthTimeSet:=3600	;健康时间设定
healthTimeDownLimit:=-600


TimeNow:=healthTimeSet	; 当前所在时间点
StatuNow:="active"	; 当前状态[active][resting]
StatuHealth:="health"
; 休息时间设定
; 恢复至设定的健康时间所需休息的时间(从0健康时间起算)
restTimeSet:=300

recoverTime:=healthTimeSet//restTimeSet	; 每休息单位时间所恢复的健康时间

; 在健康时间为负数时，恢复健康时间的速率
unhealthMutil:=0.25	;非健康时间倍率

SetTimer, oneSec, 1000

freq:=0
DllCall("QueryPerformanceFrequency", "Int64P", freq)

gui1W:=A_ScreenWidth
gui1H:=A_ScreenHeight

Gui, 1:-Caption +hwndhgui1 +E0x80000 +E0x20 +AlwaysOnTop
Gui, 1:Show, x0 y0 w%gui1W% h%gui1H% NA

Gui, 2:-Caption +hwndhgui2 +E0x80000 +E0x20 +AlwaysOnTop
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
pBrushBlack:=Gdip_BrushCreateSolid(0x99000000)
Gdip_FillRectangle(GBack1, pBrushBlack, 0, 0, gui1W, gui1H)

Bitblt(hdc1,0, 0,gui1W,gui1H,hBackDC1,0,0)
UpdateLayeredWindow(hgui1, hdc1, ,,,,255)

timer1(5,"tst")

Return

oneSec:
if(A_TimeIdlePhysical>100000)
	StatuNow="resting"
Else
	StatuNow="active"
if(StatuNow="active"){
	if(TimeNow>healthTimeDownLimit)
		TimeNow-=1
}
if(StatuNow="resting"){
	if(TimeNow<0){
		TimeNow+=recoverTime*unhealthMutil
	}else if(TimeNow<healthTimeUpLimit){
		TimeNow+=recoverTime
	}
}

Return

tst()
{
	Msgbox, 123
}

timer1(period,_func_)
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

Esc::
Exit:
Gdip_Shutdown(pToken)
ExitApp

