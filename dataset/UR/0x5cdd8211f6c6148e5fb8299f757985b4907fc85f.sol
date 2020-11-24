 

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

contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
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


   
  function () payable {
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

contract Ownable {
  address public owner;


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

contract Contactable is Ownable{

    string public contactInformation;

     
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
     }
}

contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

contract HasNoEther is Ownable {

   
  function HasNoEther() payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    revert();
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

contract FlipCrowdsale is Contactable, Pausable, HasNoContracts, HasNoTokens, FinalizableCrowdsale {
    using SafeMath for uint256;

    uint256 public tokensSold = 0;

     
    function FlipCrowdsale(MintableToken _token, uint256 _startTime, uint256 _endTime, address _ethWallet)
    Ownable()
    Pausable()
    Contactable()
    HasNoTokens()
    HasNoContracts()
    Crowdsale(_startTime, _endTime, 1, _ethWallet)
    FinalizableCrowdsale()
    {
         
        token = _token;
        contactInformation = 'https: 
    }

    function setWallet(address _wallet) onlyOwner public {
        require(_wallet != 0x0);
        wallet = _wallet;
    }

     
     
    function buyTokens(address beneficiary) public payable whenNotPaused {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = applyExchangeRate(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    function tokenTransferOwnership(address newOwner) public onlyOwner {
        require(hasEnded());
        token.transferOwnership(newOwner);
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
         
        require(newOwner != address(this));
        super.transferOwnership(newOwner);
    }

     
     
    function hasEnded() public constant returns (bool) {
        bool capReached = tokensRemaining() == 0;
        return super.hasEnded() || capReached;
    }

     
    function tokensRemaining() constant public returns (uint256);


     
    function createTokenContract() internal returns (MintableToken) {
        return token;
    }

     
    function applyExchangeRate(uint256 _wei) constant internal returns (uint256);

     
    function finalization() internal {
         
        if(address(token) != address(0) && token.owner() == address(this) && owner != address(0)) {
            token.transferOwnership(owner);
        }
        super.finalization();
    }
}

contract FlipToken is Contactable, HasNoTokens, HasNoEther, MintableToken, PausableToken {

    string public constant name = "FLIP Token";
    string public constant symbol = "FLP";
    uint8 public constant decimals = 18;

    uint256 public constant ONE_TOKENS = (10 ** uint256(decimals));
    uint256 public constant MILLION_TOKENS = (10**6) * ONE_TOKENS;
    uint256 public constant TOTAL_TOKENS = 100 * MILLION_TOKENS;

    function FlipToken()
    Ownable()
    Contactable()
    HasNoTokens()
    HasNoEther()
    MintableToken()
    PausableToken()
    {
        contactInformation = 'https: 
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply.add(_amount) <= TOTAL_TOKENS);
        return super.mint(_to, _amount);
    }


     
    function transferOwnership(address newOwner) onlyOwner public {
         
        require(newOwner != address(this));
        super.transferOwnership(newOwner);
    }
}

contract PreSale is FlipCrowdsale {
    using SafeMath for uint256;

    uint256 public constant PRESALE_TOKEN_CAP = 238 * (10**4) * (10 ** uint256(18));  
    uint256 public minPurchaseAmt = 3 ether;

    function PreSale(MintableToken _token, uint256 _startTime, uint256 _endTime, address _ethWallet)
    FlipCrowdsale(_token, _startTime, _endTime, _ethWallet)
    {
    }

    function setMinPurchaseAmt(uint256 _wei) onlyOwner public {
        require(_wei >= 0);
        minPurchaseAmt = _wei;
    }

    function tokensRemaining() constant public returns (uint256) {
        return PRESALE_TOKEN_CAP.sub(tokensSold);
    }

     

    function applyExchangeRate(uint256 _wei) constant internal returns (uint256) {
         
         
        require(_wei >= minPurchaseAmt);
        uint256 tokens;
        if(_wei >= 5000 ether) {
            tokens = _wei.mul(340);
        } else if(_wei >= 3000 ether) {
            tokens = _wei.mul(320);
        } else if(_wei >= 1000 ether) {
            tokens = _wei.mul(300);
        } else if(_wei >= 100 ether) {
            tokens = _wei.mul(280);
        } else {
            tokens = _wei.mul(260);
        }
         
        uint256 remaining = tokensRemaining();
        require(remaining >= tokens);
         
        uint256 min_tokens_purchasable = minPurchaseAmt.mul(260);
        remaining = remaining.sub(tokens);
        if(remaining < min_tokens_purchasable) {
            tokens = tokens.add(remaining);
        }
        return tokens;
    }

}

contract PreSaleExtended is PreSale {
    using SafeMath for uint256;

    uint256 public extendedTokenCap;

    function PreSaleExtended(MintableToken _token, uint256 _startTime, uint256 _endTime, address _ethWallet)
    PreSale(_token, _startTime, _endTime, _ethWallet)
    {
        minPurchaseAmt = 1 ether;
    }

    function setExtendedTokenCap(uint256 _extendedTokenCap) public onlyOwner returns(uint256) {
        require(_extendedTokenCap <= PRESALE_TOKEN_CAP);  
        require(_extendedTokenCap > extendedTokenCap);   
        extendedTokenCap = _extendedTokenCap;
    }

    function tokensRemaining() constant public returns (uint256) {
        return extendedTokenCap.sub(tokensSold);
    }

}