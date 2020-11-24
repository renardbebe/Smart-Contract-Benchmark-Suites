 

pragma solidity ^0.4.25;

 
 
interface CSportsRosterInterface {

     
    function isLeagueRosterContract() external pure returns (bool);

     
    function commissionerAuctionComplete(uint32 _rosterIndex, uint128 _price) external;

     
    function commissionerAuctionCancelled(uint32 _rosterIndex) external view;

     
    function getMetadata(uint128 _md5Token) external view returns (string);

     
    function getRealWorldPlayerRosterIndex(uint128 _md5Token) external view returns (uint128);

     
    function realWorldPlayerFromIndex(uint128 idx) external view returns (uint128 md5Token, uint128 prevCommissionerSalePrice, uint64 lastMintedTime, uint32 mintedCount, bool hasActiveCommissionerAuction, bool mintingEnabled);

     
    function updateRealWorldPlayer(uint32 _rosterIndex, uint128 _prevCommissionerSalePrice, uint64 _lastMintedTime, uint32 _mintedCount, bool _hasActiveCommissionerAuction, bool _mintingEnabled) external;

}

 
 
 
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

 
 
interface CSportsCoreInterface {

     
    function isCoreContract() external pure returns (bool);

     
     
     
     
    function batchEscrowToTeamContract(address _owner, uint32[] _tokenIds) external;

     
     
     
     
     
     
    function approve(address _to, uint256 _tokenId) external;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}
 
 
 
contract CSportsTeamGeneric is CSportsAuth, CSportsTeam,  CSportsContestBase {

   

   
  CSportsCoreInterface public coreContract;

   
  address public contestContractAddress;

   
   
  CSportsRosterInterface public leagueRosterContract;

   
  uint64 uniqueTeamId;

   
  uint32 playersPerTeam;

   
  mapping (uint32 => Team) teamIdToTeam;

   

   
  constructor(uint32 _playersPerTeam) public {

       
      ceoAddress = msg.sender;
      cfoAddress = msg.sender;
      cooAddress = msg.sender;
      commissionerAddress = msg.sender;

       
       
      uniqueTeamId = 1;

       
      isTeamContract = true;

       
      playersPerTeam = _playersPerTeam;
  }

   
   
  function setContestContractAddress(address _address) public onlyCEO {
    contestContractAddress = _address;
  }

   
   
  function setCoreContractAddress(address _address) public onlyCEO {
    CSportsCoreInterface candidateContract = CSportsCoreInterface(_address);
    require(candidateContract.isCoreContract());
    coreContract = candidateContract;
  }

   
   
  function setLeagueRosterContractAddress(address _address) public onlyCEO {
    CSportsRosterInterface candidateContract = CSportsRosterInterface(_address);
    require(candidateContract.isLeagueRosterContract());
    leagueRosterContract = candidateContract;
  }

   
  function setLeagueRosterAndCoreAndContestContractAddress(address _league, address _core, address _contest) public onlyCEO {
    setLeagueRosterContractAddress(_league);
    setCoreContractAddress(_core);
    setContestContractAddress(_contest);
  }

   
   
   
   
   
   
   
   
   
   
   
   
   
  function createTeam(address _owner, uint32[] _tokenIds) public returns (uint32) {
    require(msg.sender == contestContractAddress);
    require(_tokenIds.length == playersPerTeam);

     
     
     
    coreContract.batchEscrowToTeamContract(_owner, _tokenIds);

    uint32 _teamId =  _createTeam(_owner, _tokenIds);

    emit TeamCreated(_teamId, _owner);

    return _teamId;
  }

   
   
   
   
   
   
   
   
  function updateTeam(address _owner, uint32 _teamId, uint8[] _indices, uint32[] _tokenIds) public {
    require(msg.sender == contestContractAddress);
    require(_owner != address(0));
    require(_tokenIds.length <= playersPerTeam);
    require(_indices.length <= playersPerTeam);
    require(_indices.length == _tokenIds.length);

    Team storage _team = teamIdToTeam[_teamId];
    require(_owner == _team.owner);

     
     
     
    coreContract.batchEscrowToTeamContract(_owner, _tokenIds);

     
    for (uint8 i = 0; i < _indices.length; i++) {
      require(_indices[i] <= playersPerTeam);

      uint256 _oldTokenId = uint256(_team.playerTokenIds[_indices[i]]);
      uint256 _newTokenId = _tokenIds[i];

       
       
      coreContract.approve(_owner, _oldTokenId);
      coreContract.transferFrom(address(this), _owner, _oldTokenId);

       
      _team.playerTokenIds[_indices[i]] = uint32(_newTokenId);

    }

    emit TeamUpdated(_teamId);
  }

   
   
   
  function releaseTeam(uint32 _teamId) public {

    require(msg.sender == contestContractAddress);
    Team storage _team = teamIdToTeam[_teamId];
    require(_team.owner != address(0));

    if (_team.ownsPlayerTokens) {
       
       
      for (uint32 i = 0; i < _team.playerTokenIds.length; i++) {
        uint32 _tokenId = _team.playerTokenIds[i];
        coreContract.approve(_team.owner, _tokenId);
        coreContract.transferFrom(address(this), _team.owner, _tokenId);
      }

       
      _team.ownsPlayerTokens = false;

      emit TeamReleased(_teamId);
    }

  }

   
   
   
  function refunded(uint32 _teamId) public {
    require(msg.sender == contestContractAddress);
    Team storage _team = teamIdToTeam[_teamId];
    require(_team.owner != address(0));
    _team.holdsEntryFee = false;
  }

   
   
   
   
   
   
  function scoreTeams(uint32[] _teamIds, int32[] _scores, uint32[] _places) public {

    require(msg.sender == contestContractAddress);
    require ((_teamIds.length == _scores.length) && (_teamIds.length == _places.length)) ;
    for (uint i = 0; i < _teamIds.length; i++) {
      Team storage _team = teamIdToTeam[_teamIds[i]];
      if (_team.owner != address(0)) {
        _team.score = _scores[i];
        _team.place = _places[i];
      }
    }
  }

   
   
  function getScore(uint32 _teamId) public view returns (int32) {
    Team storage _team = teamIdToTeam[_teamId];
    require(_team.owner != address(0));
    return _team.score;
  }

   
   
  function getPlace(uint32 _teamId) public view returns (uint32) {
    Team storage _team = teamIdToTeam[_teamId];
    require(_team.owner != address(0));
    return _team.place;
  }

   
   
   
  function ownsPlayerTokens(uint32 _teamId) public view returns (bool) {
    Team storage _team = teamIdToTeam[_teamId];
    require(_team.owner != address(0));
    return _team.ownsPlayerTokens;
  }

   
   
  function getTeamOwner(uint32 _teamId) public view returns (address) {
    Team storage _team = teamIdToTeam[_teamId];
    require(_team.owner != address(0));
    return _team.owner;
  }

   
   
   
   
  function tokenIdsForTeam(uint32 _teamId) public view returns (uint32 count, uint32[50]) {

      
     uint32[50] memory _tokenIds;

     Team storage _team = teamIdToTeam[_teamId];
     require(_team.owner != address(0));

     for (uint32 i = 0; i < _team.playerTokenIds.length; i++) {
       _tokenIds[i] = _team.playerTokenIds[i];
     }

     return (uint32(_team.playerTokenIds.length), _tokenIds);
  }

   
   
  function getTeam(uint32 _teamId) public view returns (
      address _owner,
      int32 _score,
      uint32 _place,
      bool _holdsEntryFee,
      bool _ownsPlayerTokens
    ) {
    Team storage t = teamIdToTeam[_teamId];
    require(t.owner != address(0));
    _owner = t.owner;
    _score = t.score;
    _place = t.place;
    _holdsEntryFee = t.holdsEntryFee;
    _ownsPlayerTokens = t.ownsPlayerTokens;
  }

   

   
   
   
   
  function _createTeam(address _owner, uint32[] _playerTokenIds) internal returns (uint32) {

    Team memory _team = Team({
      owner: _owner,
      score: 0,
      place: 0,
      holdsEntryFee: true,
      ownsPlayerTokens: true,
      playerTokenIds: _playerTokenIds
    });

    uint32 teamIdToReturn = uint32(uniqueTeamId);
    teamIdToTeam[teamIdToReturn] = _team;

     
    uniqueTeamId++;

     
     
     
    require(uniqueTeamId < 4294967295);

     
     

    return teamIdToReturn;
  }

}