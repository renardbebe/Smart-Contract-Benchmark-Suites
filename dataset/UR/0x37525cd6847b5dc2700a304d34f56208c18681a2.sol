 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
     function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
}


contract multiowned {

     

     
    struct PendingState {
        uint yetNeeded;
        uint ownersDone;
        uint index;
    }

     

     
     
    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
     
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);
     
    event RequirementChanged(uint newRequirement);

     

     
    modifier onlyowner {
        if (isOwner(msg.sender))
            _;
    }
     
     
     
    modifier onlymanyowners(bytes32 _operation) {
        if (confirmAndCheck(_operation))
            _;
    }

     

     
     
    constructor(address[] _owners, uint _required) public {
        m_numOwners = _owners.length; 
         
         
        for (uint i = 0; i < _owners.length; ++i)
        {
            m_owners[1 + i] = uint(_owners[i]);
            m_ownerIndex[uint(_owners[i])] = 1 + i;
        }
        m_required = _required;
    }
    
     
    function revoke(bytes32 _operation) external {
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
         
        if (ownerIndex == 0) return;
        uint ownerIndexBit = 2**ownerIndex;
        PendingState storage pending = m_pending[_operation];
        if (pending.ownersDone & ownerIndexBit > 0) {
            pending.yetNeeded++;
            pending.ownersDone -= ownerIndexBit;
            emit Revoke(msg.sender, _operation);
        }
    }
    
     
    function changeOwner(address _from, address _to) onlymanyowners(keccak256(abi.encodePacked(msg.data))) external {
        if (isOwner(_to)) return;
        uint ownerIndex = m_ownerIndex[uint(_from)];
        if (ownerIndex == 0) return;

        clearPending();
        m_owners[ownerIndex] = uint(_to);
        m_ownerIndex[uint(_from)] = 0;
        m_ownerIndex[uint(_to)] = ownerIndex;
        emit OwnerChanged(_from, _to);
    }
    
    function addOwner(address _owner) onlymanyowners(keccak256(abi.encodePacked(msg.data))) external {
        if (isOwner(_owner)) return;

        clearPending();
        if (m_numOwners >= c_maxOwners)
            reorganizeOwners();
        if (m_numOwners >= c_maxOwners)
            return;
        m_numOwners++;
        m_owners[m_numOwners] = uint(_owner);
        m_ownerIndex[uint(_owner)] = m_numOwners;
        emit OwnerAdded(_owner);
    }
    
    function removeOwner(address _owner) onlymanyowners(keccak256(abi.encodePacked(msg.data))) external {
        uint ownerIndex = m_ownerIndex[uint(_owner)];
        if (ownerIndex == 0) return;
        
        if (m_required > m_numOwners - 1) return;

        m_owners[ownerIndex] = 0;
        m_ownerIndex[uint(_owner)] = 0;
        clearPending();
        reorganizeOwners();  
        emit OwnerRemoved(_owner);
    }
    
    function changeRequirement(uint _newRequired) onlymanyowners(keccak256(abi.encodePacked(msg.data))) external {
        if (_newRequired > m_numOwners) return;
        m_required = _newRequired;
        clearPending();
        emit RequirementChanged(_newRequired);
    }
    
    function isOwner(address _addr) public view returns (bool) {
        return m_ownerIndex[uint(_addr)] > 0;
    }
    
    function hasConfirmed(bytes32 _operation, address _owner) public view returns (bool) {
        PendingState storage pending = m_pending[_operation];
        uint ownerIndex = m_ownerIndex[uint(_owner)];

         
        if (ownerIndex == 0) return false;

         
        uint ownerIndexBit = 2**ownerIndex;
        if (pending.ownersDone & ownerIndexBit == 0) {
            return false;
        } else {
            return true;
        }
    }
    
     

    function confirmAndCheck(bytes32 _operation) internal returns (bool) {
         
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
         
        if (ownerIndex == 0) return;

        PendingState storage pending = m_pending[_operation];
         
        if (pending.yetNeeded == 0) {
             
            pending.yetNeeded = m_required;
             
            pending.ownersDone = 0;
            pending.index = m_pendingIndex.length++;
            m_pendingIndex[pending.index] = _operation;
        }
         
        uint ownerIndexBit = 2**ownerIndex;
         
        if (pending.ownersDone & ownerIndexBit == 0) {
            emit Confirmation(msg.sender, _operation);
             
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

    function reorganizeOwners() private returns (bool) {
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
        for (uint i = 0; i < length; ++i) {
            if (m_pendingIndex[i] != 0) {
                delete m_pending[m_pendingIndex[i]];
            }
        }
            
        delete m_pendingIndex;
    }
        
     

     
    uint public m_required;
     
    uint public m_numOwners;
    
     
    uint[256] m_owners;
    uint constant c_maxOwners = 250;
     
    mapping(uint => uint) m_ownerIndex;
     
    mapping(bytes32 => PendingState) m_pending;
    bytes32[] m_pendingIndex;
}

 
 
 
contract daylimit is multiowned {

     

     
    modifier limitedDaily(uint _value) {
        if (underLimit(_value))
            _;
    }

     

     
    constructor(uint _limit) public {
        m_dailyLimit = _limit;
        m_lastDay = today();
    }
     
    function setDailyLimit(uint _newLimit) onlymanyowners(keccak256(abi.encodePacked(msg.data))) external {
        m_dailyLimit = _newLimit;
    }
     
    function resetSpentToday() onlymanyowners(keccak256(abi.encodePacked(msg.data))) external {
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
     
    function today() private view returns (uint) { return block.timestamp / 1 days; }

     

    uint public m_dailyLimit;
    uint public m_spentToday;
    uint public m_lastDay;
}

 
contract multisig {

     

     
     
    event Deposit(address from, uint value);
     
    event SingleTransact(address owner, uint value, address to);
     
    event MultiTransact(address owner, bytes32 operation, uint value, address to);
     
    event ConfirmationERC20Needed(bytes32 operation, address initiator, uint value, address to, ERC20Basic token);

    
    event ConfirmationETHNeeded(bytes32 operation, address initiator, uint value, address to);
    
     
    
     
    function changeOwner(address _from, address _to) external;
     
     
}

 
 
 
contract Wallet is multisig, multiowned, daylimit {

    uint public version = 4;

     

     
    struct Transaction {
        address to;
        uint value;
        address token;
    }

    ERC20Basic public erc20;

     

     
     
    constructor(address[] _owners, uint _required, uint _daylimit, address _erc20)
            multiowned(_owners, _required) daylimit(_daylimit) public {
            erc20 = ERC20Basic(_erc20);
    }

    function changeERC20(address _erc20) onlymanyowners(keccak256(abi.encodePacked(msg.data))) public {
        erc20 = ERC20Basic(_erc20);
    }
    
     
    function kill(address _to) onlymanyowners(keccak256(abi.encodePacked(msg.data))) external {
        selfdestruct(_to);
    }
    
     
    function() public payable {
         
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }
    
     
     
     
     
    function transferETH(address _to, uint _value) external onlyowner returns (bytes32 _r) {
         
        if (underLimit(_value)) {
            emit SingleTransact(msg.sender, _value, _to);
             
            _to.transfer(_value);
            return 0;
        }
         
        _r = keccak256(abi.encodePacked(msg.data, block.number));
        if (!confirmETH(_r) && m_txs[_r].to == 0) {
            m_txs[_r].to = _to;
            m_txs[_r].value = _value;
            emit ConfirmationETHNeeded(_r, msg.sender, _value, _to);
        }
    }

     
     
    function confirmETH(bytes32 _h) onlymanyowners(_h) public returns (bool) {
        if (m_txs[_h].to != 0) {
            m_txs[_h].to.transfer(m_txs[_h].value);
            emit MultiTransact(msg.sender, _h, m_txs[_h].value, m_txs[_h].to);
            delete m_txs[_h];
            return true;
        }
    }

    function transferERC20(address _to, uint _value) external onlyowner returns (bytes32 _r) {
         
        if (underLimit(_value)) {
            emit SingleTransact(msg.sender, _value, _to);
             

            erc20.transfer(_to, _value);
            return 0;
        }
         
        _r = keccak256(abi.encodePacked(msg.data, block.number));
        if (!confirmERC20(_r, address(0)) && m_txs[_r].to == 0) {
            m_txs[_r].to = _to;
            m_txs[_r].value = _value;
            m_txs[_r].token = erc20;
            emit ConfirmationERC20Needed(_r, msg.sender, _value, _to, erc20);
        }
    }

    function confirmERC20(bytes32 _h, address from) onlymanyowners(_h) public returns (bool) {
        if (m_txs[_h].to != 0) {
            ERC20Basic token = ERC20Basic(m_txs[_h].token);
            token.transferFrom(from, m_txs[_h].to, m_txs[_h].value);
            emit MultiTransact(msg.sender, _h, m_txs[_h].value, m_txs[_h].to);
            delete m_txs[_h];
            return true;
        }
    }
    

    
     
    
    function clearPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i < length; ++i)
            delete m_txs[m_pendingIndex[i]];
        super.clearPending();
    }

     

     
    mapping (bytes32 => Transaction) m_txs;
}