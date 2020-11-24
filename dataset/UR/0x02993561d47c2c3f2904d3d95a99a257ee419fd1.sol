 

pragma solidity ^0.4.24;

 
contract ContractReceiver {
  function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

 
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

  

 /* https: 
contract SafeMathERC223 {
  uint256 constant public MAX_UINT256 =
  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
    if (x > MAX_UINT256 - y) revert();
    return x + y;
  }

  function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    if (x < y) revert();
    return x - y;
  }

  function safeMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    if (y == 0) return 0;
    if (x > MAX_UINT256 / y) revert();
    return x * y;
  }
}


contract ERC223Token is ERC223, SafeMathERC223 {
  mapping(address => uint) public balances;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

   
  constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
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
    if (isContract(_to)) {
      return transferToContractCustom(msg.sender, _to, _value, _data, _custom_fallback);
    } else {
      return transferToAddress(msg.sender, _to, _value, _data);
    }
  }

   
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    if (isContract(_to)) {
      return transferToContract(msg.sender, _to, _value, _data);
    } else {
      return transferToAddress(msg.sender, _to, _value, _data);
    }
  }

   
   
  function transfer(address _to, uint _value) public returns (bool success) {
     
     
    bytes memory empty;
    if (isContract(_to)) {
      return transferToContract(msg.sender, _to, _value, empty);
    } else {
      return transferToAddress(msg.sender, _to, _value, empty);
    }
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

   
  function isContract(address _addr) internal view returns (bool is_contract) {
    uint length;
    assembly {  
           
          length := extcodesize(_addr)
    }
    return (length > 0);
  }

   
  function transferToAddress(address _from, address _to, uint _value, bytes _data) internal returns (bool success) {
    if (balanceOf(_from) < _value) revert();
    balances[_from] = safeSub(balanceOf(_from), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    emit Transfer(_from, _to, _value, _data);
    return true;
  }

   
  function transferToContract(address _from, address _to, uint _value, bytes _data) internal returns (bool success) {
    if (balanceOf(_from) < _value) revert();
    balances[_from] = safeSub(balanceOf(_from), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(_from, _value, _data);
    emit Transfer(_from, _to, _value, _data);
    return true;
  }

   
  function transferToContractCustom(address _from, address _to, uint _value, bytes _data, string _custom_fallback) internal returns (bool success) {
    if (balanceOf(_from) < _value) revert();
    balances[_from] = safeSub(balanceOf(_from), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
     
    assert(_to.call.value(0)(abi.encodeWithSignature(_custom_fallback, _from, _value, _data)));
    emit Transfer(_from, _to, _value, _data);
    return true;
  }
}