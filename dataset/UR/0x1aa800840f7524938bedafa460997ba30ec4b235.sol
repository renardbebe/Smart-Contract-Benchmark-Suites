 

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
  function totalSupply() public view returns (uint256);
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

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
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

contract ConfigurableToken is StandardToken, Ownable {
  uint256 public totalTokens = uint256(1000000000).mul(1 ether);
  uint256 public tokensForSale = uint256(750000000).mul(1 ether);
  uint256 public bountyTokens = uint256(25000000).mul(1 ether);
  uint256 public teamTokens = uint256(100000000).mul(1 ether);
  uint256 public teamReleased = 0;
  uint256 public employeePoolTokens = uint256(50000000).mul(1 ether);
  uint256 public liquidityPoolTokens = uint256(50000000).mul(1 ether);
  uint256 public advisorsTokens = uint256(25000000).mul(1 ether);
  uint256 public advisorsReleased = 0;
  uint256 public listingDate = 0;
  uint256 tokensUnlockPeriod = 2592000;  
  uint256 vestingPeriod = 15724800;  
  address public saleContract;
  address public advisors;
  address public team;
  bool public tokensLocked = true;

  event SaleContractActivation(address saleContract, uint256 tokensForSale);

  event Burn(address tokensOwner, uint256 burnedTokensAmount);

  modifier tokenNotLocked() {
    if (tokensLocked && msg.sender != owner) {
      if (listingDate > 0 && now.sub(listingDate) > tokensUnlockPeriod) {
        tokensLocked = false;
      } else {
        revert();
      }
    }
    _;
  }

  function activateSaleContract(address _saleContract) public onlyOwner {
    require(_saleContract != address(0));
    saleContract = _saleContract;
    balances[saleContract] = balances[saleContract].add(tokensForSale);
    totalSupply_ = totalSupply_.add(tokensForSale);
    require(totalSupply_ <= totalTokens);
    Transfer(address(this), saleContract, tokensForSale);
    SaleContractActivation(saleContract, tokensForSale);
  }

  function isListing() public onlyOwner {
    listingDate = now;
  }

  function transfer(address _to, uint256 _value) public tokenNotLocked returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public tokenNotLocked returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public tokenNotLocked returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public tokenNotLocked returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public tokenNotLocked returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

  function saleTransfer(address _to, uint256 _value) public returns (bool) {
    require(saleContract != address(0));
    require(msg.sender == saleContract);
    return super.transfer(_to, _value);
  }

  function sendBounty(address _to, uint256 _value) public onlyOwner returns (bool) {
    uint256 value = _value.mul(1 ether);
    require(bountyTokens >= value);
    totalSupply_ = totalSupply_.add(value);
    require(totalSupply_ <= totalTokens);
    balances[_to] = balances[_to].add(value);
    bountyTokens = bountyTokens.sub(value);
    Transfer(address(this), _to, value);
    return true;
  }

  function burn(uint256 _value) public onlyOwner returns (bool) {
    uint256 value = _value.mul(1 ether);
    require(balances[owner] >= value);
    require(totalSupply_ >= value);
    balances[owner] = balances[owner].sub(value);
    totalSupply_ = totalSupply_.sub(value);
    Burn(owner, value);
    return true;
  }

  function burnTokensForSale() public returns (bool) {
    require(saleContract != address(0));
    require(msg.sender == saleContract);
    uint256 tokens = balances[saleContract];
    require(tokens > 0);
    require(tokens <= totalSupply_);
    balances[saleContract] =0;
    totalSupply_ = totalSupply_.sub(tokens);
    Burn(saleContract, tokens);
    return true;
  }

  function getVestingPeriodNumber() public view returns (uint256) {
    if (listingDate == 0) return 0;
    return now.sub(listingDate).div(vestingPeriod);
  }

  function releaseAdvisorsTokens() public returns (bool) {
    uint256 vestingPeriodNumber = getVestingPeriodNumber();
    uint256 percents = vestingPeriodNumber.mul(50);
    if (percents > 100) percents = 100;
    uint256 tokensToRelease = advisorsTokens.mul(percents).div(100).sub(advisorsReleased);
    require(tokensToRelease > 0);
    totalSupply_ = totalSupply_.add(tokensToRelease);
    require(totalSupply_ <= totalTokens);
    balances[advisors] = balances[advisors].add(tokensToRelease);
    advisorsReleased = advisorsReleased.add(tokensToRelease);
    require(advisorsReleased <= advisorsTokens);
    Transfer(address(this), advisors, tokensToRelease);
    return true;
  }

  function releaseTeamTokens() public returns (bool) {
    uint256 vestingPeriodNumber = getVestingPeriodNumber();
    uint256 percents = vestingPeriodNumber.mul(25);
    if (percents > 100) percents = 100;
    uint256 tokensToRelease = teamTokens.mul(percents).div(100).sub(teamReleased);
    require(tokensToRelease > 0);
    totalSupply_ = totalSupply_.add(tokensToRelease);
    require(totalSupply_ <= totalTokens);
    balances[team] = balances[team].add(tokensToRelease);
    teamReleased = teamReleased.add(tokensToRelease);
    require(teamReleased <= teamTokens);
    Transfer(address(this), team, tokensToRelease);
    return true;
  }
}

contract IDAP is ConfigurableToken {
  string public constant name = "IDAP";
  string public constant symbol = "IDAP";
  uint32 public constant decimals = 18;

  function IDAP(address _newOwner, address _team, address _advisors) public {
    require(_newOwner != address(0));
    require(_team != address(0));
    require(_advisors != address(0));
    totalSupply_ = employeePoolTokens.add(liquidityPoolTokens); 
    owner = _newOwner;
    team = _team;
    advisors = _advisors;
    balances[owner] = totalSupply_;
    Transfer(address(this), owner, totalSupply_);
  }
}