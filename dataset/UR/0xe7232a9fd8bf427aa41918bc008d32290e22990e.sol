 

pragma solidity ^0.4.23;

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }
}

 
contract OperationalControl {
     
     
     
     

     
    event ContractUpgrade(address newContract);

    mapping (address => bool) allowedAddressList;
    

     
    address public gameManagerPrimary;
    address public gameManagerSecondary;
    address public bankManager;

     
    bool public paused = false;

     
    modifier onlyGameManager() {
        require(msg.sender == gameManagerPrimary || msg.sender == gameManagerSecondary);
        _;
    }

     
    modifier onlyBanker() {
        require(msg.sender == bankManager);
        _;
    }

     
    modifier anyOperator() {
        require(
            msg.sender == gameManagerPrimary ||
            msg.sender == gameManagerSecondary ||
            msg.sender == bankManager
        );
        _;
    }

     
    function setPrimaryGameManager(address _newGM) external onlyGameManager {
        require(_newGM != address(0));

        gameManagerPrimary = _newGM;
    }

     
    function setSecondaryGameManager(address _newGM) external onlyGameManager {
        require(_newGM != address(0));

        gameManagerSecondary = _newGM;
    }

     
    function setBanker(address _newBK) external onlyBanker {
        require(_newBK != address(0));

        bankManager = _newBK;
    }

    function updateAllowedAddressesList (address _newAddress, bool _value) external onlyGameManager {

        require (_newAddress != address(0));

        allowedAddressList[_newAddress] = _value;
        
    }

    modifier canTransact() { 
        require (msg.sender == gameManagerPrimary
            || msg.sender == gameManagerSecondary
            || allowedAddressList[msg.sender]); 
        _; 
    }
    

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyGameManager whenNotPaused {
        paused = true;
    }

     
     
    function unpause() public onlyGameManager whenPaused {
         
        paused = false;
    }
}

 
contract MLBNFT {
    function exists(uint256 _tokenId) public view returns (bool _exists);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function approve(address _to, uint256 _tokenId) public;
    function setApprovalForAll(address _to, bool _approved) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function createPromoCollectible(uint8 _teamId, uint8 _posId, uint256 _attributes, address _owner, uint256 _gameId, uint256 _playerOverrideId, uint256 _mlbPlayerId) external returns (uint256);
    function createSeedCollectible(uint8 _teamId, uint8 _posId, uint256 _attributes, address _owner, uint256 _gameId, uint256 _playerOverrideId, uint256 _mlbPlayerId) public returns (uint256);
    function checkIsAttached(uint256 _tokenId) public view returns (uint256);
    function getTeamId(uint256 _tokenId) external view returns (uint256);
    function getPlayerId(uint256 _tokenId) external view returns (uint256 playerId);
    function getApproved(uint256 _tokenId) public view returns (address _operator);
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

 
contract LSEscrow {
    function escrowTransfer(address seller, address buyer, uint256 currentPrice, uint256 marketsCut) public returns(bool);
}



 
contract ERC721Receiver {
     
    bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

     
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data
    )
        public
        returns(bytes4);
}

contract ERC721Holder is ERC721Receiver {
    function onERC721Received(address,address, uint256, bytes) public returns(bytes4) {
        return ERC721_RECEIVED;
    }
}

 
contract SaleBase is OperationalControl, ERC721Holder {
    using SafeMath for uint256;
    
     

    event SaleCreated(uint256 tokenID, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt);
    event TeamSaleCreated(uint256[9] tokenIDs, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt);
    event SaleWinner(uint256 tokenID, uint256 totalPrice, address winner);
    event TeamSaleWinner(uint256[9] tokenIDs, uint256 totalPrice, address winner);
    event SaleCancelled(uint256 tokenID, address sellerAddress);
    event EtherWithdrawed(uint256 value);

     

     
    struct Sale {
         
        address seller;
         
        uint256 startingPrice;
         
        uint256 endingPrice;
         
        uint256 duration;
         
         
        uint256 startedAt;
         
        uint256[9] tokenIds;
    }

     
    MLBNFT public nonFungibleContract;

     
    LSEscrow public LSEscrowContract;

     
    uint256 public BID_DELAY_TIME = 0;

     
     
    uint256 public ownerCut = 500;  

     
    mapping (uint256 => Sale) tokenIdToSale;

     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.safeTransferFrom(_owner, this, _tokenId);
    }

     
    function _transfer(address _owner, address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.transferFrom(_owner, _receiver, _tokenId);
    }

     
    function _addSale(uint256 _tokenId, Sale _sale) internal {
         
         
        require(_sale.duration >= 1 minutes);
        
        tokenIdToSale[_tokenId] = _sale;

        emit SaleCreated(
            uint256(_tokenId),
            uint256(_sale.startingPrice),
            uint256(_sale.endingPrice),
            uint256(_sale.duration),
            uint256(_sale.startedAt)
        );
    }

     
    function _addTeamSale(uint256[9] _tokenIds, Sale _sale) internal {
         
         
        require(_sale.duration >= 1 minutes);
        
        for(uint ii = 0; ii < 9; ii++) {
            require(_tokenIds[ii] != 0);
            require(nonFungibleContract.exists(_tokenIds[ii]));

            tokenIdToSale[_tokenIds[ii]] = _sale;
        }

        emit TeamSaleCreated(
            _tokenIds,
            uint256(_sale.startingPrice),
            uint256(_sale.endingPrice),
            uint256(_sale.duration),
            uint256(_sale.startedAt)
        );
    }

     
    function _cancelSale(uint256 _tokenId, address _seller) internal {
        Sale memory saleItem = tokenIdToSale[_tokenId];

         
        if(saleItem.tokenIds[1] != 0) {
            for(uint ii = 0; ii < 9; ii++) {
                _removeSale(saleItem.tokenIds[ii]);
                _transfer(address(this), _seller, saleItem.tokenIds[ii]);
            }
            emit SaleCancelled(_tokenId, _seller);
        } else {
            _removeSale(_tokenId);
            _transfer(address(this), _seller, _tokenId);
            emit SaleCancelled(_tokenId, _seller);
        }
    }

     
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
         
        Sale storage _sale = tokenIdToSale[_tokenId];
        uint256[9] memory tokenIdsStore = tokenIdToSale[_tokenId].tokenIds;
        
         
        require(_isOnSale(_sale));

         
        uint256 price = _currentPrice(_sale);
        require(_bidAmount >= price);

         
         
        address seller = _sale.seller;

         
         
        if(tokenIdsStore[1] > 0) {
            for(uint ii = 0; ii < 9; ii++) {
                _removeSale(tokenIdsStore[ii]);
            }
        } else {
            _removeSale(_tokenId);
        }

         
        if (price > 0) {
             
             
             
            uint256 marketsCut = _computeCut(price);
            uint256 sellerProceeds = price.sub(marketsCut);

            seller.transfer(sellerProceeds);
        }

         
         
        uint256 bidExcess = _bidAmount.sub(price);

         
        msg.sender.transfer(bidExcess);

         
         
        if(tokenIdsStore[1] > 0) {
            emit TeamSaleWinner(tokenIdsStore, price, msg.sender);
        } else {
            emit SaleWinner(_tokenId, price, msg.sender);
        }
        
        return price;
    }

     
    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToSale[_tokenId];
    }

     
    function _isOnSale(Sale memory _sale) internal pure returns (bool) {
        return (_sale.startedAt > 0);
    }

     
    function _currentPrice(Sale memory _sale)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

         
         
         
        if (now > _sale.startedAt.add(BID_DELAY_TIME)) {
            secondsPassed = now.sub(_sale.startedAt.add(BID_DELAY_TIME));
        }

        return _computeCurrentPrice(
            _sale.startingPrice,
            _sale.endingPrice,
            _sale.duration,
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
        return _price.mul(ownerCut).div(10000);
    }
}

 
contract SaleManager is SaleBase {

     
    mapping (uint256 => uint256[3]) public lastTeamSalePrices;
    mapping (uint256 => uint256) public lastSingleSalePrices;
    mapping (uint256 => uint256) public seedTeamSaleCount;
    uint256 public seedSingleSaleCount = 0;

     
    uint256 public constant SINGLE_SALE_MULTIPLIER = 35;
    uint256 public constant TEAM_SALE_MULTIPLIER = 12;
    uint256 public constant STARTING_PRICE = 10 finney;
    uint256 public constant SALES_DURATION = 1 days;

    bool public isBatchSupported = true;

     
    constructor() public {
        require(ownerCut <= 10000);  
        require(msg.sender != address(0));
        paused = true;
        gameManagerPrimary = msg.sender;
        gameManagerSecondary = msg.sender;
        bankManager = msg.sender;
    }

     
     
     
     
     
    function unpause() public onlyGameManager whenPaused {
        require(nonFungibleContract != address(0));

         
        super.unpause();
    }

     
    function _withdrawBalance() internal {
         
        bankManager.transfer(address(this).balance);
    }


     
    function() external payable {
        address nftAddress = address(nonFungibleContract);
        require(
            msg.sender == address(this) || 
            msg.sender == gameManagerPrimary ||
            msg.sender == gameManagerSecondary ||
            msg.sender == bankManager ||
            msg.sender == nftAddress ||
            msg.sender == address(LSEscrowContract)
        );
    }

     
    function _createSale(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        internal
    {
        Sale memory sale = Sale(
            _seller,
            _startingPrice,
            _endingPrice,
            _duration,
            now,
            [_tokenId,0,0,0,0,0,0,0,0]
        );
        _addSale(_tokenId, sale);
    }

     
    function _createTeamSale(
        uint256[9] _tokenIds,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller)
        internal {

        Sale memory sale = Sale(
            _seller,
            _startingPrice,
            _endingPrice,
            _duration,
            now,
            _tokenIds
        );

         
        _addTeamSale(_tokenIds, sale);
    }

     
    function cancelSale(uint256 _tokenId) external whenNotPaused {
        Sale memory sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        address seller = sale.seller;
        require(msg.sender == seller);
        _cancelSale(_tokenId, seller);
    }

     
    function cancelSaleWhenPaused(uint256 _tokenId) external whenPaused onlyGameManager {
        Sale memory sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        address seller = sale.seller;
        _cancelSale(_tokenId, seller);
    }

     
    function getSale(uint256 _tokenId) external view returns (address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt, uint256[9] tokenIds) {
        Sale memory sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return (
            sale.seller,
            sale.startingPrice,
            sale.endingPrice,
            sale.duration,
            sale.startedAt,
            sale.tokenIds
        );
    }

     
    function getCurrentPrice(uint256 _tokenId) external view returns (uint256) {
        Sale memory sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return _currentPrice(sale);
    }

     
    function _averageSalePrice(uint256 _saleType, uint256 _teamId) internal view returns (uint256) {
        uint256 _price = 0;
        if(_saleType == 0) {
            for(uint256 ii = 0; ii < 10; ii++) {
                _price = _price.add(lastSingleSalePrices[ii]);
            }
            _price = _price.mul(SINGLE_SALE_MULTIPLIER).div(100);
        } else {
            for (uint256 i = 0; i < 3; i++) {
                _price = _price.add(lastTeamSalePrices[_teamId][i]);
            }
        
            _price = _price.mul(TEAM_SALE_MULTIPLIER).div(30);
            _price = _price.mul(9);
        }

        return _price;
    }
    
     
    function createSale(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _owner) external whenNotPaused {
        require(msg.sender == address(nonFungibleContract));

         
        require(nonFungibleContract.checkIsAttached(_tokenId) == 0);
        
        _escrow(_owner, _tokenId);

         
         
        _createSale(
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            _owner
        );
    }

     
    function userCreateSaleIfApproved (uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external whenNotPaused {
        
        require(nonFungibleContract.getApproved(_tokenId) == address(this) || nonFungibleContract.isApprovedForAll(msg.sender, address(this)));
        
         
        require(nonFungibleContract.checkIsAttached(_tokenId) == 0);
        
        _escrow(msg.sender, _tokenId);

         
         
        _createSale(
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
    function withdrawSaleManagerBalances() public onlyBanker {
        _withdrawBalance();
    }

     
    function setOwnerCut(uint256 _newCut) external onlyBanker {
        require(_newCut <= 10000);
        ownerCut = _newCut;
    }
    
     
    function createSingleSeedAuction(
        uint8 _teamId,
        uint8 _posId,
        uint256 _attributes,
        uint256 _playerOverrideId,
        uint256 _mlbPlayerId,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _saleDuration)
        public
        onlyGameManager
        whenNotPaused {
         
        require(nonFungibleContract != address(0));
        require(_teamId != 0);

        uint256 nftId = nonFungibleContract.createSeedCollectible(_teamId,_posId,_attributes,address(this),0, _playerOverrideId, _mlbPlayerId);

        uint256 startPrice = 0;
        uint256 endPrice = 0;
        uint256 duration = 0;
        
        if(_startPrice == 0) {
            startPrice = _computeNextSeedPrice(0, _teamId);
        } else {
            startPrice = _startPrice;
        }

        if(_endPrice != 0) {
            endPrice = _endPrice;
        } else {
            endPrice = 0;
        }

        if(_saleDuration == 0) {
            duration = SALES_DURATION;
        } else {
            duration = _saleDuration;
        }

        _createSale(
            nftId,
            startPrice,
            endPrice,
            duration,
            address(this)
        );
    }

     
    function createPromoSeedAuction(
        uint8 _teamId,
        uint8 _posId,
        uint256 _attributes,
        uint256 _playerOverrideId,
        uint256 _mlbPlayerId,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _saleDuration)
        public
        onlyGameManager
        whenNotPaused {
         
        require(nonFungibleContract != address(0));
        require(_teamId != 0);

        uint256 nftId = nonFungibleContract.createPromoCollectible(_teamId, _posId, _attributes, address(this), 0, _playerOverrideId, _mlbPlayerId);

        uint256 startPrice = 0;
        uint256 endPrice = 0;
        uint256 duration = 0;
        
        if(_startPrice == 0) {
            startPrice = _computeNextSeedPrice(0, _teamId);
        } else {
            startPrice = _startPrice;
        }

        if(_endPrice != 0) {
            endPrice = _endPrice;
        } else {
            endPrice = 0;
        }

        if(_saleDuration == 0) {
            duration = SALES_DURATION;
        } else {
            duration = _saleDuration;
        }

        _createSale(
            nftId,
            startPrice,
            endPrice,
            duration,
            address(this)
        );
    }

     
    function createTeamSaleAuction(
        uint8 _teamId,
        uint256[9] _tokenIds,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _saleDuration)
        public
        onlyGameManager
        whenNotPaused {

        require(_teamId != 0);

         
        for(uint ii = 0; ii < _tokenIds.length; ii++){
            require(nonFungibleContract.getTeamId(_tokenIds[ii]) == _teamId);
        }
        
        uint256 startPrice = 0;
        uint256 endPrice = 0;
        uint256 duration = 0;
        
        if(_startPrice == 0) {
            startPrice = _computeNextSeedPrice(1, _teamId).mul(9);
        } else {
            startPrice = _startPrice;
        }

        if(_endPrice != 0) {
            endPrice = _endPrice;
        } else {
            endPrice = 0;
        }

        if(_saleDuration == 0) {
            duration = SALES_DURATION;
        } else {
            duration = _saleDuration;
        }

        _createTeamSale(
            _tokenIds,
            startPrice,
            endPrice,
            duration,
            address(this)
        );
    }

     
    function _computeNextSeedPrice(uint256 _saleType, uint256 _teamId) internal view returns (uint256) {
        uint256 nextPrice = _averageSalePrice(_saleType, _teamId);

         
        require(nextPrice == nextPrice);

         
        if (nextPrice < STARTING_PRICE) {
            nextPrice = STARTING_PRICE;
        }

        return nextPrice;
    }

     
    bool public isSalesManager = true;

     
    function bid(uint256 _tokenId) public whenNotPaused payable {
        
        Sale memory sale = tokenIdToSale[_tokenId];
        address seller = sale.seller;

         
        require (now > sale.startedAt.add(BID_DELAY_TIME));
        
        uint256 price = _bid(_tokenId, msg.value);

         
        if(sale.tokenIds[1] > 0) {
            
            for (uint256 i = 0; i < 9; i++) {
                _transfer(address(this), msg.sender, sale.tokenIds[i]);
            }

             
            price = price.div(9);
        } else {
            
            _transfer(address(this), msg.sender, _tokenId);
        }
        
         
        if (seller == address(this)) {
            if(sale.tokenIds[1] > 0){
                uint256 _teamId = nonFungibleContract.getTeamId(_tokenId);

                lastTeamSalePrices[_teamId][seedTeamSaleCount[_teamId] % 3] = price;

                seedTeamSaleCount[_teamId]++;
            } else {
                lastSingleSalePrices[seedSingleSaleCount % 10] = price;
                seedSingleSaleCount++;
            }
        }
    }
    
     
    function setNFTContractAddress(address _nftAddress) public onlyGameManager {
        require (_nftAddress != address(0));        
        nonFungibleContract = MLBNFT(_nftAddress);
    }

     
    function assetTransfer(address _to, uint256 _tokenId) public onlyGameManager {
        require(_tokenId != 0);
        nonFungibleContract.transferFrom(address(this), _to, _tokenId);
    }

      
    function batchAssetTransfer(address _to, uint256[] _tokenIds) public onlyGameManager {
        require(isBatchSupported);
        require (_tokenIds.length > 0);
        
        for(uint i = 0; i < _tokenIds.length; i++){
            require(_tokenIds[i] != 0);
            nonFungibleContract.transferFrom(address(this), _to, _tokenIds[i]);
        }
    }

     
    function createSeedTeam(uint8 _teamId, uint256[9] _attributes, uint256[9] _mlbPlayerId) public onlyGameManager whenNotPaused {
        require(_teamId != 0);
        
        for(uint ii = 0; ii < 9; ii++) {
            nonFungibleContract.createSeedCollectible(_teamId, uint8(ii.add(1)), _attributes[ii], address(this), 0, 0, _mlbPlayerId[ii]);
        }
    }

     
    function batchCancelSale(uint256[] _tokenIds) external whenNotPaused {
        require(isBatchSupported);
        require(_tokenIds.length > 0);

        for(uint ii = 0; ii < _tokenIds.length; ii++){
            Sale memory sale = tokenIdToSale[_tokenIds[ii]];
            require(_isOnSale(sale));
            
            address seller = sale.seller;
            require(msg.sender == seller);

            _cancelSale(_tokenIds[ii], seller);
        }
    }

     
    function updateBatchSupport(bool _flag) public onlyGameManager {
        isBatchSupported = _flag;
    }

     
    function batchCreateSingleSeedAuction(
        uint8[] _teamIds,
        uint8[] _posIds,
        uint256[] _attributes,
        uint256[] _playerOverrideIds,
        uint256[] _mlbPlayerIds,
        uint256 _startPrice)
        public
        onlyGameManager
        whenNotPaused {

        require (isBatchSupported);

        require (_teamIds.length > 0 &&
            _posIds.length > 0 &&
            _attributes.length > 0 &&
            _playerOverrideIds.length > 0 &&
            _mlbPlayerIds.length > 0 );
        
         
        require(nonFungibleContract != address(0));
        
        uint256 nftId;

        require (_startPrice != 0);

        for(uint ii = 0; ii < _mlbPlayerIds.length; ii++){
            require(_teamIds[ii] != 0);

            nftId = nonFungibleContract.createSeedCollectible(
                        _teamIds[ii],
                        _posIds[ii],
                        _attributes[ii],
                        address(this),
                        0,
                        _playerOverrideIds[ii],
                        _mlbPlayerIds[ii]);

            _createSale(
                nftId,
                _startPrice,
                0,
                SALES_DURATION,
                address(this)
            );
        }
    }

     
    function updateDelayTime(uint256 _newDelay) public onlyGameManager whenNotPaused {

        BID_DELAY_TIME = _newDelay;
    }

    function bidTransfer(uint256 _tokenId, address _buyer, uint256 _bidAmount) public canTransact {

        Sale memory sale = tokenIdToSale[_tokenId];
        address seller = sale.seller;

         
        require (now > sale.startedAt.add(BID_DELAY_TIME));
        
        uint256[9] memory tokenIdsStore = tokenIdToSale[_tokenId].tokenIds;
        
         
        require(_isOnSale(sale));

         
        uint256 price = _currentPrice(sale);
        require(_bidAmount >= price);

         
         
        if(tokenIdsStore[1] > 0) {
            for(uint ii = 0; ii < 9; ii++) {
                _removeSale(tokenIdsStore[ii]);
            }
        } else {
            _removeSale(_tokenId);
        }

        uint256 marketsCut = 0;
        uint256 sellerProceeds = 0;

         
        if (price > 0) {
             
             
             
            marketsCut = _computeCut(price);
            sellerProceeds = price.sub(marketsCut);
        }

         
        require (LSEscrowContract.escrowTransfer(seller, _buyer, sellerProceeds, marketsCut));
        
         
         
        if(tokenIdsStore[1] > 0) {
            emit TeamSaleWinner(tokenIdsStore, price, _buyer);
        } else {
            emit SaleWinner(_tokenId, price, _buyer);
        }

         
        if(sale.tokenIds[1] > 0) {
            
            for (uint256 i = 0; i < 9; i++) {
                _transfer(address(this), _buyer, sale.tokenIds[i]);
            }

             
            price = price.div(9);
        } else {
            
            _transfer(address(this), _buyer, _tokenId);
        }
        
         
        if (seller == address(this)) {
            if(sale.tokenIds[1] > 0) {
                uint256 _teamId = nonFungibleContract.getTeamId(_tokenId);

                lastTeamSalePrices[_teamId][seedTeamSaleCount[_teamId] % 3] = price;

                seedTeamSaleCount[_teamId]++;
            } else {
                lastSingleSalePrices[seedSingleSaleCount % 10] = price;
                seedSingleSaleCount++;
            }
        }
    }

     
    function setLSEscrowContractAddress(address _lsEscrowAddress) public onlyGameManager {
        require (_lsEscrowAddress != address(0));        
        LSEscrowContract = LSEscrow(_lsEscrowAddress);
    }
}