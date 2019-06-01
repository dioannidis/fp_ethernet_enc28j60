unit ufp_enc28j60;

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

{$mode objfpc}{$H-}
{$WRITEABLECONST OFF}
{$modeswitch result}
interface

uses
  intrinsics;

type
  TMacAddress = array[0..5] of byte;

  { TENC28J60 }

  TENC28J60 = object
  private
    FBank: byte;
    FMacAddress: TMacAddress;
    FNextPacketPtr,
    FPacketReadPtr: Word;
    FRevID: byte;
    FBuffer: PByte;
    FBufferSize: Word;
    procedure CSActive;
    procedure CSPassive;
    procedure SetMacAddress(const AValue: TMacAddress);
    procedure WaitSPI;
    function ReadOp(const AOP, AAddress: byte): byte;
    procedure WriteOp(const AOP: byte; const AAddress: byte; const AData: byte);
    procedure SetBank(const AAddress: byte);
    function Read(const AAddress: byte): byte;
    procedure Write(const AAddress, Adata: byte);
    procedure PhyWrite(const AAddress: byte; const AData: word);
    procedure ClockOut(const AClk: byte);
  protected
    {$IFDEF FP_ENC28J60_USEINTERRUPT}
    procedure PacketReceive(const APacketCount: Byte);
    {$ELSE}
    procedure PacketReceive;
    {$ENDIF}
    procedure ReadBuffer(ALength: Word; ABuffer: PByte);
  public
    procedure Init;
    procedure Maintain;
    property MacAddress: TMacAddress read FMacAddress write SetMacAddress;
  end;

const
  ENC28J60_CONTROL_SI  = 3;
  ENC28J60_CONTROL_SO  = 4;
  ENC28J60_CONTROL_SCK = 5;

var
  ENC28J60_CONTROL_PORT: byte absolute PORTB;
  ENC28J60_CONTROL_DDR: byte absolute DDRB;
  ENC28J60_CONTROL_INT: byte = -1;
  ENC28J60_CONTROL_CS: byte  = -1;

  //ENC28J60_CONTROL_INT: byte = 1;
  //ENC28J60_CONTROL_CS: byte = 2;

implementation

{$IFDEF FP_ENC28J60_DEBUG}
uses
  ufp_uartserial;
{$ENDIF}

const
  // ENC28J60 Control Registers
  // Control register definitions are a combination of address,
  // bank number, and Ethernet/MAC/PHY indicator bits.
  // - Register address        (bits 0-4)
  // - Bank number        (bits 5-6)
  // - MAC/PHY indicator        (bit 7)
  ADDR_MASK = $1F;
  BANK_MASK = $60;
  SPRD_MASK = $80;
  // All-bank registers
  EIE = $1B;
  EIR = $1C;
  ESTAT = $1D;
  ECON2 = $1E;
  ECON1 = $1F;
  // Bank 0 registers
  ERDPTL = ($00 or $00);
  ERDPTH = ($01 or $00);
  EWRPTL = ($02 or $00);
  EWRPTH = ($03 or $00);
  ETXSTL = ($04 or $00);
  ETXSTH = ($05 or $00);
  ETXNDL = ($06 or $00);
  ETXNDH = ($07 or $00);
  ERXSTL = ($08 or $00);
  ERXSTH = ($09 or $00);
  ERXNDL = ($0A or $00);
  ERXNDH = ($0B or $00);
  ERXRDPTL = ($0C or $00);
  ERXRDPTH = ($0D or $00);
  ERXWRPTL = ($0E or $00);
  ERXWRPTH = ($0F or $00);
  EDMASTL = ($10 or $00);
  EDMASTH = ($11 or $00);
  EDMANDL = ($12 or $00);
  EDMANDH = ($13 or $00);
  EDMADSTL = ($14 or $00);
  EDMADSTH = ($15 or $00);
  EDMACSL = ($16 or $00);
  EDMACSH = ($17 or $00);
  // Bank 1 registers
  EHT0 = ($00 or $20);
  EHT1 = ($01 or $20);
  EHT2 = ($02 or $20);
  EHT3 = ($03 or $20);
  EHT4 = ($04 or $20);
  EHT5 = ($05 or $20);
  EHT6 = ($06 or $20);
  EHT7 = ($07 or $20);
  EPMM0 = ($08 or $20);
  EPMM1 = ($09 or $20);
  EPMM2 = ($0A or $20);
  EPMM3 = ($0B or $20);
  EPMM4 = ($0C or $20);
  EPMM5 = ($0D or $20);
  EPMM6 = ($0E or $20);
  EPMM7 = ($0F or $20);
  EPMCSL = ($10 or $20);
  EPMCSH = ($11 or $20);
  EPMOL = ($14 or $20);
  EPMOH = ($15 or $20);
  EWOLIE = ($16 or $20);
  EWOLIR = ($17 or $20);
  ERXFCON = ($18 or $20);
  EPKTCNT = ($19 or $20);
  // Bank 2 registers
  MACON1 = ($00 or $40 or $80);
  MACON2 = ($01 or $40 or $80);
  MACON3 = ($02 or $40 or $80);
  MACON4 = ($03 or $40 or $80);
  MABBIPG = ($04 or $40 or $80);
  MAIPGL = ($06 or $40 or $80);
  MAIPGH = ($07 or $40 or $80);
  MACLCON1 = ($08 or $40 or $80);
  MACLCON2 = ($09 or $40 or $80);
  MAMXFLL = ($0A or $40 or $80);
  MAMXFLH = ($0B or $40 or $80);
  MAPHSUP = ($0D or $40 or $80);
  MICON = ($11 or $40 or $80);
  MICMD = ($12 or $40 or $80);
  MIREGADR = ($14 or $40 or $80);
  MIWRL = ($16 or $40 or $80);
  MIWRH = ($17 or $40 or $80);
  MIRDL = ($18 or $40 or $80);
  MIRDH = ($19 or $40 or $80);
  // Bank 3 registers
  MAADR1 = ($00 or $60 or $80);
  MAADR0 = ($01 or $60 or $80);
  MAADR3 = ($02 or $60 or $80);
  MAADR2 = ($03 or $60 or $80);
  MAADR5 = ($04 or $60 or $80);
  MAADR4 = ($05 or $60 or $80);
  EBSTSD = ($06 or $60);
  EBSTCON = ($07 or $60);
  EBSTCSL = ($08 or $60);
  EBSTCSH = ($09 or $60);
  MISTAT = ($0A or $60 or $80);
  EREVID = ($12 or $60);
  ECOCON = ($15 or $60);
  EFLOCON = ($17 or $60);
  EPAUSL = ($18 or $60);
  EPAUSH = ($19 or $60);
  // PHY registers
  PHCON1 = $00;
  PHSTAT1 = $01;
  PHHID1 = $02;
  PHHID2 = $03;
  PHCON2 = $10;
  PHSTAT2 = $11;
  PHIE = $12;
  PHIR = $13;
  PHLCON = $14;
  // ENC28J60 ERXFCON Register Bit Definitions
  ERXFCON_UCEN = $80;
  ERXFCON_ANDOR = $40;
  ERXFCON_CRCEN = $20;
  ERXFCON_PMEN = $10;
  ERXFCON_MPEN = $08;
  ERXFCON_HTEN = $04;
  ERXFCON_MCEN = $02;
  ERXFCON_BCEN = $01;
  // ENC28J60 EIE Register Bit Definitions
  EIE_INTIE = $80;
  EIE_PKTIE = $40;
  EIE_DMAIE = $20;
  EIE_LINKIE = $10;
  EIE_TXIE = $08;
  EIE_WOLIE = $04;
  EIE_TXERIE = $02;
  EIE_RXERIE = $01;
  // ENC28J60 EIR Register Bit Definitions
  EIR_PKTIF = $40;
  EIR_DMAIF = $20;
  EIR_LINKIF = $10;
  EIR_TXIF = $08;
  EIR_WOLIF = $04;
  EIR_TXERIF = $02;
  EIR_RXERIF = $01;
  // ENC28J60 ESTAT Register Bit Definitions
  ESTAT_INT = $80;
  ESTAT_LATECOL = $10;
  ESTAT_RXBUSY = $04;
  ESTAT_TXABRT = $02;
  ESTAT_CLKRDY = $01;
  // ENC28J60 ECON2 Register Bit Definitions
  ECON2_AUTOINC = $80;
  ECON2_PKTDEC = $40;
  ECON2_PWRSV = $20;
  ECON2_VRPS = $08;
  // ENC28J60 ECON1 Register Bit Definitions
  ECON1_TXRST = $80;
  ECON1_RXRST = $40;
  ECON1_DMAST = $20;
  ECON1_CSUMEN = $10;
  ECON1_TXRTS = $08;
  ECON1_RXEN = $04;
  ECON1_BSEL1 = $02;
  ECON1_BSEL0 = $01;
  // ENC28J60 MACON1 Register Bit Definitions
  MACON1_LOOPBK = $10;
  MACON1_TXPAUS = $08;
  MACON1_RXPAUS = $04;
  MACON1_PASSALL = $02;
  MACON1_MARXEN = $01;
  // ENC28J60 MACON2 Register Bit Definitions
  MACON2_MARST = $80;
  MACON2_RNDRST = $40;
  MACON2_MARXRST = $08;
  MACON2_RFUNRST = $04;
  MACON2_MATXRST = $02;
  MACON2_TFUNRST = $01;
  // ENC28J60 MACON3 Register Bit Definitions
  MACON3_PADCFG2 = $80;
  MACON3_PADCFG1 = $40;
  MACON3_PADCFG0 = $20;
  MACON3_TXCRCEN = $10;
  MACON3_PHDRLEN = $08;
  MACON3_HFRMLEN = $04;
  MACON3_FRMLNEN = $02;
  MACON3_FULDPX = $01;
  // ENC28J60 MICMD Register Bit Definitions
  MICMD_MIISCAN = $02;
  MICMD_MIIRD = $01;
  // ENC28J60 MISTAT Register Bit Definitions
  MISTAT_NVALID = $04;
  MISTAT_SCAN = $02;
  MISTAT_BUSY = $01;
  // ENC28J60 PHY PHCON1 Register Bit Definitions
  PHCON1_PRST = $8000;
  PHCON1_PLOOPBK = $4000;
  PHCON1_PPWRSV = $0800;
  PHCON1_PDPXMD = $0100;
  // ENC28J60 PHY PHSTAT1 Register Bit Definitions
  PHSTAT1_PFDPX = $1000;
  PHSTAT1_PHDPX = $0800;
  PHSTAT1_LLSTAT = $0004;
  PHSTAT1_JBSTAT = $0002;
  // ENC28J60 PHY PHCON2 Register Bit Definitions
  PHCON2_FRCLINK = $4000;
  PHCON2_TXDIS = $2000;
  PHCON2_JABBER = $0400;
  PHCON2_HDLDIS = $0100;

  // ENC28J60 Packet Control Byte Bit Definitions
  PKTCTRL_PHUGEEN = $08;
  PKTCTRL_PPADEN = $04;
  PKTCTRL_PCRCEN = $02;
  PKTCTRL_POVERRIDE = $01;

  // SPI operation codes
  ENC28J60_READ_CTRL_REG = $00;
  ENC28J60_READ_BUF_MEM = $3A;
  ENC28J60_WRITE_CTRL_REG = $40;
  ENC28J60_WRITE_BUF_MEM = $7A;
  ENC28J60_BIT_FIELD_SET = $80;
  ENC28J60_BIT_FIELD_CLR = $A0;
  ENC28J60_SOFT_RESET = $FF;

  // The RXSTART_INIT should be zero. See Rev. B4 Silicon Errata
  // buffer boundaries applied to internal 8K ram
  // the entire available packet buffer space is allocated

  // start with recbuf at 0/
  RXSTART_INIT = $0;
  // receive buffer end. make sure this is an odd value ( See Rev. B1,B4,B5,B7 Silicon Errata 'Memory (Ethernet Buffer)')
  //RXSTOP_INIT = ($1FFF - $1800);
  RXSTOP_INIT = ($1FFF - $5EB);
  // start TX buffer RXSTOP_INIT+1
  TXSTART_INIT = RXSTOP_INIT + 1;
  // stp TX buffer at end of mem
  TXSTOP_INIT = $1FFF;

  // max frame length which the conroller will accept:
  MAX_FRAMELEN = 1500;
// (note: maximum ethernet frame length would be 1518)

{ TENC28J60 }

procedure TENC28J60.CSActive;
begin
  ENC28J60_CONTROL_PORT := ENC28J60_CONTROL_PORT and not (1 shl ENC28J60_CONTROL_CS);
end;

procedure TENC28J60.CSPassive;
begin
  ENC28J60_CONTROL_PORT := ENC28J60_CONTROL_PORT or (1 shl ENC28J60_CONTROL_CS);
end;

procedure TENC28J60.SetMacAddress(const AValue: TMacAddress);
begin
  FMacAddress := AValue;
end;

procedure TENC28J60.WaitSPI;
begin
  repeat
  until (SPSR and (1 shl SPIF)) <> 0;
end;

function TENC28J60.ReadOp(const AOP, AAddress: byte): byte;
begin
  CSActive;
  // issue read command
  SPDR := (AOP or (AAddress and ADDR_MASK));
  WaitSPI;
  // read data
  SPDR := $00;
  WaitSPI;
  // do dummy read if needed (for mac and mii, see datasheet page 29)
  if (AAddress and $80) <> 0 then
  begin
    SPDR := $00;
    WaitSPI;
  end;
  // release CS
  CSPassive;
  Result := SPDR;
end;

procedure TENC28J60.WriteOp(const AOP: byte; const AAddress: byte; const AData: byte);
begin
  CSActive;
  SPDR := (AOP or (AAddress and ADDR_MASK));
  WaitSPI;
  SPDR := AData;
  WaitSPI;
  CSPassive;
end;

procedure TENC28J60.SetBank(const AAddress: byte);
begin
  // set the bank (if needed)
  if (byte(AAddress and BANK_MASK) <> FBank) then
  begin
    // set the bank
    WriteOp(ENC28J60_BIT_FIELD_CLR, ECON1, byte(ECON1_BSEL1 or ECON1_BSEL0));
    WriteOp(ENC28J60_BIT_FIELD_SET, ECON1, byte((AAddress and BANK_MASK)) shr 5);
    FBank := (AAddress and BANK_MASK);
  end;
end;

function TENC28J60.Read(const AAddress: byte): byte;
begin
  // set the bank
  SetBank(AAddress);
  // do the read
  Result := ReadOp(ENC28J60_READ_CTRL_REG, AAddress);
end;

procedure TENC28J60.Write(const AAddress, Adata: byte);
begin
  // set the bank
  SetBank(AAddress);
  // do the write
  WriteOp(ENC28J60_WRITE_CTRL_REG, AAddress, Adata);
end;

procedure TENC28J60.PhyWrite(const AAddress: byte; const AData: word);
begin
  // set the PHY register address
  Write(MIREGADR, AAddress);
  // write the PHY data
  Write(MIWRL, AData);
  Write(MIWRH, AData shr 8);
  // wait until the PHY write completes
  repeat
  until (Read(MISTAT) and MISTAT_BUSY) = 0;
end;

procedure TENC28J60.ClockOut(const AClk: byte);
begin
  //setup clkout: 2 is 12.5MHz:
  Write(ECOCON, AClk and $7);
end;

{$IFDEF FP_ENC28J60_USEINTERRUPT}
procedure TENC28J60.PacketReceive(const APacketCount: Byte);
{$ELSE}
procedure TENC28J60.PacketReceive;
{$ENDIF}
var
  PacketCount: Byte;
  PacketLength, ReceiveStatus: uint16; // Word;
  y: integer;
begin
{$IFDEF FP_ENC28J60_USEINTERRUPT}
  PacketCount := APacketCount;
{$ELSE}
  PacketCount := Read(EPKTCNT);
  if PacketCount <> 0 then
  begin
{$ENDIF}

    // Set the packet read pointer to actual start of packet bypass the first 6 bytes.
    if FNextPacketPtr + 6 > RXSTOP_INIT then
      FPacketReadPtr := FNextPacketPtr + 6 - RXSTOP_INIT + RXSTART_INIT
    else
      FPacketReadPtr := FNextPacketPtr + 6;

    // Set the read pointer to the start of the received packet
    Write(ERDPTL, (FNextPacketPtr and $FF));
    Write(ERDPTH, (FNextPacketPtr shr $8));

	  // read the next packet pointer
	  FNextPacketPtr := ReadOp(ENC28J60_READ_BUF_MEM, 0);
	  FNextPacketPtr := FNextPacketPtr or (Word(ReadOp(ENC28J60_READ_BUF_MEM, 0)) shl 8);

    // read the packet length (see datasheet page 43)
	  PacketLength := ReadOp(ENC28J60_READ_BUF_MEM, 0);
	  PacketLength := PacketLength or (Word(ReadOp(ENC28J60_READ_BUF_MEM, 0)) shl 8);
    Dec(PacketLength, 4); //remove the CRC count

    // read the receive status (see datasheet page 43)
	  ReceiveStatus := ReadOp(ENC28J60_READ_BUF_MEM, 0);
	  ReceiveStatus := ReceiveStatus or (Word(ReadOp(ENC28J60_READ_BUF_MEM, 0)) shl 8);

    // decrement the packet counter indicate we are done with this packet
	  WriteOp(ENC28J60_BIT_FIELD_SET, ECON2, ECON2_PKTDEC);

    if (ReceiveStatus and $80) <> 0 then
    begin
      if FBufferSize < PacketLength then
      begin
        FreeMem(FBuffer);
        FBufferSize := PacketLength;
        FBuffer := GetMem(PacketLength);
      end;
      if Assigned(FBuffer) then
        ReadBuffer(PacketLength, FBuffer);
    end;

   // This frees the memory we just read out. Move the RX read pointer to the start of the next received packet
   // However, compensate for the errata point 14, rev B1,B4,B5,B7: never write an even address!
   if FNextPacketPtr = RXSTART_INIT then
   begin
     Write(ERXRDPTL, (RXSTOP_INIT and $FF));
     Write(ERXRDPTH, (RXSTOP_INIT shr 8));
   end
   else
   begin
     Write(ERXRDPTL, ((FNextPacketPtr - 1) and $FF));
     Write(ERXRDPTH, ((FNextPacketPtr - 1) shr 8));
   end;

{$IFDEF FP_ENC28J60_DEBUG}
    SerialUART.SendString('Receive packet [ Start: 0x' + HexStr(FPacketReadPtr, 4));
    SerialUART.SendString( ' Length: ' + HexStr(PacketLength, 4));
    SerialUART.SendString('] next: 0x' + HexStr(FNextPacketPtr, 4));
    SerialUART.SendString(' stat: 0x' + HexStr(ReceiveStatus, 2));
    SerialUART.SendString(' Packet count: ' + HexStr(PacketCount, 2));
    SerialUART.SendString(' ');
    for y := 0 to PacketLength - 1 do
      SerialUART.SendString(HexStr(FBuffer[y], 2) + ' ');
    SerialUART.SendStringLn('');
{$ENDIF}
{$IFNDEF FP_ENC28J60_USEINTERRUPT}
  end;
{$ENDIF}
end;

procedure TENC28J60.ReadBuffer(ALength: Word; ABuffer: PByte);
begin
  CSActive;
  SPDR := ENC28J60_READ_BUF_MEM;
  WaitSPI;
  while ALength <> 0 do
  begin
    dec(Alength);
    SPDR := $0;
    WaitSPI;
    ABuffer^ := SPDR;
    inc(ABuffer);
  end;
  CSPassive;
end;

procedure TENC28J60.Init;
begin
  //FInterruptFired := 0;

  FBank := $FF;

  FBuffer := nil;

  // Iniialize io
  // SS as output.
  // mosi, sck output
  ENC28J60_CONTROL_DDR := ENC28J60_CONTROL_DDR or
    ((1 shl ENC28J60_CONTROL_SI) or (1 shl ENC28J60_CONTROL_SCK));
  // miso is input
  ENC28J60_CONTROL_DDR := ENC28J60_CONTROL_DDR or
    (ENC28J60_CONTROL_DDR and not (1 shl ENC28J60_CONTROL_SO));
  // SS as output.
  ENC28J60_CONTROL_DDR := (ENC28J60_CONTROL_DDR or (1 shl ENC28J60_CONTROL_CS));

  CSPassive; // SS High

  // MOSI low
  ENC28J60_CONTROL_PORT := (ENC28J60_CONTROL_PORT and not (1 shl ENC28J60_CONTROL_SI));
  // SCK low
  ENC28J60_CONTROL_PORT := (ENC28J60_CONTROL_PORT and not (1 shl ENC28J60_CONTROL_SCK));

  // initialize SPI interface
  // master mode and Fosc/2 clock:
  //SPCR := SPCR or ((1 SHL SPE) or (0 SHL SPIE) or (0 SHL DORD) or (1 SHL MSTR) or
  //  (0 SHL CPOL) or (0 SHL CPHA) or (%01 SHL SPR));
  SPCR := (1 shl SPE) or (1 shl MSTR){ or (%11 shl SPR)};
  //SPSR := (0 shl SPI2X);
  SPSR := (1 shl SPI2X);

  // perform system reset
  WriteOp(ENC28J60_SOFT_RESET, 0, ENC28J60_SOFT_RESET);
  //delay_ms(50);

  repeat
  until (ReadOp(ENC28J60_READ_CTRL_REG, ESTAT) and ESTAT_CLKRDY) <> 0;

  FNextPacketPtr := RXSTART_INIT;

  // Rx start
  Write(ERXSTL, (RXSTART_INIT and $FF));
  Write(ERXSTH, (RXSTART_INIT shr 8));
  // set receive pointer address
  Write(ERXRDPTL, (RXSTART_INIT and $FF));
  Write(ERXRDPTH, (RXSTART_INIT shr 8));
  // RX end
  Write(ERXNDL, (RXSTOP_INIT and $FF));
  Write(ERXNDH, (RXSTOP_INIT shr 8));
  //// TX start
  //Write(ETXSTL, (TXSTART_INIT and $FF));
  //Write(ETXSTH, (TXSTART_INIT shr 8));
  //// TX end
  //Write(ETXNDL, (TXSTOP_INIT and $FF));
  //Write(ETXNDH, (TXSTOP_INIT shr 8));

  // do bank 1 stuff, packet filter:
  // For broadcast packets we allow only ARP packtets
  // All other packets should be unicast only for our mac (MAADR)

  // The pattern to match on is therefore
  // Type     ETH.DST
  // ARP      BROADCAST
  // 06 08 -- ff ff ff ff ff ff -> ip checksum for theses bytes=f7f9
  // in binary these poitions are:11 0000 0011 1111
  // This is hex 303F->EPMM0=0x3f,EPMM1=0x30
  Write(ERXFCON, ERXFCON_UCEN or ERXFCON_CRCEN or ERXFCON_PMEN or ERXFCON_BCEN);
  Write(EPMM0, $3f);
  Write(EPMM1, $30);
  Write(EPMCSL, $f9);
  Write(EPMCSH, $f7);

  // do bank 2 stuff
  // enable MAC receive
  Write(MACON1, MACON1_MARXEN or MACON1_TXPAUS or MACON1_RXPAUS);
  // bring MAC out of reset
  Write(MACON2, $00);
  // enable automatic padding to 60bytes and CRC operations
  WriteOp(ENC28J60_BIT_FIELD_SET, MACON3, MACON3_PADCFG0 or MACON3_TXCRCEN or
    MACON3_FRMLNEN);
  // set inter-frame gap (non-back-to-back)
  Write(MAIPGL, $12);
  Write(MAIPGH, $0C);
  // set inter-frame gap (back-to-back)
  Write(MABBIPG, $12);
  // Set the maximum packet size which the controller will accept
  // Do not send packets longer than MAX_FRAMELEN:
  Write(MAMXFLL, MAX_FRAMELEN and $FF);
  Write(MAMXFLH, MAX_FRAMELEN shr 8);

  // do bank 3 stuff
  // write MAC address
  // NOTE: MAC address in ENC28J60 is byte-backward
  Write(MAADR5, FMacAddress[0]);
  Write(MAADR4, FMacAddress[1]);
  Write(MAADR3, FMacAddress[2]);
  Write(MAADR2, FMacAddress[3]);
  Write(MAADR1, FMacAddress[4]);
  Write(MAADR0, FMacAddress[5]);
  // no loopback of transmitted frames
  PhyWrite(PHCON2, PHCON2_HDLDIS);

  // switch to bank 0
  SetBank(ECON1);

{$IFDEF FP_ENC28J60_USEINTERRUPT}
  // enable interrutps global and packet
  WriteOp(ENC28J60_BIT_FIELD_SET, EIE, EIE_INTIE or EIE_PKTIE);
{$ELSE}
  // enable interrutps global
  WriteOp(ENC28J60_BIT_FIELD_SET, EIE, EIE_INTIE);
{$ENDIF}

  // enable packet reception
  WriteOp(ENC28J60_BIT_FIELD_SET, ECON1, ECON1_RXEN);

//  ClockOut(0);

  PhyWrite(PHLCON, $476);

  FRevID := Read(EREVID);

{$IFDEF FP_ENC28J60_DEBUG}
  SerialUART.SendString('ENC28J60 Revision Id: 0x');
  SerialUART.SendString(HexStr(FRevID, 2));
  SerialUART.SendStringLn(' Initialized.');
{$ENDIF}

end;

procedure TENC28J60.Maintain;
begin
{$IFDEF FP_ENC28J60_USEINTERRUPT}
  while Read(EPKTCNT) > 0 do
    PacketReceive(Read(EPKTCNT));
{$ELSE}
  PacketReceive;
{$ENDIF}
end;


end.
