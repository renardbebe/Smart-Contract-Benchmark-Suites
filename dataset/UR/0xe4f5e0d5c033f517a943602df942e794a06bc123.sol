 

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
  function ownerOf(uint256 _assetId) public view returns (address owner);
  function approve(address _to, uint256 _assetId) public;
  function transfer(address _to, uint256 _assetId) public;
  function transferFrom(address _from, address _to, uint256 _assetId) public;
  function implementsERC721() public pure returns (bool);
  function takeOwnership(uint256 _assetId) public;
  function totalSupply() public view returns (uint256 total);

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   
   
   
   
   

   
  function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

 
contract OperationalControl {
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public gameManagerPrimary;
    address public gameManagerSecondary;
    address public bankManager;

     
    bool public paused = false;

     
    bool public error = false;

     
    modifier onlyGameManager() {
        require(msg.sender == gameManagerPrimary || msg.sender == gameManagerSecondary);
        _;
    }

    modifier onlyBanker() {
        require(msg.sender == bankManager);
        _;
    }

    modifier anyOperator() {
        require(
            msg.sender == gameManagerPrimary ||
            msg.sender == gameManagerSecondary ||
            msg.sender == bankManager
        );
        _;
    }

     
    function setPrimaryGameManager(address _newGM) external onlyGameManager {
        require(_newGM != address(0));

        gameManagerPrimary = _newGM;
    }

     
    function setSecondaryGameManager(address _newGM) external onlyGameManager {
        require(_newGM != address(0));

        gameManagerSecondary = _newGM;
    }

     
    function setBanker(address _newBK) external onlyGameManager {
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

     
     
    function pause() external onlyGameManager whenNotPaused {
        paused = true;
    }

     
     
    function unpause() public onlyGameManager whenPaused {
         
        paused = false;
    }

     
     
    function hasError() public onlyGameManager whenPaused {
        error = true;
    }

     
     
    function noError() public onlyGameManager whenPaused {
        error = false;
    }
}

contract CSCCollectibleBase is ERC721, OperationalControl, StringHelpers {

   
   
  event CollectibleCreated(address owner, uint256 globalId, uint256 collectibleType, uint256 collectibleClass, uint256 sequenceId, bytes32 collectibleName, bool isRedeemed);
  event Transfer(address from, address to, uint256 shipId);

   

   
  string public constant NAME = "CSCPreSaleShip";
  string public constant SYMBOL = "CSC";
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

     
    uint256 assetId;

     
    bytes32 collectibleName;

     
    uint256 boughtTimestamp;

     
     
    uint256 collectibleType;

     
    uint256 collectibleClass;

     
    address owner;

     
    bool isRedeemed;
  }
  
   
   

   
  CSCPreSaleItem[] allPreSaleItems;

   
  uint256 public constant PROMETHEUS_SHIP_LIMIT = 300;
  uint256 public constant INTREPID_SHIP_LIMIT = 1500;
  uint256 public constant CROSAIR_SHIP_LIMIT = 600;
  uint256 public constant PROMETHEUS_VOUCHER_LIMIT = 100;
  uint256 public constant INTREPID_VOUCHER_LIMIT = 300;
  uint256 public constant CROSAIR_VOUCHER_LIMIT = 200;

   
  uint256 public prometheusShipMinted;
  uint256 public intrepidShipMinted;
  uint256 public crosairShipMinted;
  uint256 public prometheusVouchersMinted;
  uint256 public intrepidVouchersMinted;
  uint256 public crosairVouchersMinted;

   
  mapping (address => bool) approvedAddressList;

   
  mapping (uint256 => address) public preSaleItemIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public preSaleItemIndexToApproved;

   
   
   
   
   
  mapping (uint256 => mapping (uint256 => mapping ( uint256 => uint256 ) ) ) public preSaleItemTypeToSequenceIdToCollectible;

   
   
   
   
   
  mapping (uint256 => mapping ( uint256 => uint256 ) ) public preSaleItemTypeToCollectibleCount;

   
   
   
  function supportsInterface(bytes4 _interfaceID) external view returns (bool)
  {
       
       
      return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
  }

  function getCollectibleDetails(uint256 _assetId) external view returns(uint256 assetId, uint256 sequenceId, uint256 collectibleType, uint256 collectibleClass, bool isRedeemed, address owner) {
    CSCPreSaleItem memory _Obj = allPreSaleItems[_assetId];
    assetId = _assetId;
    sequenceId = _Obj.assetId;
    collectibleType = _Obj.collectibleType;
    collectibleClass = _Obj.collectibleClass;
    owner = _Obj.owner;
    isRedeemed = _Obj.isRedeemed;
  }
  
   
   
   
   
   
   
  function approve(address _to, uint256 _assetId) public {
     
    require(_owns(msg.sender, _assetId));
    preSaleItemIndexToApproved[_assetId] = _to;

    Approval(msg.sender, _to, _assetId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

   
   
   
  function ownerOf(uint256 _assetId) public view returns (address owner) {
    owner = preSaleItemIndexToOwner[_assetId];
    require(owner != address(0));
  }

   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

   
   
   
  function takeOwnership(uint256 _assetId) public {
    address newOwner = msg.sender;
    address oldOwner = preSaleItemIndexToOwner[_assetId];

     
    require(_addressNotNull(newOwner));

     
    require(_approved(newOwner, _assetId));

    _transfer(oldOwner, newOwner, _assetId);
  }

   
   
   
   
   
  function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
         
        return new uint256[](0);
    } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 totalShips = totalSupply() + 1;
        uint256 resultIndex = 0;

         
         
        uint256 _assetId;

        for (_assetId = 0; _assetId < totalShips; _assetId++) {
            if (preSaleItemIndexToOwner[_assetId] == _owner) {
                result[resultIndex] = _assetId;
                resultIndex++;
            }
        }

        return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return allPreSaleItems.length - 1;  
  }

   
   
   
   
  function transfer(address _to, uint256 _assetId) public {
    require(_addressNotNull(_to));
    require(_owns(msg.sender, _assetId));

    _transfer(msg.sender, _to, _assetId);
  }

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _assetId) public {
    require(_owns(_from, _assetId));
    require(_approved(_to, _assetId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _assetId);
  }

   
   
  function _addressNotNull(address _to) internal pure returns (bool) {
    return _to != address(0);
  }

   
  function _approved(address _to, uint256 _assetId) internal view returns (bool) {
    return preSaleItemIndexToApproved[_assetId] == _to;
  }

   
  function _createCollectible(bytes32 _collectibleName, uint256 _collectibleType, uint256 _collectibleClass) internal returns(uint256) {
    uint256 _sequenceId = uint256(preSaleItemTypeToCollectibleCount[_collectibleType][_collectibleClass]) + 1;

     
     
    require(_sequenceId == uint256(uint32(_sequenceId)));
    
    CSCPreSaleItem memory _collectibleObj = CSCPreSaleItem(
      _sequenceId,
      _collectibleName,
      0,
      _collectibleType,
      _collectibleClass,
      address(0),
      false
    );

    uint256 newCollectibleId = allPreSaleItems.push(_collectibleObj) - 1;
    
    preSaleItemTypeToSequenceIdToCollectible[_collectibleType][_collectibleClass][_sequenceId] = newCollectibleId;
    preSaleItemTypeToCollectibleCount[_collectibleType][_collectibleClass] = _sequenceId;

     
     
    CollectibleCreated(address(this), newCollectibleId, _collectibleType, _collectibleClass, _sequenceId, _collectibleObj.collectibleName, false);
    
     
     
    _transfer(address(0), address(this), newCollectibleId);
    
    return newCollectibleId;
  }

   
  function _owns(address claimant, uint256 _assetId) internal view returns (bool) {
    return claimant == preSaleItemIndexToOwner[_assetId];
  }

   
  function _transfer(address _from, address _to, uint256 _assetId) internal {
     
    CSCPreSaleItem memory _shipObj = allPreSaleItems[_assetId];
    _shipObj.owner = _to;
    allPreSaleItems[_assetId] = _shipObj;

     
    ownershipTokenCount[_to]++;

     
    preSaleItemIndexToOwner[_assetId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete preSaleItemIndexToApproved[_assetId];
    }

     
    Transfer(_from, _to, _assetId);
  }

   
   
  function _approvedFor(address _claimant, uint256 _assetId) internal view returns (bool) {
      return preSaleItemIndexToApproved[_assetId] == _claimant;
  }

  function _getCollectibleDetails (uint256 _assetId) internal view returns(CSCPreSaleItem) {
    CSCPreSaleItem storage _Obj = allPreSaleItems[_assetId];
    return _Obj;
  }

   
   
   
  function getShipDetails(uint256 _sequenceId, uint256 _shipClass) external view returns (
    uint256 assetId,
    uint256 sequenceId,
    string shipName,
    uint256 collectibleClass,
    uint256 boughtTimestamp,
    address owner
    ) {  
    uint256 _assetId = preSaleItemTypeToSequenceIdToCollectible[1][_shipClass][_sequenceId];

    CSCPreSaleItem storage _collectibleObj = allPreSaleItems[_assetId];
    require(_collectibleObj.collectibleType == 1);

    assetId = _assetId;
    sequenceId = _sequenceId;
    shipName = bytes32ToString(_collectibleObj.collectibleName);
    collectibleClass = _collectibleObj.collectibleClass;
    boughtTimestamp = _collectibleObj.boughtTimestamp;
    owner = _collectibleObj.owner;
  }

   
   
   
  function getVoucherDetails(uint256 _sequenceId, uint256 _voucherClass) external view returns (
    uint256 assetId,
    uint256 sequenceId,
    uint256 boughtTimestamp,
    uint256 voucherClass,
    address owner
    ) {
    uint256 _assetId = preSaleItemTypeToSequenceIdToCollectible[0][_voucherClass][_sequenceId];

    CSCPreSaleItem storage _collectibleObj = allPreSaleItems[_assetId];
    require(_collectibleObj.collectibleType == 0);

    assetId = _assetId;
    sequenceId = _sequenceId;
    boughtTimestamp = _collectibleObj.boughtTimestamp;
    voucherClass = _collectibleObj.collectibleClass;
    owner = _collectibleObj.owner;
  }

  function _isActive(uint256 _assetId) internal returns(bool) {
    CSCPreSaleItem memory _Obj = allPreSaleItems[_assetId];
    return (_Obj.boughtTimestamp == 0);
  }
}

 
contract CSCCollectibleSale is CSCCollectibleBase {
  event CollectibleBought (uint256 _assetId, address owner);
  event PriceUpdated (uint256 collectibleClass, uint256 newPrice, uint256 oldPrice);

   
   
  uint256 public PROMETHEUS_SHIP_PRICE = 0.25 ether;
  uint256 public INTREPID_SHIP_PRICE = 0.005 ether;
  uint256 public CROSAIR_SHIP_PRICE = 0.1 ether;

  uint256 public constant PROMETHEUS_MAX_PRICE = 0.85 ether;
  uint256 public constant INTREPID_MAX_PRICE = 0.25 ether;
  uint256 public constant CROSAIR_MAX_PRICE = 0.5 ether;

  uint256 public constant PROMETHEUS_PRICE_INCREMENT = 0.05 ether;
  uint256 public constant INTREPID_PRICE_INCREMENT = 0.002 ether;
  uint256 public constant CROSAIR_PRICE_INCREMENT = 0.01 ether;

  uint256 public constant PROMETHEUS_PRICE_THRESHOLD = 0.85 ether;
  uint256 public constant INTREPID_PRICE_THRESHOLD = 0.25 ether;
  uint256 public constant CROSAIR_PRICE_THRESHOLD = 0.5 ether;

  uint256 public prometheusSoldCount;
  uint256 public intrepidSoldCount;
  uint256 public crosairSoldCount;

   
  uint256 public PROMETHEUS_VOUCHER_PRICE = 0.75 ether;
  uint256 public INTREPID_VOUCHER_PRICE = 0.2 ether;
  uint256 public CROSAIR_VOUCHER_PRICE = 0.35 ether;

  uint256 public prometheusVoucherSoldCount;
  uint256 public crosairVoucherSoldCount;
  uint256 public intrepidVoucherSoldCount;
  
   
  mapping(address => uint256) addressToValue;

   
  mapping(address => mapping(uint256 => mapping (uint256 => uint256))) addressToCollectibleTypeBalance;

  function _bid(uint256 _assetId, uint256 _price,uint256 _collectibleType,uint256 _collectibleClass, address _buyer) internal {
    CSCPreSaleItem memory _Obj = allPreSaleItems[_assetId];

    if(_collectibleType == 1 && _collectibleClass == 1) {
      require(_price == PROMETHEUS_SHIP_PRICE);
      _Obj.owner = _buyer;
      _Obj.boughtTimestamp = now;

      addressToValue[_buyer] += _price;

      prometheusSoldCount++;
      if(prometheusSoldCount % 10 == 0){
        if(PROMETHEUS_SHIP_PRICE < PROMETHEUS_PRICE_THRESHOLD){
          PROMETHEUS_SHIP_PRICE +=  PROMETHEUS_PRICE_INCREMENT;
        }
      }
    }

    if(_collectibleType == 1 && _collectibleClass == 2) {
      require(_price == CROSAIR_SHIP_PRICE);
      _Obj.owner = _buyer;
      _Obj.boughtTimestamp = now;

      addressToValue[_buyer] += _price;

      crosairSoldCount++;
      if(crosairSoldCount % 10 == 0){
        if(CROSAIR_SHIP_PRICE < CROSAIR_PRICE_THRESHOLD){
          CROSAIR_SHIP_PRICE += CROSAIR_PRICE_INCREMENT;
        }
      }
    }

    if(_collectibleType == 1 && _collectibleClass == 3) {
      require(_price == INTREPID_SHIP_PRICE);
      _Obj.owner = _buyer;
      _Obj.boughtTimestamp = now;

      addressToValue[_buyer] += _price;

      intrepidSoldCount++;
      if(intrepidSoldCount % 10 == 0){
        if(INTREPID_SHIP_PRICE < INTREPID_PRICE_THRESHOLD){
          INTREPID_SHIP_PRICE += INTREPID_PRICE_INCREMENT;
        }
      }
    }

    if(_collectibleType == 0 &&_collectibleClass == 1) {
        require(_price == PROMETHEUS_VOUCHER_PRICE);
        _Obj.owner = _buyer;
        _Obj.boughtTimestamp = now;

        addressToValue[_buyer] += _price;

        prometheusVoucherSoldCount++;
      }

      if(_collectibleType == 0 && _collectibleClass == 2) {
        require(_price == CROSAIR_VOUCHER_PRICE);
        _Obj.owner = _buyer;
        _Obj.boughtTimestamp = now;

        addressToValue[_buyer] += _price;

        crosairVoucherSoldCount++;
      }
      
      if(_collectibleType == 0 && _collectibleClass == 3) {
        require(_price == INTREPID_VOUCHER_PRICE);
        _Obj.owner = _buyer;
        _Obj.boughtTimestamp = now;

        addressToValue[_buyer] += _price;

        intrepidVoucherSoldCount++;
      }

    addressToCollectibleTypeBalance[_buyer][_collectibleType][_collectibleClass]++;

    CollectibleBought(_assetId, _buyer);
  }

  function getCollectibleTypeBalance(address _owner, uint256 _collectibleType, uint256 _collectibleClass) external view returns(uint256) {
    require(_owner != address(0));
    return addressToCollectibleTypeBalance[_owner][_collectibleType][_collectibleClass];
  }

  function getCollectiblePrice(uint256 _collectibleType, uint256 _collectibleClass) external view returns(uint256 _price){

     
    if(_collectibleType == 1 && _collectibleClass == 1) {
      return PROMETHEUS_SHIP_PRICE;
    }

    if(_collectibleType == 1 && _collectibleClass == 2) {
      return CROSAIR_SHIP_PRICE;
    }

    if(_collectibleType == 1 && _collectibleClass == 3) {
      return INTREPID_SHIP_PRICE;
    }

     
    if(_collectibleType == 0 && _collectibleClass == 1) {
      return PROMETHEUS_VOUCHER_PRICE;
    }

    if(_collectibleType == 0 && _collectibleClass == 2) {
      return CROSAIR_VOUCHER_PRICE;
    }

    if(_collectibleType == 0 && _collectibleClass == 3) {
      return INTREPID_VOUCHER_PRICE;
    }
  }
}

 
contract CSCPreSaleManager is CSCCollectibleSale {
  event RefundClaimed(address owner, uint256 refundValue);

   
  string private constant prometheusShipName = "Vulcan Harvester";
  string private constant crosairShipName = "Phoenix Cruiser";
  string private constant intrepidShipName = "Reaper Interceptor";

  bool CSCPreSaleInit = false;

   
  function CSCPreSaleManager() public {
      require(msg.sender != address(0));
      paused = true;
      error = false;
      gameManagerPrimary = msg.sender;
  }

  function addToApprovedAddress (address _newAddr) onlyGameManager {
    require(_newAddr != address(0));
    require(!approvedAddressList[_newAddr]);
    approvedAddressList[_newAddr] = true;
  }

  function removeFromApprovedAddress (address _newAddr) onlyGameManager {
    require(_newAddr != address(0));
    require(approvedAddressList[_newAddr]);
    approvedAddressList[_newAddr] = false;
  }

  function() external payable {
  }

   
   
  function bid(uint256 _collectibleType, uint256 _collectibleClass) external payable {
    require(msg.sender != address(0));
    require(msg.sender != address(this));

    require(_collectibleType >= 0 && _collectibleType <= 1);

    require(_isActive(_assetId));

    bytes32 collectibleName;

    if(_collectibleType == 0){
      collectibleName = bytes32("NoNameForVoucher");
      if(_collectibleClass == 1){
        require(prometheusVouchersMinted < PROMETHEUS_VOUCHER_LIMIT);
        collectibleName = stringToBytes32(prometheusShipName);
        prometheusVouchersMinted++;
      }
      
      if(_collectibleClass == 2){
        require(crosairVouchersMinted < CROSAIR_VOUCHER_LIMIT);
        crosairVouchersMinted++;
      }

      if(_collectibleClass == 3){
        require(intrepidVoucherSoldCount < INTREPID_VOUCHER_LIMIT);
        intrepidVouchersMinted++;
      }
    }

    if(_collectibleType == 1){
      if(_collectibleClass == 1){
        require(prometheusShipMinted < PROMETHEUS_SHIP_LIMIT);
        collectibleName = stringToBytes32(prometheusShipName);
        prometheusShipMinted++;
      }
      
      if(_collectibleClass == 2){
        require(crosairShipMinted < CROSAIR_VOUCHER_LIMIT);
        collectibleName = stringToBytes32(crosairShipName);
        crosairShipMinted++;
      }

      if(_collectibleClass == 3){
        require(intrepidShipMinted < INTREPID_SHIP_LIMIT);
        collectibleName = stringToBytes32(intrepidShipName);
        intrepidShipMinted++;
      }
    }

    uint256 _assetId = _createCollectible(collectibleName, _collectibleType, _collectibleClass); 

    CSCPreSaleItem memory _Obj = allPreSaleItems[_assetId];

    _bid(_assetId, msg.value, _Obj.collectibleType, _Obj.collectibleClass, msg.sender);
    
    _transfer(address(this), msg.sender, _assetId);
  }

   
   
  function createReferralGiveAways(uint256 _collectibleType, uint256 _collectibleClass, address _toAddress) onlyGameManager external {
    require(msg.sender != address(0));
    require(msg.sender != address(this));

    require(_collectibleType >= 0 && _collectibleType <= 1);

    bytes32 collectibleName;

    if(_collectibleType == 0){
      collectibleName = bytes32("ReferralGiveAwayVoucher");
      if(_collectibleClass == 1){
        collectibleName = stringToBytes32(prometheusShipName);
      }
      
      if(_collectibleClass == 2){
        crosairVouchersMinted++;
      }

      if(_collectibleClass == 3){
        intrepidVouchersMinted++;
      }
    }

    if(_collectibleType == 1){
      if(_collectibleClass == 1){
        collectibleName = stringToBytes32(prometheusShipName);
      }
      
      if(_collectibleClass == 2){
        collectibleName = stringToBytes32(crosairShipName);
      }

      if(_collectibleClass == 3){
        collectibleName = stringToBytes32(intrepidShipName);
      }
    }

    uint256 _assetId = _createCollectible(collectibleName, _collectibleType, _collectibleClass); 

    CSCPreSaleItem memory _Obj = allPreSaleItems[_assetId];
    
    _transfer(address(this), _toAddress, _assetId);
  }

   
   
   
   
   
  function unpause() public onlyGameManager whenPaused {
       
      super.unpause();
  }

   
   
   
   
  function withdrawBalance() onlyBanker {
       
      bankManager.transfer(this.balance);
  }

  function claimRefund(address _ownerAddress) whenError {
    uint256 refundValue = addressToValue[_ownerAddress];
    addressToValue[_ownerAddress] = 0;

    _ownerAddress.transfer(refundValue);
    RefundClaimed(_ownerAddress, refundValue);
  }
  
  function preSaleInit() onlyGameManager {
    require(!CSCPreSaleInit);
    require(allPreSaleItems.length == 0);
      
    CSCPreSaleInit = true;

     
    CSCPreSaleItem memory _Obj = CSCPreSaleItem(0, stringToBytes32("DummyAsset"), 0, 0, 0, address(this), true);
    allPreSaleItems.push(_Obj);
  }

  function isRedeemed(uint256 _assetId) {
    require(approvedAddressList[msg.sender]);

    CSCPreSaleItem memory _Obj = allPreSaleItems[_assetId];
    _Obj.isRedeemed = true;

    allPreSaleItems[_assetId] = _Obj;
  }
}