unit status_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, Graphics, Forms;

type
  ShowStatus = class(TThread)
  private

    { Private declarations }
  protected
  var
    Result: TStringList;

    procedure Execute; override;

    procedure ShowIPTables;
    procedure ShowSquid;
    procedure ShowApache;
    procedure ShowDNSMasq;

  end;

implementation

uses Unit1;

{ TRD }

//Scan IPTables/Squid/Apache status
procedure ShowStatus.Execute;
var
  ExProcess: TProcess;
begin
  try
    FreeOnTerminate := True; //Уничтожать по завершении
    Result := TStringList.Create;

    //Вывод состояния сервисов
    ExProcess := TProcess.Create(nil);
    ExProcess.Options := [poUsePipes, poWaitOnExit];
    ExProcess.Executable := 'bash';

    while not Terminated do
    begin
      Result.Clear;
      Exprocess.Parameters.Clear;

      //IPTables status
      ExProcess.Parameters.Add('-c');
      ExProcess.Parameters.Add('systemctl is-active iptables');
      ExProcess.Execute;

      Result.LoadFromStream(ExProcess.Output);
      Synchronize(@ShowIPTables);

      //Squid status
      ExProcess.Parameters.Delete(1);
      ExProcess.Parameters.Add('systemctl is-active squid');
      Exprocess.Execute;

      Result.LoadFromStream(ExProcess.Output);
      Synchronize(@ShowSquid);

      //Apache status
      ExProcess.Parameters.Delete(1);
      ExProcess.Parameters.Add('systemctl is-active httpd');
      Exprocess.Execute;

      Result.LoadFromStream(ExProcess.Output);
      Synchronize(@ShowApache);

      //DNSMasq status
      ExProcess.Parameters.Delete(1);
      ExProcess.Parameters.Add('systemctl is-active dnsmasq');
      Exprocess.Execute;

      Result.LoadFromStream(ExProcess.Output);
      Synchronize(@ShowDNSMasq);

      Sleep(250);
    end;

  finally
    Result.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ СТАТУСА }

//IPTables status
procedure ShowStatus.ShowIPTables;
begin
  Application.ProcessMessages;
  if Trim(Result[0]) = 'active' then
    MainForm.IPTablesLabel.Font.Color := clGreen
  else
    MainForm.IPTablesLabel.Font.Color := clRed;
  MainForm.IPTablesLabel.Repaint;
end;

//Squid status
procedure ShowStatus.ShowSquid;
begin
  Application.ProcessMessages;
  if Trim(Result[0]) = 'active' then
    MainForm.SquidLabel.Font.Color := clGreen
  else
    MainForm.SquidLabel.Font.Color := clRed;
  MainForm.SquidLabel.Repaint;
end;

//Apache status
procedure ShowStatus.ShowApache;
begin
  Application.ProcessMessages;
  if Trim(Result[0]) = 'active' then
    MainForm.ApacheLabel.Font.Color := clGreen
  else
    MainForm.ApacheLabel.Font.Color := clRed;
  MainForm.ApacheLabel.Repaint;
end;

//DNSMasq status
procedure ShowStatus.ShowDNSMasq;
begin
  Application.ProcessMessages;
  if Trim(Result[0]) = 'active' then
    MainForm.DNSCheckBox.Font.Color := clGreen
  else
    MainForm.DNSMasqLabel.Font.Color := clRed;
  MainForm.DNSMasqLabel.Repaint;
end;

end.
