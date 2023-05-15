; This file is a part of CuteMouse source
; Here are messages in English

E_needvga       db 'No VGA? Use older CTMOUSE if you need EGA RIL support',nl,eos
E_error		db nl,'Error: Invalid option'
E_option	db eos
E_argument	db ' argument',eos
E_help		db 5,nl,'Enter /? on command line for help',eos

E_mousepresent	db 5,'Mouse services already present',eos
E_notfound	db 5,'Error: device not found',eos
;;+E_noIRQ	db 5,'Error: IRQ line not detected',eos

E_nocute	db 1,'CuteMouse driver is not installed!',eos
E_notunload	db 2,'Driver unload failed: some interrupts intercepted...',eos
S_unloaded	db 0,'Driver successfully unloaded...',eos

S_reset		db 'Resident part reset to ',eos
S_installed	db 'Installed at ',eos
S_atPS2		db 'PS/2 port',eos
S_atIOFull	db '('
S_atIO		db '0000h/IRQ'
IRQno		db ?
S_in		db ') in ',eos
S_inMSYS	db 'Mouse Systems mode',eos
S_inMS		db 'Microsoft mode',eos
S_inLT		db 'Logitech mode',eos
S_wheel		db ' (wheel present)'
S_CRLF		db nl,eos

Copyright	db nl,'DirtyRat ',DRTRATVER,' based on CuteMouse v',CTMRELEASE,nl,eos
Syntax		label byte
    db 0,nl,'Options:',nl
    db '  /A[a]    - Device I/O Address hex lower-case (default: 2e8). Example: /A2e8',nl
    db '  /I[i]    - Device IRQ number decimal (default: 3). Example: /I3',nl
    db '  /R[h[v]] - horizontal / vertical resolution: h,v = 1-9, or 0 for auto',nl
    db '	     (no value = use default: auto for h, or "as h" for v)',nl
    db '  /L	   - swap left and right button',nl,nl
;
    db '  /B	   - cancel run if mouse services are already present',nl
    db '  /N	   - load CuteMouse as new TSR, even if CuteMouse is already loaded',nl
    db '	     (useful for batch files which unload CuteMouse at end)',nl
    db '  /W	   - do not allow CuteMouse to move itself into UMB',nl
    db '  /U	   - uninstall driver, remove TSR from memory',nl
    db '  /?	   - show this help',eos
