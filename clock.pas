unit Clock;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, IniPropStorage, DateTimePicker, DateUtils;

type

  { TFrmClock }

  TFrmClock = class(TForm)
    alarmClockListView: TListView;
    alarmTimePicker: TDateTimePicker;
    btnDelete: TButton;
    btnOK: TButton;
    frequencyComboBox: TComboBox;
    msgMemo: TMemo;
    Timer1: TTimer;
    procedure btnDeleteClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);

  private
     alarmTime2Alarm : String;
    msg2Show : String;
    alarmed : BOOLEAN;

    procedure saveAlarmClockConfig;
    procedure loadAlarmClockConfig;
    procedure setAlarmTimer(bInit : BOOLEAN);

  public

  end;

var
  FrmClock: TFrmClock;

implementation

{$R *.lfm}

{ TFrmClock }

procedure TFrmClock.saveAlarmClockConfig;
var
  i : integer;
  config: TIniPropStorage;
begin
  config := TIniPropStorage.Create(nil);
  config.IniFileName:=ExtractFilePath(application.ExeName) + '/config.ini';
  config.IniSection:='alarmclock';

  config.WriteInteger('count', alarmClockListView.Items.Count);

  for i:=0 to alarmClockListView.Items.Count-1 do
  begin
    config.WriteString('time'+IntToStr(i), alarmClockListView.Items[i].Caption);
    config.WriteString('frequency'+IntToStr(i), alarmClockListView.Items[i].SubItems[0]);
    config.WriteString('msg'+IntToStr(i), alarmClockListView.Items[i].SubItems[1]);
  end;

  config.Free;
end;

procedure TFrmClock.loadAlarmClockConfig;
var
  i : integer;
  count : integer;
  AItem: TListItem;
  config: TIniPropStorage;
begin
  config := TIniPropStorage.Create(nil);
  config.IniFileName:=ExtractFilePath(application.ExeName) + '/config.ini';
  config.IniSection:='alarmclock';

  count := config.ReadInteger('count', 0);

  for i:=0 to count-1 do
  begin
      with alarmClockListView do
      begin
        AItem := Items.Add;
        AItem.Caption := config.ReadString('time'+IntToStr(i), '');
        AItem.ImageIndex := 0;
        AItem.StateIndex := 0;
        AItem.SubItems.Add(config.ReadString('frequency'+IntToStr(i), ''));
        AItem.SubItems.Add(config.ReadString('msg'+IntToStr(i), ''));
      end;
  end;

  config.Free;
end;

procedure TFrmClock.setAlarmTimer(bInit : BOOLEAN);
var
  i : integer;
  count : integer;
  strTime : String;
  strNow, strTimeToAlarm: String;
  desTime: TDateTime;
  config: TIniPropStorage;

begin
  strTimeToAlarm := '23:59:59';
  config := TIniPropStorage.Create(nil);
  config.IniFileName:=ExtractFilePath(application.ExeName) + '/config.ini';
  config.IniSection:='alarmclock';

  count := config.ReadInteger('count', 0);

  strNow := FormatDateTime('hh:nn:ss',Now);

  for i:=0 to count-1 do
  begin
    strTime := config.ReadString('time'+IntToStr(i), '');
    if strTime > alarmTime2Alarm then begin
       if strTime < strNow then begin
          if not bInit then
             ShowMessage(strTime +': ' + config.ReadString('msg'+IntToStr(i), ''));
       end else begin
         if strTime < strTimeToAlarm then begin
            strTimeToAlarm := strTime;
            msg2Show :=  strTime +': ' + config.ReadString('msg'+IntToStr(i), '');
            alarmed := False;
         end;
       end;
    end;
  end;

  config.Free;

  // now set timer for time strTimeToAlarm
  //desTime := EncodeDateTime(YearOf(Now), MonthOf(Now), DayOf(Now), strTimeToAlarm.Substring(0, 2), strTimeToAlarm.Substring(3, 2), strTimeToAlarm.Substring(6, 2));
  //desTime := StrToDateTime(FormatDateTime('YYYY-MM-DD ', Now) + strTimeToAlarm);
  if not self.alarmed then begin
    desTime := ScanDateTime('YYYY/MM/DD hh:nn:ss', FormatDateTime('YYYY/MM/DD ', Now) + strTimeToAlarm);

    Timer1.Interval:= MilliSecondsBetween(Now, desTime) ;
    Timer1.Enabled := True;
  end;

end;

procedure TFrmClock.btnOKClick(Sender: TObject);
var
  AItem: TListItem;
  str: String;
  s: string;
begin
  str := FormatDateTime('YYYY-MM-DD hh:nn:ss',alarmTimePicker.DateTime);

  if CompareText(self.frequencyComboBox.Text, '每天') = 0 then
  begin
    str := FormatDateTime('hh:nn:ss',alarmTimePicker.DateTime);
  end;

  alarmClockListView.BeginUpdate;
  with alarmClockListView do
  begin
    AItem := Items.Add;
    AItem.Caption := str;
    AItem.ImageIndex := 0;
    AItem.StateIndex := 0;
    AItem.SubItems.Add(self.frequencyComboBox.Text);
    AItem.SubItems.Add(self.msgMemo.Text);
  end;
  alarmClockListView.EndUpdate;

  saveAlarmClockConfig;

  setAlarmTimer(False);
end;


procedure TFrmClock.btnDeleteClick(Sender: TObject);
begin
  if alarmClockListView.ItemIndex >=0 then begin
     alarmClockListView.Items.Delete(alarmClockListView.ItemIndex);
  end;

  self.saveAlarmClockConfig;
end;

procedure TFrmClock.FormCreate(Sender: TObject);
begin
  Timer1.Enabled:= False;
  self.loadAlarmClockConfig;
  self.setAlarmTimer(True);

  self.alarmTimePicker.DateTime:=Now;
end;

procedure TFrmClock.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled:= False;
  ShowMessage(msg2Show);
  self.alarmed:= True;
  self.setAlarmTimer(True);
end;

end.

