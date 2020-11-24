 

pragma solidity ^0.5.1;

contract Multiowned {

     
     
    struct PendingState {
        uint yetNeeded;
        uint ownersDone;
        uint index;
    }

     
     
     
    event Confirmation(address owner, bytes32 operation);

     
     
    modifier onlyOwner {
        if (!isOwner(msg.sender))
            require(false);
        _;
    }

     
     
     
    modifier onlyManyOwners(bytes32 _operation) {
        if (confirmAndCheck(_operation))
            _;
    }

     
     
     
    constructor(address[] memory _owners, uint _required) public{
        m_numOwners = _owners.length;
        for (uint i = 0; i < _owners.length; ++i)
        {
            m_owners[1 + i] = _owners[i];
            m_ownerIndex[_owners[i]] = 1 + i;
        }
        m_required = _required;
    }

    function isOwner(address _addr) public view returns (bool) {
        return m_ownerIndex[_addr] > 0;
    }

    function hasConfirmed(bytes32 _operation, address _owner) view public returns (bool) {
        PendingState storage pending = m_pending[_operation];
        uint ownerIndex = m_ownerIndex[_owner];

         
        if (ownerIndex == 0) return false;

         
        uint ownerIndexBit = 2 ** ownerIndex;
        if (pending.ownersDone & ownerIndexBit == 0) {
            return false;
        } else {
            return true;
        }
    }

     

    function confirmAndCheck(bytes32 _operation) internal returns (bool) {
         
        uint ownerIndex = m_ownerIndex[msg.sender];
         
        if (ownerIndex == 0) return false;

        PendingState storage pending = m_pending[_operation];
         
        if (pending.yetNeeded == 0) {
             
            pending.yetNeeded = m_required;
             
            pending.ownersDone = 0;
            pending.index = m_pendingIndex.length++;
            m_pendingIndex[pending.index] = _operation;
        }
         
        uint ownerIndexBit = 2 ** ownerIndex;
         
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
        return false;
    }

     

     
    uint public m_required;
     
    uint public m_numOwners;

     
    address[11] m_owners;
    uint constant c_maxOwners = 10;
     
    mapping(address => uint) m_ownerIndex;
     
    mapping(bytes32 => PendingState) m_pending;
    bytes32[] m_pendingIndex;
}


 
contract Pausable is Multiowned {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}
 
contract SafeMath {
    function safeMul(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) pure internal returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) pure internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract tokenRecipientInterface {
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public;
}

contract ZVC is Multiowned, SafeMath, Pausable{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public creator;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    mapping (address => bool) public PEAccounts;

     
    mapping(bytes32 => Transaction) m_txs;

     
    struct Transaction {
        address to;
        uint value;
    }

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event MappingTo(address from, string to, uint256 value);

     
    event MultiTransact(address owner, bytes32 operation, uint value, address to);
     
    event ConfirmationNeeded(bytes32 operation, address initiator, uint value, address to);

    modifier notHolderAndPE() {
        require(creator != msg.sender && !PEAccounts[msg.sender]);
        _;
    }


     
    constructor(address[] memory _owners, uint _required) Multiowned(_owners, _required) public payable  {
        balanceOf[msg.sender] = 500000000000000000;               
        totalSupply = 500000000000000000;                         
        name = "ZVC";                                    
        symbol = "ZVC";                                
        decimals = 9;                             
        creator = msg.sender;                     
    }

     
    function transfer(address _to, uint256 _value) whenNotPaused notHolderAndPE public returns (bool success){
        require(_to != address(0x0));                                
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);            
        require(balanceOf[_to] + _value >= balanceOf[_to]);  
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
        emit Transfer(msg.sender, _to, _value);                    
        return true;
    }


     
    function approve(address _spender, uint256 _value) whenNotPaused notHolderAndPE public returns (bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool success) {
        require (_to != address(0x0));                                 
        require (_value > 0);
        require (balanceOf[_from] >= _value);                  
        require (balanceOf[_to] + _value >= balanceOf[_to]);   
        require (_value <= allowance[_from][msg.sender]);      
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) whenNotPaused notHolderAndPE public returns (bool success) {
        tokenRecipientInterface spender = tokenRecipientInterface(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
        return false;
    }

     
    function mappingTo(string memory to, uint256 _value) notHolderAndPE public returns (bool success){
        require (balanceOf[msg.sender] >= _value);             
        require(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        totalSupply = SafeMath.safeSub(totalSupply, _value);                                 
        emit MappingTo(msg.sender, to, _value);
        return true;
    }

     
     
     
     
    function execute(address _to, uint _value) external onlyOwner returns (bytes32 _r) {
        _r = keccak256(abi.encode(msg.data, block.number));
        if (!confirm(_r) && m_txs[_r].to == address(0)) {
            m_txs[_r].to = _to;
            m_txs[_r].value = _value;
            emit ConfirmationNeeded(_r, msg.sender, _value, _to);
        }
    }

     
     
    function confirm(bytes32 _h) public onlyManyOwners(_h) returns (bool) {
        uint256 _value = m_txs[_h].value;
        address _to = m_txs[_h].to;
        if (_to != address(0)) {
            require(_value > 0);
            require(balanceOf[creator] >= _value);            
            require(balanceOf[_to] + _value >= balanceOf[_to]);  
            balanceOf[creator] = SafeMath.safeSub(balanceOf[creator], _value);                      
            balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
            emit Transfer(creator, _to, _value);                    
            delete m_txs[_h];
            return true;
        }
        return false;
    }

    function addPEAccount(address _to) public onlyOwner{
        PEAccounts[_to] = true;
    }

    function delPEAccount(address _to) public onlyOwner {
        delete PEAccounts[_to];
    }

    function () external payable {
    }

     
    function withdrawEther(uint256 amount) public onlyOwner{
        msg.sender.transfer(amount);
    }
}