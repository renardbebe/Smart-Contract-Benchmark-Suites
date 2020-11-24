 

pragma solidity 0.4.21;


 
 
 
 
contract ERC20Interface {
   
  string public name;
   
  string public symbol;
   
  uint8 public decimals;
   
  uint256 public totalSupply;
   
  function balanceOf(address _owner) public view returns (uint256 balance);
   
  function transfer(address _to, uint256 _value) public returns (bool success);
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
   
  function approve(address _spender, uint256 _value) public returns (bool success);
   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);
   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  function Owned() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

 
contract TokenRecipient { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

 
contract Token is ERC20Interface, Owned {

  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;
  
   
  event Burn(address indexed from, uint256 value);
  
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= allowed[_from][msg.sender]); 
    allowed[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  
   
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
    TokenRecipient spender = TokenRecipient(_spender);
    approve(_spender, _value);
    spender.receiveApproval(msg.sender, _value, this, _extraData);
    return true;
  }

   
  function burn(uint256 _value) public returns (bool success) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }

   
  function burnFrom(address _from, uint256 _value) public returns (bool success) {
    require(balances[_from] >= _value);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] -= _value;
    allowed[_from][msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(_from, _value);
    return true;
  }

   
  function _transfer(address _from, address _to, uint _value) internal {
     
    require(_to != 0x0);
     
    require(balances[_from] >= _value);
     
    require(balances[_to] + _value > balances[_to]);
     
    uint previousBalances = balances[_from] + balances[_to];
     
    balances[_from] -= _value;
     
    balances[_to] += _value;
    emit Transfer(_from, _to, _value);
     
    assert(balances[_from] + balances[_to] == previousBalances);
  }

}

contract BEECOIN is Token {

  function BEECOIN() public {
    name = "Bee Coin";
    symbol = "BEECOIN";
    decimals = 0;
    totalSupply = 1000000000;
    balances[msg.sender] = totalSupply;
  }
}