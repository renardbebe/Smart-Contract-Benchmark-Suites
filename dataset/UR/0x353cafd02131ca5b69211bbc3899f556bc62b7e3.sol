 

pragma solidity ^0.4.24;

 
library SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    require(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c>=a && c>=b);
    return c;
  }
}

contract BEU {
    using SafeMath for uint256;
    string public name = "BitEDU";
    string public symbol = "BEU";
    uint8 public decimals = 18;
    uint256 public totalSupply =   2000000000000000000000000000;
	uint256 public totalLimit  = 100000000000000000000000000000;
    address public owner;
	bool public lockAll = false;

     
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
	mapping (address => uint256) public lockOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Freeze(address indexed from, uint256 value);

     
    event Unfreeze(address indexed from, uint256 value);

     
    constructor() public {
        owner = msg.sender;
		balanceOf[msg.sender] = totalSupply;                 
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!lockAll);                                                           
        require(_to != 0x0);                                                         
		require(_value > 0);                                                         
        require(balanceOf[msg.sender] >= _value);                                    
        require(balanceOf[_to] + _value >= balanceOf[_to]);                          
        require(balanceOf[_to] + _value >= _value);                                  
        require(balanceOf[msg.sender] >= lockOf[msg.sender] + _value);               
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);     
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                   
        emit Transfer(msg.sender, _to, _value);                                      
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
		require(_value >= 0);                                                         
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!lockAll);                                                           
        require(_to != 0x0);                                                         
		require(_value > 0);                                                         
        require(balanceOf[_from] >= _value);                                         
        require(balanceOf[_to] + _value > balanceOf[_to]);                           
        require(balanceOf[_to] + _value > _value);                                   
        require(allowance[_from][msg.sender] >= _value);                             
        require(balanceOf[_from] >= lockOf[_from] + _value);                         
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);               
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                   
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function freeze(uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);                                    
	    require(freezeOf[msg.sender] + _value >= freezeOf[msg.sender]);              
	    require(freezeOf[msg.sender] + _value >= _value);                            
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);     
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);       
        emit Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) public returns (bool success) {
        require(_value > 0);                                                         
        require(freezeOf[msg.sender] >= _value);                                     
        require(balanceOf[msg.sender] + _value > balanceOf[msg.sender]);             
	    require(balanceOf[msg.sender] + _value > _value);                            
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);       
	    balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);     
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(msg.sender == owner);                                                
        require(_value > 0);                                                         
        require(balanceOf[msg.sender] >= _value);                                    
        require(totalSupply >= _value);                                              
	    balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);     
        totalSupply = SafeMath.safeSub(totalSupply, _value);                         
        return true;
    }

    function mint(uint256 _value) public returns (bool success) {
        require(msg.sender == owner);                                                
        require(_value > 0);                                                         
        require(balanceOf[msg.sender] + _value > balanceOf[msg.sender]);             
        require(balanceOf[msg.sender] + _value > _value);                            
        require(totalSupply + _value > totalSupply);                                 
		require(totalSupply + _value > _value);                                      
        require(totalSupply + _value <= totalLimit);                                 
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);     
        totalSupply = SafeMath.safeAdd(totalSupply, _value);                         
        return true;
    }

    function lock(address _to, uint256 _value) public returns (bool success) {
	    require(msg.sender == owner);                                                 
        require(_to != 0x0);                                                          
	    require(_value >= 0);                                                         
        lockOf[_to] = _value;
        return true;
    }

    function lockForAll(bool b) public returns (bool success) {
	    require(msg.sender == owner);                                                 
        lockAll = b;
        return true;
    }

    function () public payable {
        revert();
    }
}