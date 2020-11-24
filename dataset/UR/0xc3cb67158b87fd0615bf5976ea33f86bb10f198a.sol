 

pragma solidity ^0.4.11;


 
contract Ownable {
  address public owner;
  address public ethAddress;


   
  function Ownable() {
    owner = msg.sender;
    ethAddress = msg.sender;
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


contract Token {
    uint256 public _totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

 
 
 
 
contract AuctionBase {
     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
         
        uint256 tokenQuantity;
         
        address tokenAddress;
         
        uint256 auctionNumber;
    }

     
    address public cryptiblesAuctionContract;

     
     
    uint256 public ownerCut = 375;

     
    mapping (address => uint256) auctionCounter;

     
    mapping (address => mapping (uint256 => Auction)) tokensAuction;

    event AuctionCreated(address tokenAddress, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 quantity, uint256 auctionNumber, uint64 startedAt);
    event AuctionWinner(address tokenAddress, uint256 totalPrice, address winner, uint256 quantity, uint256 auctionNumber);
    event AuctionCancelled(address tokenAddress, address sellerAddress, uint256 auctionNumber, uint256 quantity);
    event EtherWithdrawed(uint256 value);

     
     
     
    function _owns(address _tokenAddress, address _claimant, uint256 _totalTokens) internal view returns (bool) {
        StandardToken tokenContract = StandardToken(_tokenAddress);
        return (tokenContract.balanceOf(_claimant) >= _totalTokens);
    }

     
     
     
     
    function _escrow(address _tokenAddress, address _owner, uint256 _totalTokens) internal {
         
        StandardToken tokenContract = StandardToken(_tokenAddress);
        tokenContract.transferFrom(_owner, this, _totalTokens);
    }

     
     
     
     
    function _transfer(address _tokenAddress, address _receiver, uint256 _totalTokens) internal {
         
        StandardToken tokenContract = StandardToken(_tokenAddress);
        tokenContract.transfer(_receiver, _totalTokens);
    }

     
     
     
     
    function _addAuction(address _tokenAddress, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);
        
        AuctionCreated(
            _tokenAddress,
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration),
            uint256(_auction.tokenQuantity),
            uint256(_auction.auctionNumber),
            uint64(_auction.startedAt)
        );
    }

     
    function _cancelAuction(address _tokenAddress, uint256 _auctionNumber) internal {
         
        Auction storage auction = tokensAuction[_tokenAddress][_auctionNumber];
        address seller = auction.seller;
        uint256 tokenQuantity = auction.tokenQuantity;

        _removeAuction(_tokenAddress, _auctionNumber);
        _transfer(_tokenAddress, seller, tokenQuantity);
        AuctionCancelled(_tokenAddress, seller, _auctionNumber, tokenQuantity);
    }

     
     
    function _bid(address _tokenAddress, uint256 _auctionNumber, uint256 _bidAmount)
        internal
    {
         
        Auction storage auction = tokensAuction[_tokenAddress][_auctionNumber];

         
         
         
         
        require(_isOnAuction(auction));

         
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;
        uint256 quantity = auction.tokenQuantity;

         
         
        _removeAuction(_tokenAddress, _auctionNumber);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
        }

         
         
         
         
        uint256 bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        AuctionWinner(_tokenAddress, price, msg.sender, quantity, _auctionNumber);
    }

     
     
     
    function _removeAuction(address _tokenAddress, uint256 _auctionNumber) internal {
        delete tokensAuction[_tokenAddress][_auctionNumber];
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
    
     
     
     
     
     
    function _approve(address _tokenAddress, address _approved, uint256 _tokenQuantity) internal {
        StandardToken tokenContract = StandardToken(_tokenAddress);
        tokenContract.approve(_approved, _tokenQuantity);
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

 
 
contract ClockAuction is Pausable, AuctionBase {

     
     
    function ClockAuction(address _contractAddr) public {
        require(ownerCut <= 10000);
        cryptiblesAuctionContract = _contractAddr;
    }

     
     
     
     
    function withdrawBalance() external {
        require(
            msg.sender == owner ||
            msg.sender == ethAddress
        );
         
        bool res = msg.sender.send(this.balance);

    }

     
     
     
     
     
     
     
    function createAuction(
        address _tokenAddress,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _totalQuantity
    )
        external
        whenNotPaused
    {
         
        require(_owns(_tokenAddress, msg.sender, _totalQuantity));
        
         
         
         

         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(this == address(cryptiblesAuctionContract));

        uint256 auctionNumber = auctionCounter[_tokenAddress];
        
         
        if(auctionNumber == uint256(0)){
            auctionNumber = 1;
        }else{
            auctionNumber += 1;
        }

        auctionCounter[_tokenAddress] = auctionNumber;
        
        _escrow(_tokenAddress, msg.sender, _totalQuantity);

        Auction memory auction = Auction(
            msg.sender,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now),
            uint256(_totalQuantity),
            _tokenAddress,
            auctionNumber
        );

        tokensAuction[_tokenAddress][auctionNumber] = auction;

        _addAuction(_tokenAddress, auction);
    }

     
     
     
     
    function bid(address _tokenAddress, uint256 _auctionNumber)
        external
        payable
        whenNotPaused
    {
        Auction storage auction = tokensAuction[_tokenAddress][_auctionNumber];
         
        _bid(_tokenAddress, _auctionNumber, msg.value);
        _transfer(_tokenAddress, msg.sender, auction.tokenQuantity);
    }

     
     
     
     
     
     
    function cancelAuction(address _tokenAddress, uint256 _auctionNumber)
        external
    {
        Auction storage auction = tokensAuction[_tokenAddress][_auctionNumber];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenAddress, _auctionNumber);
    }

     
     
     
     
     
    function cancelAuctionWhenPaused(address _tokenAddress, uint256 _auctionNumber)
        whenPaused
        onlyOwner
        external
    {
        Auction storage auction = tokensAuction[_tokenAddress][_auctionNumber];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenAddress, _auctionNumber);
    }

     
     
     
    function getAuction(address _tokenAddress, uint256 _auctionNumber)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt,
        uint256 tokenQuantity,
        address tokenAddress,
        uint256 auctionNumber
    ) {
        Auction storage auction = tokensAuction[_tokenAddress][_auctionNumber];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt,
            auction.tokenQuantity,
            auction.tokenAddress,
            auction.auctionNumber
        );
    }

     
     
     
    function getCurrentPrice(address _tokenAddress, uint256 _auctionNumber)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokensAuction[_tokenAddress][_auctionNumber];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}


 
 
contract SaleClockAuction is ClockAuction {

     
     
    bool public isSaleClockAuction = true;

    function SaleClockAuction() public
        ClockAuction(this) {
        }
    
     
     
     
     
     
     
    function createAuction(
        address _tokenAddress,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _tokenQuantity
    )
        external
    {
        require(_owns(_tokenAddress, msg.sender, _tokenQuantity));

         
         
         

         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(this == address(cryptiblesAuctionContract));

        uint256 auctionNumber = auctionCounter[_tokenAddress];
        
         
        if(auctionNumber == 0){
            auctionNumber = 1;
        }else{
            auctionNumber += 1;
        }

        auctionCounter[_tokenAddress] = auctionNumber;
        
        _escrow(_tokenAddress, msg.sender, _tokenQuantity);

        Auction memory auction = Auction(
            msg.sender,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now),
            uint256(_tokenQuantity),
            _tokenAddress,
            auctionNumber
        );

        tokensAuction[_tokenAddress][auctionNumber] = auction;
        
        _addAuction(_tokenAddress, auction);
    }

     
     
     
    function bid(address _tokenAddress, uint256 _auctionNumber)
        external
        payable
    {
        uint256 quantity = tokensAuction[_tokenAddress][_auctionNumber].tokenQuantity;
        _bid(_tokenAddress, _auctionNumber, msg.value);
        _transfer(_tokenAddress,msg.sender, quantity);
    }

     
     
    function setOwnerCut(uint256 _newCut) external onlyOwner {
        require(_newCut <= 10000);
        ownerCut = _newCut;
    }
}