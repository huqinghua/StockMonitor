unit Stock;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, Forms, IniPropStorage;

type
  StockInfo = record
    name: string;
    code: string;
    HighWaterLevel: string;
    UpRatio: string;
    LowWaterLevel: string;
    downRatio: string;
  end;

  TStockInfoArray = array of StockInfo;

  PStockInfoArray = ^TStockInfoArray;

  TStockManager = class
  private
    stockInfoArray: TStockInfoArray;
    bInited: Boolean;
  public
    constructor create();

    procedure SaveStockConfig(stockInfoArr: TStockInfoArray);
    function LoadStockConfig(): TStockInfoArray;
    function GetStockConfig(): TStockInfoArray;
    function HasStock(code : string) : boolean;
  end;

var
  g_stockManager: TStockManager;

implementation

constructor TStockManager.create();
begin
  bInited := False;
  SetLength(stockInfoArray, 0);
  inherited create;
end;

function TStockManager.HasStock(code : string) : boolean;
var
  i : integer;
begin
  result := false;
  for i := 0 to length(stockInfoArray)-1 do
  begin
    if stockInfoArray[i].code = code then begin
       result := true;
       exit;
    end;
  end;
end;

function TStockManager.GetStockConfig(): TStockInfoArray;
begin
  if not bInited then
  begin
    Self.LoadStockConfig;
  end;

  Result := self.stockInfoArray;
end;

procedure TStockManager.SaveStockConfig(stockInfoArr: TStockInfoArray);
var
  i: integer;
  config: TIniPropStorage;
begin

  config := TIniPropStorage.Create(nil);
  config.IniFileName:=ExtractFilePath(Application.ExeName) + '/config.ini';
  config.IniSection:='stock';

  //writeln( config.IniFileName );

  config.WriteInteger('count', Length(stockInfoArr));

  for i := 0 to Length(stockInfoArr)-1 do
  begin
    config.WriteString('name'+IntToStr(i), stockInfoArr[i].name);
    config.WriteString('code'+IntToStr(i), stockInfoArr[i].code);
    config.WriteString('HighWaterLevel'+IntToStr(i), stockInfoArr[i].HighWaterLevel);
    config.WriteString('UpRatio'+IntToStr(i), stockInfoArr[i].UpRatio);
    config.WriteString('LowWaterLevel'+IntToStr(i), stockInfoArr[i].LowWaterLevel);
    config.WriteString('LowRatio'+IntToStr(i), stockInfoArr[i].downRatio);
  end;

  config.Free;
  self.stockInfoArray := stockInfoArr;
end;

function TStockManager.LoadStockConfig(): TStockInfoArray;
var
  i: integer;
  count: integer;
  config: TIniPropStorage;
begin
  config := TIniPropStorage.Create(nil);
  config.IniFileName:=ExtractFilePath(application.ExeName) + '/config.ini';
  config.IniSection:='stock';

  count := config.ReadInteger('count', 0);
  setlength(self.stockInfoArray, count);

  for i := 0 to count-1 do
  begin
    stockInfoArray[i].name := config.ReadString('name'+IntToStr(i), '');
    stockInfoArray[i].code := config.ReadString('code'+IntToStr(i), '');
    stockInfoArray[i].HighWaterLevel := config.ReadString('HighWaterLevel'+IntToStr(i), '');
    stockInfoArray[i].UpRatio := config.ReadString('UpRatio'+IntToStr(i), '');
    stockInfoArray[i].LowWaterLevel := config.ReadString('LowWaterLevel'+IntToStr(i), '');
    stockInfoArray[i].downRatio := config.ReadString('LowRatio'+IntToStr(i), '');
  end;

  config.Free;

  Result := stockInfoArray;
  bInited := True;
end;

initialization
  g_stockManager := TStockManager.create();

finalization

end.
 
