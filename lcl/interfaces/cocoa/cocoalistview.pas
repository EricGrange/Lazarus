unit CocoaListView;

{$mode delphi}
{$modeswitch objectivec2}
{$include cocoadefines.inc}

interface

uses
  // RTL, FCL, LCL
  MacOSAll, CocoaAll,
  Classes, LCLType, SysUtils, LCLMessageGlue, LMessages,
  Controls, ComCtrls, Types, StdCtrls, LCLProc, Graphics, ImgList, Forms,
  // Cocoa WS
  CocoaPrivate, CocoaCallback, CocoaScrollers, CocoaWSScrollers,
  CocoaWSCommon, cocoa_extra, CocoaGDIObjects;

type
  { TLCLListViewCallback }

  TLCLListViewCallback = class(TLCLCommonCallback, IListViewCallback)
  public
    listView: TCustomListView;

    isSetTextFromWS: Integer; // allows to suppress the notifation about text change
                              // when initiated by Cocoa itself.
    selectionIndexSet: NSMutableIndexSet;
    checkedIdx : NSMutableIndexSet;
    ownerData  : Boolean;

    constructor Create(AOwner: NSObject; ATarget: TWinControl; AHandleView: NSView); override;
    destructor Destroy; override;
    function ItemsCount: Integer;
    function GetItemTextAt(ARow, ACol: Integer; var Text: String): Boolean;
    function GetItemCheckedAt(ARow, ACol: Integer; var IsChecked: Integer): Boolean;
    function GetItemImageAt(ARow, ACol: Integer; var imgIdx: Integer): Boolean;
    function GetImageFromIndex(imgIdx: Integer): NSImage;
    procedure SetItemTextAt(ARow, ACol: Integer; const Text: String);
    procedure SetItemCheckedAt(ARow, ACol: Integer; IsChecked: Integer);
    function getItemStableSelection(ARow: Integer): Boolean;
    procedure selectOne(ARow: Integer; isSelected:Boolean );
    function shouldSelectionChange(NewSel: Integer): Boolean;
    procedure ColumnClicked(ACol: Integer);
    procedure DrawRow(rowidx: Integer; ctx: TCocoaContext; const r: TRect;
      state: TOwnerDrawState);
    procedure GetRowHeight(rowidx: Integer; var h: Integer);
    function GetBorderStyle: TBorderStyle;
    function GetImageListType( out lvil: TListViewImageList ): Boolean;
    procedure callTargetInitializeWnd;
  end;
  TLCLListViewCallBackClass = class of TLCLListViewCallback;

  { TCocoaWSListViewHandler }

  TCocoaWSListViewHandler = class
  public
    // Column
    procedure ColumnDelete( const AIndex: Integer ); virtual; abstract;
    function  ColumnGetWidth( const AIndex: Integer; const {%H-}AColumn: TListColumn): Integer; virtual; abstract;
    procedure ColumnInsert( const AIndex: Integer; const AColumn: TListColumn); virtual; abstract;
    procedure ColumnMove( const AOldIndex, ANewIndex: Integer; const AColumn: TListColumn); virtual; abstract;
    procedure ColumnSetAlignment( const AIndex: Integer; const {%H-}AColumn: TListColumn; const AAlignment: TAlignment); virtual; abstract;
    procedure ColumnSetAutoSize( const AIndex: Integer; const {%H-}AColumn: TListColumn; const AAutoSize: Boolean); virtual; abstract;
    procedure ColumnSetCaption( const AIndex: Integer; const {%H-}AColumn: TListColumn; const ACaption: String); virtual; abstract;
    procedure ColumnSetMaxWidth( const AIndex: Integer; const {%H-}AColumn: TListColumn; const AMaxWidth: Integer); virtual; abstract;
    procedure ColumnSetMinWidth( const AIndex: Integer; const {%H-}AColumn: TListColumn; const AMinWidth: integer); virtual; abstract;
    procedure ColumnSetWidth( const AIndex: Integer; const {%H-}AColumn: TListColumn; const AWidth: Integer); virtual; abstract;
    procedure ColumnSetVisible( const AIndex: Integer; const {%H-}AColumn: TListColumn; const AVisible: Boolean); virtual; abstract;
    procedure ColumnSetSortIndicator( const AIndex: Integer; const AColumn: TListColumn; const ASortIndicator: TSortIndicator); virtual; abstract;

    // Item
    procedure ItemDelete( const AIndex: Integer); virtual; abstract;
    function  ItemDisplayRect( const AIndex, ASubItem: Integer; ACode: TDisplayCode): TRect; virtual; abstract;
    function  ItemGetChecked( const AIndex: Integer; const {%H-}AItem: TListItem): Boolean; virtual; abstract;
    function  ItemGetPosition( const AIndex: Integer): TPoint; virtual; abstract;
    function  ItemGetState( const AIndex: Integer; const {%H-}AItem: TListItem; const AState: TListItemState; out AIsSet: Boolean): Boolean; virtual; abstract; // returns True if supported
    procedure ItemInsert( const AIndex: Integer; const {%H-}AItem: TListItem); virtual; abstract;
    procedure ItemSetChecked( const AIndex: Integer; const {%H-}AItem: TListItem; const AChecked: Boolean); virtual; abstract;
    procedure ItemSetImage( const AIndex: Integer; const {%H-}AItem: TListItem; const {%H-}ASubIndex, {%H-}AImageIndex: Integer); virtual; abstract;
    procedure ItemSetState( const AIndex: Integer; const {%H-}AItem: TListItem; const AState: TListItemState; const AIsSet: Boolean); virtual; abstract;
    procedure ItemSetText( const AIndex: Integer; const {%H-}AItem: TListItem; const {%H-}ASubIndex: Integer; const {%H-}AText: String); virtual; abstract;
    procedure ItemShow( const AIndex: Integer; const {%H-}AItem: TListItem; const PartialOK: Boolean); virtual; abstract;

    function GetFocused: Integer; virtual; abstract;
    function GetItemAt( x,y: integer): Integer; virtual; abstract;
    function GetSelCount: Integer; virtual; abstract;
    function GetSelection: Integer; virtual; abstract;
    function GetTopItem: Integer; virtual; abstract;
    function GetVisibleRowCount: Integer; virtual; abstract;

    procedure SelectAll( const AIsSet: Boolean); virtual; abstract;
    procedure SetDefaultItemHeight( const AValue: Integer); virtual; abstract;
    procedure SetImageList( const {%H-}AList: TListViewImageList; const {%H-}AValue: TCustomImageListResolution); virtual; abstract;
    procedure SetItemsCount( const Avalue: Integer); virtual; abstract;
    procedure SetProperty( const AProp: TListViewProperty; const AIsSet: Boolean); virtual; abstract;
    procedure SetScrollBars( const AValue: TScrollStyle); virtual; abstract;
    procedure SetSort( const {%H-}AType: TSortType; const {%H-}AColumn: Integer;
      const {%H-}ASortDirection: TSortDirection); virtual; abstract;
  end;

  { TCocoaListViewBackendControl }
  TCocoaListViewBackendControlProtocol = objcprotocol
    procedure backend_setCallback( cb: TLCLListViewCallback ); message 'backend_setCallback:';
    procedure backend_reloadData; message 'backend_reloadData';
    procedure backend_onInit; message 'backend_onInit';
  end;

  CocoaListViewAllocFunc = procedure (const listView: NSView; const viewStyle: TViewStyle; out backendControl: NSView; out WSHandler: TCocoaWSListViewHandler );

  { TCocoaListView }

  TCocoaListView = objcclass(NSView)
  private
    _allocFunc: CocoaListViewAllocFunc;
    _viewStyle: TViewStyle;
    _scrollView: TCocoaScrollView;
    _backendControl: NSView; // NSTableView or NSCollectionView
    _WSHandler: TCocoaWSListViewHandler;
    _needsCallLclInit: Boolean;
    _initializing: Boolean;
  private
    procedure createControls; message 'createControls';
    procedure releaseControls; message 'releaseControls';
    procedure initData; message 'initData';
  public
    callback: TLCLListViewCallback;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    function lclContentView: NSView; override;
  public
    class function alloc: id; override;
    procedure dealloc; override;
  public
    procedure setAllocFunc( allocFunc: CocoaListViewAllocFunc ); message 'setAllocFunc:';
    procedure setViewStyle( viewStyle: TViewStyle ); message 'setViewStyle:';
    function documentView: NSView; message 'documentView';
    function scrollView: TCocoaScrollView; message 'scrollView';
    function WSHandler: TCocoaWSListViewHandler; message 'WSHandler';
    function initializing: Boolean; message 'isinitializing';
  end;

implementation

{ TCocoaListView }
type
  TCustomListViewAccess = class(TCustomListView);

function TCocoaListView.documentView: NSView;
begin
  Result:= _backendControl;
end;

function TCocoaListView.scrollView: TCocoaScrollView;
begin
  Result:= _scrollView;
end;

function TCocoaListView.WSHandler: TCocoaWSListViewHandler;
begin
  Result:= _WSHandler;
end;

function TCocoaListView.initializing: Boolean;
begin
  Result:= _initializing;
end;

procedure TCocoaListView.setViewStyle(viewStyle: TViewStyle);
begin
  if Assigned(_backendControl) and (_viewStyle=viewStyle) then
    Exit;

  _viewStyle:= viewStyle;
  releaseControls;
  createControls;
  initData;
end;

procedure TCocoaListView.createControls;
var
  controlFrame: NSRect;
  backendControlAccess: TCocoaListViewBackendControlProtocol;
begin
  Writeln( HexStr(@_allocFunc) );
  _allocFunc( self, _viewStyle, _backendControl, _WSHandler );

  controlFrame:= self.bounds;
  _backendControl.initWithFrame( controlFrame );
  _scrollView:= TCocoaScrollView.alloc.initWithFrame( controlFrame );
  _scrollView.setDocumentView( _backendControl );
  _scrollView.setAutoresizingMask( NSViewWidthSizable or NSViewHeightSizable );
  _scrollView.callback:= self.callback;
  self.addSubView( _scrollView );
  ScrollViewSetBorderStyle( _scrollView, callback.getBorderStyle );

  backendControlAccess:= TCocoaListViewBackendControlProtocol(_backendControl);
  backendControlAccess.backend_setCallback( self.callback );
  backendControlAccess.backend_onInit;
end;

type
  TWinControlAccess = class(TWinControl);

// LCL has built-in editing functionality in TListItem.EditCaption(),
// which creates a TextEditor to Edit Caption. at the Cocoa level,
// it will be loaded into TCocoaListView.TCocoaScrollView.backendControl.
// because TCocoaScrollView and backendControl will be rebuilt when
// switching the viewStyle, the Editor handle needs to be destroyed at Cocoa,
// so that the Editor can be recreated normally when needed after the switch.
procedure releaseCaptionEditor( container:NSView );
var
  view: NSView;
  control: TWinControlAccess;
begin
  for view in container.subviews do begin
    control:= TWinControlAccess( view.lclGetTarget );
    if Assigned(control) then begin
      control.Hide;
      control.DestroyHandle;
    end;
  end;
end;

procedure TCocoaListView.releaseControls;
begin
  if not Assigned(_backendControl) then
    Exit;
  FreeAndNil( _WSHandler );
  _scrollView.removeFromSuperview;
  _scrollView.setDocumentView( nil );
  _scrollView.release;
  _scrollView:= nil;
  releaseCaptionEditor( _backendControl );
  _backendControl.release;
  _backendControl:= nil;
end;

procedure TCocoaListView.initData;
var
  needsInit: Boolean = False;
begin
  needsInit:= _needsCallLclInit;
  _needsCallLclInit:= False;
  if needsInit then begin
    _initializing:= True;
    callback.callTargetInitializeWnd;
    _initializing:= False;
    TCocoaListViewBackendControlProtocol(_backendControl).backend_reloadData;
  end;
  _needsCallLclInit:= True;
end;

function TCocoaListView.lclGetCallback: ICommonCallback;
begin
  Result:= callback;
end;

procedure TCocoaListView.lclClearCallback;
begin
  callback:= nil;
end;

function TCocoaListView.lclContentView: NSView;
begin
  Result:= documentView;
end;

class function TCocoaListView.alloc: id;
begin
  Result:=inherited alloc;
end;

procedure TCocoaListView.dealloc;
begin
  self.releaseControls;
  inherited dealloc;
end;

procedure TCocoaListView.setAllocFunc( allocFunc: CocoaListViewAllocFunc );
begin
  _allocFunc:= allocFunc;
end;

{ TLCLListViewCallback }

constructor TLCLListViewCallback.Create(AOwner: NSObject; ATarget: TWinControl; AHandleView: NSView);
begin
  inherited Create(AOwner, ATarget, AHandleView);
  selectionIndexSet:= NSMutableIndexSet.new;
  checkedIdx:= NSMutableIndexSet.new;
end;

destructor TLCLListViewCallback.Destroy;
begin
  selectionIndexSet.release;
  selectionIndexSet:= nil;
  checkedIdx.release;
  checkedIdx:= nil;
  inherited Destroy;
end;

function TLCLListViewCallback.ItemsCount: Integer;
begin
  Result:= listView.Items.Count;
end;

function TLCLListViewCallback.GetItemTextAt(ARow, ACol: Integer;
  var Text: String): Boolean;
begin
  Result := (ACol>=0) and ( (ACol<listView.ColumnCount) or (ACol=0) )
    and (ARow >= 0) and (ARow < listView.Items.Count);

  if not Result then Exit;

  if ACol = 0 then
    Text := listView.Items[ARow].Caption
  else
  begin
    Text := '';
    dec(ACol);
    if (ACol >=0) and (ACol < listView.Items[ARow].SubItems.Count) then
      Text := listView.Items[ARow].SubItems[ACol];
  end;
end;

function TLCLListViewCallback.GetItemCheckedAt(ARow, ACol: Integer;
  var IsChecked: Integer): Boolean;
var
  BoolState : array [Boolean] of Integer = (NSOffState, NSOnState);
begin
  if ownerData and Assigned(listView) and (ARow>=0) and (ARow < listView.Items.Count) then
    IsChecked := BoolState[listView.Items[ARow].Checked]
  else
    IsChecked := BoolState[checkedIdx.containsIndex(ARow)];
  Result := true;
end;

function TLCLListViewCallback.GetItemImageAt(ARow, ACol: Integer;
  var imgIdx: Integer): Boolean;
begin
  Result := (ACol >= 0) and ( (ACol<listView.ColumnCount) or ( ACol=0) )
    and (ARow >= 0) and (ARow < listView.Items.Count);

  if not Result then Exit;

  if ACol = 0 then
    imgIdx := listView.Items[ARow].ImageIndex
  else
  begin
    dec(ACol);
    if (ACol >=0) and (ACol < listView.Items[ARow].SubItems.Count) then
      imgIdx := listView.Items[ARow].SubItemImages[ACol];
  end;
end;

function TLCLListViewCallback.GetImageFromIndex(imgIdx: Integer): NSImage;
var
  bmp : TBitmap;
  lvil: TListViewImageList;
  lst : TCustomImageList;
  x,y : integer;
  img : NSImage;
  rep : NSBitmapImageRep;
  cb  : TCocoaBitmap;
begin
  Result:= nil;
  if imgIdx < 0 then
    Exit;

  if NOT self.GetImageListType( lvil ) then
    Exit;

  if lvil = lvilLarge then
    lst:= TCustomListViewAccess(listView).LargeImages
  else
    lst:= TCustomListViewAccess(listView).SmallImages;

  bmp := TBitmap.Create;
  try
    lst.GetBitmap(imgIdx, bmp);
    if bmp.Handle = 0 then
      Exit;

    // Bitmap Handle should be nothing but TCocoaBitmap
    cb := TCocoaBitmap(bmp.Handle);

    // There's NSBitmapImageRep in TCocoaBitmap, but it depends on the availability
    // of memory buffer stored with TCocoaBitmap. As soon as TCocoaBitmap is freed
    // pixels are not available. For this reason, we're making a copy of the bitmapdata
    // allowing Cocoa to allocate its own buffer (by passing nil for planes parameter)
    rep := NSBitmapImageRep(NSBitmapImageRep.alloc).initWithBitmapDataPlanes_pixelsWide_pixelsHigh__colorSpaceName_bitmapFormat_bytesPerRow_bitsPerPixel(
      nil, // planes, BitmapDataPlanes
      Round(cb.ImageRep.size.Width), // width, pixelsWide
      Round(cb.ImageRep.size.Height),// height, PixelsHigh
      cb.ImageRep.bitsPerSample,// bitsPerSample, bps
      cb.ImageRep.samplesPerPixel, // samplesPerPixel, spp
      cb.ImageRep.hasAlpha, // hasAlpha
      False, // isPlanar
      cb.ImageRep.colorSpaceName, // colorSpaceName
      cb.ImageRep.bitmapFormat, // bitmapFormat
      cb.ImageRep.bytesPerRow, // bytesPerRow
      cb.ImageRep.BitsPerPixel //bitsPerPixel
    );
    System.Move( cb.ImageRep.bitmapData^, rep.bitmapData^, cb.ImageRep.bytesPerRow * Round(cb.ImageRep.size.height));
    img := NSImage(NSImage.alloc).initWithSize( rep.size );
    img.addRepresentation(rep);
    Result := img;
	rep.release;

  finally
    bmp.Free;
  end;
end;

procedure TLCLListViewCallback.SetItemTextAt(ARow, ACol: Integer;
  const Text: String);
begin
  // there's no notifcaiton to be sent to the TCustomListView;
  if (ACol<>0) then Exit;

  inc(isSetTextFromWS);
  try
    if (ACol=0) then
      if (ARow>=0) and (ARow<listView.Items.Count) then
        TCustomListViewAccess(listView).DoEndEdit(listView.Items[ARow], Text);
  finally
    dec(isSetTextFromWS);
  end;

end;

procedure TLCLListViewCallback.SetItemCheckedAt(ARow, ACol: Integer;
  IsChecked: Integer);
var
  Msg: TLMNotify;
  NMLV: TNMListView;
begin
  if IsChecked = NSOnState
    then checkedIdx.addIndex(ARow)
    else checkedIdx.removeIndex(ARow);

  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  FillChar(NMLV{%H-}, SizeOf(NMLV), #0);

  Msg.Msg := CN_NOTIFY;

  NMLV.hdr.hwndfrom := ListView.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGED;
  NMLV.iItem := ARow;
  NMLV.iSubItem := 0;
  NMLV.uChanged := LVIF_STATE;
  Msg.NMHdr := @NMLV.hdr;

  LCLMessageGlue.DeliverMessage(ListView, Msg);
end;

function TLCLListViewCallback.getItemStableSelection(ARow: Integer): Boolean;
begin
  Result:= selectionIndexSet.containsIndex( ARow );
end;

procedure TLCLListViewCallback.selectOne(ARow: Integer; isSelected: Boolean);
  procedure sendMsgToLCL;
  var
    Msg: TLMNotify;
    NMLV: TNMListView;
  begin
    Msg:= Default( TLMNotify );
    NMLV:= Default( TNMListView );

    Msg.Msg := CN_NOTIFY;

    NMLV.hdr.hwndfrom := ListView.Handle;
    NMLV.hdr.code := LVN_ITEMCHANGED;
    NMLV.iSubItem := 0;
    NMLV.uChanged := LVIF_STATE;
    Msg.NMHdr := @NMLV.hdr;

    if isSelected then begin
      NMLV.uNewState := LVIS_SELECTED;
      NMLV.uOldState := 0;
    end else begin
      NMLV.uNewState := 0;
      NMLV.uOldState := LVIS_SELECTED;
    end;

    NMLV.iItem := ARow;
    LCLMessageGlue.DeliverMessage(ListView, Msg);
  end;
begin
  if isSelected then
    self.selectionIndexSet.addIndex( ARow )
  else
    self.selectionIndexSet.removeIndex( ARow );

  sendMsgToLCL;
end;

function TLCLListViewCallback.shouldSelectionChange(NewSel: Integer
  ): Boolean;
var
  item: TListItem = nil;
begin
  if (NewSel>=0) and (NewSel<self.listView.Items.Count) then
    item:= self.listView.Items[NewSel];
  Result:= TCustomListViewAccess(self.listView).CanChange( item, LVIF_TEXT );
end;

procedure TLCLListViewCallback.ColumnClicked(ACol: Integer);
var
  Msg: TLMNotify;
  NMLV: TNMListView;
begin
  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  FillChar(NMLV{%H-}, SizeOf(NMLV), #0);

  Msg.Msg := CN_NOTIFY;

  NMLV.hdr.hwndfrom := ListView.Handle;
  NMLV.hdr.code := LVN_COLUMNCLICK;
  NMLV.iSubItem := ACol;
  NMLV.uChanged := 0;
  Msg.NMHdr := @NMLV.hdr;

  LCLMessageGlue.DeliverMessage(ListView, Msg);
end;

procedure TLCLListViewCallback.DrawRow(rowidx: Integer; ctx: TCocoaContext;
  const r: TRect; state: TOwnerDrawState);
var
  ALV: TCustomListViewAccess;
begin
  ALV:= TCustomListViewAccess(self.listView);
  ALV.Canvas.Handle:= HDC(ctx);
  ALV.IntfCustomDraw( dtItem, cdPrePaint, rowidx, 0, [], nil );
  ALV.Canvas.Handle:= 0;
end;

procedure TLCLListViewCallback.GetRowHeight(rowidx: Integer; var h: Integer);
begin

end;

function TLCLListViewCallback.GetBorderStyle: TBorderStyle;
begin
  Result:= TCustomListView(Target).BorderStyle;
end;

function TLCLListViewCallback.GetImageListType( out lvil: TListViewImageList ): Boolean;
const
  preferredImages: array [TViewStyle] of TListViewImageList = (
    lvilLarge, lvilSmall, lvilSmall, lvilSmall );
  alternativeImages: array [TViewStyle] of TListViewImageList = (
    lvilSmall, lvilLarge, lvilLarge, lvilLarge );
var
  viewStyle: TViewStyle;
  LVA: TCustomListViewAccess;
begin
  Result:= True;
  LVA:= TCustomListViewAccess(listView);
  viewStyle:= LVA.ViewStyle;

  lvil:= preferredImages[viewStyle];
  if (lvil=lvilLarge) and Assigned(LVA.LargeImages) then
    Exit;
  if (lvil=lvilSmall) and Assigned(LVA.SmallImages) then
    Exit;

  lvil:= alternativeImages[viewStyle];
  if (lvil=lvilLarge) and Assigned(LVA.LargeImages) then
    Exit;
  if (lvil=lvilSmall) and Assigned(LVA.SmallImages) then
    Exit;

  Result:= False;
end;

procedure TLCLListViewCallback.callTargetInitializeWnd;
begin
  TCustomListViewAccess(Target).InitializeWnd;
end;

end.

