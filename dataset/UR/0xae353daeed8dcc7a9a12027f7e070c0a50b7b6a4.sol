 

pragma solidity >=0.4.24 <0.6.0;

 

 
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

contract INX is IERC20{
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    uint256 internal _totalSupply;
    string public _name = "InnovaMinex";
    string public _symbol = "MINX";
    uint8 public _decimals = 6;

    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }

    modifier enoughFunds ( address from, uint256 amount ) {
        require(_balances[from]>=amount);
        _;
    }

    constructor() public {
         
        require(address(this).balance == 0);
        
         
        uint INITIAL_SUPPLY = uint(300000000) * ( uint(10) ** _decimals);
        _totalSupply = INITIAL_SUPPLY;
        _balances[msg.sender] = INITIAL_SUPPLY;
    }


    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view returns (uint) {
        return _decimals;
    }


     
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public validDestination(to) enoughFunds(msg.sender, value) returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function approve(address spender, uint256 value) public validDestination(spender) enoughFunds(msg.sender, value) returns (bool) {
         
         
        require(_allowed[msg.sender][spender] == 0 || value == 0);
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public validDestination(to) enoughFunds(from, value) returns (bool) {
        require(_allowed[from][msg.sender]>=value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public validDestination(spender) returns (bool) {
        require(_allowed[msg.sender][spender] != 0 && addedValue != 0);
        uint finalAllowed = _allowed[msg.sender][spender].add(addedValue);
        require(_balances[msg.sender]>=finalAllowed);
        _allowed[msg.sender][spender] = finalAllowed;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public validDestination(spender) returns (bool) {
        require(_allowed[msg.sender][spender] != 0 && subtractedValue != 0 && subtractedValue < _allowed[msg.sender][spender]);
        uint finalAllowed = _allowed[msg.sender][spender].sub(subtractedValue);
        require(_balances[msg.sender]>=finalAllowed);
        _allowed[msg.sender][spender] = finalAllowed;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) private validDestination(to) enoughFunds(from, value){ 
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

         
    function _burn(address account, uint256 value) private validDestination(account) enoughFunds(account, value) {
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

}