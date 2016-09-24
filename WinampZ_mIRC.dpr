library WinampZ_mIRC;

uses
  SysUtils,
  Windows, Messages,
  Classes, vSystem;

const
  WAUM_PLAYLIST_GETINDEX = 125;
  WAUM_PLAYLIST_WRITE = 120;

function WA_Handle: HWND;
begin
  result := FindWindow('Winamp v1.x', nil);
end;

function WA_IsRunning: Boolean;
begin
  Result := (WA_Handle <> 0);
end;

function WA_GetPlaylistIndex: Integer;
begin
  Result := SendMessage(WA_Handle,WM_USER,0,WAUM_PLAYLIST_GETINDEX)+1;
end;

function WA_PlaylistSave: Longword;
begin
  Result := SendMessage(WA_Handle,WM_USER,0,WAUM_PLAYLIST_WRITE);
end;

function WA_GetTrackFile: String;
var
  pos,i: Integer;
  pls,cfg: TStringList;
begin

  pls := TStringList.Create;
  cfg := TStringList.Create;

  if not WA_IsRunning then
  begin
    result := ' "<< Winamp is not running >>" ';
    exit;
  end;

  WA_PlaylistSave;
  pos := WA_GetPlaylistIndex-1;

  if vFileExists(GetCurrentDir+'\WinampZ.cfg') then begin
    cfg.loadFromFile(GetCurrentDir+'\WinampZ.cfg');
  end else begin
    result := ' "<< WinampZ.cfg does not exist >>" ';
  end;

  if vFileExists(cfg.values['WinampDir']+'\winamp.m3u') then begin
    pls.LoadFromFile( cfg.values['WinampDir']+'\winamp.m3u' );
  end else begin
    result := ' "<< WinampDir\winamp.m3u invalid >>" ';
  end;

  i := 0;
  while i < pls.Count do
  begin
    // remove comments and null lines
    // TODO : trim pls[i] before hand, to take care of ' # my comment.. ' or even tabs in front of the comment, dunno what the m3u spec is like exactly 
    if (pls[i] <> '') and (copy(pls[i],1,1) = '#') then begin
      pls.Delete(i);
    end;
    i := i + 1;
  end;

  Result := pls[pos + 1];

  pls.free;
  cfg.free;
end;

function WA_GetTitle: String;
var
  hWinamp: HWND;
  t: PChar;
  szTitle: String;
  Fnd1,Fnd2: Integer;
begin
  // find the winamp handle
  hWinamp := WA_HANDLE;
  if hWinamp <> 0 then
  begin
    // get the caption of the winamp window
    GetWindowText(hWinamp, t, 1024);
    szTitle := StrPas(t);

    if szTitle <> '' then
  	begin

      // TODO : ODD : if I dont use Fnd1 and Fnd2 as seperate things, mIRC crashes
      // (2003-01-27) DUH, THERE ARE PCHAR'S SOMEWHERE HERE, PCHAR should not be TOUCHED, always copied to string then manipulated

      // kill - Winamp and any [Stopped] [Paused] crap after it
      Fnd1 := Pos('- Winamp', szTitle);
      if Fnd1 <> 0 then
        Delete(szTitle, Fnd1, Length(szTitle));

      // kill the playlist number
      Fnd2 := Pos('.', szTitle);
      if Fnd2 <> 0 then
        Delete(szTitle, 1, Fnd2+1);

      // remove any trailing spaces
      SzTitle := Trim(szTitle);
      result := szTitle;

    end
	  else
      result := '';
  end
  else
    result := '';
end;

//==============================================================================
function GetTrackFile( mWnd: hWnd; aWnd: hWnd; Data: PChar; Parms: PChar; Show: Boolean; NoPause: Boolean ): Integer;export;stdcall;
begin
  result:=3;
  try
    strcopy(data, PChar('"'+WA_GetTrackFile+'"'));
  except
    on e : Exception do begin
      strcopy(data, PChar(' "<< Exception : ' + e.message +  ' >>" ') );
      exit;
    end;
  end;
end;

function GetTitle( mWnd: hWnd; aWnd: hWnd; Data: PChar; Parms: PChar; Show: Boolean; NoPause: Boolean ): Integer;export;stdcall;
begin
  result:=3;
  try
    strcopy(data, PChar(WA_GetTitle));
  except
    on e : Exception do begin
      strcopy(data, PChar(' "<< Exception : ' + e.message +  ' >>" ') );
      exit;
    end;
  end;
end;

exports
GetTrackFile, GetTitle;

end.

