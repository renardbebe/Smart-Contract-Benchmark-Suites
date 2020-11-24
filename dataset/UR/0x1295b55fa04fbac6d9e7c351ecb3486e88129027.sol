 

pragma solidity 0.4.18;

 

contract BaseSafeMath {


     



    function add(uint256 a, uint256 b) internal pure

    returns (uint256) {

        uint256 c = a + b;

        assert(c >= a);

        return c;

    }


    function sub(uint256 a, uint256 b) internal pure

    returns (uint256) {

        assert(b <= a);

        return a - b;

    }


    function mul(uint256 a, uint256 b) internal pure

    returns (uint256) {

        uint256 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }


    function div(uint256 a, uint256 b) internal pure

    returns (uint256) {

	    assert( b > 0 );
		
        uint256 c = a / b;

        return c;

    }


    function min(uint256 x, uint256 y) internal pure

    returns (uint256 z) {

        return x <= y ? x : y;

    }


    function max(uint256 x, uint256 y) internal pure

    returns (uint256 z) {

        return x >= y ? x : y;

    }



     



    function madd(uint128 a, uint128 b) internal pure

    returns (uint128) {

        uint128 c = a + b;

        assert(c >= a);

        return c;

    }


    function msub(uint128 a, uint128 b) internal pure

    returns (uint128) {

        assert(b <= a);

        return a - b;

    }


    function mmul(uint128 a, uint128 b) internal pure

    returns (uint128) {

        uint128 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }


    function mdiv(uint128 a, uint128 b) internal pure

    returns (uint128) {

	    assert( b > 0 );
	
        uint128 c = a / b;

        return c;

    }


    function mmin(uint128 x, uint128 y) internal pure

    returns (uint128 z) {

        return x <= y ? x : y;

    }


    function mmax(uint128 x, uint128 y) internal pure

    returns (uint128 z) {

        return x >= y ? x : y;

    }



     



    function miadd(uint64 a, uint64 b) internal pure

    returns (uint64) {

        uint64 c = a + b;

        assert(c >= a);

        return c;

    }


    function misub(uint64 a, uint64 b) internal pure

    returns (uint64) {

        assert(b <= a);

        return a - b;

    }


    function mimul(uint64 a, uint64 b) internal pure

    returns (uint64) {

        uint64 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }


    function midiv(uint64 a, uint64 b) internal pure

    returns (uint64) {

	    assert( b > 0 );
	
        uint64 c = a / b;

        return c;

    }


    function mimin(uint64 x, uint64 y) internal pure

    returns (uint64 z) {

        return x <= y ? x : y;

    }


    function mimax(uint64 x, uint64 y) internal pure

    returns (uint64 z) {

        return x >= y ? x : y;

    }


}


 

 



contract BaseERC20 {

     
    string public name;
    string public symbol;
    uint8 public decimals;
     
    uint256 public totalSupply;

     
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowed;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
	
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function _transfer(address _from, address _to, uint _value) internal;

     
    function transfer(address _to, uint256 _value) public returns (bool success);
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);
}

  

contract Ownable { 
	address public publishOwner; 
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); 
	
	 
	function Ownable() public {
		publishOwner = msg.sender; 
	} 
	
	  
	modifier onlyOwner() { 
		require(msg.sender == publishOwner); 
		_; 
	}
 
	  
	function transferOwnership(address newOwner) onlyOwner public { 
		require(newOwner != address(0)); 
		OwnershipTransferred(publishOwner, newOwner); 
		publishOwner = newOwner; 
	} 
} 

 
contract Pausable is Ownable { 
	event Pause(); 
	event Unpause(); 
	bool public paused = false;
 
	 
	modifier whenNotPaused() 
	{ 
		require(!paused); 
		_; 
	}
	  
	modifier whenPaused() { 
		require(paused); 
		_;
	} 

	  
	function pause() onlyOwner whenNotPaused public { 
		paused = true; 
		Pause(); 
	} 

	  
	function unpause() onlyOwner whenPaused public {
		paused = false; 
		Unpause(); 
	} 
} 


 

contract LightCoinToken is BaseERC20, BaseSafeMath, Pausable {

     
	address public owner;
	address public lockOwner;
	uint256 public lockAmount ;
	uint256 public startTime ;
    function LightCoinToken() public {
		owner = 0x55ae8974743DB03761356D703A9cfc0F24045ebb;
		lockOwner = 0x07d4C8CC52BB7c4AB46A1A65DCEEdC1ab29aBDd6;
		startTime = 1515686400;
        name = "Lightcoin";
        symbol = "Light";
        decimals = 8;
         
        totalSupply = 2.1e19;
		balanceOf[owner] = totalSupply * 90 /100;
		lockAmount = totalSupply * 10 / 100 ;
	    Transfer(address(0), owner, balanceOf[owner]);
    }

	 
     
    function getBalanceOf(address _owner) public constant returns (uint256 balance) {
		 return balanceOf[_owner];
	}
	
    function _transfer(address _from, address _to, uint256 _value) internal {
         
        require(_to != 0x0);

         
        uint previousBalances = add(balanceOf[_from], balanceOf[_to]);
		
         
        balanceOf[_from] = sub(balanceOf[_from], _value);
         
        balanceOf[_to] = add(balanceOf[_to], _value);
		
		 
        assert(add(balanceOf[_from], balanceOf[_to]) == previousBalances);
		
        Transfer(_from, _to, _value);

    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success)  {
        _transfer(msg.sender, _to, _value);
		return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
         
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender], _value);
		
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
		
		Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
	}
	
	function releaseToken() public{
	   uint256 releaseBegin = add(startTime,  2 * 365 * 86400);
	   require(now >= releaseBegin );
	   
	   uint256 interval = sub(now, releaseBegin);
       uint256 i = div(interval, (0.5 * 365 * 86400));
       if (i > 3) 
       {
            i = 3;
       }

	   uint256 releasevalue = div(totalSupply, 40);
	   uint256 remainInterval = sub(3, i);
	   
	   require(lockAmount > mul(remainInterval, releasevalue));
	   lockAmount = sub(lockAmount, releasevalue);
	   
	   balanceOf[lockOwner] = add( balanceOf[lockOwner],  releasevalue);
	   Transfer(address(0), lockOwner, releasevalue);
    }
    
    function () public payable{ revert(); }
}