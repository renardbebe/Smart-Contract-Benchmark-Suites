 

 
pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }
}

 
library AddressUtils {

     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

 
contract ERC721Basic {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId)
        public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator)
        public view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public;
}

 
contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        public
        view
        returns (uint256 _tokenId);

    function tokenByIndex(uint256 _index) public view returns (uint256);
}

 
contract ERC721Metadata is ERC721Basic {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function tokenURI(uint256 _tokenId) public view returns (string);
}

 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 
contract ERC721BasicToken is ERC721Basic {
    using SafeMath for uint256;
    using AddressUtils for address;

     
     
    bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) internal tokenOwner;

     
    mapping (uint256 => address) internal tokenApprovals;

     
    mapping (address => uint256) internal ownedTokensCount;

     
    mapping (address => mapping (address => bool)) internal operatorApprovals;

     
    modifier onlyOwnerOf(uint256 _tokenId) {
        require (ownerOf(_tokenId) == msg.sender);
        _;
    }

     
    modifier canTransfer(uint256 _tokenId) {
        require (isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        require (_owner != address(0));
        return ownedTokensCount[_owner];
    }

     
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require (owner != address(0));
        return owner;
    }

     
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

     
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require (_to != owner);
        require (msg.sender == owner || isApprovedForAll(owner, msg.sender));

        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

     
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

     
    function setApprovalForAll(address _to, bool _approved) public {
        require (_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

     
    function isApprovedForAll(
        address _owner,
        address _operator
    )
        public
        view
        returns (bool)
    {
        return operatorApprovals[_owner][_operator];
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
        require (_from != address(0));
        require (_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

     
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
         
        safeTransferFrom(_from, _to, _tokenId, "");
    }

     
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public
        canTransfer(_tokenId)
    {
        transferFrom(_from, _to, _tokenId);
         
        require (checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

     
    function isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    )
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(_tokenId);
         
         
         
        return (
        _spender == owner ||
        getApproved(_tokenId) == _spender ||
        isApprovedForAll(owner, _spender)
        );
    }

     
    function _mint(address _to, uint256 _tokenId) internal {
        require (_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

     
    function _burn(address _owner, uint256 _tokenId) internal {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);
    }

     
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require (ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
        }
    }

     
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require (tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

     
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require (ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

     
    function checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        internal
        returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(
            msg.sender, _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}

 
contract ERC721Receiver {
     
    bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

     
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data
    )
        public
        returns(bytes4);
}

contract ERC721Holder is ERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes
    ) 
        public
        returns(bytes4)
        {
            return ERC721_RECEIVED;
        }
}

 
contract ERC721Token is ERC721, ERC721BasicToken {

     
    string internal name_;

     
    string internal symbol_;

     
    mapping(address => uint256[]) internal ownedTokens;

     
    mapping(uint256 => uint256) internal ownedTokensIndex;

     
    uint256[] internal allTokens;

     
    mapping(uint256 => uint256) internal allTokensIndex;

     
    string internal tokenURIBase;

     
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require (exists(_tokenId));
        return tokenURIBase;
    }

     
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        public
        view
        returns (uint256)
    {
        require (_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

     
    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }

     
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require (_index < totalSupply());
        return allTokens[_index];
    }


     
    function _setTokenURIBase(string _uri) internal {
        tokenURIBase = _uri;
    }

     
    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }

     
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);

         
         
        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
         
        ownedTokens[_from].length--;

         
         
         

        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }

     
    function name() public view returns (string) {
        return name_;
    }

     
    function symbol() public view returns (string) {
        return symbol_;
    }

     
    function _mint(address _to, uint256 _tokenId) internal {
        super._mint(_to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

     
    function _burn(address _owner, uint256 _tokenId) internal {
        super._burn(_owner, _tokenId);

         
        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.length--;
        allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;
    }

    bytes4 constant InterfaceSignature_ERC165 = 0x01ffc9a7;
     

    bytes4 constant InterfaceSignature_ERC721Enumerable = 0x780e9d63;
     

    bytes4 constant InterfaceSignature_ERC721Metadata = 0x5b5e139f;
     

    bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;
     

    bytes4 public constant InterfaceSignature_ERC721Optional =- 0x4f558e79;
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165)
        || (_interfaceID == InterfaceSignature_ERC721)
        || (_interfaceID == InterfaceSignature_ERC721Enumerable)
        || (_interfaceID == InterfaceSignature_ERC721Metadata));
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

}
 
contract LSNFT is ERC721Token {
  
   

   
  event Created(address owner, uint256 tokenId);
  
   
  
  struct NFT {
     
    uint256 attributes;

     
    uint256 currentGameCardId;

     
    uint256 mlbGameId;

     
    uint256 playerOverrideId;

     
    uint256 mlbPlayerId;

     
     
     
    uint256 earnedBy;
    
     
    uint256 assetDetails;
    
     
    uint256 isAttached;
  }

  NFT[] allNFTs;

  function isLSNFT() public view returns (bool) {
    return true;
  }

   
  function _createNFT (
    uint256[5] _nftData,
    address _owner,
    uint256 _isAttached)
    internal
    returns(uint256) {

    NFT memory _lsnftObj = NFT({
        attributes : _nftData[1],
        currentGameCardId : 0,
        mlbGameId : _nftData[2],
        playerOverrideId : _nftData[3],
        assetDetails: _nftData[0],
        isAttached: _isAttached,
        mlbPlayerId: _nftData[4],
        earnedBy: 0
    });

    uint256 newLSNFTId = allNFTs.push(_lsnftObj) - 1;

    _mint(_owner, newLSNFTId);
    
     
    emit Created(_owner, newLSNFTId);

    return newLSNFTId;
  }

   
  function _getAttributesOfToken(uint256 _tokenId) internal returns(NFT) {
    NFT storage lsnftObj = allNFTs[_tokenId];  
    return lsnftObj;
  }

  function _approveForSale(address _owner, address _to, uint256 _tokenId) internal {
    address owner = ownerOf(_tokenId);
    require (_to != owner);
    require (_owner == owner || isApprovedForAll(owner, _owner));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
        tokenApprovals[_tokenId] = _to;
        emit Approval(_owner, _to, _tokenId);
    }
  }
}

 
contract OperationalControl {
     
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public managerPrimary;
    address public managerSecondary;
    address public bankManager;

     
    mapping(address => uint8) public otherManagers;

     
    bool public paused = false;

     
    bool public error = false;

     
    modifier onlyManager() {
        require (msg.sender == managerPrimary || msg.sender == managerSecondary);
        _;
    }

     
    modifier onlyBanker() {
        require (msg.sender == bankManager);
        _;
    }

     
    modifier anyOperator() {
        require (
            msg.sender == managerPrimary ||
            msg.sender == managerSecondary ||
            msg.sender == bankManager ||
            otherManagers[msg.sender] == 1
        );
        _;
    }

     
    modifier onlyOtherManagers() {
        require (otherManagers[msg.sender] == 1);
        _;
    }

     
    function setPrimaryManager(address _newGM) external onlyManager {
        require (_newGM != address(0));

        managerPrimary = _newGM;
    }

     
    function setSecondaryManager(address _newGM) external onlyManager {
        require (_newGM != address(0));

        managerSecondary = _newGM;
    }

     
    function setBanker(address _newBK) external onlyManager {
        require (_newBK != address(0));

        bankManager = _newBK;
    }

     
    function setOtherManager(address _newOp, uint8 _state) external onlyManager {
        require (_newOp != address(0));

        otherManagers[_newOp] = _state;
    }

     

     
    modifier whenNotPaused() {
        require (!paused);
        _;
    }

     
    modifier whenPaused {
        require (paused);
        _;
    }

     
    modifier whenError {
        require (error);
        _;
    }

     
    function pause() external onlyManager whenNotPaused {
        paused = true;
    }

     
    function unpause() public onlyManager whenPaused {
         
        paused = false;
    }

     
    function hasError() public onlyManager whenPaused {
        error = true;
    }

     
    function noError() public onlyManager whenPaused {
        error = false;
    }
}

 
contract CollectibleBase is LSNFT {

     

     
    event AssetUpdated(uint256 tokenId);

     

     
    mapping (uint256 => mapping (uint32 => uint256) ) public nftTeamIdToSequenceIdToCollectible;

     
    mapping (uint256 => uint32) public nftTeamIndexToCollectibleCount;

     
    mapping(uint256 => uint256[]) public nftCollectibleAttachments;

     
    mapping(uint256 => uint256) public generationSeasonController;

     
    mapping(uint256 => uint256) public generationSeasonDict;

     
    function _updatePlayerOverrideId(uint256 _tokenId, uint256 _newPlayerOverrideId) internal {

         
        NFT storage lsnftObj = allNFTs[_tokenId];
        lsnftObj.playerOverrideId = _newPlayerOverrideId;

         
        allNFTs[_tokenId] = lsnftObj;

        emit AssetUpdated(_tokenId);
    }

     
    function _createNFTCollectible(
        uint8 _teamId,
        uint256 _attributes,
        address _owner,
        uint256 _isAttached,
        uint256[5] _nftData
    )
        internal
        returns (uint256)
    {
        uint256 generationSeason = (_attributes % 1000000).div(1000);
        require (generationSeasonController[generationSeason] == 1);

        uint32 _sequenceId = getSequenceId(_teamId);

        uint256 newNFTCryptoId = _createNFT(_nftData, _owner, _isAttached);
        
        nftTeamIdToSequenceIdToCollectible[_teamId][_sequenceId] = newNFTCryptoId;
        nftTeamIndexToCollectibleCount[_teamId] = _sequenceId;

        return newNFTCryptoId;
    }
    
    function getSequenceId(uint256 _teamId) internal returns (uint32) {
        return (nftTeamIndexToCollectibleCount[_teamId] + 1);
    }

     
    function _updateGenerationSeasonFlag(uint256 _season, uint8 _value) internal {
        generationSeasonController[_season] = _value;
    }

           
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalItems = balanceOf(_owner);
            uint256 resultIndex = 0;

             
             
            uint256 _assetId;

            for (_assetId = 0; _assetId < totalItems; _assetId++) {
                result[resultIndex] = tokenOfOwnerByIndex(_owner,_assetId);
                resultIndex++;
            }

            return result;
        }
    }

     
    function _updateMLBPlayerId(uint256 _tokenId, uint256 _newMLBPlayerId) internal {

         
        NFT storage lsnftObj = allNFTs[_tokenId];
        
        lsnftObj.mlbPlayerId = _newMLBPlayerId;

         
        allNFTs[_tokenId] = lsnftObj;

        emit AssetUpdated(_tokenId);
    }

     
    function _updateEarnedBy(uint256 _tokenId, uint256 _earnedBy) internal {

         
        NFT storage lsnftObj = allNFTs[_tokenId];
        
        lsnftObj.earnedBy = _earnedBy;

         
        allNFTs[_tokenId] = lsnftObj;

        emit AssetUpdated(_tokenId);
    }
}

 
contract CollectibleMinting is CollectibleBase, OperationalControl {

    uint256 public rewardsRedeemed = 0;

     
    uint256[31]  public promoCreatedCount;
    
     
    uint256 public seedCreatedCount;

     
    bool public isBatchSupported = true;
    
     
    mapping (address => bool) public contractsApprovedList;
    
     
    function updateBatchSupport(bool _flag) public onlyManager {
        isBatchSupported = _flag;
    }

    modifier canCreate() { 
        require (contractsApprovedList[msg.sender] || 
            msg.sender == managerPrimary ||
            msg.sender == managerSecondary); 
        _; 
    }
    
     
    function addToApproveList(address _newAddress) public onlyManager {
        
        require (!contractsApprovedList[_newAddress]);
        contractsApprovedList[_newAddress] = true;
    }

     
    function removeFromApproveList(address _newAddress) public onlyManager {
        require (contractsApprovedList[_newAddress]);
        delete contractsApprovedList[_newAddress];
    }

    
     
    function createPromoCollectible(
        uint8 _teamId,
        uint8 _posId,
        uint256 _attributes,
        address _owner,
        uint256 _gameId,
        uint256 _playerOverrideId,
        uint256 _mlbPlayerId)
        external
        canCreate
        whenNotPaused
        returns (uint256)
        {

        address nftOwner = _owner;
        if (nftOwner == address(0)) {
             nftOwner = managerPrimary;
        }

        if(allNFTs.length > 0) {
            promoCreatedCount[_teamId]++;
        }
        
        uint32 _sequenceId = getSequenceId(_teamId);
        
        uint256 assetDetails = uint256(uint64(now));
        assetDetails |= uint256(_sequenceId)<<64;
        assetDetails |= uint256(_teamId)<<96;
        assetDetails |= uint256(_posId)<<104;

        uint256[5] memory _nftData = [assetDetails, _attributes, _gameId, _playerOverrideId, _mlbPlayerId];
        
        return _createNFTCollectible(_teamId, _attributes, nftOwner, 0, _nftData);
    }

     
    function createSeedCollectible(
        uint8 _teamId,
        uint8 _posId,
        uint256 _attributes,
        address _owner,
        uint256 _gameId,
        uint256 _playerOverrideId,
        uint256 _mlbPlayerId)
        external
        canCreate
        whenNotPaused
        returns (uint256) {

        address nftOwner = _owner;
        
        if (nftOwner == address(0)) {
             nftOwner = managerPrimary;
        }
        
        seedCreatedCount++;
        uint32 _sequenceId = getSequenceId(_teamId);
        
        uint256 assetDetails = uint256(uint64(now));
        assetDetails |= uint256(_sequenceId)<<64;
        assetDetails |= uint256(_teamId)<<96;
        assetDetails |= uint256(_posId)<<104;

        uint256[5] memory _nftData = [assetDetails, _attributes, _gameId, _playerOverrideId, _mlbPlayerId];
        
        return _createNFTCollectible(_teamId, _attributes, nftOwner, 0, _nftData);
    }

     
    function createRewardCollectible (
        uint8 _teamId,
        uint8 _posId,
        uint256 _attributes,
        address _owner,
        uint256 _gameId,
        uint256 _playerOverrideId,
        uint256 _mlbPlayerId)
        external
        canCreate
        whenNotPaused
        returns (uint256) {

        address nftOwner = _owner;
        
        if (nftOwner == address(0)) {
             nftOwner = managerPrimary;
        }
        
        rewardsRedeemed++;
        uint32 _sequenceId = getSequenceId(_teamId);
        
        uint256 assetDetails = uint256(uint64(now));
        assetDetails |= uint256(_sequenceId)<<64;
        assetDetails |= uint256(_teamId)<<96;
        assetDetails |= uint256(_posId)<<104;

        uint256[5] memory _nftData = [assetDetails, _attributes, _gameId, _playerOverrideId, _mlbPlayerId];
        
        return _createNFTCollectible(_teamId, _attributes, nftOwner, 0, _nftData);
    }

     
    function createETHCardCollectible (
        uint8 _teamId,
        uint8 _posId,
        uint256 _attributes,
        address _owner,
        uint256 _gameId,
        uint256 _playerOverrideId,
        uint256 _mlbPlayerId)
        external
        canCreate
        whenNotPaused
        returns (uint256) {

        address nftOwner = _owner;
        
        if (nftOwner == address(0)) {
             nftOwner = managerPrimary;
        }
        
        rewardsRedeemed++;
        uint32 _sequenceId = getSequenceId(_teamId);
        
        uint256 assetDetails = uint256(uint64(now));
        assetDetails |= uint256(_sequenceId)<<64;
        assetDetails |= uint256(_teamId)<<96;
        assetDetails |= uint256(_posId)<<104;

        uint256[5] memory _nftData = [assetDetails, _attributes, _gameId, _playerOverrideId, _mlbPlayerId];
        
        return _createNFTCollectible(_teamId, _attributes, nftOwner, 2, _nftData);
    }
}

 
contract SaleManager {
    function createSale(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _owner) external;
}

 
contract DodgersNFT is CollectibleMinting {
    
     
    address public newContractAddress;

    string public constant MLB_Legal = "Major League Baseball trademarks and copyrights are used with permission of the applicable MLB entity.  All rights reserved.";

     
    uint32 public detachmentTime = 0;

     
    bool public attachedSystemActive;

     
    SaleManager public saleManagerAddress;

     
    constructor() public {
         
        paused = true;
        managerPrimary = msg.sender;
        managerSecondary = msg.sender;
        bankManager = msg.sender;
        name_ = "LucidSight-DODGERS-NFT";
        symbol_ = "DNFTCB";
    }

     
    function setSaleManagerAddress(address _saleManagerAddress) public onlyManager {
        require (_saleManagerAddress != address(0));
        saleManagerAddress = SaleManager(_saleManagerAddress);
    }

     
    modifier canTransfer(uint256 _tokenId) {
        uint256 isAttached = checkIsAttached(_tokenId);
        if(isAttached == 2) {
             
            require (msg.sender == managerPrimary ||
                msg.sender == managerSecondary ||
                msg.sender == bankManager ||
                otherManagers[msg.sender] == 1
            );
            updateIsAttached(_tokenId, 0);
        } else if(attachedSystemActive == true && isAttached >= 1) {
            require (msg.sender == managerPrimary ||
                msg.sender == managerSecondary ||
                msg.sender == bankManager ||
                otherManagers[msg.sender] == 1
            );
        }
        else {
            require (isApprovedOrOwner(msg.sender, _tokenId));
        }
    _;
    }

     
    function setNewAddress(address _v2Address) external onlyManager {
        require (_v2Address != address(0));
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

     
    function getCollectibleDetails(uint256 _tokenId)
        external
        view
        returns (
        uint256 isAttached,
        uint32 sequenceId,
        uint8 teamId,
        uint8 positionId,
        uint64 creationTime,
        uint256 attributes,
        uint256 playerOverrideId,
        uint256 mlbGameId,
        uint256 currentGameCardId,
        uint256 mlbPlayerId,
        uint256 earnedBy,
        uint256 generationSeason
        ) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);
        
        attributes = obj.attributes;
        currentGameCardId = obj.currentGameCardId;
        mlbGameId = obj.mlbGameId;
        playerOverrideId = obj.playerOverrideId;
        mlbPlayerId = obj.mlbPlayerId;

        creationTime = uint64(obj.assetDetails);
        sequenceId = uint32(obj.assetDetails>>64);
        teamId = uint8(obj.assetDetails>>96);
        positionId = uint8(obj.assetDetails>>104);
        isAttached = obj.isAttached;
        earnedBy = obj.earnedBy;

        generationSeason = generationSeasonDict[(obj.attributes % 1000000) / 1000];
    }

    
     
    function unpause() public onlyManager {
         
        super.unpause();
    }

     
    function getTeamId(uint256 _tokenId) external view returns (uint256) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);

        uint256 teamId = uint256(uint8(obj.assetDetails>>96));
        return uint256(teamId);
    }

     
    function getPositionId(uint256 _tokenId) external view returns (uint256) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);

        uint256 positionId = uint256(uint8(obj.assetDetails>>104));

        return positionId;
    }

     
    function getGameCardId(uint256 _tokenId) public view returns (uint256) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);
        return obj.currentGameCardId;
    }

     
    function checkIsAttached(uint256 _tokenId) public view returns (uint256) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);
        return obj.isAttached;
    }

     
    function getAbilitiesForCollectibleId(uint256 _tokenId) external view returns (uint256 ability) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);
        uint256 _attributes = uint256(obj.attributes);
        ability = (_attributes % 1000);
    }

     
    function updateCurrentGameCardId(uint256 _gameCardNumber, uint256 _playerId) public whenNotPaused {
        require (contractsApprovedList[msg.sender]);

        NFT memory obj  = _getAttributesOfToken(_playerId);
        
        obj.currentGameCardId = _gameCardNumber;
        
        if ( _gameCardNumber == 0 ) {
            obj.isAttached = 0;
        } else {
            obj.isAttached = 1;
        }

        allNFTs[_playerId] = obj;
    }

     
    function addAttachmentToCollectible ( 
        uint256 _tokenId,
        uint256 _attachment)
        external
        onlyManager
        whenNotPaused {
        require (exists(_tokenId));

        nftCollectibleAttachments[_tokenId].push(_attachment);
        emit AssetUpdated(_tokenId);
    }

     
    function removeAllAttachmentsFromCollectible(uint256 _tokenId)
        external
        onlyManager
        whenNotPaused {

        require (exists(_tokenId));
        
        delete nftCollectibleAttachments[_tokenId];
        emit AssetUpdated(_tokenId);
    }

     
    function giftAsset(address _to, uint256 _tokenId) public whenNotPaused {        
        safeTransferFrom(msg.sender, _to, _tokenId);
    }
    
     
    function setTokenURIBase (string _tokenURI) public anyOperator {
        _setTokenURIBase(_tokenURI);
    }

     
    function setPlayerOverrideId(uint256 _tokenId, uint256 _newOverrideId) public onlyManager whenNotPaused {
        require (exists(_tokenId));

        _updatePlayerOverrideId(_tokenId, _newOverrideId);
    }

     
    function updateGenerationStopTime(uint256 _season, uint8 _value ) public  onlyManager whenNotPaused {
        require (generationSeasonController[_season] == 1 && _value != 0);
        _updateGenerationSeasonFlag(_season, _value);
    }

     
    function setGenerationSeasonController(uint256 _season) public onlyManager whenNotPaused {
        require (generationSeasonController[_season] == 0);
        _updateGenerationSeasonFlag(_season, 1);
    }

     
    function updateGenerationDict(uint256 _season, uint64 _value) public onlyManager whenNotPaused {
        require (generationSeasonDict[_season] <= 1);
        generationSeasonDict[_season] = _value;
    }

     
    function getPlayerId(uint256 _tokenId) external view returns (uint256 playerId) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);
        playerId = ((obj.attributes.div(100000000000000000)) % 1000);
    }
    
     
    function getAssetAttachment(uint256 _tokenId) external view returns (uint256[]) {
        uint256[] _attachments = nftCollectibleAttachments[_tokenId];
        uint256[] attachments;
        for(uint i=0;i<_attachments.length;i++){
            attachments.push(_attachments[i]);
        }
        
        return attachments;
    }

     
    function updateEarnedBy(uint256 _tokenId, uint256 _earnedBy) public onlyManager whenNotPaused {
        require (exists(_tokenId));

        _updateEarnedBy(_tokenId, _earnedBy);
    }

     
    function batchCreateAsset(
        uint8[] _teamId,
        uint256[] _attributes,
        uint256[] _playerOverrideId,
        uint256[] _mlbPlayerId,
        address[] _to)
        external
        canCreate
        whenNotPaused {
            require (isBatchSupported);

            require (_teamId.length > 0 && _attributes.length > 0 && 
                _playerOverrideId.length > 0 && _mlbPlayerId.length > 0 && 
                _to.length > 0);

            uint256 assetDetails;
            uint256[5] memory _nftData;
            
            for(uint ii = 0; ii < _attributes.length; ii++){
                require (_to[ii] != address(0) && _teamId[ii] != 0 && _attributes.length != 0 && 
                    _mlbPlayerId[ii] != 0);
                
                assetDetails = uint256(uint64(now));
                assetDetails |= uint256(getSequenceId(_teamId[ii]))<<64;
                assetDetails |= uint256(_teamId[ii])<<96;
                assetDetails |= uint256((_attributes[ii]/1000000000000000000000000000000000000000)-800)<<104;
        
                _nftData = [assetDetails, _attributes[ii], 0, _playerOverrideId[ii], _mlbPlayerId[ii]];
                
                _createNFTCollectible(_teamId[ii], _attributes[ii], _to[ii], 0, _nftData);
            }
        }

     
    function batchCreateETHCardAsset(
        uint8[] _teamId,
        uint256[] _attributes,
        uint256[] _playerOverrideId,
        uint256[] _mlbPlayerId,
        address[] _to)
        external
        canCreate
        whenNotPaused {
            require (isBatchSupported);

            require (_teamId.length > 0 && _attributes.length > 0
                        && _playerOverrideId.length > 0 &&
                        _mlbPlayerId.length > 0 && _to.length > 0);

            uint256 assetDetails;
            uint256[5] memory _nftData;

            for(uint ii = 0; ii < _attributes.length; ii++){

                require (_to[ii] != address(0) && _teamId[ii] != 0 && _attributes.length != 0 && 
                    _mlbPlayerId[ii] != 0);
        
                assetDetails = uint256(uint64(now));
                assetDetails |= uint256(getSequenceId(_teamId[ii]))<<64;
                assetDetails |= uint256(_teamId[ii])<<96;
                assetDetails |= uint256((_attributes[ii]/1000000000000000000000000000000000000000)-800)<<104;
        
                _nftData = [assetDetails, _attributes[ii], 0, _playerOverrideId[ii], _mlbPlayerId[ii]];
                
                _createNFTCollectible(_teamId[ii], _attributes[ii], _to[ii], 2, _nftData);
            }
        }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
         
        require (checkIsAttached(_tokenId) == 0);
        
        require (_from != address(0));

        require (_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

     
    function multiBatchTransferFrom(
        uint256[] _tokenIds, 
        address[] _fromB, 
        address[] _toB) 
        public
    {
        require (isBatchSupported);

        require (_tokenIds.length > 0 && _fromB.length > 0 && _toB.length > 0);

        uint256 _id;
        address _to;
        address _from;
        
        for (uint256 i = 0; i < _tokenIds.length; ++i) {

            require (_tokenIds[i] != 0 && _fromB[i] != 0 && _toB[i] != 0);

            _id = _tokenIds[i];
            _to = _toB[i];
            _from = _fromB[i];

            transferFrom(_from, _to, _id);
        }
        
    }
    
     
    function batchTransferFrom(uint256[] _tokenIds, address _from, address _to) 
        public
    {
        require (isBatchSupported);

        require (_tokenIds.length > 0 && _from != address(0) && _to != address(0));

        uint256 _id;
        
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            
            require (_tokenIds[i] != 0);

            _id = _tokenIds[i];

            transferFrom(_from, _to, _id);
        }
    }
    
     
    function multiBatchSafeTransferFrom(
        uint256[] _tokenIds, 
        address[] _fromB, 
        address[] _toB
        )
        public
    {
        require (isBatchSupported);

        require (_tokenIds.length > 0 && _fromB.length > 0 && _toB.length > 0);

        uint256 _id;
        address _to;
        address _from;
        
        for (uint256 i = 0; i < _tokenIds.length; ++i) {

            require (_tokenIds[i] != 0 && _fromB[i] != 0 && _toB[i] != 0);

            _id = _tokenIds[i];
            _to  = _toB[i];
            _from  = _fromB[i];

            safeTransferFrom(_from, _to, _id);
        }
    }

     
    function batchSafeTransferFrom(
        uint256[] _tokenIds, 
        address _from, 
        address _to
        )
        public
    {   
        require (isBatchSupported);

        require (_tokenIds.length > 0 && _from != address(0) && _to != address(0));

        uint256 _id;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            require (_tokenIds[i] != 0);
            _id = _tokenIds[i];
            safeTransferFrom(_from, _to, _id);
        }
    }

     
    function batchApprove(
        uint256[] _tokenIds, 
        address _spender
        )
        public
    {   
        require (isBatchSupported);

        require (_tokenIds.length > 0 && _spender != address(0));
        
        uint256 _id;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {

            require (_tokenIds[i] != 0);
            
            _id = _tokenIds[i];
            approve(_spender, _id);
        }
        
    }

     
    function batchSetApprovalForAll(
        address[] _spenders,
        bool _approved
        )
        public
    {   
        require (isBatchSupported);

        require (_spenders.length > 0);

        address _spender;
        for (uint256 i = 0; i < _spenders.length; ++i) {        

            require (address(_spenders[i]) != address(0));
                
            _spender = _spenders[i];
            setApprovalForAll(_spender, _approved);
        }
    }  
    
     
    function requestDetachment(
        uint256 _tokenId
    )
        public
    {
         
        require (isApprovedOrOwner(msg.sender, _tokenId));

        uint256 isAttached = checkIsAttached(_tokenId);

         
        require(getGameCardId(_tokenId) == 0);

        require (isAttached >= 1);

        if(attachedSystemActive == true) {
             
            if(isAttached > 1 && block.timestamp - isAttached > detachmentTime) {
                isAttached = 0;
            } else if(isAttached > 1) {
                 
                require (isAttached == 1);
            } else {
                 
                 
                isAttached = block.timestamp;
            }
        } else {
            isAttached = 0;
        }

        updateIsAttached(_tokenId, isAttached);
    }

     
    function attachAsset(
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
        uint256 isAttached = checkIsAttached(_tokenId);

        require (isAttached == 0);
        isAttached = 1;

        updateIsAttached(_tokenId, isAttached);

        emit AssetUpdated(_tokenId);
    }

     
    function batchAttachAssets(uint256[] _tokenIds) public {
        require (isBatchSupported);

        for(uint i = 0; i < _tokenIds.length; i++) {
            attachAsset(_tokenIds[i]);
        }
    }

     
    function batchDetachAssets(uint256[] _tokenIds) public {
        require (isBatchSupported);

        for(uint i = 0; i < _tokenIds.length; i++) {
            requestDetachment(_tokenIds[i]);
        }
    }

     
    function requestDetachmentOnPause (uint256 _tokenId) public whenPaused {
         
        require (isApprovedOrOwner(msg.sender, _tokenId));

        updateIsAttached(_tokenId, 0);
    }

     
    function toggleAttachedEnforcement (bool _state) public onlyManager {
        attachedSystemActive = _state;
    }

     
    function setDetachmentTime (uint256 _time) public onlyManager {
         
        require (_time <= 1209600);
        detachmentTime = uint32(_time);
    }

     
    function setNFTDetached(uint256 _tokenId) public anyOperator {
        require (checkIsAttached(_tokenId) > 0);

        updateIsAttached(_tokenId, 0);
    }

     
    function setBatchDetachCollectibles(uint256[] _tokenIds) public anyOperator {
        uint256 _id;
        for(uint i = 0; i < _tokenIds.length; i++) {
            _id = _tokenIds[i];
            setNFTDetached(_id);
        }
    }

     
    function updateIsAttached(uint256 _tokenId, uint256 _isAttached) internal {
        NFT memory obj  = _getAttributesOfToken(_tokenId);
        
        obj.isAttached = _isAttached;
    
        allNFTs[_tokenId] = obj;
        emit AssetUpdated(_tokenId);
    }

     
    function initiateCreateSale(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external {
        require (_tokenId != 0);
        
         
         
        address owner = ownerOf(_tokenId);
        require (owner == msg.sender);

         
        require (_startingPrice == _startingPrice);
        require (_endingPrice == _endingPrice);
        require (_duration == _duration);

        require (checkIsAttached(_tokenId) == 0);
        
         
        _approveForSale(msg.sender, address(saleManagerAddress), _tokenId);

        saleManagerAddress.createSale(_tokenId, _startingPrice, _endingPrice, _duration, msg.sender);
    }

     
    function batchCreateAssetSale(uint256[] _tokenIds, uint256[] _startingPrices, uint256[] _endingPrices, uint256[] _durations) external whenNotPaused {

        require (_tokenIds.length > 0 && _startingPrices.length > 0 && _endingPrices.length > 0 && _durations.length > 0);
        
         
        for(uint ii = 0; ii < _tokenIds.length; ii++){

             
            require (_tokenIds[ii] != 0);
            
            require (_startingPrices[ii] == _startingPrices[ii]);
            require (_endingPrices[ii] == _endingPrices[ii]);
            require (_durations[ii] == _durations[ii]);

             
             
            address _owner = ownerOf(_tokenIds[ii]);
            address _msgSender = msg.sender;
            require (_owner == _msgSender);

             
            require (checkIsAttached(_tokenIds[ii]) == 0);
            
             
            _approveForSale(msg.sender, address(saleManagerAddress), _tokenIds[ii]);
            
            saleManagerAddress.createSale(_tokenIds[ii], _startingPrices[ii], _endingPrices[ii], _durations[ii], msg.sender);
        }
    }
}