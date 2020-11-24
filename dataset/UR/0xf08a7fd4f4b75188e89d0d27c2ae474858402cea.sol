 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }
}

 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

 
interface  Token {
 function transfer(address _to, uint256 _value) public returns (bool);
 function balanceOf(address _owner) public constant returns(uint256 balance);
}

contract DroneShowCoinICOContract is Ownable {
    
    using SafeMath for uint256;
    
    Token token;
    
    uint256 public constant RATE = 650;  
    uint256 public constant CAP = 15000;  
    uint256 public constant START = 1510754400;  
    uint256 public constant DAYS = 30;  
    
    bool public initialized = false;
    uint256 public raisedAmount = 0;
    uint256 public bonusesGiven = 0;
    uint256 public numberOfTransactions = 0;
    
    event BoughtTokens(address indexed to, uint256 value);
    
    modifier whenSaleIsActive() {
        assert (isActive());
        _;
    }
    
    function DroneShowCoinICOContract(address _tokenAddr) public {
        require(_tokenAddr != 0);
        token = Token(_tokenAddr);
    }
    
    function initialize(uint256 numTokens) public onlyOwner {
        require (initialized == false);
        require (tokensAvailable() == numTokens);
        initialized = true;
    }
    
    function isActive() public constant returns (bool) {
        return (
            initialized == true &&   
            now >= START &&  
            now <= START.add(DAYS * 1 days) &&  
            goalReached() == false  
        );  
    }
    
    function goalReached() public constant returns (bool) {
        return (raisedAmount >= CAP * 1 ether);
    }
    
    function () public payable {
        buyTokens();
    }
    
    function buyTokens() public payable whenSaleIsActive {
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(RATE);
        
        uint256 secondspassed = now - START;
        uint256 dayspassed = secondspassed/(60*60*24);
        uint256 bonusPrcnt = 0;
        if (dayspassed < 7) {
             
            bonusPrcnt = 20;
        } else if (dayspassed < 14) {
             
            bonusPrcnt = 10;
        } else {
             
            bonusPrcnt = 0;
        }
        uint256 bonusAmount = (tokens * bonusPrcnt) / 100;
        tokens = tokens.add(bonusAmount);
        BoughtTokens(msg.sender, tokens);
        
        raisedAmount = raisedAmount.add(msg.value);
        bonusesGiven = bonusesGiven.add(bonusAmount);
        numberOfTransactions = numberOfTransactions.add(1);
        token.transfer(msg.sender, tokens);
        
        owner.transfer(msg.value);
        
    }
    
    function tokensAvailable() public constant returns (uint256) {
        return token.balanceOf(this);
    }
    
    function destroy() public onlyOwner {
        uint256 balance = token.balanceOf(this);
        assert (balance > 0);
        token.transfer(owner,balance);
        selfdestruct(owner);
        
    }
}