ECHO OFF
REM
REM  Unregistered copies of DOORWAY will ignore the /M: parameter
REM  and limit DOS access to only 10 minutes.  You do not need to
REM  change this BAT file after you have registered your DOORWAY.
REM
DOORWAY PORT:%3:%4 /M:60 /S:* /K:0 /G:ON /A:ON /V:D^U /C:DOS
