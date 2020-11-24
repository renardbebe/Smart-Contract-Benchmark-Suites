 

pragma solidity >=0.4.24;

 

contract SPO8 {
    using SafeMath for uint256;
    
     
     
    string public companyName;
    string public companyLicenseID;
    string public companyTaxID;
    string public companySecurityID;
    string public companyURL;
    address public CEO;
    string public CEOName;
    address public CFO;
    string public CFOName;
    address public BOD;  
    
    event CEOTransferred(address indexed previousCEO, address indexed newCEO);
    event CEOSuccession(string previousCEO, string newCEO);
    event CFOTransferred(address indexed previousCFO, address indexed newCFO);
    event CFOSuccession(string previousCFO, string newCFO);
    event BODTransferred(address indexed previousBOD, address indexed newBOD);
    
     
    uint256 public threshold;
     
    
     
    
    address[] internal whiteListUser;  
    
     
    struct Infor{
        string userName;
        string phone;
        string certificate;
    }
    
    mapping(address => Infor) internal userInfor;
    
    mapping(address => uint256) internal userPurchasingTime;  
    
    uint256 public transferLimitationTime = 31536000000;  
    
    event UserInforUpdated(address indexed user, string name, string phone, string certificate);
    event NewUserAdded(address indexed newUser);
    event UserRemoved(address indexed user);
    event UserUnlocked(address indexed user);
    event UserLocked(address indexed user);
    event LimitationTimeSet(uint256 time);
    event TokenUnlocked(uint256 time);
     
    
     
    address[] internal saleContracts;
    
    event NewSaleContractAdded(address _saleContractAddress);
    event SaleContractRemoved(address _saleContractAddress);
     
    
     
     
    string public name;
    string public symbol;
    uint256 internal _totalSupply;

    mapping (address => uint256) internal balances;

    mapping (address => mapping (address => uint256)) internal allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BODBudgetApproval(address indexed owner, address indexed spender, uint256 value, address indexed to);
    event AllowanceCanceled(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed from, address indexed to, uint256 totalMint);
     
    
     
    modifier onlyBoss() {
        require(msg.sender == CEO || msg.sender == CFO);
        _;
    }
    
     
    modifier onlyBOD {
        require(msg.sender == BOD);
        _;
    }
    
     
    function changeCEO(address newCEO) public onlyBoss {
        require(newCEO != address(0));
        emit CEOTransferred(CEO, newCEO);
        CEO = newCEO;
    }
    
    function changeCEOName(string newName) public onlyBoss {
        emit CEOSuccession(CEOName, newName);
        CEOName = newName;
    }
    
    function changeCFO(address newCFO) public onlyBoss {
        require(newCFO != address(0));
        emit CEOTransferred(CFO, newCFO);
        CFO = newCFO;
    }
    
    function changeCFOName(string newName) public onlyBoss {
        emit CFOSuccession(CFOName, newName);
        CFOName = newName;
    }
    
    function changeBODAddress(address newBOD) public onlyBoss {
        require(newBOD != address(0));
        emit BODTransferred(BOD, newBOD);
        BOD = newBOD;
    }
    
     
     
    enum TransactionState {
        Fail,
        Success,
        Pending
    }
        
     
    struct Transaction {
        address from;
        address to;
        uint256 value;
        TransactionState state;
        uint256 date;
        address bod;
    }
    
     
    Transaction[] internal specialTransactions;  
    
     
    constructor (uint256 totalSupply_,
                address _CEO, 
                string _CEOName, 
                address _CFO, 
                string _CFOName,
                address _BOD) public {
        name = "Security PO8 Token";
        symbol = "SPO8";
        _totalSupply = totalSupply_;
        companyName = "PO8 Ltd";
        companyTaxID = "IBC";
        companyLicenseID = "No. 203231 B";
        companySecurityID = "qKkFiGP4235d";
        companyURL = "https://po8.io";
        CEO = _CEO;
        CEOName = _CEOName;  
        CFO = _CFO;
        CFOName = _CFOName;  
        BOD = _BOD;
        threshold = (totalSupply_.mul(10)).div(100);  
        balances[CEO] = totalSupply_;
    }
    
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
     
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
    
     
    function mint(uint256 _totalMint) external onlyBoss returns (bool) {
        balances[CEO] += _totalMint;
        _totalSupply += _totalMint;
        threshold = (_totalSupply.mul(10)).div(100);
        
        emit Mint(address(0), CEO, _totalMint);
        
        return true;
    }
    
     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(balances[_to].add(_value) > balances[_to]);
        require(checkWhiteList(_from));
        require(checkWhiteList(_to));
        require(!checkLockedUser(_from));
        
        if(balances[_from] < threshold || msg.sender == CEO || msg.sender == CFO || msg.sender == BOD) {
            uint256 previousBalances = balances[_from].add(balances[_to]);
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(_from, _to, _value);
    
            assert(balances[_from].add(balances[_to]) == previousBalances);
        }
        
        else {
            specialTransfer(_from, _to, _value);  
            emit Transfer(_from, _to, 0);
        }
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
		return true;
    }
    
     
    function specialTransfer(address _from, address _to, uint256 _value) internal returns (bool) {
        specialTransactions.push(Transaction({from: _from, to: _to, value: _value, state: TransactionState.Pending, date: now.mul(1000), bod: BOD}));
        approveToBOD(_value, _to);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0));
        require(_spender != BOD);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
     
    function approveToBOD(uint256 _value, address _to) internal returns (bool) {
        if(allowed[msg.sender][BOD] > 0)
            allowed[msg.sender][BOD] = (allowed[msg.sender][BOD].add(_value));
        else
            allowed[msg.sender][BOD] = _value;
        emit BODBudgetApproval(msg.sender, BOD, _value, _to);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);      
        require(msg.sender != BOD);
        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
     
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        require(_spender != address(0));
        require(_spender != BOD);

        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(_spender != address(0));
        require(_spender != BOD);

        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].sub(_subtractedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
     
    function cancelAllowance(address _from, uint256 _value) internal onlyBOD {
        require(_from != address(0));
        
        allowed[_from][BOD] = allowed[_from][BOD].sub(_value);
        emit AllowanceCanceled(_from, BOD, _value);
    }
    
     
    function addUser(address _newUser) external onlyBoss returns (bool) {
        require (!checkWhiteList(_newUser));
        whiteListUser.push(_newUser);
        emit NewUserAdded(_newUser);
        return true;
    }
    
     
    function addUsers(address[] _newUsers) external onlyBoss returns (bool) {
        for(uint i = 0; i < _newUsers.length; i++)
        {
            whiteListUser.push(_newUsers[i]);
            emit NewUserAdded(_newUsers[i]);
        }
        return true;
    }
    
     
    function totalUsers() public view returns (uint256 users) {
        return whiteListUser.length;
    }
    
     
    function checkWhiteList(address _user) public view returns (bool) {
        uint256 length = whiteListUser.length;
        for(uint i = 0; i < length; i++)
            if(_user == whiteListUser[i])
                return true;
        
        return false;
    }
    
      
    function deleteUser(address _user) external onlyBoss returns (bool) {
        require(checkWhiteList(_user));
        
        uint256 i;
        uint256 length = whiteListUser.length;
        
        for(i = 0; i < length; i++)
        {
            if (_user == whiteListUser[i])
                break;
        }
        
        whiteListUser[i] = whiteListUser[length - 1];
        delete whiteListUser[length - 1];
        whiteListUser.length--;
        
        emit UserRemoved(_user);
        return true;
    }
    
     
    function updateUserInfor(address _user, string _name, string _phone, string _certificate) external onlyBoss returns (bool) {
        require(checkWhiteList(_user));
        
        userInfor[_user].userName = _name;
        userInfor[_user].phone = _phone;
        userInfor[_user].certificate = _certificate;
        emit UserInforUpdated(_user, _name, _phone, _certificate);
        
        return true;
    }
    
     
    function getUserInfor(address _user) public view returns (string, string) {
        require(msg.sender == _user);
        require(checkWhiteList(_user));
        
        Infor memory infor = userInfor[_user];
        
        return (infor.userName, infor.phone);
    }
    
     
    function lockUser(address _user) external returns (bool) {
        require(checkSaleContracts(msg.sender) || msg.sender == CEO || msg.sender == CFO);
        
        userPurchasingTime[_user] = now.mul(1000);
        emit UserLocked(_user);
        
        return true;
    }
    
     
    function unlockUser(address _user) external onlyBoss returns (bool) {
        userPurchasingTime[_user] = 0;
        emit UserUnlocked(_user);
        
        return true;
    }
    
     
    function checkLockedUser(address _user) public view returns (bool) {
        if ((now.mul(1000)).sub(userPurchasingTime[_user]) < transferLimitationTime)
            return true;
        return false;
    }
    
     
    function setLimitationTime(uint256 _time) external onlyBoss returns (bool) {
        transferLimitationTime = _time;
        emit LimitationTimeSet(_time);
        
        return true;
    }
    
     
    function unlockToken() external onlyBoss returns (bool) {
        transferLimitationTime = 0;
        emit TokenUnlocked(now.mul(1000)); 
        return true;
    }
    
     
    function getSpecialTxInfor(uint256 _index) public view returns (address from, 
                                                                            address to,
                                                                            uint256 value, 
                                                                            TransactionState state, 
                                                                            uint256 date, 
                                                                            address bod) {
        Transaction storage txInfor = specialTransactions[_index];
        return (txInfor.from, txInfor.to, txInfor.value, txInfor.state, txInfor.date, txInfor.bod);
    }
    
     
    function getTotalPendingTxs() internal view returns (uint32) {
        uint32 count;
        TransactionState txState = TransactionState.Pending;
        for(uint256 i = 0; i < specialTransactions.length; i++) {
            if(specialTransactions[i].state == txState)
                count++;
        }
        return count;
    }
    
     
    function getPendingTxIDs() public view returns (uint[]) {
        uint32 totalPendingTxs = getTotalPendingTxs();
        uint[] memory pendingTxIDs = new uint[](totalPendingTxs);
        uint32 id = 0;
        TransactionState txState = TransactionState.Pending;
        for(uint256 i = 0; i < specialTransactions.length; i++) {
            if(specialTransactions[i].state == txState) {
                pendingTxIDs[id] = i;
                id++;
            }
        }
        return pendingTxIDs;
    }
    
     
    function handlePendingTx(uint256 _index, bool _decision) public onlyBOD returns (bool) {
        Transaction storage txInfo = specialTransactions[_index];
        require(txInfo.state == TransactionState.Pending);
        require(txInfo.bod == BOD);
        
        if(_decision) {
            require(txInfo.value <= allowed[txInfo.from][BOD]);
            
            allowed[txInfo.from][BOD] = allowed[txInfo.from][BOD].sub(txInfo.value);
            _transfer(txInfo.from, txInfo.to, txInfo.value);
            txInfo.state = TransactionState.Success;
        }
        else {
            txInfo.state = TransactionState.Fail;
            cancelAllowance(txInfo.from, txInfo.value);
        }
        return true;
    }
    
     
    function checkSaleContracts(address _saleContract) public view returns (bool) {
        uint256 length = saleContracts.length;
        for(uint i = 0; i < length; i++) {
            if(saleContracts[i] == _saleContract)
                return true;
        }
        return false;
    }
    
     
    function addNewSaleContract(address _newSaleContract) external onlyBoss returns (bool) {
        require(!checkSaleContracts(_newSaleContract));
        
        saleContracts.push(_newSaleContract);
        emit NewSaleContractAdded(_newSaleContract);
        
        return true;
    }
    
     
    function removeSaleContract(address _saleContract) external onlyBoss returns (bool) {
        require(checkSaleContracts(_saleContract));
        
        uint256 length = saleContracts.length;
        uint256 i;
        for(i = 0; i < length; i++) {
            if(saleContracts[i] == _saleContract)
                break;
        }
        
        saleContracts[i] = saleContracts[length - 1];
        delete saleContracts[length - 1];
        saleContracts.length--;
        emit SaleContractRemoved(_saleContract);
        
        return true;
    }
    
     
    function () public payable {
        revert();
    }
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
    
        uint256 c = a * b;
        require(c / a == b);
    
        return c;
    }
    
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         
        require(a == b * c);
    
        return c;
    }
    
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
    
        return c;
    }
    
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
    
        return c;
    }
    
     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}