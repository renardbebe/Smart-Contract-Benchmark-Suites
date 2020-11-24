 

pragma solidity 0.4.24;


 

 
 
 
 
 
 
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address approver, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed approver, address indexed spender, uint256 value);
}



 
 
 
contract HorizonContractBase {
     
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
}




 

 
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
         
         
         
        return a / b;
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
 

 

 
 
 
 

 
 
 
 

 
 



library DSMath {
    
    function dsAdd(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function dsMul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = dsAdd(dsMul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = dsAdd(dsMul(x, WAD), y / 2) / y;
    }
}


 
contract VOXTrader is HorizonContractBase {
    using SafeMath for uint256;
    using DSMath for uint256;

    struct TradeOrder {
        uint256 quantity;
        uint256 price;
        uint256 expiry;
    }

     
    address public owner;

     
    mapping (address => TradeOrder) public orderBook;

     
    address public tokenContract;

     
    uint256 public lastSellPrice;

     
    uint256 public sellCeiling;

     
    uint256 public sellFloor;

     
    uint256 public etherFeePercent;
    
     
    uint256 public etherFeeMin;

     
    bool public enforceKyc;

     
    mapping (address => bool) public tradingWhitelist;

     
    event TokensOffered(address indexed who, uint256 quantity, uint256 price, uint256 expiry);

     
    event TokensPurchased(address indexed purchaser, address indexed seller, uint256 quantity, uint256 price);

     
    event TokenOfferChanged(address who, uint256 quantity, uint256 price, uint256 expiry);

     
    event VoucherRedeemed(uint256 voucherCode, address voucherOwner, address tokenSeller, uint256 quantity);

     
    event ContractRetired(address newAddcontract);


     
    constructor(address tokenContract_) public {
        owner = msg.sender;
        tokenContract = tokenContract_;

         
        enforceKyc = true;
        setTradingAllowed(msg.sender, true);
    }

     
    function getOrder(address who) public view returns (uint256 quantity, uint256 price, uint256 expiry) {
        TradeOrder memory order = orderBook[who];
        return (order.quantity, order.price, order.expiry);
    }

     
    function offer(uint256 quantity, uint256 price, uint256 expiry) public {
        require(enforceKyc == false || isAllowedTrade(msg.sender), "You are unknown and not allowed to trade.");
        require(quantity > 0, "You must supply a quantity.");
        require(price > 0, "The sale price cannot be zero.");
        require(expiry > block.timestamp, "Cannot have an expiry date in the past.");
        require(price >= sellFloor, "The ask is below the minimum allowed.");
        require(sellCeiling == 0 || price <= sellCeiling, "The ask is above the maximum allowed.");

        uint256 allowed = ERC20Interface(tokenContract).allowance(msg.sender, this);
        require(allowed >= quantity, "You must approve the transfer of tokens before offering them for sale.");

        uint256 balance = ERC20Interface(tokenContract).balanceOf(msg.sender);
        require(balance >= quantity, "Not enough tokens owned to complete the order.");

        orderBook[msg.sender] = TradeOrder(quantity, price, expiry);
        emit TokensOffered(msg.sender, quantity, price, expiry);
    }

     
    function execute(address seller, uint256 quantity, uint256 price) public payable {
        require(enforceKyc == false || (isAllowedTrade(msg.sender) && isAllowedTrade(seller)), "Buyer and Seller must be approved to trade on this exchange.");
        TradeOrder memory order = orderBook[seller];
        require(order.price == price, "Buy price does not match the listed sell price.");
        require(block.timestamp < order.expiry, "Sell order has expired.");
        require(price >= sellFloor, "The bid is below the minimum allowed.");
        require(sellCeiling == 0 || price <= sellCeiling, "The bid is above the maximum allowed.");

         
        uint256 tradeQuantity = order.quantity > quantity ? quantity : order.quantity;
        order.quantity = order.quantity.sub(tradeQuantity);
        if (order.quantity == 0) {
            order.price = 0;
            order.expiry = 0;
        }
        orderBook[seller] = order;

        uint256 cost = tradeQuantity.wmul(order.price);
        require(msg.value >= cost, "You did not send enough Ether to purchase the tokens.");

        uint256 etherFee = calculateFee(cost);

        if(!ERC20Interface(tokenContract).transferFrom(seller, msg.sender, tradeQuantity)) {
            revert("Unable to transfer tokens from seller to buyer.");
        }

         
        seller.transfer(cost.sub(etherFee));
        if(etherFee > 0)
            owner.transfer(etherFee);

        lastSellPrice = price;

        emit TokensPurchased(msg.sender, seller, tradeQuantity, price);
    }

     
    function cancel() public {
        orderBook[msg.sender] = TradeOrder(0, 0, 0);

        TradeOrder memory order = orderBook[msg.sender];
        emit TokenOfferChanged(msg.sender, order.quantity, order.price, order.expiry);
    }

     
    function setTradingAllowed(address who, bool canTrade) public onlyOwner {
        tradingWhitelist[who] = canTrade;
    }

     
    function isAllowedTrade(address who) public view returns (bool) {
        return tradingWhitelist[who];
    }

     
    function setEnforceKyc(bool enforce) public onlyOwner {
        enforceKyc = enforce;
    }

     
    function setOfferPrice(uint256 price) public {
        require(enforceKyc == false || isAllowedTrade(msg.sender), "You are unknown and not allowed to trade.");
        require(price >= sellFloor && (sellCeiling == 0 || price <= sellCeiling), "Updated price is out of range.");

        TradeOrder memory order = orderBook[msg.sender];
        require(order.price != 0 || order.expiry != 0, "There is no existing order to modify.");
        
        order.price = price;
        orderBook[msg.sender] = order;

        emit TokenOfferChanged(msg.sender, order.quantity, order.price, order.expiry);
    }

     
    function setOfferSize(uint256 quantity) public {
        require(enforceKyc == false || isAllowedTrade(msg.sender), "You are unknown and not allowed to trade.");
        require(quantity > 0, "Size must be greater than zero, change rejected.");
        uint256 balance = ERC20Interface(tokenContract).balanceOf(msg.sender);
        require(balance >= quantity, "Not enough tokens owned to complete the order change.");
        uint256 allowed = ERC20Interface(tokenContract).allowance(msg.sender, this);
        require(allowed >= quantity, "You must approve the transfer of tokens before offering them for sale.");

        TradeOrder memory order = orderBook[msg.sender];
        order.quantity = quantity;
        orderBook[msg.sender] = order;

        emit TokenOfferChanged(msg.sender, quantity, order.price, order.expiry);
    }

     
    function setOfferExpiry(uint256 expiry) public {
        require(enforceKyc == false || isAllowedTrade(msg.sender), "You are unknown and not allowed to trade.");
        require(expiry > block.timestamp, "Cannot have an expiry date in the past.");

        TradeOrder memory order = orderBook[msg.sender];
        order.expiry = expiry;
        orderBook[msg.sender] = order;

        emit TokenOfferChanged(msg.sender, order.quantity, order.price, order.expiry);        
    }

     
    function setEtherFeePercent(uint256 percent) public onlyOwner {
        require(percent <= 100000000000000000000, "Percent must be between 0 and 100.");
        etherFeePercent = percent;
    }

     
    function setEtherFeeMin(uint256 min) public onlyOwner {
        etherFeeMin = min;
    }

     
    function calculateFee(uint256 ethers) public view returns (uint256 fee) {

        fee = ethers.wmul(etherFeePercent / 100);
        if(fee < etherFeeMin)
            fee = etherFeeMin;            

        return fee;
    }

     
    function multiExecute(address[] sellers, uint256 lastQuantity) public payable returns (uint256 totalVouchers) {
        require(enforceKyc == false || isAllowedTrade(msg.sender), "You are unknown and not allowed to trade.");

        totalVouchers = 0;

        for (uint i = 0; i < sellers.length; i++) {
            TradeOrder memory to = orderBook[sellers[i]];
            if(i == sellers.length-1) {
                execute(sellers[i], lastQuantity, to.price);
                totalVouchers += lastQuantity;
            }
            else {
                execute(sellers[i], to.quantity, to.price);
                totalVouchers += to.quantity;
            }
        }

        return totalVouchers;
    }

     
    function redeemVoucherSingle(uint256 voucherCode, address voucherOwner, address seller, uint256 quantity) public onlyOwner payable {

         
        TradeOrder memory order = orderBook[seller];
        execute(seller, quantity, order.price);

         
        emit VoucherRedeemed(voucherCode, voucherOwner, seller, quantity);
    }

     
    function redeemVoucher(uint256 voucherCode, address voucherOwner, address[] sellers, uint256 lastQuantity) public onlyOwner payable {

         
        uint256 totalVouchers = multiExecute(sellers, lastQuantity);

         
         
        address seller = sellers.length == 1 ? sellers[0] : 0;
        emit VoucherRedeemed(voucherCode, voucherOwner, seller, totalVouchers);
    }

     
    function setSellCeiling(uint256 ceiling) public onlyOwner {
        sellCeiling = ceiling;
    }

     
    function setSellFloor(uint256 floor) public onlyOwner {
        sellFloor = floor;
    }

     
    function retire(address recipient, address newContract) public onlyOwner {
        emit ContractRetired(newContract);

        selfdestruct(recipient);
    }
}