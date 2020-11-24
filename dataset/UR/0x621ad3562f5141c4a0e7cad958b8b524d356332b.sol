 

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


contract SaleAuction is ClockAuction {
    function SaleAuction(address _deedContractAddress, uint256 _fee) ClockAuction(_deedContractAddress, _fee) public {}
    
     
    bool public isSaleAuction = true;
}