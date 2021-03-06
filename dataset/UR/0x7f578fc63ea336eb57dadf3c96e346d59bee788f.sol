 

pragma solidity ^0.4.25;
 

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
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



contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint value);
  
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint;
    
  address public owner;
  
   
  bool public transferable = true;
  
  mapping(address => uint) balances;

   
  mapping (address => bool) public frozenAccount;

  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }
  
  modifier unFrozenAccount{
      require(!frozenAccount[msg.sender]);
      _;
  }
  
  modifier onlyOwner {
        require(msg.sender == owner);
        _;
  }
  
  modifier onlyTransferable {
      if (transferable) {
          _;
      } else {
          emit LiquidityAlarm("The liquidity is switched off");
          throw;
      }
  }
  
   
  event FrozenFunds(address _target, bool _frozen);
  
   
  event InvalidCaller(address indexed _from);
  
   
  event OwnershipTransferred(address indexed _from, address indexed to);
  
   
  event InvalidAccount(address indexed _from, bytes msg);
  
   
  event LiquidityAlarm(bytes msg);
  
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) unFrozenAccount onlyTransferable public returns (bool){
    if (frozenAccount[_to]) {
        emit InvalidAccount(_to, "The receiver account is frozen");
		return false;
    } else {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
		return true;
    } 
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

   
   
   
  function freezeAccount(address target, bool freeze) onlyOwner public {
      frozenAccount[target]=freeze;
      emit FrozenFunds(target, freeze);
    }
  
  function accountFrozenStatus(address target) public view returns (bool frozen) {
      return frozenAccount[target];
  }
  
  function transferOwnership(address newOwner) onlyOwner public {
      if (newOwner != address(0)) {
          address oldOwner=owner;
          owner = newOwner;
          emit OwnershipTransferred(oldOwner, owner);
        }
  }
  
  function switchLiquidity (bool _transferable) onlyOwner public returns (bool success) {
      transferable=_transferable;
      return true;
  }
  
  function liquidityStatus () public view returns (bool _transferable) {
      return transferable;
  }
}


contract StandardToken is BasicToken {

  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) unFrozenAccount onlyTransferable public returns (bool){
    uint256 _allowance = allowed[_from][msg.sender];

     
    require(!frozenAccount[_from] && !frozenAccount[_to]);
    
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
	return true;
  }

  function approve(address _spender, uint _value) unFrozenAccount public returns (bool){
    require(_value > 0);

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
	return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    return allowed[_owner][_spender];
  }	
  
}


contract ChainFarmToken is StandardToken {
    string public name = "ChainFarm";
    string public symbol = "CFC";
    uint public decimals = 8;
 
    constructor() public {
        owner = msg.sender;
        totalSupply = 1000000000 * 10 ** decimals;
        balances[owner] = totalSupply;
    }
	
    function () public payable {
        revert();
    }
}