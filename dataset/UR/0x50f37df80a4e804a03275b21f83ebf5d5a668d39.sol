 

 
 
 
 
 
 

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



 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract AuctionPotato is Ownable {
    using SafeMath for uint256; 

    string name;
    uint public startTime;
    uint public endTime;
    uint auctionDuration;

     
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
    event Withdraw(address owner, uint amount);
    
    
    constructor() public {
        
        blockerWithdraw = false;
        blockerPay = false;
        
         
        highestBindingBid = 3000000000000000;
        potato = 0;
        
         
        auctionDuration = 3 hours;

         

        startTime = 1546794000;
        endTime = startTime + auctionDuration;

        name = "Glen Weyl 3";

    }
    
    
    function setStartTime(uint _time) onlyOwner public 
    {
        require(now < startTime);
        startTime = _time;
        endTime = startTime + auctionDuration;
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
    }


    function cancelAuction() public
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
    {
        canceled = true;
        emit LogCanceled();
        
        emit Withdraw(highestBidder, address(this).balance);
        highestBidder.transfer(address(this).balance);
        
    }


    function withdraw() public onlyOwner {
        require(now > endTime);
        
        emit Withdraw(msg.sender, address(this).balance);
        msg.sender.transfer(address(this).balance);
    }


    function balance() public view returns (uint _balance) {
        return address(this).balance;
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