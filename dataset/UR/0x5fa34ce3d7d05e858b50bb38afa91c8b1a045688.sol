 

 

pragma solidity ^0.4.24;
contract Token {

     
    function totalSupply() public pure returns (uint256) {}

     
     
    function balanceOf(address) public payable returns (uint256) {}

     
     
     
     
    function transfer(address , uint256 ) public payable returns (bool) {}

     
     
     
     
     
    function transferFrom(address , address , uint256 ) public payable returns (bool ) {}

     
     
     
     
    function approve(address , uint256 ) public payable returns (bool ) {}

     
     
     
    function allowance(address , address ) public payable returns (uint256 ) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public payable returns (bool ) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public payable returns (bool ) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public payable  returns (uint256 ) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public payable returns (bool ) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public payable returns (uint256 a ) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

 

contract SmartCityCoinTestNet is StandardToken {

    function () public {
         
        revert();
    }

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H0.1';        

    constructor (
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
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public payable returns (bool )  {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
}