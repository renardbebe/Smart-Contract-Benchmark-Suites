 

pragma solidity ^0.5.0;

 
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
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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

contract WallBlockChainCoinToken is ERC20, ERC20Detailed {
    using SafeMath for uint256;
    uint256 private constant totalWB= 210000000 * (10 ** 18);  
    uint256 private constant INITIAL_SUPPLY = 21000000 * (10 ** 18);  
    uint256 private constant FIRST_MONTH_COIN = 8500000 * (10 ** 18);  
    uint private constant MONTHLY_PERCENTAGE = 97;  
    uint256 public quantity = 0;  
    
    mapping(address => uint256) balances;
     
    address public owner;

    uint public startTime;

    mapping(uint=>uint) monthsTimestamp;

    uint[] fibseries;

    uint operatingTime;

    constructor () public ERC20Detailed("Wall Block Chain Coin", "WB", 18) {
        _mint(msg.sender, totalWB);
        owner = msg.sender;
        balances[owner] = totalWB;
        quantity = 0;
        startTime = 1564765200;  
    }
    function runQuantityWB(address _to) public {
        require(msg.sender == owner, "Not contract owner");
        require(totalWB > quantity, "Release stop");

        if(quantity == 0){
            transfer(_to, INITIAL_SUPPLY);
            quantity = INITIAL_SUPPLY;
            balances[owner] = balances[owner] - INITIAL_SUPPLY;
            balances[_to] = INITIAL_SUPPLY;
        }
        if(block.timestamp > startTime){
            operatingTime = block.timestamp - startTime;
            uint256 CURRENCY_WB = INITIAL_SUPPLY;
            uint256 lastMonthCoin = FIRST_MONTH_COIN;
            for (uint i = 1; i <= 36; i++){  
            if(i == 1){
                CURRENCY_WB = CURRENCY_WB;
            }
            else {
                CURRENCY_WB = CURRENCY_WB + lastMonthCoin;
                lastMonthCoin = lastMonthCoin * MONTHLY_PERCENTAGE / 100;
            }
                    if(i * 30 * (60*60*24) > operatingTime){
                        uint256 diffDays = 0;
                        uint256 diffTime = operatingTime - ((i-1) * 30 * (60*60*24));
                        for (uint256 j = 1; j <= 30; j++){
                            if(diffTime < j * (60*60*24)){
                                diffDays = j;
                                break;
                            }
                        }
                        if(operatingTime>0 && diffDays != 0){
                            CURRENCY_WB = CURRENCY_WB + lastMonthCoin * diffDays / 30;
                        }
                         
                        break;
                    }
            }
            if(totalWB >= CURRENCY_WB){
                uint256 wb = CURRENCY_WB - quantity;
                quantity = CURRENCY_WB;
                if(wb > 0){
                    transfer(_to, wb);
                    balances[owner] = balances[owner].sub(wb);
                    balances[_to] = balances[_to].add(wb);
                }
            }
            else {
                uint256 wb = totalWB - quantity;
                if(wb > 0)
                {
                    quantity = totalWB;
                    transfer(_to, wb);
                    balances[owner] = balances[owner] - wb;
                    balances[_to] = balances[_to] + wb;
                }
            }
        }
    }

}