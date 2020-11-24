 

pragma solidity ^0.4.9;

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  
  function name() constant returns (string _name);
  function symbol() constant returns (string _symbol);
  function decimals() constant returns (uint8 _decimals);
  function totalSupply() constant returns (uint256 _supply);

  function transfer(address to, uint value) returns (bool ok);
  function transfer(address to, uint value, bytes data) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ContractReceiver {
     
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    
    
    function tokenFallback(address _from, uint _value, bytes _data){
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
      
       
    }
}
  
 
 
  
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    assert(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    assert(!halted);
    _;
  }

  modifier onlyInEmergency {
    assert(halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

contract ERC223Token is ERC223, SafeMath, Haltable {

  mapping(address => uint) balances;
  
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  
  
   
  function name() constant returns (string _name) {
      return name;
  }
   
  function symbol() constant returns (string _symbol) {
      return symbol;
  }
   
  function decimals() constant returns (uint8 _decimals) {
      return decimals;
  }
   
  function totalSupply() constant returns (uint256 _totalSupply) {
      return totalSupply;
  }
  
  

   
  function transfer(address _to, uint _value, bytes _data) returns (bool success) {
      
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}
  
   
   
  function transfer(address _to, uint _value) returns (bool success) {
      
     
     
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

 
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
             
            length := extcodesize(_addr)
        }
        if(length>0) {
            return true;
        }
        else {
            return false;
        }
    }

   
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    assert(balanceOf(msg.sender) >= _value);
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  
   
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    assert(balanceOf(msg.sender) >= _value);
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    ContractReceiver reciever = ContractReceiver(_to);
    reciever.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
}


  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  
  
}

contract ZontoToken is ERC223Token {

    address public beneficiary;
    event Buy(address indexed participant, uint tokens, uint eth);
    event GoalReached(uint amountRaised);

    uint public cap = 20000000000000;
    uint public price;
    uint public collectedTokens;
    uint public collectedEthers;

    uint public tokensSold = 0;
    uint public weiRaised = 0;
    uint public investorCount = 0;

    uint public startTime;
    uint public endTime;

    bool public presaleFinished = false;

   
    function ZontoToken() {
            
        name = "ZONTO Token";
        symbol = "ZONTO";
        decimals = 8;
        totalSupply = 500000000000000;
    
        balances[msg.sender] = totalSupply;
        
        beneficiary = 0x0980eaD74d176025F2962f8b5535346c77ffd2f5;
        price = 150;
        startTime = 1502706677;
        endTime = startTime + 14 * 1 days;
        
    }
    
    modifier onlyAfter(uint time) {
        assert(now >= time);
        _;
    }

    modifier onlyBefore(uint time) {
        assert(now <= time);
        _;
    }
    
    function () payable stopInEmergency {
        assert(msg.value >= 0.01 * 1 ether);
        doPurchase();
    }
    
    function doPurchase() private onlyAfter(startTime) onlyBefore(endTime) {

        assert(!presaleFinished);
        
        uint tokens = msg.value * price / 10000000000;

        if (balanceOf(msg.sender) == 0) investorCount++;
        
        balances[owner] -= tokens;
        balances[msg.sender] += tokens;
        
        collectedTokens = safeAdd(collectedTokens, tokens);
        collectedEthers = safeAdd(collectedEthers, msg.value);
        
        weiRaised = safeAdd(weiRaised, msg.value);
        tokensSold = safeAdd(tokensSold, tokens);
        
        bytes memory empty;
        Transfer(owner, msg.sender, tokens, empty);
        Transfer(owner, msg.sender, tokens);
        
        Buy(msg.sender, tokens, msg.value);
        
        if (collectedTokens >= cap) {
            GoalReached(collectedTokens);
        }

    }
    
    function withdraw() onlyOwner onlyAfter(endTime) returns (bool) {
        if (!beneficiary.send(collectedEthers)) {
            return false;
        }
        presaleFinished = true;
        return true;
    }
    
    
}