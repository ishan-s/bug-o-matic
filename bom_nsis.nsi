
!define PRODUCT_NAME "bug-o-matic"
!define PRODUCT_VERSION "0.0.2a"
!define PRODUCT_PUBLISHER "Ishan Shrivastava"

SetCompressor /SOLID zlib
BrandingText "ishan.shrivastava@oracle.com"
InstallColors /windows
RequestExecutionLevel admin

name "bug-o-matic Pidgin plugin for Oracle"
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
Section Prerequisites 1
	SetOutPath $INSTDIR
	File "strawberry-perl-5.20.3.3-32bit.msi"
	MessageBox MB_YESNO "bug-o-matic needs to enable Perl plugin support for Pidgin.$\nInstall Strawberry Perl?" /SD IDYES IDNO endStrawberryPerl
	ExecWait "msiexec /i $INSTDIR\strawberry-perl-5.20.3.3-32bit.msi"
	Goto endStrawberryPerl
	endStrawberryPerl:
SectionEnd

; Copy the plugin script to the needed location
Section PluginCopy 2
	ReadEnvStr $0 USERPROFILE
	SetOutPath "$0\AppData\Roaming\.purple\plugins\"
	SetOverwrite ifnewer
	File bug_o_matic.pl
SectionEnd

; Final instructions and reboot confirmation
Section RebootNow 3
	MessageBox MB_OK "Plugin installed. You will be prompted to reboot now (which is needed to enable Perl plugins for Pidgin).\
	$\n$\nAfter reboot, please enable bug-o-matic from Pidgin: Tools > Plugins" IDOK +1
	MessageBox MB_YESNO|MB_ICONQUESTION "You need to restart the system to use the plugin. Reboot now?" IDNO +2
	Reboot
SectionEnd
