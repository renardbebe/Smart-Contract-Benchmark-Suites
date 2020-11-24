 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}



 
contract Whitelist is Ownable {
    mapping(address => bool) whitelist;

    uint256 public whitelistLength = 0;

    address private addressApi;

    modifier onlyPrivilegeAddresses {
        require(msg.sender == addressApi || msg.sender == owner);
        _;
    }

     
    function setApiAddress(address _api) public onlyOwner {
        require(_api != address(0));
        addressApi = _api;
    }

       
    function addWallet(address _wallet) public onlyPrivilegeAddresses {
        require(_wallet != address(0));
        require(!isWhitelisted(_wallet));
        whitelist[_wallet] = true;
        whitelistLength++;
    }

       
    function removeWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0));
        require(isWhitelisted(_wallet));
        whitelist[_wallet] = false;
        whitelistLength--;
    }

      
    function isWhitelisted(address _wallet) public view returns (bool) {
        return whitelist[_wallet];
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}



 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract VeiagToken is StandardToken, Ownable, Pausable {
    string constant public name = "Veiag Token";
    string constant public symbol = "VEIAG";
    uint8 constant public decimals = 18;

    uint256 constant public INITIAL_TOTAL_SUPPLY = 1e9 * (uint256(10) ** decimals);

    address private addressIco;

    modifier onlyIco() {
        require(msg.sender == addressIco);
        _;
    }
    
     
    function VeiagToken (address _ico) public {
        require(_ico != address(0));

        addressIco = _ico;

        totalSupply_ = totalSupply_.add(INITIAL_TOTAL_SUPPLY);
        balances[_ico] = balances[_ico].add(INITIAL_TOTAL_SUPPLY);
        Transfer(address(0), _ico, INITIAL_TOTAL_SUPPLY);

        pause();
    }

      
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        super.transferFrom(_from, _to, _value);
    }

     
    function transferFromIco(address _to, uint256 _value) public onlyIco returns (bool) {
        super.transfer(_to, _value);
    }
}

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}


 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
     
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
     
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(address(this));
    require(amount > 0);

    token.transfer(beneficiary, amount);
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}



contract LockedOutTokens is TokenTimelock {
    function LockedOutTokens(
        ERC20Basic _token,
        address _beneficiary,
        uint256 _releaseTime
    ) public TokenTimelock(_token, _beneficiary, _releaseTime)
    {
    }

    function release() public {
        require(beneficiary == msg.sender);

        super.release();
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

   
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  function setStart(uint256 _start) onlyOwner public {
    start = _start;  
  }
   
  function release(ERC20Basic _token) public {
    uint256 unreleased = releasableAmount(_token);

    require(unreleased > 0);

    released[_token] = released[_token].add(unreleased);

    _token.transfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

   
  function revoke(ERC20Basic _token) public onlyOwner {
    require(revocable);
    require(!revoked[_token]);

    uint256 balance = _token.balanceOf(address(this));

    uint256 unreleased = releasableAmount(_token);
    uint256 refund = balance.sub(unreleased);

    revoked[_token] = true;

    _token.transfer(owner, refund);

    emit Revoked();
  }

   
  function releasableAmount(ERC20Basic _token) public view returns (uint256) {
    return vestedAmount(_token).sub(released[_token]);
  }

   
  function vestedAmount(ERC20Basic _token) public view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(released[_token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[_token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}

contract VeiagTokenVesting is TokenVesting {
    ERC20Basic public token;

    function VeiagTokenVesting(
        ERC20Basic _token,
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable
    ) TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable) public
    {
        require(_token != address(0));

        token = _token;
    }

    function grant() public {
        release(token);
    }

    function release(ERC20Basic _token) public {
        require(beneficiary == msg.sender);
        super.release(_token);
    }
}

contract Whitelistable {
    Whitelist public whitelist;

    modifier whenWhitelisted(address _wallet) {
    
        _;
    }

     
    function Whitelistable() public {
        whitelist = new Whitelist();
    }
}

contract VeiagCrowdsale is Pausable, Whitelistable {
    using SafeMath for uint256;

    uint256 constant private DECIMALS = 18;

    uint256 constant public RESERVED_LOCKED_TOKENS = 250e6 * (10 ** DECIMALS);
    uint256 constant public RESERVED_TEAMS_TOKENS = 100e6 * (10 ** DECIMALS);
    uint256 constant public RESERVED_FOUNDERS_TOKENS = 100e6 * (10 ** DECIMALS);
    uint256 constant public RESERVED_MARKETING_TOKENS = 50e6 * (10 ** DECIMALS);

    uint256 constant public MAXCAP_TOKENS_PRE_ICO = 100e6 * (10 ** DECIMALS);
    
    uint256 constant public MAXCAP_TOKENS_ICO = 400e6 * (10 ** DECIMALS);

    uint256 constant public MIN_INVESTMENT = (10 ** 16);    

    uint256 constant public MAX_INVESTMENT = 100 * (10 ** DECIMALS);  

    uint256 public startTimePreIco = 0;
    uint256 public endTimePreIco = 0;

    uint256 public startTimeIco = 0;
    uint256 public endTimeIco = 0;

     
    uint256 public exchangeRatePreIco = 200;

    uint256 public icoFirstWeekRate = 150;
    uint256 public icoSecondWeekRate = 125;
    uint256 public icoThirdWeekRate = 110;
     
    uint256 public icoRate = 100;

    uint256 public tokensRemainingPreIco = MAXCAP_TOKENS_PRE_ICO;
    uint256 public tokensRemainingIco = MAXCAP_TOKENS_ICO;

    uint256 public tokensSoldPreIco = 0;
    uint256 public tokensSoldIco = 0;
    uint256 public tokensSoldTotal = 0;

    uint256 public weiRaisedPreIco = 0;
    uint256 public weiRaisedIco = 0;
    uint256 public weiRaisedTotal = 0;

    VeiagToken public token = new VeiagToken(this);
    LockedOutTokens public lockedTokens;
    VeiagTokenVesting public teamsTokenVesting;
    VeiagTokenVesting public foundersTokenVesting;

    mapping (address => uint256) private totalInvestedAmount;

    modifier beforeReachingPreIcoMaxCap() {
        require(tokensRemainingPreIco > 0);
        _;
    }

    modifier beforeReachingIcoMaxCap() {
        require(tokensRemainingIco > 0);
        _;
    }

     
    function VeiagCrowdsale(
        uint256 _startTimePreIco,
        uint256 _endTimePreIco, 
        uint256 _startTimeIco,
        uint256 _endTimeIco,
        address _lockedWallet,
        address _teamsWallet,
        address _foundersWallet,
        address _marketingWallet
    ) public Whitelistable()
    {
        require(_lockedWallet != address(0) && _teamsWallet != address(0) && _foundersWallet != address(0) && _marketingWallet != address(0));
        require(_startTimePreIco > now && _endTimePreIco > _startTimePreIco);
        require(_startTimeIco > _endTimePreIco && _endTimeIco > _startTimeIco);
        startTimePreIco = _startTimePreIco;
        endTimePreIco = _endTimePreIco;

        startTimeIco = _startTimeIco;
        endTimeIco = _endTimeIco;

        lockedTokens = new LockedOutTokens(token, _lockedWallet, RESERVED_LOCKED_TOKENS);
        teamsTokenVesting = new VeiagTokenVesting(token, _teamsWallet, 0, 1 days, 365 days, false);
        foundersTokenVesting = new VeiagTokenVesting(token, _foundersWallet, 0, 1 days, 100 days, false);

        token.transferFromIco(lockedTokens, RESERVED_LOCKED_TOKENS);
        token.transferFromIco(teamsTokenVesting, RESERVED_TEAMS_TOKENS);
        token.transferFromIco(foundersTokenVesting, RESERVED_FOUNDERS_TOKENS);
        token.transferFromIco(_marketingWallet, RESERVED_MARKETING_TOKENS);
        teamsTokenVesting.transferOwnership(this);
        foundersTokenVesting.transferOwnership(this);        
        
        whitelist.transferOwnership(msg.sender);
        token.transferOwnership(msg.sender);
    }
	function SetStartVesting(uint256 _startTimeVestingForFounders) public onlyOwner{
	    require(now > endTimeIco);
	    require(_startTimeVestingForFounders > endTimeIco);
	    teamsTokenVesting.setStart(_startTimeVestingForFounders);
	    foundersTokenVesting.setStart(endTimeIco);
        teamsTokenVesting.transferOwnership(msg.sender);
        foundersTokenVesting.transferOwnership(msg.sender);	    
	}

	function SetStartTimeIco(uint256 _startTimeIco) public onlyOwner{
        uint256 deltaTime;  
        require(_startTimeIco > now && startTimeIco > now);
        if (_startTimeIco > startTimeIco){
          deltaTime = _startTimeIco.sub(startTimeIco);
	      endTimePreIco = endTimePreIco.add(deltaTime);
	      startTimeIco = startTimeIco.add(deltaTime);
	      endTimeIco = endTimeIco.add(deltaTime);
        }
        if (_startTimeIco < startTimeIco){
          deltaTime = startTimeIco.sub(_startTimeIco);
          endTimePreIco = endTimePreIco.sub(deltaTime);
	      startTimeIco = startTimeIco.sub(deltaTime);
	      endTimeIco = endTimeIco.sub(deltaTime);
        }  
    }
	
	
    
     
    function() public payable {
        if (isPreIco()) {
            sellTokensPreIco();
        } else if (isIco()) {
            sellTokensIco();
        } else {
            revert();
        }
    }

     
    function isPreIco() public view returns (bool) {
        return now >= startTimePreIco && now <= endTimePreIco;
    }

     
    function isIco() public view returns (bool) {
        return now >= startTimeIco && now <= endTimeIco;
    }

     
    function exchangeRateIco() public view returns(uint256) {
        require(now >= startTimeIco && now <= endTimeIco);

        if (now < startTimeIco + 1 weeks)
            return icoFirstWeekRate;

        if (now < startTimeIco + 2 weeks)
            return icoSecondWeekRate;

        if (now < startTimeIco + 3 weeks)
            return icoThirdWeekRate;

        return icoRate;
    }
	
    function setExchangeRatePreIco(uint256 _exchangeRatePreIco) public onlyOwner{
	  exchangeRatePreIco = _exchangeRatePreIco;
	} 
	
    function setIcoFirstWeekRate(uint256 _icoFirstWeekRate) public onlyOwner{
	  icoFirstWeekRate = _icoFirstWeekRate;
	} 	
	
    function setIcoSecondWeekRate(uint256 _icoSecondWeekRate) public onlyOwner{
	  icoSecondWeekRate = _icoSecondWeekRate;
	} 
	
    function setIcoThirdWeekRate(uint256 _icoThirdWeekRate) public onlyOwner{
	  icoThirdWeekRate = _icoThirdWeekRate;
	}
	
    function setIcoRate(uint256 _icoRate) public onlyOwner{
	  icoRate = _icoRate;
	}
	
     
    function sellTokensPreIco() public payable whenWhitelisted(msg.sender) beforeReachingPreIcoMaxCap whenNotPaused {
        require(isPreIco());
        require(msg.value >= MIN_INVESTMENT);
        uint256 senderTotalInvestment = totalInvestedAmount[msg.sender].add(msg.value);
        require(senderTotalInvestment <= MAX_INVESTMENT);

        uint256 weiAmount = msg.value;
        uint256 excessiveFunds = 0;

        uint256 tokensAmount = weiAmount.mul(exchangeRatePreIco);

        if (tokensAmount > tokensRemainingPreIco) {
            uint256 weiToAccept = tokensRemainingPreIco.div(exchangeRatePreIco);
            excessiveFunds = weiAmount.sub(weiToAccept);

            tokensAmount = tokensRemainingPreIco;
            weiAmount = weiToAccept;
        }

        addPreIcoPurchaseInfo(weiAmount, tokensAmount);

        owner.transfer(weiAmount);

        token.transferFromIco(msg.sender, tokensAmount);

        if (excessiveFunds > 0) {
            msg.sender.transfer(excessiveFunds);
        }
    }

     
    function sellTokensIco() public payable whenWhitelisted(msg.sender) beforeReachingIcoMaxCap whenNotPaused {
        require(isIco());
        require(msg.value >= MIN_INVESTMENT);
        uint256 senderTotalInvestment = totalInvestedAmount[msg.sender].add(msg.value);
        require(senderTotalInvestment <= MAX_INVESTMENT);

        uint256 weiAmount = msg.value;
        uint256 excessiveFunds = 0;

        uint256 tokensAmount = weiAmount.mul(exchangeRateIco());

        if (tokensAmount > tokensRemainingIco) {
            uint256 weiToAccept = tokensRemainingIco.div(exchangeRateIco());
            excessiveFunds = weiAmount.sub(weiToAccept);

            tokensAmount = tokensRemainingIco;
            weiAmount = weiToAccept;
        }

        addIcoPurchaseInfo(weiAmount, tokensAmount);

        owner.transfer(weiAmount);

        token.transferFromIco(msg.sender, tokensAmount);

        if (excessiveFunds > 0) {
            msg.sender.transfer(excessiveFunds);
        }
    }

     
    function manualSendTokens(address _address, uint256 _tokensAmount) public whenWhitelisted(_address) onlyOwner {
        require(_address != address(0));
        require(_tokensAmount > 0);
        
        if (isPreIco() && _tokensAmount <= tokensRemainingPreIco) {
            token.transferFromIco(_address, _tokensAmount);
            addPreIcoPurchaseInfo(0, _tokensAmount);
        } else if (isIco() && _tokensAmount <= tokensRemainingIco) {
            token.transferFromIco(_address, _tokensAmount);
            addIcoPurchaseInfo(0, _tokensAmount);
        } else {
            revert();
        }
    }

     
    function addPreIcoPurchaseInfo(uint256 _weiAmount, uint256 _tokensAmount) internal {
        totalInvestedAmount[msg.sender] = totalInvestedAmount[msg.sender].add(_weiAmount);

        tokensSoldPreIco = tokensSoldPreIco.add(_tokensAmount);
        tokensSoldTotal = tokensSoldTotal.add(_tokensAmount);
        tokensRemainingPreIco = tokensRemainingPreIco.sub(_tokensAmount);

        weiRaisedPreIco = weiRaisedPreIco.add(_weiAmount);
        weiRaisedTotal = weiRaisedTotal.add(_weiAmount);
    }

     
    function addIcoPurchaseInfo(uint256 _weiAmount, uint256 _tokensAmount) internal {
        totalInvestedAmount[msg.sender] = totalInvestedAmount[msg.sender].add(_weiAmount);

        tokensSoldIco = tokensSoldIco.add(_tokensAmount);
        tokensSoldTotal = tokensSoldTotal.add(_tokensAmount);
        tokensRemainingIco = tokensRemainingIco.sub(_tokensAmount);

        weiRaisedIco = weiRaisedIco.add(_weiAmount);
        weiRaisedTotal = weiRaisedTotal.add(_weiAmount);
    }
}
contract Factory {
    VeiagCrowdsale public crowdsale;

    function createCrowdsale (
        uint256 _startTimePreIco,
        uint256 _endTimePreIco,
        uint256 _startTimeIco,
        uint256 _endTimeIco,
        address _lockedWallet,
        address _teamsWallet,
        address _foundersWallet,
        address _marketingWallet
    ) public
    {
        crowdsale = new VeiagCrowdsale(
            _startTimePreIco,
            _endTimePreIco,
            _startTimeIco,
            _endTimeIco,
            _lockedWallet,
            _teamsWallet,
            _foundersWallet,
            _marketingWallet
        );

        Whitelist whitelist = crowdsale.whitelist();
        whitelist.transferOwnership(msg.sender);

        VeiagToken token = crowdsale.token();
        token.transferOwnership(msg.sender);
        crowdsale.transferOwnership(msg.sender);
    }
}