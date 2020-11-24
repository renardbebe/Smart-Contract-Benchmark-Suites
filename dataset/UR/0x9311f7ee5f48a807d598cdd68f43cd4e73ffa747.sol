 

pragma solidity ^0.4.18;

 
 
 
 
 
 

contract ERC20Interface {
     
    function totalSupply() public constant returns (uint256 _totalSupply);
 
     
    function balanceOf(address _owner) public constant returns (uint256 balance);
 
     
    function transfer(address _to, uint256 _value) public returns (bool success);
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract GTO is ERC20Interface {
    uint8 public constant decimals = 5;

    string public constant symbol = "GTO";
    string public constant name = "GTO";

    bool public _selling = false; 
    uint256 public _totalSupply = 10 ** 14;  
    uint256 public _originalBuyPrice = 45 * 10**7;  

     
    address public owner;
 
     
    mapping(address => uint256) private balances;
    
     
    mapping(address => mapping (address => uint256)) private allowed;

     
    mapping(address => bool) private approvedInvestorList;
    
     
    mapping(address => uint256) private deposit;
    
     
    address[] private buyers;
    
     
    uint8 public _icoPercent = 10;
    
     
    uint256 public _icoSupply = _totalSupply * _icoPercent / 100;
    
     
    uint256 public _minimumBuy = 3 * 10 ** 17;
    
     
    uint256 public _maximumBuy = 30 * 10 ** 18;
    
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onSale() {
        require(_selling && (_icoSupply > 0) );
        _;
    }
    
     
    modifier validInvestor() {
        require(approvedInvestorList[msg.sender]);
        _;
    }
    
     
    modifier validValue(){
         
        require ( (msg.value >= _minimumBuy) &&
                ( (deposit[msg.sender] + msg.value) <= _maximumBuy) );
        _;
    }
    
     
    modifier validRange(uint256 a, uint256 b){
        require ( (a>=0 && a<=b) &&
                  (b<buyers.length) );
        _;
    }

     
    function()
        public
        payable {
        buyGifto();
    }
    
     
    function buyGifto()
        public
        payable
        onSale
        validValue
        validInvestor {
         
        if (deposit[msg.sender] == 0){
             
            buyers.push(msg.sender);
        }
         
        deposit[msg.sender] += msg.value;
         
        owner.transfer(msg.value);
    }

     
    function GTO() 
        public {
        owner = msg.sender;
         
        balances[owner] = _totalSupply;
        Transfer(0x0, owner, _totalSupply);
    }
    
     
     
    function totalSupply()
        public 
        constant 
        returns (uint256) {
        return _totalSupply;
    }
    
     
    function turnOnSale() onlyOwner 
        public {
        _selling = true;
    }

     
    function turnOffSale() onlyOwner 
        public {
        _selling = false;
    }
    
     
     
    function setIcoPercent(uint8 newIcoPercent)
        public 
        onlyOwner {
        _icoPercent = newIcoPercent;
        _icoSupply = _totalSupply * _icoPercent / 100;
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
         
         
         
         
        _maximumBuy = 10**18 * 10000000000 /_originalBuyPrice;
    }
        
     
     
     
    function balanceOf(address _addr) 
        public
        constant 
        returns (uint256) {
        return balances[_addr];
    }
    
     
     
    function isApprovedInvestor(address _addr)
        public
        constant
        returns (bool) {
        return approvedInvestorList[_addr];
    }
    
     
    function getBuyers()
    public
    constant
    returns(address[]){
        return buyers;
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
    
     
     
     
    function deliveryToken(uint256 a, uint256 b)
        public
        onlyOwner
        validRange(a, b) {
         
        require(balances[owner] >= _icoSupply);
        for (uint256 i = a; i <= b; i++){
            if(approvedInvestorList[buyers[i]]){
                 
                uint256 requestedUnits = (deposit[buyers[i]] * _originalBuyPrice) / 10**18;
                
                 
                if(requestedUnits <= _icoSupply && requestedUnits > 0 ){
                     
                    balances[owner] -= requestedUnits;
                    balances[buyers[i]] += requestedUnits;
                    _icoSupply -= requestedUnits;
                    
                     
                    Transfer(owner, buyers[i], requestedUnits);
                    
                     
                    deposit[buyers[i]] = 0;
                }
            }
        }
    }
 
     
     
     
     
    function transfer(address _to, uint256 _amount)
        public 
        returns (bool) {
         
         
         
        if ( (balances[msg.sender] >= _amount) &&
             (_amount >= 0) && 
             (balances[_to] + _amount > balances[_to]) ) {  

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
    public
    returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
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
        CoinCreation(new GTO());
        flag = false;
    }
}