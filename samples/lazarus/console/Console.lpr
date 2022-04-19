program Console;

{$MODE DELPHI}{$H+}

uses
  SysUtils,
  Horse,
  Horse.StaticFiles;

procedure Ping(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  Res.Send('Pong');
end;

begin
  THorse.Get('/ping', Ping);
  THorse.Get('/horse', HorseStaticFile('.\modules', ['README.md','LICENSE','boss.json']));
  THorse.Listen(9000);
end.

