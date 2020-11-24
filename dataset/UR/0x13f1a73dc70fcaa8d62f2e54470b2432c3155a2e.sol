 

 
pragma solidity ^0.4.10;

 
contract Custodial {
  uint256 constant TWO_128 = 0x100000000000000000000000000000000;  
  uint256 constant TWO_127 = 0x80000000000000000000000000000000;  

   
  address client;

   
  address advisor;

   
  uint256 capital;

   
  uint256 capitalTimestamp;

   
  uint256 feeFactor;

   
  function Custodial (address _client, address _advisor, uint256 _feeFactor) {
    if (_feeFactor > TWO_128)
      throw;  

    client = _client;
    advisor = _advisor;
    feeFactor = _feeFactor;
  }

   
  function getCapital (uint256 _currentTime)
  constant returns (uint256 _result) {
    _result = capital;
    if (capital > 0 && capitalTimestamp < _currentTime && feeFactor < TWO_128) {
      _result = mul (_result, pow (feeFactor, _currentTime - capitalTimestamp));
    }
  }

   
  function deposit () payable {
    if (msg.value > 0) {
      updateCapital ();
      if (msg.value >= TWO_128 - capital)
        throw;  
      capital += msg.value;
      Deposit (msg.sender, msg.value);
    }
  }

   
  function withdraw (uint256 _value)
  returns (bool _success) {
    if (msg.sender != client) throw;

    if (_value > 0) {
      updateCapital ();
      if (_value <= capital) {
        if (client.send (_value)) {
          Withdrawal (_value);
          capital -= _value;
          return true;
        } else return false;
      } else return false;
    } else return true;
  }

   
  function withdrawAll ()
  returns (bool _success) {
    if (msg.sender != client) throw;

    updateCapital ();
    if (capital > 0) {
      if (client.send (capital)) {
        Withdrawal (capital);
        capital = 0;
        return true;
      } else return false;
    } else return true;
  }

   
  function withdrawFee ()
  returns (bool _success) {
    if (msg.sender != advisor) throw;

    uint256 _value = this.balance - getCapital (now);
    if (_value > 0) {
      return advisor.send (_value);
    } else return true;
  }

   
  function terminate () {
    if (msg.sender != advisor) throw;

    if (capital > 0) throw;
    if (this.balance > 0) {
      if (!advisor.send (this.balance)) {
         
      }
    }
    suicide (advisor);
  }

   
  function updateCapital ()
  internal {
    if (capital > 0 && capitalTimestamp < now && feeFactor < TWO_128) {
      capital = mul (capital, pow (feeFactor, now - capitalTimestamp));
    }
    capitalTimestamp = now;
  }

   
  function mul (uint256 _a, uint256 _b)
  internal constant returns (uint256 _result) {
    if (_a > TWO_128) throw;
    if (_b >= TWO_128) throw;
    return (_a * _b + TWO_127) >> 128;
  }

   
  function pow (uint256 _a, uint256 _b)
  internal constant returns (uint256 _result) {
    if (_a >= TWO_128) throw;

    _result = TWO_128;
    while (_b > 0) {
      if (_b & 1 == 0) {
        _a = mul (_a, _a);
        _b >>= 1;
      } else {
        _result = mul (_result, _a);
        _b -= 1;
      }
    }
  }

   
  event Deposit (address indexed from, uint256 value);

   
  event Withdrawal (uint256 value);
}