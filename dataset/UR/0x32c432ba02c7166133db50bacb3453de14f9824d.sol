 

pragma solidity ^0.4.24;



contract MultiOwnable {
   

  bool public isLocked;

  address public owner1;
  address public owner2;

   
  mapping(bytes32 => PendingState) public m_pending;

   

   
  struct PendingState {
    bool confirmation1;
    bool confirmation2;
    uint exists;  
  }

   

  event Confirmation(address owner, bytes32 operation);
  event Revoke(address owner, bytes32 operation);
  event ConfirmationNeeded(bytes32 operation, address from, uint value, address to);

  modifier onlyOwner {
    require(isOwner(msg.sender));
    _;
  }

  modifier onlyManyOwners(bytes32 _operation) {
    if (confirmAndCheck(_operation))
      _;
  }

  modifier onlyIfUnlocked {
    require(!isLocked);
    _;
  }


   
   
  constructor(address _owner1, address _owner2) public {
    require(_owner1 != address(0));
    require(_owner2 != address(0));

    owner1 = _owner1;
    owner2 = _owner2;
    isLocked = true;
  }

  function unlock() public onlyOwner {
    isLocked = false;
  }

   
  function revoke(bytes32 _operation) external onlyOwner {
    emit Revoke(msg.sender, _operation);
    delete m_pending[_operation];
  }

  function isOwner(address _addr) public view returns (bool) {
    return _addr == owner1 || _addr == owner2;
  }

  function hasConfirmed(bytes32 _operation, address _owner)
    constant public onlyOwner
    returns (bool) {

    if (_owner == owner1) {
      return m_pending[_operation].confirmation1;
    }

    if (_owner == owner2) {
      return m_pending[_operation].confirmation2;
    }
  }

   

  function confirmAndCheck(bytes32 _operation)
    internal onlyOwner
    returns (bool) {

     
    if (m_pending[_operation].exists == 0) {
      if (msg.sender == owner1) { m_pending[_operation].confirmation1 = true; }
      if (msg.sender == owner2) { m_pending[_operation].confirmation2 = true; }
      m_pending[_operation].exists = 1;

       
      return false;
    }

     
    if (msg.sender == owner1 && m_pending[_operation].confirmation1 == true) {
      return false;
    }

     
    if (msg.sender == owner2 && m_pending[_operation].confirmation2 == true) {
      return false;
    }

    if (msg.sender == owner1) {
      m_pending[_operation].confirmation1 = true;
    }

    if (msg.sender == owner2) {
      m_pending[_operation].confirmation2 = true;
    }

     
    return m_pending[_operation].confirmation1 && m_pending[_operation].confirmation2;
  }
}



 
 
 
library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }

  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }

  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }

  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}



 
 
 
 
contract ERC20Interface {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



 
 
 
 
 
contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
 

 
contract TruGold is ERC20Interface, MultiOwnable {
  using SafeMath for uint;

  string public symbol;
  string public  name;
  uint8 public decimals;
  uint _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;
  mapping (bytes32 => Transaction) public pendingTransactions;  

  struct Transaction {
    address from;
    address to;
    uint value;
  }


   
   
   
  constructor(address target, address _owner1, address _owner2)
    MultiOwnable(_owner1, _owner2) public {
    symbol = "TruGold";
    name = "TruGold";
    decimals = 18;
    _totalSupply = 300000000 * 10**uint(decimals);
    balances[target] = _totalSupply;

    emit Transfer(address(0), target, _totalSupply);
  }

   
   
   
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }

   
   
   
  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }

   
   
   
   
   
   
  function transfer(address to, uint tokens)
    public
    onlyIfUnlocked
    returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);

    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  function ownerTransfer(address from, address to, uint value)
    public onlyOwner
    returns (bytes32 operation) {

    operation = keccak256(abi.encodePacked(msg.data, block.number));

    if (!approveOwnerTransfer(operation) && pendingTransactions[operation].to == 0) {
      pendingTransactions[operation].from = from;
      pendingTransactions[operation].to = to;
      pendingTransactions[operation].value = value;

      emit ConfirmationNeeded(operation, from, value, to);
    }

    return operation;
  }

  function approveOwnerTransfer(bytes32 operation)
    public
    onlyManyOwners(operation)
    returns (bool success) {

     
    Transaction storage transaction = pendingTransactions[operation];

     
    balances[transaction.from] = balances[transaction.from].sub(transaction.value);
    balances[transaction.to] = balances[transaction.to].add(transaction.value);

     
    delete pendingTransactions[operation];

    emit Transfer(transaction.from, transaction.to, transaction.value);

    return true;
  }

   
   
   
   
   
   
   
   
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

   
   
   
   
   
   
   
   
   
  function transferFrom(address from, address to, uint tokens) public onlyIfUnlocked returns (bool success) {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);

    emit Transfer(from, to, tokens);

    return true;
  }

   
   
   
   
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }


   
   
   
   
   
  function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);

    return true;
  }


   
   
   
  function () public payable {
    revert();
  }

   
   
   
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
      return ERC20Interface(tokenAddress).transfer(owner1, tokens);
  }
}