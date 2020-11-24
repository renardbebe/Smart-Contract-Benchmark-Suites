 

pragma solidity ^0.4.11;

 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
  
   
  function sqrt(uint num) internal returns (uint) {
    if (0 == num) {  
      return 0; 
    }   
    uint n = (num / 2) + 1;       
    uint n1 = (n + (num / n)) / 2;  
    while (n1 < n) {  
      n = n1;  
      n1 = (n + (num / n)) / 2;  
    }  
    return n;  
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract CryptoMastersToken is StandardToken {
     
    string public constant name = "Crypto Masters Token";
    string public constant symbol = "CMS";
    uint public constant decimals = 0;
     
    uint public constant tokenCreationMin = 1000000;
    uint public constant tokenPriceMin = 0.0004 ether;
     
    address public owner1;
    address public owner2;
     
    uint public EthersRaised = 0;
    bool public isHalted = false;
     
    event LogBuy(address indexed who, uint tokens, uint EthersValue, uint supplyAfter);  
     
    modifier onlyOwner() {
      if (msg.sender != owner1 && msg.sender != owner2) {
        throw;
      }
      _;
    }
     
    function transferOwnership1(address newOwner1) onlyOwner {
     require(newOwner1 != address(0));      
     owner1 = newOwner1;
    }
    function transferOwnership2(address newOwner2) onlyOwner {
      require(newOwner2 != address(0));      
      owner2 = newOwner2;
    } 
     
    function CryptoMastersToken() {
        owner1 = msg.sender;
        owner2 = msg.sender;
    }
     
    function getBuyPrice(uint _bidValue) constant returns (uint tokenCount, uint purchaseValue) {

         
         

        uint flatTokenCount;
        uint startSupply;
        uint linearBidValue;
        
        if(totalSupply < tokenCreationMin) {
            uint maxFlatTokenCount = _bidValue.div(tokenPriceMin);
             
            if(totalSupply.add(maxFlatTokenCount) <= tokenCreationMin) {
                return (maxFlatTokenCount, maxFlatTokenCount.mul(tokenPriceMin));
            }
            flatTokenCount = tokenCreationMin.sub(totalSupply);
            linearBidValue = _bidValue.sub(flatTokenCount.mul(tokenPriceMin));
            startSupply = tokenCreationMin;
        } else {
            flatTokenCount = 0;
            linearBidValue = _bidValue;
            startSupply = totalSupply;
        }
        
         
        uint currentPrice = tokenPriceMin.mul(startSupply).div(tokenCreationMin);
        uint delta = (2 * startSupply).mul(2 * startSupply).add(linearBidValue.mul(4 * 1 * 2 * startSupply).div(currentPrice));

        uint linearTokenCount = delta.sqrt().sub(2 * startSupply).div(2);
        uint linearAvgPrice = currentPrice.add((startSupply+linearTokenCount+1).mul(tokenPriceMin).div(tokenCreationMin)).div(2);
        
         
        linearTokenCount = linearBidValue / linearAvgPrice;
        linearAvgPrice = currentPrice.add((startSupply+linearTokenCount+1).mul(tokenPriceMin).div(tokenCreationMin)).div(2);
        
        purchaseValue = linearTokenCount.mul(linearAvgPrice).add(flatTokenCount.mul(tokenPriceMin));
        return (
            flatTokenCount + linearTokenCount,
            purchaseValue
        );
     }
    
     
    function() payable {
        BuyLimit(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }
    
     
    function Buy() payable external {
        BuyLimit(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);    
    }
    
     
    function BuyLimit(uint _maxPrice) payable public {
        require(msg.value >= tokenPriceMin);
        assert(!isHalted);
        
        uint boughtTokens;
        uint averagePrice;
        uint purchaseValue;
        
        (boughtTokens, purchaseValue) = getBuyPrice(msg.value);
        if(boughtTokens == 0) { 
             
            msg.sender.transfer(msg.value);
            return; 
        }
        averagePrice = purchaseValue.div(boughtTokens);
        if(averagePrice > _maxPrice) { 
             
            msg.sender.transfer(msg.value);
            return; 
        }
        assert(averagePrice >= tokenPriceMin);
        assert(purchaseValue <= msg.value);
        
        totalSupply = totalSupply.add(boughtTokens);
        balances[msg.sender] = balances[msg.sender].add(boughtTokens);
      
        LogBuy(msg.sender, boughtTokens, purchaseValue.div(1000000000000000000), totalSupply);
        
        if(msg.value > purchaseValue) {
            msg.sender.transfer(msg.value.sub(purchaseValue));
        }  
        EthersRaised += purchaseValue;
    }
     
    function withdrawAllFunds() external onlyOwner { 
        msg.sender.transfer(this.balance);
    }
    function withdrawFunds(uint _amount) external onlyOwner { 
        require(_amount <= this.balance);
        msg.sender.transfer(_amount);
    }
     
    function haltCrowdsale() external onlyOwner {
        isHalted = !isHalted;
    }
}