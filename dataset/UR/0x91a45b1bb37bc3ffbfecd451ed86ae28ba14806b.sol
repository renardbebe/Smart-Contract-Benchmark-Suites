 

pragma solidity ^0.4.18;


 
interface ERC20 {
  function decimals() public constant returns (uint8 decimals);
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract LibraCreditNetwork is ERC20 {    		
		
  string public _name;
  string public _symbol;
  uint8 public _decimals;
  uint256 _totalSupply; 
  
  string private _version = '0.1';
  
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  
  function () {
         
        throw;
  }
  	
  function LibraCreditNetwork() {                           
        _name = "Libra Credit Network";            
        _symbol = "LBA";                                    
        _decimals = 18;                  		
        _totalSupply = 1000000000000000000000000000; 
        balances[msg.sender] = _totalSupply;
  }
  
   
  function decimals() public constant returns (uint8 decimals) {
        return _decimals;
  }
  
   
  function version() public view returns (string) {
        return _version;
  }

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] -= _value;
    balances[_to] += _value;
    allowed[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}