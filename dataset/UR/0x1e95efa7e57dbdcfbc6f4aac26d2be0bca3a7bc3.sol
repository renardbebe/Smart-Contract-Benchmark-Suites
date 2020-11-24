 

pragma solidity ^0.4.24;


 
contract Burnable {
   
   
   
  function _burnTokens(address account, uint value) internal;
  event Burned(address account, uint value);
}

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

  event Error(string _t);

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract HoldAssistant is Ownable {

	struct stholdPeriod {
        uint256 startsAtTime;
        uint256 endsAtTime;
		uint256 balance;
    }
    mapping (address => stholdPeriod) private holdPeriod;

	event Log_AdminHold(address _holder, uint _balance, bool _status);
	function adminHold(address _holder, uint _balance, bool _status) public returns (bool) {
		emit Log_AdminHold(_holder, _balance, _status);
		return true;
	}

	event Log_Hold(address _holder, uint _balance, bool _status);
	function hold(address _holder, uint _balance, bool _status) public returns (bool) {
		emit Log_Hold(_holder, _balance, _status);
		return true;
	}

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract StandardToken is Burnable, Pausable {
    using SafeMath for uint;

    uint private total_supply;
    uint public decimals;

     
    mapping (address => uint) private balances;
    mapping (address => mapping (address => uint)) private allowed;

     
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

     
    constructor(uint supply, uint token_decimals, address token_retriever) public {
        decimals                    = token_decimals;
        total_supply                = supply * uint(10) ** decimals ;  
        balances[token_retriever]   = total_supply;                    
    }

    function totalSupply() public view returns (uint) {
        return total_supply;
    }

     
    function balanceOf(address account) public view returns (uint balance) {
        return balances[account];
    }

     
    function allowance(address account, address spender) public view returns (uint remaining) {
        return allowed[account][spender];
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                         
        require(balances[_from] >= _value);         
        require(balances[_to].add(_value) >= balances[_to]);

         
        uint previousBalances = balances[_from].add(balances[_to]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to]  = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);

         
        assert(balances[_from].add(balances[_to]) == previousBalances);
    }

    function transfer(address _to, uint _value) public whenNotPaused returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);      
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub( _value);
        _transfer(_from, _to, _value);
        return true;
    }

    function _approve(address _holder, address _spender, uint _value) internal {
        require(_value <= total_supply);
        require(_value >= 0);
        allowed[_holder][_spender] = _value;
        emit Approval(_holder, _spender,_value);
    }
    function approve(address _spender, uint _value) public returns (bool success) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function safeApprove(address _spender, uint _currentValue, uint _value)  public returns (bool success) {
        require(allowed[msg.sender][_spender] == _currentValue);
        _approve(msg.sender, _spender, _value);
        return true;
    }

     
    function _burnTokens(address from, uint _value) internal {
        require(balances[from] >= _value);                     
        balances[from] = balances[from].sub(_value);     
        total_supply = total_supply.sub(_value);                     
        emit  Burned(from, _value);
    }

    function burn(uint _value) public whenNotPaused returns (bool success) {
        _burnTokens(msg.sender,_value);
        return true;
    }
}

 
contract HoldableToken is StandardToken {

	 
    mapping (address => bool) private holdFlag;

     
    address public holdAssistantAddr = address(0);

	function holded(address _account) public view returns(bool) {
		return holdFlag[_account];
	}

    function adminHold(bool _status) public onlyOwner returns (bool) {
        holdFlag[msg.sender] = _status;

         
        if (address(0) != holdAssistantAddr) {
            HoldAssistant(holdAssistantAddr).adminHold(msg.sender, balanceOf(msg.sender), _status);
        }
        emit Log_AdminHold(msg.sender, block.number, balanceOf(msg.sender), _status);
		return true;
    }
    function hold(bool _status) public returns (bool) {
        holdFlag[msg.sender] = _status;

         
        if (address(0) != holdAssistantAddr) {
            require(HoldAssistant(holdAssistantAddr).hold(msg.sender, balanceOf(msg.sender), _status));
        }
        emit Log_Hold(msg.sender, block.number, balanceOf(msg.sender), _status);
		return true;
    }
    event Log_Hold(address indexed _account, uint _holdBlock, uint _balance, bool _holded);
    event Log_AdminHold(address indexed _account, uint _holdBlock, uint _balance, bool _holded);

    function setHoldAssistant(address _newHoldAssistant) public onlyOwner returns(bool) {
        holdAssistantAddr = _newHoldAssistant;
        emit Log_SetHoldAssistant(holdAssistantAddr);
		return true;
    }
    event Log_SetHoldAssistant(address);

    modifier notHolded(address _account) {
        require(! holdFlag[_account]);
        _;
    }


  	 
  	function transfer(address to, uint value) public notHolded(msg.sender) returns (bool success) {
  		return super.transfer(to, value);
  	}

  	 
  	 
  	function transferFrom(address from, address to, uint value) public notHolded(from) returns (bool success) {
   	 	return super.transferFrom(from, to, value);
  	}

  	 
  	function burn(uint value) public notHolded(msg.sender) returns (bool success) {
    	return super.burn(value);
  	}

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
    assert(c >= a && c>=b);
    return c;
  }
}

 

 
contract Releasable is Ownable {

  address public releaseAgent;
  bool public released = false;
  mapping (address => bool) public Agents;

  event ReleaseAgent(address previous, address newAgent);

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
    releaseAgent = addr;
    emit ReleaseAgent(releaseAgent, addr);
  }

   
  function setAgent(address addr) onlyOwner inReleaseState(false) public returns(bool){
    Agents[addr] = true;
    emit Agent(addr,true);
    return true;
  }

   
  function resetAgent(address addr) onlyOwner inReleaseState(false) public returns(bool){
    Agents[addr] = false;
    emit Agent(addr,false);
    return true;
  }
    event Agent(address addr, bool status);

  function amIAgent() public view returns (bool) {
    return Agents[msg.sender];
  }

  function isAgent(address addr) public view   returns(bool) {
    return Agents[addr];
  }

   
  function releaseOperation() public onlyReleaseAgent {
        released = true;
		emit Released();
  }
  event Released();

   
  modifier canOperate(address sender) {
    require(released || Agents[sender]);
    _;
  }

   
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

   
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }
}

 
contract ReleasableToken is Releasable, HoldableToken {

   
  function transfer(address to, uint value) public canOperate(msg.sender) returns (bool success) {
   return super.transfer(to, value);
  }

   
   
  function transferFrom(address from, address to, uint value) public canOperate(from) returns (bool success) {
    return super.transferFrom(from, to, value);
  }

   
  function burn(uint value) public canOperate(msg.sender) returns (bool success) {
    return super.burn(value);
  }
}


contract ALIVE is ReleasableToken {

    string public name = "ALIVE";
    string public symbol = "AL ";

     
    constructor (uint supply, uint token_decimals, address token_retriever) StandardToken(supply, token_decimals, token_retriever) public { }
    
}