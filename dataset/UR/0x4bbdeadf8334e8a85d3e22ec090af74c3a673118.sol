 

pragma solidity ^0.4.13;
 

contract SafeMath {
   

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
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

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

}

contract ReserveToken is StandardToken, SafeMath {
    string public name;
    string public symbol;
    uint public decimals = 18;
    address public minter;
    function ReserveToken(string name_, string symbol_) {
      name = name_;
      symbol = symbol_;
      minter = msg.sender;
    }
    function create(address account, uint amount) {
      require(msg.sender == minter);
      balances[account] = safeAdd(balances[account], amount);
      totalSupply = safeAdd(totalSupply, amount);
    }
    function destroy(address account, uint amount) {
      require(msg.sender == minter);
      require(balances[account] >= amount);
      balances[account] = safeSub(balances[account], amount);
      totalSupply = safeSub(totalSupply, amount);
    }
}

contract YesNo is SafeMath {

  ReserveToken public yesToken;
  ReserveToken public noToken;

  string public name;
  string public symbol;

   
  bytes32 public factHash;
  address public ethAddr;
  string public url;

  uint public outcome;
  bool public resolved = false;

  address public feeAccount;
  uint public fee;  

  event Create(address indexed account, uint value);
  event Redeem(address indexed account, uint value, uint yesTokens, uint noTokens);
  event Resolve(bool resolved, uint outcome);

  function YesNo(string name_, string symbol_, string namey_, string symboly_, string namen_, string symboln_, bytes32 factHash_, address ethAddr_, string url_, address feeAccount_, uint fee_) {
    name = name_;
    symbol = symbol_;
    yesToken = new ReserveToken(namey_, symboly_);
    noToken = new ReserveToken(namen_, symboln_);
    factHash = factHash_;
    ethAddr = ethAddr_;
    url = url_;
    feeAccount = feeAccount_;
    fee = fee_;
  }

  function() payable {
    create();
  }

  function create() payable {
     
    yesToken.create(msg.sender, msg.value);
    noToken.create(msg.sender, msg.value);
    Create(msg.sender, msg.value);
  }

  function redeem(uint tokens) {
    feeAccount.transfer(safeMul(tokens,fee)/(1 ether));
    if (!resolved) {
      yesToken.destroy(msg.sender, tokens);
      noToken.destroy(msg.sender, tokens);
      msg.sender.transfer(safeMul(tokens,(1 ether)-fee)/(1 ether));
      Redeem(msg.sender, tokens, tokens, tokens);
    } else if (resolved) {
      if (outcome==0) {  
        noToken.destroy(msg.sender, tokens);
        msg.sender.transfer(safeMul(tokens,(1 ether)-fee)/(1 ether));
        Redeem(msg.sender, tokens, 0, tokens);
      } else if (outcome==1) {  
        yesToken.destroy(msg.sender, tokens);
        msg.sender.transfer(safeMul(tokens,(1 ether)-fee)/(1 ether));
        Redeem(msg.sender, tokens, tokens, 0);
      }
    }
  }

  function resolve(uint8 v, bytes32 r, bytes32 s, bytes32 value) {
    require(ecrecover(sha3(factHash, value), v, r, s) == ethAddr);
    require(!resolved);
    uint valueInt = uint(value);
    require(valueInt==0 || valueInt==1);
    outcome = valueInt;
    resolved = true;
    Resolve(resolved, outcome);
  }
}