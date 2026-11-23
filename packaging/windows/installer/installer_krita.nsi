!ifndef KRITA_INSTALLER_32 & KRITA_INSTALLER_64
	!error "Either one of KRITA_INSTALLER_32 or KRITA_INSTALLER_64 must be defined."
!endif
!ifdef KRITA_INSTALLER_32 & KRITA_INSTALLER_64
	!error "Only one of KRITA_INSTALLER_32 or KRITA_INSTALLER_64 should be defined."
!endif

!ifndef KRITA_PACKAGE_ROOT
	!error "KRITA_PACKAGE_ROOT should be defined and point to the root of the package files."
!endif

!ifdef KRITA_INSTALLER_64
	!define KRITA_INSTALLER_BITNESS 64
!else
	!define KRITA_INSTALLER_BITNESS 32
!endif

Unicode true
# Enabling DPI awareness creates awful CJK text in some sizes, so don't enable it.
ManifestDPIAware false

# Krita constants (can be overridden in command line params)
!define /ifndef KRITA_VERSION "0.0.0.0"
!define /ifndef KRITA_VERSION_DISPLAY "test-version"
#!define /ifndef KRITA_VERSION_GIT ""
!define /ifndef KRITA_INSTALLER_OUTPUT_DIR ""
!ifdef KRITA_INSTALLER_64
	!define /ifndef KRITA_INSTALLER_OUTPUT_NAME "krita_x64_setup.exe"
!else
	!define /ifndef KRITA_INSTALLER_OUTPUT_NAME "krita_x86_setup.exe"
!endif

# Krita constants (fixed)
!if "${KRITA_INSTALLER_OUTPUT_DIR}" == ""
	!define KRITA_INSTALLER_OUTPUT "${KRITA_INSTALLER_OUTPUT_NAME}"
!else
	!define KRITA_INSTALLER_OUTPUT "${KRITA_INSTALLER_OUTPUT_DIR}\${KRITA_INSTALLER_OUTPUT_NAME}"
!endif
!define KRTIA_PUBLISHER "imagic"
!ifdef KRITA_INSTALLER_64
	!define KRITA_PRODUCTNAME "imagic studio (x64)"
	!define KRITA_UNINSTALL_REGKEY "imagicStudio_x64"
!else
	!define KRITA_PRODUCTNAME "imagic studio (x86)"
	!define KRITA_UNINSTALL_REGKEY "imagicStudio_x86"
!endif
# imagic studio installs side by side with Krita: it has its own registry
# key, uninstall entry and ProgID, and never reads, replaces or removes
# anything that belongs to a Krita install.
!define IMAGIC_REGKEY "Software\imagic studio"
!define IMAGIC_PROGID "imagicStudio.Image"
# imagic studio 1.0.0 and 1.0.1 registered under Krita's own keys.
!define IMAGIC_LEGACY_UNINSTALL_REGKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\Krita_x64"

VIProductVersion "${KRITA_VERSION}"
VIAddVersionKey "CompanyName" "${KRTIA_PUBLISHER}"
VIAddVersionKey "FileDescription" "${KRITA_PRODUCTNAME} ${KRITA_VERSION_DISPLAY} Setup"
VIAddVersionKey "FileVersion" "${KRITA_VERSION}"
VIAddVersionKey "InternalName" "${KRITA_INSTALLER_OUTPUT_NAME}"
VIAddVersionKey "LegalCopyright" "${KRTIA_PUBLISHER}"
VIAddVersionKey "OriginalFileName" "${KRITA_INSTALLER_OUTPUT_NAME}"
VIAddVersionKey "ProductName" "${KRITA_PRODUCTNAME} ${KRITA_VERSION_DISPLAY} Setup"
VIAddVersionKey "ProductVersion" "${KRITA_VERSION}"

BrandingText "[NSIS ${NSIS_VERSION}]  ${KRITA_PRODUCTNAME} ${KRITA_VERSION}"

Name "${KRITA_PRODUCTNAME} ${KRITA_VERSION_DISPLAY}"
OutFile ${KRITA_INSTALLER_OUTPUT}
!ifdef KRITA_INSTALLER_64
	InstallDir "$PROGRAMFILES64\imagic studio (x64)"
!else
	InstallDir "$PROGRAMFILES32\imagic studio (x86)"
!endif
XPstyle on

ShowInstDetails show
ShowUninstDetails show

Var KritaStartMenuFolder
Var CreateDesktopIcon

!include MUI2.nsh

!define MUI_FINISHPAGE_NOAUTOCLOSE

# Installer Pages
!insertmacro MUI_PAGE_WELCOME
!define MUI_LICENSEPAGE_CHECKBOX
!insertmacro MUI_PAGE_LICENSE "license_gpl-3.0.rtf"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "imagic studio"
!define MUI_STARTMENUPAGE_REGISTRY_ROOT HKLM
!define MUI_STARTMENUPAGE_REGISTRY_KEY "${IMAGIC_REGKEY}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "StartMenuFolder"
!define MUI_STARTMENUPAGE_NODISABLE
!insertmacro MUI_PAGE_STARTMENU Krita $KritaStartMenuFolder
Page Custom func_BeforeInstallPage_Init
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

# Uninstaller Pages
!define MUI_PAGE_CUSTOMFUNCTION_PRE un.func_UnintallFirstpage_Init
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

# Languages
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "TradChinese"
!insertmacro MUI_LANGUAGE "SimpChinese"

!include Sections.nsh
!include LogicLib.nsh
!include x64.nsh
!include WinVer.nsh
!include WordFunc.nsh

!define KRITA_SHELLEX_DIR "$INSTDIR\shellex"

!include "include\FileExists2.nsh"
!include "include\IsFileInUse.nsh"
!include "krita_versions_detect.nsh"
!include "krita_shell_integration.nsh"

Var KritaNsisVersion
Var KritaNsisBitness
Var KritaNsisInstallLocation

!macro Imagic_ForEachDocType_Macro _var
	Push ""
	Push ".kra"
	Push ".krz"
	Push ".ora"
	${Do}
		Pop "${_var}"
		${If} "${_var}" == ""
			${Break}
		${EndIf}
!macroend
!define Imagic_ForEachDocType "!insertmacro Imagic_ForEachDocType_Macro"

# Offer imagic studio in "Open with" for its formats through its own ProgID.
# A document type only gets imagic studio as its default when nothing else
# (for example Krita) already owns it.
!macro Imagic_RegisterFileAssociation_Macro ExePath
	File "/oname=${KRITA_SHELLEX_DIR}\kritafile.ico" kritafile.ico
	File "/oname=${KRITA_SHELLEX_DIR}\krita.ico" krita.ico
	WriteRegStr HKCR "${IMAGIC_PROGID}" "" "imagic studio Image"
	WriteRegStr HKCR "${IMAGIC_PROGID}" "FriendlyTypeName" "imagic studio Image"
	WriteRegStr HKCR "${IMAGIC_PROGID}\DefaultIcon" "" "$\"${KRITA_SHELLEX_DIR}\kritafile.ico$\",0"
	WriteRegStr HKCR "${IMAGIC_PROGID}\shell\open" "FriendlyAppName" "imagic studio"
	WriteRegStr HKCR "${IMAGIC_PROGID}\shell\open\command" "" "$\"${ExePath}$\" $\"%1$\""
	WriteRegStr HKLM "${IMAGIC_REGKEY}\Capabilities" "ApplicationName" "imagic studio"
	WriteRegStr HKLM "${IMAGIC_REGKEY}\Capabilities" "ApplicationDescription" "imagic studio image editor"
	Push $0
	Push $1
	${Imagic_ForEachDocType} $0
		WriteRegStr HKCR "$0\OpenWithProgIds" "${IMAGIC_PROGID}" ""
		WriteRegStr HKLM "${IMAGIC_REGKEY}\Capabilities\FileAssociations" "$0" "${IMAGIC_PROGID}"
		ReadRegStr $1 HKCR "$0" ""
		${If} $1 == ""
			WriteRegStr HKCR "$0" "" "${IMAGIC_PROGID}"
		${EndIf}
	${Loop}
	${ForEachGenericImage} $0
		WriteRegStr HKCR "$0\OpenWithProgIds" "${IMAGIC_PROGID}" ""
		WriteRegStr HKLM "${IMAGIC_REGKEY}\Capabilities\FileAssociations" "$0" "${IMAGIC_PROGID}"
	${EndForEachGenericImage}
	Pop $1
	Pop $0
	WriteRegStr HKLM "Software\RegisteredApplications" "imagic studio" "${IMAGIC_REGKEY}\Capabilities"
!macroend
!define Imagic_RegisterFileAssociation '!insertmacro Imagic_RegisterFileAssociation_Macro'

!macro Imagic_UnregisterFileAssociation_Macro
	Delete ${KRITA_SHELLEX_DIR}\kritafile.ico
	Delete ${KRITA_SHELLEX_DIR}\krita.ico
	DeleteRegValue HKLM "Software\RegisteredApplications" "imagic studio"
	Push $0
	Push $1
	${Imagic_ForEachDocType} $0
		DeleteRegValue HKCR "$0\OpenWithProgIds" "${IMAGIC_PROGID}"
		ReadRegStr $1 HKCR "$0" ""
		${If} $1 == "${IMAGIC_PROGID}"
			DeleteRegValue HKCR "$0" ""
		${EndIf}
	${Loop}
	${ForEachGenericImage} $0
		DeleteRegValue HKCR "$0\OpenWithProgIds" "${IMAGIC_PROGID}"
	${EndForEachGenericImage}
	Pop $1
	Pop $0
	DeleteRegKey HKCR "${IMAGIC_PROGID}"
!macroend
!define Imagic_UnregisterFileAssociation '!insertmacro Imagic_UnregisterFileAssociation_Macro'

Section "$(SectionRemoveOldVer)" SEC_remove_old_version
	${If} $KritaNsisInstallLocation != ""
	${AndIf} ${FileExists} "$KritaNsisInstallLocation\uninstall.exe"
		push $R0
		DetailPrint "$(RemovingOldVer)"
		SetDetailsPrint listonly
		ExecWait "$KritaNsisInstallLocation\uninstall.exe /S _?=$KritaNsisInstallLocation" $R0
		${If} $R0 != 0
			${IfNot} ${Silent}
				MessageBox MB_OK|MB_ICONSTOP "$(RemoveOldVerFailed)"
			${EndIf}
			SetDetailsPrint both
			DetailPrint "$(RemoveOldVerFailed)"
			Abort
		${EndIf}
		Delete "$KritaNsisInstallLocation\uninstall.exe"
		RMDir /REBOOTOK "$KritaNsisInstallLocation"
		SetRebootFlag false
		SetDetailsPrint lastused
		DetailPrint "$(RemoveOldVerDone)"
		pop $R0
	${EndIf}
SectionEnd

Section "-Thing"
	SetOutPath $INSTDIR
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KRITA_UNINSTALL_REGKEY}" \
	                 "DisplayName" "${KRITA_PRODUCTNAME} ${KRITA_VERSION_DISPLAY}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KRITA_UNINSTALL_REGKEY}" \
	                 "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KRITA_UNINSTALL_REGKEY}" \
	                 "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	WriteUninstaller $INSTDIR\uninstall.exe
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KRITA_UNINSTALL_REGKEY}" \
	                 "DisplayVersion" "${KRITA_VERSION}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KRITA_UNINSTALL_REGKEY}" \
	                 "DisplayIcon" "$\"$INSTDIR\shellex\krita.ico$\",0"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KRITA_UNINSTALL_REGKEY}" \
	                 "URLInfoAbout" "https://imagic.ink/"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KRITA_UNINSTALL_REGKEY}" \
	                 "InstallLocation" "$INSTDIR"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KRITA_UNINSTALL_REGKEY}" \
	                 "Publisher" "${KRTIA_PUBLISHER}"
	#WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KRITA_UNINSTALL_REGKEY}" \
	#                   "EstimatedSize" 250000
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KRITA_UNINSTALL_REGKEY}" \
	                   "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KRITA_UNINSTALL_REGKEY}" \
	                   "NoRepair" 1
	# Registry entries for version recognition
	#   InstallLocation:
	#     Where krita is installed
	WriteRegStr HKLM "${IMAGIC_REGKEY}" \
	                 "InstallLocation" "$INSTDIR"
	#   Version:
	#     Version of Krita
	WriteRegStr HKLM "${IMAGIC_REGKEY}" \
	                 "Version" "${KRITA_VERSION}"
	#   x64:
	#     Set to 1 for 64-bit Krita, can be missing for 32-bit Krita
!ifdef KRITA_INSTALLER_64
	WriteRegDWORD HKLM "${IMAGIC_REGKEY}" \
	                   "x64" 1
!else
	DeleteRegValue HKLM "${IMAGIC_REGKEY}" "x64"
!endif
	#   InstallerLanguage:
	#     Language used by the installer (to be re-used for the uninstaller)
	WriteRegStr HKLM "${IMAGIC_REGKEY}" \
	                 "InstallerLanguage" "$LANGUAGE"
	#   StartMenuFolder:
	#     Start Menu Folder
	#     Handled by Modern UI 2.0 MUI_PAGE_STARTMENU
SectionEnd

Section "${KRITA_PRODUCTNAME}" SEC_product_main
	# TODO: Maybe switch to explicit file list?
	File /r ${KRITA_PACKAGE_ROOT}\bin
	File /r ${KRITA_PACKAGE_ROOT}\lib
	File /r ${KRITA_PACKAGE_ROOT}\share
	File /r ${KRITA_PACKAGE_ROOT}\python
SectionEnd

Section "-Main_associate"
	CreateDirectory ${KRITA_SHELLEX_DIR}
	${Imagic_RegisterFileAssociation} "$INSTDIR\bin\krita.exe"
SectionEnd

Section "-Main_Shortcuts"
	# Placing this after Krita_RegisterFileAssociation to get the icon
	!insertmacro MUI_STARTMENU_WRITE_BEGIN Krita
		CreateDirectory "$SMPROGRAMS\$KritaStartMenuFolder"
		CreateShortcut "$SMPROGRAMS\$KritaStartMenuFolder\${KRITA_PRODUCTNAME}.lnk" "$INSTDIR\bin\krita.exe" "" "$INSTDIR\shellex\krita.ico" 0
	!insertmacro MUI_STARTMENU_WRITE_END
	${If} $CreateDesktopIcon == 1
		# For the desktop icon, keep the name short and omit version info
		CreateShortcut "$DESKTOP\imagic studio.lnk" "$INSTDIR\bin\krita.exe" "" "$INSTDIR\shellex\krita.ico" 0
	${EndIf}
SectionEnd

Section "-Main_refreshShell"
	${RefreshShell}
SectionEnd

Section "-Main_MSVC"
!ifdef KRITA_INSTALLER_64
	${If} ${FileExists} "$INSTDIR\bin\vc_redist.x64.exe"
		ExecWait "$INSTDIR\bin\vc_redist.x64.exe /install /quiet /norestart"
		Delete "$INSTDIR\bin\vc_redist.x64.exe"
	${Endif}
!else
	${If} ${FileExists} "$INSTDIR\bin\vc_redist.exe"
		ExecWait "$INSTDIR\bin\vc_redist.x86.exe /install /quiet /norestart"
		Delete "$INSTDIR\bin\vc_redist.x86.exe"
	${Endif}
!endif
SectionEnd

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	#!insertmacro MUI_DESCRIPTION_TEXT ${SEC_remove_shellex} "Remove previously installed Krita Shell Integration."
	!insertmacro MUI_DESCRIPTION_TEXT ${SEC_remove_old_version} "$(SectionRemoveOldVerDesc)"
	!insertmacro MUI_DESCRIPTION_TEXT ${SEC_product_main} "$(SectionMainDesc)"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Section "un.Main_associate"
	${Imagic_UnregisterFileAssociation}
SectionEnd

Section "un.Main_Shortcuts"
	Delete "$DESKTOP\imagic studio.lnk"
	!insertmacro MUI_STARTMENU_GETFOLDER Krita $KritaStartMenuFolder
	Delete "$SMPROGRAMS\$KritaStartMenuFolder\${KRITA_PRODUCTNAME}.lnk"
	RMDir "$SMPROGRAMS\$KritaStartMenuFolder"
SectionEnd

Section "un.${KRITA_PRODUCTNAME}"
	# TODO: Maybe switch to explicit file list or some sort of install log?
	RMDir /r $INSTDIR\bin
	RMDir /r $INSTDIR\lib
	RMDir /r $INSTDIR\share
	RMDir /r $INSTDIR\python
SectionEnd

Section "un.Thing"
	RMDir /REBOOTOK $INSTDIR\shellex
	DeleteRegKey HKLM "${IMAGIC_REGKEY}"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${KRITA_UNINSTALL_REGKEY}"
	Delete $INSTDIR\uninstall.exe
	RMDir /REBOOTOK $INSTDIR
SectionEnd

Section "un.Main_refreshShell"
	${RefreshShell}
SectionEnd

Function .onInit
	SetShellVarContext all
	!insertmacro SetSectionFlag ${SEC_product_main} ${SF_RO}
	!insertmacro SetSectionFlag ${SEC_product_main} ${SF_BOLD}
	!insertmacro SetSectionFlag ${SEC_remove_old_version} ${SF_RO}
	StrCpy $CreateDesktopIcon 1 # Create desktop icon by default
	${IfNot} ${AtLeastWin7}
		${IfNot} ${Silent}
			MessageBox MB_OK|MB_ICONSTOP "$(MsgRequireWin7)"
		${EndIf}
		Abort
	${EndIf}

	${IfNot} ${Silent}
		# Language selection, seems that the order is predefined.
		Push "" # This value is for languages auto count
		Push ${LANG_ENGLISH}
		Push English
		Push ${LANG_TRADCHINESE}
		Push "繁體中文"
		Push ${LANG_SIMPCHINESE}
		Push "简体中文"
		Push A # = auto count languages
		LangDLL::LangDialog "$(^SetupCaption)" "$(SetupLangPrompt)"
		Pop $LANGUAGE
		${If} $LANGUAGE == "cancel"
			Abort
		${Endif}
	${EndIf}

!ifdef KRITA_INSTALLER_64
	${If} ${RunningX64}
		SetRegView 64
	${Else}
		${IfNot} ${Silent}
			MessageBox MB_OK|MB_ICONSTOP "$(Msg64bitOn32bit)"
		${EndIf}
		Abort
	${Endif}
!else
	${If} ${RunningX64}
		SetRegView 64
		${IfNot} ${Silent}
			MessageBox MB_YESNO|MB_ICONEXCLAMATION "$(Msg32bitOn64bit)" \
			           /SD IDYES \
			           IDYES lbl_allow32on64
			Abort
		${EndIf}
		lbl_allow32on64:
	${Endif}
!endif

	# Find a previous imagic studio install. Krita's own installs (NSIS or
	# MSI) are deliberately never looked at, so they are never removed.
	StrCpy $KritaNsisVersion ""
	StrCpy $KritaNsisInstallLocation ""
	StrCpy $KritaNsisBitness ${KRITA_INSTALLER_BITNESS}
	ClearErrors
	ReadRegStr $0 HKLM "${IMAGIC_REGKEY}" "InstallLocation"
	${If} ${Errors}
	${OrIf} $0 == ""
		# imagic studio 1.0.0/1.0.1 used Krita's keys. Only take that entry
		# when it really is imagic studio's.
		ReadRegStr $1 HKLM "${IMAGIC_LEGACY_UNINSTALL_REGKEY}" "DisplayName"
		StrCpy $1 $1 13
		${If} $1 == "imagic studio"
			ReadRegStr $KritaNsisInstallLocation HKLM "${IMAGIC_LEGACY_UNINSTALL_REGKEY}" "InstallLocation"
			ReadRegStr $KritaNsisVersion HKLM "${IMAGIC_LEGACY_UNINSTALL_REGKEY}" "DisplayVersion"
		${EndIf}
	${Else}
		StrCpy $KritaNsisInstallLocation $0
		ReadRegStr $KritaNsisVersion HKLM "${IMAGIC_REGKEY}" "Version"
	${EndIf}

	${If} $KritaNsisInstallLocation != ""
	${AndIf} ${FileExists} "$KritaNsisInstallLocation\uninstall.exe"
		!insertmacro SetSectionFlag ${SEC_remove_old_version} ${SF_SELECTED}
		${If} ${IsFileinUse} "$KritaNsisInstallLocation\bin\krita.exe"
			${IfNot} ${Silent}
				MessageBox MB_OK|MB_ICONEXCLAMATION "$(MsgKritaRunning)"
			${EndIf}
			SetErrorLevel 10
			Abort
		${EndIf}
	${Else}
		StrCpy $KritaNsisInstallLocation ""
		!insertmacro ClearSectionFlag ${SEC_remove_old_version} ${SF_SELECTED}
		SectionSetText ${SEC_remove_old_version} ""
	${EndIf}
FunctionEnd

Function un.onInit
	SetShellVarContext all
!ifdef KRITA_INSTALLER_64
	${If} ${RunningX64}
		SetRegView 64
	${Else}
		Abort
	${Endif}
!else
	${If} ${RunningX64}
		SetRegView 64
	${Endif}
!endif

	# Get and use installer language:
	Push $0
	ReadRegStr $0 HKLM "${IMAGIC_REGKEY}" "InstallerLanguage"
	${If} $0 != ""
		StrCpy $LANGUAGE $0
	${EndIf}
	Pop $0

	${If} ${Silent}
		# Only check here if running in silent mode. It's otherwise checked in
		# un.func_UnintallFirstpage_Init in order to display a prompt in the
		# correct language.
		${If} ${IsFileinUse} "$INSTDIR\bin\krita.exe"
			SetErrorLevel 10
			Abort
		${EndIf}
	${EndIf}
FunctionEnd

Function un.func_UnintallFirstpage_Init
	${If} ${IsFileinUse} "$INSTDIR\bin\krita.exe"
		${IfNot} ${Silent}
			MessageBox MB_OK|MB_ICONEXCLAMATION "$(MsgUninstallKritaRunning)"
		${EndIf}
		SetErrorLevel 10
		Quit
	${EndIf}
FunctionEnd

Var hwndChkDesktopIcon

Function func_DesktopShortcutPage_CheckChange
	${NSD_GetState} $hwndChkDesktopIcon $CreateDesktopIcon
	${If} $CreateDesktopIcon == ${BST_CHECKED}
		StrCpy $CreateDesktopIcon 1
	${Else}
		StrCpy $CreateDesktopIcon 0
	${EndIf}
FunctionEnd

Function func_BeforeInstallPage_Init
	push $R0

	nsDialogs::Create 1018
	pop $R0
	${If} $R0 == error
		Abort
	${EndIf}
	!insertmacro MUI_HEADER_TEXT "$(ConfirmInstallPageHeader)" "$(ConfirmInstallPageDesc)"

	${NSD_CreateLabel} 0u 0u 300u 20u "$(DesktopIconPageDesc2)"
	pop $R0

	${NSD_CreateCheckbox} 0u 20u 300u 10u "$(DesktopIconPageCheckbox)"
	pop $hwndChkDesktopIcon
	${If} $CreateDesktopIcon == 1
		${NSD_Check} $hwndChkDesktopIcon
	${Else}
		${NSD_Uncheck} $hwndChkDesktopIcon
	${EndIf}
	${NSD_OnClick} $hwndChkDesktopIcon func_DesktopShortcutPage_CheckChange

	${NSD_CreateLabel} 0u 40u 300u 140u "$(ConfirmInstallPageDesc2)"
	pop $R0

	# TODO: Add install option summary for review?

	nsDialogs::Show

	pop $R0
FunctionEnd


# Strings
!include "translations\English.nsh"
!include "translations\TradChinese.nsh"
!include "translations\SimpChinese.nsh"
