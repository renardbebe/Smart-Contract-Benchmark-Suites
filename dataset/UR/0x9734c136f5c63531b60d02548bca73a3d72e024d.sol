 

pragma solidity ^0.4.2;
 

 
contract Token {
     
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is Token {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
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

}


 
 
contract HumaniqToken is StandardToken {

     
    address public emissionContractAddress = 0x0;

     
    string constant public name = "HumaniQ";
    string constant public symbol = "HMQ";
    uint8 constant public decimals = 0;

    address public founder = 0x0;
    bool locked = true;
     
    modifier onlyFounder() {
         
        if (msg.sender != founder) {
            throw;
        }
        _;
    }

    modifier isCrowdfundingContract() {
         
        if (msg.sender != emissionContractAddress) {
            throw;
        }
        _;
    }

    modifier unlocked() {
         
        if (locked == true) {
            throw;
        }
        _;
    }

     

     
     
     
    function issueTokens(address _for, uint tokenCount)
        external
        payable
        isCrowdfundingContract
        returns (bool)
    {
        if (tokenCount == 0) {
            return false;
        }
        balances[_for] += tokenCount;
        totalSupply += tokenCount;
        return true;
    }

    function transfer(address _to, uint256 _value)
        unlocked
        returns (bool success)
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
        unlocked
        returns (bool success)
    {
        return super.transferFrom(_from, _to, _value);
    }

     
     
    function changeEmissionContractAddress(address newAddress)
        external
        onlyFounder
        returns (bool)
    {
        emissionContractAddress = newAddress;
    }

     
     
    function lock(bool value)
        external
        onlyFounder
    {
        locked = value;
    }

     
     
    function HumaniqToken(address _founder)
    {
        totalSupply = 0;
        founder = _founder;
    }
}