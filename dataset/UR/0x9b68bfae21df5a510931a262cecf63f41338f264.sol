 

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
        assert(c >= a && c >= b);
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

contract OldToken is ERC20 {
     
    bool public isDecentBetToken;

    address public decentBetMultisig;
}

contract NextUpgradeAgent is SafeMath {
    address public owner;

    bool public isUpgradeAgent;

    function upgradeFrom(address _from, uint256 _value) public;

    function finalizeUpgrade() public;

    function setOriginalSupply() public;
}

 
contract NewDecentBetVault is SafeMath {

     
    bool public isDecentBetVault = false;

    NewDecentBetToken decentBetToken;

    address decentBetMultisig;

    uint256 unlockedAtTime;

     
    uint256 public constant timeOffset = 47 weeks;

     
     
    function NewDecentBetVault(address _decentBetMultisig)   {
        if (_decentBetMultisig == 0x0) revert();
        decentBetToken = NewDecentBetToken(msg.sender);
        decentBetMultisig = _decentBetMultisig;
        isDecentBetVault = true;

         
        unlockedAtTime = safeAdd(getTime(), timeOffset);
    }

     
    function unlock() external {
         
        if (getTime() < unlockedAtTime) revert();
         
        if (!decentBetToken.transfer(decentBetMultisig, decentBetToken.balanceOf(this))) revert();
    }

    function getTime() internal returns (uint256) {
        return now;
    }

     
    function() payable {
        revert();
    }

}

contract NewDecentBetToken is ERC20, SafeMath {

     
    bool public isDecentBetToken;

    string public constant name = "Decent.Bet Token";

    string public constant symbol = "DBET";

    uint256 public constant decimals = 18;   

    uint256 public constant housePercentOfTotal = 10;

    uint256 public constant vaultPercentOfTotal = 18;

    uint256 public constant bountyPercentOfTotal = 2;

    uint256 public constant crowdfundPercentOfTotal = 70;

     
    bool public isNewToken = false;

     
    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

     
    NewUpgradeAgent public upgradeAgent;

    NextUpgradeAgent public nextUpgradeAgent;

    bool public finalizedNextUpgrade = false;

    address public nextUpgradeMaster;

    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

    event UpgradeFinalized(address sender, address nextUpgradeAgent);

    event UpgradeAgentSet(address agent);

    uint256 public totalUpgraded;

     
    OldToken public oldToken;

    address public decentBetMultisig;

    uint256 public oldTokenTotalSupply;

    NewDecentBetVault public timeVault;

    function NewDecentBetToken(address _upgradeAgent,
    address _oldToken, address _nextUpgradeMaster) public {

        isNewToken = true;

        isDecentBetToken = true;

        if (_upgradeAgent == 0x0) revert();
        upgradeAgent = NewUpgradeAgent(_upgradeAgent);

        if (_nextUpgradeMaster == 0x0) revert();
        nextUpgradeMaster = _nextUpgradeMaster;

        oldToken = OldToken(_oldToken);
        if (!oldToken.isDecentBetToken()) revert();
        oldTokenTotalSupply = oldToken.totalSupply();

        decentBetMultisig = oldToken.decentBetMultisig();
        if (!MultiSigWallet(decentBetMultisig).isMultiSigWallet()) revert();

        timeVault = new NewDecentBetVault(decentBetMultisig);
        if (!timeVault.isDecentBetVault()) revert();

         
        uint256 vaultTokens = safeDiv(safeMul(oldTokenTotalSupply, vaultPercentOfTotal),
        crowdfundPercentOfTotal);
        balances[timeVault] = safeAdd(balances[timeVault], vaultTokens);
        Transfer(0, timeVault, vaultTokens);

         
        uint256 houseTokens = safeDiv(safeMul(oldTokenTotalSupply, housePercentOfTotal),
        crowdfundPercentOfTotal);
        balances[decentBetMultisig] = safeAdd(balances[decentBetMultisig], houseTokens);
        Transfer(0, decentBetMultisig, houseTokens);

         
        uint256 bountyTokens = safeDiv(safeMul(oldTokenTotalSupply, bountyPercentOfTotal),
        crowdfundPercentOfTotal);
        balances[decentBetMultisig] = safeAdd(balances[decentBetMultisig], bountyTokens);
        Transfer(0, decentBetMultisig, bountyTokens);

        totalSupply = safeAdd(safeAdd(vaultTokens, houseTokens), bountyTokens);
    }

     
    function createToken(address _target, uint256 _amount) public {
        if (msg.sender != address(upgradeAgent)) revert();
        if (_amount == 0) revert();

        balances[_target] = safeAdd(balances[_target], _amount);
        totalSupply = safeAdd(totalSupply, _amount);
        Transfer(_target, _target, _amount);
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) revert();
        if (_to == address(upgradeAgent)) revert();
        if (_to == address(this)) revert();
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {return false;}
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) revert();
        if (_to == address(upgradeAgent)) revert();
        if (_to == address(this)) revert();
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        }
        else {return false;}
    }

     
     
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     

     
     
    function upgrade(uint256 value) external {
        if (nextUpgradeAgent.owner() == 0x0) revert();
         
        if (finalizedNextUpgrade) revert();
         

         
        if (value == 0) revert();
        if (value > balances[msg.sender]) revert();

         
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        totalUpgraded = safeAdd(totalUpgraded, value);
        nextUpgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, nextUpgradeAgent, value);
    }

     
     
     
    function setNextUpgradeAgent(address agent) external {
        if (agent == 0x0) revert();
         
        if (msg.sender != nextUpgradeMaster) revert();
         
        nextUpgradeAgent = NextUpgradeAgent(agent);
        if (!nextUpgradeAgent.isUpgradeAgent()) revert();
        nextUpgradeAgent.setOriginalSupply();
        UpgradeAgentSet(nextUpgradeAgent);
    }

     
     
     
    function setNextUpgradeMaster(address master) external {
        if (master == 0x0) revert();
        if (msg.sender != nextUpgradeMaster) revert();
         
        nextUpgradeMaster = master;
    }

     
     
    function finalizeNextUpgrade() external {
        if (nextUpgradeAgent.owner() == 0x0) revert();
         
        if (msg.sender != nextUpgradeMaster) revert();
         
        if (finalizedNextUpgrade) revert();
         

        finalizedNextUpgrade = true;
         

        nextUpgradeAgent.finalizeUpgrade();
         
        UpgradeFinalized(msg.sender, nextUpgradeAgent);
    }

     
    function() {revert();}
}


 
contract NewUpgradeAgent is SafeMath {

     
    bool public isUpgradeAgent = false;

     
    address public owner;

     
    bool public upgradeHasBegun = false;

    bool public finalizedUpgrade = false;

    OldToken public oldToken;

    address public decentBetMultisig;

    NewDecentBetToken public newToken;

    uint256 public originalSupply;  

    uint256 public correctOriginalSupply;  

    uint256 public mintedPercentOfTokens = 30;  

    uint256 public crowdfundPercentOfTokens = 70;

    uint256 public mintedTokens;

    event NewTokenSet(address token);

    event UpgradeHasBegun();

    event InvariantCheckFailed(uint oldTokenSupply, uint newTokenSupply, uint originalSupply, uint value);

    event InvariantCheckPassed(uint oldTokenSupply, uint newTokenSupply, uint originalSupply, uint value);

    function NewUpgradeAgent(address _oldToken) {
        owner = msg.sender;
        isUpgradeAgent = true;
        oldToken = OldToken(_oldToken);
        if (!oldToken.isDecentBetToken()) revert();
        decentBetMultisig = oldToken.decentBetMultisig();
        originalSupply = oldToken.totalSupply();
        mintedTokens = safeDiv(safeMul(originalSupply, mintedPercentOfTokens), crowdfundPercentOfTokens);
        correctOriginalSupply = safeAdd(originalSupply, mintedTokens);
    }

     
     
     
     
    function safetyInvariantCheck(uint256 _value) public {
        if (!newToken.isNewToken()) revert();
         
        uint oldSupply = oldToken.totalSupply();
        uint newSupply = newToken.totalSupply();
        if (safeAdd(oldSupply, newSupply) != safeSub(correctOriginalSupply, _value)) {
            InvariantCheckFailed(oldSupply, newSupply, correctOriginalSupply, _value);
        } else {
            InvariantCheckPassed(oldSupply, newSupply, correctOriginalSupply, _value);
        }
    }

     
     
    function setNewToken(address _newToken) external {
        if (msg.sender != owner) revert();
        if (_newToken == 0x0) revert();
        if (upgradeHasBegun) revert();
         

        newToken = NewDecentBetToken(_newToken);
        if (!newToken.isNewToken()) revert();
        NewTokenSet(newToken);
    }

     
    function setUpgradeHasBegun() internal {
        if (!upgradeHasBegun) {
            upgradeHasBegun = true;
            UpgradeHasBegun();
        }
    }

     
     
     
     
    function upgradeFrom(address _from, uint256 _value) public {
        if(finalizedUpgrade) revert();
        if (msg.sender != address(oldToken)) revert();
         
         
        if (_from == decentBetMultisig) revert();
         
        if (!newToken.isNewToken()) revert();
         

        setUpgradeHasBegun();
         
         
        safetyInvariantCheck(_value);

        newToken.createToken(_from, _value);

         
        safetyInvariantCheck(0);
    }

     
    function setOriginalSupply() public {
        if (msg.sender != address(oldToken)) revert();
        originalSupply = oldToken.totalSupply();
    }

    function finalizeUpgrade() public {
        if (msg.sender != address(oldToken)) revert();
        finalizedUpgrade = true;
    }

     
    function() {revert();}

}