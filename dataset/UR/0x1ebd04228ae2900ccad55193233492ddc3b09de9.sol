 

pragma solidity ^0.4.11;

 
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

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract HumanStandardToken is StandardToken {

    function () {
         
        throw;
    }

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H0.1';        

    function HumanStandardToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}

contract Locked {
  uint public period;

  function Locked(uint _period) public {
    period = _period;
  }
}

contract Owned {
    function Owned() { owner = msg.sender; }
    address owner;

     
     
     
     
     
     
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract Sales is Owned {
  address public wallet;
  HumanStandardToken public token;
  Locked public locked;
  uint public price;
  uint public startBlock;
  uint public freezeBlock;
  bool public frozen = false;
  uint256 public cap = 0;
  uint256 public sold = 0;
  uint created;

  event PurchasedTokens(address indexed purchaser, uint amount);

  modifier saleHappening {
    require(block.number >= startBlock);
    require(block.number <= freezeBlock);
    require(!frozen);
    require(sold < cap);
    _;
  }

  function Sales(
    address _wallet,
    uint256 _tokenSupply,
    string _tokenName,
    uint8 _tokenDecimals,
    string _tokenSymbol,
    uint _price,
    uint _startBlock,
    uint _freezeBlock,
    uint256 _cap,
    uint _locked
  ) {
    wallet = _wallet;
    token = new HumanStandardToken(_tokenSupply, _tokenName, _tokenDecimals, _tokenSymbol);
    locked = new Locked(_locked);
    price = _price;
    startBlock = _startBlock;
    freezeBlock = _freezeBlock;
    cap = _cap;
    created = now;

    uint256 ownersValue = SafeMath.div(SafeMath.mul(token.totalSupply(), 20), 100);
    assert(token.transfer(wallet, ownersValue));

    uint256 saleValue = SafeMath.div(SafeMath.mul(token.totalSupply(), 60), 100);
    assert(token.transfer(this, saleValue));

    uint256 lockedValue = SafeMath.sub(token.totalSupply(), SafeMath.add(ownersValue, saleValue));
    assert(token.transfer(locked, lockedValue));
  }

  function purchaseTokens()
    payable
    saleHappening {
    uint excessAmount = msg.value % price;
    uint purchaseAmount = SafeMath.sub(msg.value, excessAmount);
    uint tokenPurchase = SafeMath.div(purchaseAmount, price);

    require(tokenPurchase <= token.balanceOf(this));

    if (excessAmount > 0) {
      msg.sender.transfer(excessAmount);
    }

    sold = SafeMath.add(sold, tokenPurchase);
    assert(sold <= cap);
    wallet.transfer(purchaseAmount);
    assert(token.transfer(msg.sender, tokenPurchase));
    PurchasedTokens(msg.sender, tokenPurchase);
  }

   
  function changeBlocks(uint _newStartBlock, uint _newFreezeBlock)
    onlyOwner {
    require(_newStartBlock != 0);
    require(_newFreezeBlock >= _newStartBlock);
    startBlock = _newStartBlock;
    freezeBlock = _newFreezeBlock;
  }

  function changePrice(uint _newPrice) 
    onlyOwner {
    require(_newPrice > 0);
    price = _newPrice;
  }

  function changeCap(uint256 _newCap)
    onlyOwner {
    require(_newCap > 0);
    cap = _newCap;
  }

  function unlockEscrow()
    onlyOwner {
    assert((now - created) > locked.period());
    assert(token.transfer(wallet, token.balanceOf(locked)));
  }

  function toggleFreeze()
    onlyOwner {
      frozen = !frozen;
  }
}