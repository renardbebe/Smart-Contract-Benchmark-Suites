 

pragma solidity ^0.4.18;

 

contract DataCenterInterface {
  function getResult(bytes32 gameId) view public returns (uint16, uint16, uint8);
}

contract DataCenterAddrResolverInterface {
  function getAddress() public returns (address _addr);
}

contract DataCenterBridge {
  uint8 constant networkID_auto = 0;
  uint8 constant networkID_mainnet = 1;
  uint8 constant networkID_testnet = 3;
  string public networkName;

  address public mainnetAddr = 0x6690E2698Bfa407DB697E69a11eA56810454549b;
  address public testnetAddr = 0x282b192518fc09568de0E66Df8e2533f88C16672;

  DataCenterAddrResolverInterface DAR;

  DataCenterInterface dataCenter;

  modifier dataCenterAPI() {
    if((address(DAR) == 0) || (getCodeSize(address(DAR)) == 0))
      setNetwork(networkID_auto);
    if(address(dataCenter) != DAR.getAddress())
      dataCenter = DataCenterInterface(DAR.getAddress());
    _;
  }

   
  function setNetwork(uint8  ) internal returns(bool){
    return setNetwork();
  }

  function setNetwork() internal returns(bool){
    if (getCodeSize(mainnetAddr) > 0) {
      DAR = DataCenterAddrResolverInterface(mainnetAddr);
      setNetworkName("eth_mainnet");
      return true;
    }
    if (getCodeSize(testnetAddr) > 0) {
      DAR = DataCenterAddrResolverInterface(testnetAddr);
      setNetworkName("eth_ropsten");
      return true;
    }
    return false;
  }

  function setNetworkName(string _networkName) internal {
    networkName = _networkName;
  }

  function getNetworkName() internal view returns (string) {
    return networkName;
  }

  function dataCenterGetResult(bytes32 _gameId) dataCenterAPI internal returns (uint16, uint16, uint8){
    return dataCenter.getResult(_gameId);
  }

  function getCodeSize(address _addr) view internal returns (uint _size) {
    assembly {
      _size := extcodesize(_addr)
    }
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

contract Bet is Ownable, DataCenterBridge {
  using SafeMath for uint;

  event LogDistributeReward(address addr, uint reward, uint index);
  event LogGameResult(bytes32 indexed category, bytes32 indexed gameId, uint leftPts, uint rightPts);
  event LogParticipant(address addr, uint choice, uint betAmount);
  event LogRefund(address addr, uint betAmount);
  event LogBetClosed(bool isRefund, uint timestamp);
  event LogDealerWithdraw(address addr, uint withdrawAmount);

   
  struct BetInfo {
    bytes32 category;
    bytes32 gameId;
    uint8   spread;
    uint8   flag;
    uint16  leftOdds;
    uint16  middleOdds;
    uint16  rightOdds;
    uint    minimumBet;
    uint    startTime;
    uint    deposit;
    address dealer;
  }

  struct Player {
    uint betAmount;
    uint choice;
  }

   
  uint8 public winChoice;
  uint8 public confirmations = 0;
  uint8 public neededConfirmations = 1;
  uint16 public leftPts;
  uint16 public rightPts;
  bool public isBetClosed = false;

  uint public totalBetAmount = 0;
  uint public leftAmount;
  uint public middleAmount;
  uint public rightAmount;
  uint public numberOfBet;

  address [] public players;
  mapping(address => Player) public playerInfo;

   
  modifier onlyDealer() {
    require(msg.sender == betInfo.dealer);
    _;
  }

  function() payable public {}

  BetInfo betInfo;

  function Bet(address _dealer, bytes32 _category, bytes32 _gameId, uint _minimumBet, 
                  uint8 _spread, uint16 _leftOdds, uint16 _middleOdds, uint16 _rightOdds, uint8 _flag,
                  uint _startTime, uint8 _neededConfirmations, address _owner) payable public {
    require(_flag == 1 || _flag == 3);
    require(_startTime > now);
    require(msg.value >= 0.1 ether);
    require(_neededConfirmations >= neededConfirmations);

    betInfo.dealer = _dealer;
    betInfo.deposit = msg.value;
    betInfo.flag = _flag;
    betInfo.category = _category;
    betInfo.gameId = _gameId;
    betInfo.minimumBet = _minimumBet;
    betInfo.spread = _spread;
    betInfo.leftOdds = _leftOdds;
    betInfo.middleOdds = _middleOdds;
    betInfo.rightOdds = _rightOdds;
    betInfo.startTime = _startTime;

    neededConfirmations = _neededConfirmations;
    owner = _owner;
  }

   
  function getBetInfo() public view returns (bytes32, bytes32, uint8, uint8, uint16, uint16, uint16, uint, uint, uint, address) {
    return (betInfo.category, betInfo.gameId, betInfo.spread, betInfo.flag, betInfo.leftOdds, betInfo.middleOdds,
            betInfo.rightOdds, betInfo.minimumBet, betInfo.startTime, betInfo.deposit, betInfo.dealer);
  }

   
  function getBetMutableData() public view returns (uint, uint, uint, uint, uint, uint) {
    return (numberOfBet, totalBetAmount, leftAmount, middleAmount, rightAmount, betInfo.deposit);
  }

   
  function getBetResult() public view returns (uint8, uint8, uint8, uint16, uint16, bool) {
    return (winChoice, confirmations, neededConfirmations, leftPts, rightPts, isBetClosed);
  }

   
  function getRefundTxFee() public view returns (uint) {
    return numberOfBet.mul(5000000000 * 21000);
  }

   
  function checkPlayerExists(address player) public view returns (bool) {
    if (playerInfo[player].choice == 0) {
      return false;
    }
    return true;
  }

   
  function isSolvent(uint choice, uint amount) internal view returns (bool) {
    uint needAmount;
    if (choice == 1) {
      needAmount = (leftAmount.add(amount)).mul(betInfo.leftOdds).div(100);
    } else if (choice == 2) {
      needAmount = (middleAmount.add(amount)).mul(betInfo.middleOdds).div(100);
    } else {
      needAmount = (rightAmount.add(amount)).mul(betInfo.rightOdds).div(100);
    }

    if (needAmount.add(getRefundTxFee()) > totalBetAmount.add(amount).add(betInfo.deposit)) {
      return false;
    } else {
      return true;
    }
  }

   
  function updateAmountOfEachChoice(uint choice, uint amount) internal {
    if (choice == 1) {
      leftAmount = leftAmount.add(amount);
    } else if (choice == 2) {
      middleAmount = middleAmount.add(amount);
    } else {
      rightAmount = rightAmount.add(amount);
    }
  }

   
  function placeBet(uint choice) public payable {
    require(now < betInfo.startTime);
    require(choice == 1 ||  choice == 2 || choice == 3);
    require(msg.value >= betInfo.minimumBet);
    require(!checkPlayerExists(msg.sender));

    if (!isSolvent(choice, msg.value)) {
      revert();
    }

    playerInfo[msg.sender].betAmount = msg.value;
    playerInfo[msg.sender].choice = choice;

    totalBetAmount = totalBetAmount.add(msg.value);
    numberOfBet = numberOfBet.add(1);
    updateAmountOfEachChoice(choice, msg.value);
    players.push(msg.sender);
    LogParticipant(msg.sender, choice, msg.value);
  }

   
  function rechargeDeposit() public payable {
    require(msg.value >= betInfo.minimumBet);
    betInfo.deposit = betInfo.deposit.add(msg.value);
  }

   
  function getWinChoice(uint _leftPts, uint _rightPts) public view returns (uint8) {
    uint8 _winChoice;
    if (betInfo.spread == 0) {
      if (_leftPts > _rightPts) {
        _winChoice = 1;
      } else if (_leftPts == _rightPts) {
        _winChoice = 2;
      } else {
        _winChoice = 3;
      }
    } else {
      if (betInfo.flag == 1) {
        if (_leftPts + betInfo.spread > _rightPts) {
          _winChoice = 1;
        } else {
          _winChoice = 3;
        }
      } else {
        if (_rightPts + betInfo.spread > _leftPts) {
          _winChoice = 3;
        } else {
          _winChoice = 1;
        }
      }
    }
    return _winChoice;
  }

   
  function manualCloseBet(uint16 _leftPts, uint16 _rightPts) onlyOwner external {
    require(!isBetClosed);
    leftPts = _leftPts;
    rightPts = _rightPts;

    LogGameResult(betInfo.category, betInfo.gameId, leftPts, rightPts);

    winChoice = getWinChoice(leftPts, rightPts);

    if (winChoice == 1) {
      distributeReward(betInfo.leftOdds);
    } else if (winChoice == 2) {
      distributeReward(betInfo.middleOdds);
    } else {
      distributeReward(betInfo.rightOdds);
    }

    isBetClosed = true;
    LogBetClosed(false, now);
    withdraw();
  }

   
  function closeBet() external {
    require(!isBetClosed);
    (leftPts, rightPts, confirmations) = dataCenterGetResult(betInfo.gameId);

    require(confirmations >= neededConfirmations);

    LogGameResult(betInfo.category, betInfo.gameId, leftPts, rightPts);

    winChoice = getWinChoice(leftPts, rightPts);

    if (winChoice == 1) {
      distributeReward(betInfo.leftOdds);
    } else if (winChoice == 2) {
      distributeReward(betInfo.middleOdds);
    } else {
      distributeReward(betInfo.rightOdds);
    }

    isBetClosed = true;
    LogBetClosed(false, now);
    withdraw();
  }

   
  function getPlayers() view public returns (address[]) {
    return players;
  }

   
  function getBalance() view public returns (uint) {
    return address(this).balance;
  }

   
  function refund() onlyOwner public {
    for (uint i = 0; i < players.length; i++) {
      players[i].transfer(playerInfo[players[i]].betAmount);
      LogRefund(players[i], playerInfo[players[i]].betAmount);
    }

    isBetClosed = true;
    LogBetClosed(true, now);
    withdraw();
  }

   
  function withdraw() internal {
    require(isBetClosed);
    uint _balance = address(this).balance;
    betInfo.dealer.transfer(_balance);
    LogDealerWithdraw(betInfo.dealer, _balance);
  }

   
  function distributeReward(uint winOdds) internal {
    for (uint i = 0; i < players.length; i++) {
      if (playerInfo[players[i]].choice == winChoice) {
        players[i].transfer(winOdds.mul(playerInfo[players[i]].betAmount).div(100));
        LogDistributeReward(players[i], winOdds.mul(playerInfo[players[i]].betAmount).div(100), i);
      }
    }
  }
}

contract BetCenter is Ownable {

  mapping(bytes32 => Bet[]) public bets;
  mapping(bytes32 => bytes32[]) public gameIds;

  event LogCreateBet(address indexed dealerAddr, address betAddr, bytes32 indexed category, uint indexed startTime);

  function() payable public {}

  function createBet(bytes32 category, bytes32 gameId, uint minimumBet, 
                  uint8 spread, uint16 leftOdds, uint16 middleOdds, uint16 rightOdds, uint8 flag,
                  uint startTime, uint8 confirmations) payable public {
    Bet bet = (new Bet).value(msg.value)(msg.sender, category, gameId, minimumBet, 
                  spread, leftOdds, middleOdds, rightOdds , flag, startTime, confirmations, owner);
    bets[category].push(bet);
    gameIds[category].push(gameId);
    LogCreateBet(msg.sender, bet, category, startTime);
  }

   
  function getBetsByCategory(bytes32 category) view public returns (Bet[]) {
    return bets[category];
  }

  function getGameIdsByCategory(bytes32 category) view public returns (bytes32 []) {
    return gameIds[category];
  }

}