 

 
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


 
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

 
contract ERC721Token is ERC721 {
  using SafeMath for uint256;

   
  uint256 internal totalTokens;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

   
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

   
  function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) internal {
    if (approvedFor(_tokenId) != 0) {
      clearApproval(msg.sender, _tokenId);
    }
    removeToken(msg.sender, _tokenId);
    Transfer(msg.sender, 0x0, _tokenId);
  }

   
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }

   
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }

   
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

   
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }
}


contract AuctionHouse {
    address owner;

    function AuctionHouse() {
        owner = msg.sender;
    }

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
     
    uint256 public ownerCut = 375;  

     
    mapping (address => mapping (uint256 => Auction)) tokenIdToAuction;

     
    mapping (address => bool) supportedTokens;

    event AuctionCreated(address indexed tokenAddress, uint256 indexed tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration, address seller);
    event AuctionSuccessful(address indexed tokenAddress, uint256 indexed tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(address indexed tokenAddress, uint256 indexed tokenId, address seller);

     

     
    function changeOwner(address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }

     
    function setSupportedToken(address tokenAddress, bool supported) external {
        require(msg.sender == owner);
        supportedTokens[tokenAddress] = supported;
    }

     
    function setOwnerCut(uint256 cut) external {
        require(msg.sender == owner);
        require(cut <= 10000);
        ownerCut = cut;
    }

     
    function withdraw() external {
      require(msg.sender == owner);
      owner.transfer(this.balance);
    }

     
     
     
    function _owns(address _tokenAddress, address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (ERC721Token(_tokenAddress).ownerOf(_tokenId) == _claimant);
    }

     
     
     
    function _escrow(address _tokenAddress, uint256 _tokenId) internal {
         
        ERC721Token token = ERC721Token(_tokenAddress);
        if (token.ownerOf(_tokenId) != address(this)) {
          token.takeOwnership(_tokenId);
        }
    }

     
     
     
     
    function _transfer(address _tokenAddress, address _receiver, uint256 _tokenId) internal {
         
        ERC721Token(_tokenAddress).transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(address _tokenAddress, uint256 _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenAddress][_tokenId] = _auction;

        AuctionCreated(
            address(_tokenAddress),
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration),
            address(_auction.seller)
        );
    }

     
    function _cancelAuction(address _tokenAddress, uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenAddress, _tokenId);
        _transfer(_tokenAddress, _seller, _tokenId);
        AuctionCancelled(_tokenAddress, _tokenId, _seller);
    }

     
     
    function _bid(address _tokenAddress, uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
         
        Auction storage auction = tokenIdToAuction[_tokenAddress][_tokenId];

         
         
         
         
        require(_isOnAuction(auction));

         
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_tokenAddress, _tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
        }

         
         
         
         
        uint256 bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        AuctionSuccessful(_tokenAddress, _tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(address _tokenAddress, uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenAddress][_tokenId];
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

     
     
     
     
     
     
     
    function createAuction(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        public
    {
         
        require(supportedTokens[_tokenAddress]);

         
        require(msg.sender == _tokenAddress || _owns(_tokenAddress, msg.sender, _tokenId));

         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        _escrow(_tokenAddress, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenAddress, _tokenId, auction);
    }

     
     
     
    function bid(address _tokenAddress, uint256 _tokenId)
        external
        payable
    {
         
        require(supportedTokens[_tokenAddress]);
         
        _bid(_tokenAddress, _tokenId, msg.value);
        _transfer(_tokenAddress, msg.sender, _tokenId);
    }

     
     
     
     
     
    function cancelAuction(address _tokenAddress, uint256 _tokenId)
        external
    {
         
         
        Auction storage auction = tokenIdToAuction[_tokenAddress][_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenAddress, _tokenId, seller);
    }

     
     
    function getAuction(address _tokenAddress, uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
         
        require(supportedTokens[_tokenAddress]);
        Auction storage auction = tokenIdToAuction[_tokenAddress][_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

     
     
    function getCurrentPrice(address _tokenAddress, uint256 _tokenId)
        external
        view
        returns (uint256)
    {
         
        require(supportedTokens[_tokenAddress]);
        Auction storage auction = tokenIdToAuction[_tokenAddress][_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }
}

contract CryptoHandles is ERC721Token {

    address public owner;
    uint256 public defaultBuyNowPrice = 100 finney;
    uint256 public defaultAuctionPrice = 1 ether;
    uint256 public defaultAuctionDuration = 1 days;

    AuctionHouse public auctions;

    mapping (uint => bytes32) handles;
    mapping (bytes32 => uint) reverse;

    event SetRecord(bytes32 indexed handle, string indexed key, string value);

    function CryptoHandles(address auctionAddress) {
      owner = msg.sender;
      auctions = AuctionHouse(auctionAddress);
    }

     
    function changeOwner(address newOwner) external {
      require(msg.sender == owner);
      owner = newOwner;
    }

     
    function withdraw() external {
      require(msg.sender == owner);
      owner.transfer(this.balance);
    }

     
    function setBuyNowPrice(uint price) external {
      require(msg.sender == owner);
      defaultBuyNowPrice = price;
    }

     
    function setAuctionPrice(uint price) external {
      require(msg.sender == owner);
      defaultAuctionPrice = price;
    }

     
    function setAuctionDuration(uint duration) external {
      require(msg.sender == owner);
      defaultAuctionDuration = duration;
    }

     
    function() public payable {}

     
    function create(bytes32 _handle) external payable {
        require(isHandleValid(_handle));
        require(isHandleAvailable(_handle));
        uint _tokenId = totalTokens;
        handles[_tokenId] = _handle;
        reverse[_handle] = _tokenId;

         
        if (msg.value == defaultBuyNowPrice) {
          _mint(msg.sender, _tokenId);
        } else {
           
          require(msg.value == 0);
           
          _mint(address(auctions), _tokenId);
          auctions.createAuction(
              address(this),
              _tokenId,
              defaultAuctionPrice,
              0,
              defaultAuctionDuration,
              address(this)
          );
        }
    }

     
    function isHandleValid(bytes32 _handle) public pure returns (bool) {
        if (_handle == 0x0) {
            return false;
        }
        bool padded;
        for (uint i = 0; i < 32; i++) {
            byte char = byte(bytes32(uint(_handle) * 2 ** (8 * i)));
             
            if (char == 0x0) {
                padded = true;
                continue;
            }
             
            if (char >= 0x30  && char <= 0x39 && !padded) {
                continue;
            }
             
            if (char >= 0x61  && char <= 0x7A && !padded) {
                continue;
            }
             
            if (char == 0x5F && !padded) {
                continue;
            }
            return false;
        }
        return true;
    }

     
    function isHandleAvailable(bytes32 _handle) public view returns (bool) {
         
        uint tokenId = reverse[_handle];
        if (handles[tokenId] != _handle) {
          return true;
        }
    }

     
    function approveAndAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external {
        require(ownerOf(_tokenId) == msg.sender);
        tokenApprovals[_tokenId] = address(auctions);
        auctions.createAuction(
            address(this),
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
    function tokenIdForHandle(bytes32 _handle) public view returns (uint) {
         
        uint tokenId = reverse[_handle];
        require(handles[tokenId] == _handle);
        return tokenId;
    }

     
    function handleForTokenId(uint _tokenId) public view returns (bytes32) {
        bytes32 handle = handles[_tokenId];
        require(handle != 0x0);
        return handle;
    }

     
    function getHandleOwner(bytes32 _handle) public view returns (address) {
         
        uint tokenId = reverse[_handle];
        require(handles[tokenId] == _handle);
        return ownerOf(tokenId);
    }

     
    mapping(bytes32 => mapping(string => string)) internal records;

    function setRecord(bytes32 _handle, string _key, string _value) external {
        uint tokenId = reverse[_handle];
        require(ownerOf(tokenId) == msg.sender);
        records[_handle][_key] = _value;
        SetRecord(_handle, _key, _value);
    }

    function getRecord(bytes32 _handle, string _key) external view returns (string) {
        return records[_handle][_key];
    }
}