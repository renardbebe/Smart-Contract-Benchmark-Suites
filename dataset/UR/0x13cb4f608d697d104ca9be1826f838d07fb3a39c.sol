 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
  function transfer(address to, uint256 value) internal returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) tokenBalances;

   
  function transfer(address _to, uint256 _value) internal returns (bool) {
     
     
    return false;
  }

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return tokenBalances[_owner];
  }

}
contract HareemMinePoolToken is BasicToken, Ownable {

   using SafeMath for uint256;
   string public constant name = "HareemMinePool";
   string public constant symbol = "HMP";
   uint256 public constant decimals = 18;

   uint256 constant INITIAL_SUPPLY = 1000 * (10 ** uint256(decimals));
   uint256 public sellPrice = 2;  
   uint256 public buyPrice = 1; 
  
   string public constant COLLATERAL_HELD = "1000 ETH";
   uint payout_worth = 0;
   
   event Debug(string message, uint256 num);
   
   mapping(address => uint256) amountLeftToBePaid;
   mapping(address => uint256) partialAmtToBePaid;
   
   address[] listAddr;
   
    
   address ethStore = 0x66Ef84EE378B07012FE44Df83b64Ea2Ae35fD09b;   
   address exchange = 0x093af86909F7E2135aD764e9cB384Ed7311799d3;
   
   uint perTokenPayout = 0;
   uint tokenToTakeBack = 0;
   
   event addr(string message, address sender);
   event logString(string message);
   
    
    function () public payable {
    buy(msg.sender);
    }
  
     
    function HareemMinePoolToken() public {
    owner = ethStore;
    totalSupply = INITIAL_SUPPLY;
    tokenBalances[owner] = INITIAL_SUPPLY;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
  
    function payoutWorth(address beneficiary) constant public returns (uint amount) {
        amount = tokenBalances[beneficiary].mul(sellPrice);
    }
    
    function tokensLeft() public view returns (uint amount) {
        amount = tokenBalances[owner];
    }
    
    function payoutLeft() internal constant returns (uint amount) {
        for (uint i=0;i<listAddr.length;i++)
        {
            amount = amount + amountLeftToBePaid[listAddr[i]];
        }
        return amount;
    }
    function doPayout() payable public onlyOwner{
      uint payLeft = payoutLeft();
      uint cashBack = msg.value;
      require (payLeft>0 && cashBack <=payLeft);
      uint soldTokens = totalSupply.sub(tokenBalances[owner]);
      cashBack = cashBack.mul(10**18);
      perTokenPayout =cashBack.div(soldTokens);
      tokenToTakeBack = perTokenPayout.div(sellPrice);
      makePayments();
    }
    
    function makePayments() internal {
        uint exchangeAmount;
        uint customerAmt;
        for (uint i=0;i<listAddr.length;i++)
        {
            uint payAmt = amountLeftToBePaid[listAddr[i]];
            if (payAmt >0)
            {
                uint tokensHeld = payAmt.div(sellPrice);
                if (tokensHeld >0)
                {
                    uint sendMoney = tokensHeld.mul(perTokenPayout);
                    sendMoney = sendMoney.div(10**decimals);
                    uint takeBackTokens = tokenToTakeBack.mul(tokensHeld);
                    takeBackTokens = takeBackTokens.div(10**decimals);
                    (exchangeAmount,customerAmt) = getExchangeAndEthStoreAmount(sendMoney); 
                    exchange.transfer(exchangeAmount);
                    listAddr[i].transfer(customerAmt);
                    amountLeftToBePaid[listAddr[i]] = amountLeftToBePaid[listAddr[i]].sub(sendMoney);
                    tokenBalances[listAddr[i]] = tokenBalances[listAddr[i]].sub(takeBackTokens);
                    tokenBalances[owner] = tokenBalances[owner].add(takeBackTokens);
                    Transfer(listAddr[i],owner, takeBackTokens); 
                    takeBackTokens = takeBackTokens.div(10**decimals);
                }
            }
        }
    }
    
    function buy(address beneficiary) payable public returns (uint amount) {
        require (msg.value >= 10 ** decimals);    
        uint exchangeAmount;
        uint ethStoreAmt;
        (exchangeAmount,ethStoreAmt) = getExchangeAndEthStoreAmount(msg.value); 
        ethStore.transfer(ethStoreAmt);    
        exchange.transfer(exchangeAmount);
        uint tempBuyPrice = buyPrice.mul(10**decimals);
        amount = msg.value.div(tempBuyPrice);                     
        amount = amount.mul(10**decimals);
        require(tokenBalances[owner] >= amount);                
        tokenBalances[beneficiary] = tokenBalances[beneficiary].add(amount);                   
        tokenBalances[owner] = tokenBalances[owner].sub(amount);                         
        amountLeftToBePaid[beneficiary] = amount.mul(sellPrice);    
        Transfer(owner, beneficiary, amount);
        listAddr.push(beneficiary);
        return amount;                                     
    }
   
   function getExchangeAndEthStoreAmount(uint value) internal pure returns (uint exchangeAmt, uint ethStoreAmt) {
       exchangeAmt = value.div(100);     
       ethStoreAmt = value - exchangeAmt;    
   }
}