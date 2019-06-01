unit ufp_at24mac402;

{$mode objfpc}{$H+}
{$WRITEABLECONST OFF}

interface

uses
  ufp_i2c_twi, ufp_enc28j60;

type

  { TAT24MAC402 }

  TAT24MAC402 = object
  private
    function GetMacAddress: TMacAddress;
  public
    property MacAddress: TMacAddress read GetMacAddress;
  end;

implementation

{ TAT24MAC402 }

// Read MacAddress from AT24MAC402
function TAT24MAC402.GetMacAddress: TMacAddress;
begin
  TWIInit;
  TWIStart((($58 or 0) shl 1) or TWI_Write);
  TWIWrite($9A);
  TWIStop;

  TWIStart((($58 or 0) shl 1) or TWI_Read);
  Result[0] := TWIReadACK_Error;
  Result[1] := TWIReadACK_Error;
  Result[2] := TWIReadACK_Error;
  Result[3] := TWIReadACK_Error;
  Result[4] := TWIReadACK_Error;
  Result[5] := TWIReadACK_Error;
  TWIStop;
end;

end.

