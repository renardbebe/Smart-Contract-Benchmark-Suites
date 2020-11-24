 

pragma solidity ^0.4.16;

 
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 is owned, SafeMath {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

	mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);
	
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
		 
        require(_to != 0x0);
		require(_value > 0);
         
        require(balanceOf[msg.sender] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
		 
		require(!frozenAccount[msg.sender]);
		 
        require(!frozenAccount[_to]);
         
		balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
         
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(_to != 0x0);
		require(_value > 0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
		 
		require(!frozenAccount[_from]);
		 
        require(!frozenAccount[_to]);
		 
		require(_value <= allowance[_from][msg.sender]);
		 
		balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
         
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
		
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender],_value);
		emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
		require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
         
		require(balanceOf[msg.sender] >= _value);   
		require(_value > 0);
		 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
         
		totalSupply = SafeMath.safeSub(totalSupply, _value);
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value > 0);
		require(_value <= allowance[_from][msg.sender]);     
		 
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
		 
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
         
		totalSupply = SafeMath.safeSub(totalSupply, _value);
        emit Burn(_from, _value);
        return true;
    }
	
	 
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = SafeMath.safeAdd(balanceOf[target], mintedAmount);
        totalSupply = SafeMath.safeAdd(totalSupply, mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
}