 

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

 
interface modIERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value, uint256 index) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract modERC20Detailed is modIERC20 {
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

contract modERC20 is modIERC20 {
    using SafeMath for uint256;

    uint256 constant public MIN_HOLDERS_BALANCE = 20 ether;

    address public gameAddress;

    mapping (address => uint256) private _balances;
    uint256 private _totalSupply;

    address[] internal holders;
    mapping(address => bool) internal isUser;

    function getHolders() public view returns (address[]) {
        return holders;
    }

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        if (to != gameAddress && from != gameAddress) {
            uint256 transferFee = value.div(100);
            _burn(from, transferFee);
            value = value.sub(transferFee);
        }
        _balances[from] = _balances[from].sub(value);
        if (to != gameAddress && _balances[to] < MIN_HOLDERS_BALANCE && _balances[to].add(value) >= MIN_HOLDERS_BALANCE) {
            holders.push(to);
        }
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

contract InvestToken is modERC20, modERC20Detailed, Ownable {

    uint8 constant public REFERRER_PERCENT = 3;
    uint8 constant public CASHBACK_PERCENT = 2;
    uint8 constant public HOLDERS_BUY_PERCENT_WITH_REFERRER = 7;
    uint8 constant public HOLDERS_BUY_PERCENT_WITH_REFERRER_AND_CASHBACK = 5;
    uint8 constant public HOLDERS_BUY_PERCENT = 10;
    uint8 constant public HOLDERS_SELL_PERCENT = 5;
    uint8 constant public TOKENS_DIVIDER = 10;
    uint256 constant public PRICE_INTERVAL = 10000000000;

    uint256 public swapTokensLimit;
    uint256 public investDividends;
    uint256 public casinoDividends;
    mapping(address => uint256) public ethStorage;
    mapping(address => address) public referrers;
    mapping(address => uint256) public investSize24h;
    mapping(address => uint256) public lastInvestTime;
    BonusToken public bonusToken;

    uint256 private holdersIndex;
    uint256 private totalInvestDividends;
    uint256 private totalCasinoDividends;
    uint256 private priceCoeff = 105e9;
    uint256 private constant a = 5e9;

    event Buy(address indexed buyer, uint256 weiAmount, uint256 tokensAmount, uint256 timestamp);
    event Sell(address indexed seller, uint256 weiAmount, uint256 tokensAmount, uint256 timestamp);
    event Reinvest(address indexed investor, uint256 weiAmount, uint256 tokensAmount, uint256 timestamp);
    event Withdraw(address indexed investor, uint256 weiAmount, uint256 timestamp);
    event ReferalsIncome(address indexed recipient, uint256 amount, uint256 timestamp);
    event InvestIncome(address indexed recipient, uint256 amount, uint256 timestamp);
    event CasinoIncome(address indexed recipient, uint256 amount, uint256 timestamp);

    constructor (address _bonusToken) public modERC20Detailed("Get Token", "GET", 18) {
        require(_bonusToken != address (0));
        bonusToken = BonusToken(_bonusToken);
        swapTokensLimit = 10000;
        swapTokensLimit = swapTokensLimit.mul(10 ** uint256(decimals()));
    }

    modifier onlyGame() {
        require(msg.sender == gameAddress, 'The sender must be a game contract.');
        _;
    }

    function () public payable {
        if (msg.sender != gameAddress) {
            address referrer;
            if (msg.data.length == 20) {
                referrer = bytesToAddress(bytes(msg.data));
            }
            buyTokens(referrer);
        }
    }

    function buyTokens(address referrer) public payable {
        uint256 weiAmount = msg.value;
        address buyer = msg.sender;
        uint256 tokensAmount;
        (weiAmount, tokensAmount) = mint(buyer, weiAmount);
        uint256 correctWeiAmount = msg.value.sub(weiAmount);
        checkInvestTimeAndSize(buyer, correctWeiAmount);
        if (!isUser[buyer]) {
            if (referrer != address(0) && referrer != buyer) {
                referrers[buyer] = referrer;
            }
            buyFee(buyer, correctWeiAmount, true);
            isUser[buyer] = true;
        } else {
            buyFee(buyer, correctWeiAmount, false);
        }
        if (weiAmount > 0) {
            buyer.transfer(weiAmount);
        }
        emit Buy(buyer, correctWeiAmount, tokensAmount, now);
    }

    function sellTokens(uint256 tokensAmount, uint index) public {
        address seller = msg.sender;
        tokensAmount = tokensAmount.div(decimals()).mul(decimals());
        burn(seller, tokensAmount, index);
        uint256 weiAmount = tokensToEthereum(tokensAmount.div(uint256(10) ** decimals()));
        weiAmount = sellFee(weiAmount);
        seller.transfer(weiAmount);
        emit Sell(seller, weiAmount, tokensAmount, now);
    }

    function swapTokens(uint256 tokensAmountToBurn) public {
        uint256 tokensAmountToMint = tokensAmountToBurn.div(TOKENS_DIVIDER);
        require(tokensAmountToMint <= swapTokensLimit.sub(tokensAmountToMint));
        require(bonusToken.balanceOf(msg.sender) >= tokensAmountToBurn, 'Not enough bonus tokens.');
        bonusToken.swapTokens(msg.sender, tokensAmountToBurn);
        swapTokensLimit = swapTokensLimit.sub(tokensAmountToMint);
        priceCoeff = priceCoeff.add(tokensAmountToMint.mul(1e10));
        correctBalanceByMint(msg.sender, tokensAmountToMint);
        _mint(msg.sender, tokensAmountToMint);
    }

    function reinvest(uint256 weiAmount) public {
        ethStorage[msg.sender] = ethStorage[msg.sender].sub(weiAmount);
        uint256 tokensAmount;
        (weiAmount, tokensAmount) = mint(msg.sender, weiAmount);
        if (weiAmount > 0) {
            ethStorage[msg.sender] = ethStorage[msg.sender].add(weiAmount);
        }
        emit Reinvest(msg.sender, weiAmount, tokensAmount, now);
    }

    function withdraw(uint256 weiAmount) public {
        require(weiAmount > 0);
        ethStorage[msg.sender] = ethStorage[msg.sender].sub(weiAmount);
        msg.sender.transfer(weiAmount);
        emit Withdraw(msg.sender, weiAmount, now);
    }

    function transfer(address to, uint256 value, uint256 index) public returns (bool) {
        if (msg.sender != gameAddress) {
            correctBalanceByBurn(msg.sender, value, index);
        }
        _transfer(msg.sender, to, value);
        return true;
    }

    function sendDividendsToHolders(uint holdersIterations) public onlyOwner {
        if (holdersIndex == 0) {
            totalInvestDividends = investDividends;
            totalCasinoDividends = casinoDividends;
        }
        uint holdersIterationsNumber;
        if (holders.length.sub(holdersIndex) < holdersIterations) {
            holdersIterationsNumber = holders.length.sub(holdersIndex);
        } else {
            holdersIterationsNumber = holdersIterations;
        }
        uint256 holdersBalance = 0;
        uint256 weiAmount = 0;
        for (uint256 i = 0; i < holdersIterationsNumber; i++) {
            holdersBalance = balanceOf(holders[holdersIndex]);
            if (holdersBalance >= MIN_HOLDERS_BALANCE) {
                if (totalInvestDividends > 0) {
                    weiAmount = holdersBalance.mul(totalInvestDividends).div(totalSupply());
                    investDividends = investDividends.sub(weiAmount);
                    emit InvestIncome(holders[holdersIndex], weiAmount, now);
                    ethStorage[holders[holdersIndex]] = ethStorage[holders[holdersIndex]].add(weiAmount);
                }
                if (totalCasinoDividends > 0) {
                    weiAmount = holdersBalance.mul(totalCasinoDividends).div(totalSupply());
                    casinoDividends = casinoDividends.sub(weiAmount);
                    emit CasinoIncome(holders[holdersIndex], weiAmount, now);
                    ethStorage[holders[holdersIndex]] = ethStorage[holders[holdersIndex]].add(weiAmount);
                }
            }
            holdersIndex++;
        }
        if (holdersIndex == holders.length) {
            holdersIndex = 0;
        }
    }

    function setGameAddress(address newGameAddress) public onlyOwner {
        gameAddress = newGameAddress;
    }

    function sendToGame(address player, uint256 tokensAmount, uint256 index) public onlyGame returns(bool) {
        correctBalanceByBurn(player, tokensAmount, index);
        _transfer(player, gameAddress, tokensAmount);
        return true;
    }

    function gameDividends(uint256 weiAmount) public onlyGame {
        casinoDividends = casinoDividends.add(weiAmount);
    }

    function price() public view returns(uint256) {
        return priceCoeff.add(a);
    }

    function mint(address account, uint256 weiAmount) private returns(uint256, uint256) {
        (uint256 tokensToMint, uint256 backPayWeiAmount) = ethereumToTokens(weiAmount);
        correctBalanceByMint(account, tokensToMint);
        _mint(account, tokensToMint);
        return (backPayWeiAmount, tokensToMint);
    }

    function burn(address account, uint256 tokensAmount, uint256 index) private returns(uint256, uint256) {
        correctBalanceByBurn(account, tokensAmount, index);
        _burn(account, tokensAmount);
    }

    function checkInvestTimeAndSize(address account, uint256 weiAmount) private {
        if (now - lastInvestTime[account] > 24 hours) {
            investSize24h[account] = 0;
        }
        require(investSize24h[account].add(weiAmount) <= 5 ether, 'Investment limit exceeded for 24 hours.');
        investSize24h[account] = investSize24h[account].add(weiAmount);
        lastInvestTime[account] = now;
    }

    function buyFee(address sender, uint256 weiAmount, bool isFirstInvest) private {
        address referrer = referrers[sender];
        uint256 holdersWeiAmount;
        if (referrer != address(0)) {
            uint256 referrerWeiAmount = weiAmount.mul(REFERRER_PERCENT).div(100);
            emit ReferalsIncome(referrer, referrerWeiAmount, now);
            ethStorage[referrer] = ethStorage[referrer].add(referrerWeiAmount);
            if (isFirstInvest) {
                uint256 cashbackWeiAmount = weiAmount.mul(CASHBACK_PERCENT).div(100);
                emit ReferalsIncome(sender, cashbackWeiAmount, now);
                ethStorage[sender] = ethStorage[sender].add(cashbackWeiAmount);
                holdersWeiAmount = weiAmount.mul(HOLDERS_BUY_PERCENT_WITH_REFERRER_AND_CASHBACK).div(100);
            } else {
                holdersWeiAmount = weiAmount.mul(HOLDERS_BUY_PERCENT_WITH_REFERRER).div(100);
            }
        } else {
            holdersWeiAmount = weiAmount.mul(HOLDERS_BUY_PERCENT).div(100);
        }
        addDividends(holdersWeiAmount);
    }

    function sellFee(uint256 weiAmount) private returns(uint256) {
        uint256 holdersWeiAmount = weiAmount.mul(HOLDERS_SELL_PERCENT).div(100);
        addDividends(holdersWeiAmount);
        weiAmount = weiAmount.sub(holdersWeiAmount);
        return weiAmount;
    }

    function addDividends(uint256 weiAmount) private {
        investDividends = investDividends.add(weiAmount);
    }

    function correctBalanceByMint(address account, uint256 value) private {
        if (balanceOf(account) < MIN_HOLDERS_BALANCE && balanceOf(account).add(value) >= MIN_HOLDERS_BALANCE) {
            holders.push(msg.sender);
        }
    }

    function correctBalanceByBurn(address account, uint256 value, uint256 index) private {
        if (balanceOf(account) >= MIN_HOLDERS_BALANCE && balanceOf(account).sub(value) < MIN_HOLDERS_BALANCE) {
            require(holders[index] == account);
            deleteTokensHolder(index);
        }
    }

    function ethereumToTokens(uint256 weiAmount) private returns(uint256, uint256) {
        uint256 b = priceCoeff;
        uint256 c = weiAmount;
        uint256 D = (b ** 2).add(a.mul(4).mul(c));
        uint256 tokensAmount = (sqrt(D).sub(b)).div((a).mul(2));
        require(tokensAmount > 0);
        uint256 backPayWeiAmount = weiAmount.sub(a.mul(tokensAmount ** 2).add(priceCoeff.mul(tokensAmount)));
        priceCoeff = priceCoeff.add(tokensAmount.mul(1e10));
        tokensAmount = tokensAmount.mul(10 ** uint256(decimals()));
        return (tokensAmount, backPayWeiAmount);
    }

    function tokensToEthereum(uint256 tokensAmount) private returns(uint256) {
        require(tokensAmount > 0);
        uint256 weiAmount = priceCoeff.mul(tokensAmount).sub((tokensAmount ** 2).mul(5).mul(1e9));
        priceCoeff = priceCoeff.sub(tokensAmount.mul(1e10));
        return weiAmount;
    }

    function bytesToAddress(bytes source) private pure returns(address parsedAddress)
    {
        assembly {
            parsedAddress := mload(add(source,0x14))
        }
        return parsedAddress;
    }

    function sqrt(uint256 x) private pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function deleteTokensHolder(uint index) private {
        holders[index] = holders[holders.length - 1];
        delete holders[holders.length - 1];
        holders.length--;
    }
}