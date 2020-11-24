 

pragma solidity ^0.4.11;

contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    function transfer(address to, uint value, bytes data)public ;
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}
 
 
contract ERC223ReceivingContract { 
 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}
 

 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure  returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  
}

contract StandardAuth is ERC223Interface {
    address      public  owner;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}

 
contract StandardToken is StandardAuth {
    using SafeMath for uint;

    mapping(address => uint) balances;  
    mapping(address => bool) optionPoolMembers;  
    string public name;
    string public symbol;
    uint8 public decimals = 9;
    uint256 public totalSupply;
    uint256 public optionPoolMembersUnlockTime = 1534168800;
    address public optionPool;
    uint256 public optionPoolTotalMax;
    uint256 public optionPoolTotal = 0;
    uint256 public optionPoolMembersAmount = 0;
    
    modifier verifyTheLock {
        if(optionPoolMembers[msg.sender] == true) {
            if(now < optionPoolMembersUnlockTime) {
                revert();
            } else {
                _;
            }
        } else {
            _;
        }
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
     
    function optionPool() public view returns (address _optionPool) {
        return optionPool;
    }
     
    function optionPoolTotal() public view returns (uint256 _optionPoolTotal) {
        return optionPoolTotal;
    }
     
    function optionPoolTotalMax() public view returns (uint256 _optionPoolTotalMax) {
        return optionPoolTotalMax;
    }
    
    function optionPoolBalance() public view returns (uint256 _optionPoolBalance) {
        return balances[optionPool];
    }
    
    function verifyOptionPoolMembers(address _add) public view returns (bool _verifyResults) {
        return optionPoolMembers[_add];
    }
    
    function optionPoolMembersAmount() public view returns (uint _optionPoolMembersAmount) {
        return optionPoolMembersAmount;
    }
    
    function optionPoolMembersUnlockTime() public view returns (uint _optionPoolMembersUnlockTime) {
        return optionPoolMembersUnlockTime;
    }
  
    constructor(uint256 _initialAmount, string _tokenName, string _tokenSymbol, address _tokenOptionPool, uint256 _tokenOptionPoolTotalMax) public  {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        symbol = _tokenSymbol;                                
        optionPool = _tokenOptionPool;
        optionPoolTotalMax = _tokenOptionPoolTotalMax;
    }
   
    function _verifyOptionPoolIncome(address _to, uint _value) private returns (bool _verifyIncomeResults) {
        if(msg.sender == optionPool && _to == owner){
          return false;
        }
        if(_to == optionPool) {
            if(optionPoolTotal + _value <= optionPoolTotalMax){
                optionPoolTotal = optionPoolTotal.add(_value);
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }
    
    function _verifyOptionPoolDefray(address _to) private returns (bool _verifyDefrayResults) {
        if(msg.sender == optionPool) {
            if(optionPoolMembers[_to] != true){
              optionPoolMembers[_to] = true;
              optionPoolMembersAmount++;
            }
        }
        
        return true;
    }
     
    function transfer(address _to, uint _value, bytes _data) public verifyTheLock {
         
         
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }
        
        if (balanceOf(msg.sender) < _value) revert();
        require(_verifyOptionPoolIncome(_to, _value));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        _verifyOptionPoolDefray(_to);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
    }
    
     
    function transfer(address _to, uint _value) public verifyTheLock {
        uint codeLength;
        bytes memory empty;

        assembly {
             
            codeLength := extcodesize(_to)
        }
        
        if (balanceOf(msg.sender) < _value) revert();
        require(_verifyOptionPoolIncome(_to, _value));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        _verifyOptionPoolDefray(_to);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value, empty);
    }
     
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }
}