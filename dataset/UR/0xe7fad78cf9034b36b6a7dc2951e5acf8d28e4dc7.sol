 

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


contract CryptoAngelConstants {

  string constant TOKEN_NAME = "CryptoAngel";
  string constant TOKEN_SYMBOL = "ANGEL";
  uint constant TOKEN_DECIMALS = 18;
  uint8 constant TOKEN_DECIMALS_UINT8 = uint8(TOKEN_DECIMALS);
  uint constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;

  uint constant TEAM_TOKENS =   18000000 * TOKEN_DECIMAL_MULTIPLIER;
  uint constant HARD_CAP_TOKENS =   88000000 * TOKEN_DECIMAL_MULTIPLIER;
  uint constant MINIMAL_PURCHASE = 0.05 ether;
  uint constant RATE = 1000;  

  address constant TEAM_ADDRESS = 0x6941A0FD30198c70b3872D4d1b808e4bFc5A07E1;
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
    require(_value > 0);
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


 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
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

   
  function burnFrom(address _from, uint256 _value) public returns (bool) {
      require(_value > 0);
      var allowance = allowed[_from][msg.sender];
      require(allowance >= _value);
      balances[_from] = balances[_from].sub(_value);
      totalSupply = totalSupply.sub(_value);
      allowed[_from][msg.sender] = allowance.sub(_value);
      Burn(_from, _value);
      return true;
  }
}


contract CryptoAngel is CryptoAngelConstants, MintableToken, BurnableToken {

  mapping (address => bool) public frozenAccount;

  event FrozenFunds(address target, bool frozen);

   
  function freezeAccount(address target, bool freeze) public onlyOwner {
      frozenAccount[target] = freeze;
      FrozenFunds(target, freeze);
  }
    
   
  function name() pure public returns (string _name) {
      return TOKEN_NAME;
  }

   
  function symbol() pure public returns (string _symbol) {
      return TOKEN_SYMBOL;
  }

   
  function decimals() pure public returns (uint8 _decimals) {
      return TOKEN_DECIMALS_UINT8;
  }

   
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        require(!frozenAccount[_to]);
        super.mint(_to, _amount);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!frozenAccount[msg.sender]);
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        return super.transferFrom(_from, _to, _value);
    }
}

 
contract Crowdsale is CryptoAngelConstants{
  using SafeMath for uint256;

   
  CryptoAngel public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  uint public hardCap;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    hardCap = HARD_CAP_TOKENS;
    wallet = _wallet;
    rate = RATE;
  }

   
  function createTokenContract() internal returns (CryptoAngel) {
    return new CryptoAngel();
  }

   
  function() public payable {
    buyTokens(msg.sender, msg.value);
  }

   
  function buyTokens(address beneficiary, uint256 weiAmount) internal {
    require(beneficiary != address(0));
    require(validPurchase(weiAmount, token.totalSupply()));

     
    uint256 tokens = calculateTokens(token.totalSupply(), weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds(weiAmount);
  }

   
  function calculateTokens(uint256 totalTokens, uint256 weiAmount) internal view returns (uint256) {

    uint256 numOfTokens = weiAmount.mul(RATE);

    if (totalTokens <= hardCap.mul(30).div(100)) {  
        numOfTokens += numOfTokens.mul(30).div(100);
    }
    else if (totalTokens <= hardCap.mul(45).div(100)) {  
        numOfTokens += numOfTokens.mul(20).div(100);
    }
    else if (totalTokens <= hardCap.mul(60).div(100)) {  
        numOfTokens += numOfTokens.mul(10).div(100);
    }  
   return numOfTokens;
  }

   
   
  function forwardFunds(uint amountWei) internal {
    wallet.transfer(amountWei);
  }

   
  function validPurchase(uint _amountWei, uint _totalSupply) internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonMinimalPurchase = _amountWei >= MINIMAL_PURCHASE;
    bool hardCapNotReached = _totalSupply <= hardCap;
    return withinPeriod && nonMinimalPurchase && hardCapNotReached;
  }

   
  function hasEnded() internal view returns (bool) {
    return now > endTime;
  }
}


 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  function FinalizableCrowdsale(uint _startTime, uint _endTime, address _wallet) public
            Crowdsale(_startTime, _endTime, _wallet) {
    }

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());
    isFinalized = true;
    token.finishMinting();
    token.transferOwnership(owner);
    Finalized();
  }

  modifier notFinalized() {
    require(!isFinalized);
    _;
  }
}


contract CryptoAngelCrowdsale is CryptoAngelConstants, FinalizableCrowdsale {

    function CryptoAngelCrowdsale(
            uint _startTime,
            uint _endTime,
            address _wallet
    ) public
        FinalizableCrowdsale(_startTime, _endTime, _wallet) {
        token.mint(TEAM_ADDRESS, TEAM_TOKENS);
    }

   
    function setStartTime(uint256 _startTime) public onlyOwner notFinalized {
        require(_startTime < endTime);
        startTime = _startTime;
    }

   
    function setEndTime(uint256 _endTime) public onlyOwner notFinalized {
        require(_endTime > startTime);
        endTime = _endTime;
    }

   
    function setHardCap(uint256 _hardCapTokens) public onlyOwner notFinalized {
        require(_hardCapTokens * TOKEN_DECIMAL_MULTIPLIER > hardCap);
        hardCap = _hardCapTokens * TOKEN_DECIMAL_MULTIPLIER;
    }
}