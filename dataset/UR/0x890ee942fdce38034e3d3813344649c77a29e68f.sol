 

pragma solidity ^0.4.21;

 
contract LemonToken {
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

contract LemonSelfDrop1 is Ownable {
    LemonToken public LemonContract;
    uint8 public dropNumber;
    uint256 public LemonsDroppedToTheWorld;
    uint256 public LemonsRemainingToDrop;
    uint256 public holderAmount;
    uint256 public basicReward;
    uint256 public holderReward;
    mapping (uint8 => uint256[]) donatorReward;
    uint8 donatorRewardLevels;
    uint8 public totalDropTransactions;
    mapping (address => uint8) participants;
    
    
     
    function LemonSelfDrop1 () {
        address c = 0x2089899d03607b2192afb2567874a3f287f2f1e4; 
        LemonContract = LemonToken(c); 
        dropNumber = 1;
        LemonsDroppedToTheWorld = 0;
        LemonsRemainingToDrop = 0;
        basicReward = 500;
       donatorRewardLevels = 1;
        totalDropTransactions = 0;
    }
    
    
     
    function() payable {
        require (participants[msg.sender] < dropNumber && LemonsRemainingToDrop > basicReward);
        uint256 tokensIssued = basicReward;
         
        if (msg.value > donatorReward[0][0])
            tokensIssued += donatorBonus(msg.value);
         
        if (LemonContract.balanceOf(msg.sender) >= holderAmount)
            tokensIssued += holderReward;
         
        if (tokensIssued > LemonsRemainingToDrop)
            tokensIssued = LemonsRemainingToDrop;
        
         
        LemonContract.transfer(msg.sender, tokensIssued);
        participants[msg.sender] = dropNumber;
        LemonsRemainingToDrop -= tokensIssued;
        LemonsDroppedToTheWorld += tokensIssued;
        totalDropTransactions += 1;
    }
    
    
    function participant(address part) public constant returns (uint8 participationCount) {
        return participants[part];
    }
    
    
     
    function setDropNumber(uint8 dropN) public onlyOwner {
        dropNumber = dropN;
        LemonsRemainingToDrop = LemonContract.balanceOf(this);
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
        LemonContract.transfer(owner, LemonContract.balanceOf(this));
        LemonsRemainingToDrop = 0;
    }
    
    
     
    function withdrawToken(address token) public onlyOwner {
        Token(token).transfer(owner, Token(token).balanceOf(this));
    }
    
    
    function updateKittenCoinsRemainingToDrop() public {
        LemonsRemainingToDrop = LemonContract.balanceOf(this);
    }
    
    
     
    function donatorBonus(uint256 amount) public returns (uint256) {
        for(uint8 i = 1; i < donatorRewardLevels; i++) {
            if(amount < donatorReward[i][0])
                return (donatorReward[i-1][1]);
        }
        return (donatorReward[i-1][1]);
    }
    
}