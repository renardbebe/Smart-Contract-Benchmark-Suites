 

 
 
 
 
 
 

pragma solidity ^0.4.21;

 
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
        if (b >= a) {
            return 0;
        }
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract AuctionPotato {
    using SafeMath for uint256; 
     
    address public owner;
    uint public bidIncrement;
    uint public startTime;
    uint public endTime;
    string public infoUrl;
    string name;
    
     
    bool started;

     
    uint public potato;
    
     
    bool public canceled;
    
    uint public highestBindingBid;
    address public highestBidder;
    
    mapping(address => uint256) public fundsByBidder;
    bool ownerHasWithdrawn;

    event LogBid(address bidder, uint bid, address highestBidder, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();
    
    
     
    constructor() public {

        owner = msg.sender;
         
        bidIncrement = 10000000000000000;
        
        started = false;
        
        name = "Lizard People";
        infoUrl = "https://chibifighters.io";
        
    }

    function getHighestBid() internal
        constant
        returns (uint)
    {
        return fundsByBidder[highestBidder];
    }
    
    function timeLeft() public view returns (uint time) {
        if (now >= endTime) return 0;
        return endTime - now;
    }
    
    function auctionName() public view returns (string _name) {
        return name;
    }
    
    function nextBid() public view returns (uint _nextBid) {
        return bidIncrement.add(highestBindingBid).add(potato);
    }
    
    function startAuction(string _name, uint _duration_secs) public onlyOwner returns (bool success){
        require(started == false);
        
        started = true;
        startTime = now;
        endTime = now + _duration_secs;
        name = _name;
        
        return true;
        
    }
    
    function isStarted() public view returns (bool success) {
        return started;
    }

    function placeBid() public
        payable
        onlyAfterStart
        onlyBeforeEnd
        onlyNotCanceled
        onlyNotOwner
        returns (bool success)
    {   
         
        require(msg.value == highestBindingBid.add(bidIncrement).add(potato));
        require(msg.sender != highestBidder);
        require(started == true);
        
         
         
        uint newBid = highestBindingBid.add(bidIncrement);

        fundsByBidder[msg.sender] = fundsByBidder[msg.sender].add(newBid);
        
        fundsByBidder[highestBidder] = fundsByBidder[highestBidder].add(potato);
        
         
        highestBidder = msg.sender;
        highestBindingBid = newBid;
        
         
        bidIncrement = bidIncrement.mul(5).div(4);
        
         
        potato = highestBindingBid.div(100).mul(20);
        
        emit LogBid(msg.sender, newBid, highestBidder, highestBindingBid);
        return true;
    }

    function cancelAuction() public
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
        returns (bool success)
    {
        canceled = true;
        emit LogCanceled();
        return true;
    }

    function withdraw() public
     
        returns (bool success)
    {
        address withdrawalAccount;
        uint withdrawalAmount;

        if (canceled) {
             
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
             
            fundsByBidder[withdrawalAccount] = 0;
        }
        
         
         
        if (msg.sender == owner) {
            withdrawalAccount = owner;
            withdrawalAmount = highestBindingBid;
            ownerHasWithdrawn = true;
            
             
            fundsByBidder[withdrawalAccount] = 0;
        }
        
         
         
        if (!canceled && (msg.sender != highestBidder && msg.sender != owner)) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
            fundsByBidder[withdrawalAccount] = 0;
        }

         
        if (msg.sender == highestBidder && msg.sender != owner) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount].sub(highestBindingBid);
            fundsByBidder[withdrawalAccount] = fundsByBidder[withdrawalAccount].sub(withdrawalAmount);
        }

        if (withdrawalAmount == 0) revert();
    
         
        if (!msg.sender.send(withdrawalAmount)) revert();

        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;
    }
    
     
    function fuelContract() public onlyOwner payable {
        
    }
    
    function balance() public view returns (uint _balance) {
        return address(this).balance;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    modifier onlyNotOwner {
        if (msg.sender == owner) revert();
        _;
    }

    modifier onlyAfterStart {
        if (now < startTime) revert();
        _;
    }

    modifier onlyBeforeEnd {
        if (now > endTime) revert();
        _;
    }

    modifier onlyNotCanceled {
        if (canceled) revert();
        _;
    }
}