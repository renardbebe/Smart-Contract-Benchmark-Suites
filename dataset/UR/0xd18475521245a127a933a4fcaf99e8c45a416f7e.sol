 

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;



 
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

 

pragma solidity ^0.5.2;


 
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

 

pragma solidity ^0.5.2;

 
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
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity 0.5.9;





contract QDT is ERC20, ERC20Detailed, Ownable{
    using SafeMath for uint256;

    uint8 constant LIMIT_FOR_PAYOUT = 200;
    uint32 constant PASSWORD_REVEAL_MIN_DELAY = 2592000;

    string private _name = "Quantfury Data Token";
    string private _symbol = "QDT";
    uint8 private _decimals = 8;

     
    struct Epoch {
        string hash;
        uint256 epochTime;
        string password;
        uint256 weiAmount;
        uint256 tokenAmount;
        uint256 revealTime;
    }

    uint256 private _currentEpoch;

     
    mapping(uint256 => Epoch) private listOfEpoch;

     
    uint256 private _ethPayoutPool;

     
     
    uint256 private _tokenPrice;

    constructor() ERC20Detailed(_name, _symbol, _decimals) public {
        _currentEpoch = 0;
        _tokenPrice = 0;
    }

     
    function getBalance()
    external
    view
    returns(uint256)
    {
        return _ethPayoutPool;
    }

     
    function getPrice()
    external
    view
    returns (uint256)
    {
        return _tokenPrice;
    }

     
    function getCurrentEpoch()
    external
    view
    returns (uint256)
    {
        return _currentEpoch;
    }

     
    function getEpoch(uint256 epoch)
    external
    view
    returns (
        string memory,
        uint256,
        string memory,
        uint256,
        uint256,
        uint256
    ) {
        return (
                listOfEpoch[epoch].hash,
                listOfEpoch[epoch].epochTime,
                listOfEpoch[epoch].password,
                listOfEpoch[epoch].weiAmount,
                listOfEpoch[epoch].tokenAmount,
                listOfEpoch[epoch].revealTime
               );
    }

     

    function deposit()
    external
    onlyOwner
    payable
    returns (bool)
    {
        require(msg.value > 0);
        _ethPayoutPool = _ethPayoutPool.add(msg.value);
        emit Deposit(msg.sender, msg.value);
        return true;
    }

     
    function withdraw(address payable receiver, uint256 weiAmount)
    external
    onlyOwner
    returns (bool)
    {
        require(receiver != address(0x0));
        _ethPayoutPool = _ethPayoutPool.sub(weiAmount);
        address(receiver).transfer(weiAmount);
        emit Withdraw(receiver, weiAmount);
        return true;
    }

     
    function createEpoch(
        string calldata ipfsHash,
        uint256 epochTime,
        uint256 weiAmount,
        uint256 tokenAmount
    )
    external
    onlyOwner
    {
        require(listOfEpoch[_currentEpoch].epochTime < epochTime);
        uint256 _totalSupply = totalSupply();
        uint256 tokenPriceOld = _tokenPrice;
        _currentEpoch++;
        listOfEpoch[_currentEpoch].hash = ipfsHash;
        listOfEpoch[_currentEpoch].epochTime = epochTime;
        listOfEpoch[_currentEpoch].weiAmount = weiAmount;
        listOfEpoch[_currentEpoch].tokenAmount = tokenAmount;
        listOfEpoch[_currentEpoch].revealTime = epochTime.add(PASSWORD_REVEAL_MIN_DELAY);

         
        _tokenPrice = (weiAmount.add(_totalSupply.mul(_tokenPrice))).div(_totalSupply.add(tokenAmount));
        require(_tokenPrice != 0);

        emit CreateEpoch(
            _currentEpoch,
                weiAmount,
                tokenAmount,
                _tokenPrice,
                _totalSupply,
                tokenPriceOld,
                _ethPayoutPool);
    }

     
    function sellTokens(
        uint256 tokenAmount
    )
    external
    {
        uint256 weiAmount = _getWeiAmount(tokenAmount);

        _burn(msg.sender, tokenAmount);

        _ethPayoutPool = _ethPayoutPool.sub(weiAmount);

        address(msg.sender).transfer(weiAmount);

        emit Sell(msg.sender, tokenAmount, weiAmount, _tokenPrice, balanceOf(msg.sender));
    }

     
    function payout(
        address[] calldata holderAdresses,
        uint256[] calldata tokenAmounts,
        uint256 totalTokenAmount
    )
    external
    onlyOwner
    {
        require(balanceOf(msg.sender) >= totalTokenAmount);
        require(holderAdresses.length == tokenAmounts.length);
        require(holderAdresses.length <= LIMIT_FOR_PAYOUT);

        for (uint i = 0; i < holderAdresses.length; i++) {
            _transfer(msg.sender, holderAdresses[i], tokenAmounts[i]);
        }
    }

     
    function mint(
        address to,
        uint256 value
    )
    external
    onlyOwner
    returns (bool) {
        _mint(to, value);
        return true;
    }

     
    function burn(
        uint256 value
    )
    external
    onlyOwner
    returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

     
    function commitTradingPassword(
        uint256 epoch,
        string calldata password
    )
    external
    onlyOwner
    {
        require(_currentEpoch >= epoch);
        require(listOfEpoch[epoch].revealTime < now);
        listOfEpoch[epoch].password = password;
        emit OpenPassword(epoch, password);
    }

     
    function _getWeiAmount(uint256 tokenAmount)
    internal
    view
    returns (uint256) {
        return tokenAmount.mul(_tokenPrice);
    }

    event CreateEpoch(
        uint256 epoch,
        uint256 weiAmount,
        uint256 tokenAmount,
        uint256 tokenPrice,
        uint256 totalSupply,
        uint256 tokenPriceOld,
        uint256 ethPayoutPool);
    event OpenPassword(uint256 epoch, string password);
    event Sell(address indexed seller, uint256 tokenAmount, uint256 weiAmount, uint256 tokenPrice, uint256 balances);
    event Withdraw(address indexed receiver, uint256 weiAmount);
    event Deposit(address indexed sender, uint256 weiAmount);
}