 

pragma solidity ^0.4.23;

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Token is Ownable {

   
  function totalSupply() view public returns (uint256 supply) {}

   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {}

   
   
   
   
  function transfer(address _to, uint256 _value) public returns (bool success) {}

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

   
   
   
   
  function approve(address _spender, uint256 _value) public returns (bool success) {}

   
   
   
  function allowance(address _owner, address _spender) view public returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

  function transfer(address _to, uint256 _value) public returns (bool success) {
       
       
       
       
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
      }
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
       
       
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      emit Transfer(_from, _to, _value);
      return true;
    } else { 
      return false;
      }
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  uint256 public totalSupply;
}

contract Bitotal is StandardToken { 

   

   
  string public name;                    
  uint8 public decimals;                 
  string public symbol;                  
  string public version = "1.0"; 
  uint256 public unitsOneEthCanBuy;      
  uint256 public totalEthInWei;          
  address public fundsWallet;            
  uint256 public maxSupply;
  uint256 public maxTransferPerTimeframe;
  uint256 public timeFrame;
  bool public paused;
  bool public restrictTransfers;
  mapping (address => uint256) public lastTransfer;
  mapping (address => uint256) public transfered;

  modifier NotPaused() {
    require(!paused);
    _;
  }

   
   
  constructor() public {
    fundsWallet = msg.sender; 
    balances[fundsWallet] = 100000000;               
    totalSupply = 100000000;    
    maxSupply = 500000000;                    
    name = "Bitotal";                                   
    decimals = 2;                                               
    symbol = "TFUND";                                             
    unitsOneEthCanBuy = 15;                                       
    timeFrame = 86399;      
    maxTransferPerTimeframe = 300;                            
  }

  function() payable public {
    require(msg.value > 1 finney);
    totalEthInWei = totalEthInWei + msg.value;
    uint256 amount = msg.value * unitsOneEthCanBuy;
    amount = (amount * 100) / 1 ether;
    mintTokens(msg.sender, amount);
    fundsWallet.transfer(msg.value);                               
  }

  function mintTokens(address _to, uint256 _amount) private {
    require((totalSupply + _amount) <= maxSupply);
    balances[_to] += _amount;
    totalSupply += _amount;
    emit Transfer(0x0, _to, _amount);
  }

  function setWalletAddress(address _newWallet) onlyOwner public {
    require(_newWallet != address(0x0));
    fundsWallet = _newWallet;
  }

  function pause(bool _paused) onlyOwner public {
    paused = _paused;
  }

  function setTimeFrame(uint256 _time) onlyOwner public {
    timeFrame = _time;
  }

  function restrict(bool _restricted) onlyOwner public {
    restrictTransfers = _restricted;
  }

  function maxTransferAmount(uint256 _amount) onlyOwner public {
    maxTransferPerTimeframe = _amount;
  }

  function transfer(address _to, uint256 _value) NotPaused public returns (bool success) {
    uint256 _lastTransfer;

    _lastTransfer = lastTransfer[msg.sender] + timeFrame;

    if ( _lastTransfer < now) {
        
      transfered[msg.sender] = 0;
      lastTransfer[msg.sender] = now;
    }
     
    if ((_value <= (maxTransferPerTimeframe - transfered[msg.sender])) || !restrictTransfers) {
      
      if (restrictTransfers) {
        transfered[msg.sender] += _value;
      }
      super.transfer(_to, _value);
      return true;
    } else {
      return false;
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) NotPaused public returns (bool success) {
    uint256 _lastTransfer;

    _lastTransfer = lastTransfer[_from] + timeFrame;
    if ( _lastTransfer < now) {
      transfered[_from] = 0;
      lastTransfer[_from] = now;
    }
    if ((_value <= (maxTransferPerTimeframe - transfered[_from])) || !restrictTransfers) {
      if (restrictTransfers) {
        transfered[_from] += _value;
      }
      super.transferFrom(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }

}