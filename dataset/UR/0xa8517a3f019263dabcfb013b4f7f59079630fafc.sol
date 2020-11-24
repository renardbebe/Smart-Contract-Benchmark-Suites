 

pragma solidity ^0.4.11;
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) tokenBalances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(tokenBalances[msg.sender]>=_value);
    tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return tokenBalances[_owner];
  }
  
}

contract RevolutionCoin is BasicToken,Ownable {

   using SafeMath for uint256;
   
   string public constant name = "R-evolutioncoin";
   string public constant symbol = "RVL";
   uint256 public constant decimals = 18;
   uint256 public preIcoBuyPrice = 222222222222222;    
   uint256 public IcoPrice = 1000000000000000;
   uint256 public bonusPhase1 = 30;
   uint256 public bonusPhase2 = 20;
   uint256 public bonusPhase3 = 10;
   uint256 public TOKENS_SOLD;
  
   address public ethStore = 0xDd64EF0c8a41d8a17F09ce2279D79b3397184A10;
   uint256 public constant INITIAL_SUPPLY = 100000000;
   event Debug(string message, address addr, uint256 number);
   event log(string message, uint256 number);
    
    
    function RevolutionCoin() public {
        owner = ethStore;
        totalSupply = INITIAL_SUPPLY;
        tokenBalances[ethStore] = INITIAL_SUPPLY * (10 ** uint256(decimals));    
        TOKENS_SOLD = 0;
    }
    
    
     
      function () public payable {
        
        buy(msg.sender);
    }
    
    function calculateTokens(uint amt) internal returns (uint tokensYouCanGive, uint returnAmount) {
        uint bonus = 0;
        uint tokensRequired = 0;
        uint tokensWithoutBonus = 0;
        uint priceCharged = 0;
        
         
        if (TOKENS_SOLD <4500000)
        {
            tokensRequired = amt.div(preIcoBuyPrice);
            if (tokensRequired + TOKENS_SOLD > 4500000)
            {
                tokensYouCanGive = 4500000 - TOKENS_SOLD;
                returnAmount = tokensRequired - tokensYouCanGive;
                returnAmount = returnAmount.mul(preIcoBuyPrice);
                log("Tokens being bought exceed the limit of pre-ico. Returning remaining amount",returnAmount);
            }
            else
            {
                tokensYouCanGive = tokensRequired;
                returnAmount = 0;
            }
            require (tokensYouCanGive + TOKENS_SOLD <= 4500000);
        }
         
        else if (TOKENS_SOLD >=4500000 && TOKENS_SOLD <24000000)
        {
             tokensRequired = amt.div(IcoPrice);
             bonus = tokensRequired.mul(bonusPhase1);
             bonus = bonus.div(100);
             tokensRequired = tokensRequired.add(bonus);
             if (tokensRequired + TOKENS_SOLD > 24000000)
             {
                tokensYouCanGive = 24000000 - TOKENS_SOLD;
                tokensWithoutBonus = tokensYouCanGive.mul(10);
                tokensWithoutBonus = tokensWithoutBonus.div(13);
                
                priceCharged = tokensWithoutBonus.mul(IcoPrice); 
                returnAmount = amt - priceCharged;
                
                log("Tokens being bought exceed the limit of ico phase 1. Returning remaining amount",returnAmount);
             }
             else
            {
                tokensYouCanGive = tokensRequired;
                returnAmount = 0;
            }
            require (tokensYouCanGive + TOKENS_SOLD <= 24000000);
        }
         
        if (TOKENS_SOLD >=24000000 && TOKENS_SOLD <42000000)
        {
             tokensRequired = amt.div(IcoPrice);
             bonus = tokensRequired.mul(bonusPhase2);
             bonus = bonus.div(100);
             tokensRequired = tokensRequired.add(bonus);
             if (tokensRequired + TOKENS_SOLD > 42000000)
             {
                tokensYouCanGive = 42000000 - TOKENS_SOLD;
                tokensWithoutBonus = tokensYouCanGive.mul(10);
                tokensWithoutBonus = tokensWithoutBonus.div(13);
                
                priceCharged = tokensWithoutBonus.mul(IcoPrice); 
                returnAmount = amt - priceCharged;
                log("Tokens being bought exceed the limit of ico phase 2. Returning remaining amount",returnAmount);
             }
              else
            {
                tokensYouCanGive = tokensRequired;
                returnAmount = 0;
            }
             require (tokensYouCanGive + TOKENS_SOLD <= 42000000);
        }
         
        if (TOKENS_SOLD >=42000000 && TOKENS_SOLD <58500000)
        {
             tokensRequired = amt.div(IcoPrice);
             bonus = tokensRequired.mul(bonusPhase3);
             bonus = bonus.div(100);
             tokensRequired = tokensRequired.add(bonus);
              if (tokensRequired + TOKENS_SOLD > 58500000)
             {
                tokensYouCanGive = 58500000 - TOKENS_SOLD;
                tokensWithoutBonus = tokensYouCanGive.mul(10);
                tokensWithoutBonus = tokensWithoutBonus.div(13);
                
                priceCharged = tokensWithoutBonus.mul(IcoPrice); 
                returnAmount = amt - priceCharged;
                log("Tokens being bought exceed the limit of ico phase 3. Returning remaining amount",returnAmount);
             }
            else
            {
                tokensYouCanGive = tokensRequired;
                returnAmount = 0;
            }
             require (tokensYouCanGive + TOKENS_SOLD <= 58500000);
        }
        if (TOKENS_SOLD == 58500000)
        {
            log("ICO has ended. All tokens sold.", 58500000);
            tokensYouCanGive = 0;
            returnAmount = amt;
        }
        require(TOKENS_SOLD <=58500000);
    }
    
    function buy(address beneficiary) payable public returns (uint tokens) {
        uint paymentToGiveBack = 0;
        (tokens,paymentToGiveBack) = calculateTokens(msg.value);
        
        TOKENS_SOLD += tokens;
        tokens = tokens * (10 ** uint256(decimals));
        
        require(tokenBalances[owner] >= tokens);                
        
        tokenBalances[beneficiary] = tokenBalances[beneficiary].add(tokens);                   
        tokenBalances[owner] = tokenBalances[owner].sub(tokens);                         
        
        Transfer(owner, beneficiary, tokens);                
    
        if (paymentToGiveBack >0)
        {
            beneficiary.transfer(paymentToGiveBack);
        }
    
        ethStore.transfer(msg.value - paymentToGiveBack);                        
        
        return tokens;                                     
    }
    
   function getTokenBalance(address yourAddress) constant public returns (uint256 balance) {
        return tokenBalances[yourAddress].div (10**decimals);  
    }
}