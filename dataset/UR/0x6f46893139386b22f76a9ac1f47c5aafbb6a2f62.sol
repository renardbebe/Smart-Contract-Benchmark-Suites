 

pragma solidity ^0.4.24;

 

 
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
   
  function sqrt(uint256 x)
    internal
    pure
    returns (uint256 y)
  {
    uint256 z = ((add(x,1)) / 2);
    y = x;
    while (z < y)
    {
        y = z;
        z = ((add((x / z),z)) / 2);
    }
  }

   
  function sq(uint256 x)
    internal
    pure
    returns (uint256)
  {
    return (mul(x,x));
  }

   
  function pwr(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
  {
    if (x==0)
        return (0);
    else if (y==0)
        return (1);
    else
    {
        uint256 z = x;
        for (uint256 i=1; i < y; i++)
            z = mul(z,x);
        return (z);
    }
  }
}

 

library CKingCal {

  using SafeMath for *;
   
  function keysRec(uint256 _curEth, uint256 _newEth)
    internal
    pure
    returns (uint256)
  {
    return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
  }

   
  function ethRec(uint256 _curKeys, uint256 _sellKeys)
    internal
    pure
    returns (uint256)
  {
    return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
  }

   
  function keys(uint256 _eth)
    internal
    pure
    returns(uint256)
  {
       
      return ((((((_eth).mul(1000000000000000000)).mul(31250000000000000000000000)).add(56249882812561035156250000000000000000000000000000000000000000)).sqrt()).sub(7499992187500000000000000000000)) / (15625000);
  }  

   
  function eth(uint256 _keys)
    internal
    pure
    returns(uint256)
  {
     
    return ((7812500).mul(_keys.sq()).add(((14999984375000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
  }
}

 

 
contract Ownable {
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

 

contract CKing is Ownable {
  using SafeMath for *;
  using CKingCal for uint256;


  string constant public name = "Cryptower";
  string constant public symbol = "CT";

   
  uint256 constant private timeInit = 1 weeks;  
  uint256 constant private timeInc = 30 seconds;  
  uint256 constant private timeMax = 30 minutes;  

   
  uint256 constant private fixRet = 46;
  uint256 constant private extraRet = 10;
  uint256 constant private affRet = 10;
  uint256 constant private gamePrize = 12;
  uint256 constant private groupPrize = 12;
  uint256 constant private devTeam = 10;

   
  struct Player {
    address addr;  
    string name;  
    uint256 aff;   
    uint256 affId;  
    uint256 hretKeys;  
    uint256 mretKeys;  
    uint256 lretKeys;  
    uint256 eth;       
    uint256 ethWithdraw;  
  }

  mapping(uint256 => Player) public players;  
  mapping(address => uint) public addrXpId;  
  uint public playerNum = 0;

   
  uint256 public totalEther;      
  uint256 public totalKeys;       
  uint256 private constant minPay = 1000000000;  
  uint256 public totalCommPot;    
  uint256 private keysForGame;     
  uint256 private gamePot;         
  uint256 public teamWithdrawed;  
  uint256 public gameWithdrawed;  
  uint256 public endTime;         
  address public CFO;
  address public COO; 
  address public fundCenter; 
  address public playerBook; 



  uint private stageId = 1;    
  uint private constant groupPrizeStartAt = 2000000000000000000000000;  
  uint private constant groupPrizeStageGap = 100000000000000000000000;  
  mapping(uint => mapping(uint => uint)) public stageInfo;  

   
  uint256 public startTime;   
  uint256 constant private coolDownTime = 2 days;  

  modifier isGameActive() {
    uint _now = now;
    require(_now > startTime && _now < endTime);
    _;
  }
  
  modifier onlyCOO() {
    require(COO == msg.sender, "Only COO can operate.");
    _; 
  }

   
  event BuyKey(uint indexed _pID, uint _affId, uint _keyType, uint _keyAmount);
  event EarningWithdraw(uint indexed _pID, address _addr, uint _amount);


  constructor(address _CFO, address _COO, address _fundCenter, address _playerBook) public {
    CFO = _CFO;
    COO = _COO; 
    fundCenter = _fundCenter; 
    playerBook = _playerBook; 
  }
    
  function setCFO(address _CFO) onlyOwner public {
    CFO = _CFO; 
  }  
  
  function setCOO(address _COO) onlyOwner public {
    COO = _COO; 
  }  
  
  function setContractAddress(address _fundCenter, address _playerBook) onlyCOO public {
    fundCenter = _fundCenter; 
    playerBook = _playerBook; 
  }

  function startGame(uint _startTime) onlyCOO public {
    require(_startTime > now);
    startTime = _startTime;
    endTime = startTime.add(timeInit);
  }
  
  function gameWithdraw(uint _amount) onlyCOO public {
     
    uint _total = getTotalGamePot(); 
    uint _remainingBalance = _total.sub(gameWithdrawed); 
    
    if(_amount > 0) {
      require(_amount <= _remainingBalance);
    } else{
      _amount = _remainingBalance;
    }
    
    fundCenter.transfer(_amount); 
    gameWithdrawed = gameWithdrawed.add(_amount); 
  }


  function teamWithdraw(uint _amount) onlyCOO public {
    uint256 _now = now;
    if(_now > endTime.add(coolDownTime)) {
       
       
      CFO.transfer(_amount);
      teamWithdrawed = teamWithdrawed.add(_amount); 
    } else {
        uint _total = totalEther.mul(devTeam).div(100); 
        uint _remainingBalance = _total.sub(teamWithdrawed); 
        
        if(_amount > 0) {
            require(_amount <= _remainingBalance);
        } else{
            _amount = _remainingBalance;
        }
        CFO.transfer(_amount);
        teamWithdrawed = teamWithdrawed.add(_amount); 
    }
  }
  

  function updateTimer(uint256 _keys) private {
    uint256 _now = now;
    uint256 _newTime;

    if(endTime.sub(_now) < timeMax) {
        _newTime = ((_keys) / (1000000000000000000)).mul(timeInc).add(endTime);
        if(_newTime.sub(_now) > timeMax) {
            _newTime = _now.add(timeMax);
        }
        endTime = _newTime;
    }
  }
  
  function receivePlayerInfo(address _addr, string _name) external {
    require(msg.sender == playerBook, "must be from playerbook address"); 
    uint _pID = addrXpId[_addr];
    if(_pID == 0) {  
        playerNum = playerNum + 1;
        Player memory p; 
        p.addr = _addr;
        p.name = _name; 
        players[playerNum] = p; 
        _pID = playerNum; 
        addrXpId[_addr] = _pID;
    } else {
        players[_pID].name = _name; 
    }
  }

  function buyByAddress(uint256 _affId, uint _keyType) payable isGameActive public {
    uint _pID = addrXpId[msg.sender];
    if(_pID == 0) {  
      playerNum = playerNum + 1;
      Player memory p;
      p.addr = msg.sender;
      p.affId = _affId;
      players[playerNum] = p;
      _pID = playerNum;
      addrXpId[msg.sender] = _pID;
    }
    buy(_pID, msg.value, _affId, _keyType);
  }

  function buyFromVault(uint _amount, uint256 _affId, uint _keyType) public isGameActive  {
    uint _pID = addrXpId[msg.sender];
    uint _earning = getPlayerEarning(_pID);
    uint _newEthWithdraw = _amount.add(players[_pID].ethWithdraw);
    require(_newEthWithdraw < _earning);  
    players[_pID].ethWithdraw = _newEthWithdraw;  
    buy(_pID, _amount, _affId, _keyType);
  }

  function getKeyPrice(uint _keyAmount) public view returns(uint256) {
    if(now > startTime) {
      return totalKeys.add(_keyAmount).ethRec(_keyAmount);
    } else {  
      return (7500000000000);
    }
  }

  function buy(uint256 _pID, uint256 _eth, uint256 _affId, uint _keyType) private {

    if (_eth > minPay) {  
      players[_pID].eth = _eth.add(players[_pID].eth);
      uint _keys = totalEther.keysRec(_eth);
       
      if(_keys >= 1000000000000000000) {
        updateTimer(_keys);
      }

       
      totalEther = totalEther.add(_eth);
      totalKeys = totalKeys.add(_keys);
       
      uint256 _game = _eth.mul(gamePrize).div(100);
      gamePot = _game.add(gamePot);


       
      if(_keyType == 1) {  
        players[_pID].hretKeys  = _keys.add(players[_pID].hretKeys);
      } else if (_keyType == 2) {
        players[_pID].mretKeys = _keys.add(players[_pID].mretKeys);
        keysForGame = keysForGame.add(_keys.mul(extraRet).div(fixRet+extraRet));
      } else if (_keyType == 3) {
        players[_pID].lretKeys = _keys.add(players[_pID].lretKeys);
        keysForGame = keysForGame.add(_keys);
      } else {  
        revert();
      }
       
      if(_affId != 0 && _affId != _pID && _affId <= playerNum) {  
          uint256 _aff = _eth.mul(affRet).div(100);
          players[_affId].aff = _aff.add(players[_affId].aff);
          totalCommPot = (_eth.mul(fixRet+extraRet).div(100)).add(totalCommPot);
      } else {  
          totalCommPot = (_eth.mul(fixRet+extraRet+affRet).div(100)).add(totalCommPot);
      }
       
      if(totalKeys > groupPrizeStartAt) {
        updateStageInfo(_pID, _keys);
      }
      emit BuyKey(_pID, _affId, _keyType, _keys);
    } else {  
      players[_pID].aff = _eth.add(players[_pID].aff);
    }
  }

  function updateStageInfo(uint _pID, uint _keyAmount) private {
    uint _stageL = groupPrizeStartAt.add(groupPrizeStageGap.mul(stageId - 1));
    uint _stageH = groupPrizeStartAt.add(groupPrizeStageGap.mul(stageId));
    if(totalKeys > _stageH) {  
      stageId = (totalKeys.sub(groupPrizeStartAt)).div(groupPrizeStageGap) + 1;
      _keyAmount = (totalKeys.sub(groupPrizeStartAt)) % groupPrizeStageGap;
      stageInfo[stageId][_pID] = stageInfo[stageId][_pID].add(_keyAmount);
    } else {
      if(_keyAmount < totalKeys.sub(_stageL)) {
        stageInfo[stageId][_pID] = stageInfo[stageId][_pID].add(_keyAmount);
      } else {
        _keyAmount = totalKeys.sub(_stageL);
        stageInfo[stageId][_pID] = stageInfo[stageId][_pID].add(_keyAmount);
      }
    }
  }

  function withdrawEarning(uint256 _amount) public {
    address _addr = msg.sender;
    uint256 _pID = addrXpId[_addr];
    require(_pID != 0);   

    uint _earning = getPlayerEarning(_pID);
    uint _remainingBalance = _earning.sub(players[_pID].ethWithdraw);
    if(_amount > 0) {
      require(_amount <= _remainingBalance);
    }else{
      _amount = _remainingBalance;
    }


    _addr.transfer(_amount);   
    players[_pID].ethWithdraw = players[_pID].ethWithdraw.add(_amount);
  }

  function getPlayerEarning(uint256 _pID) view public returns (uint256) {
    Player memory p = players[_pID];
    uint _gain = totalCommPot.mul(p.hretKeys.add(p.mretKeys.mul(fixRet).div(fixRet+extraRet))).div(totalKeys);
    uint _total = _gain.add(p.aff);
    _total = getWinnerPrize(_pID).add(_total);
    return _total;
  }

  function getPlayerWithdrawEarning(uint _pid) public view returns(uint){
    uint _earning = getPlayerEarning(_pid);
    return _earning.sub(players[_pid].ethWithdraw);
  }

  function getWinnerPrize(uint256 _pID) view public returns (uint256) {
    uint _keys;
    uint _pKeys;
    if(now < endTime) {
      return 0;
    } else if(totalKeys > groupPrizeStartAt) {  
      _keys = totalKeys.sub(groupPrizeStartAt.add(groupPrizeStageGap.mul(stageId - 1)));
      _pKeys = stageInfo[stageId][_pID];
      return totalEther.mul(groupPrize).div(100).mul(_pKeys).div(_keys);
    } else {  
      Player memory p = players[_pID];
      _pKeys = p.hretKeys.add(p.mretKeys).add(p.lretKeys);
      return totalEther.mul(groupPrize).div(100).mul(_pKeys).div(totalKeys);
    }
  }

  function getWinningStageInfo() view public returns (uint256 _stageId, uint256 _keys, uint256 _amount) {
    _amount = totalEther.mul(groupPrize).div(100);
    if(totalKeys < groupPrizeStartAt) {  
      return (0, totalKeys, _amount);
    } else {
      _stageId = stageId;
      _keys = totalKeys.sub(groupPrizeStartAt.add(groupPrizeStageGap.mul(stageId - 1)));
      return (_stageId, _keys, _amount);
    }
  }

  function getPlayerStageKeys() view public returns (uint256 _stageId, uint _keys, uint _pKeys) {
    uint _pID = addrXpId[msg.sender];
    if(totalKeys < groupPrizeStartAt) {
      Player memory p = players[_pID];
      _pKeys = p.hretKeys.add(p.mretKeys).add(p.lretKeys);
      return (0, totalKeys, _pKeys);
    } else {
      _stageId = stageId;
      _keys = totalKeys.sub(groupPrizeStartAt.add(groupPrizeStageGap.mul(stageId - 1)));
      _pKeys = stageInfo[_stageId][_pID];
      return (_stageId, _keys, _pKeys);
    }

  }

  function getTotalGamePot() view public returns (uint256) {
    uint _gain = totalCommPot.mul(keysForGame).div(totalKeys);
    uint _total = _gain.add(gamePot);
    return _total;
  }
  
}