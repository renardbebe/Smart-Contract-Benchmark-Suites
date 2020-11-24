 
contract MOVEToken is StandardToken
{
  string public name      = "move token";
  string public symbol    = "MOVE";
  uint256 public decimals = 8;
  uint256 public INITIAL_SUPPLY = 100000000000000000;

   
 constructor() public
 {
  totalSupply_ = INITIAL_SUPPLY;
  balances[msg.sender] = INITIAL_SUPPLY;
 }
}
