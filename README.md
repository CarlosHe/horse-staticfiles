# horse-staticfiles

Middleware for StaticFiles in HORSE

Sample Horse Server to serve static files
```delphi
uses
  Horse,
  Horse.StaticFiles;

begin
  THorse.Use('/static', HorseStaticFile('.\static', ['index.html']))
  THorse.Listen;
end;
```
