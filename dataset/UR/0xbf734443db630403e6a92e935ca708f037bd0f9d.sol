 

pragma solidity ^0.4.13;

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract BasicToken is ERC20Basic {
    
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}

contract Wallet {

	address owner;

	function Wallet() {
		owner = msg.sender;
	}

	function changeOwner(address _owner) returns (bool) {
		require(owner == msg.sender);
		owner = _owner;
		return true;
	}

	function transfer(address _to, uint _value) returns (bool) {
		require(owner == msg.sender);
		require(_value <= this.balance);
		_to.transfer(_value);
		return true;
	}

	function transferToken(address _token, address _to, uint _value) returns (bool) {
		require(owner == msg.sender);
		BasicToken token = BasicToken(_token);
		require(_value <= token.balanceOf(this));
		token.transfer(_to, _value);
		return true;
	}

	function () payable {}

	function tokenFallback(address _from, uint _value, bytes _data) {
		(_from); (_value); (_data);
	}
}