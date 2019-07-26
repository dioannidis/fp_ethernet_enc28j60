unit ufp_at24mac402;

{

  ENC28J60 AVR low level driver for Free Pascal.

  Copyright (C) 2019 Dimitrios Chr. Ioannidis.
    Nephelae - https://www.nephelae.eu

  https://www.nephelae.eu/enc28j60/

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

uses
  fpethtypes, ufp_i2c_twi;

  function at24mac402_GetMacAddress(const AAddress: Byte): THWAddress;

implementation


function at24mac402_GetMacAddress(const AAddress: Byte): THWAddress;
begin
  TWIInit;
  TWIStart((($58 or AAddress) shl 1) or TWI_Write);
  TWIWrite($9A);
  TWIStop;

  TWIStart((($58 or AAddress) shl 1) or TWI_Read);
  Result[0] := TWIReadACK_Error;
  Result[1] := TWIReadACK_Error;
  Result[2] := TWIReadACK_Error;
  Result[3] := TWIReadACK_Error;
  Result[4] := TWIReadACK_Error;
  Result[5] := TWIReadACK_Error;
  TWIStop;
end;

end.

