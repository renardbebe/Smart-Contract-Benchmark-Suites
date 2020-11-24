 

pragma solidity ^0.4.11;

 
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
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

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract StandardToken is ERC20, SafeMath {

  mapping (address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
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

 
contract MoedaToken is StandardToken, Ownable {
    string public constant name = "Moeda Loyalty Points";
    string public constant symbol = "MDA";
    uint8 public constant decimals = 18;

     
    uint public constant MAX_TOKENS = 20000000 ether;
    
     
    bool public saleActive;

     
    event Created(address indexed donor, uint256 tokensReceived);

     
    modifier onlyAfterSale() {
        if (saleActive) {
            throw;
        }
        _;
    }

    modifier onlyDuringSale() {
        if (!saleActive) {
            throw;
        }
        _;
    }

     
    function MoedaToken() {
        saleActive = true;
    }

     
    function unlock() onlyOwner {
        saleActive = false;
    }

     
     
     
    function create(address recipient, uint256 amount)
    onlyOwner onlyDuringSale {
        if (amount == 0) throw;
        if (safeAdd(totalSupply, amount) > MAX_TOKENS) throw;

        balances[recipient] = safeAdd(balances[recipient], amount);
        totalSupply = safeAdd(totalSupply, amount);

        Created(recipient, amount);
    }

     
     
    function transfer(address _to, uint _value) onlyAfterSale returns (bool) {
        return super.transfer(_to, _value);
    }

     
     
    function transferFrom(address from, address to, uint value) onlyAfterSale 
    returns (bool)
    {
        return super.transferFrom(from, to, value);
    }
}

 
contract Crowdsale is Ownable, SafeMath {
    bool public crowdsaleClosed;         
                                         
    address public wallet;               
    MoedaToken public moedaToken;        
    uint256 public etherReceived;        
    uint256 public totalTokensSold;      
    uint256 public startBlock;           
    uint256 public endBlock;             

     
    uint256 public constant TOKEN_MULTIPLIER = 10 ** 18;

     
    uint256 public constant PRESALE_TOKEN_ALLOCATION = 5000000 * TOKEN_MULTIPLIER;

     
    address public PRESALE_WALLET = "0x30B3C64d43e7A1E8965D934Fa96a3bFB33Eee0d2";
    
     
    uint256 public constant DUST_LIMIT = 1 finney;

     
    uint256 public constant TIER1_RATE = 160;
    uint256 public constant TIER2_RATE = 125;
    uint256 public constant TIER3_RATE = 80;

     
    uint256 public constant TIER1_CAP =  31250 ether;
    uint256 public constant TIER2_CAP =  71250 ether;
    uint256 public constant TIER3_CAP = 133750 ether;  

     
    event Purchase(address indexed donor, uint256 amount, uint256 tokenAmount);

     
    event TokenDrain(address token, address to, uint256 amount);

    modifier onlyDuringSale() {
        if (crowdsaleClosed) {
            throw;
        }

        if (block.number < startBlock) {
            throw;
        }

        if (block.number >= endBlock) {
            throw;
        }
        _;
    }

     
     
     
     
    function Crowdsale(address _wallet, uint _startBlock, uint _endBlock) {
        if (_wallet == address(0)) throw;
        if (_startBlock <= block.number) throw;
        if (_endBlock <= _startBlock) throw;
        
        crowdsaleClosed = false;
        wallet = _wallet;
        moedaToken = new MoedaToken();
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

     
     
     
     
    function getLimitAndPrice(uint256 totalReceived)
    constant returns (uint256, uint256) {
        uint256 limit = 0;
        uint256 price = 0;

        if (totalReceived < TIER1_CAP) {
            limit = TIER1_CAP;
            price = TIER1_RATE;
        }
        else if (totalReceived < TIER2_CAP) {
            limit = TIER2_CAP;
            price = TIER2_RATE;
        }
        else if (totalReceived < TIER3_CAP) {
            limit = TIER3_CAP;
            price = TIER3_RATE;
        } else {
            throw;  
        }

        return (limit, price);
    }

     
     
     
     
     
     
    function getTokenAmount(uint256 totalReceived, uint256 requestedAmount) 
    constant returns (uint256) {

         
        if (requestedAmount == 0) return 0;
        uint256 limit = 0;
        uint256 price = 0;
        
         
        (limit, price) = getLimitAndPrice(totalReceived);

         
         
         
         
        uint256 maxETHSpendableInTier = safeSub(limit, totalReceived);
        uint256 amountToSpend = min256(maxETHSpendableInTier, requestedAmount);

         
         
        uint256 tokensToReceiveAtCurrentPrice = safeMul(amountToSpend, price);

         
         
        uint256 additionalTokens = getTokenAmount(
            safeAdd(totalReceived, amountToSpend),
            safeSub(requestedAmount, amountToSpend));

        return safeAdd(tokensToReceiveAtCurrentPrice, additionalTokens);
    }

     
     
    function () payable onlyDuringSale {
        if (msg.value < DUST_LIMIT) throw;
        if (safeAdd(etherReceived, msg.value) > TIER3_CAP) throw;

        uint256 tokenAmount = getTokenAmount(etherReceived, msg.value);

        moedaToken.create(msg.sender, tokenAmount);
        etherReceived = safeAdd(etherReceived, msg.value);
        totalTokensSold = safeAdd(totalTokensSold, tokenAmount);
        Purchase(msg.sender, msg.value, tokenAmount);

        if (!wallet.send(msg.value)) throw;
    }

     
     
     
    function finalize() onlyOwner {
        if (block.number < startBlock) throw;
        if (crowdsaleClosed) throw;

         
        uint256 amountRemaining = safeSub(TIER3_CAP, etherReceived);
        if (block.number < endBlock && amountRemaining >= DUST_LIMIT) throw;

         
        moedaToken.create(PRESALE_WALLET, PRESALE_TOKEN_ALLOCATION);

         
        moedaToken.unlock();
        crowdsaleClosed = true;
    }

     
     
     
     
    function drainToken(address _token, address _to) onlyOwner {
        if (_token == address(0)) throw;
        if (_to == address(0)) throw;
        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(_to, balance);
        TokenDrain(_token, _to, balance);
    }
}