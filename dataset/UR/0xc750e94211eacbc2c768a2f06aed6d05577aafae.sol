 

pragma solidity ^0.4.24;

contract ERC20Basic {
   
  event Transfer(address indexed from, address indexed to, uint256 value);

   
  function totalSupply() public view returns (uint256);
  function balanceOf(address addr) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

       
                     string public name;
  string public symbol;
  uint8 public decimals = 18;

   
  uint256 _totalSupply;
  mapping(address => uint256) _balances;
  mapping(address => uint256) _freezeOf;

   

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address addr) public view returns (uint256 balance) {
    return _balances[addr];
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(to != address(0));
    require(value <= _balances[msg.sender]);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

   
}

contract ERC20 is ERC20Basic {
   
  event Approval(address indexed owner, address indexed agent, uint256 value);

   
  function allowance(address owner, address agent) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address agent, uint256 value) public returns (bool);

}

contract Ownable {

   
  address public owner;

   

   
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
}

contract StandardToken is ERC20, BasicToken {
   

   
  mapping (address => mapping (address => uint256)) _allowances;

   

   
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(to != address(0));
    require(value <= _balances[from]);
    require(value <= _allowances[from][msg.sender]);

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

  function approve(address agent, uint256 value) public returns (bool) {
    _allowances[msg.sender][agent] = value;
    emit Approval(msg.sender, agent, value);
    return true;
  }

  function allowance(address owner, address agent) public view returns (uint256) {
    return _allowances[owner][agent];
  }

  function increaseApproval(address agent, uint value) public returns (bool) {
    _allowances[msg.sender][agent] = _allowances[msg.sender][agent].add(value);
    emit Approval(msg.sender, agent, _allowances[msg.sender][agent]);
    return true;
  }

  function decreaseApproval(address agent, uint value) public returns (bool) {
    uint allowanceValue = _allowances[msg.sender][agent];
    if (value > allowanceValue) {
      _allowances[msg.sender][agent] = 0;
    } else {
      _allowances[msg.sender][agent] = allowanceValue.sub(value);
    }
    emit Approval(msg.sender, agent, _allowances[msg.sender][agent]);
    return true;
  }

   
}

contract Vnk is StandardToken{
   
  address public manager;
  string public name = "vietnam digital ecology";
  string public symbol = "VNK";
  uint8 public decimals = 8;

  address[] public invs;
  uint lastReleased = 0;

  uint256 public releaseTime = 1548508570;  
  uint256 public rate = 100;  


  event Freeze(address indexed from, uint256 value);

   
  event Unfreeze(address indexed from, uint256 value);

  function() public payable
  {

  }

  constructor() public {
    _totalSupply = 600000000 * (10 ** uint256(decimals));

    _balances[msg.sender] = _totalSupply;
    manager = msg.sender;
    emit Transfer(0x0, msg.sender, _totalSupply);
  }

  modifier onlyManager(){ 
    require(msg.sender == manager);
    _;
  }

  function releaseByNum(uint256 num) public onlyManager() returns (bool){ 
    require(num >= 1);
    require(num <= 12);
    require(num == (lastReleased.add(1)));
     
    require(now > (releaseTime.add(num.mul(2592000)) )); 


    for(uint i = 0; i < invs.length; i++)
    {
      uint256 releaseNum = _freezeOf[invs[i]].div( 13 - num );
      _freezeOf[invs[i]] = _freezeOf[invs[i]].sub(releaseNum);
      _balances[invs[i]] = _balances[invs[i]].add(releaseNum);
      emit Freeze(invs[i], releaseNum);
    }
    lastReleased = lastReleased.add(1);

  }

  function releaseByInv(address inv, uint256 num) public onlyManager() returns (bool){ 
    require(num >= 1);
    _freezeOf[inv] = _freezeOf[inv].sub(num);
    _balances[inv] = _balances[inv].add(num);
    emit Freeze(inv, num);
  }

   
  function checkTime(uint256 num) public view returns (bool){
     
    return now > (releaseTime.add(num.mul(2592000)));
  }

  function sendToInv(address inv, uint256 eth) public onlyManager() returns (bool){ 
    uint256 give = eth.mul(rate);
    uint256 firstRealease = give.mul(20).div(100);
    _freezeOf[inv] = give.sub(firstRealease);
    _balances[inv] = firstRealease;
    invs.push(inv);
  }

  function getAllInv() public view onlyManager() returns (address[]){
    return invs;
  }

  function getLastReleased() public view onlyManager() returns (uint256){
    return lastReleased;
  }

  function setRate(uint256 _rate) public onlyManager() returns (bool){
    rate = _rate;
  }

  function setReleaseTime(uint256 _releaseTime) public onlyManager() returns (bool){
    releaseTime = _releaseTime;
  }



  function getRate() public view returns (uint256){
    return rate;
  }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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