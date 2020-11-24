 

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
    Transfer(msg.sender, _to, _value);
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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract GRCToken is StandardToken, Ownable {

  string public constant name = "Green Chain";
  string public constant symbol = "GRC";
  uint8 public constant decimals = 18;

  uint256 private constant TOKEN_UNIT = 10 ** uint256(decimals);
  uint256 private constant INITIAL_SUPPLY = (10 ** 9) * TOKEN_UNIT;

  uint256 private constant PRIVATE_SALE_SUPPLY = INITIAL_SUPPLY * 35 / 100;   
  uint256 private constant COMMUNITY_REWARDS_SUPPLY = INITIAL_SUPPLY * 20 / 100;   
  uint256 private constant COMMERCIAL_PLAN_SUPPLY = INITIAL_SUPPLY * 20 / 100;   
  uint256 private constant FOUNDATION_SUPPLY = INITIAL_SUPPLY * 15 / 100;   
  uint256 private constant TEAM_SUPPLY = INITIAL_SUPPLY * 10 / 100;   

  struct VestingGrant {
        address beneficiary;
        uint256 start;
        uint256 duration;  
        uint256 amount;  
        uint256 transfered;  
        uint8 releaseCount;  
  }

  address private constant PRIVAYE_SALE_ADDRESS = 0x2bC86DE64915873A8523073d25a292E204228156;  
  address private constant COMMUNITY_REWARDS_ADDRESS = 0x6E204E498084013c1ba4071D7d61074467378855;  
  address private constant COMMERCIAL_PLAN_ADDRESS = 0x6E204E498084013c1ba4071D7d61074467378855;  
  address private constant FOUNDATION_ADDRESS = 0xf88BB479b9065D6f82AC21E857f75Ba648EcBdA7;  

  VestingGrant teamVestingGrant;

   
  function GRCToken() public {
    totalSupply =  INITIAL_SUPPLY;

    balances[PRIVAYE_SALE_ADDRESS] = PRIVATE_SALE_SUPPLY;
    balances[COMMUNITY_REWARDS_ADDRESS] = COMMUNITY_REWARDS_SUPPLY;
    balances[COMMERCIAL_PLAN_ADDRESS] = COMMERCIAL_PLAN_SUPPLY;
    balances[FOUNDATION_ADDRESS] = FOUNDATION_SUPPLY;

    teamVestingGrant = makeGrant(msg.sender, now, (182 days), TEAM_SUPPLY, 4);  
  }

  function makeGrant(address _beneficiary, uint256 _start, uint256 _duration, uint256 _amount, uint8 _releaseCount)
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
      totalSupply = totalSupply.add(amount);
      balances[grant.beneficiary] = balances[grant.beneficiary].add(amount);
      Transfer(address(0), grant.beneficiary, amount);
    }
}