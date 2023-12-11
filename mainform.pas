unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  IniPropStorage;

type

  { TFrmMain }

  TFrmMain = class(TForm)
    btnAdd: TButton;
    btnDelete: TButton;
    btnDown: TButton;
    btnUp: TButton;
    edtCode: TEdit;
    edtHighWaterLevel: TEdit;
    edtLowRatio: TEdit;
    edtLowWaterLevel: TEdit;
    edtName: TEdit;
    edtUpRatio: TEdit;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lbl1: TLabel;
    lbl2: TLabel;
    lbl3: TLabel;
    lvStockWarnConfig: TListView;
    procedure btnAddClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lvStockWarnConfigSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
  private
    procedure saveConfig();
    procedure loadConfig;
  public

  end;

var
  FrmMain: TFrmMain;

implementation

uses
  Stock, WarnForm;

{$R *.lfm}

{ TFrmMain }

procedure TFrmMain.btnDeleteClick(Sender: TObject);
begin
  if lvStockWarnConfig.ItemIndex >= 0 then
  begin
    lvStockWarnConfig.Items.Delete(lvStockWarnConfig.ItemIndex);
  end;

  self.saveConfig;
end;

procedure TFrmMain.btnDownClick(Sender: TObject);
begin
  if Assigned(self.lvStockWarnConfig.Selected) then begin
    if self.lvStockWarnConfig.ItemIndex < self.lvStockWarnConfig.items.Count-1 then begin
       self.lvStockWarnConfig.Items.Move(self.lvStockWarnConfig.ItemIndex, self.lvStockWarnConfig.ItemIndex + 1);
       self.saveConfig();
    end;
  end;
end;

procedure TFrmMain.btnUpClick(Sender: TObject);
begin
  if Assigned(self.lvStockWarnConfig.Selected) then begin
    if self.lvStockWarnConfig.ItemIndex > 0 then begin
       self.lvStockWarnConfig.Items.Move(self.lvStockWarnConfig.ItemIndex, self.lvStockWarnConfig.ItemIndex - 1);
       self.saveConfig();
    end;
  end;
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  self.loadConfig;
end;

procedure TFrmMain.loadConfig;
var
  i: integer;
  AItem: TListItem;
  stockInfoArr: TStockInfoArray;
begin
  stockInfoArr := g_stockManager.GetStockConfig();
  for i := 0 to Length(stockInfoArr) - 1 do
  begin
    with self.lvStockWarnConfig do
    begin
      AItem := Items.Add;
      AItem.Caption := stockInfoArr[i].name;
      AItem.ImageIndex := 0;
      AItem.StateIndex := 0;
      AItem.SubItems.Add(stockInfoArr[i].code);
      AItem.SubItems.Add(stockInfoArr[i].HighWaterLevel);
      AItem.SubItems.Add(stockInfoArr[i].UpRatio);
      AItem.SubItems.Add(stockInfoArr[i].LowWaterLevel);
      AItem.SubItems.Add(stockInfoArr[i].downRatio);
    end;
  end;
end;

procedure TFrmMain.lvStockWarnConfigSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  self.edtName.Text := Item.Caption;
  self.edtCode.Text := Item.SubItems[0];
  self.edtHighWaterLevel.Text := Item.SubItems[1];
  self.edtUpRatio.Text := Item.SubItems[2];
  self.edtLowWaterLevel.Text := Item.SubItems[3];
  self.edtLowRatio.Text := Item.SubItems[4];
end;

procedure TFrmMain.btnAddClick(Sender: TObject);
var
  AItem: TListItem;
  i : integer;
begin
  if self.edtCode.Text = '' then exit;

  if not g_stockManager.HasStock(self.edtCode.Text) then
  begin
    with self.lvStockWarnConfig do
    begin
      AItem := Items.Add;
      AItem.Caption := self.edtName.Text;
      AItem.ImageIndex := 0;
      AItem.StateIndex := 0;
      AItem.SubItems.Add(self.edtCode.Text);
      AItem.SubItems.Add(self.edtHighWaterLevel.Text);
      AItem.SubItems.Add(self.edtUpRatio.Text);
      AItem.SubItems.Add(self.edtLowWaterLevel.Text);
      AItem.SubItems.Add(self.edtLowRatio.Text);
    end;
  end else begin
    for i:=0 to lvStockWarnConfig.Items.Count-1 do
    begin
      if lvStockWarnConfig.Items[i].SubItems[0] = self.edtCode.Text then begin
        lvStockWarnConfig.Items[i].Caption := self.edtName.Text;
        lvStockWarnConfig.Items[i].SubItems[1] := self.edtHighWaterLevel.Text;
        lvStockWarnConfig.Items[i].SubItems[2] := self.edtUpRatio.Text;
        lvStockWarnConfig.Items[i].SubItems[3] := self.edtLowWaterLevel.Text;
        lvStockWarnConfig.Items[i].SubItems[4] := self.edtLowRatio.Text;
      end;
    end;
  end;

  saveConfig();
end;

procedure TFrmMain.saveConfig;
var
  i: integer;
  stockInfoArray: TStockInfoArray;
begin
  SetLength(stockInfoArray, lvStockWarnConfig.Items.Count);
  for i:=0 to lvStockWarnConfig.Items.Count-1 do
  begin
    stockInfoArray[i].name := lvStockWarnConfig.Items[i].Caption;
    stockInfoArray[i].code := lvStockWarnConfig.Items[i].SubItems[0];
    stockInfoArray[i].HighWaterLevel := lvStockWarnConfig.Items[i].SubItems[1];
    stockInfoArray[i].UpRatio := lvStockWarnConfig.Items[i].SubItems[2];
    stockInfoArray[i].LowWaterLevel := lvStockWarnConfig.Items[i].SubItems[3];
    stockInfoArray[i].downRatio := lvStockWarnConfig.Items[i].SubItems[4];
  end;

  g_stockManager.SaveStockConfig(stockInfoArray);

  FrmWarn.ClearPriceInfo;
end;

end.

