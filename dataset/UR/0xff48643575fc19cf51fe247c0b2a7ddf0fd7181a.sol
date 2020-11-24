 

pragma solidity 0.5.11;

 

contract IERC20 {
    function transfer(address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);
}









 

library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0);
        return a % b;
    }
}
 

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns(uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns(uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns(bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns(bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
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

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}


 

contract Role {

    address private _owner;
    bool    private _paused;

    event NewOwner(address owner);
    event SetPause(bool paused);

    modifier onlyOwner {
        require(_owner == msg.sender, "owner is not msg.sender");
        _;
    }

    modifier notPaused {
        require(!_paused, "paused");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isPaused() public view returns (bool) {
        return _paused;
    }

    function _setOwner(address newOwner) internal {
        _owner = newOwner;
        emit NewOwner(newOwner);
    }

    function _setPaused(bool paused) internal {
        _paused = paused;
        emit SetPause(paused);
    }
}

 

contract ERC20Base is ERC20, Role {

    bool public mintlock;

    function transfer(address _to, uint256 _value) public notPaused returns(bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public notPaused returns(bool) {
        require(allowance(_from, msg.sender) >= _value, "Not enough funds allowed");
         
        if (allowance(_from, msg.sender) != (2 ** 256) - 1) {
            _approve(_from, msg.sender, allowance(_from, msg.sender).sub(_value));
        }
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public notPaused returns(bool) {
        return super.approve(_spender, _value);
    }

    function increaseAllowance(address _spender, uint _addedValue) public notPaused returns(bool success) {
        return super.increaseAllowance(_spender, _addedValue);
    }

    function decreaseAllowance(address _spender, uint _subtractedValue) public notPaused returns(bool success) {
        return super.decreaseAllowance(_spender, _subtractedValue);
    }

    function mint(address _to, uint256 _amount) public notPaused onlyOwner returns(bool) {
        require(!mintlock, "Mint is locked");
        _mint(_to, _amount);
        return true;
    }

    function burn(uint256 _amount) public notPaused returns(bool) {
        _burn(msg.sender, _amount);
        return true;
    }

    function setOwner(address _owner) public notPaused onlyOwner returns(bool) {
        require(_owner != address(0), "owner is zero address");
        _setOwner(_owner);
        return true;
    }

    function setMintlock() public onlyOwner returns(bool) {
        mintlock = true;
        return true;
    }

    function setPaused(bool _paused) public onlyOwner returns(bool) {
        _setPaused(_paused);
        return true;
    }
}

 

contract Token is ERC20Base {

    string private _name;
    string private _symbol;
    uint8  private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals, uint256 _value) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _setOwner(msg.sender);
        _mint(msg.sender, _value);
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