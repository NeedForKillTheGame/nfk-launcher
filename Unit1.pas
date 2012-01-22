unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdAntiFreezeBase, IdAntiFreeze, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, StdCtrls, xmldom, XMLIntf,
  msxmldom, XMLDoc, IniFiles, ComCtrls, ShellAPI;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    IdHTTP1: TIdHTTP;
    IdAntiFreeze1: TIdAntiFreeze;
    XMLDocument1: TXMLDocument;
    ProgressBar1: TProgressBar;
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
    procedure GetXML;
    procedure DoFileDownload(FName, CurFile, FDir, FUrl:String);
    procedure DoFileDelete(FName,FDir:String);
    procedure DoFileRename(FName,FDir,NFName:String);
    procedure DoFolderCreate(FName,FDir:String);
    procedure DoFolderRename(FName,FDir,NFName:String);
    procedure DoFolderDelete(FName,FDir:String);
    procedure StartUpdate(Node2:IXMLNodeList);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

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
  PQRMod, TRXMod: boolean;

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
        Result:=False;
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
  if (CFile = NFKDir+'Launcher.exe') then begin CFile:=CFile+'_'; UpdateSelf:=True; end;
  try
    LoadStream.SaveToFile(CFile);
  except
    on E: Exception do
      begin
        AddMsg('Error: Error saving file. ('+E.Message+')');
      end;
  end;
  if not FileExists(CFile) then AddMsg('Error '+CFile);
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
    AutoRun: Boolean;
    LastVer, LastPQRModVer, LastTRXVer : Integer;
    SelfUpd: boolean;
begin
  URLPath:='/files/update/';
  NFKDir:=ExtractFilePath(Application.ExeName); // Ex.: C:\NFK\
  SelfUpd:=False;
  // Перехват параметров
  for i:=1 to ParamCount do begin
    if Copy(ParamStr(i),1,6) = 'nfk://' then Continue; // пропускаем лишнее
    if (ParamStr(i) = '+selfupd') then begin SelfUpd:=True; Continue; end;
    if (ParamStr(i) = '+connect') and (Copy(ParamStr(i+1),1,6) = 'nfk://') then begin
      // свой обработчик для +connect
      Params:=Params+' +connect '+Copy(ParamStr(i+1),7,Length(ParamStr(i+1))-7);
    end else
      Params:=Params+' '+ParamStr(i);
  end;
  AutoRun:=False;
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
  if DirectoryExists(NFKDir+'pqrmod') then PQRMod:=True;
  if DirectoryExists(NFKDir+'BOTS') then TRXMod:=True;

  // получаем текущую версию
  Ini:=TIniFile.Create(NFKDir+'basenfk\nfksetup.ini');
  UpdateVer := Ini.ReadInteger('NFK_VERSION','Update',1);
  if PQRMod then PQRModVer := Ini.ReadInteger('NFK_VERSION','PQRMod',1);
  if TRXMod then TRXModVer := Ini.ReadInteger('NFK_VERSION','Tribes-X',1);
  Ini.Free;

  Memo1.Lines.Clear;

  AddMsg('Welcome to NFK 0.76.');
  if SelfUpd then AddMsg('Launcher sucessful updated!');
  AddMsg('Checking for updates...');

  // генерируем ник, если это player...
  CheckName;

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

  // обрабатываем его
  if XMLDocument1.Tag <> 0 then begin
	  XMLDocument1.Active := true;
	  Root:=XMLDocument1.DocumentElement;
	  Node:=Root.ChildNodes;
    try
      LastVer:=StrToInt(Node.Nodes['lastver'].Text);
      if PQRMod then LastPQRModVer:=StrToInt(Node.Nodes['pqrmod_lastver'].Text);
      if TRXMod then LastPQRModVer:=StrToInt(Node.Nodes['trxmod_lastver'].Text);
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
		  AddMsg('Updates found! Download...');
		  for i := 0 to Node.Count-1 do begin
		    Node2:=Node.Nodes[i].ChildNodes;
        // работа с файлами
        if not TRXMod then
		    if Node.Nodes[i].NodeName = 'files' then begin
			    if StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])) > UpdateVer then
            StartUpdate(Node2);
			      if not Error then begin
              Ini:=TIniFile.Create(NFKDir+'basenfk\nfksetup.ini');
              Ini.WriteInteger('NFK_VERSION','Update',StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])));
              Ini.Free;
            end;
        end;
        if PQRMod then
		    if Node.Nodes[i].NodeName = 'pqrmod' then begin
			    if StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])) > PQRModVer then
			      StartUpdate(Node2);
			      if not Error then begin
              Ini:=TIniFile.Create(NFKDir+'basenfk\nfksetup.ini');
              Ini.WriteInteger('NFK_VERSION','PQRMod',StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])));
              Ini.Free;
            end;
        end;
        if TRXMod then
		    if Node.Nodes[i].NodeName = 'trxmod' then begin
			    if StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])) > TRXModVer then
			      StartUpdate(Node2);
			      if not Error then begin
              Ini:=TIniFile.Create(NFKDir+'basenfk\nfksetup.ini');
              Ini.WriteInteger('NFK_VERSION','Tribes-X',StrToInt(VarToStr(Node.Nodes[i].Attributes['ver'])));
              Ini.Free;
            end;
        end;
          // обновление завершено

          if UpdateSelf then begin
            XMLDocument1.Active := False;
            LauchUpdate;
            Exit;
          end;
		  end;
		  AddMsg('NFK sucessful updated!');
	  end else begin AddMsg('Updates not found.'); AutoRun:=True; end;
	  XMLDocument1.Active := False;
	  if FileExists(NFKDir+xml) then DeleteFile(NFKDir+xml);
    if SelfUpd then AutoRun:=False;
	  if AutoRun then Button1Click(Self);
  end else AddMsg('Error: Update failed!');
  Button1.Enabled:=True;
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
begin
  if TRXMod then Params:=Params+' +game BOTS';
  WinExec(PChar(NFKDir+GameExe+' '+Params),SW_HIDE);
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


procedure TForm1.DoFileDownload(FName, CurFile, FDir, FUrl: String);
begin
                if not DirectoryExists(NFKDir+FDir) then if CreateDir(NFKDir+FDir) then begin
                  AddMsg(FDir+' folder created.');
                end else AddMsg(FDir+' folder create error '+IntToStr(GetLastError));
				        if not DownloadFile(FUrl+FName,NFKDir+FDir+FName) then begin
                  AddMsg('Update failed.');
                  XMLDocument1.Active := False;
                  Button1.Enabled:=True;
                  Exit;
                end;
end;

procedure TForm1.DoFileDelete(FName, FDir: String);
begin
                if FileExists(NFKDir+FDir+FName) then if DeleteFile(NFKDir+FDir+FName) then
                  AddMsg(FName+' deleted.');
end;

procedure TForm1.DoFileRename(FName, FDir, NFName: String);
begin

                if FileExists(NFKDir+FDir+FName) then if RenameFile(NFKDir+FDir+FName,NFKDir+FDir+NFName) then begin
                  AddMsg(FName+' renamed to '+NFName);
                end else AddMsg(FName+' renaming error '+IntToStr(GetLastError));
end;

procedure TForm1.DoFolderCreate(FName, FDir: String);
begin
                if not DirectoryExists(NFKDir+FDir+FName) then if CreateDir(NFKDir+FDir+FName) then begin
                  AddMsg(FName+' folder created.');
                end else AddMsg(FName+' folder create error '+IntToStr(GetLastError));
end;

procedure TForm1.DoFolderRename(FName, FDir, NFName: String);
begin
                if RenameFile(NFKDir+FDir+FName,NFKDir+FDir+NFName) then begin
                  AddMsg(FName+' renamed to '+NFName);
                end else AddMsg(FName+' renaming error '+IntToStr(GetLastError));
end;

procedure TForm1.DoFolderDelete(FName, FDir: String);
begin
                if DirectoryExists(NFKDir+FDir+FName) then if FullRemoveDir(NFKDir+FDir+FName+'\', True, True, True) then begin
                  AddMsg(FName+' folder deleted.');
                end else AddMsg(FName+' folder delete error '+NFKDir+FDir+FName+' - '+IntToStr(GetLastError));
end;

procedure TForm1.StartUpdate(Node2: IXMLNodeList);
var k:byte;
begin
			      for k := 0 to Node2.Count-1 do begin
              // скачать файл
				      if Node2.Nodes[k].NodeName = 'file' then begin
                DoFileDownload(Node2.Nodes[k].Text,Node2.Nodes[k].Text,
                    VarToStr(Node2.Nodes[k].Attributes['dir']),
                    VarToStr(Node2.Nodes[k].Attributes['url']));
				      end;
              // удалить файл
              if Node2.Nodes[k].NodeName = 'delete' then begin
                DoFileDelete(Node2.Nodes[k].Text,VarToStr(Node2.Nodes[k].Attributes['dir']));
              end;
              // переименовать файл
              if Node2.Nodes[k].NodeName = 'rename' then begin
                DoFileRename(Node2.Nodes[k].Text,VarToStr(Node2.Nodes[k].Attributes['dir']),
                    VarToStr(Node2.Nodes[k].Attributes['newname']));
              end;
              // создать папку
              if Node2.Nodes[k].NodeName = 'crdir' then begin
                DoFolderCreate(Node2.Nodes[k].Text,VarToStr(Node2.Nodes[k].Attributes['dir']));
              end;
              // переименовать папку
              if Node2.Nodes[k].NodeName = 'rendir' then begin
                DoFolderRename(Node2.Nodes[k].Text,VarToStr(Node2.Nodes[k].Attributes['dir']),
                    VarToStr(Node2.Nodes[k].Attributes['newname']));
              end;
              // удалить папку
              if Node2.Nodes[k].NodeName = 'remdir' then begin
                DoFolderDelete(Node2.Nodes[k].Text,VarToStr(Node2.Nodes[k].Attributes['dir']));
              end;
            end;
end;

end.
