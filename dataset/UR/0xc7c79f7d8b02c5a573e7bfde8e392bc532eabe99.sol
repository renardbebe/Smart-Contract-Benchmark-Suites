 

pragma solidity ^0.4.23;


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
    );
}


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
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
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
  
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}



contract DefaultToken is BasicToken {

  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}



 
contract IWingsController {
  uint256 public ethRewardPart;
  uint256 public tokenRewardPart;

  function fitCollectedValueIntoRange(uint256 _totalCollected) public view returns (uint256);
}


contract HasManager {
  address public manager;

  modifier onlyManager {
    require(msg.sender == manager);
    _;
  }

  function transferManager(address _newManager) public onlyManager() {
    require(_newManager != address(0));
    manager = _newManager;
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


 
contract ICrowdsaleProcessor is Ownable, HasManager {
  modifier whenCrowdsaleAlive() {
    require(isActive());
    _;
  }

  modifier whenCrowdsaleFailed() {
    require(isFailed());
    _;
  }

  modifier whenCrowdsaleSuccessful() {
    require(isSuccessful());
    _;
  }

  modifier hasntStopped() {
    require(!stopped);
    _;
  }

  modifier hasBeenStopped() {
    require(stopped);
    _;
  }

  modifier hasntStarted() {
    require(!started);
    _;
  }

  modifier hasBeenStarted() {
    require(started);
    _;
  }

   
  uint256 constant public MIN_HARD_CAP = 1 ether;

   
  uint256 constant public MIN_CROWDSALE_TIME = 3 days;

   
  uint256 constant public MAX_CROWDSALE_TIME = 50 days;

   
  bool public started;

   
  bool public stopped;

   
  uint256 public totalCollected;

   
  uint256 public totalCollectedETH;

   
  uint256 public totalSold;

   
  uint256 public minimalGoal;

   
  uint256 public hardCap;

   
   
  uint256 public duration;

   
  uint256 public startTimestamp;

   
  uint256 public endTimestamp;

   
  function deposit() public payable {}

   
  function getToken() public returns(address);

   
  function mintETHRewards(address _contract, uint256 _amount) public onlyManager();

   
  function mintTokenRewards(address _contract, uint256 _amount) public onlyManager();

   
  function releaseTokens() public onlyManager() hasntStopped() whenCrowdsaleSuccessful();

   
   
  function stop() public onlyManager() hasntStopped();

   
  function start(uint256 _startTimestamp, uint256 _endTimestamp, address _fundingAddress)
    public onlyManager() hasntStarted() hasntStopped();

   
  function isFailed() public constant returns (bool);

   
  function isActive() public constant returns (bool);

   
  function isSuccessful() public constant returns (bool);
}


 
contract BasicCrowdsale is ICrowdsaleProcessor {
  event CROWDSALE_START(uint256 startTimestamp, uint256 endTimestamp, address fundingAddress);

   
  address public fundingAddress;

   
  function BasicCrowdsale(
    address _owner,
    address _manager
  )
    public
  {
    owner = _owner;
    manager = _manager;
  }

   
   
   
   
  function mintETHRewards(
    address _contract,   
    uint256 _amount      
  )
    public
    onlyManager()  
  {
    require(_contract.call.value(_amount)());
  }

   
  function stop() public onlyManager() hasntStopped()  {
     
    if (started) {
      require(!isFailed());
      require(!isSuccessful());
    }
    stopped = true;
  }

   
   
  function start(
    uint256 _startTimestamp,
    uint256 _endTimestamp,
    address _fundingAddress
  )
    public
    onlyManager()    
    hasntStarted()   
    hasntStopped()   
  {
    require(_fundingAddress != address(0));

     
    require(_startTimestamp >= block.timestamp);

     
    require(_endTimestamp > _startTimestamp);
    duration = _endTimestamp - _startTimestamp;

     
    require(duration >= MIN_CROWDSALE_TIME && duration <= MAX_CROWDSALE_TIME);

    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
    fundingAddress = _fundingAddress;

     
    started = true;

    CROWDSALE_START(_startTimestamp, _endTimestamp, _fundingAddress);
  }

   
  function isFailed()
    public
    constant
    returns(bool)
  {
    return (
       
      started &&

       
      block.timestamp >= endTimestamp &&

       
      totalCollected < minimalGoal
    );
  }

   
  function isActive()
    public
    constant
    returns(bool)
  {
    return (
       
      started &&

       
      totalCollected < hardCap &&

       
      block.timestamp >= startTimestamp &&
      block.timestamp < endTimestamp
    );
  }

   
  function isSuccessful()
    public
    constant
    returns(bool)
  {
    return (
       
      totalCollected >= hardCap ||

       
      (block.timestamp >= endTimestamp && totalCollected >= minimalGoal)
    );
  }
}


 
contract Bridge is BasicCrowdsale {

  using SafeMath for uint256;

  event CUSTOM_CROWDSALE_TOKEN_ADDED(address token, uint8 decimals);
  event CUSTOM_CROWDSALE_FINISH();

   
  DefaultToken token;

   
  bool completed;

   
  constructor(
     
     
     
  ) public
    BasicCrowdsale(msg.sender, msg.sender)  
  {
    minimalGoal = 1;
    hardCap = 1;
    token = DefaultToken(0x9998Db897783603c9344ED2678AB1B5D73d0f7C3);
  }

   

   
  function getToken()
    public
    returns (address)
  {
    return address(token);
  }

   
   
  function mintTokenRewards(
    address _contract,
    uint256 _amount     
  )
    public
    onlyManager()
  {
     
    token.transfer(_contract, _amount);
  }

  function releaseTokens() public onlyManager() hasntStopped() whenCrowdsaleSuccessful() {
  }

   

   
  function() public payable {
  }

   
  function notifySale(uint256 _amount, uint256 _ethAmount, uint256 _tokensAmount)
    public
    hasBeenStarted()
    hasntStopped()
    whenCrowdsaleAlive()
    onlyOwner()
  {
    totalCollected = totalCollected.add(_amount);
    totalCollectedETH = totalCollectedETH.add(_ethAmount);
    totalSold = totalSold.add(_tokensAmount);
  }

   
   
  function start(
    uint256 _startTimestamp,
    uint256 _endTimestamp,
    address _fundingAddress
  )
    public
    hasntStarted()
    hasntStopped()
    onlyManager()
  {
    started = true;

    emit CROWDSALE_START(_startTimestamp, _endTimestamp, _fundingAddress);
  }

   
  function finish()
    public
    hasntStopped()
    hasBeenStarted()
    whenCrowdsaleAlive()
    onlyOwner()
  {
    completed = true;

    emit CUSTOM_CROWDSALE_FINISH();
  }

  function isFailed()
    public
    view
    returns (bool)
  {
    return (false);
  }

  function isActive()
    public
    view
    returns (bool)
  {
    return (started && !completed);
  }

  function isSuccessful()
    public
    view
    returns (bool)
  {
    return (completed);
  }

   
  function calculateRewards() public view returns (uint256, uint256) {
    uint256 tokenRewardPart = IWingsController(manager).tokenRewardPart();
    uint256 ethRewardPart = IWingsController(manager).ethRewardPart();
    uint256 ethReward;
    bool hasEthReward = (ethRewardPart != 0);

    uint256 tokenReward = totalSold.mul(tokenRewardPart) / 1000000;

    if (totalCollectedETH != 0) {
      totalCollected = totalCollectedETH;
    }

    totalCollected = IWingsController(manager).fitCollectedValueIntoRange(totalCollected);

    if (hasEthReward) {
      ethReward = totalCollected.mul(ethRewardPart) / 1000000;
    }

    return (ethReward, tokenReward);
  }

   
  function changeToken(address _newToken) public onlyOwner() {
    token = DefaultToken(_newToken);

    emit CUSTOM_CROWDSALE_TOKEN_ADDED(address(token), uint8(token.decimals()));
  }

   
  function withdraw() public onlyOwner() {
    uint256 ethBalance = address(this).balance;
    uint256 tokenBalance = token.balanceOf(address(this));

    if (ethBalance > 0) {
      require(msg.sender.send(ethBalance));
    }

    if (tokenBalance > 0) {
      require(token.transfer(msg.sender, tokenBalance));
    }
  }
}