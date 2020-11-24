 

pragma solidity ^0.4.18;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
library Math {
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

contract Auscoin is StandardToken, Ownable {
   
  string public name = "AUSCOIN COIN";
   
  string public symbol = "AUSC";
   
  uint8 public decimals = 18;
   
  uint256 million = 1000000 * (uint256(10) ** decimals);
   
  uint256 public totalSupply = 100 * million;
   
  uint256 public exchangeRate;
   
  uint256 public totalEthRaised = 0;
   
  uint256 public startTime;
   
  uint256 public endTime;
   
  uint256 public ausGroupReleaseDate;
   
  address public fundsWallet;
   
  address public bonusWallet;
   
  address public ausGroup;
   
  address public whiteLister;

   
  uint256 public ausGroupAllocation = 50 * million;
  uint256 public bountyAllocation = 1 * million;
  uint256 public preSeedAllocation = 3 * million;
  uint256 public bonusAllocation = 6 * million;

   
   
  mapping (address => bool) public whiteListed;

   
  mapping (address => bool) isICOParticipant;

   
  uint256 numberOfMillisecsPerYear = 365 * 24 * 60 * 60 * 1000;
  uint256 amountPerYearAvailableToAusGroup = 5 * million;

  function Auscoin(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _ausGroupReleaseDate,
    uint256 _exchangeRate,
    address _bonusWallet,
    address _ausGroup,
    address _bounty,
    address _preSeedFund,
    address _whiteLister
  )
    public
  {
    fundsWallet = owner;
    bonusWallet = _bonusWallet;
    startTime = _startTime;
    endTime = _endTime;  
    ausGroupReleaseDate = _ausGroupReleaseDate;
    exchangeRate = _exchangeRate;
    ausGroup = _ausGroup;
    whiteLister = _whiteLister;

     
     
     
    balances[fundsWallet] = totalSupply;
    Transfer(0x0, fundsWallet, totalSupply);

     
     
     
     
    super.transfer(bonusWallet, bonusAllocation);

     
    super.transfer(_ausGroup, ausGroupAllocation);

     
    super.transfer(_bounty, bountyAllocation);

     
    super.transfer(_preSeedFund, preSeedAllocation);
  }

   
  function currentTime() public view returns (uint256) {
    return now * 1000;
  }

   
  function calculateBonusAmount(uint256 amount) view internal returns (uint256) {
    uint256 totalAvailableDuringICO = totalSupply - (bonusAllocation + ausGroupAllocation + bountyAllocation + preSeedAllocation);
    uint256 sold = totalAvailableDuringICO - balances[fundsWallet];

    uint256 amountForThirtyBonusBracket = int256((10 * million) - sold) > 0 ? (10 * million) - sold : 0;
    uint256 amountForTwentyBonusBracket = int256((20 * million) - sold) > 0 ? (20 * million) - sold : 0;
    uint256 amountForTenBonusBracket = int256((30 * million) - sold) > 0 ? (30 * million) - sold : 0;

    uint256 thirtyBonusBracket = Math.min256(Math.max256(0, amountForThirtyBonusBracket), Math.min256(amount, (10 * million)));
    uint256 twentyBonusBracket = Math.min256(Math.max256(0, amountForTwentyBonusBracket), Math.min256(amount - thirtyBonusBracket, (10 * million)));
    uint256 tenBonusBracket = Math.min256(Math.max256(0, amountForTenBonusBracket), Math.min256(amount - twentyBonusBracket - thirtyBonusBracket, (10 * million)));

    uint256 totalBonus = thirtyBonusBracket.mul(30).div(100) + twentyBonusBracket.mul(20).div(100) + tenBonusBracket.mul(10).div(100);

    return totalBonus;
  }

   
   
   
   
  function() isIcoOpen payable public {
    buyTokens();
  }

  function buyTokens() isIcoOpen payable public {
     
    uint256 tokenAmount = msg.value.mul(exchangeRate);
     
    uint256 bonusAmount = calculateBonusAmount(tokenAmount);
     
    require(balances[fundsWallet] >= tokenAmount);
     
    require(balances[bonusWallet] >= bonusAmount);

     
    totalEthRaised = totalEthRaised.add(msg.value);

     
    balances[bonusWallet] = balances[bonusWallet].sub(bonusAmount);
    balances[fundsWallet] = balances[fundsWallet].sub(tokenAmount);
     
    balances[msg.sender] = balances[msg.sender].add(tokenAmount.add(bonusAmount));

     
    isICOParticipant[msg.sender] = true;

    fundsWallet.transfer(msg.value);

     
    Transfer(fundsWallet, msg.sender, tokenAmount);
    Transfer(bonusWallet, msg.sender, bonusAmount);
  }

  function addToWhiteList(address _purchaser) canAddToWhiteList public {
    whiteListed[_purchaser] = true;
  }

  function setWhiteLister(address _newWhiteLister) onlyOwner public {
    whiteLister = _newWhiteLister;
  }

   
  function transfer(address _to, uint _value) isIcoClosed public returns (bool success) {
    require(msg.sender != ausGroup);
    if (isICOParticipant[msg.sender]) {
      require(whiteListed[msg.sender]);
    }
    return super.transfer(_to, _value);
  }

  function ausgroupTransfer(address _to, uint _value) timeRestrictedAccess isValidAusGroupTransfer(_value) public returns (bool success) {
    require(msg.sender == ausGroup);
    require(balances[ausGroup] >= _value);
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) isIcoClosed public returns (bool success) {
    require(_from != ausGroup);
    if (isICOParticipant[_from]) {
      require(whiteListed[_from]);
    }
    return super.transferFrom(_from, _to, _value);
  }

  function burnUnsoldTokens() isIcoClosed onlyOwner public {
    uint256 bonusLeft = balances[bonusWallet];
    uint256 fundsLeft = balances[fundsWallet];
     
    balances[bonusWallet] = 0;
    balances[fundsWallet] = 0;
    Transfer(bonusWallet, 0, bonusLeft);
    Transfer(fundsWallet, 0, fundsLeft);
  }

   
  modifier isIcoOpen() {
    require(currentTime() >= startTime);
    require(currentTime() < endTime);
    _;
  }

  modifier isIcoClosed() {
    require(currentTime() >= endTime);
    _;
  }

  modifier timeRestrictedAccess() {
    require(currentTime() >= ausGroupReleaseDate);
    _;
  }

  modifier canAddToWhiteList() {
    require(msg.sender == whiteLister);
    _;
  }

  modifier isValidAusGroupTransfer(uint256 _value) {
    uint256 yearsAfterRelease = ((currentTime() - ausGroupReleaseDate) / numberOfMillisecsPerYear) + 1;
    uint256 cumulativeTotalAvailable = yearsAfterRelease * amountPerYearAvailableToAusGroup;
    require(cumulativeTotalAvailable > 0);
    uint256 amountAlreadyTransferred = ausGroupAllocation - balances[ausGroup];
    uint256 amountAvailable = cumulativeTotalAvailable - amountAlreadyTransferred;
    require(_value <= amountAvailable);
    _;
  }
}