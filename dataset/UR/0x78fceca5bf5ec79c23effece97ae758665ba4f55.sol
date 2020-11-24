 

pragma solidity ^0.4.21;

 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
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

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}

 
contract YouDealToken is PausableToken {

  string public constant name = "YouDeal Token";
  string public constant symbol = "YD";
  uint8 public constant decimals = 18;

  uint256 private constant TOKEN_UNIT = 10 ** uint256(decimals);
  uint256 private constant INITIAL_SUPPLY = 10500000000 * TOKEN_UNIT;

  uint256 private constant PRIVATE_SALE_SUPPLY = INITIAL_SUPPLY * 25 / 100;   
  uint256 private constant COMMUNITY_REWARDS_SUPPLY = INITIAL_SUPPLY * 40 / 100;   
  uint256 private constant FOUNDATION_SUPPLY = INITIAL_SUPPLY * 20 / 100;   
  uint256 private constant TEAM_SUPPLY = INITIAL_SUPPLY * 15 / 100;   

  struct VestingGrant {
        address beneficiary;
        uint256 start;
        uint256 duration;  
        uint256 amount;  
        uint256 transfered;  
        uint8 releaseCount;  
  }

  address private constant PRIVAYE_SALE_ADDRESS = 0x65158a7270b58fd9499bE7E95feFBF2169360728;  
  address private constant COMMUNITY_REWARDS_ADDRESS = 0xDFE95879606F520CaC6a3546FE2f0d8BBC10A32b;  
  address private constant FOUNDATION_ADDRESS = 0xC138e8A6763e78fA0fFAD6c392D01e37CF3fdf27;  

  VestingGrant teamVestingGrant;

   
  function YouDealToken() public {
    totalSupply =  INITIAL_SUPPLY;

    balances[PRIVAYE_SALE_ADDRESS] = PRIVATE_SALE_SUPPLY;
    balances[COMMUNITY_REWARDS_ADDRESS] = COMMUNITY_REWARDS_SUPPLY;
    balances[FOUNDATION_ADDRESS] = FOUNDATION_SUPPLY;

    teamVestingGrant = founderGrant(msg.sender, now.add(150 days), (30 days), TEAM_SUPPLY, 30);  
  }

  function founderGrant(address _beneficiary, uint256 _start, uint256 _duration, uint256 _amount, uint8 _releaseCount)
    internal pure returns  (VestingGrant) {
      return VestingGrant({ beneficiary : _beneficiary, start: _start, duration:_duration, amount:_amount, transfered:0, releaseCount:_releaseCount});
  }

  function releaseTeamVested() public onlyOwner {
      relaseVestingGrant(teamVestingGrant);
  }

  function releasableAmount(uint256 time, VestingGrant grant) internal pure returns (uint256) {
      if (grant.amount == grant.transfered) {
          return 0;
      }
	  if (time < grant.start) {
          return 0;
      }
      uint256 amountPerRelease = grant.amount.div(grant.releaseCount);
      uint256 amount = amountPerRelease.mul((time.sub(grant.start)).div(grant.duration));
      if (amount > grant.amount) {
        amount = grant.amount;
      }
      amount = amount.sub(grant.transfered);
      return amount;
  }

  function relaseVestingGrant(VestingGrant storage grant) internal {
      uint256 amount = releasableAmount(now, grant);
      require(amount > 0);

      grant.transfered = grant.transfered.add(amount);
      balances[grant.beneficiary] = balances[grant.beneficiary].add(amount);
      emit Transfer(address(0), grant.beneficiary, amount);
  }

}