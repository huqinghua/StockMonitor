unit WarnForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  {$if defined(windows)}
  Windows,
  {$endif}
  {$ifdef darwin}
  Process,
  {$endif}
  SysUtils, StrUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, Menus, IdHTTP;

type

  RWarnMessage = record
    warnType : string;
    warnMessage : string;
    suggustion : string;
  end;
  PRWarnMessage = ^RWarnMessage;

  RStockPrice = record
    stockName : string;
    price : string;
    fd : string;
  end;
  PRStockPrice = ^RStockPrice;

  { TFrmWarn }

  TFrmWarn = class(TForm)
    btnClear: TButton;
    Button1: TButton;
    IdHTTP1: TIdHTTP;
    il1: TImageList;
    lv1: TListView;
    lvStockPrice: TListView;
    MenuItemStockConfig: TMenuItem;
    MenuItemClockConfig: TMenuItem;
    PopupMenuConfig: TPopupMenu;
    tmr1: TTimer;
    procedure btnClearClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItemClockConfigClick(Sender: TObject);
    procedure MenuItemStockConfigClick(Sender: TObject);
  private

  public
    procedure addMsg(msgType: string; msg: string; suggestion: string);
    procedure ShowPrice(stockname, price, fd: string);
    procedure ClearPriceInfo;

  end;

  { TMyThread }

  TMyThread = class(TThread)
  private
    warnMessageList : TThreadList;
    stockPriceList : TThreadList;
    procedure ShowWarnMessage;
    procedure ShowPrice;

    procedure AddWarnMessage(warnType, warnMessage, suggestion: string);
    procedure AddStockPriceRecord(stockName, price, fd: string);
  protected

    procedure GetPrice(stockCode: string; var price: string; var fd: string);
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: boolean);
  end;

var
  FrmWarn: TFrmWarn;

implementation

uses
  Utils, MainForm, Stock;

{$R *.lfm}

{ TFrmWarn }

procedure TFrmWarn.Button1Click(Sender: TObject);
begin
  //self.PopupMenuConfig.PopUp;
  FrmMain.Show;
end;

procedure TFrmWarn.btnClearClick(Sender: TObject);
begin
  self.lv1.Clear;
end;

procedure TFrmWarn.FormCreate(Sender: TObject);
var
  MyThread : TMyThread;
begin
  MyThread := TMyThread.Create(True); // With the True parameter it doesn't start automatically
  if Assigned(MyThread.FatalException) then
    raise MyThread.FatalException;

  MyThread.Start;
end;

procedure TFrmWarn.MenuItemClockConfigClick(Sender: TObject);
begin
  //FrmClock.Show;
end;

procedure TFrmWarn.MenuItemStockConfigClick(Sender: TObject);
begin
  FrmMain.Show;
end;

procedure TFrmWarn.ClearPriceInfo;
begin
  self.lvStockPrice.Clear;
end;

procedure TFrmWarn.addMsg(msgType: string; msg: string; suggestion: string);
var
  AItem: TListItem;
begin
  with self.lv1 do
  begin
    AItem := Items.Add;
    AItem.Caption := msgType;
    if msgType = '^' then begin
       //AItem.ImageIndex := 1;
    end else if msgType = 'WARN' then
       AItem.ImageIndex := 0;
    AItem.SubItems.Add(msg);
    AItem.SubItems.Add(suggestion);
  end;
end;

procedure TFrmWarn.ShowPrice(stockname, price, fd: string);
var
  AItem: TListItem;
  i: integer;
begin
  for i := 0 to self.lvStockPrice.Items.Count - 1 do
  begin
    if lvStockPrice.Items[i].Caption = stockname then
    begin
      lvStockPrice.Items[i].SubItems[0] := price;
      lvStockPrice.Items[i].SubItems[1] := fd;
      exit;
    end;
  end;

  with self.lvStockPrice do
  begin
    AItem := Items.Add;
    AItem.Caption := stockname;
    AItem.SubItems.Add(price);
    AItem.SubItems.Add(fd);
  end;
end;

{ TMyThread }

procedure TMyThread.ShowWarnMessage;
var
  //F:FLASHWINFO;
  pRecord : PRWarnMessage;
  i: Integer;
  s: string;
  warntype : string;
begin
  //f.cbSize:=sizeof(FLASHWINFO);
  //f.hwnd:=application.Handle;
  //f.dwFlags:=FLASHW_ALL or FLASHW_STOP;
  //f.uCount:=4;
  //f.dwTimeout:=250;
  //FlashWindowEx(@f);

  pRecord := self.warnMessageList.LockList.First;
  if pRecord <> nil then begin
    warntype := pRecord^.warnType;
    FrmWarn.addMsg(pRecord^.warnType, pRecord^.warnMessage, pRecord^.suggustion);
    self.warnMessageList.Remove(pRecord);
    Dispose(pRecord);
  end;
  self.warnMessageList.UnlockList;

  if frmwarn.lv1.Items.Count > 200 then
  begin
    for i:=0 to 100 do
        frmwarn.lv1.Items.Delete(0);
  end;

{$if defined(windows)}
  flashwindow(application.Handle, True);
{$endif}

{$ifdef darwin}
  if warntype = '^' then begin
      RunCommand('/usr/bin/osascript', ['-e', 'display notification "WooHoo!" with title "Attention Please:"'], s);
  end else begin
    if warntype = 'WARN' then begin
      RunCommand('/usr/bin/osascript', ['-e', 'display notification "Warn **************" with title "Attention Please:"'], s);
    end;
  end;
{$endif}
end;

procedure TMyThread.AddWarnMessage(warnType, warnMessage, suggestion: string);
var
  pRecord : PRWarnMessage;
begin
  New(pRecord);
  FillChar(pRecord^, SizeOf(RWarnMessage), 0);
  pRecord^.warnType:= warnType;
  pRecord^.warnMessage:= warnMessage;
  pRecord^.suggustion:= suggestion;

  self.warnMessageList.add(pRecord);

  Synchronize(@ShowWarnMessage);
end;

procedure TMyThread.AddStockPriceRecord(stockName, price, fd: string);
var
  pRecord : PRStockPrice;
begin
  New(pRecord);
  FillChar(pRecord^, SizeOf(RStockPrice), 0);
  pRecord^.stockName:= stockName;
  pRecord^.price:= price;
  pRecord^.fd := fd;
  self.stockPriceList.add(pRecord);

  Synchronize(@ShowPrice);
end;

procedure TMyThread.ShowPrice;
var
  pRecord : PRStockPrice;
begin
  pRecord := self.stockPriceList.LockList.First;
  if pRecord <> nil then begin
    FrmWarn.ShowPrice(pRecord^.stockname, pRecord^.price, pRecord^.fd);
    self.stockPriceList.Remove(pRecord);
    Dispose(pRecord);
  end;
  self.stockPriceList.UnlockList;
end;

procedure TMyThread.GetPrice(stockCode: string; var price: string; var fd: string);
var
  httpClient: TIdHTTP;
  responseStream: TStringStream;
  strResponse: string;
  index, i, startIndex, endIndex: integer;
  prifix: string;
begin
  httpClient := TIdHTTP.Create(nil);
  responseStream := TStringStream.Create('');

  try
    if stockCode = '000001' then
    begin
      prifix := 'sh';
    end
    else
    begin
      case stockCode[1] of
        '3', '0':
          prifix := 'sz';
        '6':
          prifix := 'sh';
        else
          prifix := 'sz';
      end;
    end;

    httpClient.Get('http://qt.gtimg.cn/q=' + prifix + stockCode, responseStream);
    strResponse := responseStream.DataString;

    // price

    index := 0;
    for i := 1 to 3 do
      index := PosEx('~', strResponse, index + 1);

    startIndex := index + 1;
    endIndex := PosEx('~', strResponse, startIndex);

    price := Copy(strResponse, startIndex, endIndex - startIndex);
    DebugOut(price);


    // fd

    index := 0;
    for i := 1 to 32 do
      index := PosEx('~', strResponse, index + 1);

    startIndex := index + 1;
    endIndex := PosEx('~', strResponse, startIndex);

    fd := Copy(strResponse, startIndex, endIndex - startIndex);
    DebugOut(fd);
  finally
    httpClient.Free;
    responseStream.Free;
  end;
end;

procedure TMyThread.Execute;
var
  fd, price: string;
  j: integer;
  code, Name, strNow: string;
  stockInfoArr: TStockInfoArray;
begin
  fd := '';
  price := '';

  while (not Terminated) do
  begin
    strNow := FormatDateTime('hh:nn:ss', Now);
    if not (((strNow > '09:30:00') and (strNow < '11:31:00')) or
      ((strNow > '13:00:00') and (strNow < '15:01:00'))) then
    begin
      sleep(1000);
      continue;
    end;

    stockInfoArr := g_stockManager.GetStockConfig();
    for j := 0 to Length(stockInfoArr) - 1 do
    begin
      try
        code := stockInfoArr[j].code;
        Name := stockInfoArr[j].Name;

        self.GetPrice(code, price, fd);
        DebugOut(price);
        DebugOut(fd);

        if (length(stockInfoArr[j].HighWaterLevel) > 0) and
          (StrToFloat(stockInfoArr[j].HighWaterLevel) > 0.1) and
          (StrToFloat(price) > StrToFloat(stockInfoArr[j].HighWaterLevel)) then
        begin
          self.AddWarnMessage('^', Name + ':' + price, '考虑获利了结');
        end
        else if (length(stockInfoArr[j].LowWaterLevel) > 0) and
          (StrToFloat(stockInfoArr[j].LowWaterLevel) > 0.1) and
          (StrToFloat(price) < StrToFloat(stockInfoArr[j].LowWaterLevel)) then
        begin
          self.AddWarnMessage('WARN', Name + ':' + price, '及时止损!');
        end;

        if (stockInfoArr[j].UpRatio <> '') and
          (StrToFloat(fd) > StrToFloat(stockInfoArr[j].UpRatio)) then
        begin
          self.AddWarnMessage('^', Name + ':' + fd + '%', '请关注');
        end
        else if (stockInfoArr[j].downRatio <> '') and
          (StrToFloat(fd) < -StrToFloat(stockInfoArr[j].downRatio)) then
        begin
          self.AddWarnMessage('WARN', Name + ':' + fd + '%', '请关注');
        end;

        self.AddStockPriceRecord(Name, price, fd);

      except
        on E: Exception do
        begin
          //self.AddWarnMessage('ERROR', E.Message);
        end;
      end;

      sleep(1000);
    end;
  end;

  self.warnMessageList.free;
  self.stockPriceList.free;
end;

constructor TMyThread.Create(CreateSuspended: boolean);
begin
  FreeOnTerminate := True;
  self.stockPriceList := TThreadList.Create;
  self.warnMessageList := TThreadList.Create;
  inherited Create(CreateSuspended);
end;

end.



