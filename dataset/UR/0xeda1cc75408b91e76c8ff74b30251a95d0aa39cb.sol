 

 

 

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



contract Vault {
    function execute(IERC20 _token, address _to, uint256 _val) external payable {
        _token.transfer(_to, _val);
         
        selfdestruct(address(uint256(msg.sender)));  
    }
}

 

pragma solidity ^0.5.11;




 
library Fabric {
     
    function getVault(bytes32 _key) internal view returns (address) {
        return address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        byte(0xff),
                        address(this),
                        _key,
                        keccak256(type(Vault).creationCode)
                    )
                )
            )
        );
    }

     
    function executeVault(bytes32 _key, IERC20 _token, address _to) internal returns (uint256 value) {
        address addr;
        bytes memory slotcode = type(Vault).creationCode;

         
        assembly{
           
          addr := create2(0, add(slotcode, 0x20), mload(slotcode), _key)
          if iszero(extcodesize(addr)) {
            revert(0, 0)
          }
        }

        value = _token.balanceOf(addr);
        Vault(addr).execute(_token, _to, value);
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

    event Executed(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _bought,
        uint256 _fee,
        address _owner,
        bytes32 _salt,
        address _relayer
    );

    address public constant ETH_ADDRESS = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint256 private constant never = uint(-1);

    UniswapFactory public uniswapFactory;

    mapping(bytes32 => uint256) public ethDeposits;

    constructor(UniswapFactory _uniswapFactory) public {
        uniswapFactory = _uniswapFactory;
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

    function _pull(
        IERC20 _from,
        bytes32 _key
    ) private returns (uint256 amount) {
        if (address(_from) == ETH_ADDRESS) {
            amount = ethDeposits[_key];
            ethDeposits[_key] = 0;
        } else {
            amount = _key.executeVault(_from, address(this));
        }
    }

    function _keyOf(
        IERC20 _from,
        IERC20 _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _from,
                _to,
                _return,
                _fee,
                _owner,
                _salt
            )
        );
    }

    function vaultOfOrder(
        IERC20 _from,
        IERC20 _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) public view returns (address) {
        return _keyOf(
            _from,
            _to,
            _return,
            _fee,
            _owner,
            _salt
        ).getVault();
    }

    function encodeTokenOrder(
        IERC20 _from,
        IERC20 _to,
        uint256 _amount,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external view returns (bytes memory) {
        return abi.encodeWithSelector(
            _from.transfer.selector,
            vaultOfOrder(
                _from,
                _to,
                _return,
                _fee,
                _owner,
                _salt
            ),
            _amount,
            abi.encode(
                _from,
                _to,
                _return,
                _fee,
                _owner,
                _salt
            )
        );
    }

    function encode(
        address _from,
        address _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external view returns (bytes memory) {
        return abi.encode(
            _from,
            _to,
            _return,
            _fee,
            _owner,
            _salt
        );
    }

    function decode(
        bytes calldata _data
    ) external view returns (
        address _from,
        address _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner
    ) {
        (
            _from,
            _to,
            _return,
            _fee,
            _owner
        ) = abi.decode(
            _data,
            (address, address, uint256, uint256, address)
        );
    }

    function exists(
        IERC20 _from,
        IERC20 _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external view returns (bool) {
        bytes32 key = _keyOf(
            _from,
            _to,
            _return,
            _fee,
            _owner,
            _salt
        );

        if (address(_from) == ETH_ADDRESS) {
            return ethDeposits[key] != 0;
        } else {
            return _from.balanceOf(key.getVault()) != 0;
        }
    }

    function canFill(
        IERC20 _from,
        IERC20 _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external view returns (bool) {
        bytes32 key = _keyOf(
            _from,
            _to,
            _return,
            _fee,
            _owner,
            _salt
        );

         
        uint256 amount;
        if (address(_from) == ETH_ADDRESS) {
            amount = ethDeposits[key];
        } else {
            amount = _from.balanceOf(key.getVault());
        }

        uint256 bought;

        if (address(_from) == ETH_ADDRESS) {
            uint256 sell = amount.sub(_fee);
            bought = uniswapFactory.getExchange(address(_to)).getEthToTokenInputPrice(sell);
        } else if (address(_to) == ETH_ADDRESS) {
            bought = uniswapFactory.getExchange(address(_from)).getTokenToEthInputPrice(amount);
            bought = bought.sub(_fee);
        } else {
            uint256 boughtEth = uniswapFactory.getExchange(address(_from)).getTokenToEthInputPrice(amount);
            bought = uniswapFactory.getExchange(address(_to)).getEthToTokenInputPrice(boughtEth.sub(_fee));
        }

        return bought >= _return;
    }

    function depositETH(
        bytes calldata _data
    ) external payable {
        bytes32 key = keccak256(_data);
        ethDeposits[key] = ethDeposits[key].add(msg.value);
        emit DepositETH(msg.value, _data);
    }

    function cancel(
        IERC20 _from,
        IERC20 _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external {
        require(msg.sender == _owner, "only owner can cancel");
        bytes32 key = _keyOf(
            _from,
            _to,
            _return,
            _fee,
            _owner,
            _salt
        );

        if (address(_from) == ETH_ADDRESS) {
            uint256 amount = ethDeposits[key];
            ethDeposits[key] = 0;
            msg.sender.transfer(amount);
        } else {
            key.executeVault(_from, msg.sender);
        }
    }

    function execute(
        IERC20 _from,
        IERC20 _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external {
        bytes32 key = _keyOf(
            _from,
            _to,
            _return,
            _fee,
            _owner,
            _salt
        );

         
        uint256 amount = _pull(_from, key);
        require(amount > 0, "order does not exists");

        uint256 bought;

        if (address(_from) == ETH_ADDRESS) {
             
            uint256 sell = amount.sub(_fee);
            bought = _ethToToken(uniswapFactory, _to, sell, _owner);
            msg.sender.transfer(_fee);
        } else if (address(_to) == ETH_ADDRESS) {
             
            bought = _tokenToEth(uniswapFactory, _from, amount, address(this));
            bought = bought.sub(_fee);

             
            msg.sender.transfer(_fee);
            _owner.transfer(bought);
        } else {
             
            uint256 boughtEth = _tokenToEth(uniswapFactory, _from, amount, address(this));
            msg.sender.transfer(_fee);

             
            bought = _ethToToken(uniswapFactory, _to, boughtEth.sub(_fee), _owner);
        }

        require(bought >= _return, "sell return is not enought");

        emit Executed(
            address(_from),
            address(_to),
            amount,
            bought,
            _fee,
            _owner,
            _salt,
            msg.sender
        );
    }

    function() external payable { }
}