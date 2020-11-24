 

pragma solidity ^0.4.11;

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

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner returns (address _owner) {
        owner = newOwner;
        return owner;
    }
}

contract ProsperaToken is StandardToken, Owned {

    function () {
         
        throw;
    }

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = '0.1';        


    function ProsperaToken(
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


     
    function batchTransfer(address[] _recipients, uint256[] _values) returns (bool success) {
      if ((_recipients.length == 0) || (_recipients.length != _values.length)) throw;

      for(uint8 i = 0; i < _recipients.length; i += 1) {
        if (!transfer(_recipients[i], _values[i])) throw;
      }
      return true;
    }



    address minterContract;
    event Mint(address indexed _account, uint256 _amount);

    modifier onlyMinter {
        if (msg.sender != minterContract) throw;
         _;
    }

    function setMinter (address newMinter) onlyOwner returns (bool success) {
      minterContract = newMinter;
      return true;
    }

    function mintToAccount(address _account, uint256 _amount) onlyMinter returns (bool success) {
         
        if (balances[_account] + _amount < balances[_account]) throw;
        balances[_account] += _amount;
        Mint(_account, _amount);
        return true;
    }

    function incrementTotalSupply(uint256 _incrementValue) onlyMinter returns (bool success) {
        totalSupply += _incrementValue;
        return true;
    }
}

contract Minter is Owned {

  uint256 public lastMintingTime = 0;
  uint256 public lastMintingAmount;
  address public prosperaTokenAddress;
  ProsperaToken public prosperaToken;

  modifier allowedMinting() {
    if (block.timestamp >= lastMintingTime + 30 days) {
      _;
    }
  }

  function Minter (uint256 _lastMintingAmount, address _ownerContract) {
    lastMintingAmount = _lastMintingAmount;
    prosperaTokenAddress = _ownerContract;
    prosperaToken = ProsperaToken(_ownerContract);
  }

   
  function calculateMintAmount() returns (uint256 amount){
   return lastMintingAmount * 10295 / 10000;
  }

  function updateMintingStatus(uint256 _mintedAmount) internal {
    lastMintingAmount = _mintedAmount;
    lastMintingTime = block.timestamp;
    prosperaToken.incrementTotalSupply(_mintedAmount);
  }

  function mint() allowedMinting onlyOwner returns (bool success) {
    uint256 value = calculateMintAmount();
    prosperaToken.mintToAccount(msg.sender, value);
    updateMintingStatus(value);
    return true;
  }
}