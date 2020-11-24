 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

contract UniswapExchangeInterface {
     
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

 

pragma solidity ^0.5.0;

contract UniswapFactoryInterface {
     
    address public exchangeTemplate;
    uint256 public tokenCount;
     
    function createExchange(address token) external returns (address exchange);
     
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
     
    function initializeFactory(address template) external;
}

 

pragma solidity ^0.5.0;





contract PaymentProcessor is Ownable {
    uint256 constant UINT256_MAX = ~uint256(0);

    address public fundManager;
    UniswapFactoryInterface public uniswapFactory;
    address public intermediaryToken;
    UniswapExchangeInterface public intermediaryTokenExchange;

    constructor(UniswapFactoryInterface uniswapFactory_)
        public {
        uniswapFactory = uniswapFactory_;
    }

    function setFundManager(address fundManager_)
        onlyOwner
        public {
        fundManager = fundManager_;
    }

    function isFundManager()
        public view
        returns (bool) {
        return isOwner() || msg.sender == fundManager;
    }

    function setIntermediaryToken(address token)
        onlyFundManager
        external {
        intermediaryToken = token;
        if (token != address(0)) {
            intermediaryTokenExchange = UniswapExchangeInterface(uniswapFactory.getExchange(token));
            require(address(intermediaryTokenExchange) != address(0), "The token does not have an exchange");
        } else {
            intermediaryTokenExchange = UniswapExchangeInterface(address(0));
        }
    }

    function depositEther(uint64 orderId)
        payable
        external {
        require(msg.value > 0, "Minimal deposit is 0");
        uint256 amountBought = 0;
        if (intermediaryToken != address(0)) {
            amountBought = intermediaryTokenExchange.ethToTokenSwapInput.value(msg.value)(
                1  ,
                UINT256_MAX  );
        }
        emit EtherDepositReceived(orderId, msg.value, intermediaryToken, amountBought);
    }

    function withdrawEther(uint256 amount, address payable to)
        onlyFundManager
        external {
        to.transfer(amount);
        emit EtherDepositWithdrawn(to, amount);
    }

    function withdrawToken(IERC20 token, uint256 amount, address to)
        onlyFundManager
        external {
        require(token.transfer(to, amount), "Withdraw token failed");
        emit TokenDepositWithdrawn(address(token), to, amount);
    }


    function depositToken(uint64 orderId, address depositor, IERC20 inputToken, uint256 amount)
        hasExchange(address(inputToken))
        onlyFundManager
        external {
        require(address(inputToken) != address(0), "Input token cannont be ZERO_ADDRESS");
        UniswapExchangeInterface tokenExchange = UniswapExchangeInterface(uniswapFactory.getExchange(address(inputToken)));
        require(inputToken.allowance(depositor, address(this)) >= amount, "Not enough allowance");
        inputToken.transferFrom(depositor, address(this), amount);
        uint256 amountBought = 0;
        if (intermediaryToken != address(0)) {
            if (intermediaryToken != address(inputToken)) {
                inputToken.approve(address(tokenExchange), amount);
                amountBought = tokenExchange.tokenToTokenSwapInput(
                    amount  ,
                    1  ,
                    1  ,
                    UINT256_MAX  ,
                    intermediaryToken  );
            } else {
                 
                amountBought = amount;
            }
        } else {
            inputToken.approve(address(tokenExchange), amount);
            amountBought = tokenExchange.tokenToEthSwapInput(
                amount  ,
                1  ,
                UINT256_MAX  );
        }
        emit TokenDepositReceived(orderId, address(inputToken), amount, intermediaryToken, amountBought);
    }

    event EtherDepositReceived(uint64 indexed orderId, uint256 amount, address intermediaryToken, uint256 amountBought);
    event EtherDepositWithdrawn(address to, uint256 amount);
    event TokenDepositReceived(uint64 indexed orderId, address indexed inputToken, uint256 amount, address intermediaryToken, uint256 amountBought);
    event TokenDepositWithdrawn(address indexed token, address to, uint256 amount);

    modifier hasExchange(address token) {
        address tokenExchange = uniswapFactory.getExchange(token);
        require(tokenExchange != address(0), "Token doesn't have an exchange");
        _;
    }

    modifier onlyFundManager() {
        require(isFundManager(), "Only fund manager allowed");
        _;
    }
}