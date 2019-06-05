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

{.$DEFINE FP_HAS_TAT24MAC402}

uses
  intrinsics, heapmgr, ufp_uartserial, {$IFDEF FP_HAS_TAT24MAC402}at24mac402,{$endif} ufp_enc28j60,
  fpethbuf, fpethcfg, fpethip, fpethudp, fpethtcp, fpetharp, fpethtypes, fpethif, fpethicmp, fpethdhcp;

var
  enc28j60: TENC28J60;
{$IFDEF FP_HAS_TAT24MAC402}
  at24mac402: TAT24MAC402;
{$ENDIF}

{$IFDEF FP_ENC28J60_USEINTERRUPT}
procedure ExternalInterrupt0_ISR; public Name 'PCINT0_ISR'; interrupt;
begin
  // Check if ENC28J60 Interrupt Pin is Low
  if Not (PINB and (1 shl ENC28J60_CONTROL_INT) = (1 shl ENC28J60_CONTROL_INT)) then
    enc28j60.maintain;
end;
{$ENDIF}

begin
  SerialUART.Init(57600);
  SerialUART.SendStringLn('Free Pascal ENC28J60 Driver Demo');

  // Chip Select / Slave Select Pin
  // PORTB Pin 1

  ENC28J60_CONTROL_CS  := 2; //

{$IFDEF FP_ENC28J60_USEINTERRUPT}

  // Interrupt Pin
  // PORTB Pin 0
  ENC28J60_CONTROL_INT := 1;

  // Interrupt Pin internal pull-up ( High )
  ENC28J60_CONTROL_PORT := ENC28J60_CONTROL_PORT or (1 shl ENC28J60_CONTROL_INT);
  // Enable interrupt for vector 0
  PCICR := PCICR or (PCIE + 1); // PORTB
  // Enable Pin Change Detection for the ENC28J60_CONTROL_INT pin
  PCMSK0 := PCMSK0 or ( 1 shl ENC28J60_CONTROL_INT); // PCINT0

{$ENDIF}

{$IFDEF FP_HAS_TAT24MAC402}
  enc28j60.MacAddress := at24mac402.MacAddress;
{$ELSE}
  enc28j60.MacAddress := HWAddress(12, 12, 12, 12, 12, 12);
{$ENDIF}

  enc28j60.Init;
  // ENC28J60 Uses SPI which needs global interrupts.
  avr_sei;

  repeat
{$IFNDEF FP_ENC28J60_USEINTERRUPT}
    enc28j60.Maintain;
{$ENDIF}
  until false;
end.
