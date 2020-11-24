 

pragma solidity ^0.4.18;

interface IApprovalRecipient {
     
    function receiveApproval(address _sender, uint256 _value, bytes _extraData) public;
}

interface IKYCProvider {
    function isKYCPassed(address _address) public view returns (bool);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

    event Burn(address indexed from, uint256 amount);

     
    function burn(uint256 _amount)
        public
        returns (bool)
    {
        address from = msg.sender;

        require(_amount > 0);
        require(_amount <= balances[from]);

        totalSupply = totalSupply.sub(_amount);
        balances[from] = balances[from].sub(_amount);
        Burn(from, _amount);
        Transfer(from, address(0), _amount);

        return true;
    }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract TokenWithApproveAndCallMethod is StandardToken {

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public {
        require(approve(_spender, _value));
        IApprovalRecipient(_spender).receiveApproval(msg.sender, _value, _extraData);
    }
}

contract SmartzToken is ArgumentsChecker, multiowned, BurnableToken, StandardToken, TokenWithApproveAndCallMethod {

     
    struct FrozenCell {
         
        uint amount;

         
        uint128 thawTS;

         
        uint128 isKYCRequired;
    }


     

    modifier onlySale(address account) {
        require(isSale(account));
        _;
    }

    modifier validUnixTS(uint ts) {
        require(ts >= 1522046326 && ts <= 1800000000);
        _;
    }

    modifier checkTransferInvariant(address from, address to) {
        uint initial = balanceOf(from).add(balanceOf(to));
        _;
        assert(balanceOf(from).add(balanceOf(to)) == initial);
    }

    modifier privilegedAllowed {
        require(m_allowPrivileged);
        _;
    }


     

     
    function SmartzToken()
        public
        payable
        multiowned(getInitialOwners(), 1)
    {
        if (0 != 35000000000000000000000000) {
            totalSupply = 35000000000000000000000000;
            balances[msg.sender] = totalSupply;
            Transfer(address(0), msg.sender, totalSupply);
        }

        
totalSupply = totalSupply.add(0);

        
    }

    function getInitialOwners() private pure returns (address[]) {
        address[] memory result = new address[](1);
result[0] = address(0x15B694A7C4106beC672cCB8E0b0590B1d649b4aF);
        return result;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        uint256 balance = balances[_owner];

        for (uint cellIndex = 0; cellIndex < frozenBalances[_owner].length; ++cellIndex) {
            balance = balance.add(frozenBalances[_owner][cellIndex].amount);
        }

        return balance;
    }

     
    function availableBalanceOf(address _owner) public view returns (uint256) {
        uint256 balance = balances[_owner];

        for (uint cellIndex = 0; cellIndex < frozenBalances[_owner].length; ++cellIndex) {
            if (isSpendableFrozenCell(_owner, cellIndex))
                balance = balance.add(frozenBalances[_owner][cellIndex].amount);
        }

        return balance;
    }

     
    function transfer(address _to, uint256 _value)
        public
        payloadSizeIs(2 * 32)
        returns (bool)
    {
        thawSomeTokens(msg.sender, _value);
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        payloadSizeIs(3 * 32)
        returns (bool)
    {
        thawSomeTokens(_from, _value);
        return super.transferFrom(_from, _to, _value);
    }

    
     
    function burn(uint256 _amount)
        public
        payloadSizeIs(1 * 32)
        returns (bool)
    {
        thawSomeTokens(msg.sender, _amount);
        return super.burn(_amount);
    }


     

     
    function frozenCellCount(address owner) public view returns (uint) {
        return frozenBalances[owner].length;
    }

     
    function frozenCell(address owner, uint index) public view returns (uint amount, uint thawTS, bool isKYCRequired) {
        require(index < frozenCellCount(owner));

        amount = frozenBalances[owner][index].amount;
        thawTS = uint(frozenBalances[owner][index].thawTS);
        isKYCRequired = decodeKYCFlag(frozenBalances[owner][index].isKYCRequired);
    }


     

     
    function setKYCProvider(address KYCProvider)
        external
        validAddress(KYCProvider)
        privilegedAllowed
        onlymanyowners(keccak256(msg.data))
    {
        m_KYCProvider = IKYCProvider(KYCProvider);
    }

     
    function setSale(address account, bool isSale)
        external
        validAddress(account)
        privilegedAllowed
        onlymanyowners(keccak256(msg.data))
    {
        m_sales[account] = isSale;
    }


     
    function frozenTransfer(address _to, uint256 _value, uint thawTS, bool isKYCRequired)
        external
        validAddress(_to)
        validUnixTS(thawTS)
        payloadSizeIs(4 * 32)
        privilegedAllowed
        onlySale(msg.sender)
        checkTransferInvariant(msg.sender, _to)
        returns (bool)
    {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        addFrozen(_to, _value, thawTS, isKYCRequired);
        Transfer(msg.sender, _to, _value);

        return true;
    }

     
    function frozenTransferFrom(address _from, address _to, uint256 _value, uint thawTS, bool isKYCRequired)
        external
        validAddress(_to)
        validUnixTS(thawTS)
        payloadSizeIs(5 * 32)
        privilegedAllowed
         
         
        checkTransferInvariant(_from, _to)
        returns (bool)
    {
        require(isSale(msg.sender) && isSale(_to));
        require(_value <= allowed[_from][msg.sender]);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        subFrozen(_from, _value, thawTS, isKYCRequired);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);

        return true;
    }

     
    function disablePrivileged()
        external
        privilegedAllowed
        onlymanyowners(keccak256(msg.data))
    {
        m_allowPrivileged = false;
    }


     

    function isSale(address account) private view returns (bool) {
        return m_sales[account];
    }

     
    function findFrozenCell(address owner, uint128 thawTSEncoded, uint128 isKYCRequiredEncoded)
        private
        view
        returns (uint cellIndex)
    {
        for (cellIndex = 0; cellIndex < frozenBalances[owner].length; ++cellIndex) {
            FrozenCell storage checkedCell = frozenBalances[owner][cellIndex];
            if (checkedCell.thawTS == thawTSEncoded && checkedCell.isKYCRequired == isKYCRequiredEncoded)
                break;
        }

        assert(cellIndex <= frozenBalances[owner].length);
    }

     
    function isSpendableFrozenCell(address owner, uint cellIndex)
        private
        view
        returns (bool)
    {
        FrozenCell storage cell = frozenBalances[owner][cellIndex];
        if (uint(cell.thawTS) > getTime())
            return false;

        if (0 == cell.amount)    
            return false;

        if (decodeKYCFlag(cell.isKYCRequired) && !m_KYCProvider.isKYCPassed(owner))
            return false;

        return true;
    }

     
    function addFrozen(address _to, uint256 _value, uint thawTS, bool isKYCRequired)
        private
        validAddress(_to)
        validUnixTS(thawTS)
    {
        uint128 thawTSEncoded = uint128(thawTS);
        uint128 isKYCRequiredEncoded = encodeKYCFlag(isKYCRequired);

        uint cellIndex = findFrozenCell(_to, thawTSEncoded, isKYCRequiredEncoded);

         
        if (cellIndex == frozenBalances[_to].length) {
            frozenBalances[_to].length++;
            targetCell = frozenBalances[_to][cellIndex];
            assert(0 == targetCell.amount);

            targetCell.thawTS = thawTSEncoded;
            targetCell.isKYCRequired = isKYCRequiredEncoded;
        }

        FrozenCell storage targetCell = frozenBalances[_to][cellIndex];
        assert(targetCell.thawTS == thawTSEncoded && targetCell.isKYCRequired == isKYCRequiredEncoded);

        targetCell.amount = targetCell.amount.add(_value);
    }

     
    function subFrozen(address _from, uint256 _value, uint thawTS, bool isKYCRequired)
        private
        validUnixTS(thawTS)
    {
        uint cellIndex = findFrozenCell(_from, uint128(thawTS), encodeKYCFlag(isKYCRequired));
        require(cellIndex != frozenBalances[_from].length);    

        FrozenCell storage cell = frozenBalances[_from][cellIndex];
        require(cell.amount >= _value);

        cell.amount = cell.amount.sub(_value);
    }

     
    function thawSomeTokens(address owner, uint requiredAmount)
        private
    {
        if (balances[owner] >= requiredAmount)
            return;      

         
        require(availableBalanceOf(owner) >= requiredAmount);

        for (uint cellIndex = 0; cellIndex < frozenBalances[owner].length; ++cellIndex) {
            if (isSpendableFrozenCell(owner, cellIndex)) {
                uint amount = frozenBalances[owner][cellIndex].amount;
                frozenBalances[owner][cellIndex].amount = 0;
                balances[owner] = balances[owner].add(amount);
            }
        }

        assert(balances[owner] >= requiredAmount);
    }

     
    function getTime() internal view returns (uint) {
        return now;
    }

    function encodeKYCFlag(bool isKYCRequired) private pure returns (uint128) {
        return isKYCRequired ? uint128(1) : uint128(0);
    }

    function decodeKYCFlag(uint128 isKYCRequired) private pure returns (bool) {
        return isKYCRequired != uint128(0);
    }


     

     
    IKYCProvider public m_KYCProvider;

     
    mapping (address => bool) public m_sales;

     
    mapping (address => FrozenCell[]) public frozenBalances;

     
    bool public m_allowPrivileged = true;


     

    string public constant name = 'BitDraw';
    string public constant symbol = 'BTDW';
    uint8 public constant decimals = 18;
}