 

pragma solidity 0.5.2;

 
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

 
library Math {
     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: Integer overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath#div: Invalid divisor zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: Integer underflow");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: Integer overflow");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: Invalid divisor zero");
        return a % b;
    }
}

contract IUniswapExchange {
     
    function tokenAddress() external view returns (address token);
     
    function factoryAddress() external view returns (address factory);
     
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
     
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
     
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
     
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_tokens, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
     
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
     
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
     
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
     
    function setup(address token_addr) external;
}

contract IUniswapFactory {
     
    address public exchangeTemplate;
    uint256 public tokenCount;
     
    function createExchange(address token) external returns (address payable exchange);
     
    function getExchange(address token) external view returns (address payable exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
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
        require(spender != address(0), "ERC20#approve: Cannot approve address zero");

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
        require(spender != address(0), "ERC20#increaseAllowance: Cannot increase allowance for address zero");

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "ERC20#decreaseAllowance: Cannot decrease allowance for address zero");

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "ERC20#_transfer: Cannot transfer to address zero");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20#_mint: Cannot mint to address zero");

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20#_burn: Cannot burn from address zero");

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

contract OracleToken is ERC20 {
    string public name = "Polaris Token";
    string public symbol = "PLRS";
    uint8 public decimals = 18;
    address public oracle;
    address public token;

    constructor(address _token) public payable {
        oracle = msg.sender;
        token = _token;
    }

    function () external payable {}

    function mint(address to, uint amount) public returns (bool) {
        require(msg.sender == oracle, "OracleToken::mint: Only Oracle can call mint");
        _mint(to, amount);
        return true;
    }

    function redeem(uint amount) public {
        uint ethAmount = address(this).balance.mul(amount).div(totalSupply());
        _burn(msg.sender, amount);
        msg.sender.transfer(ethAmount);
    }
}

pragma experimental ABIEncoderV2;


contract Polaris {
    using Math for uint;
    using SafeMath for uint;

    event NewMedian(address indexed token, uint ethReserve, uint tokenReserve);
    event Subscribe(address indexed token, address indexed subscriber, uint amount);
    event Unsubscribe(address indexed token, address indexed subscriber, uint amount);

    uint8 public constant MAX_CHECKPOINTS = 15;

     
    uint public constant CHECKPOINT_REWARD = 1e18;

     
    uint public constant MIN_PRICE_CHANGE = .01e18;  
    uint public constant MAX_TIME_SINCE_LAST_CHECKPOINT = 3 hours;

    uint public constant PENDING_PERIOD = 3.5 minutes;

    address public constant ETHER = address(0);

     
    uint public constant MONTHLY_SUBSCRIPTION_FEE = 5 ether;
    uint public constant ONE_MONTH_IN_SECONDS = 30 days;

    IUniswapFactory public uniswap;

    struct Account {
        uint balance;
        uint collectionTimestamp;
    }

    struct Checkpoint {
        uint ethReserve;
        uint tokenReserve;
    }

    struct Medianizer {
        uint8 tail;
        uint pendingStartTimestamp;
        uint latestTimestamp;
        Checkpoint[] prices;
        Checkpoint[] pending;
        Checkpoint median;
    }

     
    mapping (address => mapping (address => Account)) public accounts;

     
    mapping (address => OracleToken) public oracleTokens;

     
    mapping (address => Medianizer) private medianizers;

    constructor(IUniswapFactory _uniswap) public {
        uniswap = _uniswap;
    }

     
    function subscribe(address token) public payable {
        Account storage account = accounts[token][msg.sender];
        _collect(token, account);
        account.balance = account.balance.add(msg.value);
        require(account.balance >= MONTHLY_SUBSCRIPTION_FEE, "Polaris::subscribe: Account balance is below the minimum");
        emit Subscribe(token, msg.sender, msg.value);
    }

     
    function unsubscribe(address token, uint amount) public returns (uint) {
        Account storage account = accounts[token][msg.sender];
        _collect(token, account);
        uint maxWithdrawAmount = account.balance.sub(MONTHLY_SUBSCRIPTION_FEE);
        uint actualWithdrawAmount = amount.min(maxWithdrawAmount);
        account.balance = account.balance.sub(actualWithdrawAmount);
        msg.sender.transfer(actualWithdrawAmount);
        emit Unsubscribe(token, msg.sender, actualWithdrawAmount);
    }

     
    function collect(address token, address who) public {
        Account storage account = accounts[token][who];
        _collect(token, account);
    }

     
    function poke(address token) public {
        require(_isHuman(), "Polaris::poke: Poke must be called by an externally owned account");
        OracleToken oracleToken = oracleTokens[token];

         
        Checkpoint memory checkpoint = _newCheckpoint(token);

        if (address(oracleToken) == address(0)) {
            _initializeMedianizer(token, checkpoint);
        } else {
            Medianizer storage medianizer = medianizers[token];

            require(medianizer.latestTimestamp != block.timestamp, "Polaris::poke: Cannot poke more than once per block");

             
            if (_willRewardCheckpoint(token, checkpoint)) {
                oracleToken.mint(msg.sender, CHECKPOINT_REWARD);
            }

             
            if (block.timestamp.sub(medianizer.pendingStartTimestamp) > PENDING_PERIOD || medianizer.pending.length == MAX_CHECKPOINTS) {
                medianizer.pending.length = 0;
                medianizer.tail = (medianizer.tail + 1) % MAX_CHECKPOINTS;
                medianizer.pendingStartTimestamp = block.timestamp;
            }

            medianizer.latestTimestamp = block.timestamp;

             
            medianizer.pending.push(checkpoint);
            
             
            medianizer.prices[medianizer.tail] = _medianize(medianizer.pending);
            
             
            medianizer.median = _medianize(medianizer.prices);

            emit NewMedian(token, medianizer.median.ethReserve, medianizer.median.tokenReserve);
        }
    }

     
    function getMedianizer(address token) public view returns (Medianizer memory) {
        require(_isSubscriber(accounts[token][msg.sender]) || _isHuman(), "Polaris::getMedianizer: Not subscribed");
        return medianizers[token];
    }

     
    function getDestAmount(address src, address dest, uint srcAmount) public view returns (uint) {
        if (!_isHuman()) {
            require(src == ETHER || _isSubscriber(accounts[src][msg.sender]), "Polaris::getDestAmount: Not subscribed");
            require(dest == ETHER || _isSubscriber(accounts[dest][msg.sender]), "Polaris::getDestAmount: Not subscribed");    
        }

        if (src == dest) {
            return srcAmount;
        } else if (src == ETHER) {
            Checkpoint memory median = medianizers[dest].median;
            return srcAmount.mul(median.tokenReserve).div(median.ethReserve.add(srcAmount));
        } else if (dest == ETHER) {
            Checkpoint memory median = medianizers[src].median;
            return srcAmount.mul(median.ethReserve).div(median.tokenReserve.add(srcAmount));
        } else {
            Checkpoint memory srcMedian = medianizers[src].median;
            Checkpoint memory destMedian = medianizers[dest].median;
            
            uint ethAmount = srcAmount.mul(srcMedian.ethReserve).div(srcMedian.tokenReserve.add(srcAmount));
            return ethAmount.mul(destMedian.ethReserve).div(destMedian.tokenReserve.add(ethAmount));
        }
    }

     
    function willRewardCheckpoint(address token) public view returns (bool) {
        Checkpoint memory checkpoint = _newCheckpoint(token);
        return _willRewardCheckpoint(token, checkpoint);
    }

     
    function getAccount(address token, address who) public view returns (Account memory) {
        return accounts[token][who];
    }

     
    function getOwedAmount(address token, address who) public view returns (uint) {
        Account storage account = accounts[token][who];
        return _getOwedAmount(account);
    }

     
    function _collect(address token, Account storage account) internal {
        if (account.balance == 0) {
            account.collectionTimestamp = block.timestamp;
            return;
        }

        uint owedAmount = _getOwedAmount(account);
        OracleToken oracleToken = oracleTokens[token];

         
        if (owedAmount >= account.balance) {
            address(oracleToken).transfer(account.balance);
            account.balance = 0;
        } else {
            address(oracleToken).transfer(owedAmount);
            account.balance = account.balance.sub(owedAmount);
        }

        account.collectionTimestamp = block.timestamp;
    }

     
    function _initializeMedianizer(address token, Checkpoint memory checkpoint) internal {
        address payable exchange = uniswap.getExchange(token);
        require(exchange != address(0), "Polaris::_initializeMedianizer: Token must exist on Uniswap");

        OracleToken oracleToken = new OracleToken(token);
        oracleTokens[token] = oracleToken;
         
        oracleToken.mint(msg.sender, CHECKPOINT_REWARD.mul(10));

        Medianizer storage medianizer = medianizers[token];
        medianizer.pending.push(checkpoint);
        medianizer.median = checkpoint;
        medianizer.latestTimestamp = block.timestamp;
        medianizer.pendingStartTimestamp = block.timestamp;

         
        for (uint i = 0; i < MAX_CHECKPOINTS; i++) {
            medianizer.prices.push(checkpoint);
        }
    }

     
    function _medianize(Checkpoint[] memory checkpoints) internal pure returns (Checkpoint memory) {
         
        uint k = checkpoints.length.div(2); 
        uint left = 0;
        uint right = checkpoints.length.sub(1);

        while (left < right) {
            uint pivotIndex = left.add(right).div(2);
            Checkpoint memory pivotCheckpoint = checkpoints[pivotIndex];

            (checkpoints[pivotIndex], checkpoints[right]) = (checkpoints[right], checkpoints[pivotIndex]);
            uint storeIndex = left;
            for (uint i = left; i < right; i++) {
                if (_isLessThan(checkpoints[i], pivotCheckpoint)) {
                    (checkpoints[storeIndex], checkpoints[i]) = (checkpoints[i], checkpoints[storeIndex]);
                    storeIndex++;
                }
            }

            (checkpoints[storeIndex], checkpoints[right]) = (checkpoints[right], checkpoints[storeIndex]);
            if (storeIndex < k) {
                left = storeIndex.add(1);
            } else {
                right = storeIndex;
            }
        }

        return checkpoints[k];
    }

     
    function _isLessThan(Checkpoint memory x, Checkpoint memory y) internal pure returns (bool) {
        return x.ethReserve.mul(y.tokenReserve) < y.ethReserve.mul(x.tokenReserve);
    }

     
    function _isHuman() internal view returns (bool) {
        return msg.sender == tx.origin;
    }

     
    function _newCheckpoint(address token) internal view returns (Checkpoint memory) {
        address payable exchange = uniswap.getExchange(token);
        return Checkpoint({
            ethReserve: exchange.balance,
            tokenReserve: IERC20(token).balanceOf(exchange)
        });
    }

     
    function _isSubscriber(Account storage account) internal view returns (bool) {
         
        return account.balance > _getOwedAmount(account);
    }

     
    function _getOwedAmount(Account storage account) internal view returns (uint) {
        if (account.collectionTimestamp == 0) return 0;

        uint timeElapsed = block.timestamp.sub(account.collectionTimestamp);
        return MONTHLY_SUBSCRIPTION_FEE.mul(timeElapsed).div(ONE_MONTH_IN_SECONDS);
    }

     
    function _willRewardCheckpoint(address token, Checkpoint memory checkpoint) internal view returns (bool) {
        Medianizer memory medianizer = medianizers[token];

        return (
            medianizer.prices.length < MAX_CHECKPOINTS ||
            block.timestamp.sub(medianizer.latestTimestamp) >= MAX_TIME_SINCE_LAST_CHECKPOINT ||
            (block.timestamp.sub(medianizer.pendingStartTimestamp) >= PENDING_PERIOD && _percentChange(medianizer.median, checkpoint) >= MIN_PRICE_CHANGE) ||
            _percentChange(medianizer.prices[medianizer.tail], checkpoint) >= MIN_PRICE_CHANGE ||
            _percentChange(medianizer.pending[medianizer.pending.length.sub(1)], checkpoint) >= MIN_PRICE_CHANGE
        );
    }

     
    function _percentChange(Checkpoint memory x, Checkpoint memory y) internal pure returns (uint) {
        uint a = x.ethReserve.mul(y.tokenReserve);
        uint b = y.ethReserve.mul(x.tokenReserve);
        uint diff = a > b ? a.sub(b) : b.sub(a);
        return diff.mul(10 ** 18).div(a);
    }

}