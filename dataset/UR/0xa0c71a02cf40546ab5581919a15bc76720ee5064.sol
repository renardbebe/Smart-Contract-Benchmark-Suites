 

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
        require(msg.sender == owner);
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


 


contract VOXTrader is HorizonContractBase {
    using SafeMath for uint256;

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

     
    uint256 public tokenFeePercent;
    
     
    uint256 public tokenFeeMin;
    
     
    uint256 public etherFeePercent;
    
     
    uint256 public etherFeeMin;

     
    event TokensOffered(address indexed who, uint256 quantity, uint256 price, uint256 expiry);

     
    event TokensPurchased(address indexed purchaser, address indexed seller, uint256 quantity, uint256 price);

     
    event VoucherRedeemed(uint256 voucherCode, address voucherOwner, address tokenSeller, uint256 quantity);


     
    constructor(address tokenContract_) public {
        owner = msg.sender;
        tokenContract = tokenContract_;
    }

     
    function getOrder(address who) public view returns (uint256 quantity, uint256 price, uint256 expiry) {
        TradeOrder memory order = orderBook[who];
        return (order.quantity, order.price, order.expiry);
    }

     
    function sell(uint256 quantity, uint256 price, uint256 expiry) public {
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

     
    function buy(address seller, uint256 quantity, uint256 price) public payable {
        TradeOrder memory order = orderBook[seller];
        require(order.price == price, "Buy price does not match the listed sell price.");
        require(block.timestamp < order.expiry, "Sell order has expired.");

        uint256 tradeQuantity = order.quantity > quantity ? quantity : order.quantity;
        uint256 cost = multiplyAtPrecision(tradeQuantity, order.price, 9);
        require(msg.value >= cost, "You did not send enough Ether to purchase the tokens.");

        uint256 tokenFee;
        uint256 etherFee;
        (tokenFee, etherFee) = calculateFee(tradeQuantity, cost);

        if(!ERC20Interface(tokenContract).transferFrom(seller, msg.sender, tradeQuantity.sub(tokenFee))) {
            revert("Unable to transfer tokens from seller to buyer.");
        }

         
        if(tokenFee > 0 && !ERC20Interface(tokenContract).transferFrom(seller, owner, tokenFee)) {
            revert("Unable to transfer tokens from seller to buyer.");
        }

         
        order.quantity = order.quantity.sub(tradeQuantity);
        orderBook[seller] = order;

         
        seller.transfer(cost.sub(etherFee));
        if(etherFee > 0)
            owner.transfer(etherFee);

        lastSellPrice = price;

        emit TokensPurchased(msg.sender, seller, tradeQuantity, price);
    }

     
    function setTokenFeePercent(uint256 percent) public onlyOwner {
        require(percent <= 100000000000000000000, "Percent must be between 0 and 100.");
        tokenFeePercent = percent;
    }

     
    function setTokenFeeMin(uint256 min) public onlyOwner {
        tokenFeeMin = min;
    }

     
    function setEtherFeePercent(uint256 percent) public onlyOwner {
        require(percent <= 100000000000000000000, "Percent must be between 0 and 100.");
        etherFeePercent = percent;
    }

     
    function setEtherFeeMin(uint256 min) public onlyOwner {
        etherFeeMin = min;
    }

     
    function calculateFee(uint256 tokens, uint256 ethers) public view returns (uint256 tokenFee, uint256 etherFee) {
        tokenFee = multiplyAtPrecision(tokens, tokenFeePercent / 100, 9);
        if(tokenFee < tokenFeeMin)
            tokenFee = tokenFeeMin;

        etherFee = multiplyAtPrecision(ethers, etherFeePercent / 100, 9);
        if(etherFee < etherFeeMin)
            etherFee = etherFeeMin;            

        return (tokenFee, etherFee);
    }

     
    function multiBuy(address[] sellers, uint256 lastQuantity) public payable {

        for (uint i = 0; i < sellers.length; i++) {
            TradeOrder memory to = orderBook[sellers[i]];
            if(i == sellers.length-1) {
                buy(sellers[i], lastQuantity, to.price);
            }
            else {
                buy(sellers[i], to.quantity, to.price);
            }
        }
    }

     
    function redeemVoucher(uint256 voucherCode, address voucherOwner, address tokenSeller, uint256 quantity) public onlyOwner payable {

         
        buy(tokenSeller, quantity, orderBook[tokenSeller].price);

         
        emit VoucherRedeemed(voucherCode, voucherOwner, tokenSeller, quantity);
    }

     
    function setSellCeiling(uint256 ceiling) public onlyOwner {
        sellCeiling = ceiling;
    }

     
    function setSellFloor(uint256 floor) public onlyOwner {
        sellFloor = floor;
    }

     
    function multiplyAtPrecision(uint256 num1, uint256 num2, uint8 digits) public pure returns (uint256) {
        return removeLowerDigits(num1, digits) * removeLowerDigits(num2, digits);
    }

     
    function removeLowerDigits(uint256 value, uint8 digits) public pure returns (uint256) {
        uint256 divisor = 10 ** uint256(digits);
        uint256 div = value / divisor;
        uint256 mult = div * divisor;

        require(mult == value, "The lower digits bring stripped off must be non-zero");

        return div;
    }
}