 

 
pragma solidity ^0.4.6;

contract SafeMath {
     

    function safeMul(uint a, uint b) internal returns (uint) {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
      assert(b <= a);
      return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
      uint c = a + b;
      assert(c>=a && c>=b);
      return c;
    }

    function assert(bool assertion) internal {
      if (!assertion) throw;
    }
}

 
contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 
contract StandardToken is Token {

     

    function transfer(address _to, uint256 _value) returns (bool success) {
       
       
       
      if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
      return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
      return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

}


 
contract AntiqueCoin is StandardToken, SafeMath {

    string public name = "AntiqueCoin";
    string public symbol = "1XNC";
    uint public decimals = 18;
    address public founder = 0x0;
    uint private counter = 0;

    mapping (bytes32 => address) public antiques;


    event RegistrationAntique(bytes32 hash);
    event TransferAntique(bytes32 filehash, address from, address to);

     

    function AntiqueCoin(address _founder,  uint256 _totalSupply) {
      founder = _founder;
      balances[_founder] = _totalSupply;
      totalSupply = _totalSupply;
    }

    function registerAntique(bytes32 _fileHash) returns (bool success){
      if (msg.sender != founder) throw;
     
      antiques[_fileHash] = msg.sender;
      RegistrationAntique(_fileHash);
      return true;
    }


    function transferAntique(address _to, bytes32 _fileHash) returns (bool success){
      if (antiques[_fileHash] != msg.sender) throw;
      antiques[_fileHash] = _to;
      TransferAntique(_fileHash, msg.sender, _to);
      return true;
    }


    function changeFounder(address _newFounder) returns (bool success){
      if (msg.sender!=founder) throw;
      balances[_newFounder] = safeAdd(balances[_newFounder], balances[founder]);
      balances[founder] = 0;
      founder = _newFounder;
      return true;
    }

    function() {
      throw;
    }

}