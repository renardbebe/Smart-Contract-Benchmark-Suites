 

pragma solidity ^0.4.11;

contract Crowdsale {
    function buyTokens(address _recipient) payable;
}

contract CapWhitelist {
    address public owner;
    mapping (address => uint256) public whitelist;

    event Set(address _address, uint256 _amount);

    function CapWhitelist() {
        owner = msg.sender;
         
    }

    function destruct() {
        require(msg.sender == owner);
        selfdestruct(owner);
    }

    function setWhitelisted(address _address, uint256 _amount) {
        require(msg.sender == owner);
        setWhitelistInternal(_address, _amount);
    }

    function setWhitelistInternal(address _address, uint256 _amount) private {
        whitelist[_address] = _amount;
        Set(_address, _amount);
    }
}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract StandardToken is Token {
    using SafeMath for uint256;
    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender,  uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
      allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
      uint oldValue = allowed[msg.sender][_spender];
      if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
      } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract MintableToken is StandardToken, Ownable {
  using SafeMath for uint256;
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
  }

   
  function finishMinting() onlyOwner public {
    mintingFinished = true;
    MintFinished();
  }
}
contract RCNToken is MintableToken {
    string public constant name = "Ripio Credit Network Token";
    string public constant symbol = "RCN";
    uint8 public constant decimals = 18;
    string public version = "1.0";
}

contract PreallocationsWhitelist {
    address public owner;
    mapping (address => bool) public whitelist;

    event Set(address _address, bool _enabled);

    function PreallocationsWhitelist() {
        owner = msg.sender;
         
    }

    function destruct() {
        require(msg.sender == owner);
        selfdestruct(owner);
    }

    function setWhitelisted(address _address, bool _enabled) {
        require(msg.sender == owner);
        setWhitelistInternal(_address, _enabled);
    }

    function setWhitelistInternal(address _address, bool _enabled) private {
        whitelist[_address] = _enabled;
        Set(_address, _enabled);
    }
}

contract RCNCrowdsale is Crowdsale {
    using SafeMath for uint256;

     
    uint256 public constant decimals = 18;

     
    address public ethFundDeposit;       
    address public rcnFundDeposit;       

     
    bool public isFinalized;               
    uint256 public fundingStartTimestamp;
    uint256 public fundingEndTimestamp;
    uint256 public constant rcnFund = 490 * (10**6) * 10**decimals;    
    uint256 public constant tokenExchangeRate = 4000;  
    uint256 public constant tokenCreationCap =  1000 * (10**6) * 10**decimals;
    uint256 public constant minBuyTokens = 400 * 10**decimals;  
    uint256 public constant gasPriceLimit = 60 * 10**9;  

     
    event CreateRCN(address indexed _to, uint256 _value);

    mapping (address => uint256) bought;  

    CapWhitelist public whiteList;
    PreallocationsWhitelist public preallocationsWhitelist;
    RCNToken public token;

     
    function RCNCrowdsale(address _ethFundDeposit,
          address _rcnFundDeposit,
          uint256 _fundingStartTimestamp,
          uint256 _fundingEndTimestamp) {
      token = new RCNToken();
      whiteList = new CapWhitelist();
      preallocationsWhitelist = new PreallocationsWhitelist();

       
      assert(_ethFundDeposit != 0x0);
      assert(_rcnFundDeposit != 0x0);
      assert(_fundingStartTimestamp < _fundingEndTimestamp);
      assert(uint256(token.decimals()) == decimals); 

      isFinalized = false;                    
      ethFundDeposit = _ethFundDeposit;
      rcnFundDeposit = _rcnFundDeposit;
      fundingStartTimestamp = _fundingStartTimestamp;
      fundingEndTimestamp = _fundingEndTimestamp;
      token.mint(rcnFundDeposit, rcnFund);
      CreateRCN(rcnFundDeposit, rcnFund);   
    }

     
    function () payable {
      buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) payable {
      require (!isFinalized);
      require (block.timestamp >= fundingStartTimestamp || preallocationsWhitelist.whitelist(msg.sender));
      require (block.timestamp <= fundingEndTimestamp);
      require (msg.value != 0);
      require (beneficiary != 0x0);
      require (tx.gasprice <= gasPriceLimit);

      uint256 tokens = msg.value.mul(tokenExchangeRate);  
      uint256 checkedSupply = token.totalSupply().add(tokens);
      uint256 checkedBought = bought[msg.sender].add(tokens);

       
      require (checkedBought <= whiteList.whitelist(msg.sender) || preallocationsWhitelist.whitelist(msg.sender));

       
      require (tokenCreationCap >= checkedSupply);

       
       
      require (tokens >= minBuyTokens || (tokenCreationCap - token.totalSupply()) <= minBuyTokens);

      token.mint(beneficiary, tokens);
      bought[msg.sender] = checkedBought;
      CreateRCN(beneficiary, tokens);   

      forwardFunds();
    }

    function finalize() {
      require (!isFinalized);
      require (block.timestamp > fundingEndTimestamp || token.totalSupply() == tokenCreationCap);
      require (msg.sender == ethFundDeposit);
      isFinalized = true;
      token.finishMinting();
      whiteList.destruct();
      preallocationsWhitelist.destruct();
    }

     
    function forwardFunds() internal {
      ethFundDeposit.transfer(msg.value);
    }

    function setWhitelist(address _address, uint256 _amount) {
      require (msg.sender == ethFundDeposit);
      whiteList.setWhitelisted(_address, _amount);
    }

    function setPreallocationWhitelist(address _address, bool _status) {
      require (msg.sender == ethFundDeposit);
      preallocationsWhitelist.setWhitelisted(_address, _status);
    }
}