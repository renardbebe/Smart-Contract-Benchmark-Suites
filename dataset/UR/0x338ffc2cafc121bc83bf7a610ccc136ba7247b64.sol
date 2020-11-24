 

pragma solidity ^0.4.23;

 
 
 
interface ConfigInterface
{
    function isConfig() external pure returns (bool);

    function getCooldownIndexFromGeneration(uint16 _generation, uint40 _cutieId) external view returns (uint16);
    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex, uint40 _cutieId) external view returns (uint40);
    function getCooldownIndexFromGeneration(uint16 _generation) external view returns (uint16);
    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex) external view returns (uint40);

    function getCooldownIndexCount() external view returns (uint256);

    function getBabyGenFromId(uint40 _momId, uint40 _dadId) external view returns (uint16);
    function getBabyGen(uint16 _momGen, uint16 _dadGen) external pure returns (uint16);

    function getTutorialBabyGen(uint16 _dadGen) external pure returns (uint16);

    function getBreedingFee(uint40 _momId, uint40 _dadId) external view returns (uint256);
}


contract CutieCoreInterface
{
    function isCutieCore() pure public returns (bool);

    ConfigInterface public config;

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
    function totalSupply() view external returns (uint256);
    function createPromoCutie(uint256 _genes, address _owner) external;
    function checkOwnerAndApprove(address _claimant, uint40 _cutieId, address _pluginsContract) external view;
    function breedWith(uint40 _momId, uint40 _dadId) public payable returns (uint40);
    function getBreedingFee(uint40 _momId, uint40 _dadId) public view returns (uint256);
}

pragma solidity ^0.4.23;


pragma solidity ^0.4.23;


 
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

pragma solidity ^0.4.23;

 
 
contract MarketInterface 
{
    function withdrawEthFromBalance() external;

    function createAuction(uint40 _cutieId, uint128 _startPrice, uint128 _endPrice, uint40 _duration, address _seller) public payable;
    function createAuctionWithTokens(uint40 _cutieId, uint128 _startPrice, uint128 _endPrice, uint40 _duration, address _seller, address[] allowedTokens) public payable;

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
        address[] allowedTokens
    );
}

pragma solidity ^0.4.23;

interface Gen0CallbackInterface
{
    function onGen0Created(uint40 _cutieId) external;
}

pragma solidity ^0.4.23;

 
 
 
 

interface TokenRecipientInterface
{
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

pragma solidity ^0.4.23;

 
interface TokenFallback
{
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

 
contract ERC20 {

     
     

    string public symbol;
    string public  name;
    uint8 public decimals;

    function transfer(address _to, uint _value, bytes _data) external returns (bool success);

     
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);

     
     


    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

     
    function transferBulk(address[] to, uint[] tokens) public;
    function approveBulk(address[] spender, uint[] tokens) public;
}


interface TokenRegistryInterface
{
    function getPriceInToken(ERC20 tokenContract, uint128 priceWei) external view returns (uint128);
    function areAllTokensAllowed(address[] tokens) external view returns (bool);
    function isTokenInList(address[] allowedTokens, address currentToken) external pure returns (bool);
    function getDefaultTokens() external view returns (address[]);
    function getDefaultCreatorTokens() external view returns (address[]);
    function onTokensReceived(ERC20 tokenContract, uint tokenCount) external;
    function withdrawEthFromBalance() external;
    function canConvertToEth(ERC20 tokenContract) external view returns (bool);
    function convertTokensToEth(ERC20 tokenContract, address seller, uint sellerValue, uint fee) external;
}


 
 
contract Market is MarketInterface, Pausable, TokenRecipientInterface, TokenFallback
{
     
    struct Auction {
         
        uint128 startPrice;
         
        uint128 endPrice;
         
        address seller;
         
        uint40 duration;
         
         
        uint40 startedAt;
         
        uint128 featuringFee;
         
        address[] allowedTokens;
    }

     
    CutieCoreInterface public coreContract;
    Gen0CallbackInterface public gen0Callback;

     
     
    uint16 public ownerFee;

     
    mapping (uint40 => Auction) public cutieIdToAuction;
    TokenRegistryInterface public tokenRegistry;


    address operatorAddress;

    event AuctionCreatedWithTokens(uint40 indexed cutieId, uint128 startPrice, uint128 endPrice, uint40 duration, uint128 fee, address[] allowedTokens);
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

     
    function() external payable {}

    modifier canBeStoredIn128Bits(uint256 _value)
    {
        require(_value <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        _;
    }

     
     
     
     
     
    function _addAuction(uint40 _cutieId, Auction _auction) internal
    {
        if (_auction.seller == address(coreContract))
        {
            if (address(gen0Callback) != 0x0)
            {
                gen0Callback.onGen0Created(_cutieId);
            }
            if (_auction.duration == 0)
            {
                _transfer(operatorAddress, _cutieId);
                return;
            }
        }
         
         
        require(_auction.duration >= 1 minutes);

        cutieIdToAuction[_cutieId] = _auction;
        
        emit AuctionCreatedWithTokens(
            _cutieId,
            _auction.startPrice,
            _auction.endPrice,
            _auction.duration,
            _auction.featuringFee,
            _auction.allowedTokens
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

         
        if (price > 0 && seller != address(coreContract)) {
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

        tokenRegistry.withdrawEthFromBalance();
        coreAddress.transfer(address(this).balance);
    }

     
     
     
     
     
     
    function createAuction(uint40 _cutieId, uint128 _startPrice, uint128 _endPrice, uint40 _duration, address _seller)
        public whenNotPaused payable
    {
        require(_isOwner(_seller, _cutieId));
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
            allowTokens ?
                (_seller == address(coreContract) ? tokenRegistry.getDefaultCreatorTokens() : tokenRegistry.getDefaultTokens())
                : new address[](0)
        );
        _addAuction(_cutieId, auction);
    }

     
     
     
     
     
     
     
    function createAuctionWithTokens(
        uint40 _cutieId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration,
        address _seller,
        address[] _allowedTokens) public payable
    {
        require(tokenRegistry.areAllTokensAllowed(_allowedTokens));
        require(_isOwner(_seller, _cutieId));
        _escrow(_seller, _cutieId);

        Auction memory auction = Auction(
            _startPrice,
            _endPrice,
            _seller,
            _duration,
            uint40(now),
            uint128(msg.value),
            _allowedTokens
        );
        _addAuction(_cutieId, auction);
    }

     
     
    function setup(address _coreContractAddress, TokenRegistryInterface _tokenRegistry, uint16 _fee) public onlyOwner
    {
        require(_fee <= 10000);

        ownerFee = _fee;

        CutieCoreInterface candidateContract = CutieCoreInterface(_coreContractAddress);
        require(candidateContract.isCutieCore());
        coreContract = candidateContract;
        tokenRegistry = _tokenRegistry;
    }

    function setGen0Callback(Gen0CallbackInterface _gen0Callback) public onlyOwner
    {
        gen0Callback = _gen0Callback;
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

    function getCutieId(bytes _extraData) pure internal returns (uint40)
    {
        require(_extraData.length == 5);  

        return
            uint40(_extraData[0]) +
            uint40(_extraData[1]) * 0x100 +
            uint40(_extraData[2]) * 0x10000 +
            uint40(_extraData[3]) * 0x100000 +
            uint40(_extraData[4]) * 0x10000000;
    }

    function bidWithToken(address _tokenContract, uint40 _cutieId) external whenNotPaused
    {
        _bidWithToken(_tokenContract, _cutieId, msg.sender);
    }

    function tokenFallback(address _sender, uint _value, bytes _extraData) external whenNotPaused
    {
        uint40 cutieId = getCutieId(_extraData);
        address tokenContractAddress = msg.sender;
        ERC20 tokenContract = ERC20(tokenContractAddress);

         
        Auction storage auction = cutieIdToAuction[cutieId];

        require(tokenRegistry.isTokenInList(auction.allowedTokens, tokenContractAddress));  

        require(_isOnAuction(auction));

        uint128 priceWei = _currentPrice(auction);

        uint128 priceInTokens = tokenRegistry.getPriceInToken(tokenContract, priceWei);

         
        require(_value >= priceInTokens);

         
        address seller = auction.seller;

        _removeAuction(cutieId);

         
        if (seller != address(coreContract))
        {
            uint128 fee = _computeFee(priceInTokens);
            uint128 sellerValue = priceInTokens - fee;

            tokenContract.transfer(seller, sellerValue);
        }

        emit AuctionSuccessfulForToken(cutieId, priceWei, _sender, priceInTokens, tokenContractAddress);
        _transfer(_sender, cutieId);
    }

     
     
    function receiveApproval(address _sender, uint256 _value, address _tokenContract, bytes _extraData)
        external
        canBeStoredIn128Bits(_value)
        whenNotPaused
    {
        uint40 cutieId = getCutieId(_extraData);
        _bidWithToken(_tokenContract, cutieId, _sender);
    }

    function _bidWithToken(address _tokenContract, uint40 _cutieId, address _sender) internal
    {
        ERC20 tokenContract = ERC20(_tokenContract);

         
        Auction storage auction = cutieIdToAuction[_cutieId];

        bool allowTokens = tokenRegistry.isTokenInList(auction.allowedTokens, _tokenContract);  
        bool allowConvertToEth = tokenRegistry.canConvertToEth(tokenContract);

        require(allowTokens || allowConvertToEth);

        require(_isOnAuction(auction));

        uint128 priceWei = _currentPrice(auction);

        uint128 priceInTokens = tokenRegistry.getPriceInToken(tokenContract, priceWei);

         
        address seller = auction.seller;

        _removeAuction(_cutieId);

        if (seller != address(coreContract))
        {
            uint128 fee = _computeFee(priceInTokens);
            uint128 sellerValueTokens = priceInTokens - fee;

            if (allowTokens)
            {
                 
                require(tokenContract.transferFrom(_sender, seller, sellerValueTokens));

                 
                require(tokenContract.transferFrom(_sender, address(tokenRegistry), fee));
                tokenRegistry.onTokensReceived(tokenContract, fee);
            }
            else
            {
                 
                require(tokenContract.transferFrom(_sender, address(tokenRegistry), priceInTokens));  
                tokenRegistry.convertTokensToEth(tokenContract, seller, priceInTokens, ownerFee);  
            }
        }
        else
        {
            require(tokenContract.transferFrom(_sender, address(tokenRegistry), priceInTokens));
            tokenRegistry.onTokensReceived(tokenContract, priceInTokens);
        }
        emit AuctionSuccessfulForToken(_cutieId, priceWei, _sender, priceInTokens, _tokenContract);
        _transfer(_sender, _cutieId);
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
        address[] allowedTokens
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
            auction.allowedTokens
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

    function isPluginInterface() public pure returns (bool)
    {
        return true;
    }

    function onRemove() public {}

    function run(
        uint40  ,
        uint256  ,
        address  
    )
    public
    payable
    {
        revert();
    }

    function runSigned(
        uint40  ,
        uint256  ,
        address  
    )
        external
        payable
    {
        revert();
    }

    function withdraw() public
    {
        require(
            msg.sender == owner ||
            msg.sender == address(coreContract)
        );
        if (address(this).balance > 0)
        {
            address(coreContract).transfer(address(this).balance);
        }
    }
}


 
 
contract SaleMarket is Market
{
     
     
    bool public isSaleMarket = true;

     
     
    function bid(uint40 _cutieId)
        public
        payable
        canBeStoredIn128Bits(msg.value)
    {
         
        _bid(_cutieId, uint128(msg.value));
        _transfer(msg.sender, _cutieId);
    }
}