unit locr_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, FileUtil, UTF8Process, Forms, Controls, Graphics,
  Dialogs, ComCtrls, StdCtrls, Menus, ExtCtrls, ExtDlgs, FPimage,LazFileUtils,
   RichMemo,RichMemoRTF, LConvEncoding,
  LCLType, DefaultTranslator, Buttons,
  locr_utils,locr_consts;

type

  { TMyRichMemo }

  TMyRichMemo=class(TRichMemo)
  public
    FChanged:boolean;
    FOrigRTF:string;
    constructor Create(AOwner: TComponent); override;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    cbLang: TComboBox;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    MainMenu: TMainMenu;
    mAddSane: TMenuItem;
    mAddFromFile: TMenuItem;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    mCutOf: TMenuItem;
    mExit: TMenuItem;
    mSaveText: TMenuItem;
    mRecognize: TMenuItem;
    mRotateCW: TMenuItem;
    mRotateCCW: TMenuItem;
    mPage: TMenuItem;
    mFile: TMenuItem;
    OpenPictureDialog: TOpenPictureDialog;
    rbnTesseract: TRadioButton;
    rbnCuneiform: TRadioButton;
    RadioGroup1: TRadioGroup;
    dSaveAll: TSaveDialog;
    sbSaveTxt: TSpeedButton;
    sbAddFromFile: TSpeedButton;
    sbSANE: TSpeedButton;
    sbRotateCW: TSpeedButton;
    sbRotateCCW: TSpeedButton;
    sbRecognize: TSpeedButton;
    Tabs: TPageControl;
    Process: TProcessUTF8;
    ShSettings: TTabSheet;
    ToolBar1: TToolBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure mAddFromFileClick(Sender: TObject);
    procedure mAddSaneClick(Sender: TObject);
    procedure mCutOfClick(Sender: TObject);
    procedure mExitClick(Sender: TObject);
    procedure mRecognizeClick(Sender: TObject);
    procedure mRotateCCWClick(Sender: TObject);
    procedure mSaveTextClick(Sender: TObject);
  private
    { private declarations }
  public
    Imgs:TList;
    RecogElems:TList;
    Bevels:TList;
    X1,X2,Y1,Y2:integer;
    procedure MChange(Sender:TObject);
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TMyRichMemo }

constructor TMyRichMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChanged:=false;
end;

{ TForm1 }

procedure TForm1.mAddSaneClick(Sender: TObject);
var
  FName: String;
  CPage: TTabSheet;
  Img: TImage;
  Btn: TButton;
begin
  FName:=GetTempFileByExt('img','pgm');
  Process.Executable:='xsane';
  Process.Parameters.Clear;
  Process.Parameters.Add('--save');
  Process.Parameters.Add('--no-mode-selection');
  Process.Parameters.Add('--force-filename');
  Process.Parameters.Add(FName);
  Process.Execute;
  Process.WaitOnExit;
  if not FileExists(FName) then begin ShowMessage('Error in SANE!');exit;end;
  CPage:=Tabs.AddTabSheet;
  CPage.Caption:='Page';
  Btn:=TButton.Create(self);
  btn.Caption:='Osel';
  Btn.Parent:=CPage;
  Btn.Show;
  Img:=TImage.Create(self);
  Img.Parent:=CPage;
  Imgs.Add(Img);
  Img.Left:=0;Img.Top:=0;
  Img.Height:=CPage.Height-20;
  Img.Width:=(CPage.Width div 2)-10;
  Img.Picture.LoadFromFile(FName);
  Img.Stretch:=true;
  Img.OnMouseDown:=@Image1MouseDown;
  Img.OnMouseUp:=@Image1MouseUp;
  Img.Show;
  DeleteFile(FName);
  Btn.Hide;
  Btn.Free;
end;

procedure TForm1.mCutOfClick(Sender: TObject);
var
  N: Integer;
  Bv: TBevel;
  Img: TImage;
  XFactor, YFactor: Double;
  PNGName,PNGName1, Cmd: String;
  CPage: TTabSheet;
begin
  N:=Tabs.ActivePageIndex-1;
  if (Bevels.Count<=N)or(Bevels[N]=nil)or not (TObject(Bevels[N]) is TBevel)then
  begin
    ShowMessage(rsNothingSelec);
    exit;
  end;
  Bv:=TBevel(Bevels[N]);
  if (Imgs.Count<=N)or(Imgs[N]=nil)or not (TObject(Imgs[N]) is TImage)then
  begin
    ShowMessage(rsNoWorkingIma);
    exit;
  end;
  Img:=TImage(Imgs[N]);
  XFactor:=Img.Picture.Width/Img.Width;
  YFactor:=Img.Picture.Height/Img.Height;
  X1:=round((Bv.Left-Img.Left)*XFactor);
  X2:=X1+round((Bv.Width)*XFactor);
  Y1:=round((Bv.Top-Img.Top)*YFactor);
  Y2:=Y1+round(Bv.Height*YFactor);
  try
    PNGName:=GetTempFileByExt('img','png');
    Img.Picture.SaveToFile(PNGName);
    PNGName1:=GetTempFileByExt('img','png');
    Cmd:='-c "convert '+PNGName+' -crop '+IntToStr(X2-X1)+'x'+IntToStr(Y2-Y1)+'+'+IntToStr(X1)+'+'+IntToStr(Y1)+' '+PNGName1+'"';
    ExecuteProcess('/bin/sh',Cmd);
    Img.Picture.LoadFromFile(PNGName1);
    Bv.Hide;
    Bv.Parent:=nil;
    Bv.Free;
    Bevels[N]:=nil;
    X1:=0;X2:=0;Y1:=0;Y2:=0;
  finally
    if FileExistsUTF8(PNGName) then DeleteFileUTF8(PNGName);
    if FileExistsUTF8(PNGName1) then DeleteFileUTF8(PNGName1);
  end;

end;

procedure TForm1.mExitClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.mRecognizeClick(Sender: TObject);
var
  O: TObject;
  Img: TImage;
  ImgName, RtfName, S: String;
  FS:TFileStream;
  RM: TMyRichMemo;

  Pg: TTabSheet;
  k, i: Integer;
  MS: TMemoryStream;
  SL: TStringList;
begin
  O:=TObject(Imgs[Tabs.PageIndex-1]);
  if not (O is TImage) then
  begin
    ShowMessage(rsErrorGetting);
    exit;
  end;
  Img:=TImage(O);
  ImgName:=GetTempFileByExt('img','png');
  if rbnCuneiform.Checked then RtfName:=GetTempFileByExt('txt','rtf')
  else
  begin
    RtfName:=GetTempFileByExt('txt','txt');
    if RtfName[1]<>'"' then k:=4 else k:=5;
    S:=copy(RtfName,1,Length(RtfName)-k);
    if k=5 then S:=s+'"';
  end;
  try
    Img.Picture.SaveToFile(ImgName);
    if rbnCuneiform.Checked then
      ExecuteProcess(('/usr/bin/cuneiform'),('-f rtf -l '+cbLang.Text+' -o "'+RtfName+
        '" '+ImgName))
    else
      ExecuteProcess(('/usr/bin/tesseract'),(ImgName+' '
      +S+' -l '+cbLang.Text));

    if not FileExistsUTF8(RtfName) then ShowMessage(rsErrorRecogni) else
    begin

      Pg:=Tabs.Pages[Tabs.PageIndex];
      if rbnCuneiform.Checked then
      begin
        {HV:=THtmlViewer.Create(Self);
        HV.Parent:=Pg;
        HV.Left:=Img.Left+Img.Width+10;
        HV.Width:=Pg.Width-HV.Left-3;
        HV.Top:=1;
        HV.Height:=Pg.Height-10;
        HV.LoadFromFile(RtfName);}
        RM:=TMyRichMemo.Create(Self);
        RM.Parent:=Pg;
        RM.Left:=Img.Left+Img.Width+10;
        RM.Width:=Pg.Width-RM.Left-3;
        RM.Top:=1;
        RM.Height:=Pg.Height-10;
        SL:=TStringList.Create;
        SL.LoadFromFile(RtfName);
        SL.Text:=CorrectRtf(SL.Text);
        RM.FOrigRTF:=SL.Text;
        SL.SaveToFile(RtfName);
        SL.Free;
        FS:=TFileStream.Create(RtfName,fmOpenRead);
        RM.LoadRichText(FS);
        FS.Free;
        RM.OnChange:=@MChange;
        RM.Show;
      end else
      begin
        RM:=TMyRichMemo.Create(Self);
        RM.Parent:=Pg;
        RM.Left:=Img.Left+Img.Width+10;
        RM.Width:=Pg.Width-RM.Left-3;
        RM.Top:=1;
        RM.Height:=Pg.Height-10;
        RM.Lines.LoadFromFile(RtfName);
        RM.FOrigRTF:=RM.Lines.Text;
        RM.OnChange:=@MChange;
        RM.Show;
      end;
      i:=Tabs.PageIndex-1;
      while RecogElems.Count<i+1 do RecogElems.Add(nil);
      RecogElems[i]:=RM;
    end;

  finally
    if FileExistsUTF8(ImgName) then DeleteFileUTF8(ImgName);
    if FileExistsUTF8(RtfName) then DeleteFileUTF8(RtfName);
  end;
end;

procedure TForm1.mRotateCCWClick(Sender: TObject);
var
  O: TObject;
  Img: TImage;
  FileName, FileName1, Angle: String;
begin
  O:=TObject(Imgs[Tabs.PageIndex-1]);
  if not (O is TImage) then
  begin
    ShowMessage(rsErrorGetting);
    exit;
  end;
  Img:=TImage(O);
  if (Sender=mRotateCCW)or(Sender=sbRotateCCW) then Angle:='-90' else
      if (Sender=mRotateCW)or(Sender=sbRotateCW) then Angle:='90';
  try
    FileName:=GetTempFileByExt('img','png');
    Img.Picture.SaveToFile(FileName);

    FileName1:=GetTempFileByExt('img','png');
    Writeln(('/bin/sh'),('-c "convert -rotate '+Angle+' '+FileName+' '+FileName1)+'"');
    ExecuteProcess(('/bin/sh'),('-c "convert -rotate '+Angle+' '+FileName+' '+FileName1)+'"');
    if FileExistsUTF8(FileName1) then begin
      Img.Picture.LoadFromFile(FileName1);
    end;
  finally
    if FileExistsUTF8(FileName) then DeleteFileUTF8(FileName);
    if FileExistsUTF8(FileName1) then DeleteFileUTF8(FileName1);
  end;

end;

procedure TForm1.mSaveTextClick(Sender: TObject);
var
  i, N, j: Integer;
  RM: TMyRichMemo;
  FS: TFileStream;
  S, All: String;
  SL: TStringList;
begin
  if not dSaveAll.Execute then exit;
  N:=RecogElems.Count-1;
  All:='';
  for i:=0 to N do
    if (RecogElems[i]<>nil)and(TObject(RecogElems[i]) is TMyRichMemo) then
    begin
      RM:=TMyRichMemo(RecogElems[i]);
      if RM.FChanged then S:=RM.Rtf else S:=RM.FOrigRTF;
      if i>0 then
      begin
        j:=1;
        while (j<=length(S))and(S[j]<>'{') do inc(j);
        S:=copy(S,j+1,Length(S)-j);
      end;
      if i<N then
      begin
        j:=Length(S);
        while (j>0)and(S[j]<>'}') do dec(j);
        S:=copy(s,1,j-1);
      end;
      All:=All+S;
    end;
  SL:=TStringList.Create;
  SL.Text:=All;
  SL.SaveToFile(dSaveAll.FileName);
end;

procedure TForm1.MChange(Sender: TObject);
begin
  if Sender is TMyRichMemo then TMyRichMemo(Sender).FChanged:=true;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Imgs:=TList.Create;
  RecogElems:=TList.Create;
  Bevels:=TList.Create;
end;


procedure TForm1.FormDestroy(Sender: TObject);
var
  O: TObject;
  i: Integer;
begin
{  for i:=0 to Imgs.Count-1 do
  begin
    try
      O:=TObject(Imgs[i]);
      if not assigned(O) then continue;
      if O is TControl then TControl(O).Parent:=nil;
      if (O is TObject) then O.Free;
    except
      O:=nil;
    end;
  end;}
  Imgs.Free;
{  for i:=0 to Imgs.Count-1 do
    begin
      try
        O:=TObject(RecogElems[i]);
        if not assigned(O) then continue;
        if O is TControl then TControl(O).Parent:=nil;
        if O is TObject then O.Free;
      except
        o:=nil;
      end;
    end;          }
  RecogElems.Free;
  Bevels.Free;
end;

procedure TForm1.FormResize(Sender: TObject);
var
  i: Integer;
  Img: TImage;
  CPage: TTabSheet;
  RM: TControl;
begin
  for i:=1 to Tabs.PageCount-1 do
  begin
    CPage:=Tabs.Pages[i];
    if (Imgs.Count>=i) and assigned(Imgs[i-1]) and (TObject(Imgs[i-1])is TImage) then
      Img:=TImage(Imgs[i-1]) else continue;
    Img.Left:=0;Img.Top:=0;
    Img.Height:=CPage.Height-20;
    Img.Width:=(CPage.Width div 2)-10;
    if (RecogElems.Count>=i)and assigned(RecogElems[i-1]) and (TObject(RecogElems[i-1])is TControl) then
      RM:=TControl(RecogElems[i-1]) else continue;
      RM.Left:=Img.Left+Img.Width+10;
      RM.Width:=CPage.Width-RM.Left-3;
      RM.Top:=1;
      RM.Height:=CPage.Height-10;
  end;

end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  X1:=X;Y1:=Y;
end;

procedure TForm1.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Bv: TBevel;
  Im: TImage;
  N: Integer;
  O:TObject;
begin
  X2:=X;Y2:=Y;
  if X2<X1 then Exchange(X1,X2);
  if Y2<Y1 then Exchange(Y1,Y2);
  Im:=Sender as TImage;
  N:=Imgs.IndexOf(Im);
  if N<0 then exit;
  Bv:=TBevel.Create(self);
  Bv.Parent:=Tabs.ActivePage;
  Bv.Shape:=bsFrame;
  if not (Sender is TImage) then exit;

  Bv.Left:=X1+Im.Left;
  Bv.Top:=Y1+Im.Top;
  Bv.Width:=X2-X1+1;
  Bv.Height:=Y2-Y1+1;
  Bv.Show;
  while Bevels.Count<=N do Bevels.Add(nil);
  O:=TObject(Bevels[N]);
  if (O<>Nil) then begin
    if O is TBevel then begin
      TBevel(O).RemoveAllHandlersOfObject(O);
      TBevel(O).Parent:=nil;
    end;
    O.Free;
  end;
  Bevels[N]:=Bv;
end;

procedure TForm1.mAddFromFileClick(Sender: TObject);
var
  CPage: TTabSheet;
  Btn: TButton;
  Img: TImage;
begin
  if not OpenPictureDialog.Execute then exit;
  CPage:=Tabs.AddTabSheet;
  CPage.Caption:=rsPage+' '+IntToStr(Tabs.PageCount-1);
  Btn:=TButton.Create(self);
  btn.Caption:='Button';
  Btn.Parent:=CPage;
  Btn.Show;
  Img:=TImage.Create(self);
  Img.Parent:=CPage;
  Imgs.Add(Img);
  Img.Left:=0;Img.Top:=0;
  Img.Height:=CPage.Height-20;
  Img.Width:=(CPage.Width div 2)-10;
  Img.Picture.LoadFromFile(OpenPictureDialog.FileName);
  Img.Stretch:=true;
  Img.OnMouseDown:=@Image1MouseDown;
  Img.OnMouseUp:=@Image1MouseUp;
  Img.Show;
  Btn.Hide;
end;




end.

