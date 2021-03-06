REM >Ha bloody ha - the IRClient source!
REM � 1995-7 Matthew Godbolt & Justin Fletcher

REM Version History :
REM v0.01  -  WIMP front-end sorted out
REM v0.02  -  First 'proper' live connection established
REM v0.03  -  Sessions added
REM v0.04  -  Sessions working completely
REM v0.05  -  CTCP begun - PING completed and bugs ironed out (-:
REM v0.06  -  CTCP command implemented, more TCP/IP stack bugs ironed out thanks to neil@sitex
REM v0.07  -  Error handler installed at bloody last!
REM v0.08  -  TOPIC and MODE added, main menu added
REM v0.09  -  More bugs ironed out - BETA version
REM v0.10  -  Yay! Veneers working for PING.  Malc implement METAserver
REM v0.11  -  Metaserver support added.  TOPIC, MODE, LIST, NAMES and KICK implemented properly.
REM v0.12  -  Major overhaul of code, DCC added rather shitely
REM v0.13  -  DCC sped up and bugs removed. MOTD added, /invite, /query and /away done
REM v0.14  -  DCC fixed more, DCC CHAT, IRC_messages and suchforth sorted out.
REM v0.15  -  DCC fixed at fucking last, NAGLE turned off
REM v0.16  -  All OS-corruptions sorted out, ZapRedraw Used

REM v0.17  -  STARTED AGAIN FROM SCRATCH!
REM v0.18  -  Actually started working again
REM v0.19  -  Nearly finished...
REM v0.20  -  zarni redesigns everything....:)
REM v0.21  -  taking shape nicely
REM v0.24  -  Many improvements for Gerph/zarni mostly fixes...
REM v0.25  -  New BASIC bits'n'bobs for more speed, error stuff put in
REM v0.26  -  More bits added to make Gerphy happier
REM v0.27  -  Made Voyager-aware(ish)
REM v0.28  -  StrongARM-compatibility issues addressed, scheduler added in assembler
REM        -  AIF file format
REM v0.29  -  At Gerph's house - lots to be done
REM v0.30  -  FIXED THE NASTY BUG AT LAST!!!!!!!!!!!!!!!!!!!!!!! Loads
REM        -  of menu stuff added, considerations on ADJUST click...
REM v0.31  -  Source code modularised, menu stuff re-written
REM v0.32  -  Shareware nasties added, menus updated more, bugs found,
REM           Memory manager sped up
REM v0.33  -  Bugs fixed
REM v0.34  -  Garbage collecting class system added
REM v0.35  -  Object-orientated methods added
REM           Extensible EEBuffer stack added
REM           Gerphies changes committed to the source (moderated peeps)
REM           Memory manager slowed back down again - pending complete re-write
REM v0.36  -  More Gerph integration, bugs fixed, References noted in connections and
REM           callbacks
REM v0.37  -  Release-ready version after hasty release of a buggered 0.33
REM v0.38  -  New memory manager added
REM v0.39  -  GC sped up and uses new MM, still problems with order of GC at program quit.
REM           @ passed by reference in all routines, implicit this passing stopped
REM v0.40  -  Memory shrinks now, loadsa misc bugs fixed inside code, and major speedups
REM           all over.  More SA-bugs found and fixed
REM v0.41  -  More bugs fixed, like re-entrancy problem in Construct and FN re-entrancy in
REM           PROCs
REM v0.42  -  SYS "foo" TO a.b done
REM v0.43  -  Stoopid bug in windows finally fixed
REM v0.44  -  Window manager installed
REM v0.45  -  Dynamic variables, and variable lookup fixed, FN()() done
REM v0.46  -  Stupid bug in PermStrdup fixed - new '@' paradigm installed where @
REM           is a local variable of all instances
REM v0.47  -  Problems with Garbage collection of locals fixed,
REM           Throwback error handler, SYS TOx;y fixed. (Gerph)

ON ERROR ERROR 0,REPORT$+" at line "+STR$ ERL

DIM code% &50000
DIM Pal(16)
DIM eor_tab 64,chk_tab 64

IF RND(-210838)
FOR N%=0 TO 63 STEP 4:eor_tab!N%=RND:NEXT
IF RND(-764339)
FOR N%=0 TO 63 STEP 4:chk_tab!N%=RND:NEXT

wasted = 0
ip=12:lr=14:pc=15

XOS_DynamicArea = &20066

fptrProc = 0
fptrFn   = 1 : REM NOT USED
fptrNum  = 2
fptrStr  = 3

debug%=TRUE
profile%=FALSE
verbose%=FALSE

SYS "OS_GetEnv" TO com$
IF INSTR(com$,"-release") THEN
 debug%=FALSE
 profile%=FALSE
 verbose%=TRUE
ENDIF


wait%      = 100
Notify_Time% = 4

IndirSize    = 6*1024
TemplateSize = 3*1024

Vnum$      = "0.47"
Vnum%      = VAL(MID$(Vnum$,4,1))+&10*VAL(MID$(Vnum$,3,1))+&100*VAL(MID$(Vnum$,1,1))
Version$   = Vnum$+" ("+MID$(TIME$,5,2)+" "+MID$(TIME$,8,3)+" "+MID$(TIME$,14,2)+")"

MetaTime%  = 128*64*4

IF verbose% THEN
 PRINT "IRClient compiling - version "+Vnum$
 PRINT "Debug = ";debug%
 PRINT "Profile = ";profile%
ENDIF

Wimp_MDataSave    = 1
Wimp_MDataSaveAck = 2
Wimp_MDataLoad    = 3
Wimp_MDataLoadAck = 4
Wimp_MRAMFetch    = 6
Wimp_MRAMTransmit = 7
Wimp_MClaimEntity = 15
Wimp_MDataRequest = 16
Wimp_MDragging    = 17
Wimp_MDragClaim   = 18

Wimp_ModeChange   = &400C1
Wimp_WindowInfo   = &400CA

Channel_Next    = 0
Channel_Name    = 4
Channel_Flags   = 8
Channel_Users   = 12
Channel_Limit   = 16
Channel_Toolbar = 20
Channel_UserBox = 24
sizeof_Channel  = 28

Buffer_Next    = 0
Buffer_Data    = 4
Buffer_Length  = 8
Buffer_Size    = 12
sizeof_Buffer  = 16

CF_Topic       =   1
CF_Msgs        =   2
CF_Invite      =   4
CF_Moderated   =   8
CF_Secret      =  16
CF_Private     =  32
CF_Limited     =  64
CF_YouHaveOps  = 128

User_Next      =  0         : REM One user per user/channel combination
User_Name      =  4
User_Flags     =  8
sizeof_User    =  12
REM User_LastMes   = 12         : REM Monotonic time of last message from user
REM User_MesCount  = 16         : REM Count of messages occurring rapidly
REM User_ITimer    = 20         : REM Monotonic time to UNIGNORE a user
REM sizeof_User    = 24

U_HasOps       =  1
U_Ignored      =  2         : REM User is being ignored due to flooding
U_Selected     =  4         : REM User has been selected by the client
U_HasVoice     =  8


Version$+=" (unregistered)"

Garbage_Time = &1800      : REM Once a minute

Display_Next        =  0
Display_ZapArea     =  4
Display_NumLines    =  8
Display_What        = 12 : REM ptr to what information this display ie channel or nick
Display_LineAddrs   = 16 : REM ptr to the addresses of lines
Display_Wind        = 20 : REM the window
Display_Flags       = 24 : REM display flags
Display_Channel     = 28 : REM the channel this display is associated with
Display_Open        = 32 : REM whether disp is open
sizeof_Display      = 36

DisplayFlag_NoCR      = 1
DisplayFlag_Halfway   = 2
DisplayFlag_NoIndent  = 4
DisplayFlag_ANSI      = 8

Hotlist_Next        = 0
Hotlist_Flag        = 4
Hotlist_Address     = 8
Hotlist_Port        = 12
Hotlist_Comment     = 16
Hotlist_Selected    = 20
sizeof_Hotlist      = 24

CallBack_Next       = 0
CallBack_Proc       = 4
CallBack_Time       = 8
sizeof_CallBack     = 12

Recall_Next         = 0
Recall_Previous     = 4 : REM ooh - a doubly linked list
Recall_String       = 8
Recall_Display      = 12
sizeof_Recall       = 16
MaxRecall           = 32

_amount%            = 0
_f$                 = ""

DragType_User       = 0
DragType_Selection  = 1
DragType_DragNDrop  = 2
DragType_Clipboard  = 3
DragType_Hot        = 4

Connection_Next      = 0
Connection_Error     = 4
Connection_Incoming  = 8
Connection_Connected = 12
Connection_Handle    = 16
Connection_Private   = 20
sizeof_Connection    = 24

Schedule_Next        = 0
Schedule_Time        = 4
Schedule_Name        = 8
Schedule_Private     = 12
Schedule_TimeAgain   = 16
sizeof_Schedule      = 20

LIBRARY "<IRClient$Dir>.IRCModules.Menus"
LIBRARY "<IRClient$Dir>.IRCModules.IRBasic"
LIBRARY "<IRClient$Dir>.IRCModules.MemManager"
LIBRARY "<IRClient$Dir>.IRCModules.Object"
LIBRARY "<IRClient$Dir>.IRCModules.WinManager"

FOR pass%=4 TO 6 STEP 2
P%=&8000:O%=code%
[OPT pass%
MOV R0,R0
MOV R0,R0
bl  &8040
BL  ImageEntryPoint
SWI "OS_Exit"
EQUD EndReadOnlyData-&8000
EQUD EndData - EndReadOnlyData
EQUD 0 ; no debug info
EQUD TopOfStack% - EndData ; zero-init size
EQUD 0 ; debug state
EQUD &8000 ; linked at
EQUD 0 ; wkspce
EQUD 26 ; 26-bit
EQUD 0 ; no data space
EQUD 0
EQUD 0 ; reserved
MOV R0,R0 ; debug init instruction (NOP)
SUB    ip, lr, pc         ; base+12+[PSR]-(ZeroInit+12+[PSR])
                          ; = base-ZeroInit
ADD    ip, pc, ip         ; base-ZeroInit+ZeroInit+16 = base+16
LDMIB  ip, {r0,r1,r2,r4}  ; various sizes
SUB    ip, ip, #16        ; image base
ADD    ip, ip, r0         ; + rO size
ADD    ip, ip, r1         ; + RW size = base of 0-init area
MOV    r0, #0
MOV    r1, #0
MOV    r2, #0
MOV    r3, #0
CMPS   r4, #0
.lp
MOVLE  pc, lr               ; nothing left to do
STMIA  (ip)!, {r0,r1,r2,r3} ; always zero a multiple of 16 bytes
SUBS   r4, r4, #16
B      lp

.EndReadOnlyData

.ImageEntryPoint
MOV R12,#&8000
B Start

]:IF debug% THEN
[OPT pass%
.BreakPoint
MOV     R0,R0
MOVS    PC,R14
]
ENDIF
[OPT pass%

]:P%-=&8000:[OPT pass%

; Global variables
.Task             EQUS "TASK"
.Wind             EQUS "Wind"
.TopOfStack       EQUD TopOfStack%
.MyName           EQUD MyName%
.MN_C             EQUD MyName_Config%
.MyIP             EQUD 0
.TaskHandle       EQUD 0
.EqHandle         EQUD 0
.EqNetHandle      EQUD 0
.WimpArea         EQUD 0 ; instead of WimpArea%
.MsgArea          EQUD 0 ; A copy of the wimp area on messages
.Templates        EQUD Templates%
.Sprites          EQUD Sprites%
.IconHandle       EQUD 0
.QuitFlag         EQUD 0
.HelpMes          EQUD &502
.MenuWarning      EQUD &400C0
.MenuClose        EQUD &400C9
.Help             EQUD Help%
.PageSize         EQUD 0
.BaseSP           EQUD 0
.ErrBlock         EQUD ErrBlock%
.IndirArea        EQUD IndirArea%
.StartupTimerKill EQUD 0
.NotifyOff        EQUD 0
.Zap_Data         EQUD Zap_Data%
.LineBuf          EQUD LineBuf%
.WindowAddx       EQUD 0
.WindowAddy       EQUD 0
.IRCNick          EQUD 0
.ProgramHead      EQUD 0
.ChannelHead      EQUD 0
.SelectedChannel  EQUD 0
.InputWind        EQUD 0
.CursorPos        EQUD 0
.PreInsert        EQUD 0
.RegFlag          EQUD 0
.MenuSelPerson    EQUD 0
.MenuSelHot       EQUD 0
.DumpRegs         EQUD 0
.Oflag            EQUD 0
.CallBackStack    EQUD CallBackStack%
.ConFlag          EQUD 0
.DC_Yes           EQUD 0
.DC_No            EQUD 0
.rc_Startup       EQUD Startup
.HotlistHead      EQUD 0
.RecallHead       EQUD 0
.RecallPointer    EQUD 0
.DisplayHead      EQUD 0
.ConnectionHead   EQUD 0
.CurrentDisplay   EQUD 0
.HotlistFlag      EQUD 0
.DragType         EQUD 0
.DragFlag         EQUD 0
.DraggingDisplay  EQUD 0
.RAMTransBufBase  EQUD 0
.RAMTransPtr      EQUD 0
.RAMTransSize     EQUD 0
.DynamicFlag      EQUD 0
.HeapPtr          EQUD 0
.SharedBuffer     EQUD 0
.DisplayTemplate  EQUD DisplayWindowName
.BufferHead       EQUD 0
.XExtent          EQUD 0
.YExtent          EQUD 0
.Vnum             EQUD Vnum%
.MetaTime         EQUD 0
.MetaIP           EQUD 0
.ProgNumber       EQUD 0
.CallBackHead     EQUD 0
.MenuParameter    EQUD 0
.MenuChannel      EQUD 0
.RIptr            EQUD RetraceInfo

FNwkspIRBasic
FNwkspMemoryManager
FNwkspWindowManager
FNwkspMenus
FNwkspObject

.SelectedDisplay  EQUD 0
.S_StartLine      EQUD 0
.S_EndLine        EQUD 0
.S_StartChar      EQUD 0
.S_EndChar        EQUD 0
.StartLine        EQUD 0
.EndLine          EQUD 0
.StartChar        EQUD 0
.EndChar          EQUD 0
.DisplayWithFocus EQUD 0
.CurrentTB        EQUD 0
.CurrentGlocals   EQUD 0

.DnD_Claimant     EQUD 0
.DnD_DragFinished EQUD 0
.DnD_DragAborted  EQUD 0
.DnD_LastRef      EQUD 0

.ShowIconbarFlag  EQUD 0
.ConfigFlag       EQUD 0
.ConNowFlag       EQUD 0
.NoteOffQuit      EQUD 0

.CaretFlag        EQUD 0
.Clipboard        EQUD 0
.Clipboard_Ptr    EQUD 0
.Clipboard_Size   EQUD 0

.SchedList        EQUD 0

.Hotlist_Editing  EQUD 0

.PasteBuffer      EQUD 0
.RAMBuffer        EQUD 0
.EndRAMIn         EQUD 0

]:P%+=&8000:[OPT pass%

.MyName%        EQUS "IRClient"+CHR$0
.MyName_Config% EQUS "IRClient Configuration"+CHR$0
.Templates%     EQUS "<IRClient$Dir>.Resources.Templates"+CHR$0
.Sprites%       EQUS "<IRClient$Dir>.Resources.Sprites"+CHR$0
.Help%          EQUS "<IRClient$Dir>.Resources.Messages"+CHR$0

\\ ZapRedraw Area
]:P=P%:O=O%:P%=0:[OPT pass%
.r_flags            EQUD 0    \ Redraw flags
.r_minx             EQUD 0    \ min x in pixs inc
.r_miny             EQUD 0    \ min y in pixs inc (from top)
.r_maxx             EQUD 0    \ max x in pixs exc
.r_maxy             EQUD 0    \ max y in pixs exc (from top)
.r_screen           EQUD 0    \ address of the screen
.r_bpl              EQUD 0    \ bytes per raster line
.r_bpp              EQUD 0    \ log base 2 of bpp
.r_charw            EQUD 0    \ width of a character in pixs
.r_charh            EQUD 0    \ height of a character in pixs
.r_caddr            EQUD 0    \ cache address / font name
.r_cbpl             EQUD 0    \ bytes per cached line
.r_cbpc             EQUD 0    \ bytes per cached character
.r_linesp           EQUD 0    \ line spacing in pixels
.r_data             EQUD 0    \ address of data to print
.r_scrollx          EQUD 0    \ x scroll offset in pixs
.r_scrolly          EQUD 0    \ y scroll offset in pixs
.r_palette          EQUD 0    \ address of palette data
.r_for              EQUD 0    \ start forground colour
.r_bac              EQUD 0    \ start background colour
.r_workarea         EQUD 0    \ address of work area
.r_magx             EQUD 0    \ log 2 of num of x os per pixel
.r_magy             EQUD 0    \ log 2 of num of y os per pixel
.r_xsize            EQUD 0    \ screen width in pixels
.r_ysize            EQUD 0    \ screen height in pixels
.r_mode             EQUD 0    \ screen mode
.sizeof_ZapArea
]P%=P:O%=O:[OPT pass%

.InitFrame EQUD 0:EQUS "Start"+CHR$0:ALIGN

.Start
LDR R13,[R12,#TopOfStack]
FNmov(11,TopOfRetraceInfo)
MOV R0,#0:STMFD R11!,{R0} ; put end bit in
BL MemInit ; from now on BL Claim works

; Voyager stuff
SWI "OS_GetEnv"
.lp LDRB R14,[R0],#1:CMP R14,#32:MOVNES R14,R14:BNE lp:MOVS R14,R14
BEQ NoChangeDueToParms
MOV R1,R0:ADR R0,SyntaxString:LDR R2,[R12,#WimpArea]:MOV R3,#&100
SWI "OS_ReadArgs"
LDR R0,[R12,#WimpArea]:LDR R1,[R0]:STR R1,[R12,#ShowIconbarFlag]
LDR R1,[R0,#4]:STR R1,[R12,#ConfigFlag]
LDR R1,[R0,#8]:STR R1,[R12,#ConNowFlag]
B NoChangeDueToParms
.SyntaxString EQUS "noicon/s,configure/s,connect/s"+CHR$0:ALIGN
.NoChangeDueToParms

]
IF profile% THEN
[OPT pass%
BL InitProfiler
]
ENDIF
[OPT pass%

MOV r0,#0:STR r13,[r12,#BaseSP]
MOV R0,#6:ADR R1,ErrorHandler:MOV R2,#0:LDR R3,[R12,#ErrBlock]
SWI "OS_ChangeEnvironment":ADR R7,Environ:STMIA R7!,{R0-R3}
MOV R0,#13:MOV R1,#0:SWI "OS_ChangeEnvironment"
STR R1,[R12,#DumpRegs]

BL Initialise

STR R13,[R12,#BaseSP]

; open the prefs window, appropriately changing the templates
LDR R0,[R12,#ConfigFlag]:MOVS R0,R0:BEQ NormalityNotVoyager
LDR R0,[R12,#EqHandle]:FNadr(1,PreferenceWindow+4):ADR R2,okay
ADR R3,BindleWorthy:SWI "EqWimp_WriteStringToIcon"
ADR R2,BindleWorthy:LDR R3,[R12,#WimpArea]:SWI "EqWimp_WimpBlock"
SWI "Wimp_DeleteIcon"
BL OpenPrefs
B NormalityNotVoyager
.okay EQUS "OK"+CHR$0:ALIGN:.BindleWorthy EQUS "Save"+CHR$0:ALIGN
.NormalityNotVoyager

; open the connect dialog if on voyager mode
LDR R0,[R12,#ConNowFlag]:MOVS R0,R0:BEQ felching
LDR R0,[R12,#EqHandle]:FNadr(1,ConnectWindow+4):SWI "EqWimp_PutAtFrontAndCentre"
.felching

.PollLoop
LDR R0,[R12,#EqNetHandle]:SWI "EqNet_Poll"
BL WimpPoll
BL CheckCallBacks ; after WIMPPOLL!
LDR R0,[R12,#QuitFlag]:MOVS R0,R0
BEQ PollLoop

.ForcedQuit
ADR R7,Environ:LDMIA R7!,{R0-R3}:SWI "OS_ChangeEnvironment"
BL Finalise

SWI "OS_Exit"

.Environ EQUD 0:EQUD 0:EQUD 0:EQUD 0:EQUD 0:EQUD 0:EQUD 0:EQUD 0

.ErrSemaphore EQUD 0
.ErrorHandler
SWI "XDragASprite_Stop"
MOV R12,#&8000
LDR R14,ErrSemaphore:CMP R14,#1:BEQ NotReentrant
MOV R14,#1:STR R14,ErrSemaphore

;check for stack retrace
LDR R3,[R12,#ErrBlock]:LDR R3,[R3,#4]

TST R3,#1<<31:BEQ NotFatal

LDR R1,[R12,#DumpRegs]
FNmov(0,ExpressionEvaluateBuffer):BL Retrace
MOV R4,R0:MOV R0,#10:ADR R1,CrashFn:MOV R3,#0
MOV R2,#&FF:ORR R2,R2,#&F00
MOV R5,R4:.flp LDRB R14,[R5]:MOVS R14,R14:ADDNE R5,R5,#1:BNE flp
SWI "XOS_File"

.NotFatal
MOV R1,#0
FNadr(3,CallRoot11):LDR r2,[r3]    ; read the root procedure ptr
TEQ R2,#0
BEQ ErrorWhilstNotInBasic
LDR r0,[r12,#ErrBlock]
ADD r0,r0,#8
BL DoBasicErrorTrace
BL ResetTheLot
BL ResetMenuSystem
B ReturnFromError

.ErrorWhilstNotInBasic
STR R1,[R3]  ; zap the program stk

FNmov(11,TopOfRetraceInfo)
MOV R0,#0:STMFD R11!,{R0} ; put end bit in
FNmov(0,CallBackStack%):STR R0,[R12,#CallBackStack]

FNborrow(1,256)
ADR R2,ErrString:LDR R3,[R12,#ErrBlock]:ADD R3,R3,#4:LDR R4,[R3],#4
BL String:MOV R3,R1
LDR R0,[R12,#EqHandle]:ADR R1,Win_Alert:ADR R2,Icon_Message
SWI "EqWimp_WriteStringToIcon"
FNrepay

SWI "EqWimp_PutAtFrontAndCentre"
SWI "EqWimp_RestrictMouse"
MVN R2,#0:MVN R3,#0:MVN R4,#0:MVN R5,#0:SWI "EqWimp_SetCaret"
BL ClaimCaret
FNadr(0,BeepOnError):LDR R0,[R0]:MOVS R0,R0:SWINE &107
B PollLoop
.Win_Alert EQUS "Alert"+CHR$0
.Icon_Message EQUS "Message"+CHR$0:ALIGN
.NotReentrant
ADR R7,Environ:LDMIA R7!,{R0-R3}:SWI "OS_ChangeEnvironment"
LDR R0,[R12,#EqHandle]:SWI "XEqWimp_ReleaseMouse"
ADR R0,OhDear:MOV R1,#6:LDR R2,[R12,#MyName]:SWI "Wimp_ReportError"
BL Finalise
SWI "OS_Exit"
.ErrString EQUS "Error : %s (&%0)"+CHR$0
.OhDear EQUS "SHITError occurred in error handler - IRClient must die now!"+CHR$0:ALIGN
.MesList
EQUD Wimp_MClaimEntity
EQUD Wimp_MDataRequest
EQUD Wimp_MDataSave
EQUD Wimp_MDataSaveAck
EQUD Wimp_MDataLoad
EQUD Wimp_MDataLoadAck
EQUD Wimp_MRAMFetch
EQUD Wimp_MRAMTransmit
EQUD Wimp_ModeChange
EQUD Wimp_WindowInfo
EQUD Wimp_MDragging
EQUD Wimp_MDragClaim
EQUD &502:EQUD &400C0:EQUD &400C9:EQUD 0

.CrashFn EQUS "Pipe:$.IRC_Core"+CHR$0:ALIGN

.TemplateList
              EQUS "Alert,"
              EQUS "AreYouSure,"
              EQUS "ByTheWay,"
              EQUS "ChangeTopic,"
              EQUS "ChannelPane,"
              EQUS "ChanToolbar,"
              EQUS "Colour,"
              EQUS "Connect,"
              EQUS "Connecting,"
              EQUS "Display,"
              EQUS "Friends,"
              EQUS "Hotlist,"
              EQUS "Info,"
              EQUS "Input,"
              EQUS "Invite,"
              EQUS "JoinChannel,"
              EQUS "NewHotlist,"
              EQUS "Palette,"
              EQUS "Preferences,"
              EQUS "PrefPane,"
              EQUS "SaveBox,"
              EQUS "ServerMsgs,"
              EQUS "Startup,"
              EQUS "Userpane"
              EQUB 0:ALIGN
.IconSprite EQUS "!IRClient"+CHR$0:ALIGN
.Version EQUS Version$+CHR$0:ALIGN
.Icon_Version EQUS "Version"+CHR$0:ALIGN
.InfoWin EQUS "Info"+CHR$0:ALIGN
.Startup EQUS "Startup"+CHR$0:ALIGN

.Initialise
STMFD R13!,{R0-R7,R14}
FNfunction("Initialise")
MOV R0,#256:ADD R0,R0,#(300-256)
LDR R1,[R12,#Task]
LDR R2,[R12,#MyName]:LDR R14,[R12,#ConfigFlag]:MOVS R14,R14:LDRNE R2,[R12,#MN_C]
ADR R3,MesList
SWI "XWimp_Initialise":BVS FatalError
STR R1,[R12,#TaskHandle]
LDR R0,[R12,#Sprites]:SWI "EqWimp_Sprites":MOV R5,R0
MOV R3,#TemplateSize:BL Claim ; get some temp space
STMFD R13!,{R2}
ADR R0,TemplateList
MOV R1,R2
LDR R2,[R12,#IndirArea]
ADD R3,R2,#IndirSize:SUB R3,R3,#1
LDR R4,[R12,#Templates]
MVN R6,#0
SWI "EqWimp_Initialise":STR R0,[R12,#EqHandle]
LDMFD R13!,{R2}:BL Release
LDR R14,[R12,#ShowIconbarFlag]:MOVS R14,R14:BNE DontShowIcon
ADR R1,IconSprite:MOV R2,#2:MVN R3,#0
SWI "EqWimp_InstallOnIconbar":STR R1,[R12,#IconHandle]
.DontShowIcon
LDR R1,[R12,#Help]:SWI "EqWimp_LoadHelpFile"
ADR R1,InfoWin:ADR R2,Icon_Version
ADR R3,Version:SWI "EqWimp_WriteStringToIcon"

BL LoadOptions
BL InitRndGenerator

BL CheckRegistration

LDR R0,[R12,#EqHandle]:ADR R1,Startup
LDR R14,[R12,#RegFlag]:MOVS R14,R14:BLNE IsItReg
BEQ AlwaysShow
FNadr(0,ShowBanner):LDR R0,[R0]:MOVS R0,R0:BEQ NoBanner
.AlwaysShow
LDR R0,[R12,#EqHandle]:SWI "EqWimp_PutAtFrontAndCentre"
MOV R0,#0
LDR R1,[R12,#WimpArea]:SWI "Wimp_Poll"
SWI "OS_ReadMonotonicTime":FNadr(2,NoteLen):LDR R2,[R2]:MOV R3,#100:MUL R2,R3,R2
ADD R1,R0,R2:STR R1,[R12,#StartupTimerKill]
.NoBanner

LDR R0,[R12,#EqHandle]
ADR R1,UserPane:ADR R2,TemName
FNadr(3,UserIconTemplate)
SWI "EqWimp_MakeIconTemplate":STR R1,UserIconXSize:STR R2,UserIconYSize

FNadr(1,ChanPane):ADR R2,TemName
FNadr(3,ChannelTemplate)
SWI "EqWimp_MakeIconTemplate":STR R1,ChanIconXSize:STR R2,ChanIconYSize

FNadr(1,HotlistWindow+4):ADR R2,T1text:FNadr(3,HotlistT1)
SWI "EqWimp_MakeIconTemplate":STR R1,HotT1XSize:STR R2,HotT1YSize
FNadr(1,HotlistWindow+4):ADR R2,T2text:FNadr(3,HotlistT2)
SWI "EqWimp_MakeIconTemplate":STR R1,HotT2XSize:STR R2,HotT2YSize
FNadr(1,HotlistWindow+4):ADR R2,T3text:FNadr(3,HotlistT3)
SWI "EqWimp_MakeIconTemplate":STR R1,HotT3XSize:STR R2,HotT3YSize
FNadr(1,HotlistWindow+4):ADR R2,T4text:FNadr(3,HotlistT4)
SWI "EqWimp_MakeIconTemplate":STR R1,HotT4XSize:STR R2,HotT4YSize

LDR R0,[R12,#MyName]
ADR R1,MyMalloc
ADR R2,MyFree
SWI "EqNet_Initialise":STR R0,[R12,#EqNetHandle]

BL DisplayInit

BL Initialise_Root_Class

ADR R0,NEthing:BL Str_dup:STR R1,[R12,#IRCNick] ; so error reporting works
BL ReloadPrograms

BL OpenHotlist

]
IF NOT debug% THEN
[OPT pass%
SWI &61D41:BVS NotBeingDB
TEQ R0,#0:BEQ NotBeingDB
SWI &61D43
BVS P%
.NotBeingDB
]
ENDIF
[OPT pass%
; Nuke the init code
ADR R0,Initialise
MOV R1,#P% - Initialise
.lp
STR R14,[R0],#4
SUBS R1,R1,#4
BNE lp

FNend
LDMFD R13!,{R0-R7,PC}^
.NEthing EQUS "!"+CHR$0:ALIGN
.MyMalloc
STMFD R13!,{R11,R12,R14}
FNmov(11,DummyR11Stack)
MOV R12,#&8000
MOV R3,R0:BL Claim:MOV R0,R2
LDMFD R13!,{R11,R12,PC}^
.MyFree
STMFD R13!,{R11,R12,R14}
FNmov(11,DummyR11Stack)
MOV R12,#&8000
MOV R2,R0:BL Release
LDMFD R13!,{R11,R12,PC}^

.IsItReg
STMFD R13!,{R0-R3,R14}
FNcrypt(IsItReg_End-IsItReg_Start)
.IsItReg_Start
ADR R2,StartupR:FNadr(3,RegiData)
SWI "EqWimp_WriteStringToIcon":B St_Over
.StartupR EQUS "RegisteredTo"+CHR$0:ALIGN
.St_Over
FNadr(0,Version):MOV R1,#0:STRB R1,[R0,#LEN(Version$)-LEN(" (unregistered)")]
MOV R3,R0:LDR R0,[R12,#EqHandle]
FNadr(1,InfoWin):FNadr(2,Icon_Version)
SWI "EqWimp_WriteStringToIcon"
LDMFD R13!,{R0-R3,PC}^
.IsItReg_End
FNendcrypt

.UserPane  EQUS "UserPane"+CHR$0:ALIGN
.TemName   EQUS "Template"+CHR$0:ALIGN
.ChanIconXSize EQUD 0
.ChanIconYSize EQUD 0
.UserIconXSize EQUD 0
.UserIconYSize EQUD 0
.T1text EQUS "T1"+CHR$0:ALIGN
.T2text EQUS "T2"+CHR$0:ALIGN
.T3text EQUS "T3"+CHR$0:ALIGN
.T4text EQUS "T4"+CHR$0:ALIGN
.HotT1XSize EQUD 0
.HotT1YSize EQUD 0
.HotT2XSize EQUD 0
.HotT2YSize EQUD 0
.HotT3XSize EQUD 0
.HotT3YSize EQUD 0
.HotT4XSize EQUD 0
.HotT4YSize EQUD 0

.ReloadPrograms
STMFD R13!,{R0,R14}
FNfunction("ReloadPrograms")
BL NukePrograms
BL InstallRoutines
ADR R0,InitProgram:BL LoadProgram:SWIVS "OS_GenerateError"
ADR R0,InitialiseProc:MOV R1,#0:BL CallRootProcedure
FNnastyCheck0
FNend
LDMFD R13!,{R0,PC}^
.InitProgram EQUS "<IRClient$Dir>.Scripts.Internal.Boot"+CHR$0:ALIGN
.InitialiseProc EQUS "Initialise"+CHR$0:ALIGN
.Finnie EQUS "Finalise"+CHR$0

.NukePrograms
STMFD R13!,{R0-R7,R14}
FNfunction("NukePrograms")
LDR R7,[R12,#ProgramHead]
MOVS R7,R7:BEQ NoProgs
ADR R0,Finnie:MOV R1,#0:BL CallRootProcedure
.NoProgs
MOV R0,#0:STR R0,[R12,#ProgramHead]
.NukeAllPrograms
MOVS R2,R7:LDR R7,[R7]:BLNE Release:BNE NukeAllPrograms
FNadr(7,fptrs):MOV R6,#(ASC"z"-ASC"A")
.NukeAllLoop
LDR R5,[R7],#4:MOV R0,#0:STR R0,[R7,#-4]
.NukeOneLoop
MOVS R2,R5:BEQ EndNukeBit
LDR R5,[R5]:LDR R0,[R2,#8]:CMP R0,#fptrProc
LDR R0,[R2,#4]:BL Str_free:LDR R0,[R2,#8]:CMP R0,#fptrStr:LDREQ R0,[R2,#12]
BLEQ Str_free
BL Release
B NukeOneLoop
.EndNukeBit
SUBS R6,R6,#1:BNE NukeAllLoop
BL HoseLocalStack
BL ResetEvaluator
FNend
LDMFD R13!,{R0-R7,PC}^

.ClaimCaret
STMFD R13!,{R0-R7,R14}
FNfunction("ClaimCaret")
LDR R0,[R12,#CaretFlag]:MOVS R0,R0:BNE IveGotTheCaretAlready
MOV R0,#3:STR R0,cflgs
MOV R0,#1:STR R0,[R12,#CaretFlag]:MOV R0,#17:ADR R1,CaretClaimMessage
MOV R2,#0:SWI "Wimp_SendMessage"
.IveGotTheCaretAlready
FNend
LDMFD R13!,{R0-R7,PC}^
.CaretClaimMessage EQUD 24:EQUD 0:EQUD 0:EQUD 0:EQUD Wimp_MClaimEntity
.cflgs EQUD 0

.ClaimClipboard
STMFD R13!,{R0-R7,R14}
FNfunction("ClaimClipboard")
MOV R0,#4:STR R0,cflgs:MOV R2,#0:MOV R0,#17:ADR R1,CaretClaimMessage
SWI "Wimp_SendMessage"
FNend
LDMFD R13!,{R0-R7,PC}^

.Notify
STMFD R13!,{R0-R7,R14}
FNfunction("Notify")
FNadr(4,NoteLen):LDR R4,[R4]:MOV R5,#100:MUL R4,R5,R4
MOV R3,R0:LDR R0,[R12,#EqHandle]:ADR R1,BtW:ADR R2,MesThingy:SWI "EqWimp_WriteStringToIcon"
SWI "EqWimp_PutAtFrontAndCentre":SWI "OS_ReadMonotonicTime":ADD R0,R0,R4
STR R0,[R12,#NotifyOff]
FNadr(1,BeepOnNotify):LDR R1,[R1]:MOVS R1,R1:SWINE &107
FNend
LDMFD R13!,{R0-R7,PC}^

.MesThingy EQUS "Message"+CHR$0:.BtW EQUS "ByTheWay"+CHR$0:ALIGN

.FatalError
FNadr(0,Initialise)
MOV R1,#NEthing - Initialise
.lp
STR R14,[R0],#4
SUBS R1,R1,#4
BNE lp
LDMFD R13!,{R0-R7,R14}
ADR R0,InitError:SWI "OS_GenerateError"
SWI "OS_Exit"
.InitError EQUS "!!!!Error during startup!"+CHR$0:ALIGN

.DoubleCheck ; r0->qn, r1->cancel, r2->ok, r3->cancel rout, r4->ok routine
STMFD R13!,{R0-R7,R14}
FNfunction("DoubleCheck")
STR R3,[R12,#DC_No]
STR R4,[R12,#DC_Yes]
LDR R0,[R12,#EqHandle]:ADR R1,AYS:ADR R2,MIcon
LDR R3,[R13]:SWI "EqWimp_WriteStringToIcon"
ADR R2,YIcon:LDR R3,[R13,#8]:SWI "EqWimp_WriteStringToIcon"
ADR R2,NIcon:LDR R3,[R13,#4]:SWI "EqWimp_WriteStringToIcon"
SWI "EqWimp_PutAtFrontAndCentre"
MVN R2,#0:MOV R3,#0:MOV R4,#0:MVN R5,#0
SWI "EqWimp_GrabCaret"
FNend
LDMFD R13!,{R0-R7,PC}^
.AYS EQUS "AreYouSure"+CHR$0:ALIGN
.YIcon EQUS "Yes"+CHR$0:ALIGN
.NIcon EQUS "No"+CHR$0:ALIGN
.MIcon EQUS "Message"+CHR$0:ALIGN

.No_Clicked
STMFD R13!,{R0-R7,R14}
FNfunction("No_Clicked")
LDR R0,[R12,#EqHandle]:ADR R1,AYS:SWI "XEqWimp_RestoreCaret"
LDR R0,[R12,#EqHandle]:ADR R1,AYS:SWI "EqWimp_ShutWindow"
LDR R0,[R12,#DC_No]:MOVS R0,R0
ADR R14,P%+8:MOVNE PC,R0
FNend
LDMFD R13!,{R0-R7,PC}^
.Yes_Clicked
STMFD R13!,{R0-R7,R14}
FNfunction("Yes_Clicked")
LDR R0,[R12,#EqHandle]:ADR R1,AYS:SWI "XEqWimp_RestoreCaret"
LDR R0,[R12,#EqHandle]:ADR R1,AYS:SWI "EqWimp_ShutWindow"
LDR R0,[R12,#DC_Yes]:MOVS R0,R0
ADR R14,P%+8:MOVNE PC,R0
FNend
LDMFD R13!,{R0-R7,PC}^

.WimpPoll
STMFD R13!,{R0-R7,R14}
FNfunction("WimpPoll")

MOV R0,#0
LDR R1,[R12,#WimpArea]:MOV R2,#50:MOV R3,#0
SWI "Wimp_Poll":TEQ R0,#0:BEQ SkipWMpoll
BL WindowManager_WimpPoll:TEQ R0,#0:BEQ EndPoll ; check extra windows
.SkipWMpoll
ADR R14,EndPoll
CMP R0,#17:CMPNE R0,#18:CMPNE R0,#19
BEQ WimpMessage
CMP R0,#12:BEQ GainCaret
CMP R0,#11:BEQ LoseCaret
CMP R0,#9:BEQ Menu_Select
CMP R0,#8:BEQ Key_Click
CMP R0,#7:BEQ UserDragBox
CMP R0,#6:BEQ Mouse_Click
CMP R0,#3:BEQ Win_Close
CMP R0,#2:BEQ Win_Open
CMP R0,#1:BEQ RedrawDisplay
CMP R0,#0:BEQ NullEvent
.EndPoll
FNend
LDMFD R13!,{R0-R7,PC}^

.LoseCaret
STMFD R13!,{R0-R7,R14}
MOV R0,#0:STR R0,[R12,#CurrentDisplay]
LDMFD R13!,{R0-R7,PC}^

.GainCaret
STMFD R13!,{R0-R7,R14}
; xxx
LDMFD R13!,{R0-R7,PC}^

.UserDragBox
STMFD R13!,{R0-R7,R14}
FNfunction("UserDragBox")
LDR R1,[R12,#WimpArea]
SWI "Wimp_GetPointerInfo"
LDMIA R1,{R2-R6}
ADR R1,DSBData:STMIA R1!,{R5-R6}:STMIA R1,{R2,R3}
MOV R0,#0:STR R0,DBSmy_ref ;your_ref
LDR R0,[R12,#DragType]
CMP R0,#DragType_DragNDrop:BNE NotRelledDND
SWI "XDragASprite_Stop"
MOV R0,#1:STR R0,[R12,#DnD_DragFinished]:BL ProcessDnD
B EndUserDragBox
.NotRelledDND
CMP R0,#DragType_Selection:MOVEQ R0,#0:STREQ R0,[R12,#DragFlag]:BEQ EndUserDragBox
CMP R0,#DragType_Hot:BNE TryU3
FNadr(0,Hotlist):B EndlpSaveUsers
.TryU3
CMP R0,#DragType_User:BNE EndUserDragBox
LDR R0,[R12,#SelectedChannel]:MOVS R0,R0:BEQ EndUserDragBox
LDR R7,[R0,#Channel_Users]:MOVS R7,R7:BEQ EndUserDragBox
MOV R0,#0:.lp
MOVS R7,R7:BEQ EndlpSaveUsers
LDR R1,[R7,#User_Flags]:TST R1,#U_Selected:BEQ NotSelectedUserForSave
MOVS R0,R0:ADRNE R0,ManyUsersToSave:BNE EndlpSaveUsers
.NotSelectedUserForSave
LDR R0,[R7,#User_Name]:LDR R7,[R7]:B lp
.EndlpSaveUsers
MOVS R0,R0:BEQ EndUserDragBox
ADR R1,DSBName:.lp LDRB R2,[R0],#1:STRB R2,[R1],#1:MOVS R2,R2:BNE lp
MOV R0,#17:ADR R1,DataSaveBlock:LDR R2,[R1,#20]:LDR R3,[R1,#24]
SWI "Wimp_SendMessage"
.EndUserDragBox
FNend
LDMFD R13!,{R0-R7,PC}^
.ManyUsersToSave EQUS "Users"+CHR$0:ALIGN
.DataSaveBlock
           EQUD 64+8
           EQUD 0
           EQUD 0
.DBSmy_ref EQUD 0
           EQUD 1 ; message_datasave
.DSBData   EQUD 0
           EQUD 0
           EQUD 0
           EQUD 0
           EQUD 64
.DBSFType  EQUD &FFF ; filetype
.DSBName   FNres(24)
.SaveSelection ; in r0->fname, r1->your_ref,r2,r3 who to send to
STMFD R13!,{R0-R7,R14}
FNfunction("SaveSelection")
STR R1,DBSmy_ref:ADR R1,DSBName
.lp LDRB R14,[R0],#1:STRB R14,[R1],#1:MOVS R14,R14:BNE lp
LDR R1,[R12,#WimpArea]
SWI "Wimp_GetPointerInfo"
LDMIA R1,{R2-R6}
ADR R1,DSBData:STMIA R1!,{R5-R6}:STMIA R1,{R2,R3}
MOV R0,#17:ADR R1,DataSaveBlock:LDR R2,[R13,#2*4]:LDR R3,[R13,#3*4]
SWI "Wimp_SendMessage"
FNend
LDMFD R13!,{R0-R7,PC}^

.DataRequest
LDR R0,[R1,#36]:CMP R0,#4:BNE EndWimpMessage
LDR R0,[R12,#Clipboard]:MOVS R0,R0:BEQ EndWimpMessage
MOV R0,#DragType_Clipboard:STR R0,[12,#DragType]
ADR R0,ClipboardStr:ADR R2,DSBName
.lp LDRB R14,[R0],#1:STRB R14,[R2],#1:MOVS R14,R14:BNE lp
MOV R2,#0:STR R2,DBSmy_ref
LDR R7,[R1,#8]
ADD R1,R1,#20:ADR R14,DSBData:LDMIA R1,{R2-R5}:STMIA R14,{R2-R5}
ADR R1,DataSaveBlock:STR R7,[R1,#12]:MOV R0,#17:SWI "Wimp_SendMessage"
B EndWimpMessage
.ClipboardStr EQUS "Clipboard"+CHR$0:ALIGN

.Disco EQUS "Disconnect"+CHR$0:ALIGN:    EQUD OfflineCheck
.QuitFlagOn
STMFD R13!,{R0-R7,R14}
LDR R0,[R12,#EqHandle]:FNadr(1,ConText):SWI "EqWimp_ReadMenuFlag":MOVS R1,R1
BLEQ CanQuitAway:BEQ QFO_done
ADR R0,AYSquit:ADR R1,dontquit:ADR R2,yesquit:MOV R3,#0:ADR R4,CanQuitAway
BL DoubleCheck
.QFO_done
LDMFD R13!,{R0-R7,PC}^
.CanQuitAway
MOV R0,#1:STR R0,[R12,#QuitFlag]:MOVS PC,R14
.AYSquit EQUS "IRClient is connected to a remote host.  Really quit?"+CHR$0:ALIGN
.dontquit EQUS "Don't quit"+CHR$0:ALIGN
.yesquit  EQUS "Quit"+CHR$0:ALIGN

.FingleWingle FNres(48)
.Opblock EQUD fptrStr:.Chanel EQUD 0:EQUD fptrStr:EQUD FingleWingle
.Op EQUS "Op"+CHR$0:ALIGN:.Deop EQUS "DeOp"+CHR$0:ALIGN
.Spacedout EQUS "%s "+CHR$0:ALIGN
.Do_Deop
STMFD R13!,{R0-R7,R14}
FNfunction("Do_Deop")
LDR R7,[R12,#SelectedChannel]:MOVS R7,R7:BEQ EndDeop
LDR R6,[R7,#Channel_Users]:MOVS R6,R6:BEQ EndDeop
LDR R7,[R7,#Channel_Name]:STR R7,Chanel:MOV R4,#0
ADR R3,FingleWingle
.Deoplp MOVS R6,R6:BEQ EndDeoplp
LDR R0,[R6,#User_Flags]:TST R0,#U_Selected:LDREQ R6,[R6]:BEQ Deoplp
ADD R4,R4,#1:CMP R4,#3:BLE AddPersonToDeop
ADR R0,Deop:MOV R1,#2:ADR R2,Opblock:BL CallRootProcedure
MOV R4,#1:ADR R3,FingleWingle
.AddPersonToDeop
STMFD R13!,{R3}
MOV R1,R3:LDR R3,[R6,#User_Name]:ADR R2,Spacedout:BL String:MOV R0,R1:BL GetStrLen
LDMFD R13!,{R3}
ADD R3,R3,R1:LDR R6,[R6]:B Deoplp
.EndDeoplp
CMP R4,#0:BEQ EndDeop
ADR R0,Deop:MOV R1,#2:ADR R2,Opblock:BL CallRootProcedure
.EndDeop
FNend
LDMFD R13!,{R0-R7,PC}^
.Do_Op
STMFD R13!,{R0-R7,R14}
FNfunction("Do_Op")
LDR R7,[R12,#SelectedChannel]:MOVS R7,R7:BEQ EndOp
LDR R6,[R7,#Channel_Users]:MOVS R6,R6:BEQ EndOp
LDR R7,[R7,#Channel_Name]:STR R7,Chanel:MOV R4,#0
ADR R3,FingleWingle
.Oplp MOVS R6,R6:BEQ EndOplp
LDR R0,[R6,#User_Flags]:TST R0,#U_Selected:LDREQ R6,[R6]:BEQ Oplp
ADD R4,R4,#1:CMP R4,#3:BLE AddPersonToOp
MOV R4,#1:ADR R0,Op:MOV R1,#2:ADR R2,Opblock:BL CallRootProcedure
ADR R3,FingleWingle
.AddPersonToOp
STMFD R13!,{R3}
MOV R1,R3:LDR R3,[R6,#User_Name]:ADR R2,Spacedout:BL String:MOV R0,R1:BL GetStrLen
LDMFD R13!,{R3}
ADD R3,R3,R1:LDR R6,[R6]:B Oplp
.EndOplp
CMP R4,#0:BEQ EndOp
ADR R0,Op:MOV R1,#2:ADR R2,Opblock:BL CallRootProcedure
.EndOp
FNend
LDMFD R13!,{R0-R7,PC}^

.DCC_Chat
STMFD R13!,{R0-R7,R14}
FNfunction("DCC_Chat")
LDR R7,[R12,#SelectedChannel]:MOVS R7,R7:BEQ EndChat
LDR R7,[R7,#Channel_Users]:MOVS R7,R7:BEQ EndChat
ADR R0,DChat:MOV R1,#1:ADR R2,DChatBit
.lp MOVS R7,R7:BEQ EndChat:LDR R3,[R7,#User_Flags]:TST R3,#U_Selected:LDREQ R7,[R7]:BEQ lp
LDR R3,[R7,#User_Name]:STR R3,DChatBit+4:BL CallRootProcedure:LDR R7,[R7]:B lp
.EndChat
FNend
LDMFD R13!,{R0-R7,PC}^
.DChat EQUS "DCCChat"+CHR$0:ALIGN
.DChatBit EQUD fptrStr:EQUD 0

.LeaveChan
STMFD R13!,{R0-R7,R14}
ADR R0,LCn:MOV R1,#1:ADR R2,MMFOOMB2:LDR R3,[R12,#SelectedChannel]
MOVS R3,R3:LDRNE R3,[R3,#Channel_Name]:STRNE R3,MMFOOMB2+4:BLNE CallRootProcedure
LDMFD R13!,{R0-R7,PC}^
.MMFOOMB2 EQUD fptrStr:EQUD 0
.LCn EQUS "LeaveChannel"+CHR$0:ALIGN

.CTCP_ClientInfo
ADR R0,P%+8:B CTCP:EQUS "CLIENTINFO"+CHR$0:ALIGN
.CTCP_Finger
ADR R0,P%+8:B CTCP:EQUS "FINGER"+CHR$0:ALIGN
.CTCP_Ping
ADR R0,P%+8:B CTCP:EQUS "PING"+CHR$0:ALIGN
.CTCP_Time
ADR R0,P%+8:B CTCP:EQUS "TIME"+CHR$0:ALIGN
.CTCP_UserInfo
ADR R0,P%+8:B CTCP:EQUS "USERINFO"+CHR$0:ALIGN
.CTCP_Version
ADR R0,P%+8:B CTCP:EQUS "VERSION"+CHR$0:ALIGN

.ClearSelection
STMFD R13!,{R0-R7,R14}
FNfunction("ClearSelection")
BL RedrawSelectedArea:MOV R0,#0:STR R0,[R12,#SelectedDisplay]
FNend
LDMFD R13!,{R0-R7,PC}^

.CopyToClipboard
STMFD R13!,{R0-R7,R14}
FNfunction("CopyToClipboard")
LDR R0,[R12,#SelectedDisplay]:MOVS R0,R0:BEQ EndCtC
LDR R2,[R12,#Clipboard]:MOVS R2,R2:BLNE Release:MOV R2,#0:STR R2,[R12,#Clipboard]
ADD R1,R12,#Clipboard AND &FF
ADD R1,R1,#Clipboard AND &FF00
BL SaveTheSelection
BL ClaimClipboard
.EndCtC
FNend
LDMFD R13!,{R0-R7,PC}^

.PasteFromClipboard
STMFD R13!,{R0-R7,R14}
FNfunction("PasteFromClipboard")
LDR R0,[R12,#Clipboard]:MOVS R0,R0:BEQ AskForClipboard
MOV R1,R0:LDR R0,[R12,#PasteBuffer]:MOVS R0,R0:BLNE FreeBuffer
BL NewBuffer:STR R0,[R12,#PasteBuffer]
LDR R2,[R12,#Clipboard_Ptr]:BL BufferAdd
B EndPFC
.AskForClipboard
FNadr(0,InputBox):BL FindDisplayByName:LDR R0,[R0,#Display_Wind]:STR R0,DRwinh
ADR R0,ClipIncoming:STR R0,[R12,#EndRAMIn]
MOV R0,#17:ADR R1,Mes_DR:MOV R2,#0
SWI "Wimp_SendMessage"
.EndPFC
FNend
LDMFD R13!,{R0-R7,PC}^
.Mes_DR EQUD 12*4
        EQUD 0
        EQUD 0
        EQUD 0
        EQUD 16
.DRwinh EQUD 0
        EQUD 0
        EQUD 0
        EQUD 0
        EQUD 1<<2
        EQUD &FFF
        EQUD -1

.ClipIncoming
STMFD R13!,{R0-R7,R14}
FNfunction("ClipIncoming")
BL NewBuffer:LDR R1,[R12,#RAMBuffer]:LDR R2,[R1,#Buffer_Length]:LDR R1,[R1,#Buffer_Data]
BL BufferAdd:STR R0,[R12,#PasteBuffer]
FNend
LDMFD R13!,{R0-R7,PC}^

.OfflineCheck
STMFD R13!,{R0-R7,R14}
FNfunction("OfflineCheck")
FNadr(0,AYSOff):FNadr(1,Cancel):FNadr(2,Disco):MOV R3,#0:FNadr(4,AbortConnection)
BL DoubleCheck
FNend
LDMFD R13!,{R0-R7,PC}^
.AYSOff EQUS "Are you sure you wish to disconnect?"+CHR$0:ALIGN

.WimpMessage
STMFD R13!,{R0-R7,R14}
FNfunction("WimpMessage")
LDR R0,[R12,#EqHandle]
LDR R2,[R1,#16]:MOVS R2,R2:MOVEQ R2,#1:STREQ R2,[R12,#QuitFlag]:BEQ EndWimpMessage
FNmov(3,Wimp_ModeChange):CMP R2,R3:BLEQ ZapModeChange:BEQ EndWimpMessage
LDR R3,[R12,#HelpMes]:CMP R2,R3:SWIEQ "EqWimp_HelpRequest"
LDR R3,[R12,#MenuClose]:CMP R2,R3:BLEQ DeSelPerson:BLEQ MenusDeleted
LDR R3,[R12,#MenuWarning]:CMP R2,R3:ADDEQ R0,R1,#20:BLEQ OpenSubMenuRequest
CMP R2,#Wimp_MDataSave:BEQ DataSave
; gerph >>> (DataLoad's going to text windows)
CMP R2,#Wimp_MDataLoad:BEQ DataLoad
; <<< gerph
CMP R2,#Wimp_MClaimEntity:BEQ ClaimEntity
CMP R2,#Wimp_MDataRequest:BEQ DataRequest
CMP R2,#Wimp_MDataSaveAck:BEQ DoMDSaveAck
CMP R2,#Wimp_MRAMFetch:BEQ RamFetch
CMP R2,#Wimp_MRAMTransmit:BEQ RamTransmit
CMP R2,#Wimp_MDragging:BEQ MDragging
CMP R2,#Wimp_MDragClaim:BEQ DragClaim
.EndWimpMessage
; tell anyone on the call chain we're interested
; gerph's changes - copy the block
LDR R2,[R13,#4]:LDR r1,[r12,#MsgArea]:MOV r3,#252
.wm_loop ; this could be optimised, but it's just quick...
LDR r0,[r2,r3]:STR r0,[r1,r3]:SUBS r3,r3,#4:BPL wm_loop
LDR R2,[R1,#16]:STR R2,blkWMRec+4:STR R1,blkWMRec+12
LDR r0,[r13,#0]:CMP r0,#19
ADRNE R0,WMReceived:ADREQ r0,WMBounced
; end change
MOV R1,#2:ADR R2,blkWMRec:BL CallRootProcedure
.EndWimpMessageWithoutBASIC
FNend
LDMFD R13!,{R0-R7,PC}^
.WMReceived EQUS "WimpMessage_Received"+CHR$0:ALIGN
; another change
.WMBounced EQUS "WimpMessage_Bounced"+CHR$0:ALIGN
; end change
.blkWMRec EQUD fptrNum:EQUD 0:EQUD fptrNum:EQUD 0

; gerph >>> (from Wimp_SendMessage)
.DataLoad
LDR r0,[r1,#20] ; read window handle
BL FindDisplay  ; see if we can find the display
TEQ r0,#0       ; did we find it ?
BEQ EndWimpMessage ; no, so pass it back to the main handler
; I'm going to copy the block here
LDR r2,[r13,#0]:CMP r0,#19 ; was it a bounce ?
BEQ EndWimpMessage         ; if so, deal normally with it
LDR r2,[r0,#Display_What]  ; read the display name
STR r2,blkWMLoad+4         ; store the name pointer
LDR R2,[R13,#4]:LDR r1,[r12,#MsgArea]:MOV r3,#252
.wm_loop ; this could be optimised, but it's just quick...
LDR r0,[r2,r3]:STR r0,[r1,r3]:SUBS r3,r3,#4:BPL wm_loop
LDR R2,[R1,#40]:STR R2,blkWMLoad+12 ; store filetype
ADD r1,r1,#44:STR R1,blkWMLoad+20  ; filename pointer
ADR R0,WMLoad                      ; routine to call
MOV R1,#3:ADR R2,blkWMLoad:BL CallRootProcedure
B EndWimpMessageWithoutBASIC
.WMLoad EQUS "DisplayLoadFile"+CHR$0:ALIGN
.blkWMLoad
EQUD fptrStr:EQUD 0:EQUD fptrNum:EQUD 0:EQUD fptrStr:EQUD 0
; <<< gerph

.DataSave
LDR R0,[R12,#EndRAMIn]:MOVS R0,R0:BNE WeKnowWhatItIs
B EndWimpMessage
.WeKnowWhatItIs
LDR R0,[R12,#RAMBuffer]:MOVS R0,R0:BLNE FreeBuffer
LDR R0,[R1,#4]:LDR R2,[R12,#TaskHandle]:CMP R1,R2:BEQ ScratchIt ; BOUNCE?
BL NewBuffer:STR R0,[R12,#RAMBuffer]
LDR R0,[R1,#36]:CMP R0,#8192:BGT ScratchIt ; too big
.SendRamFetch
LDR R2,[R1,#8]:STR R2,RF_my_ref
LDR R2,[R1,#4]:ADR R1,RF_Mes:MOV R0,#18:SWI "Wimp_SendMessage"
B EndWimpMessage
.RF_Mes    EQUD 28
           EQUD 0
           EQUD 0
.RF_my_ref EQUD 0
           EQUD Wimp_MRAMFetch
           EQUD ExpressionEvaluateBuffer
           EQUD 8192
.ScratchIt
LDR R2,[R1,#4]:STR R2,[R1,#12]
MOV R0,#Wimp_MDataSaveAck:STR R0,[R1,#16]
MOV R0,#64:STR R0,[R1,#0]
MVN R0,#0:STR R0,[R1,#36]
MOV R0,#&F:ORR R0,R0,#&FF:STR R0,[R1,#40]
STMFD R13!,{R2}:ADD R1,R1,#44:ADR R2,ScripIt:BL String
LDMFD R13!,{R2}
LDR R1,[R12,#WimpArea]:MOV R0,#17:SWI "Wimp_SendMessage"
B EndWimpMessage
.ScripIt EQUS "<Wimp$Scrap>"+CHR$0:ALIGN

.ClaimEntity
LDR R0,[R12,#TaskHandle]:LDR R2,[R1,#4]:CMP R0,R2:BEQ EndWimpMessage
LDR R0,[R1,#20]:CMP R0,#3:MOVEQ R0,#0:STREQ R0,[R12,#CaretFlag]:BEQ EndWimpMessage
CMP R0,#4:BNE EndWimpMessage:LDR R2,[R12,#Clipboard]:MOVS R2,R2:BLNE Release
MOV R2,#0:STR R2,[R12,#Clipboard]
B EndWimpMessage

.DragClaim
LDR R0,[R12,#DnD_DragFinished]:MOVS R0,R0:BEQ NewClaimant
LDR R0,[R12,#DnD_DragAborted]:MOVS R0,R0:BNE EndWimpMessage
LDR R2,[R1,#4]:MOV R3,#0
LDR R1,[R12,#DnD_LastRef]:ADR R0,Seln
BL SaveSelection
B EndWimpMessage
.NewClaimant
LDR R0,[R1,#4]:STR R0,[R12,#DnD_Claimant]
LDR R0,[R1,#8]:STR R0,[R12,#DnD_LastRef]
B EndWimpMessage

.MDragging
LDR R0,[R12,#DnD_Claimant]:MOVS R0,R0:BEQ NoCurrentClaimant
MOV R0,#0:STR R0,[R12,#DnD_Claimant]
BL ProcessDnD
B EndWimpMessage
.NoCurrentClaimant
LDR R0,[R12,#DnD_DragFinished]:MOVS R0,R0:BEQ EndWimpMessage
LDR R0,[R12,#DnD_DragAborted]:MOVS R0,R0:BNE EndWimpMessage
ADD R0,R1,#20:LDMIA R0,{R2,R3}:ADR R0,Seln:MOV R1,#0
BL SaveSelection
B EndWimpMessage
.Seln EQUS "Selection"+CHR$0:ALIGN

.RamFetch
LDR R0,[R1,#4]:LDR R14,[R12,#TaskHandle]:CMP R0,R14:BNE NotABrokenThing
LDR R0,[R12,#RAMBuffer]:MOVS R0,R0:BLNE FreeBuffer
B EndWimpMessage
.NotABrokenThing
MOV R6,R1
LDR R0,[R12,#RAMTransBufBase]:CMP R0,R0:BNE AlreadyTransmitting
LDR R0,[R12,#DragType]
CMP R0,#DragType_Hot:BNE TryClip
ADD R1,R12,#RAMTransBufBase:BL SaveHotlist
B Fetching
.TryClip
CMP R0,#DragType_Clipboard:BNE TryDnD
ADD R1,R12,#Clipboard AND &FF
ADD R1,R1,#Clipboard AND &ff00
LDMIA R1,{R2-R4}:ADD R1,R12,#RAMTransBufBase:STMIA R1,{R2-R4}
B Fetching
.TryDnD
CMP R0,#DragType_DragNDrop:BNE TryUserMes
ADD R1,R12,#RAMTransBufBase:BL SaveTheSelection
B Fetching
.TryUserMes
CMP R0,#DragType_User:BNE EndWimpMessage
ADD R1,R12,#RAMTransBufBase:BL SaveUserList ; heheheheh
.Fetching
LDR R0,[R12,#RAMTransPtr]:STR R0,[R12,#RAMTransSize]:MOV R0,#0:STR R0,[R12,#RAMTransPtr]
.AlreadyTransmitting
MOV R1,R6
LDR R0,[R1,#8]:STR R0,[R1,#12] ; your_ref = my_ref
LDR R2,[R1,#4] ; your_task
STMFD R13!,{R2}
LDR R3,[R1,#20]:LDR R4,[R1,#24] ; r3 = buffer, r4=numbytes
LDR R1,[R12,#RAMTransPtr]:LDR R5,[R12,#RAMTransSize]:SUB R5,R5,R1 ; get num to go
LDR R14,[R12,#RAMTransBufBase]:ADD R1,R1,R14 ; get address in r1
CMP R5,R4:MOVLE R4,R5 ; r4 is number of bytes to send
LDR R0,[R12,#TaskHandle]
SWI "Wimp_TransferBlock"
LDR R1,[R12,#RAMTransPtr]
ADD R1,R1,R4
STR R1,[R12,#RAMTransPtr]
LDR R14,[R12,#RAMTransSize]:CMP R1,R14 ;   FINISHED?
BNE Trannotfinned
LDR R0,[R12,#DragType]:CMP R0,#DragType_Clipboard
LDRNE R2,[R12,#RAMTransBufBase]:BLNE Release ; don't free the clipboard
MOV R0,#0:STR R0,[R12,#RAMTransBufBase]
CMP R0,R0
.Trannotfinned
MOV R1,R6:MOVNE R0,#18:MOVEQ R0,#17:STR R4,[R1,#24]:MOV R14,#Wimp_MRAMTransmit:STR R14,[R1,#16]
LDMFD R13!,{R2}
SWI "Wimp_SendMessage"
B EndWimpMessage

.RamTransmit
LDR R2,[R1,#4]:LDR R3,[R12,#TaskHandle]:CMP R2,R3:BNE DataIncoming
LDR R2,[R12,#RAMTransBufBase]:BL Release:ADR R0,RAMDied:BL Notify
MOV R0,#0:STR R0,[R12,#RAMTransBufBase]
B EndWimpMessage
.RAMDied EQUS "Reciever died during RAM transmission"+CHR$0:ALIGN
.DataIncoming
LDR R0,[R12,#RAMBuffer]:MOVS R0,R0:BEQ EndWimpMessage
LDR R2,[R1,#24]:MOVS R2,R2:BEQ EndOfTransfer
LDR R2,[R1,#24]:LDR R1,[R1,#20]:BL BufferAdd
CMP R2,#8192:LDREQ R1,[R12,#WimpArea]:BEQ SendRamFetch
.EndOfTransfer
ADR R14,EndOfTransfer_End
LDR PC,[R12,#EndRAMIn]
.EndOfTransfer_End
MOV R0,#0:STR R0,[R12,#EndRAMIn]
LDR R0,[R12,#RAMBuffer]:BL FreeBuffer
B EndWimpMessage

.DoMDSaveAck
MOV R6,R1
LDR R0,[R12,#DragType]
CMP R0,#DragType_Hot:BNE TryDnD2
MOV R0,#&80:ADD R1,R1,#44
SWI "OS_Find"
CMP R0,#0:BEQ EndWimpMessage
MOV R1,R0
BL SaveHotlist:B SaveAcked
.TryDnD2
CMP R0,#DragType_DragNDrop:BNE TryUser2
MOV R0,#&80:ADD R1,R1,#44
SWI "OS_Find"
CMP R0,#0:BEQ EndWimpMessage
MOV R1,R0
BL SaveTheSelection:B SaveAcked
.TryUser2
CMP R0,#DragType_User:BNE EndWimpMessage
MOV R0,#&80:ADD R1,R1,#44
SWI "OS_Find"
CMP R0,#0:BEQ EndWimpMessage
MOV R1,R0
BL SaveUserList
.SaveAcked
MOV R0,#0:SWI "OS_Find"
MOV R0,#18:ADD R1,R6,#44:MOV R2,#&F00:ORR R2,R2,#&FF:SWI "OS_File"
MOV R1,R6:MOV R0,#Wimp_MDataLoad:STR R0,[R1,#16]
MOV R0,#17:LDR R2,[R1,#20]:LDR R3,[R1,#24]:SWI "Wimp_SendMessage"
B EndWimpMessage
.TypeOfIRClientFile_User EQUS "# IRClient UserList"+CHR$0:ALIGN

.SaveUserList ; r1->file thing
STMFD R13!,{R0-R7,R14}
FNfunction("SaveUserList")
ADR R0,TypeOfIRClientFile_User:BL WriteLine
LDR R7,[R12,#SelectedChannel]:MOVS R7,R7:BEQ NoChanToSave
LDR R7,[R7,#Channel_Users]
.lp
MOVS R7,R7:BEQ NoChanToSave
LDR R0,[R7,#User_Flags]:TST R0,#U_Selected:LDREQ R7,[R7]:BEQ lp
LDR R0,[R7,#User_Name]:BL WriteLine
LDR R7,[R7]:B lp
.NoChanToSave
FNend
LDMFD R13!,{R0-R7,PC}^

.TypeOfIRClientFile_Hotlist EQUS "# IRClient Hotlist"+CHR$0:ALIGN
.SaveHotlist
STMFD R13!,{R0-R7,R14}
FNfunction("SaveHotlist")
ADR R0,TypeOfIRClientFile_User:BL WriteLine
LDR R7,[R12,#HotlistHead]
BL RecurseSaveHot
FNend
LDMFD R13!,{R0-R7,PC}^
._Y EQUS "Y"+CHR$0:ALIGN
._N EQUS "N"+CHR$0:ALIGN
.HotlistSaveStr EQUS "%s %s %s %s"+CHR$0:ALIGN
.RecurseSaveHot
MOVS R7,R7:MOVEQS PC,R14
STMFD   R13!,{R0-R7,R14}
LDR R7,[R7]:BL RecurseSaveHot
LDR R7,[R13,#7*4]
LDR R0,[R7,#Hotlist_Selected]:MOVS R0,R0:LDREQ R7,[R7]:BEQ lp
LDR R1,[R12,#LineBuf]:ADR R2,HotlistSaveStr
LDR R3,[R7,#Hotlist_Flag]:MOVS R3,R3:ADREQ R3,_N:ADRNE R3,_Y
LDR R4,[R7,#Hotlist_Address]:LDR R5,[R7,#Hotlist_Port]
LDR R6,[R7,#Hotlist_Comment]:BL String
MOV R0,R1:LDR R1,[R13,#4]:BL WriteLine
LDR R7,[R7]:B lp
LDMFD   R13!,{R0-R7,PC}^

.SaveWholeHotlist
STMFD R13!,{R0-R7,R14}
FNfunction("SaveWholeHotlist")
MOV R0,#&80:FNadr(1,HotlistFile):SWI "XOS_Find":MOV R1,R0:BVS foobedSave
BL SelectAllHotlist:BL SaveHotlist
MOV R0,#0:SWI "XOS_Find"
.foobedSave
FNend
LDMFD R13!,{R0-R7,PC}^

.SaveTheSelection ; r1->file thing
STMFD R13!,{R0-R7,R14}
FNfunction("SaveTheSelection")
LDR R7,[R12,#SelectedDisplay]:MOVS R7,R7:BEQ NothingToSave
ADD R0,R12,#StartLine AND &FF
ADD R0,R0,#StartLine AND &FF00
:LDMIA R0,{R0-R3}
CMP R0,R1:BLT SS
.REVERs2
EORGT R0,R0,R1:EORGT R1,R1,R0:EORGT R0,R0,R1
EORGT R2,R2,R3:EORGT R3,R3,R2:EORGT R2,R2,R3:BGT SS
CMP R2,R3:BGT REVERs2
.SS
MOV R5,R0:MOV R8,R2:MOV R6,R1
LDR R0,[R7,#Display_NumLines]:CMP R5,R0:MOVGT R5,R0:MOVGT R8,#80
.Yloop
CMP R5,R6:BGT EndOfSave
MOV R4,R8:MOV R8,#0:LDR R1,[R12,#LineBuf]
MOV R0,#0:STRB R0,[R1]
.Xloop
CMP R5,R6:BNE NotLastLineForXloop
CMP R4,R3:MOVGE R0,#0:STRGEB R0,[R1],#1:BGE EndOfXloop
.NotLastLineForXloop
BL GetCharFromDisplay:STRB R0,[R1],#1:MOVS R0,R0:BEQ EndOfXloop
ADD R4,R4,#1:B Xloop
.EndOfXloop
LDR R0,[R12,#LineBuf]:LDR R1,[R13,#4]
CMP R5,R6:BLNE WriteLine:BLEQ WriteLineNoCR
ADD R5,R5,#1
B Yloop
.EndOfSave
.NothingToSave
FNend
LDMFD R13!,{R0-R7,PC}^

.WriteLine ; r0->z/termed string, r1->fhandle, or ptr->memstruct
STMFD R13!,{R0-R7,R14}
FNfunction("WriteLine")
CMP R1,#&8000:BLT ItsAFileHandle
LDMIA R1,{R5-R7} ; R5=buf, r6=ptr, r7=size
MOVS R5,R5:BNE AlreadyGotABuf
MOV R3,#512:BL Claim:MOV R5,R2:MOV R6,#0:MOV R7,#512
.AlreadyGotABuf
SUB R2,R7,R6 ; r2 bytes left
BL GetStrLen:ADD R1,R1,#1:CMP R1,R2:BLT NoNeedToRealloc
MOV R2,R5:MOV R3,R7,LSL #1 ; size*=2
BL Realloc:MOV R5,R2:MOV R7,R3
.NoNeedToRealloc
ADD R4,R5,R6
.lp LDRB R14,[R0],#1:CMP R14,#0:CMPNE R14,#10:CMPNE R14,#13:MOVEQ R14,#10
STRB R14,[R4],#1:CMP R14,#10:BNE lp
SUB R6,R4,R5
LDR R1,[R13,#4]
STMIA R1,{R5-R7}
B EndWriteLine
.ItsAFileHandle
MOV R2,R1:BL GetStrLen:MOV R3,R1:MOV R1,R2:MOV R2,R0:MOV R0,#2
SWI "XOS_GBPB":MOV R0,#10:SWI "XOS_BPut"
.EndWriteLine
FNend
LDMFD R13!,{R0-R7,PC}^

.WriteLineNoCR ; r0->z/termed string, r1->fhandle, or ptr->memstruct
STMFD R13!,{R0-R7,R14}
FNfunction("WriteLineNoCR")
CMP R1,#&8000:BLT ItsAFileHandle2
LDMIA R1,{R5-R7} ; R5=buf, r6=ptr, r7=size
MOVS R5,R5:BNE AlreadyGotABuf2
MOV R3,#512:BL Claim:MOV R5,R2:MOV R6,#0:MOV R7,#512
.AlreadyGotABuf2
SUB R2,R7,R6 ; r2 bytes left
BL GetStrLen:ADD R1,R1,#1:CMP R1,R2:BLT NoNeedToRealloc2
MOV R2,R5:MOV R3,R7,LSL #1 ; size*=2
BL Realloc:MOV R5,R2:MOV R7,R3
.NoNeedToRealloc2
ADD R4,R5,R6
.lp LDRB R14,[R0],#1:CMP R14,#0:CMPNE R14,#10:CMPNE R14,#13:MOVEQ R14,#0
STRNEB R14,[R4],#1:CMP R14,#0:BNE lp
SUB R6,R4,R5
LDR R1,[R13,#4]
STMIA R1,{R5-R7}
B EndWriteLine2
.ItsAFileHandle2
MOV R2,R1:BL GetStrLen:MOV R3,R1:MOV R1,R2:MOV R2,R0:MOV R0,#2
SWI "XOS_GBPB"
.EndWriteLine2
FNend
LDMFD R13!,{R0-R7,PC}^

.DeSelPerson
STMFD R13!,{R0-R1,R14}
LDR R0,[R12,#MenuSelPerson]:MOVS R0,R0:BEQ EndDeSelPerson
LDR R1,[R0,#User_Flags]:BIC R1,R1,#U_Selected:STR R1,[R0,#User_Flags]
BL RedrawSingleUser
MOV R0,#0:STR R0,[R12,#MenuSelPerson]
.EndDeSelPerson
LDR R0,[R12,#MenuSelHot]:MOVS R0,R0:BEQ EndDeSelHot
MOV R1,#0:STR R1,[R0,#Hotlist_Selected]:BL RedrawSingleHotlist
MOV R0,#0:STR R0,[R12,#MenuSelPerson]
.EndDeSelHot
LDMFD R13!,{R0-R1,PC}^

.Win_Close
STMFD R13!,{R0-R7,R14}
FNfunction("Win_Close")
LDR R14,[R12,#ConfigFlag]:MOVS R14,R14:BEQ NotDieOnConfigClose
FNadr(0,PreferenceWindow+4):BL CheckSame:BNE NotDieOnConfigClose
MOV R0,#1:STR R0,[R12,#QuitFlag]:B EndWin_Close ; XXX PROBABLY WRONG
.NotDieOnConfigClose
LDR R0,[R1]:BL FindDisplay:MOVS R0,R0:BEQ NotADisplay
STMFD R13!,{R0}:MOV R7,#0:STR R7,[R0,#Display_Open]
LDR R0,[R0,#Display_Channel]:MOVS R7,R0:BEQ NotCloseToolbar
LDR R1,[R7,#Channel_Toolbar]:LDR R0,[R12,#EqHandle]:SWI "EqWimp_ShutWindow"
LDR R1,[R7,#Channel_UserBox]:LDR R0,[R12,#EqHandle]:SWI "EqWimp_ShutWindow"
LDR R1,[R12,#CurrentDisplay]:LDR R0,[R13]
CMP R0,R1:BNE NotCloseToolbar
MOV R0,#0:STR R0,[R12,#CurrentDisplay]
.NotCloseToolbar LDMFD R13,{R0}
LDR R0,[R0,#Display_What]
STMFD R13!,{R1}:FNadr(1,SerVa):BL CheckSame:LDMFD R13!,{R1}:BNE NoCloseServ
STMFD R13!,{R1}:FNadr(1,ChanPane):LDR R0,[R12,#EqHandle]:SWI "EqWimp_ShutWindow"
LDMFD R13!,{R1}
.NoCloseServ LDMFD R13!,{R0}
LDR R0,[R0,#Display_What]
LDRB R0,[R0]:CMP R0,#ASC"#" ; do we kill it or what?
LDREQ R1,[R13,#4]:BEQ NotADisplay
LDR R0,[R1]:BL KillDisplay
B EndWin_Close

.NotADisplay
LDR R0,[R12,#EqHandle]
SWI "EqWimp_CloseWindow"
.EndWin_Close
FNend
LDMFD R13!,{R0-R7,PC}^

.ChanPane EQUS "ChannelPane"+CHR$0:ALIGN
.Win_Open
STMFD R13!,{R0-R7,R14}
FNfunction("Win_Open")
LDR R0,[R1]:BL FindDisplay:MOVS R0,R0:BEQ EqWimpHandlesIt
MOV R7,R0
LDR R1,[R12,#WimpArea]:LDR R1,[R1,#28]
CMN R1,#3:MOVNE R1,#1:MOVEQ R1,#0:STR R1,[R7,#Display_Open]
LDR R0,[R0,#Display_What]:FNadr(1,SerVa):BL CheckSame:BNE NotServerWin
LDR R0,[R12,#EqHandle]:ADR R1,ChanPane:SWI "EqWimp_HandleFromName":MOV R0,R1
LDR R1,[R12,#WimpArea]
STMFD R13!,{R0}:LDR R6,[R1,#28]:STR R0,[R1,#28]
SWI "Wimp_OpenWindow":SWI "Wimp_GetWindowState"
LDMFD R13!,{R0}
ADD R2,R1,#32:STR R0,[R2]
STMFD R13!,{R0,R1}:MOV R1,R2:SWI "Wimp_GetWindowState":LDMFD R13!,{R0,R1}
LDR R4,[R2,#12]:LDR R3,[R2,#4]:SUB R4,R4,R3
LDR R3,[R1,#12]:ADD R3,R3,#44:STR R3,[R2,#4]
LDR R3,[R1,#8]:STR R3,[R2,#8]
LDR R3,[R2,#4]:ADD R3,R3,R4
LDR R14,[R12,#XExtent]:SUB R14,R14,#40:CMP R3,R14:BLT WereOkay2
MOV R3,R14:SUB R14,R3,R4:STR R14,[R2,#4]
.WereOkay2
STR R3,[R2,#12]
LDR R3,[R1,#16]:STR R3,[R2,#16]
STR R6,[R2,#28]
STR R0,[R1,#28]
MOV R1,R2
SWI "Wimp_OpenWindow"
LDR R1,[R12,#WimpArea]:SWI "Wimp_OpenWindow"
B EndWin_Open
.NotServerWin
MOV R0,R7:LDR R1,[R12,#WimpArea]
LDR R0,[R0,#Display_Channel]:MOVS R0,R0:BEQ EqWimpHandlesIt
LDR R5,[R0,#Channel_Toolbar]
LDR R0,[R0,#Channel_UserBox]:MOV R7,R0:LDR R6,[R1,#28]:STR R5,[R1,#28]
SWI "Wimp_OpenWindow":SWI "Wimp_GetWindowState"
MOV R0,R7
ADD R2,R1,#64:STR R0,[R2]
STMFD R13!,{R1}:MOV R1,R2:SWI "Wimp_GetWindowState":LDMFD R13!,{R1}
LDR R4,[R2,#12]:LDR R3,[R2,#4]:SUB R4,R4,R3
LDR R3,[R1,#12]:ADD R3,R3,#44:STR R3,[R2,#4]
LDR R3,[R1,#8]:STR R3,[R2,#8]
LDR R3,[R2,#4]:ADD R3,R3,R4
LDR R14,[R12,#XExtent]:SUB R14,R14,#40:CMP R3,R14:BLT WereOkay
MOV R3,R14:SUB R14,R3,R4:STR R14,[R2,#4]
.WereOkay
STR R3,[R2,#12]
LDR R3,[R1,#16]:STR R3,[R2,#16]
STR R6,[R2,#28]

ADD R2,R1,#32:STR R5,[R2]
LDR R3,[R1,#4]:STR R3,[R2,#4]
LDR R3,[R1,#8]:STR R3,[R2,#8]
LDR R3,[R1,#12]:STR R3,[R2,#12]
LDR R3,[R1,#16]:STR R3,[R2,#16]
MOV R3,#0:STR R3,[R2,#20]:STR R3,[R2,#24]:STR R7,[R2,#28]
STR R5,[R1,#28]
LDR R1,[R12,#WimpArea]:ADD R1,R1,#64:SWI "Wimp_OpenWindow"
LDR R1,[R12,#WimpArea]:ADD R1,R1,#32:SWI "Wimp_OpenWindow"
LDR R1,[R12,#WimpArea]:SWI "Wimp_OpenWindow"
B EndWin_Open
.EqWimpHandlesIt
LDR R0,[R12,#EqHandle]
SWI "EqWimp_OpenWindow"
.EndWin_Open
FNend
LDMFD R13!,{R0-R7,PC}^
.SerVa EQUS "##server##"+CHR$0:ALIGN

.FakeClick
STMFD R13!,{R0-R2,R14}
FNfunction("FakeClick")
LDR R1,[R12,#WimpArea]:LDR R2,[R12,#InputWind]:STR R2,[R1]
STR R0,[R1,#24]:BL Key_Click
FNend
LDMFD R13!,{R0-R2,PC}^

FNassembleMenus

FNassembleObject

FNassembleWindowManager

.CycleFocusForwards
STMFD   R13!,{R0-R7,R14}
LDR R7,[R12,#DisplayWithFocus]:MOVS R7,R7:BEQ EndCycleF
MOV R6,#0
.lp LDR R7,[R7]:MOVS R7,R7:LDREQ R7,[R12,#DisplayHead]:ADDEQ R6,R6,#1
CMP R6,#2:BEQ EndCycleF
LDR R0,[R7,#Display_What]
LDRB R1,[R0]:LDRB R2,[R0,#1]:CMP R1,#ASC"#":CMPEQ R2,#ASC"#":BEQ lp
LDR R1,[R7,#Display_Open]:MOVS R1,R1:BEQ lp
STR R0,Foo_Area+4
FNadr(0,DSelected):MOV R1,#1:FNadr(2,Foo_Area):BL ImplicitCallRootProcedure
.EndCycleF
LDMFD   R13!,{R0-R7,PC}^

.CycleFocusBackwards
STMFD   R13!,{R0-R7,R14}
LDR R5,[R12,#DisplayWithFocus]:MOVS R7,R5:BEQ EndCycleB
MOV R6,#0
.lp LDR R7,[R7]:MOVS R7,R7:LDREQ R7,[R12,#DisplayHead]:ADDEQ R6,R6,#1
CMP R6,#2:BEQ EndCycleB
LDR R1,[R7]:MOVS R1,R1:LDREQ R1,[R12,#DisplayHead]:CMP R1,R5:BNE lp
LDR R1,[R7,#Display_Open]:MOVS R1,R1
MOVEQ R5,R7:LDREQ R7,[R12,#DisplayHead]:BEQ lp
LDR R0,[R7,#Display_What]
LDRB R1,[R0]:LDRB R2,[R0,#1]:CMP R1,#ASC"#":CMPEQ R2,#ASC"#"
MOVEQ R5,R7:LDREQ R7,[R12,#DisplayHead]:BEQ lp
LDR R0,[R7,#Display_What]:STR R0,Foo_Area+4
FNadr(0,DSelected):MOV R1,#1:FNadr(2,Foo_Area):BL ImplicitCallRootProcedure
.EndCycleB
LDMFD   R13!,{R0-R7,PC}^

.Key_Click
STMFD R13!,{R0-R7,R14}
FNfunction("Key_Click")
LDR R1,[R12,#WimpArea]
LDR R0,[R1]:BL FindDisplay:MOVS R0,R0:BEQ NotInputPress
LDR R14,[R12,#WimpArea]
LDR R2,[R14,#24] ; r2 is the key press
CMP R2,#32:BGE NotCheck
MOV R3,R2
STMFD R13!,{R0-R1}
MOV R0,#129:MOV R1,#256-1:MOV R2,#255:SWI "OS_Byte":CMP R1,#255
ANDEQ R2,R3,#31:ADDEQ R2,R2,#&200:MOVNE R2,R3
LDMFD R13!,{R0-R1}
.NotCheck
STR R2,Ppp+12
LDR R2,[R0,#Display_What]:STR R2,Ppp+4
ADR R0,CharEntered
MOV R1,#2
ADR R2,Ppp
BL CallRootProcedure
B EndKeyClick
.CharEntered EQUS "CharEntered"+CHR$0:ALIGN
.Ppp EQUD fptrStr:EQUD 0:EQUD fptrNum:EQUD 0

.Proc_ProcessKey
STMFD R13!,{R14}
CMP R1,#1:BNE CrapParms
LDMIA R2,{R1,R2}
CMP R1,#fptrNum:BNE CrapParms
MOV R0,R2
SWI "Wimp_ProcessKey"
MOV R0,#0:LDMFD R13!,{PC}^

.Proc_SetInputText
STMFD R13!,{R14}
CMP R1,#1:BNE CrapParms
LDMIA R2,{R1,R2}
CMP R1,#fptrStr:BNE CrapParms
FNadr(1,InputBuffer)
MOV R3,#0:.lp LDRB R0,[R2],#1:STRB R0,[R1],#1:TEQ R0,#0:ADDNE R3,R3,#1:BNE lp
LDR R0,[R12,#CursorPos]:CMP R0,R1:STRGT R1,[R12,#CursorPos]
MOV R0,#0:LDMFD R13!,{PC}^

.Proc_SetCursorPos
STMFD R13!,{R14}
CMP R1,#1:BNE CrapParms
LDMIA R2,{R1,R2}
CMP R1,#fptrNum:BNE CrapParms
FNadr(0,InputBuffer):BL GetStrLen
CMP R2,R1:MOVGT R2,R1
STR R2,[R12,#CursorPos]
MOV R0,#0:LDMFD R13!,{PC}^

.Proc_RedrawInputBox
STMFD R13!,{R14}
CMP R1,#0:BNE CrapParms
BL UpdateInputBuffer
MOV R0,#0:LDMFD R13!,{PC}^

.NotInputPress
LDR R0,[R1]:BL FindChannelByToolbar:MOVS R0,R0:BEQ Moophi
LDR R14,[R12,#WimpArea]:LDR R1,[R14,#24]:CMP R1,#13:BNE PassOnMore
STMFD R13!,{R0}
LDR R0,[R12,#EqHandle]:LDR R1,[R14,#0]:LDR R2,[R14,#4]
SWI "EqWimp_ReadIconString":STR R1,Mank3a+12
LDMFD R13!,{R6}
LDR R0,[R6,#Channel_Name]:STR R0,Mank3a+4
FNadr(0,CTopic):MOV R1,#2:FNadr(2,Mank3a)
BL CallRootProcedure
FNadr(0,DSelected):MOV R1,#1:FNadr(2,Mank3a)
BL CallRootProcedure
B EndKeyClick
.Mank3a EQUD fptrStr:EQUD 0:EQUD fptrStr:EQUD 0
.Moophi
LDR R0,[R12,#EqHandle]
LDR R4,[R1]:CMN R4,#1:BEQ PassOnMore
SWI "EqWimp_ProcessKey"
CMP R0,#0:BEQ PassOnMore
STMFD R13!,{R2}
ADR R14,ICNBuf:.lp LDRB R0,[R2],#1:STRB R0,[R14],#1:MOVS R0,R0:BNE lp
LDMFD R13!,{R2}
LDR R0,[R12,#EqHandle]:STR R0,ClosedFlag
STMFD R13!,{R1,R2}
SWI "EqWimp_ClickOnIcon"
LDMFD R13!,{R1,R2}
STMFD R13!,{R0-R2}
LDR R0,[R12,#EqHandle]
ADR R3,Select:BL Clicked
LDMFD R13!,{R0-R2}
CMP R0,#0:BEQ EndKeyClick
LDR R0,ClosedFlag:MOVS R0,R0:LDRNE R0,[R12,#EqHandle]:ADR R2,ICNBuf
SWINE "EqWimp_DeselectIcon"
.EndKeyClick
FNend
LDMFD R13!,{R0-R7,PC}^
.Select EQUS "Select"+CHR$0:ALIGN
.ICNBuf FNres(64)
.ClosedFlag EQUD 1
.PassOnMore
LDR R1,[R12,#WimpArea]:LDR R0,[R1,#24]:SWI "Wimp_ProcessKey"
B EndKeyClick

.UpdateInputBuffer
STMFD R13!,{R0-R7,R14}
FNfunction("UpdateInputBuffer")
FNadr(0,InputBox):BL FindDisplayByName:MOVS R7,R0:BEQ EndUpdateInputBuffer
LDR R1,[R0,#Display_NumLines]
LDR R0,[R0,#Display_LineAddrs]:MOV R4,#0:.clrlp LDR R2,[R0]:MOVS R2,R2:BLNE Release
STR R4,[R0],#4:SUBS R1,R1,#1:BNE clrlp
FNadr(0,InputBuffer)
FNmov(1,MenuArea) ; ovfs over WimpArea
LDR R3,[R12,#CursorPos]
LDR R2,[R12,#PreInsert]:MOVS R2,R2:BEQ NoPreInsert
.floozle LDRB R14,[R2],#1:STRB R14,[R1]:MOVS R14,R14:ADDNE R1,R1,#1:BNE floozle
.NoPreInsert
MOVS R3,R3:BEQ PutInCursor
.FriendlyLoop
LDRB R14,[R0],#1:STRB R14,[R1],#1:SUBS R3,R3,#1:BNE FriendlyLoop
.PutInCursor
MOV R14,#30:STRB R14,[R1],#1
.Cont
LDRB R14,[R0],#1:STRB R14,[R1],#1:MOVS R14,R14:BNE Cont
FNmov(0,MenuArea)
MOV R1,#1 ; redraw
BL InsertIntoDisplay
.EndUpdateInputBuffer
FNend
LDMFD R13!,{R0-R7,PC}^

.Mouse_Click
STMFD R13!,{R0-R7,R14}
FNfunction("Mouse_Click")
LDR R0,[R12,#EqHandle]:SWI "EqWimp_MouseClick"
LDR R0,[R12,#EqHandle]
BL Clicked
FNend
LDMFD R13!,{R0-R7,PC}^

.ClearDisplaySelection
STMFD R13!,{R0-R3,R14}
FNfunction("ClearDisplaySelection")
LDR R1,[R12,#SelectedDisplay]:MOVS R1,R1:BEQ EndClearDS
BL RedrawSelectedArea
MOV R0,#0:STR R0,[R12,#SelectedDisplay]
.EndClearDS
FNend
LDMFD R13!,{R0-R3,PC}^

.Clicked ; r0=eqhandle, r1=Window, r2=icon, r3=button
STMFD R13!,{R0-R7,R14}
FNfunction("Clicked")

MOV R0,#0:STR R0,[R12,#MenuChannel]

; Check for clicks in displays
MOV R0,R1
BL FindChannelByUserBox:MOVS R0,R0:BLNE UserPaneClick:BNE EndClick
MOV R0,R1
BL FindChannelByToolbar:MOVS R0,R0:BEQ NotATB
STR R0,[R12,#CurrentTB]:FNadr(1,ChanName)
B NotADisplayClick ; bodge
.NotATB
MOV R0,R1
BL FindDisplay:MOVS R7,R0:BEQ NotADisplayClick
FNadr(0,InputBox):BL FindDisplayByName:MOVS R0,R0:BEQ NotADisplayClick
LDRB R14,[R3]:CMP R14,#ASC"M":BNE NotDisplayMenu
LDR R1,[R7,#Display_Channel]:MOVS R1,R1:STRNE R1,[R12,#SelectedChannel]
LDR R1,[R7,#Display_What]:STR R1,[R12,#MenuParameter]
FNadr(14,WhichCTCPFlag)
MOVNE R1,#0:MOVEQ R1,#1:STR R1,[R14] ; atm just a channel
ADR R0,DispMenu
BL CreateAndOpenMenuAtMouse
B EndClick
.NotDisplayMenu
MOV R0,#129:MOV R1,#256-2:MOV R2,#255:SWI "OS_Byte":CMP R1,#255:BEQ ChangleDangle
LDR R1,[R12,#CurrentDisplay]:CMP R7,R1:BEQ ChangleDangle
STR R7,[R12,#CurrentDisplay]
LDR R0,[R7,#Display_What]:FNadr(1,InputBox):BL CheckSame:;BEQ EndClick
STR R0,Foo_Area+4
ADR R0,DSelected:MOV R1,#1:ADR R2,Foo_Area:BL CallRootProcedure
.ChangleDangle
LDR R0,[R12,#WimpArea]
LDR R0,[R0,#8]
CMP R0,#256:BLEQ GetXY:BEQ AdjustDrag
CMP R0,#4:CMPNE R0,#1:BNE NotDClick
BL ClearDisplaySelection
STR R7,[R12,#SelectedDisplay]
BL GetXY:STR R5,[R12,#StartLine]:STR R5,[R12,#EndLine]
BL GetCharFromDisplay:CMP R0,#0:CMPNE R0,#32 ; we are on a space - sulk
BEQ EndClick:.lp SUBS R4,R4,#1:BEQ FoundSpacePlusOne
BL GetCharFromDisplay:CMP R0,#32:BNE lp
ADD R4,R4,#1
.FoundSpacePlusOne
STR R4,[R12,#StartChar]
.lp ADD R4,R4,#1:CMP R4,#80:BEQ FoundEndSpaceMinusOne
BL GetCharFromDisplay:CMP R0,#0:BEQ FoundEndSpaceMinusOne:CMP R0,#32:BNE lp:;SUB R4,R4,#1
.FoundEndSpaceMinusOne
STR R4,[R12,#EndChar]
BL RedrawSelectedArea
B EndClick
.NotDClick
CMP R0,#64:CMPNE R0,#16:BNE EndClick
; Drag handler - aaargh!
BL GetXY
CMP R0,#64:BNE AdjustDrag
LDR R0,[R12,#SelectedDisplay]:CMP R0,R7:BNE FlambleMamble
ADD R0,R12,#StartLine AND &FF
ADD R0,R0,#StartLine AND &FF00
LDMIA R0,{R0-R3}
CMP R0,R1:BLT CheckForInsideSelection
.REVERs
EORGT R0,R0,R1:EORGT R1,R1,R0:EORGT R0,R0,R1
EORGT R2,R2,R3:EORGT R3,R3,R2:EORGT R2,R2,R3:BGT CheckForInsideSelection
CMP R2,R3:BGT REVERs
.CheckForInsideSelection
CMP R5,R0:BLT FlambleMamble:BGT OKsofar
CMP R4,R2:BLT FlambleMamble
.OKsofar
CMP R5,R1:BGT FlambleMamble:BLT StartDraggingText
CMP R4,R3:BGT FlambleMamble
.StartDraggingText
MOV R0,#DragType_DragNDrop:STR R0,[R12,#DragType]:STR R0,[R12,#DragFlag]
MOV R0,#0:STR R0,[R12,#DnD_Claimant]
STR R0,[R12,#DnD_DragFinished]
STR R0,[R12,#DnD_DragAborted]
STR R0,[R12,#DnD_LastRef]
LDR R0,[R12,#EqHandle]:SWI "EqWimp_MouseInfo":LDR R3,[R12,#WimpArea]
STMIA R3!,{R1,R2}:STMIA R3,{R1,R2}:SUB R3,R3,#8
MOV R0,#197:MOV R1,#1:ADR R2,file_fff
SWI "DragASprite_Start"
B EndClick
.file_fff EQUS "file_fff"+CHR$0:ALIGN
.FlambleMamble
BL ClearDisplaySelection
STR R7,[R12,#SelectedDisplay]
STR R5,[R12,#StartLine]:STR R4,[R12,#StartChar]
STR R5,[R12,#EndLine]:STR R4,[R12,#EndChar]
.DrawyPoos
BL RedrawSelectedArea
LDR R1,[R7,#Display_Wind]
LDR R0,[R12,#WimpArea]:STR R1,[R0,#20]:ADD R1,R0,#20
SWI "Wimp_GetWindowState"
LDR R1,[R12,#WimpArea]:MOV R0,#7:STR R0,[R1,#4]:SWI "Wimp_DragBox"
MOV R0,#DragType_Selection:STR R0,[R12,#DragType]
MVN R0,#0:STR R0,[R12,#DragFlag]:STR R7,[R12,#DraggingDisplay]
SWI "Wimp_DragBox"
B EndClick
.DSelected EQUS "DisplaySelected"+CHR$0:ALIGN
.Foo_Area EQUD fptrStr:EQUD 0
.DispMenu EQUS "_Display"+CHR$0:ALIGN
.AdjustDrag
LDR R0,[R12,#SelectedDisplay]:CMP R0,R7:BNE FlambleMamble
BL RedrawSelectedArea
LDR R0,[R12,#StartLine] : LDR R1,[R12,#StartChar]
LDR R2,[R12,#EndLine]   : LDR R3,[R12,#EndChar]
CMP R0,R2:BEQ HaveToCharCheck
BLT StartLtEnd
.StartGtEnd
CMP R5,R0:BGT PutItInStart
BLT PutItInEnd:CMP R4,R1:BGT PutItInStart
.Wideboy
CMP R5,R2:BGT PutItInEnd:BLT PutItInStart
CMP R4,R3:BGT PutItInStart
.PutItInEnd
STR R4,[R12,#EndChar]:STR R5,[R12,#EndLine]
B DrawyPoos

.HaveToCharCheck CMP R1,R3:BGT StartGtEnd
.StartLtEnd
CMP R5,R2:BLT PutItInStart
BGT PutItInEnd:CMP R4,R3:BLT PutItInStart
.Wideboy
CMP R5,R0:BLT PutItInEnd:BGT PutItInStart
CMP R4,R1:BGT PutItInEnd
.PutItInStart
STR R2,[R12,#StartLine]:STR R3,[R12,#StartChar]
B DrawyPoos

.NotADisplayClick
FNadr(0,Iconbar):BL CheckEqual:BEQ Iconbarclick
ADR R5,WindowIconList
.FindWinLoop
LDR R4,[R5]:MOVS R4,R4:BEQ EndClick ; not found
ADD R0,R5,#4 ; window name
BL CheckEqual:ADDNE R5,R5,R4:BNE FindWinLoop
BL Ffwd:MOV R5,R0 ; R5 points to first name

MOV R1,R2 ; r1 is now icon name
.FindIconLoop
LDR R4,[R5]:MOVS R4,R4:BEQ TryDragging ; not found
LDRB R14,[R5]:CMP R14,#ASC"*":BLEQ Ffwd:BEQ Wild_Match
MOV R0,R5:BL CheckEqual:BL Ffwd:ADDNE R5,R0,#4:BNE FindIconLoop
.Wild_Match
ADR R14,EndClick:MOV R1,R0:LDRB R0,[R3]:CMP R0,#ASC"S":LDR PC,[R1]
; so routine is called with 'EQ' on select, NE otherwise, R0 is first char of thingy

.TryDragging
LDRB R0,[R3]:CMP R0,#ASC"M":BEQ EndClick
LDR R0,[R12,#EqHandle]:LDR R1,[R13,#4]:LDR R2,[R13,#8]
SWI "EqWimp_UsefulButton"
MOVS R1,R1:LDREQ R1,[R13,#4]
SWIEQ "XEqWimp_DragWindow"

.EndClick
FNend
LDMFD R13!,{R0-R7,PC}^

.GetCharFromDisplay
STMFD R13!,{R1-R7,R14}
FNfunction("GetCharFromDisplay")
LDR R0,[R7,#Display_NumLines]:CMP R5,R0:MOVGE R0,#0:BGE EndOLine
LDR R0,[R7,#Display_LineAddrs]:ADD R0,R0,R5,LSL #2:LDR R0,[R0]:MOVS R0,R0:BEQ EndOLine
MOV R1,R0:MOV R0,R4:MOV R2,#0:MOV R3,#0:SWI "ZapRedraw_FindCharacter"
LDRB R0,[R1]:CMP R0,#0:BNE EndOLine
LDRB R0,[R1,#1]:CMP R0,#2:MOVEQ R0,#0:BEQ EndOLine
CMP R0,#3:LDREQB R0,[R1,#2]:BEQ EndOLine
CMP R0,#4:MOVNE R0,#0:BNE EndOLine
LDRB R0,[R1,#4]
TEQ R0,#0:LDREQ R0,[R1,#6] ; 0,3,l
.EndOLine
FNend
LDMFD R13!,{R1-R7,PC}^

.Ffwd ; ffwds r0 past a string, and word aligns it
STMFD R13!,{R14}
FNfunction("Ffwd")
.Beedle LDRB R14,[R0],#1:MOVS R14,R14:BNE Beedle:ADD R0,R0,#3:BIC R0,R0,#3
FNend
LDMFD R13!,{PC}^

.WindowIconList
.PreferenceWindow
EQUD (PrefPanew-WindowIconList)
EQUS "Preferences"+CHR$0:ALIGN
EQUS "OK"+CHR$0:ALIGN                       : EQUD PrefsOK
.Cancel EQUS "Cancel"+CHR$0:ALIGN           : EQUD PrefsCancel
EQUS "LaunchHelp"+CHR$0:ALIGN               : EQUD LaunchHelp
EQUS "Save"+CHR$0:ALIGN                     : EQUD SaveOptions
EQUD 0
.PrefPanew
EQUD (AYSWindow-PrefPanew)
EQUS "PrefPane"+CHR$0:ALIGN
EQUS "EditColours"+CHR$0:ALIGN              : EQUD EditColours
EQUS "Hotlist"+CHR$0:ALIGN                  : EQUD PrefHotlist
EQUS "BitList"+CHR$0:ALIGN                  : EQUD ShowBitList
EQUD 0
.AYSWindow
EQUD (ConnectWindow-AYSWindow)
EQUS "AreYouSure"+CHR$0:ALIGN
EQUS "Yes"+CHR$0:ALIGN                      : EQUD Yes_Clicked
EQUS "No"+CHR$0:ALIGN                       : EQUD No_Clicked
EQUD 0
.ConnectWindow
EQUD (ConnectingWindow-ConnectWindow)
EQUS "Connect"+CHR$0:ALIGN
EQUS "Connect"+CHR$0:ALIGN                  : EQUD Connect
EQUS "Hotlist"+CHR$0:ALIGN                  : EQUD ConnectHotlist
EQUD 0
.ConnectingWindow
EQUD (InfoWindow-ConnectingWindow)
EQUS "Connecting"+CHR$0:ALIGN
EQUS "Abort"+CHR$0:ALIGN                    : EQUD AbortConnection
EQUD 0
.InfoWindow
EQUD (ColWindow-InfoWindow)
EQUS "Info"+CHR$0:ALIGN
EQUS "LaunchHelp"+CHR$0:ALIGN               : EQUD LaunchHelp
EQUD 0
.ColWindow
EQUD (PaletteWindow-ColWindow)
EQUS "Colour"+CHR$0:ALIGN
.Foreground   EQUS "Foreground"+CHR$0:ALIGN : EQUD ChangeFore
.Background   EQUS "Background"+CHR$0:ALIGN : EQUD ChangeBack
.CurForeST    EQUS "CurFore"+CHR$0:ALIGN    : EQUD ChangeCurFore
.CurBackST    EQUS "CurBack"+CHR$0:ALIGN    : EQUD ChangeCurBack
.SelForeST    EQUS "SelFore"+CHR$0:ALIGN    : EQUD ChangeSelFore
.SelBackST    EQUS "SelBack"+CHR$0:ALIGN    : EQUD ChangeSelBack
.CTCPST       EQUS "CTCPColour"+CHR$0:ALIGN : EQUD ChangeCTCPCol
.MeST         EQUS "MeColour"+CHR$0:ALIGN   : EQUD ChangeMeCol
EQUD 0
.PaletteWindow
EQUD (ChanWindow-PaletteWindow)
EQUS "Palette"+CHR$0:ALIGN
]FOR N%=0TO15:[OPT pass%:EQUS STR$ N%+CHR$0:ALIGN:EQUD Pal(N%):]:NEXT:[OPT pass%
EQUD 0
.ChanWindow
EQUD (AlertWindow-ChanWindow)
.ChanName EQUS "Channel"+CHR$0:ALIGN
.plusT EQUS "ChanOpTopic"+CHR$0:ALIGN              : EQUD RadioPlusT
.plusN EQUS "NoOutside"+CHR$0:ALIGN                : EQUD RadioPlusN
.plusI EQUS "Invite"+CHR$0:ALIGN                   : EQUD RadioPlusI
.plusM EQUS "Moderated"+CHR$0:ALIGN                : EQUD RadioPlusM
.plusS EQUS "Secret"+CHR$0:ALIGN                   : EQUD RadioPlusS
.plusP EQUS "Private"+CHR$0:ALIGN                  : EQUD RadioPlusP
.plusL EQUS "Limit"+CHR$0:ALIGN                    : EQUD RadioPlusL
EQUD 0
.AlertWindow
EQUD (Join_Channel-AlertWindow)
EQUS "Alert"+CHR$0:ALIGN
EQUS "Quit"+CHR$0:ALIGN                     : EQUD AlertQuit
EQUS "Continue"+CHR$0:ALIGN                 : EQUD AlertContinue
EQUD 0
.Join_Channel
EQUD (HotlistWindow-Join_Channel)
.JoinChannel EQUS "JoinChannel"+CHR$0:ALIGN
EQUS "Join"+CHR$0:ALIGN                     : EQUD JoinJoin
EQUS "Cancel"+CHR$0:ALIGN                   : EQUD JoinCancel
EQUD 0
.HotlistWindow
EQUD (NewHotWindow-HotlistWindow)
EQUS "Hotlist"+CHR$0:ALIGN
EQUS "*"+CHR$0:ALIGN                        : EQUD HotlistClick
EQUD 0
.NewHotWindow
EQUD (TopWindow-NewHotWindow)
EQUS "NewHotlist"+CHR$0:ALIGN
EQUS "Cancel"+CHR$0:ALIGN                   : EQUD CloseNewHot
EQUS "Done"+CHR$0:ALIGN                     : EQUD DoneHotList
EQUD 0
.TopWindow
EQUD (ChannelPane-TopWindow)
EQUS "ChangeTopic"+CHR$0:ALIGN
EQUS "Cancel"+CHR$0:ALIGN                   : EQUD CancTopic
EQUS "Change"+CHR$0:ALIGN                   : EQUD ChangeTopic
EQUD 0
.ChannelPane
EQUD (ByTheWayWindow-ChannelPane)
EQUS "ChannelPane"+CHR$0:ALIGN
EQUS "*"+CHR$0:ALIGN                        : EQUD ChanPaneClick
EQUD 0
.ByTheWayWindow
EQUD (EndWindow-ByTheWayWindow)
EQUS "ByTheWay"+CHR$0:ALIGN
EQUS "Dismiss"+CHR$0:ALIGN                  : EQUD DismissNote
EQUD 0
.EndWindow EQUD 0

]FOR N%=0TO15:[OPT pass%
.Pal(N%)
STMFD R13!,{R14}
FNadr(0,ColourAddr):LDR R0,[R0]:MOV R1,#N%:STR R1,[R0]
LDR R0,[R12,#EqHandle]:FNadr(1,PaletteWindow+4):SWI "EqWimp_ShutWindow"
BL SetColours
LDMFD R13!,{PC}^
]:NEXT:[OPT pass%

.BingleBongle EQUD fptrStr:EQUD 0:EQUD fptrNum:EQUD 0:EQUD fptrNum:EQUD 0
.ChannelStateChange EQUS "ChannelStateChange"+CHR$0:ALIGN

.DismissNote
STMFD   R13!,{R0-R7,R14}
LDR     R0,[R12,#EqHandle]
FNadr(1,ByTheWayWindow+4)
SWI     "EqWimp_ShutWindow"
LDMFD   R13!,{R0-R7,PC}^

.RadioPlusT
STMFD R13!,{R0-R7,R14}
FNradio(plusT,"t")
LDMFD R13!,{R0-R7,PC}^

.RadioPlusN
STMFD R13!,{R0-R7,R14}
FNradio(plusN,"n")
LDMFD R13!,{R0-R7,PC}^

.RadioPlusI
STMFD R13!,{R0-R7,R14}
FNradio(plusI,"i")
LDMFD R13!,{R0-R7,PC}^

.RadioPlusM
STMFD R13!,{R0-R7,R14}
FNradio(plusM,"m")
LDMFD R13!,{R0-R7,PC}^

.RadioPlusS
STMFD R13!,{R0-R7,R14}
FNradio(plusS,"s")
LDMFD R13!,{R0-R7,PC}^

.RadioPlusP
STMFD R13!,{R0-R7,R14}
FNradio(plusP,"p")
LDMFD R13!,{R0-R7,PC}^

.RadioPlusL
STMFD R13!,{R0-R7,R14}
FNradio(plusL,"l")
LDMFD R13!,{R0-R7,PC}^

.ChanPaneClick
STMFD R13!,{R0-R7,R14}
FNfunction("ChanPaneClick")
LDR R1,[R12,#WimpArea]
LDR R3,[R1,#0]:LDR R4,[R1,#4]:LDR R8,[R1,#8]
LDR R2,[R1,#12]:STR R2,[R1]
SWI "Wimp_GetWindowState"
LDR R14,[R1,#4]:SUB R3,R3,R14:LDR R14,[R1,#16]:SUB R4,R4,R14
LDR R14,[R1,#24]:ADD R4,R4,R14
ADDS R4,R4,#12:BGE MissedAChan
FNadr(5,ChanIconYSize):LDR R5,[R5]
LDR R7,[R12,#ChannelHead]:MOVS R7,R7:BEQ MissedAChan
.SearchChanPaneList
MOVS R7,R7:BNE NotAtEndOfCPListYet
.MissedAChan
TEQ R8,#2:BNE EndCPC
.ChannnMenu
STR R7,[R12,#SelectedChannel]:MOVS r7,r7
FNadr(0,Blank2)
LDRNE R0,[R7,#Channel_Name]
STR R0,[R12,#MenuParameter]
ADR R0,ChanMenu:BL CreateAndOpenMenuAtMouse
B EndCPC
.NotAtEndOfCPListYet
ADDS R4,R4,R5:LDRLE R7,[R7]:BLE SearchChanPaneList
CMP R4,#8:BLE MissedAChan
CMP R8,#2:BNE NotChanMenu
B ChannnMenu
.NotChanMenu
CMP R8,#4:BNE EndCPC
LDR R0,[R7,#Channel_Name]:BL FindDisplayByName:LDR R0,[R0,#Display_Wind]
LDR R1,[R12,#WimpArea]:STR R0,[R1]:SWI "Wimp_GetWindowState":MVN R0,#0:STR R0,[R1,#28]
BL Win_Open

.EndCPC
FNend
LDMFD R13!,{R0-R7,PC}^
.ChanMenu EQUS "_Channel"+CHR$0:ALIGN

.CloseNewHot
STMFD R13!,{R0-R7,R14}
FNfunction("CloseNewHot")
LDR R0,[R12,#EqHandle]:FNadr(1,NewHotlistS):SWI "EqWimp_ShutWindow"
FNend
LDMFD R13!,{R0-R7,PC}^

.GetXY
STMFD R13!,{R0-R3,R6,R7,R14}
FNfunction("GetXY")
LDR R1,[R12,#WimpArea]:LDMIA R1,{R4,R5}
LDR R0,[R7,#Display_Wind]:STR R0,[R1]
SWI "Wimp_GetWindowState"
LDR R2,[R1,#4]:LDR R3,[R1,#20]  :SUB R2,R2,R3:SUB R4,R4,R2
LDR R2,[R1,#16]:LDR R3,[R1,#24] :SUB R2,R2,R3:SUB R5,R2,R5
MOV R4,R4,LSR #4:MOV R0,R5
MOV R1,#36
BL DivMod:MOV R5,R0
LDR R1,[R7,#Display_NumLines]:CMP R5,R1:MOVGT R4,#0:BGT EndGetXY
LDR R1,[R7,#Display_LineAddrs]:ADD R1,R1,R5,LSL #2:LDR R1,[R1]:MOVS R1,R1
MOVEQ R4,#0
.EndGetXY
FNend
LDMFD R13!,{R0-R3,R6,R7,PC}^

.ShowBitList
STMFD R13!,{R0-R7,R14}
FNfunction("ShowBitList")
ADR R0,FontList:BL CreateAndOpenMenuAtMouse
FNend
LDMFD R13!,{R0-R7,PC}^
.FontList EQUS "_FontList"+CHR$0:ALIGN

.Do_Kick
STMFD R13!,{R0-R7,R14}
FNfunction("Do_Kick")
LDR R7,[R12,#SelectedChannel]:STR R7,FooBloq2+4
LDR R2,[R7,#Channel_Users]
.lp MOVS R2,R2:BEQ EndKick:LDR R0,[R2,#User_Name]:STR R0,FooBloq2+12
LDR R7,[R2]
LDR R14,[R2,#User_Flags]:TST R14,#U_Selected
ADR R0,KICKfun:MOV R1,#2:ADR R2,FooBloq2
BLNE CallRootProcedure:MOV R2,R7:B lp
.EndKick
FNend
LDMFD R13!,{R0-R7,PC}^
.KICKfun EQUS "Kick"+CHR$0:ALIGN
.FooBloq2 EQUD fptrStr:EQUD 0:EQUD fptrStr:EQUD 0

.CTCP
STMFD R13!,{R0-R7,R14}
FNfunction("CTCP")
STR R0,FooBloq+4
LDR R7,[R12,#SelectedChannel]
LDR R1,WhichCTCPFlag:CMP R1,#1:BEQ UserCTCPs
LDR R0,[R7,#Channel_Name]:STR R0,FooBloq+12
ADR R0,CTCPfun:MOV R1,#2:ADR R2,FooBloq
BL CallRootProcedure:B EndCTCP
.UserCTCPs
LDR R2,[R7,#Channel_Users]
.lp MOVS R2,R2:BEQ EndCTCP:LDR R0,[R2,#User_Name]:STR R0,FooBloq+12
LDR R7,[R2]
LDR R14,[R2,#User_Flags]:TST R14,#U_Selected
ADR R0,CTCPfun:MOV R1,#2:ADR R2,FooBloq
BLNE CallRootProcedure:MOV R2,R7:B lp
.EndCTCP
FNend
LDMFD R13!,{R0-R7,PC}^
.CTCPfun EQUS "CTCPrequest"+CHR$0:ALIGN
.FooBloq EQUD fptrStr:EQUD 0:EQUD fptrStr:EQUD 0
.WhichCTCPFlag EQUD 0

.ClearUsers
STMFD R13!,{R0-R7,R14}
FNfunction("ClearUsers")
LDR R7,[R12,#SelectedChannel]:MOVS R7,R7:BEQ EndClearUsers
LDR R7,[R7,#Channel_Users]
.CUlp
MOVS R7,R7:BEQ EndClearUsers
LDR R0,[R7,#User_Flags]:TST R0,#U_Selected
BIC R0,R0,#U_Selected:STR R0,[R7,#User_Flags]
MOVNE R0,R7:BLNE RedrawSingleUser
LDR R7,[R7]:B CUlp
.EndClearUsers
FNend
LDMFD R13!,{R0-R7,PC}^

.SelectAllUsers
STMFD R13!,{R0-R7,R14}
FNfunction("SelectAllUsers")
LDR R7,[R12,#SelectedChannel]:MOVS R7,R7:BEQ EndSAU
LDR R7,[R7,#Channel_Users]
.SAUlp
MOVS R7,R7:BEQ EndSAU
LDR R0,[R7,#User_Flags]:TST R0,#U_Selected
ORR R0,R0,#U_Selected:STR R0,[R7,#User_Flags]
MOVEQ R0,R7:BLEQ RedrawSingleUser
LDR R7,[R7]:B SAUlp
.EndSAU
MOV R0,#0:STR R0,[R12,#MenuSelPerson]
FNend
LDMFD R13!,{R0-R7,PC}^

.ClearHotlist
STMFD R13!,{R0-R7,R14}
FNfunction("ClearHotlist")
LDR R7,[R12,#HotlistHead]
.CHlp
MOVS R7,R7:BEQ EndCHlp
LDR R0,[R7,#Hotlist_Selected]:MOVS R0,R0:MOVNE R0,#0:STRNE R0,[R7,#Hotlist_Selected]
MOVNE R0,R7:BLNE RedrawSingleHotlist
LDR R7,[R7]:B CHlp
.EndCHlp
FNend
LDMFD R13!,{R0-R7,PC}^

.SelectAllHotlist
STMFD R13!,{R0-R7,R14}
FNfunction("SelectAllHotlist")
LDR R7,[R12,#HotlistHead]
.CHlp2
MOVS R7,R7:BEQ EndCHlp2
LDR R0,[R7,#Hotlist_Selected]:MOVS R0,R0:MOVEQ R0,#1:STREQ R0,[R7,#Hotlist_Selected]
MOVEQ R0,R7:BLEQ RedrawSingleHotlist
LDR R7,[R7]:B CHlp2
.EndCHlp2
MOV R0,#0:STR R0,[R12,#MenuSelHot]
FNend
LDMFD R13!,{R0-R7,PC}^

.DoneHotList
STMFD R13!,{R0-R7,R14}
FNfunction("DoneHotlist")
LDR R0,[R12,#EqHandle]:FNadr(1,NewHotlistS):SWIEQ "EqWimp_ShutWindow"
LDR R7,[R12,#Hotlist_Editing]:MOVS R7,R7:BLNE KillHotlistEntry
FNadr(1,NewHotlistS):FNadr(2,Port):SWI "EqWimp_ReadIconString":MOV R4,R1 ; port
FNadr(1,NewHotlistS):FNadr(2,Server):SWI "EqWimp_ReadIconString":MOV R5,R1
FNadr(1,NewHotlistS):FNadr(2,IsIRC):SWI "EqWimp_ReadIconState":MOV R6,R3 ; flag
ADR R2,Comment:SWI "EqWimp_ReadIconString":MOV R3,R1 ; comment
MOV R1,R5:MOV R2,R4:MOV R0,R6:BL NewHotlistEntry
BL RecalcHotsize
FNadr(1,HotlistWindow+4):LDR R0,[R12,#EqHandle]:SWI "EqWimp_RedrawWholeWindow"
FNend
LDMFD R13!,{R0-R7,PC}^

.DelHotlist
STMFD R13!,{R0-R7,R14}
LDR R7,[R12,#HotlistHead]
.lp MOVS R7,R7:BEQ EndDelHot:LDR R6,[R7]:LDR R0,[R7,#Hotlist_Selected]:MOVS R0,R0
BLNE KillHotlistEntry
MOV R7,R6:B lp
.EndDelHot
BL RecalcHotsize
FNadr(1,HotlistWindow+4):LDR R0,[R12,#EqHandle]:SWI "EqWimp_RedrawWholeWindow"
LDMFD R13!,{R0-R7,PC}^

.EditHotlist
STMFD R13!,{R0-R7,R14}
LDR R7,[R12,#HotlistHead]
.lp MOVS R7,R7:BEQ EndEdHot:LDR R0,[R7,#Hotlist_Selected]:MOVS R0,R0:LDREQ R7,[R7]:BEQ lp
LDR R0,[R12,#EqHandle]:ADR R1,NewHotlistS:SWI "EqWimp_ShutWindow"
ADR R2,EdHotli:SWI "EqWimp_WriteWindowName"
FNadr(2,Port):LDR R3,[R7,#Hotlist_Port]:SWI "EqWimp_WriteStringToIcon"
ADR R2,Comment:LDR R3,[R7,#Hotlist_Comment]:SWI "EqWimp_WriteStringToIcon"
FNadr(2,IsIRC):LDR R3,[R7,#Hotlist_Flag]:MOVS R3,R3:SWIEQ "EqWimp_DeselectIcon"
SWINE "EqWimp_SelectIcon"
FNadr(2,Server):LDR R3,[R7,#Hotlist_Address]:SWI "EqWimp_WriteStringToIcon"
SWI "EqWimp_PutAtFrontAndCentre"
BL PutCaret
STR R7,[R12,#Hotlist_Editing]
.EndEdHot
LDMFD R13!,{R0-R7,PC}^
.NewHotlistS EQUS "NewHotlist"+CHR$0:ALIGN
.EdHotli     EQUS "Edit an existing hotlist entry"+CHR$0:ALIGN
.NewHotli    EQUS "Add an entry to the hotlist"+CHR$0:ALIGN
.Comment     EQUS "Comment"+CHR$0:ALIGN
.DefPort     EQUS "6667"+CHR$0:ALIGN
.NewHotlist
STMFD R13!,{R0-R7,R14}
LDR R0,[R12,#EqHandle]:ADR R1,NewHotlistS:SWI "EqWimp_ShutWindow"
ADR R2,NewHotli:SWI "EqWimp_WriteWindowName"
FNadr(2,Port):ADR R3,DefPort:SWI "EqWimp_WriteStringToIcon"
ADR R2,Comment:FNadr(3,Blank2):SWI "EqWimp_WriteStringToIcon"
FNadr(2,IsIRC):SWI "EqWimp_SelectIcon"
FNadr(2,Server):FNadr(3,Blank2):SWI "EqWimp_WriteStringToIcon"
SWI "EqWimp_PutAtFrontAndCentre"
BL PutCaret
MOV R0,#0:STR R0,[R12,#Hotlist_Editing]
LDMFD R13!,{R0-R7,PC}^

.HotlistClick
STMFD R13!,{R0-R7,R14}
FNfunction("HotlistClick")
LDR R1,[R12,#WimpArea]:LDR R3,[R1,#0]:LDR R4,[R1,#4]:LDR R8,[R1,#8]
LDR R2,[R1,#12]:STR R2,[R1]
SWI "Wimp_GetWindowState"
LDR R14,[R1,#4]:SUB R3,R3,R14:LDR R14,[R1,#16]:SUB R4,R4,R14
LDR R14,[R1,#24]:ADD R4,R4,R14
ADDS R4,R4,#54:BGE MissedHotlist
FNadr(5,HotT2YSize):LDR R5,[R5]:ADD R5,R5,#8
LDR R7,[R12,#HotlistHead]
.SearchHotlist
MOVS R7,R7:BNE NotAtEndOfHotlist
.MissedHotlist
MOV R4,R8:CMP R4,#4:CMPNE R4,#1024:BNE NotAMissedHotlistSelClick
BL ClearHotlist
B EndHotlistClick
.NotAMissedHotlistSelClick
CMP R4,#2:BNE EndHotlistClick
FNadr(0,Blank2):STR R0,[R12,#MenuParameter]
ADR R0,underlineHotlist:BL CreateAndOpenMenuAtMouse
B EndUserPaneClick
.underlineHotlist EQUS "_Hotlist"+CHR$0:ALIGN
.NotAtEndOfHotlist
ADDS R4,R4,R5:LDRLE R7,[R7]:BLE SearchHotlist
.FoundHEnt
CMP R4,#8:BLE MissedHotlist
MOV R4,R8
CMP R4,#2:BNE NotHotMenu
LDR R6,[R12,#HotlistHead]:MOV R5,#0
.HotMenuLoop
MOVS R6,R6:BEQ HaveToSelectHot
LDR R0,[R6,#Hotlist_Selected]:MOVS R0,R0:ADDNE R5,R5,#1:MOVNE R4,R6
LDR R6,[R6]:B HotMenuLoop
.HaveToSelectHot
CMP R5,#2:BGE MenuAlreadySelectedHot
CMP R5,#1:MOVEQ R7,R4:BEQ SingleHotM
MVN R0,#0:STR R0,[R7,#Hotlist_Selected]:MOV R0,R7
BL RedrawSingleHotlist:STR R0,[R12,#MenuSelHot]
.SingleHotM
LDR R0,[R7,#Hotlist_Address]:STR R0,[R12,#MenuParameter]
ADR R0,underlineHotlist:BL CreateAndOpenMenuAtMouse
B EndHotlistClick
.MenuAlreadySelectedHot
FNadr(0,StarThing):STR R0,[R12,#MenuParameter]
ADR R0,underlineHotlist:BL CreateAndOpenMenuAtMouse
B EndHotlistClick

.NotHotMenu
CMP R4,#64:BLEQ DragHot:BEQ EndHotlistClick
CMP R4,#1024:BNE NotSingleClickHot
LDR R0,[R7,#Hotlist_Selected]:MOVS R0,R0:BNE EndHotlistClick
.NotSingleClickHot
CMP R4,#4:CMPNE R4,#1:BLEQ DoubleClickedHot
LDR R0,[R7,#Hotlist_Selected]:MOV R14,R0
CMP R4,#1024:MVNEQ R0,#0                    ; single click (select)
CMP R4,#256:MVNEQ R6,#0:EOREQ R0,R0,R6      ; adjust click
CMP R4,#1:CMPNE R4,#4:MOVEQ R0,#0           ; double click (select,adjust)

STR R0,[R7,#Hotlist_Selected]:CMP R0,R14:MOVNE R0,R7:BLNE RedrawSingleHotlist
CMP R4,#1:CMPNE R4,#4:CMPNE R4,#1024:BNE EndHotlistClick
LDR R6,[R12,#HotlistHead]
.DeselectHots
MOVS R6,R6:BEQ EndHotlistClick
CMP R6,R7:LDREQ R6,[R6]:BEQ DeselectHots
LDR R0,[R6,#Hotlist_Selected]:MOVS R0,R0:MOVNE R0,#0:STRNE R0,[R6,#Hotlist_Selected]
MOVNE R0,R6:BLNE RedrawSingleHotlist
LDR R6,[R6]:B DeselectHots

.EndHotlistClick
FNend
LDMFD R13!,{R0-R7,PC}^

.UserPaneClick
STMFD R13!,{R0-R7,R14}
FNfunction("UserPaneClick")
STR R0,[R12,#SelectedChannel]
LDR R0,[R0,#Channel_Name]:STR R0,[R12,#MenuChannel]
MOV R0,#1:STR R0,WhichCTCPFlag
LDR R1,[R12,#WimpArea]
LDR R3,[R1,#0]:LDR R4,[R1,#4]:LDR R8,[R1,#8]
LDR R2,[R1,#12]:STR R2,[R1]
SWI "Wimp_GetWindowState"
LDR R14,[R1,#4]:SUB R3,R3,R14:LDR R14,[R1,#16]:SUB R4,R4,R14
LDR R14,[R1,#24]:ADD R4,R4,R14
ADDS R4,R4,#12:BGE EndUserPaneClick
FNadr(5,UserIconYSize):LDR R5,[R5]
LDR R7,[R12,#SelectedChannel]:MOVS R7,R7:BEQ EndUserPaneClick
LDR R7,[R7,#Channel_Users]
.SearchUserPaneList
MOVS R7,R7:BNE NotAtEndOfUserPaneListYet
.MissedAUser
MOV R4,R8
CMP R4,#4:CMPNE R4,#1024:BNE NotAMissedSelectClick
BL ClearUsers
B EndUserPaneClick
.NotAMissedSelectClick
CMP R4,#2:BNE EndUserPaneClick
LDR R7,[R12,#SelectedChannel]
LDR R7,[R7,#Channel_Users]
.lp MOVS R7,R7:BEQ SongleUser
LDR R0,[R7,#User_Flags]:TST R0,#U_Selected:BNE ManyUserMenu:LDR R7,[R7]:B lp
.SongleUser
MOV R0,#0:STR R0,[R12,#MenuParameter]
ADR R0,UserMenu:BL CreateAndOpenMenuAtMouse
B EndUserPaneClick
.NotAtEndOfUserPaneListYet
ADDS R4,R4,R5:LDRLE R7,[R7]:BLE SearchUserPaneList
.FoundUser
CMP R4,#8:BLE MissedAUser
MOV R4,R8
CMP R4,#2:BNE NotUserMenu
LDR R6,[R12,#SelectedChannel]
LDR R5,[R6,#Channel_Flags]:TST R5,#CF_YouHaveOps
LDR R6,[R6,#Channel_Users]:MOV R5,#0
.UserMenuLoop
MOVS R6,R6:BEQ HaveToSelectR7
LDR R0,[R6,#User_Flags]:TST R0,#U_Selected:ADDNE R5,R5,#1:MOVNE R4,R6
LDR R6,[R6]:B UserMenuLoop
.HaveToSelectR7
CMP R5,#2:BGE MenuAlreadySelected
CMP R5,#1:MOVEQ R7,R4:BEQ SingleUserM
LDR R0,[R7,#User_Flags]:ORR R0,R0,#U_Selected:STR R0,[R7,#User_Flags]:MOV R0,R7
BL RedrawSingleUser:STR R0,[R12,#MenuSelPerson]
.SingleUserM
MOV R0,#1:STR R0,WhichCTCPFlag
ADR R0,UserMenu
LDR R4,[R7,#User_Name]:STR R4,[R12,#MenuParameter]
BL CreateAndOpenMenuAtMouse
B EndUserPaneClick
.ManyUserMenu
.MenuAlreadySelected
MOV R0,#1:STR R0,WhichCTCPFlag
ADR R0,StarThing:STR R0,[R12,#MenuParameter]
ADR R0,UserMenu:BL CreateAndOpenMenuAtMouse
B EndUserPaneClick
.StarThing EQUS "*"+CHR$0:ALIGN

.NotUserMenu
CMP R4,#64:BLEQ DragUser:BEQ EndUserPaneClick
CMP R4,#1024:BNE NotSingleClick
LDR R0,[R7,#User_Flags]:TST R0,#U_Selected:BNE EndUserPaneClick
.NotSingleClick
CMP R4,#4:CMPNE R4,#1:BLEQ DoubleClickedUsers
LDR R0,[R7,#User_Flags]:MOV R14,R0

CMP R4,#1024:ORREQ R0,R0,#U_Selected                    ; single click (select)
CMP R4,#256:EOREQ R0,R0,#U_Selected                     ; adjust click
CMP R4,#1:CMPNE R4,#4:BICEQ R0,R0,#U_Selected           ; double click (select,adjust)

STR R0,[R7,#User_Flags]:CMP R0,R14:MOVNE R0,R7:BLNE RedrawSingleUser
CMP R4,#1:CMPNE R4,#4:CMPNE R4,#1024:BNE EndUserPaneClick
LDR R6,[R12,#SelectedChannel]:LDR R6,[R6,#Channel_Users]
.DeselectUsers
MOVS R6,R6:BEQ EndUserPaneClick
CMP R6,R7:LDREQ R6,[R6]:BEQ DeselectUsers
LDR R0,[R6,#User_Flags]:TST R0,#U_Selected:BICNE R0,R0,#U_Selected:STRNE R0,[R6,#User_Flags]
MOVNE R0,R6:BLNE RedrawSingleUser
LDR R6,[R6]:B DeselectUsers
.EndUserPaneClick
FNend
LDMFD R13!,{R0-R7,PC}^

.DoubleClickedHot
STMFD R13!,{R0,R14}
FNfunction("DoubleClickedHot")
LDR R0,[R12,#HotlistFlag]:CMP R0,#1:BLEQ ConnectHot:BLNE DefHot
FNend
LDMFD R13!,{R0,PC}^

.DefHot
STMFD R13!,{R0-R9,R14}
FNadr(0,ForegroundColour):FNadr(1,_ForegroundColour):LDMIA R0,{R2-R9}:STMIA R1,{R2-R9}
LDR R0,[R12,#EqHandle]:FNadr(1,PrefPane)
FNadr(2,OptionString):FNadr(3,OptionBuffer):SWI "EqWimp_UpdateOptions"
BL SetColours
LDR R7,[R12,#HotlistHead]:.lp MOVS R7,R7:BEQ EndDefHot:LDR R0,[R7,#Hotlist_Selected]
MOVS R0,R0:LDREQ R7,[R7]:BEQ lp
LDR R0,[R12,#EqHandle]:FNadr(1,PrefPane):FNadr(2,Server):LDR R3,[R7,#Hotlist_Address]
SWI "EqWimp_WriteStringToIcon"
FNadr(2,Port):LDR R3,[R7,#Hotlist_Port]
SWI "EqWimp_WriteStringToIcon"
LDR R3,[R7,#Hotlist_Flag]:MOVS R3,R3:FNadr(2,IsIRC):SWIEQ "EqWimp_DeselectIcon"
SWINE "EqWimp_SelectIcon"
FNadr(1,HotlistWindow+4):SWI "EqWimp_ShutWindow"
BL Transcribe
BL SaveOptions
.EndDefHot
LDMFD R13!,{R0-R9,PC}^

.DoubleClickedUsers
STMFD R13!,{R0-R7,R14}
FNfunction("DoubleClickedUsers")
LDR R6,[R12,#SelectedChannel]:LDR R6,[R6,#Channel_Users]
ADR R0,Foob_funname:MOV R1,#1:ADR R2,Foob_params
.CallForAllLoopDCU
MOVS R6,R6:BEQ EndDCU
LDR R14,[R6,#User_Flags]:TST R14,#U_Selected
LDRNE R14,[R6,#User_Name]:STRNE R14,Foob_params+4:BLNE CallRootProcedure
LDR R6,[R6]:B CallForAllLoopDCU
.EndDCU
FNend
LDMFD R13!,{R0-R7,PC}^
.Foob_funname EQUS "UserDoubleClicked"+CHR$0:ALIGN
.Foob_params EQUD fptrStr:EQUD 0

.UserMenu EQUS "_User"+CHR$0:ALIGN
.YGO EQUS "YouGotOps"+CHR$0:ALIGN
.TGO EQUS "TheyGotOps"+CHR$0:ALIGN
.Some1sel EQUS "SomeoneSelected"+CHR$0:ALIGN

.RedrawSingleHotlist
STMFD R13!,{R0-R7,R14}
FNfunction("RedrawSingleHotlist")
LDR R0,[R12,#EqHandle]:FNadr(1,Hotlist):SWI "EqWimp_HandleFromName"
MOV R0,R1:MOV R1,#0:MOV R3,#2048
FNadr(6,HotT2YSize):LDR R6,[R6]:ADD R6,R6,#8
MVN R4,#NOT-54:SUB R2,R4,R6:ADD R4,R4,#4:SUB R2,R2,#4
LDR R5,[R13]:LDR R7,[R12,#HotlistHead]
.FindULp2
MOVS R7,R7:BEQ EndRSH
CMP R7,R5:BEQ RSH
LDR R7,[R7]
SUB R2,R2,R6:SUB R4,R4,R6:B FindULp2
.RSH
SWI "Wimp_ForceRedraw"
.EndRSH
FNend
LDMFD R13!,{R0-R7,PC}^

.RedrawSingleUser
STMFD R13!,{R0-R7,R14}
FNfunction("RedrawSingleUser")
LDR R0,[R12,#EqHandle]:LDR R1,[R12,#SelectedChannel]:LDR R1,[R1,#Channel_UserBox]
MOV R0,R1:MOV R1,#0:FNadr(3,UserIconXSize):LDR R3,[R3]:ADD R3,R3,#1024 ; cheesey cheat
FNadr(6,UserIconYSize):LDR R6,[R6]:MVN R4,#NOT-(12):SUB R2,R4,R6:ADD R4,R4,#4:SUB R2,R2,#4
LDR R5,[R13]:LDR R7,[R12,#SelectedChannel]:MOVS R7,R7:BEQ EndRSU
LDR R7,[R7,#Channel_Users]
.FindULp
MOVS R7,R7:BEQ EndRSU
CMP R7,R5:BEQ RSU
LDR R7,[R7]
SUB R2,R2,R6:SUB R4,R4,R6:B FindULp
.RSU
SWI "Wimp_ForceRedraw"
.EndRSU
FNend
LDMFD R13!,{R0-R7,PC}^

.DragHot
STMFD R13!,{R0-R7,R14}
FNfunction("DragHot")
LDR R0,[R12,#EqHandle]:FNadr(1,Hotlist)
SWI "EqWimp_GetExtent"
LDR R0,[R12,#EqHandle]:FNadr(1,Hotlist)
SWI "EqWimp_HandleFromName"
LDR R0,[R12,#WimpArea]:STR R1,[R0]:MOV R1,R0:SWI "Wimp_GetWindowState"
MOV R1,#0:MOV R3,R4
FNadr(6,HotT2YSize):LDR R6,[R6]:MVN R4,#NOT-54
ADD R6,R6,#8:SUB R2,R4,R6:ADD R4,R4,#4:SUB R2,R2,#4
MOV R5,#0:LDR R7,[R12,#HotlistHead]
.FindDULp2
MOVS R7,R7:BEQ DU2
LDR R0,[R7,#Hotlist_Selected]:MOVS R0,R0
ADDNE R5,R5,#1:STRNE R2,Top:STRNE R4,Bottom
LDR R7,[R7]
CMP R5,#0:SUB R2,R2,R6:SUBEQ R4,R4,R6:B FindDULp2
.DU2
LDR R2,Top:LDR R4,Bottom
LDR R0,[R12,#WimpArea]
LDR R14,[R0,#4] :ADD R1,R1,R14
LDR R14,[R0,#16] :ADD R2,R14,R2
LDR R14,[R0,#4] :ADD R3,R14,R3
LDR R14,[R0,#16] :ADD R4,R14,R4
LDR R14,[R0,#24]:SUB R2,R2,R14:SUB R4,R4,R14
LDR R14,[R12,#WimpArea]
ADD R2,R2,#12
ADD R0,R14,#8:STMIA R0,{R1-R4}
MOV R1,R14
MOV R14,#5:STR R14,[R1,#4]
MOV R14,#0:STR R14,[R1,#24]:STR R14,[R1,#36]
MOV R14,#16384:STR R14,[R1,#32]:STR R14,[R1,#28]
SWI "Wimp_DragBox"
MOV R0,#DragType_Hot:STR R0,[R12,#DragType]
.DragABox
.EndDragHot
FNend
LDMFD R13!,{R0-R7,PC}^

.DragUser
STMFD R13!,{R0-R7,R14}
FNfunction("DragUser")
LDR R1,[R12,#SelectedChannel]:LDR R1,[R1,#Channel_UserBox]
LDR R0,[R12,#WimpArea]:STR R1,[R0]:MOV R1,R0:SWI "Wimp_GetWindowState"
MOV R1,#0:FNadr(3,UserIconXSize):LDR R3,[R3]
MOV R5,#0
FNadr(6,UserIconYSize):LDR R6,[R6]:MVN R4,#NOT-(12):SUB R2,R4,R6:ADD R4,R4,#4:SUB R2,R2,#4
LDR R7,[R12,#SelectedChannel]:MOVS R7,R7:BEQ EndDragUser
LDR R7,[R7,#Channel_Users]
.FindDULp
MOVS R7,R7:BEQ DU
LDR R0,[R7,#User_Flags]:TST R0,#U_Selected
ADDNE R5,R5,#1:STRNE R2,Top:STRNE R4,Bottom
LDR R7,[R7]
CMP R5,#0:SUB R2,R2,R6:SUBEQ R4,R4,R6:B FindDULp
.DU
LDR R2,Top:LDR R4,Bottom
LDR R0,[R12,#WimpArea]
LDR R14,[R0,#4] :ADD R1,R1,R14
LDR R14,[R0,#16] :ADD R2,R14,R2
LDR R14,[R0,#4] :ADD R3,R14,R3
LDR R14,[R0,#16] :ADD R4,R14,R4
LDR R14,[R0,#24]:SUB R2,R2,R14:SUB R4,R4,R14
LDR R14,[R12,#WimpArea]
ADD R0,R14,#8:STMIA R0,{R1-R4}
MOV R1,R14
MOV R14,#5:STR R14,[R1,#4]
MOV R14,#0:STR R14,[R1,#24]:STR R14,[R1,#36]
MOV R14,#16384:STR R14,[R1,#32]:STR R14,[R1,#28]
SWI "Wimp_DragBox"
MOV R0,#DragType_User:STR R0,[R12,#DragType]
.DragABox
.EndDragUser
FNend
LDMFD R13!,{R0-R7,PC}^
.Top EQUD 0:.Bottom EQUD 0

.JoinJoin
STMFD R13!,{R0-R7,R14}
MVN R1,#0:SWI "Wimp_CreateMenu"
LDR R0,[R12,#EqHandle]:FNadr(1,JoinChannel)
FNadr(2,ChanName):SWI "EqWimp_ReadIconString":STR R1,MangelWorzel+4:MOV R1,#1
ADR R2,MangelWorzel:ADR R0,JoinChan:BL CallRootProcedure
LDR R0,[R12,#EqHandle]:FNadr(1,JoinChannel)
FNadr(2,ChanName):FNadr(3,Blank2):SWI "EqWimp_WriteStringToIcon"
LDMFD R13!,{R0-R7,PC}^
.MangelWorzel EQUD fptrStr:EQUD 0
.JoinChan EQUS "Join"+CHR$0:ALIGN

.JoinCancel
STMFD R13!,{R0-R7,R14}
MVN R1,#0:SWI "Wimp_CreateMenu"
LDR R0,[R12,#EqHandle]:FNadr(1,JoinChannel)
FNadr(2,ChanName):FNadr(3,Blank2):SWI "EqWimp_WriteStringToIcon"
LDMFD R13!,{R0-R7,PC}^

.LeaveCurrentChannel
STMFD R13!,{R0-R7,R14}
FNfunction("LeaveCurrentChannel")
LDR R0,[R12,#SelectedChannel]:MOVS R0,R0:BEQ IgnoreCC
LDR R0,[R0,#Channel_Name]:STR R0,Mank+4:ADR R0,Leav:MOV R1,#1:ADR R2,Mank
BL CallRootProcedure
.IgnoreCC
FNend
LDMFD R13!,{R0-R7,PC}^
.Leav EQUS "Leave"+CHR$0:ALIGN
.Mank EQUD fptrStr:EQUD 0

.OpenTopicWindow
STMFD R13!,{R0-R7,R14}
LDR R0,[R12,#EqHandle]:ADR R1,CTopic
FNadr(2,Topic):FNadr(3,Blank2)
SWI "EqWimp_WriteStringToIcon"
SWI "EqWimp_PutAtFrontAndCentre"
BL PutCaretTemp
LDR R1,[R12,#LineBuf]:ADR R2,TitleForm:LDR R3,[R12,#SelectedChannel]:MOVS R3,R3:BEQ Jigolo
LDR R3,[R3,#Channel_Name]:BL String:MOV R2,R1:ADR R1,CTopic
SWI "EqWimp_WriteWindowName"
.Jigolo
LDMFD R13!,{R0-R7,PC}^
.CTopic EQUS "ChangeTopic"+CHR$0:ALIGN
.Topic EQUS "Topic"+CHR$0:ALIGN
.TitleForm EQUS "Change the topic on channel %s"+CHR$0:ALIGN

.CancTopic
STMFD R13!,{R0-R2,R14}
MVN R1,#0:SWI "Wimp_CreateMenu"
LDR R0,[R12,#EqHandle]:ADR R1,CTopic
ADR R2,Topic:FNadr(3,Blank2):SWI "EqWimp_WriteStringToIcon"
LDMFD R13!,{R0-R2,PC}^

.ChangeTopic
STMFD R13!,{R0-R2,R14}
MVN R1,#0:SWI "Wimp_CreateMenu"
LDR R0,[R12,#EqHandle]:ADR R1,CTopic
ADR R2,Topic:SWI "EqWimp_ReadIconString":STR R1,Mank3+12
LDR R0,[R12,#SelectedChannel]:MOVS R0,R0:BEQ foong
LDR R0,[R0,#Channel_Name]:STR R0,Mank3+4
ADR R0,CTopic:MOV R1,#2:ADR R2,Mank3
BL CallRootProcedure
.foong
LDR R0,[R12,#EqHandle]:ADR R1,CTopic
ADR R2,Topic:FNadr(3,Blank2):SWI "EqWimp_WriteStringToIcon"
LDMFD R13!,{R0-R2,PC}^
.Mank3 EQUD fptrStr:EQUD 0:EQUD fptrStr:EQUD 0

.AlertQuit
LDR R0,[R12,#EqHandle]:SWI "EqWimp_ReleaseMouse"
B ForcedQuit

.AlertContinue
STMFD R13!,{R0-R7,R14}
MOV R0,#0:FNadr(0,ErrSemaphore):STR R0,[R0]
LDR R0,[R12,#EqHandle]:SWI "EqWimp_ReleaseMouse"
FNadr(1,Win_Alert):SWI "EqWimp_ShutWindow"
LDMFD R13!,{R0-R7,PC}^

EQUB 0:EQUB 0:EQUB 0:._Iconbar EQUS "_"
.Iconbar EQUS "Iconbar"+CHR$0:ALIGN
.Iconbarclick
LDR R14,[R12,#ConFlag]:MOVS R14,R14:BNE EndClick
LDRB R14,[R3]:CMP R14,#ASC"M":BNE NotMenu
LDR R0,[R12,#EqHandle]:SWI "EqWimp_MouseInfo"
SUB R1,R1,#64:ADR R0,_Iconbar:MVN R2,#0
BL CreateAndOpenMenu
B EndClick
.NotMenu
CMP R14,#ASC"A":BLEQ OpenPrefs:BEQ EndClick
ADR R0,IconBarClick:MOV R1,#0:BL CallRootProcedure
B EndClick
.IconBarClick EQUS "IconbarClick"+CHR$0:ALIGN
.Proc_OpenConnect
STMFD R13!,{R14}
LDR R0,[R12,#EqHandle]:SWI "EqWimp_MouseInfo":MOV R3,#260:SUB R2,R1,#128
FNadr(1,ConnectWindow+4)
SWI "EqWimp_HandleFromName":SWI "Wimp_CreateMenu"
MOV R0,#0:LDMFD R13!,{PC}^

.PrefPane EQUS "PrefPane"+CHR$0:ALIGN
.Transcribe
STMFD R13!,{R0-R7,R14}
FNfunction("Transcribe")
LDR R0,[R12,#EqHandle]:ADR R1,PrefPane
FNadr(2,OptionString):FNadr(3,OptionBuffer):SWI "EqWimp_TranscribeOptions"
FNadr(0,Background):FNadr(1,_BackgroundColour):BL GetColour
FNadr(0,Foreground):FNadr(1,_ForegroundColour):BL GetColour
FNadr(0,CurForeST):FNadr(1,_CurFore):BL GetColour
FNadr(0,CurBackST):FNadr(1,_CurBack):BL GetColour
FNadr(0,SelForeST):FNadr(1,_SelFore):BL GetColour
FNadr(0,SelBackST):FNadr(1,_SelBack):BL GetColour
FNadr(0,CTCPST):FNadr(1,_CTCPCol):BL GetColour
FNadr(0,MeST):FNadr(1,_MeCol):BL GetColour
FNadr(0,_ForegroundColour):FNadr(1,ForegroundColour):LDMIA R0,{R2-R9}:STMIA R1,{R2-R9}
MVN R0,#0:FNadr(14,ZapMode):STR R0,[R14]
FNadr(14,SysFlag):STR R0,[R14]:BL ZapModeChange
BL UpdateBackgroundColours
FNend
LDMFD R13!,{R0-R7,PC}^

.ApplyOptions
STMFD R13!,{R0-R7,R14}
LDR R0,[R12,#EqHandle]
FNadr(1,ConnectWindow+4):FNadr(2,Server):FNadr(3,DefaultHost):SWI "EqWimp_WriteStringToIcon"
FNadr(2,Port):FNadr(3,DefaultPort):SWI "EqWimp_WriteStringToIcon"
FNadr(2,IsIRC):FNadr(3,DefaultIRCflag):LDR R3,[R3]:MOVS R3,R3
SWINE "EqWimp_SelectIcon":SWIEQ "EqWimp_DeselectIcon"
LDMFD R13!,{R0-R7,PC}^

.GetColour
STMFD R13!,{R14}
FNfunction("GetColour")
MOV R2,R0:MOV R7,R1:LDR R0,[R12,#EqHandle]:FNadr(1,ColWindow+4)
LDR R3,[R12,#WimpArea]:SWI "EqWimp_GetIconInfo":LDR R0,[R3,#24]
MOV R0,R0,LSR #28:STR R0,[R7]
FNend
LDMFD R13!,{PC}^
.SetColour
STMFD R13!,{R14}
FNfunction("SetColour")
MOV R4,R1
MOV R2,R0:LDR R0,[R12,#EqHandle]:FNadr(1,ColWindow+4):LDR R3,[R12,#WimpArea]
SWI "EqWimp_WimpBlock"
MOV R0,R4,LSL #28:STR R0,[R1,#8]:MOV R0,#&F0000000:STR R0,[R1,#12]
SWI "Wimp_SetIconState"
FNend
LDMFD R13!,{PC}^

.ConnectHotlist
STMFD R13!,{R0-R7,R14}
FNfunction("ConnectHotlist")
MOV R0,#1:STR R0,[R12,#HotlistFlag]
B Noogle:FNend   ; cheesey cheat

.PrefHotlist
STMFD R13!,{R0-R7,R14}
FNfunction("PrefHotlist")
MOV R0,#0:STR R0,[R12,#HotlistFlag]
.Noogle
BL RecalcHotsize
FNend
LDMFD R13!,{R0-R7,PC}^

.RecalcHotsize
STMFD R13!,{R0-R7,R14}
LDR R0,[R12,#EqHandle]:LDR R6,[R12,#HotlistHead]
MOV R5,#54:FNadr(4,HotT2YSize):LDR R4,[R4]:ADD R4,R4,#8
.CountHotlistEntries
MOVS R6,R6:BEQ EndCountHot:ADD R5,R5,R4:LDR R6,[R6]:B CountHotlistEntries
.EndCountHot
ADD R6,R5,#0:CMP R6,#156:MOVLT R6,#156
LDR R0,[R12,#EqHandle]:FNadr(1,HotlistWindow+4):SWI "EqWimp_GetExtent"
RSB R3,R6,#0:SWI "EqWimp_SetExtent"
LDR R0,[R12,#EqHandle]:FNadr(1,HotlistWindow+4):SWI "EqWimp_PutAtFront"
LDMFD R13!,{R0-R7,PC}^

.OpenPrefs
STMFD R13!,{R0-R7,R14}
FNfunction("OpenPrefs")
FNadr(0,ForegroundColour):FNadr(1,_ForegroundColour):LDMIA R0,{R2-R9}:STMIA R1,{R2-R9}
LDR R0,[R12,#EqHandle]:FNadr(1,PrefPane)
ADR R2,OptionString:ADR R3,OptionBuffer:SWI "EqWimp_UpdateOptions"
FNadr(1,PreferenceWindow+4):SWI "EqWimp_PutAtFrontAndCentre"
FNadr(1,PrefPane):ADR R2,Nick:BL PutCaret
BL SetColours
FNend
LDMFD R13!,{R0-R7,PC}^
.Nick EQUS "Nick"+CHR$0

.SetColours
STMFD R13!,{R0-R7,R14}
FNfunction("SetColours")
FNadr(0,Background):LDR R1,_BackgroundColour:BL SetColour
FNadr(0,Foreground):LDR R1,_ForegroundColour:BL SetColour
FNadr(0,CurForeST) :LDR R1,_CurFore:BL SetColour
FNadr(0,CurBackST) :LDR R1,_CurBack:BL SetColour
FNadr(0,SelForeST) :LDR R1,_SelFore:BL SetColour
FNadr(0,SelBackST) :LDR R1,_SelBack:BL SetColour
FNadr(0,CTCPST)    :LDR R1,_CTCPCol:BL SetColour
FNadr(0,MeST)      :LDR R1,_MeCol:BL SetColour
FNend
LDMFD R13!,{R0-R7,PC}^

.OptionString
EQUS "Nick|s,User|s,IRLname|s,Bitfont|s,Server|s,Port|s,"
EQUS "MailServer|s,Username|s,"
EQUS "UseSys|AND,UseBitMap|AND,Banner|AND,BeepError|AND,BeepNotify|AND,"
EQUS "NoteLen|d,MOTD|AND,Invis|AND,Meta|AND,IdentD|AND,"
EQUS "IRCserver|AND,MailPort|d"+CHR$0:ALIGN
.OptionBuffer
EQUD Nickname:EQUD Username:EQUD IRLname:EQUD Bitfont:EQUD DefaultHost
EQUD DefaultPort:EQUD MailServer:EQUD MailUsername
.Startsave
.UseSysflag EQUD 1
.Bitmapflag EQUD 0
.ShowBanner EQUD 1
.BeepOnError EQUD 1
.BeepOnNotify EQUD 1
.NoteLen EQUD Notify_Time%
.ShowMOTD EQUD 1
.Modeplusi EQUD 0
.Metaserver EQUD 1
.IdentD EQUD 0
.DefaultIRCflag EQUD 0
.MailPort EQUD 0
.Nickname EQUS "TheMoog"+CHR$0:EQUD 0:EQUD 0 ; 16 bytes
.Username FNres(20)
.IRLname FNres(64)
.Bitfont FNres(80)
.ForegroundColour EQUD 0:.BackgroundColour EQUD 0
.CurFore         EQUD 0
.CurBack       EQUD 0
.SelFore         EQUD 0
.SelBack       EQUD 0
.CTCPCol EQUD 0:.MeCol EQUD 0
.DefaultHost FNres(80)
.DefaultPort FNres(8)
.MailServer FNres(80)
.MailUsername FNres(20)
.Endsave

._ForegroundColour EQUD 0:._BackgroundColour EQUD 0
._CurFore         EQUD 0
._CurBack       EQUD 0
._SelFore         EQUD 0
._SelBack       EQUD 0
._CTCPCol EQUD 0:._MeCol EQUD 0

.SaveOptions
STMFD R13!,{R0-R7,R14}
FNfunction("SaveOptions")
MOVNE R7,#1:MOVEQ R7,#0
BL Transcribe
MOV R0,#10:ADR R1,Optionfile:MOV R2,#&F00:ORR R2,R2,#&FD:ADR R4,Startsave:ADR R5,Endsave
SWI "XOS_File":BVC AllOkSave
LDR R1,[R12,#WimpArea]:ADR R2,NotOptSave:ADD R3,R0,#4:BL String:MOV R0,R1:BL Notify
.AllOkSave
LDR R3,[R13,#3*4]
LDRB R14,[R3]:CMP R14,#ASC"A":BEQ PrefsNoCloseOnSave
LDR R0,[R12,#EqHandle]:FNadr(1,PreferenceWindow+4):MOVS R7,R7:SWIEQ "EqWimp_ShutWindow"
FNadr(1,PalMarrowBone):MOVS R7,R7:SWIEQ "EqWimp_ShutWindow"
.PrefsNoCloseOnSave
LDR R0,[R12,#ConfigFlag]:STR R0,[R12,#QuitFlag]
BL ApplyOptions
FNend
LDMFD R13!,{R0-R7,PC}^
.Optionfile EQUS "<IRClient$Dir>.Resources.Options"+CHR$0:ALIGN
.LoadOptions
STMFD R13!,{R0-R7,R14}
FNfunction("LoadOptions")
MOV R0,#5:ADR R1,Optionfile:SWI "XOS_File":BVS ProblemLoading:CMP R0,#1:BNE ProblemLoading
FNmov(14,Endsave-Startsave):CMP R4,R14:BNE ProblemLoading
MOV R0,#&ff:ADR R1,Optionfile:ADR R2,Startsave:MOV R3,#0:SWI "XOS_File":BVS ProblemLoading
BL ApplyOptions
.OptLoadEnd
BL UpdateBackgroundColours
FNend
LDMFD R13!,{R0-R7,PC}^
.NotOptSave EQUS "Can't save options: %s"+CHR$0:ALIGN
.ProblemLoading
ADR R0,CantLoadOpt:BL Notify
B OptLoadEnd
.CantLoadOpt EQUS "Unable to load options!"+CHR$0:ALIGN

.PutCaret ; in r1->window, r2->icon, puts caret in that icon
STMFD R13!,{R0-R7,R14}
FNfunction("PutCaret")
LDR R0,[R12,#EqHandle]:SWI "EqWimp_ReadIconString":MOV R0,R1:BL GetStringLen
MOV R6,R1:LDR R0,[R12,#EqHandle]:LDR R1,[R13,#4]:MOV R3,#0:MOV R4,#0:MVN R5,#0
SWI "EqWimp_SetCaret"
BL ClaimCaret
FNend
LDMFD R13!,{R0-R7,PC}^

.PutCaretTemp ; in r1->window, r2->icon, puts caret in that icon
STMFD R13!,{R0-R7,R14}
FNfunction("PutCaretTemp")
LDR R0,[R12,#EqHandle]:SWI "EqWimp_ReadIconString":MOV R0,R1:BL GetStringLen
MOV R6,R1:LDR R0,[R12,#EqHandle]:LDR R1,[R13,#4]:MOV R3,#0:MOV R4,#0:MVN R5,#0
SWI "EqWimp_GrabCaret"
FNend
LDMFD R13!,{R0-R7,PC}^

.PrefsOK
STMFD R13!,{R14}
LDR R0,[R12,#ConfigFlag]:MOVS R0,R0:BLNE SaveOptions:BNE ClosePrefs
BL Transcribe:LDMNEFD R13!,{PC}^
LDRB R14,[R3]:CMP R14,#ASC"A":BEQ PrefsNoClose
LDR R0,[R12,#EqHandle]:FNadr(1,PreferenceWindow+4)
SWI "EqWimp_ShutWindow":ADR R1,PalMarrowBone:SWI "EqWimp_ShutWindow"
.PrefsNoClose
LDR R0,[R12,#ConfigFlag]:STR R0,[R12,#QuitFlag]
BL ApplyOptions
LDMFD R13!,{PC}^

.PrefsCancel
STMFD R13!,{R14}
BEQ ClosePrefs
LDR R0,[R12,#ConfigFlag]:STR R0,[R12,#QuitFlag]
FNadr(0,ForegroundColour):FNadr(1,_ForegroundColour):LDMIA R0,{R2-R9}:STMIA R1,{R2-R9}
LDR R0,[R12,#EqHandle]:FNadr(1,PrefPane)
FNadr(2,OptionString):FNadr(3,OptionBuffer):SWI "EqWimp_UpdateOptions"
FNadr(1,PrefPane):FNadr(2,Nick):BL PutCaret
BL SetColours
LDMFD R13!,{PC}^
.ClosePrefs
LDR R0,[R12,#EqHandle]:FNadr(1,PreferenceWindow+4)
SWI "EqWimp_ShutWindow":ADR R1,PalMarrowBone:SWI "EqWimp_ShutWindow"
LDR R0,[R12,#ConfigFlag]:STR R0,[R12,#QuitFlag]
LDMFD R13!,{PC}^

.PrefsEdCol
STMFD R13!,{R14}
LDR R0,[R12,#EqHandle]:ADR R1,PalMarrowBone:SWI "EqWimp_PutAtFrontAndCentre"
LDMFD R13!,{PC}^
.PalMarrowBone EQUS "Colour"+CHR$0:ALIGN

.LaunchHelp
STMFD R13!,{R14}
ADR R0,HelpName:ADR R1,Launch:SWI "EqWimp_LaunchApplication"
LDMFD R13!,{PC}^
.HelpName EQUS "Help"+CHR$0:.Launch EQUS "Resources:$.Apps.!Help"+CHR$0:ALIGN

.EditColours
STMFD R13!,{R14}
LDR R0,[R12,#EqHandle]:FNadr(1,ColWindow+4):SWI "EqWimp_PutAtFrontAndCentre"
LDMFD R13!,{PC}^

.ChangeFore
STMFD R13!,{R14}
FNadr(0,_ForegroundColour):BL Change
LDMFD R13!,{PC}^
.ChangeBack
STMFD R13!,{R14}
FNadr(0,_BackgroundColour):BL Change
LDMFD R13!,{PC}^
.ChangeCurFore
STMFD R13!,{R14}
FNadr(0,_CurFore):BL Change
LDMFD R13!,{PC}^
.ChangeCurBack
STMFD R13!,{R14}
FNadr(0,_CurBack):BL Change
LDMFD R13!,{PC}^
.ChangeSelFore
STMFD R13!,{R14}
FNadr(0,_SelFore):BL Change
LDMFD R13!,{PC}^
.ChangeSelBack
STMFD R13!,{R14}
FNadr(0,_SelBack):BL Change
LDMFD R13!,{PC}^
.ChangeCTCPCol
STMFD R13!,{R14}
FNadr(0,_CTCPCol):BL Change
LDMFD R13!,{PC}^
.ChangeMeCol
STMFD R13!,{R14}
FNadr(0,_MeCol):BL Change
LDMFD R13!,{PC}^

.Change
STMFD R13!,{R14}
STR R0,ColourAddr:LDR R0,[R12,#EqHandle]:SWI "EqWimp_MouseInfo":ADD R3,R2,#64:SUB R2,R1,#128
FNadr(1,PaletteWindow+4):SWI "EqWimp_HandleFromName"
SWI "Wimp_CreateMenu"
LDMFD R13!,{PC}^
.ColourAddr EQUD 0

.OpenHotlist
STMFD R13!,{R0-R7,R14}
FNfunction("OpenHotlist")
LDR R0,[R12,#EqHandle]:ADR R1,Hotlist:SWI "EqWimp_ShutWindow"
LDR R7,[R12,#HotlistHead]
.FreeHotlist
MOVS R7,R7:BEQ EndFreeHotlist
LDR R0,[R7,#Hotlist_Address]:BL Str_free
LDR R0,[R7,#Hotlist_Port]   :BL Str_free
LDR R0,[R7,#Hotlist_Comment]:BL Str_free
MOV R2,R7:LDR R7,[R7]
BL Release
B FreeHotlist
.EndFreeHotlist
MOV R0,#&40:ADR R1,HotlistFile:SWI "XOS_Find":ADRVS R0,NoHot:BLVS Notify:BVS EndOpenHotlist
MOV R6,R0 ; R6 = file handle
.LGHEntries
MOV R1,R6
FNadr(2,MenuArea)
.LoopGetLine SWI "OS_BGet":BCS GotHotlist
CMP R0,#13:CMPNE R0,#10:MOVEQ R0,#0:STRB R0,[R2],#1:MOVS R0,R0:BNE LoopGetLine
.ProcessHotlistLine
FNadr(0,MenuArea):BL StripSpaces
LDRB R1,[R0]:CMP R1,#0:CMPNE R1,#ASC"#":BEQ LGHEntries ; ignore blank and comments
ADD R0,R0,#1:CMP R1,#ASC"Y":MOVEQ R2,#1:MOVNE R2,#0 ; flag
BL StripSpaces:MOV R3,R0 ; address
.lp LDRB R14,[R0],#1:CMP R14,#0:BEQ LGHEntries:CMP R14,#32:BNE lp
MOV R14,#0:STRB R14,[R0,#-1] ; put terminator on
BL StripSpaces:MOV R4,R0 ; port
.lp LDRB R14,[R0],#1:CMP R14,#0:BEQ LGHEntries:CMP R14,#32:BNE lp
MOV R14,#0:STRB R14,[R0,#-1] ; put terminator on
BL StripSpaces:MOV R5,R0 ; Comment - to EOL
MOV R0,R2:MOV R1,R3:MOV R2,R4:MOV R3,R5: BL NewHotlistEntry ; make new hotlist entry
B ProcessHotlistLine
.GotHotlist
MOV R0,#0:MOV R1,R6:SWI "XOS_Find"
.EndOpenHotlist
FNend
LDMFD R13!,{R0-R7,PC}^
.HotlistFile EQUS "<IRClient$Dir>.Resources.Hotlist"+CHR$0:ALIGN
.Hotlist EQUS "HotList"+CHR$0:ALIGN
.NoHot EQUS "Unable to open hotlist file"+CHR$0:ALIGN

.ConnectHot
STMFD R13!,{R0-R7,R14}
FNfunction("ConnectHot")
BL KillAllDisplays
LDR R7,[R12,#HotlistHead]:.lp MOVS R7,R7:BEQ EndCH:LDR R0,[R7,#Hotlist_Selected]
MOVS R0,R0:LDREQ R7,[R7]:BEQ lp
LDR R5,[R7,#Hotlist_Address]; r5 is hostname
LDR R3,[R7,#Hotlist_Flag]:STR R3,CallSesInit+20
LDR R4,[R7,#Hotlist_Port] ; r4 is port
LDR R0,[R12,#EqHandle]:FNadr(1,HotlistWindow+4):SWI "EqWimp_ShutWindow"
FNadr(1,ConnectWindow+4):SWI "EqWimp_ShutWindow"
ADR R1,Connecting:ADR R2,Port:MOV R3,R4:SWI "EqWimp_WriteStringToIcon"
ADR R2,Server:MOV R3,R5:SWI "EqWimp_WriteStringToIcon"
B Connect4
.EndCH
FNend
LDMFD R13!,{R0-R7,PC}^
.Connect
STMFD R13!,{R0-R7,R14}
FNfunction("Connect")
BL KillAllDisplays
LDR R0,[R12,#EqHandle]:FNadr(1,ConnectWindow+4):ADR R2,Server
SWI "EqWimp_ReadIconString":MOV R5,R1 ; r5 is hostname
FNadr(1,ConnectWindow+4):FNadr(2,IsIRC)
SWI "EqWimp_ReadIconState":STR R3,CallSesInit+20
FNadr(1,ConnectWindow+4):ADR R2,Port:SWI "EqWimp_ReadIconString":MOV R4,R1 ; r4 is port
FNadr(1,ConnectWindow+4):SWI "EqWimp_ShutWindow"
ADR R1,Connecting:MOV R3,R4:SWI "EqWimp_WriteStringToIcon"
ADR R2,Server:MOV R3,R5:SWI "EqWimp_WriteStringToIcon"
.Connect4
SWI "EqWimp_PutAtFrontAndCentre"
MVN R1,#0:SWI "Wimp_CreateMenu":STR R1,[R12,#ConFlag]

MOV R0,#10:MOV R1,R4:SWI "OS_ReadUnsigned" ; R2 is now port

MOV R1,R5:.lp LDRB R14,[R5]:CMP R14,#32:MOVLT R14,#0:STRB R14,[R5],#1:BGE lp
STR R2,CallSesInit+12:STR R1,CallSesInit+4:
LDR R2,[R12,#IRCNick]:MOVS R2,R2:BLNE Release
FNadr(0,Nickname):BL Str_dup:STR R0,[R12,#IRCNick]

ADR R0,CallSesName:MOV R1,#3:ADR R2,CallSesInit:BL CallRootProcedure

FNend
LDMFD R13!,{R0-R7,PC}^
.Server EQUS "Server"+CHR$0:ALIGN
.Port   EQUS "Port"+CHR$0:ALIGN
.IsIRC  EQUS "IRCServer"+CHR$0:ALIGN
.Connecting EQUS "Connecting"+CHR$0:ALIGN
.CallSesInit EQUD fptrStr:EQUD 0:EQUD fptrNum:EQUD 0:EQUD fptrNum:EQUD 0
.CallSesName EQUS "Session_Initialise"+CHR$0:ALIGN

.UnkHost
LDR R0,[R0]:SUB R0,R0,#&DA000:SUB R0,R0,#&C00
CMP R0,#&44
LDR R0,[R12,#EqHandle]:ADR R1,Connecting:SWI "EqWimp_ShutWindow"
MOV R0,#0:STR R0,[R12,#ConFlag]
ADREQ R0,UnkHostText:ADRNE R0,CantConText:BL Notify
LDMFD R13!,{R0-R7,PC}^
.CantConText EQUS "Unable to connect to that host"+CHR$0:ALIGN
.UnkHostText EQUS "Unable to resolve that hostname"+CHR$0:ALIGN

.AbortConnection
STMFD R13!,{R0-R7,R14}
ADR R0,AbortConn:MOV R1,#0:BL CallRootProcedure
LDR R0,[R12,#ConNowFlag]:STR R0,[R12,#NoteOffQuit]
LDMFD R13!,{R0-R7,PC}^
.AbortConn EQUS "AbortConnection"+CHR$0:ALIGN

.CheckCallBacks
STMFD R13!,{R0-R7,R14}
FNfunction("CheckCallBacks")
LDR R7,[R12,#CallBackStack]:FNadr(6,CallBackStack%)
.CallThemBackLoop
CMP R7,R6:BGE CalledThemAllBack
ADR R14,CallThemBackLoop:LDMFD R7!,{R0,R1,PC}
.CalledThemAllBack
STR R6,[R12,#CallBackStack]

FNnastyCheck3

FNend
LDMFD R13!,{R0-R7,PC}^
.AddCallBack
STMFD R13!,{R7,R12,R14}
; DO NOT USE ANY R11 STUFF IN THIS ROUTINE
MOV R12,#&8000
LDR R7,[R12,#CallBackStack]:STMFD R7!,{R0-R2}
STR R7,[R12,#CallBackStack]
LDMFD R13!,{R7,R12,PC}^

.Offline
STMFD R13!,{R0-R7,R14}
FNfunction("Offline")
LDR R0,[R12,#EqHandle]
ADR R1,ConText:SWI "EqWimp_ClearMenuFlag"
LDR R0,[R12,#EqHandle]:ADR R1,Connecting:SWI "EqWimp_ShutWindow"
MOV R0,#0:STR R0,[R12,#ConFlag]
LDR R0,[R12,#ConNowFlag]:STR R0,[R12,#NoteOffQuit]
FNnastyCheck1
FNend
LDMFD R13!,{R0-R7,PC}^

.Online
STMFD R13!,{R0-R7,R14}
FNfunction("Online")
LDR R0,[R12,#EqHandle]:ADR R1,Connecting:SWI "EqWimp_ShutWindow"
MOV R1,#0:STR R1,[R12,#ConFlag]
LDR R0,[R12,#EqHandle]
ADR R1,ConText:SWI "EqWimp_SetMenuFlag"
FNend
LDMFD R13!,{R0-R7,PC}^
.ConText EQUS "Connected"+CHR$0:ALIGN

.Finalise
STMFD R13!,{R0-R7,R14}
FNfunction("Finalise")
BL Garbage_Clear                        ; clear the heap
BL NukePrograms
BL SaveWholeHotlist
.CheckMeFromHere
LDR R0,[R12,#RegFlag]:TEQ R0,#1:BEQ NoNeedToIrritate
ADR R0,RegMeNowMes
MOV R1,#1+16:ORR R1,R1,#(1<<8)+(1<<9)
ADR R2,er_title:FNadr(3,IconSprite):MOV R4,#1:MOV R5,#0
SWI "Wimp_ReportError"

.NoNeedToIrritate
; no more WIMP stuff after this ...
LDR R0,[R12,#EqHandle]:SWI "EqWimp_Finalise"
LDR R0,[R12,#EqNetHandle]:SWI "EqNet_Finalise"
LDR R0,[R12,#TaskHandle]:LDR R1,[R12,#Task]:SWI "Wimp_CloseDown"

]
IF profile% THEN
[OPT pass%
BL FinalProfile
]
ENDIF
[OPT pass%

BL MemFinalise

FNend
LDMFD R13!,{R0-R7,PC}^
.er_title EQUS "IRClient Registration"+CHR$0:ALIGN
.RegMeNowMes EQUD 200:EQUS "Please register IRClient - it's only a tenner!"+CHR$0:ALIGN
.ToHere

.NullEvent
STMFD R13!,{R14}
FNfunction("NullEvent")

LDR R1,[R12,#StartupTimerKill]:CMP R1,#0:BEQ DeadWindow
SWI "OS_ReadMonotonicTime":CMP R0,R1:BLT DeadWindow
LDR R0,[R12,#EqHandle]:FNadr(1,Startup):SWI "EqWimp_ShutWindow"
.DeadWindow
LDR R1,[R12,#NotifyOff]:CMP R1,#0:BEQ AnotherDeadWindow
SWI "OS_ReadMonotonicTime":CMP R0,R1:BLT AnotherDeadWindow
LDR R0,[R12,#EqHandle]:FNadr(1,BtW):SWI "EqWimp_ShutWindow"
LDR R0,[R12,#NoteOffQuit]:STR R0,[R12,#QuitFlag]
.AnotherDeadWindow

; check to see if we're dragging a thang around
LDR R0,[R12,#DragFlag]:MOVS R0,R0:BEQ NotDraggingThang
LDR R0,[R12,#DragType]:CMP R0,#DragType_DragNDrop
BLEQ ProcessDnD:BEQ NotDraggingThang
LDR R1,[R12,#WimpArea]:SWI "Wimp_GetPointerInfo"
LDR R7,[R12,#DraggingDisplay]
BL GetXY
LDR R0,[R12,#StartLine]:CMP R0,R5:BLT Sokay
LDR R0,[R12,#StartChar]:CMP R0,R4:BGT Foombar
.Sokay
ADD R4,R4,#1 ; round up this way
.Foombar
LDR R2,[R12,#EndChar]:LDR R3,[R12,#EndLine]
CMP R2,R4:CMPEQ R3,R5:BEQ NotDraggingThang
BL RedrawSelectedArea
STR R4,[R12,#EndChar]:STR R5,[R12,#EndLine]
BL RedrawSelectedArea
.NotDraggingThang

; check for any pending lines to be sent...
LDR R0,[R12,#PasteBuffer]:MOVS R0,R0:BEQ NowtToPaste
BL GetLineFromBuffer:BL GetStrLen:MOVS R1,R1:BNE GotSomethingToProcess
LDR R0,[R12,#PasteBuffer]
LDR R1,[R0,#Buffer_Length]
MOVS R1,R1:BLEQ FreeBuffer:STREQ R1,[R12,#PasteBuffer]
BEQ NowtToPaste
LDR R2,[R0,#Buffer_Size]:CMP R1,R2:SUBGE R1,R2,#1
CMP R1,#508:MOVGE R1,#508
LDR R2,[R0,#Buffer_Data]:MOV R3,#0:STRB R3,[R2,R1]
.lp LDRB R0,[R2],#1:MOVS R0,R0:BLNE FakeClick:BNE lp
LDR R0,[R12,#PasteBuffer]:BL FreeBuffer:MOV R0,#0:STR R0,[R12,#PasteBuffer]
B NowtToPaste
.GotSomethingToProcess
MOV R2,R0
.lp LDRB R0,[R2],#1:MOVS R0,R0:BLNE FakeClick:BNE lp
MOV R0,#13:BL FakeClick
.NowtToPaste

BL CheckSchedules

LDR R1,[R12,#GarbageTime]
SWI "OS_ReadMonotonicTime"
CMP R0,R1
BLT DontGarbage
ADD R0,R0,#Garbage_Time
STR R0,[R12,#GarbageTime]
LDR R0,[R12,#GarbageFlag]
EORS R0,R0,#1
STR R0,[R12,#GarbageFlag]
BLNE Garbage_Mark
BLEQ Garbage_Sweep
.DontGarbage

Bl TidyMemory

FNend
LDMFD R13!,{PC}^

.ProcessDnD
STMFD R13!,{R0-R7,R14}
FNfunction("ProcessDnD")
LDR R1,[R12,#WimpArea]:SWI "Wimp_GetPointerInfo"
LDMIA R1,{R1-R5}
STR R1,MD_x
STR R2,MD_y:STR R4,MD_wind:STR R5,MD_icon
LDR R0,[R12,#DnD_Claimant]:MOVS R0,R0
LDRNE R0,[R12,#DnD_LastRef]
STR R0,your_ref
LDR R0,[R12,#DnD_DragAborted]
MOVS R0,R0:MOV R0,#1:ORRNE R0,R0,#1<<4:STR R0,MD_flags
LDR R0,[R12,#DnD_DragFinished]:MOVS R0,R0
MOVEQ R0,#17:MOVNE R0,#18:ADR R1,Message_Dragging
LDR R2,MD_wind:LDR R3,MD_icon
SWI "Wimp_SendMessage"
LDR R0,[R12,#DnD_DragFinished]:MOVS R0,R0:LDREQ R0,[R12,#DnD_DragAborted]:MOVEQS R0,R0
MOVNE R0,#0:STRNE R0,[R12,#DragFlag]
.EndProcessDnD
FNend
LDMFD R13!,{R0-R7,PC}^
.Message_Dragging
EQUD 64
EQUD 0
.your_ref EQUD 0
EQUD 0
EQUD Wimp_MDragging
.MD_wind EQUD 0
.MD_icon EQUD 0
.MD_x    EQUD 0
.MD_y    EQUD 0
.MD_flags EQUD 0
EQUD 1:EQUD 0:EQUD 0:EQUD 0
EQUD &FFF
EQUD -1

.RedrawSelectedArea
STMFD R13!,{R0-R7,R14}
FNfunction("RedrawSelectedArea")
LDR R7,[R12,#SelectedDisplay]:MOVS R7,R7:BEQ EndRSA
LDR R0,[R7,#Display_Wind]:MOV R1,#0:MOV R3,#2048 ; har har
MOV R5,#36
LDR R2,[R12,#StartLine]:LDR R4,[R12,#EndLine]
CMP R2,R4:EORLT R2,R2,R4:EORLT R4,R4,R2:EORLT R2,R2,R4
ADD R2,R2,#1
MUL R2,R5,R2:MUL R4,R5,R4
RSB R2,R2,#0:RSB R4,R4,#0
SWI "XWimp_ForceRedraw" ; window may no longer exist - so ignore errors
.EndRSA
FNend
LDMFD R13!,{R0-R7,PC}^

.SaveRecall ; r0->string
STMFD R13!,{R0-R7,R14}
FNfunction("SaveRecall")
LDR R1,[R12,#CurrentDisplay]
LDR R7,[R12,#RecallHead]:MOV R6,#0 ; free old strings
.FreeRecalls
MOVS R7,R7:BEQ EndFreeRecalls
ADD R6,R6,#1:CMP R6,#MaxRecall:LDRLT R7,[R7]:BLT FreeRecalls
LDR R6,[R7] ; next one:MOV R2,#0:STR R2,[R7] ;end of list here
LDR R2,[R7,#Recall_String]:BL Release
MOV R2,R7:BL Release
.EndFreeRecalls
MOV R3,#sizeof_Recall:BL Claim:LDR R7,[R12,#RecallHead]
STR R2,[R12,#RecallHead] ; recallhead = this;
STR R7,[R2] ; this->next = recallhead
MOVS R7,R7:STRNE R2,[R7,#Recall_Previous] ; oldrecallhead->previous = this;
STR R1,[R2,#Recall_Display]
BL Str_dup:STR R1,[R2,#Recall_String]
MOV R0,#0:STR R0,[R2,#Recall_Previous]
FNend
LDMFD R13!,{R0-R7,PC}^

\\      Display handling

.DefaultZapArea
EQUD 0    \ Redraw flags
EQUD 0    \ min x in pixs inc
EQUD 0    \ min y in pixs inc (from top)
EQUD 0    \ max x in pixs exc
EQUD 0    \ max y in pixs exc (from top)
EQUD 0    \ address of the screen
EQUD 0    \ bytes per raster line
EQUD 0    \ log base 2 of bpp
EQUD 8    \ width of a character in pixs
EQUD 16   \ height of a character in pixs
EQUD 0    \ cache address / font name
EQUD 0    \ bytes per cached line
EQUD 0    \ bytes per cached character
EQUD 2    \ line spacing in pixels
EQUD Zap_Data%   \ address of data to print
EQUD 0    \ x scroll offset in pixs
EQUD 0    \ y scroll offset in pixs
EQUD Pal2 \ address of palette data
EQUD 0    \ start foreground colour
EQUD 7    \ start background colour
EQUD 0    \ address of work area
EQUD 0    \ log 2 of num of x os per pixel
EQUD 0    \ log 2 of num of y os per pixel
EQUD 0    \ screen width in pixels
EQUD 0    \ screen height in pixels
EQUD 0    \ screen mode

.DisplayInit
STMFD R13!,{R0-R7,R14}
FNfunction("DisplayInit")
ADR R0,DefaultZapArea
MOV R3,#4096:BL Claim:STR R2,[R0,#r_workarea]
MOV R3,#&1000:BL Claim:STR R2,ZapSysChars
; update mode parms
MVN R0,#0:STR R0,ZapMode:BL ZapModeChange
FNadr(1,BlankLine)
MOV R0,#0:STRB R0,[R1],#1:MOV R0,#2:STRB R0,[R1],#1

FNend
LDMFD R13!,{R0-R7,PC}^
.ZapSysChars EQUD 0
.ZapMode EQUD -1
.ZapChars EQUD 0
.Foomba EQUS "<IRClient$Dir>.Resources.Fonts.%s"+CHR$0:ALIGN

.SysFlag EQUD -1
.MakeSystemFont
STMFD R13!,{R0-R7,R14}
FNfunction("MakeSystemfont")
MVN R0,#0:MOV R1,#5:SWI "OS_ReadModeVariable"
MOV R5,R2 ; if r5=2, then small chars
LDR R2,SysFlag:CMP R5,R2:BEQ DontBotherMakingFont
STR R5,SysFlag

LDR R2,ZapSysChars:MOVS R2,R2:BLNE Release
CMP R5,#1:MOVEQ R3,#&2000:MOVNE R3,#&1000
BL Claim:STR R2,ZapSysChars

LDR R0,ZapSysChars:ADR R1,DefaultZapArea:SWI "ZapRedraw_ReadSystemChars" ; initial thangs

;make the chars double height
CMP R5,#1:BNE NotDoubleEmUp
LDR R0,ZapSysChars:ADD R0,R0,#&1000:ADD R1,R0,#&1000:MOV R3,#&1000
.lp LDRB R2,[R0,#-1]!:STRB R2,[R1,#-1]!:STRB R2,[R1,#-1]!:SUBS R3,R3,#1:BNE lp

.NotDoubleEmUp
FNadr(0,Bitmapflag):LDR R0,[R0]:MOVS R0,R0:BEQ NoNiceFont
LDR R1,[R12,#WimpArea]
ADR R2,Foomba:FNadr(3,Bitfont):BL String:MOV R0,R1
MOV R1,R5:BL LoadZapFont
.NoNiceFont

CMP R5,#1:MOV R1,#ASC"_":MOVEQ R1,R1,LSL #4:MOVNE R1,R1,LSL #3
ADDEQ R1,R1,#15:ADDNE R1,R1,#7:MOV R2,#255:LDR R0,ZapSysChars
STRB R2,[R0,R1]

; now need to create bold equivs
CMP R5,#1:MOVEQ R6,#&1000:MOVNE R6,#&800
LDR R0,ZapSysChars:ADD R1,R0,R6 ; get to next area
MOV R2,R6
.MakeBoldLoop
LDRB R3,[R0],#1:ORR R3,R3,R3,LSR #1:STRB R3,[R1],#1
SUBS R2,R2,#1:BNE MakeBoldLoop
.DontBotherMakingFont
FNend
LDMFD R13!,{R0-R7,PC}^

.BackCol EQUD -1
.ForeCol EQUD -1
.UpdateBackgroundColours
STMFD R13!,{R0-R7,R14}
FNfunction("UpdateBackgroundColours")
FNadr(0,BackgroundColour):LDR R0,[R0]:LDR R4,ForeCol:LDR R5,BackCol:CMP R0,R5:STRNE R0,BackCol
BNE YupChangeCol
FNadr(0,ForegroundColour):LDR R0,[R0]:CMP R0,R5:BEQ EndUBC
.YupChangeCol FNadr(0,ForegroundColour):LDR R0,[R0]:STR R0,ForeCol
FNadr(1,DefaultZapArea):FNadr(0,BackgroundColour):LDR R0,[R0]:STR R0,[R1,#r_bac]
FNadr(0,ForegroundColour):LDR R0,[R0]:STR R0,[R1,#r_for]
LDR R7,[R12,#DisplayHead]
.ChangeAllDisplays
MOVS R7,R7:BEQ EndUBC
LDR R6,[R7,#Display_ZapArea]
FNadr(0,BackgroundColour):LDR R0,[R0]:STR R0,[R6,#r_bac]
LDR R0,[R7,#Display_LineAddrs]:LDR R1,[R7,#Display_NumLines]
.UBClp
LDR R2,[R0],#4:MOVS R2,R2:BEQ IgnoreThisLine
.UBClinelp
LDRB R14,[R2],#1:CMP R14,#0:BNE UBClinelp
LDRB R14,[R2],#1
CMP R14,#2:BEQ IgnoreThisLine
CMP R14,#1:CMPNE R14,#4:CMPNE R14,#8:BEQ ItsAColChange
CMP R14,#3:ADDEQ R2,R2,#2:BEQ UBClinelp
CMP R14,#6:ADDEQ R2,R2,#1:BEQ UBClinelp
CMP R14,#7:ADDEQ R2,R2,#1:BEQ UBClinelp
B UBClp
.ItsAColChange
LDRB R14,[R2],#1:CMP R14,R5:BNE CheckNormalVideo ; this is for reverse video
LDRB R14,[R2],#1:CMP R14,R4:BNE UBClinelp
FNadr(14,ForegroundColour):LDR R14,[R14]:STRB R14,[R2,#-1]
FNadr(14,BackgroundColour):LDR R14,[R14]:STRB R14,[R2,#-2]
B UBClinelp
.CheckNormalVideo
CMP R14,R4:BNE CheckBGOnly
LDRB R14,[R2],#1:CMP R14,R5:BNE UBClinelp
FNadr(14,ForegroundColour):LDR R14,[R14]:STRB R14,[R2,#-2]
FNadr(14,BackgroundColour):LDR R14,[R14]:STRB R14,[R2,#-1]
B UBClinelp
.CheckBGOnly
LDRB R14,[R2],#1:CMP R14,R5:BNE UBClinelp
FNadr(14,BackgroundColour):LDR R14,[R14]:STRB R14,[R2,#-1]
B UBClinelp
.IgnoreThisLine
SUBS R1,R1,#1:BNE UBClp
LDR R0,[R12,#EqHandle]:LDR R1,[R7,#Display_Wind]:LDR R14,[R7,#Display_Open]:MOVS R14,R14
SWINE "EqWimp_RedrawWholeWindow"
LDR R7,[R7]:B ChangeAllDisplays
.EndUBC
FNend
LDMFD R13!,{R0-R7,PC}^

.LoadZapFont ; r0->filename, R1 = 1 OR 2
STMFD R13!,{R0-R7,R14}
FNfunction("LoadZapFont")
MOV R1,R0:MOV R0,#&4C:SWI "OS_Find"
MOV R1,R0 ; file handle
MOV R0,#4:ADR R2,ZapHeader:MOV R3,#&20
SWI "OS_GBPB":ADR R2,ShouldBe:ADR R4,ZapHeader
LDMIA R2,{R2,R3}:LDMIA R4,{R4,R5}
CMP R2,R4:CMPEQ R3,R5:BEQ FontIsOK
ADR R0,NotAZapFont:BL Notify:B EndLoadZapFont
.FontIsOK
ADR R2,ZapHeader+&08:LDMIA R2,{R2,R3,R4,R5}
CMP R2,#8: ADRNE R0,WrongSize:BLNE Notify:BNE EndLoadZapFont
CMP R3,#16:ADRNE R0,WrongSize:BLNE Notify:BNE EndLoadZapFont
LDR R14,[R13,#4]:CMP R14,#1:BNE CheatingLoad
LDR R2,ZapSysChars:ADD R2,R2,R4,LSL #4:CMP R5,#255:MOVGE R5,#255
SUB R5,R5,R4:MOV R3,R5,LSL #4
MOV R0,#4
SWI "OS_GBPB"
.EndLoadZapFont
MOV R0,#0:SWI "OS_Find"
FNend
LDMFD R13!,{R0-R7,PC}^
.WrongSize EQUS "Font must be 8x16"+CHR$0:ALIGN
.NotAZapFont EQUS "This is not a Zap font"+CHR$0:ALIGN
.ShouldBe EQUS "ZapFont"+CHR$13:ALIGN
.ZapHeader FNres(&20)
.CheatingLoad
LDR R2,ZapSysChars:ADD R2,R2,R4,LSL #3:CMP R5,#255:MOVGE R5,#255
SUB R5,R5,R4:MOV R7,R5,LSL #3
.lp SWI "OS_BGet":SWICC "OS_BGet":BCS EndLoadZapFont:STRB R0,[R2],#1:SUBS R7,R7,#1:BNE lp
B EndLoadZapFont

.ZapModeChange
STMFD R13!,{R0-R7,R14}
FNfunction("ZapModeChange")

MOV R0,#135
SWI "OS_Byte":CMP R2,#256:BGT AlwaysRemake
LDR R0,ZapMode:CMP R0,R2:BEQ EndZapModeChange
.AlwaysRemake
STR R2,ZapMode  ; check to see if the mode actually has changed

MVN R0,#0:MOV R1,#11:SWI "OS_ReadModeVariable":MOV R3,R2
MVN R0,#0:MOV R1,#4 :SWI "OS_ReadModeVariable":MOV R2,R3,LSL R2:STR R2,[R12,#XExtent]
MVN R0,#0:MOV R1,#12:SWI "OS_ReadModeVariable":MOV R3,R2
MVN R0,#0:MOV R1,#5 :SWI "OS_ReadModeVariable":MOV R2,R3,LSL R2:STR R2,[R12,#YExtent]

BL MakeSystemFont

LDR R2,ZapChars:MOVS R2,R2:BLNE Release ; release invalid char data

FNadr(1,DefaultZapArea):SWI "ZapRedraw_ReadVduVars" ; get the new VDU vars

FNadr(0,BackgroundColour):LDR R0,[R0]:STR R0,[R1,#r_bac]
FNadr(0,ForegroundColour):LDR R0,[R0]:STR R0,[R1,#r_for]

MOV R0,#0:STR R0,[R1,#r_flags]

STMFD R13!,{R1}:MVN R0,#0:MOV R1,#5:SWI "OS_ReadModeVariable":LDMFD R13!,{R1}
CMP R2,#2:MOVEQ R3,#8:MOVNE R3,#16:STR R3,[R1,#r_charh]
MOVEQ R0,#1:MOVNE R0,#2:STR R0,[R1,#r_linesp]
MOV R2,#8:STR R2,[R1,#r_charw]
LDR R0,[R1,#r_bpp]:MOV R1,#0
SWI "ZapRedraw_CachedCharSize"
FNadr(1,DefaultZapArea)
STR R2,[R1,#r_cbpl]
STR R3,[R1,#r_cbpc]

MOV R3,R3,LSL #9 ; multiply r_cbpc by 256
BL Claim:STR R2,ZapChars
STR R2,[R1,#r_caddr]                   ; New chars

MOV R0,#3:ADR R2,Pal1:ADR R3,Pal2:MOV R4,#16
SWI "ZapRedraw_CreatePalette"          ; actually create the palette data
MOV R0,#2:ADR R2,Pal1+16*4:ADR R3,Pal2+16*4:MOV R4,#8
SWI "ZapRedraw_CreatePalette"          ; actually create the palette data

MOV R0,#0:MOV R2,#0:MOV R3,#512:SUB R3,R3,#1:LDR R4,ZapSysChars
SWI "ZapRedraw_ConvertBitmap"          ; and create the chars for the mode

; Now have to actually go and fill in the details on the other displays
FNadr(6,DefaultZapArea)
LDR R7,[R12,#DisplayHead]
.LoopForAllDisplays
MOVS R7,R7:BEQ EndLoopForAllDisplays
LDR R5,[R7,#Display_ZapArea] ; r5 is the zaparea for this display

LDR R0,[R6,#r_flags ]:STR R0,[R5,#r_flags ]
LDR R0,[R6,#r_linesp]:STR R0,[R5,#r_linesp]
LDR R0,[R6,#r_charw ]:STR R0,[R5,#r_charw ]
LDR R0,[R6,#r_charh ]:STR R0,[R5,#r_charh ]
LDR R0,[R6,#r_screen]:STR R0,[R5,#r_screen]
LDR R0,[R6,#r_bpl   ]:STR R0,[R5,#r_bpl   ]
LDR R0,[R6,#r_bpp   ]:STR R0,[R5,#r_bpp   ]
LDR R0,[R6,#r_cbpl  ]:STR R0,[R5,#r_cbpl  ]
LDR R0,[R6,#r_cbpc  ]:STR R0,[R5,#r_cbpc  ]
LDR R0,[R6,#r_caddr ]:STR R0,[R5,#r_caddr ]  ; copy the blocks
LDR R0,[R6,#r_mode  ]:STR R0,[R5,#r_mode  ]
LDR R0,[R6,#r_magx  ]:STR R0,[R5,#r_magx  ]
LDR R0,[R6,#r_magy  ]:STR R0,[R5,#r_magy  ]
LDR R0,[R6,#r_xsize ]:STR R0,[R5,#r_xsize ]
LDR R0,[R6,#r_ysize ]:STR R0,[R5,#r_ysize ]

LDR R7,[R7,#Display_Next]:B LoopForAllDisplays
.EndLoopForAllDisplays
.EndZapModeChange
FNend
LDMFD R13!,{R0-R7,PC}^
.Pal1 ]:FOR N%=0TO15:[OPT pass%:EQUD N%:]:NEXT:[OPT pass%
EQUD &00000000 ; black
EQUD &0000FF00
EQUD &00FF0000
EQUD &00FFFF00
EQUD &FF000000
EQUD &FF00FF00
EQUD &FFFF0000
EQUD &FFFFFF00
.Pal2 FNres(32*4)

.ReopenDisplay  ; r0->display structure
STMFD   R13!,{R0-R7,R14}
FNfunction("ReopenDisplay")
MOV R14,#1:STR R14,[R0,#Display_Open]
LDR R1,[R12,#WimpArea]
LDR R0,[R0,#Display_Wind]
STR R0,[R1]
SWI "Wimp_GetWindowState"
BL Win_Open
FNend
LDMFD   R13!,{R0-R7,PC}^

.NewDisplay
; r0 points to string which tells IRClient what to display in window - like '#acorn' or 'zarni'
; r1 is the number of lines the window is to have
; r2 points to string to put in title bar
; r3 is flags
STMFD R13!,{R0-R7,R14}
FNfunction("NewDisplay")

.NewDisplay2
; First see if there is already a display by this name
BL FindDisplayByName:CMP R0,#0:LDREQ R0,[R13]:BEQ NewNewDisplay
STR R3,[R0,#Display_Flags]
FNborrow(1,64)
MOV R14,#1:STR R14,[R0,#Display_Open]
LDR R0,[R0,#Display_Wind]
STR R0,[R1]
SWI "Wimp_GetWindowState"
SWI "Wimp_OpenWindow"
FNrepay
B EndNewDisplay

.NewNewDisplay
MOV R3,#sizeof_Display:BL Claim ; r2 is the new Display

LDR R14,[R12,#DisplayHead]:STR R14,[R2,#Display_Next]
STR R2,[R12,#DisplayHead] ; thread onto linked list of displays
MOV R7,R2 ; preserve pointer in r7

CMP R1,#8:MOVLT R1,#8           ; min 8 lines
CMP R1,#256:MOVGE R1,#256       ; max 256 lines
STR R1,[R7,#Display_NumLines] ; number of lines

BL Str_dup:STR R1,[R7,#Display_What] ; keep a copy of the 'what' field
LDR R3,[R13,#4*3]:STR R3,[R7,#Display_Flags]
MOV R3,#0:STR R3,[R7,#Display_Open]

MOV R3,#sizeof_ZapArea:BL Claim ; r2 is the new ZapArea
STR R2,[R7,#Display_ZapArea]    ; new zaparea

MOV R0,#0:STR R0,[R7,#Display_Channel] ; initially attached to no channel

FNadr(0,DefaultZapArea):MOV R1,#sizeof_ZapArea:.CopyInLoop
LDR R14,[R0],#4:STR R14,[R2],#4:SUBS R1,R1,#4:BNE CopyInLoop

LDR R3,[R7,#Display_NumLines]
MOV R3,R3,LSL #2 ; x4
BL Claim:STR R2,[R7,#Display_LineAddrs]
MOV R14,#0
.CopyInLoop
STR R14,[R2],#4:SUBS R3,R3,#4:BNE CopyInLoop ; fill up display with blanks

LDR R1,[R12,#DisplayTemplate]:LDR R0,[R12,#EqHandle]:SWI "EqWimp_CreateWindow"
STR R0,[R7,#Display_Wind]:MOV R1,R0:LDR R0,[R12,#EqHandle]
SWI "EqWimp_GetExtent"
MOV R3,#36
LDR R6,[R7,#Display_NumLines]:MUL R3,R6,R3:RSB R3,R3,#0
SWI "EqWimp_SetExtent"
LDR R2,[R13,#8] ; get window title
SWI "EqWimp_WriteWindowName"
FNborrow(0,64)
STR R1,[R0]:MOV R1,R0
SWI "Wimp_GetWindowState"
LDR R0,[R1,#4]:LDR R2,[R12,#WindowAddx]:ADD R0,R0,R2:STR R0,[R1,#4]
LDR R0,[R1,#12]:ADD R0,R0,R2:STR R0,[R1,#12]
LDR R0,[R1,#8]:LDR R2,[R12,#WindowAddy]:SUB R0,R0,R2:STR R0,[R1,#8]
LDR R0,[R1,#16]:SUB R0,R0,R2:STR R0,[R1,#16]
LDR R0,[R1,#24]:SUB R0,R0,#1<<30:STR R0,[R1,#24]
MVN R0,#0:STR R0,[R1,#28]
LDR R14,[R12,#Oflag]:MOVS R14,R14
MOVEQ R14,#1:MOVNE R14,#0:STR R14,[R7,#Display_Open]
SWIEQ "Wimp_OpenWindow"
FNrepay
LDR R0,[R12,#WindowAddx]:ADD R0,R0,#64
LDR R1,[R12,#WindowAddy]:ADD R1,R1,#64
CMP R0,#4*128:MOVEQ R0,#0:SUBEQ R1,R1,#6*64
STR R0,[R12,#WindowAddx]
STR R1,[R12,#WindowAddy]
.EndNewDisplay
FNend
LDMFD R13!,{R0-R7,PC}^
.DisplayWindowName EQUS "Display"+CHR$0:ALIGN

.KillAllDisplays
STMFD R13!,{R0-R7,R14}
FNfunction("KillAllDisplays")
.lp LDR R0,[R12,#DisplayHead]:MOVS R0,R0
LDRNE R0,[R0,#Display_Wind]:BLNE KillDisplay:BNE lp
FNend
LDMFD R13!,{R0-R7,PC}^

.KillDisplay
; r0->window number
STMFD R13!,{R0-R7,R14}
FNfunction("KillDisplay")
BL FindDisplay:MOVS R0,R0:BEQ RealEndKillDisplay
LDR R14,[R12,#DisplayWithFocus]:CMP R14,R0:MOVEQ R14,#0:STREQ R14,[R12,#DisplayWithFocus]
STMFD R13!,{R0}
LDR R2,[R0,#Display_Wind]:FNborrow(1,64)
STR R2,[R1]:SWI "XWimp_DeleteWindow" ; kill the window
LDR R2,[R0,#Display_Channel]:MOVS R2,R2:BNE NoBitz
LDR R3,[R2,#Channel_Toolbar]:STR R3,[R1]:SWI "XWimp_DeleteWindow"
LDR R3,[R2,#Channel_UserBox]:STR R3,[R1]:SWI "XWimp_DeleteWindow"
.NoBitz
FNrepay
LDMFD R13!,{R0}

MOV R6,R0 ; preserve addr for releae
LDR R2,[R0,#Display_What]:BL Release
LDR R4,[R0,#Display_LineAddrs]
LDR R3,[R0,#Display_NumLines]
.lp
LDR R2,[R4],#4:MOVS R2,R2:BLNE Release:SUBS R3,R3,#1:BNE lp
LDR R2,[R0,#Display_LineAddrs]:BL Release
LDR R2,[R0,#Display_ZapArea]:BL Release
STMFD R13!,{R0}
LDR R0,[R0,#Display_Channel]:TEQ R0,#0:LDRNE R0,[R0,#Channel_Name]
BLNE DeleteChannel
LDMFD R13!,{R0}
LDR R7,[R12,#DisplayHead]
CMP R7,R0:LDREQ R7,[R7,#Display_Next]:STREQ R7,[R12,#DisplayHead]:BEQ EndKillDisplay
.KillDisplayLoop
LDR R1,[R7,#Display_Next]:MOVS R1,R1:LDMEQFD R13!,{R0-R7,PC}^
CMP R1,R0:MOVNE R7,R1:BNE KillDisplayLoop
LDR R1,[R1,#Display_Next]:STR R1,[R7,#Display_Next]
.EndKillDisplay
MOV R2,R6:BL Release
.RealEndKillDisplay
FNend
LDMFD R13!,{R0-R7,PC}^

; => R0 = window handle
; <= R0 = display block, or 0 if not found
; Gerph> slightly optimised from stacking r1-r7
.FindDisplay
STMFD R13!,{R1,R7,R14}
FNfunction("FindDisplay")
LDR R7,[R12,#DisplayHead]
.FindWinLoop
MOVS R7,R7:MOVEQ R0,#0:BEQ EndFindDisplay
LDR R1,[R7,#Display_Wind]:CMP R1,R0:BEQ FoundDisp
LDR R7,[R7,#Display_Next]:B FindWinLoop
.FoundDisp
MOV R0,R7
.EndFindDisplay
FNend
LDMFD R13!,{R1,R7,PC}^

.FindDisplayByName
STMFD R13!,{R1-R7,R14}
FNfunction("FindDisplayByName")
LDR R7,[R12,#DisplayHead]
.FindWinLoopByName
MOVS R7,R7:MOVEQ R0,#0:BEQ EndFindDisplayByName
LDR R1,[R7,#Display_What]:BL CheckEqual:BEQ FoundDispByName
LDR R7,[R7,#Display_Next]:B FindWinLoopByName
.FoundDispByName
MOV R0,R7
.EndFindDisplayByName
FNend
LDMFD R13!,{R1-R7,PC}^

.RedrawSomethingElse
LDR R1,[R12,#WimpArea]
SWI "Wimp_RedrawWindow"
MOVS R0,R0:BEQ EndRedrawDisplay
LDR R0,[R12,#EqHandle]:LDR R1,[R1]
SWI "EqWimp_NameFromHandle"
FNadr(0,HotlistWindow+4):BL CheckEqual:BNE RedrawUserListBox
.RedrawHotlistWindow
MOV R2,#22:MVN R3,#NOT-102:LDR R0,[R12,#HotlistHead]
.RedrawEachHotlistEntry
MOVS R0,R0:BEQ EndRedrawEachHotlistEntry
; the tick/cross
FNadr(1,HotlistT1)
LDR R4,[R0,#Hotlist_Selected]:MOVS R4,R4
LDR R4,[R1,#16]:ORRNE R4,R4,#1<<21:BICEQ R4,R4,#1<<21:STR R4,[R1,#16]
FNadr(4,HotT1XSize):LDMIA R4,{R4,R5}
MVN R6,#0:LDR R7,[R0,#Hotlist_Flag]:MOVS R7,R7:ADRNE R7,Tick:ADREQ R7,Cross
SWI "EqWimp_PlotVirtualIcon":ADD R2,R2,#(94-22):SUB R3,R3,#4
; the server name
FNadr(1,HotlistT2)
LDR R4,[R0,#Hotlist_Selected]:MOVS R4,R4
LDR R4,[R1,#16]:ORRNE R4,R4,#1<<21:BICEQ R4,R4,#1<<21:STR R4,[R1,#16]
FNadr(4,HotT2XSize):LDMIA R4,{R4,R5}
MVN R7,#0:LDR R6,[R0,#Hotlist_Address]
SWI "EqWimp_PlotVirtualIcon":ADD R2,R2,R4:ADD R2,R2,#(668-660)
; the port
FNadr(1,HotlistT3)
LDR R4,[R0,#Hotlist_Selected]:MOVS R4,R4
LDR R4,[R1,#16]:ORRNE R4,R4,#1<<21:BICEQ R4,R4,#1<<21:STR R4,[R1,#16]
FNadr(4,HotT3XSize):LDMIA R4,{R4,R5}
MVN R7,#0:LDR R6,[R0,#Hotlist_Port]
SWI "EqWimp_PlotVirtualIcon":ADD R2,R2,R4:ADD R2,R2,#(796-788)
; the comment
FNadr(1,HotlistT4):
LDR R4,[R0,#Hotlist_Selected]:MOVS R4,R4
LDR R4,[R1,#16]:ORRNE R4,R4,#1<<21:BICEQ R4,R4,#1<<21:STR R4,[R1,#16]
FNadr(4,HotT4XSize):LDMIA R4,{R4,R5}
MVN R7,#0:LDR R6,[R0,#Hotlist_Comment]
SWI "EqWimp_PlotVirtualIcon"
.SkipThisHotlistEntry
MOV R2,#22:SUB R3,R3,R5:SUB R3,R3,#4
LDR R0,[R0]:B RedrawEachHotlistEntry
.EndRedrawEachHotlistEntry
LDR R1,[R12,#WimpArea]
SWI "Wimp_GetRectangle"
MOVS R0,R0:BNE RedrawHotlistWindow
B EndRedrawDisplay
.Tick EQUS "Sopton"+CHR$0:ALIGN
.Cross EQUS "Soptoff"+CHR$0:ALIGN
.RedrawUserListBox
FNadr(0,ChanPane):BL CheckEqual:BNE OKItIsAUserBox
.RedrawChansLp
LDR R0,[R12,#ChannelHead]
MOV R2,#12:MVN R3,#NOT-48:FNadr(1,ChannelTemplate)
FNadr(4,ChanIconXSize):LDMIA R4,{R4,R5}
.RedrawEachChan
MOVS R0,R0:BEQ EndRedrawChan
LDR R6,[R0,#Channel_Name]
LDR R14,[R0,#Channel_Flags]
TST R14,#CF_YouHaveOps:LDR R7,[R1,#16]:ORRNE R7,R7,#1<<21:BICEQ R7,R7,#1<<21:STR R7,[R1,#16]
MVN R7,#0
SWI "EqWimp_PlotVirtualIcon"
SUB R3,R3,R5:LDR R0,[R0]:B RedrawEachChan
.EndRedrawChan
LDR R1,[R12,#WimpArea]
SWI "Wimp_GetRectangle"
MOVS R0,R0:BNE RedrawChansLp
B EndRedrawDisplay

.FindChannelByUserBox ; in r0->window of user box out r0->channel
STMFD R13!,{R1,R7,R14}
FNfunction("FindUserBox")
LDR R7,[R12,#ChannelHead]
.lp MOVS R7,R7:MOVEQ R0,#0:BEQ NotFoundUB
LDR R1,[R7,#Channel_UserBox]:CMP R0,R1:LDRNE R7,[R7]:BNE lp
MOV R0,R7
.NotFoundUB
FNend
LDMFD R13!,{R1,R7,PC}^

.FindChannelByToolbar ; in r0->window of toolbar out r0->channel
STMFD R13!,{R1,R7,R14}
FNfunction("FindUserBox")
LDR R7,[R12,#ChannelHead]
.lp MOVS R7,R7:MOVEQ R0,#0:BEQ NotFoundUB
LDR R1,[R7,#Channel_Toolbar]:CMP R0,R1:LDRNE R7,[R7]:BNE lp
MOV R0,R7
.NotFoundUB
FNend
LDMFD R13!,{R1,R7,PC}^

.OKItIsAUserBox
;hack thwack
LDR R1,[R12,#WimpArea]:LDR R0,[R1]:BL FindChannelByUserBox
MOVS R0,R0:LDRNE R0,[R0,#Channel_Users]
STMFD R13!,{R0}
.RedrawUserListBoxLp LDR R0,[R13]
MOV R2,#12:;MVN R3,#NOT-92:MVN R3,#NOT-48:FNadr(1,UserIconTemplate)
FNadr(4,UserIconXSize):LDMIA R4,{R4,R5}
.RedrawEachUser
MOVS R0,R0:BEQ EndRedrawUser
LDR R6,[R0,#User_Name]
LDR R14,[R0,#User_Flags]
TST R14,#U_Selected:LDR R7,[R1,#16]:ORRNE R7,R7,#1<<21:BICEQ R7,R7,#1<<21:STR R7,[R1,#16]
TST R14,#U_HasOps:ADREQ R7,LilliputHasntOps:ADRNE R7,LilliputHasOps
; Gerph's changies
TST R14,#U_HasVoice:ADRNE R7,LilliputHasVoice
; end changies
SWI "EqWimp_PlotVirtualIcon"
SUB R3,R3,R5:LDR R0,[R0]:B RedrawEachUser
.EndRedrawUser
LDR R1,[R12,#WimpArea]
SWI "Wimp_GetRectangle"
MOVS R0,R0:BNE RedrawUserListBoxLp
LDMFD R13!,{R0}
B EndRedrawDisplay
.LilliputHasOps   EQUS "slilliputg"+CHR$0:ALIGN
.LilliputHasntOps EQUS "slilliput"+CHR$0:ALIGN
.LilliputHasVoice EQUS "slilliputo"+CHR$0:ALIGN

.RedrawDisplay ; in r1->wimpthing
STMFD R13!,{R0-R7,R14}
FNfunction("RedrawDisplay")
LDR R0,[R1] ; get window number
BL FindDisplay:MOVS R7,R0:BEQ RedrawSomethingElse
BL ProcessDisplayBeforeRedraw
LDR R0,[R13,#4]:LDR R1,[R7,#Display_ZapArea]
SWI "ZapRedraw_RedrawWindow"
.EndRedrawDisplay
FNend
LDMFD R13!,{R0-R7,PC}^

.ProcessDisplayBeforeRedraw ; R7 -> thing
STMFD R13!,{R0-R7,R14}

LDR R6,[R12,#SelectedDisplay]:CMP R6,R7:BNE NotASelectedWindow

FNadr(2,ForegroundColour):LDMIA R2,{R2,R3}:STR R2,__Fore:STR R3,__Back

ADD R0,R12,#StartLine AND &FF:ADD R0,R0,#StartLine AND &FF00
:LDMIA R0,{R1-R4}
ADD R0,R12,#S_StartLine AND &FF:ADD R0,R0,#S_StartLine AND &FF00
:STMIA R0,{R1-R4}

LDR R0,[R12,#S_StartLine]:LDR R1,[R12,#S_EndLine]:CMP R0,R1:BLE NasalHair
STR R0,[R12,#S_EndLine]:STR R1,[R12,#S_StartLine]
LDR R0,[R12,#S_StartChar]:LDR R1,[R12,#S_EndChar]
STR R1,[R12,#S_StartChar]:STR R0,[R12,#S_EndChar]
B EarWax
.NasalHair
BNE EarWax
LDR R0,[R12,#S_StartChar]:LDR R1,[R12,#S_EndChar]
CMP R0,R1:STRGT R0,[R12,#S_EndChar]:STRGT R1,[R12,#S_StartChar]
BEQ NotASelectedWindow
.EarWax
FNadr(0,Thing%):STR R0,ThingPtr
LDR R6,[R12,#Zap_Data]              ; Get the address of the zap_data buffer
MOV R0,R6:LDR R1,[R7,#Display_NumLines]:LDR R2,[R7,#Display_LineAddrs]
FNadr(14,BlankLine):SUB R14,R14,R6
LDR R5,[R12,#S_StartLine]:MOVS R5,R5:BEQ SoStartAlready
.CopyDownLoop
LDR R3,[R2],#4:MOVS R3,R3
SUBNE R3,R3,R6 ; make relative to D_NL
MOVEQ R3,R14   ; rel to blankline if zero
STR R3,[R0],#4
SUBS R5,R5,#1:SUBEQ R1,R1,#1:BEQ SoStartAlready
SUBS R1,R1,#1:BNE CopyDownLoop:B NoSelected
.SoStartAlready
MOV R9,R2
MOVS R1,R1:BEQ NoSelected
LDR R5,[R12,#S_StartChar]:MOVS R5,R5:LDREQ R3,[R9],#4:LDREQ R2,ThingPtr:BEQ PreStartAtBegLn
STMFD R13!,{R0-R3}
MOV R0,R5:LDR R1,[R9]
MOVS R1,R1:BNE foomb3
FNadr(1,BlankLine)
.foomb3
FNadr(2,ForegroundColour):LDMIA R2,{R2,R3}:STR R2,__Fore:STR R3,__Back
SWI "ZapRedraw_FindCharacter":STR R2,__Fore:STR R3,__Back
MOV R4,R1:LDMFD R13!,{R0-R3}
LDR R14,[R9] ; get start of string
MOVS R14,R14:MOVEQ R4,#0:SUBNE R4,R4,R14 ; get number of normal chars to copy across
LDR R3,[R9],#4 ; get base of line
MOVS R3,R3:BNE foomb2
FNadr(3,BlankLine)
.foomb2
LDR R2,ThingPtr:MOVS R4,R4:BEQ StartAtBegLn
.lp LDRB R14,[R3],#1:STRB R14,[R2],#1:SUBS R4,R4,#1:BNE lp
.PreStartAtBegLn
LDR R14,[R12,#S_EndLine]:LDR R5,[R12,#S_StartLine]:SUB R5,R14,R5
.StartAtBegLn
MOVS R3,R3:BNE foomb
FNadr(3,BlankLine)
.foomb
MOV R14,#0 :STRB R14,[R2],#1
MOV R14,#1 :STRB R14,[R2],#1
FNadr(14,SelFore):LDR R14,[R14]:STRB R14,[R2],#1
FNadr(14,SelBack):LDR R14,[R14]:STRB R14,[R2],#1
MOVS R5,R5:MOVPL R4,#1024:BNE PreStartAtBegLnLp
MOVMI R4,#0:BMI PreStartAtBegLnLp
STMFD R13!,{R0-R3}
MOV R1,R3:LDR R0,[R12,#S_EndChar]
LDR R2,[R12,#S_StartLine]:LDR R3,[R12,#S_EndLine]:CMP R2,R3:LDREQ R2,[R12,#S_StartChar]
SUBEQ R0,R0,R2
ADR R2,__Fore:LDMIA R2,{R2,R3}
SWI "ZapRedraw_FindCharacter":STR R2,T_Fore:STR R3,T_Back
MOV R4,R1:LDMFD R13!,{R0-R3}
FNadr(14,BlankLine)
CMP R3,R14:MOVEQ R4,#0:BEQ PreStartAtBegLnLp
SUBNE R4,R4,R3 ; get number of normal chars to copy across
.PreStartAtBegLnLp
.StartAtBegLnLp
SUBS R4,R4,#1:BPL JurassicShift
MOV R14,#0 :STRB R14,[R2],#1
MOV R14,#1 :STRB R14,[R2],#1
LDR R14,T_Fore:STRB R14,[R2],#1
LDR R14,T_Back :STRB R14,[R2],#1
.SmegMaLp
LDRB R14,[R3],#1:CMP R14,#0:STRB R14,[R2],#1:BNE SmegMaLp
LDRB R14,[R3],#1
CMP R14,#2:STREQB R14,[R2],#1:BEQ EndOfLine
CMP R14,#3:STREQB R14,[R2],#1           ; 3 byte
LDREQB R14,[R3],#1:STREQB R14,[R2],#1 ; L
LDREQB R14,[R3],#1:STREQB R14,[R2],#1 ; H
BEQ StartAtBegLnLp
CMP R14,#4:BNE NotAnUnda2
STRB R14,[R2],#1
LDRB R14,[R3],#1:STRB R14,[R2],#1 ; foregnd
LDRB R14,[R3],#1:STRB R14,[R2],#1 ; backgnd
LDRB R14,[R3],#1:TEQ R14,#0:BNE AsPerNormalMate
STRB R14,[R2],#1 ; zero byte
LDRB R14,[R3],#1:STRB R14,[R2],#1 ; 3
LDRB R14,[R3],#1:STRB R14,[R2],#1 ; low
LDRB R14,[R3],#1 ; get high
.AsPerNormalMate
STRB R14,[R2],#1 ; char1
LDRB R14,[R3],#1:STRB R14,[R2],#1 ; char2
B StartAtBegLnLp
.T_Fore EQUD 0:.T_Back EQUD 0
.NotAnUnda2
CMP R14,#1:STRB R14,[R2],#1:BNE SmegMaLp
LDRB R14,[R3],#1:STRB R14,[R2],#1 ; foregnd
LDRB R14,[R3],#1:STRB R14,[R2],#1 ; backgnd
B SmegMaLp
.__Fore EQUD 0
.__Back EQUD 0
.JurassicShift
LDRB R14,[R3],#1:CMP R14,#0:STRB R14,[R2],#1:BNE StartAtBegLnLp ; loop until a zero char
LDRB R14,[R3],#1
CMP R14,#2:STREQB R14,[R2],#1:BEQ EndOfLine
CMP R14,#3:STREQB R14,[R2],#1           ; 3 byte
LDREQB R14,[R3],#1:STREQB R14,[R2],#1 ; L
LDREQB R14,[R3],#1:STREQB R14,[R2],#1 ; H
SUBEQ R4,R4,#3
BEQ StartAtBegLnLp
CMP R14,#4:BNE NotAnUnda
STRB R14,[R2],#1
LDRB R14,[R3],#1:STRB R14,[R2],#1 ; foregnd
LDRB R14,[R3],#1:STRB R14,[R2],#1 ; backgnd
LDRB R14,[R3],#1:TEQ R14,#0:BNE AsPerNormalMate2
STRB R14,[R2],#1 ; zero byte
LDRB R14,[R3],#1:STRB R14,[R2],#1 ; 3
LDRB R14,[R3],#1:STRB R14,[R2],#1 ; low
LDRB R14,[R3],#1 ; get high
.AsPerNormalMate2
STRB R14,[R2],#1 ; char1
LDRB R14,[R3],#1:STRB R14,[R2],#1 ; char2
SUB R4,R4,#5
B StartAtBegLnLp
.NotAnUnda
SUB R4,R4,#1
CMP R14,#1:STRNEB R14,[R3],#1:SUBEQ R4,R4,#2:ADDEQ R3,R3,#2:SUBEQ R2,R2,#1 ; skip colours
B StartAtBegLnLp
.EndOfLine
LDR R8,ThingPtr:SUB R8,R8,R6:STR R2,ThingPtr
STR R8,[R0],#4
LDR R3,[R9],#4
SUB R5,R5,#1
SUBS R1,R1,#1:BNE StartAtBegLn

B NoSelected ;xxx hmmm
.ThingPtr EQUD Thing%

.NotASelectedWindow
LDR R6,[R12,#Zap_Data]              ; Get the address of the zap_data buffer
MOV R0,R6:LDR R1,[R7,#Display_NumLines]:LDR R2,[R7,#Display_LineAddrs]
FNadr(14,BlankLine):SUB R14,R14,R6
.CopyDownLoop
LDR R3,[R2],#4:MOVS R3,R3
SUBNE R3,R3,R6 ; make relative to D_NL
MOVEQ R3,R14   ; rel to blankline if zero
STR R3,[R0],#4:SUBS R1,R1,#1:BNE CopyDownLoop

.NoSelected
LDMFD R13!,{R0-R7,PC}^

.DisplayMessage
; r0 = message to display
; r1 = who from    - or 0 if internal
; r2 = who to      - if this does not start with '&' or '#' it is assumed to be a nick, and then
;                  - if it is equal to your nick, then r1 is the discriminatory register
; r3 = orr flags for the DisplayFlag
STMFD R13!,{R0-R7,R14}
FNfunction("DisplayMessage")
MOVS R0,R0:MOVNES R2,R2:BEQ EndDisplayMessage      ; sanity checks

LDRB R3,[R2]:CMP R3,#ASC"#":CMPNE R3,#ASC"&":BEQ DisplayToChannel ; see whether message is for
; a channel

; if not, is it a message from us?
LDR R0,[R12,#IRCNick]:BL CheckEqual:BNE NotFromUs
LDR R0,[R13,#8] ; get the 'to' field
B FromOrTo

.NotFromUs
; if not - check to see whether it's for 'us'
LDR R0,[R12,#IRCNick]:MOV R1,R2:BL CheckEqual:BNE EndDisplayMessage ; drop on floor if not
LDR R0,[R13,#4] ; get back who from
.FromOrTo
MOVS R0,R0:BEQ EndDisplayMessage ; if no 'from' also drop on floor

BL FindDisplayByName:MOVS R7,R0:BNE DispAlreadyOpen

; is there a window '->someone' already around?
ADR R1,MyBuf:ADR R2,MyTemplate:LDR R3,[R13,#4]:BL String:MOV R2,R1 ;window name
MOV R0,R3 ; display 'name'
MOV R3,#0 ; flags
MOV R1,#200 ; *CHANGE HERE FOR LEN GTH OF WINDOW* NEEDS TO BE CHANGED xxx
BL NewDisplay ; and create the new display

LDR R0,[R13,#4] ; get back the who from
BL FindDisplayByName:MOVS R7,R0:BEQ EndDisplayMessage ; if we can't find it after having just
;created it, give up

.DispAlreadyOpen
; r7 now points to a newly-opened, or previously opened Display_struct (we hope)
LDR R0,[R13,#12] ; get flags
LDR R14,[R7,#Display_Flags]
ORR R14,R14,R0
STR R14,[R7,#Display_Flags]
LDR R0,[R13] ; get back the original message
MOV R1,#0 ; scroll
BL InsertIntoDisplay ; and put it in the window in question
B EndDisplayMessage

.DisplayToChannel
; channel information - r2 is the channel name
MOV R0,R2:BL FindDisplayByName:MOVS R7,R0
BEQ EndDisplayMessage ; not a channel we've ever heard of - ignore
LDR R0,[R13,#12] ; get flags
LDR R14,[R7,#Display_Flags]
ORR R14,R14,R0
STR R14,[R7,#Display_Flags]
LDR R0,[R13] ; get back original message
MOV R1,#0 ; scroll
BL InsertIntoDisplay ; and show it up
.EndDisplayMessage
FNend
LDMFD R13!,{R0-R7,PC}^
.MyTemplate EQUS "->%s"+CHR$0:ALIGN
.MyBuf FNres(64) ; ample


.InsertIntoDisplay ; puts 'r0' into display *r7 wordwrapping as it does so, if r1 zero then
                   ; scroll window else redraw in entirity
STMFD R13!,{R0-R8,R14}
FNfunction("InsertIntoDisplay")
LDR   R6,[R7,#Display_Flags]
TST   R6,#DisplayFlag_ANSI
BL    ANSIfy

LDR   R2,[R7,#Display_Flags]
TST   R2,#DisplayFlag_ANSI
BLEQ  ResetLineColours      ; make sure the colours are right, only if in nonANSI mode
STR R1,ScrollFlag
; firstly find the position of the first space for indentation purposes
MOV R1,#0:.FindFirstSpace
LDRB R2,[R0],#1:MOVS R2,R2:BEQ FoundASpace ; if one-word only
CMP R2,#27:ADDEQ R0,R0,#2:BEQ FindFirstSpace
CMP R2,#32:BEQ FoundASpace:ADDGT R1,R1,#1 ; ignore non-printables
B FindFirstSpace
.FoundASpace
ADD R6,R1,#1 ; r6 is how many spaces we need to put on following lines
CMP R6,#30:MOVGE R6,#1
LDR R5,[R7,#Display_Flags]:TST R5,#DisplayFlag_NoIndent:MOVNE R6,#0
MOV R5,#1 ; flag saying 'this is the first line'
LDR R0,[R13] ; and get back the original
.LineLoop
MOV R4,R6 ; number of columns across so far
.PastZeroR4
LDR R2,[R12,#LineBuf]
MOV R1,#0 ; r1 points to the last 'space' for the purposes of word-wrapping
CMP R5,#1:MOVEQ R5,#0:BEQ ScanAcross ; don't
MOVS R5,R6:BEQ ScanAcross:MOV R3,#32
.IndentTheLine
STRB R3,[R2],#1:SUBS R5,R5,#1:BNE IndentTheLine
.ScanAcross
LDRB   R3,[R0],#1  ; get the next character
CMP    R3,#10
BNE    NotCR
CMP    R3,#13
LDRB   R3,[R0]
CMP    R3,#10
ADDEQ  R0,R0,#1
MOV    R3,#0
.NotCR
CMP    R3,#13
CMPNE  R3,#0       ; have we reached the end of the line?
MOVEQ  R3,#0       ; zero it
STRB   R3,[R2],#1
BEQ    Harlem      ; the end of the line

CMP    R3,#27      ; special case
LDREQB R3,[R0],#1  ; get the f'gnd
STREQB R3,[R2],#1
LDREQB R3,[R0],#1  ; get the B'gnd
STREQB R3,[R2],#1
BEQ    ScanAcross

CMP    R3,#32      ; is it a space?
MOVEQ  R1,R2       ; if it is point r1 to the next char on from the space
MOVEQ  R8,R0       ; and keep track of the new position
ADDGE  R4,R4,#1    ; move position across by one
CMP    R4,#80      ; check to see if we're past the end of the screen
BLE    ScanAcross  ; if not then continue looping

                   ; Check to see whether the next 'word' will fit on the next line, if not
                   ; don't bother moving it down a line to stop
                   ; <TheMoog>
                   ;           whatalonglinethisisisisisisisisi
CMP    R1,#0
MOVEQ  R1,R2       ; if so - put at the end of the line
MOVEQ  R8,R0
BEQ    FoundWholeLine
STMFD  R13!,{R1,R2}
MOV    R2,R6       ; initial count
.CountWordLength
LDRB   R3,[R1],#1
CMP    R3,#27      ; special case - ignore 27,f,b
ADDEQ  R1,R1,#2
BEQ    CountWordLength
CMP    R3,#0
CMPNE  R3,#32
BEQ    ItllFit
ADDGT  R2,R2,#1
CMP    R2,#80
BLE    CountWordLength
LDMFD  R13!,{R1,R2}
MOV    R1,R2
MOV    R8,R0
B      FoundWholeLine

.ItllFit
LDMFD  R13!,{R1,R2}

.FoundWholeLine
MOV    R3,#0
STRB   R3,[R1]     ; put zero byte at end

LDR    R0,[R12,#LineBuf]
BL     InsertOneLineIntoDisplay

                  ; now determine where to start the next line from
MOV    R0,R8

.KillSpaces
LDRB  R14,[R0]:CMP R14,#0:BEQ RealHarlem:CMP R14,#32:ADDEQ R0,R0,#1:BEQ KillSpaces

B      LineLoop    ; and start all over again

.Harlem           ; we reached the end of the line
LDR    R0,[R12,#LineBuf]
BL     InsertOneLineIntoDisplay  ; show the remainder
.RealHarlem
FNend
LDMFD R13!,{R0-R8,PC}^

.ResetLineColours
STMFD R13!,{R0-R1,R14}
FNfunction("ResetLineColours")
FNadr(0,ForegroundColour):LDMIA R0,{R0,R1}
STRB  R0,Internal_fc
STRB  R1,Internal_bc
MOV   R0,#0
STRB  R0,Internal_UnderLine
STRB  R0,Internal_Bold
FNend
LDMFD R13!,{R0-R1,PC}^

.Internal_fc EQUD 0
.Internal_bc EQUD 0
.Internal_UnderLine EQUD 0:.Internal_Bold      EQUD 0
.ScrollFlag EQUD 0

.InsertOneLineIntoDisplay
; r0->string to display, r7->display structure
STMFD R13!,{R0-R8,R14}
FNfunction("InsertOneLineIntoDisplay")

LDR   R1,[R7,#Display_LineAddrs]

MOV   R5,#0                       ; flag saying whether we should scroll the lines up
LDR   R6,[R7,#Display_Flags]
TST   R6,#DisplayFlag_Halfway
MOVNE R5,#1                       ; yup - we shouldn't scroll
TST   R6,#DisplayFlag_NoCR        ; Do we want a CRLF at the end?
BIC   R6,R6,#DisplayFlag_NoCR
ORRNE R6,R6,#DisplayFlag_Halfway  ; We are now halfway through a line
BICEQ R6,R6,#DisplayFlag_Halfway
STR   R6,[R7,#Display_Flags]      ; store them back

MOVS  R5,R5
BNE   DontReleaseTop

LDR   R2,[R1]                     ; get address of top line
MOVS  R2,R2                       ; is it zero?
BLNE  Release                     ; if not, release the associated memory

.DontReleaseTop

LDR   R2,[R7,#Display_NumLines]   ; init stuff

.MoveLinesUpLoop
SUBS  R2,R2,#1
BEQ   EndOfMoveLinesUpLoop
LDR   R3,[R1,#4]
MOVS  R5,R5
STREQ R3,[R1]
ADD   R1,R1,#4
B     MoveLinesUpLoop             ; shuffle up the lines

.EndOfMoveLinesUpLoop
MOV   R6,R1                       ; r6 points to the bottom line

MOVS R5,R5
BEQ   DontReleaseBottom

LDR  R2,[R6]
MOVS  R2,R2
BLNE  Release

.DontReleaseBottom

;now count the number of bytes we need to store in the new line
MOV   R4,#2+4+4                   ; EOL+colour change at either end
STMFD R13!,{R7}                   ; preserve r7, as this is our bold marker

LDR   R7,Internal_Bold            ; get the bold marker
MOVS  R7,R7
MOVEQ R7,#0
MOVNE R7,#3

LDR   R5,Internal_UnderLine
MOVS  R5,R5
MOVEQ R5,#1
MOVNE R5,#6                       ; bytes/char (taking underline)

.CountInitialSpaces               ; always one byte each
LDRB  R3,[R0]
CMP   R3,#32
ADDEQ R4,R4,#1
ADDEQ R0,R0,#1
BEQ   CountInitialSpaces

.CountNumberOfBytes
LDRB  R3,[R0],#1                  ; get a byte
MOVS  R3,R3
BEQ   EndCountNumberOfBytes

CMP   R3,#32
ADDGE R4,R4,R5
ADDGE R4,R4,R7
BGE   CountNumberOfBytes          ; a 'normal' char

CMP   R3,#2                       ; toggle bold
RSBEQ R7,R7,#3

CMP   R3,#30                      ; next char is a cursor
ADDEQ R4,R4,#6                    ; 0,8,f,b,x,y (y may *not* take up a byte)
ADDEQ R4,R4,R7

CMP   R3,#22                      ; toggle rev_video
ADDEQ R4,R4,#4                    ; 0,1,b,f

CMP   R3,#26                      ; underline off
MOVEQ R5,#1

CMP   R3,#27                      ; ansi-ish thing
ADDEQ R4,R4,#2                    ; 27,f,b becomes 0,1,f,b

CMP   R3,#29
ADDEQ R4,R4,#4                    ; fg/bg back

CMP   R3,#31                      ; toggle underline
RSBEQ R5,R5,#7                    ; heheh recalc new bytes/char size

CMP   R3,#15                      ; all fx off
MOVEQ R5,#1                       ; size of chars back to 1 'cos no underlining
MOVEQ R7,#0
ADDEQ R4,R4,#4                    ; and put fg/bg back

B     CountNumberOfBytes          ; ignore if not underline or REVERSE or reset

.EndCountNumberOfBytes
; now r4 is the number of bytes we need to allocate
LDMFD R13!,{R7}
MOV   R3,R4
BL    Claim                       ; yeah man
STR   R2,[R6]                     ; store in address in bottom line

; now actually put the data in - ignore the padding spaces before the beginning

LDR    R1,[R13]                    ; r1 is the message

MOV    R0,#0                       ; put colours in
STRB   R0,[R2],#1
MOV    R0,#1
STRB   R0,[R2],#1
LDRB   R0,Internal_fc
STRB   R0,[R2],#1
LDRB   R0,Internal_bc
STRB   R0,[R2],#1

.FirstFewSpacesLoop
LDRB   R0,[R1]
CMP    R0,#32
STREQB R0,[R2],#1
ADDEQ  R1,R1,#1
BEQ    FirstFewSpacesLoop

LDR    R5,Internal_UnderLine       ; flag saying whether we are underlining

.CopyInTheMessage
LDRB   R0,[R1],#1
CMP    R0,#0
BEQ    EndOfTheMessage
CMP    R0,#32
BLT    SpecialCharacter       ; less than a space - go and see, otherwise put a char in

;check to see if this is a bold char
LDRB   R14,Internal_Bold
MOVS   R14,R14
BEQ    CharNotBold
MOVS   R5,R5
MOVNE  R14,#0
STRNEB R14,[R2],#1
MOVNE  R14,#4
STRNEB R14,[R2],#1
LDRNEB R14,Internal_bc
STRNEB R14,[R2],#1
LDRNEB R14,Internal_fc
STRNEB R14,[R2],#1
MOV    R14,#0
STRB   R14,[R2],#1
MOV    R14,#3
STRB   R14,[R2],#1
STRB   R0,[R2],#1
MOV    R14,#1
STRB   R14,[R2],#1
MOVS   R5,R5
MOVNE  R14,#ASC"_"
STRNEB R14,[R2],#1
B      CopyInTheMessage

.CharNotBold
MOVS   R5,R5
STREQB R0,[R2],#1
BEQ    CopyInTheMessage       ; put the char in if not underlining, else

MOV    R14,#0
STRB   R14,[R2],#1
MOV    R14,#4
STRB   R14,[R2],#1
LDRB   R14,Internal_bc
STRB   R14,[R2],#1
LDRB   R14,Internal_fc
STRB   R14,[R2],#1
STRB   R0,[R2],#1
MOV    R14,#ASC"_"
STRB   R14,[R2],#1
B      CopyInTheMessage      ; 0,4,fb,bg,char,'_'

.SpecialCharacter
ADD    PC,PC,R0,LSL #2
MOV    R0,R0        ; do-lally

B   Char_Ignore       ; ascii 0
B   Char_Ignore       ; ascii 1
B   Char_ToggleBold   ; ascii 2
B   Char_Ignore       ; ascii 3
B   Char_Ignore       ; ascii 4
B   Char_Ignore       ; ascii 5
B   Char_Ignore       ; ascii 6 ; SPECIAL CASE - ALWAYS IGNORE
B   Char_Beep         ; ascii 7
B   Char_Ignore       ; ascii 8
B   Char_Ignore       ; ascii 9
B   Char_Ignore       ; ascii 10
B   Char_Ignore       ; ascii 11
B   Char_Ignore       ; ascii 12
B   Char_Ignore       ; ascii 13
B   Char_Ignore       ; ascii 14
B   Char_AllOff       ; ascii 15
B   Char_Ignore       ; ascii 16
B   Char_Ignore       ; ascii 17
B   Char_Ignore       ; ascii 18
B   Char_Ignore       ; ascii 19
B   Char_Ignore       ; ascii 20
B   Char_Ignore       ; ascii 21
B   Char_Reverse      ; ascii 22
B   Char_Ignore       ; ascii 23
B   Char_Ignore       ; ascii 24
B   Char_Ignore       ; ascii 25
B   Char_UnderOff     ; ascii 26
B   Char_ANSI         ; ascii 27
B   Char_BoldOff      ; ascii 28
B   Char_RevOff       ; ascii 29
B   Char_Cursor       ; ascii 30
B   Char_Underline    ; ascii 31

.Char_AllOff
MOV    R5,#0
STR    R5,Internal_UnderLine
STR    R5,Internal_Bold
STMFD R13!,{R1,R4}:FNadr(4,ForegroundColour)
LDMIA  R4,{R1,R4}
STRB   R1,Internal_fc
STRB   R4,Internal_bc
LDMFD R13!,{R1,R4}
B      UpdCol

.Char_Beep
SWI   256+7
.Char_Ignore
B CopyInTheMessage

.Char_UnderOff
MOV    R5,#0
STR    R5,Internal_UnderLine

.Char_Underline
EOR    R5,R5,#1
STR    R5,Internal_UnderLine
B      CopyInTheMessage

.Char_BoldOff
MOV    R14,#0
STRB   R14,Internal_Bold
B      CopyInTheMessage

.Char_RevOff
STMFD R13!,{R1,R4}:FNadr(4,ForegroundColour)
LDMIA  R4,{R1,R4}
STRB   R1,Internal_fc
STRB   R4,Internal_bc
LDMFD R13!,{R1,R4}
B      UpdCol

.Char_ToggleBold
LDRB   R14,Internal_Bold
EOR    R14,R14,#1
STRB   R14,Internal_Bold
B      CopyInTheMessage

.Char_ANSI
LDRB   R0,[R1],#1
SUB    R0,R0,#64
STRB   R0,Internal_fc
LDRB   R0,[R1],#1
SUB    R0,R0,#64
STRB   R0,Internal_bc
B      UpdCol

.Char_Cursor
MOV    R0,#0
STRB   R0,[R2],#1
MOV    R0,#8
STRB   R0,[R2],#1
FNadr(0,CurBack):LDR R0,[R0]
STRB   R0,[R2],#1
FNadr(0,CurFore):LDR R0,[R0]
STRB   R0,[R2],#1
LDRB   R0,[R1],#1:CMP R0,#32:SUBLT R1,R1,#1:ADDLT R0,R0,#64:CMP R0,#64:MOVEQ R0,#32
STRB   R0,[R2],#1
MOV    R0,#&7F
STRB   R0,[R2],#1
B CopyInTheMessage

.Char_Reverse
LDRB   R0,Internal_fc
LDRB   R14,Internal_bc
STRB   R0,Internal_bc
STRB   R14,Internal_fc       ; swap fg and bg

.UpdCol
MOV    R0,#0
STRB   R0,[R2],#1
MOV    R0,#1
STRB   R0,[R2],#1
LDRB   R0,Internal_fc
STRB   R0,[R2],#1
LDRB   R0,Internal_bc
STRB   R0,[R2],#1            ; change colours
B      CopyInTheMessage

.EndOfTheMessage
MOV R0,#0:STRB R0,[R2],#1:MOV R0,#1:STRB R0,[R2],#1
FNadr(0,ForegroundColour):LDR R0,[R0]
STRB R0,[R2],#1:FNadr(0,BackgroundColour):LDR R0,[R0]
STRB R0,[R2],#1

MOV R0,#0:STRB R0,[R2],#1:MOV R0,#2:STRB R0,[R2],#1 ; put terminator on

LDR R1,ScrollFlag:MOVS R1,R1:BEQ ScrollWindowUp
LDR R0,[R12,#EqHandle]:LDR R1,[R7,#Display_Wind]:SWI "EqWimp_RedrawWholeWindow"
B NotScroll
.ScrollWindowUp
LDR R0,[R12,#SelectedDisplay]:CMP R0,R7:BNE NotScrollSelection
LDR R0,[R12,#S_StartLine]:SUBS R0,R0,#1:MOVMI R0,#0:STR R0,[R12,#S_StartLine]
LDR R0,[R12,#S_EndLine]:SUBS R0,R0,#1:MOVMI R0,#0:STR R0,[R12,#S_EndLine]
LDR R0,[R12,#StartLine]:SUBS R0,R0,#1:MOVMI R0,#0:STR R0,[R12,#StartLine]
LDR R0,[R12,#EndLine]:SUBS R0,R0,#1:MOVMI R0,#0:STR R0,[R12,#EndLine]
.NotScrollSelection
LDR R0,[R7,#Display_Wind]
MOV R1,#36   ; r1 = size of a char
MOV R2,#&80000000:MOV R3,#&40000000:RSB R4,R1,#0:MOV R5,#0
MOV R6,#&80000000:ORR R6,R6,R1
MOV R1,#0
SWI "Wimp_BlockCopy"  ; and shuffle up the window

; experimental!
;LDR     R0,[R7,#Display_Wind]
;LDR     R1,[R12,#WimpArea]
;STR     R0,[R1]
;SWI     "Wimp_GetRectangle"
;TEQ     R0,#0
;BEQ     NotScroll
;BL      ProcessDisplayBeforeRedraw
;.LoopRedrawBits
;LDR     R0,[R12,#WimpArea]
;LDR     R1,[R7,#Display_ZapArea]
;SWI     "ZapRedraw_GetRectangle"
;LDR     R1,[R7,#Display_ZapArea]
;SWI     "ZapRedraw_RedrawArea"
;LDR     R1,[R12,#WimpArea]
;SWI     "Wimp_GetRectangle"
;TEQ     R0,#0
;BNE     LoopRedrawBits

LDR R0,[R12,#MenuReopenFlag] ; are we reopening - if we are then no Wimp_Polls!
TEQ R0,#0:B NotScroll ;xxx should be bne
LDR R0,IamTheMask
LDR R1,[R12,#WimpArea]
SWI "XWimp_Poll":BVS NotScroll
CMP R0,#1:BNE NotScroll
ADR R14,NotScroll
B RedrawDisplay

.NotScroll
FNend
LDMFD R13!,{R0-R8,PC}^
.IamTheMask
EQUD (1<<0)+(1<<4)+(1<<5)+(1<<6)+(0<<8)+(1<<11)+(1<<12)+(1<<13)+(1<<17)+(1<<18)+(1<<19)

._Debug
STMFD   R13!,{R0-R7,R14}
MOV R6,R3:MOV R3,R0:MOV R4,R1:MOV R5,R2:LDR R7,[R11]
ADR R1,_poo:ADR R2,_poo2:BL String
MOV R0,R1:BL PrintString
LDMFD   R13!,{R0-R7,PC}^
._poo FNres(256)
._poo2 EQUS "r0=&%0 r1=&%0 r2=&%0 r3=&%0 in '%s'"+CHR$0:ALIGN


.ANSIbuffer FNres(16)

.ANSIfy ; NE = ANSIfy, EQ = deansi, unless 27,f,b is ok
STMFD R13!,{R0-R7,R14}
FNfunction("ANSIfy")
MOVNE R6,#1:MOVEQ R6,#0
MOV R7,R0:MOV R1,R7
.ANSIlp
LDRB R0,[R1],#1:MOVS R0,R0:BEQ EndANSIfy
CMP R0,#255:BNE Try27:MOV R0,#6:STRB R0,[R1,#-1] ; hides blob
LDRB R14,[R1]:CMP R14,#251:STRB R0,[R1],#1:STRGEB R0,[R1],#1
B EndANSIpass
.Try27
CMP R0,#27:BNE ANSIlp:SUB R2,R1,#1 ; r2 points to place to put stuff
MOV R3,#0:STRB R3,[R2] ; failsafe
LDRB R0,[R1],#1:MOVS R0,R0:BEQ EndANSIfy
CMP R0,#ASC"[":BEQ StandardANSI
CMP R0,#64:BLT EndANSIpass
CMP R0,#(64+16):BGE EndANSIpass
;it's all ok
MOV R0,#27:STRB R0,[R2] ;put 27 back
ADD R7,R1,#2:B EndANSIpass
.StandardANSI
ADR R3,ANSIbuffer:MOV R4,#16
.findm
LDRB R0,[R1],#1:STRB R0,[R3],#1
MOVS R0,R0:BEQ GotEnd
SUBS R4,R4,#1:BEQ GotEnd
CMP R0,#ASC"A":BLT findm:CMP R0,#ASC"Z":BLE GotEnd2
CMP R0,#ASC"a":BLT findm:CMP R0,#ASC"z":BGT findm
.GotEnd2 ; a whole ANSI thing processed
MOV R14,#0:STRB R14,[R3,#-1]
MOV R3,R2
STMFD R13!,{R0-R2}
CMP R0,#ASC"m":BNE NotColChange
ADR R1,ANSIbuffer
CMP R6,#0:BEQ NotColChange
.decodeloop
LDRB R0,[R1]:MOVS R0,R0:BEQ NotColChange
CMP R0,#ASC";":ADDEQ R1,R1,#1:BEQ decodeloop
MOV R0,#10:SWI "OS_ReadUnsigned"
CMP R2,#0:MOVEQ R0,#28:STREQB R0,[R3],#1 ; bold off
CMP R2,#1:MOVEQ R0,#28:STREQB R0,[R3],#1 ; bold off
          MOVEQ R0,#2: STREQB R0,[R3],#1 ; bold toggle
CMP R2,#30:BLT decodeloop:CMP R2,#37:BGT decodeloop
SUB R2,R2,#30:MOV R0,#27:STRB R0,[R3],#1
ADD R2,R2,#64+16 ; ansi colour block
STRB R2,[R3],#1:FNadr(0,BackgroundColour):LDR R0,[R0]
ADD R0,R0,#64:STRB R0,[R3],#1
B decodeloop
.NotColChange
MOV R7,R3
LDMFD R13!,{R0-R2}:MOV R2,R3
LDRB R0,[R1],#1
.GotEnd
STRB R0,[R2],#1:MOVS R0,R0:BEQ EndANSIpass
LDRB R0,[R1],#1:B GotEnd
.EndANSIpass
MOV R1,R7:B ANSIlp
.EndANSIfy
FNend
LDMFD R13!,{R0-R7,PC}^

\\ User/Channel handlers

.FindChannel ; r0->name rets r0=0 if no match, or r0->channel structure
STMFD R13!,{R1-R7,R14}
FNfunction("FindChannel")
LDR R7,[R12,#ChannelHead]
.FindChannelLoop
MOVS R7,R7:BEQ EndFindChannel
LDR R1,[R7,#Channel_Name]:BL CheckEqual:LDRNE R7,[R7,#Channel_Next]:BNE FindChannelLoop
.EndFindChannel
MOV R0,R7
FNend
LDMFD R13!,{R1-R7,PC}^

.SetChannelFlags
STMFD R13!,{R0-R7,R14}
FNfunction("SetChannelFlags")
BL FindChannel:MOVS R0,R0:BEQ EndSetChannelFlags
STR R1,[R0,#Channel_Flags]
BL UpdateChannelFlags
.EndSetChannelFlags
FNend
LDMFD R13!,{R0-R7,PC}^

.GetChannelFlags
STMFD R13!,{R0,R2-R7,R14}
FNfunction("GetChannelFlags")
BL FindChannel:MOVS R0,R0:BEQ EndGetChannelFlags
LDR R1,[R0,#Channel_Flags]
.EndGetChannelFlags
FNend
LDMFD R13!,{R0,R2-R7,PC}^

.NewChannel ; r0->name of 'new' channel, out r0>chan struct
STMFD R13!,{R0-R7,R14}
FNfunction("NewChannel")
BL FindChannel:MOVS R0,R0:STRNE R0,[R13]:BNE EndNewChannel
LDR R0,[R13]
MOV R3,#sizeof_Channel:BL Claim:MOV R7,R2
; keep list alphabetic *ugh*
ADD R3,R12,#ChannelHead ; erk
.GetChannelPlace
LDR R2,[R3] ; follow link, or in first case, get ChannelHead
MOVS R2,R2:BEQ EndGetChannelPlace
LDR R1,[R2,#Channel_Name]:BL CheckEqual:MOVGT R3,R2:BGT GetChannelPlace
.EndGetChannelPlace
; here r3 points to last, r2 to next
STR R7,[R3] ; last->us
STR R2,[R7] ; last->us->next
BL Str_dup:STR R1,[R7,#Channel_Name]
MOV R0,#0:STR R0,[R7,#Channel_Flags]
STR R0,[R7,#Channel_Users]
STR R0,[R7,#Channel_Limit]
LDR R0,[R12,#EqHandle]:ADR R1,DisplayPane:SWI "EqWimp_CreateWindow":STR R0,[R7,#Channel_Toolbar]
LDR R0,[R12,#EqHandle]:FNadr(1,UserPane):SWI "EqWimp_CreateWindow":STR R0,[R7,#Channel_UserBox]
STR R7,[R13]
BL RedrawChannelBox
.EndNewChannel
FNend
LDMFD R13!,{R0-R7,PC}^
.DisplayPane EQUS "ChanToolbar"+CHR$0:ALIGN

.DeleteChannel ; r0->name of channel to nuke
STMFD R13!,{R0-R7,R14}
FNfunction("DeleteChannel")
ADD R3,R12,#ChannelHead
.DeleteChannelLoop
LDR R2,[R3]:MOVS R2,R2:BEQ EndDeleteChannel
LDR R1,[R2,#Channel_Name]:BL CheckSame:MOVNE R3,R2:BNE DeleteChannelLoop
MOV R7,R2:LDR R2,[R2] ; r2->next, r3->previous, r7->this
STR R2,[R3] ; previous->next = this->next
LDR R1,[R7,#Channel_Users]
.DeleteUsersLoop
MOVS R1,R1:BEQ EndDeleteUsersLoop
LDR R2,[R1] ; Next user
LDR R1,[R1,#User_Name]
BL DeleteUser:MOV R1,R2:B DeleteUsersLoop
.EndDeleteUsersLoop
LDR R0,[R7,#Channel_Name]:BL Str_free
LDR R1,[R12,#WimpArea]:LDR R0,[R7,#Channel_Toolbar]:STR R0,[R1]:SWI "Wimp_DeleteWindow"
LDR R1,[R12,#WimpArea]:LDR R0,[R7,#Channel_UserBox]:STR R0,[R1]:SWI "Wimp_DeleteWindow"
MOV R2,R7:BL Release
BL RedrawChannelBox
.EndDeleteChannel
FNend
LDMFD R13!,{R0-R7,PC}^

.NewHotlistEntry ; r0-> flag, r1->address, r2->port, r3->comment
STMFD R13!,{R0-R7,R14}
FNfunction("NewHostlistEntry")
MOV R3,#sizeof_Hotlist:BL Claim
MOV R7,R2:                   STR R0,[R7,#Hotlist_Flag]
MOV R0,R1:        BL Str_dup:STR R1,[R7,#Hotlist_Address]
LDR R0,[R13,#2*4]:BL Str_dup:STR R1,[R7,#Hotlist_Port]
LDR R0,[R13,#3*4]:BL Str_dup:STR R1,[R7,#Hotlist_Comment]
MOV R0,#0:                   STR R0,[R7,#Hotlist_Selected]
ADD R3,R12,#HotlistHead
LDR R0,[R7,#Hotlist_Address]
.GetHotPlace
LDR R2,[R3]
MOVS R2,R2:BEQ EndGetHotPlace
LDR R1,[R2,#Hotlist_Address]:BL CheckSame:MOVGT R3,R2:BGT GetHotPlace
.EndGetHotPlace
STR R7,[R3]:STR R2,[R7]
FNend
LDMFD R13!,{R0-R7,PC}^

.KillHotlistEntry ; r7->hotlist
STMFD R13!,{R0-R7,R14}
FNfunction("KillHotlistEntry")
ADD R0,R12,#HotlistHead
.lp LDR R1,[R0]:MOVS R1,R1:BEQ EndKillHotlistEntry
CMP R1,R7:MOVNE R0,R1:BNE lp
LDR R2,[R1]:STR R2,[R0] ; patch the hole
LDR R2,[R1,#Hotlist_Address]:BL Release
LDR R2,[R1,#Hotlist_Port]:BL Release
LDR R2,[R1,#Hotlist_Comment]:BL Release
MOV R2,R1:BL Release ; Release the mem
.EndKillHotlistEntry
FNend
LDMFD R13!,{R0-R7,PC}^

.CreateUser ; in r0->channel name, r1->user name
STMFD R13!,{R0-R7,R14}
FNfunction("CreateUser")
BL FindUser:MOVS R7,R0:BEQ EndCreateUser ; R7 is channel
MOVS R1,R1:BNE EndCreateUser
LDR R0,[R13,#4]
MOV R3,#sizeof_User:BL Claim
MOV R6,R2 ; r6-> user
ADD R3,R7,#Channel_Users ; erk
.GetUserPlace
LDR R2,[R3]
MOVS R2,R2:BEQ EndGetUserPlace
LDR R1,[R2,#User_Name]:BL CheckEqual:MOVGT R3,R2:BGT GetUserPlace
.EndGetUserPlace
; here r3 points to last, r2 to next
STR R6,[R3] ; last->us
STR R2,[R6] ; last->us->next
BL Str_dup:STR R1,[R6,#User_Name]
MOV R0,#0:STR R0,[R6,#User_Flags]
;STR R0,[R6,#User_LastMes]:;STR R0,[R6,#User_MesCount]:;STR R0,[R6,#User_ITimer]
BL RedrawUserList
.EndCreateUser
FNend
LDMFD R13!,{R0-R7,PC}^

.FindUser ; in r0->channel name, r1->user name, out r0->channel, r1->user
STMFD R13!,{R2-R7,R14}
FNfunction("FindUser")
BL FindChannel:MOVS R7,R0:MOVEQ R1,R0:BEQ EndFindUser
LDR R2,[R7,#Channel_Users]
.FindUserLoop
MOVS R2,R2:MOVEQ R0,R7:MOVEQ R1,#0:BEQ EndFindUser
LDR R0,[R2,#User_Name]:BL CheckEqual:LDRNE R2,[R2]:BNE FindUserLoop
MOV R0,R7:MOV R1,R2
.EndFindUser
FNend
LDMFD R13!,{R2-R7,PC}^

.SetUserFlags
STMFD R13!,{R0-R7,R14}
FNfunction("SetUserFlags")
BL FindUser:MOVS R1,R1:BEQ EndSetUserFlags
STR R2,[R1,#User_Flags]
STR R0,[R12,#SelectedChannel]:MOV R0,R1:BL RedrawSingleUser
LDR R1,[R13,#4]:LDR R0,[R12,#IRCNick]:BL CheckEqual
BNE EndSetUserFlags
LDR R0,[R13]
BL GetChannelFlags:BIC R1,R1,#CF_YouHaveOps:TST R2,#U_HasOps:ORRNE R1,R1,#CF_YouHaveOps
BL SetChannelFlags
.EndSetUserFlags
FNend
LDMFD R13!,{R0-R7,PC}^

.DeleteUser ; in r0->channel name, r1->user name
STMFD R13!,{R0-R7,R14}
FNfunction("DeleteUser")
BL FindChannel:MOVS R7,R0:BEQ EndDeleteUser
ADD R3,R7,#Channel_Users
MOV R0,R1
.DeleteUserLoop
LDR R2,[R3]:MOVS R2,R2:BEQ EndDeleteUser
LDR R1,[R2,#User_Name]:BL CheckEqual:MOVNE R3,R2:BNE DeleteUserLoop
MOV R6,R2:LDR R2,[R2] ; r2->next, r3->previous, r6->this
STR R2,[R3]
LDR R0,[R6,#User_Name]:BL Str_free
MOV R2,R6:BL Release
BL RedrawUserList
.EndDeleteUser
FNend
LDMFD R13!,{R0-R7,PC}^

.RedrawUserList ; in r7->channel
STMFD R13!,{R0-R7,R14}
FNfunction("RedrawUserList")
MOVS R7,R7:BEQ EndRedrawUL
LDR R6,[R7,#Channel_Users]
MOV R5,#12:FNadr(4,UserIconYSize):LDR R4,[R4]
.CountUsers
MOVS R6,R6:BEQ EndCountUsers:ADD R5,R5,R4:LDR R6,[R6]:B CountUsers
.EndCountUsers
;ADD R5,R5,R4
ADD R6,R5,#0:CMP R6,#170:MOVLT R6,#170
LDR R0,[R12,#EqHandle]:LDR R1,[R7,#Channel_UserBox]:SWI "EqWimp_GetExtent"
RSB R3,R6,#0:SWI "EqWimp_SetExtent"
LDR R0,[R7,#Channel_Name]:BL FindDisplayByName:LDR R2,[R0,#Display_Wind]
LDR R1,[R12,#WimpArea]:STR R2,[R1]
SWI "Wimp_GetWindowState":BL Win_Open
LDR R0,[R12,#EqHandle]:LDR R1,[R7,#Channel_UserBox]:SWI "EqWimp_RedrawWholeWindow"
.EndRedrawUL
FNend
LDMFD R13!,{R0-R7,PC}^

.OneParam ; Takes one parameter from R0 and puts it in R1.
          ; r2 then points to the command and r0 and r1 updated
STMFD R13!,{R3,R14}
FNfunction("OneParam")

MOV R3,#0:STRB R3,[R1]
MOV R2,R1
.Spaces
LDRB R3,[R0]:CMP R3,#32:CMPNE R3,#8:ADDEQ R0,R0,#1:BEQ Spaces
LDRB R3,[R0]:CMP R3,#ASC":":ADDEQ R0,R0,#1:BEQ Flimsy
.Communist
LDRB R3,[R0],#1:CMP R3,#0:CMPNE R3,#8:CMPNE R3,#32:CMPNE R3,#10:CMPNE R3,#13
MOVEQ R3,#0:STRB R3,[R1],#1
MOVS R3,R3:BNE Communist
LDRB R3,[R0,#-1]:CMP R3,#0:CMPNE R3,#13:CMPNE R3,#10:MOVEQ R3,#0:STREQB R3,[R0,#-1]!
B EndOneParam
.Flimsy
LDRB R3,[R0],#1:CMP R3,#10:CMPNE R3,#13:MOVEQ R3,#0
STRB R3,[R1],#1
MOVS R3,R3:BNE Flimsy
SUB R0,R0,#1
.EndOneParam
FNend
LDMFD R13!,{R3,PC}^

.Strcat ; calls string for appending
STMFD R13!,{R1,R14}
.StrcatLoop LDRB R14,[R1]:CMP R14,#0:ADDNE R1,R1,#1:BNE StrcatLoop
BL String
LDMFD R13!,{R1,PC}^

FNAlignToCacheBoundary
.String     ; in R1->to, R2->from, R3-R10 strings/whatever *USR MODE ON LY*
STMFD R13!,{R0-R10,R14}
FNfunction("String")

MOV R14,#3
.CopyLoop
LDRB R0,[R2],#1:CMP R0,#ASC"%":BEQ String_found
STRB R0,[R1],#1:MOVS R0,R0:BNE CopyLoop

.EndString
FNend
LDMFD R13!,{R0-R10,PC}^

.String_found
LDRB R0,[R2],#1:CMP R0,#ASC"%":STREQB R0,[R1],#1:BEQ CopyLoop
CMP R14,#3:MOVEQ R10,R3
CMP R14,#4:MOVEQ R10,R4
CMP R14,#5:MOVEQ R10,R5
CMP R14,#6:MOVEQ R10,R6
CMP R14,#7:MOVEQ R10,R7
CMP R14,#8:MOVEQ R10,R8
CMP R14,#9:MOVGE R10,R9
ADDLT R14,R14,#1
CMP R0,#ASC"0":BEQ String_0
BLT NotNum
CMP R0,#ASC"9":BGT NotNum
STMFD R13!,{R14}
SUB R14,R0,#ASC"0":MOV R14,R14,LSL #1
.String_snum
LDRB R0,[R10],#1:SUB R14,R14,#1:STRB R0,[R1],#1
CMP R0,#0:CMPNE R0,#10:CMPNE R0,#13:BNE String_snum
SUB R1,R1,#1
MOVS R14,R14:BEQ Notal:BMI Notal
MOV R0,#32:.flabberghast STRB R0,[R1],#1:SUBS R14,R14,#1:BNE flabberghast
.Notal
LDMFD R13!,{R14}:B CopyLoop
.NotNum
CMP R0,#ASC"s":BEQ String_s
CMP R0,#ASC"u":BEQ String_u
CMP R0,#ASC"d":BEQ String_d
CMP R0,#ASC"$":BEQ String_read
CMP R0,#ASC"%":STREQB R0,[R1],#1:BEQ CopyLoop
ADR R0,StringErr:SWI "OS_GenerateError":SWI "OS_Exit"
.StringErr EQUD &DEAD0000:EQUS "Unsupported %function in string handler"+CHR$0:ALIGN

.String_s
LDRB R0,[R10],#1:STRB R0,[R1],#1:CMP R0,#0:CMPNE R0,#10:CMPNE R0,#13:BNE String_s
SUB R1,R1,#1:B CopyLoop

.String_0
STMFD R13!,{R0-R2}
MOV R0,R10:MOV R2,#32
SWI "OS_ConvertHex8":MOV R3,R1:LDMFD R13!,{R0-R2}
MOV R1,R3:B CopyLoop

.String_u
STMFD R13!,{R0,R2}
MOV R0,R10:MOV R2,#32
SWI "XOS_ConvertCardinal4":LDMFD R13!,{R0,R2}
B CopyLoop

.String_d
STMFD R13!,{R0-R2}
MOV R0,R10:MOV R2,#32
SWI "XOS_BinaryToDecimal":ADD R3,R1,R2:LDMFD R13!,{R0-R2}
MOV R1,R3:B CopyLoop

.String_read
STMFD R13!,{R0-R4}
MOV R0,R10:MOV R2,#512:MOV R3,#0:MOV R4,#0
SWI "XOS_ReadVarVal":ADDVS R13,R13,#5*4+4:BVS EndString
ADD R1,R1,R2:STR R1,[R13,#4]:LDMFD R13!,{R0-R4}
B CopyLoop


FNAlignToCacheBoundary
.CheckSame ; r0==r1? eq/ne
STMFD R13!,{R0-R2,R14}
;FNfunction("CheckSame")
.Sloop2
LDRB R2,[R0],#1:LDRB R14,[R1],#1
CMP R2,#10:CMPNE R2,#13:MOVEQ R2,#0
CMP R14,#10:CMPNE R14,#13:MOVEQ R14,#0
CMP R2,#0:CMPEQ R14,#0:LDMEQFD R13!,{R0-R2,PC}
CMP R2,R14:BEQ Sloop2
.FoundItyeah2
;FNend
LDMFD R13!,{R0-R2,PC}

FNAlignToCacheBoundary
.CheckEqual ; r0=r1? eq/ne ...r0&r1 zero termed or 10 or 13'd
STMFD R13!,{R0-R3,R14}
;FNfunction("CheckEqual")

.Sloop
LDRB    R2,[R0],#1
LDRB    R3,[R1],#1

;CMP     R2,#ASC "z"             ; if this char below "z" ?
;RSBLE   R14,R2,#ASC"z"
;CMPLE   R14,#25
;RSBLE   R2,R14,#ASC"Z"
;CMP     R3,#ASC "z"             ; if this char below "z" ?
;RSBLE   R14,R3,#ASC"z"
;CMPLE   R14,#25
;RSBLE   R3,R14,#ASC"Z"

CMP      R2,#ASC"A"
RSBGES   R14,R2,#ASC"Z"
ORRGE    R2,R2,#32
CMP      R3,#ASC"A"
RSBGES   R14,R3,#ASC"Z"
ORRGE    R3,R3,#32

CMP     R2,#10
CMPNE   R2,#13
MOVEQ   R2,#0
CMP     R3,#10
CMPNE   R3,#13
MOVEQ   R3,#0
CMP     R2,#0
CMPEQ   R3,#0
LDMEQFD R13!,{R0-R3,PC}
CMP     R2,R3
BEQ     Sloop
.FoundItyeah
;FNend
LDMFD R13!,{R0-R3,PC}

FNAlignToCacheBoundary
.GetStringLen  ; R1 = LEN(R0)
STMFD R13!,{R0,R14}
;FNfunction("GetStringLen")
MOV R1,#0:.Loop LDRB R14,[R0],#1:CMP R14,#10:CMPNE R14,#13
CMPNE R14,#0
LDMEQFD R13!,{R0,PC}^
ADD R1,R1,#1
LDRB R14,[R0],#1:CMP R14,#10:CMPNE R14,#13
CMPNE R14,#0
ADDNE R1,R1,#1
BNE Loop
;FNend
LDMFD R13!,{R0,PC}^

FNAlignToCacheBoundary
.GetStrLen                      ; cache line number (710/SA)
STMFD   R13!,{R0,R14}           ; 0
MOV     R1,#0                   ; 0
.lp                             ; 0
LDRB    R14,[R0],#1             ; 0
TEQ     R14,#0                  ; 0
LDMEQFD R13!,{R0,PC}^           ; 0
ADD     R1,R1,#1                ; 0
LDRB    R14,[R0],#1             ; 0
TEQ     R14,#0                  ; 1
ADDNE   R1,R1,#1                ; 1
BNE     lp                      ; 1
LDMFD   R13!,{R0,PC}^           ; 1

FNassembleIRBasic

FNassembleMemoryManager

; Cunning - and stolen from ARM ;)

.hton
STMFD R13!,{R14}
EOR     R14,R0,R0,ROR #16
BIC     R14,R14,#&00FF0000
MOV     R0,R0,ROR #8
EOR     R0,R0,R14,LSR #8
LDMFD   R13!,{PC}^
; was STMFD R13!,{R14}
; was STRB R0,htonbuf+3:;MOV R0,R0,LSR #8
; was STRB R0,htonbuf+2:;MOV R0,R0,LSR #8
; was STRB R0,htonbuf+1:;MOV R0,R0,LSR #8
; was STRB R0,htonbuf:;LDR R0,htonbuf
; was LDMFD R13!,{PC}^
; was .htonbuf EQUD 0

.DontTouchThisBitAfter
EQUD 0:EQUD 0:EQUD 0:EQUD 0:EQUD 0
EQUD 0:EQUD 0:EQUD 0:EQUD 0:EQUD 0
.PrivateR11
.Retrace ; put a canonical stack retrace at r0, from registers at r1
STMFD R13!,{R0-R7,R11,R14}
ADR R11,PrivateR11
MOV R7,R1
MOV R1,R0:FNadr(3,MailUsername):FNadr(4,HostName):ADR R2,FoobMes1:BL String
LDMIA R7!,{R3,R4,R5,R6}:ADR R2,FoobMes2:BL Strcat
LDMIA R7!,{R3,R4,R5,R6}:ADR R2,FoobMes3:BL Strcat
LDMIA R7!,{R3,R4,R5,R6}:ADR R2,FoobMes4:BL Strcat
LDMIA R7!,{R3,R4,R5,R6}:ADR R2,FoobMes5:BL Strcat
]IF debug% THEN
[OPT pass%
ADR R2,FoobMes6:BL Strcat
MOV R2,R1:.flp LDRB R14,[R2]:MOVS R14,R14:ADDNE R2,R2,#1:BNE flp
LDR R11,[R13,#4]:LDR R11,[R11,#11*4]
.StackRetrace
MOVS R0,R11
STREQB R0,[R2,#-1]!:BEQ EndStackRetrace
ADD R1,R0,#4:SWI "OS_ValidateAddress"
BCS r11corrupt
LDMFD R11!,{R0}:MOVS R0,R0:STREQB R0,[R2,#-1]!:BEQ EndStackRetrace
ADD R1,R0,#64:SWI "OS_ValidateAddress":BCS r11corrupt
MOV R1,R0 ; address of routine name
.CopyNameOfRoutine
LDRB R14,[R1],#1:CMP R14,#0:MOVEQ R14,#ASC"."
STRB R14,[R2],#1:BNE CopyNameOfRoutine
B StackRetrace
.EndStackRetrace
]
ENDIF
[OPT pass%
MOV R1,R2:ADR R2,FoobMes7:BL Strcat
LDMFD R13!,{R0-R7,R11,PC}^
]IF debug% THEN
[OPT pass%
.r11corrupt
ADR R11,ZeroR11
ADR R1,r11corruptmes
B CopyNameOfRoutine
.r11corruptmes
EQUS "!r11_corrupt!"+CHR$0:ALIGN
]
ENDIF
[OPT pass%
.ZeroR11 EQUD 0
]:nl$=CHR$13+CHR$10:[OPT pass%
.FoobMes1 EQUS "MAIL FROM: <%s@%s>"+nl$
          EQUS "RCPT TO:   <matthew@xania.uk.org>"+nl$
          EQUS "DATA"+nl$
          EQUS "To: Matthew Godbolt <matthew@xania.uk.org>"+nl$
          EQUS "Subject: IRClient crash"+nl$+nl$+CHR$0:ALIGN
.FoobMes2 EQUS "r0 =%0 r1 =%0 r2 =%0 r3 =%0"+nl$+CHR$0:ALIGN
.FoobMes3 EQUS "r4 =%0 r5 =%0 r6 =%0 r7 =%0"+nl$+CHR$0:ALIGN
.FoobMes4 EQUS "r8 =%0 r9 =%0 r10=%0 r11=%0"+nl$+CHR$0:ALIGN
.FoobMes5 EQUS "r12=%0 r13=%0 r14=%0 pc =%0"+nl$+CHR$0:ALIGN
.FoobMes6 EQUS nl$+"Retrace:"+nl$+CHR$0:ALIGN
.FoobMes7 EQUS nl$+"."+nl$+CHR$0:ALIGN

.HostName EQUS "pcslipfoo.ex.ac.uk"+CHR$0:ALIGN ; needs to be changed XXX

.CheckRegistration
STMFD R13!,{R0-R7,R14}
ADR R1,RegiFile:MOV R0,#&40:SWI "XOS_Find":BVS NotRegistered
MOV R1,R0:MOV R0,#3:ADR R2,RegiData:MOV R3,#204:MOV R4,#&1D
SWI "XOS_GBPB":BVC cunning
MOV R0,#0:SWI "XOS_Find":B NotRegistered
.cunning
MOV R0,#0:SWI "XOS_Find"
MOV R0,#0:ADR R1,RegiData:ADD R2,R1,#200:MOV R3,#1:SWI "OS_CRC":ADR R1,RegiData
LDR R1,[R1,#200]:CMP R1,R0:ADRNE R0,CorRegD:BLNE Notify:BNE NotRegistered
MOV R0,   #&5F000000
ORR R0,R0,#&00430000
ORR R0,R0,#&00005200
ORR R0,R0,#&00000049
ADR R1,RegiData:MOV R2,#200
.lp LDR R3,[R1]:EOR R3,R3,R0:STR R3,[R1],#4:SUBS R2,R2,#4:BNE lp
ADR R1,RegiData:ADD R1,R1,#132:STR R1,EorCode
BL CheckABit
.NotRegistered
LDMFD R13!,{R0-R7,PC}^
.RegiFile EQUS "<IRClient$Dir>.Registered"+CHR$0:ALIGN
.RegiData FNres(204)
.CorRegD EQUS "Corrupt registration file"+CHR$0:ALIGN
.EorCode EQUD &DEADBEEF

.CheckABit
STMFD R13!,{R0-R7,R14}
FNcrypt(CheckABit_End-CheckABit_Start)
.CheckABit_Start
FNcheck
MOV R0,#1:STR R0,[R12,#RegFlag]
; XXX other checks here, and poke out error thang
.CheckABit_End
FNendcrypt
LDMFD R13!,{R0-R7,PC}^

.Decrypt
STMFD R13!,{R0-R7,R14}
.bibble MOV R0,R0:LDR R0,bibble:BIC R7,R14,#&FC000003
STR R0,[R7,#-4]:LDR R6,[R7],#4 ; r6 is length to encrypt
LDR R1,EorCode:MOV R2,#0
.lp LDR R0,[R1,R2] ; get eor word
ADD R2,R2,#4:AND R2,R2,#63 ; wrap
LDR R3,[R7]:EOR R3,R3,R0:STR R3,[R7],#4:SUBS R6,R6,#4:BNE lp
BL SynchCodeAreas
LDMFD R13!,{R0-R7,R14}
ADDS PC,R14,#4

.SynchCodeAreas
STMFD R13!,{R0,R14}
MOV R0,#0
SWI &2006e
LDMFD R13!,{R0,PC}^

\\ END OF PROGRAM //

.EndData

\\ Areas
.IndirArea%
FNres(IndirSize)

.Zap_Data%
FNres(256*4) : REM max 256 lines
.BlankLine
EQUD 0       : REM must be after the ZapData

.ChannelTemplate
FNres(64)
.UserIconTemplate
FNres(64)
.HotlistT1
FNres(64)
.HotlistT2
FNres(64)
.HotlistT3
FNres(64)
.HotlistT4
FNres(64)
.InputBuffer
FNres(512)
.Thing% FNres(8192) ; area for selected text to be dumped in
.ExpressionEvaluateBuffer FNres(16384)
.EELimit FNres(516)
.MenuArea
FNres(512)
.BottomOfLocalStack
FNres(1024)
.TopOfLocalStack
.MenuNamePlace%
FNres(512)
.LineBuf% ; ovfs over ErrBlock
FNres(80)
.ErrBlock%
FNres(256)
.CallBackStack%
EQUD 0:EQUD 0:EQUD 0:EQUD 0:EQUD 0:EQUD 0:EQUD 0:EQUD 0:EQUD 0
.DummyR11Stack
.RetraceInfo
FNres(1024)           ; if not enough - aaargh! (was 256, gerph)
.TopOfRetraceInfo
\Bottom of stack
FNres(256)
.StackLimit
FNres(32*1024)
.TopOfStack%
]
IF (P% AND 3) <>0 THEN AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARGH!
IF _f$<>"" THEN AAAAAAAAAAAAAAAAAAAARGH
IF _amount%<>0 THEN OOOOOOOOOOOOOOOOK
NEXT

shouldbe = 0
FOR N%=0 TO (NotRegistered - CheckRegistration)-1 STEP 4
 shouldbe = shouldbe EOR N%!(CheckRegistration - &8000 + code%)
NEXT
!(rc0_ShouldBe-&8000+code%) = shouldbe

shouldbe = 0
FOR N%=0 TO (ToHere - CheckMeFromHere)-1 STEP 4
 shouldbe = shouldbe EOR N%!(CheckMeFromHere - &8000 + code%)
NEXT
!(nc3_ShouldBe-&8000+code%) = shouldbe

SYS "OS_File",10,"<IRClient$Dir>.!RunImage",&FF8,,code%,EndData-&8000+code%
IF verbose% THEN
 PRINT "Needs ";(O%-code%)/1024;"K"
 PRINT "Wasted ";wasted
ENDIF
REM OSCLI "Squeeze -f <IRClient$Dir>.!RunImage"
END

DEF FNres(amount)
LOCAL N%
FOR N%=0 TO amount-1 STEP 4:O%!N%=0:NEXT
P%+=amount
O%+=amount
=""

DEF FNmov(reg,place)
[OPT pass%
LDR reg,P%+8
B P%+8
EQUD place
]
=""

DEF FNadr(reg%,addr%)
LOCAL val%
val%=addr%-P%-8
IF ABS(val%)>&3FFFC ERROR 0,"FNadr("+STR$ reg%+",&"+STR$~addr%+") too far in '"+_f$+"'"
IF (val% AND 3) ERROR 0,"FNadr("+STR$ reg%+",&"+STR$~addr%+") not w/aligned"
IF val%>=0 THEN
  [OPT pass%
  ADD reg%,PC,#(val% AND &3FC)
  ADD reg%,reg%,#(val% AND &3FC00)
  ]
ELSE
  [OPT pass%
  SUB reg%,PC,#((-val%) AND &3FC)
  SUB reg%,reg%,#((-val%) AND &3FC00)
  ]
ENDIF
=""

DEF FNfunction(f$)
 LOCAL pleb
  IF debug% THEN
     IF _f$<>"" ERROR 0,"End of function "+_f$+" not found when starting "+f$
     _f$=f$
     pleb = P%
   [OPT pass%
   ADR R14,P%+12
   STMFD R11!,{R14}
   B P%+4+((LEN f$+4) AND NOT 3)
   EQUS f$+CHR$0:ALIGN
;   LDR R14,[R12,#RIptr]
;   CMP R11,R14
;   BGT P%+8
;   FNcrash
   ]
   IF profile% THEN
     [OPT pass%
     BL EnteringProc
     ]
   ENDIF
     wasted+=P%-pleb
  ENDIF
=""

DEF FNend
  IF debug% THEN
    IF _f$="" ERROR 0,"End with no function"
    _f$=""
   IF profile% THEN
     [OPT pass%
     BL LeavingProc
     ]
   ENDIF
  [OPT pass%
    ADD R11,R11,#4
  ]
    wasted+=4
  ENDIF
=""

DEF FNcrash
[OPT pass%
EQUD &E7777777
]
=""

DEF FNborrow(reg%,amount%)
  IF _amount%<>0 Can't do that!
  _amount%=amount%
[OPT pass%
SUB R13,R13,#amount%
MOV reg%,R13
]
=""

DEF FNrepay
  IF _amount%=0 Can't do that
[OPT pass%
ADD R13,R13,#_amount%
]
  _amount%=0
=""

DEF FNtoken(num,var)
  LOCAL P%,O%
  P%=TokenDispatchTable+(num-128)*4
  O%=P%-&8000+code%
  [OPT pass%
    B var
  ]
=""

DEF FNcrypt(length)
  LOCAL N%,A%
[OPT pass%
BL Decrypt
EQUD length
]
  e_start=O%:e_end=O%+length-1
=""

DEF FNendcrypt
  LOCAL N%,A%
  A%=0
  FOR N%=e_start TO e_end STEP 4
    !N%=!N% EOR eor_tab!A%
    A%+=4
    A%=A% AND 63
  NEXT
=""

DEF FNcheck
IF RND(-TIME)
a=RND(64)-1
[OPT pass%
  FNmov(0,RegiData+68+a)
  LDRB R0,[R0]
  CMP R0,#chk_tab?a
  BEQ P%+16
  SWI "OS_EnterOS"
  TEQP PC,#&0C000003
  B P%
  LDR R0,P%
  STR R0,P%-16
  STR R0,P%-16
  STR R0,P%-16
]
=""

DEF FNradio(icon,letter$)
[OPT pass%
  LDR R1,[R12,#CurrentTB]:LDR R1,[R1,#Channel_Toolbar]
  LDR R0,[R12,#EqHandle]:FNadr(2,icon)
  SWI "EqWimp_ReadIconState"
  LDR R0,[R12,#CurrentTB]:MOVS R0,R0:BEQ P%+40
  LDR R0,[R0,#Channel_Name]:STR R0,BingleBongle+4
  STR R3,BingleBongle+12:MOV R3,#ASC letter$:STR R3,BingleBongle+20
  ADR R0,ChannelStateChange:MOV R1,#3:ADR R2,BingleBongle
  BL CallRootProcedure
]
=""

DEF FNexp(opcode,routine)
  LOCAL P%,O%
  P%=JumpTableForGetValue+(opcode-128)*4
  O%=P%-&8000+code%
  [OPT pass%
    EQUD routine
  ]
=""

DEF FNnastyCheck0
LOCAL N%
[OPT pass%
 ADD    R0,R12,#RegFlag - 48
 MOV    R1,#24
 ADD    R0,R0,R1,LSL #1
 LDR    R0,[R0]
 TEQ    R0,#0
 BEQ    rc0_NotRegistered
 LDR    R0,[PC]
 B      rc0_Skip
 EQUD   CheckRegistration-1024
.rc0_Skip
 ADD    R0,R0,R1
 ADD    R0,R0,#&3E0
 MOV    R1,#0
 MOV    R2,#NotRegistered - CheckRegistration
 ADD    R0,R0,#8
.lp
 LDR    R3,[R0],#4
 EOR    R1,R1,R3
 SUBS   R2,R2,#4
 BNE    lp
 LDR    R0,rc0_ShouldBe
 CMP    R0,R1
 BEQ    rc0_NotRegistered
 MOV    R0,#1
 SWI    "XOS_ReadDynamicArea"
 STR    R1,[R0]                                 ; lovely way of corrupting memory
 B      rc0_NotRegistered
.rc0_ShouldBe
 EQUD   0
.rc0_NotRegistered
]
=""

DEF FNnastyCheck1
[OPT pass%
 ADD    R0,R12,#RegFlag + 128
 MOV    R1,#32
 SUB    R0,R0,R1,LSL #2
 LDR    R0,[R0]
 TEQ    R0,#1
 BEQ    rc1_Registered
 LDR    R0,[R12,#EqHandle]
 ADD    R1,R12,#rc_Startup
 LDMIA  R1,{R1}
 MOV    R2,#3
 SWI    "XEqWimp_ReadIconString"
 BVS    rc1_crash
 ADR    R0,rc1_EoredString
.rc1_lp
 LDRB   R2,[R0],#1
 EOR    R2,R2,#&67
 LDRB   R3,[R1],#1
 CMP    R3,#10
 CMPNE  R3,#13
 MOVEQ  R3,#0
 TEQ    R2,#0
 TEQEQ  R3,#0
 BEQ    rc1_Registered
 TEQ    R2,R3
 BEQ    rc1_lp
.rc1_crash
 SWI    "OS_EnterOS"
 TEQP   PC,#&C000003
 MOV    R13,#0
 ADR    R0,P%-16
 LDMIA  R0,{R1-R7}
 STMIA  R13,{R1-R7}
 B      P%
.rc1_EoredString EQUS "* UNREGISTERED VERSION *"+CHR$0:ALIGN
.rc1_Registered
]

FOR N%=rc1_EoredString-&8000+code% TO rc1_Registered-&8000+code%-1
 ?N% = ?N% EOR &67
NEXT
=""

DEF FNnastyCheck3
[OPT pass%
 FNadr(0,CheckMeFromHere - 44)
 MOV R1,#ToHere - CheckMeFromHere
 ADD R0,R0,#44
 MOV R2,#0
.lp
 LDR R3,[R0],#4
 EOR R2,R2,R3
 SUBS R1,R1,#4
 BNE lp
 LDR R3,nc3_ShouldBe
 TEQ R2,R3
 BEQ nc3_ok

 LDR R0,[PC]
 MOV PC,PC
 MOVS PC,R14
 FNadr(3,Release + 128)
 STR R0,[R3,#-128]
 B nc3_ok

.nc3_ShouldBe EQUD 0
.nc3_ok
]
=""

DEF FNDebug(string$)
IF debug% THEN
[OPT pass%
STMFD R13!,{R0}
ADR R0,P%+12:BL PrintString:B P%+4+(LEN(string$)+4 AND NOT 3)
EQUS string$+CHR$0:ALIGN
BL _Debug
ldmfd r13!,{r0}
]
ENDIF
=""

DEF FNbreakpoint
IF debug% THEN
[OPT pass%
STMFD R13!,{R14}
BL Breakpoint
LDMFD R13!,{R14}
]
ENDIF
=""

DEF FNAlignToCacheBoundary
WHILE P% AND 63
 [OPT pass%:EQUB 0:]
ENDWHILE
=""
