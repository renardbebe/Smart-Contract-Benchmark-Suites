 

 
 

pragma solidity 0.4.19;


 
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


 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
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

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}


 
contract ReentrancyGuard {

     
    bool private reentrancyLock = false;

     
    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}


 
 
contract OwnTheDay is Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    event DayClaimed(address buyer, address seller, uint16 dayIndex, uint256 newPrice);

     
     
    mapping (uint16 => uint256) public dayIndexToPrice;

     
     
    mapping (uint16 => address) public dayIndexToOwner;

     
    mapping (address => string) public ownerAddressToName;

     
    function calculateOwnerCut(uint256 price) public pure returns (uint256) {
        uint8 percentCut = 5;
        if (price > 5000 finney) {
            percentCut = 2;
        } else if (price > 500 finney) {
            percentCut = 3;
        } else if (price > 250 finney) {
            percentCut = 4;
        }
        return price.mul(percentCut).div(100);
    }

     
    function calculatePriceIncrease(uint256 price) public pure returns (uint256) {
        uint8 percentIncrease = 100;
        if (price > 5000 finney) {
            percentIncrease = 15;
        } else if (price > 2500 finney) {
            percentIncrease = 18;
        } else if (price > 500 finney) {
            percentIncrease = 26;
        } else if (price > 250 finney) {
            percentIncrease = 36;
        }
        return price.mul(percentIncrease).div(100);
    }

     
    function getPriceByDayIndex(uint16 dayIndex) public view returns (uint256) {
        require(dayIndex >= 0 && dayIndex < 366);
        uint256 price = dayIndexToPrice[dayIndex];
        if (price == 0) { price = 1 finney; }
        return price;
    }

     
    function setAccountNickname(string nickname) public whenNotPaused {
        require(msg.sender != address(0));
        require(bytes(nickname).length > 0);
        ownerAddressToName[msg.sender] = nickname;
    }

     
     
    function claimDay(uint16 dayIndex) public nonReentrant whenNotPaused payable {
        require(msg.sender != address(0));
        require(dayIndex >= 0 && dayIndex < 366);

         
        address buyer = msg.sender;
        address seller = dayIndexToOwner[dayIndex];
        require(buyer != seller);

         
        uint256 amountPaid = msg.value;

         
        uint256 purchasePrice = dayIndexToPrice[dayIndex];
        if (purchasePrice == 0) {
            purchasePrice = 1 finney;  
        }
        require(amountPaid >= purchasePrice);

         
        uint256 changeToReturn = 0;
        if (amountPaid > purchasePrice) {
            changeToReturn = amountPaid.sub(purchasePrice);
            amountPaid -= changeToReturn;
        }

         
        uint256 priceIncrease = calculatePriceIncrease(purchasePrice);
        uint256 newPurchasePrice = purchasePrice.add(priceIncrease);
        dayIndexToPrice[dayIndex] = newPurchasePrice;

         
        uint256 ownerCut = calculateOwnerCut(amountPaid);
        uint256 salePrice = amountPaid.sub(ownerCut);

         
        dayIndexToOwner[dayIndex] = buyer;

         
        DayClaimed(buyer, seller, dayIndex, newPurchasePrice);

         
        if (seller != address(0)) {
            owner.transfer(ownerCut);
            seller.transfer(salePrice);
        } else {
            owner.transfer(salePrice.add(ownerCut));
        }
        if (changeToReturn > 0) {
            buyer.transfer(changeToReturn);
        }
    }
}