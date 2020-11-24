 

contract ERC20Detailed is ERC20Mintable {
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  bool public mintable;
  bool public burnable;

  constructor(string name, string symbol, uint8 decimals, uint256 initialSupply, bool _mintable, bool _burnable) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
    _totalSupply = initialSupply;
    _balances[msg.sender] = initialSupply;
    mintable = _mintable;
    burnable = _burnable;
  }

   
  function name() public view returns(string) {
    return _name;
  }

   
  function symbol() public view returns(string) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
  }

   
  function mint(address _to, uint256 _value) public returns (bool)  {
    require(mintable, "Token is not mintable");
    super.mint(_to, _value);
  }

   
  function burn(uint256 _value) public returns (bool)  {
    require(burnable, "Token is not burnable");
    super.burn(_value);
  }
}
