 

pragma solidity ^0.4.24;


contract Owned {
   address public owner;

   constructor() {
     owner = msg.sender;
   }

   modifier onlyOwner {
     require(msg.sender == owner);
     _;
   }

   function transferOwnership (address newOwner) onlyOwner {
     owner = newOwner;
   }

}


contract Token is Owned{

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
    uint public totalSupply;
    uint8 constant public decimals = 18;
     uint constant MAX_UINT = 2**256 - 1;
     
    string public name;
    string public symbol;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Burn (address indexed from, uint256 value);


    constructor(string tokenName, string tokenSymbol, uint initialSupply) {
        totalSupply = initialSupply*10**uint256(decimals);
        name = tokenName;
        symbol = tokenSymbol;
        balances[msg.sender] = totalSupply;
    }


     
    function totalSupply() constant returns (uint) {

        return totalSupply;
    }


  
     
     
     
 function transfer(address _to, uint _value) returns (bool) {
         
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }




     
     
    
    function balanceOf(address _owner) constant returns (uint256) {
        return balances[_owner];
    }


     
     
     
     
    function approve(address _spender, uint _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
     
     
    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }



   
     
     
     
     
        function transferFrom(address _from, address _to, uint _value) returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
 
function mintToken (address _target, uint _mintedAmount) onlyOwner {
      balances[_target] += _mintedAmount;
      totalSupply += _mintedAmount;
      emit Transfer(0, owner, _mintedAmount);
      emit Transfer(owner, _target, _mintedAmount);
  }

  function burn(uint _value) onlyOwner returns (bool success) {
    require (balances[msg.sender] >= _value);
    balances[msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }

}