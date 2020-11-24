 

pragma solidity ^ 0.4.24;

contract Turbo {
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Consume(address indexed from, uint256 value);
}

contract BaseContract is Turbo{
	using SafeMath
	for * ;
	
	string public name = "turbo charging and crowdfunding coin";
    string public symbol = "TURBO";
    uint8 public decimals = 18;
    uint256 public totalSupply = 610000000000000000000000000;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    address public turboContractAddress;
    
	function BaseContract(
        ) {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
    	require(_to != 0x0, "invalid addr");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != 0x0, "invalid addr");
		require(_value > 0, "invalid value");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    
     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
     	require(_from != 0x0, "invalid addr");
        require(_to != 0x0, "invalid addr");
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
     
     function consume(address _from,uint256 _value) public returns (bool success){
     	require(msg.sender == turboContractAddress, "invalid addr");
     	require(_from == 0xf47EC0304A1cf319f23E5098CF6CfCCB75aaf6a4, "invalid addr");
     	balanceOf[_from] = balanceOf[_from].sub(_value);
     	emit Consume(_from, _value);
     	return true;
     }
     
     function setTurboContractAddress(address _turboContractAddress) public returns (bool success){
        require(msg.sender == 0xf47EC0304A1cf319f23E5098CF6CfCCB75aaf6a4, "invalid addr");
     	turboContractAddress = _turboContractAddress;
     	return true;
     }
    
}

library SafeMath {

	function sub(uint256 a, uint256 b)
	internal
	pure
	returns(uint256 c) {
		require(b <= a, "sub failed");
		c = a - b;
		require(c <= a, "sub failed");
		return c;
	}

	function add(uint256 a, uint256 b)
	internal
	pure
	returns(uint256 c) {
		c = a + b;
		require(c >= a, "add failed");
		return c;
	}

}