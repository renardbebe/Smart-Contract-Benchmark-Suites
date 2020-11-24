 

pragma solidity ^0.4.26;

 
 
 
 
 
 

 
 

 
 

 
 

 
 
 

contract MakerOracle_ETHUSD {
  function peek() external view returns (uint256,bool);
}

contract Simple_Options {

   
  address public feeAddress;  
  uint256 public feePercent = 5000;  
  uint256 constant roundCutoff = 43200;  
  uint256 constant roundLength = 86400;  
  address constant makerOracle = 0x729D19f657BD0614b4985Cf1D82531c67569197B;  

   
  enum RoundStatus {
    OPEN,
    CLOSED,
    STALEPRICE,  
    NOCONTEST  
  }

  struct Round {
    uint256 roundNum;  
    RoundStatus roundStatus;  
    uint256 startPriceWei;  
    uint256 endPriceWei;  
    uint256 startTime;  
    uint256 endTime;  
    uint256 totalCallTickets;  
    uint256 totalCallPotWei;  
    uint256 totalPutTickets;  
    uint256 totalPutPotWei;  

    uint256 totalUsers;  
    mapping (uint256 => address) userList;
    mapping (address => User) users;
  }

  struct User {
    uint256 numCallTickets;
    uint256 numPutTickets;
    uint256 callBalanceWei;
    uint256 putBalanceWei;
  }

  mapping (uint256 => Round) roundList;  
  uint256 public currentRound = 0;  

  event ChangedFeeAddress(address _newFeeAddress);
  event FailedFeeSend(address _user, uint256 _amount);
  event FeeSent(address _user, uint256 _amount);
  event BoughtCallTickets(address _user, uint256 _ticketNum, uint256 _roundNum);
  event BoughtPutTickets(address _user, uint256 _ticketNum, uint256 _roundNum);
  event FailedPriceOracle();
  event StartedNewRound(uint256 _roundNum);

  constructor() public {
    feeAddress = msg.sender;  
  }

   
   
  function viewRoundInfo(uint256 _numRound) public view returns (
    uint256 _startPriceWei,
    uint256 _endPriceWei,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _totalCallPotWei,
    uint256 _totalPutPotWei,
    uint256 _totalCallTickets, 
    uint256 _totalPutTickets,
    RoundStatus _status
  ) {
    assert(_numRound <= currentRound);
    assert(_numRound >= 1);
    Round memory _round = roundList[_numRound];
    return (_round.startPriceWei, _round.endPriceWei, _round.startTime, _round.endTime, _round.totalCallPotWei, _round.totalPutPotWei, _round.totalCallTickets, _round.totalPutTickets, _round.roundStatus);
  }

   
  function viewUserInfo(uint256 _numRound, address _userAddress) public view returns (
    uint256 _numCallTickets,
    uint256 _numPutTickets,
    uint256 _balanceWei
  ) {
    assert(_numRound <= currentRound);
    assert(_numRound >= 1);
    Round storage _round = roundList[_numRound];
    User memory _user = _round.users[_userAddress];
    uint256 balance = _user.callBalanceWei + _user.putBalanceWei;
    return (_user.numCallTickets, _user.numPutTickets, balance);
  }

   
  function viewCurrentCost(uint256 _currentTime) public view returns (
    uint256 _cost
  ) {
    assert(currentRound > 0);
    Round memory _round = roundList[currentRound];
    uint256 startTime = _round.startTime;
    uint256 currentTime = _currentTime;
    assert(currentTime >= startTime);
    uint256 cost = calculateCost(startTime, currentTime);
    return (cost);
  }

   
   
  function changeContractFeeAddress(address _newFeeAddress) public {
    require (msg.sender == feeAddress);  
    
    feeAddress = _newFeeAddress;  

      
    emit ChangedFeeAddress(_newFeeAddress);
  }

   
   
  function startNewRound() public {
    if(currentRound == 0){
       
      Round memory _newRound;
      currentRound = currentRound + 1;
      _newRound.roundNum = currentRound;
      
       
      _newRound.startPriceWei = getOraclePrice(0,true);  

       
      _newRound.startTime = now;
      _newRound.endTime = _newRound.startTime + roundLength;  
      roundList[currentRound] = _newRound;

      emit StartedNewRound(currentRound);
    }else if(currentRound > 0){
       
      uint256 cTime = now;
      uint256 feeAmount = 0;
      Round storage _round = roundList[currentRound];
      require( cTime >= _round.endTime );  

       
      _round.endPriceWei = getOraclePrice(_round.startPriceWei, false);

      bool no_contest = false; 

       
      if( cTime - 180 > _round.endTime){  
        no_contest = true;
        _round.endTime = cTime;
        _round.roundStatus = RoundStatus.STALEPRICE;
      }

      if(_round.endPriceWei == _round.startPriceWei){
        no_contest = true;  
        _round.roundStatus = RoundStatus.NOCONTEST;
      }

      if(_round.totalPutTickets == 0 || _round.totalCallTickets == 0){
        no_contest = true;  
        _round.roundStatus = RoundStatus.NOCONTEST;
      }

      if(no_contest == false){
         
        uint256 addAmount = 0;
        uint256 it = 0;
        uint256 rewardPerTicket = 0;
        uint256 roundTotal = 0;
        if(_round.endPriceWei > _round.startPriceWei){
           
           
          roundTotal = _round.totalPutPotWei;  
          feeAmount = (roundTotal * feePercent) / 100000;  
          roundTotal = roundTotal - feeAmount;  
          uint256 putRemainBalance = roundTotal;    
          rewardPerTicket = roundTotal / _round.totalCallTickets;

          for(it = 0; it < _round.totalUsers; it++){  
            User storage _user = _round.users[_round.userList[it]];
            if(_user.numPutTickets > 0){
               
              _user.putBalanceWei = 0;
            }
            if(_user.numCallTickets > 0){
               
              addAmount = _user.numCallTickets * rewardPerTicket;
              if(addAmount > putRemainBalance){addAmount = putRemainBalance;}  
              _user.callBalanceWei = _user.callBalanceWei + addAmount;
              putRemainBalance = putRemainBalance - addAmount;
            }
          }
        }else{
           
           
          roundTotal = _round.totalCallPotWei;  
          feeAmount = (roundTotal * feePercent) / 100000;  
          roundTotal = roundTotal - feeAmount;  
          uint256 callRemainBalance = roundTotal;    
          rewardPerTicket = roundTotal / _round.totalPutTickets;

          for(it = 0; it < _round.totalUsers; it++){  
            User storage _user2 = _round.users[_round.userList[it]];
            if(_user2.numCallTickets > 0){
               
              _user2.callBalanceWei = 0;
            }
            if(_user2.numPutTickets > 0){
               
              addAmount = _user2.numPutTickets * rewardPerTicket;
              if(addAmount > callRemainBalance){addAmount = callRemainBalance;}  
              _user2.putBalanceWei = _user2.putBalanceWei + addAmount;
              callRemainBalance = callRemainBalance - addAmount;
            }
          }
        }

         
        _round.roundStatus = RoundStatus.CLOSED;
      }

       
       
      Round memory _nextRound;
      currentRound = currentRound + 1;
      _nextRound.roundNum = currentRound;
      
       
      _nextRound.startPriceWei = _round.endPriceWei;

       
      _nextRound.startTime = _round.endTime;  
      _nextRound.endTime = _nextRound.startTime + roundLength;  
      roundList[currentRound] = _nextRound;

       
      if(feeAmount > 0){
        bool sentfee = feeAddress.send(feeAmount);
        if(sentfee == false){
          emit FailedFeeSend(feeAddress, feeAmount);  
        }else{
          emit FeeSent(feeAddress, feeAmount);  
        }
      }

      emit StartedNewRound(currentRound);
    }
  }

   
  function buyCallTickets() public payable {
    buyTickets(0);
  }

   
  function buyPutTickets() public payable {
    buyTickets(1);
  }

   
   
  function withdrawFunds(uint256 roundNum) public {
    require( roundNum > 0 && roundNum < currentRound);  
    Round storage _round = roundList[roundNum];
    require( _round.roundStatus != RoundStatus.OPEN );  
    User storage _user = _round.users[msg.sender];
    uint256 balance = _user.callBalanceWei + _user.putBalanceWei;
    require( _user.callBalanceWei + _user.putBalanceWei > 0);  
    _user.callBalanceWei = 0;
    _user.putBalanceWei = 0;
    msg.sender.transfer(balance);  
  }

   
  function calculateCost(uint256 startTime, uint256 currentTime) private pure returns (uint256 _weiCost){
    uint256 timediff = currentTime - startTime;
    uint256 chour = timediff / 3600;
    uint256 cost = 10000000000000000;  
    cost = cost + 90000000000000000 * chour;  
    return cost;
  }

   
  function getOraclePrice(uint256 _currentPrice, bool required) private returns (uint256 _price){
    MakerOracle_ETHUSD oracle = MakerOracle_ETHUSD(makerOracle);
    (uint256 price, bool ok) = oracle.peek();  

    if(ok == true){
      return price;
    }else{
      if(required == false){
         
         
        emit FailedPriceOracle();
        return _currentPrice;       
      }else{
         
        revert();
      }
    }
  }

  function buyTickets(uint256 ticketType) private {
    require( currentRound > 0 );  
    Round storage _round = roundList[currentRound];
    uint256 endTime = _round.endTime;
    uint256 startTime = _round.startTime;
    uint256 currentTime = now;
    require( currentTime <= endTime - roundCutoff);  
    uint256 currentCost = calculateCost(startTime, currentTime);  
    require(msg.value % currentCost == 0);  
    require(msg.value >= currentCost);  
    require(_round.totalUsers <= 1000);  
    require(_round.roundStatus == RoundStatus.OPEN);  
    
    uint256 numTickets = msg.value / currentCost;  

     
    User memory _user = _round.users[msg.sender];
    if(_user.numCallTickets + _user.numPutTickets == 0){
       
      _round.userList[_round.totalUsers] = msg.sender;
      _round.totalUsers = _round.totalUsers + 1;
    }

    if(ticketType == 0){
       
      _user.numCallTickets = _user.numCallTickets + numTickets;
      _user.callBalanceWei = _user.callBalanceWei + msg.value;
      _round.totalCallTickets = _round.totalCallTickets + numTickets;
      _round.totalCallPotWei = _round.totalCallPotWei + msg.value;

      emit BoughtCallTickets(msg.sender, numTickets, currentRound);
    }else{
       
      _user.numPutTickets = _user.numPutTickets + numTickets;
      _user.putBalanceWei = _user.putBalanceWei + msg.value;
      _round.totalPutTickets = _round.totalPutTickets + numTickets;
      _round.totalPutPotWei = _round.totalPutPotWei + msg.value;

      emit BoughtPutTickets(msg.sender, numTickets, currentRound);
    }

    _round.users[msg.sender] = _user;  
  }
}