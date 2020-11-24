 

pragma solidity ^0.4.17;
 
contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }
    address public controller;
    function Controlled() public { controller = msg.sender;}
     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}
 
contract ERC20MiniMe is ERC20, Controlled {
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool);
    function totalSupply() public view returns (uint);
    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint);
    function totalSupplyAt(uint _blockNumber) public view returns(uint);
    function createCloneToken(string _cloneTokenName, uint8 _cloneDecimalUnits, string _cloneTokenSymbol, uint _snapshotBlock, bool _transfersEnabled) public returns(address);
    function generateTokens(address _owner, uint _amount) public returns (bool);
    function destroyTokens(address _owner, uint _amount)  public returns (bool);
    function enableTransfers(bool _transfersEnabled) public;
    function isContract(address _addr) internal view returns(bool);
    function claimTokens(address _token) public;
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
}
 
contract Crowdsale {
  using SafeMath for uint256;
   
  ERC20MiniMe public token;
   
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
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }
   
  function () payable {
    buyTokens(msg.sender);
  }
   
  function buyTokens(address beneficiary) public payable {
    buyTokens(beneficiary, msg.value);
  }
   
  function buyTokens(address beneficiary, uint256 weiAmount) internal {
    require(beneficiary != 0x0);
    require(validPurchase(weiAmount));
     
    weiRaised = weiRaised.add(weiAmount);
    transferToken(beneficiary, weiAmount);
    forwardFunds(weiAmount);
  }
   
   
  function transferToken(address beneficiary, uint256 weiAmount) internal {
     
    uint256 tokens = weiAmount.mul(rate);
    token.generateTokens(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }
   
   
  function forwardFunds(uint256 weiAmount) internal {
    wallet.transfer(weiAmount);
  }
   
  function validPurchase(uint256 weiAmount) internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = weiAmount != 0;
    return withinPeriod && nonZeroPurchase;
  }
   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }
   
  function hasStarted() public view returns (bool) {
    return now >= startTime;
  }
}
 
contract TokenController {
    ERC20MiniMe public ethealToken;
    address public SALE;  
     
    function addHodlerStake(address _beneficiary, uint _stake) public;
    function setHodlerStake(address _beneficiary, uint256 _stake) public;
    function setHodlerTime(uint256 _time) public;
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);
     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);
     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
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
 
contract Hodler is Ownable {
    using SafeMath for uint;
     
     
    struct HODL {
        uint256 stake;
         
        bool invalid;
        bool claimed3M;
        bool claimed6M;
        bool claimed9M;
    }
    mapping (address => HODL) public hodlerStakes;
     
    uint256 public hodlerTotalValue;
    uint256 public hodlerTotalCount;
     
    uint256 public hodlerTotalValue3M;
    uint256 public hodlerTotalValue6M;
    uint256 public hodlerTotalValue9M;
    uint256 public hodlerTimeStart;
    uint256 public hodlerTime3M;
    uint256 public hodlerTime6M;
    uint256 public hodlerTime9M;
     
    uint256 public TOKEN_HODL_3M;
    uint256 public TOKEN_HODL_6M;
    uint256 public TOKEN_HODL_9M;
     
    uint256 public claimedTokens;
    
    event LogHodlSetStake(address indexed _setter, address indexed _beneficiary, uint256 _value);
    event LogHodlClaimed(address indexed _setter, address indexed _beneficiary, uint256 _value);
    event LogHodlStartSet(address indexed _setter, uint256 _time);
     
    modifier beforeHodlStart() {
        if (hodlerTimeStart == 0 || now <= hodlerTimeStart)
            _;
    }
     
    function Hodler(uint256 _stake3m, uint256 _stake6m, uint256 _stake9m) {
        TOKEN_HODL_3M = _stake3m;
        TOKEN_HODL_6M = _stake6m;
        TOKEN_HODL_9M = _stake9m;
    }
     
     
     
     
    function addHodlerStake(address _beneficiary, uint256 _stake) public onlyOwner beforeHodlStart {
         
        if (_stake == 0 || _beneficiary == address(0))
            return;
        
         
        if (hodlerStakes[_beneficiary].stake == 0)
            hodlerTotalCount = hodlerTotalCount.add(1);
        hodlerStakes[_beneficiary].stake = hodlerStakes[_beneficiary].stake.add(_stake);
        hodlerTotalValue = hodlerTotalValue.add(_stake);
        LogHodlSetStake(msg.sender, _beneficiary, hodlerStakes[_beneficiary].stake);
    }
     
     
     
     
    function setHodlerStake(address _beneficiary, uint256 _stake) public onlyOwner beforeHodlStart {
         
        if (hodlerStakes[_beneficiary].stake == _stake || _beneficiary == address(0))
            return;
        
         
        if (hodlerStakes[_beneficiary].stake == 0 && _stake > 0) {
            hodlerTotalCount = hodlerTotalCount.add(1);
        } else if (hodlerStakes[_beneficiary].stake > 0 && _stake == 0) {
            hodlerTotalCount = hodlerTotalCount.sub(1);
        }
        uint256 _diff = _stake > hodlerStakes[_beneficiary].stake ? _stake.sub(hodlerStakes[_beneficiary].stake) : hodlerStakes[_beneficiary].stake.sub(_stake);
        if (_stake > hodlerStakes[_beneficiary].stake) {
            hodlerTotalValue = hodlerTotalValue.add(_diff);
        } else {
            hodlerTotalValue = hodlerTotalValue.sub(_diff);
        }
        hodlerStakes[_beneficiary].stake = _stake;
        LogHodlSetStake(msg.sender, _beneficiary, _stake);
    }
     
     
    function setHodlerTime(uint256 _time) public onlyOwner beforeHodlStart {
        require(_time >= now);
        hodlerTimeStart = _time;
        hodlerTime3M = _time.add(90 days);
        hodlerTime6M = _time.add(180 days);
        hodlerTime9M = _time.add(270 days);
        LogHodlStartSet(msg.sender, _time);
    }
     
     
    function invalidate(address _account) public onlyOwner {
        if (hodlerStakes[_account].stake > 0 && !hodlerStakes[_account].invalid) {
            hodlerStakes[_account].invalid = true;
            hodlerTotalValue = hodlerTotalValue.sub(hodlerStakes[_account].stake);
            hodlerTotalCount = hodlerTotalCount.sub(1);
        }
         
        updateAndGetHodlTotalValue();
    }
     
    function claimHodlReward() public {
        claimHodlRewardFor(msg.sender);
    }
     
    function claimHodlRewardFor(address _beneficiary) public {
         
        require(hodlerStakes[_beneficiary].stake > 0 && !hodlerStakes[_beneficiary].invalid);
        uint256 _stake = 0;
        
         
        updateAndGetHodlTotalValue();
         
        if (!hodlerStakes[_beneficiary].claimed3M && now >= hodlerTime3M) {
            _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue3M));
            hodlerStakes[_beneficiary].claimed3M = true;
        }
        if (!hodlerStakes[_beneficiary].claimed6M && now >= hodlerTime6M) {
            _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_6M).div(hodlerTotalValue6M));
            hodlerStakes[_beneficiary].claimed6M = true;
        }
        if (!hodlerStakes[_beneficiary].claimed9M && now >= hodlerTime9M) {
            _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_9M).div(hodlerTotalValue9M));
            hodlerStakes[_beneficiary].claimed9M = true;
        }
        if (_stake > 0) {
             
            claimedTokens = claimedTokens.add(_stake);
             
            require(TokenController(owner).ethealToken().transfer(_beneficiary, _stake));
             
            LogHodlClaimed(msg.sender, _beneficiary, _stake);
        }
    }
     
     
     
    function claimHodlRewardsFor(address[] _beneficiaries) external {
        for (uint256 i = 0; i < _beneficiaries.length; i++)
            claimHodlRewardFor(_beneficiaries[i]);
    }
     
    function updateAndGetHodlTotalValue() public returns (uint) {
        if (now >= hodlerTime3M && hodlerTotalValue3M == 0) {
            hodlerTotalValue3M = hodlerTotalValue;
        }
        if (now >= hodlerTime6M && hodlerTotalValue6M == 0) {
            hodlerTotalValue6M = hodlerTotalValue;
        }
        if (now >= hodlerTime9M && hodlerTotalValue9M == 0) {
            hodlerTotalValue9M = hodlerTotalValue;
             
            TOKEN_HODL_9M = TokenController(owner).ethealToken().balanceOf(this).sub(TOKEN_HODL_3M).sub(TOKEN_HODL_6M).add(claimedTokens);
        }
        return hodlerTotalValue;
    }
}
 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  event Released(uint256 amount);
  event Revoked();
   
  address public beneficiary;
  uint256 public cliff;
  uint256 public start;
  uint256 public duration;
  bool public revocable;
  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;
   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);
    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }
   
  function release(ERC20MiniMe token) public {
    uint256 unreleased = releasableAmount(token);
    require(unreleased > 0);
    released[token] = released[token].add(unreleased);
    require(token.transfer(beneficiary, unreleased));
    Released(unreleased);
  }
   
  function revoke(ERC20MiniMe token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);
    uint256 balance = token.balanceOf(this);
    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);
    revoked[token] = true;
    require(token.transfer(owner, refund));
    Revoked();
  }
   
  function releasableAmount(ERC20MiniMe token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }
   
  function vestedAmount(ERC20MiniMe token) public view returns (uint256) {
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
 
contract HasNoTokens is Ownable {
    event ExtractedTokens(address indexed _token, address indexed _claimer, uint _amount);
     
     
     
     
     
    function extractTokens(address _token, address _claimer) onlyOwner public {
        if (_token == 0x0) {
            _claimer.transfer(this.balance);
            return;
        }
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        token.transfer(_claimer, balance);
        ExtractedTokens(_token, _claimer, balance);
    }
}
 
contract EthealController is Pausable, HasNoTokens, TokenController {
    using SafeMath for uint;
     
    TokenController public newController;
     
    ERC20MiniMe public ethealToken;
     
    uint256 public constant ETHEAL_UNIT = 10**18;
    uint256 public constant THOUSAND = 10**3;
    uint256 public constant MILLION = 10**6;
    uint256 public constant TOKEN_SALE1_PRE = 9 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_SALE1_NORMAL = 20 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_SALE2 = 9 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_SALE3 = 5 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_HODL_3M = 1 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_HODL_6M = 2 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_HODL_9M = 7 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_REFERRAL = 2 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_BOUNTY = 1500 * THOUSAND * ETHEAL_UNIT;
    uint256 public constant TOKEN_COMMUNITY = 20 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_TEAM = 14 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_FOUNDERS = 6500 * THOUSAND * ETHEAL_UNIT;
    uint256 public constant TOKEN_INVESTORS = 3 * MILLION * ETHEAL_UNIT;
     
    address public SALE = 0X1;
    address public FOUNDER1 = 0x296dD2A2879fEBe2dF65f413999B28C053397fC5;
    address public FOUNDER2 = 0x0E2feF8e4125ed0f49eD43C94b2B001C373F74Bf;
    address public INVESTOR1 = 0xAAd27eD6c93d91aa60Dc827bE647e672d15e761A;
    address public INVESTOR2 = 0xb906665f4ef609189A31CE55e01C267EC6293Aa5;
     
    address public ethealMultisigWallet;
    Crowdsale public crowdsale;
     
    Hodler public hodlerReward;
     
    TokenVesting[] public tokenGrants;
    uint256 public constant VESTING_TEAM_CLIFF = 365 days;
    uint256 public constant VESTING_TEAM_DURATION = 4 * 365 days;
    uint256 public constant VESTING_ADVISOR_CLIFF = 3 * 30 days;
    uint256 public constant VESTING_ADVISOR_DURATION = 6 * 30 days;
     
    modifier onlyCrowdsale() {
        require(msg.sender == address(crowdsale));
        _;
    }
     
    modifier onlyEthealMultisig() {
        require(msg.sender == address(ethealMultisigWallet));
        _;
    }
     
     
     
     
    function EthealController(address _wallet) {
        require(_wallet != address(0));
        paused = true;
        ethealMultisigWallet = _wallet;
    }
     
    function extractTokens(address _token, address _claimer) onlyOwner public {
        require(newController != address(0) || _token != address(ethealToken));
        super.extractTokens(_token, _claimer);
    }
     
     
     
     
     
    function setCrowdsaleTransfer(address _sale, uint256 _amount) public onlyOwner {
        require (_sale != address(0) && !isCrowdsaleOpen() && address(ethealToken) != address(0));
        crowdsale = Crowdsale(_sale);
         
        require(ethealToken.transferFrom(SALE, _sale, _amount));
    }
     
     
    function isCrowdsaleOpen() public view returns (bool) {
        return address(crowdsale) != address(0) && !crowdsale.hasEnded() && crowdsale.hasStarted();
    }
     
     
     
     
    function createGrant(address _beneficiary, uint256 _start, uint256 _amount, bool _revocable, bool _advisor) public onlyOwner {
        require(_beneficiary != address(0) && _amount > 0 && _start >= now);
         
        if (_advisor) {
            tokenGrants.push(new TokenVesting(_beneficiary, _start, VESTING_ADVISOR_CLIFF, VESTING_ADVISOR_DURATION, _revocable));
        } else {
            tokenGrants.push(new TokenVesting(_beneficiary, _start, VESTING_TEAM_CLIFF, VESTING_TEAM_DURATION, _revocable));
        }
         
        transferToGrant(tokenGrants.length.sub(1), _amount);
    }
     
    function transferToGrant(uint256 _id, uint256 _amount) public onlyOwner {
        require(_id < tokenGrants.length && _amount > 0 && now <= tokenGrants[_id].start());
         
        require(ethealToken.transfer(address(tokenGrants[_id]), _amount));
    }
     
    function revokeGrant(uint256 _id) public onlyOwner {
        require(_id < tokenGrants.length);
        tokenGrants[_id].revoke(ethealToken);
    }
     
    function getGrantCount() view public returns (uint) {
        return tokenGrants.length;
    }
     
     
     
     
    function burn(address _where, uint256 _amount) public onlyEthealMultisig {
        require(_where == address(this) || _where == SALE);
        require(ethealToken.destroyTokens(_where, _amount));
    }
     
    function setNewController(address _controller) public onlyEthealMultisig {
        require(_controller != address(0) && newController == address(0));
        newController = TokenController(_controller);
        ethealToken.changeController(_controller);
        hodlerReward.transferOwnership(_controller);
         
        uint256 _stake = this.balance;
        if (_stake > 0) {
            _controller.transfer(_stake);
        }
         
        _stake = ethealToken.balanceOf(this);
        if (_stake > 0) {
            ethealToken.transfer(_controller, _stake);
        }
    }
     
    function setNewMultisig(address _wallet) public onlyEthealMultisig {
        require(_wallet != address(0));
        ethealMultisigWallet = _wallet;
    }
     
     
     
     
    function setEthealToken(address _token, address _hodler) public onlyOwner whenPaused {
        require(_token != address(0));
        ethealToken = ERC20MiniMe(_token);
        
        if (_hodler != address(0)) {
             
            hodlerReward = Hodler(_hodler);
        } else if (hodlerReward == address(0)) {
             
            hodlerReward = new Hodler(TOKEN_HODL_3M, TOKEN_HODL_6M, TOKEN_HODL_9M);
        }
         
        if (ethealToken.totalSupply() == 0) {
             
            ethealToken.generateTokens(SALE, TOKEN_SALE1_PRE.add(TOKEN_SALE1_NORMAL).add(TOKEN_SALE2).add(TOKEN_SALE3));
             
            ethealToken.generateTokens(address(hodlerReward), TOKEN_HODL_3M.add(TOKEN_HODL_6M).add(TOKEN_HODL_9M));
             
            ethealToken.generateTokens(owner, TOKEN_BOUNTY.add(TOKEN_REFERRAL));
             
            ethealToken.generateTokens(address(ethealMultisigWallet), TOKEN_COMMUNITY);
             
            ethealToken.generateTokens(address(this), TOKEN_FOUNDERS.add(TOKEN_TEAM));
             
            ethealToken.generateTokens(INVESTOR1, TOKEN_INVESTORS.div(3).mul(2));
            ethealToken.generateTokens(INVESTOR2, TOKEN_INVESTORS.div(3));
        }
    }
     
     
     
    
     
    function setHodlerTime(uint256 _time) public onlyCrowdsale {
        hodlerReward.setHodlerTime(_time);
    }
     
    function addHodlerStake(address _beneficiary, uint256 _stake) public onlyCrowdsale {
        hodlerReward.addHodlerStake(_beneficiary, _stake);
    }
     
    function setHodlerStake(address _beneficiary, uint256 _stake) public onlyCrowdsale {
        hodlerReward.setHodlerStake(_beneficiary, _stake);
    }
     
     
     
     
    function proxyPayment(address _owner) payable public returns (bool) {
        revert();
    }
     
    function onTransfer(address _from, address _to, uint256 _amount) public returns (bool) {
         
        hodlerReward.invalidate(_from);
        return !paused || _from == address(this) || _to == address(this) || _from == address(crowdsale) || _to == address(crowdsale);
    }
    function onApprove(address _owner, address _spender, uint256 _amount) public returns (bool) {
        return !paused;
    }
     
    function claimTokenTokens(address _token) public onlyOwner {
        require(_token != address(ethealToken));
        ethealToken.claimTokens(_token);
    }
}