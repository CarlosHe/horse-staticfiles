unit Horse.StaticFiles;


{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IF DEFINED(FPC)}
  Generics.Collections,
  Classes,
  SysUtils,
  {$ELSE}
  System.Generics.Collections,
  System.Classes,
  System.SysUtils,
  {$ENDIF}
  Horse;

type

  { THorseStaticFileCallback }

  THorseStaticFileCallback = class
  public
    class function New: THorseStaticFileCallback;
  end;

  THorseStaticFileManager = class
  private
    FCallbackList: TObjectList<THorseStaticFileCallback>;
    class var FDefaultManager: THorseStaticFileManager;
    procedure SetCallbackList(const Value: TObjectList<THorseStaticFileCallback>);
  protected
    class function GetDefaultManager: THorseStaticFileManager; static;
  public
    constructor Create;
    destructor Destroy; override;
    property CallbackList: TObjectList<THorseStaticFileCallback> read FCallbackList write SetCallbackList;
    class destructor UnInitialize;
    class property DefaultManager: THorseStaticFileManager read GetDefaultManager;
  end;

function HorseStaticFile(APathRoot: string; const ADefaultFiles: TArray<string>): THorseCallback; overload;
procedure Middleware(AHorseRequest: THorseRequest; AHorseResponse: THorseResponse; ANext: {$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});

implementation

uses
  {$IF DEFINED(FPC)}
   fpmimetypes;
  {$ELSE}
  System.IOUtils,
  System.Net.Mime;
  {$ENDIF}

var
  PathRoot: string;
  DefaultFiles: TArray<string>;

function HorseStaticFile(APathRoot: string; const ADefaultFiles: TArray<string>): THorseCallback; overload;
var
  LHorseStaticFileCallback: THorseStaticFileCallback;
begin
  LHorseStaticFileCallback := THorseStaticFileCallback.Create;

  THorseStaticFileManager
    .DefaultManager
    .CallbackList
    .Add(LHorseStaticFileCallback);

  PathRoot := APathRoot;
  DefaultFiles := ADefaultFiles;

  Result := {$IF DEFINED(FPC)}@Middleware{$ELSE}Middleware{$ENDIF};
end;

procedure Middleware(AHorseRequest: THorseRequest;
  AHorseResponse: THorseResponse; ANext: TNextProc);
var
  LFileStream: TFileStream;
  LNormalizeFileName: string;
  {$IFNDEF FPC}
  LType: string;
  LKind: TMimeTypes.TKind;
  {$ENDIF}
  I: Integer;
begin
  LNormalizeFileName := AHorseRequest.RawWebRequest.PathInfo.TrimLeft(['/']);

  {$IFDEF FPC}
  LNormalizeFileName := LNormalizeFileName.Replace('/', PathDelim);
  LNormalizeFileName := ConcatPaths([PathRoot,LNormalizeFileName]);
  {$ELSE}
  LNormalizeFileName := LNormalizeFileName.Replace('/', TPath.DirectorySeparatorChar);
  LNormalizeFileName := TPath.Combine(PathRoot, LNormalizeFileName);
  {$ENDIF}

  {$IFDEF FPC}
  if DirectoryExists(LNormalizeFileName) or (Trim(ExtractFileName(LNormalizeFileName)) = EmptyStr)  then
  begin
    for I := Low(DefaultFiles) to High(DefaultFiles) do
    begin
      if FileExists(ConcatPaths([LNormalizeFileName, DefaultFiles[I]])) then
      begin
        LNormalizeFileName := ConcatPaths([LNormalizeFileName, DefaultFiles[I]]);
        Break;
      end;
    end;
  end;
  {$ELSE}
  if (TDirectory.Exists(LNormalizeFileName)) or (ExtractFileName(LNormalizeFileName).IsEmpty) then
  begin
    for I := Low(DefaultFiles) to High(DefaultFiles) do
    begin
      if TFile.Exists(TPath.Combine(LNormalizeFileName, DefaultFiles[I])) then
      begin
        LNormalizeFileName := TPath.Combine(LNormalizeFileName, DefaultFiles[I]);
        Break;
      end;
    end;
  end;
  {$ENDIF}

  {$IFDEF FPC}
  if FileExists(LNormalizeFileName) then
  {$ELSE}
  if TFile.Exists(LNormalizeFileName) then
  {$ENDIF}
  begin
    LFileStream := TFileStream.Create(LNormalizeFileName, fmShareDenyNone or fmOpenRead);
    try
      AHorseResponse.RawWebResponse.ContentStream := LFileStream;

      {$IFDEF FPC}
      MimeTypes.LoadKnownTypes;
      AHorseResponse.ContentType(MimeTypes.GetMimeType(ExtractFileExt(LNormalizeFileName)));
      {$ELSE}
      TMimeTypes.Default.GetFileInfo(LNormalizeFileName, LType, LKind);
      AHorseResponse.RawWebResponse.ContentType := LType;
      {$ENDIF}
      AHorseResponse.Status(THTTPStatus.OK);
      AHorseResponse.RawWebResponse.SendResponse;
      raise EHorseCallbackInterrupted.Create;
    finally
      LFileStream.Free;
    end;
  end;

  ANext();
end;

{ THorseStaticFileCallback }
class function THorseStaticFileCallback.New: THorseStaticFileCallback;
begin
  Result := Self.Create;
end;

{ THorseStaticFileManager }

constructor THorseStaticFileManager.Create;
begin
  FCallbackList := TObjectList<THorseStaticFileCallback>.Create(True);
end;

destructor THorseStaticFileManager.Destroy;
begin
  FCallbackList.Free;
  inherited;
end;

class function THorseStaticFileManager.GetDefaultManager: THorseStaticFileManager;
begin
  if FDefaultManager = nil then
    FDefaultManager := THorseStaticFileManager.Create;
  Result := FDefaultManager;
end;

procedure THorseStaticFileManager.SetCallbackList(const Value: TObjectList<THorseStaticFileCallback>);
begin
  FCallbackList := Value;
end;

class destructor THorseStaticFileManager.UnInitialize;
begin
  FreeAndNil(FDefaultManager);
end;

end.
