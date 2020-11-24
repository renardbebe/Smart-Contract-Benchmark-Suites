 

pragma solidity ^0.4.8;


contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c>=a && c>=b);
    return c;
  }
}

contract ERC20Interface {

    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract SPADLAND is SafeMath, ERC20Interface{
    
     
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;
	uint public initialRate;
    uint public finalRate;
    uint public openingTime;
    uint public closingTime;
    bool public paused = false;
	address public owner;


     
    mapping (address => uint) public balanceOf;
	mapping (address => uint) public freezeOf;
    mapping (address => mapping (address => uint)) public allowance;


     
    event Transfer(address indexed from, address indexed to, uint value);
    event Burn(address indexed from, uint value);
    event Mint(address indexed from, uint value);
    event Freeze(address indexed from, uint value);
    event Unfreeze(address indexed from, uint value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    
     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

  
  

    constructor(
        uint initialSupply,
        string tokenName,
        uint decimalUnits,
        string tokenSymbol
        ) public {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
		owner = msg.sender;
    }


    function transfer(address _to, uint _value) public returns(bool){
        if (_to == 0x0) revert();
		if (_value <= 0) revert();
        if (balanceOf[msg.sender] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public
        returns (bool success) {
		if (_value <= 0) revert(); 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        if (_to == 0x0) revert();
		if (_value <= 0) revert();
        if (balanceOf[_from] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        if (_value > allowance[_from][msg.sender]) revert();
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint _value) public returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert();
		if (_value <= 0) revert(); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.safeSub(totalSupply,_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
    
        
    function mint(uint _value) public onlyOwner returns (bool success) {
        if (_value <= 0) revert(); 
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.safeAdd(totalSupply,_value);
        emit Mint(msg.sender, _value);
        return true;
    }
	
	
	
	function freeze(uint _value) public returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert();
		if (_value <= 0) revert(); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint _value) public returns (bool success) {
        if (freezeOf[msg.sender] < _value) revert();
		if (_value <= 0) revert(); 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	function withdrawEther(uint amount) public {
		if(msg.sender != owner) revert();
		owner.transfer(amount);
	}
	
	
	function totalSupply() public view returns (uint){
	    return totalSupply;
	}
	
	
    function balanceOf(address tokenOwner) public view returns (uint){
        return balanceOf[tokenOwner];
    }
    
    
    function allowance(address tokenOwner, address spender) public view returns (uint){
        return allowance[tokenOwner][spender];
    }

 
    



}