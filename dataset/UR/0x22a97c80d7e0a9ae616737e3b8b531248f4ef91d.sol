 

contract ReentrancyGuard {

   
  bool private rentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
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

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = 0x0;
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

contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
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

contract Campaign is Claimable, HasNoTokens, ReentrancyGuard {
    using SafeMath for uint256;

    string constant public version = "1.0.0";

    string public id;

    string public name;

    string public website;

    bytes32 public whitePaperHash;

    uint256 public fundingThreshold;

    uint256 public fundingGoal;

    uint256 public tokenPrice;

    enum TimeMode {
        Block,
        Timestamp
    }

    TimeMode public timeMode;

    uint256 public startTime;

    uint256 public finishTime;

    enum BonusMode {
        Flat,
        Block,
        Timestamp,
        AmountRaised,
        ContributionAmount
    }

    BonusMode public bonusMode;

    uint256[] public bonusLevels;

    uint256[] public bonusRates;  

    address public beneficiary;

    uint256 public amountRaised;

    uint256 public minContribution;

    uint256 public earlySuccessTimestamp;

    uint256 public earlySuccessBlock;

    mapping (address => uint256) public contributions;

    Token public token;

    enum Stage {
        Init,
        Ready,
        InProgress,
        Failure,
        Success
    }

    function stage()
    public
    constant
    returns (Stage)
    {
        if (token == address(0)) {
            return Stage.Init;
        }

        var _time = timeMode == TimeMode.Timestamp ? block.timestamp : block.number;

        if (_time < startTime) {
            return Stage.Ready;
        }

        if (finishTime <= _time) {
            if (amountRaised < fundingThreshold) {
                return Stage.Failure;
            }
            return Stage.Success;
        }

        if (fundingGoal <= amountRaised) {
            return Stage.Success;
        }

        return Stage.InProgress;
    }

    modifier atStage(Stage _stage) {
        require(stage() == _stage);
        _;
    }

    event Contribution(address sender, uint256 amount);

    event Refund(address recipient, uint256 amount);

    event Payout(address recipient, uint256 amount);

    event EarlySuccess();

    function Campaign(
        string _id,
        address _beneficiary,
        string _name,
        string _website,
        bytes32 _whitePaperHash
    )
    public
    {
        id = _id;
        beneficiary = _beneficiary;
        name = _name;
        website = _website;
        whitePaperHash = _whitePaperHash;
    }

    function setParams(
         
        uint256[] _fundingThreshold_fundingGoal_tokenPrice_startTime_finishTime,
        uint8[] _timeMode_bonusMode,
        uint256[] _bonusLevels,
        uint256[] _bonusRates
    )
    public
    onlyOwner
    atStage(Stage.Init)
    {
        assert(fundingGoal == 0);

        fundingThreshold = _fundingThreshold_fundingGoal_tokenPrice_startTime_finishTime[0];
        fundingGoal = _fundingThreshold_fundingGoal_tokenPrice_startTime_finishTime[1];
        tokenPrice = _fundingThreshold_fundingGoal_tokenPrice_startTime_finishTime[2];
        timeMode = TimeMode(_timeMode_bonusMode[0]);
        startTime = _fundingThreshold_fundingGoal_tokenPrice_startTime_finishTime[3];
        finishTime = _fundingThreshold_fundingGoal_tokenPrice_startTime_finishTime[4];
        bonusMode = BonusMode(_timeMode_bonusMode[1]);
        bonusLevels = _bonusLevels;
        bonusRates = _bonusRates;

        require(fundingThreshold > 0);
        require(fundingThreshold <= fundingGoal);
        require(startTime < finishTime);
        require((timeMode == TimeMode.Block ? block.number : block.timestamp) < startTime);
        require(bonusLevels.length == bonusRates.length);
    }

    function createToken(
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals,
        address[] _distributionRecipients,
        uint256[] _distributionAmounts,
        uint256[] _releaseTimes
    )
    public
    onlyOwner
    atStage(Stage.Init)
    {
        assert(fundingGoal > 0);

        token = new Token(
            _tokenName,
            _tokenSymbol,
            _tokenDecimals,
            _distributionRecipients,
            _distributionAmounts,
            _releaseTimes,
            uint8(timeMode)
        );

        minContribution = tokenPrice.div(10 ** uint256(token.decimals()));
        if (minContribution < 1 wei) {
            minContribution = 1 wei;
        }
    }

    function()
    public
    payable
    atStage(Stage.InProgress)
    {
        require(minContribution <= msg.value);

        contributions[msg.sender] = contributions[msg.sender].add(msg.value);

         
        uint256 _level;
        uint256 _tokensAmount;
        uint i;
        if (bonusMode == BonusMode.AmountRaised) {
            _level = amountRaised;
            uint256 _value = msg.value;
            uint256 _weightedRateSum = 0;
            uint256 _stepAmount;
            for (i = 0; i < bonusLevels.length; i++) {
                if (_level <= bonusLevels[i]) {
                    _stepAmount = bonusLevels[i].sub(_level);
                    if (_value <= _stepAmount) {
                        _level = _level.add(_value);
                        _weightedRateSum = _weightedRateSum.add(_value.mul(bonusRates[i]));
                        _value = 0;
                        break;
                    } else {
                        _level = _level.add(_stepAmount);
                        _weightedRateSum = _weightedRateSum.add(_stepAmount.mul(bonusRates[i]));
                        _value = _value.sub(_stepAmount);
                    }
                }
            }
            _weightedRateSum = _weightedRateSum.add(_value.mul(1 ether));

            _tokensAmount = _weightedRateSum.div(1 ether).mul(10 ** uint256(token.decimals())).div(tokenPrice);
        } else {
            _tokensAmount = msg.value.mul(10 ** uint256(token.decimals())).div(tokenPrice);

            if (bonusMode == BonusMode.Block) {
                _level = block.number;
            }
            if (bonusMode == BonusMode.Timestamp) {
                _level = block.timestamp;
            }
            if (bonusMode == BonusMode.ContributionAmount) {
                _level = msg.value;
            }

            for (i = 0; i < bonusLevels.length; i++) {
                if (_level <= bonusLevels[i]) {
                    _tokensAmount = _tokensAmount.mul(bonusRates[i]).div(1 ether);
                    break;
                }
            }
        }

        amountRaised = amountRaised.add(msg.value);

         
        require(amountRaised <= fundingGoal);

        require(token.mint(msg.sender, _tokensAmount));

        Contribution(msg.sender, msg.value);

        if (fundingGoal <= amountRaised) {
            earlySuccessTimestamp = block.timestamp;
            earlySuccessBlock = block.number;
            token.finishMinting();
            EarlySuccess();
        }
    }

    function withdrawPayout()
    public
    atStage(Stage.Success)
    {
        require(msg.sender == beneficiary);

        if (!token.mintingFinished()) {
            token.finishMinting();
        }

        var _amount = this.balance;
        require(beneficiary.call.value(_amount)());
        Payout(beneficiary, _amount);
    }

     
    function releaseTokens()
    public
    atStage(Stage.Success)
    {
        require(!token.mintingFinished());
        token.finishMinting();
    }

    function withdrawRefund()
    public
    atStage(Stage.Failure)
    nonReentrant
    {
        var _amount = contributions[msg.sender];

        require(_amount > 0);

        contributions[msg.sender] = 0;

        msg.sender.transfer(_amount);
        Refund(msg.sender, _amount);
    }
}

contract Token is MintableToken, NoOwner {
    string constant public version = "1.0.0";

    string public name;

    string public symbol;

    uint8 public decimals;

    enum TimeMode {
        Block,
        Timestamp
    }

    TimeMode public timeMode;

    mapping (address => uint256) public releaseTimes;

    function Token(
        string _name,
        string _symbol,
        uint8 _decimals,
        address[] _recipients,
        uint256[] _amounts,
        uint256[] _releaseTimes,
        uint8 _timeMode
    )
    public
    {
        require(_recipients.length == _amounts.length);
        require(_recipients.length == _releaseTimes.length);

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        timeMode = TimeMode(_timeMode);

         
        for (uint256 i = 0; i < _recipients.length; i++) {
            mint(_recipients[i], _amounts[i]);
            if (_releaseTimes[i] > 0) {
                releaseTimes[_recipients[i]] = _releaseTimes[i];
            }
        }
    }

    function transfer(address _to, uint256 _value)
    public
    returns (bool)
    {
         
        require(mintingFinished);

         
        require(!timeLocked(msg.sender));

        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
    public
    returns (bool)
    {
         
        require(mintingFinished);

         
        require(!timeLocked(_from));

        return super.transferFrom(_from, _to, _value);
    }

     
    function timeLocked(address _spender)
    public
    constant
    returns (bool)
    {
        if (releaseTimes[_spender] == 0) {
            return false;
        }

         
        var _time = timeMode == TimeMode.Timestamp ? block.timestamp : block.number;
        if (releaseTimes[_spender] <= _time) {
            delete releaseTimes[_spender];
            return false;
        }

        return true;
    }
}