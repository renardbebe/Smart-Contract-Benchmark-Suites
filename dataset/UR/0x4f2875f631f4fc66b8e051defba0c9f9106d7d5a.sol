 

 
 

 
 
 
 
 
 
 
 
 
 
pragma solidity ^0.4.6;

contract multisig {
     

     
     
    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);

     
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);

     
    event RequirementChanged(uint newRequirement);

     
    event Deposit(address _from, uint value);
     
    event SingleTransact(address owner, uint value, address to, bytes data);
     
    event MultiTransact(address owner, bytes32 operation, uint value, address to, bytes data);
     
    event ConfirmationNeeded(bytes32 operation, address initiator, uint value, address to, bytes data);
}

contract multisigAbi is multisig {
    function isOwner(address _addr) returns (bool);

    function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool);

    function confirm(bytes32 _h) returns(bool);

     
    function setDailyLimit(uint _newLimit);

    function addOwner(address _owner);

    function removeOwner(address _owner);

    function changeRequirement(uint _newRequired);

     
    function revoke(bytes32 _operation);

    function changeOwner(address _from, address _to);

    function execute(address _to, uint _value, bytes _data) returns(bool);
}

contract WalletLibrary is multisig {
     

     
    struct PendingState {
        uint yetNeeded;
        uint ownersDone;
        uint index;
    }

     
    struct Transaction {
        address to;
        uint value;
        bytes data;
    }

     

     

     
    modifier onlyowner {
        if (isOwner(msg.sender))
            _;
    }
     
     
     
    modifier onlymanyowners(bytes32 _operation) {
        if (confirmAndCheck(_operation))
            _;
    }

     

     
     
     
    function initMultiowned(address[] _owners, uint _required) {
        m_numOwners = _owners.length ;
        m_required = _required;

        for (uint i = 0; i < _owners.length; ++i)
        {
            m_owners[1 + i] = uint(_owners[i]);
            m_ownerIndex[uint(_owners[i])] = 1 + i;
        }
    }

     
    function revoke(bytes32 _operation) {
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
         
        if (ownerIndex == 0) return;
        uint ownerIndexBit = 2**ownerIndex;
        var pending = m_pending[_operation];
        if (pending.ownersDone & ownerIndexBit > 0) {
            pending.yetNeeded++;
            pending.ownersDone -= ownerIndexBit;
            Revoke(msg.sender, _operation);
        }
    }

     
    function changeOwner(address _from, address _to) onlymanyowners(sha3(msg.data)) {
        if (isOwner(_to)) return;
        uint ownerIndex = m_ownerIndex[uint(_from)];
        if (ownerIndex == 0) return;

        clearPending();
        m_owners[ownerIndex] = uint(_to);
        m_ownerIndex[uint(_from)] = 0;
        m_ownerIndex[uint(_to)] = ownerIndex;
        OwnerChanged(_from, _to);
    }

    function addOwner(address _owner) onlymanyowners(sha3(msg.data)) {
        if (isOwner(_owner)) return;

        clearPending();
        if (m_numOwners >= c_maxOwners)
            reorganizeOwners();
        if (m_numOwners >= c_maxOwners)
            return;
        m_numOwners++;
        m_owners[m_numOwners] = uint(_owner);
        m_ownerIndex[uint(_owner)] = m_numOwners;
        OwnerAdded(_owner);
    }

    function removeOwner(address _owner) onlymanyowners(sha3(msg.data)) {
        uint ownerIndex = m_ownerIndex[uint(_owner)];
        if (ownerIndex == 0) return;
        if (m_required > m_numOwners - 1) return;

        m_owners[ownerIndex] = 0;
        m_ownerIndex[uint(_owner)] = 0;
        clearPending();
        reorganizeOwners();  
        OwnerRemoved(_owner);
    }

    function changeRequirement(uint _newRequired) onlymanyowners(sha3(msg.data)) {
        if (_newRequired > m_numOwners) return;
        m_required = _newRequired;
        clearPending();
        RequirementChanged(_newRequired);
    }

    function isOwner(address _addr) returns (bool) {
        return m_ownerIndex[uint(_addr)] > 0;
    }


    function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
        var pending = m_pending[_operation];
        uint ownerIndex = m_ownerIndex[uint(_owner)];

         
        if (ownerIndex == 0) return false;

         
        uint ownerIndexBit = 2**ownerIndex;
        return !(pending.ownersDone & ownerIndexBit == 0);
    }

     

    function confirmAndCheck(bytes32 _operation) internal returns (bool) {
         
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
         
        if (ownerIndex == 0) return;

        var pending = m_pending[_operation];
         
        if (pending.yetNeeded == 0) {
             
            pending.yetNeeded = m_required;
             
            pending.ownersDone = 0;
            pending.index = m_pendingIndex.length++;
            m_pendingIndex[pending.index] = _operation;
        }
         
        uint ownerIndexBit = 2**ownerIndex;
         
        if (pending.ownersDone & ownerIndexBit == 0) {
            Confirmation(msg.sender, _operation);
             
            if (pending.yetNeeded <= 1) {
                 
                delete m_pendingIndex[m_pending[_operation].index];
                delete m_pending[_operation];
                return true;
            }
            else
            {
                 
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
            }
        }
    }

    function reorganizeOwners() private {
        uint free = 1;
        while (free < m_numOwners)
        {
            while (free < m_numOwners && m_owners[free] != 0) free++;
            while (m_numOwners > 1 && m_owners[m_numOwners] == 0) m_numOwners--;
            if (free < m_numOwners && m_owners[m_numOwners] != 0 && m_owners[free] == 0)
            {
                m_owners[free] = m_owners[m_numOwners];
                m_ownerIndex[m_owners[free]] = free;
                m_owners[m_numOwners] = 0;
            }
        }
    }

    function clearPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i < length; ++i)
            if (m_pendingIndex[i] != 0)
                delete m_pending[m_pendingIndex[i]];
        delete m_pendingIndex;
    }


     

     

     
    modifier limitedDaily(uint _value) {
        if (underLimit(_value))
            _;
    }

     

     
    function initDaylimit(uint _limit) {
        m_dailyLimit = _limit;
        m_lastDay = today();
    }
     
    function setDailyLimit(uint _newLimit) onlymanyowners(sha3(msg.data)) {
        m_dailyLimit = _newLimit;
    }
     
    function resetSpentToday() onlymanyowners(sha3(msg.data)) {
        m_spentToday = 0;
    }

     

     
     
    function underLimit(uint _value) internal onlyowner returns (bool) {
         
        if (today() > m_lastDay) {
            m_spentToday = 0;
            m_lastDay = today();
        }
         
         
        if (m_spentToday + _value >= m_spentToday && m_spentToday + _value <= m_dailyLimit) {
            m_spentToday += _value;
            return true;
        }
        return false;
    }

     
    function today() private constant returns (uint) { return now / 1 days; }


     

     

     
     
    function initWallet(address[] _owners, uint _required, uint _daylimit) {
        initMultiowned(_owners, _required);
        initDaylimit(_daylimit) ;
    }

     
    function kill(address _to) onlymanyowners(sha3(msg.data)) {
        suicide(_to);
    }

     
     
     
     
    function execute(address _to, uint _value, bytes _data) onlyowner returns(bool _callValue) {
         
        if (underLimit(_value)) {
            SingleTransact(msg.sender, _value, _to, _data);
             
            _callValue =_to.call.value(_value)(_data);
        } else {
             
            bytes32 _r = sha3(msg.data, block.number);
            if (!confirm(_r) && m_txs[_r].to == 0) {
                m_txs[_r].to = _to;
                m_txs[_r].value = _value;
                m_txs[_r].data = _data;
                ConfirmationNeeded(_r, msg.sender, _value, _to, _data);
            }
        }
    }

     
     
    function confirm(bytes32 _h) onlymanyowners(_h) returns (bool) {
        if (m_txs[_h].to != 0) {
            m_txs[_h].to.call.value(m_txs[_h].value)(m_txs[_h].data);
            MultiTransact(msg.sender, _h, m_txs[_h].value, m_txs[_h].to, m_txs[_h].data);
            delete m_txs[_h];
            return true;
        }
    }

     

    function clearWalletPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i < length; ++i)
            delete m_txs[m_pendingIndex[i]];
        clearPending();
    }

     
    address constant _walletLibrary = 0x4f2875f631f4fc66b8e051defba0c9f9106d7d5a;

     
    uint m_required;
     
    uint m_numOwners;

    uint public m_dailyLimit;
    uint public m_spentToday;
    uint public m_lastDay;

     
    uint[256] m_owners;
    uint constant c_maxOwners = 250;

     
    mapping(uint => uint) m_ownerIndex;
     
    mapping(bytes32 => PendingState) m_pending;
    bytes32[] m_pendingIndex;

     
    mapping (bytes32 => Transaction) m_txs;
}