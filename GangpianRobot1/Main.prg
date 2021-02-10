Global String CCDCmdStrs$(10), DeltaRecStrs$(20), CmdRevStr$(100), CmdSend$, MsgSend$, CCDRevStr$(20), CCDCmdSend$
Global Integer TakePhotoFinish, PLC_TiemoRDY, PLC_SimoRDY
Global Boolean MoLeftHave, MoRightHave, TakePhotoCMD
Global Double Delta_X, Delta_Y, Delta_U
Global Preserve Double X_Offset, Y_Offset, U_Offset
Global Preserve Integer ProductType

Function main
	Boolean SiXiamoFlag, TakePhotoFlag
	Trap Emergency Xqt TrapInterruptAbort
	
	Trap Abort Xqt TrapInterruptAbort
	Xqt AllMonitor, NoEmgAbort
	Xqt TcpIpCCDCmdSend, NoEmgAbort
	Fine 250, 250, 250, 250
	Motor On
	Power High
	Speed 50
	Accel 100, 100
	Go Here :Z(-15)
	LimZ -10
	MemOff PLCOUT1
	Select ProductType
		Case 0
			tiemo = tiemo1
		Case 1
			tiemo = tiemo2
	Send

	Do
		Off XiaJiaZhua
		Call PickMofromFeed
		
		SiXiamoFlag = SiXiamoProcess
		MemOn PLCOUT4
		If SiXiamoFlag Then
			TakePhotoFlag = TakePhotoProcess
			If TakePhotoFlag Then
				Call TiejiaoProcess
				
				Call SiShangmoProcess
			Else
				Print "����ʧ��"
				MsgSend$ = "����ʧ��"
				Go Here +Z(20)
				Pause
				Jump sixiamo4
				Off Suck
				On Blow
				Wait 1
			EndIf
		Else
			Print "˺��Ĥʧ��"
			MsgSend$ = "˺��Ĥʧ��"
			Pause
			Off Suck
			Off XiaJiaZhua
			
		EndIf
		MemOff PLCOUT4
	Loop
Fend
Function TrapInterruptAbort
	MemOut 11, 0
	MemOut 12, 0
	MemOut 13, 0
	MemOut 14, 0
	Out 0, 0, Forced
	Out 1, 0, Forced
	PLC_TiemoRDY = 0
	PLC_SimoRDY = 0
Fend
Function AllMonitor
	Integer m0, m1, m2, m3
	m0 = 0; m1 = 0; m2 = 0; m3 = 0
	Do
		If m2 <> MemSw(PLCIN2) Then
			m2 = MemSw(PLCIN2)
			If m2 = 1 Then
				PLC_TiemoRDY = 1
			Else
				MemOff PLCOUT2
			EndIf
		EndIf
		If m3 <> MemSw(PLCIN3) Then
			m3 = MemSw(PLCIN3)
			If m3 = 1 Then
				PLC_SimoRDY = 1
			Else
				MemOff PLCOUT3
			EndIf
		EndIf
	Loop
Fend
Function PickMofromFeed
	Integer ii
	Jump ximoWaitP1
PickMofromFeedlabel1:
	MemOff PLCOUT0
	If MemSw(PLCIN0) = 1 Then
		Go ximo1 +Z(16)
		On Suck
		Off Blow
		Go ximo1
		Wait 0.5
		Speed 60
		Go ximo1 +Z(9)
		Go ximo1 +Z(9) -X(3)
		Go ximo1 +Z(30) -X(3)
		
		For ii = 0 To 2
			Wait 0.1
			Go ximo1 +Z(10)
			Wait 0.1
			Go ximo1 +Z(30)
		Next
		Wait 1
		If Sw(VoccumValue) = 1 Then
'			Go ximoWaitP1
			MemOn PLCOUT0
			Go ximo1 :Z(-15)
		Else
			Print "���Ĥ��ȡʧ��"
			MsgSend$ = "���Ĥ��ȡʧ��"
			MemOn PLCOUT0
			Pass ximo1 +Z(16)
			Go ximoWaitP1
			Pause
			
			GoTo PickMofromFeedlabel1
		EndIf
		Speed 50
	ElseIf MemSw(PLCIN1) = 1 Then
		Go ximo2 +Z(16)
		On Suck
		Off Blow
		Go ximo2
		Wait 0.5
		Speed 60
		Go ximo2 +Z(9)
		Go ximo2 +Z(9) -X(3)
		Go ximo2 +Z(30) -X(3)
		For ii = 0 To 2
			Wait 0.1
			Go ximo2 +Z(10)
			Wait 0.1
			Go ximo2 +Z(30)
		Next
		Wait 1
		If Sw(VoccumValue) = 1 Then
'			Go ximoWaitP1
			MemOn PLCOUT0
			Go ximo2 :Z(-15)
		Else
			Print "�Ҳ�Ĥ��ȡʧ��"
			MsgSend$ = "�Ҳ�Ĥ��ȡʧ��"
			MemOn PLCOUT0
			Pass ximo2 +Z(16)
			Go ximoWaitP1
			Pause
			
			GoTo PickMofromFeedlabel1
		EndIf
		Speed 50
	Else
		Print "Ĥȱ��"
		Wait MemSw(PLCIN0) = 1 Or MemSw(PLCIN1) = 1
		GoTo PickMofromFeedlabel1
	EndIf
Fend
Function SiXiamoProcess As Boolean
	Jump sixiamo2 '��ʼλ
	Go sixiamo1 '��צ��
	On XiaJiaZhua
	Wait 1
	Speed 40
	Go Here +Z(5)
	Move Here +Z(10) -X(20)
	Move sixiamo5 '˺Ĥ��һ��
	Go sixiamo3 '˺Ĥ�ڶ���
'	Go sixiamo4
	Speed 50
	
	If Sw(VoccumValue) = 1 Then
		SiXiamoProcess = True
	Else
		SiXiamoProcess = False
	EndIf
Fend
Function TakePhotoProcess As Boolean
	Jump paizhao
	
TakePhotoProcessLabel1:
'0:Finish
'1:Error
	On Light
	Wait 0.5
	TakePhotoFinish = -1
	CCDCmdSend$ = "TMCAMERA"
	Wait TakePhotoFinish = 0 Or TakePhotoFinish = 1, 10
	If TakePhotoFinish = -1 Then
		GoTo TakePhotoProcessLabel1
	Else
		If TakePhotoFinish = 0 Then
			TakePhotoProcess = True
		Else
			TakePhotoProcess = False
		EndIf
	EndIf
	Off Light
'	TakePhotoProcess = True
Fend
Function TiejiaoProcess
	If PLC_TiemoRDY <> 1 Then
		Sense MemSw(99) = 0
		Jump tiemo Sense
		Off XiaJiaZhua
		Wait PLC_TiemoRDY = 1
	EndIf
	PLC_TiemoRDY = 0
	MemOff PLCOUT2
	Jump tiemo -X(Delta_X - X_Offset) -Y(Delta_Y - Y_Offset) +U(Delta_U + U_Offset)
	Off XiaJiaZhua
	Wait 0.5
	Off Suck; On Blow
	Wait 0.5
	Off Blow
	Sense MemSw(99) = 0
	Jump tiemo -X(Delta_X) -Y(Delta_Y) +U(Delta_U) Sense
	MemOn PLCOUT2
	Wait MemSw(PLCIN2) = 0
	MemOff PLCOUT2
Fend
Function SiShangmoProcess
	Integer ii
'	If PLC_SimoRDY <> 1 Then
'		Sense MemSw(99) = 0
'		Jump simo Sense
'		Wait PLC_SimoRDY = 1
'	EndIf
	Jump simop3
	Wait PLC_SimoRDY = 1
	MemOff PLCOUT3
	PLC_SimoRDY = 0
	On DingZhen
	Wait 0.5
	Go simo
	On ShangJiaZhua
	Wait 0.5
	Off DingZhen
	Speed 3 '˺Ĥ�ٶ�
	Wait 1
'	For ii = 0 To 5
'		Go simoP1
'		Wait 0.1
'		Go simo
'		Wait 0.1
'	Next
	Pass simoP1
	Pass simoP2
	Pass simop4
	MemOn PLCOUT3
	Wait MemSw(PLCIN3) = 0
	MemOff PLCOUT3
	Speed 10
	Jump simop5
	Wait 1

	Off ShangJiaZhua
	On Blow
	Wait 1.5
	Off Blow
	Wait 1
Fend
Function bgmain
	Xqt DeltaCommunitation
	Xqt TcpIpCmdRev
	Xqt TcpIpCmdSend
	Xqt TcpIpMsgSend
Fend
Function main2
	Integer chknet2, errTask
	Double DeltaX, DeltaY, DeltaU
	String CCDCmdStr$
	Motor On
	Power High
	Speed 30
	OpenNet #215 As Client
	Print "�˿�215��"
	WaitNet #215
	Print "�˿�215����"
	Do
		OnErr GoTo NetErr
		chknet2 = ChkNet(215)
		If chknet2 >= 0 Then


			Input #215, CCDCmdStr$
			If Len(CCDCmdStr$) > 0 Then
				Print "CCDCmdStr$�յ��� " + CCDCmdStr$
				StringSplit(CCDCmdStr$, ";")
				Select CCDCmdStrs$(0)
					Case "CAL"
						Jump paizhao
'						Print #215, "OK"
					Case "CMD"
						DeltaX = Val(CCDCmdStrs$(1))
						DeltaY = Val(CCDCmdStrs$(2))
						DeltaU = Val(CCDCmdStrs$(3))
						Go paizhao +X(DeltaX) +Y(DeltaY) +U(DeltaU)
'						Print #215, "OK"
				Send
			EndIf



		Else
			CloseNet #215
			Print "�˿�215�ر�"
			Wait 0.1
			OpenNet #215 As Client
			Print "�˿�215���´�"
			WaitNet #215
			Print "�˿�215��������"
		EndIf
	Loop
	 
	NetErr:
		Print "The Error code is ", Err
		Print "The Error Message is ", ErrMsg$(Err, LANGID_SIMPLIFIED_CHINESE)
		errTask = Ert
		If errTask > 0 Then
			Print "Task number in which error occurred is ", errTask
			Print "The line where the error occurred is Line ", Erl(errTask)
			If Era(errTask) > 0 Then
				Print "Joint which caused the error is ", Era(errTask)
			EndIf
		EndIf
		EResume Next
Fend
'�ַ����ָ�
Function StringSplit(StrSplit$ As String, CharSelect$ As String)
	Integer findstr, i
	String RemainStr$
	RemainStr$ = StrSplit$
	i = 0
	findstr = InStr(RemainStr$, CharSelect$)
	Do While findstr <> -1
		CCDCmdStrs$(i) = Mid$(RemainStr$, 1, findstr - 1)
		RemainStr$ = Mid$(RemainStr$, findstr + 1)
		i = i + 1
		findstr = InStr(RemainStr$, CharSelect$)
	Loop
	CCDCmdStrs$(i) = RemainStr$
Fend
Function DeltaCommunitation
	Integer chknet2, errTask, i
	String DeltaRecStr$, DelatSendStr$;
	OpenNet #202 As Server
	Print "�˿�202��"
	WaitNet #202
	Print "�˿�202����"
	Do
		OnErr GoTo NetErr
		chknet2 = ChkNet(202)
		If chknet2 >= 0 Then
			Input #202, DeltaRecStr$
'			Print "DeltaRecStr$�յ��� " + DeltaRecStr$ + " �ַ�������Ϊ " + Str$(Len(DeltaRecStr$))
			If Len(DeltaRecStr$) = 18 Then
				StringSplit1(DeltaRecStr$, ";")
				For i = 0 To 8
					If DeltaRecStrs$(i) = "1" Then
						MemOn 100 + i
					ElseIf DeltaRecStrs$(i) = "0" Then
						MemOff 100 + i
					EndIf
				Next
				DelatSendStr$ = ""
				For i = 0 To 8
					If MemSw(110 + i) = 1 Then
						DelatSendStr$ = DelatSendStr$ + "1;"
					Else
						DelatSendStr$ = DelatSendStr$ + "0;"
					EndIf
				Next
				Print #202, DelatSendStr$
'				Print "DelatSendStr$���ͣ� " + DelatSendStr$
			EndIf
			

		Else
			CloseNet #202
			Print "�˿�202�ر�"
			Wait 0.1
			OpenNet #202 As Server
			Print "�˿�202���´�"
			WaitNet #202
			Print "�˿�202��������"
		EndIf
	Loop
	 
	NetErr:
		Print "The Error code is ", Err
		Print "The Error Message is ", ErrMsg$(Err, LANGID_SIMPLIFIED_CHINESE)
		errTask = Ert
		If errTask > 0 Then
			Print "Task number in which error occurred is ", errTask
			Print "The line where the error occurred is Line ", Erl(errTask)
			If Era(errTask) > 0 Then
				Print "Joint which caused the error is ", Era(errTask)
			EndIf
		EndIf
		EResume Next
Fend
Function StringSplit1(StrSplit$ As String, CharSelect$ As String)
	Integer findstr, i
	String RemainStr$
	RemainStr$ = StrSplit$
	i = 0
	findstr = InStr(RemainStr$, CharSelect$)
	Do While findstr <> -1
		DeltaRecStrs$(i) = Mid$(RemainStr$, 1, findstr - 1)
		RemainStr$ = Mid$(RemainStr$, findstr + 1)
		i = i + 1
		findstr = InStr(RemainStr$, CharSelect$)
	Loop
	DeltaRecStrs$(i) = RemainStr$
Fend
'������λ��������
Function TcpIpCmdRev
	Integer chknet1, errTask, i;
	String CmdRev$
	OpenNet #208 As Server
	Print "�˿�208��"
	WaitNet #208
	Print "�˿�208����"
	Do
		OnErr GoTo NetErr
		chknet1 = ChkNet(208)
		If chknet1 >= 0 Then
			Input #208, CmdRev$
			Print "CmdRev$�յ��� " + CmdRev$
			CmdRevStr$(0) = ""
			StringSplit2(CmdRev$, ";")
			Select CmdRevStr$(0)
				Case "R1Offset"
				
					X_Offset = Val(CmdRevStr$(1))

				
					Y_Offset = Val(CmdRevStr$(2))
			
			
					U_Offset = Val(CmdRevStr$(3))
				Default
					
			Send
			CmdRev$ = ""
		Else
			CloseNet #208
			Print "�˿�208�ر�"
			Wait 0.1
			OpenNet #208 As Server
			Print "�˿�208���´�"
			WaitNet #208
			Print "�˿�208��������"
		EndIf
	Loop
	 
	NetErr:
		Print "The Error code is ", Err
		Print "The Error Message is ", ErrMsg$(Err, LANGID_SIMPLIFIED_CHINESE)
		errTask = Ert
		If errTask > 0 Then
			Print "Task number in which error occurred is ", errTask
			Print "The line where the error occurred is Line ", Erl(errTask)
			If Era(errTask) > 0 Then
				Print "Joint which caused the error is ", Era(errTask)
			EndIf
		EndIf
		EResume Next
Fend
Function StringSplit2(StrSplit$ As String, CharSelect$ As String)
	Integer findstr, i
	String RemainStr$
	RemainStr$ = StrSplit$
	i = 0
	findstr = InStr(RemainStr$, CharSelect$)
	Do While findstr <> -1
		CmdRevStr$(i) = Mid$(RemainStr$, 1, findstr - 1)
		RemainStr$ = Mid$(RemainStr$, findstr + 1)
		i = i + 1
		findstr = InStr(RemainStr$, CharSelect$)
	Loop
	CmdRevStr$(i) = RemainStr$
Fend
'���������λ��
Function TcpIpCmdSend
	Integer chknet2, errTask
	OpenNet #209 As Server
	Print "�˿�209��"
	WaitNet #209
	Print "�˿�209����"
	Do
		OnErr GoTo NetErr
		chknet2 = ChkNet(209)
		If chknet2 >= 0 Then
			If CmdSend$ <> "" Then
				Print #209, CmdSend$
				Print "CmdSend$�� " + CmdSend$
				CmdSend$ = ""
			EndIf
		Else
			CloseNet #209
			Print "�˿�202�ر�"
			Wait 0.1
			OpenNet #209 As Server
			Print "�˿�209���´�"
			WaitNet #209
			Print "�˿�209��������"
		EndIf
	Loop
	 
	NetErr:
		Print "The Error code is ", Err
		Print "The Error Message is ", ErrMsg$(Err, LANGID_SIMPLIFIED_CHINESE)
		errTask = Ert
		If errTask > 0 Then
			Print "Task number in which error occurred is ", errTask
			Print "The line where the error occurred is Line ", Erl(errTask)
			If Era(errTask) > 0 Then
				Print "Joint which caused the error is ", Era(errTask)
			EndIf
		EndIf
		EResume Next
Fend
'������Ϣ����λ��
Function TcpIpMsgSend
	Integer chknet4, errTask
	OpenNet #210 As Server
	Print "�˿�210��"
	WaitNet #210
	Print "�˿�210����"
	Do
		OnErr GoTo NetErr
		chknet4 = ChkNet(210)
		If chknet4 >= 0 Then
			If MsgSend$ <> "" Then
				Print #210, MsgSend$
				Print "MsgSend$: " + MsgSend$
				MsgSend$ = ""
			EndIf
		Else
			CloseNet #210
			Print "�˿�210�ر�"
			Wait 0.1
			OpenNet #210 As Server
			Print "�˿�210���´�"
			WaitNet #210
			Print "�˿�210��������"
		EndIf
	Loop
	 
	NetErr:
		Print "The Error code is ", Err
		Print "The Error Message is ", ErrMsg$(Err, LANGID_SIMPLIFIED_CHINESE)
		errTask = Ert
		If errTask > 0 Then
			Print "Task number in which error occurred is ", errTask
			Print "The line where the error occurred is Line ", Erl(errTask)
			If Era(errTask) > 0 Then
				Print "Joint which caused the error is ", Era(errTask)
			EndIf
		EndIf
		EResume Next
Fend
'���������λ��
Function TcpIpCCDCmdSend
	Integer chknet2, errTask, strnum, i
	String CCDRev$
	OpenNet #215 As Client
	Print "�˿�215��"
	WaitNet #215
	Print "�˿�215����"
	Do
		OnErr GoTo NetErr
		chknet2 = ChkNet(215)
		If chknet2 >= 0 Then
			If CCDCmdSend$ <> "" Then
				Print #215, CCDCmdSend$
				Print "CCDCmdSend$: " + CCDCmdSend$
				CCDCmdSend$ = ""
				Input #215, CCDRev$
				If Len(CCDRev$) > 0 Then
					Print "CCDRev$: " + CCDRev$
					strnum = StringSplit3(CCDRev$, ";")
					If strnum = 4 And CCDRevStr$(0) = "CMD" Then
						
						Delta_X = Val(CCDRevStr$(1))
						Delta_Y = Val(CCDRevStr$(2))
						Delta_U = Val(CCDRevStr$(3))
						ProductType = Val(CCDRevStr$(4))
						Select ProductType
		                   Case 0
			                     tiemo = tiemo1
		                   Case 1
		                         tiemo = tiemo2
	                    Send

						If Delta_X > 5 Or Delta_X < -5 Or Delta_Y > 3 Or Delta_Y < -3 Or Delta_U > 2 Or Delta_U < -2 Then
							TakePhotoFinish = 1
						Else
							TakePhotoFinish = 0
						EndIf
						
					ElseIf CCDRevStr$(0) = "ERROR" Then
						
						TakePhotoFinish = 1
					EndIf
				EndIf
				CCDRev$ = ""
			EndIf
		Else
			CloseNet #215
			Print "�˿�215�ر�"
			Wait 0.1
			OpenNet #215 As Client
			Print "�˿�215���´�"
			WaitNet #215
			Print "�˿�215��������"
		EndIf
	Loop
	 
	NetErr:
		Print "The Error code is ", Err
		Print "The Error Message is ", ErrMsg$(Err, LANGID_SIMPLIFIED_CHINESE)
		errTask = Ert
		If errTask > 0 Then
			Print "Task number in which error occurred is ", errTask
			Print "The line where the error occurred is Line ", Erl(errTask)
			If Era(errTask) > 0 Then
				Print "Joint which caused the error is ", Era(errTask)
			EndIf
		EndIf
		EResume Next
Fend
Function StringSplit3(StrSplit$ As String, CharSelect$ As String) As Integer
	Integer findstr, i
	String RemainStr$
	RemainStr$ = StrSplit$
	i = 0
	findstr = InStr(RemainStr$, CharSelect$)
	Do While findstr <> -1
		CCDRevStr$(i) = Mid$(RemainStr$, 1, findstr - 1)
		RemainStr$ = Mid$(RemainStr$, findstr + 1)
		i = i + 1
		findstr = InStr(RemainStr$, CharSelect$)
	Loop
	CCDRevStr$(i) = RemainStr$
	StringSplit3 = i
Fend


