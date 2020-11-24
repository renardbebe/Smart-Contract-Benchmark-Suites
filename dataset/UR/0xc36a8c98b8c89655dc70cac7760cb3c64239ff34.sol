 
contract O2ERC20Token is ERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;

     
    constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply, address tokenOwnerAddress) public {
      _name = name;
      _symbol = symbol;
      _decimals = decimals;

       
      _mint(tokenOwnerAddress, totalSupply);

    }

     


     

     
    function name() public view returns (string memory) {
      return _name;
    }

     
    function symbol() public view returns (string memory) {
      return _symbol;
    }

     
    function decimals() public view returns (uint8) {
      return _decimals;
    }
}