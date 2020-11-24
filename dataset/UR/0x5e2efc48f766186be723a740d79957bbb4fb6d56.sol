 

pragma solidity ^0.4.25;

 
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address previousOwner, address newOwner);

     
    constructor(address _owner) public {
        owner = _owner == address(0) ? msg.sender : _owner;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function confirmOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 
contract IERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value)  public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success);
    function approve(address _spender, uint256 _value)  public returns (bool success);
    function allowance(address _owner, address _spender)  public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract SafeMath {
     
    constructor() public {
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20Token is IERC20Token, SafeMath {
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);

        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }
}

 
interface ITokenEventListener {
     
    function onTokenTransfer(address _from, address _to, uint256 _value) external;
}

 
contract ManagedToken is ERC20Token, Ownable {
    uint256 public totalIssue;                                                   
    bool public allowTransfers = true;                                           

    ITokenEventListener public eventListener;                                    

    event AllowTransfersChanged(bool _newState);                                 
    event Issue(address indexed _to, uint256 _value);                            
    event Destroy(address indexed _from, uint256 _value);                        
    event IssuanceFinished(bool _issuanceFinished);                              

     
    modifier transfersAllowed() {
        require(allowTransfers, "Require enable transfer");
        _;
    }

     
    constructor(address _listener, address _owner) public Ownable(_owner) {
        if(_listener != address(0)) {
            eventListener = ITokenEventListener(_listener);
        }
    }

     
    function setAllowTransfers(bool _allowTransfers) external onlyOwner {
        allowTransfers = _allowTransfers;

         
        emit AllowTransfersChanged(_allowTransfers);
    }

     
    function setListener(address _listener) public onlyOwner {
        if(_listener != address(0)) {
            eventListener = ITokenEventListener(_listener);
        } else {
            delete eventListener;
        }
    }

    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool) {
        bool success = super.transfer(_to, _value);
         
        return success;
    }

    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool) {
        bool success = super.transferFrom(_from, _to, _value);

         
         
        return success;
    }

    function hasListener() internal view returns(bool) {
        if(eventListener == address(0)) {
            return false;
        }
        return true;
    }

     
    function issue(address _to, uint256 _value) external onlyOwner {
        totalIssue = safeAdd(totalIssue, _value);
        require(totalSupply >= totalIssue, "Total issue is not greater total of supply");
        balances[_to] = safeAdd(balances[_to], _value);
         
        emit Issue(_to, _value);
        emit Transfer(address(0), _to, _value);
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
contract LEX is ManagedToken {

     
    struct OwnerLock {
        string name;                                                             
        uint256 lockEndTime;                                                     
        uint256 amount;                                                          
        bool isLock;                                                             
    }

     
    struct ClientLock {
        uint256 lockEndTime;                                                     
        uint256 amount;                                                          
        bool isLock;                                                             
    }

    uint256 public TotalLocked = 0;                                              

     
    mapping (address => uint256) public freezeOf;
     
    mapping(uint256 => OwnerLock) public ownerLocks;
     
    mapping(address => ClientLock) public clientLocks;
     
    uint256[] public LockIds;

     
    event LockOwner(string name, uint256 lockEndTime, uint256 amount, uint256 id);

     
    event UnLockOwner(string name, uint256 lockEndTime, uint256 amount, uint256 id);

     
    event Burn(address indexed from, uint256 value);

     
    event Freeze(address indexed from, uint256 value);

    event UnLockClient(address _addressLock, uint256 lockEndTime, uint256 amount);
    event LockClient(address _addressLock, uint256 lockEndTime, uint256 amount);

     
    constructor() public ManagedToken(msg.sender, msg.sender) {
        name = "Liquiditex";
        symbol = "LEX";
        decimals = 18;
        totalIssue = 0;
         
        totalSupply = 100000000 ether;
    }

    function issue(address _to, uint256 _value) external onlyOwner {
        totalIssue = safeAdd(totalIssue, _value);
        require(totalSupply >= totalIssue, "Total issue is not greater total of supply");

        balances[_to] = safeAdd(balances[_to], _value);
         
        emit Issue(_to, _value);
        emit Transfer(address(0), _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if(clientLocks[msg.sender].isLock){
            require(_value <= safeSub(balances[msg.sender], clientLocks[msg.sender].amount), "Not enough token to transfer");
        }
        bool success = super.transfer(_to, _value);
        return success;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(clientLocks[_from].isLock){
            require(_value <= safeSub(balances[_from], clientLocks[_from].amount), "Not enough token to transfer");
        }
        bool success = super.transferFrom(_from, _to, _value);
        return success;
    }

     
    function burn(uint256 _value) external onlyOwner returns (bool success) {
        require(balances[msg.sender] >= _value, "Not enough token to burn");                 
		require(_value > 0, "Require burn token greater than 0");
        balances[msg.sender] = safeSub(balances[msg.sender], _value);                        
        totalSupply = safeSub(totalSupply,_value);                                           
        totalIssue = safeSub(totalIssue,_value);                                             
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function freeze(uint256 _value) external returns (bool success) {
        require(balances[msg.sender] >= _value, "Not enough token to freeze");              
		require(_value > 0, "Require burn token greater than 0");
        balances[msg.sender] = safeSub(balances[msg.sender], _value);                       
        freezeOf[msg.sender] = safeAdd(freezeOf[msg.sender], _value);                       
        emit Freeze(msg.sender, _value);
        return true;
    }

     
    function setLockInOwner(uint256 _lockTotal, uint256 _totalDayLock, string name, uint256 id) external onlyOwner {
        require(_totalDayLock >= 1, "Lock for at least one day");
        require(balances[msg.sender] >= _lockTotal, "Total lock is not greater total of owner");
        require(ownerLocks[id].amount == 0, "Lock with id is not existed");

         
        ownerLocks[id].amount = _lockTotal;
        ownerLocks[id].lockEndTime = _totalDayLock * 86400 + now;
        ownerLocks[id].name = name;
        ownerLocks[id].isLock = true;

         
        TotalLocked = safeAdd(TotalLocked, _lockTotal);
        balances[msg.sender] = safeSub(balances[msg.sender], _lockTotal);

         
        LockIds.push(id);

         
        emit LockOwner(name, ownerLocks[id].lockEndTime, _lockTotal, id);
    }

     
    function unLockInOwner(uint256 id) external onlyOwner {
         
        require(ownerLocks[id].isLock == true, "Lock with id is locking");
        require(now > ownerLocks[id].lockEndTime, "Please wait to until the end of lock previous");
         
        ownerLocks[id].isLock = false;

         
        TotalLocked = safeSub(TotalLocked, ownerLocks[id].amount);
        balances[msg.sender] = safeAdd(balances[msg.sender], ownerLocks[id].amount);

         
        emit UnLockOwner(name, ownerLocks[id].lockEndTime, ownerLocks[id].amount, id);
    }

     
    function transferLockFromOwner(address _to, uint256 _value, uint256 _totalDayLock) external onlyOwner returns (bool) {
        require(_totalDayLock >= 1, "Lock for at least one day");
        require(clientLocks[_to].isLock == false, "Account client has not lock token");
        bool success = super.transfer(_to, _value);
        if(success){
            clientLocks[_to].isLock = true;
            clientLocks[_to].amount = _value;
            clientLocks[_to].lockEndTime = _totalDayLock * 86400 + now;

             
            emit LockClient(_to, clientLocks[_to].lockEndTime, clientLocks[_to].amount);
        }

        return success;
    }

     
    function unLockTransferClient(address _addressLock) external {
        require(clientLocks[_addressLock].isLock == true, "Account client has lock token");
        require(now > clientLocks[_addressLock].lockEndTime, "Please wait to until the end of lock previous");

         
        clientLocks[_addressLock].isLock = false;

         
        emit UnLockClient(_addressLock, clientLocks[_addressLock].lockEndTime, clientLocks[_addressLock].amount);
    }

}