 

pragma solidity ^0.4.18;

 

 
 
contract AetherAccessControl {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused = false;

     
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

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
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

    function withdrawBalance() external onlyCFO {
        cfoAddress.transfer(this.balance);
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

 

 
 
 
contract AetherBase is AetherAccessControl {
     

     
    event Construct (
      address indexed owner,
      uint256 propertyId,
      PropertyClass class,
      uint8 x,
      uint8 y,
      uint8 z,
      uint8 dx,
      uint8 dz,
      string data
    );

     
     
    event Transfer(
      address indexed from,
      address indexed to,
      uint256 indexed tokenId
    );

     

    enum PropertyClass { DISTRICT, BUILDING, UNIT }

     
     
    struct Property {
        uint32 parent;
        PropertyClass class;
        uint8 x;
        uint8 y;
        uint8 z;
        uint8 dx;
        uint8 dz;
    }

     

     
    bool[100][100][100] public world;

     
     
    Property[] properties;

     
    uint256[] districts;

     
    uint256 public progress;

     
    uint256 public unitCreationFee = 0.05 ether;

     
    bool public updateEnabled = true;

     
     
    mapping (uint256 => address) public propertyIndexToOwner;

     
    mapping (uint256 => string) public propertyIndexToData;

     
     
    mapping (address => uint256) ownershipTokenCount;

     
    mapping (uint256 => uint256) public districtToBuildingsCount;
    mapping (uint256 => uint256[]) public districtToBuildings;
    mapping (uint256 => uint256) public buildingToUnitCount;
    mapping (uint256 => uint256[]) public buildingToUnits;

     
    mapping (uint256 => bool) public buildingIsPublic;

     
     
     
    mapping (uint256 => address) public propertyIndexToApproved;

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
       
       
      ownershipTokenCount[_to]++;
       
      propertyIndexToOwner[_tokenId] = _to;
       
      if (_from != address(0)) {
          ownershipTokenCount[_from]--;
           
          delete propertyIndexToApproved[_tokenId];
      }
       
      Transfer(_from, _to, _tokenId);
    }

    function _createUnit(
      uint256 _parent,
      uint256 _x,
      uint256 _y,
      uint256 _z,
      address _owner
    )
        internal
        returns (uint)
    {
      require(_x == uint256(uint8(_x)));
      require(_y == uint256(uint8(_y)));
      require(_z == uint256(uint8(_z)));
      require(!world[_x][_y][_z]);
      world[_x][_y][_z] = true;
      return _createProperty(
        _parent,
        PropertyClass.UNIT,
        _x,
        _y,
        _z,
        0,
        0,
        _owner
      );
    }

    function _createBuilding(
      uint256 _parent,
      uint256 _x,
      uint256 _y,
      uint256 _z,
      uint256 _dx,
      uint256 _dz,
      address _owner,
      bool _public
    )
        internal
        returns (uint)
    {
      require(_x == uint256(uint8(_x)));
      require(_y == uint256(uint8(_y)));
      require(_z == uint256(uint8(_z)));
      require(_dx == uint256(uint8(_dx)));
      require(_dz == uint256(uint8(_dz)));

       
      for(uint256 i = 0; i < _dx; i++) {
          for(uint256 j = 0; j <_dz; j++) {
              if (world[_x + i][0][_z + j]) {
                  revert();
              }
              world[_x + i][0][_z + j] = true;
          }
      }

      uint propertyId = _createProperty(
        _parent,
        PropertyClass.BUILDING,
        _x,
        _y,
        _z,
        _dx,
        _dz,
        _owner
      );

      districtToBuildingsCount[_parent]++;
      districtToBuildings[_parent].push(propertyId);
      buildingIsPublic[propertyId] = _public;
      return propertyId;
    }

    function _createDistrict(
      uint256 _x,
      uint256 _z,
      uint256 _dx,
      uint256 _dz
    )
        internal
        returns (uint)
    {
      require(_x == uint256(uint8(_x)));
      require(_z == uint256(uint8(_z)));
      require(_dx == uint256(uint8(_dx)));
      require(_dz == uint256(uint8(_dz)));

      uint propertyId = _createProperty(
        districts.length,
        PropertyClass.DISTRICT,
        _x,
        0,
        _z,
        _dx,
        _dz,
        cooAddress
      );

      districts.push(propertyId);
      return propertyId;

    }


     
     
     
     
    function _createProperty(
        uint256 _parent,
        PropertyClass _class,
        uint256 _x,
        uint256 _y,
        uint256 _z,
        uint256 _dx,
        uint256 _dz,
        address _owner
    )
        internal
        returns (uint)
    {
        require(_x == uint256(uint8(_x)));
        require(_y == uint256(uint8(_y)));
        require(_z == uint256(uint8(_z)));
        require(_dx == uint256(uint8(_dx)));
        require(_dz == uint256(uint8(_dz)));
        require(_parent == uint256(uint32(_parent)));
        require(uint256(_class) <= 3);

        Property memory _property = Property({
            parent: uint32(_parent),
            class: _class,
            x: uint8(_x),
            y: uint8(_y),
            z: uint8(_z),
            dx: uint8(_dx),
            dz: uint8(_dz)
        });
        uint256 _tokenId = properties.push(_property) - 1;

         
         
        require(_tokenId <= 4294967295);

        Construct(
            _owner,
            _tokenId,
            _property.class,
            _property.x,
            _property.y,
            _property.z,
            _property.dx,
            _property.dz,
            ""
        );

         
         
        _transfer(0, _owner, _tokenId);

        return _tokenId;
    }

     
    function _computeHeight(
      uint256 _x,
      uint256 _z,
      uint256 _height
    ) internal view returns (uint256) {
        uint256 x = _x < 50 ? 50 - _x : _x - 50;
        uint256 z = _z < 50 ? 50 - _z : _z - 50;
        uint256 distance = x > z ? x : z;
        if (distance > progress) {
          return 1;
        }
        uint256 scale = 100 - (distance * 100) / progress ;
        uint256 height = 2 * progress * _height * scale / 10000;
        return height > 0 ? height : 1;
    }

     
    function canCreateUnit(uint256 _buildingId)
        public
        view
        returns(bool)
    {
      Property storage _property = properties[_buildingId];
      if (_property.class == PropertyClass.BUILDING &&
            (buildingIsPublic[_buildingId] ||
              propertyIndexToOwner[_buildingId] == msg.sender)
      ) {
        uint256 totalVolume = _property.dx * _property.dz *
          (_computeHeight(_property.x, _property.z, _property.y) - 1);
        uint256 totalUnits = buildingToUnitCount[_buildingId];
        return totalUnits < totalVolume;
      }
      return false;
    }

     
     
    function _createUnitHelper(uint256 _buildingId, address _owner)
        internal
        returns(uint256)
    {
         
        Property storage _property = properties[_buildingId];
        uint256 totalArea = _property.dx * _property.dz;
        uint256 index = buildingToUnitCount[_buildingId];

         
        uint256 y = index / totalArea + 1;
        uint256 intermediate = index % totalArea;
        uint256 z = intermediate / _property.dx;
        uint256 x = intermediate % _property.dx;

        uint256 unitId = _createUnit(
          _buildingId,
          x + _property.x,
          y,
          z + _property.z,
          _owner
        );

        buildingToUnitCount[_buildingId]++;
        buildingToUnits[_buildingId].push(unitId);

         
        return unitId;
    }

     
    function updateBuildingPrivacy(uint _tokenId, bool _public) public {
        require(propertyIndexToOwner[_tokenId] == msg.sender);
        buildingIsPublic[_tokenId] = _public;
    }

     
    function updatePropertyData(uint _tokenId, string _data) public {
        require(updateEnabled);
        address _owner = propertyIndexToOwner[_tokenId];
        require(msg.sender == _owner);
        propertyIndexToData[_tokenId] = _data;
        Property memory _property = properties[_tokenId];
        Construct(
            _owner,
            _tokenId,
            _property.class,
            _property.x,
            _property.y,
            _property.z,
            _property.dx,
            _property.dz,
            _data
        );
    }
}

 

 
 
contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

     
     
     
     
     
}

 

 
 
 
contract AetherOwnership is AetherBase, ERC721 {

     
    string public name = "Aether";
    string public symbol = "AETH";

    function implementsERC721() public pure returns (bool)
    {
        return true;
    }

     
     
     

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return propertyIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return propertyIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        propertyIndexToApproved[_tokenId] = _approved;
    }

     
     
     
     
     
     
    function rescueLostProperty(uint256 _propertyId, address _recipient) public onlyCOO whenNotPaused {
        require(_owns(this, _propertyId));
        _transfer(this, _recipient, _propertyId);
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
         
        require(_to != address(0));
         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint) {
        return properties.length;
    }

    function totalDistrictSupply() public view returns(uint count) {
        return districts.length;
    }

     
     
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = propertyIndexToOwner[_tokenId];

        require(owner != address(0));
    }


     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalProperties = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 tokenId;

            for (tokenId = 1; tokenId <= totalProperties; tokenId++) {
                if (propertyIndexToOwner[tokenId] == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
}

 

 
 
contract ClockAuctionBase {

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
    ERC721 public nonFungibleContract;

     
     
    uint256 public ownerCut;

     
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

     
    function() external {}

     
     
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615);
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
    function _escrow(address _owner, uint256 _tokenId) internal {
         
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

     
     
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
         
        Auction storage auction = tokenIdToAuction[_tokenId];

         
         
         
         
        require(_isOnAuction(auction));

         
         
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
        }

         
        AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

     
     
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

     
     
     
     
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

         
         
         
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

     
     
     
     
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
         
         
         
         
         
        if (_secondsPassed >= _duration) {
             
             
            return _endingPrice;
        } else {
             
             
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

             
             
             
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

             
             
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

     
     
    function _computeCut(uint256 _price) internal view returns (uint256) {
         
         
         
         
         
        return _price * ownerCut / 10000;
    }

}

 

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

 

 
contract ClockAuction is Pausable, ClockAuctionBase {

     
     
     
     
     
     
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;
        
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.implementsERC721());
        nonFungibleContract = candidateContract;
    }

     
     
     
     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        nftAddress.transfer(this.balance);
    }

     
     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        public
        whenNotPaused
        canBeStoredWith128Bits(_startingPrice)
        canBeStoredWith128Bits(_endingPrice)
        canBeStoredWith64Bits(_duration)
    {
        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
     
     
    function bid(uint256 _tokenId)
        public
        payable
        whenNotPaused
    {
         
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

     
     
     
     
     
    function cancelAuction(uint256 _tokenId)
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

     
     
     
     
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

     
     
    function getAuction(uint256 _tokenId)
        public
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

     
     
    function getCurrentPrice(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}

 

 
contract AetherClockAuction is ClockAuction {

     
     
    bool public isAetherClockAuction = true;

     
    uint256 public saleCount;
    uint256[5] public lastSalePrices;

     
    function AetherClockAuction(address _nftAddr, uint256 _cut) public
      ClockAuction(_nftAddr, _cut) {}


     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        public
        canBeStoredWith128Bits(_startingPrice)
        canBeStoredWith128Bits(_endingPrice)
        canBeStoredWith64Bits(_duration)
    {
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
     
    function bid(uint256 _tokenId)
        public
        payable
    {
         
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

         
        if (seller == address(nonFungibleContract)) {
             
            lastSalePrices[saleCount % 5] = price;
            saleCount++;
        }
    }

    function averageSalePrice() public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastSalePrices[i];
        }
        return sum / 5;
    }
}

 

 
 
 
contract AetherAuction is AetherOwnership{

     
     
     
    AetherClockAuction public saleAuction;

     
     
    function setSaleAuctionAddress(address _address) public onlyCEO {
        AetherClockAuction candidateContract = AetherClockAuction(_address);

         
        require(candidateContract.isAetherClockAuction());

         
        saleAuction = candidateContract;
    }

     
     
    function createSaleAuction(
        uint256 _propertyId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        public
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _propertyId));
        _approve(_propertyId, saleAuction);
         
         
        saleAuction.createAuction(
            _propertyId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
     
     
    function withdrawAuctionBalances() external onlyCOO {
        saleAuction.withdrawBalance();
    }
}

 

 


 
contract AetherConstruct is AetherAuction {

    uint256 public districtLimit = 16;
    uint256 public startingPrice = 1 ether;
    uint256 public auctionDuration = 1 days;

     
    function createUnit(uint256 _buildingId)
        public
        payable
        returns(uint256)
    {
        require(canCreateUnit(_buildingId));
        require(msg.value >= unitCreationFee);
        if (msg.value > unitCreationFee)
            msg.sender.transfer(msg.value - unitCreationFee);
        uint256 propertyId = _createUnitHelper(_buildingId, msg.sender);
        return propertyId;
    }

     
    function createUnitOmni(
      uint32 _buildingId,
      address _owner
    )
      public
      onlyCOO
    {
        if (_owner == address(0)) {
             _owner = cooAddress;
        }
        require(canCreateUnit(_buildingId));
        _createUnitHelper(_buildingId, _owner);
    }

     
    function createBuildingOmni(
      uint32 _districtId,
      uint8 _x,
      uint8 _y,
      uint8 _z,
      uint8 _dx,
      uint8 _dz,
      address _owner,
      bool _open
    )
      public
      onlyCOO
    {
        if (_owner == address(0)) {
             _owner = cooAddress;
        }
        _createBuilding(_districtId, _x, _y, _z, _dx, _dz, _owner, _open);
    }

     
    function createDistrictOmni(
      uint8 _x,
      uint8 _z,
      uint8 _dx,
      uint8 _dz
    )
      public
      onlyCOO
    {
      require(districts.length < districtLimit);
      _createDistrict(_x, _z, _dx, _dz);
    }


     
     
    function createBuildingAuction(
      uint32 _districtId,
      uint8 _x,
      uint8 _y,
      uint8 _z,
      uint8 _dx,
      uint8 _dz,
      bool _open
    ) public onlyCOO {
        uint256 propertyId = _createBuilding(_districtId, _x, _y, _z, _dx, _dz, address(this), _open);
        _approve(propertyId, saleAuction);

        saleAuction.createAuction(
            propertyId,
            _computeNextPrice(),
            0,
            auctionDuration,
            address(this)
        );
    }

     
     
    function setUnitCreationFee(uint256 _value) public onlyCOO {
        unitCreationFee = _value;
    }

     
     
    function setProgress(uint256 _progress) public onlyCOO {
        require(_progress <= 100);
        require(_progress > progress);
        progress = _progress;
    }

     
    function setUpdateState(bool _updateEnabled) public onlyCOO {
        updateEnabled = _updateEnabled;
    }

     
     
    function _computeNextPrice() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageSalePrice();

         
        require(avePrice < 340282366920938463463374607431768211455);

        uint256 nextPrice = avePrice + (avePrice / 2);

         
        if (nextPrice < startingPrice) {
            nextPrice = startingPrice;
        }

        return nextPrice;
    }
}

 

 
 
contract AetherCore is AetherConstruct {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     

     
    address public newContractAddress;

     
    function AetherCore() public {
         
        paused = true;

         
        ceoAddress = msg.sender;

         
        cooAddress = msg.sender;
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) public onlyCEO whenPaused {
         
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

     
     
     
    function() external payable {
        require(
            msg.sender == address(saleAuction)
        );
    }

     
     
    function getProperty(uint256 _id)
        public
        view
        returns (
        uint32 parent,
        uint8 class,
        uint8 x,
        uint8 y,
        uint8 z,
        uint8 dx,
        uint8 dz,
        uint8 height
    ) {
        Property storage property = properties[_id];
        parent = uint32(property.parent);
        class = uint8(property.class);

        height = uint8(property.y);
        if (property.class == PropertyClass.BUILDING) {
          y = uint8(_computeHeight(property.x, property.z, property.y));
        } else {
          y = uint8(property.y);
        }

        x = uint8(property.x);
        z = uint8(property.z);
        dx = uint8(property.dx);
        dz = uint8(property.dz);
    }

     
     
     
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(newContractAddress == address(0));
         
        super.unpause();
    }
}