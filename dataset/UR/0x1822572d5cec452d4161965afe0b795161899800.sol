 

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}


contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract ParentToken {

      
    using SafeMath for uint256; 

     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address=>uint)) allowance;        



     
    function ParentToken(uint256 currentSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol){
            
       balances[msg.sender] =  currentSupply;     
       totalSupply = currentSupply;               
       name = tokenName;                          
       decimals = decimalUnits;                   
       symbol = tokenSymbol;					 
    }
    
    

    
    
    
       function transfer(address to, uint value) returns (bool success){
        require(
            balances[msg.sender] >= value 
            && value > 0 
            );
            balances[msg.sender] = balances[msg.sender].sub(value);    
            balances[to] = balances[to].add(value);
            return true;
    }
    
	 
	 
	 
    function approve(address spender, uint256 value)
        returns (bool success) {
        allowance[msg.sender][spender] = value;
        return true;
    }

     
	 
	 
    function approveAndCall(address spender, uint256 value, bytes extraData)
        returns (bool success) {    
        tokenRecipient recSpender = tokenRecipient(spender);
        if (approve(spender, value)) {
            recSpender.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
    }



    
    
    
    
    function transferFrom(address from, address to, uint value) returns (bool success){
        
        require(
            allowance[from][msg.sender] >= value
            &&balances[from] >= value
            && value > 0
            );
            
            balances[from] = balances[from].sub(value);
            balances[to] =  balances[to].add(value);
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
            return true;
        }
        
}



library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
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
  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


contract MLC is owned,ParentToken{

      
    using SafeMath for uint256; 

      
    string public standard = 'Token 0.1';  
    uint256 public currentSupply= 2400000000000000;
    string public constant symbol = "MLC";
    string public constant tokenName = "Melania";
    uint8 public constant decimals = 8;

    

    mapping (address => bool) public frozenAccount;


   
    function () payable {
        acceptPayment();    
    }
   

    
    function acceptPayment() payable {
        require(msg.value>0);
        
        owner.transfer(msg.value);
    }



    function MLC()ParentToken(currentSupply,tokenName,decimals,symbol){}


    
    
    function balanceOf(address add) constant returns (uint balance){
       return balances[add];
    }
    
    
    
    
    
    
        function transfer(address to, uint value) returns (bool success){
        require(
            balances[msg.sender] >= value 
            && value > 0 
            && (!frozenAccount[msg.sender]) 										 
            );
            balances[msg.sender] = balances[msg.sender].sub(value);                 
            balances[to] = balances[to].add(value);                                
			Transfer(msg.sender,to,value);
            return true;
    }
    
    

    
    
    
    
        function transferFrom(address from, address to, uint value) returns (bool success){
        
            require(
            allowance[from][msg.sender] >= value
            &&balances[from] >= value                                                  
            && value > 0 
            && (!frozenAccount[msg.sender])                                            
            );
            
            balances[from] = balances[from].sub(value);                                
            balances[to] =  balances[to].add(value);                                   
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
            Transfer(from,to,value);
            return true;
        }
        
    

    
    
    
        function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balances[target] = balances[target].add(mintedAmount);       
        currentSupply = currentSupply.add(mintedAmount);             
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    
    
    function freezeAccount(address target, bool freeze) onlyOwner {
        require(freeze);                                              
        frozenAccount[target] = freeze;                               
        FrozenFunds(target, freeze);
    }


    
     
    function burn(uint256 value) returns (bool success) {
        require (balances[msg.sender] > value && value>0);             
        balances[msg.sender] = balances[msg.sender].sub(value);        
        currentSupply = currentSupply.sub(value);                      
        Burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint256 value) returns (bool success) {
        require(balances[from] >= value);                                          
        require(value <= allowance[from][msg.sender]);                             
        balances[from] = balances[from].sub(value);                                
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);      
        currentSupply = currentSupply.sub(value);                                  
        Burn(from, value);
        return true;
    }



   
	event Transfer(address indexed _from, address indexed _to,uint256 _value);     

   
	event Approval(address indexed _owner, address indexed _spender,uint256 _value);

   
	event FrozenFunds(address target, bool frozen);
    
   
   event Burn(address indexed from, uint256 value);

}