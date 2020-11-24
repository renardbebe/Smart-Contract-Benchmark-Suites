 

pragma solidity ^0.4.23;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor (string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 
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

 
 
contract MultiSigWallet {

     
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

     
    uint constant public MAX_OWNER_COUNT = 50;

     
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

     
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != 0);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT && _required <= ownerCount && _required != 0 && ownerCount != 0);
        _;
    }

     
    function() public payable
    {
        if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }

     
    constructor () public
    {
        isOwner[msg.sender] = true;
        owners.push(msg.sender);
        emit OwnerAddition(msg.sender);
        required = 1;
    }

     
     
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

     
     
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }

     
     
     
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

     
     
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

     
     
     
     
     
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

     
     
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

     
     
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

     
     
    function executeTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

     
     
    function external_call(address destination, uint value, uint dataLength, bytes data) private returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)    
            let d := add(data, 32)  
            result := call(
                sub(gas, 34710),    
                                    
                                    
                destination,
                value,
                d,
                dataLength,         
                x,
                0                   
            )
        }
        return result;
    }

     
     
     
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

     
     
     
     
     
     
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

     
     
     
     
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) count += 1;
        }
    }

     
     
     
     
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
      for ( uint i=0; i<transactionCount; i++ ) {
        if ( pending && !transactions[i].executed || executed && transactions[i].executed )
           count += 1;
      }
    }

     
     
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

     
     
     
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

     
     
     
     
     
     
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}

contract NomadPreICO is
    StandardToken, 
    Ownable, 
    DetailedERC20("preNSP", "NOMAD SPACE NETWORK preICO TOKEN", 18)
    , MultiSigWallet
{
    using SafeMath for uint256;

     
    uint256 public StartDate     = 1527811200;        
    uint256 public EndDate       = 1538351999;        
    uint256 public ExchangeRate  = 762000000000000000000;  
    uint256 public hardCap       = 5000000*ExchangeRate;  
    uint256 public softCap       = 1000000*ExchangeRate;  

     
     
     
       
     

     
    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
     
    }

    function setExchangeRate(uint256 newExchangeRate) 
        onlyOwner 
        public
    {
        require(getTimestamp() < StartDate);
        ExchangeRate = newExchangeRate;
        hardCap      = 5000000*ExchangeRate;
        softCap      = 1000000*ExchangeRate;
    }

    address[] senders;
    mapping(address => uint256) sendersCalcTokens;
    mapping(address => uint256) sendersEth;

    function getSenders          (               ) public view returns (address[]) {return senders                   ;}
    function getSendersCalcTokens(address _sender) public view returns (uint256 )  {return sendersCalcTokens[_sender];}
    function getSendersEth       (address _sender) public view returns (uint256)   {return sendersEth       [_sender];}

    function () payable public {
        require(msg.value > 0); 
        require(getTimestamp() >= StartDate);
        require(getTimestamp() <= EndDate);
        require(Eth2USD(address(this).balance) <= hardCap);
        
        sendersEth[msg.sender] = sendersEth[msg.sender].add(msg.value);
        sendersCalcTokens[msg.sender] = sendersCalcTokens[msg.sender].add( Eth2preNSP(msg.value) );

        for (uint i=0; i<senders.length; i++) 
            if (senders[i] == msg.sender) return;
        senders.push(msg.sender);        
    }

    bool public mvpExists = false;
    bool public softCapOk = false;

    function setMvpExists(bool _mvpExists) 
        public 
        onlyWallet 
    { mvpExists = _mvpExists; }
    
    function checkSoftCapOk() public { 
        require(!softCapOk);
        if( softCap <= Eth2USD(address(this).balance) ) softCapOk = true;
    }

    address withdrawalAddress;
    function setWithdrawalAddress (address _withdrawalAddress) public onlyWallet { 
        withdrawalAddress = _withdrawalAddress;
    }
    
    function release() public onlyWallet {
        releaseETH();
        releaseTokens();
    }

    function releaseETH() public onlyWallet {
        if(address(this).balance > 0 && softCapOk && mvpExists)
            address(withdrawalAddress).transfer(address(this).balance);
    }

    function releaseTokens() public onlyWallet {
        if(softCapOk && mvpExists)
            for (uint i=0; i<senders.length; i++)
                releaseTokens4Sender(i);
    }

    function releaseTokens4Sender(uint senderNum) public onlyWallet {
        address sender = senders[senderNum];
        uint256 tokens = sendersCalcTokens[sender];
        if (tokens>0) {
            sendersCalcTokens[sender] = 0;
            mint(sender, tokens);
        }
    }

    function mint(address _to, uint256 _amount) internal {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
    }

    function returnEth() public onlyWallet {
        require(getTimestamp() > EndDate);
        require(!softCapOk || !mvpExists);
        
        for (uint i=0; i<senders.length; i++)
            returnEth4Sender(i);
    }

    function returnEth4Sender(uint senderNum) public onlyWallet {
        require(getTimestamp() > EndDate);
        require(!softCapOk || !mvpExists);
        
        address sender = senders[senderNum];
        sendersEth[sender] = 0;
        address(sender).transfer(sendersEth[sender]);
    }

    function GetTokenPriceCents() public view returns (uint256) {
        require(getTimestamp() >= StartDate);
        require(getTimestamp() <= EndDate);
        if( (getTimestamp() >= 1527811200)&&(getTimestamp() < 1530403200) ) return 4;  
        else                   
        if( (getTimestamp() >= 1530403200)&&(getTimestamp() < 1533081600) ) return 5;  
        else
        if( (getTimestamp() >= 1533081600)&&(getTimestamp() < 1535760000) ) return 6;  
        else
        if( (getTimestamp() >= 1535760000)&&(getTimestamp() < 1538352000) ) return 8;  
        else revert();
    }

    function Eth2USD(uint256 _wei) public view returns (uint256) {
        return _wei*ExchangeRate;
    }

    function Eth2preNSP(uint256 _wei) public view returns (uint256) {
        return Eth2USD(_wei)*100/GetTokenPriceCents();
    }
}