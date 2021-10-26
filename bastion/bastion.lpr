program bastion;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Unit1, TRD_CMD, status_trd, ping_trd;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='Bastion-v1.3';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

