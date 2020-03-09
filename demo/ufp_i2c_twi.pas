unit ufp_i2c_twi;

{

  SPI Protocol.

  Copyright (C) 2018 Dimitrios Chr. Ioannidis.
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

{$mode objfpc}
{$LONGSTRINGS OFF}
{$INLINE ON}
{$MACRO ON}
{$MODESWITCH TYPEHELPERS}
{$MODESWITCH ADVANCEDRECORDS}
{$WRITEABLECONST OFF}

interface

const
  I2C_Takt = 100000;
  TWI_Write = 0;
  TWI_Read = 1;
  SDA = 4;
  SCL = 5;

procedure TWIInit;
procedure TWIStart(const addr: byte);
procedure TWIStop;
procedure TWIWrite(const u8data: byte);

function TWIReadACK: byte;
function TWIReadNACK: byte;
function TWIReadACK_Error: byte;
function TWIReadNACK_Error: byte;

implementation

procedure TWIInit;
const
  TWBR_val = byte((F_CPU div I2C_Takt) - 16) div 2;
begin
  TWSR := 0;
  TWBR := byte(TWBR_val);

  PORTC := PORTC or (1 shl SDA); // Pullup Register SDA
  PORTC := PORTC or (1 shl SCL); // Pullup Register SCL

  TWSR := TWSR and not (1 shl TWPS);
  TWSR := TWSR and not (1 shl 1);
end;

procedure TWIStart(const addr: byte);
begin
  TWCR := 0;
  TWCR := (1 shl TWINT) or (1 shl TWSTA) or (1 shl TWEN);
  while ((TWCR and (1 shl TWINT)) = 0) do
  begin
  end;

  TWDR := addr;
  TWCR := (1 shl TWINT) or (1 shl TWEN);
  while ((TWCR and (1 shl TWINT)) = 0) do
  begin
  end;
end;

procedure TWIStop;
begin
  TWCR := (1 shl TWINT) or (1 shl TWSTO) or (1 shl TWEN);
end;

procedure TWIWrite(const u8data: byte);
begin
  TWDR := u8data;
  TWCR := (1 shl TWINT) or (1 shl TWEN);
  while ((TWCR and (1 shl TWINT)) = 0) do
  begin
  end;
end;

function TWIReadACK: byte;
begin
  TWCR := (1 shl TWINT) or (1 shl TWEN) or (1 shl TWEA);
  while (TWCR and (1 shl TWINT)) = 0 do
  begin
  end;
  Result := TWDR;
end;

// Letztes Zeichen lesen.
function TWIReadNACK: byte;
begin
  TWCR := (1 shl TWINT) or (1 shl TWEN);
  while (TWCR and (1 shl TWINT)) = 0 do
  begin
  end;
  Result := TWDR;
end;

function TWIReadACK_Error: byte;
var
  err: byte;
begin
  err := 0;
  TWCR := (1 shl TWINT) or (1 shl TWEN) or (1 shl TWEA);
  while ((TWCR and (1 shl TWINT)) = 0) and (err < 255) do
  begin
    Inc(err);
  end;
  if err = 255 then
  begin
    Result := 0;
  end
  else
  begin
    Result := TWDR;
  end;
end;

function TWIReadNACK_Error: byte;
var
  err: byte;
begin
  err := 0;
  TWCR := (1 shl TWINT) or (1 shl TWEN);
  while ((TWCR and (1 shl TWINT)) = 0) and (err < 255) do
  begin
    Inc(err);
  end;
  if err = 255 then
  begin
    Result := 0;
  end
  else
  begin
    Result := TWDR;
  end;
end;

end.
