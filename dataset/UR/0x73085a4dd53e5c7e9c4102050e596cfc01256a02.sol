 

 

pragma solidity ^0.5.11;

 
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



 
library Fabric {
     
    bytes public constant code = hex"6012600081600A8239F360008060448082803781806038355AF132FF";
    bytes32 public constant vaultCodeHash = bytes32(0xfa3da1081bc86587310fce8f3a5309785fc567b9b20875900cb289302d6bfa97);

     
    function getVault(bytes32 _key) internal view returns (address) {
        return address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        byte(0xff),
                        address(this),
                        _key,
                        vaultCodeHash
                    )
                )
            )
        );
    }

     
    function executeVault(bytes32 _key, IERC20 _token, address _to) internal returns (uint256 value) {
        address addr;
        bytes memory slotcode = code;

         
        assembly{
           
          addr := create2(0, add(slotcode, 0x20), mload(slotcode), _key)
          if iszero(extcodesize(addr)) {
            revert(0, 0)
          }
        }

        value = _token.balanceOf(addr);
         
        (bool success, ) = addr.call(
            abi.encodePacked(
                abi.encodeWithSelector(
                    _token.transfer.selector,
                    _to,
                    value
                ),
                address(_token)
            )
        );

        require(success, "error pulling tokens");
    }
}

 

pragma solidity ^0.5.11;







contract UniswapEX {
    using SafeMath for uint256;
    using Fabric for bytes32;

    event DepositETH(
        uint256 _amount,
        bytes _data
    );

    event OrderExecuted(
        bytes32 indexed _key,
        address _fromToken,
        address _toToken,
        uint256 _minReturn,
        uint256 _fee,
        address _owner,
        bytes32 _salt,
        address _relayer,
        uint256 _amount,
        uint256 _bought
    );

    event OrderCancelled(
        bytes32 indexed _key,
        address _fromToken,
        address _toToken,
        uint256 _minReturn,
        uint256 _fee,
        address _owner,
        bytes32 _salt,
        uint256 _amount
    );

    address public constant ETH_ADDRESS = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint256 private constant never = uint(-1);

    UniswapFactory public uniswapFactory;

    mapping(bytes32 => uint256) public ethDeposits;

    constructor(UniswapFactory _uniswapFactory) public {
        uniswapFactory = _uniswapFactory;
    }

    function() external payable { }

    function depositEth(
        bytes calldata _data
    ) external payable {
        require(msg.value > 0, "No value provided");
         

        bytes32 key = keccak256(_data);
        ethDeposits[key] = ethDeposits[key].add(msg.value);
        emit DepositETH(msg.value, _data);
    }

    function cancelOrder(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _minReturn,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external {
        require(msg.sender == _owner, "Only the owner of the order can cancel it");
        bytes32 key = _keyOf(
            _fromToken,
            _toToken,
            _minReturn,
            _fee,
            _owner,
            _salt
        );

        uint256 amount;
        if (address(_fromToken) == ETH_ADDRESS) {
            amount = ethDeposits[key];
            ethDeposits[key] = 0;
            msg.sender.transfer(amount);
        } else {
            amount = key.executeVault(_fromToken, msg.sender);
        }

        emit OrderCancelled(
            key,
            address(_fromToken),
            address(_toToken),
            _minReturn,
            _fee,
            _owner,
            _salt,
            amount
        );
    }

    function executeOrder(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _minReturn,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external {
        bytes32 key = _keyOf(
            _fromToken,
            _toToken,
            _minReturn,
            _fee,
            _owner,
            _salt
        );

         
        uint256 amount = _pullOrder(_fromToken, key);
        require(amount > 0, "The order does not exists");

        uint256 bought;

        if (address(_fromToken) == ETH_ADDRESS) {
             
            uint256 sell = amount.sub(_fee);
            bought = _ethToToken(uniswapFactory, _toToken, sell, _owner);
            msg.sender.transfer(_fee);
        } else if (address(_toToken) == ETH_ADDRESS) {
             
            bought = _tokenToEth(uniswapFactory, _fromToken, amount, address(this));
            bought = bought.sub(_fee);

             
            msg.sender.transfer(_fee);
            _owner.transfer(bought);
        } else {
             
            uint256 boughtEth = _tokenToEth(uniswapFactory, _fromToken, amount, address(this));
            msg.sender.transfer(_fee);

             
            bought = _ethToToken(uniswapFactory, _toToken, boughtEth.sub(_fee), _owner);
        }

        require(bought >= _minReturn, "Tokens bought are not enough");

        emit OrderExecuted(
            key,
            address(_fromToken),
            address(_toToken),
            _minReturn,
            _fee,
            _owner,
            _salt,
            msg.sender,
            amount,
            bought
        );
    }

    function encodeTokenOrder(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _amount,
        uint256 _minReturn,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external view returns (bytes memory) {
        return abi.encodeWithSelector(
            _fromToken.transfer.selector,
            vaultOfOrder(
                _fromToken,
                _toToken,
                _minReturn,
                _fee,
                _owner,
                _salt
            ),
            _amount,
            abi.encode(
                _fromToken,
                _toToken,
                _minReturn,
                _fee,
                _owner,
                _salt
            )
        );
    }

    function encodeETHOrder(
        address _fromToken,
        address _toToken,
        uint256 _minReturn,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external pure returns (bytes memory) {
        return abi.encode(
            _fromToken,
            _toToken,
            _minReturn,
            _fee,
            _owner,
            _salt
        );
    }

    function decodeOrder(
        bytes calldata _data
    ) external pure returns (
        address fromToken,
        address toToken,
        uint256 minReturn,
        uint256 fee,
        address payable owner,
        bytes32 salt
    ) {
        (
            fromToken,
            toToken,
            minReturn,
            fee,
            owner,
            salt
        ) = abi.decode(
            _data,
            (address, address, uint256, uint256, address, bytes32)
        );
    }

    function existOrder(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _minReturn,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external view returns (bool) {
        bytes32 key = _keyOf(
            _fromToken,
            _toToken,
            _minReturn,
            _fee,
            _owner,
            _salt
        );

        if (address(_fromToken) == ETH_ADDRESS) {
            return ethDeposits[key] != 0;
        } else {
            return _fromToken.balanceOf(key.getVault()) != 0;
        }
    }

    function canExecuteOrder(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _minReturn,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external view returns (bool) {
        bytes32 key = _keyOf(
            _fromToken,
            _toToken,
            _minReturn,
            _fee,
            _owner,
            _salt
        );

         
        uint256 amount;
        if (address(_fromToken) == ETH_ADDRESS) {
            amount = ethDeposits[key];
        } else {
            amount = _fromToken.balanceOf(key.getVault());
        }

        uint256 bought;

        if (address(_fromToken) == ETH_ADDRESS) {
            uint256 sell = amount.sub(_fee);
            bought = uniswapFactory.getExchange(address(_toToken)).getEthToTokenInputPrice(sell);
        } else if (address(_toToken) == ETH_ADDRESS) {
            bought = uniswapFactory.getExchange(address(_fromToken)).getTokenToEthInputPrice(amount);
            bought = bought.sub(_fee);
        } else {
            uint256 boughtEth = uniswapFactory.getExchange(address(_fromToken)).getTokenToEthInputPrice(amount);
            bought = uniswapFactory.getExchange(address(_toToken)).getEthToTokenInputPrice(boughtEth.sub(_fee));
        }

        return bought >= _minReturn;
    }

    function vaultOfOrder(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _minReturn,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) public view returns (address) {
        return _keyOf(
            _fromToken,
            _toToken,
            _minReturn,
            _fee,
            _owner,
            _salt
        ).getVault();
    }

    function _ethToToken(
        UniswapFactory _uniswapFactory,
        IERC20 _token,
        uint256 _amount,
        address _dest
    ) private returns (uint256) {
        UniswapExchange uniswap = _uniswapFactory.getExchange(address(_token));

        if (_dest != address(this)) {
            return uniswap.ethToTokenTransferInput.value(_amount)(1, never, _dest);
        } else {
            return uniswap.ethToTokenSwapInput.value(_amount)(1, never);
        }
    }

    function _tokenToEth(
        UniswapFactory _uniswapFactory,
        IERC20 _token,
        uint256 _amount,
        address _dest
    ) private returns (uint256) {
         
        UniswapExchange uniswap = _uniswapFactory.getExchange(address(_token));

         
        uint256 prevAllowance = _token.allowance(address(this), address(uniswap));
        if (prevAllowance < _amount) {
            if (prevAllowance != 0) {
                _token.approve(address(uniswap), 0);  
            }

            _token.approve(address(uniswap), uint(-1));
        }

         
        if (_dest != address(this)) {
            return uniswap.tokenToEthTransferInput(_amount, 1, never, _dest);
        } else {
            return uniswap.tokenToEthSwapInput(_amount, 1, never);
        }
    }

    function _pullOrder(
        IERC20 _fromToken,
        bytes32 _key
    ) private returns (uint256 amount) {
        if (address(_fromToken) == ETH_ADDRESS) {
            amount = ethDeposits[_key];
            ethDeposits[_key] = 0;
        } else {
            amount = _key.executeVault(_fromToken, address(this));
        }
    }

    function _keyOf(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _minReturn,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _fromToken,
                _toToken,
                _minReturn,
                _fee,
                _owner,
                _salt
            )
        );
    }
}