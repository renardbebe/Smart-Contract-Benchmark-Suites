 

 
pragma solidity ^0.5.0;

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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract ERC20 is IERC20 {
 
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
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
        _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
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

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances[account] >= value);
        
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

    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(value));
    }
}

contract MyTradingToken is Ownable, ERC20 {
    
    using SafeMath for uint256;

    uint public minInvestment = 0.01 ether;
    uint public loanSize;
    uint public withdrawalSize;
    uint public rate;
    uint public totalInvested;
    address payable public loaner;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    event TokenWithdrawn(address indexed from, uint256 amount);
    event Loan(address indexed loaner, uint256 amount);
    event DebtReturned(address indexed addr, uint256 amount);
    event NewLoaner(address indexed previousLoaner, address indexed newLoaner);

    constructor () public {
        _name = "MyTradingToken";
        _symbol = "MTT";
        _decimals = 18;
        rate = 100;
        loaner = 0x840A4023A0147094321444E74dDC09231A397a8A;
    }

    function buyTokens() public payable {
        require(msg.value > minInvestment, "");

        uint amount = msg.value.mul(rate);
        _buyTokens(msg.sender, amount);
        
        loanSize = loanSize.add(msg.value);
        totalInvested = totalInvested.add(msg.value);
    }
    
    function _buyTokens(address buyer, uint amount) internal {
        _mint(buyer, amount);
    }
    
    function withdraw(uint _tokenAmount) public {
        uint amountToSend = _tokenAmount.div(rate).mul(2);
        
        require(amountToSend <= withdrawalSize, "");
        require(balanceOf(msg.sender) >= _tokenAmount, "");
        
        msg.sender.transfer(amountToSend);
        
        withdrawalSize = withdrawalSize.sub(amountToSend);
        
        _burn(msg.sender, _tokenAmount);
       
         emit TokenWithdrawn(msg.sender, _tokenAmount);
    }
    
    function loan(uint _value) public {
        require(msg.sender == loaner, "");
        require(loanSize >= _value, "");
        
        loaner.transfer(_value);
        loanSize = loanSize.sub(_value);
      
        emit Loan(loaner, _value);
    }

    function returnDebt() public payable {
        withdrawalSize += msg.value;
      
        emit DebtReturned(msg.sender, msg.value);
    }
    
    function setLoaner(address payable _newLoaner) public onlyOwner {
        loaner = _newLoaner;
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

    function getLoanSize() public view returns (uint) {
        return loanSize;
    }

}

library SafeMath {
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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}