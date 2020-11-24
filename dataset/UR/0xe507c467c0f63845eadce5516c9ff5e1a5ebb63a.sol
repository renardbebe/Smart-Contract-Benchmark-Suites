 

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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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



contract CaiShen is Ownable {
    struct Gift {
        bool exists;         
        uint giftId;         
        address giver;       
        address recipient;   
        uint expiry;         
                             
        uint amount;         
        bool redeemed;       
        string giverName;    
        string message;      
        uint timestamp;      
    }

     
     
    uint public feesGathered;

     
     
    uint public nextGiftId;

     
     
    mapping (address => uint[]) public recipientToGiftIds;

     
    mapping (uint => Gift) public giftIdToGift;

    event Constructed (address indexed by, uint indexed amount);

    event CollectedAllFees (address indexed by, uint indexed amount);

    event DirectlyDeposited(address indexed from, uint indexed amount);

    event Gave (uint indexed giftId,
                address indexed giver,
                address indexed recipient,
                uint amount, uint expiry);

    event Redeemed (uint indexed giftId,
                    address indexed giver,
                    address indexed recipient,
                    uint amount);

     
    function CaiShen() public payable {
        Constructed(msg.sender, msg.value);
    }

     
    function () public payable {
         
         
        DirectlyDeposited(msg.sender, msg.value);
    }

     

    function getGiftIdsByRecipient (address recipient) 
    public view returns (uint[]) {
        return recipientToGiftIds[recipient];
    }

     

     
     
     
     
     
     
    function give (address recipient, uint expiry, string giverName, string message)
    public payable returns (uint) {
        address giver = msg.sender;

         
        assert(giver != address(0));

         
        uint amount = msg.value;
        require(amount > 0);
        
         
         
         
        require(expiry > now);

         
        require(giver != recipient);

         
        require(recipient != address(0));

         
        assert(nextGiftId >= 0);

         
        uint feeTaken = fee(amount);
        assert(feeTaken >= 0);

         
        feesGathered = SafeMath.add(feesGathered, feeTaken);

         
        uint amtGiven = SafeMath.sub(amount, feeTaken);
        assert(amtGiven > 0);

         
        assert(giftIdToGift[nextGiftId].exists == false);

         
        recipientToGiftIds[recipient].push(nextGiftId);
        giftIdToGift[nextGiftId] = 
            Gift(true, nextGiftId, giver, recipient, expiry, 
            amtGiven, false, giverName, message, now);

        uint giftId = nextGiftId;

         
        nextGiftId = SafeMath.add(giftId, 1);

         
        assert(giftIdToGift[nextGiftId].exists == false);

         
        Gave(giftId, giver, recipient, amount, expiry);

        return giftId;
    }

     
     
    function redeem (uint giftId) public {
         
        require(giftId >= 0);

         
        require(isValidGift(giftIdToGift[giftId]));

         
        address recipient = giftIdToGift[giftId].recipient;
        require(recipient == msg.sender);

         
        require(now >= giftIdToGift[giftId].expiry);

         
         

         
        uint amount = giftIdToGift[giftId].amount;
        assert(amount > 0);

         
        address giver = giftIdToGift[giftId].giver;
        assert(giver != recipient);

         
        assert(giver != address(0));

         
         
        giftIdToGift[giftId].redeemed = true;

         
        recipient.transfer(amount);

         
        Redeemed(giftId, giftIdToGift[giftId].giver, recipient, amount);
    }

     
     
    function fee (uint amount) public pure returns (uint) {
        if (amount <= 0.01 ether) {
            return 0;
        } else if (amount > 0.01 ether) {
            return SafeMath.div(amount, 100);
        }
    }

     
     
     
    function collectAllFees () public onlyOwner {
         
        uint amount = feesGathered;

         
        require(amount > 0);

         
        feesGathered = 0;

         
        owner.transfer(amount);

        CollectedAllFees(owner, amount);
    }

     
     
    function isValidGift(Gift gift) private pure returns (bool) {
        return gift.exists == true && gift.redeemed == false;
    }
}