 

pragma solidity ^0.4.18;


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract Token {

     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
        require(_to != 0x0);
         
        require(balances[msg.sender] >= _value);
         
        require(balances[_to] + _value > balances[_to]);

        uint previousBalances = balances[msg.sender] + balances[_to];
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
         
        assert(balances[msg.sender] + balances[_to] == previousBalances);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(_to != 0x0);
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);

        uint previousBalances = balances[_from] + balances[_to];
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);

        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;
}

contract PDAToken is StandardToken {

    function () payable public {
         
         
        require(false);
    }

    string public constant name = "PDACoin";   
    string public constant symbol = "PDA";
    uint256 private constant _INITIAL_SUPPLY = 15*(10**26);
    uint8 public decimals = 18;  
    uint256 public totalSupply;            
     

    function PDAToken(
    ) public {
         
        balances[msg.sender] = _INITIAL_SUPPLY;
        totalSupply = _INITIAL_SUPPLY;
       
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}