 

pragma solidity ^0.4.13;

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtrCPCE(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
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
      } else {
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

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract CPCE is StandardToken, SafeMath {

    string public constant name = "CPC123";
    string public constant symbol = "CPC123";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    address public CPCEPrivateDeposit;
    address public CPCEIcoDeposit;
    address public CPCEFundDeposit;

    uint256 public constant factorial = 6;
    uint256 public constant CPCEPrivate = 150 * (10**factorial) * 10**decimals;  
    uint256 public constant CPCEIco = 150 * (10**factorial) * 10**decimals;  
    uint256 public constant CPCEFund = 380 * (10**factorial) * 10**decimals;  
  

     
    function CPCE()
    {
      CPCEPrivateDeposit = 0x960F9fD51b887F537268b2E4d88Eba995E87E5E0;
      CPCEIcoDeposit = 0x90d247AcdA80eBB6E950F0087171ea821B208541;
      CPCEFundDeposit = 0xF249A8353572e98545b37Dc16b3A5724053D7337;

      balances[CPCEPrivateDeposit] = CPCEPrivate;
      balances[CPCEIcoDeposit] = CPCEIco;
      balances[CPCEFundDeposit] = CPCEFund;
    }
}