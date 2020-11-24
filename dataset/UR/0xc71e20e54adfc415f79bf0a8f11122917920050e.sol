 

pragma solidity ^0.5.2;
 
 

 
 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
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



 
 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         

        require(address(token).isContract());

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) {  
            require(abi.decode(returndata, (bool)));
        }
    }
}
 
 
 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}
 
 
 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 
 
 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor (address Owner) internal {
        _owner = Owner;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
     
     
     
     

     
     
     
     

     
     
     
     
     
     
}

 
 
 
contract LockerPool is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public lockMonths;

    uint256 public INITIAL_LOCK_AMOUNT;

    uint256 public lockDays;
    uint256 public lockDaysTime;

    modifier checkBeneficiaryExist(address _addr) {
        require(beneficiaryList.length-1 != 0);
        require(userBeneficiaryMap[_addr] != 0);
        require(beneficiaryList[userBeneficiaryMap[_addr]].beneficiaryAddr == _addr);
        _;
    }

    function balanceOfPool() public view returns (uint256){
        return token.balanceOf(address(this));
    }

    function getRemainAmount() public view returns (uint256) {
        return INITIAL_LOCK_AMOUNT.sub(getAllocatedAmount());
    }

    function totalBeneficiaryCount() public view returns (uint256) {
        return beneficiaryList.length-1;
    }

    function getAllocatedAmount() public view returns (uint256){
        uint256 _beneficiaryCount = beneficiaryList.length;
        uint256 totalValue;
        for (uint256 i=1; i < _beneficiaryCount; i++) {  
            totalValue = totalValue.add(beneficiaryList[i].initialAmount);
        }
        return totalValue;
    }

    function _checkIsReleasable(address addr, uint256 releasingPointId) internal view returns(bool){
        if (beneficiaryList[userBeneficiaryMap[addr]].releasingPointStateList[releasingPointId] == false &&
            now >= beneficiaryList[userBeneficiaryMap[addr]].releasingPointDateList[releasingPointId]) {
                return true;
        }
        else{
            return false;
        }
    }

    function checkIsReleasableById(uint256 id, uint256 releasingPointId) internal view returns(bool){
        if (beneficiaryList[id].releasingPointStateList[releasingPointId] == false &&
            now >= beneficiaryList[id].releasingPointDateList[releasingPointId]) {
                return true;
        }
        else{
            return false;
        }
    }

    function getUnlockedAmountPocket(address addr) public checkBeneficiaryExist(addr) view returns (uint256) {

        uint256 totalValue;
        for (uint256 i=0; i < lockMonths; i++) {

            if (_checkIsReleasable(addr, i)){
                totalValue = totalValue.add(beneficiaryList[userBeneficiaryMap[addr]].releasingPointValueList[i]);
            }
        }
        return totalValue;
    }

    function getTransferCompletedAmount() public view returns (uint256) {
        uint256 _beneficiaryCount = beneficiaryList.length;
        uint256 totalValue;
        for (uint256 i=1; i < _beneficiaryCount; i++) {  
            totalValue = totalValue.add(beneficiaryList[i].transferCompletedAmount);
        }
        return totalValue;
    }

    function getReleasingPoint(uint256 beneficiaryId, uint256 index) public view returns (uint256 _now, uint256 date, uint256 value, bool state, bool releasable){
        return (now, beneficiaryList[beneficiaryId].releasingPointDateList[index], beneficiaryList[beneficiaryId].releasingPointValueList[index], beneficiaryList[beneficiaryId].releasingPointStateList[index], checkIsReleasableById(beneficiaryId, index));
    }

    event AllocateLockupToken(address indexed beneficiaryAddr, uint256 initialAmount, uint256 lockupPeriodStartDate, uint256 releaseStartDate, uint256 releaseEndDate, uint256 id);

    struct Beneficiary {
        uint256 id;
        address beneficiaryAddr;
        uint256 initialAmount;
        uint256 transferCompletedAmount;
        uint256 lockupPeriodStartDate;   
        uint256 releaseStartDate;  
        uint256[] releasingPointDateList;
        uint256[] releasingPointValueList;
        bool[] releasingPointStateList;
        uint256 releaseEndDate;
        uint8 bType;
    }

    Beneficiary[] public beneficiaryList;
    mapping (address => uint256) public userBeneficiaryMap;
     
    constructor (uint256 _lockMonths, uint256 _lockAmount, address poolOwner, address tokenAddr) public Ownable(poolOwner){
        require(36 >= _lockMonths);  
        token = IERC20(tokenAddr);
        lockMonths = _lockMonths;
        INITIAL_LOCK_AMOUNT = _lockAmount;
        lockDays = lockMonths * 30;   
        lockDaysTime = lockDays * 60 * 60 * 24;  
        beneficiaryList.length = beneficiaryList.length.add(1);  
    }

    function allocateLockupToken(address _beneficiaryAddr, uint256 amount, uint8 _type) onlyOwner public returns (uint256 _beneficiaryId) {
        require(userBeneficiaryMap[_beneficiaryAddr] == 0);   
        require(getRemainAmount() >= amount);
        Beneficiary memory beneficiary = Beneficiary({
            id: beneficiaryList.length,
            beneficiaryAddr: _beneficiaryAddr,
            initialAmount: amount,
            transferCompletedAmount: 0,
            lockupPeriodStartDate: uint256(now),  
            releaseStartDate: uint256(now).add(lockDaysTime),
            releasingPointDateList: new uint256[](lockMonths),  
            releasingPointValueList: new uint256[](lockMonths),
            releasingPointStateList: new bool[](lockMonths),
            releaseEndDate: 0,
            bType: _type
            });

        beneficiary.releaseEndDate = beneficiary.releaseStartDate.add(lockDaysTime);
        uint256 remainAmount = beneficiary.initialAmount;
        for (uint256 i=0; i < lockMonths; i++) {
            beneficiary.releasingPointDateList[i] = beneficiary.releaseStartDate.add(lockDaysTime.div(lockMonths).mul(i.add(1)));
            beneficiary.releasingPointStateList[i] = false;
            if (i.add(1) != lockMonths){
                beneficiary.releasingPointValueList[i] = uint256(beneficiary.initialAmount.div(lockMonths));
                remainAmount = remainAmount.sub(beneficiary.releasingPointValueList[i]);
            }
            else{
                beneficiary.releasingPointValueList[i] = remainAmount;
            }
        }

        beneficiaryList.push(beneficiary);
        userBeneficiaryMap[_beneficiaryAddr] = beneficiary.id;

        emit AllocateLockupToken(beneficiary.beneficiaryAddr, beneficiary.initialAmount, beneficiary.lockupPeriodStartDate, beneficiary.releaseStartDate, beneficiary.releaseEndDate, beneficiary.id);
        return beneficiary.id;
    }
    event Claim(address indexed beneficiaryAddr, uint256 indexed beneficiaryId, uint256 value);
    function claim () public checkBeneficiaryExist(msg.sender) returns (uint256) {
        uint256 unlockedAmount = getUnlockedAmountPocket(msg.sender);
        require(unlockedAmount > 0);

        uint256 totalValue;
        for (uint256 i=0; i < lockMonths; i++) {
            if (_checkIsReleasable(msg.sender, i)){
                beneficiaryList[userBeneficiaryMap[msg.sender]].releasingPointStateList[i] = true;
                totalValue = totalValue.add(beneficiaryList[userBeneficiaryMap[msg.sender]].releasingPointValueList[i]);
            }
        }
        require(unlockedAmount == totalValue);
        token.safeTransfer(msg.sender, totalValue);
        beneficiaryList[userBeneficiaryMap[msg.sender]].transferCompletedAmount = beneficiaryList[userBeneficiaryMap[msg.sender]].transferCompletedAmount.add(totalValue);
        emit Claim(beneficiaryList[userBeneficiaryMap[msg.sender]].beneficiaryAddr, beneficiaryList[userBeneficiaryMap[msg.sender]].id, totalValue);
        return totalValue;
    }
}

 
 
 
contract ToriToken is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 4000000000 * (10 ** uint256(DECIMALS));

    uint256 public remainReleased = INITIAL_SUPPLY;

    address private _owner;

     
    address public initialSale = 0x4dEF0A02D30cdf62AB6e513e978dB8A58ed86B53;
    address public saleCPool = 0xF3963A437E0e156e8102414DE3a9CC6E38829ea1;
    address public ecoPool = 0xf6e25f35C3c5cF40035B7afD1e9F5198594f600e;
    address public reservedPool = 0x557e4529D5784D978fCF7A5a20a184a78AF597D5;
    address public marketingPool = 0xEeE05AfD6E1e02b6f86Dd1664689cC46Ab0D7B20;

    uint256 public initialSaleAmount = 600000000 ether;
    uint256 public saleCPoolAmount = 360000000 ether;
    uint256 public ecoPoolAmount = 580000000 ether;
    uint256 public reservedPoolAmount = 600000000 ether;
    uint256 public marketingPoolAmount = 80000000 ether;

     
    address public saleBPoolOwner = 0xB7F1ea2af2a9Af419F093f62bDD67Df914b0ff2E;
    address public airDropPoolOwner = 0x590d6d6817ed53142BF69F16725D596dAaE9a6Ce;
    address public companyPoolOwner = 0x1b0E91D484eb69424100A48c74Bfb450ea494445;
    address public productionPartnerPoolOwner = 0x0c0CD85EA55Ea1B6210ca89827FA15f9F10D56F6;
    address public advisorPoolOwner = 0x68F0D15D17Aa71afB14d72C97634977495dF4d0E;
    address public teamPoolOwner = 0x5A353e276F68558bEA884b13017026A6F1067951;

    uint256 public saleBPoolAmount = 420000000 ether;
    uint256 public airDropPoolAmount = 200000000 ether;
    uint256 public companyPoolAmount = 440000000 ether;
    uint256 public productionPartnerPoolAmount = 200000000 ether;
    uint256 public advisorPoolAmount = 120000000 ether;
    uint256 public teamPoolAmount = 400000000 ether;

    uint8 public saleBPoolLockupPeriod = 12;
    uint8 public airDropPoolLockupPeriod = 3;
    uint8 public companyPoolLockupPeriod = 12;
    uint8 public productionPartnerPoolLockupPeriod = 6;
    uint8 public advisorPoolLockupPeriod = 12;
    uint8 public teamPoolLockupPeriod = 24;

    LockerPool public saleBPool;
    LockerPool public airDropPool;
    LockerPool public companyPool;
    LockerPool public productionPartnerPool;
    LockerPool public advisorPool;
    LockerPool public teamPool;

    bool private _deployedOuter;
    bool private _deployedInner;

    function deployLockersOuter() public {
        require(!_deployedOuter);
        saleBPool = new LockerPool(saleBPoolLockupPeriod, saleBPoolAmount, saleBPoolOwner, address(this));
        airDropPool = new LockerPool(airDropPoolLockupPeriod, airDropPoolAmount, airDropPoolOwner, address(this));
        productionPartnerPool = new LockerPool(productionPartnerPoolLockupPeriod, productionPartnerPoolAmount, productionPartnerPoolOwner, address(this));
        _deployedOuter = true;
        _mint(address(saleBPool), saleBPoolAmount);
        _mint(address(airDropPool), airDropPoolAmount);
        _mint(address(productionPartnerPool), productionPartnerPoolAmount);
    }

    function deployLockersInner() public {
        require(!_deployedInner);
        companyPool = new LockerPool(companyPoolLockupPeriod, companyPoolAmount, companyPoolOwner, address(this));
        advisorPool = new LockerPool(advisorPoolLockupPeriod, advisorPoolAmount, advisorPoolOwner, address(this));
        teamPool = new LockerPool(teamPoolLockupPeriod, teamPoolAmount, teamPoolOwner, address(this));
        _deployedInner = true;
        _mint(address(companyPool), companyPoolAmount);
        _mint(address(advisorPool), advisorPoolAmount);
        _mint(address(teamPool), teamPoolAmount);
    }

    constructor () public ERC20Detailed("Storichain", "TORI", DECIMALS) {
        _mint(address(initialSale), initialSaleAmount);
        _mint(address(saleCPool), saleCPoolAmount);
        _mint(address(ecoPool), ecoPoolAmount);
        _mint(address(reservedPool), reservedPoolAmount);
        _mint(address(marketingPool), marketingPoolAmount);
        _deployedOuter = false;
        _deployedInner = false;
    }
}