 

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

contract CratePreSale is Ownable {
    
     
    uint256 constant public MAX_CRATES_TO_SELL = 3900;  
    uint256 constant public PRESALE_END_TIMESTAMP = 1518699600;  

    uint256 public appreciationRateWei = 400000000000000;  
    uint256 public currentPrice = appreciationRateWei;  
    uint32 public cratesSold;
    
    mapping (address => uint32) public userCrateCount;  
    mapping (address => uint[]) public userToRobots;  
    
     
    event LogCratePurchase( 
        address indexed _from,
        uint256 _value,
        uint32 _quantity
        );


     
    function getPrice() view public returns (uint256) {
        return currentPrice;
    }

    function getRobotsForUser( address _user ) view public returns (uint[]) {
        return userToRobots[_user];
    }

    function incrementPrice() private { 
         
         
         
         
        if ( currentPrice == 100000000000000000 ) {
            appreciationRateWei = 200000000000000;
        } else if ( currentPrice == 200000000000000000) {
            appreciationRateWei = 100000000000000;
        } else if (currentPrice == 300000000000000000) {
            appreciationRateWei = 50000000000000;
        }
        currentPrice += appreciationRateWei;
    }

    function purchaseCrate() payable public {
        require(now < PRESALE_END_TIMESTAMP);  
        require(cratesSold < MAX_CRATES_TO_SELL);  
        require(msg.value >= currentPrice);  
        if (msg.value > currentPrice) {  
            msg.sender.transfer(msg.value-currentPrice);
        }
        userCrateCount[msg.sender] += 1;
        cratesSold++;
        incrementPrice();
        userToRobots[msg.sender].push(genRandom());
        LogCratePurchase(msg.sender, msg.value, 1);

    }

     
     
     
     
     
     
     
     
     
     
     
    function genRandom() private view returns (uint) {
        uint rand = uint(keccak256(block.blockhash(block.number-1)));
        return uint(rand % (10 ** 20));
    }

     
    function withdraw() onlyOwner public {
        owner.transfer(this.balance);
    }
}