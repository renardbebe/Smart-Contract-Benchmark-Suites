 

 
 
 pragma solidity ^0.4.10;

 

 


contract Owned {
    address public owner;        

    function Owned() {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        owner = _newOwner;
    }
}
 

 
 
contract Manageable is Owned {

    event ManagerSet(address manager, bool state);

    mapping (address => bool) public managers;

    function Manageable() Owned() {
        managers[owner] = true;
    }

     
    modifier managerOnly {
        assert(managers[msg.sender]);
        _;
    }

    function transferOwnership(address _newOwner) public ownerOnly {
        super.transferOwnership(_newOwner);

        managers[_newOwner] = true;
        managers[msg.sender] = false;
    }

    function setManager(address manager, bool state) ownerOnly {
        managers[manager] = state;
        ManagerSet(manager, state);
    }
} 
 

 

 

 
 

 
contract SafeMath {

     
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {        
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }

     
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(a >= b);
        return a - b;
    }

     
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }

    function safeDiv(uint256 x, uint256 y) internal returns (uint256) {
        assert(y != 0);
        return x / y;
    }
} 

 
contract ERC20StandardToken is IERC20Token, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

     
    uint256 tokensIssued;
     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowed;

    function ERC20StandardToken() {
     
    }    

     
     
     

    function totalSupply() constant returns (uint total) {
        total = tokensIssued;
    }
 
    function balanceOf(address _owner) constant returns (uint balance) {
        balance = balances[_owner];
    }

    function transfer(address _to, uint256 _value) returns (bool) {
        require(_to != address(0));

         
        doTransfer(msg.sender, _to, _value);        
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(_to != address(0));
        
         
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);        
         
        doTransfer(_from, _to, _value);        
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        remaining = allowed[_owner][_spender];
    }    

     
     
     
     
    function getRealTokenAmount(uint256 tokens) constant returns (uint256) {
        return tokens * (uint256(10) ** decimals);
    }

     
     
     
    
    function doTransfer(address _from, address _to, uint256 _value) internal {
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
    }
} 
 




 
contract ValueTokenAgent {

     
    ValueToken public valueToken;

     
    modifier valueTokenOnly {require(msg.sender == address(valueToken)); _;}

    function ValueTokenAgent(ValueToken token) {
        valueToken = token;
    }

        
    function tokenIsBeingTransferred(address from, address to, uint256 amount);

     
    function tokenChanged(address holder, uint256 amount);
} 


 
contract ValueToken is Manageable, ERC20StandardToken {
    
     
    ValueTokenAgent valueAgent;

     
    mapping (address => bool) public reserved;

     
    uint256 public reservedAmount;

    function ValueToken() {}

     
    function setValueAgent(ValueTokenAgent newAgent) managerOnly {
        valueAgent = newAgent;
    }

    function doTransfer(address _from, address _to, uint256 _value) internal {

        if (address(valueAgent) != 0x0) {
             
            valueAgent.tokenIsBeingTransferred(_from, _to, _value);
        }

         
        if (reserved[_from]) {
            reservedAmount = safeSub(reservedAmount, _value);
             
        } 
        if (reserved[_to]) {
            reservedAmount = safeAdd(reservedAmount, _value);
             
        }

         
        super.doTransfer(_from, _to, _value);
    }

     
    function getValuableTokenAmount() constant returns (uint256) {
        return totalSupply() - reservedAmount;
    }

     
    function setReserved(address holder, bool state) managerOnly {        

        uint256 holderBalance = balanceOf(holder);
        if (address(valueAgent) != 0x0) {            
            valueAgent.tokenChanged(holder, holderBalance);
        }

         
        if (state) {
             
            reservedAmount = safeAdd(reservedAmount, holderBalance);
        } else {
             
            reservedAmount = safeSub(reservedAmount, holderBalance);
        }

        reserved[holder] = state;
    }
} 
 



 




 
contract ReturnTokenAgent is Manageable {
     

     
    mapping (address => bool) public returnableTokens;

     
     
    modifier returnableTokenOnly {require(returnableTokens[msg.sender]); _;}

     
    function returnToken(address from, uint256 amountReturned);

     
    function setReturnableToken(ReturnableToken token) managerOnly {
        returnableTokens[address(token)] = true;
    }

     
    function removeReturnableToken(ReturnableToken token) managerOnly {
        returnableTokens[address(token)] = false;
    }
} 

 
contract ReturnableToken is Manageable, ERC20StandardToken {

     
    mapping (address => bool) public returnAgents;

    function ReturnableToken() {}    
    
     
    function setReturnAgent(ReturnTokenAgent agent) managerOnly {
        returnAgents[address(agent)] = true;
    }

     
    function removeReturnAgent(ReturnTokenAgent agent) managerOnly {
        returnAgents[address(agent)] = false;
    }

    function doTransfer(address _from, address _to, uint256 _value) internal {
        super.doTransfer(_from, _to, _value);
        if (returnAgents[_to]) {
            ReturnTokenAgent(_to).returnToken(_from, _value);                
        }
    }
} 
 

 
contract IBurnableToken {
    function burn(uint256 _value);
} 

 
contract BCSToken is ValueToken, ReturnableToken, IBurnableToken {

     
    mapping (address => bool) public transferAllowed;
         
    mapping (address => uint256) public transferLockUntil; 
     
    bool public transferLocked;

    event Burn(address sender, uint256 value);

     
    function BCSToken(uint256 _initialSupply, uint8 _decimals) {
        name = "BCShop.io Token";
        symbol = "BCS";
        decimals = _decimals;        

        tokensIssued = _initialSupply * (uint256(10) ** decimals);
         
        balances[msg.sender] = tokensIssued;

        transferLocked = true;
        transferAllowed[msg.sender] = true;        
    }

     
    function doTransfer(address _from, address _to, uint256 _value) internal {
        require(canTransfer(_from));
        super.doTransfer(_from, _to, _value);
    }    

     
    function canTransfer(address holder) constant returns (bool) {
        if(transferLocked) {
            return transferAllowed[holder];
        } else {
            return now > transferLockUntil[holder];
        }
         
    }    

     
    function lockTransferFor(address holder, uint256 daysFromNow) managerOnly {
        transferLockUntil[holder] = daysFromNow * 1 days + now;
    }

     
    function allowTransferFor(address holder, bool state) managerOnly {
        transferAllowed[holder] = state;
    }

     
    function setLockedState(bool state) managerOnly {
        transferLocked = state;
    }
    
    function burn(uint256 _value) managerOnly {        
        require (balances[msg.sender] >= _value);             

        if (address(valueAgent) != 0x0) {            
            valueAgent.tokenChanged(msg.sender, _value);
        }

        balances[msg.sender] -= _value;                       
        tokensIssued -= _value;                               

        Burn(msg.sender, _value);        
    }
}