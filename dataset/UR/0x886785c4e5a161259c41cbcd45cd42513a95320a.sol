 

pragma solidity 0.4.23;

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function proposeOwnership(address _newOwnerCandidate) external onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        emit OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
    function acceptOwnership() external {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        emit OwnershipTransferred(oldOwner, owner);
    }

     
    function changeOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        emit OwnershipTransferred(oldOwner, owner);
    }

     
    function removeOwnership(address _dac) external onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        emit OwnershipRemoved();
    }
}

 
contract ERC777Helper is ERC777Token, ERC20Token, ERC820Implementer {
    using SafeMath for uint256;

    bool internal mErc20compatible;
    uint256 internal mGranularity;
    mapping(address => uint) internal mBalances;

     
    function requireMultiple(uint256 _amount) internal view {
        require(_amount.div(mGranularity).mul(mGranularity) == _amount);
    }

     
    function isRegularAddress(address _addr) internal view returns(bool) {
        if (_addr == 0) { return false; }
        uint size;
        assembly { size := extcodesize(_addr) }  
        return size == 0;
    }

     
    function doSend(
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        address _operator,
        bytes _operatorData,
        bool _preventLocking
    )
    internal
    {
        requireMultiple(_amount);

        callSender(_operator, _from, _to, _amount, _userData, _operatorData);

        require(_to != address(0));           
        require(mBalances[_from] >= _amount);  

        mBalances[_from] = mBalances[_from].sub(_amount);
        mBalances[_to] = mBalances[_to].add(_amount);

        callRecipient(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);

        emit Sent(_operator, _from, _to, _amount, _userData, _operatorData);
        if (mErc20compatible) { emit Transfer(_from, _to, _amount); }
    }

     
    function callRecipient(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    ) internal {
        address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
        if (recipientImplementation != 0) {
            ERC777TokensRecipient(recipientImplementation).tokensReceived(
                _operator, _from, _to, _amount, _userData, _operatorData);
        } else if (_preventLocking) {
            require(isRegularAddress(_to));
        }
    }

     
    function callSender(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData
    ) internal {
        address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
        if (senderImplementation != 0) {
            ERC777TokensSender(senderImplementation).tokensToSend(
                _operator, _from, _to, _amount, _userData, _operatorData);
        }
    }
}

 
contract ERC20TokenCompat is ERC777Helper, Owned {

    mapping(address => mapping(address => uint256)) private mAllowed;

     
    constructor() public {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
    }

     
    modifier erc20 () {
        require(mErc20compatible);
        _;
    }

     
    function disableERC20() public onlyOwner {
        mErc20compatible = false;
        setInterfaceImplementation("ERC20Token", 0x0);
    }

     
    function enableERC20() public onlyOwner {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
    }

     
    function decimals() public erc20 view returns (uint8) {return uint8(18);}

     
    function transfer(address _to, uint256 _amount) public erc20 returns (bool success) {
        doSend(msg.sender, _to, _amount, "", msg.sender, "", false);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) public erc20 returns (bool success) {
        require(_amount <= mAllowed[_from][msg.sender]);

         
        mAllowed[_from][msg.sender] = mAllowed[_from][msg.sender].sub(_amount);
        doSend(_from, _to, _amount, "", msg.sender, "", false);
        return true;
    }

     
    function approve(address _spender, uint256 _amount) public erc20 returns (bool success) {
        mAllowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender) public erc20 view returns (uint256 remaining) {
        return mAllowed[_owner][_spender];
    }
}

 
contract ERC777StandardToken is ERC777Helper, Owned {
    string private mName;
    string private mSymbol;
    uint256 private mTotalSupply;

    mapping(address => mapping(address => bool)) private mAuthorized;

     
    constructor(
        string _name,
        string _symbol,
        uint256 _totalSupply,
        uint256 _granularity
    )
    public {
        require(_granularity >= 1);
        require(_totalSupply > 0);

        mName = _name;
        mSymbol = _symbol;
        mTotalSupply = _totalSupply;
        mGranularity = _granularity;
        mBalances[msg.sender] = mTotalSupply;

        setInterfaceImplementation("ERC777Token", this);
    }

     
    function name() public view returns (string) {return mName;}

     
    function symbol() public view returns (string) {return mSymbol;}

     
    function granularity() public view returns (uint256) {return mGranularity;}

     
    function totalSupply() public view returns (uint256) {return mTotalSupply;}

     
    function balanceOf(address _tokenHolder) public view returns (uint256) {return mBalances[_tokenHolder];}

     
    function send(address _to, uint256 _amount) public {
        doSend(msg.sender, _to, _amount, "", msg.sender, "", true);
    }

     
    function send(address _to, uint256 _amount, bytes _userData) public {
        doSend(msg.sender, _to, _amount, _userData, msg.sender, "", true);
    }

     
    function authorizeOperator(address _operator) public {
        require(_operator != msg.sender);
        mAuthorized[_operator][msg.sender] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

     
    function revokeOperator(address _operator) public {
        require(_operator != msg.sender);
        mAuthorized[_operator][msg.sender] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

     
    function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
        return _operator == _tokenHolder || mAuthorized[_operator][_tokenHolder];
    }

     
    function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _from));
        doSend(_from, _to, _amount, _userData, msg.sender, _operatorData, true);
    }
}

 
contract ERC20Multi is ERC20TokenCompat {

     
    function multiPartyTransfer(address[] _toAddresses, uint256[] _amounts) external erc20 {
         
        require(_toAddresses.length <= 255);
         
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transfer(_toAddresses[i], _amounts[i]);
        }
    }

     
    function multiPartyTransferFrom(address _from, address[] _toAddresses, uint256[] _amounts) external erc20 {
         
        require(_toAddresses.length <= 255);
         
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transferFrom(_from, _toAddresses[i], _amounts[i]);
        }
    }
}

 
contract ERC777Multi is ERC777Helper {

     
    function multiOperatorSend(address _from, address[] _to, uint256[] _amounts, bytes _userData, bytes _operatorData)
    external {
         
        require(_to.length <= 255);
         
        require(_to.length == _amounts.length);

        for (uint8 i = 0; i < _to.length; i++) {
            operatorSend(_from, _to[i], _amounts[i], _userData, _operatorData);
        }
    }

     
    function multiPartySend(address[] _toAddresses, uint256[] _amounts, bytes _userData) public {
         
        require(_toAddresses.length <= 255);
         
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            doSend(msg.sender, _toAddresses[i], _amounts[i], _userData, msg.sender, "", true);
        }
    }

     
    function multiPartySend(address[] _toAddresses, uint256[] _amounts) public {
         
        require(_toAddresses.length <= 255);
         
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            doSend(msg.sender, _toAddresses[i], _amounts[i], "", msg.sender, "", true);
        }
    }
}

 
contract SafeGuard is Owned {

    event Transaction(address indexed destination, uint value, bytes data);

     
    function executeTransaction(address destination, uint value, bytes data)
    public
    onlyOwner
    {
        require(externalCall(destination, value, data.length, data));
        emit Transaction(destination, value, data);
    }

     
    function externalCall(address destination, uint value, uint dataLength, bytes data)
    private
    returns (bool) {
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
}

 
contract ERC664Balances is SafeGuard {
    using SafeMath for uint256;

    uint256 public totalSupply;

    event BalanceAdj(address indexed module, address indexed account, uint amount, string polarity);
    event ModuleSet(address indexed module, bool indexed set);

    mapping(address => bool) public modules;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    modifier onlyModule() {
        require(modules[msg.sender]);
        _;
    }

     
    constructor(uint256 _initialAmount) public {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
    }

     
    function setApprove(address _sender, address _spender, uint256 _value) external onlyModule returns (bool) {
        allowed[_sender][_spender] = _value;
        return true;
    }

     
    function decApprove(address _from, address _spender, uint _value) external onlyModule returns (bool) {
        allowed[_from][_spender] = allowed[_from][_spender].sub(_value);
        return true;
    }

     
    function incTotalSupply(uint _val) external onlyOwner returns (bool) {
        totalSupply = totalSupply.add(_val);
        return true;
    }

     
    function decTotalSupply(uint _val) external onlyOwner returns (bool) {
        totalSupply = totalSupply.sub(_val);
        return true;
    }

     
    function setModule(address _acct, bool _set) external onlyOwner returns (bool) {
        modules[_acct] = _set;
        emit ModuleSet(_acct, _set);
        return true;
    }

     
    function getBalance(address _acct) external view returns (uint256) {
        return balances[_acct];
    }

     
    function getAllowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function getModule(address _acct) external view returns (bool) {
        return modules[_acct];
    }

     
    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

     
    function incBalance(address _acct, uint _val) public onlyModule returns (bool) {
        balances[_acct] = balances[_acct].add(_val);
        emit BalanceAdj(msg.sender, _acct, _val, "+");
        return true;
    }

     
    function decBalance(address _acct, uint _val) public onlyModule returns (bool) {
        balances[_acct] = balances[_acct].sub(_val);
        emit BalanceAdj(msg.sender, _acct, _val, "-");
        return true;
    }
}

 
contract CStore is ERC664Balances, ERC820Implementer {

    mapping(address => mapping(address => bool)) private mAuthorized;

     
    constructor(uint256 _totalSupply, address _registry) public
    ERC664Balances(_totalSupply)
    ERC820Implementer(_registry) {
        setInterfaceImplementation("ERC664Balances", this);
    }

     
     
    function incTotalSupply(uint _val) external onlyOwner returns (bool) {
        return false;
    }

     
     
    function decTotalSupply(uint _val) external onlyOwner returns (bool) {
        return false;
    }

     
    function move(address _from, address _to, uint256 _amount) external
    onlyModule
    returns (bool) {
        balances[_from] = balances[_from].sub(_amount);
        emit BalanceAdj(msg.sender, _from, _amount, "-");
        balances[_to] = balances[_to].add(_amount);
        emit BalanceAdj(msg.sender, _to, _amount, "+");
        return true;
    }

     
    function setOperator(address _operator, address _tokenHolder, bool _status) external
    onlyModule
    returns (bool) {
        mAuthorized[_operator][_tokenHolder] = _status;
        return true;
    }

     
    function getOperator(address _operator, address _tokenHolder) external
    view
    returns (bool) {
        return mAuthorized[_operator][_tokenHolder];
    }

     
     
    function incBalance(address _acct, uint _val) public onlyModule returns (bool) {
        return false;
    }

     
     
    function decBalance(address _acct, uint _val) public onlyModule returns (bool) {
        return false;
    }
}

 
contract CALL is ERC820Implementer, ERC777StandardToken, ERC20TokenCompat, ERC20Multi, ERC777Multi, SafeGuard {
    using SafeMath for uint256;

    CStore public balancesDB;

     
    constructor(address _intRegistry, string _name, string _symbol, uint256 _totalSupply,
        uint256 _granularity, address _balancesDB) public
    ERC820Implementer(_intRegistry)
    ERC777StandardToken(_name, _symbol, _totalSupply, _granularity) {
        balancesDB = CStore(_balancesDB);
        setInterfaceImplementation("ERC777CALLToken", this);
    }

     
    function changeBalancesDB(address _newDB) public onlyOwner {
        balancesDB = CStore(_newDB);
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) public erc20 returns (bool success) {
        uint256 allowance = balancesDB.getAllowance(_from, msg.sender);
        require(_amount <= allowance);

         
        require(balancesDB.decApprove(_from, msg.sender, _amount));
        doSend(_from, _to, _amount, "", msg.sender, "", false);
        return true;
    }

     
    function approve(address _spender, uint256 _amount) public erc20 returns (bool success) {
        require(balancesDB.setApprove(msg.sender, _spender, _amount));
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender) public erc20 view returns (uint256 remaining) {
        return balancesDB.getAllowance(_owner, _spender);
    }

     
    function totalSupply() public view returns (uint256) {
        return balancesDB.getTotalSupply();
    }

     
    function balanceOf(address _tokenHolder) public view returns (uint256) {
        return balancesDB.getBalance(_tokenHolder);
    }

     
    function authorizeOperator(address _operator) public {
        require(_operator != msg.sender);
        require(balancesDB.setOperator(_operator, msg.sender, true));
        emit AuthorizedOperator(_operator, msg.sender);
    }

     
    function revokeOperator(address _operator) public {
        require(_operator != msg.sender);
        require(balancesDB.setOperator(_operator, msg.sender, false));
        emit RevokedOperator(_operator, msg.sender);
    }

     
    function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
        return _operator == _tokenHolder || balancesDB.getOperator(_operator, _tokenHolder);
    }

     
    function doSend(
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        address _operator,
        bytes _operatorData,
        bool _preventLocking
    )
    internal
    {
        requireMultiple(_amount);

        callSender(_operator, _from, _to, _amount, _userData, _operatorData);

        require(_to != address(0));           
         
         

        require(balancesDB.move(_from, _to, _amount));

        callRecipient(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);

        emit Sent(_operator, _from, _to, _amount, _userData, _operatorData);
        if (mErc20compatible) { emit Transfer(_from, _to, _amount); }
    }
}