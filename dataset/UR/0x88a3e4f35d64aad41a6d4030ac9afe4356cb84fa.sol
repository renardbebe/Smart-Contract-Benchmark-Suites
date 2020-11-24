 

pragma solidity ^0.4.17;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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
}

 
contract preToken {
  using SafeMath for uint256;

   
  string public constant name = "Presearch";
  string public constant symbol = "PRE";
  uint8 public constant decimals = 18;
  uint public totalSupply = 0;

   
  uint256 public constant maxSupply = 1000000000e18;

   
  uint256 public constant initialSupply = 250000000e18;

   
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

   
  address public owner;

   
  address public crowdsaleAddress;

   
  uint public unlockDate = 1512018000;

   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  modifier onlyPayloadSize(uint size) {
     assert(msg.data.length == size + 4);
     _;
   }

   
   
  modifier tradable {
      if (now < unlockDate && msg.sender != owner && msg.sender != crowdsaleAddress) revert();
      _;
    }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function preToken() public {
    balances[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    owner = msg.sender;
    crowdsaleAddress = msg.sender;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
   }

   
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) tradable returns (bool success) {
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(2 * 32) tradable returns (bool success) {
    require(_from != address(0) && _to != address(0));
    uint256 _allowance = allowed[_from][msg.sender];
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(_spender != address(0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
   
   
  function mint(uint256 _amount) public onlyOwner {
    if (totalSupply.add(_amount) <= maxSupply){
      balances[msg.sender] = balances[msg.sender].add(_amount);
      totalSupply = totalSupply.add(_amount);
    }else{
      revert();
    }
  }

   
   
  function burn(uint256 _amount) public onlyOwner {
    require(balances[msg.sender] >= _amount);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
  }

   
  function setCrowdsaleAddress(address newCrowdsaleAddress) public onlyOwner {
    require(newCrowdsaleAddress != address(0));
    crowdsaleAddress = newCrowdsaleAddress;
  }

   
  function updateUnlockDate(uint _newDate) public onlyOwner {
    require (_newDate <= 1512018000);
      unlockDate=_newDate;
  }

}