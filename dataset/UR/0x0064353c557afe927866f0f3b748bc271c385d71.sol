 

pragma solidity 0.4.19;

contract Base {
  function isContract(address _addr) constant internal returns(bool) {
    uint size;
    if (_addr == 0) return false;
    assembly {
        size := extcodesize(_addr)
    }
    return size > 0;
  }
}

 
contract RngRequester {
  function acceptRandom(bytes32 id, bytes result);
}

 
contract CryptoLuckRng {
  function requestRandom(uint8 numberOfBytes) payable returns(bytes32);

  function getFee() returns(uint256);
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

contract StateQuickEth is Ownable {
   
   
   
   
   
  modifier gameStopped {
    require(!gameRunning);
    
    _;
  }

  uint16 internal constant MANUAL_WITHDRAW_INTERVAL = 1 hours;
  
  bool public gameRunning;
  
   
   
   
  bool public stopGameOnNextRound;

   
   
  uint32 public minGasForDrawing = 350000;
  
   
   
  uint256 public minGasPriceForDrawing = 6000000000;

   
   
   
  uint256 public rewardForDrawing = 2 finney;

   
   
  uint8 public houseFee = 10;

   
  uint256 public minContribution = 20 finney;
  uint256 public maxContribution = 1 ether;
  
   
  uint256 public maxBonusTickets = 5;
  
   
  uint8 public bonusTicketsPercentage = 1;
  
   
  uint16 public requiredEntries = 5;
  
   
  uint256 public requiredTimeBetweenDraws = 60 minutes;

  address public rngAddress;
   
   

   
  function updateHouseFee(uint8 _value) public onlyOwner gameStopped {
    houseFee = _value;
  }

  function updateMinContribution(uint256 _value) public onlyOwner gameStopped {
    minContribution = _value;
  }

  function updateMaxContribution(uint256 _value) public onlyOwner gameStopped {
    maxContribution = _value;
  }

  function updateRequiredEntries(uint16 _value) public onlyOwner gameStopped {
    requiredEntries = _value;
  }

  function updateRequiredTimeBetweenDraws(uint256 _value) public onlyOwner gameStopped {
    requiredTimeBetweenDraws = _value;
  }
   
   

   
  function updateMaxBonusTickets(uint256 _value) public onlyOwner {
    maxBonusTickets = _value;
  }

  function updateBonusTicketsPercentage(uint8 _value) public onlyOwner {
    bonusTicketsPercentage = _value;
  }

  function updateStopGameOnNextRound(bool _value) public onlyOwner {
    stopGameOnNextRound = _value;
  }

  function restartGame() public onlyOwner {
    gameRunning = true;
  }
  
  function updateMinGasForDrawing(uint32 newGasAmount) public onlyOwner {
    minGasForDrawing = newGasAmount;
  }

  function updateMinGasPriceForDrawing(uint32 newGasPrice) public onlyOwner {
    minGasPriceForDrawing = newGasPrice;
  }

  function updateRngAddress(address newAddress) public onlyOwner {
    require(rngAddress != 0x0);
    rngAddress = newAddress;
  }

  function updateRewardForDrawing(uint256 newRewardForDrawing) public onlyOwner {
    require(newRewardForDrawing > 0);

    rewardForDrawing = newRewardForDrawing;
  }
   

   
}

 
 
 
 
 
 
 
 
 
 
contract CryptoLuckQuickEthV1 is RngRequester, StateQuickEth, Base {
  using SafeMath for uint;

  modifier onlyRng {
    require(msg.sender == rngAddress);
    
    _;
  }

  event LogLotteryResult(
    uint32 indexed lotteryId, 
    uint8 status,
    bytes32 indexed oraclizeId, 
    bytes oraclizeResult
  );
  
  struct Lottery {
    uint256 prizePool;
    uint256 totalContributions;
    uint256 oraclizeFees;
    
    uint256 drawerBonusTickets;
    
    mapping (address => uint256) balances;
    address[] participants;
      
    address winner;
    address drawer;

    bytes32[] oraclizeIds;
    bytes oraclizeResult;

    uint256 winningNumber;

     
     
     
    uint8 status;

    bool awaitingOraclizeCallback;
  }
  
  bool public useOraclize;
   
  uint32 public currentLotteryId = 0;
  mapping (uint32 => Lottery) public lotteries;
  
   
  uint256 public ticketPrice = 1 finney;
  
   
  uint256 public lastDrawTs;
  
  uint256 public houseBalance = 0;
  
  function CryptoLuckQuickEthV1(address _rngAddress, bool _useOraclize) {
    stopGameOnNextRound = false;
    gameRunning = true;
    
    require(_rngAddress != 0x0);

    rngAddress = _rngAddress;
    useOraclize = _useOraclize;
    
     
     
    lastDrawTs = block.timestamp;
  }

   
  function currentLottery() view internal returns (Lottery storage) {
    return lotteries[currentLotteryId];
  }

   
   
   
  function () public payable {
     
    require(!isContract(msg.sender));
    
     
    require(gameRunning);
    
     
    require(msg.value >= ticketPrice);
    
    uint256 existingBalance = currentLottery().balances[msg.sender];
    
     
    require(msg.value + existingBalance >= minContribution);
     
    require(msg.value + existingBalance <= maxContribution);
    
    updatePlayerBalance(currentLotteryId);
    
     
     
    if (mustDraw() && gasRequirementsOk()) {
      draw();
    }
  }

   
   
  function gasRequirementsOk() view private returns(bool) {
    return (msg.gas >= minGasForDrawing) && (tx.gasprice >= minGasPriceForDrawing);
  }

   
   
   
   
  function updatePlayerBalance(uint32 lotteryId) private returns(uint) {
    Lottery storage lot = lotteries[lotteryId];
    
     
     
    if (lot.awaitingOraclizeCallback) {
      updatePlayerBalance(lotteryId + 1);
      return;
    }

    address participant = msg.sender;
    
     
     
    if (lot.balances[participant] == 0) {
      lot.participants.push(participant);
    }
    
     
    lot.balances[participant] = lot.balances[participant].add(msg.value);
     
    lot.prizePool = lot.prizePool.add(msg.value);
    
    return lot.balances[participant];
  }
  
   
   
  function mustDraw() view private returns (bool) {
    Lottery memory lot = currentLottery();
    
     
    bool timeDiffOk = now - lastDrawTs >= requiredTimeBetweenDraws;
    
     
    bool minParticipantsOk = lot.participants.length >= requiredEntries;

    return minParticipantsOk && timeDiffOk;
  }

   
   
   
   
  function draw() private {
    Lottery storage lot = currentLottery();
    
    lot.awaitingOraclizeCallback = true;
    
     
     
    lot.totalContributions = lot.prizePool;

     
     
    lot.drawer = msg.sender;

    lastDrawTs = now;
    
    requestRandom();
  }

   
   
  function requestRandom() private {
    Lottery storage lot = currentLottery();
    
    CryptoLuckRng rngContract = CryptoLuckRng(rngAddress);
    
     
    uint fee = rngContract.getFee();
    
     
     
    lot.prizePool = lot.prizePool.sub(fee);
    lot.oraclizeFees = lot.oraclizeFees.add(fee);
    
     
     
    bytes32 oraclizeId = rngContract.requestRandom.value(fee)(7);
    
    lot.oraclizeIds.push(oraclizeId);
  }

   
   
  function acceptRandom(bytes32 reqId, bytes result) public onlyRng {
    Lottery storage lot = currentLottery();
    
     
     
    if (useOraclize) {
      require(currentOraclizeId() == reqId);
    }
    
     
    lot.oraclizeResult = result;

     
    uint256 bonusTickets = calculateBonusTickets(lot.totalContributions);

    lot.drawerBonusTickets = bonusTickets;

     
    uint256 totalTickets = bonusTickets + (lot.totalContributions / ticketPrice);
    
     
     
    lot.winningNumber = 1 + (uint(keccak256(result)) % totalTickets);

    findWinner();

    LogLotteryResult(currentLotteryId, 1, reqId, result);
  }
  
   
  function calculateBonusTickets(uint256 totalContributions) view internal returns(uint256) {
    
     
    uint256 bonusTickets = (totalContributions * bonusTicketsPercentage / 100) / ticketPrice;
    
     
    if (bonusTickets == 0) {
       bonusTickets = 1;
    }

    if (bonusTickets > maxBonusTickets) {
      bonusTickets = maxBonusTickets;
    }
    
    return bonusTickets;
  }

   
   
   
  function findWinner() private {
    Lottery storage lot = currentLottery();
    
    uint256 currentLocation = 1;

    for (uint16 i = 0; i < lot.participants.length; i++) {
      address participant = lot.participants[i];
      
       
       
      uint256 finalTickets = lot.balances[participant] / ticketPrice;
      
       
      if (participant == lot.drawer) {
        finalTickets += lot.drawerBonusTickets;
      }

      currentLocation += finalTickets - 1; 
      
      if (currentLocation >= lot.winningNumber) {
          lot.winner = participant;
          break;
      }
       
      currentLocation += 1; 
    }
    
     
    uint256 prize = lot.prizePool;

     
     
    uint256 houseShare = houseFee * prize / 1000;
    
    houseBalance = houseBalance.add(houseShare);
    
     
    prize = prize.sub(houseShare);
    prize = prize.sub(rewardForDrawing);
    
    lot.status = 1;
    lot.awaitingOraclizeCallback = false;
    
    lot.prizePool = prize;

     
    lot.winner.transfer(prize);
    
     
     
    lot.drawer.transfer(rewardForDrawing);

    finalizeLottery();
  } 
  
   
   
  
   
  function finalizeLottery() private {
    currentLotteryId += 1;

    if (stopGameOnNextRound) {
      gameRunning = false;
      stopGameOnNextRound = false;
    }
  }

  function currentOraclizeId() view private returns(bytes32) {
    Lottery memory lot = currentLottery();
    
    return lot.oraclizeIds[lot.oraclizeIds.length - 1];
  }

   
   
  function withdrawFromFailedLottery(uint32 lotteryId) public {
    address player = msg.sender;
    
    Lottery storage lot = lotteries[lotteryId];
    
     
    require(lot.status == 2);
    
     
    uint256 playerBalance = lot.balances[player].sub(lot.oraclizeFees / lot.participants.length);
     
    require(playerBalance > 0);

     
    lot.balances[player] = 0;
    lot.prizePool = lot.prizePool.sub(playerBalance);

     
    player.transfer(playerBalance);
  }

   
   
  
   
   
   
  function houseTopUp() public payable {
    houseBalance = houseBalance.add(msg.value);
  }
  
   
  function houseWithdraw() public onlyOwner {
    owner.transfer(houseBalance);
  }

   
  function manualDraw() public onlyOwner {
    Lottery storage lot = currentLottery();
     
    require(lot.status == 0);
    
     
    require(mustDraw());
    
     
     
    require(now - lastDrawTs > MANUAL_WITHDRAW_INTERVAL);

     
     
     
    if (lot.oraclizeIds.length == 2) {
      lot.status = 2;
      lot.awaitingOraclizeCallback = false;
      
      LogLotteryResult(currentLotteryId, 2, lot.oraclizeIds[lot.oraclizeIds.length - 1], "");

      finalizeLottery();
    } else {
      draw();
    }
  }

  
   

   
  function balanceInLottery(uint32 lotteryId, address player) view public returns(uint) {
    return lotteries[lotteryId].balances[player];
  }

  function participantsOf(uint32 lotteryId) view public returns (address[]) {
    return lotteries[lotteryId].participants;
  }

  function oraclizeIds(uint32 lotteryId) view public returns(bytes32[]) {
    return lotteries[lotteryId].oraclizeIds;
  }
}