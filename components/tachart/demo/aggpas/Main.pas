{ Demonstrates how a chart can be painted by means of the AggPas library,
  either directly or via the corresponding GUIConnector.
  
  Note that the AggPas version coming with Lazarus is unmaintained at the moment 
  and rather buggy. Font support works fine only on Windows. On Linux, you must 
  specify the directory with your fonts in the constant FONT_DIR defined below. 
  On macOS (cocoa), text output is not supported at all. }

unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, ExtCtrls, StdCtrls, SysUtils, FileUtil, Forms, Controls,
  Graphics, FPCanvas, Dialogs, 
  Agg_LCL, Agg_FPImage,
  TAGraph, TAGUIConnectorAggPas, TASeries, TASources, TADrawerAggPas, TADrawUtils;

type

  { TMainForm }

  TMainForm = class(TForm)
    Bevel1: TBevel;
    cbAggPas: TCheckBox;
    Chart: TChart;
    ChartConstantLine: TConstantLine;
    ChartLineSeries: TLineSeries;
    ChartPieSeries: TPieSeries;
    ChartGUIConnectorAggPas: TChartGUIConnectorAggPas;
    ChartPaintBox: TPaintBox;
    BottomPanel: TPanel;
    RandomChartSource: TRandomChartSource;
    procedure cbAggPasClick(Sender: TObject);
    procedure Chart1AfterPaint(ASender: TChart);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ChartPaintBoxPaint(Sender: TObject);
  private
    FAggCanvas: TAggLCLCanvas;
    FBmp: TBitmap;
  end;

var
  MainForm: TMainForm; 

implementation

{$R *.lfm}

uses
  TAChartUtils, TADrawerCanvas;

const
  FONT_DIR = '/usr/share/fonts/truetype/';

{ TMainForm }

procedure TMainForm.cbAggPasClick(Sender: TObject);
begin
  if cbAggPas.Checked then
    Chart.GUIConnector := ChartGUIConnectorAggPas
  else
    Chart.GUIConnector := nil;
end;

procedure TMainForm.Chart1AfterPaint(ASender: TChart);
begin
  Unused(ASender);
  ChartPaintBox.Invalidate;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FBmp := TBitmap.Create;
  FAggCanvas := TAggLCLCanvas.Create;
  FAggCanvas.Image.PixelFormat := afpimRGBA32;
  
  {$IFDEF LCLWin32}
  ChartLineSeries.Transparency := 128;
  {$ENDIF}
  {$IF DEFINED(LCLGtk2) or DEFINED(LCLGtk3) or DEFINED(LCLQt) or DEFINED(LCLQt5)}
  ChartGUIConnectorAggPas.FontDir := FONT_DIR;
  {$ENDIF}
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FAggCanvas.Free;
  FBmp.Free;
end;

procedure TMainForm.ChartPaintBoxPaint(Sender: TObject);
var
  d: IChartDrawer;
begin
  FAggCanvas.Width := ChartPaintBox.Width;
  FAggCanvas.Height := ChartPaintBox.Height;

  Chart.DisableRedrawing;
  Chart.Title.Text.Text := 'AggPas';
  d := TAggPasDrawer.Create(FAggCanvas);
  d.DoGetFontOrientation := @CanvasGetFontOrientationFunc;
  {$IF DEFINED(LCLGtk2) or DEFINED(LCLGtk3) or DEFINED(LCLQt) or DEFINED(LCLQt5)}
  (d as TAggPasDrawer).FontDir := FONT_DIR;
  {$ENDIF}
  Chart.Draw(d, ChartPaintBox.Canvas.ClipRect);
  Chart.Title.Text.Text := 'Standard';
  Chart.EnableRedrawing;

  // On Windows the order of red, green and blue is blue-green-red, while on 
  // others it is red-green-blue. In principle, AggPas can handle this, but
  // since it is not maintained ATM, I chose the "easy way" to swap the red
  // and blue bytes.
  {$IF DEFINED(LCLGtk2) or DEFINED(LCLGtk3) or DEFINED(LCLQt) or DEFINED(LCLQt5)}
  SwapRedBlue(FAggCanvas.Image.IntfImg);
  {$ENDIF}
  FBmp.LoadFromIntfImage(FAggCanvas.Image.IntfImg);
  ChartPaintBox.Canvas.Draw(0, 0, FBmp);
end;

end.

