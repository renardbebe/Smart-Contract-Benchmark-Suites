 

pragma solidity ^0.5.9;

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

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }
}

contract ATokenERC20 is ERC20Detailed {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    string constant tokenName = "B-ROCKET";
    string constant tokenSymbol = "BRE";
    uint8 constant tokenDecimals = 0;
    uint256 _totalSupply = 50000000;
    uint256 _totalBaseline = 5000000;
    uint256 public basePercent = 100;

    constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
        _mint(msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function findOnePercent(uint256 value) public view returns (uint256)  {
        uint256 roundValue = value.ceil(basePercent);
        uint256 onePercent = roundValue.mul(basePercent).div(10000);
        return onePercent;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {

        if (_totalSupply <= _totalBaseline) {
            require(_value <= _balances[msg.sender]);
            require(_to != address(0));

            _balances[msg.sender] = _balances[msg.sender].sub(_value);
            _balances[_to] = _balances[_to].add(_value);

            emit Transfer(msg.sender, _to, _value);
        } else {
            require(_value <= _balances[msg.sender]);
            require(_to != address(0));

            uint256 tokensToBurn = findOnePercent(_value);
            uint256 tokensToTransfer = _value.sub(tokensToBurn);

            _balances[msg.sender] = _balances[msg.sender].sub(_value);
            _balances[_to] = _balances[_to].add(tokensToTransfer);

            _totalSupply = _totalSupply.sub(tokensToBurn);

            emit Transfer(msg.sender, _to, tokensToTransfer);
            emit Transfer(msg.sender, address(0), tokensToBurn);
        }

        return true;
    }

    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        if (_totalSupply <= _totalBaseline) {
            require(_value <= _balances[_from]);
            require(_value <= _allowed[_from][msg.sender]);
            require(_to != address(0));

            _balances[_from] = _balances[_from].sub(_value);
            _balances[_to] = _balances[_to].add(_value);
            _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);

            emit Transfer(_from, _to, _value);
        } else {
            require(_value <= _balances[_from]);
            require(_value <= _allowed[_from][msg.sender]);
            require(_to != address(0));

            _balances[_from] = _balances[_from].sub(_value);

            uint256 tokensToBurn = findOnePercent(_value);
            uint256 tokensToTransfer = _value.sub(tokensToBurn);

            _balances[_to] = _balances[_to].add(tokensToTransfer);
            _totalSupply = _totalSupply.sub(tokensToBurn);
            _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);

            emit Transfer(_from, _to, tokensToTransfer);
            emit Transfer(_from, address(0), tokensToBurn);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(amount != 0);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(amount != 0);
        require(amount <= _balances[account]);
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        require(amount <= _allowed[account][msg.sender]);
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
        _burn(account, amount);
    }
}