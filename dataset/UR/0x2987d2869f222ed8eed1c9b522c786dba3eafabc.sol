 

pragma solidity ^0.5.1;

contract SafeMath {
 uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

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

contract Unic is SafeMath {
  mapping(address => uint) public balances;
  string public name = "UNICORN";
  string public symbol = "UNIC";
  uint8 public decimals = 18;
  uint256 public totalSupply = 210000000000000000000000000;

  event Transfer(address indexed from, address indexed to, uint value);
    event Burn(address indexed from, uint256 value);

  constructor() public payable { balances[msg.sender] = totalSupply; }

  function isContract(address ethAddress) private view returns (bool) {
    uint length;
    assembly { length := extcodesize(ethAddress) }
    return (length>0);
  }

  function transfer(address to, uint value) public returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], value);
    balances[to] = safeAdd(balances[to], value);
    if(isContract(to)) {
      ITokenRecipient receiver = ITokenRecipient(to);
      receiver.tokenFallback(msg.sender, value);
    }
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function burn(uint256 value) public returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], value);
    totalSupply = safeSub(totalSupply,value); 
    emit Burn(msg.sender, value);
    return true;
  }

  function balanceOf(address ethAddress) public view returns (uint balance) {
    return balances[ethAddress];
  }
}

contract ITokenRecipient {
  function tokenFallback(address from, uint value) public;
}