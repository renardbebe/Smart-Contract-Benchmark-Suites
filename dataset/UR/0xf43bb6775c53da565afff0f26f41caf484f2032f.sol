 

pragma solidity 0.4.19;

 
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

 
contract ReentrancyGuard {

   
  bool private reentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
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

 
contract EtherButton is Ownable, ReentrancyGuard {
   
   
  using SafeMath for uint;

   
   
  event LogClick(
    uint _id,
    uint _price,
    uint _previousPrice,
    uint _endTime,
    uint _clickCount,
    uint _totalBonus,
    address _activePlayer,
    uint _activePlayerClickCount,
    uint _previousRoundTotalBonus
  );
  event LogClaimBonus(address _recipient, uint _bonus);
  event LogPlayerPayout(address _recipient, uint _amount);
  event LogSendPaymentFailure(address _recipient, uint _amount);

   
   
  uint public constant INITIAL_PRICE = .5 ether;
  uint public constant ROUND_DURATION = 7 hours;
   
  uint private constant PLAYER_PROFIT_NUMERATOR = 5;
  uint private constant PLAYER_PROFIT_DENOMINATOR = 100;
   
  uint private constant BONUS_NUMERATOR = 1;
  uint private constant BONUS_DENOMINATOR = 100; 
   
  uint private constant OWNER_FEE_NUMERATOR = 25;
  uint private constant OWNER_FEE_DENOMINATOR = 1000;

   
   
  struct Round {
    uint id;
    uint price;
    uint previousPrice;
    uint endTime;
    uint clickCount;
    uint totalBonus;
    uint claimedBonus;
    address activePlayer;
    mapping (address => uint) playerClickCounts;
    mapping (address => bool) bonusClaimedList;
  }

   
   
  mapping (uint => Round) public Rounds;
  uint public RoundId;

   
  function EtherButton() public {
    initializeRound();
    Rounds[RoundId].endTime = now.sub(1);
  }

   
  function click() nonReentrant external payable {
     
    require(msg.sender != owner);

     
     
     
    if (getIsRoundOver(RoundId)) {
      advanceRound(); 
    }

    Round storage round = Rounds[RoundId];

     
    require(msg.sender != round.activePlayer);
     
    require(msg.value >= round.price);

     
     
     
     
     
    if (msg.value > round.price) {
      sendPayment(msg.sender, msg.value.sub(round.price));
    }

     
    if (round.activePlayer != address(0)) {
       
       
      uint playerPayout = getPlayerPayout(round.previousPrice);
      sendPayment(round.activePlayer, playerPayout);
      LogPlayerPayout(round.activePlayer, playerPayout);

       
      sendPayment(owner, getOwnerFee(round.previousPrice));

       
      round.totalBonus = round.totalBonus.add(getBonusFee(round.previousPrice));
    }

     
    round.activePlayer = msg.sender;
    round.playerClickCounts[msg.sender] = round.playerClickCounts[msg.sender].add(1);
    round.clickCount = round.clickCount.add(1);
    round.previousPrice = round.price;
     
    round.price = getNextPrice(round.price);
     
    round.endTime = now.add(ROUND_DURATION);
    
     
    LogClick(
      round.id,
      round.price,
      round.previousPrice,
      round.endTime,
      round.clickCount,
      round.totalBonus,
      msg.sender,
      round.playerClickCounts[msg.sender],
      Rounds[RoundId.sub(1)].totalBonus
    );
  }

   
  function claimBonus() nonReentrant external {
     
     
     
    uint roundId = getIsRoundOver(RoundId) ? RoundId.add(1) : RoundId;
    uint previousRoundId = roundId.sub(1);
    bool isBonusClaimed = getIsBonusClaimed(previousRoundId, msg.sender);

     
    if (isBonusClaimed) {
      return;
    }

     
     
    bool isBonusUnlockExempt = getIsBonusUnlockExempt(previousRoundId, msg.sender);
    bool isBonusUnlocked = getPlayerClickCount(roundId, msg.sender) > 0;
    if (!isBonusUnlockExempt && !isBonusUnlocked) {
      return;
    }

     
    Round storage previousRound = Rounds[previousRoundId];
    uint playerClickCount = previousRound.playerClickCounts[msg.sender];
    uint roundClickCount = previousRound.clickCount;
     
    uint bonus = previousRound.totalBonus.mul(playerClickCount).div(roundClickCount);

     
     
     
    if (previousRound.activePlayer == msg.sender) {
      bonus = bonus.add(INITIAL_PRICE);
    }

    previousRound.bonusClaimedList[msg.sender] = true;
    previousRound.claimedBonus = previousRound.claimedBonus.add(bonus);
    sendPayment(msg.sender, bonus);

     
    LogClaimBonus(msg.sender, bonus);
  }

   
  function getIsBonusClaimed(uint roundId, address player) public view returns (bool) {
    return Rounds[roundId].bonusClaimedList[player];
  }

   
  function getPlayerClickCount(uint roundId, address player) public view returns (uint) {
    return Rounds[roundId].playerClickCounts[player];
  }

   
  function getIsBonusUnlockExempt(uint roundId, address player) public view returns (bool) {
    return Rounds[roundId].activePlayer == player;
  }

   
  function getIsRoundOver(uint roundId) private view returns (bool) {
    return now > Rounds[roundId].endTime;
  }

   
  function advanceRound() private {
    if (RoundId > 1) {
       
      Round storage previousRound = Rounds[RoundId.sub(1)];      
       
       
      uint remainingBonus = previousRound.totalBonus.add(INITIAL_PRICE).sub(previousRound.claimedBonus);
      Rounds[RoundId].totalBonus = Rounds[RoundId].totalBonus.add(remainingBonus);
    }

    RoundId = RoundId.add(1);
    initializeRound();
  }

   
  function initializeRound() private {
    Rounds[RoundId].id = RoundId;
    Rounds[RoundId].endTime = block.timestamp.add(ROUND_DURATION);
    Rounds[RoundId].price = INITIAL_PRICE;
  }

   
  function sendPayment(address recipient, uint amount) private returns (bool) {
    assert(recipient != address(0));
    assert(amount > 0);

     
     
     
     
     
     
     
    bool result = recipient.send(amount);

     
     
     
    if (!result) {
       
      LogSendPaymentFailure(recipient, amount);
    }

    return result;
  }

   
  function getNextPrice(uint price) private pure returns (uint) {
    uint playerFee = getPlayerFee(price);
    assert(playerFee > 0);

    uint bonusFee = getBonusFee(price);
    assert(bonusFee > 0);

    uint ownerFee = getOwnerFee(price);
    assert(ownerFee > 0);

    return price.add(playerFee).add(bonusFee).add(ownerFee);
  }

   
  function getBonusFee(uint price) private pure returns (uint) {
    return price.mul(BONUS_NUMERATOR).div(BONUS_DENOMINATOR);
  }

   
  function getOwnerFee(uint price) private pure returns (uint) {
    return price.mul(OWNER_FEE_NUMERATOR).div(OWNER_FEE_DENOMINATOR);
  }

   
  function getPlayerFee(uint price) private pure returns (uint) {
    return price.mul(PLAYER_PROFIT_NUMERATOR).div(PLAYER_PROFIT_DENOMINATOR);
  }

   
  function getPlayerPayout(uint price) private pure returns (uint) {
    return price.add(getPlayerFee(price));
  }
}