 

pragma solidity ^0.4.11;

 

 
 
 
 


 
contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


 
contract GUNS is StandardToken {

     
    string public constant name = "GeoUnits";
    string public constant symbol = "GUNS";
    uint256 public constant decimals = 18;
    string public version = "1.0";

     
    address public hostAccount;        
    address public ethFundDeposit;     
    address public gunsFundDeposit;    

     
    bool public isFinalized;                                                       
    uint256 public fundingStartBlock;                                              
    uint256 public fundingEndBlock;                                                
    uint256 public constant gunsFund = 35 * (10**6) * 10**decimals;                
    uint256 public constant tokenExchangeRate = 1000;                              
    uint256 public constant tokenCreationCap =  100 * (10**6) * 10**decimals;      
    uint256 public constant tokenCreationMin =  1 * (10**6) * 10**decimals;        

     
    event LogRefund(address indexed _to, uint256 _value);    
    event CreateGUNS(address indexed _to, uint256 _value);   

     
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

     
    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

     
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

     
    function GUNS() {}

     
    function initialize(
        address _ethFundDeposit,
        address _gunsFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock
    ) public {
        require(address(hostAccount) == 0x0);      
        hostAccount = msg.sender;                  
        isFinalized = false;                       
        ethFundDeposit = _ethFundDeposit;          
        gunsFundDeposit = _gunsFundDeposit;        
        fundingStartBlock = _fundingStartBlock;    
        fundingEndBlock = _fundingEndBlock;        
        totalSupply = gunsFund;                    
        balances[gunsFundDeposit] = gunsFund;      
        CreateGUNS(gunsFundDeposit, gunsFund);     
    }

     
    function () public payable {
        require(address(hostAccount) != 0x0);                       

        if (isFinalized) throw;                                     
        if (block.number < fundingStartBlock) throw;                
        if (block.number > fundingEndBlock) throw;                  
        if (msg.value == 0) throw;                                  

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);    
        uint256 checkedSupply = safeAdd(totalSupply, tokens);       

        if (tokenCreationCap < checkedSupply) throw;                

        totalSupply = checkedSupply;                                
        balances[msg.sender] += tokens;                             
        CreateGUNS(msg.sender, tokens);                             
    }

     
    function emergencyPay() external payable {}

     
    function finalize() external {
         
        if (msg.sender != ethFundDeposit) throw;                                          
         
        if (block.number <= fundingEndBlock && totalSupply < tokenCreationCap) throw;     

        if (!ethFundDeposit.send(this.balance)) throw;                                    
        
        uint256 remainingSupply = safeSubtract(tokenCreationCap, totalSupply);            
        if (remainingSupply > 0) {                                                        
            uint256 updatedSupply = safeAdd(totalSupply, remainingSupply);                
            totalSupply = updatedSupply;                                                  
            balances[gunsFundDeposit] += remainingSupply;                                 
            CreateGUNS(gunsFundDeposit, remainingSupply);                                 
        }

        isFinalized = true;                                                               
    }

     
    function refund() external {
        if (isFinalized) throw;                                
        if (block.number <= fundingEndBlock) throw;            
        if (totalSupply >= tokenCreationMin) throw;            
        if (msg.sender == gunsFundDeposit) throw;              

        uint256 gunsVal = balances[msg.sender];                
        if (gunsVal == 0) throw;                               

        balances[msg.sender] = 0;                              
        totalSupply = safeSubtract(totalSupply, gunsVal);      
        uint256 ethVal = gunsVal / tokenExchangeRate;          
        LogRefund(msg.sender, ethVal);                         

        if (!msg.sender.send(ethVal)) throw;                   
    }

     
     
     
    function mistakenTokens() external {
        if (msg.sender != ethFundDeposit) throw;                 
        
        if (balances[this] > 0) {                                
            Transfer(this, gunsFundDeposit, balances[this]);     
            balances[gunsFundDeposit] += balances[this];         
            balances[this] = 0;                                  
        }

        if (balances[0x0] > 0) {                                 
            Transfer(0x0, gunsFundDeposit, balances[0x0]);       
            balances[gunsFundDeposit] += balances[0x0];          
            balances[0x0] = 0;                                   
        }
    }

}