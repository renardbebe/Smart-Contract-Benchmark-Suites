 

 

pragma solidity ^0.4.19;

contract owned {

    address public owner;
    address public candidate;

    function owned() payable public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        candidate = _owner;
    }
    
    function confirmOwner() public {
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }
}

 
contract ERC20Base {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
}

contract CryptaurRewards {
    function payment(address _buyer, address _seller, uint _amount, address _opinionLeader) public returns(uint fee);
}

contract CryputarReserveFund {
    function depositNotification(uint _amount) public;
    function withdrawNotification(uint _amount) public;
}

 
contract AddressBook {

    struct AddressRelations {
        SlaveDictionary slaves;
        bool hasValue;
    }

    struct SlaveDictionary
    {
        address[] values;
        mapping(address => uint) keys;
    }

    event WalletLinked(address indexed _master, address indexed _slave);
    event WalletUnlinked(address indexed _master, address indexed _slave);
    event AddressChanged(address indexed _old, address indexed _new);

    mapping(address => AddressRelations) private masterToSlaves;
    mapping(address => address) private slaveToMasterAddress;
    uint8 public maxLinkedWalletCount = 5;

     
    function linkToMasterWalletInternal(address _masterWallet, address _linkedWallet) internal {
        require(_masterWallet != _linkedWallet && _linkedWallet != address(0));
        require(isMasterWallet(_masterWallet));
        require(!isLinkedWallet(_linkedWallet) && !isMasterWallet(_linkedWallet));
        AddressRelations storage rel = masterToSlaves[_masterWallet];
        require(rel.slaves.values.length < maxLinkedWalletCount);    
        rel.slaves.values.push(_linkedWallet);
        rel.slaves.keys[_linkedWallet] = rel.slaves.values.length - 1;
        slaveToMasterAddress[_linkedWallet] = _masterWallet;
        WalletLinked(_masterWallet, _linkedWallet);
    }
 
    function unLinkFromMasterWalletInternal(address _masterWallet, address _linkedWallet) internal {
        require(_masterWallet != _linkedWallet && _linkedWallet != address(0));
        require(_masterWallet == getMasterWallet(_linkedWallet));
        SlaveDictionary storage slaves = masterToSlaves[_masterWallet].slaves;
        uint indexToDelete = slaves.keys[_linkedWallet];
        address keyToMove = slaves.values[slaves.values.length - 1];
        slaves.values[indexToDelete] = keyToMove;
        slaves.keys[keyToMove] = indexToDelete;
        slaves.values.length--;
        delete slaves.keys[_linkedWallet];
        delete slaveToMasterAddress[_linkedWallet];
        WalletUnlinked(_masterWallet, _linkedWallet);
    }

    function getLinkedWallets(address _wallet) public view returns (address[]) {
        return masterToSlaves[_wallet].slaves.values;
    }

    function isMasterWallet(address _addr) internal constant returns (bool) {
        return masterToSlaves[_addr].hasValue;
    }

    function isLinkedWallet(address _addr) internal constant returns (bool) {
        return slaveToMasterAddress[_addr] != address(0);
    }

      
    function applyChangeWalletAddress(address _old, address _new) internal {
        require(isMasterWallet(_old) || isLinkedWallet(_old));
        require(_new != address(0));
        if (isMasterWallet(_old)) {
             
            require(!isLinkedWallet(_new));
            require(masterToSlaves[_new].slaves.values.length == 0);
            changeMasterAddress(_old, _new);
        }
        else {
             
            require(!isMasterWallet(_new) && !isLinkedWallet(_new));
            changeLinkedAddress(_old, _new);
        }
    }

    function changeLinkedAddress(address _old, address _new) private {
        slaveToMasterAddress[_new] = slaveToMasterAddress[_old];     
        SlaveDictionary storage slaves = masterToSlaves[slaveToMasterAddress[_new]].slaves;
        uint index = slaves.keys[_old];
        slaves.values[index] = _new;
        delete slaveToMasterAddress[_old];
    }
    
    function changeMasterAddress(address _old, address _new) private {    
        masterToSlaves[_new] = masterToSlaves[_old];  
        SlaveDictionary storage slaves = masterToSlaves[_new].slaves;
        for (uint8 i = 0; i < slaves.values.length; ++i)
            slaveToMasterAddress[slaves.values[i]] = _new;
        delete masterToSlaves[_old];
    }

    function addMasterWallet(address _master) internal {
        require(_master != address(0));
        masterToSlaves[_master].hasValue = true;
    }

    function getMasterWallet(address _wallet) internal constant returns(address) {
        if(isMasterWallet(_wallet))
            return _wallet;
        return slaveToMasterAddress[_wallet];  
    }

     
    function getOrAddMasterWallet(address _wallet) internal returns (address) {
        address masterWallet = getMasterWallet(_wallet);
        if (masterWallet == address(0))
            addMasterWallet(_wallet);
        return _wallet;
    }
}

contract CryptaurDepository is owned, AddressBook {
    enum UnlimitedMode {UNLIMITED,LIMITED}

    event Deposit(address indexed _who, uint _amount, bytes32 _txHash);
    event Withdraw(address indexed _who, uint _amount);
    event Payment(address indexed _buyer, address indexed _seller, uint _amount, address indexed _opinionLeader, bool _dapp);
    event Freeze(address indexed _who, bool _freeze);
    event Share(address indexed _who, address indexed _dapp, uint _amount);

    ERC20Base cryptaurToken = ERC20Base(0x88d50B466BE55222019D71F9E8fAe17f5f45FCA1);
    address cryptaurRecovery;
    address cryptaurRewards;
    address cryptaurReserveFund;
    address backend;
    modifier onlyBackend {
        require(backend == msg.sender);
        _;
    }

    modifier onlyOwnerOrBackend {
        require(owner == msg.sender || backend == msg.sender);
        _;
    }

    modifier notFreezed {
        require(freezedAll != true);
        _;
    }

    mapping(address => uint) internal balances;
    mapping(address => mapping (address => uint256)) public available;
    mapping(address => bool) public freezed;
    mapping(address => mapping(address => UnlimitedMode)) public unlimitedMode;
    bool freezedAll;
  
    function CryptaurDepository() owned() public {}

    function balanceOf(address _who) constant public returns (uint) {
        return balances[getMasterWallet(_who)];
    }

    function setUnlimitedMode(bool _unlimited, address _dapp) public {
        address masterWallet = getOrAddMasterWallet(msg.sender);
        unlimitedMode[masterWallet][_dapp] = _unlimited ? UnlimitedMode.UNLIMITED : UnlimitedMode.LIMITED;
    }

    function transferToToken(address[] _addresses) public onlyOwnerOrBackend {
        for (uint index = 0; index < _addresses.length; index++) {
            address addr = _addresses[index];
            uint amount = balances[addr];
            if (amount > 0) {
                balances[addr] = 0;
                cryptaurToken.transfer(addr, amount);
                Withdraw(addr, amount);
            }        
        }
    }

    function setBackend(address _backend) onlyOwner public {
        backend = _backend;
    }

    function setCryptaurRecovery(address _cryptaurRecovery) onlyOwner public {
        cryptaurRecovery = _cryptaurRecovery;
    }

    function setCryptaurToken(address _cryptaurToken) onlyOwner public {
        cryptaurToken = ERC20Base(_cryptaurToken);
    }

    function setCryptaurRewards(address _cryptaurRewards) onlyOwner public {
        cryptaurRewards = _cryptaurRewards;
    }

    function setCryptaurReserveFund(address _cryptaurReserveFund) onlyOwner public {
        cryptaurReserveFund = _cryptaurReserveFund;
    }
    
    function changeAddress(address _old, address _new) public {
        require(msg.sender == cryptaurRecovery);
        applyChangeWalletAddress(_old, _new);

        balances[_new] += balances[_old];
        balances[_old] = 0;
        AddressChanged(_old, _new);
    }

    function linkToMasterWallet(address _masterWaller, address _linkedWaller) public {
        require(msg.sender == owner || msg.sender == backend || msg.sender == cryptaurRecovery);
        linkToMasterWalletInternal(_masterWaller, _linkedWaller);
    }

    function unLinkFromMasterWallet(address _masterWaller, address _linkedWaller) public {
        require(msg.sender == owner || msg.sender == backend || msg.sender == cryptaurRecovery);
        unLinkFromMasterWalletInternal(_masterWaller, _linkedWaller);
    }

    function setMaxLinkedWalletCount(uint8 _newMaxCount) public onlyOwnerOrBackend {
        maxLinkedWalletCount = _newMaxCount;
    }
    
    function freeze(address _who, bool _freeze) onlyOwner public {
        address masterWallet = getMasterWallet(_who);
        if (masterWallet == address(0))
            masterWallet = _who;
        freezed[masterWallet] = _freeze;
        Freeze(masterWallet, _freeze);
    }

    function freeze(bool _freeze) public onlyOwnerOrBackend {
        freezedAll = _freeze;
    }
    
    function deposit(address _who, uint _amount, bytes32 _txHash) onlyBackend public {
        address masterWallet = getOrAddMasterWallet(_who);
        balances[masterWallet] += _amount;
        Deposit(masterWallet, _amount, _txHash);
    }
    
    function withdraw(uint _amount) public notFreezed {
        address masterWallet = getMasterWallet(msg.sender);   
        require(balances[masterWallet] >= _amount);
        require(!freezed[masterWallet]);
        balances[masterWallet] -= _amount;
        cryptaurToken.transfer(masterWallet, _amount);
        Withdraw(masterWallet, _amount);
    }

    function balanceOf2(address _who, address _dapp) constant public returns (uint) { 
        return balanceOf2Internal(getMasterWallet(_who), _dapp);
    }
    
    function balanceOf2Internal(address _who, address _dapp) constant internal returns (uint) {
        uint avail;
        if (!freezed[_who]) {
            if (unlimitedMode[_who][_dapp] == UnlimitedMode.UNLIMITED) {
                avail = balances[_who];
            } 
            else {
                avail = available[_who][_dapp];
                if (avail > balances[_who])
                    avail = balances[_who];
            }
        }
        return avail;
    }
     
    function pay2(address _seller, uint _amount, address _opinionLeader) public notFreezed {
        address dapp = getOrAddMasterWallet(msg.sender);
        address seller = getOrAddMasterWallet(_seller);
        payInternal(dapp, seller, _amount, _opinionLeader);
        available[seller][dapp] += _amount;
    }

    function pay(address _seller, uint _amount, address _opinionLeader) public notFreezed {
        address buyer = getOrAddMasterWallet(msg.sender);
        address seller = getOrAddMasterWallet(_seller);
        payInternal(buyer, seller, _amount, _opinionLeader);
    }
    
     
    function payInternal(address _buyer, address _seller, uint _amount, address _opinionLeader) internal {    
        require(balances[_buyer] >= _amount);
        uint fee;
        if (cryptaurRewards != 0 && cryptaurReserveFund != 0) {
            fee = CryptaurRewards(cryptaurRewards).payment(_buyer, _seller, _amount, _opinionLeader);
        }
        balances[_buyer] -= _amount;
        balances[_seller] += _amount - fee;
        if (fee != 0) {
            balances[cryptaurReserveFund] += fee;
            CryputarReserveFund(cryptaurReserveFund).depositNotification(_amount);
        }
        Payment(_buyer, _seller, _amount, _opinionLeader, false);
    }
    
    function payDAPP(address _buyer, uint _amount, address _opinionLeader) public notFreezed {
        address buyerMasterWallet = getOrAddMasterWallet(_buyer);
        require(balanceOf2Internal(buyerMasterWallet, msg.sender) >= _amount);
        uint fee;
        if (cryptaurRewards != 0 && cryptaurReserveFund != 0) {
            fee = CryptaurRewards(cryptaurRewards).payment(buyerMasterWallet, msg.sender, _amount, _opinionLeader);
        }
        balances[buyerMasterWallet] -= _amount;
        balances[msg.sender] += _amount - fee; 
        if (unlimitedMode[buyerMasterWallet][msg.sender] == UnlimitedMode.LIMITED)
            available[buyerMasterWallet][msg.sender] -= _amount;
        if (fee != 0) {
            balances[cryptaurReserveFund] += fee;
            CryputarReserveFund(cryptaurReserveFund).depositNotification(_amount);
        }
        Payment(buyerMasterWallet, msg.sender, _amount, _opinionLeader, true);
    }

    function shareBalance(address _dapp, uint _amount) public notFreezed {
        address masterWallet = getMasterWallet(msg.sender);
        require(masterWallet != address(0));
        available[masterWallet][_dapp] = _amount;
        Share(masterWallet, _dapp, _amount);
    }
    
    function transferFromFund(address _to, uint _amount) public {
        require(msg.sender == owner || msg.sender == cryptaurRewards || msg.sender == backend);
        require(cryptaurReserveFund != address(0));
        require(balances[cryptaurReserveFund] >= _amount);
        address masterWallet = getOrAddMasterWallet(_to);
        balances[masterWallet] += _amount;
        balances[cryptaurReserveFund] -= _amount;
        CryputarReserveFund(cryptaurReserveFund).withdrawNotification(_amount);
    }
}

 
contract CryptaurDepositoryTest is CryptaurDepository {
    function CryptaurDepositoryTest() CryptaurDepository() {}

     
    function testDrip(address _who, address _dapp, uint _amount) public {
        require(msg.sender == owner || msg.sender == backend);
        address masterWallet = getOrAddMasterWallet(_who);
        balances[masterWallet] = _amount;
        available[masterWallet][_dapp] = _amount;
    }
}