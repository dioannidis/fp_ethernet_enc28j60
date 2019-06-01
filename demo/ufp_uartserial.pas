unit ufp_uartserial;

{

  UART Driver for AVR.

  Copyright (C) 2019 Dimitrios Chr. Ioannidis.
    Nephelae - https://www.nephelae.eu

  https://www.nephelae.eu/

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

type

  { TUART }

  TUART = object
  private
    FBaudRate: DWord;
    function Divider: Integer;
  public
    procedure Init(const ABaudRate: DWord = 57600);
    procedure SendChar(c: char);
    function ReadChar: char;
    procedure SendString(s: ShortString);
    procedure SendStringLn(s: ShortString = '');
  end;

var
  SerialUART: TUART;

implementation

{ TUART }

function TUART.Divider: integer;
begin
  //Result := (16000000 div (8 * FBaudRate)) - 1;
  //Result := (((16000000 + 4 * FBaudRate) shr 3)  div FBaudRate) - 1;
  Result := (16000000 div 4 div FBaudRate - 1) div 2;

end;

procedure TUART.Init(const ABaudRate: DWord = 57600);
begin
  FBaudRate := ABaudRate;
  UBRR0 := Divider;
  UCSR0A := (1 shl U2X0);
  UCSR0B := (1 shl TXEN0) or (1 shl RXEN0);
  UCSR0C := (%011 shl UCSZ0);
end;

procedure TUART.SendChar(c: char);
begin
  while ((UCSR0A and (1 shl UDRE0)) = 0) do ;
  UDR0 := byte(c);
end;

function TUART.ReadChar: char;
begin
  while ((UCSR0A and (1 shl RXC0)) = 0) do ;
  Result := char(UDR0);
end;

procedure TUART.SendString(s: ShortString);
var
  i: integer;
begin
  for i := 1 to length(s) do
    SendChar(s[i]);
end;

procedure TUART.SendStringLn(s: ShortString);
var
  i: integer;
begin
  for i := 1 to length(s) do
    SendChar(s[i]);
  SendChar(#10);
  SendChar(#13);
end;

end.
