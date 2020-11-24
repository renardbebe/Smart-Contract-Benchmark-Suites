 

pragma solidity ^0.4.21;

 
contract Ownable {
  
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address _from, address _to);
  
   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    assert(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    assert(_newOwner != address(0));      
    newOwner = _newOwner;
  }

   
  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }
  }
}

 
contract SafeMath {

  function safeSub(uint256 x, uint256 y) internal pure returns (uint256) {
    uint256 z = x - y;
    assert(z <= x);
	  return z;
  }

  function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
    uint256 z = x + y;
	  assert(z >= x);
	  return z;
  }
	
  function safeDiv(uint256 x, uint256 y) internal pure returns (uint256) {
    uint256 z = x / y;
    return z;
  }
	
  function safeMul(uint256 x, uint256 y) internal pure returns (uint256) {
    uint256 z = x * y;
    assert(x == 0 || z / x == y);
    return z;
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256) {
    uint256 z = x <= y ? x : y;
    return z;
  }

  function max(uint256 x, uint256 y) internal pure returns (uint256) {
    uint256 z = x >= y ? x : y;
    return z;
  }
}

  
contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint256 _decimals);
  function totalSupply() public view returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool success);
}


contract ERC223Token is ERC223,SafeMath ,Ownable {

  mapping(address => uint) balances;
  
  string public name;
  string public symbol;
  uint256 public decimals;
  uint256 public totalSupply;
  
  address public crowdsaleAgent;
  address[] public addrCotracts;
  bool public released = false;  
  
   
  modifier onlyCrowdsaleAgent() {
    assert(msg.sender == crowdsaleAgent);
    _;
  }
  
   
  modifier canTransfer() {
    if(msg.sender != address(this)){
      if(!released){
        revert();
      }
    }
    _;
  } 
  
   
  function name() public view returns (string _name) {
      return name;
  }
   
  function symbol() public view returns (string _symbol) {
      return symbol;
  }
   
  function decimals() public view returns (uint256 _decimals) {
      return decimals;
  }
   
  function totalSupply() public view returns (uint256 _totalSupply) {
      return totalSupply;
  }
  
  
   
  function transfer(address _to, uint _value, bytes _data) public canTransfer returns (bool success) {
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }
  
   
   
  function transfer(address _to, uint _value) public canTransfer returns (bool success) {
     
     
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
  }

   
  function isContract(address _addr) private view returns (bool is_contract) {
      uint length;
      assembly {
             
            length := extcodesize(_addr)
      }
      return (length>0);
    }

   
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }
  
   
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    bool flag = false;
    for(uint i = 0; i < addrCotracts.length; i++) {
      if(_to == addrCotracts[i]) flag = true;
    }
    if(flag){
      balances[this] = safeAdd(balanceOf(this), _value);
    }else{
      balances[_to] = safeAdd(balanceOf(_to), _value);
    }
    ContractReceiver receiver = ContractReceiver(_to);
    if(receiver.tokenFallback(msg.sender, _value, _data)){
      emit Transfer(msg.sender, _to, _value, _data);
      return true;
    }else{
      revert();
    }
    if(flag){
      emit Transfer(msg.sender, this, _value, _data);
    }else{
      emit Transfer(msg.sender, _to, _value, _data);
    }
    return true;
}

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
  
    
  function mint(address _to, uint _value, bytes _data) public onlyCrowdsaleAgent returns (bool success) {
    totalSupply = safeAdd(totalSupply, _value);
    balances[_to] = safeAdd(balances[_to], _value);
    emit Transfer(0, _to, _value, _data);
    return true;
  }

   
  function setCrowdsaleAgent(address _crowdsaleAgent) public onlyOwner {
    crowdsaleAgent = _crowdsaleAgent;
  }
  
   
  function releaseTokenTransfer() public onlyCrowdsaleAgent {
    released = true;
  }

}

 
contract GoldVein is ERC223Token{
  
   
  modifier onlyAgent() {
    bool flag = false;
    for(uint i = 0; i < addrCotracts.length; i++) {
      if(msg.sender == addrCotracts[i]) flag = true;
    }
   assert(flag);
    _;
  }

   
  event UpdatedTokenInformation(string newName, string newSymbol);
  
   
   
  function GoldVein(string _name, string _symbol, uint256 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }   
  
   function tokenFallback(address _from, uint _value, bytes _data) public onlyAgent returns (bool success){
    balances[this] = safeSub(balanceOf(this), _value);
    balances[_from] = safeAdd(balanceOf(_from), _value);
    emit Transfer(this, _from, _value, _data);
    return true;
  }
  
   
  function setTokenInformation(string _name, string _symbol) public onlyOwner {
    name = _name;
    symbol = _symbol;
    emit UpdatedTokenInformation(name, symbol);
  }
  
  function setAddr (address _addr) public onlyOwner {
    addrCotracts.push(_addr);
  }
 
  function transferForICO(address _to, uint _value) public onlyCrowdsaleAgent returns (bool success) {
    return this.transfer(_to, _value);
  }
 
  function delAddr (uint number) public onlyOwner {
    require(number < addrCotracts.length);
    for(uint i = number; i < addrCotracts.length-1; i++) {
      addrCotracts[i] = addrCotracts[i+1];
    }
    addrCotracts.length = addrCotracts.length-1;
  }
}