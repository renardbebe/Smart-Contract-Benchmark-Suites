 

pragma solidity ^0.4.24;

 
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
        require(_to != address(0), "Recipient address is zero address(0). Check the address again.");
        require(_value <= balances[msg.sender], "The balance of account is insufficient.");

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
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        require(_to != address(0), "Recipient address is zero address(0). Check the address again.");
        require(_value <= balances[_from], "The balance of account is insufficient.");
        require(_value <= allowed[_from][msg.sender], "Insufficient tokens approved from account owner.");

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

     
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
library AddressUtils {

     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

 
contract MultiOwnable {
    using SafeMath for uint256;

    address public root;  
    address public superOwner;
    mapping (address => bool) public owners;
    address[] public ownerList;

     
    mapping(address => address) public candidateRootMap;


    event ChangedRoot(address newRoot);
    event ChangedSuperOwner(address newSuperOwner);
    event AddedNewOwner(address newOwner);
    event DeletedOwner(address deletedOwner);

    constructor() public {
        root = msg.sender;
        superOwner = msg.sender;
        owners[root] = true;

        ownerList.push(msg.sender);

    }

    modifier onlyRoot() {
        require(msg.sender == root, "Root privilege is required.");
        _;
    }

    modifier onlySuperOwner() {
        require(msg.sender == superOwner, "SuperOwner priviledge is required.");
        _;
    }

    modifier onlyOwner() {
        require(owners[msg.sender], "Owner priviledge is required.");
        _;
    }

     
    function changeRoot(address newRoot) onlyRoot public returns (bool) {
        require(newRoot != address(0), "This address to be set is zero address(0). Check the input address.");

        root = newRoot;

        emit ChangedRoot(newRoot);
        return true;
    }

     
    function changeSuperOwner(address newSuperOwner) onlyRoot public returns (bool) {
        require(newSuperOwner != address(0), "This address to be set is zero address(0). Check the input address.");

        superOwner = newSuperOwner;

        emit ChangedSuperOwner(newSuperOwner);
        return true;
    }

     
    function changeRootByDAO(address newRoot) onlyOwner public returns (bool) {
        require(newRoot != address(0), "This address to be set is zero address(0). Check the input address.");
        require(newRoot != candidateRootMap[msg.sender], "You have already voted for this account.");

        candidateRootMap[msg.sender] = newRoot;

        uint8 votingNumForRoot = 0;
        uint8 i = 0;

        for (i = 0; i < ownerList.length; i++) {
            if (candidateRootMap[ownerList[i]] == newRoot)
                votingNumForRoot++;
        }

        if (votingNumForRoot > ownerList.length / 2) {  
            root = newRoot;

             
            for (i = 0; i < ownerList.length; i++) {
                delete candidateRootMap[ownerList[i]];
            }

            emit ChangedRoot(newRoot);
        }

        return true;
    }

    function newOwner(address owner) onlySuperOwner public returns (bool) {
        require(owner != address(0), "This address to be set is zero address(0). Check the input address.");
        require(!owners[owner], "This address is already registered.");

        owners[owner] = true;
        ownerList.push(owner);

        emit AddedNewOwner(owner);
        return true;
    }

    function deleteOwner(address owner) onlySuperOwner public returns (bool) {
        require(owners[owner], "This input address is not a super owner.");
        delete owners[owner];

        for (uint256 i = 0; i < ownerList.length; i++) {
            if (ownerList[i] == owner) {
                ownerList[i] = ownerList[ownerList.length.sub(1)];
                ownerList.length = ownerList.length.sub(1);
                break;
            }
        }

        emit DeletedOwner(owner);
        return true;
    }
}

 
contract LockableToken is StandardToken, MultiOwnable {
    bool public locked = true;
    uint256 public constant LOCK_MAX = uint256(-1);

     
    mapping(address => bool) public unlockAddrs;

     
    mapping(address => uint256) public lockValues;

    event Locked(bool locked, string note);
    event LockedTo(address indexed addr, bool locked, string note);
    event SetLockValue(address indexed addr, uint256 value, string note);

    constructor() public {
        unlockTo(msg.sender,  "");
    }

    modifier checkUnlock (address addr, uint256 value) {
        require(!locked || unlockAddrs[addr], "The account is currently locked.");
        require(balances[addr].sub(value) >= lockValues[addr], "Transferable limit exceeded. Check the status of the lock value.");
        _;
    }

    function lock(string note) onlyOwner public {
        locked = true;
        emit Locked(locked, note);
    }

    function unlock(string note) onlyOwner public {
        locked = false;
        emit Locked(locked, note);
    }

    function lockTo(address addr, string note) onlyOwner public {
        setLockValue(addr, LOCK_MAX, note);
        unlockAddrs[addr] = false;

        emit LockedTo(addr, true, note);
    }

    function unlockTo(address addr, string note) onlyOwner public {
        if (lockValues[addr] == LOCK_MAX)
            setLockValue(addr, 0, note);
        unlockAddrs[addr] = true;

        emit LockedTo(addr, false, note);
    }

    function setLockValue(address addr, uint256 value, string note) onlyOwner public {
        lockValues[addr] = value;
        emit SetLockValue(addr, value, note);
    }

     
    function getMyUnlockValue() public view returns (uint256) {
        address addr = msg.sender;
        if ((!locked || unlockAddrs[addr]) && balances[addr] > lockValues[addr])
            return balances[addr].sub(lockValues[addr]);
        else
            return 0;
    }

    function transfer(address to, uint256 value) checkUnlock(msg.sender, value) public returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) checkUnlock(from, value) public returns (bool) {
        return super.transferFrom(from, to, value);
    }
}

 
contract DelayLockableToken is LockableToken {
    mapping(address => uint256) public delayLockValues;
    mapping(address => uint256) public delayLockBeforeValues;
    mapping(address => uint256) public delayLockTimes;

    event SetDelayLockValue(address indexed addr, uint256 value, uint256 time);

    modifier checkDelayUnlock (address addr, uint256 value) {
        if (delayLockTimes[msg.sender] <= now) {
            require (balances[addr].sub(value) >= delayLockValues[addr], "Transferable limit exceeded. Change the balance lock value first and then use it");
        } else {
            require (balances[addr].sub(value) >= delayLockBeforeValues[addr], "Transferable limit exceeded. Please note that the residual lock value has changed and it will take 12 hours to apply.");
        }
        _;
    }

     
    function delayLock(uint256 value) public returns (bool) {
        require (value <= balances[msg.sender], "Your balance is insufficient.");

        if (value >= delayLockValues[msg.sender])
            delayLockTimes[msg.sender] = now;
        else {
            require (delayLockTimes[msg.sender] <= now, "The remaining money in the account cannot be unlocked continuously. You cannot renew until 12 hours after the first run.");
            delayLockTimes[msg.sender] = now + 12 hours;
            delayLockBeforeValues[msg.sender] = delayLockValues[msg.sender];
        }

        delayLockValues[msg.sender] = value;

        emit SetDelayLockValue(msg.sender, value, delayLockTimes[msg.sender]);
        return true;
    }

     
    function delayUnlock() public returns (bool) {
        return delayLock(0);
    }

     
    function getMyUnlockValue() public view returns (uint256) {
        uint256 myUnlockValue;
        address addr = msg.sender;
        if (delayLockTimes[addr] <= now) {
            myUnlockValue = balances[addr].sub(delayLockValues[addr]);
        } else {
            myUnlockValue = balances[addr].sub(delayLockBeforeValues[addr]);
        }
        
        uint256 superUnlockValue = super.getMyUnlockValue();

        if (myUnlockValue > superUnlockValue)
            return superUnlockValue;
        else
            return myUnlockValue;
    }    

    function transfer(address to, uint256 value) checkDelayUnlock(msg.sender, value) public returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) checkDelayUnlock(from, value) public returns (bool) {
        return super.transferFrom(from, to, value);
    }
}

 
contract LBKBaseToken is DelayLockableToken {
    event LBKTransfer(address indexed from, address indexed to, uint256 value, string note);
    event LBKTransferFrom(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event LBKApproval(address indexed owner, address indexed spender, uint256 value, string note);

    event LBKMintTo(address indexed controller, address indexed to, uint256 amount, string note);
    event LBKBurnFrom(address indexed controller, address indexed from, uint256 value, string note);

    event LBKBurnWhenMoveToMainnet(address indexed controller, address indexed from, uint256 value, string note);

    event LBKSell(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event LBKSellByOtherCoin(address indexed owner, address indexed spender, address indexed to, uint256 value,  uint256 processIdHash, uint256 userIdHash, string note);

    event LBKTransferToTeam(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event LBKTransferToPartner(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);

    event LBKTransferToEcosystem(address indexed owner, address indexed spender, address indexed to, uint256 value, uint256 processIdHash, uint256 userIdHash, string note);
    event LBKTransferToBounty(address indexed owner, address indexed spender, address indexed to, uint256 value, uint256 processIdHash, uint256 userIdHash, string note);

     
    function transfer(address to, uint256 value) public returns (bool ret) {
        return lbkTransfer(to, value, "");
    }

    function lbkTransfer(address to, uint256 value, string note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of LEGALBLOCK. You cannot send money to this address.");

        ret = super.transfer(to, value);
        emit LBKTransfer(msg.sender, to, value, note);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        return lbkTransferFrom(from, to, value, "");
    }

    function lbkTransferFrom(address from, address to, uint256 value, string note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of LEGALBLOCK. You cannot send money to this address.");

        ret = super.transferFrom(from, to, value);
        emit LBKTransferFrom(from, msg.sender, to, value, note);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        return lbkApprove(spender, value, "");
    }

    function lbkApprove(address spender, uint256 value, string note) public returns (bool ret) {
        ret = super.approve(spender, value);
        emit LBKApproval(msg.sender, spender, value, note);
    }

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        return lbkIncreaseApproval(spender, addedValue, "");
    }

    function lbkIncreaseApproval(address spender, uint256 addedValue, string note) public returns (bool ret) {
        ret = super.increaseApproval(spender, addedValue);
        emit LBKApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        return lbkDecreaseApproval(spender, subtractedValue, "");
    }

    function lbkDecreaseApproval(address spender, uint256 subtractedValue, string note) public returns (bool ret) {
        ret = super.decreaseApproval(spender, subtractedValue);
        emit LBKApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

     
    function mintTo(address to, uint256 amount) internal returns (bool) {
        require(to != address(0x0), "This address to be set is zero address(0). Check the input address.");

        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);

        emit Transfer(address(0), to, amount);
        return true;
    }

    function lbkMintTo(address to, uint256 amount, string note) onlySuperOwner public returns (bool ret) {
        ret = mintTo(to, amount);
        emit LBKMintTo(msg.sender, to, amount, note);
    }

     
    function burnFrom(address from, uint256 value) internal returns (bool) {
        require(value <= balances[from], "Your balance is insufficient.");

        balances[from] = balances[from].sub(value);
        totalSupply_ = totalSupply_.sub(value);

        emit Transfer(from, address(0), value);
        return true;
    }

    function lbkBurnFrom(address from, uint256 value, string note) onlyOwner public returns (bool ret) {
        ret = burnFrom(from, value);
        emit LBKBurnFrom(msg.sender, from, value, note);
    }

     
    function lbkBurnWhenMoveToMainnet(address burner, uint256 value, string note) onlyOwner public returns (bool ret) {
        ret = burnFrom(burner, value);
        emit LBKBurnWhenMoveToMainnet(msg.sender, burner, value, note);
    }

    function lbkBatchBurnWhenMoveToMainnet(address[] burners, uint256[] values, string note) onlyOwner public returns (bool ret) {
        uint256 length = burners.length;
        require(length == values.length, "The size of \'burners\' and \'values\' array is different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            ret = ret && lbkBurnWhenMoveToMainnet(burners[i], values[i], note);
        }
    }

     
    function lbkSell(
        address from,
        address to,
        uint256 value,
        string note
    ) onlyOwner public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of LEGALBLOCK. You cannot send money to this address.");

        ret = super.transferFrom(from, to, value);
        emit LBKSell(from, msg.sender, to, value, note);
    }

     
    function lbkBatchSellByOtherCoin(
        address from,
        address[] to,
        uint256[] values,
        uint256 processIdHash,
        uint256[] userIdHash,
        string note
    ) onlyOwner public returns (bool ret) {
        uint256 length = to.length;
        require(length == values.length, "The size of \'to\' and \'values\' array is different.");
        require(length == userIdHash.length, "The size of \'to\' and \'userIdHash\' array is different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this), "The receive address is the Contact Address of LEGALBLOCK. You cannot send money to this address.");

            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit LBKSellByOtherCoin(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }

     
    function lbkTransferToTeam(
        address from,
        address to,
        uint256 value,
        string note
    ) onlyOwner public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of LEGALBLOCK. You cannot send money to this address.");

        ret = super.transferFrom(from, to, value);
        emit LBKTransferToTeam(from, msg.sender, to, value, note);
    }

     
    function lbkTransferToPartner(
        address from,
        address to,
        uint256 value,
        string note
    ) onlyOwner public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of LEGALBLOCK. You cannot send money to this address.");

        ret = super.transferFrom(from, to, value);
        emit LBKTransferToPartner(from, msg.sender, to, value, note);
    }

     
    function lbkBatchTransferToEcosystem(
        address from, address[] to,
        uint256[] values,
        uint256 processIdHash,
        uint256[] userIdHash,
        string note
    ) onlyOwner public returns (bool ret) {
        uint256 length = to.length;
        require(length == values.length, "The size of \'to\' and \'values\' array is different.");
        require(length == userIdHash.length, "The size of \'to\' and \'userIdHash\' array is different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this), "The receive address is the Contact Address of LEGALBLOCK. You cannot send money to this address.");

            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit LBKTransferToEcosystem(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }

     
    function lbkBatchTransferToBounty(
        address from,
        address[] to,
        uint256[] values,
        uint256 processIdHash,
        uint256[] userIdHash,
        string note
    ) onlyOwner public returns (bool ret) {
        uint256 length = to.length;
        require(to.length == values.length, "The size of \'to\' and \'values\' array is different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this), "The receive address is the Contact Address of LEGALBLOCK. You cannot send money to this address.");

            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit LBKTransferToBounty(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }

    function destroy() onlyRoot public {
        selfdestruct(root);
    }
}

 
contract LEGALBLOCK is LBKBaseToken {
    using AddressUtils for address;

    event TransferedToLBKDapp(
        address indexed owner,
        address indexed spender,
        address indexed to, uint256 value, LBKReceiver.LBKReceiveType receiveType);

    string public constant name = "LEGALBLOCK";
    string public constant symbol = "LBK";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 15e9 * (10 ** uint256(decimals));

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function lbkTransfer(address to, uint256 value, string note) public returns (bool ret) {
        ret = super.lbkTransfer(to, value, note);
        postTransfer(msg.sender, msg.sender, to, value, LBKReceiver.LBKReceiveType.LBK_TRANSFER);
    }

    function lbkTransferFrom(address from, address to, uint256 value, string note) public returns (bool ret) {
        ret = super.lbkTransferFrom(from, to, value, note);
        postTransfer(from, msg.sender, to, value, LBKReceiver.LBKReceiveType.LBK_TRANSFER);
    }

    function postTransfer(address owner, address spender, address to, uint256 value, LBKReceiver.LBKReceiveType receiveType) internal returns (bool) {
        if (to.isContract()) {
            bool callOk = address(to).call(bytes4(keccak256("onLBKReceived(address,address,uint256,uint8)")), owner, spender, value, receiveType);
            if (callOk) {
                emit TransferedToLBKDapp(owner, spender, to, value, receiveType);
            }
        }

        return true;
    }

    function lbkMintTo(address to, uint256 amount, string note) onlySuperOwner public returns (bool ret) {
        ret = super.lbkMintTo(to, amount, note);
        postTransfer(0x0, msg.sender, to, amount, LBKReceiver.LBKReceiveType.LBK_MINT);
    }

    function lbkBurnFrom(address from, uint256 value, string note) onlyOwner public returns (bool ret) {
        ret = super.lbkBurnFrom(from, value, note);
        postTransfer(0x0, msg.sender, from, value, LBKReceiver.LBKReceiveType.LBK_BURN);
    }
}


 
contract LBKReceiver {
    enum LBKReceiveType { LBK_TRANSFER, LBK_MINT, LBK_BURN }
    function onLBKReceived(address owner, address spender, uint256 value, LBKReceiveType receiveType) public returns (bool);
}

 
contract LBKDappSample is LBKReceiver {
    event LogOnReceiveLBK(string message, address indexed owner, address indexed spender, uint256 value, LBKReceiveType receiveType);

    function onLBKReceived(address owner, address spender, uint256 value, LBKReceiveType receiveType) public returns (bool) {
        emit LogOnReceiveLBK("I receive LEGALBLOCK.", owner, spender, value, receiveType);
        return true;
    }
}