 

 
 
pragma solidity ^0.4.18;

contract ABC {

    uint256 constant MAX_UINT256 = 2**256 - 1;

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'ABCv1.0';        
    address public owner;
    uint256 public totalSupply;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FrozenFunds(address indexed _target, bool _frozen);

     function ABC(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) public {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
        owner = msg.sender;                                   
        transfer(msg.sender, _initialAmount);                 
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
        require(frozenAccount[msg.sender] != true && frozenAccount[_to] != true);
         
         
         
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
         
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(frozenAccount[_from] != true && frozenAccount[_to] != true);

         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        uint256 allowance = allowed[_from][msg.sender];
         
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
         
        require(frozenAccount[_spender] != true);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
         
        require(frozenAccount[_spender] != true);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

         
         
         
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function issueNew(uint256 _issueQty) public returns (bool success) {
        require(msg.sender == owner);
        balances[owner] += _issueQty;
		totalSupply += _issueQty;
		emit Transfer(msg.sender, owner, _issueQty); 
        return true;
    }
	
	function vanishToken( uint256 _vanishQty ) public returns (bool success) {
        require(msg.sender == owner);
        require(balances[owner] >= _vanishQty);
        balances[owner] -= _vanishQty;
		totalSupply -= _vanishQty;
		emit Transfer(msg.sender, owner, _vanishQty); 
        return true;
    }

	function freezeAccount(address _target, bool _freeze) public returns (bool success) {
        require(msg.sender == owner);
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
        return true;
    }

    function transferOwnership(address _newOwner) public returns (bool success) {
        require(msg.sender == owner);
        owner = _newOwner;
        return true;
    }

    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}