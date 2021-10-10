unit uNsGraphVCL;

interface

uses
  SysUtils, Classes, Types, VCL.Graphics, DB, System.UITypes, VCL.Dialogs, Vcl.ExtCtrls;

const
  I_MIN_CELL_SIZE = 5;
  C_COLOR_REGULAR = clGray;
  C_COLOR_BOLD = clGray;
  I_THICKNESS_REGULAR = 1;
  I_THICKNESS_BOLD = 1;
  I_CANVAS_FONT_SIZE = 8;

type
  TNsGraph = class(TImage)
  private
    FDX: Integer;
    FDY: Integer;
    FMinY: Integer;
    FMaxY: Integer;
    FXAxisPos: Integer;
    FYAxisPos: Integer;
    FLinesWidth: Integer;
    FDataSet: TDataSet;
    FBeginDate: TDateTime;
    FEndDate: TDateTime;
    FDateField: string;
    FKeyField: string;
    FValueField: string;
    FNameField: string;
    FColorField: string;
    FDataSource: TDataSource;
    FDataLink: TDataLink;
    //
    procedure DrawLine(var aCanvas: TCanvas; aPoint1, aPoint2: TPoint; aColor: TAlphaColor; aThickness: Integer = 1);
    procedure FillText(var aCanvas: TCanvas; aRect: TRect; aText: string; aColor: TAlphaColor);
    procedure ClearCanvas;
    procedure DrawHorizontalGridLines(aDiapasoneY: Integer; aXAxisUsefulLen: Integer);
    procedure DrawVerticalGridLines(aDiapasoneX: Integer; aYAxisUsefulLen: Integer);
    procedure DrawAxis(aXAxisLen, aYAxisLen: Integer);
    procedure SetDataSet(const aDataSet: TDataSet);
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure DrawGrid;
    procedure DrawGraph(aFieldFieldName: string);
  published
    property LinesWidth: Integer read FLinesWidth write FLinesWidth;
    property MinY: Integer read FMinY write FMinY;
    property MaxY: Integer read FMaxY write FMaxY;
    property DataSet: TDataSet read FDataSet write SetDataSet;
    property BeginDate: TDateTime read FBeginDate write FBeginDate;
    property EndDate: TDateTime read FEndDate write FEndDate;
    property DateField: string read FDateField write FDateField;
    property KeyField: string read FKeyField write FKeyField;
    property ValueField: string read FValueField write FValueField;
    property NameField: string read FNameField write FNameField;
    property ColorField: string read FColorField write FColorField;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('NeferSky', [TNsGraph]);
end;

{ TNsGraph }

constructor TNsGraph.Create(aOwner: TComponent);
begin
  inherited;

  FDataSource := TDataSource.Create(Self);
  FDataLink := TDataLink.Create;

  FDX := 10;
  FDY := 10;
  FMinY := 10;
  FMaxY := 100;
  FXAxisPos := 10;
  FYAxisPos := 10;
  FLinesWidth := 1;
  FDataSet := nil;
  FBeginDate := 0;
  FEndDate := 0;
  FKeyField := '';
  FValueField := '';
  FNameField := '';
  FColorField := '';

  Picture.Bitmap.Height := Height;
  Picture.Bitmap.Width := Width;

  ClearCanvas;
end;

destructor TNsGraph.Destroy;
begin
  if Assigned(FDataSource) then
    FDataSource.Free;

  if Assigned(FDataLink) then
    FDataLink.Free;
end;

procedure TNsGraph.DrawLine(var aCanvas: TCanvas; aPoint1, aPoint2: TPoint; aColor: TAlphaColor; aThickness: Integer);
begin
  aCanvas.Pen.Color := aColor;
  aCanvas.Pen.Width := aThickness;
  aCanvas.MoveTo(aPoint1.X, aPoint1.Y);
  aCanvas.LineTo(aPoint2.X, aPoint2.Y);
end;

procedure TNsGraph.FillText(var aCanvas: TCanvas; aRect: TRect; aText: string; aColor: TAlphaColor);
begin
  aCanvas.Font.Color := aColor;
  aCanvas.TextOut(aRect.Left, aRect.Top, aText);
end;

procedure TNsGraph.ClearCanvas;
var
  bmpCanvas: TCanvas;
begin
  bmpCanvas := Picture.Bitmap.Canvas;

  bmpCanvas.Lock;
  try
    bmpCanvas.Brush.Color := 0;
    bmpCanvas.FillRect(Self.BoundsRect);
  finally
    bmpCanvas.Unlock;
  end;
end;

procedure TNsGraph.DrawGrid;
var
  XAxisLen,
  YAxisLen,
  XAxisUsefulLen,
  YAxisUsefulLen: Integer;
  DiapasoneX,
  DiapasoneY: Integer;
begin
  FXAxisPos := Height - 23; // Offset of XAxis from the bottom edge of canvas
  FYAxisPos := 23; // Offset of YAxis from the left edge of canvas

  XAxisLen := Width - FYAxisPos - 20; // Full length of XAxis
  YAxisLen := FXAxisPos - 20; // Full length of YAxis
  XAxisUsefulLen := XAxisLen - 20; // Useful length of XAxis for marks
  YAxisUsefulLen := YAxisLen - 20; // Useful length of YAxis for marks
  DiapasoneX := Round((FEndDate - FBeginDate) + 1); // Marks count on XAxis
  DiapasoneY := FMaxY - FMinY; // Marks count on YAxis

  // Dimensions of grid cell
  FDX := XAxisUsefulLen div DiapasoneX;
  FDY := YAxisUsefulLen div DiapasoneY;

  // If cells is very small - decrease its count
  if (FDX < I_MIN_CELL_SIZE) then
  begin
    FDX := I_MIN_CELL_SIZE;
    DiapasoneX := Round(XAxisUsefulLen / FDX);
  end;

  if (FDY < I_MIN_CELL_SIZE) then
  begin
    FDY := I_MIN_CELL_SIZE;
    DiapasoneY := Round(YAxisUsefulLen / FDY);
  end;

  // Prepare bitmap
  Picture.Bitmap.Height := Height;
  Picture.Bitmap.Width := Width;
  ClearCanvas;

  DrawHorizontalGridLines(DiapasoneY, XAxisUsefulLen);
  DrawVerticalGridLines(DiapasoneX, YAxisUsefulLen);
  DrawAxis(XAxisLen, YAxisLen);
end;

procedure TNsGraph.DrawHorizontalGridLines(aDiapasoneY: Integer; aXAxisUsefulLen: Integer);
var
  bmpCanvas: TCanvas;
  I: Integer;
  Point1,
  Point2: TPoint;
  Rect: TRect;
  Color: TAlphaColor;
  Thickness: Integer;
begin
  bmpCanvas := Picture.Bitmap.Canvas;
  bmpCanvas.Font.Size := I_CANVAS_FONT_SIZE;

  bmpCanvas.Lock;
  try
    for I := 1 to aDiapasoneY do
    begin
      Rect := TRect.Create(0, FXAxisPos - (bmpCanvas.Font.Size div 2) - I * FDY, FYAxisPos, FXAxisPos + (bmpCanvas.Font.Size div 2) - I * FDY);
      FillText(bmpCanvas, Rect, IntToStr(I + FMinY), clWhite);

      // Every 5'th line - dark
      if ((I + MinY) mod 5 = 0) then
      begin
        Color := C_COLOR_BOLD;
        Thickness := I_THICKNESS_BOLD;
      end
      else
      begin
        Color := C_COLOR_REGULAR;
        Thickness := I_THICKNESS_REGULAR;
      end;

      Point1 := TPoint.Create(FYAxisPos, FXAxisPos - I * FDY);
      Point2 := TPoint.Create(FYAxisPos + aXAxisUsefulLen, FXAxisPos - I * FDY);
      DrawLine(bmpCanvas, Point1, Point2, Color, Thickness);
    end;

  finally
    bmpCanvas.Unlock;
  end;
end;

procedure TNsGraph.DrawVerticalGridLines(aDiapasoneX: Integer; aYAxisUsefulLen: Integer);
var
  bmpCanvas: TCanvas;
  I: Integer;
  CounterDate: TDateTime;
  cd,
  cm,
  cy: Word;
  Point1,
  Point2: TPoint;
  Rect: TRect;
  Color: TAlphaColor;
  Thickness: Integer;
begin
  // Zero on X-axis
  CounterDate := FBeginDate;
  bmpCanvas := Picture.Bitmap.Canvas;
  bmpCanvas.Font.Size := I_CANVAS_FONT_SIZE;

  bmpCanvas.Lock;
  try
    for I := 1 to aDiapasoneX do
    begin
      DecodeDate(CounterDate, cy, cm, cd);
      Rect := TRect.Create(FYAxisPos - bmpCanvas.Font.Size + I * FDX, FXAxisPos, FYAxisPos + bmpCanvas.Font.Size + I * FDX, Height);
      FillText(bmpCanvas, Rect, IntToStr(cd), clWhite);

      CounterDate := CounterDate + 1;

      // Every 5'th line - dark
      if (I mod 5 = 0) then
      begin
        Color := C_COLOR_BOLD;
        Thickness := I_THICKNESS_BOLD;
      end
      else
      begin
        Color := C_COLOR_REGULAR;
        Thickness := I_THICKNESS_REGULAR;
      end;

      Point1 := TPoint.Create(FYAxisPos + I * FDX, FXAxisPos);
      Point2 := TPoint.Create(FYAxisPos + I * FDX, FXAxisPos - aYAxisUsefulLen);
      DrawLine(bmpCanvas, Point1, Point2, Color, Thickness);
    end;

  finally
    bmpCanvas.Unlock;
  end;
end;

procedure TNsGraph.DrawAxis(aXAxisLen, aYAxisLen: Integer);
const
  C_COLOR_AXIS = clWhite;
var
  bmpCanvas: TCanvas;
  Point1, Point2: TPoint;
begin
  bmpCanvas := Picture.Bitmap.Canvas;

  bmpCanvas.Lock;
  try
    // X-axis
    Point1 := TPoint.Create(FYAxisPos, FXAxisPos);
    Point2 := TPoint.Create(FYAxisPos + aXAxisLen, FXAxisPos);
    DrawLine(bmpCanvas, Point1, Point2, C_COLOR_AXIS);

    Point1 := TPoint.Create(FYAxisPos + aXAxisLen, FXAxisPos);
    Point2 := TPoint.Create(FYAxisPos + aXAxisLen - 13, FXAxisPos - 2);
    DrawLine(bmpCanvas, Point1, Point2, C_COLOR_AXIS);

    Point1 := TPoint.Create(FYAxisPos + aXAxisLen, FXAxisPos);
    Point2 := TPoint.Create(FYAxisPos + aXAxisLen - 13, FXAxisPos + 2);
    DrawLine(bmpCanvas, Point1, Point2, C_COLOR_AXIS);

    // Y-axis
    Point1 := TPoint.Create(FYAxisPos, FXAxisPos);
    Point2 := TPoint.Create(FYAxisPos, FXAxisPos - aYAxisLen);
    DrawLine(bmpCanvas, Point1, Point2, C_COLOR_AXIS);

    Point1 := TPoint.Create(FYAxisPos, FXAxisPos - aYAxisLen);
    Point2 := TPoint.Create(FYAxisPos + 2, FXAxisPos - aYAxisLen + 13);
    DrawLine(bmpCanvas, Point1, Point2, C_COLOR_AXIS);

    Point1 := TPoint.Create(FYAxisPos, FXAxisPos - aYAxisLen);
    Point2 := TPoint.Create(FYAxisPos - 2, FXAxisPos - aYAxisLen + 13);
    DrawLine(bmpCanvas, Point1, Point2, C_COLOR_AXIS);

  finally
    bmpCanvas.Unlock;
  end;
end;

procedure TNsGraph.DrawGraph(aFieldFieldName: string);
var
  CounterDate,
  RecordDate: TDateTime;
  cd, cm, cy,
  rd, rm, ry: Word;
  X, X1, Y: Integer;
  Value, Value1: Integer;
  ValName: string;
  bmpCanvas: TCanvas;
  Rect: TRect;
  Point1, Point2: TPoint;
begin
  DataSet.Filtered := False;
  DataSet.Filter := FKeyField + '=''' + aFieldFieldName + '''';
  DataSet.Filtered := True;

  if (DataSet.RecordCount <= 0) then Exit;

  bmpCanvas := Picture.Bitmap.Canvas;
  bmpCanvas.Font.Size := 10;

  // Inverse - it's okay
  X := FYAxisPos;
  Y := FXAxisPos;

  // Get first value and set pen position to start point
  DataSet.First;
  ValName := DataSet.FieldByName(FNameField).AsString;
  Value := Round(Y - (DataSet.FieldByName(FValueField).AsFloat - FMinY) * FDY);
  Rect := TRect.Create(X, Value - 8 - bmpCanvas.Font.Size, X + 300, Value);

  bmpCanvas.Font.Color := DataSet.FieldByName(FColorField).AsLongWord and $FFFFFF;
  bmpCanvas.Lock;
  try
    bmpCanvas.TextRect(Rect, ValName, [TTextFormats.tfLeft, TTextFormats.tfVerticalCenter, TTextFormats.tfSingleLine]);
  finally
    bmpCanvas.Unlock;
  end;

  X1 := X;
  Value1 := Value;
  Point1 := TPoint.Create(X1, Value1);
  CounterDate := FBeginDate;

  // Loop by selected days interval
  bmpCanvas.Lock;
  try
    while CounterDate <= FEndDate do
    begin
      // Step X coordinate
      X := X + FDX;

      // Check DatasetRecordDate = LoopCounterDate
      RecordDate := DataSet.FieldByName(FDateField).AsDateTime;
      DecodeDate(RecordDate, ry, rm, rd);
      DecodeDate(CounterDate, cy, cm, cd);
      CounterDate := CounterDate + 1; // here!!!
      //if (cd <> rd) then continue; // It means we haven't this day in dataset

      // Get value and draw graph line
      Value := Round(Y - (DataSet.FieldByName(FValueField).AsFloat - FMinY) * FDY);
      Point2 := TPoint.Create(X, Value);
      DrawLine(bmpCanvas, Point1, Point2, DataSet.FieldByName(FColorField).AsLongWord and $FFFFFF, FLinesWidth);
      Point1 := Point2;

      // Next record
      DataSet.Next;
    end;

  finally
    bmpCanvas.Unlock;
  end;
end;

procedure TNsGraph.SetDataSet(const aDataSet: TDataSet);
begin
  if aDataSet = FDatalink.DataSet then
    Exit;

  FDataSet := aDataSet;
  FDataSource.DataSet := aDataSet;

  if Assigned(aDataSet) then
    FDataLink.DataSource := FDataSource

  else
  begin
    FDataLink.DataSource := nil;

    FDateField := '';
    FKeyField := '';
    FValueField := '';
    FNameField := '';
    FColorField := '';
  end;
end;

end.
