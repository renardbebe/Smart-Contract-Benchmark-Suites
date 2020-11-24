 

pragma solidity ^0.4.24;

contract ERC721Basic {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256 _balance);

    function ownerOf(uint256 _tokenId) public view returns (address _owner);

    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;

    function getApproved(uint256 _tokenId) public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;

    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;

     
     
     
     
     
     
     
}

 
contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);

    function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
    function name() public view returns (string _name);

    function symbol() public view returns (string _symbol);

    function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

contract ToonInterface is ERC721 {

    function isToonInterface() external pure returns (bool);

     
    function authorAddress() external view returns (address);

     
    function maxSupply() external view returns (uint256);

    function getToonInfo(uint _id) external view returns (
        uint genes,
        uint birthTime,
        address owner
    );

}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
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

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

     
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

contract Withdrawable {

    mapping(address => uint) private pendingWithdrawals;

    event Withdrawal(address indexed receiver, uint amount);
    event BalanceChanged(address indexed _address, uint oldBalance, uint newBalance);

     
    function getPendingWithdrawal(address _address) public view returns (uint) {
        return pendingWithdrawals[_address];
    }

     
    function addPendingWithdrawal(address _address, uint _amount) internal {
        require(_address != 0x0);

        uint oldBalance = pendingWithdrawals[_address];
        pendingWithdrawals[_address] += _amount;

        emit BalanceChanged(_address, oldBalance, oldBalance + _amount);
    }

     
    function withdraw() external {
        uint amount = getPendingWithdrawal(msg.sender);
        require(amount > 0);

        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);

        emit Withdrawal(msg.sender, amount);
        emit BalanceChanged(msg.sender, amount, 0);
    }

}

contract ClockAuctionBase is Withdrawable, Pausable {

     
    struct Auction {
         
        address _contract;
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
    ToonInterface[] public toonContracts;
    mapping(address => uint256) addressToIndex;

     
     
    uint256 public ownerCut;

     
     
    uint256 public authorShare;

     
     
    mapping(address => mapping(uint256 => Auction)) tokenToAuction;

    event AuctionCreated(address indexed _contract, uint256 indexed tokenId,
        uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(address indexed _contract, uint256 indexed tokenId,
        uint256 totalPrice, address indexed winner);
    event AuctionCancelled(address indexed _contract, uint256 indexed tokenId);

     
    function addToonContract(address _toonContractAddress) external onlyOwner {
        ToonInterface _interface = ToonInterface(_toonContractAddress);
        require(_interface.isToonInterface());

        uint _index = toonContracts.push(_interface) - 1;
        addressToIndex[_toonContractAddress] = _index;
    }

     
     
     
     
    function _owns(address _contract, address _claimant, uint256 _tokenId)
    internal
    view
    returns (bool) {
        ToonInterface _interface = _interfaceByAddress(_contract);
        address _owner = _interface.ownerOf(_tokenId);

        return (_owner == _claimant);
    }

     
     
     
     
    function _escrow(address _contract, address _owner, uint256 _tokenId) internal {
        ToonInterface _interface = _interfaceByAddress(_contract);
         
        _interface.transferFrom(_owner, this, _tokenId);
    }

     
     
     
     
    function _transfer(address _contract, address _receiver, uint256 _tokenId) internal {
        ToonInterface _interface = _interfaceByAddress(_contract);
         
        _interface.transferFrom(this, _receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(address _contract, uint256 _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        _isAddressSupportedContract(_contract);
        tokenToAuction[_contract][_tokenId] = _auction;

        emit AuctionCreated(
            _contract,
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

     
    function _cancelAuction(address _contract, uint256 _tokenId, address _seller) internal {
        _removeAuction(_contract, _tokenId);
        _transfer(_contract, _seller, _tokenId);
        emit AuctionCancelled(_contract, _tokenId);
    }

     
     
    function _bid(address _contract, uint256 _tokenId, uint256 _bidAmount)
    internal
    returns (uint256)
    {
         
        Auction storage auction = tokenToAuction[_contract][_tokenId];
        ToonInterface _interface = _interfaceByAddress(auction._contract);

         
         
         
         
        require(_isOnAuction(auction));

         
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_contract, _tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut;
            uint256 authorCut;
            uint256 sellerProceeds;
            (auctioneerCut, authorCut, sellerProceeds) = _computeCut(_interface, price);

            if (authorCut > 0) {
                address authorAddress = _interface.authorAddress();
                addPendingWithdrawal(authorAddress, authorCut);
            }

            addPendingWithdrawal(owner, auctioneerCut);

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
        }

         
         
         
         
        uint256 bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        emit AuctionSuccessful(_contract, _tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(address _contract, uint256 _tokenId) internal {
        delete tokenToAuction[_contract][_tokenId];
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

     
     
    function _computeCut(ToonInterface _interface, uint256 _price) internal view returns (
        uint256 ownerCutValue,
        uint256 authorCutValue,
        uint256 sellerProceeds
    ) {
         
         
         
         
         

        uint256 _totalCut = _price * ownerCut / 10000;
        uint256 _authorCut = 0;
        uint256 _ownerCut = 0;
        if (_interface.authorAddress() != 0x0) {
            _authorCut = _totalCut * authorShare / 10000;
        }

        _ownerCut = _totalCut - _authorCut;
        uint256 _sellerProfit = _price - _ownerCut - _authorCut;
        require(_sellerProfit + _ownerCut + _authorCut == _price);

        return (_ownerCut, _authorCut, _sellerProfit);
    }

    function _interfaceByAddress(address _address) internal view returns (ToonInterface) {
        uint _index = addressToIndex[_address];
        ToonInterface _interface = toonContracts[_index];
        require(_address == address(_interface));

        return _interface;
    }

    function _isAddressSupportedContract(address _address) internal view returns (bool) {
        uint _index = addressToIndex[_address];
        ToonInterface _interface = toonContracts[_index];
        return _address == address(_interface);
    }
}

contract ClockAuction is ClockAuctionBase {

     
     
     
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

    bool public isSaleClockAuction = true;

     
     
     
     
     
     
    constructor(uint256 _ownerCut, uint256 _authorShare) public {
        require(_ownerCut <= 10000);
        require(_authorShare <= 10000);

        ownerCut = _ownerCut;
        authorShare = _authorShare;
    }

     
     
     
     
     
     
     
    function createAuction(
        address _contract,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external
    whenNotPaused
    {
        require(_isAddressSupportedContract(_contract));
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        _escrow(_contract, _seller, _tokenId);

        Auction memory auction = Auction(
            _contract,
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_contract, _tokenId, auction);
    }

     
     
     
    function bid(address _contract, uint256 _tokenId)
    external
    payable
    whenNotPaused
    {
         
        _bid(_contract, _tokenId, msg.value);
        _transfer(_contract, msg.sender, _tokenId);
    }

     
     
     
     
     
    function cancelAuction(address _contract, uint256 _tokenId)
    external
    {
        Auction storage auction = tokenToAuction[_contract][_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_contract, _tokenId, seller);
    }

     
     
     
     
    function cancelAuctionWhenPaused(address _contract, uint256 _tokenId)
    whenPaused
    onlyOwner
    external
    {
        Auction storage auction = tokenToAuction[_contract][_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_contract, _tokenId, auction.seller);
    }

     
     
    function getAuction(address _contract, uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt,
        uint256 currentPrice
    ) {
        Auction storage auction = tokenToAuction[_contract][_tokenId];

        if (!_isOnAuction(auction)) {
            return (0x0, 0, 0, 0, 0, 0);
        }

        return (
        auction.seller,
        auction.startingPrice,
        auction.endingPrice,
        auction.duration,
        auction.startedAt,
        getCurrentPrice(_contract, _tokenId)
        );
    }

     
     
    function getCurrentPrice(address _contract, uint256 _tokenId)
    public
    view
    returns (uint256)
    {
        Auction storage auction = tokenToAuction[_contract][_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}