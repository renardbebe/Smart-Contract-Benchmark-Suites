 

pragma solidity ^0.4.11;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

   
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public
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
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
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

 
contract CAToken is MintableToken, PausableToken {
    
     
    string public constant symbol = "CAT";
    string public constant name = "BitClave - Consumer Activity Token";
    uint8 public constant decimals = 18;
    string public constant version = "2.0";

     
    function finishMinting() onlyOwner canMint public returns(bool) {
        return super.finishMinting();
    }

}

 
contract PreCAToken is CAToken, Destructible {

     
    string public constant symbol = "CAT";
    string public constant name = "BitClave - Consumer Activity Token";
    uint8 public constant decimals = 18;
    string public constant version = "1.1";

     
    function destroy() public onlyOwner {
        require(mintingFinished);
        super.destroy();
    }

     
    function destroyAndSend(address _recipient) public onlyOwner {
        require(mintingFinished);
        super.destroyAndSend(_recipient);
    }

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
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
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

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}

 
contract PausableCrowdsale is Crowdsale, Pausable {

    function PausableCrowdsale(bool _paused) public {
        if (_paused) {
            pause();
        }
    }

     
     
    function validPurchase() internal constant returns(bool) {
        return super.validPurchase() && !paused;
    }

}

 
contract BonusCrowdsale is Crowdsale, Ownable {

     
     
    uint32[] public BONUS_TIMES;
    uint32[] public BONUS_TIMES_VALUES;
    uint32[] public BONUS_AMOUNTS;
    uint32[] public BONUS_AMOUNTS_VALUES;
    uint public constant BONUS_COEFF = 1000;  
    
     
    uint public tokenPriceInCents;

     
    function BonusCrowdsale(uint256 _tokenPriceInCents) public {
        tokenPriceInCents = _tokenPriceInCents;
    }

     
    function bonusesForTimesCount() public constant returns(uint) {
        return BONUS_TIMES.length;
    }

     
    function setBonusesForTimes(uint32[] times, uint32[] values) public onlyOwner {
        require(times.length == values.length);
        for (uint i = 0; i + 1 < times.length; i++) {
            require(times[i] < times[i+1]);
        }

        BONUS_TIMES = times;
        BONUS_TIMES_VALUES = values;
    }

     
    function bonusesForAmountsCount() public constant returns(uint) {
        return BONUS_AMOUNTS.length;
    }

     
    function setBonusesForAmounts(uint32[] amounts, uint32[] values) public onlyOwner {
        require(amounts.length == values.length);
        for (uint i = 0; i + 1 < amounts.length; i++) {
            require(amounts[i] > amounts[i+1]);
        }

        BONUS_AMOUNTS = amounts;
        BONUS_AMOUNTS_VALUES = values;
    }

     
    function buyTokens(address beneficiary) public payable {
         
        uint256 usdValue = msg.value.mul(rate).mul(tokenPriceInCents).div(100).div(1 ether); 
        
         
        uint256 bonus = computeBonus(usdValue);

         
        uint256 oldRate = rate;
        rate = rate.mul(BONUS_COEFF.add(bonus)).div(BONUS_COEFF);
        super.buyTokens(beneficiary);
        rate = oldRate;
    }

     
    function computeBonus(uint256 usdValue) public constant returns(uint256) {
        return computeAmountBonus(usdValue).add(computeTimeBonus());
    }

     
    function computeTimeBonus() public constant returns(uint256) {
        require(now >= startTime);

        for (uint i = 0; i < BONUS_TIMES.length; i++) {
            if (now.sub(startTime) <= BONUS_TIMES[i]) {
                return BONUS_TIMES_VALUES[i];
            }
        }

        return 0;
    }

     
    function computeAmountBonus(uint256 usdValue) public constant returns(uint256) {
        for (uint i = 0; i < BONUS_AMOUNTS.length; i++) {
            if (usdValue >= BONUS_AMOUNTS[i]) {
                return BONUS_AMOUNTS_VALUES[i];
            }
        }

        return 0;
    }

}



 
contract TokensCappedCrowdsale is Crowdsale {

    uint256 public tokensCap;

    function TokensCappedCrowdsale(uint256 _tokensCap) public {
        tokensCap = _tokensCap;
    }

     
     
    function validPurchase() internal constant returns(bool) {
        uint256 tokens = token.totalSupply().add(msg.value.mul(rate));
        bool withinCap = tokens <= tokensCap;
        return super.validPurchase() && withinCap;
    }

     
     
    function hasEnded() public constant returns(bool) {
        bool capReached = token.totalSupply() >= tokensCap;
        return super.hasEnded() || capReached;
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
    isFinalized = isFinalized;
  }
}


    
contract CATCrowdsale is FinalizableCrowdsale, TokensCappedCrowdsale(CATCrowdsale.CAP), PausableCrowdsale(true), BonusCrowdsale(CATCrowdsale.TOKEN_USDCENT_PRICE) {

     
    uint256 public constant DECIMALS = 18;
    uint256 public constant CAP = 2 * (10**9) * (10**DECIMALS);               
    uint256 public constant BITCLAVE_AMOUNT = 1 * (10**9) * (10**DECIMALS);   
    uint256 public constant TOKEN_USDCENT_PRICE = 10;                         

     
    address public remainingTokensWallet;
    address public presaleWallet;

     
    function setRate(uint256 _rate) external onlyOwner {
        require(_rate != 0x0);
        rate = _rate;
        RateChange(_rate);
    }

     
    function setEndTime(uint256 _endTime) external onlyOwner {
        require(!isFinalized);
        require(_endTime >= startTime);
        require(_endTime >= now);
        endTime = _endTime;
    }

     
    function setWallet(address _wallet) external onlyOwner {
        require(_wallet != 0x0);
        wallet = _wallet;
    }

     
    function setRemainingTokensWallet(address _remainingTokensWallet) external onlyOwner {
        require(_remainingTokensWallet != 0x0);
        remainingTokensWallet = _remainingTokensWallet;
    }

     
    event RateChange(uint256 rate);

     
    function CATCrowdsale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        address _remainingTokensWallet,
        address _bitClaveWallet
    ) public
        Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        remainingTokensWallet = _remainingTokensWallet;
        presaleWallet = this;

         
        mintTokens(_bitClaveWallet, BITCLAVE_AMOUNT);
    }

     

     
    function createTokenContract() internal returns(MintableToken) {
        PreCAToken token = new PreCAToken();
        token.pause();
        return token;
    }

     
    function finalization() internal {
        super.finalization();

         
        if (token.totalSupply() < tokensCap) {
            uint tokens = tokensCap.sub(token.totalSupply());
            token.mint(remainingTokensWallet, tokens);
        }

         
        token.finishMinting();

         
        token.transferOwnership(owner);
    }

     

     
    function pauseTokens() public onlyOwner {
        PreCAToken(token).pause();
    }

     
    function unpauseTokens() public onlyOwner {
        PreCAToken(token).unpause();
    }

     
    function mintPresaleTokens(uint256 tokens) public onlyOwner {
        mintTokens(presaleWallet, tokens);
        presaleWallet = 0;
    }

     
    function transferPresaleTokens(address destination, uint256 amount) public onlyOwner {
        unpauseTokens();
        token.transfer(destination, amount);
        pauseTokens();
    }

     
     
    function mintTokens(address beneficiary, uint256 tokens) public onlyOwner {
        require(beneficiary != 0x0);
        require(tokens > 0);
        require(now <= endTime);                                
        require(!isFinalized);                                  
        require(token.totalSupply().add(tokens) <= tokensCap);  
        
        token.mint(beneficiary, tokens);
    }

}