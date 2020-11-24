 

pragma solidity ^0.4.8;

 
 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


 

 
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
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

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

 
 
contract MultiSigWallet {

     
    bool public isMultiSigWallet = false;

    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

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
        if (msg.sender != address(this)) throw;
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner]) throw;
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner]) throw;
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0) throw;
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner]) throw;
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner]) throw;
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed) throw;
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0) throw;
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (ownerCount > MAX_OWNER_COUNT) throw;
        if (_required > ownerCount) throw;
        if (_required == 0) throw;
        if (ownerCount == 0) throw;
        _;
    }

     
    function()
        payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

     
     
     
     
    function MultiSigWallet(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0) throw;
            isOwner[_owners[i]] = true;
        }
        isMultiSigWallet = true;
        owners = _owners;
        required = _required;
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
        OwnerAddition(owner);
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
        OwnerRemoval(owner);
    }

     
     
     
     
    function replaceOwnerIndexed(address owner, address newOwner, uint index)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        if (owners[index] != owner) throw;
        owners[index] = newOwner;
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }


     
     
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required);
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
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

     
     
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
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

     

     
     
    function executeTransaction(uint transactionId)
       internal
       notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction tx = transactions[transactionId];
            tx.executed = true;
            if (tx.destination.call.value(tx.value)(tx.data))
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
                tx.executed = false;
            }
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
        Submission(transactionId);
    }

     
     
     
     
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

     
     
     
     
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if ((pending && !transactions[i].executed) ||
                (executed && transactions[i].executed))
                count += 1;
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
          if ((pending && !transactions[i].executed) ||
              (executed && transactions[i].executed))
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}



contract NewToken is ERC20 {}

contract UpgradeAgent is SafeMath {
  address public owner;
  bool public isUpgradeAgent;
  NewToken public newToken;
  uint256 public originalSupply;  
  bool public upgradeHasBegun;
  function upgradeFrom(address _from, uint256 _value) public;
}

 
contract LUNVault is SafeMath {

     
    bool public isLUNVault = false;

    LunyrToken lunyrToken;
    address lunyrMultisig;
    uint256 unlockedAtBlockNumber;
     
     
    uint256 public constant numBlocksLocked = 1110857;

     
     
    function LUNVault(address _lunyrMultisig) internal {
        if (_lunyrMultisig == 0x0) throw;
        lunyrToken = LunyrToken(msg.sender);
        lunyrMultisig = _lunyrMultisig;
        isLUNVault = true;
        unlockedAtBlockNumber = safeAdd(block.number, numBlocksLocked);  
    }

     
    function unlock() external {
         
        if (block.number < unlockedAtBlockNumber) throw;
         
        if (!lunyrToken.transfer(lunyrMultisig, lunyrToken.balanceOf(this))) throw;
    }

     
    function () { throw; }

}

 
contract LunyrToken is SafeMath, ERC20 {

     
    bool public isLunyrToken = false;

     
    enum State{PreFunding, Funding, Success, Failure}

     
    string public constant name = "Lunyr Token";
    string public constant symbol = "LUN";
    uint256 public constant decimals = 18;   
    uint256 public constant crowdfundPercentOfTotal = 78;
    uint256 public constant vaultPercentOfTotal = 15;
    uint256 public constant lunyrPercentOfTotal = 7;
    uint256 public constant hundredPercent = 100;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     
    address public upgradeMaster;
    UpgradeAgent public upgradeAgent;
    uint256 public totalUpgraded;

     
    bool public finalizedCrowdfunding = false;
    uint256 public fundingStartBlock;  
    uint256 public fundingEndBlock;  
    uint256 public constant tokensPerEther = 44;  
    uint256 public constant tokenCreationMax = safeMul(250000 ether, tokensPerEther);
    uint256 public constant tokenCreationMin = safeMul(25000 ether, tokensPerEther);
     
     
     

    address public lunyrMultisig;
    LUNVault public timeVault;  

    event Upgrade(address indexed _from, address indexed _to, uint256 _value);
    event Refund(address indexed _from, uint256 _value);
    event UpgradeFinalized(address sender, address upgradeAgent);
    event UpgradeAgentSet(address agent);

     
    function LunyrToken(address _lunyrMultisig,
                        address _upgradeMaster,
                        uint256 _fundingStartBlock,
                        uint256 _fundingEndBlock) {

        if (_lunyrMultisig == 0) throw;
        if (_upgradeMaster == 0) throw;
        if (_fundingStartBlock <= block.number) throw;
        if (_fundingEndBlock   <= _fundingStartBlock) throw;
        isLunyrToken = true;
        upgradeMaster = _upgradeMaster;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
        timeVault = new LUNVault(_lunyrMultisig);
        if (!timeVault.isLUNVault()) throw;
        lunyrMultisig = _lunyrMultisig;
        if (!MultiSigWallet(lunyrMultisig).isMultiSigWallet()) throw;
    }

    function balanceOf(address who) constant returns (uint) {
        return balances[who];
    }

     
     
     
     
     
     
     
    function transfer(address to, uint256 value) returns (bool ok) {
        if (getState() != State.Success) throw;  
        if (to == 0x0) throw;
        if (to == address(upgradeAgent)) throw;
         
        uint256 senderBalance = balances[msg.sender];
        if (senderBalance >= value && value > 0) {
            senderBalance = safeSub(senderBalance, value);
            balances[msg.sender] = senderBalance;
            balances[to] = safeAdd(balances[to], value);
            Transfer(msg.sender, to, value);
            return true;
        }
        return false;
    }

     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint value) returns (bool ok) {
        if (getState() != State.Success) throw;  
        if (to == 0x0) throw;
        if (to == address(upgradeAgent)) throw;
         
        if (balances[from] >= value &&
            allowed[from][msg.sender] >= value)
        {
            balances[to] = safeAdd(balances[to], value);
            balances[from] = safeSub(balances[from], value);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], value);
            Transfer(from, to, value);
            return true;
        } else { return false; }
    }

     
     
     
     
    function approve(address spender, uint256 value) returns (bool ok) {
        if (getState() != State.Success) throw;  
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

     
     
     
    function allowance(address owner, address spender) constant returns (uint) {
        return allowed[owner][spender];
    }

     

     
     
     
    function upgrade(uint256 value) external {
        if (getState() != State.Success) throw;  
        if (upgradeAgent.owner() == 0x0) throw;  

         
        if (value == 0) throw;
        if (value > balances[msg.sender]) throw;

         
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        totalUpgraded = safeAdd(totalUpgraded, value);
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

     
     
     
     
    function setUpgradeAgent(address agent) external {
        if (getState() != State.Success) throw;  
        if (agent == 0x0) throw;  
        if (msg.sender != upgradeMaster) throw;  
        if (address(upgradeAgent) != 0x0 && upgradeAgent.upgradeHasBegun()) throw;  
        upgradeAgent = UpgradeAgent(agent);
         
        if (upgradeAgent.originalSupply() != totalSupply) throw;
        UpgradeAgentSet(upgradeAgent);
    }

     
     
     
     
    function setUpgradeMaster(address master) external {
        if (getState() != State.Success) throw;  
        if (master == 0x0) throw;
        if (msg.sender != upgradeMaster) throw;  
        upgradeMaster = master;
    }

    function setMultiSigWallet(address newWallet) external {
      if (msg.sender != lunyrMultisig) throw;
      MultiSigWallet wallet = MultiSigWallet(newWallet);
      if (!wallet.isMultiSigWallet()) throw;
      lunyrMultisig = newWallet;
    }

     

     
    function() { throw; }


     
     
     
    function create() payable external {
         
         
         
        if (getState() != State.Funding) throw;

         
        if (msg.value == 0) throw;

         
        uint256 createdTokens = safeMul(msg.value, tokensPerEther);

         
        totalSupply = safeAdd(totalSupply, createdTokens);

         
        if (totalSupply > tokenCreationMax) throw;

         
        balances[msg.sender] = safeAdd(balances[msg.sender], createdTokens);

         
        Transfer(0, msg.sender, createdTokens);
    }

     
     
     
     
     
    function finalizeCrowdfunding() external {
         
        if (getState() != State.Success) throw;  
        if (finalizedCrowdfunding) throw;  

         
        finalizedCrowdfunding = true;

         
         
        uint256 vaultTokens = safeDiv(safeMul(totalSupply, vaultPercentOfTotal), crowdfundPercentOfTotal);
        balances[timeVault] = safeAdd(balances[timeVault], vaultTokens);
        Transfer(0, timeVault, vaultTokens);

         
        uint256 lunyrTokens = safeDiv(safeMul(totalSupply, lunyrPercentOfTotal), crowdfundPercentOfTotal);
        balances[lunyrMultisig] = safeAdd(balances[lunyrMultisig], lunyrTokens);
        Transfer(0, lunyrMultisig, lunyrTokens);

        totalSupply = safeAdd(safeAdd(totalSupply, vaultTokens), lunyrTokens);

         
        if (!lunyrMultisig.send(this.balance)) throw;
    }

     
     
     
    function refund() external {
         
        if (getState() != State.Failure) throw;

        uint256 lunValue = balances[msg.sender];
        if (lunValue == 0) throw;
        balances[msg.sender] = 0;
        totalSupply = safeSub(totalSupply, lunValue);

        uint256 ethValue = safeDiv(lunValue, tokensPerEther);  
        Refund(msg.sender, ethValue);
        if (!msg.sender.send(ethValue)) throw;
    }

     
     
     
    function getState() public constant returns (State){
       
      if (finalizedCrowdfunding) return State.Success;
      if (block.number < fundingStartBlock) return State.PreFunding;
      else if (block.number <= fundingEndBlock && totalSupply < tokenCreationMax) return State.Funding;
      else if (totalSupply >= tokenCreationMin) return State.Success;
      else return State.Failure;
    }
}