 

 
pragma solidity ^0.4.13;

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


interface GlobalToken {
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
    address public owner;
    
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner) ;
        _;
    }
	
	modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
		_;
	}

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
        OwnershipTransferred(owner, newOwner);
    }
  
  function contractVersion() constant returns(uint256) {
         
        return 100201712010000;
    }
}

 
contract GlobalCryptoFund is Owned, GlobalToken {
    
    using SafeMath for uint256;
    
     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	
	address public minter;
    
     
    mapping (address => uint256) public balanceOf;
    
	modifier onlyMinter {
		require(msg.sender == minter);
		_;
	}
	
	function setMinter(address _addressMinter) onlyOwner {
		minter = _addressMinter;
	}
    
     
    function GlobalCryptoFund() {
		name = "GlobalCryptoFund";                    								 
        symbol = "GCF";                												 
        decimals = 18;                          									 
        totalSupply = 0;                									 
        balanceOf[msg.sender] = totalSupply;       									 
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance){
        return balanceOf[_owner];
    }
    
     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);                               						 
        require (balanceOf[_from] >= _value);                						 
        require (balanceOf[_to].add(_value) >= balanceOf[_to]); 						 
        require(_to != address(this));
        balanceOf[_from] = balanceOf[_from].sub(_value);                         	 
        balanceOf[_to] = balanceOf[_to].add(_value);                           		 
        Transfer(_from, _to, _value);
    }
    
    function transfer(address _to, uint256 _value) onlyPayloadSize(2) returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
	event Mint(address indexed from, uint256 value);
    function mintToken(address target, uint256 mintedAmount) onlyMinter {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
        Mint(target, mintedAmount);
    }
    
	event Burn(address indexed from, uint256 value);
    function burn(uint256 _value) onlyMinter returns (bool success) {
        require (balanceOf[msg.sender] >= _value);            					 
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);               
        totalSupply = totalSupply.sub(_value);                                	 
        Burn(msg.sender, _value);
        return true;
    }  
	
	function kill() onlyOwner {
        selfdestruct(owner);
    }
    
    function contractVersion() constant returns(uint256) {
         
        return 200201712010000;
    }
}