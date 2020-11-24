 

pragma solidity ^0.4.11;


 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
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


contract ERC20Protocol {
     
     
    uint public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint balance);

     
     
     
     
    function transfer(address _to, uint _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract StandardToken is ERC20Protocol {
    using SafeMath for uint;

     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
         
         
         
         
        assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
}

 
 
 
contract WanToken is StandardToken {
    using SafeMath for uint;

     
    string public constant name = "WanCoin";
    string public constant symbol = "WAN";
    uint public constant decimals = 18;

     
    uint public constant MAX_TOTAL_TOKEN_AMOUNT = 210000000 ether;

     
     
    address public minter; 
     
    uint public startTime;
     
    uint public endTime;

     
    mapping (address => uint) public lockedBalances;
     

    modifier onlyMinter {
        assert(msg.sender == minter);
        _;
    }

    modifier isLaterThan (uint x){
        assert(now > x);
        _;
    }

    modifier maxWanTokenAmountNotReached (uint amount){
        assert(totalSupply.add(amount) <= MAX_TOTAL_TOKEN_AMOUNT);
        _;
    }

     
    function WanToken(address _minter, uint _startTime, uint _endTime){
        minter = _minter;
        startTime = _startTime;
        endTime = _endTime;
    }

         
    function mintToken(address receipent, uint amount)
        external
        onlyMinter
        maxWanTokenAmountNotReached(amount)
        returns (bool)
    {
        require(now <= endTime);
        lockedBalances[receipent] = lockedBalances[receipent].add(amount);
        totalSupply = totalSupply.add(amount);
        return true;
    }

     

     
     
    function claimTokens(address receipent)
        public
        onlyMinter
    {
        balances[receipent] = balances[receipent].add(lockedBalances[receipent]);
        lockedBalances[receipent] = 0;
    }

     
    function lockedBalanceOf(address _owner) constant returns (uint balance) {
        return lockedBalances[_owner];
    }
}