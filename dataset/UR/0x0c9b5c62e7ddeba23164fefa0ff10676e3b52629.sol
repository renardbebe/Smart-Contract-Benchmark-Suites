 

pragma solidity 0.4.23;

 
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

 
contract TimeAware is Ownable {

     
    function getTime() public view returns (uint) {
        return now;
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

 
contract CanvasFactory is TimeAware {

     
    uint8 public constant STATE_NOT_FINISHED = 0;

     
     
    uint8 public constant STATE_INITIAL_BIDDING = 1;

     
    uint8 public constant STATE_OWNED = 2;

    uint8 public constant WIDTH = 64;
    uint8 public constant HEIGHT = 64;
    uint32 public constant PIXEL_COUNT = 4096;  

    uint32 public constant MAX_CANVAS_COUNT = 1000;
    uint8 public constant MAX_ACTIVE_CANVAS = 12;

    Canvas[] canvases;
    uint32 public activeCanvasCount = 0;

    event PixelPainted(uint32 indexed canvasId, uint32 index, uint8 color, address indexed painter);
    event CanvasFinished(uint32 indexed canvasId);
    event CanvasCreated(uint indexed canvasId);

    modifier notFinished(uint32 _canvasId) {
        require(!isCanvasFinished(_canvasId));
        _;
    }

    modifier finished(uint32 _canvasId) {
        require(isCanvasFinished(_canvasId));
        _;
    }

    modifier validPixelIndex(uint32 _pixelIndex) {
        require(_pixelIndex < PIXEL_COUNT);
        _;
    }

     
    function createCanvas() external returns (uint canvasId) {
        require(canvases.length < MAX_CANVAS_COUNT);
        require(activeCanvasCount < MAX_ACTIVE_CANVAS);

        uint id = canvases.push(Canvas(STATE_NOT_FINISHED, 0x0, 0, 0, false)) - 1;

        emit CanvasCreated(id);
        activeCanvasCount++;

        return id;
    }

     
    function setPixel(uint32 _canvasId, uint32 _index, uint8 _color) external notFinished(_canvasId) validPixelIndex(_index) {
        require(_color > 0);

        Canvas storage canvas = _getCanvas(_canvasId);
        Pixel storage pixel = canvas.pixels[_index];

         
         
        if (pixel.painter == 0x0) {
            canvas.paintedPixelsCount++;
        } else {
            canvas.addressToCount[pixel.painter]--;
        }

        canvas.addressToCount[msg.sender]++;
        canvas.pixels[_index] = Pixel(_color, msg.sender);

        if (_isCanvasFinished(canvas)) {
            activeCanvasCount--;
            canvas.state = STATE_INITIAL_BIDDING;
            emit CanvasFinished(_canvasId);
        }

        emit PixelPainted(_canvasId, _index, _color, msg.sender);
    }

     
    function getCanvasBitmap(uint32 _canvasId) external view returns (uint8[]) {
        Canvas storage canvas = _getCanvas(_canvasId);
        uint8[] memory result = new uint8[](PIXEL_COUNT);

        for (uint32 i = 0; i < PIXEL_COUNT; i++) {
            result[i] = canvas.pixels[i].color;
        }

        return result;
    }

     
    function getCanvasPaintedPixelsCount(uint32 _canvasId) public view returns (uint32) {
        return _getCanvas(_canvasId).paintedPixelsCount;
    }

    function getPixelCount() external pure returns (uint) {
        return PIXEL_COUNT;
    }

     
    function getCanvasCount() public view returns (uint) {
        return canvases.length;
    }

     
    function isCanvasFinished(uint32 _canvasId) public view returns (bool) {
        return _isCanvasFinished(_getCanvas(_canvasId));
    }

     
    function getPixelAuthor(uint32 _canvasId, uint32 _pixelIndex) public view validPixelIndex(_pixelIndex) returns (address) {
        return _getCanvas(_canvasId).pixels[_pixelIndex].painter;
    }

     
    function getPaintedPixelsCountByAddress(address _address, uint32 _canvasId) public view returns (uint32) {
        Canvas storage canvas = _getCanvas(_canvasId);
        return canvas.addressToCount[_address];
    }

    function _isCanvasFinished(Canvas canvas) internal pure returns (bool) {
        return canvas.paintedPixelsCount == PIXEL_COUNT;
    }

    function _getCanvas(uint32 _canvasId) internal view returns (Canvas storage) {
        require(_canvasId < canvases.length);
        return canvases[_canvasId];
    }

    struct Pixel {
        uint8 color;
        address painter;
    }

    struct Canvas {
         
        mapping(uint32 => Pixel) pixels;

        uint8 state;

         
        address owner;

         
        uint32 paintedPixelsCount;

        mapping(address => uint32) addressToCount;


         
        uint initialBiddingFinishTime;

         
        bool isCommissionPaid;

         
        mapping(address => bool) isAddressPaid;
    }
}

 
contract BiddableCanvas is CanvasFactory, Withdrawable {

     
    uint public constant COMMISSION = 39;
    uint public constant COMMISSION_DIVIDER = 1000;

    uint8 public constant ACTION_INITIAL_BIDDING = 0;
    uint8 public constant ACTION_SELL_OFFER_ACCEPTED = 1;
    uint8 public constant ACTION_BUY_OFFER_ACCEPTED = 2;

    uint public constant BIDDING_DURATION = 48 hours;

    mapping(uint32 => Bid) bids;
    mapping(address => uint32) addressToCount;

    uint public minimumBidAmount = 0.1 ether;

    event BidPosted(uint32 indexed canvasId, address indexed bidder, uint amount, uint finishTime);
    event RewardAddedToWithdrawals(uint32 indexed canvasId, address indexed toAddress, uint amount);
    event CommissionAddedToWithdrawals(uint32 indexed canvasId, uint amount, uint8 indexed action);

    modifier stateBidding(uint32 _canvasId) {
        require(getCanvasState(_canvasId) == STATE_INITIAL_BIDDING);
        _;
    }

    modifier stateOwned(uint32 _canvasId) {
        require(getCanvasState(_canvasId) == STATE_OWNED);
        _;
    }

     
    modifier forceOwned(uint32 _canvasId) {
        Canvas storage canvas = _getCanvas(_canvasId);
        if (canvas.state != STATE_OWNED) {
            canvas.state = STATE_OWNED;
        }
        _;
    }

     
    function makeBid(uint32 _canvasId) external payable stateBidding(_canvasId) {
        Canvas storage canvas = _getCanvas(_canvasId);
        Bid storage oldBid = bids[_canvasId];

        if (msg.value < minimumBidAmount || msg.value <= oldBid.amount) {
            revert();
        }

        if (oldBid.bidder != 0x0 && oldBid.amount > 0) {
             
            addPendingWithdrawal(oldBid.bidder, oldBid.amount);
        }

        uint finishTime = canvas.initialBiddingFinishTime;
        if (finishTime == 0) {
            canvas.initialBiddingFinishTime = getTime() + BIDDING_DURATION;
        }

        bids[_canvasId] = Bid(msg.sender, msg.value);

        if (canvas.owner != 0x0) {
            addressToCount[canvas.owner]--;
        }
        canvas.owner = msg.sender;
        addressToCount[msg.sender]++;

        emit BidPosted(_canvasId, msg.sender, msg.value, canvas.initialBiddingFinishTime);
    }

     
    function getLastBidForCanvas(uint32 _canvasId) external view returns (uint32 canvasId, address bidder, uint amount, uint finishTime) {
        Bid storage bid = bids[_canvasId];
        Canvas storage canvas = _getCanvas(_canvasId);

        return (_canvasId, bid.bidder, bid.amount, canvas.initialBiddingFinishTime);
    }

     
    function getCanvasState(uint32 _canvasId) public view returns (uint8) {
        Canvas storage canvas = _getCanvas(_canvasId);
        if (canvas.state != STATE_INITIAL_BIDDING) {
             
             
             
            return canvas.state;
        }

         
         
         
        uint finishTime = canvas.initialBiddingFinishTime;
        if (finishTime == 0 || finishTime > getTime()) {
            return STATE_INITIAL_BIDDING;

        } else {
            return STATE_OWNED;
        }
    }

     
    function getCanvasByState(uint8 _state) external view returns (uint32[]) {
        uint size;
        if (_state == STATE_NOT_FINISHED) {
            size = activeCanvasCount;
        } else {
            size = getCanvasCount() - activeCanvasCount;
        }

        uint32[] memory result = new uint32[](size);
        uint currentIndex = 0;

        for (uint32 i = 0; i < canvases.length; i++) {
            if (getCanvasState(i) == _state) {
                result[currentIndex] = i;
                currentIndex++;
            }
        }

        return _slice(result, 0, currentIndex);
    }

     
    function calculateReward(uint32 _canvasId, address _address)
    public
    view
    stateOwned(_canvasId)
    returns (uint32 pixelsCount, uint reward, bool isPaid) {

        Bid storage bid = bids[_canvasId];
        Canvas storage canvas = _getCanvas(_canvasId);

        uint32 paintedPixels = getPaintedPixelsCountByAddress(_address, _canvasId);
        uint pricePerPixel = _calculatePricePerPixel(bid.amount);
        uint _reward = paintedPixels * pricePerPixel;

        return (paintedPixels, _reward, canvas.isAddressPaid[_address]);
    }

     
    function addRewardToPendingWithdrawals(uint32 _canvasId)
    external
    stateOwned(_canvasId)
    forceOwned(_canvasId) {
        Canvas storage canvas = _getCanvas(_canvasId);

        uint32 pixelCount;
        uint reward;
        bool isPaid;
        (pixelCount, reward, isPaid) = calculateReward(_canvasId, msg.sender);

        require(pixelCount > 0);
        require(reward > 0);
        require(!isPaid);

        canvas.isAddressPaid[msg.sender] = true;
        addPendingWithdrawal(msg.sender, reward);

        emit RewardAddedToWithdrawals(_canvasId, msg.sender, reward);
    }

     
    function calculateCommission(uint32 _canvasId)
    public
    view
    stateOwned(_canvasId)
    returns (uint commission, bool isPaid) {

        Bid storage bid = bids[_canvasId];
        Canvas storage canvas = _getCanvas(_canvasId);

        return (_calculateCommission(bid.amount), canvas.isCommissionPaid);
    }

     
    function addCommissionToPendingWithdrawals(uint32 _canvasId)
    external
    onlyOwner
    stateOwned(_canvasId)
    forceOwned(_canvasId) {

        Canvas storage canvas = _getCanvas(_canvasId);

        uint commission;
        bool isPaid;
        (commission, isPaid) = calculateCommission(_canvasId);

        require(commission > 0);
        require(!isPaid);

        canvas.isCommissionPaid = true;
        addPendingWithdrawal(owner, commission);

        emit CommissionAddedToWithdrawals(_canvasId, commission, ACTION_INITIAL_BIDDING);
    }

     
    function balanceOf(address _owner) external view returns (uint) {
        return addressToCount[_owner];
    }

     
    function setMinimumBidAmount(uint _amount) external onlyOwner {
        minimumBidAmount = _amount;
    }

    function _calculatePricePerPixel(uint _totalPrice) private pure returns (uint) {
        return (_totalPrice - _calculateCommission(_totalPrice)) / PIXEL_COUNT;
    }

    function _calculateCommission(uint _amount) internal pure returns (uint) {
        return (_amount * COMMISSION) / COMMISSION_DIVIDER;
    }

     
    function _slice(uint32[] memory _array, uint _start, uint _end) internal pure returns (uint32[]) {
        require(_start <= _end);

        if (_start == 0 && _end == _array.length) {
            return _array;
        }

        uint size = _end - _start;
        uint32[] memory sliced = new uint32[](size);

        for (uint i = 0; i < size; i++) {
            sliced[i] = _array[i + _start];
        }

        return sliced;
    }

    struct Bid {
        address bidder;
        uint amount;
    }

}

 
contract CanvasMarket is BiddableCanvas {

    mapping(uint32 => SellOffer) canvasForSale;
    mapping(uint32 => BuyOffer) buyOffers;

    event CanvasOfferedForSale(uint32 indexed canvasId, uint minPrice, address indexed from, address indexed to);
    event SellOfferCancelled(uint32 indexed canvasId, uint minPrice, address indexed from, address indexed to);
    event CanvasSold(uint32 indexed canvasId, uint amount, address indexed from, address indexed to);
    event BuyOfferMade(uint32 indexed canvasId, address indexed buyer, uint amount);
    event BuyOfferCancelled(uint32 indexed canvasId, address indexed buyer, uint amount);

    struct SellOffer {
        bool isForSale;
        address seller;
        uint minPrice;
        address onlySellTo;      
    }

    struct BuyOffer {
        bool hasOffer;
        address buyer;
        uint amount;
    }

     
    function acceptSellOffer(uint32 _canvasId)
    external
    payable
    stateOwned(_canvasId)
    forceOwned(_canvasId) {

        Canvas storage canvas = _getCanvas(_canvasId);
        SellOffer memory sellOffer = canvasForSale[_canvasId];

        require(msg.sender != canvas.owner);
         
        require(sellOffer.isForSale);
        require(msg.value >= sellOffer.minPrice);
        require(sellOffer.seller == canvas.owner);
         
        require(sellOffer.onlySellTo == 0x0 || sellOffer.onlySellTo == msg.sender);
         

        uint fee = _calculateCommission(msg.value);
        uint toTransfer = msg.value - fee;

        addPendingWithdrawal(sellOffer.seller, toTransfer);
        addPendingWithdrawal(owner, fee);

        addressToCount[canvas.owner]--;
        addressToCount[msg.sender]++;

        canvas.owner = msg.sender;
        cancelSellOfferInternal(_canvasId, false);

        emit CanvasSold(_canvasId, msg.value, sellOffer.seller, msg.sender);
        emit CommissionAddedToWithdrawals(_canvasId, fee, ACTION_SELL_OFFER_ACCEPTED);

         
        BuyOffer memory offer = buyOffers[_canvasId];
        if (offer.buyer == msg.sender) {
            buyOffers[_canvasId] = BuyOffer(false, 0x0, 0);
            if (offer.amount > 0) {
                 
                addPendingWithdrawal(offer.buyer, offer.amount);
            }
        }

    }

     
    function offerCanvasForSale(uint32 _canvasId, uint _minPrice) external {
        _offerCanvasForSaleInternal(_canvasId, _minPrice, 0x0);
    }

     
    function offerCanvasForSaleToAddress(uint32 _canvasId, uint _minPrice, address _receiver) external {
        _offerCanvasForSaleInternal(_canvasId, _minPrice, _receiver);
    }

     
    function cancelSellOffer(uint32 _canvasId) external {
        cancelSellOfferInternal(_canvasId, true);
    }

     
    function makeBuyOffer(uint32 _canvasId) external payable stateOwned(_canvasId) forceOwned(_canvasId) {
        Canvas storage canvas = _getCanvas(_canvasId);
        BuyOffer storage existing = buyOffers[_canvasId];

        require(canvas.owner != msg.sender);
        require(canvas.owner != 0x0);
        require(msg.value > existing.amount);

        if (existing.amount > 0) {
             
            addPendingWithdrawal(existing.buyer, existing.amount);
        }

        buyOffers[_canvasId] = BuyOffer(true, msg.sender, msg.value);
        emit BuyOfferMade(_canvasId, msg.sender, msg.value);
    }

     
    function cancelBuyOffer(uint32 _canvasId) external stateOwned(_canvasId) forceOwned(_canvasId) {
        BuyOffer memory offer = buyOffers[_canvasId];
        require(offer.buyer == msg.sender);

        buyOffers[_canvasId] = BuyOffer(false, 0x0, 0);
        if (offer.amount > 0) {
             
            addPendingWithdrawal(offer.buyer, offer.amount);
        }

        emit BuyOfferCancelled(_canvasId, offer.buyer, offer.amount);
    }

     
    function acceptBuyOffer(uint32 _canvasId, uint _minPrice) external stateOwned(_canvasId) forceOwned(_canvasId) {
        Canvas storage canvas = _getCanvas(_canvasId);
        require(canvas.owner == msg.sender);

        BuyOffer memory offer = buyOffers[_canvasId];
        require(offer.hasOffer);
        require(offer.amount > 0);
        require(offer.buyer != 0x0);
        require(offer.amount >= _minPrice);

        uint fee = _calculateCommission(offer.amount);
        uint toTransfer = offer.amount - fee;

        addressToCount[canvas.owner]--;
        addressToCount[offer.buyer]++;

        canvas.owner = offer.buyer;
        addPendingWithdrawal(msg.sender, toTransfer);
        addPendingWithdrawal(owner, fee);

        buyOffers[_canvasId] = BuyOffer(false, 0x0, 0);
        canvasForSale[_canvasId] = SellOffer(false, 0x0, 0, 0x0);

        emit CanvasSold(_canvasId, offer.amount, msg.sender, offer.buyer);
        emit CommissionAddedToWithdrawals(_canvasId, fee, ACTION_BUY_OFFER_ACCEPTED);
    }

     
    function getCurrentBuyOffer(uint32 _canvasId)
    external
    view
    returns (bool hasOffer, address buyer, uint amount) {
        BuyOffer storage offer = buyOffers[_canvasId];
        return (offer.hasOffer, offer.buyer, offer.amount);
    }

     
    function getCurrentSellOffer(uint32 _canvasId)
    external
    view
    returns (bool isForSale, address seller, uint minPrice, address onlySellTo) {

        SellOffer storage offer = canvasForSale[_canvasId];
        return (offer.isForSale, offer.seller, offer.minPrice, offer.onlySellTo);
    }

    function _offerCanvasForSaleInternal(uint32 _canvasId, uint _minPrice, address _receiver)
    private
    stateOwned(_canvasId)
    forceOwned(_canvasId) {

        Canvas storage canvas = _getCanvas(_canvasId);
        require(canvas.owner == msg.sender);
        require(_receiver != canvas.owner);

        canvasForSale[_canvasId] = SellOffer(true, msg.sender, _minPrice, _receiver);
        emit CanvasOfferedForSale(_canvasId, _minPrice, msg.sender, _receiver);
    }

    function cancelSellOfferInternal(uint32 _canvasId, bool emitEvent)
    private
    stateOwned(_canvasId)
    forceOwned(_canvasId) {

        Canvas storage canvas = _getCanvas(_canvasId);
        SellOffer memory oldOffer = canvasForSale[_canvasId];

        require(canvas.owner == msg.sender);
        require(oldOffer.isForSale);
         

        canvasForSale[_canvasId] = SellOffer(false, msg.sender, 0, 0x0);

        if (emitEvent) {
            emit SellOfferCancelled(_canvasId, oldOffer.minPrice, oldOffer.seller, oldOffer.onlySellTo);
        }
    }

}

 
contract CryptoArt is CanvasMarket {

    function getCanvasInfo(uint32 _canvasId) external view returns (
        uint32 id,
        uint32 paintedPixels,
        uint8 canvasState,
        uint initialBiddingFinishTime,
        address owner
    ) {
        Canvas storage canvas = _getCanvas(_canvasId);

        return (_canvasId, canvas.paintedPixelsCount, getCanvasState(_canvasId),
        canvas.initialBiddingFinishTime, canvas.owner);
    }

    function getCanvasByOwner(address _owner) external view returns (uint32[]) {
        uint32[] memory result = new uint32[](canvases.length);
        uint currentIndex = 0;

        for (uint32 i = 0; i < canvases.length; i++) {
            if (getCanvasState(i) == STATE_OWNED) {
                Canvas storage canvas = _getCanvas(i);
                if (canvas.owner == _owner) {
                    result[currentIndex] = i;
                    currentIndex++;
                }
            }
        }

        return _slice(result, 0, currentIndex);
    }

     
    function getCanvasesWithSellOffer(bool includePrivateOffers) external view returns (uint32[]) {
        uint32[] memory result = new uint32[](canvases.length);
        uint currentIndex = 0;

        for (uint32 i = 0; i < canvases.length; i++) {
            SellOffer storage offer = canvasForSale[i];
            if (offer.isForSale && (includePrivateOffers || offer.onlySellTo == 0x0)) {
                result[currentIndex] = i;
                currentIndex++;
            }
        }

        return _slice(result, 0, currentIndex);
    }

     
    function getCanvasPainters(uint32 _canvasId) external view returns (address[]) {
        Canvas storage canvas = _getCanvas(_canvasId);
        address[] memory result = new address[](PIXEL_COUNT);

        for (uint32 i = 0; i < PIXEL_COUNT; i++) {
            result[i] = canvas.pixels[i].painter;
        }

        return result;
    }

}