 

pragma solidity ^0.5.0;




 
 
 
 

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
 
 
 
pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");

        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}



 
 
 
 


 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

 
 
 
 


 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}



 
 
 
 
pragma solidity ^0.5.0;

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}


 
 
 
contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}


 
 
 
contract LockerRole {
    using Roles for Roles.Role;

    event LockerAdded(address indexed account);
    event LockerRemoved(address indexed account);

    Roles.Role private _lockers;

    constructor () internal {
        _addLocker(msg.sender);
    }

    modifier onlyLockers() {
        require(isLocker(msg.sender), "LockersRole: caller does not have the Locker role");
        _;
    }

    function isLocker(address account) public view returns (bool) {
        return _lockers.has(account);
    }

    function addLocker(address account) public onlyLockers {
        _addLocker(account);
    }

    function renounceLockers() public {
        _removeLocker(msg.sender);
    }

    function _addLocker(address account) internal {
        _lockers.add(account);
        emit LockerAdded(account);
    }

    function _removeLocker(address account) internal {
        _lockers.remove(account);
        emit LockerRemoved(account);
    }
}


 
 
 
contract AdminRole{
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    constructor () internal {
        _addAdmin(msg.sender);
    }

    modifier onlyAdmins() {
        require(isAdmin(msg.sender), "AdminRole: caller does not have the Admin role");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyAdmins {
        _addAdmin(account);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}


 
 
 
 
contract Pausable is PauserRole {
     
    event Paused(address account);

     
    event Unpaused(address account);

    bool private _paused;

     
    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


 
 
 
 
contract Lockable is LockerRole {
     
    event Locked(address account);

     
    event Unlocked(address account);

    mapping (uint64=>address) private _locked;    

     
    constructor () internal {
        
    }

     
    function locked() public view returns (bool) {
        return (_locked[uint64(msg.sender)]==msg.sender);
    }
    
      
    function lockedByAddr(address _addr) public view returns (bool) {
        return (_locked[uint64(_addr)]==_addr);
    }

     
    modifier whenNotLocked() {
        require(_locked[uint64(msg.sender)]!=msg.sender, "Lockable: locked");
        _;
    }

     
    modifier whenLocked() {
        require(_locked[uint64(msg.sender)]!=msg.sender, "Lockable: not locked");
        _;
    }

     
    function lock(address _addr) public onlyLockers {
        _locked[uint64(_addr)] = _addr;
        emit Locked(_addr);
    }

     
    function unlock(address _addr) public onlyLockers {
        _locked[uint64(_addr)] = address(0);
        emit Unlocked(_addr);
    }
}



 
 
 
 

 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
    
     
    function transferFromThisByMint(address recipient, uint256 amount) public onlyMinter returns (bool) {
        address sender = address (this);
        _transfer(sender, recipient, amount);
        return true;
    }
}


 
 
 

 
 
contract ERC20Pausable is ERC20Mintable, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
    
    function mint(address account, uint256 amount) public whenNotPaused returns (bool) {
        return super.mint(account, amount);
    }
    
    function transferFromThisByMint(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        return super.transferFromThisByMint(recipient, amount);
    }
}


 
 
 

 
 
contract ERC20Lockable is ERC20Pausable, Lockable {
    function transfer(address to, uint256 value) public whenNotLocked returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotLocked returns (bool) {
        require(!lockedByAddr(from), 'Locable: from locked');
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotLocked returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotLocked returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotLocked returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
    
    function mint(address account, uint256 amount) public whenNotLocked returns (bool) {
        return super.mint(account, amount);
    }
    
    function transferFromThisByMint(address recipient, uint256 amount) public whenNotLocked returns (bool) {
        return super.transferFromThisByMint(recipient, amount);
    }
}

 
 
 
 

 
 
contract ERC20Detailed{
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



 
 
 
interface IPiramid{
    
    function getFullSumPay() external view returns(uint retSum) ;
    
    function checkPresentAddr(address _addr) external view returns(bool _retPresent) ;
    
    function checkComplitePay(address _addr) external view returns(bool _retPresent) ;
    
    function checkCompliteGenerateTable(address _addr) external view returns(bool _retPresent) ;
    
    function getNeadPaymentCount(address _addr) external view returns (int _countNead) ;
    
    function getNeadPaymentAddr(address _addr, int _pos) external view returns (address _NeadAddr) ;
    
    function getNeadPaymentSum(address _addr, int _pos) external view returns (uint _NeadAddr) ;
    
    function setComlitePay(address _addr) external ;
    
    function addPayment(address _addrParent, address _addrPayer, int _idPartner) external payable returns(address _realposition) ;
    
}




 
 
 
 


 
contract HelpYourSelfToken is ERC20Lockable, ERC20Detailed, AdminRole  {
    
    string private CONFIG_NAME = "Help YourSelf Token";
    string private CONFIG_SYMBOL = "HYST";
    uint8 private CONFIG_DECEMALS = 18;
    address payable private OWNER;
    
    mapping (string=>IPiramid) Piramids;
    
    constructor () public ERC20Detailed(CONFIG_NAME, CONFIG_SYMBOL, CONFIG_DECEMALS) {
         
        OWNER = msg.sender;
    }
    
    function () external payable {
        
        if(msg.value>0){
            OWNER.transfer(address(this).balance);
        }
    }
    
    function setNewAddressPir(string memory _namepirm, address _account) public onlyAdmins {
        
        Piramids[_namepirm] = IPiramid(_account);
    }
    
    function getAddreesPir(string memory _namepir) public view returns (address AddressPiramid){
        
        return address(Piramids[_namepir]);
    }
    
    
    function setOwner(address payable _addr) public payable onlyAdmins {
        
        OWNER = _addr;
    }
    
    function getOwner() public view returns (address _owner){
        
        _owner = OWNER;
    }
    
    function transferETH(uint amount) public onlyAdmins returns (bool success) {
        
        if(amount>0){
            OWNER.transfer(amount);
        }
        success = true;
    }
    
    function GameOver() public onlyAdmins payable {
        selfdestruct(OWNER);
    }
        
    
    function transferAnyERC20Token(IERC20 tokenAddress, address toaddr, uint tokens) public onlyAdmins returns (bool success) {
        return IERC20(tokenAddress).transfer(toaddr, tokens);
    }
    
    
    function pirGetFullSumPay(string memory _namepir) public returns(uint retSum){
        
        bytes memory data = abi.encodeWithSelector(Piramids[_namepir].getFullSumPay.selector);
        (bool success, bytes memory returndata) = address(Piramids[_namepir]).call(data);
        require(success, "PiramidV3.getFullSumPay: low-level call failed");

        if (returndata.length > 0) {  
            return abi.decode(returndata, (uint));
        }
    }
    
    function pirCheckPresentAddr(string memory _namepir, address account) public returns (bool result){
        
        bytes memory data = abi.encodeWithSelector(Piramids[_namepir].checkPresentAddr.selector, account);
        (bool success, bytes memory returndata) = address(Piramids[_namepir]).call(data);
        require(success, "PiramidV3.checkPresentAddr: low-level call failed");

        if (returndata.length > 0) {  
            return abi.decode(returndata, (bool));
        }
    }
    
    function pirCheckComplitePay(string memory _namepir, address Pretendent) public returns (bool result){
        
        bytes memory data = abi.encodeWithSelector(Piramids[_namepir].checkComplitePay.selector, Pretendent);
        (bool success, bytes memory returndata) = address(Piramids[_namepir]).call(data);
        require(success, "PiramidV3.checkComplitePay: low-level call failed");

        if (returndata.length > 0) {  
            return abi.decode(returndata, (bool));
        }
    }
    
    function pirCheckCompliteGenerateTable(string memory _namepir, address Pretendent) public returns (bool result){
        
        bytes memory data = abi.encodeWithSelector(Piramids[_namepir].checkCompliteGenerateTable.selector, Pretendent);
        (bool success, bytes memory returndata) = address(Piramids[_namepir]).call(data);
        require(success, "PiramidV3.checkCompliteGenerateTable: low-level call failed");

        if (returndata.length > 0) {  
            return abi.decode(returndata, (bool));
        }
    }
    
    function pirGetNeadPaymentCount(string memory _namepir, address Pretendent) public returns (int countpos){
        
        bytes memory data = abi.encodeWithSelector(Piramids[_namepir].getNeadPaymentCount.selector, Pretendent);
        (bool success, bytes memory returndata) = address(Piramids[_namepir]).call(data);
        require(success, "PiramidV3.getNeadPaymentCount: low-level call failed");

        if (returndata.length > 0) {  
            return abi.decode(returndata, (int));
        }
    }
    
    function pirGetNeadPaymentAddr(string memory _namepir, address Pretendent, int pos) public returns (address account){
        
        bytes memory data = abi.encodeWithSelector(Piramids[_namepir].getNeadPaymentAddr.selector, Pretendent, pos);
        (bool success, bytes memory returndata) = address(Piramids[_namepir]).call(data);
        require(success, "PiramidV3.getNeadPaymentAddr: low-level call failed");

        if (returndata.length > 0) {  
            return abi.decode(returndata, (address));
        }
    }
    
    function pirGetNeadPaymentSum(string memory _namepir, address Pretendent, int pos) public returns (uint sum){
        
        bytes memory data = abi.encodeWithSelector(Piramids[_namepir].getNeadPaymentSum.selector, Pretendent, pos);
        (bool success, bytes memory returndata) = address(Piramids[_namepir]).call(data);
        require(success, "PiramidV3.getNeadPaymentSum: low-level call failed");

        if (returndata.length > 0) {  
            return abi.decode(returndata, (uint));
        }
    }
    
    function pirSetComlitePay(string memory _namepir, address Pretendent) public {
        
        bytes memory data = abi.encodeWithSelector(Piramids[_namepir].setComlitePay.selector, Pretendent);
        (bool success, bytes memory returndata) = address(Piramids[_namepir]).call(data);
        require(success, "PiramidV3.setComlitePay: low-level call failed");

        if (returndata.length > 0) {  
             
        }
    }
    
    function pirEndPayRescue(string memory _namepir, address Pretendent) public payable {
        require(pirGetFullSumPay(_namepir)<=balanceOf(msg.sender), 'You have small balance.');
        require(pirCheckCompliteGenerateTable(_namepir, Pretendent), 'Table not generated at this address');
        require(!pirCheckComplitePay(_namepir, Pretendent), 'Already complite pay');
        int PosPay = pirGetNeadPaymentCount(_namepir, Pretendent);
        for(int i=1; i<=PosPay; i++){
            address PayAddr = pirGetNeadPaymentAddr(_namepir, Pretendent, i);
            uint PaySum = pirGetNeadPaymentSum(_namepir, Pretendent, i);
            transfer(PayAddr, PaySum);
        }
        pirSetComlitePay(_namepir, Pretendent);
    }
    
    function pirStart(string memory _namepir, address Parent, address Pretendent, int Partner) public payable returns(address _realposition){
        
        require(pirGetFullSumPay(_namepir)<=balanceOf(msg.sender), 'You have small balance.');
        require(!pirCheckPresentAddr(_namepir, Pretendent), 'Pretendent address already added');
        require(pirCheckComplitePay(_namepir, Parent), 'Parent address not complite');
        
        bytes memory data = abi.encodeWithSelector(Piramids[_namepir].addPayment.selector, Parent, Pretendent, Partner);
        (bool success, bytes memory returndata) = address(Piramids[_namepir]).call(data);
        require(success, "PiramidV3.addPayment: low-level call failed");
        if (returndata.length > 0) {
            _realposition = abi.decode(returndata, (address));
        }
        pirEndPayRescue(_namepir, Pretendent);
    }
    
    function pirStartMe(string memory _namepir, address Parent, int Partner) public payable returns(address _realposition){
        
        _realposition = pirStart(_namepir, Parent, msg.sender, Partner);
    }
    
    
}