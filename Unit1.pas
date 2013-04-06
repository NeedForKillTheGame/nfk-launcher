unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdAntiFreezeBase, IdAntiFreeze, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, StdCtrls, xmldom, XMLIntf,
  msxmldom, XMLDoc, IniFiles, ComCtrls, ShellAPI, Menus, ExtCtrls;

type


  TModInfo = record
    Name: String[30];
    Caption: String[30];
    ModDll: String[30];
    ModExe: String[30];
    Version: String[30];
    Update: Integer;
    Path: String;
  end;

  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    IdHTTP1: TIdHTTP;
    IdAntiFreeze1: TIdAntiFreeze;
    XMLDocument1: TXMLDocument;
    ProgressBar1: TProgressBar;
    MainMenu1: TMainMenu;
    Mods1: TMenuItem;
    Launcher1: TMenuItem;
    Autostart1: TMenuItem;
    Exit1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    NFK1: TMenuItem;
    Timer1: TTimer;
    StartNFK1: TMenuItem;
    N1: TMenuItem;
    Community1: TMenuItem;
    ools1: TMenuItem;
    NFKSite1: TMenuItem;
    NFKStatistics1: TMenuItem;
    NFKChat1: TMenuItem;
    Setup1: TMenuItem;
    PlanetScanner1: TMenuItem;
    Editor1: TMenuItem;
    Readme1: TMenuItem;
    function AddMsg(Msg: string):integer;
    function DownloadFile(RFile,CFile:string; NotMsg:Boolean = False):boolean;
    procedure IdHTTP1Work(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCount: Integer);
    procedure IdHTTP1WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCountMax: Integer);
    procedure IdHTTP1WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
    procedure FormCreate(Sender: TObject);
    procedure LauchUpdate;
    procedure Button1Click(Sender: TObject);
    procedure CheckName;
    procedure CheckAaa;
    procedure GetXML;
    procedure DoFileDownload(FName, CFile, FDir, FUrl:String);
    procedure DoFileDelete(FName,FDir:String);
    procedure DoFileRename(FName,FDir,NFName:String);
    procedure DoFolderCreate(FName,FDir:String);
    procedure DoFolderRename(FName,FDir,NFName:String);
    procedure DoFolderDelete(FName,FDir:String);
    procedure StartUpdate(Node2:IXMLNodeList; Dir:ShortString = '');
    procedure ScanDir(StartDir: string);
    procedure FindMods;
    procedure CancelAutoStart;
    procedure ModClick(Sender: TObject);
    procedure Memo1Click(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Launcher1Click(Sender: TObject);
    procedure Mods1Click(Sender: TObject);
    procedure Help1Click(Sender: TObject);
    procedure Autostart1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Memo1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Memo1KeyPress(Sender: TObject; var Key: Char);
    procedure NFKSite1Click(Sender: TObject);
    procedure NFKStatistics1Click(Sender: TObject);
    procedure NFKChat1Click(Sender: TObject);
    procedure Setup1Click(Sender: TObject);
    procedure PlanetScanner1Click(Sender: TObject);
    procedure Editor1Click(Sender: TObject);
    procedure Readme1Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

function GetFileSize(FileName: String): Integer;
function CheckConnection(const RemoteHost: string; const RemotePort: integer): boolean;
function FullRemoveDir(Dir: string; DeleteAllFilesAndFolders,
          StopIfNotAllDeleted, RemoveRoot: boolean): Boolean;

Const
  xml = 'nfkupdate.xml';

var
  Form1: TForm1;
  UpdateVer, TRXModVer, PQRModVer: Integer;
  CurFile: String;
  UpdateSelf : Boolean = False;
  Params: string;
  Error: boolean = False;
  NFKDir: string;
  GameExe: string;
  Host: string;
  URLPath: string;
  ConnTO: Integer = 1500; // time out
  PQRMod: boolean;
  TRXMod: byte = 0;
  ModList: array of TModInfo;
  GameMod: TModInfo;
  ForceMod: boolean;
  AutoRun: Boolean;

implementation

{$R *.dfm}

function TForm1.AddMsg(Msg: string):integer;
begin
  Memo1.Lines.Add(Msg);
  Result:=Memo1.Lines.Count;
  if Result>12 then Memo1.ScrollBars:=ssVertical;
end;

procedure TForm1.GetXML;
var LoadStream: TMemoryStream;
begin
  IdHTTP1.Tag:=1;
  XMLDocument1.Tag:=0;
  LoadStream := TMemoryStream.Create;
  try
    IdHTTP1.Get('http://'+Host+URLPath+xml, LoadStream);
  except
    on E : EIDHttpProtocolException do
      begin
        if E.ReplyErrorCode = 404 then begin
          AddMsg('Error: 404: xml file not found.');
          Button1.Enabled:=True;
          Exit;
        end else AddMsg('Error: '+IntToStr(E.ReplyErrorCode));
      end;
    on E: Exception do
      begin
        AddMsg('Error: Update server not available. ('+E.Message+')');
        LoadStream.Free;
        Button1.Enabled:=True;
        Exit;
      end;
  end;
  XMLDocument1.LoadFromStream(LoadStream);
  XMLDocument1.Tag:=1;
end;

function TForm1.DownloadFile(RFile,CFile:string; NotMsg:Boolean = False):boolean;
var LoadStream: TMemoryStream;
begin
  Result:=True;
  if (RFile = '') or (CFile = '') then begin
    AddMsg('Error: Empty file name.');
    Result:=False;
    Exit;
  end;
  LoadStream := TMemoryStream.Create;
  if NotMsg then IdHTTP1.Tag:=1 else IdHTTP1.Tag:=0;
  try
    IdHTTP1.Get('http://'+Host+URLPath+RFile, LoadStream);
  except
    on E : EIDHttpProtocolException do
      begin
        if E.ReplyErrorCode = 404 then begin
          AddMsg('Error: 404: File not found.');
          AddMsg('http://'+Host+URLPath+RFile);
          Button1.Enabled:=True;
        end else AddMsg('Error: '+IntToStr(E.ReplyErrorCode));
        //AddMsg('Update break.');
        Result:=False;
        LoadStream.Free;
        Button1.Enabled:=True;
        Exit;
      end;
    on E: Exception do
      begin
        AddMsg('Error: Update server not available. ('+E.Message+')');
        LoadStream.Free;
        Result:=False;
        Button1.Enabled:=True;
        Exit;
      end;
  end;
  if (CFile = NFKDir+'Launcher.exe') then begin CFile:=CFile+'_'; UpdateSelf:=True;  end;

  if LoadStream.Size <= 1 then begin
    AddMsg('Error: Load stream size error');
    Result:=False;
    LoadStream.Free;
    Button1.Enabled:=True;
    Exit;
  end;
  try
    LoadStream.SaveToFile(CFile);
  except
    on E: Exception do
      begin
        AddMsg('Error: Error saving file. ('+E.Message+')');
        Result:=False;
        Button1.Enabled:=True;
        LoadStream.Free;
        Exit;
      end;
  end;
  if not FileExists(CFile) then begin
        AddMsg('Error: File not found ('+CFile+')');
        Result:=False;
        Button1.Enabled:=True;
        LoadStream.Free;
        Exit;
  end;
  if LoadStream.Size <> GetFileSize(CFile) then begin
        AddMsg('Error: File size does not match ('+CFile+')');
        Result:=False;
        Button1.Enabled:=True;
        LoadStream.Free;
        Exit;
  end;
  LoadStream.Free;
end;


procedure TForm1.IdHTTP1Work(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCount: Integer);
begin
  ProgressBar1.Position:=AWorkCount;
end;

procedure TForm1.IdHTTP1WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCountMax: Integer);
var KByte: Real;
begin
  ProgressBar1.Position:=0;
  ProgressBar1.max:=AWorkCountMax;
  KByte:=AWorkCountMax/1024;
  if IdHTTP1.Tag=0 then AddMsg('Downloading: '+CurFile+' ('+IntToStr(Round(KByte))+' Kb)');
end;

procedure TForm1.IdHTTP1WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
begin
  CurFile:='';
  ProgressBar1.Position:=0;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
    Node : IXMLNodeList;
    Node2 : IXMLNodeList;
    Root : IXMLNode;
    i,k : integer;
    Ini: TIniFile;
    //FName, FDir, FUrl, NFName: String;
    LastVer{, LastPQRModVer, LastTRXVer} : Integer;
    SelfUpd, UpdatesFound: boolean;
begin
  URLPath:='/files/update/';
  NFKDir:=ExtractFilePath(Application.ExeName); // Ex.: C:\NFK\
  SelfUpd:=False;
  ForceMod:=False;
  // Перехват параметров
  for i:=1 to ParamCount do begin
    if Copy(ParamStr(i),1,6) = 'nfk://' then Continue; // пропускаем лишнее
    if (ParamStr(i) = '+selfupd') then begin SelfUpd:=True; Continue; end;
    if (ParamStr(i) = '+connect') and (Copy(ParamStr(i+1),1,6) = 'nfk://') then begin
      Params:=Params+' +connect '+Copy(ParamStr(i+1),7,Length(ParamStr(i+1))-7);
    end else if ParamStr(i) = '+game' then begin
      ForceMod:=True;
      Params:=Params+' '+ParamStr(i);
    end else
      Params:=Params+' '+ParamStr(i);
  end;

  Memo1.Lines.Clear;
     // Mods
  // Ищем установленные моды

  FindMods;

  if GameMod.Name = '' then begin
    NFK1.Checked := True;
  end else begin
    Button1.Caption:='Start NFK ('+GameMod.Caption+')';
  end;

  AutoRun:=False;

  Ini:=TIniFile.Create(NFKDir+'basenfk\nfksetup.ini');
  Autostart1.Checked := Ini.ReadBool('LAUNCHER', 'AutoStart', True);
  Ini.Free;

  Form1.Caption:='NFK Launcher '+Params;
  Form1.Show;

  HideCaret(Memo1.Handle);


  if FileExists(NFKDir+xml) then DeleteFile(NFKDir+xml);  // уже не нужно...
  if FileExists(NFKDir+'update.bat') then DeleteFile(NFKDir+'update.bat');


  // доп. проверки
  if FileExists(NFKDir+'NFK.exe') then GameExe:='NFK.exe' else
    if FileExists(NFKDir+'Game.dat') then GameExe:='Game.dat' else
      if FileExists(NFKDir+'ENGINE.dat') then GameExe:='ENGINE.dat' else begin
        ShowMessage('Error: Game file not found!');
        Application.Terminate;
        Exit;
    end;
  if not DirectoryExists(NFKDir+'basenfk') then begin
    ShowMessage('Error: BASENFK not found!');
    Application.Terminate;
    Exit;
  end;

  // Ищем установленные моды
 // if DirectoryExists(NFKDir+'pqrmod') then PQRMod:=True;
  //if DirectoryExists(NFKDir+'BOTS') then TRXMod:=True;
  
  if Length(ModList) > 0 then
    for k := Low(ModList) to High(ModList) do
      if ModList[k].Caption = 'Tribes-X' then begin
        TRXMod:=k;
        TRXModVer:=ModList[k].Update;
        Break;
      end;

  // получаем текущую версию
  Ini:=TIniFile.Create(NFKDir+'basenfk\nfksetup.ini');
  UpdateVer := Ini.ReadInteger('LAUNCHER','Update',33);
  //if PQRMod then PQRModVer := Ini.ReadInteger('LAUNCHER','PQRMod',1);
  //if TRXMod then TRXModVer := Ini.ReadInteger('LAUNCHER','Tribes-X',1);
  Ini.Free;



  AddMsg('Welcome to NFK 0.77.');
  if SelfUpd then AddMsg('Launcher sucessful updated!');
  AddMsg('Checking for updates...');

  // генерируем ник, если это player...
  CheckName;
  CheckAaa;

  // проверка серверов с обновлениями на доступность
  if CheckConnection('nfk.pro2d.ru',80) then
    Host:='nfk.pro2d.ru'
  else if CheckConnection('nfk.nx0.ru',80) then
    Host:='nfk.nx0.ru'
  else begin
    AddMsg('Error: Update server not available.');
    Button1.Enabled:=True;
    Exit;
  end;

  // получаем список с обновлениями
  GetXML;

  UpdatesFound:=False;
  
  // обрабатываем его
  if XMLDocument1.Tag <> 0 then begin
	  XMLDocument1.Active := true;
	  Root:=XMLDocument1.DocumentElement;
	  Node:=Root.ChildNodes;
    try
      LastVer:=StrToInt(Node.Nodes['lastver'].Text);
{      if PQRMod then LastPQRModVer:=StrToInt(Node.Nodes['pqrmod_lastver'].Text);
      if TRXMod then LastPQRModVer:=StrToInt(Node.Nodes['trxmod_lastver'].Text); }
    except
      on E: Exception do
        begin
          AddMsg('Error: ('+E.Message+')');
          XMLDocument1.Active := False;
          Button1.Enabled:=True;
          Exit;
        end;
    end;

    // если есть обновления, то загружаем
 	  if UpdateVer < LastVer then begin
      UpdatesFound:=True;
		  AddMsg('Updates found! Download...');
		  for i := 0 to Node.Count-1 do begin
		    Node2:=Node.Nodes[i].ChildNodes;
        if Error then Break;
        // работа с файлами
		    if Node.Nodes[i].NodeName = 'files' then begin
			    if StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])) > UpdateVer then
            StartUpdate(Node2,NFKDir);
			      if not Error then begin
              Ini:=TIniFile.Create(NFKDir+'basenfk\nfksetup.ini');
              Ini.WriteInteger('LAUNCHER','Update',StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])));
              Ini.Free;
            end;
        end;
       { if PQRMod then
		    if Node.Nodes[i].NodeName = 'pqrmod' then begin
			    if StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])) > PQRModVer then
			      StartUpdate(Node2);
			      if not Error then begin
              Ini:=TIniFile.Create(NFKDir+'basenfk\nfksetup.ini');
              Ini.WriteInteger('LAUNCHER','PQRMod',StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])));
              Ini.Free;
            end;
        end;
        if TRXMod then
		    if Node.Nodes[i].NodeName = 'trxmod' then begin
			    if StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])) > TRXModVer then
			      StartUpdate(Node2);
			      if not Error then begin
              Ini:=TIniFile.Create(NFKDir+'basenfk\nfksetup.ini');
              Ini.WriteInteger('LAUNCHER','Tribes-X',StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])));
              Ini.Free;
            end;
        end;   }
          // обновление завершено

          if UpdateSelf then begin
            XMLDocument1.Active := False;
            LauchUpdate;
            Exit;
          end;
		  end;
		  if not Error then AddMsg('NFK sucessful updated!');
	  end;

    if TRXMod <> 0 then
    for i := 0 to Node.Count-1 do begin
      Node2:=Node.Nodes[i].ChildNodes;
      if Node.Nodes[i].NodeName = 'trxmod' then begin
			  if StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])) > TRXModVer then begin
          UpdatesFound:=True;
			    StartUpdate(Node2,ModList[TRXMod].Path);
          if not Error then begin
            Ini:=TIniFile.Create(ModList[TRXMod].Path+'\'+'Mod.nfo');
            Ini.WriteInteger('MOD_INFO','update',StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])));
            Ini.Free;
            AddMsg('Tribes-X mod sucessful updated!');
          end;
        end;
      end;
    end;



    if not UpdatesFound then begin
      AddMsg('Updates not found.');
      if Autostart1.Checked then AutoRun:=True;
    end;

	  XMLDocument1.Active := False;
	  if FileExists(NFKDir+xml) then DeleteFile(NFKDir+xml);
    if SelfUpd then AutoRun:=False;
  end else AddMsg('Error: Update failed!');
  Button1.Enabled:=True;
  Timer1.Enabled := True;
end;

procedure TForm1.LauchUpdate;
var f: TextFile;
begin
  AddMsg('Lancher update begin');
  AssignFile(f,NFKDir+'update.bat');
  ReWrite(f);
  WriteLn(f,'@echo off');
  WriteLn(f,'del "'+NFKDir+'Launcher.exe"');
  WriteLn(f,'rename "'+NFKDir+'Launcher.exe_" Launcher.exe');
  WriteLn(f,'start "" "'+NFKDir+'Launcher.exe" '+Params+' +selfupd');
  CloseFile(f);
  ShellExecute(Application.Handle,'Open',PChar(NFKDir+'update.bat'),'','',sw_Hide);
 // WinExec(PChar(NFKDir+GameExe+' '+Params),SW_HIDE);
  Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
{var
  StartUpInfo: TSTARTUPINFO;
  ProcessInfo: TPROCESSINFORMATION;   }
begin
  //if TRXMod then Params:=Params+' +game BOTS';
  if not ForceMod and (GameMod.Name <> '') and (GameMod.Name <> 'NFK') then begin
    Params:=Params+' +game Mods\'+GameMod.Name;
    if GameMod.ModExe <> '' then GameExe:=GameMod.ModExe;
    //if GameMod.ModDll <> '' then Params:=Params+' +dll '+GameMod.ModDll;
  end;
  WinExec(PChar(NFKDir+GameExe+' '+Params),SW_HIDE);
{  CreateProcess(PAnsiChar(GameMod.Path+'\'+GameExe),
                PAnsiChar(Params),
                nil,
                nil,
                False,
                NORMAL_PRIORITY_CLASS,
                nil,
                PAnsiChar(NFKDir),
                StartUpInfo,
                ProcessInfo);  }
  Application.Terminate;
end;

procedure TForm1.CheckName;
var ts: TStringList;
    i: integer;
    ROOTDIR: String;
    Changed: boolean;
begin
  Changed:=False;
  ROOTDIR:=NFKDir+'basenfk\';
  if not FileExists(ROOTDIR+'nfkconfig.cfg') then begin
    ShowMessage('Error: nfkconfig.cfg not found!');
    exit;
  end;
  ts := TStringList.Create;
  ts.LoadFromFile(ROOTDIR+'nfkconfig.cfg');
  for i := 0 to ts.Count - 1 do
    if LowerCase(ts[i]) = 'name player' then begin
      Randomize;
      ts[i]:='name player'+(IntToStr(Random(998)+1));
      Changed:=True;
    end;
  if Changed then ts.SaveToFile(ROOTDIR+'nfkconfig.cfg');
  ts.Free;
end;

procedure TForm1.CheckAaa;
var ts: TStringList;
    i: integer;
    ROOTDIR: String;
    Found: boolean;
begin
  Found:=False;
  ROOTDIR:=NFKDir+'basenfk\';
  if not FileExists(ROOTDIR+'autoexec.cfg') then begin
    ShowMessage('Error: autoexec.cfg not found!');
    exit;
  end;
  ts := TStringList.Create;
  ts.LoadFromFile(ROOTDIR+'autoexec.cfg');
  for i := 0 to ts.Count - 1 do
    if LowerCase(ts[i]) = 'aaa' then begin
      Found:=True;
    end;
  if not Found then begin
    ts.Add('aaa');
    ts.SaveToFile(ROOTDIR+'autoexec.cfg');
  end;
  ts.Free;
end;

function CheckConnection(const RemoteHost: string; const RemotePort: integer): boolean;
var Conn: TIdTCPClient;
begin
  Result := True;
  Conn:=TIdTCPClient.Create(nil);
  Conn.Host := RemoteHost;
  Conn.Port := RemotePort;
  try
    Conn.Connect(1500);
  except
    Result := False;
  end;

end;

function FullRemoveDir(Dir: string; DeleteAllFilesAndFolders,
  StopIfNotAllDeleted, RemoveRoot: boolean): Boolean;
var
  i: Integer;
  SRec: TSearchRec;
  FN: string;
begin
  Result := False;
  if not DirectoryExists(Dir) then
    exit;
  Result := True;
  // Добавляем слэш в конце и задаем маску - "все файлы и директории"
  //Dir := IncludeTrailingBackslash(Dir);
  i := FindFirst(Dir + '*', faAnyFile, SRec);
  try
    while i = 0 do
    begin
      // Получаем полный путь к файлу или директорию
      FN := Dir + SRec.Name;
      // Если это директория
      if SRec.Attr = faDirectory then
      begin
        // Рекурсивный вызов этой же функции с ключом удаления корня
        if (SRec.Name <> '') and (SRec.Name <> '.') and (SRec.Name <> '..') then
        begin
          //if DeleteAllFilesAndFolders then
          //  FileSetAttr(FN, faArchive);
          Result := FullRemoveDir(FN, DeleteAllFilesAndFolders,
            StopIfNotAllDeleted, True);
          if not Result and StopIfNotAllDeleted then
            exit;
        end;
      end
      else // Иначе удаляем файл
      begin
        //if DeleteAllFilesAndFolders then
        //  FileSetAttr(FN, faArchive);
        Result := SysUtils.DeleteFile(FN);
        if not Result and StopIfNotAllDeleted then
          exit;
      end;
      // Берем следующий файл или директорию
      i := FindNext(SRec);
    end;
  finally
    SysUtils.FindClose(SRec);
  end;
  if not Result then
    exit;
  if RemoveRoot then // Если необходимо удалить корень - удаляем
    if not RemoveDir(Dir) then
      Result := false;
end;


procedure TForm1.DoFileDownload(FName, CFile, FDir, FUrl: String);
begin
  CurFile:=CFile;
                if not DirectoryExists(FDir) then if CreateDir(FDir) then begin
                  AddMsg(FDir+' folder created.');
                end else AddMsg(FDir+' folder create error '+IntToStr(GetLastError));
				        if not DownloadFile(FUrl+FName,FDir+FName) then begin
                  AddMsg('Update failed.');
                  XMLDocument1.Active := False;
                  Button1.Enabled:=True;
                  Error:=True;
                  Exit;
                end;
end;

procedure TForm1.DoFileDelete(FName, FDir: String);
begin
                if FileExists(FDir+FName) then if DeleteFile(FDir+FName) then
                  AddMsg(FName+' deleted.');
end;

procedure TForm1.DoFileRename(FName, FDir, NFName: String);
begin

                if FileExists(FDir+FName) then if RenameFile(FDir+FName,FDir+NFName) then begin
                  AddMsg(FName+' renamed to '+NFName);
                end else AddMsg(FName+' renaming error '+IntToStr(GetLastError));
end;

procedure TForm1.DoFolderCreate(FName, FDir: String);
begin
                if not DirectoryExists(FDir+FName) then if CreateDir(FDir+FName) then begin
                  AddMsg(FName+' folder created.');
                end else AddMsg(FName+' folder create error '+IntToStr(GetLastError));
end;

procedure TForm1.DoFolderRename(FName, FDir, NFName: String);
begin
                if RenameFile(FDir+FName,FDir+NFName) then begin
                  AddMsg(FName+' renamed to '+NFName);
                end else AddMsg(FName+' renaming error '+IntToStr(GetLastError));
end;

procedure TForm1.DoFolderDelete(FName, FDir: String);
begin
                if DirectoryExists(FDir+FName) then if FullRemoveDir(FDir+FName+'\', True, True, True) then begin
                  AddMsg(FName+' folder deleted.');
                end else AddMsg(FName+' folder delete error '+NFKDir+FDir+FName+' - '+IntToStr(GetLastError));
end;

procedure TForm1.StartUpdate(Node2: IXMLNodeList; Dir: ShortString = '');
var k:byte;
begin
  if Dir[Length(Dir)] <> '\' then
    Dir := Dir + '\';
			      for k := 0 to Node2.Count-1 do begin
              // скачать файл
				      if Node2.Nodes[k].NodeName = 'file' then begin
                DoFileDownload(Node2.Nodes[k].Text,Node2.Nodes[k].Text,
                    Dir+VarToStr(Node2.Nodes[k].Attributes['dir']),
                    VarToStr(Node2.Nodes[k].Attributes['url']));
				      end;
              // удалить файл
              if Node2.Nodes[k].NodeName = 'delete' then begin
                DoFileDelete(Node2.Nodes[k].Text,Dir+VarToStr(Node2.Nodes[k].Attributes['dir']));
              end;
              // переименовать файл
              if Node2.Nodes[k].NodeName = 'rename' then begin
                DoFileRename(Node2.Nodes[k].Text,Dir+VarToStr(Node2.Nodes[k].Attributes['dir']),
                    VarToStr(Node2.Nodes[k].Attributes['newname']));
              end;
              // создать папку
              if Node2.Nodes[k].NodeName = 'crdir' then begin
                DoFolderCreate(Node2.Nodes[k].Text,Dir+VarToStr(Node2.Nodes[k].Attributes['dir']));
              end;
              // переименовать папку
              if Node2.Nodes[k].NodeName = 'rendir' then begin
                DoFolderRename(Node2.Nodes[k].Text,Dir+VarToStr(Node2.Nodes[k].Attributes['dir']),
                    VarToStr(Node2.Nodes[k].Attributes['newname']));
              end;
              // удалить папку
              if Node2.Nodes[k].NodeName = 'remdir' then begin
                DoFolderDelete(Node2.Nodes[k].Text,Dir+VarToStr(Node2.Nodes[k].Attributes['dir']));
              end;
            end;
end;


procedure TForm1.ScanDir(StartDir: string);
var
  SearchRec: TSearchRec;
    ini: TIniFile;
    Item: TMenuItem;
    n: Byte;
    Mask: string;
    ModFound: boolean;
begin

  Mask := '*.*';
  if StartDir[Length(StartDir)] <> '\' then
    StartDir := StartDir + '\';

  Ini:=TIniFile.Create(NFKDir+'basenfk\nfksetup.ini');
  GameMod.Name := Ini.ReadString('LAUNCHER','Mod','');;
  Ini.Free;
  ModFound:=False;
  SetLength(ModList, 1);
  ModList[0].Name := 'NFK';
  ModList[0].Caption := 'NFK';
 if DirectoryExists(NFKDir+'Mods') then begin
  if FindFirst(StartDir + Mask, faDirectory, SearchRec) = 0 then begin
    repeat Application.ProcessMessages;
      if (SearchRec.Name <> '..') and (SearchRec.Name <> '.')then
      if FileExists(StartDir + SearchRec.Name + '\' + 'Mod.nfo') then  begin
        Ini:=TIniFile.Create(StartDir + SearchRec.Name + '\' + 'Mod.nfo');
        if Ini.ReadString('MOD_INFO','name','') = '' then continue;
        SetLength(ModList, Length(ModList)+1);
        n:=High(ModList);
        ModList[n].Name := SearchRec.Name;
        ModList[n].Path := StartDir + SearchRec.Name + '\';
        ModList[n].Caption := Ini.ReadString('MOD_INFO','name','');
        ModList[n].ModDll := 'Mods\' + SearchRec.Name + '\' + Ini.ReadString('MOD_INFO','moddll','');
        ModList[n].ModExe := Ini.ReadString('MOD_INFO','modexe','');
        ModList[n].Version := Ini.ReadString('MOD_INFO','version','');
        ModList[n].Update := Ini.ReadInteger('MOD_INFO','update',1);
        Ini.Free;
        Item := TMenuItem.Create(self);
        Item.OnClick := ModClick;
        Item.Caption := ModList[n].Caption;
        Item.AutoCheck := True;
        Item.GroupIndex := 1;
        Item.RadioItem := True;
        if GameMod.Name = ModList[n].Name then begin
          Item.Checked := True;
          ModFound:=True;
          GameMod:=ModList[n];
        end;
        Mods1.Add(Item);
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
 end;
  if not ModFound then GameMod.Name := '';
end;

procedure TForm1.FindMods;
{var
    i:byte;
    Item: TMenuItem;
    List: TModInfo;  }
begin
    ScanDir(NFKDir+'Mods');
end;

procedure TForm1.ModClick(Sender: TObject);
var i : byte;
    ini : TIniFile;
begin
  (Sender as TMenuItem).Checked := True;
  i := Mods1.IndexOf(Sender as TMenuItem);
  if GameMod.Name <> ModList[i].Name then begin
    GameMod:=ModList[i];
    Ini:=TIniFile.Create(NFKDir+'basenfk\nfksetup.ini');
    Ini.WriteString('LAUNCHER','Mod',GameMod.Name);
    Ini.Free;
    AddMsg('Game Mod changed to ' + ModList[i].Caption);
    Button1.Caption:='Start NFK ('+ModList[i].Caption+')';
  end;
end;

procedure TForm1.Memo1Click(Sender: TObject);
begin
  CancelAutoStart;
end;

procedure TForm1.FormClick(Sender: TObject);
begin
  CancelAutoStart;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if AutoRun then
    if AutoStart1.Checked then Button1Click(Self);
  Timer1.Enabled := False;
end;

procedure TForm1.Launcher1Click(Sender: TObject);
begin
  CancelAutoStart;
end;

procedure TForm1.Mods1Click(Sender: TObject);
begin
  CancelAutoStart;
end;

procedure TForm1.Help1Click(Sender: TObject);
begin
  CancelAutoStart;
end;

procedure TForm1.Autostart1Click(Sender: TObject);
var
  ini : TIniFile;
begin
  Ini:=TIniFile.Create(NFKDir+'basenfk\nfksetup.ini');
  Ini.WriteBool('LAUNCHER', 'AutoStart', Autostart1.Checked);
  Ini.Free;
  if Autostart1.Checked then AddMsg('Autostart Enabled.') else AddMsg('Autostart Disabled.');
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.About1Click(Sender: TObject);
begin
ShowMessage('On any questions please contact pff-clan@mail.ru,'+#10#13+'or IRC channel irc.wenet.ru #nfk'+#10#13+
            #10#13+
            'Author: coolant'+#10#13+
            'Version: 1.2.6');
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  CancelAutoStart;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  CancelAutoStart;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  CancelAutoStart;
end;

procedure TForm1.Memo1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  CancelAutoStart;
end;

procedure TForm1.CancelAutoStart;
begin
  if AutoRun then begin
    AutoRun:=False;
    AddMsg('Autostart canceled');
  end;
end;

procedure TForm1.Memo1KeyPress(Sender: TObject; var Key: Char);
begin
  CancelAutoStart;
end;

function GetFileSize(FileName: String): Integer;
var
  FS: TFileStream;
begin
  try
    FS := TFileStream.Create(Filename, fmOpenRead);
  except
    Result := -1;
    Exit;
  end;
  Result := FS.Size;
  FS.Free;
end;

procedure TForm1.NFKSite1Click(Sender: TObject);
begin
  ShellExecute(0, 'open', 'http://needforkill.ru', nil, nil, SW_SHOW);
end;

procedure TForm1.NFKStatistics1Click(Sender: TObject);
begin
  ShellExecute(0, 'open', 'http://nfk.pro2d.ru', nil, nil, SW_SHOW);
end;

procedure TForm1.NFKChat1Click(Sender: TObject);
begin
  ShellExecute(0, nil, PChar('nfkchat.exe'), nil, nil, SW_SHOW);
end;

procedure TForm1.Setup1Click(Sender: TObject);
begin
  ShellExecute(0, nil, PChar('Setup.exe'), nil, nil, SW_SHOW);
end;

procedure TForm1.PlanetScanner1Click(Sender: TObject);
begin
  ShellExecute(0, nil, PChar('PlanetScanner.exe'), nil, nil, SW_SHOW);
end;

procedure TForm1.Editor1Click(Sender: TObject);
begin
  ShellExecute(0, nil, PChar('Editor\Editor.exe'), nil, nil, SW_SHOW);
end;

procedure TForm1.Readme1Click(Sender: TObject);
begin
  ShellExecute(0, 'open', 'HELP\nfk_help070.htm', nil, nil, SW_SHOW);
end;

end.
