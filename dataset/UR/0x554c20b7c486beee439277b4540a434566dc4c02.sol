 

pragma solidity ^0.4.15;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}


 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner {
    owner = pendingOwner;
    pendingOwner = 0x0;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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


 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 
contract DecisionToken is MintableToken, Claimable {

  using SafeMath for uint256;

   
  string public constant name = "Decision Token";

   
  string public constant symbol = "HST";

   
  string public constant version = "1.0";

   
  uint8 public constant decimals = 18;

   
   
  uint256 public triggerTime = 0;

   
  modifier onlyWhenReleased() {
    require(now >= triggerTime);
    _;
  }


   
   
  function DecisionToken() MintableToken() {
    owner = msg.sender;
  }

   
   
  function transfer(address _to, uint256 _value) onlyWhenReleased returns (bool) {
    return super.transfer(_to, _value);
  }

   
   
  function transferFrom(address _from, address _to, uint256 _value) onlyWhenReleased returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
   
  function finishMinting() onlyOwner returns (bool) {
    require(triggerTime==0);
    triggerTime = now.add(10 days);
    return super.finishMinting();
  }
}

 

 
 
 
contract DecisionTokenSale is Claimable {
  using SafeMath for uint256;

   
   
  uint256 public startTime;

   
   
  uint256 public endTime;

   
  uint256 public constant presaleTokenRate = 3750;

   
  uint256 public constant earlyBirdTokenRate = 3500;

   
  uint256 public constant secondStageTokenRate = 3250;

   
  uint256 public constant thirdStageTokenRate = 3000;

   
  uint256 public constant tokenCap =  10**9 * 10**18;

   
  uint256 public constant tokenReserve = 4 * (10**8) * 10**18;

   
  DecisionToken public token;

   
  address public wallet;

   
   
  mapping (address => bool) whiteListedForPresale;

   
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

   
  event LogUserAddedToWhiteList(address indexed user);

   
  event LogUserUserRemovedFromWhiteList(address indexed user);


   
   
   
  function DecisionTokenSale(uint256 _startTime, address _wallet) {
    require(_startTime >= now);
    require(_wallet != 0x0);
    startTime = _startTime;
    endTime = startTime.add(14 days);
    wallet = _wallet;

     
    token = createTokenContract();

     
    token.mint(owner, tokenReserve);
  }

   
   
  function createTokenContract() internal returns (DecisionToken) {
    return new DecisionToken();
  }

   
   
  function buyTokens() payable {
    require(msg.sender != 0x0);
    require(msg.value != 0);
    require(whiteListedForPresale[msg.sender] || now >= startTime);
    require(!hasEnded());

     
    uint256 tokens = calculateTokenAmount(msg.value);

    if (token.totalSupply().add(tokens) > tokenCap) {
      revert();
    }

     
    token.mint(msg.sender, tokens);

     
    TokenPurchase(msg.sender, msg.value, tokens);

     
    wallet.transfer(msg.value);
  }

   
  function () payable {
    buyTokens();
  }

   
   
   
   
   
   
   
   
   
   
   
   
   
   
  function calculateTokenAmount(uint256 _weiAmount) internal constant returns (uint256) {
    if (now >= startTime + 8 days) {
      return _weiAmount.mul(thirdStageTokenRate);
    }
    if (now >= startTime + 1 days) {
      return _weiAmount.mul(secondStageTokenRate);
    }
    if (now >= startTime) {
      return _weiAmount.mul(earlyBirdTokenRate);
    }
    return _weiAmount.mul(presaleTokenRate);
  }

   
   
   
   
   
   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

   
   
   
   
  function whiteListAddress(address _buyer) onlyOwner {
    require(_buyer != 0x0);
    whiteListedForPresale[_buyer] = true;
    LogUserAddedToWhiteList(_buyer);
  }

   
   
   
   
  function addWhiteListedAddressesInBatch(address[] _buyers) onlyOwner {
    require(_buyers.length < 1000);
    for (uint i = 0; i < _buyers.length; i++) {
      whiteListAddress(_buyers[i]);
    }
  }

   
   
   
  function removeWhiteListedAddress(address _buyer) onlyOwner {
    whiteListedForPresale[_buyer] = false;
  }

   
   
   
  function destroy() onlyOwner {
    token.finishMinting();
    token.transferOwnership(msg.sender);
    selfdestruct(owner);
  }
}