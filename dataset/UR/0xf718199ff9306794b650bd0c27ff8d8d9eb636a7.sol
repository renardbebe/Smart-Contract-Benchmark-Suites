 
contract UAT is StandardToken, Ownable{

  uint256 public totalSupply;
  string public name;
  string public symbol;
  uint32 public decimals;

   
 constructor() public {
  symbol = "UAT";
  name = "UltrAlpha";
  decimals = 18;
  totalSupply = 500000000000000000000000000;

  owner = 0x19061bDCa862387eBd99E5e9b4e51958e4151123;
  balances[msg.sender] = totalSupply;

  emit Transfer(0x0, msg.sender, totalSupply);
 }}
