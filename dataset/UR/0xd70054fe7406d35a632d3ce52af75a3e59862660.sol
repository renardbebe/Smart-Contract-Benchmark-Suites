 

pragma solidity ^0.4.23;

 
contract OperationalControl {
     
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public managerPrimary;
    address public managerSecondary;
    address public bankManager;

     
    mapping(address => uint8) public otherManagers;

     
    bool public paused = false;

     
    bool public error = false;

     
    modifier onlyManager() {
        require(msg.sender == managerPrimary || msg.sender == managerSecondary);
        _;
    }

    modifier onlyBanker() {
        require(msg.sender == bankManager);
        _;
    }

    modifier onlyOtherManagers() {
        require(otherManagers[msg.sender] == 1);
        _;
    }


    modifier anyOperator() {
        require(
            msg.sender == managerPrimary ||
            msg.sender == managerSecondary ||
            msg.sender == bankManager ||
            otherManagers[msg.sender] == 1
        );
        _;
    }

     
    function setOtherManager(address _newOp, uint8 _state) external onlyManager {
        require(_newOp != address(0));

        otherManagers[_newOp] = _state;
    }

     
    function setPrimaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerPrimary = _newGM;
    }

     
    function setSecondaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerSecondary = _newGM;
    }

     
    function setBanker(address _newBK) external onlyManager {
        require(_newBK != address(0));

        bankManager = _newBK;
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    modifier whenError {
        require(error);
        _;
    }

     
     
    function pause() external onlyManager whenNotPaused {
        paused = true;
    }

     
     
    function unpause() public onlyManager whenPaused {
         
        paused = false;
    }

     
     
    function hasError() public onlyManager whenPaused {
        error = true;
    }

     
     
    function noError() public onlyManager whenPaused {
        error = false;
    }
}

contract CCNFTFactory {

   
     

    function getAssetDetails(uint256 _assetId) public view returns(
        uint256 assetId,
        uint256 ownersIndex,
        uint256 assetTypeSeqId,
        uint256 assetType,
        uint256 createdTimestamp,
        uint256 isAttached,
        address creator,
        address owner
    );

    function getAssetDetailsURI(uint256 _assetId) public view returns(
        uint256 assetId,
        uint256 ownersIndex,
        uint256 assetTypeSeqId,
        uint256 assetType,
        uint256 createdTimestamp,
        uint256 isAttached,
        address creator,
        address owner,
        string metaUriAddress
    );

    function getAssetRawMeta(uint256 _assetId) public view returns(
        uint256 dataA,
        uint128 dataB
    );

    function getAssetIdItemType(uint256 _assetId) public view returns(
        uint256 assetType
    );

    function getAssetIdTypeSequenceId(uint256 _assetId) public view returns(
        uint256 assetTypeSequenceId
    );
    
    function getIsNFTAttached( uint256 _tokenId) 
    public view returns(
        uint256 isAttached
    );

    function getAssetIdCreator(uint256 _assetId) public view returns(
        address creator
    );
    function getAssetIdOwnerAndOIndex(uint256 _assetId) public view returns(
        address owner,
        uint256 ownerIndex
    );
    function getAssetIdOwnerIndex(uint256 _assetId) public view returns(
        uint256 ownerIndex
    );

    function getAssetIdOwner(uint256 _assetId) public view returns(
        address owner
    );

    function spawnAsset(address _to, uint256 _assetType, uint256 _assetID, uint256 _isAttached) public;

    function isAssetIdOwnerOrApproved(address requesterAddress, uint256 _assetId) public view returns(
        bool
    );
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens);
     
    function getTypeName (uint32 _type) public returns(string);
    function RequestDetachment(
        uint256 _tokenId
    )
        public;
    function AttachAsset(
        uint256 _tokenId
    )
        public;
    function BatchAttachAssets(uint256[10] _ids) public;
    function BatchDetachAssets(uint256[10] _ids) public;
    function RequestDetachmentOnPause (uint256 _tokenId) public;
    function burnAsset(uint256 _assetID) public;
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);
    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId)
        public view returns (address _operator);
    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator)
        public view returns (bool);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public;

}

 
contract ERC721Receiver {
     
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

     
    function onERC721Received(
        address _from,
        uint256 _tokenId,
        bytes _data
    )
        public
        returns(bytes4);
}
contract ERC721Holder is ERC721Receiver {
    function onERC721Received(address, uint256, bytes) public returns(bytes4) {
        return ERC721_RECEIVED;
    }
}

contract CCTimeSaleManager is ERC721Holder, OperationalControl {
     
    struct CollectibleSale {
         
        address seller;
         
        uint256 startingPrice;
         
        uint256 endingPrice;
         
        uint256 duration;
         
         
        uint64 startedAt;
         
        bool isActive;
         
        address buyer;
         
        uint256 tokenId;
    }
    struct PastSales {
        uint256[5] sales;
    }

     
    address public NFTAddress;

     
    mapping (uint256 => CollectibleSale) public tokenIdToSale;

     
    mapping (uint256 => uint256) public assetTypeSaleCount;

     
    mapping (uint256 => PastSales) internal assetTypeSalePrices;

    uint256 public avgSalesToCount = 5;

     
    mapping(uint256 => uint256[]) public assetTypeSalesTokenId;

    event SaleWinner(address owner, uint256 collectibleId, uint256 buyingPrice);
    event SaleCreated(uint256 tokenID, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint64 startedAt);
    event SaleCancelled(address seller, uint256 collectibleId);

     
    mapping (uint256 => uint256) internal vendingAmountType;

     
    mapping (uint256 => uint256) internal vendingTypeSold;

     
    mapping (uint256 => uint256) internal vendingPrice;

     
    mapping (uint256 => uint256) internal vendingStepUpAmount;

     
    mapping (uint256 => uint256) internal vendingStepUpQty;

    uint256 public startingIndex = 100000;

    uint256 public vendingAttachedState = 1;


    constructor() public {
        require(msg.sender != address(0));
        paused = true;
        error = false;
        managerPrimary = msg.sender;
        managerSecondary = msg.sender;
        bankManager = msg.sender;
    }

    function  setNFTAddress(address _address) public onlyManager {
        NFTAddress = _address;
    }

    function setAvgSalesCount(uint256 _count) public onlyManager  {
        avgSalesToCount = _count;
    }

     
    function CreateSale(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint64 _duration, address _seller) public anyOperator {
        _createSale(_tokenId, _startingPrice, _endingPrice, _duration, _seller);
    }

    function BatchCreateSales(uint256[] _tokenIds, uint256 _startingPrice, uint256 _endingPrice, uint64 _duration, address _seller) public anyOperator {
        uint256 _tokenId;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            _tokenId = _tokenIds[i];
            _createSale(_tokenId, _startingPrice, _endingPrice, _duration, _seller);
        }
    }

    function CreateSaleAvgPrice(uint256 _tokenId, uint256 _margin, uint _minPrice, uint256 _endingPrice, uint64 _duration, address _seller) public anyOperator {
        var ccNFT = CCNFTFactory(NFTAddress);
        uint256 assetType = ccNFT.getAssetIdItemType(_tokenId);
         
        uint256 salePrice = GetAssetTypeAverageSalePrice(assetType);

         
        salePrice = salePrice * _margin / 10000;

        if(salePrice < _minPrice) {
            salePrice = _minPrice;
        } 
       
        _createSale(_tokenId, salePrice, _endingPrice, _duration, _seller);
    }

    function BatchCreateSaleAvgPrice(uint256[] _tokenIds, uint256 _margin, uint _minPrice, uint256 _endingPrice, uint64 _duration, address _seller) public anyOperator {
        var ccNFT = CCNFTFactory(NFTAddress);
        uint256 assetType;
        uint256 _tokenId;
        uint256 salePrice;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            _tokenId = _tokenIds[i];
            assetType = ccNFT.getAssetIdItemType(_tokenId);
             
            salePrice = GetAssetTypeAverageSalePrice(assetType);

             
            salePrice = salePrice * _margin / 10000;

            if(salePrice < _minPrice) {
                salePrice = _minPrice;
            } 
            
            _tokenId = _tokenIds[i];
            _createSale(_tokenId, salePrice, _endingPrice, _duration, _seller);
        }
    }

    function BatchCancelSales(uint256[] _tokenIds) public anyOperator {
        uint256 _tokenId;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            _tokenId = _tokenIds[i];
            _cancelSale(_tokenId);
        }
    }

    function CancelSale(uint256 _assetId) public anyOperator {
        _cancelSale(_assetId);
    }

    function GetCurrentSalePrice(uint256 _assetId) external view returns(uint256 _price) {
        CollectibleSale memory _sale = tokenIdToSale[_assetId];
        
        return _currentPrice(_sale);
    }

    function GetCurrentTypeSalePrice(uint256 _assetType) external view returns(uint256 _price) {
        CollectibleSale memory _sale = tokenIdToSale[assetTypeSalesTokenId[_assetType][0]];
        return _currentPrice(_sale);
    }

    function GetCurrentTypeDuration(uint256 _assetType) external view returns(uint256 _duration) {
        CollectibleSale memory _sale = tokenIdToSale[assetTypeSalesTokenId[_assetType][0]];
        return  _sale.duration;
    }

    function GetCurrentTypeStartTime(uint256 _assetType) external view returns(uint256 _startedAt) {
        CollectibleSale memory _sale = tokenIdToSale[assetTypeSalesTokenId[_assetType][0]];
        return  _sale.startedAt;
    }

    function GetCurrentTypeSaleItem(uint256 _assetType) external view returns(address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt, uint256 tokenId) {
        CollectibleSale memory _sale = tokenIdToSale[assetTypeSalesTokenId[_assetType][0]];
        return (
            _sale.seller,
            _sale.startingPrice,
            _sale.endingPrice,
            _sale.duration,
            _sale.startedAt,
            _sale.tokenId
        );
    }

    function GetCurrentTypeSaleCount(uint256 _assetType) external view returns(uint256 _count) {
        return assetTypeSalesTokenId[_assetType].length;
    }

    function BuyCurrentTypeOfAsset(uint256 _assetType) external whenNotPaused payable {
        require(msg.sender != address(0));
        require(msg.sender != address(this));

        CollectibleSale memory _sale = tokenIdToSale[assetTypeSalesTokenId[_assetType][0]];
        require(_isOnSale(_sale));

        _buy(_sale.tokenId, msg.sender, msg.value);
    }

     
     
    function BuyAsset(uint256 _assetId) external whenNotPaused payable {
        require(msg.sender != address(0));
        require(msg.sender != address(this));
        CollectibleSale memory _sale = tokenIdToSale[_assetId];
        require(_isOnSale(_sale));
        
         

        _buy(_assetId, msg.sender, msg.value);
    }

    function GetAssetTypeAverageSalePrice(uint256 _assetType) public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < avgSalesToCount; i++) {
            sum += assetTypeSalePrices[_assetType].sales[i];
        }
        return sum / 5;
    }

     
     
     
     
     
    function unpause() public anyOperator whenPaused {
         
        super.unpause();
    }

     
     
     
     
    function withdrawBalance() public onlyBanker {
         
        bankManager.transfer(address(this).balance);
    }

     
     
    function getSale(uint256 _assetId) external view returns (address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt, bool isActive, address buyer, uint256 tokenId) {
        CollectibleSale memory sale = tokenIdToSale[_assetId];
        require(_isOnSale(sale));
        return (
            sale.seller,
            sale.startingPrice,
            sale.endingPrice,
            sale.duration,
            sale.startedAt,
            sale.isActive,
            sale.buyer,
            sale.tokenId
        );
    }


     

    function _createSale(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint64 _duration, address _seller) internal {
        var ccNFT = CCNFTFactory(NFTAddress);

        require(ccNFT.isAssetIdOwnerOrApproved(this, _tokenId) == true);
        
        CollectibleSale memory onSale = tokenIdToSale[_tokenId];
        require(onSale.isActive == false);

         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

         
        if(ccNFT.ownerOf(_tokenId) != address(this)) {
            
            require(ccNFT.isApprovedForAll(msg.sender, this) == true);

            ccNFT.safeTransferFrom(ccNFT.ownerOf(_tokenId), this, _tokenId);
        }

        CollectibleSale memory sale = CollectibleSale(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now),
            true,
            address(0),
            uint256(_tokenId)
        );
        _addSale(_tokenId, sale);
    }

     
     
    function _addSale(uint256 _assetId, CollectibleSale _sale) internal {
         
         
        require(_sale.duration >= 1 minutes);
        
        tokenIdToSale[_assetId] = _sale;

        var ccNFT = CCNFTFactory(NFTAddress);
        uint256 assetType = ccNFT.getAssetIdItemType(_assetId);
        assetTypeSalesTokenId[assetType].push(_assetId);

        SaleCreated(
            uint256(_assetId),
            uint256(_sale.startingPrice),
            uint256(_sale.endingPrice),
            uint256(_sale.duration),
            uint64(_sale.startedAt)
        );
    }

     
     
     
     
    function _currentPrice(CollectibleSale memory _sale) internal view returns (uint256) {
        uint256 secondsPassed = 0;

         
         
         
        if (now > _sale.startedAt) {
            secondsPassed = now - _sale.startedAt;
        }

        return _computeCurrentPrice(
            _sale.startingPrice,
            _sale.endingPrice,
            _sale.duration,
            secondsPassed
        );
    }

     
     
     
     
    function _computeCurrentPrice(uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, uint256 _secondsPassed) internal pure returns (uint256) {
         
         
         
         
         
        if (_secondsPassed >= _duration) {
             
             
            return _endingPrice;
        } else {
             
             
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

             
             
             
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

             
             
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    function _buy(uint256 _assetId, address _buyer, uint256 _price) internal {

        CollectibleSale storage _sale = tokenIdToSale[_assetId];

         
        uint256 currentPrice = _currentPrice(_sale);

        require(_price >= currentPrice);
        _sale.buyer = _buyer;
        _sale.isActive = false;

        _removeSale(_assetId);

        uint256 bidExcess = _price - currentPrice;
        _buyer.transfer(bidExcess);

        var ccNFT = CCNFTFactory(NFTAddress);
        uint256 assetType = ccNFT.getAssetIdItemType(_assetId);
        _updateSaleAvgHistory(assetType, _price);
        ccNFT.safeTransferFrom(this, _buyer, _assetId);

        emit SaleWinner(_buyer, _assetId, _price);
    }

    function _cancelSale (uint256 _assetId) internal {
        CollectibleSale storage _sale = tokenIdToSale[_assetId];

        require(_sale.isActive == true);

        address sellerAddress = _sale.seller;

        _removeSale(_assetId);

        var ccNFT = CCNFTFactory(NFTAddress);

        ccNFT.safeTransferFrom(this, sellerAddress, _assetId);

        emit SaleCancelled(sellerAddress, _assetId);
    }
    
     
    function _isOnSale(CollectibleSale memory _sale) internal view returns (bool) {
        return (_sale.startedAt > 0 && _sale.isActive);
    }

    function _updateSaleAvgHistory(uint256 _assetType, uint256 _price) internal {
        assetTypeSaleCount[_assetType] += 1;
        assetTypeSalePrices[_assetType].sales[assetTypeSaleCount[_assetType] % avgSalesToCount] = _price;
    }

     
     
    function _removeSale(uint256 _assetId) internal {
        delete tokenIdToSale[_assetId];

        var ccNFT = CCNFTFactory(NFTAddress);
        uint256 assetType = ccNFT.getAssetIdItemType(_assetId);

        bool hasFound = false;
        for (uint i = 0; i < assetTypeSalesTokenId[assetType].length; i++) {
            if ( assetTypeSalesTokenId[assetType][i] == _assetId) {
                hasFound = true;
            }
            if(hasFound == true) {
                if(i+1 < assetTypeSalesTokenId[assetType].length)
                    assetTypeSalesTokenId[assetType][i] = assetTypeSalesTokenId[assetType][i+1];
                else 
                    delete assetTypeSalesTokenId[assetType][i];
            }
        }
        assetTypeSalesTokenId[assetType].length--;
    }


     

    function setVendingAttachedState (uint256 _collectibleType, uint256 _state) external onlyManager {
        vendingAttachedState = _state;
    }

     
    function setVendingAmount (uint256 _collectibleType, uint256 _vendingQty) external onlyManager {
        vendingAmountType[_collectibleType] = _vendingQty;
    }

     
    function setVendingStartPrice (uint256 _collectibleType, uint256 _startingPrice) external onlyManager {
        vendingPrice[_collectibleType] = _startingPrice;
    }

     
    function setVendingStepValues(uint256 _collectibleType, uint256 _stepAmount, uint256 _stepQty) external onlyManager {
        vendingStepUpQty[_collectibleType] = _stepQty;
        vendingStepUpAmount[_collectibleType] = _stepAmount;
    }

     
    function createVendingItem(uint256 _collectibleType, uint256 _vendingQty, uint256 _startingPrice, uint256 _stepAmount, uint256 _stepQty) external onlyManager {
        vendingAmountType[_collectibleType] = _vendingQty;
        vendingPrice[_collectibleType] = _startingPrice;
        vendingStepUpQty[_collectibleType] = _stepQty;
        vendingStepUpAmount[_collectibleType] = _stepAmount;
    }

     
     
    function vendingCreateCollectible(uint256 _collectibleType, address _toAddress) payable external whenNotPaused {
        
         
        require((vendingAmountType[_collectibleType] - vendingTypeSold[_collectibleType]) > 0);

        require(msg.value >= vendingPrice[_collectibleType]);

        require(msg.sender != address(0));
        require(msg.sender != address(this));
        
        require(_toAddress != address(0));
        require(_toAddress != address(this));

        var ccNFT = CCNFTFactory(NFTAddress);

        ccNFT.spawnAsset(_toAddress, _collectibleType, startingIndex, vendingAttachedState);

        startingIndex += 1;

        vendingTypeSold[_collectibleType] += 1;

        uint256 excessBid = msg.value - vendingPrice[_collectibleType];

        if(vendingTypeSold[_collectibleType] % vendingStepUpQty[_collectibleType] == 0) {
            vendingPrice[_collectibleType] += vendingStepUpAmount[_collectibleType];
        }

        if(excessBid > 0) {
            msg.sender.transfer(excessBid);
        }
 
    }

    function getVendingAmountLeft (uint256 _collectibleType) view public returns (uint256) {
        return (vendingAmountType[_collectibleType] - vendingTypeSold[_collectibleType]);
    }

    function getVendingAmountSold (uint256 _collectibleType) view public returns (uint256) {
        return (vendingTypeSold[_collectibleType]);
    }

    function getVendingPrice (uint256 _collectibleType) view public returns (uint256) {
        return (vendingPrice[_collectibleType]);
    }

    function getVendingStepPrice (uint256 _collectibleType) view public returns (uint256) {
        return (vendingStepUpAmount[_collectibleType]);
    }

    function getVendingStepQty (uint256 _collectibleType) view public returns (uint256) {
        return (vendingStepUpQty[_collectibleType]);
    }

    function getVendingInfo (uint256 _collectibleType) view public returns (uint256 amountRemaining, uint256 sold, uint256 price, uint256 stepPrice, uint256 stepQty) {
        amountRemaining = (vendingAmountType[_collectibleType] - vendingTypeSold[_collectibleType]);
        sold = vendingTypeSold[_collectibleType];
        price = vendingPrice[_collectibleType];
        stepPrice = vendingStepUpAmount[_collectibleType];
        stepQty = vendingStepUpQty[_collectibleType];
    }

}