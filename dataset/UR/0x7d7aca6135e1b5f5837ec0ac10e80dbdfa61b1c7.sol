 

pragma solidity ^0.4.15;

 

  

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 

contract Token {

     
    string public name;
    string public symbol;
    uint8 public decimals; 
    string public version = 'v1';
    uint256 public totalSupply;
    uint public price;
    bool locked;

    address rootAddress;
    address Owner;
    uint multiplier;  

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) freezed;


    event Transfer(address indexed from, address indexed to, uint256 value);
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


     
    function Token() {        
        locked = false;
        name = 'Token name'; 
        symbol = 'SYMBOL'; 
        decimals = 18; 
        multiplier = 10 ** uint(decimals);
        totalSupply = 1000000 * multiplier;  
        rootAddress = msg.sender;        
        Owner = msg.sender;
        balances[rootAddress] = totalSupply; 
    }


     

    function changeRoot(address _newrootAddress) onlyRoot returns(bool){
        rootAddress = _newrootAddress;
        return true;
    }

     

     
    function sendToken(address _token,address _to , uint _value) onlyOwner returns(bool) {
        ERC20Basic Token = ERC20Basic(_token);
        require(Token.transfer(_to, _value));
        return true;
    }

    function changeOwner(address _newOwner) onlyOwner returns(bool) {
        Owner = _newOwner;
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


    function burn(uint256 _value) onlyOwner returns(bool) {
        if ( balances[rootAddress] < _value ) revert();
        balances[rootAddress] = safeSub( balances[rootAddress] , _value );
        totalSupply = safeSub( totalSupply,  _value );
        Transfer(rootAddress, 0x0,_value);
        return true;
    }


     

    function isLocked() constant returns(bool) {
        return locked;
    }


     
    function transfer(address _to, uint _value) isUnlocked returns (bool success) {
        if (balances[msg.sender] < _value) return false;
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender,_to,_value);
        return true;
        }


    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {

        if ( locked && msg.sender != Owner && msg.sender != rootAddress ) return false; 
        if ( freezed[_from] || freezed[_to] ) return false;  
        if ( balances[_from] < _value ) return false;  
    	if ( _value > allowed[_from][msg.sender] ) return false;  

        balances[_from] = safeSub(balances[_from] , _value);  
        balances[_to] = safeAdd(balances[_to] , _value);  

        allowed[_from][msg.sender] = safeSub( allowed[_from][msg.sender] , _value );

        Transfer(_from,_to,_value);
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