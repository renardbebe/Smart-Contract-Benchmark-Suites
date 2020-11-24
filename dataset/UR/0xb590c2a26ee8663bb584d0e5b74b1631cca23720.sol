 

pragma solidity ^0.4.23;


 
 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    require(c / a == b, "mul failed");
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "sub fail");
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "add fail");
    return c;
  }
}


 
 
contract iERC20 {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}









 
 
 
 
contract iNovaStaking {

  function balanceOf(address _owner) public view returns (uint256);
}



 
 
 
 
contract iNovaGame {
  function isAdminForGame(uint _game, address account) external view returns(bool);

   
  uint[] public games;
}







 
 
 
 
contract NovaMasterAccess {
  using SafeMath for uint256;

  event OwnershipTransferred(address previousOwner, address newOwner);
  event PromotedGame(uint game, bool isPromoted, string json);
  event SuppressedGame(uint game, bool isSuppressed);

   
  iERC20 public nvtContract;

   
  iNovaGame public gameContract;

   
  address public owner;

   
  address public recoveryAddress;


   
  constructor() 
    internal 
  {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier onlyRecovery() {
    require(msg.sender == recoveryAddress);
    _;
  }

   
   
   
  function setOwner(address _newOwner) 
    external 
    onlyRecovery 
  {
    require(_newOwner != address(0));
    require(_newOwner != recoveryAddress);

    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  }

   
   
   
  function setRecovery(address _newRecovery) 
    external 
    onlyOwner 
  {
    require(_newRecovery != address(0));
    require(_newRecovery != owner);

    recoveryAddress = _newRecovery;
  }

   
   
   
   
  function setPromotedGame(uint _game, bool _isPromoted, string _json)
    external
    onlyOwner
  {
    uint gameId = gameContract.games(_game);
    require(gameId == _game, "gameIds must match");
    emit PromotedGame(_game, _isPromoted, _isPromoted ? _json : "");
  }

   
   
   
   
   
  function setSuppressedGame(uint _game, bool _isSuppressed)
    external
    onlyOwner
  {
    uint gameId = gameContract.games(_game);
    require(gameId == _game, "gameIds must match");
    emit SuppressedGame(_game, _isSuppressed);
  }
}



 
 
 
 
 
contract NovaStakingBase is NovaMasterAccess, iNovaStaking {
  using SafeMath for uint256;

  uint public constant WEEK_ZERO_START = 1538352000;  
  uint public constant SECONDS_PER_WEEK = 604800;

   
  mapping(address => uint) public balances;
  
   
  mapping(uint => uint) public storedNVTbyWeek;

   
  modifier onlyGameAdmin(uint _game) {
    require(gameContract.isAdminForGame(_game, msg.sender));
    _;
  }

   
   
  function linkContracts(address _gameContract)
    external
    onlyOwner
  {
    gameContract = iNovaGame(_gameContract);
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Balance(address account, uint256 value);
  event StoredNVT(uint week, uint stored);

   
   
   
  function balanceOf(address _owner) 
    public
    view
  returns (uint256) {
    return balances[_owner];
  }

   
   
   
   
  function _transfer(address _from, address _to, uint _value) 
    internal
  {
    require(_from != _to, "can't transfer to yourself");
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    emit Balance(_from, balances[_from]);
    emit Balance(_to, balances[_to]);
  }

   
   
  function getCurrentWeek()
    external
    view
  returns(uint) {
    return _getCurrentWeek();
  }

   
   
  function _getCurrentWeek()
    internal
    view
  returns(uint) {
    return (now - WEEK_ZERO_START) / SECONDS_PER_WEEK;
  }
}


 
 
 
 
contract NovaStakeManagement is NovaStakingBase {

   
  event Payout(address indexed staker, uint amount, uint endWeek);

   
  event ChangeStake(uint week, uint indexed game, address indexed staker, uint prevStake, uint newStake,
    uint accountStake, uint gameStake, uint totalStake);

   
   
   
  mapping(uint => mapping(address => uint)) public gameAccountStaked;
   
  mapping(address => uint) public accountStaked;
   
  mapping(uint => uint) public gameStaked;
   
  uint public totalStaked;

   
   
   
   
   
   
  mapping(uint => mapping(uint => mapping(address => uint))) public weekGameAccountStakes;
   
  mapping(uint => mapping(address => uint)) public weekAccountStakes;
   
  mapping(uint => mapping(uint => uint)) public weekGameStakes;
   
  mapping(uint => uint) public weekTotalStakes;

   
  mapping(address => uint) public lastPayoutWeekByAccount;
   
  mapping(uint => uint) public lastPayoutWeekByGame;

   
   
  mapping(uint => uint) public weeklyIncome;

  constructor()
    public
  {
    weekTotalStakes[_getCurrentWeek() - 1] = 1;
  }


   
   
   
   
  function setStake(uint _game, uint _newStake)
    public
  {
    uint currentStake = gameAccountStaked[_game][msg.sender];
    if (currentStake < _newStake) {
      increaseStake(_game, _newStake - currentStake);
    } else 
    if (currentStake > _newStake) {
      decreaseStake(_game, currentStake - _newStake);

    }
  }

   
   
   
   
  function increaseStake(uint _game, uint _increase)
    public
  returns(uint newStake) {
    require(_increase > 0, "Must be a non-zero change");
     
    uint newBalance = balances[msg.sender].sub(_increase);
    balances[msg.sender] = newBalance;
    emit Balance(msg.sender, newBalance);

    uint prevStake = gameAccountStaked[_game][msg.sender];
    newStake = prevStake.add(_increase);
    uint gameStake = gameStaked[_game].add(_increase);
    uint accountStake = accountStaked[msg.sender].add(_increase);
    uint totalStake = totalStaked.add(_increase);

    _storeStakes(_game, msg.sender, prevStake, newStake, gameStake, accountStake, totalStake);
  }

   
   
   
  function decreaseStake(uint _game, uint _decrease)
    public
  returns(uint newStake) {
    require(_decrease > 0, "Must be a non-zero change");
    uint newBalance = balances[msg.sender].add(_decrease);
    balances[msg.sender] = newBalance;
    emit Balance(msg.sender, newBalance);

    uint prevStake = gameAccountStaked[_game][msg.sender];
    newStake = prevStake.sub(_decrease);
    uint gameStake = gameStaked[_game].sub(_decrease);
    uint accountStake = accountStaked[msg.sender].sub(_decrease);
    uint totalStake = totalStaked.sub(_decrease);

    _storeStakes(_game, msg.sender, prevStake, newStake, gameStake, accountStake, totalStake);
  }

   
   
   
  function collectPayout(uint _numberOfWeeks) 
    public
  returns(uint _payout) {
    uint startWeek = lastPayoutWeekByAccount[msg.sender];
    require(startWeek > 0, "must be a valid start week");
    uint endWeek = _getEndWeek(startWeek, _numberOfWeeks);
    require(startWeek < endWeek, "must be at least one week to pay out");
    
    uint lastWeekStake;
    for (uint i = startWeek; i < endWeek; i++) {
       
      uint weeklyStake = weekAccountStakes[i][msg.sender] == 0 
          ? lastWeekStake 
          : weekAccountStakes[i][msg.sender];
      lastWeekStake = weeklyStake;

      uint weekStake = _getWeekTotalStake(i);
      uint storedNVT = storedNVTbyWeek[i];
      uint weeklyPayout = storedNVT > 1 && weeklyStake > 1 && weekStake > 1 
        ? weeklyStake.mul(storedNVT) / weekStake / 2
        : 0;
      _payout = _payout.add(weeklyPayout);

    }
     
     
     
     
    if(weekAccountStakes[endWeek][msg.sender] == 0) {
      weekAccountStakes[endWeek][msg.sender] = lastWeekStake;
    }
     
    lastPayoutWeekByAccount[msg.sender] = endWeek;

    _transfer(address(this), msg.sender, _payout);
    emit Payout(msg.sender, _payout, endWeek);
  }

   
   
   
   
  function collectGamePayout(uint _game, uint _numberOfWeeks)
    external
    onlyGameAdmin(_game)
  returns(uint _payout) {
    uint week = lastPayoutWeekByGame[_game];
    require(week > 0, "must be a valid start week");
    uint endWeek = _getEndWeek(week, _numberOfWeeks);
    require(week < endWeek, "must be at least one week to pay out");

    uint lastWeekStake;
    for (week; week < endWeek; week++) {
       
      uint weeklyStake = weekGameStakes[week][_game] == 0 
          ? lastWeekStake 
          : weekGameStakes[week][_game];
      lastWeekStake = weeklyStake;

      uint weekStake = _getWeekTotalStake(week);
      uint storedNVT = storedNVTbyWeek[week];
      uint weeklyPayout = storedNVT > 1 && weeklyStake > 1 && weekStake > 1 
        ? weeklyStake.mul(storedNVT) / weekStake / 2
        : 0;
      _payout = _payout.add(weeklyPayout);
    }
     
     
     
     
    if(weekGameStakes[endWeek][_game] == 0) {
      weekGameStakes[endWeek][_game] = lastWeekStake;
    }
     
    lastPayoutWeekByGame[_game] = endWeek;

    _transfer(address(this), address(_game), _payout);
    emit Payout(address(_game), _payout, endWeek);
  }

   
   
   
   
   
   
   
   
  function _storeStakes(uint _game, address _staker, uint _prevStake, uint _newStake,
    uint _gameStake, uint _accountStake, uint _totalStake)
    internal
  {
    uint _currentWeek = _getCurrentWeek();

    gameAccountStaked[_game][msg.sender] = _newStake;
    gameStaked[_game] = _gameStake;
    accountStaked[msg.sender] = _accountStake;
    totalStaked = _totalStake;
    
     
     
    weekGameAccountStakes[_currentWeek][_game][_staker] = _newStake > 0 ? _newStake : 1;
    weekAccountStakes[_currentWeek][_staker] = _accountStake > 0 ? _accountStake : 1;
    weekGameStakes[_currentWeek][_game] = _gameStake > 0 ? _gameStake : 1;
    weekTotalStakes[_currentWeek] = _totalStake > 0 ? _totalStake : 1;

     
     
    if(lastPayoutWeekByAccount[_staker] == 0) {
      lastPayoutWeekByAccount[_staker] = _currentWeek - 1;
      if (lastPayoutWeekByGame[_game] == 0) {
        lastPayoutWeekByGame[_game] = _currentWeek - 1;
      }
    }

    emit ChangeStake(_currentWeek, _game, _staker, _prevStake, _newStake, 
      _accountStake, _gameStake, _totalStake);
  }

   
   
   
   
   
  function _getWeekTotalStake(uint _week)
    internal
  returns(uint _stake) {
    _stake = weekTotalStakes[_week];
    if(_stake == 0) {
      uint backWeek = _week;
      while(_stake == 0) {
        backWeek--;
        _stake = weekTotalStakes[backWeek];
      }
      weekTotalStakes[_week] = _stake;
    }
  }

   
   
   
   
   
  function _getEndWeek(uint _startWeek, uint _numberOfWeeks)
    internal
    view
  returns(uint endWeek) {
    uint _currentWeek = _getCurrentWeek();
    require(_startWeek < _currentWeek, "must get at least one week");
    endWeek = _numberOfWeeks == 0 ? _currentWeek : _startWeek + _numberOfWeeks;
    require(endWeek <= _currentWeek, "can't get more than the current week");
  }
}



 
 
 
 
contract NovaStaking is NovaStakeManagement {

  event Deposit(address account, uint256 amount, uint256 balance);
  event Withdrawal(address account, uint256 amount, uint256 balance);

   
   
   
  constructor(iERC20 _nvtContract)
    public
  {
    nvtContract = _nvtContract;
  }

   
   
   
   
   
   
  function receiveApproval(address _sender, uint _amount, address _contract, bytes _data)
    public
  {
    require(_data.length == 0, "you must pass no data");
    require(_contract == address(nvtContract), "sending from a non-NVT contract is not allowed");

     
    uint newBalance = balances[_sender].add(_amount);
    balances[_sender] = newBalance;

    emit Balance(_sender, newBalance);
    emit Deposit(_sender, _amount, newBalance);

     
    require(nvtContract.transferFrom(_sender, address(this), _amount), "must successfully transfer");
  }

  function receiveNVT(uint _amount, uint _week) 
    external
  {
    require(_week >= _getCurrentWeek(), "Current Week must be equal or greater");
    uint totalDonation = weeklyIncome[_week].add(_amount);
    weeklyIncome[_week] = totalDonation;

    uint stored = storedNVTbyWeek[_week].add(_amount);
    storedNVTbyWeek[_week] = stored;
    emit StoredNVT(_week, stored);
     
    _transfer(msg.sender, address(this), _amount);
  }

   
   
   
   
  function withdraw(uint amount)
    external
  {
    uint withdrawalAmount = amount > 0 ? amount : balances[msg.sender];
    require(withdrawalAmount > 0, "Can't withdraw - zero balance");
    uint newBalance = balances[msg.sender].sub(withdrawalAmount);
    balances[msg.sender] = newBalance;
    emit Withdrawal(msg.sender, withdrawalAmount, newBalance);
    emit Balance(msg.sender, newBalance);
    nvtContract.transfer(msg.sender, withdrawalAmount);
  }

   
   
   
  function addNVTtoGame(uint _game, uint _tokensToToAdd)
    external
    onlyGameAdmin(_game)
  {
     
    _transfer(msg.sender, address(_game), _tokensToToAdd);
  }

   
   
   
  function withdrawNVTfromGame(uint _game, uint _tokensToWithdraw)
    external
    onlyGameAdmin(_game)
  {
     
    _transfer(address(_game), msg.sender, _tokensToWithdraw);
  }
}