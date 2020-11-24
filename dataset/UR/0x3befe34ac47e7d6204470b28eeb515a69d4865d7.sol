 

 

pragma solidity 0.5.12;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if(a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
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
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract IERC223Recipient {
    function tokenFallback(address from, uint value, bytes memory data) public;
}

contract StandardToken is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) public {
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

    function multiTransfer(address[] memory to, uint256[] memory value) public returns (bool) {
        require(to.length > 0 && to.length == value.length, "Invalid params");

        for(uint i = 0; i < to.length; i++) {
            _transfer(msg.sender, to[i], value[i]);
        }

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
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

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "ERC20: transfer to the zero address");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        
        bytes memory empty = hex"00000000";
        if(Address.isContract(to)) {
            IERC223Recipient receiver = IERC223Recipient(to);
            receiver.tokenFallback(from, value, empty);
        }

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

contract MintableToken is StandardToken, Ownable {
    bool public mintingFinished = false;

    event MintFinished(address account);

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function finishMinting() onlyOwner canMint public returns(bool) {
        mintingFinished = true;

        emit MintFinished(msg.sender);
        return true;
    }

    function mint(address to, uint256 value) public canMint onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }
}

contract CappedToken is MintableToken {
    uint256 private _cap;

    constructor(uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");

        _cap = cap;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap, "ERC20Capped: cap exceeded");
        super._mint(account, value);
    }
}

contract BurnableToken is StandardToken {
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

contract Withdrawable is Ownable {
    event WithdrawEther(address indexed to, uint value);

    function withdrawEther(address payable _to, uint _value) onlyOwner public {
        require(_to != address(0));
        require(address(this).balance >= _value);

        address(_to).transfer(_value);

        emit WithdrawEther(_to, _value);
    }

    function withdrawTokensTransfer(IERC20 _token, address _to, uint256 _value) onlyOwner public {
        require(_token.transfer(_to, _value));
    }

    function withdrawTokensTransferFrom(IERC20 _token, address _from, address _to, uint256 _value) onlyOwner public {
        require(_token.transferFrom(_from, _to, _value));
    }

    function withdrawTokensApprove(IERC20 _token, address _spender, uint256 _value) onlyOwner public {
        require(_token.approve(_spender, _value));
    }
}

contract Pausable is Ownable {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
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


 
contract Token is CappedToken, BurnableToken, Withdrawable {
    constructor() CappedToken(120000000000 * 1e4) StandardToken("NEP Index", "NEP", 4) public {
        
    }
}

contract Wallet is Ownable {
    struct WalletItem {
        address payable addr;
        uint percent;
    }

    WalletItem[] public wallets;

    function setWallet(uint _index, address payable _addr, uint _percent) onlyOwner external {
        wallets[_index].addr = _addr;
        wallets[_index].percent = _percent;
    }

    function addWallet(address payable _addr, uint _percent) onlyOwner external {
        wallets.push(WalletItem({addr: _addr, percent: _percent}));
    }
}

contract IncomingStream is Wallet, Withdrawable {
    using SafeMath for uint;

    Token public token;

    uint public rate = 500;
    uint public min_buy_amount = 100e4;

    event Operation(address indexed addr, uint256 eth, uint256 tokens);

    constructor(Token _token) public {
        token = _token;
    }

    function() payable external {
        uint tokens = msg.value.mul(rate).div(1e14);

        require(token.balanceOf(address(this)) >= tokens, "Insufficient funds");
        require(token.transfer(msg.sender, tokens), "Error send tokens");
        require(tokens >= min_buy_amount, "Invalid amount");

        for(uint i = 0; i < wallets.length; i++) {
            if(wallets[i].percent > 0) {
                address(wallets[i].addr).transfer(msg.value.mul(wallets[i].percent).div(100));
            }
        }

        emit Operation(msg.sender, msg.value, tokens);
    }

    function setRate(uint _rate) onlyOwner external {
        rate = _rate;
    }

    function setMinBuyAmount(uint _min_buy_amount) onlyOwner external {
        min_buy_amount = _min_buy_amount;
    }
}

contract OutgoingStream is Wallet, Withdrawable {
    using SafeMath for uint;

    event Operation(address indexed addr, uint256 eth);

    function() payable external {
        for(uint i = 0; i < wallets.length; i++) {
            if(wallets[i].percent > 0) {
                address(wallets[i].addr).transfer(msg.value.mul(wallets[i].percent).div(100));
            }
        }

        emit Operation(msg.sender, msg.value);
    }
}

contract ExchangerToken is Withdrawable, IERC223Recipient {
    using SafeMath for uint;
    using Address for address;

    Token public token;
    address public tokenHolder;

    uint public rate = 650;

    event Operation(address indexed addr, uint256 tokens, uint256 eth);

    constructor(Token _token) public {
        token = _token;
    }

    function() payable external {
        
    }
    
    function tokenFallback(address from, uint value, bytes memory data) public {
        require(msg.sender == address(token), "Invalid token");

        uint eth = value.mul(1e14).div(rate);
        address payable to = from.toPayable();

        require(address(this).balance >= eth, "Insufficient funds");
        to.transfer(eth);

        if(tokenHolder != address(0)) {
            token.transfer(tokenHolder, value);
        }
 
        emit Operation(to, value, eth);
    }

    function setRate(uint _rate) onlyOwner external {
        rate = _rate;
    }

    function setTokenHolder(address _addr) onlyOwner external {
        tokenHolder = _addr;
    }
}