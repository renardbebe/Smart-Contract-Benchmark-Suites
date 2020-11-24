 

pragma solidity 0.4.25;

 
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

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

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

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        require((value == 0) || (_allowed[msg.sender][spender] == 0));

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
}

 
contract ERC20Detailed is ERC20 {
    string private _name = 'Ethereum Message Search';
    string private _symbol = 'EMS';
    uint8 private _decimals = 18;

     
    function name() public view returns (string) {
        return _name;
    }

     
    function symbol() public view returns (string) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract EMS is ERC20Detailed {
    using SafeMath for uint;

    uint private DEC = 1000000000000000000;
    uint public msgCount = 0;

    struct Message {
        bytes data;
        uint sum;
        uint time;
        address addressUser;
    }

    mapping(uint => Message) public messages;

    constructor() public {
        _mint(msg.sender, 5000000 * DEC);
        _mint(address(this), 5000000 * DEC);
    }

    function cost(uint availableTokens) private view returns (uint) {
        if (availableTokens <= 5000000 * DEC && availableTokens > 4000000 * DEC) {
             
            return 1;
        } else if (availableTokens <= 4000000 * DEC && availableTokens > 3000000 * DEC) {
             
            return 2;
        } else if (availableTokens <= 3000000 * DEC && availableTokens > 2000000 * DEC) {
             
            return 3;
        } else if (availableTokens <= 2000000 * DEC && availableTokens > 1000000 * DEC) {
             
            return 4;
        } else if (availableTokens <= 1000000 * DEC) {
             
            return 5;
        }
    }

    function() external payable {
        require(msg.value > 0, "Wrong ETH value");

        uint availableTokens = balanceOf(address(this));

        if (availableTokens > 0) {
            uint tokens = msg.value.mul(100).div(cost(availableTokens));

            if (availableTokens < tokens) tokens = availableTokens;

            _transfer(address(this), msg.sender, tokens);
        }

        messages[msgCount].data = msg.data;
        messages[msgCount].sum = msg.value;
        messages[msgCount].time = now;
        messages[msgCount].addressUser = msg.sender;

        msgCount++;
    }

    function sellTokens(uint tokens) public {
        uint value = address(this).balance.mul(tokens).div(totalSupply());

        _burn(msg.sender, tokens);

        msg.sender.transfer(value);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        if (to == address(this)) {
            sellTokens(value);
        } else {
            _transfer(msg.sender, to, value);
        }

        return true;
    }
}