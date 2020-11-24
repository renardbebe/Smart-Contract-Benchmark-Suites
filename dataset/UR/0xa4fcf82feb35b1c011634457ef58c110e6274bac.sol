 

pragma solidity 0.4.25;

contract _0xbccInterface {
    function buyAndSetDivPercentage(uint _0xbtcAmount, address _referredBy, uint8 _divChoice, string providedUnhashedPass) public returns(uint);

    function balanceOf(address who) public view returns(uint);

    function transfer(address _to, uint _value) public returns(bool);

    function transferFrom(address _from, address _toAddress, uint _amountOfTokens) public returns(bool);

    function exit() public;

    function sell(uint amountOfTokens) public;

    function withdraw(address _recipient) public;
}

contract ERC20Interface {

    function totalSupply() public constant returns(uint);

    function balanceOf(address tokenOwner) public constant returns(uint balance);

    function allowance(address tokenOwner, address spender) public constant returns(uint remaining);

    function transfer(address to, uint tokens) public returns(bool success);

    function approve(address spender, uint tokens) public returns(bool success);

    function transferFrom(address from, address to, uint tokens) public returns(bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract ERC223Receiving {
    function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns(bool);
}

contract _0xbtcBankroll is ERC223Receiving {
    using SafeMath
    for uint;

     

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event WhiteListAddition(address indexed contractAddress);
    event WhiteListRemoval(address indexed contractAddress);
    event RequirementChange(uint required);
    event DevWithdraw(uint amountTotal, uint amountPerPerson);
    event _0xBTCLogged(uint amountReceived, address sender);
    event BankrollInvest(uint amountReceived);
    event DailyTokenAdmin(address gameContract);
    event DailyTokensSent(address gameContract, uint tokens);
    event DailyTokensReceived(address gameContract, uint tokens);

     

    uint constant public MAX_OWNER_COUNT = 10;
    uint constant public MAX_WITHDRAW_PCT_DAILY = 100;
    uint constant public MAX_WITHDRAW_PCT_TX = 100;
    uint constant internal resetTimer = 1 days;

     

    ERC20Interface internal _0xBTC;

     

    address internal _0xbccAddress;
    _0xbccInterface public _0xbcc;

     

    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) public dailyTokensPerContract;
    address internal divCardAddress;
    address[] public owners;
    address[] public whiteListedContracts;
    uint public required;
    uint public transactionCount;
    uint internal dailyResetTime;
    uint internal dailyTknLimit;
    uint internal tknsDispensedToday;
    bool internal reEntered = false;

     

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    struct TKN {
        address sender;
        uint value;
    }

     

    modifier onlyWallet() {
        if (msg.sender != address(this))
            revert();
        _;
    }

    modifier contractIsNotWhiteListed(address contractAddress) {
        if (isWhitelisted[contractAddress])
            revert();
        _;
    }

    modifier contractIsWhiteListed(address contractAddress) {
        if (!isWhitelisted[contractAddress])
            revert();
        _;
    }

    modifier isAnOwner() {
        address caller = msg.sender;
        if (!isOwner[caller])
            revert();
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
            revert();
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            revert();
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0)
            revert();
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed)
            revert();
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0)
            revert();
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (ownerCount > MAX_OWNER_COUNT ||
            _required > ownerCount ||
            _required == 0 ||
            ownerCount == 0)
            revert();
        _;
    }

     

     
     
     
    constructor(address[] _owners, uint _required, address _btcAddress)
    public
    validRequirement(_owners.length, _required) {
        for (uint i = 0; i < _owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0)
                revert();
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        _0xBTC = ERC20Interface(_btcAddress);

        dailyResetTime = now - (1 days);
    }

    function add0xbccAddresses(address _0xbtc, address _divcards)
    public
    isAnOwner {
        _0xbccAddress = _0xbtc;
        divCardAddress = _divcards;
        _0xbcc = _0xbccInterface(_0xbccAddress);
    }

     
    function ()
    payable
    public {

    }

    uint NonICOBuyins;

    function deposit(uint value)
    public {
        _0xBTC.transferFrom(msg.sender, address(this), value);
        NonICOBuyins = NonICOBuyins.add(value);
    }

     
    function buyTokens()
    public
    isAnOwner {
        uint savings = _0xBTC.balanceOf(address(this));
        if (savings.mul(1e10) > 0.01 ether) {  
            _0xBTC.approve(_0xbcc, savings);
            _0xbcc.buyAndSetDivPercentage(savings, address(0x0), 30, "");
            emit BankrollInvest(savings);
        } else {
            emit _0xBTCLogged(savings, msg.sender);
        }
    }

    function tokenFallback(address   , uint   , bytes   ) public returns(bool) {
         
    }

     
     
    function permissibleTokenWithdrawal(uint _toWithdraw)
    public
    returns(bool) {
        uint currentTime = now;
        uint tokenBalance = _0xbcc.balanceOf(address(this));
        uint maxPerTx = (tokenBalance.mul(MAX_WITHDRAW_PCT_TX)).div(100);

        require(_toWithdraw <= maxPerTx);

        if (currentTime - dailyResetTime >= resetTimer) {
            dailyResetTime = currentTime;
            dailyTknLimit = (tokenBalance.mul(MAX_WITHDRAW_PCT_DAILY)).div(100);
            tknsDispensedToday = _toWithdraw;
            return true;
        } else {
            if (tknsDispensedToday.add(_toWithdraw) <= dailyTknLimit) {
                tknsDispensedToday += _toWithdraw;
                return true;
            } else {
                return false;
            }
        }
    }

     
    function setDailyTokenLimit(uint limit)
    public
    isAnOwner {
        dailyTknLimit = limit;
    }

     
     
    function addOwner(address owner)
    public
    onlyWallet
    ownerDoesNotExist(owner)
    notNull(owner)
    validRequirement(owners.length + 1, required) {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

     
     
    function removeOwner(address owner)
    public
    onlyWallet
    ownerExists(owner)
    validRequirement(owners.length, required) {
        isOwner[owner] = false;
        for (uint i = 0; i < owners.length - 1; i++)
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
    ownerDoesNotExist(newOwner) {
        for (uint i = 0; i < owners.length; i++)
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
    validRequirement(owners.length, _required) {
        required = _required;
        emit RequirementChange(_required);
    }

     
     
     
     
     
    function submitTransaction(address destination, uint value, bytes data)
    public
    returns(uint transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

     
     
    function confirmTransaction(uint transactionId)
    public
    ownerExists(msg.sender)
    transactionExists(transactionId)
    notConfirmed(transactionId, msg.sender) {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

     
     
    function revokeConfirmation(uint transactionId)
    public
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId) {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

     
     
    function executeTransaction(uint transactionId)
    public
    notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction storage txToExecute = transactions[transactionId];
            txToExecute.executed = true;
            if (txToExecute.destination.call.value(txToExecute.value)(txToExecute.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txToExecute.executed = false;
            }
        }
    }

     
     
     
    function isConfirmed(uint transactionId)
    public
    constant
    returns(bool) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

     

     
     
     
     
     
    function addTransaction(address destination, uint value, bytes data)
    internal
    notNull(destination)
    returns(uint transactionId) {
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
    returns(uint count) {
        for (uint i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

     
     
     
     
    function getTransactionCount(bool pending, bool executed)
    public
    constant
    returns(uint count) {
        for (uint i = 0; i < transactionCount; i++)
            if (pending && !transactions[i].executed ||
                executed && transactions[i].executed)
                count += 1;
    }

     
     
    function getOwners()
    public
    constant
    returns(address[]) {
        return owners;
    }

     
     
     
    function getConfirmations(uint transactionId)
    public
    constant
    returns(address[] _confirmations) {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

     
     
     
     
     
     
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
    public
    constant
    returns(uint[] _transactionIds) {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++)
            if (pending && !transactions[i].executed ||
                executed && transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }

     
    function whiteListContract(address contractAddress)
    public
    isAnOwner
    contractIsNotWhiteListed(contractAddress)
    notNull(contractAddress) {
        isWhitelisted[contractAddress] = true;
        whiteListedContracts.push(contractAddress);
         
        dailyTokensPerContract[contractAddress] = 0;
        emit WhiteListAddition(contractAddress);
    }

     
     
     
     
     
    function deWhiteListContract(address contractAddress)
    public
    isAnOwner
    contractIsWhiteListed(contractAddress) {
        isWhitelisted[contractAddress] = false;
        for (uint i = 0; i < whiteListedContracts.length - 1; i++)
            if (whiteListedContracts[i] == contractAddress) {
                whiteListedContracts[i] = owners[whiteListedContracts.length - 1];
                break;
            }

        whiteListedContracts.length -= 1;

        emit WhiteListRemoval(contractAddress);
    }

    function contractTokenWithdraw(uint amount, address target) public
    contractIsWhiteListed(msg.sender) {
        require(isWhitelisted[msg.sender]);
        require(_0xbcc.transfer(target, amount));
    }

     
    function alterTokenGrant(address _contract, uint _newAmount)
    public
    isAnOwner
    contractIsWhiteListed(_contract) {
        dailyTokensPerContract[_contract] = _newAmount;
    }

    function queryTokenGrant(address _contract)
    public
    view
    returns(uint) {
        return dailyTokensPerContract[_contract];
    }

     
     
    function dailyAccounting()
    public
    isAnOwner {
        for (uint i = 0; i < whiteListedContracts.length; i++) {
            address _contract = whiteListedContracts[i];
            if (dailyTokensPerContract[_contract] > 0) {
                allocateTokens(_contract);
                emit DailyTokenAdmin(_contract);
            }
        }
    }

     
     
    function retrieveTokens(address _contract, uint _amount)
    public
    isAnOwner
    contractIsWhiteListed(_contract) {
        require(_0xbcc.transferFrom(_contract, address(this), _amount));
    }

     
     
     
    function allocateTokens(address _contract)
    public
    isAnOwner
    contractIsWhiteListed(_contract) {
        uint dailyAmount = dailyTokensPerContract[_contract];
        uint bccPresent = _0xbcc.balanceOf(_contract);

         
        if (bccPresent <= dailyAmount) {
             
            uint toDispense = dailyAmount.sub(bccPresent);

             
            require(permissibleTokenWithdrawal(toDispense));

            require(_0xbcc.transfer(_contract, toDispense));
            emit DailyTokensSent(_contract, toDispense);
        } else {
             
            uint toRetrieve = bccPresent.sub(dailyAmount);
            require(_0xbcc.transferFrom(_contract, address(this), toRetrieve));
            emit DailyTokensReceived(_contract, toRetrieve);

        }
        emit DailyTokenAdmin(_contract);
    }

     
    function devTokenWithdraw(uint amount) public
    onlyWallet {
        require(permissibleTokenWithdrawal(amount));

        uint amountPerPerson = SafeMath.div(amount, owners.length);

        for (uint i = 0; i < owners.length; i++) {
            _0xbcc.transfer(owners[i], amountPerPerson);
        }

        emit DevWithdraw(amount, amountPerPerson);
    }

     
     
    function changeDivCardAddress(address _newDivCardAddress)
    public
    isAnOwner {
        divCardAddress = _newDivCardAddress;
    }

     
     
     
    function receiveDividends(uint amount) public {

        _0xBTC.transferFrom(msg.sender, address(this), amount);

        if (!reEntered) {
            uint ActualBalance = (_0xBTC.balanceOf(address(this)).sub(NonICOBuyins));
            if (ActualBalance.mul(1e10) > 0.01 ether) {
                reEntered = true;
                _0xBTC.approve(_0xbcc, ActualBalance);
                _0xbcc.buyAndSetDivPercentage(ActualBalance, address(0x0), 30, "");
                emit BankrollInvest(ActualBalance);
                reEntered = false;
            }
        }
    }

     
    function buyInWithAllBalance() public isAnOwner {
        if (!reEntered) {
            uint balance = _0xBTC.balanceOf(address(this));
            require(balance.mul(1e10) > 0.01 ether);
            _0xBTC.approve(_0xbcc, balance);
            _0xbcc.buyAndSetDivPercentage(balance, address(0x0), 30, "");
        }
    }

     

     
    function fromHexChar(uint c) public pure returns(uint) {
        if (byte(c) >= byte('0') && byte(c) <= byte('9')) {
            return c - uint(byte('0'));
        }
        if (byte(c) >= byte('a') && byte(c) <= byte('f')) {
            return 10 + c - uint(byte('a'));
        }
        if (byte(c) >= byte('A') && byte(c) <= byte('F')) {
            return 10 + c - uint(byte('A'));
        }
    }

     
    function fromHex(string s) public pure returns(bytes) {
        bytes memory ss = bytes(s);
        require(ss.length % 2 == 0);  
        bytes memory r = new bytes(ss.length / 2);
        for (uint i = 0; i < ss.length / 2; ++i) {
            r[i] = byte(fromHexChar(uint(ss[2 * i])) * 16 +
                fromHexChar(uint(ss[2 * i + 1])));
        }
        return r;
    }
}

 
library SafeMath {

     
    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint a, uint b) internal pure returns(uint) {
         
        uint c = a / b;
         
        return c;
    }

     
    function sub(uint a, uint b) internal pure returns(uint) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}