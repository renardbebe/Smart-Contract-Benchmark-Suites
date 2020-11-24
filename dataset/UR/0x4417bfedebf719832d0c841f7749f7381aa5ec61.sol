 

pragma solidity ^0.4.17;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract Ownable {
  address internal owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
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

 













 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
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

  function burnTokens(uint256 _unsoldTokens) onlyOwner public returns (bool) {
    totalSupply = SafeMath.sub(totalSupply, _unsoldTokens);
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

  
    uint256 public preICOstartTime;
    uint256 public preICOEndTime;
  
    uint256 public ICOstartTime;
    uint256 public ICOEndTime;
    
     

    uint public StageTwo;
    uint public StageThree;
    uint public StageFour;

     
    uint public preIcoBonus;
    uint public StageOneBonus;
    uint public StageTwoBonus;
    uint public StageThreeBonus;

     
    uint256 public totalSupply = SafeMath.mul(500000000, 1 ether);  
    uint256 public publicSupply = SafeMath.mul(100000000, 1 ether);
    uint256 public preIcoSupply = SafeMath.mul(50000000, 1 ether);                     
    uint256 public icoSupply = SafeMath.mul(50000000, 1 ether);

    uint256 public bountySupply = SafeMath.mul(50000000, 1 ether);
    uint256 public reserveSupply = SafeMath.mul(100000000, 1 ether);
    uint256 public advisorSupply = SafeMath.mul(50000000, 1 ether);
    uint256 public founderSupply = SafeMath.mul(100000000, 1 ether);
    uint256 public teamSupply = SafeMath.mul(50000000, 1 ether);
    uint256 public rewardSupply = SafeMath.mul(50000000, 1 ether);
  
     
    uint256 public founderTimeLock;
    uint256 public advisorTimeLock;
    uint256 public reserveTimeLock;
    uint256 public teamTimeLock;

     
    uint public founderCounter = 0;  
    uint public teamCounter = 0;
    uint public advisorCounter = 0;
   
    bool public checkBurnTokens;
    bool public upgradeICOSupply;
    bool public grantReserveSupply;

  
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
     
 function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    preICOstartTime = _startTime;  
    preICOEndTime =  1547769600;  
    ICOstartTime =  1548633600;  
    ICOEndTime = _endTime;  
    rate = _rate; 
    wallet = _wallet;

     
    preIcoBonus = SafeMath.div(SafeMath.mul(rate,20),100);
    StageOneBonus = SafeMath.div(SafeMath.mul(rate,15),100);
    StageTwoBonus = SafeMath.div(SafeMath.mul(rate,10),100);
    StageThreeBonus = SafeMath.div(SafeMath.mul(rate,5),100);

     
    StageTwo = SafeMath.add(ICOstartTime, 12 days);  
    StageThree = SafeMath.add(StageTwo, 12 days);
    StageFour = SafeMath.add(StageThree, 12 days);

     
    founderTimeLock = SafeMath.add(ICOEndTime, 3 minutes);
    advisorTimeLock = SafeMath.add(ICOEndTime, 3 minutes);
    reserveTimeLock = SafeMath.add(ICOEndTime, 3 minutes);
    teamTimeLock = SafeMath.add(ICOEndTime, 3 minutes);
    
    checkBurnTokens = false;
    upgradeICOSupply = false;
    grantReserveSupply = false;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
   
  function preIcoTokens(uint256 weiAmount, uint256 tokens) internal returns (uint256) {
  
    require(preIcoSupply > 0);
    tokens = SafeMath.add(tokens, weiAmount.mul(preIcoBonus));
    tokens = SafeMath.add(tokens, weiAmount.mul(rate));

    require(preIcoSupply >= tokens);
    
    preIcoSupply = preIcoSupply.sub(tokens);        
    publicSupply = publicSupply.sub(tokens);

    return tokens;     
  }

   
  function icoTokens(uint256 weiAmount, uint256 tokens, uint256 accessTime) internal returns (uint256) {

    require(icoSupply > 0);
      
      if ( accessTime <= StageTwo ) { 
        tokens = SafeMath.add(tokens, weiAmount.mul(StageOneBonus));
      } else if (( accessTime <= StageThree ) && (accessTime > StageTwo)) {  
        tokens = SafeMath.add(tokens, weiAmount.mul(StageTwoBonus));
      } else if (( accessTime <= StageFour ) && (accessTime > StageThree)) {  
        tokens = SafeMath.add(tokens, weiAmount.mul(StageThreeBonus));
      }
        tokens = SafeMath.add(tokens, weiAmount.mul(rate)); 
      require(icoSupply >= tokens);
      
      icoSupply = icoSupply.sub(tokens);        
      publicSupply = publicSupply.sub(tokens);

      return tokens;
  }
  

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) whenNotPaused public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
     
    require((weiAmount >= 50000000000000000));
    
    uint256 accessTime = now;
    uint256 tokens = 0;


   if ((accessTime >= preICOstartTime) && (accessTime <= preICOEndTime)) {
           tokens = preIcoTokens(weiAmount, tokens);

    } else if ((accessTime >= ICOstartTime) && (accessTime <= ICOEndTime)) {
       if (!upgradeICOSupply) {
          icoSupply = SafeMath.add(icoSupply,preIcoSupply);
          upgradeICOSupply = true;
        }
       tokens = icoTokens(weiAmount, tokens, accessTime);
    } else {
      revert();
    }
    
    weiRaised = weiRaised.add(weiAmount);
     if(msg.data.length == 20) {
    address referer = bytesToAddress(bytes(msg.data));
     
    require(referer != msg.sender);
    uint refererTokens = tokens.mul(6).div(100);
     
    token.mint(referer, refererTokens);
  }
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

function bytesToAddress(bytes source) internal pure returns(address) {
  uint result;
  uint mul = 1;
  for(uint i = 20; i > 0; i--) {
    result += uint8(source[i-1])*mul;
    mul = mul*256;
  }
  return address(result);
}
   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= preICOstartTime && now <= ICOEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
      return now > ICOEndTime;
  }

  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }

}





contract Allocations is Crowdsale {

    function bountyDrop(address[] recipients, uint256[] values) public onlyOwner {

        for (uint256 i = 0; i < recipients.length; i++) {
            values[i] = SafeMath.mul(values[i], 1 ether);
            require(bountySupply >= values[i]);
            bountySupply = SafeMath.sub(bountySupply,values[i]);

            token.mint(recipients[i], values[i]);
        }
    }

    function rewardDrop(address[] recipients, uint256[] values) public onlyOwner {

        for (uint256 i = 0; i < recipients.length; i++) {
            values[i] = SafeMath.mul(values[i], 1 ether);
            require(rewardSupply >= values[i]);
            rewardSupply = SafeMath.sub(rewardSupply,values[i]);

            token.mint(recipients[i], values[i]);
        }
    }

    function grantAdvisorToken(address beneficiary ) public onlyOwner {
        require((advisorCounter < 4) && (advisorTimeLock < now));
        advisorTimeLock = SafeMath.add(advisorTimeLock, 2 minutes);
        token.mint(beneficiary,SafeMath.div(advisorSupply, 4));
        advisorCounter = SafeMath.add(advisorCounter, 1);    
    }

    function grantFounderToken(address founderAddress) public onlyOwner {
        require((founderCounter < 4) && (founderTimeLock < now));
        founderTimeLock = SafeMath.add(founderTimeLock, 2 minutes);
        token.mint(founderAddress,SafeMath.div(founderSupply, 4));
        founderCounter = SafeMath.add(founderCounter, 1);        
    }

    function grantTeamToken(address teamAddress) public onlyOwner {
        require((teamCounter < 2) && (teamTimeLock < now));
        teamTimeLock = SafeMath.add(teamTimeLock, 2 minutes);
        token.mint(teamAddress,SafeMath.div(teamSupply, 4));
        teamCounter = SafeMath.add(teamCounter, 1);        
    }

    function grantReserveToken(address beneficiary) public onlyOwner {
        require((!grantReserveSupply) && (now > reserveTimeLock));
        grantReserveSupply = true;
        token.mint(beneficiary,reserveSupply);
        reserveSupply = 0;
    }

    function transferFunds(address[] recipients, uint256[] values) public onlyOwner {
        require(!checkBurnTokens);
        for (uint256 i = 0; i < recipients.length; i++) {
            values[i] = SafeMath.mul(values[i], 1 ether);
            require(publicSupply >= values[i]);
            publicSupply = SafeMath.sub(publicSupply,values[i]);
            token.mint(recipients[i], values[i]); 
            }
    } 

    function burnToken() public onlyOwner returns (bool) {
        require(hasEnded());
        require(!checkBurnTokens);
         
        totalSupply = SafeMath.sub(totalSupply, icoSupply);
        publicSupply = 0;
        preIcoSupply = 0;
        icoSupply = 0;
        checkBurnTokens = true;

        return true;
    }

}





 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 internal cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}










 
contract FinalizableCrowdsale is Crowdsale {
  using SafeMath for uint256;

  bool isFinalized = false;

  event Finalized();

   
  function finalizeCrowdsale() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());
    
    finalization();
    Finalized();
    
    isFinalized = true;
    }
  

   
  function finalization() internal {
  }
}






 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) {
    require(_wallet != 0x0);
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}



 
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 internal goal;
   
  RefundVault private vault;

  function RefundableCrowdsale(uint256 _goal) {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) { 
      vault.close();
    } else {
      vault.enableRefunds();
    }
    super.finalization();
  
  }

   
  function goalReached() public view returns (bool) {
    return weiRaised >= (goal - (5000 * 1 ether));
  }

  function getVaultAddress() onlyOwner public returns (address) {
    return vault;
  }
}

 


contract TradePlaceToken is MintableToken {

  string public constant name = "Trade PLace";
  string public constant symbol = "EXTP";
  uint8 public constant decimals = 18;
  uint256 public totalSupply = SafeMath.mul(500000000 , 1 ether);  
}





contract TradePlaceCrowdsale is Crowdsale, CappedCrowdsale, RefundableCrowdsale, Allocations {
     
    function TradePlaceCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap, uint256 _goal, address _wallet)
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
    }

     
    function createTokenContract() internal returns (MintableToken) {
        return new TradePlaceToken();
    }
}