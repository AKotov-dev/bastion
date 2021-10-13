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
    MainForm.Shape2.Brush.Color := clLime
  else
    MainForm.Shape2.Brush.Color := clYellow;
  MainForm.Shape2.Repaint;
end;

//Squid status
procedure ShowStatus.ShowSquid;
begin
  Application.ProcessMessages;
  if Trim(Result[0]) = 'active' then
    MainForm.Shape1.Brush.Color := clLime
  else
    MainForm.Shape1.Brush.Color := clYellow;
  MainForm.Shape1.Repaint;
end;

//Apache status
procedure ShowStatus.ShowApache;
begin
  Application.ProcessMessages;
  if Trim(Result[0]) = 'active' then
    MainForm.Shape3.Brush.Color := clLime
  else
    MainForm.Shape3.Brush.Color := clYellow;
  MainForm.Shape3.Repaint;
end;

end.
