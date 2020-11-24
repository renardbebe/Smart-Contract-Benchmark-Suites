 

contract Multiowned {

     

     
    struct PendingState {
        uint yetNeeded;
        uint ownersDone;
        uint index;
    }

     

     
     
    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
     
    event OwnerChanged(address oldOwner, address newOwner, bytes32 operation);
    event OwnerAdded(address newOwner, bytes32 operation);
    event OwnerRemoved(address oldOwner, bytes32 operation);
     
    event RequirementChanged(uint newRequirement, bytes32 operation);
    event Operation(bytes32 operation);


     

     
    modifier onlyOwner {
        if (isOwner(msg.sender))
            _;
    }
     
     
     
    modifier onlyManyOwners(bytes32 _operation) {
        Operation(_operation);
        if (confirmAndCheck(_operation))
            _;
    }

     

     
     
    function Multiowned() public{
        m_numOwners = 1;
        m_owners[1] = uint(msg.sender);
        m_ownerIndex[uint(msg.sender)] = 1;
        m_required = 1;
    }
    
     
    function revoke(bytes32 _operation) external {
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
    
     
    function changeOwner(address _from, address _to) onlyManyOwners(keccak256(msg.data)) external {
        if (isOwner(_to)) return;
        uint ownerIndex = m_ownerIndex[uint(_from)];
        if (ownerIndex == 0) return;

        clearPending();
        m_owners[ownerIndex] = uint(_to);
        m_ownerIndex[uint(_from)] = 0;
        m_ownerIndex[uint(_to)] = ownerIndex;
        OwnerChanged(_from, _to, keccak256(msg.data));
    }
    
    function addOwner(address _owner) onlyManyOwners(keccak256(msg.data)) external {
        if (isOwner(_owner)) return;

        clearPending();
        if (m_numOwners >= c_maxOwners)
            reorganizeOwners();
        if (m_numOwners >= c_maxOwners)
            return;
        m_numOwners++;
        m_owners[m_numOwners] = uint(_owner);
        m_ownerIndex[uint(_owner)] = m_numOwners;
        OwnerAdded(_owner,keccak256(msg.data));
    }
    
    function removeOwner(address _owner) onlyManyOwners(keccak256(msg.data)) external {
        uint ownerIndex = m_ownerIndex[uint(_owner)];
        if (ownerIndex == 0) return;
        if (m_required > m_numOwners - 1) return;

        m_owners[ownerIndex] = 0;
        m_ownerIndex[uint(_owner)] = 0;
        clearPending();
        reorganizeOwners();  
        OwnerRemoved(_owner,keccak256(msg.data));
    }
    
    function changeRequirement(uint _newRequired) onlyManyOwners(keccak256(msg.data)) external {
        if (_newRequired > m_numOwners) return;
        m_required = _newRequired;
        clearPending();
        RequirementChanged(_newRequired,keccak256(msg.data));
    }

    function isOwner(address _addr) view public returns (bool){
        return m_ownerIndex[uint(_addr)] > 0;
    }
    
     
     
    function hasConfirmed(bytes32 _operation, address _owner) view public returns (bool) {
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
        
     

     
    uint public m_required;
     
    uint public m_numOwners;
    
     
    uint[256] m_owners;
    uint constant c_maxOwners = 250;
     
    mapping(uint => uint) m_ownerIndex;
     
    mapping(bytes32 => PendingState) m_pending;
    bytes32[] m_pendingIndex;
}

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
    view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


contract UGCoin is Multiowned, StandardToken {

    event Freeze(address from, uint value);
    event Defreeze(address ownerAddr, address userAddr, uint256 amount);
    event ReturnToOwner(address ownerAddr, uint amount);
    event Destroy(address from, uint value);

    function UGCoin() public Multiowned(){
        balances[msg.sender] = initialAmount;    
        totalSupply = initialAmount;               
    }

    function() public {

    }
    
     
    function freeze(uint256 _amount) external returns (bool success){
        require(balances[msg.sender] >= _amount);
        coinPool += _amount;
        balances[msg.sender] -= _amount;
        Freeze(msg.sender, _amount);
        return true;
    }

     
    function defreeze(address _userAddr, uint256 _amount) onlyOwner external returns (bool success){
        require(balances[msg.sender] >= _amount);  
        require(coinPool >= _amount);
        balances[_userAddr] += _amount;
        balances[msg.sender] -= _amount;
        ownersLoan[msg.sender] += _amount;
        Defreeze(msg.sender, _userAddr, _amount);
        return true;
    }

    function returnToOwner(address _ownerAddr, uint256 _amount) onlyManyOwners(keccak256(msg.data)) external returns (bool success){
        require(coinPool >= _amount);
        require(isOwner(_ownerAddr));
        require(ownersLoan[_ownerAddr] >= _amount);
        balances[_ownerAddr] += _amount;
        coinPool -= _amount;
        ownersLoan[_ownerAddr] -= _amount;
        ReturnToOwner(_ownerAddr, _amount);
        return true;
    }
    
    function destroy(uint256 _amount) external returns (bool success){
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        Destroy(msg.sender, _amount);
        return true;
    }

    function getOwnersLoan(address _ownerAddr) view public returns (uint256){
        return ownersLoan[_ownerAddr];
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
         
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

    string public name = "UG Coin";
    uint8 public decimals = 18;
    string public symbol = "UGC";
    string public version = "v0.1";
    uint256 public initialAmount = (10 ** 9) * (10 ** 18);
    uint256 public coinPool = 0;       
    mapping (address => uint256) ownersLoan;       

}