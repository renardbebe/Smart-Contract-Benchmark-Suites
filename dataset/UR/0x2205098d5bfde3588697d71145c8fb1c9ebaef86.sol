 

 
 
 
 
 
 
 
 
 
 
 
 

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
    
    string name;
    
     
    bool started;

     
    uint public potato;
    uint oldPotato;
    uint oldHighestBindingBid;
    
     
    address creatureOwner;
    
    event CreatureOwnershipTransferred(address indexed _from, address indexed _to);
    
    
   
    
    uint public highestBindingBid;
    address public highestBidder;
    
     
    bool blockerPay;
    bool blockerWithdraw;
    
    mapping(address => uint256) public fundsByBidder;
  

    event LogBid(address bidder, address highestBidder, uint oldHighestBindingBid, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    
    
    
     
    constructor() public {
    
        
        blockerWithdraw = false;
        blockerPay = false;
        
        owner = msg.sender;
        creatureOwner = owner;
        
         
        highestBindingBid = 1000000000000000000;
        potato = 0;
        
        started = false;
        
        name = "Aetherian";
        
    }

    function getHighestBid() internal
        constant
        returns (uint)
    {
        return fundsByBidder[highestBidder];
    }
    
    
    
    function auctionName() public view returns (string _name) {
        return name;
    }
    
     
    function nextBid() public view returns (uint _nextBid) {
        return highestBindingBid.add(potato);
    }
    
    
     
    function startAuction() public onlyOwner returns (bool success){
        require(started == false);
        
        started = true;
        startTime = now;
        
        
        return true;
        
    }
    
    function isStarted() public view returns (bool success) {
        return started;
    }

    function placeBid() public
        payable
        onlyAfterStart
        onlyNotOwner
        returns (bool success)
    {   
         
         
        require(msg.value >= highestBindingBid.add(potato));
        require(msg.sender != highestBidder);
        require(started == true);
        require(blockerPay == false);
        blockerPay = true;

         
        if (msg.value > highestBindingBid.add(potato))
        {
            uint overbid = msg.value - highestBindingBid.add(potato);
            msg.sender.transfer(overbid);
        }
        
         
         

        
        
        oldHighestBindingBid = highestBindingBid;
        
         
        highestBidder = msg.sender;
        highestBindingBid = highestBindingBid.add(potato);
        
        fundsByBidder[msg.sender] = fundsByBidder[msg.sender].add(highestBindingBid);
        
        
        oldPotato = potato;
        
        uint potatoShare;
        
        potatoShare = potato.div(2);
        potato = highestBindingBid.mul(5).div(10);
            
         
        if (creatureOwner == owner) {
            fundsByBidder[owner] = fundsByBidder[owner].add(highestBindingBid);
        }
        else {
            fundsByBidder[owner] = fundsByBidder[owner].add(potatoShare);
            
            fundsByBidder[creatureOwner] = fundsByBidder[creatureOwner].add(potatoShare);
        }
        
        
        
        
        emit LogBid(msg.sender, highestBidder, oldHighestBindingBid, highestBindingBid);
        
        
        emit CreatureOwnershipTransferred(creatureOwner, msg.sender);
        creatureOwner = msg.sender;
        
        
        blockerPay = false;
        return true;
    }

    

    function withdraw() public
     
        returns (bool success)
    {
        require(blockerWithdraw == false);
        blockerWithdraw = true;
        
        address withdrawalAccount;
        uint withdrawalAmount;
        
        if (msg.sender == owner) {
            withdrawalAccount = owner;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
            
            
             
            fundsByBidder[withdrawalAccount] = 0;
        }
       
         
         
        if (msg.sender != highestBidder && msg.sender != owner) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
            fundsByBidder[withdrawalAccount] = 0;
        }
        
        if (withdrawalAmount == 0) revert();
    
         
        msg.sender.transfer(withdrawalAmount);

        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);
        blockerWithdraw = false;
        return true;
    }
    
     
     
     
     
    function ownerCanWithdraw() public view returns (uint amount) {
        return fundsByBidder[owner];
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

    
    
    
     
    function queryCreatureOwner() public view returns (address _creatureOwner) {
        return creatureOwner;
    }
    
    
    
   
    
}