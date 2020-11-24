 

pragma solidity ^0.4.23;

 
contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        require(a == b * c + a % b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c>=a && c>=b);
        return c;
    }
  }

contract BitgetToken is SafeMath{   
    address public owner;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    string public name;
    string public symbol;
      
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;

     
     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
	
	 
    event Freeze(address indexed from, uint256 value);
	
	 
    event Unfreeze(address indexed from, uint256 value);

    constructor(
        uint256 initSupply, 
        string tokenName, 
        string tokenSymbol, 
        uint8 decimalUnits) public {
        owner = msg.sender;
        totalSupply = initSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;  
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

     
     
    function totalSupply() public view returns (uint256){
        return totalSupply;
    }

     
     
    function balanceOf(address _owner) public view returns (uint256) {
        return balanceOf[_owner];
    }
    
     
     
    function freezeOf(address _owner) public view returns (uint256) {
        return freezeOf[_owner];
    }

     
     
     
     
     
    function transfer(address _to, uint256 _value) public {
        require(_to != 0x0);                                 
        require(_value > 0);                                 
        require(balanceOf[msg.sender] >= _value);            
        require(balanceOf[_to] + _value > balanceOf[_to]);   
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value); 
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value); 
        emit Transfer(msg.sender, _to, _value); 
    }

     
     
     
    function burn(uint256 _value) public {
        require(owner == msg.sender);                 
        require(balanceOf[msg.sender] >= _value);     
        require(_value > 0);                          
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);     
        totalSupply = SafeMath.sub(totalSupply,_value);                          
        emit Burn(msg.sender, _value);
    }
	
     
     
     
	function freeze(address _addr, uint256 _value) public {
        require(owner == msg.sender);                 
        require(balanceOf[_addr] >= _value);          
		require(_value > 0);                          
        balanceOf[_addr] = SafeMath.sub(balanceOf[_addr], _value);               
        freezeOf[_addr] = SafeMath.add(freezeOf[_addr], _value);                 
        emit Freeze(_addr, _value);
    }
	
     
     
     
	function unfreeze(address _addr, uint256 _value) public {
        require(owner == msg.sender);                 
        require(freezeOf[_addr] >= _value);           
		require(_value > 0);                          
        freezeOf[_addr] = SafeMath.sub(freezeOf[_addr], _value);                 
		balanceOf[_addr] = SafeMath.add(balanceOf[_addr], _value);               
        emit Unfreeze(_addr, _value);
    }

     
	function withdrawEther(uint256 amount) public {
		require(owner == msg.sender);
		owner.transfer(amount);
	}
	
	 
	function() payable public {
    }
}