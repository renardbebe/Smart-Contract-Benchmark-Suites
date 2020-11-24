 

pragma solidity ^0.4.18;

 
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


     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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


contract TempusToken {

    function mint(address receiver, uint256 amount) public returns (bool success);

}

contract TempusPreIco is Ownable {
    using SafeMath for uint256;

     
    uint public startTime = 1512118800;  
    uint public endTime = 1517562000;  

     
    uint public price = 0.005 ether / 1000;

     
    uint public hardCap = 860000000;
    uint public tokensSold = 0;

    bool public paused = false;

    address withdrawAddress1;
    address withdrawAddress2;

    TempusToken token;

    mapping(address => bool) public sellers;

    modifier onlySellers() {
        require(sellers[msg.sender]);
        _;
    }

    function TempusPreIco (address tokenAddress, address _withdrawAddress1,
    address _withdrawAddress2) public {
        token = TempusToken(tokenAddress);
        withdrawAddress1 = _withdrawAddress1;
        withdrawAddress2 = _withdrawAddress2;
    }

     
    function isActive() public view returns (bool active) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool capIsNotMet = tokensSold < hardCap;
        return capIsNotMet && withinPeriod && !paused;
    }

    function() external payable {
        buyFor(msg.sender);
    }

     
    function buyFor(address beneficiary) public payable {
        require(msg.value != 0);
        uint amount = msg.value;
        uint tokenAmount = amount.div(price);
        makePurchase(beneficiary, tokenAmount);
    }

     
    function externalPurchase(address beneficiary, uint amount) external onlySellers {
        makePurchase(beneficiary, amount);
    }

    function makePurchase(address beneficiary, uint amount) private {
        require(beneficiary != 0x0);
        require(isActive());
        uint minimumTokens = 20000;
        if(tokensSold < hardCap.sub(minimumTokens)) {
            require(amount >= minimumTokens);
        }
        require(amount.add(tokensSold) <= hardCap);
        tokensSold = tokensSold.add(amount);
        token.mint(beneficiary, amount);
    }

    function setPaused(bool isPaused) external onlyOwner {
        paused = isPaused;
    }

     
    function setAsSeller(address seller, bool isSeller) external onlyOwner {
        sellers[seller] = isSeller;
    }

     
    function setStartTime(uint _startTime) external onlyOwner {
        startTime = _startTime;
    }

     
    function setEndTime(uint _endTime) external onlyOwner {
        endTime = _endTime;
    }

     
    function withdrawEther(uint amount) external onlyOwner {
        withdrawAddress1.transfer(amount / 2);
        withdrawAddress2.transfer(amount / 2);
    }

}