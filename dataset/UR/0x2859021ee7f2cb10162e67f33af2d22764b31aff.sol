 

pragma solidity ^0.4.18;

  
contract SafeMath {
  function safeMul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

  
contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

  
contract Killable is Ownable {
  function kill() public onlyOwner {
    selfdestruct(owner);
  }
}

  
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);  
  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  function decimals() public constant returns (uint value);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

  
contract SilentNotaryToken is SafeMath, ERC20, Killable {
  string constant public name = "Silent Notary Token";
  string constant public symbol = "SNTR";
 
   
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

   
  function SilentNotaryToken() public {
  }

   
  function() payable public {
	  revert();
  }

  function decimals() public constant returns (uint value) {
    return 4;
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
   
   
   
   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer addIfNotExist(_to) public returns (bool success) {
    balances[msg.sender].value = safeSub(balances[msg.sender].value, _value);
    balances[_to].value = safeAdd(balances[_to].value, _value);
    balances[_to].exist = true;
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
   
   
   
   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer addIfNotExist(_to) public returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to].value = safeAdd(balances[_to].value, _value);
    balances[_from].value = safeSub(balances[_from].value, _value);
    balances[_to].exist = true;

    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }
   
   
   
  function balanceOf(address _owner) constant public returns (uint balance) {
    return balances[_owner].value;
  }

   
   
   
   
  function approve(address _spender, uint _value) public returns (bool success) {
     
     
     
     
    require ((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
   
   
   
  function allowance(address _owner, address _spender) constant public returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}