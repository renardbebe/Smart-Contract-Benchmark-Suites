 

pragma solidity ^0.4.18;

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

contract BurnableToken is StandardToken {
  event Burn(address indexed burner, uint256 value);
  function burn(uint256 _value) public {
    require(_value > 0);
    require(_value <= balances[msg.sender]);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }
}
contract SpaceKIMToken is BurnableToken {
  string public constant name = "Space KIM Token";
  string public constant symbol = "KIM";
  uint32 public constant decimals = 0;
  uint256 public constant INITIAL_SUPPLY = 37900000;
  function SpaceKIMToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}

contract Crowdsale is Ownable {

  using SafeMath for uint;

  SpaceKIMToken public token = new SpaceKIMToken();

  address multisig;
  address restricted;

  uint statusPreSale = 0;

  uint rate;
  uint minAmount;

  uint saleStartDate;
  uint saleFinishDate;

  uint olympStartDate;
  uint olympEndDate;

  uint percentsTeamTokens;
  uint percentsPreSaleTokens;
  uint percentsBountySecondTokens;
  uint percentsOlympicTokens;

  uint endCrowdsaleDate;

  modifier saleIsOn() {
    uint curState = getStatus();
    require(curState != 0 && curState != 5 && curState != 3);
    _;
  }

  modifier isUnderHardCap() {
    uint _availableTokens = token.balanceOf(this);
    uint _tokens = calculateTokens(msg.value);
    uint _minTokens = holdTokensOnStage();
    require(_availableTokens.sub(_tokens) >= _minTokens);
    _;
  }

  modifier checkMinAmount() {
    require(msg.value >= minAmount);
    _;
  }
  function Crowdsale() public {
    multisig = 0x381b16397eF8fB8FFF65F6d3B6E5979C9d38fe40;
    restricted = 0x381b16397eF8fB8FFF65F6d3B6E5979C9d38fe40;
    minAmount = 0.01 * 1 ether;
    rate = 10000;

    saleStartDate = 1515974400;  
    saleFinishDate = 1517961600;  
     
    olympStartDate = 1518134400;  
    olympEndDate = 1519516800;  
     
    endCrowdsaleDate = 1519948800;  

    percentsTeamTokens = 20;
    percentsBountySecondTokens = 5;
    percentsPreSaleTokens = 30;
    percentsOlympicTokens = 15;
  }

  function calculateTokens(uint value) internal constant returns (uint) {
    uint tokens = rate.mul(value).div(1 ether);
    if(getStatus() == 1){
      tokens += tokens.div(2);
    }
    return tokens;
  }

   
   
   
   
   
   
  function getStatus() internal constant returns (uint8) {
    if(now > endCrowdsaleDate) {
      return 0;
    } else if(now > olympEndDate && now < endCrowdsaleDate) {
      return 5;
    } else if(now > olympStartDate && now < olympEndDate) {
      return 4;
    } else if(now > saleFinishDate && now < olympStartDate) {
      return 3;
    } else if(now > saleStartDate && now < saleFinishDate) {
      return 2;
    } else if(statusPreSale == 1){
      return 1;
    } else {
      return 0;
    }
  }

  function holdTokensOnStage() public view returns (uint) {
    uint _totalSupply = token.totalSupply();
    uint _percents = 100;
    uint curState = getStatus();
    if(curState == 5) {
      _percents = percentsTeamTokens; 
    } else if(curState == 4) {
      _percents = percentsTeamTokens.add(percentsBountySecondTokens); 
    } else if(curState == 3) {
      _percents = percentsTeamTokens.add(percentsBountySecondTokens).add(percentsOlympicTokens); 
    } else if(curState == 2) {
      _percents = percentsTeamTokens.add(percentsBountySecondTokens).add(percentsOlympicTokens); 
    } else if(curState == 1) {
      _percents = _percents.sub(percentsPreSaleTokens); 
    }
    return _totalSupply.mul(_percents).div(100);
  }

  function onBalance() public view returns (uint) {
    return token.balanceOf(this);
  }

  function availableTokensOnCurrentStage() public view returns (uint) {
    uint _currentHolder = token.balanceOf(this);
    uint _minTokens = holdTokensOnStage();
    return _currentHolder.sub(_minTokens);
  }

  function getStatusInfo() public view returns (string) {
    uint curState = getStatus();
    if(now > endCrowdsaleDate) {
      return "Crowdsale is over";
    } else if(curState == 5) {
      return "Now Bounty #2 token distribution is active";
    } else if(curState == 4) {
      return "Now Olympic Special (ICO #2) is active";
    } else if(curState == 3) {
      return "Now Bounty #1 token distribution is active";
    } else if(curState == 2) {
      return "Now ICO #1 is active";
    } else if(curState == 1) {
      return "Now Pre-ICO is active";
    } else {
      return "The sale of tokens is stopped";
    }
  }

  function setStatus(uint8 newStatus) public onlyOwner {
    require(newStatus == 1 || newStatus == 0);
    statusPreSale = newStatus;
  }

  function burnTokens() public onlyOwner {
    require(now > endCrowdsaleDate);
    uint _totalSupply = token.totalSupply();
    uint _teamTokens = _totalSupply.mul(percentsTeamTokens).div(100);
    token.transfer(restricted, _teamTokens);
    uint _burnTokens = token.balanceOf(this);
    token.burn(_burnTokens);
  }

  function sendTokens(address to, uint tokens) public onlyOwner {
    uint curState = getStatus();
    require(curState == 5 || curState == 3);
    uint _minTokens = holdTokensOnStage();
    require(token.balanceOf(this).sub(tokens) >=  _minTokens);
    token.transfer(to, tokens);
  }

  function createTokens() public saleIsOn isUnderHardCap checkMinAmount payable {
    uint tokens = calculateTokens(msg.value);
    multisig.transfer(msg.value);
    token.transfer(msg.sender, tokens);
  }

  function() external payable {
    createTokens();
  }
}