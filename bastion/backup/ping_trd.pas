unit ping_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, Graphics, Forms;

type
  CheckPing = class(TThread)
  private

    { Private declarations }
  protected
  var
    PingStr: TStringList;

    procedure Execute; override;
    procedure ShowPing;

  end;

implementation

uses unit1;

{ TRD }

procedure CheckPing.Execute;
var
  PingProcess: TProcess;
begin
  try
    FreeOnTerminate := True; //Уничтожать по завершении
    PingStr := TStringList.Create;

    PingProcess := TProcess.Create(nil);
    PingProcess.Executable := 'bash';
    PingProcess.Parameters.Add('-c');
    PingProcess.Parameters.Add(
      'ERR=$(ping google.com -c 2 2>&1 > /dev/null) && echo "yes" || echo "no"');
    PingProcess.Options := [poUsePipes, poWaitOnExit];

    while not Terminated do
    begin
      PingProcess.Execute;
      PingStr.LoadFromStream(PingProcess.Output);
      Synchronize(@ShowPing);
      Sleep(1000);
    end;
  finally
    PingStr.Free;
    PingProcess.Free;
    Terminate;
  end;
end;

//Отображение состояния ping WWW
procedure CheckPing.ShowPing;
begin
  Application.ProcessMessages;
  if Trim(PingStr[0]) = 'yes' then
    MainForm.WWWSh.Brush.Color := clLime
  else
    MainForm.WWWSh.Brush.Color := clYellow;
  MainForm.WWWSh.Repaint;
end;

end.
