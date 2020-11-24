 

 
 
 
 
 
 

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
    uint public startTime;
    uint public endTime;
    string public infoUrl;
    string name;
    
     
    bool started;

     
    uint public potato;
    uint oldPotato;
    uint oldHighestBindingBid;
    
     
    address creatureOwner;
    address creature_newOwner;
    event CreatureOwnershipTransferred(address indexed _from, address indexed _to);
    
    
     
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
        creatureOwner = owner;
        
         
        highestBindingBid = 2000000000000000;
        potato = 0;
        
        started = false;
        
        name = "Minotaur";
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
        return highestBindingBid.add(potato);
    }
    
     
     
    function nextNextBid() public view returns (uint _nextBid) {
        return highestBindingBid.add(potato).add((highestBindingBid.add(potato)).mul(4).div(9));
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
         
        require(msg.value == highestBindingBid.add(potato));
        require(msg.sender != highestBidder);
        require(started == true);
        require(blockerPay == false);
        blockerPay = true;
        
         
         

        fundsByBidder[msg.sender] = fundsByBidder[msg.sender].add(highestBindingBid);
        fundsByBidder[highestBidder] = fundsByBidder[highestBidder].add(potato);
        
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

    function withdraw() public
     
        returns (bool success)
    {
        require(blockerWithdraw == false);
        blockerWithdraw = true;
        
        address withdrawalAccount;
        uint withdrawalAmount;

        if (canceled) {
             
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
             
            fundsByBidder[withdrawalAccount] = 0;
        }
        
         
        if (ownerHasWithdrawn == false && msg.sender == owner && (canceled == true || now > endTime)) {
            withdrawalAccount = owner;
            withdrawalAmount = highestBindingBid.sub(oldPotato);
            ownerHasWithdrawn = true;
            
             
            fundsByBidder[withdrawalAccount] = 0;
        }
        
         
         
        if (!canceled && (msg.sender != highestBidder && msg.sender != owner)) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
            fundsByBidder[withdrawalAccount] = 0;
        }

         
        if (!canceled && msg.sender == highestBidder && msg.sender != owner) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount].sub(oldHighestBindingBid);
            fundsByBidder[withdrawalAccount] = fundsByBidder[withdrawalAccount].sub(withdrawalAmount);
        }

        if (withdrawalAmount == 0) revert();
    
         
        msg.sender.transfer(withdrawalAmount);

        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);
        blockerWithdraw = false;
        return true;
    }
    
     
     
     
     
    function ownerCanWithdraw() public view returns (uint amount) {
        return highestBindingBid.sub(oldPotato);
    }
    
     
     
    function fuelContract() public onlyOwner payable {
        
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
    
     
    function queryCreatureOwner() public view returns (address _creatureOwner) {
        return creatureOwner;
    }
    
     
    function transferCreatureOwnership(address _newOwner) public {
        require(msg.sender == creatureOwner);
        creature_newOwner = _newOwner;
    }
    
     
    function acceptCreatureOwnership() public {
        require(msg.sender == creature_newOwner);
        emit CreatureOwnershipTransferred(creatureOwner, creature_newOwner);
        creatureOwner = creature_newOwner;
        creature_newOwner = address(0);
    }
    
}