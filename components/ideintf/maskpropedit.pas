{ Copyright (C) 2005

 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Author: Lagunov Aleksey

  Abstract:
    Property Editors for TMaskEdit.EditMask of FCL and LCL.
}

unit MaskPropEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  // LCL
  Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, ButtonPanel, MaskEdit,
  // LazUtils
  LazUTF8, LazFileUtils,
  // IdeIntf
  LazIDEIntf, PropEdits, ComponentEditors, ObjInspStrConsts, IDEWindowIntf;

type

  { TMaskEditorForm }

  TMaskEditorForm = class(TForm)
    ButtonPanel1: TButtonPanel;
    EnableSetsCheckBox: TCheckBox;
    LoadSampleMasksButton: TButton;
    SaveLiteralCheckBox: TCheckBox;
    InputMaskEdit: TEdit;
    CharactersForBlanksEdit: TEdit;
    InputMaskLabel: TLabel;
    SampleMasksLabel: TLabel;
    CharactersForBlanksLabel: TLabel;
    TestInputLabel: TLabel;
    SampleMasksListBox: TListBox;
    TestMaskEdit: TMaskEdit;
    OpenDialog1: TOpenDialog;
    TestInputPanel: TPanel;
    procedure EnableSetsCheckBoxClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var {%H-}CloseAction: TCloseAction);
    procedure LoadSampleMasksButtonClick(Sender: TObject);
    procedure SampleMasksListBoxDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; {%H-}State: TOwnerDrawState);
    procedure SaveLiteralCheckBoxClick(Sender: TObject);
    procedure InputMaskEditChange(Sender: TObject);
    procedure CharactersForBlankEditChange(Sender: TObject);
    procedure SampleMasksListBoxClick(Sender: TObject);
    procedure MaskEditorFormCreate(Sender: TObject);
  private
    FEnableSets: Boolean;
    function ConstructEditmask: String;
    function GetEditMask: string;
    procedure LoadDEMFile(AFileName: string);
    procedure ReConstructEditmask;
    procedure SetEditMask(AValue: string);
    procedure SetEnableSets(AValue: Boolean);
    procedure UpdateTestEditor;
  public
    property EditMask: string read GetEditMask write SetEditMask;
    property EnableSets: Boolean write SetEnableSets;
  end; 

  { TEditMaskProperty }

  TEditMaskProperty = class(TStringPropertyEditor)
  public
    function  GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
    function GetMaskEdit: TCustomMaskEdit;
  end;

  { TMaskEditEditor }
  TCustomMaskEditAccess = class(TCustomMaskEdit)
  end; //Hack to get access to EditMask

  TMaskEditEditor = class(TDefaultComponentEditor)
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
    function MaskEdit: TCustomMaskEditAccess; virtual;
  end;

implementation

{$R *.lfm}

procedure ParseMaskLine(Line: String; out Caption, Example, Mask: String);
begin
  // in delphi .dem files every mask line contains:
  // mask name|mask example|mask

  // 1. Extract caption from Line
  Caption := Copy(Line, 1, Pos(' | ', Line) - 1);
  Delete(Line, 1, Length(Caption) + 3);

  // 2. Extract example from Line
  Example := Copy(Line, 1, Pos(' | ', Line) - 1);
  Delete(Line, 1, Length(Example) + 3);

  // 3. Copy what we have to Mask
  Mask := Line;
end;

function MaskDoFormatText(const EditMask: string; const Value: string; EnableSets: Boolean): String;
var
  P: Integer;
  S: String;
begin
  // cheat maskutils while it has no its own MaskDoFormatText
  S := EditMask;
  P := LastDelimiter(';', S);
  if P <> 0 then
  begin
    S[P + 1] := #32;
    dec(P);
    while (P > 0) and (S[P] <> ';') do
      dec(P);
    if P <> 0 then
     S[P + 1] := '0';
  end;
  try
    Result := FormatMaskText(S, Value, EnableSets);
  except
    Result := Value;
  end;
end;

{ TMaskEditorForm }

procedure TMaskEditorForm.MaskEditorFormCreate(Sender: TObject);
var
  aDemFile: string;
begin
  Caption := oisInputMaskEditor;
  LoadSampleMasksButton.Caption := oisMasks;
  SaveLiteralCheckBox.Caption := oisSaveLiteralCharacters;
  InputMaskLabel.Caption := oisInputMask;
  SampleMasksLabel.Caption := oisSampleMasks;
  CharactersForBlanksLabel.Caption := oisCharactersForBlanks;
  TestInputLabel.Caption := oisTestInput;

  EnableSetsCheckBox.Hint := oisEnableSetsHint;

  if LazarusIDE<>nil then
    aDemFile:=LazarusIDE.GetPrimaryConfigPath
  else
    aDemFile:=ExtractFileDir(ParamStrUTF8(0));
  aDemFile:=CleanAndExpandDirectory(aDemFile)+'maskeditmasks.txt';
  if FileExistsUTF8(aDemFile) then
    LoadDEMFile(aDemFile);
  IDEDialogLayoutList.ApplyLayout(Self);
end;

procedure TMaskEditorForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  IDEDialogLayoutList.SaveLayout(Self);
end;

procedure TMaskEditorForm.EnableSetsCheckBoxClick(Sender: TObject);
begin
  SetEnableSets(EnableSetsCheckBox.Checked);
end;

procedure TMaskEditorForm.LoadSampleMasksButtonClick(Sender: TObject);
begin
  OpenDialog1.InitialDir:=ExtractFileDir(ParamStrUTF8(0));
  if OpenDialog1.Execute then
    LoadDEMFile(OpenDialog1.FileName);
end;

procedure TMaskEditorForm.SampleMasksListBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  OldBrushStyle: TBrushStyle;
  OldTextStyle: TTextStyle;
  NewTextStyle: TTextStyle;
  ListBox: TListBox absolute Control;
  AMaskCaption, AMaskExample, AEditMask: String;
  R1, R2: TRect;
begin
  ListBox.Canvas.FillRect(ARect);
  if (Index >= 0) and (Index < ListBox.Items.Count) then
  begin
    OldBrushStyle := ListBox.Canvas.Brush.Style;
    ListBox.Canvas.Brush.Style := bsClear;

    OldTextStyle := ListBox.Canvas.TextStyle;
    NewTextStyle := OldTextStyle;
    NewTextStyle.Layout := tlCenter;
    ListBox.Canvas.TextStyle := NewTextStyle;

    ParseMaskLine(ListBox.Items[Index], AMaskCaption, AMaskExample, AEditMask);
    AMaskExample := MaskDoFormatText(AEditMask, AMaskExample, FEnableSets);

    R1 := ARect;
    R2 := ARect;
    R1.Right := (R1.Left + R1.Right) div 2;
    R2.Left := R1.Right + 1;
    ListBox.Canvas.TextRect(R1, R1.Left + 2, R1.Top, AMaskCaption);
    ListBox.Canvas.TextRect(R2, R2.Left + 2, R2.Top, AMaskExample);
    ListBox.Canvas.MoveTo(R2.Left - 1, R2.Top);
    ListBox.Canvas.LineTo(R2.Left - 1, R2.Bottom);
    ListBox.Canvas.Brush.Style := OldBrushStyle;
    ListBox.Canvas.TextStyle := OldTextStyle;
  end;
end;

procedure TMaskEditorForm.SaveLiteralCheckBoxClick(Sender: TObject);

begin
  ReconstructEditMask;
end;

procedure TMaskEditorForm.InputMaskEditChange(Sender: TObject);
begin
  UpdateTestEditor;
end;

procedure TMaskEditorForm.CharactersForBlankEditChange(Sender: TObject);
var
  S:string;
  SL: Boolean;
  BC: Char;
begin
  SplitEditMask(InputMaskEdit.Text, S, SL, BC);
  if (CharactersForBlanksEdit.Text<>'') and (Length(S) > 0) then
    begin
      BC := CharactersForBlanksEdit.Text[1];
      if SL then InputMaskEdit.Text:=S + MaskFieldSeparator + '1' + MaskFieldSeparator + BC
        else InputMaskEdit.Text:=S + MaskFieldSeparator + MaskNoSave + MaskFieldSeparator + BC;
    end
    else
      ReConstructEditMask
end;


Function TMaskEditorForm.ConstructEditmask : String;

Var
  S : String;
  B : Char;
  L : Boolean;

begin
  SplitEditMask(InputMaskEdit.Text,S,L,B);
  If (CharactersForBlanksEdit.Text<>'') then
    B:=CharactersForBlanksEdit.Text[1];
  if (Length(S) = 0) then
    Result := ''
  else
    Result:=Format('%s'+MaskFieldSeparator+'%d'+MaskFieldSeparator+'%s',[S,ord(SaveLiteralCheckBox.checked),B]);
end;

procedure TMaskEditorForm.ReConstructEditmask;

begin
  InputMaskEdit.Text:=ConstructEditMask;
  UpdateTestEditor;
end;

procedure TMaskEditorForm.SampleMasksListBoxClick(Sender: TObject);
var
  AMaskCaption, AMaskExample, AEditMask: String;
begin
  if (SampleMasksListBox.Items.Count > 0) then
  begin
    TestMaskEdit.Text := '';
    ParseMaskLine(SampleMasksListBox.Items[SampleMasksListBox.ItemIndex],
      AMaskCaption, AMaskExample, AEditMask);
    EditMask := AEditMask;
  end;
end;

function TMaskEditorForm.GetEditMask: string;
begin
  Result:=ConstructEditMask;
end;

procedure TMaskEditorForm.LoadDEMFile(AFileName: string);
begin
  SampleMasksListBox.Items.Clear;
  SampleMasksListBox.Items.LoadFromFile(UTF8ToSys(AFileName));
end;

procedure TMaskEditorForm.SetEditMask(AValue: string);

Var
  M : String;
  B : Char;
  S : Boolean;

begin
  SplitEditMask(AValue,M,S,B);
  InputMaskEdit.Text := AValue;
  SaveLiteralCheckBox.Checked := S;
  CharactersForBlanksEdit.Text := B;
  UpdateTestEditor;
end;

procedure TMaskEditorForm.SetEnableSets(AValue: Boolean);
var
  OldMask: String;
  WasMasked: Boolean;
begin
  FEnableSets := AValue;
  WasMasked := TestMaskEdit.IsMasked;
  if WasMasked then
  begin
    OldMask := TestMaskEdit.EditMask;
    TestMaskEdit.EditMask := '';
  end;
  TestMaskEdit.EnableSets := FEnableSets;
  if WasMasked then
  begin
    TestMaskEdit.EditMask := OldMask;
  end;
  //since this is not only called from clicking on the checkbox
  EnableSetsCheckBox.Checked := FEnableSets;
end;

procedure TMaskEditorForm.UpdateTestEditor;
begin
  TestMaskEdit.EditMask:=InputMaskEdit.Text;
end;

{ TEditMaskProperty }

function TEditMaskProperty.GetAttributes: TPropertyAttributes;
begin
  Result:= [paDialog, paMultiSelect, paRevertable];
end;

procedure TEditMaskProperty.Edit;
var
  MaskEditorForm: TMaskEditorForm;
  C: TPersistent;
  AMaskEdit: TCustomMaskEdit;
begin
  MaskEditorForm:=TMaskEditorForm.Create(Application);
  try
    AMaskEdit := GetMaskEdit;
    MaskEditorForm.EnableSets := AMaskEdit.EnableSets;
    MaskEditorForm.EditMask:=GetValue;
    if MaskEditorForm.ShowModal = mrOk then
      SetValue(MaskEditorForm.EditMask);
  finally
    MaskEditorForm.Free;
  end;
end;


function TEditMaskProperty.GetMaskEdit: TCustomMaskEdit;
var
  i: Integer;
  C: TPersistent;
begin
  Result := nil;
  for i:=0 to PropCount-1 do
  begin
    C := GetComponent(i);
    if C is TCustomMaskEdit then
    begin
      Result := TCustomMaskEdit(C);
      Exit;
    end;
  end;
end;


{ TMaskEditEditor }

procedure TMaskEditEditor.ExecuteVerb(Index: Integer);
var
  MaskEditorForm: TMaskEditorForm;
begin
  if Index = 0 then
  begin
    MaskEditorForm := TMaskEditorForm.Create(Application);
    try
      MaskEditorForm.EnableSets := MaskEdit.EnableSets;
      MaskEditorForm.EditMask := MaskEdit.EditMask;
      if MaskEditorForm.ShowModal = mrOk then
        MaskEdit.EditMask := MaskEditorForm.EditMask;
    finally
      MaskEditorForm.Free;
    end;
  end;
end;

function TMaskEditEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := sccsMaskEditor;
    else
      Result := '';
  end;
end;

function TMaskEditEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TMaskEditEditor.MaskEdit: TCustomMaskEditAccess;
begin
  Result := TCustomMaskEditAccess(GetComponent)
end;

initialization
  RegisterPropertyEditor(TypeInfo(string), TCustomMaskEdit, 'EditMask',
                         TEditMaskProperty);
  RegisterComponentEditor(TMaskEdit, TMaskEditEditor);

end.

