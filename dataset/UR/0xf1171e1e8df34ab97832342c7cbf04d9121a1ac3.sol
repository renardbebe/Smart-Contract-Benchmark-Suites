 

pragma solidity ^0.4.24;

 
 
 
contract CSportsConstants {

     
     
    uint16 public MAX_MARKETING_TOKENS = 2500;

     
     
     
    uint256 public COMMISSIONER_AUCTION_FLOOR_PRICE = 5 finney;  

     
    uint256 public COMMISSIONER_AUCTION_DURATION = 14 days;  

     
    uint32 constant WEEK_SECS = 1 weeks;

}

 
 
 
contract CSportsAuth is CSportsConstants {
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    address public commissionerAddress;

     
    bool public paused = false;

     
     
    bool public isDevelopment = true;

     
    modifier onlyUnderDevelopment() {
      require(isDevelopment == true);
      _;
    }

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

     
    modifier onlyCommissioner() {
        require(msg.sender == commissionerAddress);
        _;
    }

     
    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == commissionerAddress
        );
        _;
    }

     
    modifier notContract() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0);
        _;
    }

     
     
     
     
     
    function setProduction() public onlyCEO onlyUnderDevelopment {
      isDevelopment = false;
    }

     
     
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

     
     
    function setCFO(address _newCFO) public onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

     
     
    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     
     
    function setCommissioner(address _newCommissioner) public onlyCEO {
        require(_newCommissioner != address(0));

        commissionerAddress = _newCommissioner;
    }

     
     
     
     
     
    function setCLevelAddresses(address _ceo, address _cfo, address _coo, address _commish) public onlyCEO {
        require(_ceo != address(0));
        require(_cfo != address(0));
        require(_coo != address(0));
        require(_commish != address(0));
        ceoAddress = _ceo;
        cfoAddress = _cfo;
        cooAddress = _coo;
        commissionerAddress = _commish;
    }

     
    function withdrawBalance() external onlyCFO {
        cfoAddress.transfer(address(this).balance);
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() public onlyCLevel whenNotPaused {
        paused = true;
    }

     
     
     
    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}

 
 
 
contract CSportsContestBase {

     
    struct Team {
      address owner;               
      int32 score;                 
      uint32 place;                
      bool holdsEntryFee;          
      bool ownsPlayerTokens;       
      uint32[] playerTokenIds;     
    }

}

 
 
 
 
contract CSportsTeam {

    bool public isTeamContract;

     
    event TeamCreated(uint256 teamId, address owner);
    event TeamUpdated(uint256 teamId);
    event TeamReleased(uint256 teamId);
    event TeamScored(uint256 teamId, int32 score, uint32 place);
    event TeamPaid(uint256 teamId);

    function setCoreContractAddress(address _address) public;
    function setLeagueRosterContractAddress(address _address) public;
    function setContestContractAddress(address _address) public;
    function createTeam(address _owner, uint32[] _tokenIds) public returns (uint32);
    function updateTeam(address _owner, uint32 _teamId, uint8[] _indices, uint32[] _tokenIds) public;
    function releaseTeam(uint32 _teamId) public;
    function getTeamOwner(uint32 _teamId) public view returns (address);
    function scoreTeams(uint32[] _teamIds, int32[] _scores, uint32[] _places) public;
    function getScore(uint32 _teamId) public view returns (int32);
    function getPlace(uint32 _teamId) public view returns (uint32);
    function ownsPlayerTokens(uint32 _teamId) public view returns (bool);
    function refunded(uint32 _teamId) public;
    function tokenIdsForTeam(uint32 _teamId) public view returns (uint32, uint32[50]);
    function getTeam(uint32 _teamId) public view returns (
        address _owner,
        int32 _score,
        uint32 _place,
        bool _holdsEntryFee,
        bool _ownsPlayerTokens);
}

 
 
 
 
 
 
contract CSportsContest is CSportsAuth, CSportsContestBase {

  enum ContestStatus { Invalid, Active, Scoring, Paying, Paid, Canceled }
  enum PayoutKey { Invalid, WinnerTakeAll, FiftyFifty, TopTen }

   
  bool public isContestContract = true;

   
   
   
  CSportsTeam public teamContract;

   
   
   
  uint256 public ownerCut;

   
  struct Contest {
    address scoringOracleAddress;                  
    address creator;                               
    uint32 gameSetId;                              
    uint32 numWinners;                             
    uint32 winnersToPay;                           
    uint64 startTime;                              
    uint64 endTime;                                
    uint128 entryFee;                              
    uint128 prizeAmount;                           
    uint128 remainingPrizeAmount;                  
    uint64 maxMinEntries;                          
    ContestStatus status;                          
    PayoutKey payoutKey;                           
    uint32[] teamIds;                              
    string name;                                   
    mapping (uint32 => uint32) placeToWinner;      
    mapping (uint32 => uint32) teamIdToIdx;        
  }

   
  Contest[] public contests;

   
  mapping (uint32 => uint32) public teamIdToContestId;

   
   
  mapping (address => uint128) public authorizedUserPayment;

   
   
  uint128 public totalAuthorizedForPayment;

   
  event ContestCreated(uint256 contestId);
  event ContestCanceled(uint256 contestId);
  event ContestEntered(uint256 contestId, uint256 teamId);
  event ContestExited(uint256 contestId, uint256 teamId);
  event ContestClosed(uint32 contestId);
  event ContestTeamWinningsPaid(uint32 contestId, uint32 teamId, uint128 amount);
  event ContestTeamRefundPaid(uint32 contestId, uint32 teamId, uint128 amount);
  event ContestCreatorEntryFeesPaid(uint32 contestId, uint128 amount);
  event ContestApprovedFundsDelivered(address toAddress, uint128 amount);

   
  constructor(uint256 _cut) public {
      require(_cut <= 10000);
      ownerCut = _cut;

       
      ceoAddress = msg.sender;
      cfoAddress = msg.sender;
      cooAddress = msg.sender;
      commissionerAddress = msg.sender;

       
       
       
       
      Contest memory _contest = Contest({
          scoringOracleAddress: commissionerAddress,
          gameSetId: 0,
          maxMinEntries: 0,
          numWinners: 0,
          winnersToPay: 0,
          startTime: 0,
          endTime: 0,
          creator: msg.sender,
          entryFee: 0,
          prizeAmount: 0,
          remainingPrizeAmount: 0,
          status: ContestStatus.Canceled,
          payoutKey: PayoutKey(0),
          name: "mythical",
          teamIds: new uint32[](0)
        });

        contests.push(_contest);
  }

   
   
  function pause() public onlyCLevel whenNotPaused {
    paused = true;
  }

   
   
   
  function unpause() public onlyCEO whenPaused {
     
    paused = false;
  }

   
   
  function setTeamContractAddress(address _address) public onlyCEO {
    CSportsTeam candidateContract = CSportsTeam(_address);
    require(candidateContract.isTeamContract());
    teamContract = candidateContract;
  }

   
   
  function transferApprovedFunds() public {
    uint128 amount = authorizedUserPayment[msg.sender];
    if (amount > 0) {

       
       
       
      if (totalAuthorizedForPayment >= amount) {

         
        delete authorizedUserPayment[msg.sender];
        totalAuthorizedForPayment -= amount;
        msg.sender.transfer(amount);

         
        emit ContestApprovedFundsDelivered(msg.sender, amount);
      }
    }
  }

   
  function authorizedFundsAvailable() public view returns (uint128) {
    return authorizedUserPayment[msg.sender];
  }

   
   
   
  function getTotalAuthorizedForPayment() public view returns (uint128) {
    return totalAuthorizedForPayment;
  }

   
   
   
   
   
   
   
   
   
   
   
   
   
  function createContest
  (
    string _name,
    address _scoringOracleAddress,
    uint32 _gameSetId,
    uint64 _startTime,
    uint64 _endTime,
    uint128 _entryFee,
    uint128 _prizeAmount,
    uint32 _maxEntries,
    uint32 _minEntries,
    uint8 _payoutKey,
    uint32[] _tokenIds
  ) public payable whenNotPaused {

      require (msg.sender != address(0));
      require (_endTime > _startTime);
      require (_maxEntries != 1);
      require (_minEntries <= _maxEntries);
      require(_startTime > uint64(now));

       
      require((msg.sender == commissionerAddress) || (_tokenIds.length > 0));

       
      require(((_prizeAmount + _entryFee) >= _prizeAmount) && ((_prizeAmount + _entryFee) >= _entryFee));

       
       
      if (_tokenIds.length > 0) {
        require(msg.value == (_prizeAmount + _entryFee));
      } else {
        require(msg.value == _prizeAmount);
      }

       
      if (_scoringOracleAddress == address(0)) {
        _scoringOracleAddress = commissionerAddress;
      }

       
       

       
      Contest memory _contest = Contest({
          scoringOracleAddress: _scoringOracleAddress,
          gameSetId: _gameSetId,
          maxMinEntries: (uint64(_maxEntries) << 32) | uint64(_minEntries),
          numWinners: 0,
          winnersToPay: 0,
          startTime: _startTime,
          endTime: _endTime,
          creator: msg.sender,
          entryFee: _entryFee,
          prizeAmount: _prizeAmount,
          remainingPrizeAmount: _prizeAmount,
          status: ContestStatus.Active,
          payoutKey: PayoutKey(_payoutKey),
          name: _name,
          teamIds: new uint32[](0)
        });

       
      uint32 uniqueTeamId = 0;
      if (_tokenIds.length > 0) {
         
         
         
         
         
         
         
        uniqueTeamId = teamContract.createTeam(msg.sender, _tokenIds);

         
        require(uniqueTeamId < 4294967295);
        _contest.teamIds = new uint32[](1);
        _contest.teamIds[0] = uniqueTeamId;

         
         
         
         
         
         
      }

       
       
       
       
       
      uint256 _contestId = contests.push(_contest) - 1;
      require(_contestId < 4294967295);

       
      if (_tokenIds.length > 0) {
        teamIdToContestId[uniqueTeamId] = uint32(_contestId);
      }

       
      emit ContestCreated(_contestId);
      if (_tokenIds.length > 0) {
        emit ContestEntered(_contestId, uniqueTeamId);
      }
  }

   
   
   
   
  function enterContest(uint32 _contestId, uint32[] _tokenIds) public  payable whenNotPaused {

    require (msg.sender != address(0));
    require ((_contestId > 0) && (_contestId < contests.length));

     
    Contest storage _contestToEnter = contests[_contestId];
    require (_contestToEnter.status == ContestStatus.Active);
    require(_contestToEnter.startTime > uint64(now));

     
    require(msg.value >= _contestToEnter.entryFee);

     
    uint32 maxEntries = uint32(_contestToEnter.maxMinEntries >> 32);
    if (maxEntries > 0) {
      require(_contestToEnter.teamIds.length < maxEntries);
    }

     
     
     
    uint32 _newTeamId = teamContract.createTeam(msg.sender, _tokenIds);

     
    uint256 _teamIndex = _contestToEnter.teamIds.push(_newTeamId) - 1;
    require(_teamIndex < 4294967295);

     
    _contestToEnter.teamIdToIdx[_newTeamId] = uint32(_teamIndex);

     
    teamIdToContestId[_newTeamId] = uint32(_contestId);

     
    emit ContestEntered(_contestId, _newTeamId);

  }

   
   
  function exitContest(uint32 _teamId) public {

     
    address owner;
    int32 score;
    uint32 place;
    bool holdsEntryFee;
    bool ownsPlayerTokens;
    (owner, score, place, holdsEntryFee, ownsPlayerTokens) = teamContract.getTeam(_teamId);

     
    require (owner == msg.sender);

    uint32 _contestId = teamIdToContestId[_teamId];
    require(_contestId > 0);
    Contest storage _contestToExitFrom = contests[_contestId];

     
    require(_contestToExitFrom.startTime > uint64(now));

     
    if (holdsEntryFee) {
      teamContract.refunded(_teamId);
      if (_contestToExitFrom.entryFee > 0) {
        _authorizePayment(owner, _contestToExitFrom.entryFee);
        emit ContestTeamRefundPaid(_contestId, _teamId, _contestToExitFrom.entryFee);
      }
    }
    teamContract.releaseTeam(_teamId);   

     
     
     
     
     
     
     
     
     
     
    uint32 lastTeamIdx = uint32(_contestToExitFrom.teamIds.length) - 1;
    uint32 lastTeamId = _contestToExitFrom.teamIds[lastTeamIdx];
    uint32 toRemoveIdx = _contestToExitFrom.teamIdToIdx[_teamId];

    require(_contestToExitFrom.teamIds[toRemoveIdx] == _teamId);       

    _contestToExitFrom.teamIds[toRemoveIdx] = lastTeamId;              
                                                                       
    _contestToExitFrom.teamIdToIdx[lastTeamId] = toRemoveIdx;          

    delete _contestToExitFrom.teamIds[lastTeamIdx];                    
    _contestToExitFrom.teamIds.length--;                               
    delete _contestToExitFrom.teamIdToIdx[_teamId];                    

     
     
 
 
 
 
 
 
 
 
 
 
 

     
    delete teamIdToContestId[_teamId];

     
    emit ContestExited(_contestId, _teamId);
  }

   
   
   
   
  function cancelContest(uint32 _contestId) public {

    require(_contestId > 0);
    Contest storage _toCancel = contests[_contestId];

     
    require (_toCancel.status == ContestStatus.Active);

     
     
    if (_toCancel.startTime > uint64(now)) {
       
       
      require((msg.sender == _toCancel.creator) || (msg.sender == _toCancel.scoringOracleAddress));
    } else {
       
      if (_toCancel.teamIds.length >= uint32(_toCancel.maxMinEntries & 0x00000000FFFFFFFF)) {

         
         
        require(msg.sender == _toCancel.scoringOracleAddress);
      }
    }

     
     
     
     
     
     

     
    if (_toCancel.prizeAmount > 0) {
      _authorizePayment(_toCancel.creator, _toCancel.prizeAmount);
      _toCancel.remainingPrizeAmount = 0;
    }

     
     
     
    _toCancel.status = ContestStatus.Canceled;

     
    emit ContestCanceled(_contestId);
  }

   
   
   
   
   
   
  function releaseTeams(uint32 _contestId, uint32[] _teamIds) public {
    require((_contestId < contests.length) && (_contestId > 0));
    Contest storage c = contests[_contestId];

     
     
    require ((c.status == ContestStatus.Canceled) || (c.endTime <= uint64(now)));

    for (uint32 i = 0; i < _teamIds.length; i++) {
      uint32 teamId = _teamIds[i];
      uint32 teamContestId = teamIdToContestId[teamId];
      if (teamContestId == _contestId) {
        address owner;
        int32 score;
        uint32 place;
        bool holdsEntryFee;
        bool ownsPlayerTokens;
        (owner, score, place, holdsEntryFee, ownsPlayerTokens) = teamContract.getTeam(teamId);
        if ((c.status == ContestStatus.Canceled) && holdsEntryFee) {
          teamContract.refunded(teamId);
          if (c.entryFee > 0) {
            emit ContestTeamRefundPaid(_contestId, teamId, c.entryFee);
            _authorizePayment(owner, c.entryFee);
          }
        }
        if (ownsPlayerTokens) {
          teamContract.releaseTeam(teamId);
        }
      }
    }
  }

   
   
   
   
   
   
   
  function updateContestTeam(uint32 _contestId, uint32 _teamId, uint8[] _indices, uint32[] _tokenIds) public whenNotPaused {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require (c.status == ContestStatus.Active);

     
     
    require(c.startTime > uint64(now + 1 hours));

    teamContract.updateTeam(msg.sender, _teamId, _indices, _tokenIds);
  }

   
   
  function getContest(uint32 _contestId) public view returns (
    string name,                     
    address scoringOracleAddress,    
    uint32 gameSetId,                
    uint32 maxEntries,               
    uint64 startTime,                
    uint64 endTime,                  
    address creator,                 
    uint128 entryFee,                
    uint128 prizeAmount,             
    uint32 minEntries,               
    uint8 status,                    
    uint8 payoutKey,                 
    uint32 entryCount                
  )
  {
    require((_contestId > 0) && (_contestId < contests.length));

     
     
     

    Contest storage c = contests[_contestId];
    scoringOracleAddress = c.scoringOracleAddress;
    gameSetId = c.gameSetId;
    maxEntries = uint32(c.maxMinEntries >> 32);
    startTime = c.startTime;
    endTime = c.endTime;
    creator = c.creator;
    entryFee = c.entryFee;
    prizeAmount = c.prizeAmount;
    minEntries = uint32(c.maxMinEntries & 0x00000000FFFFFFFF);
    status = uint8(c.status);
    payoutKey = uint8(c.payoutKey);
    name = c.name;
    entryCount = uint32(c.teamIds.length);
  }

   
   
  function getContestTeamCount(uint32 _contestId) public view returns (uint32 count) {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    count = uint32(c.teamIds.length);
  }

   
   
   
  function getIndexForTeamId(uint32 _contestId, uint32 _teamId) public view returns (uint32 idx) {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    idx = c.teamIdToIdx[_teamId];

    require (idx < c.teamIds.length);   
    require(c.teamIds[idx] == _teamId);
  }

   
   
   
  function getContestTeam(uint32 _contestId, uint32 _teamIndex) public view returns (
    uint32 teamId,
    address owner,
    int score,
    uint place,
    bool holdsEntryFee,
    bool ownsPlayerTokens,
    uint32 count,
    uint32[50] playerTokenIds
  )
  {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require(_teamIndex < c.teamIds.length);

    uint32 _teamId = c.teamIds[_teamIndex];
    (teamId) = _teamId;
    (owner, score, place, holdsEntryFee, ownsPlayerTokens) = teamContract.getTeam(_teamId);
    (count, playerTokenIds) = teamContract.tokenIdsForTeam(_teamId);
  }

   
   
   
  function prepareToScore(uint32 _contestId) public {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require ((c.scoringOracleAddress == msg.sender) && (c.status == ContestStatus.Active) && (c.endTime <= uint64(now)));

     
    require (uint32(c.teamIds.length) >= uint32(c.maxMinEntries & 0x00000000FFFFFFFF));

    c.status = ContestStatus.Scoring;

     
    uint32 numWinners = 1;
    if (c.payoutKey == PayoutKey.TopTen) {
        numWinners = 10;
    } else if (c.payoutKey == PayoutKey.FiftyFifty) {
        numWinners = uint32(c.teamIds.length) / 2;
    }
    c.winnersToPay = numWinners;
    c.numWinners = numWinners;

     
     
     
    require(c.numWinners <= c.teamIds.length);
  }

   
   
   
   
   
   
   
   
   
   
  function scoreTeams(uint32 _contestId, uint32[] _teamIds, int32[] _scores, uint32[] _places, uint32 _startingPlaceOffset, uint32 _totalWinners) public {
    require ((_teamIds.length == _scores.length) && (_teamIds.length == _places.length));
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require ((c.scoringOracleAddress == msg.sender) && (c.status == ContestStatus.Scoring));

     
     
    for (uint32 i = 0; i < _places.length; i++) {
      uint32 teamId = _teamIds[i];

       
      uint32 contestIdForTeamBeingScored = teamIdToContestId[teamId];
      require(contestIdForTeamBeingScored == _contestId);

       
      if (c.prizeAmount > 0) {
        if ((_places[i] <= _totalWinners - _startingPlaceOffset) && (_places[i] > 0)) {
          c.placeToWinner[_places[i] + _startingPlaceOffset] = teamId;
        }
      }
    }

     
    teamContract.scoreTeams(_teamIds, _scores, _places);
  }

   
   
   
  function getWinningPosition(uint32 _teamId) public view returns (uint32) {
    uint32 _contestId = teamIdToContestId[_teamId];
    require(_contestId > 0);
    Contest storage c = contests[_contestId];
    for (uint32 i = 1; i <= c.teamIds.length; i++) {
      if (c.placeToWinner[i] == _teamId) {
        return i;
      }
    }
    return 0;
  }

   
   
   
   
  function prepareToPayWinners(uint32 _contestId) public {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require ((c.scoringOracleAddress == msg.sender) && (c.status == ContestStatus.Scoring) && (c.endTime < uint64(now)));
    c.status = ContestStatus.Paying;
  }

   
   
  function numWinnersToPay(uint32 _contestId) public view returns (uint32) {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest memory c = contests[_contestId];
    if (c.status == ContestStatus.Paying) {
      return c.winnersToPay;
    } else {
      return 0;
    }
  }

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  function payWinners(uint32 _contestId, uint32 _payingStartingIndex, uint _numToPay, bool _isFirstPlace, uint32 _prevTies, uint32 _nextTies) public {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require ((c.scoringOracleAddress == msg.sender) && (c.status == ContestStatus.Paying));

     
     
     
     
     
    uint32[] memory localVars = new uint32[](2);
    localVars[0] = _payingStartingIndex + 1;

     
     
     
     
     
     
     
     
     
    if (c.winnersToPay + _prevTies > 0) {
       
       
       
       
       
       
       
       
      uint32 s = (c.numWinners * (c.numWinners + 1)) / 2;
      uint128 m = c.prizeAmount / uint128(s);
      while ((c.winnersToPay + _prevTies > 0) && (_numToPay > 0)) {

        uint128 totalPayout = 0;
        uint32 totalNumWinnersWithTies = _prevTies;
        if (_prevTies > 0) {
           
           
          totalPayout = m*(_prevTies * c.winnersToPay + (_prevTies * (_prevTies + 1)) / 2);
        }

         
        localVars[1] = localVars[0];

         
         
        uint32 numProcessedThisTime = 0;
        while (teamContract.getScore(c.placeToWinner[localVars[1]]) == teamContract.getScore(c.placeToWinner[localVars[0]])) {

           
           
          if (c.winnersToPay > 0) {
            totalPayout += m*c.winnersToPay;
          }

           
          totalNumWinnersWithTies++;

           
          numProcessedThisTime++;

           
           
          if (c.winnersToPay > 0) {
            c.winnersToPay--;
          }

          localVars[1]++;
          _numToPay -= 1;
          if ((_numToPay == 0) || (c.placeToWinner[localVars[1]] == 0)) {
            break;
          }
        }

         
        if (_isFirstPlace) {
          totalPayout += c.prizeAmount - m * s;
        }
        _isFirstPlace = false;

         
         
        if ((_numToPay == 0) && (_nextTies > 0)) {
          totalNumWinnersWithTies += _nextTies;
          if (_nextTies < c.winnersToPay) {
            totalPayout += m*(_nextTies * (c.winnersToPay + 1) - (_nextTies * (_nextTies + 1)) / 2);
          } else {
            totalPayout += m*(c.winnersToPay * (c.winnersToPay + 1) - (c.winnersToPay * (c.winnersToPay + 1)) / 2);
          }
        }

         
        uint128 payout = totalPayout / totalNumWinnersWithTies;

         
         
         
        if (c.winnersToPay == 0) {
          payout = c.remainingPrizeAmount / (numProcessedThisTime + _nextTies);
        }

        for (uint32 i = _prevTies; (i < (numProcessedThisTime + _prevTies)) && (c.remainingPrizeAmount > 0); i++) {

           
           
          if (i == (totalNumWinnersWithTies - 1)) {
            if ((c.winnersToPay == 0) && (_nextTies == 0)) {
              payout = c.remainingPrizeAmount;
            } else {
              payout = totalPayout - (totalNumWinnersWithTies - 1)*payout;
            }
          }

           
           
          if (payout > c.remainingPrizeAmount) {
            payout = c.remainingPrizeAmount;
          }
          c.remainingPrizeAmount -= payout;

          _authorizePayment(teamContract.getTeamOwner(c.placeToWinner[localVars[0]]), payout);

           
          emit ContestTeamWinningsPaid(_contestId, c.placeToWinner[localVars[0]], payout);

           
          localVars[0]++;
        }

         
        _prevTies = 0;

      }
    }
  }

   
   
   
   
   
   
   
  function closeContest(uint32 _contestId) public {
    require((_contestId > 0) && (_contestId < contests.length));
    Contest storage c = contests[_contestId];
    require ((c.scoringOracleAddress == msg.sender) && (c.status == ContestStatus.Paying) && (c.winnersToPay == 0));

     
    c.status = ContestStatus.Paid;

    uint128 totalEntryFees = c.entryFee * uint128(c.teamIds.length);

     
    if (c.scoringOracleAddress == commissionerAddress) {
      uint128 cut = _computeCut(totalEntryFees);
      totalEntryFees -= cut;
      cfoAddress.transfer(cut);
    }

     
    if (totalEntryFees > 0) {
      _authorizePayment(c.creator, totalEntryFees);
      emit ContestCreatorEntryFeesPaid(_contestId, totalEntryFees);
    }

    emit ContestClosed(_contestId);
  }

   
   
   

   
   
   
  function _authorizePayment(address _to, uint128 _amount) private {
    totalAuthorizedForPayment += _amount;
    uint128 _currentlyAuthorized = authorizedUserPayment[_to];
    authorizedUserPayment[_to] = _currentlyAuthorized + _amount;
  }

   
   
  function _computeCut(uint128 _amount) internal view returns (uint128) {
       
       
       
       
       
      return uint128(_amount * ownerCut / 10000);
  }

}