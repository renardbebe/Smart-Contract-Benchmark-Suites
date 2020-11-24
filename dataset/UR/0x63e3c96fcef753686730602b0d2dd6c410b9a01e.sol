 

pragma solidity ^0.4.21;

 
 

 
contract ERC20
{
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public returns (bool ok);
}

 
library SafeMath 
{
   
  function sub(uint a, uint b) 
    internal 
    pure 
    returns (uint) 
  {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint a, uint b) 
    internal 
    pure 
    returns (uint) 
  {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract MultiSigWalletTokenLimit
{
  using SafeMath for uint;

   
  event Confirmation(address indexed sender, uint indexed transaction_id);
  event Revocation(address indexed sender, uint indexed transaction_id);
  event Submission(uint indexed transaction_id);
  event Execution(uint indexed transaction_id);
  event ExecutionFailure(uint indexed transaction_id);
  event TokensReceived(address indexed from, uint value);
  event Transfer(address indexed to, uint indexed value);
  event CurrentPeriodChanged(uint indexed current_period, uint indexed current_transferred, uint indexed current_limit);

   
  struct Transaction
  {
    address to;
    uint value;
    bool executed;
  }

  struct Period
  {
    uint timestamp;
    uint current_limit;
    uint limit;
  }

   
  mapping (uint => Transaction) public transactions;
  mapping (uint => mapping (address => bool)) public confirmations;
  mapping (address => bool) public is_owner;
  address[] public owners;
  uint public required;
  uint public transaction_count;
  ERC20 public erc20_contract;   
  mapping (uint => Period) public periods;
  uint public period_count;
  uint public current_period;
  uint public current_transferred;   

   
  modifier ownerExists(address owner) 
  {
    require(is_owner[owner]);
    _;
  }

  modifier transactionExists(uint transaction_id) 
  {
    require(transactions[transaction_id].to != 0);
    _;
  }

  modifier confirmed(uint transaction_id, address owner)
  {
    require(confirmations[transaction_id][owner]);
    _;
  }

  modifier notConfirmed(uint transaction_id, address owner)
  {
    require(!confirmations[transaction_id][owner]);
    _;
  }

  modifier notExecuted(uint transaction_id)
  {
    require(!transactions[transaction_id].executed);
    _;
  }

  modifier ownerOrWallet(address owner)
  {
    require (msg.sender == address(this) || is_owner[owner]);
    _;
  }

  modifier notNull(address _address)
  {
    require(_address != 0);
    _;
  }

   
  function()
    public
    payable
  {
    revert();
  }

   
   
   
   
   
   
   
  function MultiSigWalletTokenLimit(address[] _owners, uint _required, uint[] _timestamps, uint[] _limits, ERC20 _erc20_contract)
    public
  {
    for (uint i = 0; i < _owners.length; i++)
    {
      require(!is_owner[_owners[i]] && _owners[i] != 0);
      is_owner[_owners[i]] = true;
    }
    owners = _owners;
    required = _required;

    periods[0].timestamp = 2**256 - 1;
    periods[0].limit = 2**256 - 1;
    uint total_limit = 0;
    for (i = 0; i < _timestamps.length; i++)
    {
      periods[i + 1].timestamp = _timestamps[i];
      periods[i + 1].current_limit = _limits[i];
      total_limit = total_limit.add(_limits[i]);
      periods[i + 1].limit = total_limit;
    }
    period_count = 1 + _timestamps.length;
    current_period = 0;
    if (_timestamps.length > 0)
      current_period = 1;
    current_transferred = 0;

    erc20_contract = _erc20_contract;
  }

   
   
   
   
  function submitTransaction(address to, uint value)
    public
    notNull(to)
    returns (uint transaction_id)
  {
    transaction_id = addTransaction(to, value);
    confirmTransaction(transaction_id);
  }

   
   
  function confirmTransaction(uint transaction_id)
    public
    ownerExists(msg.sender)
    transactionExists(transaction_id)
    notConfirmed(transaction_id, msg.sender)
  {
    confirmations[transaction_id][msg.sender] = true;
    emit Confirmation(msg.sender, transaction_id);
    executeTransaction(transaction_id);
  }

   
   
  function revokeConfirmation(uint transaction_id)
    public
    ownerExists(msg.sender)
    confirmed(transaction_id, msg.sender)
    notExecuted(transaction_id)
  {
    confirmations[transaction_id][msg.sender] = false;
    emit Revocation(msg.sender, transaction_id);
  }

  function executeTransaction(uint transaction_id)
    public
    ownerExists(msg.sender)
    confirmed(transaction_id, msg.sender)
    notExecuted(transaction_id)
  {
    if (isConfirmed(transaction_id))
    {
      Transaction storage txn = transactions[transaction_id];
      txn.executed = true;
      if (transfer(txn.to, txn.value))
        emit Execution(transaction_id);
      else
      {
        emit ExecutionFailure(transaction_id);
        txn.executed = false;
      }
    }
  }

   
   
   
  function isConfirmed(uint transaction_id)
    public
    view
    returns (bool)
  {
    uint count = 0;
    for (uint i = 0; i < owners.length; i++)
    {
      if (confirmations[transaction_id][owners[i]])
        ++count;
    if (count >= required)
      return true;
    }
  }

   
   
   
   
   
  function addTransaction(address to, uint value)
    internal
    returns (uint transaction_id)
  {
    transaction_id = transaction_count;
    transactions[transaction_id] = Transaction({
      to: to,
      value: value,
      executed: false
    });
    ++transaction_count;
    emit Submission(transaction_id);
  }

   
   
   
   
  function getConfirmationCount(uint transaction_id)
    public
    view
    returns (uint count)
  {
    for (uint i = 0; i < owners.length; i++)
      if (confirmations[transaction_id][owners[i]])
        ++count;
  }

   
   
   
   
  function getTransactionCount(bool pending, bool executed)
    public
    view
    returns (uint count)
  {
    for (uint i = 0; i < transaction_count; i++)
      if (pending && !transactions[i].executed
        || executed && transactions[i].executed)
        ++count;
  }

   
   
  function getOwners()
    public
    view
    returns (address[])
  {
    return owners;
  }

   
   
   
  function getConfirmations(uint transaction_id)
    public
    view
    returns (address[] _confirmations)
  {
    address[] memory confirmations_temp = new address[](owners.length);
    uint count = 0;
    uint i;
    for (i = 0; i < owners.length; i++)
      if (confirmations[transaction_id][owners[i]])
      {
        confirmations_temp[count] = owners[i];
        ++count;
      }
      _confirmations = new address[](count);
      for (i = 0; i < count; i++)
        _confirmations[i] = confirmations_temp[i];
  }

   
   
   
   
   
   
  function getTransactionIds(uint from, uint to, bool pending, bool executed)
    public
    view
    returns (uint[] _transaction_ids)
  {
    uint[] memory transaction_ids_temp = new uint[](transaction_count);
    uint count = 0;
    uint i;
    for (i = 0; i < transaction_count; i++)
      if (pending && !transactions[i].executed
        || executed && transactions[i].executed)
      {
        transaction_ids_temp[count] = i;
        ++count;
      }
      _transaction_ids = new uint[](to - from);
      for (i = from; i < to; i++)
        _transaction_ids[i - from] = transaction_ids_temp[i];
  }

   
   
   
  function tokenFallback(address from, uint value, bytes)
    public
  {
    require(msg.sender == address(erc20_contract));
    emit TokensReceived(from, value);
  }

   
  function getWalletBalance()
    public
    view
    returns(uint)
  { 
    return erc20_contract.balanceOf(this);
  }

   
  function updateCurrentPeriod()
    public
    ownerOrWallet(msg.sender)
  {
    uint new_period = 0;
    for (uint i = 1; i < period_count; i++)
      if (periods[i].timestamp > now && periods[i].timestamp < periods[new_period].timestamp)
        new_period = i;
    if (new_period != current_period)
    {
      current_period = new_period;
      emit CurrentPeriodChanged(current_period, current_transferred, periods[current_period].limit);
    }
  }

   
   
   
  function transfer(address to, uint value) 
    internal
    returns (bool)
  {
    updateCurrentPeriod();
    require(value <= getWalletBalance() && current_transferred.add(value) <= periods[current_period].limit);

    if (erc20_contract.transfer(to, value)) 
    {
      current_transferred = current_transferred.add(value);
      emit Transfer(to, value);
      return true;
    }

    return false;
  }

}