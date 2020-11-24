 

pragma solidity ^0.5.0;


contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

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

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is Context, IERC20 {
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
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract Ticket {
    ERC20 token = ERC20(0x00f87271ff78a3de23bb7a6fbd3c7080199f6ae82b);
    address public owner;
    string public ticketId;
    uint256 public tokenBorrow;
    uint256 public tokenBalance;
    uint256 public tokenBack;
    uint256 public tokenGuarantee;
    uint public createDate;
    uint depositCount;
    uint redeemCount;
    address[]  backerAddresses;
    mapping (address => bool) backerAddressesMapping;
    struct order {
        uint redeemPeriod;
        uint256 amount;
        uint redeemDate;
        bool redeemStatus;
        uint256 benifit;
    }
    mapping(address => order[]) public orders;
    event DepositTokenGuarantee(address from, address to, uint256 amount);
    event Deposit(address from, address to, uint256 amount);
    event Withdraw(address from, address to, uint256 amount);
    event Redeem(address from, address to, uint256 amount, uint no);
    event RedeemTo(address from, address to, uint256 amount, uint no);
    constructor(string memory _ticketId,  uint256 _tokenBorrow) public {
        owner = msg.sender;
        ticketId = _ticketId;
        tokenBorrow = _tokenBorrow;
        tokenBalance = _tokenBorrow;
        createDate = now;
    }
    modifier onlyOwner() {
        require (msg.sender == owner, "Only owner");
        _;
    }
    function depositTokenGuarantee (uint256 _amount) public  onlyOwner{
        require(_amount > 0, "Invalid Amount");
        require(token.transferFrom(msg.sender, address(this), _amount), "Insufficient funds");
        tokenGuarantee += _amount;
        emit DepositTokenGuarantee(msg.sender,  address(this), _amount);
    }
    function deposit (uint _redeemPeriod, uint256 _amount)  public  {
        require(tokenBalance > 0, "Ticket complete already");
        require(_amount <= tokenBalance, "Amount too much");
        require(isRedeemPeriod(_redeemPeriod) == true, "Invalid redeemPeriod");
        require(token.transferFrom(msg.sender, address(this), _amount), "Insufficient funds");
        if(backerAddressesMapping[msg.sender] == false){
            backerAddresses.push(msg.sender);
            backerAddressesMapping[msg.sender] = true;
        }
        uint _redeemDate = now + (_redeemPeriod * 86400);
        uint256 benifit = calBenifit(_amount, _redeemPeriod);
        orders[msg.sender].push(order(_redeemPeriod, _amount, _redeemDate, false, benifit));
        tokenBack += _amount;
        tokenBalance = tokenBorrow - tokenBack;
        depositCount++;
        emit Deposit(msg.sender,  address(this), _amount);
    }
    function withdraw() public  onlyOwner{
        uint256 _balances = token.balanceOf(address(this));
        require(_balances > 0, "Insufficient funds");
        require(redeemCount == depositCount, "Can not withdraw during this period");
        token.transfer(owner, _balances);
        emit Withdraw(address(this), owner, _balances);
    }
    function redeem(uint _no) public {
        uint256 _balances = token.balanceOf(address(this));
        require(_balances > 0, "Insufficient funds");
        require(checkOrderRedeem(msg.sender, _no, _balances) == true, "Invalid redeem");
        uint256 _amount = getAmountRedeem(msg.sender, _no);
        token.transfer(msg.sender, _amount);
        redeemCount++;
        orders[msg.sender][_no].redeemStatus = true;
        emit Redeem(address(this), msg.sender, _amount, _no);
    }
    function redeemTo(address _backer, uint _no) public  onlyOwner{
        uint256 _balances = token.balanceOf(address(this));
        require(_balances > 0, "Insufficient funds");
        require(checkOrderRedeem(_backer, _no, _balances) == true, "Invalid redeem");
        uint256 _amount = getAmountRedeem(_backer, _no);
        token.transfer(_backer, _amount);
        redeemCount++;
        orders[_backer][_no].redeemStatus = true;
        emit RedeemTo(address(this), _backer, _amount, _no);
    }
    function checkOrderRedeem(address _backer, uint _no, uint256 balances) internal view returns (bool isRedeem){
        if(orders[_backer].length <= 0 || _no >= orders[_backer].length){
            return false;
        }
        if(orders[_backer][_no].redeemStatus == true || now < orders[_backer][_no].redeemDate || balances < orders[_backer][_no].benifit){
            return false;
        }
        return true;
    }
    function getAmountRedeem(address _backer, uint _no) internal view returns (uint256 _amount){
        return orders[_backer][_no].benifit;
    }
    function getCountOrders(address _backer) public view returns (uint){
        return orders[_backer].length;
    }
    function getAllBacker() public view returns (address[] memory){
        return backerAddresses;
    }
    function balanceOf() public view returns(uint256){
        return token.balanceOf(address(this));
    }
    function isRedeemPeriod(uint _redeemPeriod) internal pure returns (bool _isRedeemPeriod){
        if(_redeemPeriod == 20 || _redeemPeriod == 30 || _redeemPeriod == 50 || _redeemPeriod == 90){
            return true;
        }
        return false;
    }
    function calBenifit(uint256 _amount, uint _redeemPeriod) internal pure returns (uint256 benefit){
        if(_redeemPeriod == 20){
            return _amount + ((_amount * 200) / 10000);
        }
        else if(_redeemPeriod == 30){
            return _amount + ((_amount * 300) / 10000);
        }
        else if(_redeemPeriod == 50){
            return _amount + ((_amount * 500) / 10000);
        }
        else if(_redeemPeriod == 90){
            return _amount + ((_amount * 900) / 10000);
        }
        return 0;
    }
}