 

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

 
contract AdsharesToken is StandardToken {
    using SafeMath for uint;

     
    string public constant name = "Adshares Token";
    string public constant symbol = "ADST";
    uint public constant decimals = 0;
    
     
    uint public constant tokenCreationMin = 10000000;
    uint public constant tokenPriceMin = 0.0004 ether;
    uint public constant tradeSpreadInvert = 50;  
    uint public constant crowdsaleEndLockTime = 1 weeks;
    uint public constant fundingUnlockPeriod = 1 weeks;
    uint public constant fundingUnlockFractionInvert = 100;  
    
     
    uint public crowdsaleStartBlock;
    address public owner1;
    address public owner2;
    address public withdrawAddress;  

    
     
    bool public minFundingReached;
    uint public crowdsaleEndDeclarationTime = 0;
    uint public fundingUnlockTime = 0;  
    uint public unlockedBalance = 0;  
    uint public withdrawnBalance = 0;
    bool public isHalted = false;

     
    event LogBuy(address indexed who, uint tokens, uint purchaseValue, uint supplyAfter);
    event LogSell(address indexed who, uint tokens, uint saleValue, uint supplyAfter);
    event LogWithdraw(uint amount);
    event LogCrowdsaleEnd(bool completed);    
    
     
    modifier fundingActive() {
       
      if (block.number < crowdsaleStartBlock) {
        throw;
      }
       
      if (crowdsaleEndDeclarationTime > 0 && block.timestamp > crowdsaleEndDeclarationTime + crowdsaleEndLockTime) {
          throw;
        }
      _;
    }
    
     
    modifier onlyOwner() {
      if (msg.sender != owner1 && msg.sender != owner2) {
        throw;
      }
      _;
    }
    
     
    function AdsharesToken (address _owner1, address _owner2, address _withdrawAddress, uint _crowdsaleStartBlock)
    {
        owner1 = _owner1;
        owner2 = _owner2;
        withdrawAddress = _withdrawAddress;
        crowdsaleStartBlock = _crowdsaleStartBlock;
    }
    
     
    function getLockedBalance() private constant returns (uint lockedBalance) {
        return this.balance.sub(unlockedBalance);
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
    
     
    function getSellPrice(uint _askSizeTokens) constant returns (uint saleValue) {
        
        uint flatTokenCount;
        uint linearTokenMin;
        
        if(totalSupply <= tokenCreationMin) {
            return tokenPriceMin * _askSizeTokens;
        }
        if(totalSupply.sub(_askSizeTokens) < tokenCreationMin) {
            flatTokenCount = tokenCreationMin - totalSupply.sub(_askSizeTokens);
            linearTokenMin = tokenCreationMin;
        } else {
            flatTokenCount = 0;
            linearTokenMin = totalSupply.sub(_askSizeTokens);
        }
        uint linearTokenCount = _askSizeTokens - flatTokenCount;
        
        uint minPrice = (linearTokenMin).mul(tokenPriceMin).div(tokenCreationMin);
        uint maxPrice = (totalSupply+1).mul(tokenPriceMin).div(tokenCreationMin);
        
        uint linearAveragePrice = minPrice.add(maxPrice).div(2);
        return linearAveragePrice.mul(linearTokenCount).add(flatTokenCount.mul(tokenPriceMin));
    }
    
     
    function() payable fundingActive
    {
        buyLimit(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }
    
     
    function buy() payable external fundingActive {
        buyLimit(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);    
    }
    
     
    function buyLimit(uint _maxPrice) payable public fundingActive {
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
        
        if(!minFundingReached && totalSupply >= tokenCreationMin) {
            minFundingReached = true;
            fundingUnlockTime = block.timestamp;
             
            unlockedBalance += this.balance.sub(msg.value).div(tradeSpreadInvert);
        }
        if(minFundingReached) {
            unlockedBalance += purchaseValue.div(tradeSpreadInvert);
        }
        
        LogBuy(msg.sender, boughtTokens, purchaseValue, totalSupply);
        
        if(msg.value > purchaseValue) {
            msg.sender.transfer(msg.value.sub(purchaseValue));
        }
    }
    
     
    function sell(uint _tokenCount) external fundingActive {
        sellLimit(_tokenCount, 0);
    }
    
     
    function sellLimit(uint _tokenCount, uint _minPrice) public fundingActive {
        require(_tokenCount > 0);

        assert(balances[msg.sender] >= _tokenCount);
        
        uint saleValue = getSellPrice(_tokenCount);
        uint averagePrice = saleValue.div(_tokenCount);
        assert(averagePrice >= tokenPriceMin);
        if(minFundingReached) {
            averagePrice -= averagePrice.div(tradeSpreadInvert);
            saleValue -= saleValue.div(tradeSpreadInvert);
        }
        
        if(averagePrice < _minPrice) {
             
            return;
        }
         
        assert(saleValue <= this.balance);
          
        totalSupply = totalSupply.sub(_tokenCount);
        balances[msg.sender] = balances[msg.sender].sub(_tokenCount);
        
        LogSell(msg.sender, _tokenCount, saleValue, totalSupply);
        
        msg.sender.transfer(saleValue);
    }   
    
     
    function unlockFunds() external onlyOwner fundingActive {
        assert(minFundingReached);
        assert(block.timestamp >= fundingUnlockTime);
        
        uint unlockedAmount = getLockedBalance().div(fundingUnlockFractionInvert);
        unlockedBalance += unlockedAmount;
        assert(getLockedBalance() > 0);
        
        fundingUnlockTime += fundingUnlockPeriod;
    }
    
     
    function withdrawFunds(uint _value) external onlyOwner fundingActive onlyPayloadSize(32) {
        require(_value <= unlockedBalance);
        assert(minFundingReached);
             
        unlockedBalance -= _value;
        withdrawnBalance += _value;
        LogWithdraw(_value);
        
        withdrawAddress.transfer(_value);
    }
    
     
    function declareCrowdsaleEnd() external onlyOwner fundingActive {
        assert(minFundingReached);
        assert(crowdsaleEndDeclarationTime == 0);
        
        crowdsaleEndDeclarationTime = block.timestamp;
        LogCrowdsaleEnd(false);
    }
    
     
    function confirmCrowdsaleEnd() external onlyOwner {
        assert(crowdsaleEndDeclarationTime > 0 && block.timestamp > crowdsaleEndDeclarationTime + crowdsaleEndLockTime);
        
        LogCrowdsaleEnd(true);
        withdrawAddress.transfer(this.balance);
    }
    
     
    function haltCrowdsale() external onlyOwner fundingActive {
        assert(!minFundingReached);
        isHalted = !isHalted;
    }
}