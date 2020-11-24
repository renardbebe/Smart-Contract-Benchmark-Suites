 

pragma solidity ^0.4.23;

 

interface AxieIncubatorInterface {
  function breedingFee() external view returns (uint256);

  function requireEnoughExpForBreeding(
    uint256 _axieId
  )
    external
    view;

  function breedAxies(
    uint256 _sireId,
    uint256 _matronId,
    uint256 _birthPlace
  )
    external
    payable
    returns (uint256 _axieId);
}

 

 
 
 
interface IERC721Base   {
   
   
   
   
   
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

   
   
   
   
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

   
   
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

   
   
   
   
   
  function balanceOf(address _owner) external view returns (uint256);

   
   
   
   
   
  function ownerOf(uint256 _tokenId) external view returns (address);

   
   
   
   
   
   
   
   
   
   
   
   
   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external payable;

   
   
   
   
   
   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

   
   
   
   
   
   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

   
   
   
   
   
   
  function approve(address _approved, uint256 _tokenId) external payable;

   
   
   
   
   
  function setApprovalForAll(address _operator, bool _approved) external;

   
   
   
   
  function getApproved(uint256 _tokenId) external view returns (address);

   
   
   
   
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
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

 

 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
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

 

 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    revert();
  }

}

 

 
contract AxieSiringClockAuction is HasNoContracts, HasNoTokens, Pausable {
   
  struct Auction {
     
    address seller;
     
    uint128 startingPrice;
     
    uint128 endingPrice;
     
    uint64 duration;
     
     
    uint64 startedAt;
  }

   
   
  uint256 public ownerCut;

  IERC721Base coreContract;
  AxieIncubatorInterface incubatorContract;

   
  mapping (uint256 => Auction) public auctions;

  event AuctionCreated(
    uint256 indexed _axieId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  );

  event AuctionSuccessful(
    uint256 indexed _sireId,
    uint256 indexed _matronId,
    uint256 _totalPrice,
    address _winner
  );

  event AuctionCancelled(uint256 indexed _axieId);

   
   
   
   
  constructor(uint256 _ownerCut) public {
    require(_ownerCut <= 10000);
    ownerCut = _ownerCut;
  }

  function () external payable onlyOwner {
  }

   
   
  modifier canBeStoredWith64Bits(uint256 _value) {
    require(_value <= 18446744073709551615);
    _;
  }

  modifier canBeStoredWith128Bits(uint256 _value) {
    require(_value < 340282366920938463463374607431768211455);
    _;
  }

  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }

  function setCoreContract(address _coreAddress) external onlyOwner {
    coreContract = IERC721Base(_coreAddress);
  }

  function setIncubatorContract(address _incubatorAddress) external onlyOwner {
    incubatorContract = AxieIncubatorInterface(_incubatorAddress);
  }

   
   
  function getAuction(
    uint256 _axieId
  )
    external
    view
    returns (
      address seller,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 duration,
      uint256 startedAt
    )
  {
    Auction storage _auction = auctions[_axieId];
    require(_isOnAuction(_auction));
    return (
      _auction.seller,
      _auction.startingPrice,
      _auction.endingPrice,
      _auction.duration,
      _auction.startedAt
    );
  }

   
   
  function getCurrentPrice(
    uint256 _axieId
  )
    external
    view
    returns (uint256)
  {
    Auction storage _auction = auctions[_axieId];
    require(_isOnAuction(_auction));
    return _getCurrentPrice(_auction);
  }

   
   
   
   
   
   
  function createAuction(
    uint256 _axieId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration
  )
    external
    whenNotPaused
    canBeStoredWith128Bits(_startingPrice)
    canBeStoredWith128Bits(_endingPrice)
    canBeStoredWith64Bits(_duration)
  {
    address _seller = msg.sender;

    require(coreContract.ownerOf(_axieId) == _seller);
    incubatorContract.requireEnoughExpForBreeding(_axieId);  

    _escrow(_seller, _axieId);

    Auction memory _auction = Auction(
      _seller,
      uint128(_startingPrice),
      uint128(_endingPrice),
      uint64(_duration),
      uint64(now)
    );

    _addAuction(
      _axieId,
      _auction,
      _seller
    );
  }

   
   
   
  function bidOnSiring(
    uint256 _sireId,
    uint256 _matronId,
    uint256 _birthPlace
  )
    external
    payable
    whenNotPaused
    returns (uint256  )
  {
    Auction storage _auction = auctions[_sireId];
    require(_isOnAuction(_auction));

    require(msg.sender == coreContract.ownerOf(_matronId));

     
    address _seller = _auction.seller;

     
    _bid(_sireId, _matronId, msg.value, _auction);

    uint256 _axieId = incubatorContract.breedAxies.value(
      incubatorContract.breedingFee()
    )(
      _sireId,
      _matronId,
      _birthPlace
    );

    _transfer(_seller, _sireId);

    return _axieId;
  }

   
   
   
   
   
  function cancelAuction(uint256 _axieId) external {
    Auction storage _auction = auctions[_axieId];
    require(_isOnAuction(_auction));
    require(msg.sender == _auction.seller);
    _cancelAuction(_axieId, _auction.seller);
  }

   
   
   
   
  function cancelAuctionWhenPaused(
    uint256 _axieId
  )
    external
    whenPaused
    onlyOwner
  {
    Auction storage _auction = auctions[_axieId];
    require(_isOnAuction(_auction));
    _cancelAuction(_axieId, _auction.seller);
  }

   
   
  function _isOnAuction(Auction storage _auction) internal view returns (bool) {
    return (_auction.startedAt > 0);
  }

   
   
   
   
  function _getCurrentPrice(
    Auction storage _auction
  )
    internal
    view
    returns (uint256)
  {
    uint256 _secondsPassed = 0;

     
     
     
    if (now > _auction.startedAt) {
      _secondsPassed = now - _auction.startedAt;
    }

    return _computeCurrentPrice(
      _auction.startingPrice,
      _auction.endingPrice,
      _auction.duration,
      _secondsPassed
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
       
       
      int256 _totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

       
       
       
      int256 _currentPriceChange = _totalPriceChange * int256(_secondsPassed) / int256(_duration);

       
       
      int256 _currentPrice = int256(_startingPrice) + _currentPriceChange;

      return uint256(_currentPrice);
    }
  }

   
   
   
   
  function _addAuction(
    uint256 _axieId,
    Auction memory _auction,
    address _seller
  )
    internal
  {
     
     
    require(_auction.duration >= 1 minutes);

    auctions[_axieId] = _auction;

    emit AuctionCreated(
      _axieId,
      uint256(_auction.startingPrice),
      uint256(_auction.endingPrice),
      uint256(_auction.duration),
      _seller
    );
  }

   
   
  function _removeAuction(uint256 _axieId) internal {
    delete auctions[_axieId];
  }

   
  function _cancelAuction(uint256 _axieId, address _seller) internal {
    _removeAuction(_axieId);
    _transfer(_seller, _axieId);
    emit AuctionCancelled(_axieId);
  }

   
   
   
   
  function _escrow(address _owner, uint256 _axieId) internal {
     
    coreContract.transferFrom(_owner, this, _axieId);
  }

   
   
   
   
  function _transfer(address _receiver, uint256 _axieId) internal {
     
    coreContract.transferFrom(this, _receiver, _axieId);
  }

   
   
  function _computeCut(uint256 _price) internal view returns (uint256) {
     
     
     
     
     
    return _price * ownerCut / 10000;
  }

   
   
  function _bid(
    uint256 _sireId,
    uint256 _matronId,
    uint256 _bidAmount,
    Auction storage _auction
  )
    internal
    returns (uint256)
  {
     
    uint256 _price = _getCurrentPrice(_auction);
    uint256 _priceWithFee = _price + incubatorContract.breedingFee();

     
     
    assert(_priceWithFee >= _price);

    require(_bidAmount >= _priceWithFee);

     
     
    address _seller = _auction.seller;

     
     
    _removeAuction(_sireId);

     
    if (_price > 0) {
       
       
       
      uint256 _auctioneerCut = _computeCut(_price);
      uint256 _sellerProceeds = _price - _auctioneerCut;

       
       
       
       
       
       
       
       
      _seller.transfer(_sellerProceeds);
    }

    if (_bidAmount > _priceWithFee) {
       
       
       
       
      uint256 _bidExcess = _bidAmount - _priceWithFee;

       
       
       
      msg.sender.transfer(_bidExcess);
    }

     
    emit AuctionSuccessful(
      _sireId,
      _matronId,
      _price,
      msg.sender
    );

    return _price;
  }
}