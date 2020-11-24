 

pragma solidity ^0.4.21;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

 
contract ERC20 {
    uint256 public totalSupply;

     
    function totalSupply() constant public returns (uint256 _supply);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool ok);
    function transfer(address to, uint256 value, bytes data) public returns (bool ok);
    function name() constant public returns (string _name);
    function symbol() constant public returns (string _symbol);
    function decimals() constant public returns (uint8 _decimals);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FrozenFunds(address target, bool frozen);
	event Burn(address indexed from, uint256 value);
    
}

 
contract SafeMath {
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y) revert();
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) revert();
        return x * y;
    }
}

 
contract ContractReceiver {
	struct TKN {
        address sender;
        uint256 value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) public pure {
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
    }
	
	function rewiewToken  () public pure returns (address, uint, bytes, bytes4) {
        TKN memory tkn;
        return (tkn.sender, tkn.value, tkn.data, tkn.sig);
    }
}

 
contract TokenRK50Z is ERC20, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    bool public SC_locked = false;
    bool public tokenCreated = false;
	uint public DateCreateToken;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => bool) public frozenAccount;
	mapping(address => bool) public SmartContract_Allowed;

     
     
    function TokenRK50Z() public {
         
        require(tokenCreated == false);

        owner = msg.sender;
        
		name = "RK50Z";
        symbol = "RK50Z";
        decimals = 5;
        totalSupply = 500000000 * 10 ** uint256(decimals);
        balances[owner] = totalSupply;
        emit Transfer(owner, owner, totalSupply);
		
        tokenCreated = true;

         
        require(balances[owner] > 0);

		 
		DateCreateToken = now;
    }
	
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

	 
    function DateCreateToken() public view returns (uint256 _DateCreateToken) {
		return DateCreateToken;
	}
   	
     
    function name() view public returns (string _name) {
		return name;
	}
	
     
    function symbol() public view returns (string _symbol) {
		return symbol;
    }

     
    function decimals() public view returns (uint8 _decimals) {	
		return decimals;
    }

     
    function totalSupply() public view returns (uint256 _totalSupply) {
		return totalSupply;
	}
	
	 
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

	 
    function SmartContract_Allowed(address _target) constant public returns (bool _sc_address_allowed) {
        return SmartContract_Allowed[_target];
    }

     
    function transfer(address _to, uint256 _value, bytes _data) public  returns (bool success) {
         
         
		require(!SC_locked);
		require(!frozenAccount[msg.sender]);
		require(!frozenAccount[_to]);
		
        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } 
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
         
        require(!SC_locked);
		require(!frozenAccount[msg.sender]);
		require(!frozenAccount[_to]);

         
         
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } 
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

	 
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

     
    function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
        require(SmartContract_Allowed[_to]);
		
		if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

   
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        require(!SC_locked);
		require(!frozenAccount[_from]);
		require(!frozenAccount[_to]);
		
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        balances[_from] = safeSub(balanceOf(_from), _value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
         
        require(!SC_locked);
		require(!frozenAccount[msg.sender]);
		require(!frozenAccount[_spender]);
		
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
		return allowed[_owner][_spender];
    }
	
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        require(!SC_locked);
		require(!frozenAccount[msg.sender]);
		require(!frozenAccount[_spender]);
		
		tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
	
	 
    function () public payable { 
		if(msg.sender != owner) { revert(); }
    }

	 
    function OWN_contractlocked(bool _locked) onlyOwner public {
        SC_locked = _locked;
    }
	
	 
    function OWN_burnToken(address _from, uint256 _value)  onlyOwner public returns (bool success) {
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
	
	 
    function OWN_mintToken(uint256 mintedAmount) onlyOwner public {
         
        balances[owner] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, owner, mintedAmount);
    }
	
	 
    function OWN_freezeAddress(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
		
	 
    function OWN_kill() onlyOwner public { 
		selfdestruct(owner); 
    }
	
	 
	function OWN_transferOwnership(address newOwner) onlyOwner public {
         
        if (!isContract(newOwner)) {	
			owner = newOwner;
		}
    }
	
	 
    function OWN_SmartContract_Allowed(address target, bool _allowed) onlyOwner public {
		 
        if (isContract(target)) {
			SmartContract_Allowed[target] = _allowed;
		}
    }

	 
	function OWN_DistributeTokenAdmin_Multi(address[] addresses, uint256 _value, bool freeze) onlyOwner public {
		for (uint i = 0; i < addresses.length; i++) {
			 
			frozenAccount[addresses[i]] = freeze;
			emit FrozenFunds(addresses[i], freeze);
			
			bytes memory empty;
			if (isContract(addresses[i])) {
				transferToContract(addresses[i], _value, empty);
			} 
			else {
				transferToAddress(addresses[i], _value, empty);
			}
		}
	}
}