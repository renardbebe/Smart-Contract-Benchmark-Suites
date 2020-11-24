 

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

 
 
 

contract RestartEnergyToken is MintableToken, PausableToken {
    string public name = "RED MegaWatt Token";
    string public symbol = "MWAT";
    uint256 public decimals = 18;
}

 
 
 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

 
 
 



contract TimedCrowdsale is Crowdsale, Ownable {

    uint256 public presaleStartTime;

    uint256 public presaleEndTime;

    event EndTimeChanged(uint newEndTime);

    event StartTimeChanged(uint newStartTime);

    event PresaleStartTimeChanged(uint newPresaleStartTime);

    event PresaleEndTimeChanged(uint newPresaleEndTime);

    function setEndTime(uint time) public onlyOwner {
        require(now < time);
        require(time > startTime);

        endTime = time;
        EndTimeChanged(endTime);
    }

    function setStartTime(uint time) public onlyOwner {
        require(now < time);
        require(time > presaleEndTime);

        startTime = time;
        StartTimeChanged(startTime);
    }

    function setPresaleStartTime(uint time) public onlyOwner {
        require(now < time);
        require(time < presaleEndTime);

        presaleStartTime = time;
        PresaleStartTimeChanged(presaleEndTime);
    }

    function setPresaleEndTime(uint time) public onlyOwner {
        require(now < time);
        require(time > presaleStartTime);

        presaleEndTime = time;
        PresaleEndTimeChanged(presaleEndTime);
    }


}

 
 
 

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}

 
 
 



contract TokenCappedCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

    uint256 public hardCap;
    uint256 public totalTokens;

    function TokenCappedCrowdsale() internal {

        hardCap = 400000000 * 1 ether;
        totalTokens = 500000000 * 1 ether;
    }

    function notExceedingSaleLimit(uint256 amount) internal constant returns (bool) {
        return hardCap >= amount.add(token.totalSupply());
    }

     
    function finalization() internal {
        super.finalization();
    }
}

 
 
 




contract RestartEnergyCrowdsale is TimedCrowdsale, TokenCappedCrowdsale, Pausable {

    uint256 public presaleLimit = 10 * 1 ether;

     
    uint16 public basicPresaleRate = 120;

    uint256 public soldTokens = 0;

    uint16 public etherRate = 100;

     
    address public tokensWallet;

     
    mapping(address => uint256) public purchasedAmountOf;

     
    mapping(address => uint256) public tokenAmountOf;


    function RestartEnergyCrowdsale(uint256 _presaleStartTime, uint256 _presaleEndTime,
        uint256 _startTime, uint256 _endTime, address _wallet, address _tokensWallet) public TokenCappedCrowdsale() Crowdsale(_startTime, _endTime, 100, _wallet) {
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
        tokensWallet = _tokensWallet;
    }

     
    function createTokenContract() internal returns (MintableToken) {
        return RestartEnergyToken(0x0);
    }

     
    function buildTokenContract() public onlyOwner {
        require(token == address(0x0));
        RestartEnergyToken _token = new RestartEnergyToken();
        _token.pause();
        token = _token;
    }

    function buy() public whenNotPaused payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public whenNotPaused payable {
        require(!isFinalized);
        require(beneficiary != address(0));
        require(validPresalePurchase() || validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(getRate());

        require(validPurchase());
        require(notExceedingSaleLimit(tokens));

         
        weiRaised = weiRaised.add(weiAmount);

        soldTokens = soldTokens.add(tokens);

         
        token.mint(beneficiary, tokens);

         
        purchasedAmountOf[msg.sender] = purchasedAmountOf[msg.sender].add(msg.value);
        tokenAmountOf[msg.sender] = tokenAmountOf[msg.sender].add(tokens);

         
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

         
        forwardFunds();
    }

     
    function sendTokensToAddress(uint256 amount, address to) public onlyOwner {
        require(!isFinalized);
        require(notExceedingSaleLimit(amount));
        tokenAmountOf[to] = tokenAmountOf[to].add(amount);
        token.mint(to, amount);
    }

    function enableTokenTransfers() public onlyOwner {
        require(isFinalized);
        require(now > endTime + 15 days);
        require(RestartEnergyToken(token).paused());
        RestartEnergyToken(token).unpause();
    }

     
    bool public firstPartOfTeamTokensClaimed = false;
    bool public secondPartOfTeamTokensClaimed = false;


    function claimTeamTokens() public onlyOwner {
        require(isFinalized);
        require(!secondPartOfTeamTokensClaimed);
        require(now > endTime + 182 days);

        uint256 tokensToMint = totalTokens.mul(3).div(100);
        if (!firstPartOfTeamTokensClaimed) {
            token.mint(wallet, tokensToMint);
            firstPartOfTeamTokensClaimed = true;
        }
        else {
            require(now > endTime + 365 days);
            token.mint(wallet, tokensToMint);
            secondPartOfTeamTokensClaimed = true;
            token.finishMinting();
        }
    }

     
    function getRate() internal view returns (uint256) {
        uint256 calcRate = rate;
         
        if (validPresalePurchase()) {
            calcRate = basicPresaleRate;
        }
        else {
             
             
            uint256 daysPassed = (now - startTime) / 1 days;
            if (daysPassed < 15) {
                calcRate = 100 + (15 - daysPassed);
            }
        }
        calcRate = calcRate.mul(etherRate);
        return calcRate;
    }


    function setEtherRate(uint16 _etherRate) public onlyOwner {
        etherRate = _etherRate;
    }

     
    function validPresalePurchase() internal constant returns (bool) {
        bool withinPeriod = now >= presaleStartTime && now <= presaleEndTime;
        bool nonZeroPurchase = msg.value != 0;
        bool validPresaleLimit = msg.value >= presaleLimit;
        return withinPeriod && nonZeroPurchase && validPresaleLimit;
    }

    function finalization() internal {
        super.finalization();

        uint256 toMintNow;

         
        toMintNow = hardCap.sub(token.totalSupply());
        token.mint(tokensWallet, toMintNow);


         
        toMintNow = totalTokens.mul(14).div(100);
        token.mint(tokensWallet, toMintNow);
    }
}

 