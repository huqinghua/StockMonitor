unit Utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants;


procedure DebugOut(msg : string);

implementation

procedure DebugOut(msg : string);
begin
  //OutputDebugString(PChar(msg));
end;

end.
