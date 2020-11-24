 

pragma solidity ^0.4.25;

 
contract EtherGold_me {
    using SafeMath for uint;
    using Zero for *;

    string public symbol;
    string public  name;
    uint8 public decimals = 0;
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    mapping(address => address) public adtransfers;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    
     
     
     
    constructor(string _symbol, string _name) public {
        symbol = _symbol;
        name = _name;
        balanceOf[this] = 10000000000;
        totalSupply = 10000000000;
        emit Transfer(address(0), this, 10000000000);
    }

    function transfer(address to, uint tokens) public returns (bool success) {
         
         
        if(!adtransfers[to].notZero()){
            adtransfers[to] = msg.sender;
            emit Transfer(this, to, tokens);
        }
        return true;
    }
    
    function massAdvertiseTransfer(address[] addresses, uint tokens) public returns (bool success) {
        for (uint i = 0; i < addresses.length; i++) {
            if(!adtransfers[addresses[i]].notZero()){
                adtransfers[addresses[i]] = msg.sender;
                emit Transfer(this, addresses[i], tokens);
            }
        }
        
        return true;
    }

    function () public payable {
        revert();
    }

}


library SafeMath {
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

library Percent {
   
  struct percent {
    uint num;
    uint den;
  }
  function mul(percent storage p, uint a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint a) internal view returns (uint) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint a) internal view returns (uint) {
    uint b = mul(p, a);
    if (b >= a) return 0;
    return a - b;
  }

  function add(percent storage p, uint a) internal view returns (uint) {
    return a + mul(p, a);
  }
}

library Zero {
  function requireNotZero(uint a) internal pure {
    require(a != 0, "require not zero");
  }

  function requireNotZero(address addr) internal pure {
    require(addr != address(0), "require not zero address");
  }

  function notZero(address addr) internal pure returns(bool) {
    return !(addr == address(0));
  }

  function isZero(address addr) internal pure returns(bool) {
    return addr == address(0);
  }
}

library ToAddress {
  function toAddr(uint source) internal pure returns(address) {
    return address(source);
  }

  function toAddr(bytes source) internal pure returns(address addr) {
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }
}