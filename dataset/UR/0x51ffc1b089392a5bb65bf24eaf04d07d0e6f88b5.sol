 

pragma solidity ^0.4.0;
 

contract Lockable {
    uint public numOfCurrentEpoch;
    uint public creationTime;
    uint public constant UNLOCKED_TIME = 25 days;
    uint public constant LOCKED_TIME = 5 days;
    uint public constant EPOCH_LENGTH = 30 days;
    bool public lock;
    bool public tokenSwapLock;

    event Locked();
    event Unlocked();

     
     
    modifier isTokenSwapOn {
        if (tokenSwapLock) throw;
        _;
    }

     
     
     
    modifier isNewEpoch {
        if (numOfCurrentEpoch * EPOCH_LENGTH + creationTime < now ) {
            numOfCurrentEpoch = (now - creationTime) / EPOCH_LENGTH + 1;
        }
        _;
    }

     
     
     
    modifier checkLock {
        if ((creationTime + numOfCurrentEpoch * UNLOCKED_TIME) +
        (numOfCurrentEpoch - 1) * LOCKED_TIME < now) {
             
            if (lock) throw;

            lock = true;
            Locked();
            return;
        }
        else {
             
             
            if (lock) {
                lock = false;
                Unlocked();
            }
        }
        _;
    }

    function Lockable() {
        creationTime = now;
        numOfCurrentEpoch = 1;
        tokenSwapLock = true;
    }
}


contract ERC20 {
    function totalSupply() constant returns (uint);
    function balanceOf(address who) constant returns (uint);
    function allowance(address owner, address spender) constant returns (uint);

    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Token is ERC20, Lockable {

  mapping( address => uint ) _balances;
  mapping( address => mapping( address => uint ) ) _approvals;
  uint _supply;
  address public walletAddress;

  event TokenMint(address newTokenHolder, uint amountOfTokens);
  event TokenSwapOver();

  modifier onlyFromWallet {
      if (msg.sender != walletAddress) throw;
      _;
  }

  function Token( uint initial_balance, address wallet) {
    _balances[msg.sender] = initial_balance;
    _supply = initial_balance;
    walletAddress = wallet;
  }

  function totalSupply() constant returns (uint supply) {
    return _supply;
  }

  function balanceOf( address who ) constant returns (uint value) {
    return _balances[who];
  }

  function allowance(address owner, address spender) constant returns (uint _allowance) {
    return _approvals[owner][spender];
  }

   
  function safeToAdd(uint a, uint b) internal returns (bool) {
    return (a + b >= a && a + b >= b);
  }

  function transfer( address to, uint value)
    isTokenSwapOn
    isNewEpoch
    checkLock
    returns (bool ok) {

    if( _balances[msg.sender] < value ) {
        throw;
    }
    if( !safeToAdd(_balances[to], value) ) {
        throw;
    }

    _balances[msg.sender] -= value;
    _balances[to] += value;
    Transfer( msg.sender, to, value );
    return true;
  }

  function transferFrom( address from, address to, uint value)
    isTokenSwapOn
    isNewEpoch
    checkLock
    returns (bool ok) {
     
    if( _balances[from] < value ) {
        throw;
    }
     
    if( _approvals[from][msg.sender] < value ) {
        throw;
    }
    if( !safeToAdd(_balances[to], value) ) {
        throw;
    }
     
    _approvals[from][msg.sender] -= value;
    _balances[from] -= value;
    _balances[to] += value;
    Transfer( from, to, value );
    return true;
  }

  function approve(address spender, uint value)
    isTokenSwapOn
    isNewEpoch
    checkLock
    returns (bool ok) {
    _approvals[msg.sender][spender] = value;
    Approval( msg.sender, spender, value );
    return true;
  }

   
   
  function currentSwapRate() constant returns(uint) {
      if (creationTime + 1 weeks > now) {
          return 130;
      }
      else if (creationTime + 2 weeks > now) {
          return 120;
      }
      else if (creationTime + 4 weeks > now) {
          return 100;
      }
      else {
          return 0;
      }
  }

   
   
   
   
  function mintTokens(address newTokenHolder, uint etherAmount)
    external
    onlyFromWallet {

        uint tokensAmount = currentSwapRate() * etherAmount;
        if(!safeToAdd(_balances[newTokenHolder],tokensAmount )) throw;
        if(!safeToAdd(_supply,tokensAmount)) throw;

        _balances[newTokenHolder] += tokensAmount;
        _supply += tokensAmount;

        TokenMint(newTokenHolder, tokensAmount);
  }

   
   
  function disableTokenSwapLock()
    external
    onlyFromWallet {
        tokenSwapLock = false;
        TokenSwapOver();
  }
}


pragma solidity ^0.4.0;
 

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address _newOwner)
      external
      onlyOwner {
      if (_newOwner == address(0x0)) throw;
      owner = _newOwner;
  }

}

contract ProfitContainer is Ownable {
    uint public currentEpoch;
     
     
    uint public initEpochBalance;
    mapping (address => uint) lastPaidOutEpoch;
    Token public tokenCtr;

    event WithdrawalEnabled();
    event ProfitWithdrawn(address tokenHolder, uint amountPaidOut);
    event TokenContractChanged(address newTokenContractAddr);

     
     
     
    modifier onlyNotPaidOut {
        if (lastPaidOutEpoch[msg.sender] == currentEpoch) throw;
        _;
    }

     
     
    modifier onlyLocked {
        if (!tokenCtr.lock()) throw;
        _;
    }

     
     
     
     
    modifier resetPaidOut {
        if(currentEpoch < tokenCtr.numOfCurrentEpoch()) {
            currentEpoch = tokenCtr.numOfCurrentEpoch();
            initEpochBalance = this.balance;
            WithdrawalEnabled();
        }
        _;
    }

    function ProfitContainer(address _token) {
        tokenCtr = Token(_token);
    }

    function ()
        payable {

    }

     
     
     
     
    function withdrawalProfit()
        external
        resetPaidOut
        onlyLocked
        onlyNotPaidOut {
        uint currentEpoch = tokenCtr.numOfCurrentEpoch();
        uint tokenBalance = tokenCtr.balanceOf(msg.sender);
        uint totalSupply = tokenCtr.totalSupply();

        if (tokenBalance == 0) throw;

        lastPaidOutEpoch[msg.sender] = currentEpoch;

         
         
         
         
        if (!safeToMultiply(tokenBalance, initEpochBalance)) throw;
        uint senderPortion = (tokenBalance * initEpochBalance);

        uint amountToPayOut = senderPortion / totalSupply;

        if(!msg.sender.send(amountToPayOut)) {
            throw;
        }

        ProfitWithdrawn(msg.sender, amountToPayOut);
    }

    function changeTokenContract(address _newToken)
        external
        onlyOwner {

        if (_newToken == address(0x0)) throw;

        tokenCtr = Token(_newToken);
        TokenContractChanged(_newToken);
    }

     
    function expectedPayout(address _tokenHolder)
        external
        constant returns (uint) {

        if (!tokenCtr.lock())
            return 0;

        return (tokenCtr.balanceOf(_tokenHolder) * initEpochBalance) / tokenCtr.totalSupply();
    }

    function safeToMultiply(uint _a, uint _b)
        private
        constant returns (bool) {

        return (_b == 0 || ((_a * _b) / _b) == _a);
    }
}