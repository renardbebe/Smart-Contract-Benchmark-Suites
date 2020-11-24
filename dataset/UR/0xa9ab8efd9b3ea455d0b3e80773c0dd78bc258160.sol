 

pragma solidity ^0.4.24;

 


contract suicidewatch {

    event stillKicking(
        uint amount
    );

    address lastAuthor;    

    uint public price = 0.01 ether;
    uint prevPrice = 0;
    uint increase = 25;   

    mapping (uint => string) messages;

    uint public messageCount = 0;
    

    uint public ownerAccount = 0;
 
    string public storage_;

    address owner;
    
    constructor() public {
        owner = msg.sender;
        lastAuthor = owner;
        storage_ = "YOUR MESSAGE GOES HERE";
    }

    function buyMessage(string s) public payable
    {

        require(msg.value >= price);
        uint ownerFee;
        uint authorFee;
        uint priceGain;
        
        if (price > 0.01 ether) {
            priceGain = SafeMath.sub(price, prevPrice);
            ownerFee = SafeMath.div(SafeMath.mul(priceGain,50),100);
            authorFee = ownerFee;
        } else {
            priceGain = SafeMath.sub(price, prevPrice);
            ownerFee = priceGain;
            authorFee = 0;
        }

        ownerAccount = SafeMath.add(ownerAccount, ownerFee);
       

        if (price > 0.01 ether){
            lastAuthor.transfer(authorFee + prevPrice);
        }

        prevPrice = price;
        
        price = SafeMath.div(SafeMath.mul(125,price),100);

        lastAuthor = msg.sender;
        
        store_message(s);

        messages[messageCount] = s;
        messageCount += 1;
        
    }

    function store_message(string s) internal {

        storage_ = s;
    }

    function ownerWithdraw() 
    {
        require(msg.sender == owner);
        uint tempAmount = ownerAccount;
        ownerAccount = 0;
        owner.transfer(tempAmount);
        emit stillKicking(tempAmount);
    }

    function getMessages(uint messageNum) view public returns(string)

    {
        return(messages[messageNum]);
    }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}