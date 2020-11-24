 

pragma solidity ^0.4.18;



 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




  
  

  
contract Pausable is Ownable {

  event SetPaused(bool paused);

   
  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    SetPaused(paused);
    return true;
  }

  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    SetPaused(paused);
    return true;
  }
}

contract EtherbotsPrivileges is Pausable {
  event ContractUpgrade(address newContract);

}

 
 
 
 
contract EtherbotsBase is EtherbotsPrivileges {


    function EtherbotsBase() public {
     
    }
     

     
     
     
    event Forge(address owner, uint256 partID, Part part);

     
    event Transfer(address from, address to, uint256 tokenId);

     
     
     
     
     
     
     
     
     struct Part {
        uint32 tokenId;
        uint8 partType;
        uint8 partSubType;
        uint8 rarity;
        uint8 element;
        uint32 battlesLastDay;
        uint32 experience;
        uint32 forgeTime;
        uint32 battlesLastReset;
    }

     
    uint8 constant DEFENCE = 1;
    uint8 constant MELEE = 2;
    uint8 constant BODY = 3;
    uint8 constant TURRET = 4;

     
    uint8 constant STANDARD = 1;
    uint8 constant SHADOW = 2;
    uint8 constant GOLD = 3;


     
     
     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     


    struct User {
         
        uint32 numShards;  
        uint32 experience;
        uint8[32] perks;
    }

     
     

     
     
     
    mapping ( address => User ) public addressToUser;

     
     
    Part[] parts;

     
    mapping (uint256 => address) public partIndexToOwner;

     
     
    mapping (address => uint256) addressToTokensOwned;

     
     
    mapping (uint256 => address) public partIndexToApproved;

    address auction;
     

     
     
     
    address[] approvedBattles;


    function getUserByAddress(address _user) public view returns (uint32, uint8[32]) {
        return (addressToUser[_user].experience, addressToUser[_user].perks);
    }

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
         
         
         
        addressToTokensOwned[_to]++;
         
        partIndexToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            addressToTokensOwned[_from]--;
             
            delete partIndexToApproved[_tokenId];
        }
         
        Transfer(_from, _to, _tokenId);
    }

    function getPartById(uint _id) external view returns (
        uint32 tokenId,
        uint8 partType,
        uint8 partSubType,
        uint8 rarity,
        uint8 element,
        uint32 battlesLastDay,
        uint32 experience,
        uint32 forgeTime,
        uint32 battlesLastReset
    ) {
        Part memory p = parts[_id];
        return (p.tokenId, p.partType, p.partSubType, p.rarity, p.element, p.battlesLastDay, p.experience, p.forgeTime, p.battlesLastReset);
    }


    function substring(string str, uint startIndex, uint endIndex) internal pure returns (string) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

     
    function stringToUint32(string s) internal pure returns (uint32) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {  
            if (b[i] >= 48 && b[i] <= 57) {
                result = result * 10 + (uint(b[i]) - 48);  
            }
        }
        return uint32(result);
    }

    function stringToUint8(string s) internal pure returns (uint8) {
        return uint8(stringToUint32(s));
    }

    function uintToString(uint v) internal pure returns (string) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);  
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];  
        }
        string memory str = string(s);
        return str;
    }
}


 
 
 


 
 
 
 
contract ERC721 {

     

     
    bytes4 internal constant INTERFACE_SIGNATURE_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

     
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721 =
         bytes4(keccak256("ownerOf(uint256)")) ^
         bytes4(keccak256("countOfDeeds()")) ^
         bytes4(keccak256("countOfDeedsByOwner(address)")) ^
         bytes4(keccak256("deedOfOwnerByIndex(address,uint256)")) ^
         bytes4(keccak256("approve(address,uint256)")) ^
         bytes4(keccak256("takeOwnership(uint256)"));

    function supportsInterface(bytes4 _interfaceID) external pure returns (bool);

     

    function ownerOf(uint256 _deedId) public view returns (address _owner);
    function countOfDeeds() external view returns (uint256 _count);
    function countOfDeedsByOwner(address _owner) external view returns (uint256 _count);
    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _deedId);

     

    event Transfer(address indexed from, address indexed to, uint256 indexed deedId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed deedId);

    function approve(address _to, uint256 _deedId) external payable;
    function takeOwnership(uint256 _deedId) external payable;
}

 
 
 
contract ERC721Metadata is ERC721 {

    bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata =
        bytes4(keccak256("name()")) ^
        bytes4(keccak256("symbol()")) ^
        bytes4(keccak256("deedUri(uint256)"));

    function name() public pure returns (string n);
    function symbol() public pure returns (string s);

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function deedUri(uint256 _deedId) external view returns (string _uri);
}

 
 
 
contract ERC721Enumerable is ERC721Metadata {

     
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721Enumerable =
        bytes4(keccak256("deedByIndex()")) ^
        bytes4(keccak256("countOfOwners()")) ^
        bytes4(keccak256("ownerByIndex(uint256)"));

    function deedByIndex(uint256 _index) external view returns (uint256 _deedId);
    function countOfOwners() external view returns (uint256 _count);
    function ownerByIndex(uint256 _index) external view returns (address _owner);
}

contract ERC721Original {

    bytes4 constant INTERFACE_SIGNATURE_ERC721Original =
        bytes4(keccak256("totalSupply()")) ^
        bytes4(keccak256("balanceOf(address)")) ^
        bytes4(keccak256("ownerOf(uint256)")) ^
        bytes4(keccak256("approve(address,uint256)")) ^
        bytes4(keccak256("takeOwnership(uint256)")) ^
        bytes4(keccak256("transfer(address,uint256)"));

     
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 _totalSupply);
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint _tokenId) public view returns (address _owner);
    function approve(address _to, uint _tokenId) external payable;
    function transferFrom(address _from, address _to, uint _tokenId) public;
    function transfer(address _to, uint _tokenId) public payable;

     
    function name() public pure returns (string _name);
    function symbol() public pure returns (string _symbol);
    function tokenOfOwnerByIndex(address _owner, uint _index) external view returns (uint _tokenId);
    function tokenMetadata(uint _tokenId) public view returns (string _infoUrl);

     
     
     
}

contract ERC721AllImplementations is ERC721Original, ERC721Enumerable {

}


contract EtherbotsNFT is EtherbotsBase, ERC721Enumerable, ERC721Original {
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return (_interfaceID == ERC721Original.INTERFACE_SIGNATURE_ERC721Original) ||
            (_interfaceID == ERC721.INTERFACE_SIGNATURE_ERC721) ||
            (_interfaceID == ERC721Metadata.INTERFACE_SIGNATURE_ERC721Metadata) ||
            (_interfaceID == ERC721Enumerable.INTERFACE_SIGNATURE_ERC721Enumerable);
    }
    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function name() public pure returns (string _name) {
      return "Etherbots";
    }

    function symbol() public pure returns (string _smbol) {
      return "ETHBOT";
    }

     
     
    function totalSupply() public view returns (uint) {
        return parts.length;
    }

     
     
    function countOfDeeds() external view returns (uint256) {
        return parts.length;
    }

     
     
    function owns(address _owner, uint256 _tokenId) public view returns (bool) {
        return (partIndexToOwner[_tokenId] == _owner);
    }

     
     
    function ownsAll(address _owner, uint256[] _tokenIds) public view returns (bool) {
        require(_tokenIds.length > 0);
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (partIndexToOwner[_tokenIds[i]] != _owner) {
                return false;
            }
        }
        return true;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        partIndexToApproved[_tokenId] = _approved;
    }

    function _approvedFor(address _newOwner, uint256 _tokenId) internal view returns (bool) {
        return (partIndexToApproved[_tokenId] == _newOwner);
    }

    function ownerByIndex(uint256 _index) external view returns (address _owner){
        return partIndexToOwner[_index];
    }

     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return addressToTokensOwned[_owner];
    }

    function countOfDeedsByOwner(address _owner) external view returns (uint256) {
        return balanceOf(_owner);
    }

     
    function transfer(address _to, uint256 _tokenId) public whenNotPaused payable {
         
        require(msg.value == 0);

         
        require(_to != address(0));
        require(_to != address(this));
         
        require(_to != address(auction));
         
        for (uint j = 0; j < approvedBattles.length; j++) {
            require(_to != approvedBattles[j]);
        }

         
        require(owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }
     

    function transferAll(address _to, uint256[] _tokenIds) public whenNotPaused payable {
        require(msg.value == 0);

         
        require(_to != address(0));
        require(_to != address(this));
         
        require(_to != address(auction));
         
        for (uint j = 0; j < approvedBattles.length; j++) {
            require(_to != approvedBattles[j]);
        }

         
        require(ownsAll(msg.sender, _tokenIds));

        for (uint k = 0; k < _tokenIds.length; k++) {
             
            _transfer(msg.sender, _to, _tokenIds[k]);
        }


    }


     
     
    function approve(address _to, uint256 _deedId) external whenNotPaused payable {
         
        require(msg.value == 0);
 
         
        require(owns(msg.sender, _deedId));

         
        partIndexToApproved[_deedId] = _to;

        Approval(msg.sender, _to, _deedId);
    }

     
    function approveMany(address _to, uint256[] _tokenIds) external whenNotPaused payable {

        for (uint i = 0; i < _tokenIds.length; i++) {
            uint _tokenId = _tokenIds[i];

             
            require(owns(msg.sender, _tokenId));

             
            partIndexToApproved[_tokenId] = _to;
             
            Approval(msg.sender, _to, _tokenId);
        }
    }

     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {

         
        require(_to != address(0));
        require(_to != address(this));

         
        require(partIndexToApproved[_tokenId] == msg.sender);
         
        require(owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
    function ownerOf(uint256 _deedId) public view returns (address _owner) {
        _owner = partIndexToOwner[_deedId];
         
        require(_owner != address(0));
    }

     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 totalParts = totalSupply();

        return tokensOfOwnerWithinRange(_owner, 0, totalParts);
  
    }

    function tokensOfOwnerWithinRange(address _owner, uint _start, uint _numToSearch) public view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tmpResult = new uint256[](tokenCount);
        if (tokenCount == 0) {
            return tmpResult;
        }

        uint256 resultIndex = 0;
        for (uint partId = _start; partId < _start + _numToSearch; partId++) {
            if (partIndexToOwner[partId] == _owner) {
                tmpResult[resultIndex] = partId;
                resultIndex++;
                if (resultIndex == tokenCount) {  
                    break;
                }
            }
        }

         
        uint resultLength = resultIndex;
        uint256[] memory result = new uint256[](resultLength);
        for (uint i=0; i<resultLength; i++) {
            result[i] = tmpResult[i];
        }
        return result;
    }



     
     
    function getPartsOfOwner(address _owner) external view returns(bytes24[]) {
        uint256 totalParts = totalSupply();

        return getPartsOfOwnerWithinRange(_owner, 0, totalParts);
    }
    
     
     
    function getPartsOfOwnerWithinRange(address _owner, uint _start, uint _numToSearch) public view returns(bytes24[]) {
        uint256 tokenCount = balanceOf(_owner);

        uint resultIndex = 0;
        bytes24[] memory result = new bytes24[](tokenCount);
        for (uint partId = _start; partId < _start + _numToSearch; partId++) {
            if (partIndexToOwner[partId] == _owner) {
                result[resultIndex] = _partToBytes(parts[partId]);
                resultIndex++;
            }
        }
        return result;  
    }


    function _partToBytes(Part p) internal pure returns (bytes24 b) {
        b = bytes24(p.tokenId);

        b = b << 8;
        b = b | bytes24(p.partType);

        b = b << 8;
        b = b | bytes24(p.partSubType);

        b = b << 8;
        b = b | bytes24(p.rarity);

        b = b << 8;
        b = b | bytes24(p.element);

        b = b << 32;
        b = b | bytes24(p.battlesLastDay);

        b = b << 32;
        b = b | bytes24(p.experience);

        b = b << 32;
        b = b | bytes24(p.forgeTime);

        b = b << 32;
        b = b | bytes24(p.battlesLastReset);
    }

    uint32 constant FIRST_LEVEL = 1000;
    uint32 constant INCREMENT = 1000;

     
    function getLevel(uint32 _exp) public pure returns(uint32) {
        uint32 c = 0;
        for (uint32 i = FIRST_LEVEL; i <= FIRST_LEVEL + _exp; i += c * INCREMENT) {
            c++;
        }
        return c;
    }

    string metadataBase = "https://api.etherbots.io/api/";


    function setMetadataBase(string _base) external onlyOwner {
        metadataBase = _base;
    }

     
     
    function _metadata(uint256 _id) internal view returns(string) {
        Part memory p = parts[_id];
        return strConcat(strConcat(
            metadataBase,
            uintToString(uint(p.partType)),
            "/",
            uintToString(uint(p.partSubType)),
            "/"
        ), uintToString(uint(p.rarity)), "", "", "");
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function deedUri(uint256 _deedId) external view returns (string _uri){
        return _metadata(_deedId);
    }

     
    function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl) {
        return _metadata(_tokenId);
    }

    function takeOwnership(uint256 _deedId) external payable {
         
        require(msg.value == 0);

        address _from = partIndexToOwner[_deedId];

        require(_approvedFor(msg.sender, _deedId));

        _transfer(_from, msg.sender, _deedId);
    }

     
    function deedByIndex(uint256 _index) external view returns (uint256 _deedId){
        return _index;
    }

    function countOfOwners() external view returns (uint256 _count){
         
        return 0;
    }

 
    function tokenOfOwnerByIndex(address _owner, uint _index) external view returns (uint _tokenId){
        return _tokenOfOwnerByIndex(_owner, _index);
    }

 
    function _tokenOfOwnerByIndex(address _owner, uint _index) private view returns (uint _tokenId){
         
        require(_index < balanceOf(_owner));

         
        uint256 seen = 0;
        uint256 totalTokens = totalSupply();

        for (uint i = 0; i < totalTokens; i++) {
            if (partIndexToOwner[i] == _owner) {
                if (seen == _index) {
                    return i;
                }
                seen++;
            }
        }
    }

    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _deedId){
        return _tokenOfOwnerByIndex(_owner, _index);
    }
}





 
 
 
 
contract NFTAuctionBase is Pausable {

    ERC721AllImplementations public nftContract;
    uint256 public ownerCut;
    uint public minDuration;
    uint public maxDuration;

     
    struct Auction {
         
        address seller;
         
        uint256 startPrice;
         
        uint256 endPrice;
         
        uint64 duration;
         
         
        uint64 start;
    }

    function NFTAuctionBase() public {
        minDuration = 60 minutes;
        maxDuration = 30 days;  
    }

     
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startPrice, uint256 endPrice, uint64 duration, uint64 start);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

     
    function _owns(address _claimant, uint256 _partId) internal view returns (bool) {
        return nftContract.ownerOf(_partId) == _claimant;
    }

    
    function _isActiveAuction(Auction _auction) internal pure returns (bool) {
        return _auction.start > 0;
    }
    
     
     
    function _escrow(address, uint _partId) internal {
         
        nftContract.takeOwnership(_partId);
    }

     
    function _transfer(address _purchasor, uint256 _partId) internal {
         
         
                
                nftContract.transfer(_purchasor, _partId);

    }

     
    function _newAuction(uint256 _partId, Auction _auction) internal {

        require(_auction.duration >= minDuration);
        require(_auction.duration <= maxDuration);

        tokenIdToAuction[_partId] = _auction;

        AuctionCreated(uint256(_partId),
            uint256(_auction.startPrice),
            uint256(_auction.endPrice),
            uint64(_auction.duration),
            uint64(_auction.start)
        );
    }

    function setMinDuration(uint _duration) external onlyOwner {
        minDuration = _duration;
    }

    function setMaxDuration(uint _duration) external onlyOwner {
        maxDuration = _duration;
    }

     
    function _cancelAuction(uint256 _partId, address _seller) internal {
        _removeAuction(_partId);
        _transfer(_seller, _partId);
        AuctionCancelled(_partId);
    }

    event PrintEvent(string, address, uint);

     
    function _purchase(uint256 _partId, uint256 _purchaseAmount) internal returns (uint256) {

        Auction storage auction = tokenIdToAuction[_partId];

         
        require(_isActiveAuction(auction));

         
        uint256 price = _currentPrice(auction);
        require(_purchaseAmount >= price);

         
        address seller = auction.seller;

         
        _removeAuction(_partId);

         
        if (price > 0) {
            
             

            uint256 auctioneerCut = _computeFee(price);
            uint256 sellerProceeds = price - auctioneerCut;

            PrintEvent("Seller, proceeds", seller, sellerProceeds);

             
            seller.transfer(sellerProceeds);
        }

         
        uint256 purchaseExcess = _purchaseAmount - price;

        PrintEvent("Sender, excess", msg.sender, purchaseExcess);
         
        msg.sender.transfer(purchaseExcess);

        AuctionSuccessful(_partId, price, msg.sender);

        return price;
    }

     
    function _currentPrice(Auction storage _auction) internal view returns (uint256) {
        uint256 secsElapsed = now - _auction.start;
        return _computeCurrentPrice(
            _auction.startPrice,
            _auction.endPrice,
            _auction.duration,
            secsElapsed
        );
    }

     
     
     
     

     
    function _removeAuction(uint256 _partId) internal {
        delete tokenIdToAuction[_partId];
    }

     
    function _computeCurrentPrice( uint256 _startPrice, uint256 _endPrice, uint256 _duration, uint256 _secondsPassed ) internal pure returns (uint256 _price) {
        _price = _startPrice;
        if (_secondsPassed >= _duration) {
             
             
            _price = _endPrice;
             
        }
        else if (_duration > 0) {
             
             
            int256 priceDifference = int256(_endPrice) - int256(_startPrice);
            int256 currentPriceDifference = priceDifference * int256(_secondsPassed) / int256(_duration);
            int256 currentPrice = int256(_startPrice) + currentPriceDifference;

            _price = uint256(currentPrice);
        }
        return _price;
    }

     

    function _computeFee (uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000; 
    }

}

 
 
 
 

contract DutchAuction is NFTAuctionBase, EtherbotsPrivileges {

     
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0xda671b9b);
 
    function DutchAuction(address _nftAddress, uint256 _fee) public {
        require(_fee <= 10000);
        ownerCut = _fee;

        ERC721AllImplementations candidateContract = ERC721AllImplementations(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nftContract = candidateContract;
    }

     
     
     

    function withdrawBalance() external {
        address nftAddress = address(nftContract);

        require(msg.sender == owner || msg.sender == nftAddress);

        nftAddress.transfer(this.balance);
    }

    event PrintEvent(string, address, uint);

     
    function createAuction( uint256 _partId, uint256 _startPrice, uint256 _endPrice, uint256 _duration, address _seller ) external whenNotPaused {
         
         
        require(_startPrice == uint256(uint128(_startPrice)));
        require(_endPrice == uint256(uint128(_endPrice)));
        require(_duration == uint256(uint64(_duration)));
        require(_startPrice >= _endPrice);

        require(msg.sender == address(nftContract));
        _escrow(_seller, _partId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startPrice),
            uint128(_endPrice),
            uint64(_duration),
            uint64(now)  
        );
        PrintEvent("Auction Start", 0x0, auction.start);
        _newAuction(_partId, auction);
    }


     

    uint8 constant LAST_CONSIDERED = 5;
    uint8 public scrapCounter = 0;
    uint[5] public lastScrapPrices;
    
     
     
    
    function purchase(uint256 _partId) external payable whenNotPaused {
        address seller = tokenIdToAuction[_partId].seller;

         
        uint256 price = _purchase(_partId, msg.value);
        _transfer(msg.sender, _partId);
        
         
        if (seller == address(nftContract)) {

            lastScrapPrices[scrapCounter] = price;
            if (scrapCounter == LAST_CONSIDERED - 1) {
                scrapCounter = 0;
            } else {
                scrapCounter++;
            }
        }
    }

    function averageScrapPrice() public view returns (uint) {
        uint sum = 0;
        for (uint8 i = 0; i < LAST_CONSIDERED; i++) {
            sum += lastScrapPrices[i];
        }
        return sum / LAST_CONSIDERED;
    }

     
     

    function cancelAuction(uint256 _partId) external {
        Auction storage auction = tokenIdToAuction[_partId];
        require(_isActiveAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_partId, seller);
    }

     
    function getCurrentPrice(uint256 _partId) external view returns (uint256) {
        Auction storage auction = tokenIdToAuction[_partId];
        require(_isActiveAuction(auction));
        return _currentPrice(auction);
    }

     
    function getAuction(uint256 _partId) external view returns ( address seller, uint256 startPrice, uint256 endPrice, uint256 duration, uint256 startedAt ) {
        Auction storage auction = tokenIdToAuction[_partId];
        require(_isActiveAuction(auction));
        return ( auction.seller, auction.startPrice, auction.endPrice, auction.duration, auction.start);
    }

     
     
     
     
     
    function cancelAuctionWhenPaused(uint256 _partId) whenPaused onlyOwner external {
        Auction storage auction = tokenIdToAuction[_partId];
        require(_isActiveAuction(auction));
        _cancelAuction(_partId, auction.seller);
    }
}