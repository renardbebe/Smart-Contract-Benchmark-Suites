 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

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

 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

contract MonthlyTokenVesting is TokenVesting {

    uint256 public previousTokenVesting = 0;

    function MonthlyTokenVesting(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable
    ) public
    TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable)
    { }


    function release(ERC20Basic token) public onlyOwner {
        require(now >= previousTokenVesting + 30 days);
        super.release(token);
        previousTokenVesting = now;
    }
}

contract CREDToken is CappedToken {
    using SafeMath for uint256;

     

    string public constant name = "Verify Token";
    uint8 public constant decimals = 18;
    string public constant symbol = "CRED";

     

     
    uint256 public reserveUnlockTime;

    address public teamWallet;
    address public reserveWallet;
    address public advisorsWallet;

     

    uint256 teamLocked;
    uint256 reserveLocked;
    uint256 advisorsLocked;

     
    bool public locked = true;

     
    uint256 public unfreezeTime = 0;

    bool public unlockedReserveAndTeamFunds = false;

    MonthlyTokenVesting public advisorsVesting = MonthlyTokenVesting(address(0));

     

    event MintLocked(address indexed to, uint256 amount);

    event Unlocked(address indexed to, uint256 amount);

     

     
    modifier whenLiquid {
        require(!locked);
        _;
    }

    modifier afterReserveUnlockTime {
        require(now >= reserveUnlockTime);
        _;
    }

    modifier unlockReserveAndTeamOnce {
        require(!unlockedReserveAndTeamFunds);
        _;
    }

     
    function CREDToken(
        uint256 _cap,
        uint256 _yearLockEndTime,
        address _teamWallet,
        address _reserveWallet,
        address _advisorsWallet
    )
    CappedToken(_cap)
    public
    {
        require(_yearLockEndTime != 0);
        require(_teamWallet != address(0));
        require(_reserveWallet != address(0));
        require(_advisorsWallet != address(0));

        reserveUnlockTime = _yearLockEndTime;
        teamWallet = _teamWallet;
        reserveWallet = _reserveWallet;
        advisorsWallet = _advisorsWallet;
    }

     
     
    function mintAdvisorsTokens(uint256 _value) public onlyOwner canMint {
        require(advisorsLocked == 0);
        require(_value.add(totalSupply) <= cap);
        advisorsLocked = _value;
        MintLocked(advisorsWallet, _value);
    }

    function mintTeamTokens(uint256 _value) public onlyOwner canMint {
        require(teamLocked == 0);
        require(_value.add(totalSupply) <= cap);
        teamLocked = _value;
        MintLocked(teamWallet, _value);
    }

    function mintReserveTokens(uint256 _value) public onlyOwner canMint {
        require(reserveLocked == 0);
        require(_value.add(totalSupply) <= cap);
        reserveLocked = _value;
        MintLocked(reserveWallet, _value);
    }


     
     
    function finalise() public onlyOwner {
        require(reserveLocked > 0);
        require(teamLocked > 0);
        require(advisorsLocked > 0);

        advisorsVesting = new MonthlyTokenVesting(advisorsWallet, now, 92 days, 2 years, false);
        mint(advisorsVesting, advisorsLocked);
        finishMinting();

        owner = 0;
        unfreezeTime = now + 1 weeks;
    }


     
    function unfreeze() public {
        require(unfreezeTime > 0);
        require(now >= unfreezeTime);
        locked = false;
    }


     
    function unlockTeamAndReserveTokens() public whenLiquid afterReserveUnlockTime unlockReserveAndTeamOnce {
        require(totalSupply.add(teamLocked).add(reserveLocked) <= cap);

        totalSupply = totalSupply.add(teamLocked).add(reserveLocked);
        balances[teamWallet] = balances[teamWallet].add(teamLocked);
        balances[reserveWallet] = balances[reserveWallet].add(reserveLocked);
        teamLocked = 0;
        reserveLocked = 0;
        unlockedReserveAndTeamFunds = true;

        Transfer(address(0), teamWallet, teamLocked);
        Transfer(address(0), reserveWallet, reserveLocked);
        Unlocked(teamWallet, teamLocked);
        Unlocked(reserveWallet, reserveLocked);
    }

    function unlockAdvisorTokens() public whenLiquid {
        advisorsVesting.release(this);
    }


     

    function transfer(address _to, uint256 _value) public whenLiquid returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenLiquid returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenLiquid returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint256 _addedValue) public whenLiquid returns (bool) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public whenLiquid returns (bool) {
        return super.decreaseApproval(_spender, _subtractedValue);
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
 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
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

contract Tokensale is CappedCrowdsale, Pausable{
    using SafeMath for uint256;

    uint256 constant public MAX_SUPPLY = 50000000 ether;
    uint256 constant public SALE_TOKENS_SUPPLY = 11125000 ether;
    uint256 constant public INVESTMENT_FUND_TOKENS_SUPPLY = 10500000 ether;
    uint256 constant public MISCELLANEOUS_TOKENS_SUPPLY = 2875000 ether;
    uint256 constant public TEAM_TOKENS_SUPPLY = 10000000 ether;
    uint256 constant public RESERVE_TOKENS_SUPPLY = 10000000 ether;
    uint256 constant public ADVISORS_TOKENS_SUPPLY = 5500000 ether;


    uint256 public totalSold;
    uint256 public soldDuringTokensale;

    uint256 public presaleStartTime;

    mapping(address => uint256) public presaleLimit;


    modifier beforeSale() {
        require(now < startTime);
        _;
    }

    modifier duringSale() {
        require(now >= startTime && !hasEnded() && !paused);
        _;
    }

    function Tokensale(
        uint256 _presaleStartTime,
        uint256 _startTime,
        uint256 _hardCap,
        address _investmentFundWallet,
        address _miscellaneousWallet,
        address _treasury,
        address _teamWallet,
        address _reserveWallet,
        address _advisorsWallet
    )
    CappedCrowdsale(_hardCap)
    Crowdsale(_startTime, _startTime + 30 days, SALE_TOKENS_SUPPLY.div(_hardCap), _treasury)
    public
    {
        require(_startTime > _presaleStartTime);
        require(now < _presaleStartTime);

        token = new CREDToken(
            MAX_SUPPLY,
            _startTime + 1 years,
            _teamWallet,
            _reserveWallet,
            _advisorsWallet
        );
        presaleStartTime = _presaleStartTime;
        mintInvestmentFundAndMiscellaneous(_investmentFundWallet, _miscellaneousWallet);
        castedToken().mintTeamTokens(TEAM_TOKENS_SUPPLY);
        castedToken().mintReserveTokens(RESERVE_TOKENS_SUPPLY);
        castedToken().mintAdvisorsTokens(ADVISORS_TOKENS_SUPPLY);

    }

    function setHardCap(uint256 _cap) public onlyOwner {
        require(now < presaleStartTime);
        require(_cap > 0);
        cap = _cap;
        rate = SALE_TOKENS_SUPPLY.div(_cap);
    }

     
    function addPresaleWallets(address[] _wallets, uint256[] _weiLimit) external onlyOwner {
        require(now < startTime);
        require(_wallets.length == _weiLimit.length);
        for (uint256 i = 0; i < _wallets.length; i++) {
            presaleLimit[_wallets[i]] = _weiLimit[i];
        }
    }

     
    function buyTokens(address beneficiary) public payable {
        super.buyTokens(beneficiary);
         
        if (now < startTime) {
            presaleLimit[msg.sender] = presaleLimit[msg.sender].sub(msg.value);
        }
        totalSold = totalSold.add(msg.value.mul(rate));
    }

    function finalise() public {
        require(hasEnded());
        castedToken().finalise();
    }

    function mintInvestmentFundAndMiscellaneous(
        address _investmentFundWallet,
        address _miscellaneousWallet
    ) internal {
        require(_investmentFundWallet != address(0));
        require(_miscellaneousWallet != address(0));

        token.mint(_investmentFundWallet, INVESTMENT_FUND_TOKENS_SUPPLY);
        token.mint(_miscellaneousWallet, MISCELLANEOUS_TOKENS_SUPPLY);
    }

    function castedToken() internal view returns (CREDToken) {
        return CREDToken(token);
    }

     
     
    function createTokenContract() internal returns (MintableToken) {
        return MintableToken(address(0));
    }

    function validSalePurchase() internal view returns (bool) {
        return super.validPurchase();
    }

    function validPreSalePurchase() internal view returns (bool) {
        if (msg.value > presaleLimit[msg.sender]) { return false; }
        if (weiRaised.add(msg.value) > cap) { return false; }
        if (now < presaleStartTime) { return false; }
        if (now >= startTime) { return false; }
        return true;
    }

     
    function validPurchase() internal view returns (bool) {
        require(!paused);
        return validSalePurchase() || validPreSalePurchase();
    }

}