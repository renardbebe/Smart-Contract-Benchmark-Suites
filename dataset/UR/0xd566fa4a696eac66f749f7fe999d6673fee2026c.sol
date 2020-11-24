 

pragma solidity ^0.4.16;
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

}

 
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Token is ERC20 { using SafeMath for uint;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

     
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) revert();
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
     
     
     
     
    function compareAndApprove(address _spender, uint256 _currentValue, uint256 _newValue) public returns(bool) {
        if (allowed[msg.sender][_spender] != _currentValue) {
            return false;
        }
            return approve(_spender, _newValue);
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
}

 
contract CHEXToken is Token { using SafeMath for uint;

    string public constant name = "CHEX Token";
    string public constant symbol = "CHX";
    uint public constant decimals = 18;
    uint public startBlock;  
    uint public endBlock;  

    address public founder;
    
    uint public tokenCap = 1000000000 * 10**decimals;  
    uint public crowdsaleAllocation = tokenCap;  
    uint public crowdsaleSupply = 0;

    uint public transferLockup = 5760;  
    bool public frozen = false;   

    uint public etherRaised = 0;  

    uint public constant MIN_ETHER = 1 finney;  

    function CHEXToken(address founderInput, uint startBlockInput, uint endBlockInput) {
        founder = founderInput;
        startBlock = startBlockInput;
        endBlock = endBlockInput;
    }

    function() payable {
        buy(msg.sender);
    }

    function price() constant returns(uint) {
        if (block.number < startBlock) return 42007;
        if (block.number >= startBlock && block.number <= endBlock) {
            uint percentRemaining = pct((endBlock - block.number), (endBlock - startBlock), 3);
            return 21000 + 21 * percentRemaining;
        }
        return 21000;
    }

    function buy(address recipient) payable {
        if (frozen) revert();
        if (recipient == 0x0) revert();
        if (msg.value < MIN_ETHER) revert();

        uint tokens = msg.value.mul(price());
        uint nextTotal = totalSupply.add(tokens);

        if (nextTotal > tokenCap) revert();
        
        balances[recipient] = balances[recipient].add(tokens);

        totalSupply = nextTotal;

        if (block.number <= endBlock) {
            crowdsaleSupply = nextTotal;
            etherRaised = etherRaised.add(msg.value);
        }

        Transfer(0, recipient, tokens);
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (block.number <= endBlock + transferLockup && msg.sender != founder) return false;
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (block.number <= endBlock + transferLockup && msg.sender != founder) return false;
        return super.transferFrom(_from, _to, _value);
    }

    function pct(uint numerator, uint denominator, uint precision) internal returns(uint quotient) {
        uint _numerator = numerator * 10 ** (precision+1);
        uint _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

     
    modifier onlyInternal {
        require(msg.sender == founder);
        _;
    }

    function freeze() onlyInternal {
        frozen = true;
    }

    function unfreeze() onlyInternal {
        frozen = false;
    }

    function withdrawFunds() onlyInternal {
		if (this.balance == 0) revert();

		founder.transfer(this.balance);
	}

    function changeFounder(address _newAddress) onlyInternal {
        if (msg.sender != founder) revert();
        if (_newAddress == 0x0) revert();
        

		founder = _newAddress;
	}

}