 

pragma solidity ^0.4.15;

 

contract ContractReceiver {   
    function tokenFallback(address _from, uint _value, bytes _data){
    }
}

  

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  
  function name() constant returns (string _name);
  function symbol() constant returns (string _symbol);
  function decimals() constant returns (uint8 _decimals);
  function totalSupply() constant returns (uint256 _supply);

  function transfer(address to, uint value) returns (bool ok);
  function transfer(address to, uint value, bytes data) returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) returns (bool ok);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

 

contract GXVCToken {

     
    string public name;
    string public symbol;
    uint8 public decimals; 
    string public version = 'v0.2';
    uint256 public totalSupply;
    bool locked;

    address rootAddress;
    address Owner;
    uint multiplier = 10000000000;  
    address swapperAddress;  

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) freezed; 


  	event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     

    modifier onlyOwner() {
        if ( msg.sender != rootAddress && msg.sender != Owner ) revert();
        _;
    }

    modifier onlyRoot() {
        if ( msg.sender != rootAddress ) revert();
        _;
    }

    modifier isUnlocked() {
    	if ( locked && msg.sender != rootAddress && msg.sender != Owner ) revert();
		_;    	
    }

    modifier isUnfreezed(address _to) {
    	if ( freezed[msg.sender] || freezed[_to] ) revert();
    	_;
    }


     
    function safeAdd(uint x, uint y) internal returns (uint z) {
        require((z = x + y) >= x);
    }
    function safeSub(uint x, uint y) internal returns (uint z) {
        require((z = x - y) <= x);
    }


     
    function GXVCToken() {        
        locked = true;
        totalSupply = 160000000 * multiplier;  
        name = 'Genevieve VC'; 
        symbol = 'GXVC'; 
        decimals = 10; 
        rootAddress = msg.sender;        
        Owner = msg.sender;       
        balances[rootAddress] = totalSupply; 
        allowed[rootAddress][swapperAddress] = totalSupply;
    }


	 

	function name() constant returns (string _name) {
	      return name;
	  }
	function symbol() constant returns (string _symbol) {
	      return symbol;
	  }
	function decimals() constant returns (uint8 _decimals) {
	      return decimals;
	  }
	function totalSupply() constant returns (uint256 _totalSupply) {
	      return totalSupply;
	  }


     

    function changeRoot(address _newrootAddress) onlyRoot returns(bool){
    		allowed[rootAddress][swapperAddress] = 0;  
            rootAddress = _newrootAddress;
            allowed[_newrootAddress][swapperAddress] = totalSupply;  
            return true;
    }


     

    function changeOwner(address _newOwner) onlyOwner returns(bool){
            Owner = _newOwner;
            return true;
    }

    function changeSwapperAdd(address _newSwapper) onlyOwner returns(bool){
    		allowed[rootAddress][swapperAddress] = 0;  
            swapperAddress = _newSwapper;
            allowed[rootAddress][_newSwapper] = totalSupply;  
            return true;
    }
       
    function unlock() onlyOwner returns(bool) {
        locked = false;
        return true;
    }

    function lock() onlyOwner returns(bool) {
        locked = true;
        return true;
    }

    function freeze(address _address) onlyOwner returns(bool) {
        freezed[_address] = true;
        return true;
    }

    function unfreeze(address _address) onlyOwner returns(bool) {
        freezed[_address] = false;
        return true;
    }

    function burn(uint256 _value) onlyOwner returns(bool) {
    	bytes memory empty;
        if ( balances[msg.sender] < _value ) revert();
        balances[msg.sender] = safeSub( balances[msg.sender] , _value );
        totalSupply = safeSub( totalSupply,  _value );
        Transfer(msg.sender, 0x0, _value , empty);
        return true;
    }


     
    function isFreezed(address _address) constant returns(bool) {
        return freezed[_address];
    }

    function isLocked() constant returns(bool) {
        return locked;
    }

   

   
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) isUnlocked isUnfreezed(_to) returns (bool success) {
      
    if(isContract(_to)) {
        if (balances[msg.sender] < _value) return false;
        balances[msg.sender] = safeSub( balances[msg.sender] , _value );
        balances[_to] = safeAdd( balances[_to] , _value );
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}

   
  function transfer(address _to, uint _value, bytes _data) isUnlocked isUnfreezed(_to) returns (bool success) {
      
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}


   
   
  function transfer(address _to, uint _value) isUnlocked isUnfreezed(_to) returns (bool success) {

    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

 
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
             
            length := extcodesize(_addr)
      }
      return (length>0);
    }

   
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balances[msg.sender] < _value) return false;
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }
  
   
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balances[msg.sender] < _value) return false;
    balances[msg.sender] = safeSub(balances[msg.sender] , _value);
    balances[_to] = safeAdd(balances[_to] , _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    return true;
}


    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {

        if ( locked && msg.sender != swapperAddress ) return false; 
        if ( freezed[_from] || freezed[_to] ) return false;  
        if ( balances[_from] < _value ) return false;  
		if ( _value > allowed[_from][msg.sender] ) return false;  

        balances[_from] = safeSub(balances[_from] , _value);  
        balances[_to] = safeAdd(balances[_to] , _value);  

        allowed[_from][msg.sender] = safeSub( allowed[_from][msg.sender] , _value );

        bytes memory empty;

        if ( isContract(_to) ) {
	        ContractReceiver receiver = ContractReceiver(_to);
	    	receiver.tokenFallback(_from, _value, empty);
		}

        Transfer(_from, _to, _value , empty);
        return true;
    }


    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint _value) returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns(uint256) {
        return allowed[_owner][_spender];
    }
}