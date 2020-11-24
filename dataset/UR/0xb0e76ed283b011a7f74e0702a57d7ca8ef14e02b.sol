 

pragma solidity ^0.5.2;
 
 
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
 
 
contract Ownable {
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
     
    constructor () internal {
        _owner = msg.sender;
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
 
     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
 
     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
 
     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
 
 
interface IERC20 {
    function totalSupply() external view returns (uint256);
 
    function balanceOf(address who) external view returns (uint256);
 
    function allowance(address owner, address spender) external view returns (uint256);
 
    function transfer(address to, uint256 value) external returns (bool);
 
    function approve(address spender, uint256 value) external returns (bool);
 
    function transferFrom(address from, address to, uint256 value) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;
 
    constructor () internal {
         
         
        _guardCounter = 1;
    }
 
     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}
 
 
contract Pausable is Ownable {
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
        require(!_paused);
        _;
    }
 
     
    modifier whenPaused() {
        require(_paused);
        _;
    }
 
     
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }
 
     
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}
 
 
contract ERACoin is IERC20, Ownable, ReentrancyGuard, Pausable  {
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
 
     
    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
 
     
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
 
     
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        require(spender != address(0));
        
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
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
 
     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
 
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _initSupply;
    
    constructor (string memory name, string memory symbol, uint8 decimals, uint256 initSupply) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _initSupply = initSupply.mul(10 **uint256(decimals));
        _mint(msg.sender, _initSupply);
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
    
     
    function initSupply() public view returns (uint256) {
        return _initSupply;
    }
   
   mapping (address => bool) status; 
   
   
    
    address private _walletAdmin; 
    
    address payable _walletBase90;
     
    address payable _walletF5;
     
    address payable _walletS5;
     
     
     
     
    uint256 private _rate;
     
    uint256 private _y;
     
    uint256 private _weiRaised;
     
    uint256 private _MinTokenQty;
     
    uint256 private _MaxTokenAdminQty;
    
    
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }
    
    
    function burn(address to, uint256 value) public onlyOwner returns (bool) {
        _burn(to, value);
        return true;
    }
    
     
    function transferOwner(address to, uint256 value) public onlyOwner returns (bool) {
      
        _transfer(msg.sender, to, value);
        return true;
    }
    
     
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
      
        _transfer(msg.sender, to, value);
        return true;
    }
    
     
    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
      
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }
     
    
    function CheckStatus(address account) public view returns (bool) {
        require(account != address(0));
        bool currentStatus = status[account];
        return currentStatus;
    }
    
     
    function ChangeStatus(address account) public  onlyOwner {
        require(account != address(0));
        bool currentStatus1 = status[account];
       status[account] = (currentStatus1 == true) ? false : true;
    }
 
    
    function () external payable {
        buyTokens(msg.sender, msg.value);
        }
        
    function buyTokens(address beneficiary, uint256 weiAmount) public nonReentrant payable {
        require(beneficiary != address(0) && beneficiary !=_walletBase90 && beneficiary !=_walletF5 && beneficiary !=_walletS5);
        require(weiAmount > 0);
        address _walletTokenSale = owner();
        require(_walletTokenSale != address(0));
        require(_walletBase90 != address(0));
        require(_walletF5 != address(0));
        require(_walletS5 != address(0));
        require(CheckStatus(beneficiary) != true);
         
        uint256 tokens = weiAmount.div(_y).mul(_rate);
         
        uint256 currentMinQty = MinTokenQty();
         
        require(balanceOf(_walletTokenSale) > tokens);
         
        require(tokens >= currentMinQty);
         
        _weiRaised = _weiRaised.add(weiAmount);
         
       _transfer(_walletTokenSale, beneficiary, tokens);
        
       _walletBase90.transfer(weiAmount.div(100).mul(90));
        
       _walletF5.transfer(weiAmount.div(100).mul(5));
        
       _walletS5.transfer(weiAmount.div(100).mul(5));
    }
  
     
    function setRate(uint256 rate) public onlyOwner  {
        require(rate >= 1);
        _rate = rate;
    }
   
     
    function setY(uint256 y) public onlyOwner  {
        require(y >= 1);
        _y = y;
    }
    
     
    function setFundWallets(address payable B90Wallet,address payable F5Wallet,address payable S5Wallet) public onlyOwner  {
        _walletBase90 = B90Wallet;
         _walletF5 = F5Wallet;
         _walletS5 = S5Wallet;
    } 
    
     
    function setWalletB90(address payable B90Wallet) public onlyOwner  {
        _walletBase90 = B90Wallet;
    } 
    
     
    function WalletBase90() public view returns (address) {
        return _walletBase90;
    }
    
     
    function setWalletF5(address payable F5Wallet) public onlyOwner  {
        _walletF5 = F5Wallet;
    } 
    
     
    function WalletF5() public view returns (address) {
        return _walletF5;
    }
    
      
    function setWalletS5(address payable S5Wallet) public onlyOwner  {
        _walletS5 = S5Wallet;
    } 
    
     
    function WalletS5() public view returns (address) {
        return _walletS5;
    }
    
     
    function setWalletAdmin(address WalletAdmin) public onlyOwner  {
        _walletAdmin = WalletAdmin;
    } 
    
      
    function WalletAdmin() public view returns (address) {
        return _walletAdmin;
    }
    
     
    modifier onlyAdmin() {
        require(isAdmin());
        _;
    }
 
     
    function isAdmin() public view returns (bool) {
        return msg.sender == _walletAdmin;
    }
 
     
    function transferAdmin(address to, uint256 value) public onlyAdmin returns (bool) {
        require(value <= MaxTokenAdminQty());
        _transfer(msg.sender, to, value);
        return true;
    }
    
     
    function setMinTokenQty(uint256 MinTokenQty) public onlyOwner  {
        _MinTokenQty = MinTokenQty;
    } 
    
     
    function setMaxTokenAdminQty(uint256 MaxTokenAdminQty) public onlyOwner  {
        _MaxTokenAdminQty = MaxTokenAdminQty;
    } 
    
     
    function Rate() public view returns (uint256) {
        return _rate;
    }
   
     
    function Y() public view returns (uint256) {
        return _y;
    }
    
     
    function WeiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    
     
    function MinTokenQty() public view returns (uint256) {
        return _MinTokenQty;
    }
    
      
    function MaxTokenAdminQty() public view returns (uint256) {
        return _MaxTokenAdminQty;
    }
    
}