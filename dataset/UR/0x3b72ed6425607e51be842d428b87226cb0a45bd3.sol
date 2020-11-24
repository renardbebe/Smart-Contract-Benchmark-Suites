 

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

contract PreSale is Ownable {
    uint256 constant public INCREASE_RATE = 350000000000000;
    uint256 constant public START_TIME = 1514228838;
    uint256 constant public END_TIME =   1524251238;

    uint256 public landsSold;
    mapping (address => uint32) public lands;

    bool private paused = false; 

    function PreSale() payable public {
    }

    event landsPurchased(address indexed purchaser, uint256 value, uint32 quantity);
    
    event landsRedeemed(address indexed sender, uint256 lands);

    function bulkPurchageLand() payable public {
        require(now > START_TIME);
        require(now < END_TIME);
        require(paused == false);
        require(msg.value >= (landPriceCurrent() * 5 + INCREASE_RATE * 10));
        lands[msg.sender] = lands[msg.sender] + 5;
        landsSold = landsSold + 5;
        landsPurchased(msg.sender, msg.value, 5);
    }
    
    function purchaseLand() payable public {
        require(now > START_TIME);
        require(now < END_TIME);
        require(paused == false);
        require(msg.value >= landPriceCurrent());

        lands[msg.sender] = lands[msg.sender] + 1;
        landsSold = landsSold + 1;
        
        landsPurchased(msg.sender, msg.value, 1);
    }
    
    function redeemLand(address targetUser) public onlyOwner returns(uint256) {
        require(paused == false);
        require(lands[targetUser] > 0);

        landsRedeemed(targetUser, lands[targetUser]);

        uint256 userlands = lands[targetUser];
        lands[targetUser] = 0;
        return userlands;
    }

    function landPriceCurrent() view public returns(uint256) {
        return (landsSold + 1) * INCREASE_RATE;
    }
     
    function landPricePrevious() view public returns(uint256) {
        return (landsSold) * INCREASE_RATE;
    }

    function withdrawal() onlyOwner public {
        owner.transfer(this.balance);
    }

    function pause() onlyOwner public {
        paused = true;
    }
    
    function resume() onlyOwner public {
        paused = false;
    }

    function isPaused () onlyOwner public view returns(bool) {
        return paused;
    }
}