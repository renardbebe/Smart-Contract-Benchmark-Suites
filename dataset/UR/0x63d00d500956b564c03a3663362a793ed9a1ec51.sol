 

pragma solidity ^0.4.25;

 
 
 
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

 
 
interface CSportsMinter {

     
    function isMinter() external pure returns (bool);

     
    function mintPlayers(uint128[] _md5Tokens, uint256 _startPrice, uint256 _endPrice, uint256 _duration) external;
}
 
 
 
contract CSportsRosterPlayer {

    struct RealWorldPlayer {

         
         
         
         
        uint128 md5Token;

         
        uint128 prevCommissionerSalePrice;

         
        uint64 lastMintedTime;

         
        uint32 mintedCount;

         
         
        bool hasActiveCommissionerAuction;

         
        bool mintingEnabled;

         
        string metadata;

    }

}

 
 
 
 
contract CSportsLeagueRoster is CSportsAuth, CSportsRosterPlayer  {

   

   
  CSportsMinter public minterContract;

   
   
   
   
   
   
  RealWorldPlayer[] public realWorldPlayers;

  mapping (uint128 => uint32) public md5TokenToRosterIndex;

   

   
  modifier onlyCoreContract() {
      require(msg.sender == address(minterContract));
      _;
  }

   

   
   
  constructor() public {
    ceoAddress = msg.sender;
    cfoAddress = msg.sender;
    cooAddress = msg.sender;
    commissionerAddress = msg.sender;
  }

   
  function isLeagueRosterContract() public pure returns (bool) {
    return true;
  }

   
   
  function realWorldPlayerFromIndex(uint128 idx) public view returns (uint128 md5Token, uint128 prevCommissionerSalePrice, uint64 lastMintedTime, uint32 mintedCount, bool hasActiveCommissionerAuction, bool mintingEnabled) {
    RealWorldPlayer memory _rwp;
    _rwp = realWorldPlayers[idx];
    md5Token = _rwp.md5Token;
    prevCommissionerSalePrice = _rwp.prevCommissionerSalePrice;
    lastMintedTime = _rwp.lastMintedTime;
    mintedCount = _rwp.mintedCount;
    hasActiveCommissionerAuction = _rwp.hasActiveCommissionerAuction;
    mintingEnabled = _rwp.mintingEnabled;
  }

   
   
  function setCoreContractAddress(address _address) public onlyCEO {

    CSportsMinter candidateContract = CSportsMinter(_address);
     
     
    require(candidateContract.isMinter());
     
    minterContract = candidateContract;

  }

   
  function playerCount() public view returns (uint32 count) {
    return uint32(realWorldPlayers.length);
  }

   
   
   
   
   
   
   
   
  function addAndMintPlayers(uint128[] _md5Tokens, bool[] _mintingEnabled, uint256 _startPrice, uint256 _endPrice, uint256 _duration) public onlyCommissioner {

     
    addRealWorldPlayers(_md5Tokens, _mintingEnabled);

     
    minterContract.mintPlayers(_md5Tokens, _startPrice, _endPrice, _duration);

  }

   
   
   
  function addRealWorldPlayers(uint128[] _md5Tokens, bool[] _mintingEnabled) public onlyCommissioner {
    if (_md5Tokens.length != _mintingEnabled.length) {
      revert();
    }
    for (uint32 i = 0; i < _md5Tokens.length; i++) {
       
       
      if ( (realWorldPlayers.length == 0) ||
           ((md5TokenToRosterIndex[_md5Tokens[i]] == 0) && (realWorldPlayers[0].md5Token != _md5Tokens[i])) ) {
        RealWorldPlayer memory _realWorldPlayer = RealWorldPlayer({
                                                      md5Token: _md5Tokens[i],
                                                      prevCommissionerSalePrice: 0,
                                                      lastMintedTime: 0,
                                                      mintedCount: 0,
                                                      hasActiveCommissionerAuction: false,
                                                      mintingEnabled: _mintingEnabled[i],
                                                      metadata: ""
                                                  });
        uint256 _rosterIndex = realWorldPlayers.push(_realWorldPlayer) - 1;

         
         
        require(_rosterIndex < 4294967295);

         
        md5TokenToRosterIndex[_md5Tokens[i]] = uint32(_rosterIndex);
      }
    }
  }

   
   
   
  function setMetadata(uint128 _md5Token, string _metadata) public onlyCommissioner {
      uint32 _rosterIndex = md5TokenToRosterIndex[_md5Token];
      if ((_rosterIndex > 0) || ((realWorldPlayers.length > 0) && (realWorldPlayers[0].md5Token == _md5Token))) {
         
        realWorldPlayers[_rosterIndex].metadata = _metadata;
      }
  }

   
   
  function getMetadata(uint128 _md5Token) public view returns (string metadata) {
    uint32 _rosterIndex = md5TokenToRosterIndex[_md5Token];
    if ((_rosterIndex > 0) || ((realWorldPlayers.length > 0) && (realWorldPlayers[0].md5Token == _md5Token))) {
       
      metadata = realWorldPlayers[_rosterIndex].metadata;
    } else {
      metadata = "";
    }
  }

   
   
   
   
  function removeRealWorldPlayer(uint128 _md5Token) public onlyCommissioner onlyUnderDevelopment  {
    for (uint32 i = 0; i < uint32(realWorldPlayers.length); i++) {
      RealWorldPlayer memory player = realWorldPlayers[i];
      if (player.md5Token == _md5Token) {
        uint32 stopAt = uint32(realWorldPlayers.length - 1);
        for (uint32 j = i; j < stopAt; j++){
            realWorldPlayers[j] = realWorldPlayers[j+1];
            md5TokenToRosterIndex[realWorldPlayers[j].md5Token] = j;
        }
        delete realWorldPlayers[realWorldPlayers.length-1];
        realWorldPlayers.length--;
        break;
      }
    }
  }

   
   
  function hasOpenCommissionerAuction(uint128 _md5Token) public view onlyCommissioner returns (bool) {
    uint128 _rosterIndex = this.getRealWorldPlayerRosterIndex(_md5Token);
    if (_rosterIndex == 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
      revert();
    } else {
      return realWorldPlayers[_rosterIndex].hasActiveCommissionerAuction;
    }
  }

   
   
  function getRealWorldPlayerRosterIndex(uint128 _md5Token) public view returns (uint128) {

    uint32 _rosterIndex = md5TokenToRosterIndex[_md5Token];
    if (_rosterIndex == 0) {
       
       
      if ((realWorldPlayers.length > 0) && (realWorldPlayers[0].md5Token == _md5Token)) {
        return uint128(0);
      }
    } else {
      return uint128(_rosterIndex);
    }

     
     
    return uint128(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
  }

   
   
   
  function enableRealWorldPlayerMinting(uint128[] _md5Tokens, bool[] _mintingEnabled) public onlyCommissioner {
    if (_md5Tokens.length != _mintingEnabled.length) {
      revert();
    }
    for (uint32 i = 0; i < _md5Tokens.length; i++) {
      uint32 _rosterIndex = md5TokenToRosterIndex[_md5Tokens[i]];
      if ((_rosterIndex > 0) || ((realWorldPlayers.length > 0) && (realWorldPlayers[0].md5Token == _md5Tokens[i]))) {
         
        realWorldPlayers[_rosterIndex].mintingEnabled = _mintingEnabled[i];
      } else {
         
        revert();
      }
    }
  }

   
   
  function isRealWorldPlayerMintingEnabled(uint128 _md5Token) public view returns (bool) {
     
    uint32 _rosterIndex = md5TokenToRosterIndex[_md5Token];
    if ((_rosterIndex > 0) || ((realWorldPlayers.length > 0) && (realWorldPlayers[0].md5Token == _md5Token))) {
       
      return realWorldPlayers[_rosterIndex].mintingEnabled;
    } else {
       
      revert();
    }
  }

   
   
   
   
   
   
   
   
  function updateRealWorldPlayer(uint32 _rosterIndex, uint128 _prevCommissionerSalePrice, uint64 _lastMintedTime, uint32 _mintedCount, bool _hasActiveCommissionerAuction, bool _mintingEnabled) public onlyCoreContract {
    require(_rosterIndex < realWorldPlayers.length);
    RealWorldPlayer storage _realWorldPlayer = realWorldPlayers[_rosterIndex];
    _realWorldPlayer.prevCommissionerSalePrice = _prevCommissionerSalePrice;
    _realWorldPlayer.lastMintedTime = _lastMintedTime;
    _realWorldPlayer.mintedCount = _mintedCount;
    _realWorldPlayer.hasActiveCommissionerAuction = _hasActiveCommissionerAuction;
    _realWorldPlayer.mintingEnabled = _mintingEnabled;
  }

   
   
   
  function setHasCommissionerAuction(uint32 _rosterIndex) public onlyCoreContract {
    require(_rosterIndex < realWorldPlayers.length);
    RealWorldPlayer storage _realWorldPlayer = realWorldPlayers[_rosterIndex];
    require(!_realWorldPlayer.hasActiveCommissionerAuction);
    _realWorldPlayer.hasActiveCommissionerAuction = true;
  }

   
   
   
  function commissionerAuctionComplete(uint32 _rosterIndex, uint128 _price) public onlyCoreContract {
    require(_rosterIndex < realWorldPlayers.length);
    RealWorldPlayer storage _realWorldPlayer = realWorldPlayers[_rosterIndex];
    require(_realWorldPlayer.hasActiveCommissionerAuction);
    if (_realWorldPlayer.prevCommissionerSalePrice == 0) {
      _realWorldPlayer.prevCommissionerSalePrice = _price;
    } else {
      _realWorldPlayer.prevCommissionerSalePrice = (_realWorldPlayer.prevCommissionerSalePrice + _price)/2;
    }
    _realWorldPlayer.hasActiveCommissionerAuction = false;

     
     
    if (_realWorldPlayer.mintingEnabled) {
      uint128[] memory _md5Tokens = new uint128[](1);
      _md5Tokens[0] = _realWorldPlayer.md5Token;
      minterContract.mintPlayers(_md5Tokens, 0, 0, 0);
    }
  }

   
   
  function commissionerAuctionCancelled(uint32 _rosterIndex) public view onlyCoreContract {
    require(_rosterIndex < realWorldPlayers.length);
    RealWorldPlayer storage _realWorldPlayer = realWorldPlayers[_rosterIndex];
    require(_realWorldPlayer.hasActiveCommissionerAuction);

     
     
     
     
  }

}