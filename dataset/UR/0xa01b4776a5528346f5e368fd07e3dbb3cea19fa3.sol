 

pragma solidity ^0.4.24;

 
 

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a && c >= b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
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


contract TokenERC20 {

	using SafeMath for uint256;
	 
	string public name;
	string public symbol;
	uint8 public decimals = 8;
	 
	uint256 public totalSupply;


	 
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

	 
	event Transfer(address indexed from, address indexed to, uint256 value);

	 
	event Burn(address indexed from, uint256 value);


	function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);   
		name = tokenName;                                    
		symbol = tokenSymbol;                                
	}


	function _transfer(address _from, address _to, uint _value) internal {
		 
		require(_to != 0x0);
		 
		 
		uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
		 
		balanceOf[_from] = balanceOf[_from].sub(_value);
		 
		balanceOf[_to] = balanceOf[_to].add(_value);
		emit Transfer(_from, _to, _value);
		 
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
	}


	function transfer(address _to, uint256 _value) public {
		_transfer(msg.sender, _to, _value);
	}


	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
		_transfer(_from, _to, _value);
		return true;
	}


	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		return true;
	}


	function burn(uint256 _value) public returns (bool success) {
		balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);             
		totalSupply = totalSupply.sub(_value);                       
		emit Burn(msg.sender, _value);
		return true;
	}



	function burnFrom(address _from, uint256 _value) public returns (bool success) {
		balanceOf[_from] = balanceOf[_from].sub(_value);                          
		allowance[_from][msg.sender] =allowance[_from][msg.sender].sub(_value);              
		totalSupply = totalSupply.sub(_value);                               
		emit Burn(_from, _value);
		return true;
	}


}

 
 
 

contract DJPToken is owned, TokenERC20  {

	 
	uint256 _initialSupply=500000000; 
	string _tokenName="DijitalPara";
	string _tokenSymbol="DJP";
	address public lockedWallet = 0x3d41E1d1941957FB21c2d3503E59a69aa7990370;
	uint256 public startTime;

	mapping (address => bool) public frozenAccount;

	 
	event FrozenFunds(address target, bool frozen);

	 
	function DJPToken( ) TokenERC20(_initialSupply, _tokenName, _tokenSymbol) public {

		startTime = now;

		balanceOf[lockedWallet] = totalSupply;
	}

	function _transfer(address _from, address _to, uint _value) internal {
		require(_to != 0x0);

		bool lockedBalance = checkLockedBalance(_from,_value);
		require(lockedBalance);

		uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
		balanceOf[_from] = balanceOf[_from].sub(_value);
		balanceOf[_to] = balanceOf[_to].add(_value);
		emit Transfer(_from, _to, _value);
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
	}

	function checkLockedBalance(address wallet, uint256 _value) internal returns (bool){
		if(wallet==lockedWallet){
			
			if(now<startTime + 365 * 1 days){  
				return balanceOf[lockedWallet].sub(_value)>=totalSupply.mul(15).div(100)? true : false;
			}else if(now>=startTime + 365 * 1 days && now<startTime + 730 * 1 days){  
				return balanceOf[lockedWallet].sub(_value)>=totalSupply.mul(13).div(100)? true : false;
			}else if(now>=startTime + 730 * 1 days && now<startTime + 1095 * 1 days){  
				return balanceOf[lockedWallet].sub(_value)>=totalSupply.mul(10).div(100)? true : false;	
			}else if(now>=startTime + 1095 * 1 days && now<startTime + 1460 * 1 days){  
				return balanceOf[lockedWallet].sub(_value)>=totalSupply.mul(6).div(100)? true : false;	
			}else{  
				return true;
			}

		}else{
			return true;
		}
	}


}