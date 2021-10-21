unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, ComCtrls, XMLPropStorage, Process, FileUtil, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    DNSCheckBox: TCheckBox;
    SMBCheckBox: TCheckBox;
    SMBSh: TShape;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    WWWSh: TShape;
    IPTablesSh: TShape;
    SquidSh: TShape;
    ApacheSh: TShape;
    DNSMasqSh: TShape;
    WWWLabel: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    SquidLabel: TLabel;
    IPTablesLabel: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    ApacheLabel: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    Memo3: TMemo;
    NewCertBtn: TBitBtn;
    ProgressBar1: TProgressBar;
    RestartBtn: TBitBtn;
    SaveDialog1: TSaveDialog;
    StaticText1: TStaticText;
    XMLPropStorage1: TXMLPropStorage;
    procedure FormShow(Sender: TObject);
    procedure NewCertBtnClick(Sender: TObject);
    procedure RestartBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure StartProcess;
    procedure DNSMasqConf;
    procedure SambaConf;

  private

  public

  end;

resourcestring
  SNewCertWarn =
    'Create a new squid.der certificate for installation on clients computers?';
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

//Запускаем Samba
procedure TMainForm.SambaConf;
var
  Conf: TStringList;
  hostname: ansistring;
begin
  try
    Conf := TStringList.Create;

    //Создаём общий каталог
    if not DirectoryExists('/usr/local/Common') then
    begin
      MkDir('/usr/local/Common');
      RunCommand('/bin/bash', ['-c', 'chmod 777 /usr/local/Common'], hostname);
    end;

    //Узнаём имя сервера
    if RunCommand('/bin/bash', ['-c', 'hostname'], hostname) then
      //Создаём /etc/htb/htb.samba/smb.conf
      with Conf do
      begin
        Add('[global]');
        Add('');
        Add('workgroup = WORKGROUP');
        Add('server string = htb-enot');
        Add('');
        Add('interfaces = 127.0.0.1 ' + Trim(Edit2.Text));
        Add('');
        Add('netbios name = ' + Trim(hostname));
        Add('');
   { if MasterOn.Checked then //Master Browser? (Mageia 2 - указывать явно)
    begin
      Add('domain master = no');
      Add('local master = yes');
      Add('os level = 86');
      Add('preferred master = yes');
      Add('');
    end
    else
    begin}
        Add('domain master = no');
        Add('local master = no');
        Add('preferred master = no');
        Add('');
        //end;
        Add('security = user');
        Add('map to guest = Bad Password');
        Add('');
        Add('dos charset = cp1251');
        Add('unix charset = utf8');
        Add('');
        Add('#Отключаем printcab');
        Add('load printers = no');
        Add('show add printer wizard = no');
        Add('printing = bsd');
        Add('printcap name = /dev/null');
        Add('disable spoolss = yes');
        Add('');
        Add('#Общий ресурс');
        Add('[Common]');
        Add('path = /usr/local/Common');
        Add('public = yes');
        Add('browseable = yes');
        Add('read only = no');
        Add('guest ok = yes');
        Add('');
        Add('#Корзина');
        Add('vfs object = recycle');
        Add('recycle:keeptree = yes');
        Add('recycle:version = yes');
        Add('recycle:repository = .recycle');
        Add('recycle:touch_mtime = yes');
        Add('recycle:touch = yes');
        Add('recycle:maxsize = 0');
        Add('recycle:exclude = *.tmp, *.TMP, *.temp, ~$*, ?~$*, ~*');
        Add('recycle:exclude_dir = .recycle');
      end;

    //Копируем правленный файл в рабочий каталог samba
    Conf.SaveToFile('/etc/samba/smb.conf');

    //Копируем файл автоочистки в планировщик, если его там нет
 { if not FileExists('/etc/cron.monthly/recycle-clear') then
    MainForm.StartProcess('cp -f /etc/htb/htb.samba/recycle-clear /etc/cron.monthly');
  }
  finally
    Conf.Free;
  end;
end;


//Конфигурация и запуск DNSMasq
procedure TMainForm.DNSMasqConf;
var
  i: integer;
  LanIP: ansistring;
  Conf: TStringList;
begin
  try
    Conf := TStringList.Create;

    //Узнаём IP-адрес интерфейса LAN
    if RunCommand('/bin/bash', ['-c', 'ifconfig ' + Trim(Edit2.Text) +
      ' | grep inet | awk ' + '''' + '{ print $2 }' + ''''], LanIP) then
    begin
      LanIP := Trim(LanIP);

      Conf.Add('#Авторитетный DHCP сервер');
      Conf.Add('dhcp-authoritative');
      Conf.Add('');

      Conf.Add('#Слушать на интерфейсах ($lan=enp0s8=192.168.1.1+lo)');
      Conf.Add('interface=' + Trim(Edit2.Text));
      Conf.Add('listen-address=127.0.0.1,' + LanIP);
      Conf.Add('');

      Conf.Add('#Не использовать resolv.conf');
      Conf.Add('no-resolv');
      Conf.Add('');

      Conf.Add('#Форвардинг DNS-запросов');
      Conf.Add('server=8.8.8.8');
      Conf.Add('server=8.8.4.4');
      Conf.Add('');

      Conf.Add('#Отдать параметры клиенту');
      Conf.Add('dhcp-option=option:router,' + LanIP);
      Conf.Add('dhcp-option=option:dns-server,' + LanIP);
      Conf.Add('');

      //Отбрасываем последний октет LanIP
      for i := Length(LanIP) downto 1 do
        if LanIP[i] = '.' then
        begin
          LanIP := Copy(LanIP, 1, i);
          Break;
        end;

      Conf.Add('#Диапазон выдачи IP-адресов (аренда 72 часа)');
      Conf.Add('dhcp-range=' + LanIP + '50,' + LanIP + '250,72h');
      Conf.Add('');

      Conf.Add('#Отключить DHCP_INFO-PROXY для Windows 7+');
      Conf.Add('dhcp-option=252,"\n"');
      Conf.Add('');

      Conf.Add('#Настройки кеша DNS');
      Conf.Add('cache-size=10000');
      Conf.Add('no-negcache');

      Conf.SaveToFile('/etc/dnsmasq.conf');
    end;
  finally
    Conf.Free;
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
    if RunCommand('/bin/bash', ['-c', 'squid -v | head -n1'], S) then
      MainForm.Caption := Concat(Application.Title, ' [', Trim(S), ']');

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

    //Флаг запуска DNSMasq для bastion.sh
    if FileExists('/etc/squid/dnsmasq-start') then
      DNSCheckBox.Checked := True
    else
      DNSCheckBox.Checked := False;

    //Флаг запуска Samba для bastion.sh
    if FileExists('/etc/squid/samba-start') then
      SMBCheckBox.Checked := True
    else
      SMBCheckBox.Checked := False;
  except
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

    //Конфигурация и запуск DNSMasq (флаг запуска dnsmasq-start для /etc/squid/bastion.sh)
    if DNSCheckBox.Checked then
    begin
      Memo3.Lines.SaveToFile('/etc/squid/dnsmasq-start');
      DNSMasqConf;
    end
    else
      DeleteFile('/etc/squid/dnsmasq-start');

    //Конфигурация и запуск Samba (флаг запуска samba-start для /etc/squid/bastion.sh)
    if SMBCheckBox.Checked then
    begin
      Memo3.Lines.SaveToFile('/etc/squid/samba-start');

      if RunCommand('/bin/bash',
        ['-c', 'cp -f /etc/squid/recycle-cleaner.sh /etc/cron.monthly/recycle-cleaner.sh; '
        + 'chmod 755 /etc/cron.monthly/recycle-cleaner.sh'], S) then

        SambaConf;
    end
    else
    begin
      DeleteFile('/etc/squid/samba-start');
      DeleteFile('/etc/cron.monthly/recycle-cleaner.sh');
    end;

    Application.ProcessMessages;

    //Запуск потока Рестарт
    FStartTRDCommand := StartTRDCommand.Create(False);
    FStartTRDCommand.Priority := tpNormal;
  except
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
