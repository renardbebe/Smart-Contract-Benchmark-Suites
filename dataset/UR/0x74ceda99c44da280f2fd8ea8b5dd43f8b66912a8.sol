 

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
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
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
    totalSupply_ = totalSupply_.add(_amount);
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

contract Whitelistable is Ownable {
    
    event LogUserRegistered(address indexed sender, address indexed userAddress);
    event LogUserUnregistered(address indexed sender, address indexed userAddress);
    
    mapping(address => bool) public whitelisted;

    function registerUser(address userAddress) 
        public 
        onlyOwner 
    {
        require(userAddress != 0);
        whitelisted[userAddress] = true;
        LogUserRegistered(msg.sender, userAddress);
    }

    function unregisterUser(address userAddress) 
        public 
        onlyOwner 
    {
        require(whitelisted[userAddress] == true);
        whitelisted[userAddress] = false;
        LogUserUnregistered(msg.sender, userAddress);
    }
}

contract DisbursementHandler is Ownable {

    struct Disbursement {
        uint256 timestamp;
        uint256 tokens;
    }

    event LogSetup(address indexed vestor, uint256 tokens, uint256 timestamp);
    event LogChangeTimestamp(address indexed vestor, uint256 index, uint256 timestamp);
    event LogWithdraw(address indexed to, uint256 value);

    ERC20 public token;
    mapping(address => Disbursement[]) public disbursements;
    mapping(address => uint256) public withdrawnTokens;

    function DisbursementHandler(address _token) public {
        token = ERC20(_token);
    }

     
     
     
     
    function setupDisbursement(
        address vestor,
        uint256 tokens,
        uint256 timestamp
    )
        public
        onlyOwner
    {
        require(block.timestamp < timestamp);
        disbursements[vestor].push(Disbursement(timestamp, tokens));
        LogSetup(vestor, timestamp, tokens);
    }

     
     
     
     
    function changeTimestamp(
        address vestor,
        uint256 index,
        uint256 timestamp
    )
        public
        onlyOwner
    {
        require(block.timestamp < timestamp);
        require(index < disbursements[vestor].length);
        disbursements[vestor][index].timestamp = timestamp;
        LogChangeTimestamp(vestor, index, timestamp);
    }

     
     
     
    function withdraw(address to, uint256 value)
        public
    {
        uint256 maxTokens = calcMaxWithdraw();
        uint256 withdrawAmount = value < maxTokens ? value : maxTokens;
        withdrawnTokens[msg.sender] = SafeMath.add(withdrawnTokens[msg.sender], withdrawAmount);
        token.transfer(to, withdrawAmount);
        LogWithdraw(to, value);
    }

     
     
    function calcMaxWithdraw()
        public
        constant
        returns (uint256)
    {
        uint256 maxTokens = 0;
        Disbursement[] storage temp = disbursements[msg.sender];
        for (uint256 i = 0; i < temp.length; i++) {
            if (block.timestamp > temp[i].timestamp) {
                maxTokens = SafeMath.add(maxTokens, temp[i].tokens);
            }
        }
        maxTokens = SafeMath.sub(maxTokens, withdrawnTokens[msg.sender]);
        return maxTokens;
    }
}

library StateMachineLib {

    struct Stage {
         
        bytes32 nextId;

         
        mapping(bytes4 => bool) allowedFunctions;
    }

    struct State {
         
        bytes32 currentStageId;

         
        function(bytes32) internal onTransition;

         
        mapping(bytes32 => bool) validStage;

         
        mapping(bytes32 => Stage) stages;
    }

     
     
    function setInitialStage(State storage self, bytes32 stageId) internal {
        self.validStage[stageId] = true;
        self.currentStageId = stageId;
    }

     
     
     
    function createTransition(State storage self, bytes32 fromId, bytes32 toId) internal {
        require(self.validStage[fromId]);

        Stage storage from = self.stages[fromId];

         
        if (from.nextId != 0) {
            self.validStage[from.nextId] = false;
            delete self.stages[from.nextId];
        }

        from.nextId = toId;
        self.validStage[toId] = true;
    }

     
    function goToNextStage(State storage self) internal {
        Stage storage current = self.stages[self.currentStageId];

        require(self.validStage[current.nextId]);

        self.currentStageId = current.nextId;

        self.onTransition(current.nextId);
    }

     
     
     
    function checkAllowedFunction(State storage self, bytes4 selector) internal constant returns(bool) {
        return self.stages[self.currentStageId].allowedFunctions[selector];
    }

     
     
     
    function allowFunction(State storage self, bytes32 stageId, bytes4 selector) internal {
        require(self.validStage[stageId]);
        self.stages[stageId].allowedFunctions[selector] = true;
    }


}

contract StateMachine {
    using StateMachineLib for StateMachineLib.State;

    event LogTransition(bytes32 indexed stageId, uint256 blockNumber);

    StateMachineLib.State internal state;

     
    modifier checkAllowed {
        conditionalTransitions();
        require(state.checkAllowedFunction(msg.sig));
        _;
    }

    function StateMachine() public {
         
        state.onTransition = onTransition;
    }

     
     
    function getCurrentStageId() public view returns(bytes32) {
        return state.currentStageId;
    }

     
    function conditionalTransitions() public {

        bytes32 nextId = state.stages[state.currentStageId].nextId;

        while (state.validStage[nextId]) {
            StateMachineLib.Stage storage next = state.stages[nextId];
             
            if (startConditions(nextId)) {
                state.goToNextStage();
                nextId = next.nextId;
            } else {
                break;
            }
        }
    }

     
     
    function startConditions(bytes32) internal constant returns(bool) {
        return false;
    }

     
    function onTransition(bytes32 stageId) internal {
        LogTransition(stageId, block.number);
    }


}

contract TimedStateMachine is StateMachine {

    event LogSetStageStartTime(bytes32 indexed stageId, uint256 startTime);

     
    mapping(bytes32 => uint256) internal startTime;

     
    function startConditions(bytes32 stageId) internal constant returns(bool) {
         
        uint256 start = startTime[stageId];
         
        return start != 0 && block.timestamp > start;
    }

     
     
     
    function setStageStartTime(bytes32 stageId, uint256 timestamp) internal {
        require(state.validStage[stageId]);
        require(timestamp > block.timestamp);

        startTime[stageId] = timestamp;
        LogSetStageStartTime(stageId, timestamp);
    }

     
     
    function getStageStartTime(bytes32 stageId) public view returns(uint256) {
        return startTime[stageId];
    }
}

contract Sale is Ownable, TimedStateMachine {
    using SafeMath for uint256;

    event LogContribution(address indexed contributor, uint256 amountSent, uint256 excessRefunded);
    event LogTokenAllocation(address indexed contributor, uint256 contribution, uint256 tokens);
    event LogDisbursement(address indexed beneficiary, uint256 tokens);

     
    bytes32 public constant SETUP = "setup";
    bytes32 public constant SETUP_DONE = "setupDone";
    bytes32 public constant SALE_IN_PROGRESS = "saleInProgress";
    bytes32 public constant SALE_ENDED = "saleEnded";

    mapping(address => uint256) public contributions;

    uint256 public weiContributed = 0;
    uint256 public contributionCap;

     
    address public wallet;

    MintableToken public token;

    DisbursementHandler public disbursementHandler;

    function Sale(
        address _wallet, 
        uint256 _contributionCap
    ) 
        public 
    {
        require(_wallet != 0);
        require(_contributionCap != 0);

        wallet = _wallet;

        token = createTokenContract();
        disbursementHandler = new DisbursementHandler(token);

        contributionCap = _contributionCap;

        setupStages();
    }

    function() external payable {
        contribute();
    }

     
     
    function setSaleStartTime(uint256 timestamp) 
        external 
        onlyOwner 
        checkAllowed
    {
         
        setStageStartTime(SALE_IN_PROGRESS, timestamp);
    }

     
     
    function setSaleEndTime(uint256 timestamp) 
        external 
        onlyOwner 
        checkAllowed
    {
        require(getStageStartTime(SALE_IN_PROGRESS) < timestamp);
        setStageStartTime(SALE_ENDED, timestamp);
    }

     
    function setupDone() 
        public 
        onlyOwner 
        checkAllowed
    {
        uint256 _startTime = getStageStartTime(SALE_IN_PROGRESS);
        uint256 _endTime = getStageStartTime(SALE_ENDED);
        require(block.timestamp < _startTime);
        require(_startTime < _endTime);

        state.goToNextStage();
    }

     
    function contribute() 
        public 
        payable
        checkAllowed 
    {
        require(msg.value > 0);   

        uint256 contributionLimit = getContributionLimit(msg.sender);
        require(contributionLimit > 0);

         
        uint256 totalContribution = contributions[msg.sender].add(msg.value);
        uint256 excess = 0;

         
        if (weiContributed.add(msg.value) > contributionCap) {
             
            excess = weiContributed.add(msg.value).sub(contributionCap);
            totalContribution = totalContribution.sub(excess);
        }

         
        if (totalContribution > contributionLimit) {
            excess = excess.add(totalContribution).sub(contributionLimit);
            contributions[msg.sender] = contributionLimit;
        } else {
            contributions[msg.sender] = totalContribution;
        }

         
         
        require(excess <= msg.value);

        weiContributed = weiContributed.add(msg.value).sub(excess);

        if (excess > 0) {
            msg.sender.transfer(excess);
        }

        wallet.transfer(this.balance);

        assert(contributions[msg.sender] <= contributionLimit);
        LogContribution(msg.sender, msg.value, excess);
    }

     
     
     
     
    function distributeTimelockedTokens(
        address beneficiary,
        uint256 tokenAmount,
        uint256 timestamp
    ) 
        public
        onlyOwner
        checkAllowed
    { 
        disbursementHandler.setupDisbursement(
            beneficiary,
            tokenAmount,
            timestamp
        );
        token.mint(disbursementHandler, tokenAmount);
        LogDisbursement(beneficiary, tokenAmount);
    }
    
    function setupStages() internal {
         
        state.setInitialStage(SETUP);
        state.createTransition(SETUP, SETUP_DONE);
        state.createTransition(SETUP_DONE, SALE_IN_PROGRESS);
        state.createTransition(SALE_IN_PROGRESS, SALE_ENDED);

        state.allowFunction(SETUP, this.distributeTimelockedTokens.selector);
        state.allowFunction(SETUP, this.setSaleStartTime.selector);
        state.allowFunction(SETUP, this.setSaleEndTime.selector);
        state.allowFunction(SETUP, this.setupDone.selector);
        state.allowFunction(SALE_IN_PROGRESS, this.contribute.selector);
        state.allowFunction(SALE_IN_PROGRESS, 0);  
    }

     
    function createTokenContract() internal returns (MintableToken);
    function getContributionLimit(address userAddress) public view returns (uint256);

     
    function startConditions(bytes32 stageId) internal constant returns (bool) {
         
        if (stageId == SALE_ENDED && contributionCap <= weiContributed) {
            return true;
        }
        return super.startConditions(stageId);
    }

     
    function onTransition(bytes32 stageId) internal {
        if (stageId == SALE_ENDED) { 
            onSaleEnded(); 
        }
        super.onTransition(stageId);
    }

     
    function onSaleEnded() internal {}
}

contract ERC223ReceivingContract {

     
     
     
     
    function tokenFallback(address _from, uint _value, bytes _data) public;

}

contract ERC223Basic is ERC20Basic {

     
    function transfer(address _to, uint _value, bytes _data) public returns (bool);

     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _value, bytes _data);
}


contract ERC223BasicToken is ERC223Basic, BasicToken {

     
    function transfer(address _to, uint _value, bytes _data) public returns (bool) {
         
         
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        require(super.transfer(_to, _value));

        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

       
    function transfer(address _to, uint256 _value) public returns (bool) {
        bytes memory empty;
        require(transfer(_to, _value, empty));
        return true;
    }

}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

contract DetherToken is DetailedERC20, MintableToken, ERC223BasicToken {
    string constant NAME = "Dether";
    string constant SYMBOL = "DTH";
    uint8 constant DECIMALS = 18;

     
    function DetherToken()
        DetailedERC20(NAME, SYMBOL, DECIMALS)
        public
    {}
}


contract DetherSale is Sale, Whitelistable {

    uint256 public constant PRESALE_WEI = 3956 ether * 1.15 + 490 ether;  

    uint256 public constant DECIMALS_MULTIPLIER = 1000000000000000000;
    uint256 public constant MAX_DTH = 100000000 * DECIMALS_MULTIPLIER;

     
     
    uint256 public constant WEI_CAP = 10554 ether;

     
    uint256 public constant WHITELISTING_DURATION = 2 days;

     
    uint256 public constant WHITELISTING_MAX_CONTRIBUTION = 5 ether;

     
    uint256 public constant PUBLIC_MAX_CONTRIBUTION = 2**256 - 1;

     
    uint256 public constant MIN_CONTRIBUTION = 0.1 ether;

     
    uint256 public weiPerDTH;
     
    bool private lockedTokensDistributed;
     
    bool private presaleAllocated;

     
    address public presaleAddress;

    uint256 private weiAllocated;

     
    mapping(address => uint256) public presaleMaxContribution;

    function DetherSale(address _wallet, address _presaleAddress) Sale(_wallet, WEI_CAP) public {
      presaleAddress = _presaleAddress;
    }

     
    function performInitialAllocations() external onlyOwner checkAllowed {
        require(lockedTokensDistributed == false);
        lockedTokensDistributed = true;

         
        distributeTimelockedTokens(0x4dc976cEd66d1B87C099B338E1F1388AE657377d, MAX_DTH.mul(3).div(100), now + 6 * 4 weeks);

         
        distributeTimelockedTokens(0xfEF675cC3068Ee798f2312e82B12c841157A0A0E, MAX_DTH.mul(3).div(100), now + 1 weeks);

         
        distributeTimelockedTokens(0x8F38C4ddFE09Bd22545262FE160cf441D43d2489, MAX_DTH.mul(25).div(1000), now + 6 * 4 weeks);

        distributeTimelockedTokens(0x87a4eb1c9fdef835DC9197FAff3E09b8007ADe5b, MAX_DTH.mul(25).div(1000), now + 6 * 4 weeks);

         
        distributeTimelockedTokens(0x6f63D5DF2D8644851cBb5F8607C845704C008284, MAX_DTH.mul(11).div(100), now + 1 weeks);

         
        distributeTimelockedTokens(0x24c14796f401D77fc401F9c2FA1dF42A136EbF83, MAX_DTH.mul(3).div(100), now + 6 * 4 weeks);
        distributeTimelockedTokens(0x24c14796f401D77fc401F9c2FA1dF42A136EbF83, MAX_DTH.mul(3).div(100), now + 2 * 6 * 4 weeks);
        distributeTimelockedTokens(0x24c14796f401D77fc401F9c2FA1dF42A136EbF83, MAX_DTH.mul(3).div(100), now + 3 * 6 * 4 weeks);
        distributeTimelockedTokens(0x24c14796f401D77fc401F9c2FA1dF42A136EbF83, MAX_DTH.mul(3).div(100), now + 4 * 6 * 4 weeks);
        distributeTimelockedTokens(0x24c14796f401D77fc401F9c2FA1dF42A136EbF83, MAX_DTH.mul(3).div(100), now + 5 * 6 * 4 weeks);
        distributeTimelockedTokens(0x24c14796f401D77fc401F9c2FA1dF42A136EbF83, MAX_DTH.mul(3).div(100), now + 6 * 6 * 4 weeks);
    }

     
    function registerPresaleContributor(address userAddress, uint256 maxContribution)
        external
        onlyOwner
    {
         
        require(maxContribution <= WHITELISTING_MAX_CONTRIBUTION);

         
        registerUser(userAddress);

         
        presaleMaxContribution[userAddress] = maxContribution;
    }

     
     
    function allocateTokens(address contributor)
        external
        checkAllowed
    {
        require(presaleAllocated);
        require(contributions[contributor] != 0);

         
        weiAllocated = weiAllocated.add(contributions[contributor]);

         
        token.mint(contributor, contributions[contributor].mul(DECIMALS_MULTIPLIER).div(weiPerDTH));

         
        contributions[contributor] = 0;

         
         
        if (weiAllocated == weiContributed) {
          uint256 remaining = MAX_DTH.sub(token.totalSupply());
          token.mint(owner, remaining);
          token.finishMinting();
        }
    }

     
    function presaleAllocateTokens()
        external
        checkAllowed
    {
        require(!presaleAllocated);
        presaleAllocated = true;

         
        token.mint(presaleAddress, PRESALE_WEI.mul(DECIMALS_MULTIPLIER).div(weiPerDTH));
    }

    function contribute()
        public
        payable
        checkAllowed
    {
        require(msg.value >= MIN_CONTRIBUTION);

        super.contribute();
    }

     
    function getContributionLimit(address userAddress) public view returns (uint256) {
        uint256 saleStartTime = getStageStartTime(SALE_IN_PROGRESS);

         
        if (!whitelisted[userAddress] || block.timestamp < saleStartTime) {
            return 0;
        }

         
        bool whitelistingPeriod = block.timestamp - saleStartTime <= WHITELISTING_DURATION;

         
         
        return whitelistingPeriod ? presaleMaxContribution[userAddress] : PUBLIC_MAX_CONTRIBUTION;
    }

    function createTokenContract() internal returns(MintableToken) {
        return new DetherToken();
    }

    function setupStages() internal {
        super.setupStages();
        state.allowFunction(SETUP, this.performInitialAllocations.selector);
        state.allowFunction(SALE_ENDED, this.allocateTokens.selector);
        state.allowFunction(SALE_ENDED, this.presaleAllocateTokens.selector);
    }

     
    function calculatePrice() public view returns(uint256) {
        return weiContributed.add(PRESALE_WEI).div(60000000).add(1);
    }

    function onSaleEnded() internal {
         
        weiPerDTH = calculatePrice();
    }
}