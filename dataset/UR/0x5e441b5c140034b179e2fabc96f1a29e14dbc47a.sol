 

pragma solidity ^0.4.8;

 

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == 0x0) revert();
        owner = newOwner;
    }
}

 
contract SafeMath {
   

  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

   
}

contract Token {
     
     
    uint256 public totalSupply;


     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
            balances[_from] -= _value;
            balances[_to] += _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

 
contract ClimateCoinToken is owned, SafeMath, StandardToken {
    string public code = "CLI";                                      
    string public name = "ClimateCoin";                                      
    string public symbol = "К";                                              
    address public ClimateCoinAddress = this;                                
    uint8 public decimals = 2;                                               
    uint256 public totalSupply = 10000000;                                   
    uint256 public buyPriceEth = 1 finney;                                   
    uint256 public sellPriceEth = 1 finney;                                  
    uint256 public gasForCLI = 5 finney;                                     
    uint256 public CLIForGas = 10;                                           
    uint256 public gasReserve = 0.2 ether;                                     
    uint256 public minBalanceForAccounts = 10 finney;                        
    bool public directTradeAllowed = false;                                  
    
     
    
    event Mint(address indexed to, uint value);
    event MintFinished();

    bool public mintingFinished = false;
    
     modifier canMint() {
    if(mintingFinished) revert();
    _;
  }

   
  function mint(address _to, uint _amount) public onlyOwner canMint returns (bool) {
    totalSupply = safeAdd(totalSupply,_amount);
    balances[_to] = safeAdd(balances[_to],_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
   


 
    function ClimateCoinToken() public {
        balances[msg.sender] = totalSupply;                                  
    }


 
    function setEtherPrices(uint256 newBuyPriceEth, uint256 newSellPriceEth) onlyOwner public {
        buyPriceEth = newBuyPriceEth;                                        
        sellPriceEth = newSellPriceEth;
    }
    function setGasForCLI(uint newGasAmountInWei) onlyOwner public {
        gasForCLI = newGasAmountInWei;
    }
    function setCLIForGas(uint newCLIAmount) onlyOwner public {
        CLIForGas = newCLIAmount;
    }
    function setGasReserve(uint newGasReserveInWei) onlyOwner public {
        gasReserve = newGasReserveInWei;
    }
    function setMinBalance(uint minimumBalanceInWei) onlyOwner public {
        minBalanceForAccounts = minimumBalanceInWei;
    }


 
    function haltDirectTrade() onlyOwner public {
        directTradeAllowed = false;
    }
    function unhaltDirectTrade() onlyOwner public {
        directTradeAllowed = true;
    }


 
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (_value < CLIForGas) revert();                                       
        if (msg.sender != owner && _to == ClimateCoinAddress && directTradeAllowed) {
            sellClimateCoinsAgainstEther(_value);                              
            return true;
        }

        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {                
            balances[msg.sender] = safeSub(balances[msg.sender], _value);    

            if (msg.sender.balance >= minBalanceForAccounts && _to.balance >= minBalanceForAccounts) {     
                balances[_to] = safeAdd(balances[_to], _value);              
                Transfer(msg.sender, _to, _value);                           
                return true;
            } else {
                balances[this] = safeAdd(balances[this], CLIForGas);         
                balances[_to] = safeAdd(balances[_to], safeSub(_value, CLIForGas));   
                Transfer(msg.sender, _to, safeSub(_value, CLIForGas));       

                if(msg.sender.balance < minBalanceForAccounts) {
                    if(!msg.sender.send(gasForCLI)) revert();                   
                  }
                if(_to.balance < minBalanceForAccounts) {
                    if(!_to.send(gasForCLI)) revert();                          
                }
            }
        } else { revert(); }
    }


 
    function buyClimateCoinsAgainstEther() public payable returns (uint amount) {
        if (buyPriceEth == 0 || msg.value < buyPriceEth) revert();              
        amount = msg.value / buyPriceEth;                                    
        if (balances[this] < amount) revert();                                  
        balances[msg.sender] = safeAdd(balances[msg.sender], amount);        
        balances[this] = safeSub(balances[this], amount);                    
        Transfer(this, msg.sender, amount);                                  
        return amount;
    }


 
    function sellClimateCoinsAgainstEther(uint256 amount) public returns (uint revenue) {
        if (sellPriceEth == 0 || amount < CLIForGas) revert();                 
        if (balances[msg.sender] < amount) revert();                            
        revenue = safeMul(amount, sellPriceEth);                             
        if (safeSub(this.balance, revenue) < gasReserve) revert();              
        if (!msg.sender.send(revenue)) {                                     
            revert();                                                           
        } else {
            balances[this] = safeAdd(balances[this], amount);                
            balances[msg.sender] = safeSub(balances[msg.sender], amount);    
            Transfer(this, msg.sender, revenue);                             
            return revenue;                                                  
        }
    }


 
    function refundToOwner (uint256 amountOfEth, uint256 cli) public onlyOwner {
        uint256 eth = safeMul(amountOfEth, 1 ether);
        if (!msg.sender.send(eth)) {                                         
            revert();                                                           
        } else {
            Transfer(this, msg.sender, eth);                                 
        }
        if (balances[this] < cli) revert();                                     
        balances[msg.sender] = safeAdd(balances[msg.sender], cli);           
        balances[this] = safeSub(balances[this], cli);                       
        Transfer(this, msg.sender, cli);                                     
    }

 
    function() public payable {
        if (msg.sender != owner) {
            if (!directTradeAllowed) revert();
            buyClimateCoinsAgainstEther();                                     
        }
    }
}