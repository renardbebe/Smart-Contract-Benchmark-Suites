 

pragma solidity ^0.4.18;

 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }
 
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20 {
     
    uint public totalSupply;

     
     
    function balanceOf(address _owner) public constant returns (uint balance);

     
     
     
     
    function transfer(address _to, uint _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract BDToken is ERC20 {
    using SafeMath for uint;
	
    uint constant private MAX_UINT256 = 2**256 - 1;
	uint8 constant public decimals = 18;
    string public name;
    string public symbol;
	address public owner;
	 
	bool public transferable = true;
     
	mapping (address => uint) freezes;
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    modifier onlyOwner {
        require(msg.sender == owner); 
        _;
    }
	
	modifier canTransfer() {
		require(transferable == true);
		_;
	}
	
     
    event Burn(address indexed from, uint value);
	 
    event Freeze(address indexed from, uint value);
	 
    event Unfreeze(address indexed from, uint value);

     
    function BDToken() public {
		totalSupply = 100*10**26;  
		name = "BaoDe Token";
		symbol = "BDT";
		balances[msg.sender] = totalSupply;  
		owner = msg.sender;
		emit Transfer(address(0), msg.sender, totalSupply);
    }

     
    function transfer(address _to, uint _value) public canTransfer returns (bool success) {
		require(_to != address(0)); 
		require(_value > 0);
        require(balances[msg.sender] >= _value);  
        require(balances[_to] + _value >= balances[_to]);  
		
		balances[msg.sender] = balances[msg.sender].sub(_value);  
        balances[_to] = balances[_to].add(_value);   
        emit Transfer(msg.sender, _to, _value);    
		return true;
    }

	 
    function transferFrom(address _from, address _to, uint _value) public canTransfer returns (bool success) {
        uint allowance = allowed[_from][msg.sender];
		require(_to != address(0)); 
		require(_value > 0);
		require(balances[_from] >= _value);  
		require(allowance >= _value);  
        require(balances[_to] + _value >= balances[_to]);  
        
        balances[_from] = balances[_from].sub(_value);       
        balances[_to] = balances[_to].add(_value);           
		if (allowance < MAX_UINT256) {
			allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		}
        emit Transfer(_from, _to, _value);
        return true;
    }
	
     
    function approve(address _spender, uint _value) public canTransfer returns (bool success) {
		require(_value >= 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
	function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

	function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
	
	function freezeOf(address _owner) public view returns (uint freeze) {
        return freezes[_owner];
    }
	
    function burn(uint _value) public canTransfer returns (bool success) {
		require(balances[msg.sender] >= _value);  
		require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);   
        totalSupply = totalSupply.sub(_value);                     
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint _value) public canTransfer returns (bool success) {
		require(balances[msg.sender] >= _value);  
		require(_value > 0);
		require(freezes[msg.sender] + _value >= freezes[msg.sender]);  
		
        balances[msg.sender] = balances[msg.sender].sub(_value);   
        freezes[msg.sender] = freezes[msg.sender].add(_value);  
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint _value) public canTransfer returns (bool success) {
		require(freezes[msg.sender] >= _value);   
		require(_value > 0);
		require(balances[msg.sender] + _value >= balances[msg.sender]);  
		
        freezes[msg.sender] = freezes[msg.sender].sub(_value);   
		balances[msg.sender] = balances[msg.sender].add(_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	 
	function transferForMultiAddresses(address[] _addresses, uint[] _amounts) public canTransfer returns (bool) {
		for (uint i = 0; i < _addresses.length; i++) {
		  require(_addresses[i] != address(0));  
		  require(_amounts[i] > 0);
		  require(balances[msg.sender] >= _amounts[i]);  
          require(balances[_addresses[i]] + _amounts[i] >= balances[_addresses[i]]);  

		   
		  balances[msg.sender] = balances[msg.sender].sub(_amounts[i]);
		  balances[_addresses[i]] = balances[_addresses[i]].add(_amounts[i]);
		  emit Transfer(msg.sender, _addresses[i], _amounts[i]);
		}
		return true;
	}
	
	function stop() public onlyOwner {
        transferable = false;
    }

    function start() public onlyOwner {
        transferable = true;
    }
	
	function transferOwnership(address newOwner) public onlyOwner {
		owner = newOwner;
	}
	
	 
	function withdrawEther(uint amount) public onlyOwner {
		require(amount > 0);
		owner.transfer(amount);
	}
	
	 
	function() public payable {
    }
	
}