 

 

pragma solidity ^0.4.24;

 

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

 

library ZethrTierLibrary {
  uint constant internal magnitude = 2 ** 64;

   
   
  function getTier(uint divRate) internal pure returns (uint8) {

     
     
    uint actualDiv = divRate / magnitude;
    if (actualDiv >= 30) {
      return 6;
    } else if (actualDiv >= 25) {
      return 5;
    } else if (actualDiv >= 20) {
      return 4;
    } else if (actualDiv >= 15) {
      return 3;
    } else if (actualDiv >= 10) {
      return 2;
    } else if (actualDiv >= 5) {
      return 1;
    } else if (actualDiv >= 2) {
      return 0;
    } else {
       
      revert();
    }
  }

  function getDivRate(uint _tier)
  internal pure
  returns (uint8)
  {
    if (_tier == 0) {
      return 2;
    } else if (_tier == 1) {
      return 5;
    } else if (_tier == 2) {
      return 10;
    } else if (_tier == 3) {
      return 15;
    } else if (_tier == 4) {
      return 20;
    } else if (_tier == 5) {
      return 25;
    } else if (_tier == 6) {
      return 33;
    } else {
      revert();
    }
  }
}

 

contract ERC223Receiving {
  function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

 

  
contract ZethrMultiSigWallet is ERC223Receiving {
  using SafeMath for uint;

   

  event Confirmation(address indexed sender, uint indexed transactionId);
  event Revocation(address indexed sender, uint indexed transactionId);
  event Submission(uint indexed transactionId);
  event Execution(uint indexed transactionId);
  event ExecutionFailure(uint indexed transactionId);
  event Deposit(address indexed sender, uint value);
  event OwnerAddition(address indexed owner);
  event OwnerRemoval(address indexed owner);
  event WhiteListAddition(address indexed contractAddress);
  event WhiteListRemoval(address indexed contractAddress);
  event RequirementChange(uint required);
  event BankrollInvest(uint amountReceived);

   

  mapping (uint => Transaction) public transactions;
  mapping (uint => mapping (address => bool)) public confirmations;
  mapping (address => bool) public isOwner;
  address[] public owners;
  uint public required;
  uint public transactionCount;
  bool internal reEntered = false;
  uint constant public MAX_OWNER_COUNT = 15;

   

  struct Transaction {
    address destination;
    uint value;
    bytes data;
    bool executed;
  }

  struct TKN {
    address sender;
    uint value;
  }

   

  modifier onlyWallet() {
    if (msg.sender != address(this))
      revert();
    _;
  }

  modifier isAnOwner() {
    address caller = msg.sender;
    if (isOwner[caller])
      _;
    else
      revert();
  }

  modifier ownerDoesNotExist(address owner) {
    if (isOwner[owner]) 
      revert();
      _;
  }

  modifier ownerExists(address owner) {
    if (!isOwner[owner])
      revert();
    _;
  }

  modifier transactionExists(uint transactionId) {
    if (transactions[transactionId].destination == 0)
      revert();
    _;
  }

  modifier confirmed(uint transactionId, address owner) {
    if (!confirmations[transactionId][owner])
      revert();
    _;
  }

  modifier notConfirmed(uint transactionId, address owner) {
    if (confirmations[transactionId][owner])
      revert();
    _;
  }

  modifier notExecuted(uint transactionId) {
    if (transactions[transactionId].executed)
      revert();
    _;
  }

  modifier notNull(address _address) {
    if (_address == 0)
      revert();
    _;
  }

  modifier validRequirement(uint ownerCount, uint _required) {
    if ( ownerCount > MAX_OWNER_COUNT
      || _required > ownerCount
      || _required == 0
      || ownerCount == 0)
      revert();
    _;
  }


   

   
   
   
  constructor (address[] _owners, uint _required)
    public
    validRequirement(_owners.length, _required)
  {
     
    for (uint i=0; i<_owners.length; i++) {
      if (isOwner[_owners[i]] || _owners[i] == 0)
        revert();
      isOwner[_owners[i]] = true;
    }

     
    owners = _owners;

     
    required = _required;
  }

   

   
  function()
    public
    payable
  {

  }
    
   
   
  function addOwner(address owner)
    public
    onlyWallet
    ownerDoesNotExist(owner)
    notNull(owner)
    validRequirement(owners.length + 1, required)
  {
    isOwner[owner] = true;
    owners.push(owner);
    emit OwnerAddition(owner);
  }

   
   
  function removeOwner(address owner)
    public
    onlyWallet
    ownerExists(owner)
    validRequirement(owners.length, required)
  {
    isOwner[owner] = false;
    for (uint i=0; i<owners.length - 1; i++)
      if (owners[i] == owner) {
        owners[i] = owners[owners.length - 1];
        break;
      }

    owners.length -= 1;
    if (required > owners.length)
      changeRequirement(owners.length);
    emit OwnerRemoval(owner);
  }

   
   
   
  function replaceOwner(address owner, address newOwner)
    public
    onlyWallet
    ownerExists(owner)
    ownerDoesNotExist(newOwner)
  {
    for (uint i=0; i<owners.length; i++)
      if (owners[i] == owner) {
        owners[i] = newOwner;
        break;
      }

    isOwner[owner] = false;
    isOwner[newOwner] = true;
    emit OwnerRemoval(owner);
    emit OwnerAddition(newOwner);
  }

   
   
  function changeRequirement(uint _required)
    public
    onlyWallet
    validRequirement(owners.length, _required)
  {
    required = _required;
    emit RequirementChange(_required);
  }

   
   
   
   
   
  function submitTransaction(address destination, uint value, bytes data)
    public
    returns (uint transactionId)
  {
    transactionId = addTransaction(destination, value, data);
    confirmTransaction(transactionId);
  }

   
   
  function confirmTransaction(uint transactionId)
    public
    ownerExists(msg.sender)
    transactionExists(transactionId)
    notConfirmed(transactionId, msg.sender)
  {
    confirmations[transactionId][msg.sender] = true;
    emit Confirmation(msg.sender, transactionId);
    executeTransaction(transactionId);
  }

   
   
  function revokeConfirmation(uint transactionId)
    public
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
  {
    confirmations[transactionId][msg.sender] = false;
    emit Revocation(msg.sender, transactionId);
  }

   
   
  function executeTransaction(uint transactionId)
    public
    notExecuted(transactionId)
  {
    if (isConfirmed(transactionId)) {
      Transaction storage txToExecute = transactions[transactionId];
      txToExecute.executed = true;
      if (txToExecute.destination.call.value(txToExecute.value)(txToExecute.data))
        emit Execution(transactionId);
      else {
        emit ExecutionFailure(transactionId);
        txToExecute.executed = false;
      }
    }
  }

   
   
   
  function isConfirmed(uint transactionId)
    public
    constant
    returns (bool)
  {
    uint count = 0;
    for (uint i=0; i<owners.length; i++) {
      if (confirmations[transactionId][owners[i]])
        count += 1;
      if (count == required)
        return true;
    }
  }

   

   
   
   
   
   
  function addTransaction(address destination, uint value, bytes data)
    internal
    notNull(destination)
    returns (uint transactionId)
  {
    transactionId = transactionCount;

    transactions[transactionId] = Transaction({
        destination: destination,
        value: value,
        data: data,
        executed: false
    });

    transactionCount += 1;
    emit Submission(transactionId);
  }

   
   
   
   
  function getConfirmationCount(uint transactionId)
    public
    constant
    returns (uint count)
  {
    for (uint i=0; i<owners.length; i++)
      if (confirmations[transactionId][owners[i]])
        count += 1;
  }

   
   
   
   
  function getTransactionCount(bool pending, bool executed)
    public
    constant
    returns (uint count)
  {
    for (uint i=0; i<transactionCount; i++)
      if (pending && !transactions[i].executed || executed && transactions[i].executed)
        count += 1;
  }

   
   
  function getOwners()
    public
    constant
    returns (address[])
  {
    return owners;
  }

   
   
   
  function getConfirmations(uint transactionId)
    public
    constant
    returns (address[] _confirmations)
  {
    address[] memory confirmationsTemp = new address[](owners.length);
    uint count = 0;
    uint i;
    for (i=0; i<owners.length; i++)
      if (confirmations[transactionId][owners[i]]) {
        confirmationsTemp[count] = owners[i];
        count += 1;
      }

      _confirmations = new address[](count);

      for (i=0; i<count; i++)
        _confirmations[i] = confirmationsTemp[i];
  }

   
   
   
   
   
   
  function getTransactionIds(uint from, uint to, bool pending, bool executed)
    public
    constant
    returns (uint[] _transactionIds)
  {
    uint[] memory transactionIdsTemp = new uint[](transactionCount);
    uint count = 0;
    uint i;

    for (i=0; i<transactionCount; i++)
      if (pending && !transactions[i].executed || executed && transactions[i].executed) {
        transactionIdsTemp[count] = i;
        count += 1;
      }

      _transactionIds = new uint[](to - from);

    for (i=from; i<to; i++)
      _transactionIds[i - from] = transactionIdsTemp[i];
  }

  function tokenFallback(address  , uint  , bytes  )
  public
  returns (bool)
  {
    return true;
  }
}

 

 
contract ZethrTokenBankrollInterface is ERC223Receiving {
  uint public jackpotBalance;
  
  function getMaxProfit(address) public view returns (uint);
  function gameTokenResolution(uint _toWinnerAmount, address _winnerAddress, uint _toJackpotAmount, address _jackpotAddress, uint _originalBetSize) external;
  function payJackpotToWinner(address _winnerAddress, uint payoutDivisor) public;
}

 

contract ZethrBankrollControllerInterface is ERC223Receiving {
  address public jackpotAddress;

  ZethrTokenBankrollInterface[7] public tokenBankrolls; 
  
  ZethrMultiSigWallet public multiSigWallet;

  mapping(address => bool) public validGameAddresses;

  function gamePayoutResolver(address _resolver, uint _tokenAmount) public;

  function isTokenBankroll(address _address) public view returns (bool);

  function getTokenBankrollAddressFromTier(uint8 _tier) public view returns (address);

  function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

 

 
contract ZethrGame {
  using SafeMath for uint;
  using SafeMath for uint56;

   
  event Result (address player, uint amountWagered, int amountOffset);
  event Wager (address player, uint amount, bytes data);

   
  address[] pendingBetsQueue;
  uint queueHead = 0;
  uint queueTail = 0;

   
  mapping(address => BetBase) bets;

   
  struct BetBase {
     
    uint56 tokenValue;     
    uint48 blockNumber;
    uint8 tier;
     
  }

   
   
  mapping(address => uint) pendingBetsMapping;

   
  ZethrBankrollControllerInterface controller;

   
  bool paused;

   
  uint minBet = 1e18;

   
  uint resolverPercentage;

   
  string gameName;

  constructor (address _controllerAddress, uint _resolverPercentage, string _name) public {
    controller = ZethrBankrollControllerInterface(_controllerAddress);
    resolverPercentage = _resolverPercentage;
    gameName = _name;
  }

   
  function getMaxProfit()
  public view
  returns (uint)
  {
    return ZethrTokenBankrollInterface(msg.sender).getMaxProfit(address(this));
  }

   
  function ownerPauseGame()
  public
  ownerOnly
  {
    paused = true;
  }

   
  function ownerResumeGame()
  public
  ownerOnly
  {
    paused = false;
  }

   
  function ownerSetResolverPercentage(uint _percentage)
  public
  ownerOnly
  {
    require(_percentage <= 1000000);
    resolverPercentage = _percentage;
  }

   
  function ownerSetControllerAddress(address _controllerAddress)
  public
  ownerOnly
  {
    controller = ZethrBankrollControllerInterface(_controllerAddress);
  }

   
   
  function ownerSetGameName(string _name)
  ownerOnly
  public
  {
    gameName = _name;
  }

   
  function getGameName()
  public view
  returns (string)
  {
    return gameName;
  }

   
  function resolveExpiredBets(uint _numToResolve)
  public
  returns (uint tokensEarned_, uint queueHead_)
  {
    uint mQueue = queueHead;
    uint head;
    uint tail = (mQueue + _numToResolve) > pendingBetsQueue.length ? pendingBetsQueue.length : (mQueue + _numToResolve);
    uint tokensEarned = 0;

    for (head = mQueue; head < tail; head++) {
       
       
       
      if (pendingBetsQueue[head] == address(0x0)) {
        continue;
      }

      if (bets[pendingBetsQueue[head]].blockNumber != 0 && block.number > 256 + bets[pendingBetsQueue[head]].blockNumber) {
         
         
         
         
        int sum = - finishBetFrom(pendingBetsQueue[head]);

         
        if (sum > 0) {
          tokensEarned += (uint(sum).mul(resolverPercentage)).div(1000000);
        }

         
      } else {
         
        break;
      }
    }

    queueHead = head;

     
    if (tokensEarned >= 1e14) {
      controller.gamePayoutResolver(msg.sender, tokensEarned);
    }

    return (tokensEarned, head);
  }

   
  function finishBet()
  public
  hasNotBetThisBlock(msg.sender)
  returns (int)
  {
    return finishBetFrom(msg.sender);
  }

   
  function maxRandom(uint _blockn, address _entropy, uint _index)
  private view
  returns (uint256 randomNumber)
  {
    return uint256(keccak256(
        abi.encodePacked(
          blockhash(_blockn),
          _entropy,
          _index
        )));
  }

   
  function random(uint256 _upper, uint256 _blockn, address _entropy, uint _index)
  internal view
  returns (uint256 randomNumber)
  {
    return maxRandom(_blockn, _entropy, _index) % _upper;
  }

   
  modifier hasNotBetThisBlock(address _sender)
  {
    require(bets[_sender].blockNumber != block.number);
    _;
  }

   
  modifier bankrollOnly {
    require(controller.isTokenBankroll(msg.sender));
    _;
  }

   
  modifier isNotPaused {
    require(!paused);
    _;
  }

   
  modifier betIsValid(uint _betSize, uint _tier, bytes _data) {
    uint divRate = ZethrTierLibrary.getDivRate(_tier);
    require(isBetValid(_betSize, divRate, _data));
    _;
  }

   
  modifier ownerOnly()
  {
    require(msg.sender == address(controller) || controller.multiSigWallet().isOwner(msg.sender));
    _;
  }

   
  function execute(address _player, uint _tokenCount, uint _divRate, bytes _data) public;

   
  function finishBetFrom(address _playerAddress) internal returns (int);

   
  function isBetValid(uint _tokenCount, uint _divRate, bytes _data) public view returns (bool);
}

 

 
contract ZethrDice is ZethrGame {

   

   
  struct Bet {
     
    uint56 tokenValue;
    uint48 blockNumber;
    uint8 tier;
     
    uint8 rollUnder;
    uint8 numRolls;
  }

   

  uint constant private MAX_INT = 2 ** 256 - 1;
  uint constant public maxProfitDivisor = 1000000;
  uint constant public maxNumber = 100;
  uint constant public minNumber = 2;
  uint constant public houseEdgeDivisor = 1000;
  uint constant public houseEdge = 990;
  uint constant public minBet = 1e18;

   

  constructor (address _controllerAddress, uint _resolverPercentage, string _name)
  ZethrGame(_controllerAddress, _resolverPercentage, _name)
  public
  {
  }

   

   
  function getLastRollOutput(address _playerAddress)
  public view
  returns (uint winAmount, uint lossAmount, uint[] memory output)
  {
     
    Bet storage playerBetInStorage = getBet(_playerAddress);
    Bet memory playerBet = playerBetInStorage;

     
    require(playerBet.blockNumber != 0);

    (winAmount, lossAmount, output) = getRollOutput(playerBet.blockNumber, playerBet.rollUnder, playerBet.numRolls, playerBet.tokenValue.mul(1e14), _playerAddress);

    return (winAmount, lossAmount, output);
  }

    event RollResult(
        uint    _blockNumber,
        address _target,
        uint    _rollUnder,
        uint    _numRolls,
        uint    _tokenValue,
        uint    _winAmount,
        uint    _lossAmount,
        uint[]  _output
    );

   
  function getRollOutput(uint _blockNumber, uint8 _rollUnder, uint8 _numRolls, uint _tokenValue, address _target)
  public
  returns (uint winAmount, uint lossAmount, uint[] memory output)
  {
    output = new uint[](_numRolls);
     

     
    if (block.number - _blockNumber > 255) {
      lossAmount = _tokenValue.mul(_numRolls);
    } else {
      uint profit = calculateProfit(_tokenValue, _rollUnder);

      for (uint i = 0; i < _numRolls; i++) {
         
        output[i] = random(100, _blockNumber, _target, i) + 1;

        if (output[i] < _rollUnder) {
           
          winAmount += profit + _tokenValue;
        } else {
          lossAmount += _tokenValue;
        }
      }
    }
    emit RollResult(_blockNumber, _target, _rollUnder, _numRolls, _tokenValue, winAmount, lossAmount, output);
    return (winAmount, lossAmount, output);
  }

   
  function getRollResults(uint _blockNumber, uint8 _rollUnder, uint8 _numRolls, uint _tokenValue, address _target)
  public
  returns (uint winAmount, uint lossAmount)
  {
     
    if (block.number - _blockNumber > 255) {
      lossAmount = _tokenValue.mul(_numRolls);
    } else {
      uint profit = calculateProfit(_tokenValue, _rollUnder);

      for (uint i = 0; i < _numRolls; i++) {
         
        uint output = random(100, _blockNumber, _target, i) + 1;

        if (output < _rollUnder) {
          winAmount += profit + _tokenValue;
        } else {
          lossAmount += _tokenValue;
        }
      }
    }

    return (winAmount, lossAmount);
  }

   

   

   
  function calculateProfit(uint _initBet, uint _roll)
  internal view
  returns (uint)
  {
    return ((((_initBet * (100 - (_roll.sub(1)))) / (_roll.sub(1)) + _initBet)) * houseEdge / houseEdgeDivisor) - _initBet;
  }

   
  function getBet(address _playerAddress)
  internal view
  returns (Bet storage)
  {
     
    BetBase storage betBase = bets[_playerAddress];

    Bet storage playerBet;
    assembly {
     
      let tmp := betBase_slot

     
      swap1
    }
     

     
    return playerBet;
  }

   

   
  function finishBetFrom(address _playerAddress)
  internal
  returns (int  )
  {
     
    uint winAmount;
    uint lossAmount;

     
    Bet storage playerBetInStorage = getBet(_playerAddress);
    Bet memory playerBet = playerBetInStorage;

     
    require(playerBet.blockNumber != 0);
    playerBetInStorage.blockNumber = 0;

     
     
     
    (winAmount, lossAmount) = getRollResults(playerBet.blockNumber, playerBet.rollUnder, playerBet.numRolls, playerBet.tokenValue.mul(1e14), _playerAddress);

     
    address tokenBankrollAddress = controller.getTokenBankrollAddressFromTier(playerBet.tier);
    ZethrTokenBankrollInterface bankroll = ZethrTokenBankrollInterface(tokenBankrollAddress);

     
    bankroll.gameTokenResolution(winAmount, _playerAddress, 0, address(0x0), playerBet.tokenValue.mul(1e14).mul(playerBet.numRolls));

     
    uint index = pendingBetsMapping[_playerAddress];

     
    pendingBetsQueue[index] = address(0x0);

     
    pendingBetsMapping[_playerAddress] = 0;

    emit Result(_playerAddress, playerBet.tokenValue.mul(1e14), int(winAmount) - int(lossAmount));

     
    return (int(winAmount) - int(lossAmount));
  }

   
  function execute(address _player, uint _tokenCount, uint _tier, bytes _data)
  isNotPaused
  bankrollOnly
  betIsValid(_tokenCount, _tier, _data)
  hasNotBetThisBlock(_player)
  public
  {
    Bet storage playerBet = getBet(_player);

     
    if (playerBet.blockNumber != 0) {
      finishBetFrom(_player);
    }

    uint8 rolls = uint8(_data[0]);
    uint8 rollUnder = uint8(_data[1]);

     
    playerBet.tokenValue = uint56(_tokenCount.div(rolls).div(1e14));
    playerBet.blockNumber = uint48(block.number);
    playerBet.tier = uint8(_tier);
    playerBet.rollUnder = rollUnder;
    playerBet.numRolls = rolls;

     
    pendingBetsQueue.length ++;
    pendingBetsQueue[queueTail] = _player;
    queueTail++;

     
    pendingBetsMapping[_player] = queueTail - 1;

     
    emit Wager(_player, _tokenCount, _data);
  }

   
  function isBetValid(uint _tokenCount, uint  , bytes _data)
  public view
  returns (bool)
  {
    uint8 rollUnder = uint8(_data[1]);

    return (calculateProfit(_tokenCount, rollUnder) < getMaxProfit()
    && _tokenCount >= minBet
    && rollUnder >= minNumber
    && rollUnder <= maxNumber);
  }
}