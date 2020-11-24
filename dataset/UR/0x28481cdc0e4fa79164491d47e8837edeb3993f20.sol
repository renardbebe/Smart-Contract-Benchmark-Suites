 

pragma solidity ^0.4.13;

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

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
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

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract TssToken is MintableToken, BurnableToken {
    string public constant name = "TssToken";
    string public constant symbol = "TSS";
    uint256 public constant decimals = 18;

    function TssToken(address initialAccount, uint256 initialBalance) public {
        balances[initialAccount] = initialBalance;
        totalSupply = initialBalance;
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

  event Debug(bytes32 text, uint256);

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

contract TssCrowdsale is Crowdsale, Pausable {
    enum LifecycleStage {
    DEPLOYMENT,
    MINTING,
    PRESALE,
    CROWDSALE_PHASE_1,
    CROWDSALE_PHASE_2,
    CROWDSALE_PHASE_3,
    POSTSALE
    }

    uint256 public CROWDSALE_PHASE_1_START;

    uint256 public CROWDSALE_PHASE_2_START;

    uint256 public CROWDSALE_PHASE_3_START;

    uint256 public POSTSALE_START;

    address public FOUNDER_WALLET;

    address public BOUNTY_WALLET;

    address public FUTURE_WALLET;

    address public CROWDSALE_WALLET;

    address public PRESALE_WALLET;

    address PROCEEDS_WALLET;


    LifecycleStage public currentStage;

    function assertValidParameters() internal {
        require(CROWDSALE_PHASE_1_START > 0);
        require(CROWDSALE_PHASE_2_START > 0);
        require(CROWDSALE_PHASE_3_START > 0);
        require(POSTSALE_START > 0);

        require(address(FOUNDER_WALLET) != 0);
        require(address(BOUNTY_WALLET) != 0);
        require(address(FUTURE_WALLET) != 0);
    }

     
    function setCurrentStage() onlyOwner ensureStage returns (bool) {
        return true;
    }

    modifier ensureStage() {
        if (token.mintingFinished()) {
            if (now < CROWDSALE_PHASE_1_START) {currentStage = LifecycleStage.PRESALE;}
            else if (now < CROWDSALE_PHASE_2_START) {currentStage = LifecycleStage.CROWDSALE_PHASE_1;}
            else if (now < CROWDSALE_PHASE_3_START) {currentStage = LifecycleStage.CROWDSALE_PHASE_2;}
            else if (now < POSTSALE_START) {currentStage = LifecycleStage.CROWDSALE_PHASE_3;}
            else {currentStage = LifecycleStage.POSTSALE;}
        }
        _;
    }

    function getCurrentRate() constant returns (uint _rate) {

        if (currentStage == LifecycleStage.CROWDSALE_PHASE_1) {_rate = 1150;}
        else if (currentStage == LifecycleStage.CROWDSALE_PHASE_2) {_rate = 1100;}
        else if (currentStage == LifecycleStage.CROWDSALE_PHASE_3) {_rate = 1050;}
        else {_rate == 0;}

        return _rate;
    }

    function TssCrowdsale(
    uint256 _rate,
    address _wallet,

    uint256 _phase_1_start,
    uint256 _phase_2_start,
    uint256 _phase_3_start,
    uint256 _postsale_start,

    address _founder_wallet,
    address _bounty_wallet,
    address _future_wallet,
    address _presale_wallet)

    public
    Crowdsale(_phase_1_start, _postsale_start, _rate, _wallet)
    {
         
        CROWDSALE_PHASE_1_START = _phase_1_start;
        CROWDSALE_PHASE_2_START = _phase_2_start;
        CROWDSALE_PHASE_3_START = _phase_3_start;
        POSTSALE_START = _postsale_start;

         

        FOUNDER_WALLET = _founder_wallet;
        BOUNTY_WALLET = _bounty_wallet;
        FUTURE_WALLET = _future_wallet;
        PRESALE_WALLET = _presale_wallet;

        CROWDSALE_WALLET = address(this);

        assertValidParameters();

         
        currentStage = LifecycleStage.MINTING;
        mintTokens();
        token.finishMinting();

        currentStage = LifecycleStage.PRESALE;
    }

    function mintTokens() internal {

         

        TssToken _token = TssToken(token);
        token.mint(FOUNDER_WALLET, 100000000 * 10 ** _token.decimals());
        token.mint(BOUNTY_WALLET, 25000000 * 10 ** _token.decimals());
        token.mint(FUTURE_WALLET, 275000000 * 10 ** _token.decimals());
        token.mint(CROWDSALE_WALLET, 97000000 * 10 ** _token.decimals());
        token.mint(PRESALE_WALLET, 3000000 * 10 ** _token.decimals());
    }

     
    function buyTokens(address beneficiary) public
    payable
    whenNotPaused()
    ensureStage()
    {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(getCurrentRate());

         
        weiRaised = weiRaised.add(weiAmount);

        token.transfer(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = currentStage >= LifecycleStage.CROWDSALE_PHASE_1 && currentStage <= LifecycleStage.CROWDSALE_PHASE_3;
        bool minimumPurchase = msg.value > 0.01 ether;
        return withinPeriod && minimumPurchase;
    }

     
    function createTokenContract() internal returns (MintableToken) {
        return new TssToken(0x0, 0);
    }

    event CoinsRetrieved(address indexed recipient, uint amount);    

    function retrieveRemainingCoinsPostSale() 
        public
        onlyOwner 
        ensureStage() 
    {
        require(currentStage == LifecycleStage.POSTSALE);

        uint coinBalance = token.balanceOf(CROWDSALE_WALLET);
        token.transfer(FUTURE_WALLET, coinBalance);
        CoinsRetrieved(FUTURE_WALLET, coinBalance);
    }

     
    function retrieveFunds() 
        public
        onlyOwner
    {
        owner.transfer(this.balance);
    }

}