unit locr_utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, strutils, strings;

function GetTempFileByExt(const Prefix,Ext:string):String;
function GetNextAlphaNumValue(const Value:string):string;
function PSep(const S:string):string;
function CorrectRtf(const S:string):string;
procedure Exchange(var X,Y:integer);

const AlphaNum:string=//'0123456789ABCDEFGHIGKLMNOPQRSTUVWXYZabcdefghigklmnopqrstuvwxyz';
                '0123456789abcdefghigklmnopqrstuvwxyz';//May be case insensitivity
implementation

function PSep(const S:string):string;
begin
  if S[Length(S)]=DirectorySeparator then Result:=S else
    Result:=S+DirectorySeparator;
end;
function ReplaceAll(const S,SFrom,STo:string):string;
var
  S1: String;
begin
  S1:=S;
  repeat
    Result:=S1;
    s1:=ReplaceStr(S,SFrom,STo);
  until Result=S1;
end;

function CorrectRtf(const S: string): string;
var
  c: Char;
begin
  Result:=S;
  Result:=ReplaceAll(Result,'\b','\lang1049\B');
  Result:=ReplaceAll(Result,'\B','\b');
  for c:=#128 to #255 do
    Result:=ReplaceAll(Result,c,'\'''+LowerCase(IntToHex(ord(c),2)));
end;

procedure Exchange(var X, Y: integer);
var
  Z: Integer;
begin
  Z:=X;X:=Y;Y:=Z;
end;

function GetTempFileByExt(const Prefix, Ext: string): String;
var
  Dir: String;
  Counter: String;
begin
  Dir:=GetTempDir;
  Counter:='0';
  repeat
    Counter:=GetNextAlphaNumValue(Counter);
    Result:=PSep(Dir)+Prefix+Counter+'.'+ext;
  until not FileExists(Result);
end;

function GetNextAlphaNumValue(const Value: string): string;
var
  i,j: Integer;
begin
  i:=Length(Value);
  Result:=Value;
  repeat
    j:=pos(lowerCase(Value[i]),AlphaNum);
    if j<1 then begin
      Result:='';
      for j:=1 to Length(Value) do Result:=Result+'0';
      exit;
    end;
    if j<Length(AlphaNum) then
      begin Result[i]:=AlphaNum[j+1];
        for j:=i+1 to length(Result) do          Result[j]:='0';
        exit;
      end;
    dec(i);
  until i=0;
  Result:='';
  for j:=1 to Length(Value)+1 do Result:=Result+'0';
end;

initialization

end.

