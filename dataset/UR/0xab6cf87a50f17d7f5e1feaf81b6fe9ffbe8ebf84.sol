 

pragma solidity ^0.4.11;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
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

}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  modifier onlyPayloadSize(uint256 size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract HasNoTokens is Ownable {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    throw;
  }

   
  function reclaimToken(address tokenAddr) external onlyOwner {
    ERC20Basic tokenInst = ERC20Basic(tokenAddr);
    uint256 balance = tokenInst.balanceOf(this);
    tokenInst.transfer(owner, balance);
  }
}

 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

 
contract MRVToken is StandardToken, Ownable, HasNoTokens, HasNoContracts {

     

     
    
     
    string public constant name = "Macroverse Token";
     
    string public constant symbol = "MRV";
     
     
     
    uint8 public decimals;
    
     
    
     
    address beneficiary;
     
    uint public maxCrowdsaleSupplyInWholeTokens;
     
    uint public constant wholeTokensReserved = 5000;
     
    uint public constant wholeTokensPerEth = 5000;
    
     
     
    bool crowdsaleStarted;
     
     
    bool crowdsaleEnded;
     
     
    uint public openTimer = 0;
     
    uint public closeTimer = 0;
    
     
     
     
    
     
    function MRVToken(address sendProceedsTo, address sendTokensTo) {
         
        beneficiary = sendProceedsTo;
        
         
        decimals = 18;
        
         
        totalSupply = wholeTokensReserved * 10 ** 18;
        balances[sendTokensTo] = totalSupply;
        
         
        crowdsaleStarted = false;
        crowdsaleEnded = false;
         
        maxCrowdsaleSupplyInWholeTokens = 100000000;
    }
    
     
     
     
    
     
    function() payable onlyDuringCrowdsale {
        createTokens(msg.sender);
    }
    
     
     
     
    
     
    event CrowdsaleOpen(uint time);
     
    event TokenPurchase(uint time, uint etherAmount, address from);
     
    event CrowdsaleClose(uint time);
     
    event DecimalChange(uint8 newDecimals);
    
     
     
     
    
     
    modifier onlyBeforeClosed {
        checkCloseTimer();
        if (crowdsaleEnded) throw;
        _;
    }
    
     
    modifier onlyAfterClosed {
        checkCloseTimer();
        if (!crowdsaleEnded) throw;
        _;
    }
    
     
    modifier onlyBeforeOpened {
        checkOpenTimer();
        if (crowdsaleStarted) throw;
        _;
    }
    
     
    modifier onlyDuringCrowdsale {
        checkOpenTimer();
        checkCloseTimer();
        if (crowdsaleEnded) throw;
        if (!crowdsaleStarted) throw;
        _;
    }

     
     
     
    
     
    function openTimerElapsed() constant returns (bool) {
        return (openTimer != 0 && now > openTimer);
    }
    
     
    function closeTimerElapsed() constant returns (bool) {
        return (closeTimer != 0 && now > closeTimer);
    }
    
     
    function checkOpenTimer() {
        if (openTimerElapsed()) {
            crowdsaleStarted = true;
            openTimer = 0;
            CrowdsaleOpen(now);
        }
    }
    
     
    function checkCloseTimer() {
        if (closeTimerElapsed()) {
            crowdsaleEnded = true;
            closeTimer = 0;
            CrowdsaleClose(now);
        }
    }
    
     
    function isCrowdsaleActive() constant returns (bool) {
         
        return ((crowdsaleStarted || openTimerElapsed()) && !(crowdsaleEnded || closeTimerElapsed()));
    }
    
     
     
     
    
     
    function setMaxSupply(uint newMaxInWholeTokens) onlyOwner onlyBeforeOpened {
        maxCrowdsaleSupplyInWholeTokens = newMaxInWholeTokens;
    }
    
     
    function openCrowdsale() onlyOwner onlyBeforeOpened {
        crowdsaleStarted = true;
        openTimer = 0;
        CrowdsaleOpen(now);
    }
    
     
    function setCrowdsaleOpenTimerFor(uint minutesFromNow) onlyOwner onlyBeforeOpened {
        openTimer = now + minutesFromNow * 1 minutes;
    }
    
     
    function clearCrowdsaleOpenTimer() onlyOwner onlyBeforeOpened {
        openTimer = 0;
    }
    
     
    function setCrowdsaleCloseTimerFor(uint minutesFromNow) onlyOwner onlyBeforeClosed {
        closeTimer = now + minutesFromNow * 1 minutes;
    }
    
     
    function clearCrowdsaleCloseTimer() onlyOwner onlyBeforeClosed {
        closeTimer = 0;
    }
    
    
     
     
     
    
     
    function createTokens(address recipient) internal onlyDuringCrowdsale {
        if (msg.value == 0) {
            throw;
        }

        uint tokens = msg.value.mul(wholeTokensPerEth);  
        
        var newTotalSupply = totalSupply.add(tokens);
        
        if (newTotalSupply > (wholeTokensReserved + maxCrowdsaleSupplyInWholeTokens) * 10 ** 18) {
             
             
            throw;
        }
        
         
        totalSupply = newTotalSupply;
        balances[recipient] = balances[recipient].add(tokens);
        
         
        TokenPurchase(now, msg.value, recipient);

         
         
         
        if (!beneficiary.send(msg.value)) {
            throw;
        }
    }
    
     
    function closeCrowdsale() onlyOwner onlyDuringCrowdsale {
        crowdsaleEnded = true;
        closeTimer = 0;
        CrowdsaleClose(now);
    }  
    
     
     
     
    
     
    function setDecimals(uint8 newDecimals) onlyOwner onlyAfterClosed {
        decimals = newDecimals;
         
        DecimalChange(decimals);
    }
    
     
    function reclaimEther() external onlyOwner {
         
        assert(owner.send(this.balance));
    }

}