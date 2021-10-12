unit TRD_CMD;

{$mode objfpc}{$H+}

interface

uses
  Classes, ComCtrls, Process;

type
  StartTRDCommand = class(TThread)
  private

    { Private declarations }
  protected

    procedure Execute; override;
    procedure ShowProgress;
    procedure HideProgress;

  end;

implementation

uses unit1;

{ TRD }

//udev reload
procedure StartTRDCommand.Execute;
var
  ExProcess: TProcess;
begin
  Synchronize(@ShowProgress);

  FreeOnTerminate := True; //Уничтожить по завершении
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Options := [poWaitOnExit];
    ExProcess.Parameters.Add('/etc/squid/iptables.sh');
    ExProcess.Execute;
  finally
    ExProcess.Free;
    Terminate;
    Synchronize(@HideProgress);
  end;
end;

//Прогресс
procedure StartTRDCommand.ShowProgress;
begin
  with MainForm do
  begin
    ProgressBar1.Style := pbstMarquee;
    NewCertBtn.Enabled := False;
    RestartBtn.Enabled := False;
  end;
end;

//Нет прогресса
procedure StartTRDCommand.HideProgress;
begin
  with MainForm do
  begin
    ProgressBar1.Style := pbstNormal;
    NewCertBtn.Enabled := True;
    RestartBtn.Enabled := True;
  end;
end;

end.
