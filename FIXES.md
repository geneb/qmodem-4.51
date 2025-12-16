#Fixes for Borland/Turbo Pascal 7.0

QModem v4.51TD was originally built with Turbo Pascal 6.0.  A number of changes needed to be made in order
to allow it to properly build using Turbo Pascal 7.0.  This file describes the changes that were implemented.

Note that QModem used commercial libraries from TurboPower software, including Turbo Professional v5.11, Object Professional, and Async Professional.  The versions of Object Professional and Async Professional that were used are unknown.
The build in this repo uses the last known versions of Turbo Professional (v5.22), Object Professional (v1.30), and Async Professional (v2.03).

Those libraries can be found at the following repositories:
https://github.com/geneb/TurboProfessional
https://github.com/geneb/ObjectProfessional
https://github.com/geneb/AsyncProfessional

The file ``TPDEFINE.INC`` contains a list of defines that adjust the behavior of some aspects of the Turbo Professional library when its compiled.  While this file is from version 5.11 of the libraries, you should adjust your ``TPDEFINE.INC`` file to match.  The changes are:

{.$DEFINE UseMouse}
{.$DEFINE Tpro5Menu}
{.$DEFINE FourByteDates}
{$DEFINE AllowDateTime}
{.$DEFINE IncludeNumeric}
{.$DEFINE IncludeChoice}
{.$DEFINE UseBCD}
{.$DEFINE FastDispose}
{.$DEFINE ThwartSideKick}
{$DEFINE ExplodingWindows}
{$DEFINE ShadowedWindows}
{.$DEFINE TpEntryScrolls}
{.$DEFINE PickItemDisable}
{$DEFINE EnablePickOrientations}

If you decide to leave the ``TPDEFINE.INC`` file in place in the SRC directory, you'll need to add the following section needs to be added in order to ensure Heap6 is defined. (It governs some memory management code.)

  {$IFDEF Ver70}
    {$DEFINE Heap6}
    {$I-,P-,Q-}
  {$ENDIF}

##QMODEM.PAS

Enabled Open String Parameters ($P+) and turned enabled Var-string checking ($V+).

##INT24.PAS, QDIAL2.PAS, HOST.PAS, SCRIPTS4.PAS, KEY.PAS, GROUP02.PAS

References to the DelayCalibrate procedure were commented out.  This procedure was found in OpCRT, but including it in either Uses clause would cause a confict with TpCRT.  The DelayCalibrate procedure appears to have something to do with DesqView.  The procedure must have been added to Object Professional after version 1.20.  My v1.20 manual set does not include that procedure in the OpCRT documentation.


##SCREEN.PAS

``AllowE0Codes`` is no longer part of the Object Professional library set.  I'm not sure which version dropped it, but as of the last version (v1.30), it's no longer declared in OpEnhKbd.Pas.

The ``SendFileName`` function is missing.  Maybe an accidental delete before source release?  Not sure.

##FILES.PAS

The forward declaration for the ``CleanFileName`` function was missing from TPSTRING.PAS.  Fixed.

##GROUP02.PAS, QINSTALL.PAS

Removed the EnhancedKbdInstalled check.  May have been part of an older Turbo Professional release.

##BINFSE.PAS

Removed reference to ``AllowE0Codes``. (See SCREEN.PAS above)

##RUNQINST.PAS, QMMAIN.PAS

Referencing the UseEnhancedKbd flag from OpCrt causes conflict between the Crt and OpCrt units.  Based upon how it's referenced, I decided to comment out the reference to it.

##INSTAL3A.PAS, INSTAL3B.PAS

The QINSTALL program leans on the v5.11 version of TpMenu, which was included with the Qmodem source code release.  It's been renamed to "TpMenu0" in order to allow that version to be used in QINSTALL.


