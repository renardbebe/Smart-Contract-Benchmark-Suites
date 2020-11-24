 

pragma solidity ^0.4.19;

 
library strings {
    
    struct slice {
        uint _len;
        uint _ptr;
    }

     
    function toSlice(string self) internal pure returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function memcpy(uint dest, uint src, uint len) private pure {
         
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    
    function concat(slice self, slice other) internal returns (string) {
        var ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

     
    function count(slice self, slice needle) internal returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

     
     
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private returns (uint) {
        uint ptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                 
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    let end := add(selfptr, sub(selflen, needlelen))
                    ptr := selfptr
                    loop:
                    jumpi(exit, eq(and(mload(ptr), mask), needledata))
                    ptr := add(ptr, 1)
                    jumpi(loop, lt(sub(ptr, 1), end))
                    ptr := add(selfptr, selflen)
                    exit:
                }
                return ptr;
            } else {
                 
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr;
                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

     
    function split(slice self, slice needle, slice token) internal returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
             
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

      
    function split(slice self, slice needle) internal returns (slice token) {
        split(self, needle, token);
    }

     
    function toString(slice self) internal pure returns (string) {
        var ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

}

 
contract StringHelpers {
    using strings for *;
    
    function stringToBytes32(string memory source) internal returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 x) constant internal returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

 
 
contract ERC721 {
   
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) public view returns (address owner);
  function approve(address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function implementsERC721() public pure returns (bool);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   
   
   
   
   

   
  function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

 
contract OperationalControl {
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public managerPrimary;
    address public managerSecondary;
    address public bankManager;

     
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

    modifier anyOperator() {
        require(
            msg.sender == managerPrimary ||
            msg.sender == managerSecondary ||
            msg.sender == bankManager
        );
        _;
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

contract CSCPreSaleItemBase is ERC721, OperationalControl, StringHelpers {

     
     
    event CollectibleCreated(address owner, uint256 globalId, uint256 collectibleType, uint256 collectibleClass, uint256 sequenceId, bytes32 collectibleName);
    
     
    
     
    string public constant NAME = "CSCPreSaleFactory";
    string public constant SYMBOL = "CSCPF";
    bytes4 constant InterfaceSignature_ERC165 = bytes4(keccak256('supportsInterface(bytes4)'));
    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('tokensOfOwner(address)')) ^
        bytes4(keccak256('tokenMetadata(uint256,string)'));
    
     
    struct CSCPreSaleItem {
    
         
        uint256 sequenceId;
        
         
        bytes32 collectibleName;
        
         
        uint256 collectibleType;
        
         
        uint256 collectibleClass;
        
         
        address owner;
        
         
        bool isRedeemed;
    }
    
     
    CSCPreSaleItem[] allPreSaleItems;
    
     
    mapping(uint256 => mapping(uint256 => uint256)) public preSaleItemTypeToClassToMaxLimit;
    
     
    mapping(uint256 => mapping(uint256 => bool)) public preSaleItemTypeToClassToMaxLimitSet;

     
    mapping(uint256 => mapping(uint256 => bytes32)) public preSaleItemTypeToClassToName;
    
     
    mapping (address => bool) approvedAddressList;
    
     
    mapping (uint256 => address) public preSaleItemIndexToOwner;
    
     
     
    mapping (address => uint256) private ownershipTokenCount;
    
     
     
     
    mapping (uint256 => address) public preSaleItemIndexToApproved;
    
     
    mapping (uint256 => mapping (uint256 => mapping ( uint256 => uint256 ) ) ) public preSaleItemTypeToSequenceIdToCollectible;
    
     
    mapping (uint256 => mapping ( uint256 => uint256 ) ) public preSaleItemTypeToCollectibleCount;

     
    uint256 public STARTING_ASSET_BASE = 3000;
    
     
     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
         
         
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }
    
    function setMaxLimit(string _collectibleName, uint256 _collectibleType, uint256 _collectibleClass, uint256 _maxLimit) external onlyManager whenNotPaused {
        require(_maxLimit > 0);
        require(_collectibleType >= 0 && _collectibleClass >= 0);
        require(stringToBytes32(_collectibleName) != stringToBytes32(""));

        require(!preSaleItemTypeToClassToMaxLimitSet[_collectibleType][_collectibleClass]);
        preSaleItemTypeToClassToMaxLimit[_collectibleType][_collectibleClass] = _maxLimit;
        preSaleItemTypeToClassToMaxLimitSet[_collectibleType][_collectibleClass] = true;
        preSaleItemTypeToClassToName[_collectibleType][_collectibleClass] = stringToBytes32(_collectibleName);
    }
    
     
    function getCollectibleDetails(uint256 _tokenId) external view returns(uint256 assetId, uint256 sequenceId, uint256 collectibleType, uint256 collectibleClass, string collectibleName, bool isRedeemed, address owner) {

        require (_tokenId > STARTING_ASSET_BASE);
        uint256 generatedCollectibleId = _tokenId - STARTING_ASSET_BASE;
        
        CSCPreSaleItem memory _Obj = allPreSaleItems[generatedCollectibleId];
        assetId = _tokenId;
        sequenceId = _Obj.sequenceId;
        collectibleType = _Obj.collectibleType;
        collectibleClass = _Obj.collectibleClass;
        collectibleName = bytes32ToString(_Obj.collectibleName);
        owner = _Obj.owner;
        isRedeemed = _Obj.isRedeemed;
    }
    
     
     
     
     
     
     
    function approve(address _to, uint256 _tokenId) public {
         
        require (_tokenId > STARTING_ASSET_BASE);
        
        require(_owns(msg.sender, _tokenId));
        preSaleItemIndexToApproved[_tokenId] = _to;
        
        Approval(msg.sender, _to, _tokenId);
    }
    
     
     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }
    
    function implementsERC721() public pure returns (bool) {
        return true;
    }
    
     
     
     
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        require (_tokenId > STARTING_ASSET_BASE);

        owner = preSaleItemIndexToOwner[_tokenId];
        require(owner != address(0));
    }
    
     
    function symbol() public pure returns (string) {
        return SYMBOL;
    }
    
     
     
     
    function takeOwnership(uint256 _tokenId) public {
        require (_tokenId > STARTING_ASSET_BASE);

        address newOwner = msg.sender;
        address oldOwner = preSaleItemIndexToOwner[_tokenId];
        
         
        require(_addressNotNull(newOwner));
        
         
        require(_approved(newOwner, _tokenId));
        
        _transfer(oldOwner, newOwner, _tokenId);
    }
    
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        
        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCount = totalSupply() + 1 + STARTING_ASSET_BASE;
            uint256 resultIndex = 0;
        
             
             
            uint256 _tokenId;
        
            for (_tokenId = STARTING_ASSET_BASE; _tokenId < totalCount; _tokenId++) {
                if (preSaleItemIndexToOwner[_tokenId] == _owner) {
                    result[resultIndex] = _tokenId;
                    resultIndex++;
                }
            }
        
            return result;
        }
    }
    
     
     
    function totalSupply() public view returns (uint256 total) {
        return allPreSaleItems.length - 1;  
    }
    
     
     
     
     
    function transfer(address _to, uint256 _tokenId) public {

        require (_tokenId > STARTING_ASSET_BASE);
        
        require(_addressNotNull(_to));
        require(_owns(msg.sender, _tokenId));
        
        _transfer(msg.sender, _to, _tokenId);
    }
    
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require (_tokenId > STARTING_ASSET_BASE);

        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));
        
        _transfer(_from, _to, _tokenId);
    }
    
     
     
    function _addressNotNull(address _to) internal pure returns (bool) {
        return _to != address(0);
    }
    
     
    function _approved(address _to, uint256 _tokenId) internal view returns (bool) {
        return preSaleItemIndexToApproved[_tokenId] == _to;
    }
    
     
    function _createCollectible(bytes32 _collectibleName, uint256 _collectibleType, uint256 _collectibleClass) internal returns(uint256) {
        uint256 _sequenceId = uint256(preSaleItemTypeToCollectibleCount[_collectibleType][_collectibleClass]) + 1;
        
         
         
        require(_sequenceId == uint256(uint32(_sequenceId)));
        
        CSCPreSaleItem memory _collectibleObj = CSCPreSaleItem(
          _sequenceId,
          _collectibleName,
          _collectibleType,
          _collectibleClass,
          address(0),
          false
        );
        
        uint256 generatedCollectibleId = allPreSaleItems.push(_collectibleObj) - 1;
        uint256 collectibleIndex = generatedCollectibleId + STARTING_ASSET_BASE;
        
        preSaleItemTypeToSequenceIdToCollectible[_collectibleType][_collectibleClass][_sequenceId] = collectibleIndex;
        preSaleItemTypeToCollectibleCount[_collectibleType][_collectibleClass] = _sequenceId;
        
         
         
        CollectibleCreated(address(this), collectibleIndex, _collectibleType, _collectibleClass, _sequenceId, _collectibleObj.collectibleName);
        
         
         
        _transfer(address(0), address(this), collectibleIndex);
        
        return collectibleIndex;
    }
    
     
    function _owns(address claimant, uint256 _tokenId) internal view returns (bool) {
        return claimant == preSaleItemIndexToOwner[_tokenId];
    }
    
     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        uint256 generatedCollectibleId = _tokenId - STARTING_ASSET_BASE;

         
        CSCPreSaleItem memory _Obj = allPreSaleItems[generatedCollectibleId];
        _Obj.owner = _to;
        allPreSaleItems[generatedCollectibleId] = _Obj;
        
         
        ownershipTokenCount[_to]++;
        
         
        preSaleItemIndexToOwner[_tokenId] = _to;
        
         
        if (_from != address(0)) {
          ownershipTokenCount[_from]--;
           
          delete preSaleItemIndexToApproved[_tokenId];
        }
        
         
        Transfer(_from, _to, _tokenId);
    }
    
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        require(_tokenId > STARTING_ASSET_BASE);

        return preSaleItemIndexToApproved[_tokenId] == _claimant;
    }
}

 
contract CSCPreSaleManager is CSCPreSaleItemBase {

    event RefundClaimed(address owner, uint256 refundValue);

     
    mapping(uint256 => mapping(uint256 => bool)) public preSaleItemTypeToClassToCanBeVendingMachine;

     
    mapping(uint256 => mapping(uint256 => uint256)) public preSaleItemTypeToClassToVendingFee;

     
    mapping(address => uint256) public addressToValue;
    
    bool CSCPreSaleInit = false;
     
    function CSCPreSaleManager() public {
        require(msg.sender != address(0));
        paused = true;
        error = false;
        managerPrimary = msg.sender;
    }

     
    function() external payable {
    }
    
     
     
    function addToApprovedAddress (address _newAddr) onlyManager whenNotPaused {
        require(_newAddr != address(0));
        require(!approvedAddressList[_newAddr]);
        approvedAddressList[_newAddr] = true;
    }
    
     
     
    function removeFromApprovedAddress (address _newAddr) onlyManager whenNotPaused {
        require(_newAddr != address(0));
        require(approvedAddressList[_newAddr]);
        approvedAddressList[_newAddr] = false;
    }

     
    function toggleVending (uint256 _collectibleType, uint256 _collectibleClass) external onlyManager {
        if(preSaleItemTypeToClassToCanBeVendingMachine[_collectibleType][_collectibleClass] == false) {
            preSaleItemTypeToClassToCanBeVendingMachine[_collectibleType][_collectibleClass] = true;
        } else {
            preSaleItemTypeToClassToCanBeVendingMachine[_collectibleType][_collectibleClass] = false;
        }
    }

     
    function setVendingFee (uint256 _collectibleType, uint256 _collectibleClass, uint fee) external onlyManager {
        preSaleItemTypeToClassToVendingFee[_collectibleType][_collectibleClass] = fee;
    }
    
     
     
    function createCollectible(uint256 _collectibleType, uint256 _collectibleClass, address _toAddress) onlyManager external whenNotPaused {
        require(msg.sender != address(0));
        require(msg.sender != address(this));
        
        require(_toAddress != address(0));
        require(_toAddress != address(this));
        
        require(preSaleItemTypeToClassToMaxLimitSet[_collectibleType][_collectibleClass]);
        require(preSaleItemTypeToCollectibleCount[_collectibleType][_collectibleClass] < preSaleItemTypeToClassToMaxLimit[_collectibleType][_collectibleClass]);
        
        uint256 _tokenId = _createCollectible(preSaleItemTypeToClassToName[_collectibleType][_collectibleClass], _collectibleType, _collectibleClass);
        
        _transfer(address(this), _toAddress, _tokenId);
    }


     
     
    function vendingCreateCollectible(uint256 _collectibleType, uint256 _collectibleClass, address _toAddress) payable external whenNotPaused {
        
         
        require(preSaleItemTypeToClassToCanBeVendingMachine[_collectibleType][_collectibleClass]);

        require(msg.value >= preSaleItemTypeToClassToVendingFee[_collectibleType][_collectibleClass]);

        require(msg.sender != address(0));
        require(msg.sender != address(this));
        
        require(_toAddress != address(0));
        require(_toAddress != address(this));
        
        require(preSaleItemTypeToClassToMaxLimitSet[_collectibleType][_collectibleClass]);
        require(preSaleItemTypeToCollectibleCount[_collectibleType][_collectibleClass] < preSaleItemTypeToClassToMaxLimit[_collectibleType][_collectibleClass]);
        
        uint256 _tokenId = _createCollectible(preSaleItemTypeToClassToName[_collectibleType][_collectibleClass], _collectibleType, _collectibleClass);
        uint256 excessBid = msg.value - preSaleItemTypeToClassToVendingFee[_collectibleType][_collectibleClass];
        
        if(excessBid > 0) {
            msg.sender.transfer(excessBid);
        }

        addressToValue[msg.sender] += preSaleItemTypeToClassToVendingFee[_collectibleType][_collectibleClass];
        
        _transfer(address(this), _toAddress, _tokenId);
    }

    
    
     
     
     
     
     
    function unpause() public onlyManager whenPaused {
         
        super.unpause();
    }

     
     
     
     
     
    function hasError() public onlyManager whenPaused {
         
        super.hasError();
    }
    
     
     
    function preSaleInit() onlyManager {
        require(!CSCPreSaleInit);
        require(allPreSaleItems.length == 0);
        
        CSCPreSaleInit = true;
        
         
        CSCPreSaleItem memory _Obj = CSCPreSaleItem(0, stringToBytes32("DummyAsset"), 0, 0, address(this), true);
        allPreSaleItems.push(_Obj);
    }

     
     
     
     
    function withdrawBalance() onlyBanker {
         
        bankManager.transfer(this.balance);
    }

     
    function claimRefund(address _ownerAddress) whenError {
        uint256 refundValue = addressToValue[_ownerAddress];

        require (refundValue > 0);
        
        addressToValue[_ownerAddress] = 0;

        _ownerAddress.transfer(refundValue);
        RefundClaimed(_ownerAddress, refundValue);
    }
    

     
     
    function isRedeemed(uint256 _tokenId) {
        require(approvedAddressList[msg.sender]);
        require(_tokenId > STARTING_ASSET_BASE);
        uint256 generatedCollectibleId = _tokenId - STARTING_ASSET_BASE;
        
        CSCPreSaleItem memory _Obj = allPreSaleItems[generatedCollectibleId];
        _Obj.isRedeemed = true;
        
        allPreSaleItems[generatedCollectibleId] = _Obj;
    }
}