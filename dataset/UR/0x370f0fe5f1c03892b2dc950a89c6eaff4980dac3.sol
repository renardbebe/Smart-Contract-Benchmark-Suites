 

pragma solidity ^0.4.21;

 
contract KittenCoin {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract Token {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  function Ownable() {
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

contract KittenSelfDrop2 is Ownable {
    KittenCoin public kittenContract;
    uint8 public dropNumber;
    uint256 public kittensDroppedToTheWorld;
    uint256 public kittensRemainingToDrop;
    uint256 public holderAmount;
    uint256 public basicReward;
    uint256 public holderReward;
    mapping (uint8 => uint256[]) donatorReward;
    uint8 donatorRewardLevels;
    uint8 public totalDropTransactions;
    mapping (address => uint8) participants;
    
    
     
    function KittenSelfDrop2 () {
        address c = 0xac2BD14654BBf22F9d8f20c7b3a70e376d3436B4;  
        kittenContract = KittenCoin(c); 
        dropNumber = 1;
        kittensDroppedToTheWorld = 0;
        kittensRemainingToDrop = 0;
        basicReward = 50000000000;  
        holderReward = 50000000000;  
        holderAmount = 5000000000000;  
        donatorReward[0]=[1,10000000000];  
        donatorReward[1]=[1000000000000000,100000000000];  
        donatorReward[2]=[10000000000000000,500000000000];  
        donatorRewardLevels = 3;
        totalDropTransactions = 0;
    }
    
    
     
    function() payable {
        require (participants[msg.sender] < dropNumber && kittensRemainingToDrop > basicReward);
        uint256 tokensIssued = basicReward;
         
        if (msg.value > donatorReward[0][0])
            tokensIssued += donatorBonus(msg.value);
         
        if (kittenContract.balanceOf(msg.sender) >= holderAmount)
            tokensIssued += holderReward;
         
        if (tokensIssued > kittensRemainingToDrop)
            tokensIssued = kittensRemainingToDrop;
        
         
        kittenContract.transfer(msg.sender, tokensIssued);
        participants[msg.sender] = dropNumber;
        kittensRemainingToDrop -= tokensIssued;
        kittensDroppedToTheWorld += tokensIssued;
        totalDropTransactions += 1;
    }
    
    
    function participant(address part) public constant returns (uint8 participationCount) {
        return participants[part];
    }
    
    
     
    function setDropNumber(uint8 dropN) public onlyOwner {
        dropNumber = dropN;
        kittensRemainingToDrop = kittenContract.balanceOf(this);
    }
    
    
     
    function setHolderAmount(uint256 amount) public onlyOwner {
        holderAmount = amount;
    }
    
    
     
    function setRewards(uint256 basic, uint256 holder) public onlyOwner {
        basicReward = basic;
        holderReward = holder;
    }
    
     
    function setDonatorReward(uint8 index, uint256[] values, uint8 levels) public onlyOwner {
        donatorReward[index] = values;
        donatorRewardLevels = levels;
    }
    
     
    function withdrawAll() public onlyOwner {
        owner.transfer(this.balance);
    }
    
    
     
    function withdrawKittenCoins() public onlyOwner {
        kittenContract.transfer(owner, kittenContract.balanceOf(this));
        kittensRemainingToDrop = 0;
    }
    
    
     
    function withdrawToken(address token) public onlyOwner {
        Token(token).transfer(owner, Token(token).balanceOf(this));
    }
    
    
     
    function updateKittenCoinsRemainingToDrop() public {
        kittensRemainingToDrop = kittenContract.balanceOf(this);
    }
    
    
     
    function donatorBonus(uint256 amount) public returns (uint256) {
        for(uint8 i = 1; i < donatorRewardLevels; i++) {
            if(amount < donatorReward[i][0])
                return (donatorReward[i-1][1]);
        }
        return (donatorReward[i-1][1]);
    }
    
}