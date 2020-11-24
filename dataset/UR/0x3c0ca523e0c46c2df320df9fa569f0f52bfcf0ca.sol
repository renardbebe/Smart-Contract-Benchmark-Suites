 

 
 
 
 
 
 
 

pragma solidity ^0.4.25;

 
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
    uint public startTime;
    uint public endTime;
    string name;
    
     
    uint public potato;
    uint oldPotato;
    uint oldHighestBindingBid;
    
     
    bool public canceled;
    
    uint public highestBindingBid;
    address public highestBidder;
    
     
    bool blockerPay;
    bool blockerWithdraw;
    
    mapping(address => uint256) public fundsByBidder;
    bool ownerHasWithdrawn;

    event LogBid(address bidder, address highestBidder, uint oldHighestBindingBid, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();
    
    
     
    constructor() public {
        
        blockerWithdraw = false;
        blockerPay = false;
        
        owner = msg.sender;

         
        highestBindingBid = 3000000000000000;
        potato = 0;
        
         
        startTime = 1540922400;
        endTime = startTime + 3 hours;

        name = "Pumpkinhead 3";

    }
    
    function setStartTime(uint _time) onlyOwner public 
    {
        require(now < startTime);
        startTime = _time;
        endTime = startTime + 3 hours;
    }


     
    function nextBid() public view returns (uint _nextBid) {
        return highestBindingBid.add(potato);
    }
    
    
     
     
    function nextNextBid() public view returns (uint _nextBid) {
        return highestBindingBid.add(potato).add((highestBindingBid.add(potato)).mul(4).div(9));
    }
    
    
    function queryAuction() public view returns (string, uint, address, uint, uint, uint)
    {
        
        return (name, nextBid(), highestBidder, highestBindingBid, startTime, endTime);
        
    }


    function placeBid() public
        payable
        onlyAfterStart
        onlyBeforeEnd
        onlyNotCanceled
        onlyNotOwner
        returns (bool success)
    {   
         
        require(msg.value == highestBindingBid.add(potato));
        require(msg.sender != highestBidder);
        require(now > startTime);
        require(blockerPay == false);
        blockerPay = true;
        
         
         

        fundsByBidder[msg.sender] = fundsByBidder[msg.sender].add(highestBindingBid);
        fundsByBidder[highestBidder] = fundsByBidder[highestBidder].add(potato);

        highestBidder.transfer(fundsByBidder[highestBidder]);
        fundsByBidder[highestBidder] = 0;
        
        oldHighestBindingBid = highestBindingBid;
        
         
        highestBidder = msg.sender;
        highestBindingBid = highestBindingBid.add(potato);

        oldPotato = potato;
        potato = highestBindingBid.mul(4).div(9);
        
        emit LogBid(msg.sender, highestBidder, oldHighestBindingBid, highestBindingBid);
        blockerPay = false;
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

    function withdraw() public onlyOwner returns (bool success) 
    {
        require(now > endTime);
        
        msg.sender.transfer(address(this).balance);
        
        return true;
    }
    
    
    function balance() public view returns (uint _balance) {
        return address(this).balance;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNotOwner {
        require(msg.sender != owner);
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