 

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

contract DroplexToken is SafeMath {
     
    string public standard = 'ERC20';
    string public name = 'Droplex Token';
    string public symbol = 'DROP';
    uint8 public decimals = 0;
    uint256 public totalSupply = 30000000;
    address public owner = 0xaBE3d12e5518BF8266bB91B56913962ce1F77CF4;
     

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function DroplexToken() {
        owner = 0xaBE3d12e5518BF8266bB91B56913962ce1F77CF4;
        balanceOf[owner] = 30000000;               
        totalSupply = 30000000;                    
    }

     
    function transfer(address _to, uint256 _value) returns (bool success){
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender],_value);                      
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);                             
        Transfer(msg.sender, _to, _value);                    
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        var _allowance = allowance[_from][msg.sender];
        balanceOf[_from] = safeSub(balanceOf[_from],_value);  
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);      
        allowance[_from][msg.sender] = safeSub(_allowance,_value);
        Transfer(_from, _to, _value);
        return true;
    }

}