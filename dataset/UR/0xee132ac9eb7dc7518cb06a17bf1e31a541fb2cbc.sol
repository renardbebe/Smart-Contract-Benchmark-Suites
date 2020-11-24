 

 

pragma solidity ^0.4.24;

 
contract IERC20Token {
     
    function name() public view returns (string) {}
    function symbol() public view returns (string) {}
    function decimals() public view returns (uint8) {}
    function totalSupply() public view returns (uint256) {}
    function balanceOf(address _owner) public view returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public view returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 

pragma solidity ^0.4.24;


contract Bancor {
  function claimAndConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public returns (uint256) {}
  function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256) {}
}

 

pragma solidity ^0.4.24;

contract EtherDelta {
  function deposit() payable {}
  function depositToken(address token, uint amount) {}
  function withdraw(uint amount) {}
  function withdrawToken(address token, uint amount) {}
  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) {}
  function balanceOf(address token, address user) constant returns (uint) {}
}

 

pragma solidity ^0.4.24;

contract Token {
   
  function totalSupply() constant returns (uint256 supply) {}

   
   
  function balanceOf(address _owner) constant returns (uint256 balance) {}

   
   
   
   
  function transfer(address _to, uint256 _value) returns (bool success) {}

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

   
   
   
   
  function approve(address _spender, uint256 _value) returns (bool success) {}

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

 

pragma solidity ^0.4.24;

contract TokenNoBool {
   
  function totalSupply() constant returns (uint256 supply) {}

   
   
  function balanceOf(address _owner) constant returns (uint256 balance) {}

   
   
   
   
  function transfer(address _to, uint256 _value) {}

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) {}

   
   
   
   
  function approve(address _spender, uint256 _value) {}

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

 

pragma solidity ^0.4.24;

contract GST2 {
  function mint(uint256 value) public {}
  function freeUpTo(uint256 value) public returns (uint256 freed) {}
  function freeFromUpTo(address from, uint256 value) public returns (uint256 freed) {}
}

 

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;







contract Arbot {
  enum Exchange { ETHERDELTA, BANCOR }
  struct DeltaTrade {
    DeltaOrder order;
     
    uint256 amount;
  }

  struct DeltaOrder {
     
     
     
    address[3] addresses;
     
     
     
     
    uint256[4] values;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  EtherDelta etherDelta;
  Bancor bancor;
  address owner;
  address executor;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyOwnerAndExecutor() {
    require(msg.sender == owner || msg.sender == executor);
    _;
  }

  constructor() public {
    owner = msg.sender;
    executor = 0xA21623FD5dd105F0d2d61327438F4C695aBA6dC3;
  }

  function setExecutor(address _newExecutor) public onlyOwner {
    executor = _newExecutor;
  }

  function atomicTrade(
    Exchange buyExchange,
    IERC20Token[] _path,
     
     
     
     
    address[3] addresses,
     
     
     
     
    uint256[3] values,
    DeltaTrade[] deltaTrades,
    bool balanceCheck,
    bool _isProperERC20
  ) internal returns (uint256, uint256) {
    require(addresses[0] != address(0));
    require(addresses[1] != address(0));
    require(addresses[2] != address(0));

    etherDelta = EtherDelta(addresses[0]);
    bancor = Bancor(addresses[1]);

    uint256 balanceBefore = address(this).balance;
    uint256 tokenBalance = 0;
    uint256 ethReturned = 0;

    if (buyExchange == Exchange.ETHERDELTA) {
      tokenBalance = makeBuyTradeEtherDeltaTrade(deltaTrades, values[2]);
      ensureAllowance(addresses[2], address(bancor), tokenBalance, _isProperERC20);
      ethReturned = bancor.claimAndConvert(_path, tokenBalance, values[1]);
    } else {
      tokenBalance = bancor.convert.value(values[0])(_path, values[0], values[1]);
      ensureAllowance(addresses[2], address(etherDelta), tokenBalance, _isProperERC20);
      ethReturned = makeSellTradeEtherDeltaTrade(deltaTrades, tokenBalance);
    }

    if (balanceCheck) {
      require(address(this).balance >= balanceBefore - 1);  
    }
    return (address(this).balance, ethReturned);
  }

   
  function makeBuyTradeEtherDeltaTrade(DeltaTrade[] trades, uint256 depositValue) private returns (uint256) {
    etherDelta.deposit.value(depositValue)();  

    for (uint256 i = 0; i < trades.length; i++) {
      etherDelta.trade(
        trades[i].order.addresses[0],  
        trades[i].order.values[0],  
        trades[i].order.addresses[1],  
        trades[i].order.values[1],  

        trades[i].order.values[2],  
        trades[i].order.values[3],  
        trades[i].order.addresses[2],  
        trades[i].order.v, trades[i].order.r, trades[i].order.s,  
        trades[i].amount  
      );
    }

     
    deltaWithdrawAllEth();
    return deltaWithdrawAllTokens(trades[0].order.addresses[1]);  
  }

   
  function makeSellTradeEtherDeltaTrade(DeltaTrade[] trades, uint256 tokenBalance) private returns (uint256) {
    etherDelta.depositToken(
      trades[0].order.addresses[0],  
      tokenBalance  
    );

    for (uint256 i = 0; i < trades.length; i++) {
      etherDelta.trade(
        trades[i].order.addresses[0],  
        trades[i].order.values[0],  
        trades[i].order.addresses[1],  
        trades[i].order.values[1],  
        trades[i].order.values[2],  
        trades[i].order.values[3],  
        trades[i].order.addresses[2],  
        trades[i].order.v, trades[i].order.r, trades[i].order.s,  
        trades[i].amount  
      );
    }

     
    deltaWithdrawAllTokens(trades[0].order.addresses[0]);  
    return deltaWithdrawAllEth();
  }

  function deltaWithdrawAllEth() public onlyOwnerAndExecutor returns (uint256) {
    uint256 ethBalance = etherDelta.balanceOf(0x0000000000000000000000000000000000000000, address(this));
    if (ethBalance != 0) {
      etherDelta.withdraw(ethBalance);
    }
    return ethBalance;
  }

  function deltaWithdrawAllTokens(address token) public onlyOwnerAndExecutor returns (uint256) {
    uint256 tokenBalance = etherDelta.balanceOf(token, address(this));
    if (tokenBalance != 0) {
      etherDelta.withdrawToken(token, tokenBalance);
    }
    return tokenBalance;
  }

   
   
     
     
     
   


  function ensureAllowance(address tokenAddr, address _spender, uint256 _value, bool _isProperERC20) private {
     
    if (_isProperERC20) {
      Token _token = Token(tokenAddr);
       
      if (_token.allowance(this, _spender) >= _value) {
        return;
      }

       
      if (_token.allowance(this, _spender) != 0) {
        _token.approve(_spender, 0);
      }

       
      _token.approve(_spender, _value);
    } else {
      TokenNoBool _tokenNoBool = TokenNoBool(tokenAddr);
       
      if (_tokenNoBool.allowance(this, _spender) >= _value) {
        return;
      }

       
      if (_tokenNoBool.allowance(this, _spender) != 0) {
        _tokenNoBool.approve(_spender, 0);
      }

       
      _tokenNoBool.approve(_spender, _value);
    }
  }

  function withdraw() external onlyOwner {
    owner.transfer(address(this).balance);
  }

  function withdrawToken(address _token, bool _isProperERC20) external onlyOwner {
     
    if (_isProperERC20) {
      Token token = Token(_token);
      token.transfer(owner, token.balanceOf(address(this)));
    } else {
      TokenNoBool tokenNoBool = TokenNoBool(_token);
      tokenNoBool.transfer(owner, tokenNoBool.balanceOf(address(this)));
    }
  }

  function destroyContract() external onlyOwner {
    selfdestruct(owner);
  }

   
  function() public payable {}

   
  function storeGas(uint256 num_tokens) public onlyOwner {
    GST2 gst2 = GST2(0x0000000000b3F879cb30FE243b4Dfee438691c04);
    gst2.mint(num_tokens);
  }
  function useCheapGas(uint256 num_tokens) private returns (uint256 freed) {
     
    GST2 gst2 = GST2(0x0000000000b3F879cb30FE243b4Dfee438691c04);

    uint256 safe_num_tokens = 0;
    uint256 gas = msg.gas;

    if (gas >= 27710) {
      safe_num_tokens = (gas - 27710) / (1148 + 5722 + 150);
    }

    if (num_tokens > safe_num_tokens) {
      num_tokens = safe_num_tokens;
    }

    if (num_tokens > 0) {
      return gst2.freeUpTo(num_tokens);
    } else {
      return 0;
    }
  }

   
  function atomicTradeGST(
    Exchange buyExchange,
    IERC20Token[] _path,
    address[3] addresses,
    uint256[3] values,
    DeltaTrade[] deltaTrades,
    bool balanceCheck,
    uint256 numTokens,
    bool _isProperERC20
  ) public onlyOwnerAndExecutor returns (uint256, uint256) {
     
    require(useCheapGas(numTokens) >= 0);
    return atomicTrade(
      buyExchange,
      _path,
      addresses,
      values,
      deltaTrades,
      balanceCheck,
      _isProperERC20
    );
  }
}