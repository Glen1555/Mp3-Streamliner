#SingleInstance, Force

;first check if ffmpeg is installed
;use user directory

EchoFile := A_MyDocuments . "\echo_ffmpeg_Existence_test.txt"

IfExist,%EchoFile%
{
	FileDelete,%EchoFile%
	Sleep,1000
}

RunWait, %Comspec% /min /c ffmpeg.exe -h >"%EchoFile%",,HIDE

Sleep, 1000

IfExist,%EchoFile%
{
	FileGetSize, ffmpegHelpFileSize , %EchoFile%
	FileDelete,%EchoFile%
	If (ffmpegHelpFileSize < 2000)
	{
		MsgBox,,,NOTE that it does not appear that ffmpgeg is installed on your computer. Running on selected mp3s will probably do nothing if this check process is correct that ffmpeg is not installed. You can try. Else select cancel. Click OK to continue.
	}
}

ShowChars := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'"

Global CRLF
CRLF=`r`n
DoCancel := 0
NotRunning := 1

BR_1 := 64000
BR_2 := 48000
BR_3 := 32000

HZ_1 := 22050
HZ_2 := 16000
HZ_3 := 11025

Global AllSources=

Gui Font, s12, Tahoma
Gui Add, Text, x24 y4 w628 h40 +0x200, Drag and Drop Files to Convert to Checked Selections Below.
Gui Font
Gui Font, s12, Tahoma
Gui Add, Text, x22 y43 w655 h40 +0x200, Sub Folders will be created and the converted files dropped there with originals untouched.
Gui Font


Gui Font
Gui Font, s12 Bold, Tahoma
Gui Add, Text, x40 y166 w285 h40 +0x200, YOU MAY SELECT ALL OF THESE:
Gui Font

Gui Font, s12, Tahoma
Gui Add, CheckBox, v64KB x39 y200 w371 h23, Convert dropped Mp3(s) to 64 KB at 22050 HZ
Gui Font

Gui Font, s12, Tahoma
Gui Add, CheckBox, v48KB x39 y223 w356 h23, Convert dropped Mp3(s) to 48 KB at 16000 HZ
Gui Font

Gui Font, s12, Tahoma
Gui Add, CheckBox, v32KB x39 y246 w356 h23, Convert dropped Mp3(s) to 32 KB at 11025 HZ
Gui Font

Gui Font
Gui Font, s12, Tahoma
Gui Add, CheckBox, vReplaceIt x39 y270 w307 h23, Replace pre-existing Converted Mp3(s).

Gui Font, s12, Tahoma
Gui Add, CheckBox, vRenamer x39 y295 w417 h23, Append Rate Text to file name (else identical filename)



Gui Font, s12, Verdana
Gui Add, Button, gPerform x36 y332 w599 h42, RUN - CONVERT FILES DROPPED TO FORMATS CHECKED ABOVE
Gui Font
Gui Font, s12, Verdana
Gui Add, Button, gCancelIt x109 y600 w471 h42, CANCEL AND/OR EXIT
Gui Font
Gui Font, s12, Tahoma
Gui Add, Text, x36 y402 w185 h23 +0x200, CONVERSION STATUS:
Gui Font
Gui Font, s11, Arial
Gui Add, Edit, vFileStatus x37 y429 w598 h120


Gui Font, s12, Tahoma
Gui Add, Text, x479 y204 w148 h46 +0x200, DROP FILES HERE
Gui Font
Gui Font, s12, Tahoma
Gui Add, Text, x99 y554 w509 h46 +0x200, NOTE: Cancelling occurs after current file being converted completes.
Gui Font

Gui Font, s12 Bold Underline, Tahoma
Gui Add, Text, x20 y86 w652 h40 +0x200, Originals having lower bit rates than selected rates will be ignored.
Gui Add, Text, x20 y126 w652 h40 +0x200, Originals having equal bit rates will be copied over.
Gui Font
Gui Font, s12, Tahoma
Gui Add, Text, x84 y660 w540 h23 +0x200, Developed by Glen McInnis - 2022 - Please Visit "Thy Word We Love . Love"

Gui Show, w686 h700, Mp3 Streamliner (Size Reducer) 1.1
return

GuiClose:
	ExitApp

CancelIt:
{
	If (NotRunning or DoCancel)
	{
		Exitapp
	}
	DoCancel := 1
	{
		Info := "CANCELING - PLEASE WAIT"
		Gosub,BuildInfo
	}
	return
}

Perform:
{
	FilesAt512 := 0
	FilesAt256 := 0
	FilesAt128 := 0
	FilesAt96 := 0
	FilesAt64 := 0
	FilesAt48 := 0
	FilesAt32 := 0
	FilesAt16 := 0
	
	HoldInfo=
	PreExisting := 0
	Replaced := 0
	
	If FCount = 0
	{
		MsgBox,,,NO FILES DROPPED YET
		return
	}

	;create folders if non-existent
	;pull directory out of first source file

	SourceFile := Source_1
	SplitPath, SourceFile,, dir
	
	Dir64 := dir . "\" . "64 KB"
	Dir48 := dir . "\" . "48 KB"
	Dir32 := dir . "\" . "32 KB"

	ToDir_1 := Dir64
	ToDir_2 := Dir48
	ToDir_3 := Dir32
	
	GuiControlGet,Do64,,64KB
	GuiControlGet,Do48,,48KB
	GuiControlGet,Do32,,32KB
	
	GuiControlGet,DoReplace,,ReplaceIt
	GuiControlGet,DoRenamer,,Renamer

	If DoRenamer
	{
		TextDir_1 := " 64 KB"
		TextDir_2 := " 48 KB"
		TextDir_3 := " 32 KB"
	}

	AtLeastOneChecked := Do64 + Do48 + Do32
	If !AtLeastOneChecked
	{
		MsgBox,,,You have to select 1 or more Bit Rates (The top 3 check boxes)
		return
	}
	
	NotRunning := 0
	
	bRate_1 := Do64
	bRate_2 := Do48
	bRate_3 := Do32
	
	TotalFCount := 0
	
	RatesChecked := 0
	
	If Do64
	{
		RatesChecked := RatesChecked + 1
		TotalFCount := TotalFCount + FCount
		IfNotExist,%Dir64%
		{
			FileCreateDir,%Dir64%
		}
	}

	If Do48
	{
		RatesChecked := RatesChecked + 1
		TotalFCount := TotalFCount + FCount
		IfNotExist,%Dir48%
		{
			FileCreateDir,%Dir48%
		}
	}
	
	If Do32
	{
		RatesChecked := RatesChecked + 1
		TotalFCount := TotalFCount + FCount
		IfNotExist,%Dir32%
		{
			FileCreateDir,%Dir32%
		}
	}

	InfoOut := "Beginning " . TotalFCount . " Processes"
	RemainingProcesses := TotalFCount
	
	If DoRenamer
	{
		InfoOut := InfoOut . " - Renaming files - Originals untouched"
	}
	else
	{
		InfoOut := InfoOut . " - Keeping Same Filename - Originals untouched"
	}
	
	GuiControl,,FileStatus,%InfoOut%
	
	Conversions := 0

	Loop,%FCount%
	{
		SourceFile := Source_%A_Index%
		
		SplitPath, SourceFile,JustSourceFile
		
		Gosub, GetAudioBitRate
		
		If BitRate = 512000
			FilesAt512++
		If BitRate = 256000
			FilesAt256++
		If BitRate = 128000
			FilesAt128++
		If BitRate = 96000
			FilesAt96++
		If BitRate = 64000
			FilesAt64++
		If BitRate = 48000
			FilesAt48++
		If BitRate = 32000
			FilesAt32++
		If BitRate = 16000
			FilesAt16++

		;loop through all 3 bit rates 64000, 48000, 32000
		
		
		Loop, 3
		{
			
			This_BitRate := BR_%A_Index%
			This_HZ := HZ_%A_Index%
			This_DO := bRate_%A_Index%
			TargetTextDir := TextDir_%A_Index%
			ToDirectory := ToDir_%A_Index%
			
			If This_DO
			{
				RemainingProcesses := RemainingProcesses - 1
				StringReplace,DestinationFile,SourceFile,%dir%,%ToDirectory%
				If DoRenamer
				{
					StringReplace,DestinationFile,DestinationFile,.mp3,%TargetTextDir%.mp3
				}
				SplitPath, DestinationFile,OutJustFilename
				
				OkToConvert := 1
				
				If (BitRate = This_BitRate)
				{
					Info := "Already at " . This_BitRate . " Copying over (" . JustSourceFile . ")" . CRLF
					FileCopy,%SourceFile%,%DestinationFile%
					Info := "Copying to " . ToDirectory . "  ("  . OutJustFilename . ")"
					Gosub,BuildInfo
					OkToConvert := 0
				}
				
				If (BitRate < This_BitRate)
				{
					Info := "Lower than " . This_BitRate . " (" . JustSourceFile . ")" . CRLF
					OkToConvert := 0
					HoldInfo := HoldInfo . Info . CRLF
				}
				
				If OkToConvert
				{
					DoThis := 1
					
					IfExist,%DestinationFile%
					{
						Action := "Converting"
						If DoReplace
						{
							Action := "Replacing"
							FileDelete,%DestinationFile%
							Sleep,1000
							Replaced++
						}
						else
						{
							PreExisting++
							DoThis := 0
						}
					}

					If DoThis
					{
						StringLen,FLen,OutJustFilename
						If (FLen > 50)
						{
							x := 22
							Loop
							{
								StringMid,ABC,OutJustFilename,x,1
								IfNotInstring,ShowChars,%ABC%
									break
								x++
							}
							If (x > (FLen - 10))
								x := 22
								
							StringLeft,LL,OutJustFilename,x-1
							
							x := FLen - 22
							Loop
							{
								StringMid,ABC,OutJustFilename,x,1
								IfNotInstring,ShowChars,%ABC%
									break
								x--
							}
							If (x < 22)
							{
								x = 22
							}
								
							StringRight,RR,OutJustFilename,FLen - x
	

							CutFilename := LL . " ... " . RR
						}
						else
						{
							CutFilename := OutJustFilename
						}
						
						Info := CutFilename . " - " . Action . " " . BitRate . " to " . This_BitRate
						Gosub,BuildInfo
						RunWait, %Comspec% /min /c ffmpeg.exe -i "%SourceFile%" -ac 1 -ab "%This_BitRate%" -ar "%This_HZ%" "%DestinationFile%",,HIDE
						Conversions++
						
						IfExist,%DestinationFile%
						{
							Info := "SUCCESS : " . RemainingProcesses . " Processes of Selected Remaining"
						}
						else
						{
							Info := "CONVERSION FAILED"
						}
						Gosub,BuildInfo
					}
				}
			}
			
			If DoCancel
			{
				break
			}
		}
			
		If DoCancel
		{
			Gosub,BuildCancel
			break
		}

	}

	If HoldInfo
	{
		MsgBox,,,SKIPPED FILES UNDER BR:%CRLF%%CRLF%%HoldInfo%
	}

	If !DoCancel
	{
		TMessage := CRLF . Conversions . " Conversions Completed"
		If Replaced
		{
			TMessage := TMessage . CRLF . CRLF . "Replaced " . Replaced . " Files Previously Converted"
		}
		If PreExisting
		{
			TMessage := TMessage . CRLF . CRLF . "Ignored " . PreExisting . " Files Already Converted"
		}
		GuiControl,,FileStatus,%TMessage%
	}
	NotRunning := 1
	DoCancel := 0
	
	;present report of found bit rates
	
	Stats=

	If (FilesAt512 > 0)
		Stats := Stats . FilesAt512 . " at 512" . CRLF
	If (FilesAt256 > 0)
		Stats := Stats . FilesAt256 . " at 256" . CRLF
	If (FilesAt128 > 0)
		Stats := Stats . FilesAt128 . " at 128" . CRLF
	If (FilesAt96 > 0)
		Stats := Stats . FilesAt96 . " at 96" . CRLF
	If (FilesAt64 > 0)
		Stats := Stats . FilesAt64 . " at 64" . CRLF
	If (FilesAt48 > 0)
		Stats := Stats . FilesAt48 . " at 48" . CRLF
	If (FilesAt32 > 0)
		Stats := Stats . FilesAt32 . " at 32" . CRLF
	If (FilesAt16 > 0)
		Stats := Stats . FilesAt16 . " at 16" . CRLF

	If Stats
	{
		Stats := "Original Bit Rates:" . CRLF . CRLF . Stats
		MsgBox,,,%Stats%
	}
		
return
}

BuildInfo:
{
	InfoOut := Info . CRLF . CRLF . InfoOut
	GuiControl,,FileStatus,%InfoOut%
	return
}

BuildCancel:
{
	TMessage := CRLF . "PROCESS CANCELED" . CRLF . CRLF . Conversions . " Conversions Completed"
	If Replaced
	{
		TMessage := TMessage . CRLF . CRLF . "Replaced " . Replaced . " Files Previously Converted"
	}
	If PreExisting
	{
		TMessage := TMessage . CRLF . CRLF . "Ignored " . PreExisting . " Files Already Converted"
	}
	GuiControl,,FileStatus,%TMessage%
	return
}

GuiDropFiles:
;msgbox % A_GuiEvent
FCount := 0
AllSources := "DROPPED FILES" . CRLF . CRLF
Loop, parse, A_GuiEvent, `n
{
	FCount++
	FileThis := A_LoopField
	Source_%FCount% = %FileThis%
	SplitPath, FileThis,OutJustFilename

	AllSources := AllSources . OutJustFilename . CRLF
	
}
GuiControl,,FileStatus,%AllSources%

return

GetAudioBitRate:
{
	AudioInfoTarget=%dir%\audioinfo.txt

	FileDelete, %AudioInfoTarget%
	
	BitRateInfoError=0

	AudioReadAttempts=0

	AudioRead:

	AudioReadAttempts++

	RetryGenerateAudioInfo:


	Sleep, 600

	TextSource=%AudioInfoTarget%

	RunWait %Comspec% /min /c ffprobe.exe -v quiet -show_entries stream=bit_rate "%SourceFile%" > "%AudioInfoTarget%" 2>>&1,%ffmpegDir%,Hide

	Sleep, 1000

	BitRateFileType=audio
	
	Gosub, ExtractBitRateFromTextFile

	return
}

ExtractBitRateFromTextFile:
{
	textsourcefile := FileOpen(TextSource, "r")
	Numreads=0

	ReadUntilBitRate:
	Numreads++

	If Numreads=3
	{
		BitRateInfoError=1
	}
	else
	{
		ThisLine := textsourcefile.ReadLine()
		IfNotInString, ThisLine, bit_rate
		Goto, ReadUntilBitRate
		StringReplace, ThisLine,ThisLine, `r,, All
		StringReplace, ThisLine,ThisLine, `n,, All
		StringSplit, BitRateArray, ThisLine, =
		BitRate := BitRateArray2
		textsourcefile.Close()
		FileDelete, %TextSource%
	}
return
}
