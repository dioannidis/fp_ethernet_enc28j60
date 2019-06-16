unit ufp_at24mac402;

{$mode objfpc}{$H+}
{$WRITEABLECONST OFF}

interface

uses
  fpethtypes, ufp_i2c_twi;

  function at24mac402_GetMacAddress: THWAddress;

implementation


// Read MacAddress from AT24MAC402
function at24mac402_GetMacAddress: THWAddress;
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

