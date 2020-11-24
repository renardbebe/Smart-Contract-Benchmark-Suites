 

pragma solidity ^0.4.24;

contract CutieCoreInterface
{
    function isCutieCore() pure public returns (bool);

    function transferFrom(address _from, address _to, uint256 _cutieId) external;
    function transfer(address _to, uint256 _cutieId) external;

    function ownerOf(uint256 _cutieId)
        external
        view
        returns (address owner);

    function getCutie(uint40 _id)
        external
        view
        returns (
        uint256 genes,
        uint40 birthTime,
        uint40 cooldownEndTime,
        uint40 momId,
        uint40 dadId,
        uint16 cooldownIndex,
        uint16 generation
    );

    function getGenes(uint40 _id)
        public
        view
        returns (
        uint256 genes
    );


    function getCooldownEndTime(uint40 _id)
        public
        view
        returns (
        uint40 cooldownEndTime
    );

    function getCooldownIndex(uint40 _id)
        public
        view
        returns (
        uint16 cooldownIndex
    );


    function getGeneration(uint40 _id)
        public
        view
        returns (
        uint16 generation
    );

    function getOptional(uint40 _id)
        public
        view
        returns (
        uint64 optional
    );


    function changeGenes(
        uint40 _cutieId,
        uint256 _genes)
        public;

    function changeCooldownEndTime(
        uint40 _cutieId,
        uint40 _cooldownEndTime)
        public;

    function changeCooldownIndex(
        uint40 _cutieId,
        uint16 _cooldownIndex)
        public;

    function changeOptional(
        uint40 _cutieId,
        uint64 _optional)
        public;

    function changeGeneration(
        uint40 _cutieId,
        uint16 _generation)
        public;

    function createSaleAuction(
        uint40 _cutieId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration
    )
    public;

    function getApproved(uint256 _tokenId) external returns (address);
}

pragma solidity ^0.4.24;


pragma solidity ^0.4.24;


 
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

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

pragma solidity ^0.4.24;

 
 
contract MarketInterface 
{
    function withdrawEthFromBalance() external;    

    function createAuction(uint40 _cutieId, uint128 _startPrice, uint128 _endPrice, uint40 _duration, address _seller) public payable;

    function bid(uint40 _cutieId) public payable;

    function cancelActiveAuctionWhenPaused(uint40 _cutieId) public;

	function getAuctionInfo(uint40 _cutieId)
        public
        view
        returns
    (
        address seller,
        uint128 startPrice,
        uint128 endPrice,
        uint40 duration,
        uint40 startedAt,
        uint128 featuringFee,
        bool tokensAllowed
    );
}

pragma solidity ^0.4.24;

 
contract ERC20 {

	string public name;

	string public symbol;

	uint8 public decimals;

	  
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

	function approveAndCall(address _spender, uint256 _value, bytes _extraData) external
        returns (bool success);

	 
	function transfer(address _to, uint256 _value) external;

     
    function balanceOf(address _owner) external view returns (uint256);
}

pragma solidity ^0.4.24;

 
contract PriceOracleInterface {

     
    uint256 public ETHPrice;
}

pragma solidity ^0.4.24;

interface TokenRecipientInterface
{
        function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}


 
 
contract Market is MarketInterface, Pausable, TokenRecipientInterface
{
     
    struct Auction {
         
        uint128 startPrice;
         
        uint128 endPrice;
         
        address seller;
         
        uint40 duration;
         
         
        uint40 startedAt;
         
        uint128 featuringFee;
         
        bool tokensAllowed;
    }

     
    CutieCoreInterface public coreContract;

     
     
    uint16 public ownerFee;

     
    mapping (uint40 => Auction) public cutieIdToAuction;
    mapping (address => PriceOracleInterface) public priceOracle;


    address operatorAddress;

    event AuctionCreated(uint40 indexed cutieId, uint128 startPrice, uint128 endPrice, uint40 duration, uint128 fee, bool tokensAllowed);
    event AuctionSuccessful(uint40 indexed cutieId, uint128 totalPriceWei, address indexed winner);
    event AuctionSuccessfulForToken(uint40 indexed cutieId, uint128 totalPriceWei, address indexed winner, uint128 priceInTokens, address indexed token);
    event AuctionCancelled(uint40 indexed cutieId);

    modifier onlyOperator() {
        require(msg.sender == operatorAddress || msg.sender == owner);
        _;
    }

    function setOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0));

        operatorAddress = _newOperator;
    }

     
    function() external {}

    modifier canBeStoredIn128Bits(uint256 _value) 
    {
        require(_value <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        _;
    }

     
     
     
     
     
    function _addAuction(uint40 _cutieId, Auction _auction) internal
    {
         
         
        require(_auction.duration >= 1 minutes);

        cutieIdToAuction[_cutieId] = _auction;
        
        emit AuctionCreated(
            _cutieId,
            _auction.startPrice,
            _auction.endPrice,
            _auction.duration,
            _auction.featuringFee,
            _auction.tokensAllowed
        );
    }

     
     
    function _isOwner(address _claimant, uint256 _cutieId) internal view returns (bool)
    {
        return (coreContract.ownerOf(_cutieId) == _claimant);
    }

     
     
     
     
    function _transfer(address _receiver, uint40 _cutieId) internal
    {
         
        coreContract.transfer(_receiver, _cutieId);
    }

     
     
     
     
    function _escrow(address _owner, uint40 _cutieId) internal
    {
         
        coreContract.transferFrom(_owner, this, _cutieId);
    }

     
    function _cancelActiveAuction(uint40 _cutieId, address _seller) internal
    {
        _removeAuction(_cutieId);
        _transfer(_seller, _cutieId);
        emit AuctionCancelled(_cutieId);
    }

     
     
    function _bid(uint40 _cutieId, uint128 _bidAmount)
        internal
        returns (uint128)
    {
         
        Auction storage auction = cutieIdToAuction[_cutieId];

        require(_isOnAuction(auction));

         
        uint128 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
        address seller = auction.seller;

        _removeAuction(_cutieId);

         
        if (price > 0) {
            uint128 fee = _computeFee(price);
            uint128 sellerValue = price - fee;

            seller.transfer(sellerValue);
        }

        emit AuctionSuccessful(_cutieId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(uint40 _cutieId) internal
    {
        delete cutieIdToAuction[_cutieId];
    }

     
     
    function _isOnAuction(Auction storage _auction) internal view returns (bool)
    {
        return (_auction.startedAt > 0);
    }

     
     
     
    function _computeCurrentPrice(
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration,
        uint40 _secondsPassed
    )
        internal
        pure
        returns (uint128)
    {
        if (_secondsPassed >= _duration) {
            return _endPrice;
        } else {
            int256 totalPriceChange = int256(_endPrice) - int256(_startPrice);
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);
            uint128 currentPrice = _startPrice + uint128(currentPriceChange);
            
            return currentPrice;
        }
    }
     
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint128)
    {
        uint40 secondsPassed = 0;

        uint40 timeNow = uint40(now);
        if (timeNow > _auction.startedAt) {
            secondsPassed = timeNow - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startPrice,
            _auction.endPrice,
            _auction.duration,
            secondsPassed
        );
    }

     
     
    function _computeFee(uint128 _price) internal view returns (uint128)
    {
        return _price * ownerFee / 10000;
    }

     
     
     
    function withdrawEthFromBalance() external
    {
        address coreAddress = address(coreContract);

        require(
            msg.sender == owner ||
            msg.sender == coreAddress
        );
        coreAddress.transfer(address(this).balance);
    }

     
    function createAuction(uint40 _cutieId, uint128 _startPrice, uint128 _endPrice, uint40 _duration, address _seller)
        public whenNotPaused payable
    {
        require(_isOwner(msg.sender, _cutieId));
        _escrow(msg.sender, _cutieId);

        bool allowTokens = _duration < 0x8000000000;  
        _duration = _duration % 0x8000000000;  

        Auction memory auction = Auction(
            _startPrice,
            _endPrice,
            _seller,
            _duration,
            uint40(now),
            uint128(msg.value),
            allowTokens
        );
        _addAuction(_cutieId, auction);
    }

     
     
    function setup(address _coreContractAddress, uint16 _fee) public onlyOwner
    {
        require(_fee <= 10000);

        ownerFee = _fee;
        
        CutieCoreInterface candidateContract = CutieCoreInterface(_coreContractAddress);
        require(candidateContract.isCutieCore());
        coreContract = candidateContract;
    }

     
     
    function setFee(uint16 _fee) public onlyOwner
    {
        require(_fee <= 10000);

        ownerFee = _fee;
    }

     
    function bid(uint40 _cutieId) public payable whenNotPaused canBeStoredIn128Bits(msg.value)
    {
         
        _bid(_cutieId, uint128(msg.value));
        _transfer(msg.sender, _cutieId);
    }

    function getPriceInToken(ERC20 _tokenContract, uint128 priceWei)
        public
        view
        returns (uint128)
    {
        PriceOracleInterface oracle = priceOracle[address(_tokenContract)];
        require(address(oracle) != address(0));

        uint256 ethPerToken = oracle.ETHPrice();
        int256 power = 36 - _tokenContract.decimals();
        require(power > 0);
        return uint128(uint256(priceWei) * ethPerToken / (10 ** uint256(power)));
    }

    function getCutieId(bytes _extraData) pure internal returns (uint40)
    {
        return
            uint40(_extraData[0]) +
            uint40(_extraData[1]) * 0x100 +
            uint40(_extraData[2]) * 0x10000 +
            uint40(_extraData[3]) * 0x100000 +
            uint40(_extraData[4]) * 0x10000000;
    }

     
     
    function receiveApproval(address _sender, uint256 _value, address _tokenContract, bytes _extraData)
        external
        canBeStoredIn128Bits(_value)
        whenNotPaused
    {
        ERC20 tokenContract = ERC20(_tokenContract);

        require(_extraData.length == 5);  
        uint40 cutieId = getCutieId(_extraData);

         
        Auction storage auction = cutieIdToAuction[cutieId];
        require(auction.tokensAllowed);  

        require(_isOnAuction(auction));

        uint128 priceWei = _currentPrice(auction);

        uint128 priceInTokens = getPriceInToken(tokenContract, priceWei);

         
         

         
        address seller = auction.seller;

        _removeAuction(cutieId);

        require(tokenContract.transferFrom(_sender, address(this), priceInTokens));

        if (seller != address(coreContract))
        {
            uint128 fee = _computeFee(priceInTokens);
            uint128 sellerValue = priceInTokens - fee;

            tokenContract.transfer(seller, sellerValue);
        }

        emit AuctionSuccessfulForToken(cutieId, priceWei, _sender, priceInTokens, _tokenContract);
        _transfer(_sender, cutieId);
    }

     
     
    function getAuctionInfo(uint40 _cutieId)
        public
        view
        returns
    (
        address seller,
        uint128 startPrice,
        uint128 endPrice,
        uint40 duration,
        uint40 startedAt,
        uint128 featuringFee,
        bool tokensAllowed
    ) {
        Auction storage auction = cutieIdToAuction[_cutieId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startPrice,
            auction.endPrice,
            auction.duration,
            auction.startedAt,
            auction.featuringFee,
            auction.tokensAllowed
        );
    }

     
     
    function isOnAuction(uint40 _cutieId)
        public
        view
        returns (bool) 
    {
        return cutieIdToAuction[_cutieId].startedAt > 0;
    }

 

     
    function getCurrentPrice(uint40 _cutieId)
        public
        view
        returns (uint128)
    {
        Auction storage auction = cutieIdToAuction[_cutieId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

     
     
    function cancelActiveAuction(uint40 _cutieId) public
    {
        Auction storage auction = cutieIdToAuction[_cutieId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelActiveAuction(_cutieId, seller);
    }

     
     
    function cancelActiveAuctionWhenPaused(uint40 _cutieId) whenPaused onlyOwner public
    {
        Auction storage auction = cutieIdToAuction[_cutieId];
        require(_isOnAuction(auction));
        _cancelActiveAuction(_cutieId, auction.seller);
    }

         
     
    function cancelCreatorAuction(uint40 _cutieId) public onlyOperator
    {
        Auction storage auction = cutieIdToAuction[_cutieId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(seller == address(coreContract));
        _cancelActiveAuction(_cutieId, msg.sender);
    }

     
     
    function withdrawTokenFromBalance(ERC20 _tokenContract, address _withdrawToAddress) external
    {
        address coreAddress = address(coreContract);

        require(
            msg.sender == owner ||
            msg.sender == operatorAddress ||
            msg.sender == coreAddress
        );
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_withdrawToAddress, balance);
    }

     
    function addToken(ERC20 _tokenContract, PriceOracleInterface _priceOracle) external onlyOwner
    {
        priceOracle[address(_tokenContract)] = _priceOracle;
    }

     
    function removeToken(ERC20 _tokenContract) external onlyOwner
    {
        delete priceOracle[address(_tokenContract)];
    }
}


 
 
contract SaleMarket is Market
{
     
     
    bool public isSaleMarket = true;
    

     
     
     
     
     
     
    function createAuction(
        uint40 _cutieId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration,
        address _seller
    )
        public
        payable
    {
        require(msg.sender == address(coreContract));
        _escrow(_seller, _cutieId);

        bool allowTokens = _duration < 0x8000000000;  
        _duration = _duration % 0x8000000000;  

        Auction memory auction = Auction(
            _startPrice,
            _endPrice,
            _seller,
            _duration,
            uint40(now),
            uint128(msg.value),
            allowTokens
        );
        _addAuction(_cutieId, auction);
    }

     
     
    function bid(uint40 _cutieId)
        public
        payable
        canBeStoredIn128Bits(msg.value)
    {
         
        _bid(_cutieId, uint128(msg.value));
        _transfer(msg.sender, _cutieId);
    }
}