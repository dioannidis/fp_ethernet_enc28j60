unit uUtils;

{

  Misc AVR functions.

  Copyright (C) 2018 Dimitrios Chr. Ioannidis.
    Nephelae - https://www.nephelae.eu

  Licensed under the MIT License (MIT).
  See licence file in root directory.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
  ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
  TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
  SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
  OTHER DEALINGS IN THE SOFTWARE.

}

{$mode objfpc}{$H+}
{$WRITEABLECONST OFF}

interface

function AtomicRead(var value: word): word; inline;
procedure AtomicWrite(var value: word; new_value: word); inline;

procedure delay_ms(time: byte);
function int_str(l: longint): shortstring;

{$IFDEF FP_DEBUG}
var
  DbgMsg: ShortString;
{$ENDIF}

implementation

uses
  intrinsics;

procedure AtomicWrite(var value: word; new_value: word); inline;
var
  b: Byte;
begin
  b:=avr_save;
  value:=new_value;
  avr_restore(b);
end;

function AtomicRead(var value: word): word; inline;
var
  b: Byte;
begin
  b:=avr_save;
  AtomicRead:=value;
  avr_restore(b);
end;

procedure delay_ms(time : byte);
const
  fmul = 1 * 16000000 div 1000000;
label
  loop1, loop2, loop3;
begin
  asm
    ldd r20, time
    loop1:
      ldi r21, fmul
      loop2:  // 1000 * fmul = 1000 * 1 * 8 = 8000 cycles / 8MHz
        ldi r22, 250
        loop3:  // 4 * 250 = 1000 cycles
          nop
          dec r22
          brne loop3
        dec r21
        brne loop2
      dec r20
      brne loop1
  end ['r20','r21','r22'];
end;

function int_str(l: longint): shortstring;
//var
//  m, m1: longword;
//  pcstart, pc2start, pc, pc2: PChar;
//  hs: string[32];
//  overflow: longint;
//  s: shortstring;
begin
  //pc2start := @s[1];
  //pc2 := pc2start;
  //if (l < 0) then
  //begin
  //  pc2^ := '-';
  //  Inc(pc2);
  //  m := longword(-l);
  //end
  //else
  //  m := longword(l);
  //pcstart := PChar(@hs[0]);
  //pc := pcstart;
  //repeat
  //  m1 := m div 10;
  //  Inc(pc);
  //  pc^ := char(m - (m1 * 10) + byte('0'));
  //  m := m1;
  //until m = 0;
  //overflow := (pc - pcstart) + (pc2 - pc2start) - high(s);
  //if overflow > 0 then
  //  Inc(pcstart, overflow);
  //while (pc > pcstart) do
  //begin
  //  pc2^ := pc^;
  //  Inc(pc2);
  //  Dec(pc);
  //end;
  //s[0] := char(pc2 - pc2start);
  //Result := s;
end;

end.
