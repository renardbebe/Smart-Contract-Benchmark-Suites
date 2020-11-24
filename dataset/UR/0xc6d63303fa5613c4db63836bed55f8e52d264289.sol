 

pragma solidity ^0.4.24;

 
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

pragma solidity ^0.4.24;

 
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

pragma solidity ^0.4.24;

 
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

pragma solidity ^0.4.24;

 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string name, string symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
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
}

contract BonusToken is ERC20, ERC20Detailed, Ownable {

    address public gameAddress;
    address public investTokenAddress;
    uint public maxLotteryParticipants;

    mapping (address => uint256) public ethLotteryBalances;
    address[] public ethLotteryParticipants;
    uint256 public ethLotteryBank;
    bool public isEthLottery;

    mapping (address => uint256) public tokensLotteryBalances;
    address[] public tokensLotteryParticipants;
    uint256 public tokensLotteryBank;
    bool public isTokensLottery;

    modifier onlyGame() {
        require(msg.sender == gameAddress);
        _;
    }

    modifier tokenIsAvailable {
        require(investTokenAddress != address(0));
        _;
    }

    constructor (address startGameAddress) public ERC20Detailed("Bet Token", "BET", 18) {
        setGameAddress(startGameAddress);
    }

    function setGameAddress(address newGameAddress) public onlyOwner {
        require(newGameAddress != address(0));
        gameAddress = newGameAddress;
    }

    function buyTokens(address buyer, uint256 tokensAmount) public onlyGame {
        _mint(buyer, tokensAmount * 10**18);
    }

    function startEthLottery() public onlyGame {
        isEthLottery = true;
    }

    function startTokensLottery() public onlyGame tokenIsAvailable {
        isTokensLottery = true;
    }

    function restartEthLottery() public onlyGame {
        for (uint i = 0; i < ethLotteryParticipants.length; i++) {
            ethLotteryBalances[ethLotteryParticipants[i]] = 0;
        }
        ethLotteryParticipants = new address[](0);
        ethLotteryBank = 0;
        isEthLottery = false;
    }

    function restartTokensLottery() public onlyGame tokenIsAvailable {
        for (uint i = 0; i < tokensLotteryParticipants.length; i++) {
            tokensLotteryBalances[tokensLotteryParticipants[i]] = 0;
        }
        tokensLotteryParticipants = new address[](0);
        tokensLotteryBank = 0;
        isTokensLottery = false;
    }

    function updateEthLotteryBank(uint256 value) public onlyGame {
        ethLotteryBank = ethLotteryBank.sub(value);
    }

    function updateTokensLotteryBank(uint256 value) public onlyGame {
        tokensLotteryBank = tokensLotteryBank.sub(value);
    }

    function swapTokens(address account, uint256 tokensToBurnAmount) public {
        require(msg.sender == investTokenAddress);
        _burn(account, tokensToBurnAmount);
    }

    function sendToEthLottery(uint256 value) public {
        require(!isEthLottery);
        require(ethLotteryParticipants.length < maxLotteryParticipants);
        address account = msg.sender;
        _burn(account, value);
        if (ethLotteryBalances[account] == 0) {
            ethLotteryParticipants.push(account);
        }
        ethLotteryBalances[account] = ethLotteryBalances[account].add(value);
        ethLotteryBank = ethLotteryBank.add(value);
    }

    function sendToTokensLottery(uint256 value) public tokenIsAvailable {
        require(!isTokensLottery);
        require(tokensLotteryParticipants.length < maxLotteryParticipants);
        address account = msg.sender;
        _burn(account, value);
        if (tokensLotteryBalances[account] == 0) {
            tokensLotteryParticipants.push(account);
        }
        tokensLotteryBalances[account] = tokensLotteryBalances[account].add(value);
        tokensLotteryBank = tokensLotteryBank.add(value);
    }

    function ethLotteryParticipants() public view returns(address[]) {
        return ethLotteryParticipants;
    }

    function tokensLotteryParticipants() public view returns(address[]) {
        return tokensLotteryParticipants;
    }

    function setInvestTokenAddress(address newInvestTokenAddress) external onlyOwner {
        require(newInvestTokenAddress != address(0));
        investTokenAddress = newInvestTokenAddress;
    }

    function setMaxLotteryParticipants(uint256 participants) external onlyOwner {
        maxLotteryParticipants = participants;
    }
}