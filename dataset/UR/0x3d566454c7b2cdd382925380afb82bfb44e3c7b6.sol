 

pragma solidity ^0.4.18;

contract ArgumentsChecker {

     
    modifier payloadSizeIs(uint size) {
       require(msg.data.length == size + 4  );
       _;
    }

     
    modifier validAddress(address addr) {
        require(addr != address(0));
        _;
    }
}

contract multiowned {

	 

     
    struct MultiOwnedOperationPendingState {
         
        uint yetNeeded;

         
        uint ownersDone;

         
        uint index;
    }

	 

    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    event FinalConfirmation(address owner, bytes32 operation);

     
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);

     
    event RequirementChanged(uint newRequirement);

	 

     
    modifier onlyowner {
        require(isOwner(msg.sender));
        _;
    }
     
     
     
    modifier onlymanyowners(bytes32 _operation) {
        if (confirmAndCheck(_operation)) {
            _;
        }
         
         
         
    }

    modifier validNumOwners(uint _numOwners) {
        require(_numOwners > 0 && _numOwners <= c_maxOwners);
        _;
    }

    modifier multiOwnedValidRequirement(uint _required, uint _numOwners) {
        require(_required > 0 && _required <= _numOwners);
        _;
    }

    modifier ownerExists(address _address) {
        require(isOwner(_address));
        _;
    }

    modifier ownerDoesNotExist(address _address) {
        require(!isOwner(_address));
        _;
    }

    modifier multiOwnedOperationIsActive(bytes32 _operation) {
        require(isOperationActive(_operation));
        _;
    }

	 

     
     
    function multiowned(address[] _owners, uint _required)
        public
        validNumOwners(_owners.length)
        multiOwnedValidRequirement(_required, _owners.length)
    {
        assert(c_maxOwners <= 255);

        m_numOwners = _owners.length;
        m_multiOwnedRequired = _required;

        for (uint i = 0; i < _owners.length; ++i)
        {
            address owner = _owners[i];
             
            require(0 != owner && !isOwner(owner)  );

            uint currentOwnerIndex = checkOwnerIndex(i + 1  );
            m_owners[currentOwnerIndex] = owner;
            m_ownerIndex[owner] = currentOwnerIndex;
        }

        assertOwnersAreConsistent();
    }

     
     
     
     
    function changeOwner(address _from, address _to)
        external
        ownerExists(_from)
        ownerDoesNotExist(_to)
        onlymanyowners(keccak256(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[_from]);
        m_owners[ownerIndex] = _to;
        m_ownerIndex[_from] = 0;
        m_ownerIndex[_to] = ownerIndex;

        assertOwnersAreConsistent();
        OwnerChanged(_from, _to);
    }

     
     
     
    function addOwner(address _owner)
        external
        ownerDoesNotExist(_owner)
        validNumOwners(m_numOwners + 1)
        onlymanyowners(keccak256(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        m_numOwners++;
        m_owners[m_numOwners] = _owner;
        m_ownerIndex[_owner] = checkOwnerIndex(m_numOwners);

        assertOwnersAreConsistent();
        OwnerAdded(_owner);
    }

     
     
     
    function removeOwner(address _owner)
        external
        ownerExists(_owner)
        validNumOwners(m_numOwners - 1)
        multiOwnedValidRequirement(m_multiOwnedRequired, m_numOwners - 1)
        onlymanyowners(keccak256(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[_owner]);
        m_owners[ownerIndex] = 0;
        m_ownerIndex[_owner] = 0;
         
        reorganizeOwners();

        assertOwnersAreConsistent();
        OwnerRemoved(_owner);
    }

     
     
     
    function changeRequirement(uint _newRequired)
        external
        multiOwnedValidRequirement(_newRequired, m_numOwners)
        onlymanyowners(keccak256(msg.data))
    {
        m_multiOwnedRequired = _newRequired;
        clearPending();
        RequirementChanged(_newRequired);
    }

     
     
    function getOwner(uint ownerIndex) public constant returns (address) {
        return m_owners[ownerIndex + 1];
    }

     
     
    function getOwners() public constant returns (address[]) {
        address[] memory result = new address[](m_numOwners);
        for (uint i = 0; i < m_numOwners; i++)
            result[i] = getOwner(i);

        return result;
    }

     
     
     
    function isOwner(address _addr) public constant returns (bool) {
        return m_ownerIndex[_addr] > 0;
    }

     
     
     
     
    function amIOwner() external constant onlyowner returns (bool) {
        return true;
    }

     
     
    function revoke(bytes32 _operation)
        external
        multiOwnedOperationIsActive(_operation)
        onlyowner
    {
        uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
        var pending = m_multiOwnedPending[_operation];
        require(pending.ownersDone & ownerIndexBit > 0);

        assertOperationIsConsistent(_operation);

        pending.yetNeeded++;
        pending.ownersDone -= ownerIndexBit;

        assertOperationIsConsistent(_operation);
        Revoke(msg.sender, _operation);
    }

     
     
     
    function hasConfirmed(bytes32 _operation, address _owner)
        external
        constant
        multiOwnedOperationIsActive(_operation)
        ownerExists(_owner)
        returns (bool)
    {
        return !(m_multiOwnedPending[_operation].ownersDone & makeOwnerBitmapBit(_owner) == 0);
    }

     

    function confirmAndCheck(bytes32 _operation)
        private
        onlyowner
        returns (bool)
    {
        if (512 == m_multiOwnedPendingIndex.length)
             
             
             
             
            clearPending();

        var pending = m_multiOwnedPending[_operation];

         
        if (! isOperationActive(_operation)) {
             
            pending.yetNeeded = m_multiOwnedRequired;
             
            pending.ownersDone = 0;
            pending.index = m_multiOwnedPendingIndex.length++;
            m_multiOwnedPendingIndex[pending.index] = _operation;
            assertOperationIsConsistent(_operation);
        }

         
        uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
         
        if (pending.ownersDone & ownerIndexBit == 0) {
             
            assert(pending.yetNeeded > 0);
            if (pending.yetNeeded == 1) {
                 
                delete m_multiOwnedPendingIndex[m_multiOwnedPending[_operation].index];
                delete m_multiOwnedPending[_operation];
                FinalConfirmation(msg.sender, _operation);
                return true;
            }
            else
            {
                 
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
                assertOperationIsConsistent(_operation);
                Confirmation(msg.sender, _operation);
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

    function clearPending() private onlyowner {
        uint length = m_multiOwnedPendingIndex.length;
         
        for (uint i = 0; i < length; ++i) {
            if (m_multiOwnedPendingIndex[i] != 0)
                delete m_multiOwnedPending[m_multiOwnedPendingIndex[i]];
        }
        delete m_multiOwnedPendingIndex;
    }

    function checkOwnerIndex(uint ownerIndex) private pure returns (uint) {
        assert(0 != ownerIndex && ownerIndex <= c_maxOwners);
        return ownerIndex;
    }

    function makeOwnerBitmapBit(address owner) private constant returns (uint) {
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[owner]);
        return 2 ** ownerIndex;
    }

    function isOperationActive(bytes32 _operation) private constant returns (bool) {
        return 0 != m_multiOwnedPending[_operation].yetNeeded;
    }


    function assertOwnersAreConsistent() private constant {
        assert(m_numOwners > 0);
        assert(m_numOwners <= c_maxOwners);
        assert(m_owners[0] == 0);
        assert(0 != m_multiOwnedRequired && m_multiOwnedRequired <= m_numOwners);
    }

    function assertOperationIsConsistent(bytes32 _operation) private constant {
        var pending = m_multiOwnedPending[_operation];
        assert(0 != pending.yetNeeded);
        assert(m_multiOwnedPendingIndex[pending.index] == _operation);
        assert(pending.yetNeeded <= m_multiOwnedRequired);
    }


   	 

    uint constant c_maxOwners = 250;

     
    uint public m_multiOwnedRequired;


     
    uint public m_numOwners;

     
     
     
    address[256] internal m_owners;

     
    mapping(address => uint) internal m_ownerIndex;


     
    mapping(bytes32 => MultiOwnedOperationPendingState) internal m_multiOwnedPending;
    bytes32[] internal m_multiOwnedPendingIndex;
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISmartzToken {
     
    function changeOwner(address _from, address _to) external;
    function addOwner(address _owner) external;
    function removeOwner(address _owner) external;
    function changeRequirement(uint _newRequired) external;
    function getOwner(uint ownerIndex) public view returns (address);
    function getOwners() public view returns (address[]);
    function isOwner(address _addr) public view returns (bool);
    function amIOwner() external view returns (bool);
    function revoke(bytes32 _operation) external;
    function hasConfirmed(bytes32 _operation, address _owner) external view returns (bool);

     
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

     
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);

     
    function burn(uint256 _amount) public returns (bool);

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public;

     
    function setKYCProvider(address KYCProvider) external;
    function setSale(address account, bool isSale) external;
    function disablePrivileged() external;

    function availableBalanceOf(address _owner) public view returns (uint256);
    function frozenCellCount(address owner) public view returns (uint);
    function frozenCell(address owner, uint index) public view returns (uint amount, uint thawTS, bool isKYCRequired);

    function frozenTransfer(address _to, uint256 _value, uint thawTS, bool isKYCRequired) external returns (bool);
    function frozenTransferFrom(address _from, address _to, uint256 _value, uint thawTS, bool isKYCRequired) external returns (bool);
}

contract SMRDistributionVault is ArgumentsChecker, multiowned, ERC20 {


     

    function SMRDistributionVault()
        public
        payable
        multiowned(getInitialOwners(), 1)
    {
        m_SMR = ISmartzToken(address(0x40ae4acd08e65714b093bf2495fd7941aedfa231));
        m_thawTS = 1551398400;

        totalSupply = m_SMR.totalSupply();

        
    }

    function getInitialOwners() private pure returns (address[]) {
        address[] memory result = new address[](2);
result[0] = address(0x4ff9a68a832398c6b013633bb5682595ebb7b92e);
result[1] = address(0xe4074bb7bd4828baed9d2bece1e386408428dfb7);
        return result;
    }


     
     
    function balanceOf(address who) public view returns (uint256) {
        return isOwner(who) ? m_SMR.balanceOf(this) : 0;
    }

     
    function transfer(address to, uint256 value)
        public
        payloadSizeIs(2 * 32)
        onlyowner
        returns (bool)
    {
        return m_SMR.frozenTransfer(to, value, m_thawTS, false);
    }

     
    function withdrawRemaining(address to)
        external
        payloadSizeIs(1 * 32)
        onlyowner
        returns (bool)
    {
        return m_SMR.transfer(to, m_SMR.balanceOf(this));
    }


     
    function allowance(address , address ) public view returns (uint256) {
        revert();
    }

     
    function transferFrom(address , address , uint256 ) public returns (bool) {
        revert();
    }

     
    function approve(address , uint256 ) public returns (bool) {
        revert();
    }

    function decimals() public view returns (uint8) {
        return m_SMR.decimals();
    }


     

     
    ISmartzToken public m_SMR;

     
    uint public m_thawTS;


     

    string public constant name = "SMR Community Fund Vault 1";
    string public constant symbol = "SMRDV";
}