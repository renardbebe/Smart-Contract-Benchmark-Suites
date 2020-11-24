 

pragma solidity ^0.5.12;
 
contract SafeMath { 
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;  
    }
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {	
    return a/b;  
    }
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;  
    }
  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;  
    }  
  function safePower(uint a, uint b) internal pure returns (uint256) {
      uint256 c = a**b;
      return c;  
    }
}

contract SEET is SafeMath{
    string public name;    
    string public symbol;    
    uint8 public decimals;    
    uint256 public totalSupply;  
    address payable public owner;
    mapping (address => uint256) public balanceOf; 
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Burn(address indexed from, uint256 value);   
    event Approval(address indexed owner, address indexed spender, uint256 value);  
    event SetOwner(address add);
    
    constructor ( 
        uint256 initialSupply,string memory tokenName,string memory tokenSymbol) public{
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = 18;                                       
        owner = msg.sender;
    }
    
    function transfer(address _to, uint256 _value) public  returns (bool success){ 
        require (_to != address(0x0));                         
        require (_value >= 0) ;																	
        require (balanceOf[msg.sender] >= _value) ;            
        require (safeAdd(balanceOf[_to] , _value) >= balanceOf[_to]) ;  
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);  
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);                
        emit Transfer(msg.sender, _to, _value);                    
        return true;
    }
 
    function approve(address _spender, uint256 _value) public returns (bool success) { 
        allowance[msg.sender][_spender] = _value;	
        emit Approval(msg.sender, _spender, _value);
        return true;    
    }
    
    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) { 
        require (_to != address(0x0)) ;                                 
        require (_value >= 0) ;													
        require (balanceOf[_from] >= _value) ;                  
        require (safeAdd(balanceOf[_to] , _value) >= balanceOf[_to]) ;   
        require (_value <= allowance[_from][msg.sender]) ;      
        balanceOf[_from] = safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true; 
      }

    function burn(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value) ;             
        require (_value > 0) ; 
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);             
        totalSupply = safeSub(totalSupply,_value);                                 
        emit Burn(msg.sender, _value);			
        emit Transfer(msg.sender, address(0), _value);
        return true;
    } 
    
    function setSymbol(string memory _symbol)public   {        
        require (msg.sender == owner) ; 
        symbol = _symbol;    
    } 

    function setName(string memory _name)public {        
        require (msg.sender == owner) ; 
        name = _name;    
    } 

    function setOwner(address payable _add)public{
        require (msg.sender == owner && _add != address(0x0)) ;
        owner = _add ;						 
        emit SetOwner(_add);
    }
}