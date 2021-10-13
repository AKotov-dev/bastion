unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, ComCtrls, XMLPropStorage, Process, FileUtil, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    Memo3: TMemo;
    NewCertBtn: TBitBtn;
    ProgressBar1: TProgressBar;
    RestartBtn: TBitBtn;
    SaveDialog1: TSaveDialog;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    Shape4: TShape;
    StaticText1: TStaticText;
    WWWText: TStaticText;
    XMLPropStorage1: TXMLPropStorage;
    procedure FormShow(Sender: TObject);
    procedure NewCertBtnClick(Sender: TObject);
    procedure RestartBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure StartProcess;
  private

  public

  end;

resourcestring
  SNewCertWarn =
    'Would you like to create a new Squid certificate for installation on clients computers?';
  SCreateCert = 'Creating a certificate';

var
  MainForm: TMainForm;

implementation

uses trd_cmd, status_trd, ping_trd;

{$R *.lfm}

{ TMainForm }

//Общая процедура запуска команд
procedure TMainForm.StartProcess;
var
  ExProcess: TProcess;
begin
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'sakura';  //sh или sakura
    ExProcess.Parameters.Add('--font');
    ExProcess.Parameters.Add('10');
    ExProcess.Parameters.Add('--columns');
    ExProcess.Parameters.Add('120');
    ExProcess.Parameters.Add('--rows');
    ExProcess.Parameters.Add('40');
    ExProcess.Parameters.Add('--title');
    ExProcess.Parameters.Add(SCreateCert);
    //  ExProcess.Parameters.Add('--config-file=sakura-bastion.conf');
    ExProcess.Parameters.Add('-x');
    ExProcess.Options := ExProcess.Options + [poWaitOnExit];
    ExProcess.Parameters.Add('/etc/squid/cert-init.sh');
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  Memo1.Width := MainForm.Width div 3 - 16;
  Memo2.Width := Memo1.Width;
  Memo3.Width := Memo1.Width;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  S: ansistring;
  FStartShowPingThread, FStartShowStatusThread: TThread;
begin
  try
    MainForm.Caption := Application.Title;

    //Запуск потока отображения ping
    FStartShowPingThread := CheckPing.Create(False);
    FStartShowPingThread.Priority := tpNormal;

    //Запуск потока отображения статуса
    FStartShowStatusThread := ShowStatus.Create(False);
    FStartShowStatusThread.Priority := tpNormal;

    if not DirectoryExists(GetUserDir + '.config') then
      MkDir(GetUserDir + '/.config');
    XMLPropStorage1.FileName := GetUserDir + '/.config/bastion.conf';

    //WAN/LAN
    if RunCommand('/bin/bash',
      ['-c', 'grep "wan=" /etc/squid/bastion.sh | sed "s/\"//g" | cut -b 5-'], S) then
      Edit3.Text := Trim(S);

    if RunCommand('/bin/bash',
      ['-c', 'grep "lan=" /etc/squid/bastion.sh | sed "s/\"//g" | cut -b 5-'], S) then
      Edit2.Text := Trim(S);

    //Network
    if RunCommand('/bin/bash', ['-c', 'cat /etc/squid/localnet.txt'], S) then
      Edit1.Text := Trim(S);

    //BlackList/WhiteList/Vip-Users
    Memo1.Lines.LoadFromFile('/etc/squid/blacklist.txt');
    Memo3.Lines.LoadFromFile('/etc/squid/whitelist.txt');
    Memo2.Lines.LoadFromFile('/etc/squid/vip-users.txt');
  finally
  end;
end;

procedure TMainForm.RestartBtnClick(Sender: TObject);
var
  S: ansistring;
  FStartTRDCommand: TThread;
begin
  try
    //Запись WAN/LAN
    if RunCommand('/bin/bash', ['-c', 'sed -i "s/wan=.*/wan=\"' +
      Trim(Edit3.Text) + '\"/g" /etc/squid/bastion.sh'], S) then

      if RunCommand('/bin/bash', ['-c', 'sed -i "s/lan=.*/lan=\"' +
        Trim(Edit2.Text) + '\"/g" /etc/squid/bastion.sh'], S) then

        //Local Network
        RunCommand('/bin/bash',
          ['-c', 'echo "' + Trim(Edit1.Text) + '" > /etc/squid/localnet.txt'], S);

    //Сохраняем blackList, whiteList, vip-users
    Memo1.Lines.SaveToFile('/etc/squid/blacklist.txt');
    Memo3.Lines.SaveToFile('/etc/squid/whitelist.txt');
    Memo2.Lines.SaveToFile('/etc/squid/vip-users.txt');

    Shape1.Brush.Color := clYellow;
    Shape2.Brush.Color := clYellow;
    Application.ProcessMessages;

    //Запуск потока Рестарт
    FStartTRDCommand := StartTRDCommand.Create(False);
    FStartTRDCommand.Priority := tpNormal;
  finally
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  XMLPropStorage1.Restore;
end;

//Создание сертификата
procedure TMainForm.NewCertBtnClick(Sender: TObject);
begin
  if MessageDlg(SNewCertWarn, mtConfirmation, mbOKCancel, 0) = mrOk then
  begin
    Application.ProcessMessages;
    StartProcess;

    if FileExists('/etc/squid/squid.der') then
      if SaveDialog1.Execute then
        CopyFile('/etc/squid/squid.der', SaveDialog1.FileName, False);
  end;
end;

end.
