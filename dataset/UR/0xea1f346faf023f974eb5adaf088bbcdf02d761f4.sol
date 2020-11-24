 

pragma solidity ^0.4.11;


 
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
}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


 
contract TIXStalledToken {
  uint256 public totalSupply;
  bool public isFinalized;  
  address public ethFundDeposit;  

  function balanceOf(address who) constant returns (uint256);
}


 
contract TIXToken is StandardToken {
    mapping(address => bool) converted;  

    string public constant name = "Blocktix Token";
    string public constant symbol = "TIX";
    uint256 public constant decimals = 18;
    string public version = "1.0.1";

     
    bool public isFinalized;                       
    uint256 public startTime = 1501271999;         
    uint256 public constant endTime = 1501271999;  
    uint256 public constant tokenGenerationCap =  62.5 * (10**6) * 10**decimals;  
    uint256 public constant tokenExchangeRate = 1041;

     
    address public tixGenerationContract;  
    address public ethFundDeposit;         

     
    modifier whenFinalized() {
        if (!isFinalized) throw;
        _;
    }

     
    modifier whenNotFinalized() {
        if (isFinalized) throw;
        _;
    }

     
    modifier between(uint256 _startTime, uint256 _endTime) {
        assert(now >= _startTime && now < _endTime);
        _;
    }

     
    modifier validAmount() {
        require(msg.value > 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    event CreateTIX(address indexed _to, uint256 _value);

     
    function TIXToken(address _tixGenerationContract)
    {
        isFinalized = false;  
        tixGenerationContract = _tixGenerationContract;
        ethFundDeposit = TIXStalledToken(tixGenerationContract).ethFundDeposit();
    }


     
    function transfer(address _to, uint _value) whenFinalized {
        super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) whenFinalized {
        super.transferFrom(_from, _to, _value);
    }

     
    function generateTokens()
        public
        payable
        whenNotFinalized
        between(startTime, endTime)
        validAmount
    {
        if (totalSupply == tokenGenerationCap)
            throw;

        uint256 tokens = SafeMath.mul(msg.value, tokenExchangeRate);  
        uint256 checkedSupply = SafeMath.add(totalSupply, tokens);
        uint256 diff;

         
        if (tokenGenerationCap < checkedSupply)
        {
            diff = SafeMath.sub(checkedSupply, tokenGenerationCap);
            if (diff > 10**12)
                throw;
            checkedSupply = SafeMath.sub(checkedSupply, diff);
            tokens = SafeMath.sub(tokens, diff);
        }

        totalSupply = checkedSupply;
        balances[msg.sender] += tokens;
        CreateTIX(msg.sender, tokens);  
    }

    function hasConverted(address who) constant returns (bool)
    {
      return converted[who];
    }

    function convert(address _owner)
        external
    {
        TIXStalledToken tixStalled = TIXStalledToken(tixGenerationContract);
        if (tixStalled.isFinalized()) throw;  
        if (converted[_owner]) throw;  
        uint256 balanceOf = tixStalled.balanceOf(_owner);
        if (balanceOf <= 0) throw;  
        converted[_owner] = true;
        totalSupply += balanceOf;
        balances[_owner] += balanceOf;
        Transfer(this, _owner, balanceOf);
    }

    function continueGeneration()
        external
    {
        TIXStalledToken tixStalled = TIXStalledToken(tixGenerationContract);
         
        if (totalSupply == tixStalled.totalSupply() && tixStalled.isFinalized())
          startTime = now;
        else
          throw;
    }

     
    function finalize()
        external
        whenNotFinalized
    {
        if (msg.sender != ethFundDeposit) throw;  
        if (now <= endTime && totalSupply != tokenGenerationCap) throw;
         
        isFinalized = true;
        if(!ethFundDeposit.send(this.balance)) throw;   
    }

     
    function()
        payable
        whenNotFinalized
    {
        generateTokens();
    }
}