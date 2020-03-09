unit ufp_ethernet;

{

  Free Pascal ENC28J60 AVR Demo.

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
{$LONGSTRINGS OFF}
{$INLINE ON}
{$MACRO ON}
//{$MODESWITCH TYPEHELPERS}
//{$MODESWITCH ADVANCEDRECORDS}
{$WRITEABLECONST OFF}

{.$DEFINE FP_HAS_TAT24MAC402}

interface

uses
{$IFDEF FP_HAS_TAT24MAC402}
    ufp_at24mac402,
{$ENDIF}
{$IFDEF FP_ENC28J60_USEINTERRUPT}
  intrinsics,
{$ENDIF}
  ufp_enc28j60,
  fpethbuf, fpethcfg, fpethip, fpethudp, fpethtcp, fpetharp, fpethtypes, fpethif, fpethicmp, fpethdhcp;

  procedure EtherBegin(const ACS_SSPin: Byte);
  procedure EtherMaintain;

implementation

{$IFDEF FP_ENC28J60_USEINTERRUPT}
procedure ExternalInterrupt0_ISR; public Name 'PCINT0_ISR'; interrupt;
begin
  // Check if ENC28J60 Interrupt Pin is Low
  if Not (PINB and (byte(1) shl ENC28J60_CONTROL_INT) = (byte(1) shl ENC28J60_CONTROL_INT)) then
    enc28j60_InterruptTriggered;
end;
{$ENDIF}

procedure EtherBegin(const ACS_SSPin: Byte);
begin
  // Chip Select / Slave Select Pin
  // PORTB Pin 1

  ENC28J60_CONTROL_CS  := ACS_SSPin; //

{$IFDEF FP_ENC28J60_USEINTERRUPT}

  // Interrupt Pin
  // PORTB Pin 0
  ENC28J60_CONTROL_INT := 1;

  // Interrupt Pin internal pull-up ( High )
  ENC28J60_CONTROL_PORT := ENC28J60_CONTROL_PORT or (byte(1) shl ENC28J60_CONTROL_INT);
  // Enable interrupt for vector 0
  PCICR := PCICR or (PCIE + 1); // PORTB
  // Enable Pin Change Detection for the ENC28J60_CONTROL_INT pin
  PCMSK0 := PCMSK0 or ( byte(1) shl ENC28J60_CONTROL_INT); // PCINT0

{$ENDIF}

{$IFDEF FP_HAS_TAT24MAC402}
  enc28j60_Init(at24mac402_GetMacAddress(0));
{$ELSE}
  enc28j60_Init(HWAddress($01, $02, $03, $04, $05, $06));
{$ENDIF}

end;

procedure EtherMaintain;
begin
  enc28j60_Maintain;
end;

end.

