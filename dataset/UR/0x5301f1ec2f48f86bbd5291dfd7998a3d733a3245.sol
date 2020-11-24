 

pragma solidity ^0.4.18;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
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


 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}


 
 
 
interface ERC721 {

     

     
     
     

     
     
     
     
     
     
     
     

     
     
     
     
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool);

     

     
     
     
     
     
     
    function ownerOf(uint256 _deedId) external view returns (address _owner);

     
     
     
    function countOfDeeds() public view returns (uint256 _count);

     
     
     
     
    function countOfDeedsByOwner(address _owner) public view returns (uint256 _count);

     
     
     
     
     
     
     
     
    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _deedId);

     

     
     
     
     
    event Transfer(address indexed from, address indexed to, uint256 indexed deedId);

     
     
     
     
    event Approval(address indexed owner, address indexed approved, uint256 indexed deedId);

     
     
     
     
     
     
    function approve(address _to, uint256 _deedId) external;

     
     
     
     
    function takeOwnership(uint256 _deedId) external;
    
     
    
     
     
     
     
     
    function transfer(address _to, uint256 _deedId) external;
}


 
 
 
interface ERC721Metadata {

     
     
     
     
     

     
     
     
    function name() public pure returns (string _deedName);

     
     
    function symbol() public pure returns (string _deedSymbol);

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function deedUri(uint256 _deedId) external pure returns (string _uri);
}


 
contract DWorldAccessControl is Claimable, Pausable, CanReclaimToken {
    address public cfoAddress;

    function DWorldAccessControl() public {
         
        cfoAddress = msg.sender;
    }
    
     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
     
    function setCFO(address _newCFO) external onlyOwner {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
}


 
contract DWorldBase is DWorldAccessControl {
    using SafeMath for uint256;
    
     
     
     
     
     
     
     
    uint32[] public plots;
    
    mapping (uint256 => address) identifierToOwner;
    mapping (uint256 => address) identifierToApproved;
    mapping (address => uint256) ownershipDeedCount;
    
     
     
     
     
     
     
    event SetData(uint256 indexed deedId, string name, string description, string imageUrl, string infoUrl);
    
     
    function getAllPlots() external view returns(uint32[]) {
        return plots;
    }
    
     
     
     
    function coordinateToIdentifier(uint256 x, uint256 y) public pure returns(uint256) {
        require(validCoordinate(x, y));
        
        return (y << 16) + x;
    }
    
     
     
    function identifierToCoordinate(uint256 identifier) public pure returns(uint256 x, uint256 y) {
        require(validIdentifier(identifier));
    
        y = identifier >> 16;
        x = identifier - (y << 16);
    }
    
     
     
     
    function validCoordinate(uint256 x, uint256 y) public pure returns(bool) {
        return x < 65536 && y < 65536;  
    }
    
     
     
    function validIdentifier(uint256 identifier) public pure returns(bool) {
        return identifier < 4294967296;  
    }
    
     
     
    function _setPlotData(uint256 identifier, string name, string description, string imageUrl, string infoUrl) internal {
        SetData(identifier, name, description, imageUrl, infoUrl);
    }
}


 
contract DWorldDeed is DWorldBase, ERC721, ERC721Metadata {
    
     
    function name() public pure returns (string _deedName) {
        _deedName = "DWorld Plots";
    }
    
     
    function symbol() public pure returns (string _deedSymbol) {
        _deedSymbol = "DWP";
    }
    
     
    bytes4 internal constant INTERFACE_SIGNATURE_ERC165 =  
        bytes4(keccak256('supportsInterface(bytes4)'));

     
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721 =  
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('countOfDeeds()')) ^
        bytes4(keccak256('countOfDeedsByOwner(address)')) ^
        bytes4(keccak256('deedOfOwnerByIndex(address,uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('takeOwnership(uint256)'));
        
     
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata =  
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('deedUri(uint256)'));
    
     
     
     
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return (
            (_interfaceID == INTERFACE_SIGNATURE_ERC165)
            || (_interfaceID == INTERFACE_SIGNATURE_ERC721)
            || (_interfaceID == INTERFACE_SIGNATURE_ERC721Metadata)
        );
    }
    
     
     
     
    function _owns(address _owner, uint256 _deedId) internal view returns (bool) {
        return identifierToOwner[_deedId] == _owner;
    }
    
     
     
     
     
    function _approve(address _from, address _to, uint256 _deedId) internal {
        identifierToApproved[_deedId] = _to;
        
         
        Approval(_from, _to, _deedId);
    }
    
     
     
     
    function _approvedFor(address _claimant, uint256 _deedId) internal view returns (bool) {
        return identifierToApproved[_deedId] == _claimant;
    }
    
     
     
     
     
    function _transfer(address _from, address _to, uint256 _deedId) internal {
         
         
        ownershipDeedCount[_to]++;
        
         
        identifierToOwner[_deedId] = _to;
        
         
         
        if (_from != address(0)) {
            ownershipDeedCount[_from]--;
            
             
            delete identifierToApproved[_deedId];
        }
        
         
        Transfer(_from, _to, _deedId);
    }
    
     
    
     
     
    function countOfDeeds() public view returns (uint256) {
        return plots.length;
    }
    
     
     
     
    function countOfDeedsByOwner(address _owner) public view returns (uint256) {
        return ownershipDeedCount[_owner];
    }
    
     
     
    function ownerOf(uint256 _deedId) external view returns (address _owner) {
        _owner = identifierToOwner[_deedId];

        require(_owner != address(0));
    }
    
     
     
     
     
    function approve(address _to, uint256 _deedId) external whenNotPaused {
        uint256[] memory _deedIds = new uint256[](1);
        _deedIds[0] = _deedId;
        
        approveMultiple(_to, _deedIds);
    }
    
     
     
     
    function approveMultiple(address _to, uint256[] _deedIds) public whenNotPaused {
         
        require(msg.sender != _to);
    
        for (uint256 i = 0; i < _deedIds.length; i++) {
            uint256 _deedId = _deedIds[i];
            
             
            require(_owns(msg.sender, _deedId));
            
             
            _approve(msg.sender, _to, _deedId);
        }
    }
    
     
     
     
     
     
     
    function transfer(address _to, uint256 _deedId) external whenNotPaused {
        uint256[] memory _deedIds = new uint256[](1);
        _deedIds[0] = _deedId;
        
        transferMultiple(_to, _deedIds);
    }
    
     
     
     
     
     
    function transferMultiple(address _to, uint256[] _deedIds) public whenNotPaused {
         
        require(_to != address(0));
        
         
        require(_to != address(this));
    
        for (uint256 i = 0; i < _deedIds.length; i++) {
            uint256 _deedId = _deedIds[i];
            
             
            require(_owns(msg.sender, _deedId));

             
            _transfer(msg.sender, _to, _deedId);
        }
    }
    
     
     
     
     
    function takeOwnership(uint256 _deedId) external whenNotPaused {
        uint256[] memory _deedIds = new uint256[](1);
        _deedIds[0] = _deedId;
        
        takeOwnershipMultiple(_deedIds);
    }
    
     
     
     
    function takeOwnershipMultiple(uint256[] _deedIds) public whenNotPaused {
        for (uint256 i = 0; i < _deedIds.length; i++) {
            uint256 _deedId = _deedIds[i];
            address _from = identifierToOwner[_deedId];
            
             
            require(_approvedFor(msg.sender, _deedId));

             
            _transfer(_from, msg.sender, _deedId);
        }
    }
    
     
     
     
     
     
    function deedsOfOwner(address _owner) external view returns(uint256[]) {
        uint256 deedCount = countOfDeedsByOwner(_owner);

        if (deedCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](deedCount);
            uint256 totalDeeds = countOfDeeds();
            uint256 resultIndex = 0;
            
            for (uint256 deedNumber = 0; deedNumber < totalDeeds; deedNumber++) {
                uint256 identifier = plots[deedNumber];
                if (identifierToOwner[identifier] == _owner) {
                    result[resultIndex] = identifier;
                    resultIndex++;
                }
            }

            return result;
        }
    }
    
     
     
     
    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
         
        require(_index < countOfDeedsByOwner(_owner));

         
        uint256 seen = 0;
        uint256 totalDeeds = countOfDeeds();
        
        for (uint256 deedNumber = 0; deedNumber < totalDeeds; deedNumber++) {
            uint256 identifier = plots[deedNumber];
            if (identifierToOwner[identifier] == _owner) {
                if (seen == _index) {
                    return identifier;
                }
                
                seen++;
            }
        }
    }
    
     
     
     
     
    function deedUri(uint256 _deedId) external pure returns (string uri) {
        require(validIdentifier(_deedId));
    
        var (x, y) = identifierToCoordinate(_deedId);
    
         
        uri = "https://dworld.io/plot/xxxxx/xxxxx";
        bytes memory _uri = bytes(uri);
        
        for (uint256 i = 0; i < 5; i++) {
            _uri[27 - i] = byte(48 + (x / 10 ** i) % 10);
            _uri[33 - i] = byte(48 + (y / 10 ** i) % 10);
        }
    }
}


 
contract DWorldRenting is DWorldDeed {
    event Rent(address indexed renter, uint256 indexed deedId, uint256 rentPeriodEndTimestamp, uint256 rentPeriod);
    mapping (uint256 => address) identifierToRenter;
    mapping (uint256 => uint256) identifierToRentPeriodEndTimestamp;

     
     
     
    function _rents(address _renter, uint256 _deedId) internal view returns (bool) {
        return identifierToRenter[_deedId] == _renter && identifierToRentPeriodEndTimestamp[_deedId] >= now;
    }
    
     
     
     
     
    function _rentOut(address _to, uint256 _rentPeriod, uint256 _deedId) internal {
         
        uint256 rentPeriodEndTimestamp = now.add(_rentPeriod);
        identifierToRenter[_deedId] = _to;
        identifierToRentPeriodEndTimestamp[_deedId] = rentPeriodEndTimestamp;
        
        Rent(_to, _deedId, rentPeriodEndTimestamp, _rentPeriod);
    }
    
     
     
     
     
    function rentOut(address _to, uint256 _rentPeriod, uint256 _deedId) external whenNotPaused {
        uint256[] memory _deedIds = new uint256[](1);
        _deedIds[0] = _deedId;
        
        rentOutMultiple(_to, _rentPeriod, _deedIds);
    }
    
     
     
     
     
    function rentOutMultiple(address _to, uint256 _rentPeriod, uint256[] _deedIds) public whenNotPaused {
         
        require(_to != address(0));
        
         
        require(_to != address(this));
        
        for (uint256 i = 0; i < _deedIds.length; i++) {
            uint256 _deedId = _deedIds[i];
            
            require(validIdentifier(_deedId));
        
             
            require(identifierToRentPeriodEndTimestamp[_deedId] < now);
            
             
            require(_owns(msg.sender, _deedId));
            
            _rentOut(_to, _rentPeriod, _deedId);
        }
    }
    
     
     
     
     
    function renterOf(uint256 _deedId) external view returns (address _renter, uint256 _rentPeriodEndTimestamp) {
        require(validIdentifier(_deedId));
    
        if (identifierToRentPeriodEndTimestamp[_deedId] < now) {
             
            _renter = address(0);
            _rentPeriodEndTimestamp = 0;
        } else {
            _renter = identifierToRenter[_deedId];
            _rentPeriodEndTimestamp = identifierToRentPeriodEndTimestamp[_deedId];
        }
    }
}


 
 
contract ClockAuctionBase {

     
    ERC721 public deedContract;

     
    uint256 public fee;
    
     
    uint256 public outstandingEther = 0 ether;
    
     
    mapping (address => uint256) public addressToEtherOwed;
    
     
     
     
    struct Auction {
        address seller;
        uint128 startPrice;
        uint128 endPrice;
        uint64 duration;
        uint64 startedAt;
    }

    mapping (uint256 => Auction) identifierToAuction;
    
     
    event AuctionCreated(address indexed seller, uint256 indexed deedId, uint256 startPrice, uint256 endPrice, uint256 duration);
    event AuctionSuccessful(address indexed buyer, uint256 indexed deedId, uint256 totalPrice);
    event AuctionCancelled(uint256 indexed deedId);
    
     
    modifier fitsIn64Bits(uint256 _value) {
        require (_value == uint256(uint64(_value)));
        _;
    }
    
     
    modifier fitsIn128Bits(uint256 _value) {
        require (_value == uint256(uint128(_value)));
        _;
    }
    
    function ClockAuctionBase(address _deedContractAddress, uint256 _fee) public {
        deedContract = ERC721(_deedContractAddress);
        
         
        require(deedContract.supportsInterface(0xda671b9b));
        
         
        require(0 <= _fee && _fee <= 100000);
        fee = _fee;
    }
    
     
     
    function _activeAuction(Auction storage auction) internal view returns (bool) {
        return auction.startedAt > 0;
    }
    
     
     
    function _escrow(uint256 _deedId) internal {
         
        deedContract.takeOwnership(_deedId);
    }
    
     
     
     
    function _createAuction(uint256 _deedId, Auction auction) internal {
         
        identifierToAuction[_deedId] = auction;
        
         
        AuctionCreated(auction.seller, _deedId, auction.startPrice, auction.endPrice, auction.duration);
    }
    
     
     
     
     
    function _bid(address _buyer, uint256 _value, uint256 _deedId) internal {
        Auction storage auction = identifierToAuction[_deedId];
        
         
        require(_activeAuction(auction));
        
         
        uint256 price = _currentPrice(auction);
        
         
        require(_value >= price);
        
        address seller = auction.seller;
    
        if (price > 0) {
            uint256 totalFee = _calculateFee(price);
            uint256 proceeds = price - totalFee;
            
             
             
             
             
            _assignProceeds(seller, proceeds);
        }
        
        AuctionSuccessful(_buyer, _deedId, price);
        
         
        _winBid(seller, _buyer, _deedId, price);
        
         
         
         
         
         
        _removeAuction(_deedId);
    }

     
     
     
     
     
    function _winBid(address _seller, address _winner, uint256 _deedId, uint256 _price) internal {
        _transfer(_winner, _deedId);
    }
    
     
     
     
    function _cancelAuction(uint256 _deedId, Auction auction) internal {
         
        _removeAuction(_deedId);
        
         
        _transfer(auction.seller, _deedId);
        
         
        AuctionCancelled(_deedId);
    }
    
     
     
    function _removeAuction(uint256 _deedId) internal {
        delete identifierToAuction[_deedId];
    }
    
     
     
     
    function _transfer(address _to, uint256 _deedId) internal {
         
        deedContract.transfer(_to, _deedId);
    }
    
     
     
     
    function _assignProceeds(address _to, uint256 _value) internal {
        outstandingEther += _value;
        addressToEtherOwed[_to] += _value;
    }
    
     
    function _currentPrice(Auction storage _auction) internal view returns (uint256) {
        require(now >= _auction.startedAt);
        
        uint256 secondsPassed = now - _auction.startedAt;
        
        if (secondsPassed >= _auction.duration) {
            return _auction.endPrice;
        } else {
             
            int256 totalPriceChange = int256(_auction.endPrice) - int256(_auction.startPrice);
            
             
             
             
            int256 currentPriceChange = totalPriceChange * int256(secondsPassed) / int256(_auction.duration);
            
             
             
             
            int256 price = int256(_auction.startPrice) + currentPriceChange;
            
             
            assert(price >= 0);
            
            return uint256(price);
        }
    }
    
     
     
    function _calculateFee(uint256 _price) internal view returns (uint256) {
         
         
        return _price * fee / 100000;
    }
}


contract ClockAuction is ClockAuctionBase, Pausable {
    function ClockAuction(address _deedContractAddress, uint256 _fee) 
        ClockAuctionBase(_deedContractAddress, _fee)
        public
    {}
    
     
     
    function setFee(uint256 _fee) external onlyOwner {
        require(0 <= _fee && _fee <= 100000);
    
        fee = _fee;
    }
    
     
     
     
    function getAuction(uint256 _deedId) external view returns (
            address seller,
            uint256 startPrice,
            uint256 endPrice,
            uint256 duration,
            uint256 startedAt
        )
    {
        Auction storage auction = identifierToAuction[_deedId];
        
         
        require(_activeAuction(auction));
        
        return (
            auction.seller,
            auction.startPrice,
            auction.endPrice,
            auction.duration,
            auction.startedAt
        );
    }

     
     
     
     
     
     
    function createAuction(uint256 _deedId, uint256 _startPrice, uint256 _endPrice, uint256 _duration)
        public
        fitsIn128Bits(_startPrice)
        fitsIn128Bits(_endPrice)
        fitsIn64Bits(_duration)
        whenNotPaused
    {
         
        address deedOwner = deedContract.ownerOf(_deedId);
    
         
         
        require(
            msg.sender == address(deedContract) ||
            msg.sender == deedOwner
        );
    
         
        require(_duration >= 60);
    
         
         
        _escrow(_deedId);
        
         
        Auction memory auction = Auction(
            deedOwner,
            uint128(_startPrice),
            uint128(_endPrice),
            uint64(_duration),
            uint64(now)
        );
        
        _createAuction(_deedId, auction);
    }
    
     
     
    function cancelAuction(uint256 _deedId) external whenNotPaused {
        Auction storage auction = identifierToAuction[_deedId];
        
         
        require(_activeAuction(auction));
        
         
        require(msg.sender == auction.seller);
        
        _cancelAuction(_deedId, auction);
    }
    
     
     
    function bid(uint256 _deedId) external payable whenNotPaused {
         
        _bid(msg.sender, msg.value, _deedId);
    }
    
     
     
    function getCurrentPrice(uint256 _deedId) external view returns (uint256) {
        Auction storage auction = identifierToAuction[_deedId];
        
         
        require(_activeAuction(auction));
        
        return _currentPrice(auction);
    }
    
     
     
    function withdrawAuctionBalance(address beneficiary) external {
         
        require(
            msg.sender == beneficiary ||
            msg.sender == address(deedContract)
        );
        
        uint256 etherOwed = addressToEtherOwed[beneficiary];
        
         
        require(etherOwed > 0);
         
         
        delete addressToEtherOwed[beneficiary];
        
         
         
         
        outstandingEther -= etherOwed;
        
         
         
        beneficiary.transfer(etherOwed);
    }
    
     
    function withdrawFreeBalance() external {
         
         
         
        uint256 freeBalance = this.balance - outstandingEther;
        
        address deedContractAddress = address(deedContract);

        require(
            msg.sender == owner ||
            msg.sender == deedContractAddress
        );
        
        deedContractAddress.transfer(freeBalance);
    }
}


contract RentAuction is ClockAuction {
    function RentAuction(address _deedContractAddress, uint256 _fee) ClockAuction(_deedContractAddress, _fee) public {}
    
     
    bool public isRentAuction = true;
    
    mapping (uint256 => uint256) public identifierToRentPeriod;
    
     
     
     
     
     
     
     
     
     
     
    function createAuction(
        uint256 _deedId,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _duration,
        uint256 _rentPeriod
    )
        external
    {
         
        require(_rentPeriod >= 3600);
        
         
        DWorldRenting dWorldRentingContract = DWorldRenting(deedContract);
        var (renter,) = dWorldRentingContract.renterOf(_deedId);
        require(renter == address(0));
    
         
        identifierToRentPeriod[_deedId] = _rentPeriod;
    
         
        createAuction(_deedId, _startPrice, _endPrice, _duration);
    }
    
     
     
     
     
     
    function _winBid(address _seller, address _winner, uint256 _deedId, uint256 _price) internal {
        DWorldRenting dWorldRentingContract = DWorldRenting(deedContract);
    
        uint256 rentPeriod = identifierToRentPeriod[_deedId];
        if (rentPeriod == 0) {
            rentPeriod = 604800;  
        }
    
         
        dWorldRentingContract.rentOut(_winner, identifierToRentPeriod[_deedId], _deedId);
        
         
        _transfer(_seller, _deedId);
    }
    
     
     
    function _removeAuction(uint256 _deedId) internal {
        delete identifierToAuction[_deedId];
        delete identifierToRentPeriod[_deedId];
    }
}