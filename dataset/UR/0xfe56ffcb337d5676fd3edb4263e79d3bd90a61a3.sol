 

pragma solidity >0.4.99 <0.6.0;

 
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

 
contract IERC20 {
    function transfer(address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Withdraw(address indexed account, uint256 value);
}


 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    mapping(address => uint256) private dividendBalanceOf;

    mapping(address => uint256) private dividendCreditedTo;

    uint256 private _dividendPerToken;

    uint256 private _totalSupply;

    uint256 private lastBalance;

     
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
        update(msg.sender);
        updateNewOwner(to);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        update(from);
        updateNewOwner(to);
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

    function updateDividend() public  returns (bool) {
        uint256 newBalance = address(this).balance;
        uint256 lastValue = newBalance.sub(lastBalance);
        _dividendPerToken = _dividendPerToken.add(lastValue.div(_totalSupply));
        lastBalance = newBalance;
        return true;
    }

    function viewMyDividend() public view  returns (uint256) {
        return dividendBalanceOf[msg.sender];
    }

    function withdraw() public payable {
        require(msg.value == 0);
        update(msg.sender);
        uint256 amount = dividendBalanceOf[msg.sender];
        if (amount <= address(this).balance) {
            dividendBalanceOf[msg.sender] = 0;
            emit Withdraw(msg.sender, amount);
            msg.sender.transfer(amount);
        }
    }

    function dividendPerToken() public view returns (uint256) {
        return _dividendPerToken;
    }

    function update(address account) public {
        uint256 owed = _dividendPerToken.sub(dividendCreditedTo[account]);
        dividendBalanceOf[account] = dividendBalanceOf[account].add(balanceOf(account).mul(owed));
        dividendCreditedTo[account] = _dividendPerToken;
    }

    function updateNewOwner(address account) internal {
        dividendCreditedTo[account] = _dividendPerToken;
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

contract Token is ERC20, ERC20Detailed {
    using SafeMath for uint256;

    uint8 public constant DECIMALS = 0;

    uint256 public constant INITIAL_SUPPLY = 100 * (10 ** uint256(DECIMALS));

     
    constructor (address owner) public ERC20Detailed("Sunday Lottery", "HAN1", DECIMALS) {
        require(owner != address(0));
        owner = msg.sender;  
        _mint(owner, INITIAL_SUPPLY);
    }

    function() payable external {
        if (msg.value == 0) {
            withdraw();
        }
    }

    function balanceETH() public view returns(uint256) {
        return address(this).balance;
    }

}