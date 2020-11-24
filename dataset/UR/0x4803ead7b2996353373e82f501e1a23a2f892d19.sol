 

pragma solidity ^0.4.24;

 

 
 
 contract ContractReceiver {
     
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    
    
    function tokenFallback(address _from, uint _value, bytes _data) public pure {
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
      
       
    }
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

  event Transfer(address indexed from, address indexed to, uint value);
  event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

 

 


  
contract TokenMintERC223Token is ERC223Token {

  constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply, address feeReceiver, address tokenOwnerAddress) public payable {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _totalSupply;

     
    balances[tokenOwnerAddress] = totalSupply;
    emit Transfer(address(0), tokenOwnerAddress, totalSupply);
    emit Transfer(address(0), tokenOwnerAddress, totalSupply, "");

     
    feeReceiver.transfer(msg.value);
  }
}