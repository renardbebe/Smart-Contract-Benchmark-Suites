 

pragma solidity =0.5.12;

 
 
 
 
 
 
 
 
 
 

interface ICards {
    function cardProtos(uint tokenId) external view returns (uint16 proto);
    function cardQualities(uint tokenId) external view returns (uint8 quality);
}

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract GodsUnchainedCards is IERC721, ICards {}

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract CardExchange {
    using SafeMath for uint256;

     
     
     
     
     
    GodsUnchainedCards constant public godsUnchainedCards = GodsUnchainedCards(0x629cDEc6aCc980ebeeBeA9E5003bcD44DB9fc5cE);
     
     
     
    mapping (address => mapping(uint256 => BuyOrder)) public buyOrdersById;
     
     
     
    mapping (address => mapping(uint256 => SellOrder)) public sellOrdersById;
     
     
     
    string private constant domain = "EIP712Domain(string name)";
    bytes32 public constant domainTypeHash = keccak256(abi.encodePacked(domain));
    bytes32 private domainSeparator = keccak256(abi.encode(domainTypeHash, keccak256("Sell Gods Unchained cards on gu.cards")));
    string private constant sellOrdersForTokenIdsType = "SellOrders(uint256[] ids,uint256[] tokenIds,uint256[] prices)";
    bytes32 public constant sellOrdersForTokenIdsTypeHash = keccak256(abi.encodePacked(sellOrdersForTokenIdsType));
    string private constant sellOrdersForProtosAndQualitiesType = "SellOrders(uint256[] ids,uint256[] protos,uint256[] qualities,uint256[] prices)";
    bytes32 public constant sellOrdersForProtosAndQualitiesTypeHash = keccak256(abi.encodePacked(sellOrdersForProtosAndQualitiesType));
     
     
     
     
    uint256 public lockedInFunds;
     
     
     
    bool public paused;
     
     
     
     
     
    uint256 public exchangeFee;
     
     
     
    address payable public owner;
    address payable private nextOwner;
    
     
     
     
    event BuyOrderCreated(uint256 id);
    event SellOrderCreated(uint256 id);
    event BuyOrderCanceled(uint256 id);
    event SellOrderCanceled(uint256 id);
    event Settled(uint256 buyOrderId, uint256 sellOrderId);

     
     
     
     
     
    struct BuyOrder {
         
         
         
        uint256 id;
         
         
         
        uint256 price;
         
         
         
        uint256 fee;
         
         
         
        uint16 proto;
         
         
         
        uint8 quality;
         
         
         
        address payable buyer;
         
         
         
        bool settled;
         
         
         
        bool canceled;
    }
     
     
     
    struct SellOrder {
         
         
         
        uint256 id;
         
         
         
        uint256 tokenId;
         
         
         
        uint16 proto;
         
         
         
        uint8 quality;
         
         
         
        uint256 price;
         
         
         
        address payable seller;
         
         
         
        bool settled;
         
         
         
        bool canceled;
         
         
         
         
        bool tokenIsSet;
    }

     
     
     
     
     
    modifier onlyOwner {
        require(msg.sender == owner, "Function called by non-owner.");
        _;
    }
     
     
     
    modifier onlyUnpaused {
        require(paused == false, "Exchange is paused.");
        _;
    }

     
     
     
     
     
     
    constructor() public {
        owner = msg.sender;
    }

     
     
     
     
     
    function createBuyOrders(uint256[] calldata ids, uint256[] calldata protos, uint256[] calldata prices, uint256[] calldata qualities) onlyUnpaused external payable {
        _createBuyOrders(ids, protos, prices, qualities);
    }
     
     
     
    function createBuyOrdersAndSettle(uint256[] calldata orderData, uint256[] calldata sellOrderIds, uint256[] calldata tokenIds, address[] calldata sellOrderAddresses) onlyUnpaused external payable {
        uint256[] memory buyOrderIds = _unpackOrderData(orderData, 0);
        _createBuyOrders(
            buyOrderIds,
            _unpackOrderData(orderData, 1),
            _unpackOrderData(orderData, 3),
            _unpackOrderData(orderData, 2)
        );
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            _updateSellOrderTokenId(sellOrdersById[sellOrderAddresses[i]][sellOrderIds[i]], tokenIds[i]);
            _settle(
                buyOrdersById[msg.sender][buyOrderIds[i]],
                sellOrdersById[sellOrderAddresses[i]][sellOrderIds[i]]
            );
        }
    }
     
     
     
     
     
     
     
     
     
     
    function createBuyOrderAndSettleWithOffChainSellOrderForTokenIds(uint256[] calldata orderData, address sellOrderAddress, uint256[] calldata sellOrderIds, uint256[] calldata sellOrderTokenIds, uint256[] calldata sellOrderPrices, uint8 v, bytes32 r, bytes32 s) onlyUnpaused external payable {
        _ensureBuyOrderPrice(orderData[2]);
        _createBuyOrder(orderData[0], uint16(orderData[1]), orderData[2], uint8(orderData[3]));
        _createOffChainSignedSellOrdersForTokenIds(sellOrderIds, sellOrderTokenIds, sellOrderPrices, v, r, s);
        _settle(buyOrdersById[msg.sender][orderData[0]], sellOrdersById[sellOrderAddress][orderData[4]]);
    }
     
     
     
     
    function createBuyOrderAndSettleWithOffChainSellOrderForProtosAndQualities(uint256 buyOrderId, uint16 buyOrderProto, uint256 buyOrderPrice, uint8 buyOrderQuality, uint256 sellOrderId, address sellOrderAddress, uint256 tokenId, uint256[] calldata sellOrderData, uint8 v, bytes32 r, bytes32 s) onlyUnpaused external payable {
        _ensureBuyOrderPrice(buyOrderPrice);
        _createBuyOrder(buyOrderId, buyOrderProto, buyOrderPrice, buyOrderQuality);
        _createOffChainSignedSellOrdersForProtosAndQualities(
            _unpackOrderData(sellOrderData, 0),
            _unpackOrderData(sellOrderData, 1),
            _unpackOrderData(sellOrderData, 2),
            _unpackOrderData(sellOrderData, 3),
            v,
            r,
            s
        );
        _updateSellOrderTokenId(sellOrdersById[sellOrderAddress][sellOrderId], tokenId);
        _settle(buyOrdersById[msg.sender][buyOrderId], sellOrdersById[sellOrderAddress][sellOrderId]);
    }
     
     
     
     
    function _ensureBuyOrderPrice(uint256 price) private view {
        require(
            msg.value >= (price.add(price.mul(exchangeFee).div(1000))) &&
            price > 0,
            "Amount sent to the contract needs to cover at least this buy order's price and fee (and needs to be bigger than 0)."
        );
    }
     
     
     
     
     
     
     
     
    function _unpackOrderData(uint256[] memory orderData, uint256 part) private pure returns (uint256[] memory data) {
        uint256 length = orderData.length/4;
        uint256[] memory returnData = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            returnData[i] = orderData[i*4+part];
        }
        return returnData;
    }
     
     
     
    function _createBuyOrders(uint256[] memory ids, uint256[] memory protos, uint256[] memory prices, uint256[] memory qualities) private {
        uint256 totalAmountToPay = 0;
        uint256 length = ids.length;

        for (uint256 i = 0; i < length; i++) {
            _createBuyOrder(ids[i], uint16(protos[i]), prices[i], uint8(qualities[i]));
            totalAmountToPay = totalAmountToPay.add(
                prices[i].add(prices[i].mul(exchangeFee).div(1000))
            );
        }
        
        require(msg.value >= totalAmountToPay && msg.value > 0, "ETH sent to the contract is insufficient (prices + exchange fees)!");
    }
     
     
     
    function _createBuyOrder(uint256 id, uint16 proto, uint256 price, uint8 quality) private {
        BuyOrder storage buyOrder = buyOrdersById[msg.sender][id];
        require(buyOrder.id == 0, "Buy order with this ID does already exist!");
        buyOrder.id = id;
        buyOrder.proto = proto;
        buyOrder.price = price;
        buyOrder.fee = price.mul(exchangeFee).div(1000);
        buyOrder.quality = quality;
        buyOrder.buyer = msg.sender;
        
        lockedInFunds = lockedInFunds.add(buyOrder.price.add(buyOrder.fee));

        emit BuyOrderCreated(buyOrder.id);
    }
     
     
     
    function cancelBuyOrders(uint256[] calldata ids) external {
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; i++) {
            BuyOrder storage buyOrder = buyOrdersById[msg.sender][ids[i]];
            require(buyOrder.settled == false, "Order has already been settled!");
            require(buyOrder.canceled == false, "Order has already been canceled!");
            buyOrder.canceled = true;  
            lockedInFunds = lockedInFunds.sub(buyOrder.price.add(buyOrder.fee));
            buyOrder.buyer.transfer(buyOrder.price.add(buyOrder.fee));  
            emit BuyOrderCanceled(buyOrder.id);
        }
    }
     
     
     
    function createSellOrdersForTokenIds(uint256[] calldata ids, uint256[] calldata prices, uint256[] calldata tokenIds) onlyUnpaused external {
        _createSellOrdersForTokenIds(ids, prices, tokenIds, msg.sender);
    }
     
     
     
    function _createSellOrdersForTokenIds(uint256[] memory ids, uint256[] memory prices, uint256[] memory tokenIds, address payable seller) private {
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; i++) {
            _createSellOrderForTokenId(ids[i], prices[i], tokenIds[i], seller);
        }
    }
     
     
     
    function _createSellOrderForTokenId(uint256 id, uint256 price, uint256 tokenId, address seller) private {
        _createSellOrder(
            id,
            price,
            tokenId,
            godsUnchainedCards.cardProtos(tokenId),
            godsUnchainedCards.cardQualities(tokenId),
            seller,
            true
        );
    }
      
     
     
    function createSellOrdersForProtosAndQualities(uint256[] calldata ids, uint256[] calldata prices, uint256[] calldata protos, uint256[] calldata qualities) onlyUnpaused external {
        _createSellOrdersForProtosAndQualities(ids, prices, protos, qualities, msg.sender);
    }
     
     
     
    function _createSellOrdersForProtosAndQualities(uint256[] memory ids, uint256[] memory prices, uint256[] memory protos, uint256[] memory qualities, address payable seller) private {
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; i++) {
            _createSellOrderForProtoAndQuality(ids[i], prices[i], protos[i], qualities[i], seller);
        }
    }
     
     
     
    function _createSellOrderForProtoAndQuality(uint256 id, uint256 price, uint256 proto, uint256 quality, address seller) private {
        _createSellOrder(
            id,
            price,
            0,
            proto,
            quality,
            seller,
            false
        );
    }
     
     
     
    function _createSellOrder(uint256 id, uint256 price, uint256 tokenId, uint256 proto, uint256 quality, address seller, bool tokenIsSet) private {
        address payable payableSeller = address(uint160(seller));
        require(price > 0, "Sell order price needs to be bigger than 0.");

        SellOrder storage sellOrder = sellOrdersById[seller][id];
        require(sellOrder.id == 0, "Sell order with this ID does already exist!");
        require(godsUnchainedCards.isApprovedForAll(payableSeller, address(this)), "Operator approval missing!");
        sellOrder.id = id;
        sellOrder.price = price;
        sellOrder.proto = uint16(proto);
        sellOrder.quality = uint8(quality);
        sellOrder.seller = payableSeller;
        
        if(tokenIsSet) { _updateSellOrderTokenId(sellOrder, tokenId); }
        
        emit SellOrderCreated(sellOrder.id);
    }
     
     
     
    function _updateSellOrderTokenId(SellOrder storage sellOrder, uint256 tokenId) private {
        if(
            sellOrder.tokenIsSet ||
            sellOrder.canceled ||
            sellOrder.settled
        ) { return; }
        require(godsUnchainedCards.ownerOf(tokenId) == sellOrder.seller, "Seller is not owner of this token!");
        require(
            sellOrder.proto == godsUnchainedCards.cardProtos(tokenId) &&
            sellOrder.quality == godsUnchainedCards.cardQualities(tokenId)
            , "Token does not correspond to sell order proto/quality!"
        );
        sellOrder.tokenIsSet = true;
        sellOrder.tokenId = tokenId;
    }
     
     
     
    function createSellOrdersForTokenIdsAndSettle(uint256[] calldata sellOrderIds, address[] calldata sellOrderAddresses, uint256[] calldata sellOrderPrices, uint256[] calldata sellOrderTokenIds, uint256[] calldata buyOrderIds, address[] calldata buyOrderAddresses) onlyUnpaused external {
        _createSellOrdersForTokenIds(sellOrderIds, sellOrderPrices, sellOrderTokenIds, msg.sender);
        _settle(buyOrderIds, buyOrderAddresses, sellOrderIds, sellOrderAddresses);
    }
     
     
     
    function createOffChainSignedSellOrdersForTokenIds(uint256[] calldata sellOrderIds, uint256[] calldata sellOrderTokenIds, uint256[] calldata sellOrderPrices, uint8 v, bytes32 r, bytes32 s) onlyUnpaused external {
        _createOffChainSignedSellOrdersForTokenIds(sellOrderIds, sellOrderTokenIds, sellOrderPrices, v, r, s);
    }
     
     
     
    function _createOffChainSignedSellOrdersForTokenIds(uint256[] memory sellOrderIds, uint256[] memory sellOrderTokenIds, uint256[] memory sellOrderPrices, uint8 v, bytes32 r, bytes32 s) private {
        uint256 length = sellOrderIds.length;
        address seller = _recoverForTokenIds(sellOrderIds, sellOrderTokenIds, sellOrderPrices, v, r, s);
        for (
            uint256 i = 0;
            i < length;
            i++
        ) {
            if(sellOrdersById[seller][sellOrderIds[i]].id == 0) {
                 
                _createSellOrderForTokenId(
                    sellOrderIds[i],
                    sellOrderPrices[i],
                    sellOrderTokenIds[i],
                    seller
                );
            }
        }
    }
     
     
     
    function createSellOrdersForProtosAndQualitiesAndSettle(uint256[] calldata sellOrderData, uint256[] calldata tokenIds, uint256[] calldata buyOrderIds, address[] calldata buyOrderAddresses) onlyUnpaused external {
        uint256[] memory sellOrderIds = _unpackOrderData(sellOrderData, 0);
        _createSellOrdersForProtosAndQualities(
            sellOrderIds,
            _unpackOrderData(sellOrderData, 3),
            _unpackOrderData(sellOrderData, 1),
            _unpackOrderData(sellOrderData, 2),
            msg.sender
        );
        uint256 length = buyOrderIds.length;
        for (uint256 i = 0; i < length; i++) {
          _updateSellOrderTokenId(sellOrdersById[msg.sender][sellOrderIds[i]], tokenIds[i]);
          _settle(buyOrdersById[buyOrderAddresses[i]][buyOrderIds[i]], sellOrdersById[msg.sender][sellOrderIds[i]]);
        }
    }
     
     
     
    function createOffChainSignedSellOrdersForProtosAndQualities(uint256[] calldata sellOrderIds, uint256[] calldata sellOrderProtos, uint256[] calldata sellOrderQualities, uint256[] calldata sellOrderPrices, uint8 v, bytes32 r, bytes32 s) onlyUnpaused external {
        _createOffChainSignedSellOrdersForProtosAndQualities(sellOrderIds, sellOrderProtos, sellOrderQualities, sellOrderPrices, v, r, s);
    }
     
     
     
    function _createOffChainSignedSellOrdersForProtosAndQualities(uint256[] memory sellOrderIds, uint256[] memory sellOrderProtos, uint256[] memory sellOrderQualities, uint256[] memory sellOrderPrices, uint8 v, bytes32 r, bytes32 s) private {
        uint256 length = sellOrderIds.length;
        address seller = _recoverForProtosAndQualities(sellOrderIds, sellOrderProtos, sellOrderQualities, sellOrderPrices, v, r, s);
        for (
            uint256 i = 0;
            i < length;
            i++
        ) {
            if(sellOrdersById[seller][sellOrderIds[i]].id == 0) {
                 
                _createSellOrderForProtoAndQuality(
                    sellOrderIds[i],
                    sellOrderPrices[i],
                    sellOrderProtos[i],
                    sellOrderQualities[i],
                    seller
                );
            }
        }
    }
     
     
     
    function recoverSellOrderForTokenIds(uint256[] calldata ids, uint256[] calldata tokenIds, uint256[] calldata prices,  uint8 v, bytes32 r, bytes32 s) external view returns (address) {
        return _recoverForTokenIds(ids, tokenIds, prices, v, r, s);
    }
     
     
     
    function _recoverForTokenIds(uint256[] memory ids, uint256[] memory tokenIds, uint256[] memory prices, uint8 v, bytes32 r, bytes32 s) private view returns (address) {
        return ecrecover(hashSellOrdersForTokenIds(ids, tokenIds, prices), v, r, s);
    }
     
     
     
    function hashSellOrdersForTokenIds(uint256[] memory ids, uint256[] memory tokenIds, uint256[] memory prices) private view returns (bytes32){
        return keccak256(abi.encodePacked(
           "\x19\x01",
           domainSeparator,
           keccak256(abi.encode(
                sellOrdersForTokenIdsTypeHash,
                keccak256(abi.encodePacked(ids)),
                keccak256(abi.encodePacked(tokenIds)),
                keccak256(abi.encodePacked(prices))
            ))
        ));
    }
     
     
     
    function recoverSellOrderForProtosAndQualities(uint256[] calldata ids, uint256[] calldata protos, uint256[] calldata qualities, uint256[] calldata prices,  uint8 v, bytes32 r, bytes32 s) external view returns (address) {
        return _recoverForProtosAndQualities(ids, protos, qualities, prices, v, r, s);
    }
     
     
     
    function _recoverForProtosAndQualities(uint256[] memory ids, uint256[] memory protos, uint256[] memory qualities, uint256[] memory prices, uint8 v, bytes32 r, bytes32 s) private view returns (address) {
        return ecrecover(hashSellOrdersForProtosAndQualitiesIds(ids, protos, qualities, prices), v, r, s);
    }
      
     
     
    function hashSellOrdersForProtosAndQualitiesIds(uint256[] memory ids, uint256[] memory protos, uint256[] memory qualities, uint256[] memory prices) private view returns (bytes32){
        return keccak256(abi.encodePacked(
           "\x19\x01",
           domainSeparator,
           keccak256(abi.encode(
                sellOrdersForProtosAndQualitiesTypeHash,
                keccak256(abi.encodePacked(ids)),
                keccak256(abi.encodePacked(protos)),
                keccak256(abi.encodePacked(qualities)),
                keccak256(abi.encodePacked(prices))
            ))
        ));
    }
     
     
     
    function cancelSellOrders(uint256[] calldata ids) onlyUnpaused external {
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; i++) {
            SellOrder storage sellOrder = sellOrdersById[msg.sender][ids[i]];
            if(sellOrder.id == 0) {  
                sellOrder.id = ids[i];
            }
            require(sellOrder.canceled == false, "Order has already been canceled!");
            require(sellOrder.settled == false, "Order has already been settled!");
            sellOrder.canceled = true;
            emit SellOrderCanceled(sellOrder.id);
        }
    }
     
     
     
    function settle(uint256[] calldata buyOrderIds, address[] calldata buyOrderAddresses, uint256[] calldata sellOrderIds, address[] calldata sellOrderAddresses) onlyUnpaused external {
        _settle(buyOrderIds, buyOrderAddresses, sellOrderIds, sellOrderAddresses);
    }
     
     
     
    function settleWithToken(uint256[] calldata buyOrderIds, address[] calldata buyOrderAddresses, uint256[] calldata sellOrderIds, address[] calldata sellOrderAddresses, uint256[] calldata tokenIds) onlyUnpaused external {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
          _updateSellOrderTokenId(
              sellOrdersById[sellOrderAddresses[i]][sellOrderIds[i]],
              tokenIds[i]
          );
          _settle(buyOrdersById[buyOrderAddresses[i]][buyOrderIds[i]], sellOrdersById[sellOrderAddresses[i]][sellOrderIds[i]]);
        }
    }
     
     
     
    function _settle(uint256[] memory buyOrderIds, address[] memory buyOrderAddresses, uint256[] memory sellOrderIds, address[] memory sellOrderAddresses) private {
        uint256 length = buyOrderIds.length;
        for (uint256 i = 0; i < length; i++) {
            _settle(
                buyOrdersById[buyOrderAddresses[i]][buyOrderIds[i]],
                sellOrdersById[sellOrderAddresses[i]][sellOrderIds[i]]
            );
        }
    }
     
     
    function _settle(BuyOrder storage buyOrder, SellOrder storage sellOrder) private {
        if(
            sellOrder.settled || sellOrder.canceled ||
            buyOrder.settled || buyOrder.canceled
        ) { return; }

        uint256 proto = godsUnchainedCards.cardProtos(sellOrder.tokenId);
        uint256 quality = godsUnchainedCards.cardQualities(sellOrder.tokenId);
        require(buyOrder.price >= sellOrder.price, "Sell order exceeds what the buyer is willing to pay!");
        require(buyOrder.proto == proto && sellOrder.proto == proto, "Order protos are not matching!");
        require(buyOrder.quality == quality && sellOrder.quality == quality, "Order qualities are not matching!");
        
        sellOrder.settled = buyOrder.settled = true;  
        lockedInFunds = lockedInFunds.sub(buyOrder.price.add(buyOrder.fee));
        godsUnchainedCards.transferFrom(sellOrder.seller, buyOrder.buyer, sellOrder.tokenId);
        sellOrder.seller.transfer(sellOrder.price);

        emit Settled(buyOrder.id, sellOrder.id);
    }
     
     
     
    function setPausedTo(bool value) external onlyOwner {
        paused = value;
    }
     
     
     
    function setExchangeFee(uint256 value) external onlyOwner {
        exchangeFee = value;
    }
     
     
     
    function withdraw(address payable beneficiary, uint256 amount) external onlyOwner {
        require(lockedInFunds.add(amount) <= address(this).balance, "Not enough funds. Funds are partially locked from unsettled buy orders.");
        beneficiary.transfer(amount);
    }
     
     
     
    function approveNextOwner(address payable _nextOwner) external onlyOwner {
        require(_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }
     
     
     
    function acceptNextOwner() external {
        require(msg.sender == nextOwner, "The new owner has to accept the previously set new owner.");
        owner = nextOwner;
    }
     
     
     
     
     
    function kill() external onlyOwner {
        require(lockedInFunds == 0, "All orders need to be settled or refundeded before self-destruct.");
        selfdestruct(owner);
    }
     
     
     
     
    function () external payable {}
    
}