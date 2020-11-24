 

pragma solidity ^0.5.8;


 
library SafeMath {

   
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

}


 
contract Ownable {
    address payable private _owner;

     
    constructor() public {
        _owner = msg.sender;
    }

     
    function owner() public view returns(address payable) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}



 
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address tokenOwner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 value
    );
}

contract LTLNN is ERC20, Ownable {
    using SafeMath for uint256;

    string public name = "Lawtest Token";
    string public symbol ="LTLNN";
    uint8  public decimals = 2;

    uint256 initialSupply = 5000000;
    uint256 saleBeginTime = 1557824400;  
    uint256 saleEndTime = 1557835200;    
    uint256 tokensDestructTime = 1711929599;   
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint)) _allowed;
    uint256 private _totalSupply;
    uint256 private _amountForSale;

    event Mint(address indexed to, uint256 amount, uint256 amountForSale);
    event TokensDestroyed();

    constructor() public {
        _balances[address(this)] = initialSupply;
        _amountForSale = initialSupply;
        _totalSupply = initialSupply;
    }

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function amountForSale() public view returns (uint256) {
        return _amountForSale;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function transfer(address to, uint256 amount) external returns (bool) {
        require(block.timestamp < tokensDestructTime);
        require(block.timestamp > saleEndTime);
        _transfer(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

     
    function approve(address spender, uint256 value) external returns (bool) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(to != address(0));
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        _balances[from] = _balances[from].sub(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

     
    function allowance(address tokenOwner, address spender) external view returns (uint256) {
        return _allowed[tokenOwner][spender];
    }

     
    function mint(address account, uint256 amount) external onlyOwner {
        require(saleBeginTime < block.timestamp);
        require(saleEndTime > block.timestamp);
        _transfer(address(this),  account, amount);
        emit Mint(account, amount, _amountForSale);
    }

     

    function destructContract() external onlyOwner {
        selfdestruct(owner());
    }

     
    function _transfer(address from, address to, uint256 amount) internal {
        require(amount <= _balances[from]);
        require(to != address(0));
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        if(saleEndTime > block.timestamp)
            _amountForSale = _balances[address(this)];
    }

    function hasSaleBeginTimeCome() public view returns(bool) {
        return (block.timestamp > saleBeginTime);
    }

    function hasSaleEndTimeCome() public view returns(bool) {
        return (block.timestamp > saleEndTime);
    }

    function hasTokensDestructTimeCome() public view returns(bool) {
        return (block.timestamp > tokensDestructTime);
    }

}