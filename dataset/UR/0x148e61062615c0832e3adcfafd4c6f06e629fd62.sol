 

pragma solidity ^0.4.17;

contract OracleBase {

  function getRandomUint(uint max) public returns (uint);

  function getRandomForContract(uint max, uint index) public view returns (uint);

  function getEtherDiceProfit(uint rate) public view returns (uint);

  function getRandomUint256(uint txId) public returns (uint256);

  function getRandomForContractClanwar(uint max, uint index) public view returns (uint);
}

 
contract ContractOwner {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

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


contract Etherauction is ContractOwner {

  using SafeMath for uint256;

  constructor() public payable {
    owner = msg.sender;

    gameId = 1;
    gameStartTime = block.timestamp;
    gameLastAuctionMoney = 10**15;

    gameLastAuctionTime = block.timestamp;
    gameSecondLeft = _getInitAuctionSeconds();
  }

  function adminAddMoney() public payable {
    reward = reward + msg.value * 80 / 100;
    nextReward = nextReward + msg.value * 20 / 100;
  }

  function addAuctionReward() public payable {
    reward = reward + msg.value;
  }


  uint256 gameId;  
  uint256 gameStartTime;   
  uint256 gameLastAuctionTime;    
  uint256 gameLastAuctionMoney; 
  uint256 gameSecondLeft;  


   

  uint256 reward;  
  uint256 dividends;   
  uint256 nextReward;  
  uint256 dividendForDev;


   

  OracleBase oracleAPI;

  function setOracleAPIAddress(address _addr) public onlyOwner {
    oracleAPI = OracleBase(_addr);
  }

  uint rollCount = 100;

  function getRandom() internal returns (uint256) {
    rollCount = rollCount + 1;
    return oracleAPI.getRandomForContract(100, rollCount);
  }



   

  function _inMoney(uint _m) internal {
    dividends = dividends + _m * 7 / 100;
    dividendForDev = dividendForDev + _m * 2 / 100;

    reward = reward + _m * 2 / 100;
    nextReward = nextReward + _m * 4 / 100;
  }

  function _startNewRound(address _addr) internal {
    reward = nextReward * 80 / 100;
    nextReward = nextReward * 20 / 100;
    gameId = gameId + 1;
    dividends = 0;

    gameStartTime = block.timestamp;
    gameLastAuctionTime = block.timestamp;


    uint256 price = _getMinAuctionStartPrice();
    reward = reward.sub(price);

    PlayerAuction memory p;
    gameAuction[gameId].push(p);
    gameAuction[gameId][0].addr = _addr;
    gameAuction[gameId][0].money = price;
    gameAuction[gameId][0].bid = price;
    gameAuction[gameId][0].refunded = false;
    gameAuction[gameId][0].dividended = false;

    gameLastAuctionMoney = price;
    gameSecondLeft = _getInitAuctionSeconds();

    emit GameAuction(gameId, _addr, price, price, gameSecondLeft, block.timestamp);
  }

  function adminPayout() public onlyOwner {
    owner.transfer(dividendForDev);
    dividendForDev = 0;
  }

   

  struct GameData {
    uint256 gameId;
    uint256 reward;
    uint256 dividends;
  }

  struct PlayerAuction {
    address addr;
    uint256 money;
    uint256 bid;
    bool refunded;
    bool dividended;
  }

  mapping(uint256 => PlayerAuction[]) gameAuction;

  GameData[] gameData;

   

  event GameAuction(uint indexed gameId, address player, uint money, uint auctionValue, uint secondsLeft, uint datetime);
  
  event GameRewardClaim(uint indexed gameId, address indexed player, uint money);

  event GameRewardRefund(uint indexed gameId, address indexed player, uint money);

  event GameEnd(uint indexed gameId, address indexed winner, uint money, uint datetime);

   

  function getMinAuctionValue() public view returns (uint256) {
    uint256 gap = _getGameAuctionGap();
    uint256 auctionValue = gap + gameLastAuctionMoney;
    return auctionValue;
  }

  function auction() public payable {
    bool ended = (block.timestamp > gameLastAuctionTime + gameSecondLeft) ? true: false;
    if (ended) {
      revert('this round end!!!');
    }

    uint256 len = gameAuction[gameId].length;
    if (len > 1) {
      address bidder = gameAuction[gameId][len - 1].addr;
      if (msg.sender == bidder)
        revert("wrong action");
    }

    uint256 gap = _getGameAuctionGap();
    uint256 auctionValue = gap + gameLastAuctionMoney;
    uint256 maxAuctionValue = 3 * gap + gameLastAuctionMoney;

    if (msg.value < auctionValue) {
      revert("wrong eth value!");
    }

    if (msg.value >= maxAuctionValue) {
      auctionValue = maxAuctionValue;
    } else {
      auctionValue = msg.value;
    }

    gameLastAuctionMoney = auctionValue;
    _inMoney(auctionValue);
    gameLastAuctionTime = block.timestamp;

    uint256 random = getRandom();
    gameSecondLeft = random * (_getMaxAuctionSeconds() - _getMinAuctionSeconds()) / 100 + _getMinAuctionSeconds();

    PlayerAuction memory p;
    gameAuction[gameId].push(p);
    gameAuction[gameId][gameAuction[gameId].length - 1].addr = msg.sender;
    gameAuction[gameId][gameAuction[gameId].length - 1].money = msg.value;
    gameAuction[gameId][gameAuction[gameId].length - 1].bid = auctionValue;
    gameAuction[gameId][gameAuction[gameId].length - 1].refunded = false;
    gameAuction[gameId][gameAuction[gameId].length - 1].dividended = false;

    emit GameAuction(gameId, msg.sender, msg.value, auctionValue, gameSecondLeft, block.timestamp);
  }

  function claimReward(uint256 _id) public {
    _claimReward(msg.sender, _id);
  }

  function _claimReward(address _addr, uint256 _id) internal {
    if (_id == gameId) {
      bool ended = (block.timestamp > gameLastAuctionTime + gameSecondLeft) ? true: false;
      if (ended == false)
        revert('game is still on, cannot claim reward');
    }

    uint _reward = 0;
    uint _dividends = 0;
    uint _myMoney = 0;
    uint _myDividends = 0;
    uint _myRefund = 0;
    uint _myReward = 0;
    bool _claimed = false;
    (_myMoney, _myDividends, _myRefund, _myReward, _claimed) = _getGameInfoPart1(_addr, _id);
    (_reward, _dividends) = _getGameInfoPart2(_id);

    if (_claimed)
      revert('already claimed!');

    for (uint k = 0; k < gameAuction[_id].length; k++) {
      if (gameAuction[_id][k].addr == _addr) {
        gameAuction[_id][k].dividended = true;
      }
    }

    _addr.transfer(_myDividends + _myRefund + _myReward); 
    emit GameRewardClaim(_id, _addr, _myDividends + _myRefund + _myReward);
  }

   
  function refund() public {
    uint256 len = gameAuction[gameId].length;
    if (len > 1) {
      if (msg.sender != gameAuction[gameId][len - 2].addr
        && msg.sender != gameAuction[gameId][len - 1].addr) {

        uint256 money = 0;

        for (uint k = 0; k < gameAuction[gameId].length; k++) {
          if (gameAuction[gameId][k].addr == msg.sender && gameAuction[gameId][k].refunded == false) {
            money = money + gameAuction[gameId][k].bid * 85 / 100 + gameAuction[gameId][k].money;
            gameAuction[gameId][k].refunded = true;
          }
        }

        msg.sender.transfer(money); 
        emit GameRewardRefund(gameId, msg.sender, money);
      } else {
        revert('cannot refund because you are no.2 bidder');
      }
    }   
  }


   
  function gameRoundEnd() public {
    bool ended = (block.timestamp > gameLastAuctionTime + gameSecondLeft) ? true: false;
    if (ended == false)
      revert("game cannot end");

    uint256 len = gameAuction[gameId].length;
    address winner = gameAuction[gameId][len - 1].addr;

    GameData memory d;
    gameData.push(d);
    gameData[gameData.length - 1].gameId = gameId;
    gameData[gameData.length - 1].reward = reward;
    gameData[gameData.length - 1].dividends = dividends;

    _startNewRound(msg.sender);

    _claimReward(msg.sender, gameId - 1);

    emit GameEnd(gameId - 1, winner, gameData[gameData.length - 1].reward, block.timestamp);
  }

  function getCurrCanRefund() public view returns (bool) {

    if (gameAuction[gameId].length > 1) {
      if (msg.sender == gameAuction[gameId][gameAuction[gameId].length - 2].addr) {
        return false;
      } else if (msg.sender == gameAuction[gameId][gameAuction[gameId].length - 1].addr) {
        return false;
      }
      return true;
    } else {
      return false;
    }
  }

  function getCurrGameInfo() public view returns (uint256 _gameId, 
                                                          uint256 _reward, 
                                                          uint256 _dividends,
                                                          uint256 _lastAuction, 
                                                          uint256 _gap, 
                                                          uint256 _lastAuctionTime,
                                                          uint256 _secondsLeft, 
                                                          uint256 _myMoney,
                                                          uint256 _myDividends,
                                                          uint256 _myRefund,
                                                          bool _ended) {
    _gameId = gameId;

    _reward = reward;
    _dividends = dividends;
    _lastAuction = gameLastAuctionMoney;
    _gap = _getGameAuctionGap();
    _lastAuctionTime = gameLastAuctionTime;
    _secondsLeft = gameSecondLeft;
    _ended = (block.timestamp > _lastAuctionTime + _secondsLeft) ? true: false;

    uint256 _moneyForCal = 0;

    if (gameAuction[gameId].length > 1) {

      uint256 totalMoney = 0;

      for (uint256 i = 0; i < gameAuction[gameId].length; i++) {
        if (gameAuction[gameId][i].addr == msg.sender && gameAuction[gameId][i].dividended == true) {

        }

        if (gameAuction[gameId][i].addr == msg.sender && gameAuction[gameId][i].refunded == false) {

          if ((i == gameAuction[gameId].length - 2) || (i == gameAuction[gameId].length - 1)) {
            _myRefund = _myRefund.add(gameAuction[gameId][i].money).sub(gameAuction[gameId][i].bid);
          } else {
            _myRefund = _myRefund.add(gameAuction[gameId][i].money).sub(gameAuction[gameId][i].bid.mul(15).div(100));
          }

          _myMoney = _myMoney + gameAuction[gameId][i].money;

          _moneyForCal = _moneyForCal.add((gameAuction[gameId][i].money.div(10**15)).mul(gameAuction[gameId][i].money.div(10**15)).mul(gameAuction[gameId].length + 1 - i));
        }

        if (gameAuction[gameId][i].refunded == false) {
          totalMoney = totalMoney.add((gameAuction[gameId][i].money.div(10**15)).mul(gameAuction[gameId][i].money.div(10**15)).mul(gameAuction[gameId].length + 1 - i));
        }
      }

      if (totalMoney != 0)
        _myDividends = _moneyForCal.mul(_dividends).div(totalMoney);
    }
  }

  function getGameDataByIndex(uint256 _index) public view returns (uint256 _id, uint256 _reward, uint256 _dividends) {
    uint256 len = gameData.length;
    if (len >= (_index + 1)) {
      GameData memory d = gameData[_index];
      _id = d.gameId;
      _reward = d.reward;
      _dividends = d.dividends;
    }
  }

  function getGameInfo(uint256 _id) public view returns (uint256 _reward, uint256 _dividends, uint256 _myMoney, uint256 _myDividends, uint256 _myRefund, uint256 _myReward, bool _claimed) {
    (_reward, _dividends) = _getGameInfoPart2(_id);
    (_myMoney, _myRefund, _myDividends, _myReward, _claimed) = _getGameInfoPart1(msg.sender, _id);
  }

  function _getGameInfoPart1(address _addr, uint256 _id) internal view returns (uint256 _myMoney, uint256 _myRefund, uint256 _myDividends, uint256 _myReward, bool _claimed) {
    uint256 totalMoney = 0;
    uint k = 0;

    if (_id == gameId) {
     
    } else {

      for (uint256 i = 0; i < gameData.length; i++) {
        GameData memory d = gameData[i];
        if (d.gameId == _id) {

          if (gameAuction[d.gameId].length > 1) {

             
            if (gameAuction[d.gameId][gameAuction[d.gameId].length - 1].addr == _addr) {
               
              _myReward = d.reward;

              _myReward = _myReward + gameAuction[d.gameId][gameAuction[d.gameId].length - 2].bid;
            }

             
             

            totalMoney = 0;
            uint256 _moneyForCal = 0;

            for (k = 0; k < gameAuction[d.gameId].length; k++) {

              if (gameAuction[d.gameId][k].addr == _addr && gameAuction[d.gameId][k].dividended == true) {
                _claimed = true;
              }

               
              if (gameAuction[d.gameId][k].addr == _addr && gameAuction[d.gameId][k].refunded == false && k != (gameAuction[d.gameId].length - 2)) {
                _myRefund = _myRefund.add( gameAuction[d.gameId][k].money.sub( gameAuction[d.gameId][k].bid.mul(15).div(100) ) );
                _moneyForCal = _moneyForCal.add( (gameAuction[d.gameId][k].money.div(10**15)).mul( gameAuction[d.gameId][k].money.div(10**15) ).mul( gameAuction[d.gameId].length + 1 - k) );
                _myMoney = _myMoney.add(gameAuction[d.gameId][k].money);
              }

              if (gameAuction[d.gameId][k].refunded == false && k != (gameAuction[d.gameId].length - 2)) {
                totalMoney = totalMoney.add( ( gameAuction[d.gameId][k].money.div(10**15) ).mul( gameAuction[d.gameId][k].money.div(10**15) ).mul( gameAuction[d.gameId].length + 1 - k) );
              }
            }

            if (totalMoney != 0)
              _myDividends = d.dividends.mul(_moneyForCal).div(totalMoney);

          }
  
          break;
        }
      }
    } 
  }

  function _getGameInfoPart2(uint256 _id) internal view returns (uint256 _reward, uint256 _dividends) {
    if (_id == gameId) {
     
    } else {
      for (uint256 i = 0; i < gameData.length; i++) {
        GameData memory d = gameData[i];
        if (d.gameId == _id) {
          _reward = d.reward;
          _dividends = d.dividends;
          break;
        }
      }
    }
  }

   

  function _getGameStartAuctionMoney() internal pure returns (uint256) {
    return 10**15;
  }

  function _getGameAuctionGap() internal view returns (uint256) {
    if (gameLastAuctionMoney < 10**18) {
      return 10**15;
    }

    uint256 n = 17;
    for (n = 18; n < 200; n ++) {
      if (gameLastAuctionMoney >= 10**n && gameLastAuctionMoney < 10**(n + 1)) {
        break;
      }
    }

    return 10**(n-2);
  }

  function _getMinAuctionSeconds() internal pure returns (uint256) {
    return 15 * 60;
     
  }

  function _getMaxAuctionSeconds() internal pure returns (uint256) {
    return 30 * 60;
     
  }

  function _getInitAuctionSeconds() internal pure returns (uint256) {
    return 3 * 24 * 60 * 60;
  }

   
  function _getMinAuctionStartPrice() internal view returns (uint256) {
    if (reward < 10**18) {
      return 10**15;
    }

    uint256 n = 17;
    for (n = 18; n < 200; n ++) {
      if (reward >= 10**n && reward < 10**(n + 1)) {
        break;
      }
    }

    return 10**(n-2);
  }

}