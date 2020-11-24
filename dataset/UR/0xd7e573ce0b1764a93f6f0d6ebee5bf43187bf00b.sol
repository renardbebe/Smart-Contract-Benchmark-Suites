 

 

pragma solidity ^0.5.12;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

pragma solidity ^0.5.11;


 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.11;


contract UniswapExchange {
    event EthPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed eth_bought);
     
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
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
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
    function totalSupply() external view returns (uint256);
     
    function setup(address token_addr) external;
}

 

pragma solidity ^0.5.11;




contract UniswapFactory {
     
    address public exchangeTemplate;
    uint256 public tokenCount;
     
    function createExchange(address token) external returns (address exchange);
     
    function getExchange(address token) external view returns (UniswapExchange exchange);
    function getToken(address exchange) external view returns (IERC20 token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
     
    function initializeFactory(address template) external;
}

 

pragma solidity ^0.5.11;






contract Multiswap {
    using SafeMath for uint256;

    event MultiSwapExecuted(
        IERC20[] _fromTokens,
        IERC20 indexed _toToken,
        uint256[] _fromTokensAmount,
        uint256 _minReturn,
        uint256 _bought,
        address _beneficiary
    );

    address public constant ETH_ADDRESS = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint256 private constant never = uint(-1);

    UniswapFactory public uniswapFactory;

    constructor(UniswapFactory _uniswapFactory) public {
        uniswapFactory = _uniswapFactory;
    }

    function() external payable {
        require(
             
            msg.sender != tx.origin,
            "Only contracts can send ETH directly by mistake"
        );
    }

    function swap(
        IERC20[] calldata _fromTokens,
        IERC20 _toToken,
        uint256[] calldata _fromTokensAmount,
        uint256 _minReturn,
        address _beneficiary
    ) external payable {
        uint256 bought = 0;
        uint256 ethBough = 0;

        for(uint256 i = 0; i < _fromTokens.length; i++) {
            IERC20 fromToken = _fromTokens[i];
            uint256 amount = _fromTokensAmount[i];

            require(address(fromToken) != address(0), "Invalid address");

            require(amount > 0, "Amount should be greater than 0");

            if (address(_toToken) != ETH_ADDRESS) {
                if (address(fromToken) == ETH_ADDRESS) {
                    require(msg.value == amount, "invalid amount ETH");

                    ethBough = ethBough.add(amount);
                } else {
                      
                    fromToken.transferFrom(msg.sender, address(this), amount);

                     
                    ethBough = ethBough.add(_tokenToEth(uniswapFactory, fromToken, amount, address(this)));
                }
            } else {
                 
                fromToken.transferFrom(msg.sender, address(this), amount);

                 
                bought = bought.add(_tokenToEth(uniswapFactory, fromToken, amount, _beneficiary));
            }
        }

        if (ethBough > 0) {
            bought = _ethToToken(uniswapFactory, _toToken, ethBough, _beneficiary);
        }

        require(bought >= _minReturn, "Tokens bought are not enough");

        emit MultiSwapExecuted(
            _fromTokens,
            _toToken,
            _fromTokensAmount,
            _minReturn,
            bought,
            _beneficiary
        );
    }

    function canSwap(
        IERC20[] calldata _fromTokens,
        IERC20 _toToken,
        uint256[] calldata _fromTokensAmount,
        uint256 _minReturn
    ) external view returns (bool) {
        uint256 bought;
        uint256 ethBough = 0;

        for (uint256 i; i < _fromTokens.length; i++) {
            IERC20 fromToken = _fromTokens[i];
            uint256 amount = _fromTokensAmount[i];

            if (address(_toToken) != ETH_ADDRESS) {
                if (address(fromToken) == ETH_ADDRESS) {
                    ethBough += amount;
                } else {
                    ethBough += uniswapFactory.getExchange(address(fromToken)).getTokenToEthInputPrice(amount);
                }
            } else {
                bought += uniswapFactory.getExchange(address(fromToken)).getTokenToEthInputPrice(amount);
            }
        }

        if (ethBough > 0) {
            bought = uniswapFactory.getExchange(address(_toToken)).getEthToTokenInputPrice(ethBough);
        }

        return bought >= _minReturn;
    }

    function _ethToToken (
        UniswapFactory _uniswapFactory,
        IERC20 _token,
        uint256 _amount,
        address _dest
    ) private returns (uint256) {
        UniswapExchange uniswap = _uniswapFactory.getExchange(address(_token));
        require(address(uniswap) != address(0), "The exchange should exist");

        return uniswap.ethToTokenTransferInput.value(_amount)(1, never, _dest);
    }

    function _tokenToEth(
        UniswapFactory _uniswapFactory,
        IERC20 _token,
        uint256 _amount,
        address _dest
    ) private returns (uint256) {
        UniswapExchange uniswap = _uniswapFactory.getExchange(address(_token));
        require(address(uniswap) != address(0), "The exchange should exist");

        approveTokenIfNeeded(uniswap, _token, _amount);

         
        if (_dest != address(this)) {
            return uniswap.tokenToEthTransferInput(_amount, 1, never, _dest);
        } else {
            return uniswap.tokenToEthSwapInput(_amount, 1, never);
        }
    }

    function approveTokenIfNeeded(
        UniswapExchange _uniswap,
        IERC20 _token,
        uint256 _amount
    ) private {
         
        uint256 prevAllowance = _token.allowance(address(this), address(_uniswap));
        if (prevAllowance < _amount) {
            if (prevAllowance != 0) {
                _token.approve(address(_uniswap), 0);
            }

            _token.approve(address(_uniswap), uint(-1));
        }
    }
}