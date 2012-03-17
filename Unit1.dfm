object Form1: TForm1
  Left = 444
  Top = 345
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'NFK Launcher'
  ClientHeight = 247
  ClientWidth = 353
  Color = clBtnFace
  DefaultMonitor = dmDesktop
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poScreenCenter
  OnClick = FormClick
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnKeyUp = FormKeyUp
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 353
    Height = 185
    Align = alTop
    BevelEdges = []
    BevelInner = bvNone
    BevelOuter = bvNone
    Color = clNavy
    Ctl3D = False
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clYellow
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    Lines.Strings = (
      'Welcome to NFK 0.77.')
    ParentCtl3D = False
    ParentFont = False
    ReadOnly = True
    TabOrder = 0
    OnClick = Memo1Click
    OnKeyDown = Memo1KeyDown
    OnKeyPress = Memo1KeyPress
  end
  object Button1: TButton
    Left = 8
    Top = 208
    Width = 337
    Height = 33
    Caption = 'Start NFK'
    Enabled = False
    TabOrder = 1
    OnClick = Button1Click
  end
  object ProgressBar1: TProgressBar
    Left = 0
    Top = 185
    Width = 353
    Height = 17
    Align = alTop
    TabOrder = 2
  end
  object IdHTTP1: TIdHTTP
    MaxLineAction = maException
    ReadTimeout = 0
    OnWork = IdHTTP1Work
    OnWorkBegin = IdHTTP1WorkBegin
    OnWorkEnd = IdHTTP1WorkEnd
    AllowCookies = False
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = 0
    Request.ContentRangeStart = 0
    Request.ContentType = 'text/html'
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    HTTPOptions = [hoForceEncodeParams]
    Left = 320
    Top = 8
  end
  object IdAntiFreeze1: TIdAntiFreeze
    IdleTimeOut = 100
    Left = 288
    Top = 8
  end
  object XMLDocument1: TXMLDocument
    Left = 256
    Top = 8
    DOMVendorDesc = 'MSXML'
  end
  object MainMenu1: TMainMenu
    AutoLineReduction = maManual
    BiDiMode = bdLeftToRight
    ParentBiDiMode = False
    Left = 224
    Top = 8
    object Launcher1: TMenuItem
      Caption = 'Launcher'
      OnClick = Launcher1Click
      object StartNFK1: TMenuItem
        Caption = 'Start NFK'
        OnClick = Button1Click
      end
      object Autostart1: TMenuItem
        AutoCheck = True
        Caption = 'Autostart'
        Checked = True
        OnClick = Autostart1Click
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Caption = 'Exit'
        OnClick = Exit1Click
      end
    end
    object Mods1: TMenuItem
      Caption = 'Mods'
      OnClick = Mods1Click
      object NFK1: TMenuItem
        AutoCheck = True
        Caption = 'NFK'
        Default = True
        GroupIndex = 1
        RadioItem = True
        OnClick = ModClick
      end
    end
    object Help1: TMenuItem
      Caption = 'Help'
      OnClick = Help1Click
      object About1: TMenuItem
        Caption = 'About...'
        OnClick = About1Click
      end
    end
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 192
    Top = 8
  end
end
