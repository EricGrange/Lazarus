unit IdeDebuggerStringConstants;

{$mode objfpc}{$H+}

interface

{//$R images.rc}
{$R images.res}

resourcestring
  // Overlap with the IDE
  lisMenuOk = '&OK';
  lisCancel = 'Cancel';
  lisMenuHelp = '&Help';
  lisEnabled = 'Enabled';
  //lisDefault = 'Default';

  //

  dlgInspectIndexOfFirstItemToShow = 'Index of first item to show';
  dlgInspectAmountOfItemsToShow = 'Amount of items to show';
  dlgInspectBoundsDD = 'Bounds: %d .. %d';
  dlgBackConvOptAddNew = 'Add';
  dlgBackConvOptRemove = 'Remove';
  dlgBackConvOptMatchTypesByName = 'Match types by name';
  dlgBackConvOptAction = 'Action';
  dlgBackConvOptDebugOptions = 'Backend Converter';
  dlgIdeDbgDebugger = 'Debugger';
  dlgIdeDbgNewItem = 'New Item';
  dlgIdeDbgEnterName = 'Enter name';
  dlgBackConvOptName = 'Name';

  drsUseInstanceClass = 'Instance';
  drsUseInstanceClassHint = 'Use Instance class type';
  drsUseFunctionCalls = 'Function';
  drsUseFunctionCallsHint = 'Allow function calls';
  drsEnterExpression = 'Enter Expression';
  drsAddWatch = 'Add watch';
  drsEvaluate = 'Evaluate';
  drsInspect = 'Inspect';
  drsHistory = 'History';
  drsDebugConverter = 'Converter';
  drsNoDebugConverter= 'No Converter';
  drsDisableEnableUpdatesForTh = 'Disable/Enable updates for the entire window';
  drsNoHistoryKept = 'No history kept';
  drsInsertResultAtTopOfHistor = 'Insert result at top of history';
  drsAppendResultAtBottomOfHis = 'Append result at bottom of history';
  lisInspectShowColClass = 'Show class column';
  lisInspectShowColType = 'Show type column';
  lisInspectShowColVisibility = 'Show visibility column';
  drsNewValue = 'New Value';
  drsNewValueToAssignToTheVari = 'New value to assign to the variable in the '
    +'debugged process (use Shift-Enter to confirm)';

  dbgDispFormatDefault = 'Default';
  dbgDispFormatCharacter = 'Character';
  dbgDispFormatString = 'String';
  dbgDispFormatDecimal = 'Decimal';
  dbgDispFormatUnsigned = 'Unsigned';
  dbgDispFormatHexadecimal = 'Hexadecimal';
  dbgDispFormatFloatingPoin = 'Floating Point';
  dbgDispFormatPointer = 'Pointer';
  dbgDispFormatRecordStruct = 'Record/Structure';
  dbgDispFormatMemoryDump = 'Memory Dump';
  dbgDispFormatBinary = 'Binary';

  // Watch Property Dialog
  lisWatchPropert = 'Watch Properties';
  lisExpression = 'Expression:';
  lisRepeatCount = 'Repeat Count:';
  lisDigits = 'Digits:';
  lisAllowFunctio = 'Allow Function Calls';
  lisStyle = 'Style';


  drsUseInstanceClassType = 'Use Instance class type';
  dlgBackendConvOptDebugConverter = 'Backend Converter:';
  dlgBackendConvOptDefault = '- Default -';
  dlgBackendConvOptDisabled = '- Disabled -';
  drsRunAllThreadsWhileEvaluat = 'Run all threads while evaluating';


implementation

end.

