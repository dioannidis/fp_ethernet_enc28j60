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

interface

  procedure UARTInit(const ABaudRate: DWord = 57600);
  function UARTReadChar: char;
  procedure UARTSendString(const s: ShortString);
  procedure UARTSendStringLn(const s: ShortString = '');

implementation

function Divider(const FBaudRate: DWord): integer;
begin
  Result := (F_CPU div 4 div FBaudRate - 1) div 2;
end;

procedure UARTInit(const ABaudRate: DWord = 57600);
begin
  UBRR0 := Divider(ABaudRate);
  UCSR0A := (1 shl U2X0);
  UCSR0B := (1 shl TXEN0) or (1 shl RXEN0);
  UCSR0C := (%011 shl UCSZ0);
end;

procedure UARTSendChar(const c: char); inline;
begin
  while ((UCSR0A and (1 shl UDRE0)) = 0) do ;
  UDR0 := byte(c);
end;

function UARTReadChar: char;
begin
  while ((UCSR0A and (1 shl RXC0)) = 0) do ;
  Result := char(UDR0);
end;

procedure UARTSendString(const s: ShortString);
var
  i: integer;
begin
  for i := 1 to length(s) do
    UARTSendChar(s[i]);
end;

procedure UARTSendStringLn(const s: ShortString);
var
  i: integer;
begin
  for i := 1 to length(s) do
    UARTSendChar(s[i]);
  UARTSendChar(#10);
  UARTSendChar(#13);
end;

end.
