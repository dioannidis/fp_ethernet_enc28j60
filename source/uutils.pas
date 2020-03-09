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

{$mode objfpc}
{$WRITEABLECONST OFF}
{$INLINE ON}
{$LONGSTRINGS OFF}

interface

function AtomicRead(var Value: word): word; inline;
procedure AtomicWrite(var Value: word; new_value: word); inline;
{$if defined(CPUAVR_HAS_LPMX)}// HAS_LPMX also means that movw is available
//function read_progmem_byte(constref v: byte): byte;
procedure read_progmem_str(constref s: shortstring; var res: ShortString);
{$endif}

//procedure delay_ms(time: byte);

implementation

uses
  intrinsics;

procedure AtomicWrite(var Value: word; new_value: word); inline;
var
  b: byte;
begin
  b := avr_save;
  Value := new_value;
  avr_restore(b);
end;

function AtomicRead(var Value: word): word; inline;
var
  b: byte;
begin
  b := avr_save;
  AtomicRead := Value;
  avr_restore(b);
end;

{$if defined(CPUAVR_HAS_LPMX)}// HAS_LPMX also means that movw is available
function read_progmem_byte(constref v: byte): byte; assembler; nostackframe;
asm
  MOVW    ZL, r24
  LPM     r24, Z
end;

procedure read_progmem_str(constref s: shortstring; var res: ShortString);
var
  len, i: byte;
begin
  len := read_progmem_byte(byte(s[0]));
  setlength(res, len);
  for i := 1 to len do
    res[i] := char(read_progmem_byte(byte(s[i])));
end;
{$ENDIF}

//procedure delay_ms(time : byte);
//const
//  fmul = 1 * F_CPU div 1000000;
//label
//  loop1, loop2, loop3;
//begin
//  asm
//    ldd r20, time
//    loop1:
//      ldi r21, fmul
//      loop2:  // 1000 * fmul = 1000 * 1 * 8 = 8000 cycles / 8MHz
//        ldi r22, 250
//        loop3:  // 4 * 250 = 1000 cycles
//          nop
//          dec r22
//          brne loop3
//        dec r21
//        brne loop2
//      dec r20
//      brne loop1
//  end ['r20','r21','r22'];
//end;

end.
