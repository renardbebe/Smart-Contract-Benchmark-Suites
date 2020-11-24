 

pragma solidity ^0.4.18;

 
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

 
contract YOUToken is StandardToken, Ownable {

  string public constant name = "YOU Chain";
  string public constant symbol = "YOU";
  uint8 public constant decimals = 18;

  uint256 private constant TOKEN_UNIT = 10 ** uint256(decimals);
  uint256 private constant INITIAL_SUPPLY = 32 * (10 ** 8) * TOKEN_UNIT;

  uint256 private constant ANGEL_SUPPLY                 = INITIAL_SUPPLY * 10 / 100;   
  uint256 private constant PRIVATE_SUPPLY               = INITIAL_SUPPLY * 20 / 100;   
  uint256 private constant TEAM_SUPPLY                  = INITIAL_SUPPLY * 15 / 100;   
  uint256 private constant FOUNDATION_SUPPLY            = INITIAL_SUPPLY * 25 / 100;   
  uint256 private constant COMMUNITY_SUPPLY	            = INITIAL_SUPPLY * 30 / 100;   
  
  uint256 private constant ANGEL_SUPPLY_VESTING         = ANGEL_SUPPLY * 80 / 100;     
  struct VestingGrant {
        address beneficiary;
        uint256 start;
        uint256 duration;  
        uint256 amount;  
        uint256 transfered;  
        uint8 releaseCount;  
  }

  address public constant ANGEL_ADDRESS = 0xAe195643020657B00d7DE6Cb98dE091A856059Cf;  
  address public constant PRIVATE_ADDRESS = 0x3C69915E58b972e4D17cc1e657b834EB7E9127A8;  
  address public constant TEAM_ADDRESS = 0x781204E71681D2d70b3a46201c6e60Af93372a31;  
  address public constant FOUNDATION_ADDRESS = 0xFC6423B399fC99E6ED044Ab5E872cAA915845A6f;  
  address public constant COMMUNITY_ADDRESS = 0x790F7bd778d5c81aaD168598004728Ca8AF1b0A0;  

  VestingGrant angelVestingGrant;
  VestingGrant teamVestingGrant;
  bool angelFirstVested = false;

  function YOUToken() public {

    totalSupply = PRIVATE_SUPPLY.add(FOUNDATION_SUPPLY).add(COMMUNITY_SUPPLY);
    balances[PRIVATE_ADDRESS] = PRIVATE_SUPPLY;
    balances[FOUNDATION_ADDRESS] = FOUNDATION_SUPPLY;
    balances[COMMUNITY_ADDRESS] = COMMUNITY_SUPPLY;

    angelVestingGrant = makeGrant(ANGEL_ADDRESS, now + 1 days, (30 days), ANGEL_SUPPLY_VESTING, 4);
    teamVestingGrant = makeGrant(TEAM_ADDRESS, now + 1 days, (30 days), TEAM_SUPPLY, 60);
  }

  function releaseAngelFirstVested() public onlyOwner {
    require(!angelFirstVested && now >= angelVestingGrant.start);
    uint256 angelFirstSupplyBalance = ANGEL_SUPPLY.sub(ANGEL_SUPPLY_VESTING);
    totalSupply = totalSupply.add(angelFirstSupplyBalance);
    balances[angelVestingGrant.beneficiary] = angelFirstSupplyBalance;
    angelFirstVested = true;
    emit Transfer(address(0), angelVestingGrant.beneficiary, angelFirstSupplyBalance);
  }

  function releaseAngelVested() public onlyOwner {
     releaseVestingGrant(angelVestingGrant);
  }

  function releaseTeamVested() public onlyOwner {
     releaseVestingGrant(teamVestingGrant);
  }

  function makeGrant(address _beneficiary, uint256 _start, uint256 _duration, uint256 _amount, uint8 _releaseCount)
    internal pure returns (VestingGrant) 
    {
    return VestingGrant({beneficiary : _beneficiary, start: _start, duration:_duration, amount:_amount, transfered:0, releaseCount:_releaseCount});
  }

  function releasableAmount(uint256 time, VestingGrant grant) internal pure returns (uint256) {
    if (grant.amount == grant.transfered) {
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

  function releaseVestingGrant(VestingGrant storage grant) internal {
    uint256 amount = releasableAmount(now, grant);
    require(amount > 0);

    grant.transfered = grant.transfered.add(amount);
    totalSupply = totalSupply.add(amount);
    balances[grant.beneficiary] = balances[grant.beneficiary].add(amount);
    emit Transfer(address(0), grant.beneficiary, amount);
  }
}