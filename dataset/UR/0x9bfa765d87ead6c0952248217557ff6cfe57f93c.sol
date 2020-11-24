 
contract ZSMNToken is ERC20 {

    string private _name;
	
    string private _symbol;
	
    uint8 private _decimals;
	
	uint256 private _totalSupply;
	
	constructor(string memory name, string memory symbol, uint8 decimals, uint256 initialSupply, address tokenOwnerAddress) public payable {
      _name = name;
      _symbol = symbol;
      _decimals = decimals;
      _totalSupply = initialSupply * 10 ** uint256(decimals);
      
      _mint(tokenOwnerAddress, _totalSupply);

    }
    

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
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