 

pragma solidity ^0.4.21;

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

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
 
 
library SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);  
        uint256 c = a / b;
         
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BigerToken is Ownable {
    
  modifier onlyPayloadSize(uint256 size) {
    require(size > 0);
    require(msg.data.length >= size + 4) ;
    _;
  }
  using SafeMath for uint256;
    
  string public constant name = "BigerToken";
  string public constant symbol = "BG";
  uint256 public constant decimals = 18;
  string public version = "1.0";
  uint256 public  totalSupply = 100 * (10**8) * 10**decimals;    
   
     
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
	
	 
    event Freeze(address indexed from, uint256 value);
	
	 
    event Unfreeze(address indexed from, uint256 value);

     
 function BigerToken() public {
    balanceOf[msg.sender] = totalSupply;
    owner = msg.sender;
    emit Transfer(0x0, msg.sender, totalSupply);
  }

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool){
        require (_to != 0x0);                                
        require(_to != address(this));  
		require(0 <= _value); 
        require(_value <= balanceOf[msg.sender]);            
        require(balanceOf[_to] <= balanceOf[_to] + _value);  
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
        emit Transfer(msg.sender, _to, _value);                    
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
		require (0 <= _value ) ; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool success) {
        require (_to != 0x0);              
        require(_to != address(this));         
		require( 0 <= _value); 
        require(_value <= balanceOf[_from]);                  
        require( balanceOf[_to] <= balanceOf[_to] + _value) ;   
        require(_value <= allowance[_from][msg.sender]) ;      
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(_value <= balanceOf[msg.sender]);             
		require(0 <= _value); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                 
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) onlyOwner public returns (bool success) {
        require(_value <= balanceOf[msg.sender]);             
		require(0 <= _value); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                 
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) onlyOwner public returns (bool success) {
        require( _value <= freezeOf[msg.sender]);             
		require(0 <= _value) ; 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                       
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	 
	function() payable public {
	     revert();
    }
}