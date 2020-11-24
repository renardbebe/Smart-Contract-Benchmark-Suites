 

pragma solidity ^0.5.1;

contract SafeMath {
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

}

contract Owned {
	address public owner;

	event OwnershipTransferred(address indexed _from, address indexed _to);

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address _owner) onlyOwner public {
		require(_owner != address(0));
		owner = _owner;

		emit OwnershipTransferred(owner, _owner);
	}
}

contract StandardToken is SafeMath, Owned{
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 value);
	bool public transferable = true;

	modifier canTransfer() {
		require(transferable == true);
		_;
	}
	function turnon() onlyOwner public{
        transferable = true;
    }
    function turnoff() onlyOwner public{
        transferable = false;
    }
    function transfer(address _to, uint256 _value) canTransfer public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require( _value >0);
        require(_to != address(0x0));
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require( _value > 0);
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);
        balanceOf[_from] = safeSubtract(balanceOf[_from],_value);
        allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender],_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        require(_value >0);
        balanceOf[msg.sender] = safeSubtract(balanceOf[msg.sender], _value);                       
        totalSupply = safeSubtract(totalSupply,_value);                                 
        emit Burn(msg.sender, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract nvToken is StandardToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    constructor(
    
    ) public {
        owner = 0xCFe75d625a4000a93Be6B5874d29B0A91D688d8A;
        totalSupply = 500000000 * 10 ** uint256(decimals);   
        balanceOf[owner] = totalSupply;                 
        name = "Next Value Exchange";                                    
        symbol = "NVT";                                
    }
}