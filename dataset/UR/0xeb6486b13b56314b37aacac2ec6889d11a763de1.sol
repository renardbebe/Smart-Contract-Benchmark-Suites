 

pragma solidity ^0.4.20;
 
 
 
 
 
 

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

}

contract ERC20 {
     
    function totalSupply() public constant returns (uint256 _totalSupply);
 
     
    function balanceOf(address _owner) public constant returns (uint256 balance);
 
     
    function transfer(address _to, uint256 _value) public returns (bool success);
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC223 is ERC20{
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes indexed _data);
}

 
contract ContractReceiver {  
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

contract BasicCGRID is ERC223 {
    using SafeMath for uint256;
    
    uint256 public constant decimals = 8;
    string public constant symbol = "CGRID";
    string public constant name = "Carbon Grid Token";
    uint256 public _totalSupply = 10**17;  

     
    address public owner;
    address public airdrop;

     
    bool public tradable = false;

     
    mapping(address => uint256) balances;
    
     
    mapping(address => mapping (address => uint256)) allowed;
            
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isTradable(){
        require(tradable == true || msg.sender == airdrop || msg.sender == owner);
        _;
    }

     
    function BasicCGRID() 
    public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
        Transfer(0x0, owner, _totalSupply);
        airdrop = 0x00227086ab72678903091d315b04a8dacade39647a;
    }
    
     
     
    function totalSupply()
    public 
    constant 
    returns (uint256) {
        return _totalSupply;
    }
        
     
     
     
    function balanceOf(address _addr) 
    public
    constant 
    returns (uint256) {
        return balances[_addr];
    }
    
    
     
    function isContract(address _addr) 
    private 
    view 
    returns (bool is_contract) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length>0);
    }
 
     
     
     
     
     
     
    function transfer(address _to, uint _value) 
    public 
    isTradable
    returns (bool success) {
        require(_to != 0x0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
     
     
     
    function transfer(
        address _to, 
        uint _value, 
        bytes _data) 
    public
    isTradable 
    returns (bool success) {
        require(_to != 0x0);
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        Transfer(msg.sender, _to, _value);
        if(isContract(_to)) {
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            Transfer(msg.sender, _to, _value, _data);
        }
        
        return true;
    }
    
     
     
     
     
     
    function transfer(
        address _to, 
        uint _value, 
        bytes _data, 
        string _custom_fallback) 
    public 
    isTradable
    returns (bool success) {
        require(_to != 0x0);
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        Transfer(msg.sender, _to, _value);

        if(isContract(_to)) {
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            Transfer(msg.sender, _to, _value, _data);
        }
        return true;
    }
         
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
    public
    isTradable
    returns (bool success) {
        require(_to != 0x0);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(_from, _to, _value);
        return true;
    }
    
     
     
    function approve(address _spender, uint256 _amount) 
    public
    returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    
     
    function allowance(address _owner, address _spender) 
    public
    constant 
    returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        return ERC223(tokenAddress).transfer(owner, tokens);
    }
    
     
     
    function turnOnTradable() 
    public
    onlyOwner{
        tradable = true;
    }

     
    function updateAirdrop(address newAirdropAdmin) 
    public 
    onlyOwner{
        airdrop = newAirdropAdmin;
    }
}

contract CGRID is BasicCGRID {

    bool public _selling = true; 
    
    uint256 public _originalBuyPrice = 36500 * 10 ** decimals;  

     
    mapping(address => bool) private approvedInvestorList;
    
     
    mapping(address => uint256) private deposit;
    
     
    uint256 public _icoPercent = 30;
    
     
    uint256 public _icoSupply = (_totalSupply * _icoPercent) / 100;
    
     
    uint256 public _minimumBuy = 3 * 10 ** 17;
    
     
    uint256 public _maximumBuy = 25 * 10 ** 18;

     
    uint256 public totalTokenSold = 0;

     
    modifier onSale() {
        require(_selling);
        _;
    }
    
     
    modifier validInvestor() {
        require(approvedInvestorList[msg.sender]);
        _;
    }
    
     
    modifier validValue(){
         
        require ( (msg.value >= _minimumBuy) &&
                ( (deposit[msg.sender].add(msg.value)) <= _maximumBuy) );
        _;
    }

     
    function()
    public
    payable {
        buyCGRID();
    }
    
     
    function buyCGRID()
    public
    payable
    onSale
    validValue
    validInvestor {
        uint256 requestedUnits = (msg.value * _originalBuyPrice) / 10**18;
        require(balances[owner] >= requestedUnits);
         
        balances[owner] = balances[owner].sub(requestedUnits);
        balances[msg.sender] = balances[msg.sender].add(requestedUnits);
        
         
        deposit[msg.sender] = deposit[msg.sender].add(msg.value);
        
         
        totalTokenSold = totalTokenSold.add(requestedUnits);
        if (totalTokenSold >= _icoSupply){
            _selling = false;
        }
        
         
        Transfer(owner, msg.sender, requestedUnits);
        owner.transfer(msg.value);
    }

     
    function CGRID() BasicCGRID()
    public {
        setBuyPrice(_originalBuyPrice);
    }
    
     
    function turnOffSale() onlyOwner 
    public {
        _selling = false;
    }
    
     
     
    function setIcoPercent(uint256 newIcoPercent)
    public 
    onlyOwner {
        _icoPercent = newIcoPercent;
        _icoSupply = (_totalSupply * _icoPercent) / 100;
    }
    
     
     
    function setMaximumBuy(uint256 newMaximumBuy)
    public 
    onlyOwner {
        _maximumBuy = newMaximumBuy;
    }

     
     
    function setBuyPrice(uint256 newBuyPrice) 
    onlyOwner 
    public {
        require(newBuyPrice>0);
        _originalBuyPrice = newBuyPrice;  
         
        _maximumBuy = (10**18 * 10**14) /_originalBuyPrice;
    }
    
     
     
    function isApprovedInvestor(address _addr)
    public
    constant
    returns (bool) {
        return approvedInvestorList[_addr];
    }
    
     
     
     
    function getDeposit(address _addr)
    public
    constant
    returns(uint256){
        return deposit[_addr];
}
    
     
     
    function addInvestorList(address[] newInvestorList)
    onlyOwner
    public {
        for (uint256 i = 0; i < newInvestorList.length; i++){
            approvedInvestorList[newInvestorList[i]] = true;
        }
    }

     
     
    function removeInvestorList(address[] investorList)
    onlyOwner
    public {
        for (uint256 i = 0; i < investorList.length; i++){
            approvedInvestorList[investorList[i]] = false;
        }
    }
    
     
     
    function withdraw() onlyOwner 
    public 
    returns (bool) {
        return owner.send(this.balance);
    }
}

contract MultiSigWallet {

    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
    event CoinCreation(address coin);

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;
    bool flag = true;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this))
            revert();
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
            revert();
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            revert();
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0)
            revert();
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed)
            revert();
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0)
            revert();
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (   ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0)
            revert();
        _;
    }

     
    function()
        payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

     
     
     
     
    function MultiSigWallet(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0)
                revert();
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

     
     
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

     
     
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

     
     
     
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

     
     
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required);
    }

     
     
     
     
     
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

     
     
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

     
     
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

     
     
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction tx = transactions[transactionId];
            tx.executed = true;
            if (tx.destination.call.value(tx.value)(tx.data))
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
                tx.executed = false;
            }
        }
    }

     
     
     
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

     
     
     
     
     
     
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        Submission(transactionId);
    }

     
     
     
     
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

     
     
     
     
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

     
     
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

     
     
     
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

     
     
     
     
     
     
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
    
     
    function createCoin()
        external
        onlyWallet
    {
        require(flag == true);
        CoinCreation(new CGRID());
        flag = false;
    }
}