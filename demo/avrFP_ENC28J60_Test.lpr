program avrFP_ENC28J60_Test;

{

  Demo for ENC28J60 AVR low level driver.

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

{$mode objfpc}
{$WRITEABLECONST OFF}
{$LONGSTRINGS OFF}


uses
  intrinsics, uUtils,
  //heapmgr,
  ufp_uartserial, fpethtypes, ufp_ethernet;

const
  BannerTopStr: string[25] = '-------------------------';
  BannerStr: string[25]    = 'Free Pascal ENC28J60 Demo';

begin
  UARTInit(57600);
  UARTSendStringLn(BannerTopStr);
  UARTSendStringLn(BannerStr);

  EtherBegin(2);

  // ENC28J60 Uses SPI which needs global interrupts.
  avr_sei;

  repeat
    EtherMaintain;
  until false;
end.
