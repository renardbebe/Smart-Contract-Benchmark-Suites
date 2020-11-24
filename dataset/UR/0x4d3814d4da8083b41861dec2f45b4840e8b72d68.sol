 

pragma solidity ^0.4.23;

 
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

 
library AddressUtils {

     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(addr) }
        return size > 0;
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
        require(msg.sender == managerPrimary || msg.sender == managerSecondary);
        _;
    }

    modifier onlyBanker() {
        require(msg.sender == bankManager);
        _;
    }

    modifier onlyOtherManagers() {
        require(otherManagers[msg.sender] == 1);
        _;
    }


    modifier anyOperator() {
        require(
            msg.sender == managerPrimary ||
            msg.sender == managerSecondary ||
            msg.sender == bankManager ||
            otherManagers[msg.sender] == 1
        );
        _;
    }

     
    function setOtherManager(address _newOp, uint8 _state) external onlyManager {
        require(_newOp != address(0));

        otherManagers[_newOp] = _state;
    }

     
    function setPrimaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerPrimary = _newGM;
    }

     
    function setSecondaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerSecondary = _newGM;
    }

     
    function setBanker(address _newBK) external onlyManager {
        require(_newBK != address(0));

        bankManager = _newBK;
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    modifier whenError {
        require(error);
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

 
contract ERC721Basic {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
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

     
     
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

     
    mapping (uint256 => address) internal tokenOwner;

     
    mapping (uint256 => address) internal tokenApprovals;

     
    mapping (address => uint256) internal ownedTokensCount;

     
    mapping (address => mapping (address => bool)) internal operatorApprovals;

     
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

     
    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

     
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

     
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

     
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        if (getApproved(_tokenId) != address(0) || _to != address(0)) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }

     
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

     
    function setApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender);
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
        require(_from != address(0));
        require(_to != address(0));

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
         
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
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
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

     
    function _burn(address _owner, uint256 _tokenId) internal {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);
    }

     
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }

     
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

     
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
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
        _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}

 
contract ERC721Receiver {
     
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

     
    function onERC721Received(
        address _from,
        uint256 _tokenId,
        bytes _data
    )
        public
        returns(bytes4);
}
contract ERC721Holder is ERC721Receiver {
    function onERC721Received(address, uint256, bytes) public returns(bytes4) {
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
        require(exists(_tokenId));
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
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

     
    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }

     
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
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
        ownedTokens[_from][lastTokenIndex] = 0;
         
         
         

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

contract CSCNFTFactory is ERC721Token, OperationalControl {

     
     
    event AssetCreated(address owner, uint256 assetId, uint256 assetType, uint256 sequenceId, uint256 creationTime);

    event DetachRequest(address owner, uint256 assetId, uint256 timestamp);

    event NFTDetached(address requester, uint256 assetId);

    event NFTAttached(address requester, uint256 assetId);

     
    mapping(uint256 => uint256) internal nftDataA;
    mapping(uint256 => uint128) internal nftDataB;

     
    mapping(uint32 => uint64) internal assetTypeTotalCount;

    mapping(uint32 => uint64) internal assetTypeBurnedCount;
  
     
    mapping(uint256 => mapping(uint32 => uint64) ) internal sequenceIDToTypeForID;

      
    mapping(uint256 => string) internal assetTypeName;

     
    mapping(uint256 => uint32) internal assetTypeCreationLimit;

     
    bool public attachedSystemActive;

     
    bool public canBurn;

     
    uint32 public detachmentTime = 300;

     
    constructor() public {
        require(msg.sender != address(0));
        paused = true;
        error = false;
        canBurn = false;
        managerPrimary = msg.sender;
        managerSecondary = msg.sender;
        bankManager = msg.sender;

        name_ = "CSCNFTFactory";
        symbol_ = "CSCNFT";
    }

     
    modifier canTransfer(uint256 _tokenId) {
        uint256 isAttached = getIsNFTAttached(_tokenId);
        if(isAttached == 2) {
             
            require(msg.sender == managerPrimary ||
                msg.sender == managerSecondary ||
                msg.sender == bankManager ||
                otherManagers[msg.sender] == 1
            );
            updateIsAttached(_tokenId, 1);
        } else if(attachedSystemActive == true && isAttached >= 1) {
            require(msg.sender == managerPrimary ||
                msg.sender == managerSecondary ||
                msg.sender == bankManager ||
                otherManagers[msg.sender] == 1
            );
        }
        else {
            require(isApprovedOrOwner(msg.sender, _tokenId));
        }
        
    _;
    }

     

     
    function getAssetIDForTypeSequenceID(uint256 _seqId, uint256 _type) public view returns (uint256 _assetID) {
        return sequenceIDToTypeForID[_seqId][uint32(_type)];
    }

    function getAssetDetails(uint256 _assetId) public view returns(
        uint256 assetId,
        uint256 ownersIndex,
        uint256 assetTypeSeqId,
        uint256 assetType,
        uint256 createdTimestamp,
        uint256 isAttached,
        address creator,
        address owner
    ) {
        require(exists(_assetId));

        uint256 nftData = nftDataA[_assetId];
        uint256 nftDataBLocal = nftDataB[_assetId];

        assetId = _assetId;
        ownersIndex = ownedTokensIndex[_assetId];
        createdTimestamp = uint256(uint48(nftData>>160));
        assetType = uint256(uint32(nftData>>208));
        assetTypeSeqId = uint256(uint64(nftDataBLocal));
        isAttached = uint256(uint48(nftDataBLocal>>64));
        creator = address(nftData);
        owner = ownerOf(_assetId);
    }

    function totalSupplyOfType(uint256 _type) public view returns (uint256 _totalOfType) {
        return assetTypeTotalCount[uint32(_type)] - assetTypeBurnedCount[uint32(_type)];
    }

    function totalCreatedOfType(uint256 _type) public view returns (uint256 _totalOfType) {
        return assetTypeTotalCount[uint32(_type)];
    }

    function totalBurnedOfType(uint256 _type) public view returns (uint256 _totalOfType) {
        return assetTypeBurnedCount[uint32(_type)];
    }

    function getAssetRawMeta(uint256 _assetId) public view returns(
        uint256 dataA,
        uint128 dataB
    ) {
        require(exists(_assetId));

        dataA = nftDataA[_assetId];
        dataB = nftDataB[_assetId];
    }

    function getAssetIdItemType(uint256 _assetId) public view returns(
        uint256 assetType
    ) {
        require(exists(_assetId));
        uint256 dataA = nftDataA[_assetId];
        assetType = uint256(uint32(dataA>>208));
    }

    function getAssetIdTypeSequenceId(uint256 _assetId) public view returns(
        uint256 assetTypeSequenceId
    ) {
        require(exists(_assetId));
        uint256 dataB = nftDataB[_assetId];
        assetTypeSequenceId = uint256(uint64(dataB));
    }
    
    function getIsNFTAttached( uint256 _assetId) 
    public view returns(
        uint256 isAttached
    ) {
        uint256 nftData = nftDataB[_assetId];
        isAttached = uint256(uint48(nftData>>64));
    }

    function getAssetIdCreator(uint256 _assetId) public view returns(
        address creator
    ) {
        require(exists(_assetId));
        uint256 dataA = nftDataA[_assetId];
        creator = address(dataA);
    }

    function isAssetIdOwnerOrApproved(address requesterAddress, uint256 _assetId) public view returns(
        bool
    ) {
        return isApprovedOrOwner(requesterAddress, _assetId);
    }

    function getAssetIdOwner(uint256 _assetId) public view returns(
        address owner
    ) {
        require(exists(_assetId));

        owner = ownerOf(_assetId);
    }

    function getAssetIdOwnerIndex(uint256 _assetId) public view returns(
        uint256 ownerIndex
    ) {
        require(exists(_assetId));
        ownerIndex = ownedTokensIndex[_assetId];
    }

     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;

             
             
            uint256 _itemIndex;

            for (_itemIndex = 0; _itemIndex < tokenCount; _itemIndex++) {
                result[resultIndex] = tokenOfOwnerByIndex(_owner,_itemIndex);
                resultIndex++;
            }

            return result;
        }
    }

     
    function getTypeName (uint32 _type) public returns(string) {
        return assetTypeName[_type];
    }


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }
    

    
    function multiBatchTransferFrom(
        uint256[] _assetIds, 
        address[] _fromB, 
        address[] _toB) 
        public
    {
        uint256 _id;
        address _to;
        address _from;
        
        for (uint256 i = 0; i < _assetIds.length; ++i) {
            _id = _assetIds[i];
            _to = _toB[i];
            _from = _fromB[i];

            require(isApprovedOrOwner(msg.sender, _id));

            require(_from != address(0));
            require(_to != address(0));
    
            clearApproval(_from, _id);
            removeTokenFrom(_from, _id);
            addTokenTo(_to, _id);
    
            emit Transfer(_from, _to, _id);
        }
        
    }
    
    function batchTransferFrom(uint256[] _assetIds, address _from, address _to) 
        public
    {
        uint256 _id;
        
        for (uint256 i = 0; i < _assetIds.length; ++i) {
            _id = _assetIds[i];

            require(isApprovedOrOwner(msg.sender, _id));

            require(_from != address(0));
            require(_to != address(0));
    
            clearApproval(_from, _id);
            removeTokenFrom(_from, _id);
            addTokenTo(_to, _id);
    
            emit Transfer(_from, _to, _id);
        }
    }
    
    function multiBatchSafeTransferFrom(
        uint256[] _assetIds, 
        address[] _fromB, 
        address[] _toB
        )
        public
    {
        uint256 _id;
        address _to;
        address _from;
        
        for (uint256 i = 0; i < _assetIds.length; ++i) {
            _id = _assetIds[i];
            _to  = _toB[i];
            _from  = _fromB[i];

            safeTransferFrom(_from, _to, _id);
        }
    }

    function batchSafeTransferFrom(
        uint256[] _assetIds, 
        address _from, 
        address _to
        )
        public
    {
        uint256 _id;
        for (uint256 i = 0; i < _assetIds.length; ++i) {
            _id = _assetIds[i];
            safeTransferFrom(_from, _to, _id);
        }
    }


    function batchApprove(
        uint256[] _assetIds, 
        address _spender
        )
        public
    {
        uint256 _id;
        for (uint256 i = 0; i < _assetIds.length; ++i) {
            _id = _assetIds[i];
            approve(_spender, _id);
        }
        
    }


    function batchSetApprovalForAll(
        address[] _spenders,
        bool _approved
        )
        public
    {
        address _spender;
        for (uint256 i = 0; i < _spenders.length; ++i) {
            _spender = _spenders[i];
            setApprovalForAll(_spender, _approved);
        }
    }  
    
    function requestDetachment(
        uint256 _tokenId
    )
        public
    {
         
        require(isApprovedOrOwner(msg.sender, _tokenId));

        uint256 isAttached = getIsNFTAttached(_tokenId);

        require(isAttached >= 1);

        if(attachedSystemActive == true) {
             
            if(isAttached > 1 && block.timestamp - isAttached > detachmentTime) {
                isAttached = 0;
            } else if(isAttached > 1) {
                 
                require(isAttached == 1);
            } else {
                 
                emit DetachRequest(msg.sender, _tokenId, block.timestamp);
                isAttached = block.timestamp;
            }           
        } else {
            isAttached = 0;
        } 

        if(isAttached == 0) {
            emit NFTDetached(msg.sender, _tokenId);
        }

        updateIsAttached(_tokenId, isAttached);
    }

    function attachAsset(
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
        uint256 isAttached = getIsNFTAttached(_tokenId);

        require(isAttached == 0);
        isAttached = 1;

        updateIsAttached(_tokenId, isAttached);

        emit NFTAttached(msg.sender, _tokenId);
    }

    function batchAttachAssets(uint256[] _ids) public {
        for(uint i = 0; i < _ids.length; i++) {
            attachAsset(_ids[i]);
        }
    }

    function batchDetachAssets(uint256[] _ids) public {
        for(uint i = 0; i < _ids.length; i++) {
            requestDetachment(_ids[i]);
        }
    }

    function requestDetachmentOnPause (uint256 _tokenId) public 
    whenPaused {
         
        require(isApprovedOrOwner(msg.sender, _tokenId));

        updateIsAttached(_tokenId, 0);
    }

    function batchBurnAssets(uint256[] _assetIDs) public {
        uint256 _id;
        for(uint i = 0; i < _assetIDs.length; i++) {
            _id = _assetIDs[i];
            burnAsset(_id);
        }
    }

    function burnAsset(uint256 _assetID) public {
         
        require(canBurn == true);

         
        require(getIsNFTAttached(_assetID) == 0);

        require(isApprovedOrOwner(msg.sender, _assetID) == true);
        
         
        uint256 _assetType = getAssetIdItemType(_assetID);
        assetTypeBurnedCount[uint32(_assetType)] += 1;
        
        _burn(msg.sender, _assetID);
    }


     

    function setTokenURIBase (string _tokenURI) public onlyManager {
        _setTokenURIBase(_tokenURI);
    }

    function setPermanentLimitForType (uint32 _type, uint256 _limit) public onlyManager {
         
        require(assetTypeCreationLimit[_type] == 0);

        assetTypeCreationLimit[_type] = uint32(_limit);
    }

    function setTypeName (uint32 _type, string _name) public anyOperator {
        assetTypeName[_type] = _name;
    }

     
    function batchSpawnAsset(address _to, uint256[] _assetTypes, uint256[] _assetIds, uint256 _isAttached) public anyOperator {
        uint256 _id;
        uint256 _assetType;
        for(uint i = 0; i < _assetIds.length; i++) {
            _id = _assetIds[i];
            _assetType = _assetTypes[i];
            _createAsset(_to, _assetType, _id, _isAttached, address(0));
        }
    }

    function batchSpawnAsset(address[] _toB, uint256[] _assetTypes, uint256[] _assetIds, uint256 _isAttached) public anyOperator {
        address _to;
        uint256 _id;
        uint256 _assetType;
        for(uint i = 0; i < _assetIds.length; i++) {
            _to = _toB[i];
            _id = _assetIds[i];
            _assetType = _assetTypes[i];
            _createAsset(_to, _assetType, _id, _isAttached, address(0));
        }
    }

    function batchSpawnAssetWithCreator(address[] _toB, uint256[] _assetTypes, uint256[] _assetIds, uint256[] _isAttacheds, address[] _creators) public anyOperator {
        address _to;
        address _creator;
        uint256 _id;
        uint256 _assetType;
        uint256 _isAttached;
        for(uint i = 0; i < _assetIds.length; i++) {
            _to = _toB[i];
            _id = _assetIds[i];
            _assetType = _assetTypes[i];
            _creator = _creators[i];
            _isAttached = _isAttacheds[i];
            _createAsset(_to, _assetType, _id, _isAttached, _creator);
        }
    }

    function spawnAsset(address _to, uint256 _assetType, uint256 _assetID, uint256 _isAttached) public anyOperator {
        _createAsset(_to, _assetType, _assetID, _isAttached, address(0));
    }

    function spawnAssetWithCreator(address _to, uint256 _assetType, uint256 _assetID, uint256 _isAttached, address _creator) public anyOperator {
        _createAsset(_to, _assetType, _assetID, _isAttached, _creator);
    }

     
    function withdrawBalance() public onlyBanker {
         
        bankManager.transfer(address(this).balance);
    }

     

    function setCanBurn(bool _state) public onlyManager {
        canBurn = _state;
    }

    function burnAssetOperator(uint256 _assetID) public anyOperator {
        
        require(getIsNFTAttached(_assetID) > 0);

         
        uint256 _assetType = getAssetIdItemType(_assetID);
        assetTypeBurnedCount[uint32(_assetType)] += 1;
        
        _burn(ownerOf(_assetID), _assetID);
    }

    function toggleAttachedEnforement (bool _state) public onlyManager {
        attachedSystemActive = _state;
    }

    function setDetachmentTime (uint256 _time) public onlyManager {
         
        require(_time <= 1209600);
        detachmentTime = uint32(_time);
    }

    function setNFTDetached(uint256 _assetID) public anyOperator {
        require(getIsNFTAttached(_assetID) > 0);

        updateIsAttached(_assetID, 0);
        emit NFTDetached(msg.sender, _assetID);
    }

    function setBatchDetachCollectibles(uint256[] _assetIds) public anyOperator {
        uint256 _id;
        for(uint i = 0; i < _assetIds.length; i++) {
            _id = _assetIds[i];
            setNFTDetached(_id);
        }
    }



     

     
    function _createAsset(address _to, uint256 _assetType, uint256 _assetID, uint256 _attachState, address _creator) internal returns(uint256) {
        
        uint256 _sequenceId = uint256(assetTypeTotalCount[uint32(_assetType)]) + 1;

         
        require(assetTypeCreationLimit[uint32(_assetType)] == 0 || assetTypeCreationLimit[uint32(_assetType)] > _sequenceId);
        
         
         
        require(_sequenceId == uint256(uint64(_sequenceId)));

         
        _mint(_to, _assetID);

        uint256 nftData = uint256(_creator);  
        nftData |= now<<160;  
        nftData |= _assetType<<208;  

        uint256 nftDataContinued = uint256(_sequenceId);  
        nftDataContinued |= _attachState<<64;  

        nftDataA[_assetID] = nftData;
        nftDataB[_assetID] = uint128(nftDataContinued);

        assetTypeTotalCount[uint32(_assetType)] += 1;
        sequenceIDToTypeForID[_sequenceId][uint32(_assetType)] = uint64(_assetID);

         
        emit AssetCreated(_to, _assetID, _assetType, _sequenceId, now);

        return _assetID;
    }

    function updateIsAttached(uint256 _assetID, uint256 _isAttached) 
    internal
    {
        uint256 nftData = nftDataB[_assetID];

        uint256 assetTypeSeqId = uint256(uint64(nftData));

        uint256 nftDataContinued = uint256(assetTypeSeqId);  
        nftDataContinued |= _isAttached<<64;  

        nftDataB[_assetID] = uint128(nftDataContinued);
    }



}