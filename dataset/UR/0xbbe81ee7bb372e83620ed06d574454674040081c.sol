 

pragma solidity 0.4.17;
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract Ownable {
  address internal owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  function Ownable() public {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
 
 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  mapping(address => bool) blockListed;
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    
    require(
        balances[msg.sender] >= _value
        && _value > 0
        && !blockListed[_to]
        && !blockListed[msg.sender]
    );
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(
            balances[msg.sender] >= _value
            && balances[_from] >= _value
            && _value > 0
            && !blockListed[_to]
            && !blockListed[msg.sender]
    );
    uint256 _allowance = allowed[_from][msg.sender];
     
     
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(msg.sender, _to, _amount);
    return true;
  }
   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
    function addBlockeddUser(address user) public onlyOwner {
        blockListed[user] = true;
    }
    function removeBlockeddUser(address user) public onlyOwner  {
        blockListed[user] = false;
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
    Pause();
  }
   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
 
contract Crowdsale is Ownable, Pausable {
  using SafeMath for uint256;
   
  MintableToken internal token;
  address internal wallet;
  uint256 public rate;
  uint256 internal weiRaised;
   
  
  uint256 public privateSaleStartTime;
  uint256 public privateSaleEndTime;
  uint256 public preSaleStartTime;
  uint256 public preSaleEndTime;
  uint256 public preICOStartTime;
  uint256 public preICOEndTime;
  uint256 public ICOstartTime;
  uint256 public ICOEndTime;
  
   
  uint256 internal privateSaleBonus;
  uint256 internal preSaleBonus;
  uint256 internal preICOBonus;
  uint256 internal firstWeekBonus;
  uint256 internal secondWeekBonus;
  uint256 internal thirdWeekBonus;
  uint256 internal forthWeekBonus;
  uint256 internal fifthWeekBonus;
  uint256 internal weekOne;
  uint256 internal weekTwo;
  uint256 internal weekThree;
  uint256 internal weekFour;
  uint256 internal weekFive;
  uint256 internal privateSaleTarget;
  uint256 public preSaleTarget;
  uint256 internal preICOTarget;
   
  uint256 public totalSupply = SafeMath.mul(400000000, 1 ether);
  uint256 internal publicSupply = SafeMath.mul(SafeMath.div(totalSupply,100),55);
  uint256 internal bountySupply = SafeMath.mul(SafeMath.div(totalSupply,100),6);
  uint256 internal reservedSupply = SafeMath.mul(SafeMath.div(totalSupply,100),39);
  uint256 internal privateSaleSupply = SafeMath.mul(24750000, 1 ether);
  uint256 public preSaleSupply = SafeMath.mul(39187500, 1 ether);
  uint256 internal preICOSupply = SafeMath.mul(39187500, 1 ether);
  uint256 internal icoSupply = SafeMath.mul(116875000, 1 ether);
   
  bool public checkUnsoldTokens;
  bool internal upgradePreSaleSupply;
  bool internal upgradePreICOSupply;
  bool internal upgradeICOSupply;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
   
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) internal {
    
    require(_wallet != 0x0);
    token = createTokenContract();
     
     
    preSaleStartTime = _startTime;
    preSaleEndTime = 1541581199;
    preICOStartTime = 1541581200;
    preICOEndTime = 1544000399; 
    ICOstartTime = 1544000400;
    ICOEndTime = _endTime;
    rate = _rate;
    wallet = _wallet;
     
    preSaleBonus = SafeMath.div(SafeMath.mul(rate,30),100);
    preICOBonus = SafeMath.div(SafeMath.mul(rate,30),100);
    firstWeekBonus = SafeMath.div(SafeMath.mul(rate,20),100);
    secondWeekBonus = SafeMath.div(SafeMath.mul(rate,15),100);
    thirdWeekBonus = SafeMath.div(SafeMath.mul(rate,10),100);
    forthWeekBonus = SafeMath.div(SafeMath.mul(rate,5),100);
    
    weekOne = SafeMath.add(ICOstartTime, 14 days);
    weekTwo = SafeMath.add(weekOne, 14 days);
    weekThree = SafeMath.add(weekTwo, 14 days);
    weekFour = SafeMath.add(weekThree, 14 days);
    weekFive = SafeMath.add(weekFour, 14 days);
    privateSaleTarget = SafeMath.mul(4500, 1 ether);
    preSaleTarget = SafeMath.mul(7125, 1 ether);
    preICOTarget = SafeMath.mul(7125, 1 ether);
    checkUnsoldTokens = false;
    upgradeICOSupply = false;
    upgradePreICOSupply = false;
    upgradePreSaleSupply = false;
  
  }
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  
   
  function () payable {
    buyTokens(msg.sender);
  }
     
   
        
   
   
   
   
   
   
   
   
   
   
  function preSaleTokens(uint256 weiAmount, uint256 tokens) internal returns (uint256) {
        
    require(preSaleSupply > 0);
    require(weiAmount <= preSaleTarget);
    if (!upgradePreSaleSupply) {
      preSaleSupply = SafeMath.add(preSaleSupply, privateSaleSupply);
      preSaleTarget = SafeMath.add(preSaleTarget, privateSaleTarget);
      upgradePreSaleSupply = true;
    }
    tokens = SafeMath.add(tokens, weiAmount.mul(preSaleBonus));
    tokens = SafeMath.add(tokens, weiAmount.mul(rate));
    require(preSaleSupply >= tokens);
    preSaleSupply = preSaleSupply.sub(tokens);        
    preSaleTarget = preSaleTarget.sub(weiAmount);
    return tokens;
  }
   
  function preICOTokens(uint256 weiAmount, uint256 tokens) internal returns (uint256) {
        
    require(preICOSupply > 0);
    require(weiAmount <= preICOTarget);
    if (!upgradePreICOSupply) {
      preICOSupply = SafeMath.add(preICOSupply, preSaleSupply);
      preICOTarget = SafeMath.add(preICOTarget, preSaleTarget);
      upgradePreICOSupply = true;
    }
    tokens = SafeMath.add(tokens, weiAmount.mul(preICOBonus));
    tokens = SafeMath.add(tokens, weiAmount.mul(rate));
    
    require(preICOSupply >= tokens);
    
    preICOSupply = preICOSupply.sub(tokens);        
    preICOTarget = preICOTarget.sub(weiAmount);
    return tokens;
  }
   
  
  function icoTokens(uint256 weiAmount, uint256 tokens, uint256 accessTime) internal returns (uint256) {
        
    require(icoSupply > 0);
    if (!upgradeICOSupply) {
      icoSupply = SafeMath.add(icoSupply,preICOSupply);
      upgradeICOSupply = true;
    }
    
    if (accessTime <= weekOne) {
      tokens = SafeMath.add(tokens, weiAmount.mul(firstWeekBonus));
    } else if (accessTime <= weekTwo) {
      tokens = SafeMath.add(tokens, weiAmount.mul(secondWeekBonus));
    } else if ( accessTime < weekThree ) {
      tokens = SafeMath.add(tokens, weiAmount.mul(thirdWeekBonus));
    } else if ( accessTime < weekFour ) {
      tokens = SafeMath.add(tokens, weiAmount.mul(forthWeekBonus));
    } else if ( accessTime < weekFive ) {
      tokens = SafeMath.add(tokens, weiAmount.mul(fifthWeekBonus));
    }
    
    tokens = SafeMath.add(tokens, weiAmount.mul(rate));
    icoSupply = icoSupply.sub(tokens);        
    return tokens;
  }
   
  function buyTokens(address beneficiary) whenNotPaused internal {
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 accessTime = now;
    uint256 tokens = 0;
    uint256 weiAmount = msg.value;
    require((weiAmount >= (100000000000000000)) && (weiAmount <= (20000000000000000000)));
    if ((accessTime >= preSaleStartTime) && (accessTime < preSaleEndTime)) {
      tokens = preSaleTokens(weiAmount, tokens);
    } else if ((accessTime >= preICOStartTime) && (accessTime < preICOEndTime)) {
      tokens = preICOTokens(weiAmount, tokens);
    } else if ((accessTime >= ICOstartTime) && (accessTime <= ICOEndTime)) { 
      tokens = icoTokens(weiAmount, tokens, accessTime);
    } else {
      revert();
    }
    
    publicSupply = publicSupply.sub(tokens);
    weiRaised = weiRaised.add(weiAmount);
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= privateSaleStartTime && now <= ICOEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
   
  
  function hasEnded() public constant returns (bool) {
    return now > ICOEndTime;
  }
   
  function unsoldToken() onlyOwner public {
    require(hasEnded());
    require(!checkUnsoldTokens);
    
    checkUnsoldTokens = true;
    bountySupply = SafeMath.add(bountySupply, publicSupply);
    publicSupply = 0;
  }
   
  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }
}
 
 
contract AutoCoinToken is MintableToken {
   
    string public constant name = "AUTO COIN";
    string public constant symbol = "AUTO COIN";
    uint8 public constant decimals = 18;
    uint256 public constant _totalSupply = 400000000000000000000000000;
  
 
    function AutoCoinToken() public {
        totalSupply = _totalSupply;
    }
}
 
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
contract CrowdsaleFunctions is Crowdsale {
  
    function bountyFunds(address[] beneficiary, uint256[] tokens) public onlyOwner {
        for (uint256 i = 0; i < beneficiary.length; i++) {
            tokens[i] = SafeMath.mul(tokens[i],1 ether); 
            require(beneficiary[i] != 0x0);
            require(bountySupply >= tokens[i]);
            
            bountySupply = SafeMath.sub(bountySupply,tokens[i]);
            token.mint(beneficiary[i], tokens[i]);
        }
    }
   
    function grantReservedToken(address beneficiary, uint256 tokens) public onlyOwner {
        require(beneficiary != 0x0);
        require(reservedSupply > 0);
        tokens = SafeMath.mul(tokens,1 ether);
        require(reservedSupply >= tokens);
        reservedSupply = SafeMath.sub(reservedSupply,tokens);
        token.mint(beneficiary, tokens);
      
    }
 
    function singleTransferToken(address beneficiary, uint256 tokens) onlyOwner public {
        
        require(beneficiary != 0x0);
        require(publicSupply > 0);
        tokens = SafeMath.mul(tokens,1 ether);
        require(publicSupply >= tokens);
        publicSupply = SafeMath.sub(publicSupply,tokens);
        token.mint(beneficiary, tokens);
    }
   
    function multiTransferToken(address[] beneficiary, uint256[] tokens) public onlyOwner {
        for (uint256 i = 0; i < beneficiary.length; i++) {
            tokens[i] = SafeMath.mul(tokens[i],1 ether); 
            require(beneficiary[i] != 0x0);
            require(publicSupply >= tokens[i]);
            
            publicSupply = SafeMath.sub(publicSupply,tokens[i]);
            token.mint(beneficiary[i], tokens[i]);
        }
    }
    function addBlockListed(address user) public onlyOwner {
        token.addBlockeddUser(user);
    }
    
    function removeBlockListed(address user) public onlyOwner {
        token.removeBlockeddUser(user);
    }
}
contract AutoCoinICO is Crowdsale, CrowdsaleFunctions {
  
     
    function AutoCoinICO(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet)   
    Crowdsale(_startTime,_endTime,_rate,_wallet) 
    {
    }
    
     
    function createTokenContract() internal returns (MintableToken) {
        return new AutoCoinToken();
    }
}