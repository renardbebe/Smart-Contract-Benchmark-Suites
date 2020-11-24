 

 

pragma solidity ^0.4.24;
 
contract ERC20Ownable {
    address public owner;

    function ERC20Ownable() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public{
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}
contract ERC20 {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20Token is ERC20,ERC20Ownable {
    
    mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	
    event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 _value
		);

	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint256 _value
		);
		
	 
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	}

	function balanceOf(address _owner) constant public returns (uint256) {
		return balances[_owner];
	}

	function transfer(address _to, uint256 _value) onlyPayloadSize(2*32) public returns (bool){
		require(balances[msg.sender] >= _value && _value > 0);
	    balances[msg.sender] -= _value;
	    balances[_to] += _value;
	    emit Transfer(msg.sender, _to, _value);
	    return true;
    }

	function transferFrom(address _from, address _to, uint256 _value) public {
		require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
    }

	function approve(address _spender, uint256 _value) public {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
	}

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
         
         
         
         
        require(_spender.call(abi.encodeWithSelector(bytes4(keccak256("receiveApproval(address,uint256,address,bytes)")),msg.sender, _value, this, _extraData)));

        return true;
    }
    
	function allowance(address _owner, address _spender) constant public returns (uint256) {
		return allowed[_owner][_spender];
	}
}

contract ERC20StandardToken is ERC20Token {
	uint256 public totalSupply;
	string public name;
	uint256 public decimals;
	string public symbol;
	bool public mintable;


    function ERC20StandardToken(address _owner, string _name, string _symbol, uint256 _decimals, uint256 _totalSupply, bool _mintable) public {
        require(_owner != address(0));
        owner = _owner;
		decimals = _decimals;
		symbol = _symbol;
		name = _name;
		mintable = _mintable;
        totalSupply = _totalSupply;
        balances[_owner] = totalSupply;
    }
    
    function mint(uint256 amount) onlyOwner public {
		require(mintable);
		require(amount >= 0);
		balances[msg.sender] += amount;
		totalSupply += amount;
	}

    function burn(uint256 _value) onlyOwner public returns (bool) {
        require(balances[msg.sender] >= _value  && totalSupply >=_value && _value > 0);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Transfer(msg.sender, 0x0, _value);
        return true;
    }
}