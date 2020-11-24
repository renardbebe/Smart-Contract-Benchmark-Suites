 

pragma solidity ^0.4.24;  


library SafeMath {
	function mul(uint a, uint b) internal pure returns(uint) {  
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint a, uint b) internal pure returns(uint) { 
		uint c = a / b;
		return c; 
	}

	function sub(uint a, uint b) internal pure returns(uint) {  
		assert(b <= a);
		return a - b;
	}

	function add(uint a, uint b) internal pure returns(uint) {  
		uint c = a + b;
		assert(c >= a);
		return c;
	}
	function max64(uint64 a, uint64 b) internal pure  returns(uint64) { 
		return a >= b ? a : b;
	}

	function min64(uint64 a, uint64 b) internal pure  returns(uint64) { 
		return a < b ? a : b;
	}

	function max256(uint256 a, uint256 b) internal pure returns(uint256) { 
		return a >= b ? a : b;
	}

	function min256(uint256 a, uint256 b) internal pure returns(uint256) {  
		return a < b ? a : b;
	}
 
}

contract ERC20Basic {
	uint public totalSupply;
	function balanceOf(address who) public constant returns(uint);  
	function transfer(address to, uint value) public;  
	event Transfer(address indexed from, address indexed to, uint value);
}


contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public constant returns(uint);  
	function transferFrom(address from, address to, uint value) public;  
	function approve(address spender, uint value) public;  
	event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract VT201811003  {
  using SafeMath for uint256;
  event Released(uint256 amounts);
event InvalidCaller(address caller);

   address public owner;

  address[] private _beneficiary ;
  uint256 private _locktime;  
  uint256 private _unlocktime;  
  uint256[] private _amount;

  constructor() public
  {
    owner = msg.sender;
     _unlocktime =0;
  }
  
  
    

   modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function beneficiary() public view returns(address[]) {
    return _beneficiary;
  }

   
  function unlocktime() public view returns(uint256) {
    return _unlocktime;
  }
     
  function locktime() public view returns(uint256) {
    return _locktime;
  }
  
    
  function amount() public view returns(uint256[]) {
    return _amount;
  }
   
    function setLockTime(uint256  locktimeParam,uint256  unlocktimeParam) public onlyOwner{
	         _unlocktime = unlocktimeParam;
	        _locktime = locktimeParam;
    } 
  
    function setUserInfo(address[] beneficiaryParam,uint256[]  amountParam) public onlyOwner{
        if( block.timestamp <=_locktime){
             _beneficiary = beneficiaryParam;
	         _amount = amountParam;
        }
    } 
 

   
  function release(ERC20 token) public {
       for(uint i = 0; i < _beneficiary.length; i++) {
            if(block.timestamp >= _unlocktime ){
                   token.transfer(_beneficiary[i], _amount[i].mul(10**18));
                    emit Released( _amount[i]);
                    _amount[i]=0;
            }
       }
  } 
  
  
  

   
  
    function checkRelease(ERC20 token) public {
       uint _unRelease = 0;
       
        for(uint i = 0; i < _amount.length; i++) {
            _unRelease = _unRelease.add(_amount[i]); 
        }
        if(_unRelease==0 && block.timestamp >= _unlocktime ){
             token.transfer(owner,token.balanceOf(this));
        }
        
  }

}