 

pragma solidity ^0.4.24;

 

 
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

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


 
interface ERC721   {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _tokenOwner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _tokenOwner, address indexed _operator, bool _approved);

    function balanceOf(address _tokenOwner) external view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) external view returns (address _tokenOwner);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _to, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address _operator);
    function isApprovedForAll(address _tokenOwner, address _operator) external view returns (bool);
}
 
 
 
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721TokenReceiver {
     
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
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

 
interface ERC998ERC721BottomUp {
    event TransferToParent(address indexed _toContract, uint256 indexed _toTokenId, uint256 _tokenId);
    event TransferFromParent(address indexed _fromContract, uint256 indexed _fromTokenId, uint256 _tokenId);


    function rootOwnerOf(uint256 _tokenId) public view returns (bytes32 rootOwner);

     
    function tokenOwnerOf(uint256 _tokenId) external view returns (bytes32 tokenOwner, uint256 parentTokenId, bool isParent);

     
    function transferToParent(address _from, address _toContract, uint256 _toTokenId, uint256 _tokenId, bytes _data) public;
     
    function transferFromParent(address _fromContract, uint256 _fromTokenId, address _to, uint256 _tokenId, bytes _data) public;
     
    function transferAsChild(address _fromContract, uint256 _fromTokenId, address _toContract, uint256 _toTokenId, uint256 _tokenId, bytes _data) external;

}

 
interface ERC998ERC721BottomUpEnumerable {
    function totalChildTokens(address _parentContract, uint256 _parentTokenId) external view returns (uint256);
    function childTokenByIndex(address _parentContract, uint256 _parentTokenId, uint256 _index) external view returns (uint256);
}

contract ERC998ERC721BottomUpToken is ERC721, ERC721Metadata, ERC721Enumerable, ERC165, ERC998ERC721BottomUp, ERC998ERC721BottomUpEnumerable {
    using SafeMath for uint256;

    struct TokenOwner {
        address tokenOwner;
        uint256 parentTokenId;
    }

     
     
    bytes32 constant ERC998_MAGIC_VALUE = 0xcd740db5;

     
    uint256 internal tokenCount;

     
    mapping(uint256 => TokenOwner) internal tokenIdToTokenOwner;

     
    mapping(address => uint256[]) internal ownedTokens;

     
    mapping(uint256 => uint256) internal ownedTokensIndex;

     
    mapping(address => mapping(uint256 => address)) internal rootOwnerAndTokenIdToApprovedAddress;

     
    mapping(address => mapping(uint256 => uint256[])) internal parentToChildTokenIds;

     
    mapping(uint256 => uint256) internal tokenIdToChildTokenIdsIndex;

     
    mapping(address => mapping(address => bool)) internal tokenOwnerToOperators;

     
    string internal name_;

     
    string internal symbol_;

     
    string internal tokenURIBase;

    mapping(bytes4 => bool) internal supportedInterfaces;

     
     
    bytes4 constant ERC721_RECEIVED = 0x150b7a02;

    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(_addr)}
        return size > 0;
    }

    constructor () public {
         
        supportedInterfaces[0x01ffc9a7] = true;
         
        supportedInterfaces[0x80ac58cd] = true;
         
        supportedInterfaces[0x5b5e139f] = true;
         
        supportedInterfaces[0x780e9d63] = true;
         
        supportedInterfaces[0xa1b23002] = true;
         
        supportedInterfaces[0x8318b539] = true;
    }

     
     
     
     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

     
     
     
     
     
    function balanceOf(address _tokenOwner) public view returns (uint256) {
        require(_tokenOwner != address(0));
        return ownedTokens[_tokenOwner].length;
    }

     
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address tokenOwner = tokenIdToTokenOwner[_tokenId].tokenOwner;
        require(tokenOwner != address(0));
        return tokenOwner;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        require(_to != address(this));
        _transferFromOwnerCheck(_from, _to, _tokenId);
        _transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _transferFromOwnerCheck(_from, _to, _tokenId);
        _transferFrom(_from, _to, _tokenId);
        require(_checkAndCallSafeTransfer(_from, _to, _tokenId, ""));

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
        _transferFromOwnerCheck(_from, _to, _tokenId);
        _transferFrom(_from, _to, _tokenId);
        require(_checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

    function _checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal view returns (bool) {
        if (!isContract(_to)) {
            return true;
        }
        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }

    function _transferFromOwnerCheck(address _from, address _to, uint256 _tokenId) internal {
        require(_from != address(0));
        require(_to != address(0));
        require(tokenIdToTokenOwner[_tokenId].tokenOwner == _from);
        require(tokenIdToTokenOwner[_tokenId].parentTokenId == 0);

         
        address approvedAddress = rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId];
        if(msg.sender != _from) {
            bytes32 tokenOwner;
            bool callSuccess;
             
            bytes memory calldata = abi.encodeWithSelector(0xed81cdda, address(this), _tokenId);
            assembly {
                callSuccess := staticcall(gas, _from, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                if callSuccess {
                    tokenOwner := mload(calldata)
                }
            }
            if(callSuccess == true) {
                require(tokenOwner >> 224 != ERC998_MAGIC_VALUE);
            }
            require(tokenOwnerToOperators[_from][msg.sender] || approvedAddress == msg.sender);
        }

         
        if (approvedAddress != address(0)) {
            delete rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId];
            emit Approval(_from, address(0), _tokenId);
        }
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) internal {
         
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastTokenId = ownedTokens[_from][lastTokenIndex];
        if (lastTokenId != _tokenId) {
             
             
             
            uint256 tokenIndex = ownedTokensIndex[_tokenId];
            ownedTokens[_from][tokenIndex] = lastTokenId;
            ownedTokensIndex[lastTokenId] = tokenIndex;
        }

         
        ownedTokens[_from].length--;

         
        tokenIdToTokenOwner[_tokenId].tokenOwner = _to;
        
         
        ownedTokensIndex[_tokenId] = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external {
        address tokenOwner = tokenIdToTokenOwner[_tokenId].tokenOwner;
        require(tokenOwner != address(0));
        address rootOwner = address(rootOwnerOf(_tokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender]);

        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] = _approved;
        emit Approval(rootOwner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address)  {
        address rootOwner = address(rootOwnerOf(_tokenId));
        return rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != address(0));
        tokenOwnerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool)  {
        require(_owner != address(0));
        require(_operator != address(0));
        return tokenOwnerToOperators[_owner][_operator];
    }

    function _tokenOwnerOf(uint256 _tokenId) internal view returns (address tokenOwner, uint256 parentTokenId, bool isParent) {
        tokenOwner = tokenIdToTokenOwner[_tokenId].tokenOwner;
        require(tokenOwner != address(0));
        parentTokenId = tokenIdToTokenOwner[_tokenId].parentTokenId;
        if (parentTokenId > 0) {
            isParent = true;
            parentTokenId--;
        }
        else {
            isParent = false;
        }
        return (tokenOwner, parentTokenId, isParent);
    }

    
    function tokenOwnerOf(uint256 _tokenId) external view returns (bytes32 tokenOwner, uint256 parentTokenId, bool isParent) {
        address tokenOwnerAddress = tokenIdToTokenOwner[_tokenId].tokenOwner;
        require(tokenOwnerAddress != address(0));
        parentTokenId = tokenIdToTokenOwner[_tokenId].parentTokenId;
        if (parentTokenId > 0) {
            isParent = true;
            parentTokenId--;
        }
        else {
            isParent = false;
        }
        return (ERC998_MAGIC_VALUE << 224 | bytes32(tokenOwnerAddress), parentTokenId, isParent);
    }

     
     
     
     
     
     
     
     
     
     
    function rootOwnerOf(uint256 _tokenId) public view returns (bytes32 rootOwner) {
        address rootOwnerAddress = tokenIdToTokenOwner[_tokenId].tokenOwner;
        require(rootOwnerAddress != address(0));
        uint256 parentTokenId = tokenIdToTokenOwner[_tokenId].parentTokenId;
        bool isParent = parentTokenId > 0;
        if (isParent) {
            parentTokenId--;
        }

        if((rootOwnerAddress == address(this))) {
            do {
                if(isParent == false) {
                     
                     
                    return ERC998_MAGIC_VALUE << 224 | bytes32(rootOwnerAddress);
                }
                else {
                     
                    (rootOwnerAddress, parentTokenId, isParent) = _tokenOwnerOf(parentTokenId);
                }
            } while(rootOwnerAddress == address(this));
            _tokenId = parentTokenId;
        }

        bytes memory calldata;
        bool callSuccess;

        if (isParent == false) {

             
             
            calldata = abi.encodeWithSelector(0xed81cdda, address(this), _tokenId);
            assembly {
                callSuccess := staticcall(gas, rootOwnerAddress, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                if callSuccess {
                    rootOwner := mload(calldata)
                }
            }
            if(callSuccess == true && rootOwner >> 224 == ERC998_MAGIC_VALUE) {
                 
                return rootOwner;
            }
            else {
                 
                 
                 
                return ERC998_MAGIC_VALUE << 224 | bytes32(rootOwnerAddress);
            }
        }
        else {

             
            calldata = abi.encodeWithSelector(0x43a61a8e, parentTokenId);
            assembly {
                callSuccess := staticcall(gas, rootOwnerAddress, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                if callSuccess {
                    rootOwner := mload(calldata)
                }
            }
            if (callSuccess == true && rootOwner >> 224 == ERC998_MAGIC_VALUE) {
                 
                 
                 
                return rootOwner;
            }
            else {
                 
                address childContract = rootOwnerAddress;
                 
                calldata = abi.encodeWithSelector(0x6352211e, parentTokenId);
                assembly {
                    callSuccess := staticcall(gas, rootOwnerAddress, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                    if callSuccess {
                        rootOwnerAddress := mload(calldata)
                    }
                }
                require(callSuccess);

                 
                calldata = abi.encodeWithSelector(0xed81cdda, childContract, parentTokenId);
                assembly {
                    callSuccess := staticcall(gas, rootOwnerAddress, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                    if callSuccess {
                        rootOwner := mload(calldata)
                    }
                }
                if(callSuccess == true && rootOwner >> 224 == ERC998_MAGIC_VALUE) {
                     
                    return rootOwner;
                }
                else {
                     
                     
                     
                    return ERC998_MAGIC_VALUE << 224 | bytes32(rootOwnerAddress);
                }
            }
        }
    }

     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        return ownedTokens[_owner];
    }

     
     
     
     
     

    function tokenURI(uint256 _tokenId) external view returns (string) {
        require (exists(_tokenId));
        return _appendUintToString(tokenURIBase, _tokenId);
    }

    function name() external view returns (string) {
        return name_;
    }

    function symbol() external view returns (string) {
        return symbol_;
    }

    function _appendUintToString(string inStr, uint v) private pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }

     
     
     
     
     

    function exists(uint256 _tokenId) public view returns (bool) {
        return _tokenId < tokenCount;
    }
 
    function totalSupply() external view returns (uint256) {
        return tokenCount;
    }

    function tokenOfOwnerByIndex(address _tokenOwner, uint256 _index) external view returns (uint256 tokenId) {
        require(_index < ownedTokens[_tokenOwner].length);
        return ownedTokens[_tokenOwner][_index];
    }

    function tokenByIndex(uint256 _index) external view returns (uint256 tokenId) {
        require(_index < tokenCount);
        return _index;
    }

    function _mint(address _to, uint256 _tokenId) internal {
        require (_to != address(0));
        require (tokenIdToTokenOwner[_tokenId].tokenOwner == address(0));
        tokenIdToTokenOwner[_tokenId].tokenOwner = _to;
        ownedTokensIndex[_tokenId] = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        tokenCount++;

        emit Transfer(address(0), _to, _tokenId);
    }

     
     
     
     
     

    function _removeChild(address _fromContract, uint256 _fromTokenId, uint256 _tokenId) internal {
        uint256 lastChildTokenIndex = parentToChildTokenIds[_fromContract][_fromTokenId].length - 1;
        uint256 lastChildTokenId = parentToChildTokenIds[_fromContract][_fromTokenId][lastChildTokenIndex];

        if (_tokenId != lastChildTokenId) {
            uint256 currentChildTokenIndex = tokenIdToChildTokenIdsIndex[_tokenId];
            parentToChildTokenIds[_fromContract][_fromTokenId][currentChildTokenIndex] = lastChildTokenId;
            tokenIdToChildTokenIdsIndex[lastChildTokenId] = currentChildTokenIndex;
        }
        parentToChildTokenIds[_fromContract][_fromTokenId].length--;
    }

    function _transferChild(address _from, address _toContract, uint256 _toTokenId, uint256 _tokenId) internal {
        tokenIdToTokenOwner[_tokenId].parentTokenId = _toTokenId.add(1);
        uint256 index = parentToChildTokenIds[_toContract][_toTokenId].length;
        parentToChildTokenIds[_toContract][_toTokenId].push(_tokenId);
        tokenIdToChildTokenIdsIndex[_tokenId] = index;

        _transferFrom(_from, _toContract, _tokenId);
        
        require(ERC721(_toContract).ownerOf(_toTokenId) != address(0));
        emit TransferToParent(_toContract, _toTokenId, _tokenId);
    }

    function _removeFromToken(address _fromContract, uint256 _fromTokenId, address _to, uint256 _tokenId) internal {
        require(_fromContract != address(0));
        require(_to != address(0));
        require(tokenIdToTokenOwner[_tokenId].tokenOwner == _fromContract);
        uint256 parentTokenId = tokenIdToTokenOwner[_tokenId].parentTokenId;
        require(parentTokenId != 0);
        require(parentTokenId - 1 == _fromTokenId);

         
        address rootOwner = address(rootOwnerOf(_tokenId));
        address approvedAddress = rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] || approvedAddress == msg.sender);

         
        if (approvedAddress != address(0)) {
            delete rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
            emit Approval(rootOwner, address(0), _tokenId);
        }

        tokenIdToTokenOwner[_tokenId].parentTokenId = 0;

        _removeChild(_fromContract, _fromTokenId, _tokenId);
        emit TransferFromParent(_fromContract, _fromTokenId, _tokenId);
    }

    function transferFromParent(address _fromContract, uint256 _fromTokenId, address _to, uint256 _tokenId, bytes _data) public {
        _removeFromToken(_fromContract, _fromTokenId, _to, _tokenId);
        delete tokenIdToChildTokenIdsIndex[_tokenId];
        _transferFrom(_fromContract, _to, _tokenId);
        require(_checkAndCallSafeTransfer(_fromContract, _to, _tokenId, _data));
    }

    function transferToParent(address _from, address _toContract, uint256 _toTokenId, uint256 _tokenId, bytes _data) public {
        _transferFromOwnerCheck(_from, _toContract, _tokenId);
        _transferChild(_from, _toContract, _toTokenId, _tokenId);
    }

    function transferAsChild(address _fromContract, uint256 _fromTokenId, address _toContract, uint256 _toTokenId, uint256 _tokenId, bytes _data) external {
        _removeFromToken(_fromContract, _fromTokenId, _toContract, _tokenId);
        _transferChild(_fromContract, _toContract, _toTokenId, _tokenId);
    }

     
     
     
     
     

    function totalChildTokens(address _parentContract, uint256 _parentTokenId) public view returns (uint256) {
        return parentToChildTokenIds[_parentContract][_parentTokenId].length;
    }

    function childTokenByIndex(address _parentContract, uint256 _parentTokenId, uint256 _index) public view returns (uint256) {
        require(parentToChildTokenIds[_parentContract][_parentTokenId].length > _index);
        return parentToChildTokenIds[_parentContract][_parentTokenId][_index];
    }
}


contract CryptoRomeControl {

     
    event ContractUpgrade(address newContract);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    address public ownerPrimary;
    address public ownerSecondary;

     
    address public ownerWallet;
    address public cryptoRomeWallet;

     
     
    mapping(address => uint8) public otherOperators;

     
     
     
    address public improvementContract;

     
    bool public paused = false;

    constructor() public {
        ownerPrimary = msg.sender;
        ownerSecondary = msg.sender;
        ownerWallet = msg.sender;
        cryptoRomeWallet = msg.sender;
    }

    modifier onlyOwner() {
        require (msg.sender == ownerPrimary || msg.sender == ownerSecondary);
        _;
    }

    modifier anyOperator() {
        require (
            msg.sender == ownerPrimary ||
            msg.sender == ownerSecondary ||
            otherOperators[msg.sender] == 1
        );
        _;
    }

    modifier onlyOtherOperators() {
        require (otherOperators[msg.sender] == 1);
        _;
    }

    modifier onlyImprovementContract() {
        require (msg.sender == improvementContract);
        _;
    }

    function setPrimaryOwner(address _newOwner) external onlyOwner {
        require (_newOwner != address(0));
        emit OwnershipTransferred(ownerPrimary, _newOwner);
        ownerPrimary = _newOwner;
    }

    function setSecondaryOwner(address _newOwner) external onlyOwner {
        require (_newOwner != address(0));
        emit OwnershipTransferred(ownerSecondary, _newOwner);
        ownerSecondary = _newOwner;
    }

    function setOtherOperator(address _newOperator, uint8 _state) external onlyOwner {
        require (_newOperator != address(0));
        otherOperators[_newOperator] = _state;
    }

    function setImprovementContract(address _improvementContract) external onlyOwner {
        require (_improvementContract != address(0));
        emit OwnershipTransferred(improvementContract, _improvementContract);
        improvementContract = _improvementContract;
    }

    function transferOwnerWalletOwnership(address newWalletAddress) onlyOwner external {
        require(newWalletAddress != address(0));
        ownerWallet = newWalletAddress;
    }

    function transferCryptoRomeWalletOwnership(address newWalletAddress) onlyOwner external {
        require(newWalletAddress != address(0));
        cryptoRomeWallet = newWalletAddress;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
    }

    function withdrawBalance() public onlyOwner {
        ownerWallet.transfer(address(this).balance);
    }
}

contract CryptoRomeLandComposableNFT is ERC998ERC721BottomUpToken, CryptoRomeControl {
    using SafeMath for uint256;

     
    address public newContractAddress;

    struct LandInfo {
        uint256 landType;   
        uint256 landImprovements; 
        uint256 askingPrice;
    }

    mapping(uint256 => LandInfo) internal tokenIdToLand;

     
     
    uint256[] internal allLandForSaleState;

     
    mapping(uint256 => uint256) internal landTypeToCount;

     
    uint256 constant internal MAX_VILLAGES = 50000;

    constructor () public {
        paused = true;
        name_ = "CryptoRome-Land-NFT";
        symbol_ = "CRLAND";
    }

    function isCryptoRomeLandComposableNFT() external pure returns (bool) {
        return true;
    }

    function getLandTypeCount(uint256 _landType) public view returns (uint256) {
        return landTypeToCount[_landType];
    }

    function setTokenURI(string _tokenURI) external anyOperator {
        tokenURIBase = _tokenURI;
    }

    function setNewAddress(address _v2Address) external onlyOwner {
        require (_v2Address != address(0));
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function getLand(uint256 _tokenId) external view
        returns (
            address tokenOwner,
            uint256 parentTokenId,
            uint256 landType,
            uint256 landImprovements,
            uint256 askingPrice
        ) {
        TokenOwner storage owner = tokenIdToTokenOwner[_tokenId];
        LandInfo storage land = tokenIdToLand[_tokenId];

        parentTokenId = owner.parentTokenId;
        if (parentTokenId > 0) {
            parentTokenId--;
        }
        tokenOwner = owner.tokenOwner;
        parentTokenId = owner.parentTokenId;
        landType = land.landType;
        landImprovements = land.landImprovements;
        askingPrice = land.askingPrice;
    }

     
     
     
     
     
     
    function _createLand (address _tokenOwner, uint256 _landType, uint256 _landImprovements) internal returns (uint256 tokenId) {
        require(_tokenOwner != address(0));
        require(landTypeToCount[1] < MAX_VILLAGES);
        tokenId = tokenCount;

        LandInfo memory land = LandInfo({
            landType: _landType,   
            landImprovements: _landImprovements,
            askingPrice: 0
        });
        
         
        tokenIdToLand[tokenId] = land;
        landTypeToCount[_landType]++;

        if (tokenId % 256 == 0) {
             
            allLandForSaleState.push(0);
        }

        _mint(_tokenOwner, tokenId);

        return tokenId;
    }
    
    function createLand (address _tokenOwner, uint256 _landType, uint256 _landImprovements) external anyOperator whenNotPaused returns (uint256 tokenId) {
        return _createLand (_tokenOwner, _landType, _landImprovements);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function getLandImprovementData(uint256 _tokenId) external view returns (uint256) {
        return tokenIdToLand[_tokenId].landImprovements;
    }

    function updateLandImprovementData(uint256 _tokenId, uint256 _newLandImprovementData) external whenNotPaused onlyImprovementContract {
        require(_tokenId <= tokenCount);
        tokenIdToLand[_tokenId].landImprovements = _newLandImprovementData;
    }

     
     
     
     
     

     
     
     
    function composeNewLand(uint256 _landType, uint256 _childLand1, uint256 _childLand2, uint256 _childLand3) external whenNotPaused returns(uint256) {
        uint256 parentTokenId = _createLand(msg.sender, _landType, 0);
        return composeLand(parentTokenId, _childLand1, _childLand2, _childLand3);
    }

     
     
     
    function composeLand(uint256 _parentLandId, uint256 _childLand1, uint256 _childLand2, uint256 _childLand3) public whenNotPaused returns(uint256) {
        require (tokenIdToLand[_parentLandId].landType == 2 || tokenIdToLand[_parentLandId].landType == 3);
        uint256 validChildLandType = tokenIdToLand[_parentLandId].landType.sub(1);
        require(tokenIdToLand[_childLand1].landType == validChildLandType &&
                tokenIdToLand[_childLand2].landType == validChildLandType &&
                tokenIdToLand[_childLand3].landType == validChildLandType);

         
        transferToParent(tokenIdToTokenOwner[_childLand1].tokenOwner, address(this), _parentLandId, _childLand1, "");
        transferToParent(tokenIdToTokenOwner[_childLand2].tokenOwner, address(this), _parentLandId, _childLand2, "");
        transferToParent(tokenIdToTokenOwner[_childLand3].tokenOwner, address(this), _parentLandId, _childLand3, "");

         
        if (tokenIdToTokenOwner[_parentLandId].tokenOwner == address(this)) {
            _transferFrom(address(this), msg.sender, _parentLandId);
        }

        return _parentLandId;
    }

     
     
     
     
    function decomposeLand(uint256 _tokenId) external whenNotPaused {
        uint256 numChildren = totalChildTokens(address(this), _tokenId);
        require (numChildren > 0);

         
        for (uint256 numChild = numChildren; numChild > 0; numChild--) {
            uint256 childTokenId = childTokenByIndex(address(this), _tokenId, numChild-1);

             
            transferFromParent(address(this), _tokenId, msg.sender, childTokenId, "");
        }

         
        _transferFrom(msg.sender, address(this), _tokenId);
    }

     
     
     
    function _updateSaleData(uint256 _tokenId, uint256 _askingPrice) internal {
        tokenIdToLand[_tokenId].askingPrice = _askingPrice;
        if (_askingPrice > 0) {
             
            allLandForSaleState[_tokenId.div(256)] = allLandForSaleState[_tokenId.div(256)] | (1 << (_tokenId % 256));
        } else {
             
            allLandForSaleState[_tokenId.div(256)] = allLandForSaleState[_tokenId.div(256)] & ~(1 << (_tokenId % 256));
        }
    }

    function sellLand(uint256 _tokenId, uint256 _askingPrice) public whenNotPaused {
        require(tokenIdToTokenOwner[_tokenId].tokenOwner == msg.sender);
        require(tokenIdToTokenOwner[_tokenId].parentTokenId == 0);
        require(_askingPrice > 0);
         
        _updateSaleData(_tokenId, _askingPrice);
    }

    function cancelLandSale(uint256 _tokenId) public whenNotPaused {
        require(tokenIdToTokenOwner[_tokenId].tokenOwner == msg.sender);
         
        _updateSaleData(_tokenId, 0);
    }

    function purchaseLand(uint256 _tokenId) public whenNotPaused payable {
        uint256 price = tokenIdToLand[_tokenId].askingPrice;
        require(price <= msg.value);

         
        _updateSaleData(_tokenId, 0);

         
        uint256 marketFee = computeFee(price);
        uint256 sellerProceeds = msg.value.sub(marketFee);
        cryptoRomeWallet.transfer(marketFee);

         
        uint256 excessPayment = msg.value.sub(price);
        msg.sender.transfer(excessPayment);

         
         
        tokenIdToTokenOwner[_tokenId].tokenOwner.transfer(sellerProceeds);
         
        _transferFrom(tokenIdToTokenOwner[_tokenId].tokenOwner, msg.sender, _tokenId);
    }

    function getAllForSaleStatus() external view returns(uint256[]) {
         
         
         
        return allLandForSaleState;
    }

    function computeFee(uint256 amount) internal pure returns(uint256) {
         
        return amount.mul(3).div(100);
    }
}

contract CryptoRomeLandDistribution is CryptoRomeControl {
    using SafeMath for uint256;

     
    address public newContractAddress;

    CryptoRomeLandComposableNFT public cryptoRomeLandNFTContract;
    ImprovementGeneration public improvementGenContract;
    uint256 public villageInventoryPrice;
    uint256 public numImprovementsPerVillage;

    uint256 constant public LOWEST_VILLAGE_INVENTORY_PRICE = 100000000000000000;  

    constructor (address _cryptoRomeLandNFTContractAddress, address _improvementGenContractAddress) public {
        require (_cryptoRomeLandNFTContractAddress != address(0));
        require (_improvementGenContractAddress != address(0));

        paused = true;

        cryptoRomeLandNFTContract = CryptoRomeLandComposableNFT(_cryptoRomeLandNFTContractAddress);
        improvementGenContract = ImprovementGeneration(_improvementGenContractAddress);

        villageInventoryPrice = LOWEST_VILLAGE_INVENTORY_PRICE;
        numImprovementsPerVillage = 3;
    }

    function setNewAddress(address _v2Address) external onlyOwner {
        require (_v2Address != address(0));
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

    function setCryptoRomeLandNFTContract(address _cryptoRomeLandNFTContract) external onlyOwner {
        require (_cryptoRomeLandNFTContract != address(0));
        cryptoRomeLandNFTContract = CryptoRomeLandComposableNFT(_cryptoRomeLandNFTContract);
    }

    function setImprovementGenContract(address _improvementGenContractAddress) external onlyOwner {
        require (_improvementGenContractAddress != address(0));
        improvementGenContract = ImprovementGeneration(_improvementGenContractAddress);
    }

    function setVillageInventoryPrice(uint256 _price) external onlyOwner {
        require(_price >= LOWEST_VILLAGE_INVENTORY_PRICE);
        villageInventoryPrice = _price;
    }

    function setNumImprovementsPerVillage(uint256 _numImprovements) external onlyOwner {
        require(_numImprovements <= 6);
        numImprovementsPerVillage = _numImprovements;
    }

    function purchaseFromVillageInventory(uint256 _num) external whenNotPaused payable {
        uint256 price = villageInventoryPrice.mul(_num);
        require (msg.value >= price);
        require (_num > 0 && _num <= 50);

         
        uint256 marketFee = computeFee(price);
        cryptoRomeWallet.transfer(marketFee);

         
        uint256 excessPayment = msg.value.sub(price);
        msg.sender.transfer(excessPayment);

        for (uint256 i = 0; i < _num; i++) {
             
            _createVillageWithImprovementsFromInv(msg.sender);
        }
    }

    function computeFee(uint256 amount) internal pure returns(uint256) {
         
        return amount.mul(3).div(100);
    }

    function batchIssueLand(address _toAddress, uint256[] _landType) external onlyOwner {
        require (_toAddress != address(0));
        require (_landType.length > 0);

        for (uint256 i = 0; i < _landType.length; i++) {
            issueLand(_toAddress, _landType[i]);
        }
    }

    function batchIssueVillages(address _toAddress, uint256 _num) external onlyOwner {
        require (_toAddress != address(0));
        require (_num > 0);

        for (uint256 i = 0; i < _num; i++) {
            _createVillageWithImprovements(_toAddress);
        }
    }

    function issueLand(address _toAddress, uint256 _landType) public onlyOwner returns (uint256) {
        require (_toAddress != address(0));

        return _createLandWithImprovements(_toAddress, _landType);
    }

    function batchCreateLand(uint256[] _landType) external onlyOwner {
        require (_landType.length > 0);

        for (uint256 i = 0; i < _landType.length; i++) {
             
             
            _createLandWithImprovements(address(this), _landType[i]);
        }
    }

    function batchCreateVillages(uint256 _num) external onlyOwner {
        require (_num > 0);

        for (uint256 i = 0; i < _num; i++) {
             
             
            _createVillageWithImprovements(address(this));
        }
    }

    function createLand(uint256 _landType) external onlyOwner {
         
         
        _createLandWithImprovements(address(this), _landType);
    }

    function batchTransferTo(uint256[] _tokenIds, address _to) external onlyOwner {
        require (_tokenIds.length > 0);
        require (_to != address(0));

        for (uint256 i = 0; i < _tokenIds.length; ++i) {
             
            cryptoRomeLandNFTContract.transferFrom(address(this), _to, _tokenIds[i]);
        }
    }

    function transferTo(uint256 _tokenId, address _to) external onlyOwner {
        require (_to != address(0));

         
        cryptoRomeLandNFTContract.transferFrom(address(this), _to, _tokenId);
    }

    function issueVillageWithImprovementsForPromo(address _toAddress, uint256 numImprovements) external onlyOwner returns (uint256) {
        uint256 landImprovements = improvementGenContract.genInitialResourcesForVillage(numImprovements, false);
        return cryptoRomeLandNFTContract.createLand(_toAddress, 1, landImprovements);
    }

    function _createVillageWithImprovementsFromInv(address _toAddress) internal returns (uint256) {
        uint256 landImprovements = improvementGenContract.genInitialResourcesForVillage(numImprovementsPerVillage, true);
        return cryptoRomeLandNFTContract.createLand(_toAddress, 1, landImprovements);
    }

    function _createVillageWithImprovements(address _toAddress) internal returns (uint256) {
        uint256 landImprovements = improvementGenContract.genInitialResourcesForVillage(3, false);
        return cryptoRomeLandNFTContract.createLand(_toAddress, 1, landImprovements);
    }

    function _createLandWithImprovements(address _toAddress, uint256 _landType) internal returns (uint256) {
        require (_landType > 0 && _landType < 4);

        if (_landType == 1) {
            return _createVillageWithImprovements(_toAddress);
        } else if (_landType == 2) {
            uint256 village1TokenId = _createLandWithImprovements(address(this), 1);
            uint256 village2TokenId = _createLandWithImprovements(address(this), 1);
            uint256 village3TokenId = _createLandWithImprovements(address(this), 1);
            uint256 townTokenId = cryptoRomeLandNFTContract.createLand(_toAddress, 2, 0);
            cryptoRomeLandNFTContract.composeLand(townTokenId, village1TokenId, village2TokenId, village3TokenId);
            return townTokenId;
        } else if (_landType == 3) {
            uint256 town1TokenId = _createLandWithImprovements(address(this), 2);
            uint256 town2TokenId = _createLandWithImprovements(address(this), 2);
            uint256 town3TokenId = _createLandWithImprovements(address(this), 2);
            uint256 cityTokenId = cryptoRomeLandNFTContract.createLand(_toAddress, 3, 0);
            cryptoRomeLandNFTContract.composeLand(cityTokenId, town1TokenId, town2TokenId, town3TokenId);
            return cityTokenId;
        }
    }
}

interface RandomNumGeneration {
    function getRandomNumber(uint256 seed) external returns (uint256);
}

contract ImprovementGeneration is CryptoRomeControl {
    using SafeMath for uint256;
    
     
    address public newContractAddress;

    RandomNumGeneration public randomNumberSource; 
    uint256 public rarityValueMax;
    uint256 public latestPseudoRandomNumber;
    uint8 public numResourceImprovements;

    mapping(uint8 => uint256) private improvementIndexToRarityValue;

    constructor () public {
         
         
        improvementIndexToRarityValue[1] = 256;   
        improvementIndexToRarityValue[2] = 256;   
        improvementIndexToRarityValue[3] = 128;   
        improvementIndexToRarityValue[4] = 128;   
        improvementIndexToRarityValue[5] = 64;    
        improvementIndexToRarityValue[6] = 64;    
        improvementIndexToRarityValue[7] = 32;    
        improvementIndexToRarityValue[8] = 16;    
        improvementIndexToRarityValue[9] = 8;     
         

         
        numResourceImprovements = 9;
        rarityValueMax = 952;
    }

    function setNewAddress(address _v2Address) external onlyOwner {
        require (_v2Address != address(0));
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

    function setRandomNumGenerationContract(address _randomNumberGenAddress) external onlyOwner {
        require (_randomNumberGenAddress != address(0));
        randomNumberSource = RandomNumGeneration(_randomNumberGenAddress);
    }

    function genInitialResourcesForVillage(uint256 numImprovements, bool useRandomInput) external anyOperator returns(uint256) {
        require(numImprovements <= 6);
        uint256 landImprovements;

         
        for (uint256 i = 0; i < numImprovements; i++) {
            uint8 newImprovement = generateImprovement(useRandomInput);
             
            landImprovements |= uint256(newImprovement) << (32*i);
        }
        
        return landImprovements;
    }

    function generateImprovement(bool useRandomSource) public anyOperator returns (uint8 newImprovement) {     
         
         
        uint256 seed = latestPseudoRandomNumber.add(now);
        if (useRandomSource) {
             
             
            seed = randomNumberSource.getRandomNumber(seed);
        }
        
        latestPseudoRandomNumber = addmod(uint256(blockhash(block.number-1)), seed, rarityValueMax);
        
         
        newImprovement = lookupImprovementTypeByRarity(latestPseudoRandomNumber);
    }

    function lookupImprovementTypeByRarity(uint256 rarityNum) public view returns (uint8 improvementType) {
        uint256 rarityIndexValue;
        for (uint8 i = 1; i <= numResourceImprovements; i++) {
            rarityIndexValue += improvementIndexToRarityValue[i];
            if (rarityNum < rarityIndexValue) {
                return i;
            }
        }
        return 0;
    }

    function addNewResourceImprovementType(uint256 rarityValue) external onlyOwner {
        require(rarityValue > 0);
        require(numResourceImprovements < 63);

        numResourceImprovements++;
        rarityValueMax += rarityValue;
        improvementIndexToRarityValue[numResourceImprovements] = rarityValue;
    }

    function updateImprovementRarityValue(uint256 rarityValue, uint8 improvementIndex) external onlyOwner {
        require(rarityValue > 0);
        require(improvementIndex <= numResourceImprovements);

        rarityValueMax -= improvementIndexToRarityValue[improvementIndex];
        rarityValueMax += rarityValue;
        improvementIndexToRarityValue[improvementIndex] = rarityValue;
    }
}