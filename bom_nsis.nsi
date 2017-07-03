
!define PRODUCT_NAME "bug-o-matic"
!define PRODUCT_VERSION "0.0.1a"
!define PRODUCT_PUBLISHER "Ishan Shrivastava"

name "bug-o-matic Pidgin plugin for Oracle internal network"
OutFile "bug-o-matic-${PRODUCT_VERSION}.exe"
  
Function .onInit
	ReadEnvStr $0 USERPROFILE
	IfFileExists "$0\AppData\Roaming\.purple" pidginCheckTrue pidginCheckFalse
	pidginCheckFalse:
		MessageBox MB_OK "Pidgin installation directory not found, Aborting."
		Abort
	pidginCheckTrue:
		DetailPrint "Pidgin installation directory found."
FunctionEnd

; Install Strawberry Perl
Section -Prerequisites
	SetOutPath $INSTDIR
	File "strawberry-perl-5.20.3.3-32bit.msi"
	MessageBox MB_YESNO "Install Strawberry Perl?" /SD IDYES IDNO endStrawberryPerl
	ExecWait "msiexec /i $INSTDIR\strawberry-perl-5.20.3.3-32bit.msi"
	Goto endStrawberryPerl
	endStrawberryPerl:
SectionEnd

; Copy the plugin script to the needed location
Section -PluginCopy
	ReadEnvStr $0 USERPROFILE
	SetOutPath "$0\AppData\Roaming\.purple\plugins\"
	SetOverwrite ifnewer
	File bug_o_matic.pl
SectionEnd

; Reboot now?
Section -RebootNow
	MessageBox MB_YESNO|MB_ICONQUESTION "You need to restart the system to use the plugin. Reboot now?" IDNO +2
	Reboot
SectionEnd
