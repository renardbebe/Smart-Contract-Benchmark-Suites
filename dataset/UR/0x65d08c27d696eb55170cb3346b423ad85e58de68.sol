 

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

   
   
  event CollectibleCreated(address owner, uint256 collectibleId, bytes32 collectibleName, bool isRedeemed);
  event Transfer(address from, address to, uint256 shipId);

   

   
  string public constant NAME = "CSCRareCollectiblePreSale";
  string public constant SYMBOL = "CSCR";
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

   
  struct RarePreSaleItem {

     
    bytes32 collectibleName;

     
    uint256 boughtTimestamp;

     
    address owner;

     
    bool isRedeemed;
  }

   
  RarePreSaleItem[] allPreSaleItems;

   
  mapping (address => bool) approvedAddressList;

   
  mapping (uint256 => address) public preSaleItemIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public preSaleItemIndexToApproved;

   
   
   
  function supportsInterface(bytes4 _interfaceID) external view returns (bool)
  {
       
       
      return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
  }

   
   
   
   
   
   
  function approve(address _to, uint256 _assetId) public {
     
    require(_owns(address(this), _assetId));
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

   
  function _createCollectible(bytes32 _collectibleName, address _owner) internal returns(uint256) {
    
    RarePreSaleItem memory _collectibleObj = RarePreSaleItem(
      _collectibleName,
      0,
      address(0),
      false
    );

    uint256 newCollectibleId = allPreSaleItems.push(_collectibleObj) - 1;
    
     
    CollectibleCreated(_owner, newCollectibleId, _collectibleName, false);
    
     
     
    _transfer(address(0), _owner, newCollectibleId);
    
    return newCollectibleId;
  }

   
  function _owns(address claimant, uint256 _assetId) internal view returns (bool) {
    return claimant == preSaleItemIndexToOwner[_assetId];
  }

   
  function _transfer(address _from, address _to, uint256 _assetId) internal {
     
    RarePreSaleItem memory _shipObj = allPreSaleItems[_assetId];
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

  function _getCollectibleDetails (uint256 _assetId) internal view returns(RarePreSaleItem) {
    RarePreSaleItem storage _Obj = allPreSaleItems[_assetId];
    return _Obj;
  }

   
   
   
  function getShipDetails(uint256 _assetId) external view returns (
    uint256 collectibleId,
    string shipName,
    uint256 boughtTimestamp,
    address owner,
    bool isRedeemed
    ) {
    RarePreSaleItem storage _collectibleObj = allPreSaleItems[_assetId];
    collectibleId = _assetId;
    shipName = bytes32ToString(_collectibleObj.collectibleName);
    boughtTimestamp = _collectibleObj.boughtTimestamp;
    owner = _collectibleObj.owner;
    isRedeemed = _collectibleObj.isRedeemed;
  }
}

 
contract CSCCollectibleSale is CSCCollectibleBase {
  event SaleWinner(address owner, uint256 collectibleId, uint256 buyingPrice);
  event CollectibleBidSuccess(address owner, uint256 collectibleId, uint256 newBidPrice, bool isActive);
  event SaleCreated(uint256 tokenID, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint64 startedAt, bool isActive, uint256 bidPrice);

   
  struct CollectibleSale {
     
    address seller;
     
    uint256 startingPrice;
     
    uint256 endingPrice;
     
    uint256 duration;
     
     
    uint64 startedAt;

     
    bool isActive;

     
    address highestBidder;

     
    address buyer;

     
    uint256 tokenId;
  }

   
  uint256 public constant SALE_DURATION = 2592000;
  
   
  mapping(uint256 => address) indexToBidderAddress;
  mapping(address => mapping(uint256 => uint256)) addressToBidValue;

   
  mapping ( uint256 => uint256 ) indexToPriceIncrement;
   
  mapping ( uint256 => uint256 ) indexToBidPrice;

   
  mapping (uint256 => CollectibleSale) tokenIdToSale;

   
   
  function _addSale(uint256 _assetId, CollectibleSale _sale) internal {
       
       
      require(_sale.duration >= 1 minutes);
      
      tokenIdToSale[_assetId] = _sale;
      indexToBidPrice[_assetId] = _sale.endingPrice;

      SaleCreated(
          uint256(_assetId),
          uint256(_sale.startingPrice),
          uint256(_sale.endingPrice),
          uint256(_sale.duration),
          uint64(_sale.startedAt),
          _sale.isActive,
          indexToBidPrice[_assetId]
      );
  }

   
   
  function _removeSale(uint256 _assetId) internal {
      delete tokenIdToSale[_assetId];
  }

  function _bid(uint256 _assetId, address _buyer, uint256 _bidAmount) internal {
    CollectibleSale storage _sale = tokenIdToSale[_assetId];
    
    require(_bidAmount >= indexToBidPrice[_assetId]);

    uint256 _newBidPrice = _bidAmount + indexToPriceIncrement[_assetId];
    indexToBidPrice[_assetId] = _newBidPrice;

    _sale.highestBidder = _buyer;
    _sale.endingPrice = _newBidPrice;

    address lastBidder = indexToBidderAddress[_assetId];
    
    if(lastBidder != address(0)){
      uint256 _value = addressToBidValue[lastBidder][_assetId];

      indexToBidderAddress[_assetId] = _buyer;

      addressToBidValue[lastBidder][_assetId] = 0;
      addressToBidValue[_buyer][_assetId] = _bidAmount;

      lastBidder.transfer(_value);
    } else {
      indexToBidderAddress[_assetId] = _buyer;
      addressToBidValue[_buyer][_assetId] = _bidAmount;
    }

     
    uint256 price = _currentPrice(_sale);

    if(_bidAmount >= price) {
      _sale.buyer = _buyer;
      _sale.isActive = false;

      _removeSale(_assetId);

      uint256 bidExcess = _bidAmount - price;
      _buyer.transfer(bidExcess);

      SaleWinner(_buyer, _assetId, _bidAmount);
      _transfer(address(this), _buyer, _assetId);
    } else {
      tokenIdToSale[_assetId] = _sale;

      CollectibleBidSuccess(_buyer, _assetId, _sale.endingPrice, _sale.isActive);
    }
  }

   
  function _isOnSale(CollectibleSale memory _sale) internal view returns (bool) {
      return (_sale.startedAt > 0 && _sale.isActive);
  }

   
   
   
   
  function _currentPrice(CollectibleSale memory _sale) internal view returns (uint256) {
      uint256 secondsPassed = 0;

       
       
       
      if (now > _sale.startedAt) {
          secondsPassed = now - _sale.startedAt;
      }

      return _computeCurrentPrice(
          _sale.startingPrice,
          _sale.endingPrice,
          _sale.duration,
          secondsPassed
      );
  }

   
   
   
   
  function _computeCurrentPrice(uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, uint256 _secondsPassed) internal pure returns (uint256) {
       
       
       
       
       
      if (_secondsPassed >= _duration) {
           
           
          return _endingPrice;
      } else {
           
           
          int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

           
           
           
          int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

           
           
          int256 currentPrice = int256(_startingPrice) + currentPriceChange;

          return uint256(currentPrice);
      }
  }
  
   
   
  function _escrow(address _owner, uint256 _tokenId) internal {
    transferFrom(_owner, this, _tokenId);
  }

  function getBuyPrice(uint256 _assetId) external view returns(uint256 _price){
    CollectibleSale memory _sale = tokenIdToSale[_assetId];
    
    return _currentPrice(_sale);
  }
  
  function getBidPrice(uint256 _assetId) external view returns(uint256 _price){
    return indexToBidPrice[_assetId];
  }

   
  function _createSale(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint64 _duration, address _seller) internal {
       
       
      require(_startingPrice == uint256(uint128(_startingPrice)));
      require(_endingPrice == uint256(uint128(_endingPrice)));
      require(_duration == uint256(uint64(_duration)));

      CollectibleSale memory sale = CollectibleSale(
          _seller,
          uint128(_startingPrice),
          uint128(_endingPrice),
          uint64(_duration),
          uint64(now),
          true,
          address(this),
          address(this),
          uint256(_tokenId)
      );
      _addSale(_tokenId, sale);
  }

  function _buy(uint256 _assetId, address _buyer, uint256 _price) internal {

    CollectibleSale storage _sale = tokenIdToSale[_assetId];
    address lastBidder = indexToBidderAddress[_assetId];
    
    if(lastBidder != address(0)){
      uint256 _value = addressToBidValue[lastBidder][_assetId];

      indexToBidderAddress[_assetId] = _buyer;

      addressToBidValue[lastBidder][_assetId] = 0;
      addressToBidValue[_buyer][_assetId] = _price;

      lastBidder.transfer(_value);
    }

     
    uint256 currentPrice = _currentPrice(_sale);

    require(_price >= currentPrice);
    _sale.buyer = _buyer;
    _sale.isActive = false;

    _removeSale(_assetId);

    uint256 bidExcess = _price - currentPrice;
    _buyer.transfer(bidExcess);

    SaleWinner(_buyer, _assetId, _price);
    _transfer(address(this), _buyer, _assetId);
  }

   
   
  function getSale(uint256 _assetId) external view returns (address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt, bool isActive, address owner, address highestBidder) {
      CollectibleSale memory sale = tokenIdToSale[_assetId];
      require(_isOnSale(sale));
      return (
          sale.seller,
          sale.startingPrice,
          sale.endingPrice,
          sale.duration,
          sale.startedAt,
          sale.isActive,
          sale.buyer,
          sale.highestBidder
      );
  }
}

 
contract CSCRarePreSaleManager is CSCCollectibleSale {
  event RefundClaimed(address owner);

  bool CSCPreSaleInit = false;

   
  function CSCRarePreSaleManager() public {
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

  function createPreSaleShip(string collectibleName, uint256 startingPrice, uint256 bidPrice) whenNotPaused returns (uint256){
    require(approvedAddressList[msg.sender] || msg.sender == gameManagerPrimary || msg.sender == gameManagerSecondary);
    
    uint256 assetId = _createCollectible(stringToBytes32(collectibleName), address(this));

    indexToPriceIncrement[assetId] = bidPrice;

    _createSale(assetId, startingPrice, bidPrice, uint64(SALE_DURATION), address(this));
  }

  function() external payable {
  }

   
   
  function bid(uint256 _assetId) external whenNotPaused payable {
    require(msg.sender != address(0));
    require(msg.sender != address(this));
    CollectibleSale memory _sale = tokenIdToSale[_assetId];
    require(_isOnSale(_sale));
    
    address seller = _sale.seller;

    _bid(_assetId, msg.sender, msg.value);
  }

   
   
  function buyNow(uint256 _assetId) external whenNotPaused payable {
    require(msg.sender != address(0));
    require(msg.sender != address(this));
    CollectibleSale memory _sale = tokenIdToSale[_assetId];
    require(_isOnSale(_sale));
    
    address seller = _sale.seller;

    _buy(_assetId, msg.sender, msg.value);
  }

   
   
   
   
   
  function unpause() public onlyGameManager whenPaused {
       
      super.unpause();
  }

   
   
   
   
  function withdrawBalance() onlyBanker {
       
      bankManager.transfer(this.balance);
  }
  
  function preSaleInit() onlyGameManager {
    require(!CSCPreSaleInit);
    require(allPreSaleItems.length == 0);
      
    CSCPreSaleInit = true;

    bytes32[6] memory attributes = [bytes32(999), bytes32(999), bytes32(999), bytes32(999), bytes32(999), bytes32(999)];
     
    RarePreSaleItem memory _Obj = RarePreSaleItem(stringToBytes32("Dummy"), 0, address(this), true);
    allPreSaleItems.push(_Obj);
  } 
}