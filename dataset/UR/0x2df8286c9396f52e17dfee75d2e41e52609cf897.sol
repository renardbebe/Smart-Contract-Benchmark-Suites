 

pragma solidity ^0.4.14;

 
contract Ownable {
 address public owner;

 function Ownable() {
   owner = msg.sender;
 }

 modifier onlyOwner() {
   require(msg.sender == owner);
   _;
 }

 function transferOwnership(address newOwner) onlyOwner {
   if (newOwner != address(0)) {
     owner = newOwner;
   }
 }
}

 
contract Killable is Ownable {
 function kill() onlyOwner {
   selfdestruct(owner);
 }
}

  
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);
  function mint(address receiver, uint amount);
  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

  
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

  
contract SilentNotaryToken is SafeMath, ERC20, Killable {
  string constant public name = "Silent Notary Token";
  string constant public symbol = "SNTR";
  uint constant public decimals = 4;
   
  uint constant public BUYOUT_PRICE = 20e10;
   
  address[] public holders;
   
  struct Balance {
     
    uint value;
     
    bool exist;
  }
   
  mapping(address => Balance) public balances;
   
  address public crowdsaleAgent;
   
  bool public released = false;
   
  mapping (address => mapping (address => uint)) allowed;

   
  modifier canTransfer() {
    if(!released)
      require(msg.sender == crowdsaleAgent);
    _;
  }

   
   
  modifier inReleaseState(bool _released) {
    require(_released == released);
    _;
  }

   
   
  modifier addIfNotExist(address holder) {
    if(!balances[holder].exist)
      holders.push(holder);
    _;
  }

   
  modifier onlyCrowdsaleAgent() {
    require(msg.sender == crowdsaleAgent);
    _;
  }

   
   
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4);
    _;
  }

   
  modifier canMint() {
    require(!released);
    _;
  }

   
  event Burned(address indexed burner, address indexed holder, uint burnedAmount);
   
  event Pay(address indexed to, uint value);
   
  event Deposit(address indexed from, uint value);

   
  function SilentNotaryToken() {
  }

   
  function() payable {
    require(msg.value > 0);
    Deposit(msg.sender, msg.value);
  }
   
   
   
  function mint(address receiver, uint amount) onlyCrowdsaleAgent canMint addIfNotExist(receiver) public {
      totalSupply = safeAdd(totalSupply, amount);
      balances[receiver].value = safeAdd(balances[receiver].value, amount);
      balances[receiver].exist = true;
      Transfer(0, receiver, amount);
  }

   
   
  function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner inReleaseState(false) public {
    crowdsaleAgent = _crowdsaleAgent;
  }
   
  function releaseTokenTransfer() public onlyCrowdsaleAgent {
    released = true;
  }
   
   
   
   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer addIfNotExist(_to) returns (bool success) {
    balances[msg.sender].value = safeSub(balances[msg.sender].value, _value);
    balances[_to].value = safeAdd(balances[_to].value, _value);
    balances[_to].exist = true;
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
   
   
   
   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer addIfNotExist(_to) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to].value = safeAdd(balances[_to].value, _value);
    balances[_from].value = safeSub(balances[_from].value, _value);
    balances[_to].exist = true;

    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }
   
   
   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner].value;
  }

   
   
   
   
  function approve(address _spender, uint _value) returns (bool success) {
     
     
     
     
    require ((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
   
   
   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

   
   
   
  function buyout(address _holder, uint _amount) onlyOwner addIfNotExist(msg.sender) external  {
    require(_holder != msg.sender);
    require(this.balance >= _amount);
    require(BUYOUT_PRICE <= _amount);

    uint multiplier = 10 ** decimals;
    uint buyoutTokens = safeDiv(safeMul(_amount, multiplier), BUYOUT_PRICE);

    balances[msg.sender].value = safeAdd(balances[msg.sender].value, buyoutTokens);
    balances[_holder].value = safeSub(balances[_holder].value, buyoutTokens);
    balances[msg.sender].exist = true;

    Transfer(_holder, msg.sender, buyoutTokens);

    _holder.transfer(_amount);
    Pay(_holder, _amount);
  }
}