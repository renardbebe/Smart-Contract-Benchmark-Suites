 

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

 
 
interface CSportsRosterInterface {

     
    function isLeagueRosterContract() external pure returns (bool);

     
    function commissionerAuctionComplete(uint32 _rosterIndex, uint128 _price) external;

     
    function commissionerAuctionCancelled(uint32 _rosterIndex) external view;

     
    function getMetadata(uint128 _md5Token) external view returns (string);

     
    function getRealWorldPlayerRosterIndex(uint128 _md5Token) external view returns (uint128);

     
    function realWorldPlayerFromIndex(uint128 idx) external view returns (uint128 md5Token, uint128 prevCommissionerSalePrice, uint64 lastMintedTime, uint32 mintedCount, bool hasActiveCommissionerAuction, bool mintingEnabled);

     
    function updateRealWorldPlayer(uint32 _rosterIndex, uint128 _prevCommissionerSalePrice, uint64 _lastMintedTime, uint32 _mintedCount, bool _hasActiveCommissionerAuction, bool _mintingEnabled) external;

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

 
 
 
contract CSportsBase is CSportsAuth, CSportsRosterPlayer {

     
     
     
     
     
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

     
     
     
     
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

     
     
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

     
    event CommissionerAuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);

     
    event CommissionerAuctionCanceled(uint256 tokenId);

     
     
     

     
     
    struct PlayerToken {

       
       
       
      uint32 realWorldPlayerId;

       
       
      uint32 serialNumber;

       
      uint64 mintedTime;

       
      uint128 mostRecentPrice;

    }

     
     
     

     
     
     
    mapping (uint256 => address) public playerTokenToOwner;

     
    mapping (uint256 => address) public playerTokenToApproved;

     
    mapping(address => uint32[]) public ownedTokens;

     
     
    mapping(uint32 => uint32) tokenToOwnedTokensIndex;

     
    mapping(address => mapping(address => bool)) operators;

     
     
     
     
     
     
    uint16 public remainingMarketingTokens = MAX_MARKETING_TOKENS;
    mapping (uint256 => uint128) marketingTokens;

     
     
     

     
     
     
     
     
     
    CSportsRosterInterface public leagueRosterContract;

     
     
    CSportsTeam public teamContract;

     
    PlayerToken[] public playerTokens;

     
     
     

     
     
    function setLeagueRosterContractAddress(address _address) public onlyCEO {
       
       
      if (!isDevelopment) {
        require(leagueRosterContract == address(0));
      }

      CSportsRosterInterface candidateContract = CSportsRosterInterface(_address);
       
       
      require(candidateContract.isLeagueRosterContract());
       
      leagueRosterContract = candidateContract;
    }

     
     
     
     
    function setTeamContractAddress(address _address) public onlyCEO {
      CSportsTeam candidateContract = CSportsTeam(_address);
       
       
      require(candidateContract.isTeamContract());
       
      teamContract = candidateContract;
    }

     
     
     

     
     
    function _isContract(address addressToTest) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addressToTest)
        }
        return (size > 0);
    }

     
     
    function _tokenExists(uint256 _tokenId) internal view returns (bool) {
        return (_tokenId < playerTokens.length);
    }

     
     
     
     
     
     
    function _mintPlayer(uint32 _realWorldPlayerId, uint32 _serialNumber, address _owner) internal returns (uint32) {
         
         
         
        require(_realWorldPlayerId < 4294967295);
        require(_serialNumber < 4294967295);

        PlayerToken memory _player = PlayerToken({
          realWorldPlayerId: _realWorldPlayerId,
          serialNumber: _serialNumber,
          mintedTime: uint64(now),
          mostRecentPrice: 0
        });

        uint256 newPlayerTokenId = playerTokens.push(_player) - 1;

         
         
        require(newPlayerTokenId < 4294967295);

         
         
        _transfer(0, _owner, newPlayerTokenId);

        return uint32(newPlayerTokenId);
    }

     
     
     
     
    function _removeTokenFrom(address _from, uint256 _tokenId) internal {

       
      uint32 fromIndex = tokenToOwnedTokensIndex[uint32(_tokenId)];

       
      uint lastIndex = ownedTokens[_from].length - 1;
      uint32 lastToken = ownedTokens[_from][lastIndex];

       
       
      ownedTokens[_from][fromIndex] = lastToken;
      ownedTokens[_from].length--;

       
       
      tokenToOwnedTokensIndex[lastToken] = fromIndex;

       
      tokenToOwnedTokensIndex[uint32(_tokenId)] = 0;

    }

     
     
     
     
    function _addTokenTo(address _to, uint256 _tokenId) internal {
      uint32 toIndex = uint32(ownedTokens[_to].push(uint32(_tokenId))) - 1;
      tokenToOwnedTokensIndex[uint32(_tokenId)] = toIndex;
    }

     
     
     
     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {

         
        playerTokenToOwner[_tokenId] = _to;

         
         
        if (_from != address(0)) {

             
             
             
            _removeTokenFrom(_from, _tokenId);

             
            delete playerTokenToApproved[_tokenId];
        }

         
        _addTokenTo(_to, _tokenId);

         
        emit Transfer(_from, _to, _tokenId);
    }

     
     
    function uintToString(uint v) internal pure returns (string str) {
      bytes32 b32 = uintToBytes32(v);
      str = bytes32ToString(b32);
    }

     
     
    function uintToBytes32(uint v) internal pure returns (bytes32 ret) {
        if (v == 0) {
            ret = '0';
        }
        else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

     
     
    function bytes32ToString (bytes32 data) internal pure returns (string) {

        uint count = 0;
        bytes memory bytesString = new bytes(32);  
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
                count++;
            } else {
              break;
            }
        }

        bytes memory s = new bytes(count);
        for (j = 0; j < count; j++) {
            s[j] = bytesString[j];
        }
        return string(s);

    }

}

 
 
 
interface ERC721   {
     
     
     
     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external payable;

     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 
 
 
interface ERC721Metadata   {
     
    function name() external view returns (string _name);

     
    function symbol() external view returns (string _symbol);

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string);
}

 
 
 
interface ERC721Enumerable   {
     
     
     
    function totalSupply() external view returns (uint256);

     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256);

     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

 
interface ERC721TokenReceiver {
     
     
     
     
     
     
     
     
     
     
     
     
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

interface ERC165 {
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 
 
 
 
contract CSportsOwnership is CSportsBase {

   
  string _name;
  string _symbol;
  string _tokenURI;

   
   
  function implementsERC721() public pure returns (bool)
  {
      return true;
  }

   
  function name() external view returns (string) {
    return _name;
  }

   
  function symbol() external view returns (string) {
    return _symbol;
  }

   
   
   
   
  function tokenURI(uint256 _tokenId) external view returns (string ret) {
    string memory tokenIdAsString = uintToString(uint(_tokenId));
    ret = string (abi.encodePacked(_tokenURI, tokenIdAsString, "/"));
  }

   
   
   
   
   
  function ownerOf(uint256 _tokenId)
      public
      view
      returns (address owner)
  {
      owner = playerTokenToOwner[_tokenId];
      require(owner != address(0));
  }

   
   
   
   
   
  function balanceOf(address _owner) public view returns (uint256 count) {
       
       
       
      return ownedTokens[_owner].length;
  }

   
   
   
   
   
   
   
   
   
   
  function transferFrom(
      address _from,
      address _to,
      uint256 _tokenId
  )
      public
      whenNotPaused
  {
      require(_to != address(0));
      require (_tokenExists(_tokenId));

       
      require(_approvedFor(_to, _tokenId));
      require(_owns(_from, _tokenId));

       
      require(_owns(msg.sender, _tokenId) ||  
             (msg.sender == playerTokenToApproved[_tokenId]) ||  
             operators[_from][msg.sender]);  

       
      _transfer(_from, _to, _tokenId);
  }

   
   
   
   
   
   
   
   
   
   
  function batchTransferFrom(
        address _from,
        address _to,
        uint32[] _tokenIds
  )
  public
  whenNotPaused
  {
    for (uint32 i = 0; i < _tokenIds.length; i++) {

        uint32 _tokenId = _tokenIds[i];

         
        require(_approvedFor(_to, _tokenId));
        require(_owns(_from, _tokenId));

         
        require(_owns(msg.sender, _tokenId) ||  
        (msg.sender == playerTokenToApproved[_tokenId]) ||  
        operators[_from][msg.sender]);  

         
         
        _transfer(_from, _to, _tokenId);
    }
  }

   
   
   
   
   
   
  function approve(
      address _to,
      uint256 _tokenId
  )
      public
      whenNotPaused
  {
      address owner = ownerOf(_tokenId);
      require(_to != owner);

       
      require((msg.sender == owner) || (operators[ownerOf(_tokenId)][msg.sender]));

       
      _approve(_tokenId, _to);

       
      emit Approval(msg.sender, _to, _tokenId);
  }

   
   
   
   
   
   
   
  function batchApprove(
        address _to,
        uint32[] _tokenIds
  )
  public
  whenNotPaused
  {
    for (uint32 i = 0; i < _tokenIds.length; i++) {

        uint32 _tokenId = _tokenIds[i];

         
        require(_owns(msg.sender, _tokenId) || (operators[ownerOf(_tokenId)][msg.sender]));

         
        _approve(_tokenId, _to);

         
        emit Approval(msg.sender, _to, _tokenId);
    }
  }

   
   
   
   
  function batchEscrowToTeamContract(
    address _owner,
    uint32[] _tokenIds
  )
    public
    whenNotPaused
  {
    require(teamContract != address(0));
    require(msg.sender == address(teamContract));

    for (uint32 i = 0; i < _tokenIds.length; i++) {

      uint32 _tokenId = _tokenIds[i];

       
      require(_owns(_owner, _tokenId));

       
       
      _transfer(_owner, teamContract, _tokenId);
    }
  }

  bytes4 constant TOKEN_RECEIVED_SIG = bytes4(keccak256("onERC721Received(address,uint256,bytes)"));

   
   
   
   
   
   
   
   
   
   
   
   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable {
    transferFrom(_from, _to, _tokenId);
    if (_isContract(_to)) {
        ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);
        bytes4 response = receiver.onERC721Received.gas(50000)(msg.sender, _from, _tokenId, data);
        require(response == TOKEN_RECEIVED_SIG);
    }
  }

   
   
   
   
   
   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
    require(_to != address(0));
    transferFrom(_from, _to, _tokenId);
    if (_isContract(_to)) {
        ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);
        bytes4 response = receiver.onERC721Received.gas(50000)(msg.sender, _from, _tokenId, "");
        require(response == TOKEN_RECEIVED_SIG);
    }
  }

   
   
   
  function totalSupply() public view returns (uint) {
      return playerTokens.length;
  }

   
   
   
   
   
   
   
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 _tokenId) {
      require(owner != address(0));
      require(index < balanceOf(owner));
      return ownedTokens[owner][index];
  }

   
   
   
   
   
  function tokenByIndex(uint256 index) external view returns (uint256) {
      require (_tokenExists(index));
      return index;
  }

   
   
   
   
   
   
  function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender);
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
  }

   
   
   
   
  function getApproved(uint256 _tokenId) external view returns (address) {
      require(_tokenExists(_tokenId));
      return playerTokenToApproved[_tokenId];
  }

   
   
   
   
   
   
  function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
      return (
          interfaceID == this.supportsInterface.selector ||  
          interfaceID == 0x5b5e139f ||  
          interfaceID == 0x80ac58cd ||  
          interfaceID == 0x780e9d63);   
  }

   
   
   

   
   
   
  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return playerTokenToOwner[_tokenId] == _claimant;
  }

   
   
   
  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return playerTokenToApproved[_tokenId] == _claimant;
  }

   
   
   
   
   
  function _approve(uint256 _tokenId, address _approved) internal {
      playerTokenToApproved[_tokenId] = _approved;
  }

}

 
interface CSportsAuctionInterface {

     
     
    function isSaleClockAuction() external pure returns (bool);

     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    ) external;

     
     
     
     
     
     
     
    function repriceAuctions(
        uint256[] _tokenIds,
        uint256[] _startingPrices,
        uint256[] _endingPrices,
        uint256 _duration,
        address _seller
    ) external;

     
     
     
    function cancelAuction(uint256 _tokenId) external;

     
    function withdrawBalance() external;

}

 
contract SaleClockAuctionListener {
    function implementsSaleClockAuctionListener() public pure returns (bool);
    function auctionCreated(uint256 tokenId, address seller, uint128 startingPrice, uint128 endingPrice, uint64 duration) public;
    function auctionSuccessful(uint256 tokenId, uint128 totalPrice, address seller, address buyer) public;
    function auctionCancelled(uint256 tokenId, address seller) public;
}

 
 
 
contract CSportsAuction is CSportsOwnership, SaleClockAuctionListener {

   
  CSportsAuctionInterface public saleClockAuctionContract;

   
  function implementsSaleClockAuctionListener() public pure returns (bool) {
    return true;
  }

   
  function auctionCreated(uint256  , address  , uint128  , uint128  , uint64  ) public {
    require (saleClockAuctionContract != address(0));
    require (msg.sender == address(saleClockAuctionContract));
  }

   
   
   
   
   
  function auctionSuccessful(uint256 tokenId, uint128 totalPrice, address seller, address winner) public {
    require (saleClockAuctionContract != address(0));
    require (msg.sender == address(saleClockAuctionContract));

     
    PlayerToken storage _playerToken = playerTokens[tokenId];
    _playerToken.mostRecentPrice = totalPrice;

    if (seller == address(this)) {
       
      leagueRosterContract.commissionerAuctionComplete(playerTokens[tokenId].realWorldPlayerId, totalPrice);
      emit CommissionerAuctionSuccessful(tokenId, totalPrice, winner);
    }
  }

   
   
   
  function auctionCancelled(uint256 tokenId, address seller) public {
    require (saleClockAuctionContract != address(0));
    require (msg.sender == address(saleClockAuctionContract));
    if (seller == address(this)) {
       
      leagueRosterContract.commissionerAuctionCancelled(playerTokens[tokenId].realWorldPlayerId);
      emit CommissionerAuctionCanceled(tokenId);
    }
  }

   
   
  function setSaleAuctionContractAddress(address _address) public onlyCEO {

      require(_address != address(0));

      CSportsAuctionInterface candidateContract = CSportsAuctionInterface(_address);

       
      require(candidateContract.isSaleClockAuction());

       
      saleClockAuctionContract = candidateContract;

  }

   
   
  function cancelCommissionerAuction(uint32 tokenId) public onlyCommissioner {
    require(saleClockAuctionContract != address(0));
    saleClockAuctionContract.cancelAuction(tokenId);
  }

   
   
   
   
   
   
  function createSaleAuction(
      uint256 _playerTokenId,
      uint256 _startingPrice,
      uint256 _endingPrice,
      uint256 _duration
  )
      public
      whenNotPaused
  {
       
       
       
      require(_owns(msg.sender, _playerTokenId));
      _approve(_playerTokenId, saleClockAuctionContract);

       
       
      saleClockAuctionContract.createAuction(
          _playerTokenId,
          _startingPrice,
          _endingPrice,
          _duration,
          msg.sender
      );
  }

   
   
   
   
   
  function withdrawAuctionBalances() external onlyCOO {
      saleClockAuctionContract.withdrawBalance();
  }
}

 
 
 
contract CSportsMinting is CSportsAuction {

   
  event MarketingTokenRedeemed(uint256 hash, uint128 rwpMd5, address indexed recipient);

   
  event MarketingTokenCreated(uint256 hash, uint128 rwpMd5);

   
  event MarketingTokenReplaced(uint256 oldHash, uint256 newHash, uint128 rwpMd5);

   
  function isMinter() public pure returns (bool) {
      return true;
  }

   
   
  function getKeccak256(string stringToHash) public pure returns (uint256) {
      return uint256(keccak256(abi.encodePacked(stringToHash)));
  }

   
   
   
   
   
   
   
   
   
   
  function addMarketingToken(uint256 keywordHash, uint128 md5Token) public onlyCommissioner {

    require(remainingMarketingTokens > 0);
    require(marketingTokens[keywordHash] == 0);

     
    uint128 _rosterIndex = leagueRosterContract.getRealWorldPlayerRosterIndex(md5Token);
    require(_rosterIndex != 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

     
    remainingMarketingTokens--;
    marketingTokens[keywordHash] = md5Token;

    emit MarketingTokenCreated(keywordHash, md5Token);

  }

   
   
   
   
   
   
   
   
   
   
  function replaceMarketingToken(uint256 oldKeywordHash, uint256 newKeywordHash, uint128 md5Token) public onlyCommissioner {

    uint128 _md5Token = marketingTokens[oldKeywordHash];
    if (_md5Token != 0) {
      marketingTokens[oldKeywordHash] = 0;
      marketingTokens[newKeywordHash] = md5Token;
      emit MarketingTokenReplaced(oldKeywordHash, newKeywordHash, md5Token);
    }

  }

   
   
   
   
   
   
   
   
  function MD5FromMarketingKeywords(string keyWords) public view returns (uint128) {
    uint256 keyWordsHash = uint256(keccak256(abi.encodePacked(keyWords)));
    uint128 _md5Token = marketingTokens[keyWordsHash];
    return _md5Token;
  }

   
   
   
   
   
   
   
   
  function redeemMarketingToken(string keyWords) public {

    uint256 keyWordsHash = uint256(keccak256(abi.encodePacked(keyWords)));
    uint128 _md5Token = marketingTokens[keyWordsHash];
    if (_md5Token != 0) {

       
      marketingTokens[keyWordsHash] = 0;

      uint128 _rosterIndex = leagueRosterContract.getRealWorldPlayerRosterIndex(_md5Token);
      if (_rosterIndex != 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {

         
        RealWorldPlayer memory _rwp;
        (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) =  leagueRosterContract.realWorldPlayerFromIndex(_rosterIndex);

         
        _mintPlayer(uint32(_rosterIndex), _rwp.mintedCount, msg.sender);

         
         
         
        leagueRosterContract.updateRealWorldPlayer(uint32(_rosterIndex), _rwp.prevCommissionerSalePrice, uint64(now), _rwp.mintedCount + 1, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled);

        emit MarketingTokenRedeemed(keyWordsHash, _rwp.md5Token, msg.sender);
      }

    }
  }

   
   
   
  function minStartPriceForCommishAuctions(uint128[] _md5Tokens) public view onlyCommissioner returns (uint128[50]) {
    require (_md5Tokens.length <= 50);
    uint128[50] memory minPricesArray;
    for (uint32 i = 0; i < _md5Tokens.length; i++) {
        uint128 _md5Token = _md5Tokens[i];
        uint128 _rosterIndex = leagueRosterContract.getRealWorldPlayerRosterIndex(_md5Token);
        if (_rosterIndex == 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
           
          continue;
        }
        RealWorldPlayer memory _rwp;
        (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) =  leagueRosterContract.realWorldPlayerFromIndex(_rosterIndex);

         
        if (_rwp.md5Token != _md5Token) continue;

        minPricesArray[i] = uint128(_computeNextCommissionerPrice(_rwp.prevCommissionerSalePrice));
    }
    return minPricesArray;
  }

   
   
   
   
   
   
   
   
   
   
   
   
   
   
  function mintPlayers(uint128[] _md5Tokens, uint256 _startPrice, uint256 _endPrice, uint256 _duration) public {

    require(leagueRosterContract != address(0));
    require(saleClockAuctionContract != address(0));
    require((msg.sender == commissionerAddress) || (msg.sender == address(leagueRosterContract)));

    for (uint32 i = 0; i < _md5Tokens.length; i++) {
      uint128 _md5Token = _md5Tokens[i];
      uint128 _rosterIndex = leagueRosterContract.getRealWorldPlayerRosterIndex(_md5Token);
      if (_rosterIndex == 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
         
        continue;
      }

       
       
      RealWorldPlayer memory _rwp;
      (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) =  leagueRosterContract.realWorldPlayerFromIndex(_rosterIndex);

      if (_rwp.md5Token != _md5Token) continue;
      if (!_rwp.mintingEnabled) continue;

       
       
      if (_rwp.hasActiveCommissionerAuction) continue;

       
      uint256 _minStartPrice = _computeNextCommissionerPrice(_rwp.prevCommissionerSalePrice);

       
      if (_startPrice < _minStartPrice) {
          _startPrice = _minStartPrice;
      }

       
      uint32 _playerId = _mintPlayer(uint32(_rosterIndex), _rwp.mintedCount, address(this));

       
       
      _approve(_playerId, saleClockAuctionContract);

       
      if (_duration == 0) {
        _duration = COMMISSIONER_AUCTION_DURATION;
      }

       
       
       
       
      saleClockAuctionContract.createAuction(
          _playerId,
          _startPrice,
          _endPrice,
          _duration,
          address(this)
      );

       
       
      leagueRosterContract.updateRealWorldPlayer(uint32(_rosterIndex), _rwp.prevCommissionerSalePrice, uint64(now), _rwp.mintedCount + 1, true, _rwp.mintingEnabled);
    }
  }

   
   
   
   
   
   
   
   
   
  function repriceAuctions(
      uint256[] _tokenIds,
      uint256[] _startingPrices,
      uint256[] _endingPrices,
      uint256 _duration
  ) external onlyCommissioner {

       
      for (uint32 i = 0; i < _tokenIds.length; i++) {
          uint32 _tokenId = uint32(_tokenIds[i]);
          PlayerToken memory pt = playerTokens[_tokenId];
          RealWorldPlayer memory _rwp;
          (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) = leagueRosterContract.realWorldPlayerFromIndex(pt.realWorldPlayerId);
          uint256 _minStartPrice = _computeNextCommissionerPrice(_rwp.prevCommissionerSalePrice);

           
          require(_startingPrices[i] >= _minStartPrice);
      }

       
       
      saleClockAuctionContract.repriceAuctions(_tokenIds, _startingPrices, _endingPrices, _duration, address(this));
  }

   
   
   
   
   
   
   
  function createCommissionerAuction(uint32 _playerTokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration)
        public whenNotPaused onlyCommissioner {

        require(leagueRosterContract != address(0));
        require(_playerTokenId < playerTokens.length);

         
         
         
         
         
        require(_owns(address(this), _playerTokenId));

         
        PlayerToken memory pt = playerTokens[_playerTokenId];

         
        RealWorldPlayer memory _rwp;
        (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) = leagueRosterContract.realWorldPlayerFromIndex(pt.realWorldPlayerId);

         
        uint256 _minStartPrice = _computeNextCommissionerPrice(_rwp.prevCommissionerSalePrice);
        if (_startingPrice < _minStartPrice) {
            _startingPrice = _minStartPrice;
        }

         
        if (_duration == 0) {
            _duration = COMMISSIONER_AUCTION_DURATION;
        }

         
        _approve(_playerTokenId, saleClockAuctionContract);

         
         
        saleClockAuctionContract.createAuction(
            _playerTokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            address(this)
        );
  }

   
   
  function _computeNextCommissionerPrice(uint128 prevTwoCommissionerSalePriceAve) internal view returns (uint256) {

      uint256 nextPrice = prevTwoCommissionerSalePriceAve + (prevTwoCommissionerSalePriceAve / 4);

       
      if (nextPrice > 340282366920938463463374607431768211455) {
        nextPrice = 340282366920938463463374607431768211455;
      }

       
      if (nextPrice < COMMISSIONER_AUCTION_FLOOR_PRICE) {
          nextPrice = COMMISSIONER_AUCTION_FLOOR_PRICE;
      }

      return nextPrice;
  }

}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract CSportsCore is CSportsMinting {

   
  bool public isCoreContract = true;

   
   
   
  address public newContractAddress;

   
   
   
   
  constructor(string nftName, string nftSymbol, string nftTokenURI) public {

       
      paused = true;

       
      _name = nftName;
      _symbol = nftSymbol;
      _tokenURI = nftTokenURI;

       
      ceoAddress = msg.sender;
      cfoAddress = msg.sender;
      cooAddress = msg.sender;
      commissionerAddress = msg.sender;

  }

   
  function() external payable {
     
  }

   
   
   

   
   
   
   
   
   
  function upgradeContract(address _v2Address) public onlyCEO whenPaused {
      newContractAddress = _v2Address;
      emit ContractUpgrade(_v2Address);
  }

   
   
   
  function unpause() public onlyCEO whenPaused {
      require(leagueRosterContract != address(0));
      require(saleClockAuctionContract != address(0));
      require(newContractAddress == address(0));

       
      super.unpause();
  }

   
  function setLeagueRosterAndSaleAndTeamContractAddress(address _leagueAddress, address _saleAddress, address _teamAddress) public onlyCEO {
      setLeagueRosterContractAddress(_leagueAddress);
      setSaleAuctionContractAddress(_saleAddress);
      setTeamContractAddress(_teamAddress);
  }

   
   
  function getPlayerToken(uint32 _playerTokenID) public view returns (
      uint32 realWorldPlayerId,
      uint32 serialNumber,
      uint64 mintedTime,
      uint128 mostRecentPrice) {
    require(_playerTokenID < playerTokens.length);
    PlayerToken storage pt = playerTokens[_playerTokenID];
    realWorldPlayerId = pt.realWorldPlayerId;
    serialNumber = pt.serialNumber;
    mostRecentPrice = pt.mostRecentPrice;
    mintedTime = pt.mintedTime;
  }

   
   
  function realWorldPlayerTokenForPlayerTokenId(uint32 _playerTokenID) public view returns (uint128 md5Token) {
      require(_playerTokenID < playerTokens.length);
      PlayerToken storage pt = playerTokens[_playerTokenID];
      RealWorldPlayer memory _rwp;
      (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) = leagueRosterContract.realWorldPlayerFromIndex(pt.realWorldPlayerId);
      md5Token = _rwp.md5Token;
  }

   
   
  function realWorldPlayerMetadataForPlayerTokenId(uint32 _playerTokenID) public view returns (string metadata) {
      require(_playerTokenID < playerTokens.length);
      PlayerToken storage pt = playerTokens[_playerTokenID];
      RealWorldPlayer memory _rwp;
      (_rwp.md5Token, _rwp.prevCommissionerSalePrice, _rwp.lastMintedTime, _rwp.mintedCount, _rwp.hasActiveCommissionerAuction, _rwp.mintingEnabled) = leagueRosterContract.realWorldPlayerFromIndex(pt.realWorldPlayerId);
      metadata = leagueRosterContract.getMetadata(_rwp.md5Token);
  }

   
   
   

   
   
   
   
   
   
   
   
  function updateRealWorldPlayer(uint32 _rosterIndex, uint128 _prevCommissionerSalePrice, uint64 _lastMintedTime, uint32 _mintedCount, bool _hasActiveCommissionerAuction, bool _mintingEnabled) public onlyCEO onlyUnderDevelopment {
    require(leagueRosterContract != address(0));
    leagueRosterContract.updateRealWorldPlayer(_rosterIndex, _prevCommissionerSalePrice, _lastMintedTime, _mintedCount, _hasActiveCommissionerAuction, _mintingEnabled);
  }

}