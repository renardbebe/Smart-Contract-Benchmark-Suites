 

pragma solidity ^0.4.13;

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    require(b > 0);
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    require(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    require(c >= a);
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

 
contract Ownable {

  address public owner;

  modifier onlyOwner {
    require (msg.sender == owner);
    _;
  }

  function Ownable() {
    owner = msg.sender;
  }

  function setNewOwner(address _owner) public onlyOwner returns(bool success) {
    if (_owner != address(0)) {
      owner = _owner;
      return true;
    }
    return false;
  }
}

 
contract LockEvents {
  event Locked();
  event Unlocked();
}

 
contract Lockable is Ownable, LockEvents {

  bool public locked;

  modifier whenUnlocked() {
    require(locked==false);
    _;
  }

  modifier whenLocked() {
    require(locked==true);
    _;
  }

  function Lockable() {
    locked = true;
    Locked();
  }

  function unlock() public onlyOwner whenLocked returns(bool success) {
    locked = false;
    Unlocked();
    return true;
  }

  function lock() public onlyOwner whenUnlocked returns(bool success) {
    locked = true;
    Locked();
    return true;
  }
}

contract TimedVaultEvents {
  event Locked(address _target, uint256 timestamp);
}

 
contract TimedVault is Ownable, TimedVaultEvents {
  mapping (address => uint256) lockDeadline;

  modifier timedVaultIsOpen(address _target) {
    require(now > lockDeadline[_target]);
    _;
  }

  function setVaultLock(address _target, uint256 timestamp) internal onlyOwner returns(bool success) {
    lockDeadline[_target] = timestamp;
    Locked(_target, timestamp);
    return true;
  }

  function getVaultLock(address _target) public returns(uint256 timestamp) {
    return lockDeadline[_target];
  }
}

 
contract ERC20Events {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract ERC20 is ERC20Events {
  
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  uint256 public totalSupply;

   
  function totalSupply() public constant returns (uint256) {
    return totalSupply;
  }

   
   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

   
   
   
   
  function transfer(address _to, uint256 _value) public returns (bool success) {
     
    if(balances[msg.sender] >= _value 
      && balances[_to]+_value > balances[_to]) {

      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }
  
   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    if (balances[_from] >= _value 
      && allowed[_from][msg.sender] >= _value 
      && balances[_to] + _value > balances[_to]) {

      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else { 
      return false; 
    }
  }

   
   
   
   
  function approve(address _spender, uint256 _value) public returns (bool success) {
     
    if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
    
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
   
   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

contract IdiotToken is Lockable, ERC20, TimedVault {
  
  string public name = "Idiot Token";
  string public symbol = "IDT";
  uint public decimals = 18;
  uint MULTIPLIER = 1000000000000000000; 

  function IdiotToken() {
    totalSupply = 76000000*MULTIPLIER;
    balances[owner] = totalSupply;
  }

  function transfer(address _to, uint256 _value) whenUnlocked timedVaultIsOpen(msg.sender) public returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transferInitialAllocation(address _to, uint256 _value) onlyOwner public returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transferInitialAllocationWithTimedLock(address _to, uint256 _value, uint256 _timestamp) onlyOwner public returns (bool success) {
     
    return (setVaultLock(_to, _timestamp) && super.transfer(_to, _value));
  }

  function transferFrom(address _from, address _to, uint256 _value) whenUnlocked public returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) whenUnlocked public returns (bool success) {
    return super.approve(_spender, _value);
  }

   
  function() payable {
    revert();
  }
}


 

contract IdiotTokenSale is Ownable {
  using SafeMath for uint;

  event Purchase(address indexed _buyer, uint256 _value);
  event SaleStarted();
  event SaleFinished();

  uint256 public tokenCap;
  uint public start;
  uint public end;
  bool public saleFinished;
  bool public forceFinished;
  bool public setupDone;
  uint256 public rate;
  uint public totalContribution;

  IdiotToken public token;

  address public founder1;
  address public founder2;
  address public advisoryPool;
  address public angelPool;
  uint MULTIPLIER = 1000000000000000000;

  modifier saleInProgress() {
    require(tokenCap > 0 && (start <= now && now < end) && !saleFinished && !forceFinished && setupDone);
    _;
  }

  modifier saleIsOver() {
    require(tokenCap == 0 || (start <= now && now < end) || forceFinished);
    _;
  }

  function IdiotTokenSale() {   
    setupDone = false;
    saleFinished = false;
    forceFinished = false;
    token = new IdiotToken();
    totalContribution = 0;

    founder1 = address(0x383C69259149BDd38B5093Bf1c75ebD443684288);
    founder2 = address(0xc6f29A076cc937917F3cd608881C0B0a0b3276f2);
    advisoryPool = address(0x8995b6645d60975Cb14be68B6495Be2618a77B94);
    angelPool = address(0x6e121956a9C8E4b3D1F7a7D3316056cD89eD109C);
  }

  function setup() public onlyOwner returns(bool success){
    require(!setupDone);

    start = 1509361200;  
    end = 1514199600;  

     
    token.transferInitialAllocation(owner, 22800000*MULTIPLIER); 
     
    token.transferInitialAllocationWithTimedLock(founder1, 7600000*MULTIPLIER, now + 365 days);
    token.transferInitialAllocationWithTimedLock(founder2, 7600000*MULTIPLIER, now + 365 days);
     
    token.transferInitialAllocation(angelPool, 6840000*MULTIPLIER); 
    token.transferInitialAllocation(advisoryPool, 760000*MULTIPLIER);
     
    tokenCap = 30400000*MULTIPLIER;
    require(tokenCap == token.balanceOf(this));

    rate = 30400*MULTIPLIER;

    setupDone = true;
    SaleStarted();
    return true;
  }

  function buyToken() public payable saleInProgress {
    require (msg.value >= 10 finney);
    uint purchasedToken = rate.mul(msg.value).div(1 ether);
    
    require(tokenCap >= purchasedToken);
    tokenCap -= purchasedToken;
    token.transferInitialAllocation(msg.sender, purchasedToken);
    
    require(owner.send(msg.value));
    totalContribution += msg.value;
    Purchase(msg.sender, purchasedToken);
  }

  function finalizeCrowdsale() public onlyOwner saleIsOver returns(bool success) {
    if (tokenCap > 0) {
      require(token.transferInitialAllocation(owner, tokenCap));
    }
    require(token.setNewOwner(owner));
    saleFinished = true;
    SaleFinished();
    return true;
  }

  function forceEnd() public onlyOwner saleInProgress returns(bool success) {
    forceFinished = true;
    SaleFinished();
    return true;
  }

  function () external payable {
    buyToken();
  }
}