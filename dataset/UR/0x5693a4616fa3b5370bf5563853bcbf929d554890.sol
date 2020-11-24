 

pragma solidity ^0.4.20;

 
library SafeMath { 
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0){
        return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function pow(uint256 a, uint256 b) internal pure returns (uint256){  
    if (b == 0){
      return 1;
    }
    uint256 c = a**b;
    assert (c >= a);
    return c;
  }
}

 
contract Ownable {

  address public owner;

  address public newOwner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function Ownable() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }
}

contract CAIDToken is Ownable {  
  using SafeMath for uint;
   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  string public constant symbol = "CAID";
  string public constant name = "ClearAid";  
  uint8 public constant decimals = 8;
  uint256 _totalSupply = 100000000*(uint(10).pow(decimals));

   
  mapping(address => uint256) balances;

   
  mapping(address => mapping (address => uint256)) allowed;

  function totalSupply() public view returns (uint256) {  
    return _totalSupply;
  }

  function balanceOf(address _address) public view returns (uint256 balance) { 
    return balances[_address];
  }
  
  bool public locked = true;
  function changeLockTransfer (bool _request) public onlyOwner {
    locked = _request;
  }
  
   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(this != _to);
    require(!locked);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender,_to,_amount);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _amount) public returns(bool success){
    require(this != _to);
    require(!locked);
    balances[_from] = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(_from,_to,_amount);
    return true;
  }
   
  function approve(address _spender, uint256 _amount)public returns (bool success) { 
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

   
  function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function CAIDToken() public {
    owner = msg.sender;
    balances[this] = _totalSupply;
  }

  address public crowdsaleContract;

  function setCrowdsaleContract (address _address) public{
    require(crowdsaleContract == address(0));

    crowdsaleContract = _address;
  }

  function endICO () public {
    require(msg.sender == crowdsaleContract);

    emit Transfer(this,0,balances[this]);
    
    _totalSupply = _totalSupply.sub(balances[this]);
    balances[this] = 0;
  }

    
  function sendCrowdsaleTokens (address _address, uint _value) public {
    require(msg.sender == crowdsaleContract);

    balances[this] = balances[this].sub(_value);
    balances[_address] = balances[_address].add(_value);
        
    emit Transfer(this,_address,_value);    
  }
}