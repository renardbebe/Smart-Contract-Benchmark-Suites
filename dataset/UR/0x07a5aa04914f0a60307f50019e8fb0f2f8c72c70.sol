 

pragma solidity ^0.4.11;
 
contract ERC223 {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
  
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    function totalSupply() public view returns (uint256 _supply);
 
    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
 
 
contract ContractReceiver {                
    function tokenFallback(address _from, uint _value, bytes _data) public;
}
 
  
 
 
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
 
    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
        return x + y;
    }
 
    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y) revert();
        return x - y;
    }
 
    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) revert();
        return x * y;
    }
}
 
contract TstToken is ERC223, SafeMath {
 
    mapping(address => uint) balances;
    
    string public name = "Test";
    string public symbol = "TST";
    uint8 public decimals = 8;
    uint256 public totalSupply = 3000000000000000;
 
     
    event Transfer(address indexed from, address indexed to, uint value);
    
    constructor () public {
        balances[tx.origin] = totalSupply;
    }
 
     
    function name() public view returns (string _name) {
        return name;
    }
     
    function symbol() public view returns (string _symbol) {
        return symbol;
    }
     
    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }
     
    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }
 
    
     
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {        
        if(isContract(_to)) {
            if (balanceOf(msg.sender) < _value) revert();
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        else {
            return transferToAddress(_to, _value, false, _data);
        }
    }  
    
  
     
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {        
        if(isContract(_to)) {
            return transferToContract(_to, _value, false, _data);
        }
        else {
            return transferToAddress(_to, _value, false, _data);
        }
    }  
    
     
     
    function transfer(address _to, uint _value) public returns (bool success) {
        
       
       
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, true, empty);
        }
        else {
            return transferToAddress(_to, _value, true, empty);
        }
    }  
  
    
  
     
    function transferToAddress(address _to, uint _value, bool isErc20Transfer, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        if (isErc20Transfer)
            emit Transfer(msg.sender, _to, _value);
        else
            emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
     
    function transferToContract(address _to, uint _value, bool isErc20Transfer, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        if (isErc20Transfer)
            emit Transfer(msg.sender, _to, _value);
        else
            emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }  
  
     
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
               
              length := extcodesize(_addr)
        }
        return (length>0);
    }
  
    function balanceOf(address _owner) public view returns (uint balance) {
      return balances[_owner];
    }
}