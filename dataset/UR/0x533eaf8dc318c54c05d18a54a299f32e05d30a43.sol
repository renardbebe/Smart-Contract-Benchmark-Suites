 

pragma solidity ^0.4.25;

 
library SafeMath {
	function mul(uint a, uint b) internal returns (uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
	function div(uint a, uint b) internal returns (uint) {
		 
		uint c = a / b;
		 
		return c;
	}
	function sub(uint a, uint b) internal returns (uint) {
		assert(b <= a);
		return a - b;
	}
	function add(uint a, uint b) internal returns (uint) {
		uint c = a + b;
		assert(c >= a);
		return c;
	}
	function max64(uint64 a, uint64 b) internal constant returns (uint64) {
		return a >= b ? a : b;
	}
	function min64(uint64 a, uint64 b) internal constant returns (uint64) {
		return a < b ? a : b;
	}
	function max256(uint256 a, uint256 b) internal constant returns (uint256) {
		return a >= b ? a : b;
	}
	function min256(uint256 a, uint256 b) internal constant returns (uint256) {
		return a < b ? a : b;
	}
	function assert(bool assertion) internal {
		if (!assertion) {
			throw;
		}
	}
}


 
contract ERC20 {
  function totalSupply() public view returns (uint256);  
  function balanceOf(address _owner) public view returns (uint256);  
  function transfer(address _to, uint256 _value) public returns (bool);  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);  
  function approve(address _spender, uint256 _value) public returns (bool);  
  function allowance(address _owner, address _spender) public view returns (uint256);  
  event Transfer(address indexed _from, address indexed _to, uint256 _value);  
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}
contract ERC223 {
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public returns(bool);
    function transfer(address to, uint value, bytes data) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);  
     
}
 
contract ERC223Token is ERC223{
	using SafeMath for uint;

	mapping(address => uint256) balances;
  
	function transfer(address _to, uint _value) public returns(bool){
		uint codeLength;
		bytes memory empty;
		assembly {
			 
			codeLength := extcodesize(_to)
		}

		require(_value > 0);
		require(balances[msg.sender] >= _value);
		require(balances[_to]+_value > 0);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		if(codeLength>0) {
			ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
			receiver.tokenFallback(msg.sender, _value, empty);
			return false;
		}
		emit Transfer(msg.sender, _to, _value);
		return true;
	}
  
	function transfer(address _to, uint _value, bytes _data) public returns(bool){
		 
		 
		uint codeLength;
		assembly {
			 
			codeLength := extcodesize(_to)
		}

		require(_value > 0);
		require(balances[msg.sender] >= _value);
		require(balances[_to]+_value > 0);
		
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		if(codeLength>0) {
			ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
			receiver.tokenFallback(msg.sender, _value, _data);
			return false;
		}
		emit Transfer(msg.sender, _to, _value);
		return true;
	} 

	function balanceOf(address _owner) public view returns (uint256) {    
		return balances[_owner];
	}
  
}

 
 
 
 
contract Owned {
	address public owner;
	constructor() public {
		owner = msg.sender;
		 
	}
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
}
 
contract DING is ERC223Token, Owned{
    
    string public constant name = "Ding Ding Token";
    string public constant symbol = "DING";
    uint8  public constant decimals = 18;

    uint256 public tokenRemained = 2 * (10 ** 9) * (10 ** 18);  
    uint256 public totalSupply   = 2 * (10 ** 9) * (10 ** 18);
    

    bool public pause=false;

    mapping(address => bool) lockAddresses;
    
     
    function DING(){    
         
        balances[0xd8686d2aB1a65149FDd4ee36c60d161c274C41e0]= totalSupply;
    	emit Transfer(0x0,0xd8686d2aB1a65149FDd4ee36c60d161c274C41e0,totalSupply);
    }

     
    event ChangeOwner(address indexed _from,address indexed _to);
    function changeOwner(address _new) public onlyOwner{
        emit ChangeOwner(owner,_new);
        owner=_new;
    }


    

     
    event PauseContract();
    function pauseContract() public onlyOwner{
        pause = true;
        emit PauseContract();
    }
    event ResumeContract();
    function resumeContract() public onlyOwner{
        pause = false;
        emit ResumeContract();
    }
    function is_contract_paused() public view returns(bool){
        return pause;
    }
    

     
    event Lock(address _addr);
    function lock(address _addr) public onlyOwner{
        lockAddresses[_addr] = true; 
        emit Lock(_addr);
    }
    event Unlock(address _addr);
    function unlock(address _addr) public onlyOwner{
        lockAddresses[_addr] = false;
        emit Unlock(_addr); 
    }
    function am_I_locked(address _addr) public view returns(bool){
    	return lockAddresses[_addr];
    }
    
  
     
    
  	
    function() payable {
    
    }
    
    function getETH(uint256 _amount) public onlyOwner{
        msg.sender.transfer(_amount);
    }
     

     
     
     
    modifier transferable(address _addr) {
        require(!pause);
    	require(!lockAddresses[_addr]);
    	_;
    }
    function transfer(address _to, uint _value, bytes _data) public transferable(msg.sender) returns (bool) {
    	return super.transfer(_to, _value, _data);
    }
    function transfer(address _to, uint _value) public transferable(msg.sender) returns (bool) {
		return super.transfer(_to, _value);
    }


     
     
     
    function transferAnyERC20Token(address _tokenAddress, uint256 _value) public onlyOwner returns (bool) {
    	return ERC20(_tokenAddress).transfer(owner, _value);
  	}
}