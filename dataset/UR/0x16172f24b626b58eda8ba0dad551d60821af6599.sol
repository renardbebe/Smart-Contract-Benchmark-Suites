 

pragma solidity ^0.4.24;

 
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

 

 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier stopNonOwnersInEmergency {
    require(!halted && msg.sender == owner);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 

contract iCrowdCoin is StandardToken, Ownable, Haltable {

   
  string public constant name = "iCrowdCoin";
  string public constant symbol = "ICC";
  uint8 public constant decimals = 18;

    
  mapping (address => bool) public distributors;

  event Distribute(address indexed to, uint256 amount);
  event DistributeOpened();
  event DistributeFinished();
  event DistributorChanged(address addr, bool state);
  event BurnToken(address addr,uint256 amount);
   
  event WithdrowErc20Token (address indexed erc20, address indexed wallet, uint value);

  bool public distributionFinished = false;

  modifier canDistribute() {
    require(!distributionFinished);
    _;
  }
   
  modifier onlyDistributor() {
    require(distributors[msg.sender]);
    _;
  }


  constructor (uint256 _amount) public {
    totalSupply_ = totalSupply_.add(_amount);
    balances[address(this)] = _amount;
  }

   
  function setDistributor(address addr, bool state) public onlyOwner canDistribute {
    distributors[addr] = state;
    emit DistributorChanged(addr, state);
  }


   
  function distribute(address _to, uint256 _amount) public onlyDistributor canDistribute {
    require(balances[address(this)] >= _amount);

    balances[address(this)] = balances[address(this)].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    
    emit Distribute(_to, _amount);
    emit Transfer(address(0), _to, _amount);
  }

 
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

   
  function _burn(address _addr,uint256 _amount) internal  {
    require(balances[_addr] >= _amount);

    balances[_addr] = balances[_addr].sub(_amount);
    totalSupply_ = totalSupply_.sub(_amount);

    emit BurnToken(_addr,_amount);
    emit Transfer(_addr, address(0), _amount);
  }

   
  function openDistribution() public onlyOwner {
    distributionFinished = false;
    emit DistributeOpened();
  }

  
  function distributionFinishing() public onlyOwner {
    distributionFinished = true;
    emit DistributeFinished();
  }

  function withdrowErc20(address _tokenAddr, address _to, uint _value) public onlyOwner {
    ERC20 erc20 = ERC20(_tokenAddr);
    erc20.transfer(_to, _value);
    emit WithdrowErc20Token(_tokenAddr, _to, _value);
  }

   
  function transfer(address _to, uint256 _value) public stopInEmergency returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public stopInEmergency returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public stopInEmergency returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public stopInEmergency returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public stopInEmergency returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}