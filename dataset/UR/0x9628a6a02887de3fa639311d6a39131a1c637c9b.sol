 

 

pragma solidity ^0.5.12;


interface IERC20 {
     
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);

     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    function transferFromWithFee(address sender, address recipient, uint256 amount) external returns (bool);

     
    function transferWithFee(address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.12;


interface IUniswapExchange {
     
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
     
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
     
    function setup(address token_addr) external;
}

 

pragma solidity ^0.5.12;


library IsContract {
    function isContract(address _addr) internal view returns (bool) {
        bytes32 codehash;
         
        assembly { codehash := extcodehash(_addr) }
        return codehash != bytes32(0) && codehash != bytes32(0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }
}

 

pragma solidity ^0.5.12;


interface IDefswapExchange {
    function base() external view returns (IERC20);
    function token() external view returns (IERC20);
    function addLiquidity(uint256 _tokens, uint256 _maxBase) external returns (uint256);
    function removeLiquidity(uint256 _amount, uint256 _minBase, uint256 _minTokens) external returns (uint256, uint256);
    function ethToTokenSwapInput(uint256 _minTokens) external payable returns (uint256);
    function baseToTokenSwapInput(uint256 _amount, uint256 _minTokens) external returns (uint256);
    function baseToTokenTransferInput(uint256 _amount, uint256 _minTokens, address _recipient) external returns (uint256);
    function tokenToEthSwapInput(uint256 _amount, uint256 _minEth) external returns (uint256);
    function tokenToEthTransferInput(uint256 _amount, uint256 _minEth, address _recipient) external returns (uint256);
    function tokenToEthExchangeTransferInput(uint256 _amount, uint256 _minTokens, address _recipient, address _exchangeAddr) external returns (uint256);
    function tokenToBaseSwapInput(uint256 _amount, uint256 _minBase) external returns (uint256);
    function tokenToBaseTransferInput(uint256 _amount, uint256 _minBase, address _recipient) external returns (uint256);
    function tokenToBaseExchangeTransferInput(uint256 _amount, uint256 _minTokens, address _recipient, address _exchangeAddr) external returns (uint256);
     
    function ethToTokenTransferInput(uint256 _minTokens, uint256 _deadline, address _recipient) external payable returns (uint256);
}

 

pragma solidity ^0.5.12;


 
contract ReentrancyGuard {
    uint256 private _guardFlag;

    uint256 private constant FLAG_LOCK = 2;
    uint256 private constant FLAG_UNLOCK = 1;

    constructor () internal {
         
         
        _guardFlag = FLAG_UNLOCK;
    }

     
    modifier nonReentrant() {
        require(_guardFlag != FLAG_LOCK, "reentrancy-guard: reentrant call");
        _guardFlag = FLAG_LOCK;
        _;
        _guardFlag = FLAG_UNLOCK;
    }
}

 

pragma solidity ^0.5.12;


library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x, "safemath: add overflow");
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x >= y, "safemath: sub overflow");
        return x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = x * y;
        require(z / x == y, "safemath: mul overflow");
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "safemath: div by zero");
        return x / y;
    }

    function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "safemath: div by zero");
        uint256 z = x / y;
        if (x % y != 0) {
            z = z + 1;
        }

        return z;
    }
}

 

pragma solidity ^0.5.12;


contract ERC20 is IERC20 {
    using SafeMath for uint256;

    uint256 internal p_totalSupply;
    mapping(address => uint256) private p_balance;
    mapping(address => mapping(address => uint256)) private p_allowance;

    string private p_symbol;
    string private p_name;
    uint256 private p_decimals;

    function _setMetadata(
        string memory _symbol,
        string memory _name,
        uint256 _decimals
    ) internal {
        p_symbol = _symbol;
        p_name = _name;
        p_decimals = _decimals;
    }

    function symbol() external view returns (string memory) {
        return p_symbol;
    }

    function name() external view returns (string memory) {
        return p_name;
    }

    function decimals() external view returns (uint256) {
        return p_decimals;
    }

    function totalSupply() external view returns (uint256) {
        return p_totalSupply;
    }

    function balanceOf(address _addr) external view returns (uint256) {
        return p_balance[_addr];
    }

    function allowance(address _addr, address _spender) external view returns (uint256) {
        return p_allowance[_addr][_spender];
    }

    function approve(address _spender, uint256 _wad) external returns (bool) {
        emit Approval(msg.sender, _spender, _wad);
        p_allowance[msg.sender][_spender] = _wad;
        return true;
    }

    function transfer(address _to, uint256 _wad) external returns (bool) {
        _transfer(msg.sender, _to, _wad);
        return true;
    }

    function transferWithFee(address _to, uint256 _wad) external returns (bool) {
        _transfer(msg.sender, _to, _wad);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _wad) external returns (bool) {
        _transfer(_from, _to, _wad);
        return true;
    }

    function transferFromWithFee(address _from, address _to, uint256 _wad) external returns (bool) {
        _transfer(_from, _to, _wad);
        return true;
    }

    function _mint(
        address _to,
        uint256 _wad
    ) internal {
        p_totalSupply = p_totalSupply.add(_wad);
        p_balance[_to] = p_balance[_to].add(_wad);

        emit Transfer(address(0), _to, _wad);
    }

    function _burn(
        address _from,
        uint256 _wad
    ) internal {
        uint256 balance = p_balance[_from];
        require(balance >= _wad, "erc20: burn _from balance is not enough");
        p_balance[_from] = balance.sub(_wad);
        p_totalSupply = p_totalSupply.sub(_wad);
        emit Transfer(_from, address(0), _wad);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _wad
    ) private {
        if (msg.sender != _from) {
            uint256 t_allowance = p_allowance[_from][msg.sender];
            if (t_allowance != uint(-1)) {
                require(t_allowance >= _wad, "erc20: sender allowance is not enough");
                p_allowance[_from][msg.sender] = t_allowance.sub(_wad);
            }
        }

        uint256 fromBalance = p_balance[_from];
        require(fromBalance >= _wad, "erc20: transfer _from balance is not enough");
        p_balance[_from] = fromBalance.sub(_wad);
        p_balance[_to] = p_balance[_to].add(_wad);

        emit Transfer(_from, _to, _wad);
    }
}

 

pragma solidity ^0.5.12;


library SafeDefERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 _token,
        address _to,
        uint256 _wad
    ) internal returns (uint256) {
        uint256 prev = _token.balanceOf(address(this));

        (bool success, ) = address(_token).call(
            abi.encodeWithSelector(
                _token.transfer.selector,
                _to,
                _wad
            )
        );

        require(success, "safedeferc20: error sending tokens");
        return prev.sub(_token.balanceOf(address(this)));
    }

    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _wad
    ) internal returns (uint256) {
        uint256 prev = _token.balanceOf(_to);

        (bool success, ) = address(_token).call(
            abi.encodeWithSelector(
                _token.transferFrom.selector,
                _from,
                _to,
                _wad
            )
        );

        require(success, "safedeferc20: error pulling tokens");
        return _token.balanceOf(_to).sub(prev);
    }
}

 

pragma solidity ^0.5.12;


library ShufUtils {
    using SafeMath for uint256;

    function takeFee(uint256 _a) internal pure returns (uint256) {
        if (_a == 1) {
            return 0;
        }

        uint256 fee = _a / 100;
        if (_a % 100 != 0) {
            fee = fee + 1;
        }

        return _a - (fee * 2);
    }

    function untakeFee(uint256 _a) internal pure returns (uint256) {
        if (_a == 1) {
            return 3;
        }

        uint256 aux = _a / 49;
        if (aux % 2 == 0) {
            aux = _a.add(aux);
            if (aux % 100 == 0) {
                return aux;
            } else {
                return aux.add(2);
            }
        } else {
            return _a.add(aux).add(1);
        }
    }
}

 

pragma solidity ^0.5.12;


contract DefswapExchange is IDefswapExchange, ERC20, ReentrancyGuard {
    using SafeDefERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 private p_base;
    IERC20 private p_token;
    IUniswapExchange private p_uniswap;

    string private constant SYMBOL_PREFIX = "SHUF-";
    string private constant NAME_SUFIX = " - defswap.io pooled";
    uint256 private constant DECIMALS = 18;

    event AddLiquidity(
        address indexed _provider,
        uint256 _baseAmount,
        uint256 _tokenAmount,
        uint256 _minted
    );

    event RemoveLiquidity(
        address indexed _provider,
        uint256 _baseAmount,
        uint256 _tokenAmount,
        uint256 _burned,
        uint256 _type
    );

    event TokenPurchase(
        address indexed _buyer,
        uint256 _baseSold,
        uint256 _tokensBought,
        uint256 _baseReserve,
        uint256 _tokenReserve,
        address _recipient
    );

    event BasePurchase(
        address indexed _buyer,
        uint256 _tokensSold,
        uint256 _baseBought,
        uint256 _tokenReserve,
        uint256 _baseReserve,
        address _recipient
    );

    constructor(IERC20 _base, IERC20 _token, IUniswapExchange _uniswap) public {
        require(_uniswap.tokenAddress() == address(_base), "defswap: uniswap token doesn't match");
        require(address(_base) != address(_token), "defswap: token and base can't be the same");

        p_base = _base;
        p_token = _token;
        p_uniswap = _uniswap;

        approveUniswap();
        buildMetadata();
    }

    function approveUniswap() public nonReentrant {
        p_base.approve(
            address(p_uniswap),
            uint(-1)
        );
    }

    function buildMetadata() public nonReentrant {
        address token = address(p_token);
        require(gasleft() >= 402000, "defswap: gasleft build metadata is not enough");

        (
            bool successName,
            bytes memory name
        ) = token.staticcall(
            abi.encodeWithSelector(p_token.name.selector)
        );

        (
            bool successSymbol,
            bytes memory symbol
        ) = token.staticcall(
            abi.encodeWithSelector(p_token.symbol.selector)
        );

        _setMetadata(
            string(abi.encodePacked(SYMBOL_PREFIX, successSymbol ? abi.decode(symbol, (string)) : "???")),
            string(abi.encodePacked(successName ? abi.decode(name, (string)) : "Unknown", NAME_SUFIX)),
            DECIMALS
        );
    }

    function base() external view returns (IERC20) {
        return p_base;
    }

    function token() external view returns (IERC20) {
        return p_token;
    }

    function uniswap() external view returns (IUniswapExchange) {
        return p_uniswap;
    }

    function addLiquidity(
        uint256 _tokens,
        uint256 _maxBase
    ) external nonReentrant returns (uint256 minted) {
        IERC20 t_token = p_token;
        IERC20 t_base = p_base;

         
         
        uint256 received = t_token.safeTransferFrom(msg.sender, address(this), _tokens);
        require(received != 0, "defswap: pull zero tokens is not allowed");

        uint256 baseReceived;
        uint256 t_totalSupply = p_totalSupply;

         
        if (t_totalSupply == 0) {
             
            require(t_base.transferFrom(msg.sender, address(this), _maxBase), "defswap: error pulling base tokens");
            baseReceived = ShufUtils.takeFee(_maxBase);
            minted = baseReceived;
        } else {
             
            uint256 tokenReserve = t_token.balanceOf(address(this)).sub(received);
            uint256 baseReserve = t_base.balanceOf(address(this));
            uint256 requiredPull = received.mul(baseReserve).divRound(tokenReserve);

             
            baseReceived = t_base.safeTransferFrom(msg.sender, address(this), ShufUtils.untakeFee(requiredPull));
            require(baseReceived <= _maxBase, "defswap: _maxBase is below of pulled required");
            require(baseReceived >= requiredPull, "defswap: pulled base is not enough");

             
            minted = baseReceived.mul(t_totalSupply).div(baseReserve);
        }

         
        emit AddLiquidity(msg.sender, baseReceived, received, minted);
        _mint(msg.sender, minted);
    }

    function removeLiquidity(
        uint256 _amount,
        uint256 _minBase,
        uint256 _minTokens
    ) external nonReentrant returns (
        uint256 baseAmount,
        uint256 tokenAmount
    ) {
         
        uint256 t_totalSupply = p_totalSupply;
        require(t_totalSupply != 0, "defswap: pool is empty");

         
        IERC20 t_token = p_token;
        IERC20 t_base = p_base;

         
        uint256 tokenReserve = t_token.balanceOf(address(this));
        uint256 baseReserve = t_base.balanceOf(address(this));

         
        baseAmount = _amount.mul(baseReserve) / t_totalSupply;
        tokenAmount = _amount.mul(tokenReserve) / t_totalSupply;

         
        emit RemoveLiquidity(msg.sender, baseAmount, tokenAmount, _amount, 0);
        _burn(msg.sender, _amount);

         
        require(baseAmount >= _minBase, "defswap: baseAmount is below _minBase");

         
        require(t_token.safeTransfer(msg.sender, tokenAmount) >= _minTokens, "defswap: tokenAmount is below _minTokens");
        t_base.transferWithFee(msg.sender, baseAmount);  
    }

    function removeBaseLiquidity(
        uint256 _amount,
        uint256 _minBase
    ) external nonReentrant returns (
        uint256 baseAmount
    ) {
         
        uint256 t_totalSupply = p_totalSupply;
        require(t_totalSupply != 0, "defswap: pool is empty");

         
        IERC20 t_base = p_base;

         
        uint256 baseReserve = t_base.balanceOf(address(this));

         
        baseAmount = _amount.mul(baseReserve) / t_totalSupply;

         
         
        emit RemoveLiquidity(msg.sender, baseAmount, 0, _amount, 1);
        _burn(msg.sender, _amount);

         
        require(baseAmount >= _minBase, "defswap: baseAmount is below _minBase");
        t_base.transferWithFee(msg.sender, baseAmount);  
    }

    function removeTokenLiquidity(
        uint256 _amount,
        uint256 _minTokens
    ) external nonReentrant returns (
        uint256 tokenAmount
    ) {
         
        uint256 t_totalSupply = p_totalSupply;
        require(t_totalSupply != 0, "defswap: pool is empty");

         
        IERC20 t_token = p_token;

         
        uint256 tokenReserve = t_token.balanceOf(address(this));

         
        tokenAmount = _amount.mul(tokenReserve) / t_totalSupply;

         
         
        emit RemoveLiquidity(msg.sender, 0, tokenAmount, _amount, 2);
        _burn(msg.sender, _amount);

         
        require(t_token.safeTransfer(msg.sender, tokenAmount) >= _minTokens, "defswap: tokenAmount is below _minTokens");
    }

    function getBaseToTokenPrice(uint256 _baseSold) external view returns (uint256 tokensBought) {
        tokensBought = _getInputPrice(
            _baseSold,
            p_base.balanceOf(address(this)),
            p_token.balanceOf(address(this))
        );
    }

    function getTokenToBasePrice(uint256 _tokenSold) external view returns (uint256 baseBought) {
        baseBought = _getInputPrice(
            _tokenSold,
            p_token.balanceOf(address(this)),
            p_base.balanceOf(address(this))
        );
    }

    function ethToTokenSwapInput(
        uint256 _minTokens
    ) external nonReentrant payable returns (uint256 bought) {
         
        uint256 baseBought = msg.value != 0 ? ShufUtils.takeFee(
            p_uniswap.ethToTokenSwapInput.value(msg.value)(1, uint(-1))
        ) : 0;

         
        bought = _baseToToken(
            p_base,      
            p_token,     
            baseBought,  
            _minTokens,  
            msg.sender,  
            msg.sender   
        );
    }

     
    function ethToTokenTransferInput(
        uint256 _minTokens,
        uint256 _deadline,
        address _recipient
    ) external nonReentrant payable returns (uint256 bought) {
         
        require(_deadline >= block.timestamp, "defswap: expired transaction");

         
        uint256 baseBought = msg.value != 0 ? ShufUtils.takeFee(
            p_uniswap.ethToTokenSwapInput.value(msg.value)(1, uint(-1))
        ) : 0;

         
        bought = _baseToToken(
            p_base,      
            p_token,     
            baseBought,  
            _minTokens,  
            msg.sender,  
            _recipient   
        );
    }

    function baseToTokenSwapInput(
        uint256 _amount,
        uint256 _minTokens
    ) external nonReentrant returns (uint256 bought) {
         
        IERC20 t_base = p_base;

         
        t_base.transferFromWithFee(msg.sender, address(this), _amount);
         
        uint256 received = ShufUtils.takeFee(_amount);

         
        bought = _baseToToken(
            t_base,      
            p_token,     
            received,    
            _minTokens,  
            msg.sender,  
            msg.sender   
        );
    }

    function baseToTokenTransferInput(
        uint256 _amount,
        uint256 _minTokens,
        address _recipient
    ) external nonReentrant returns (uint256 bought) {
         
        IERC20 t_base = p_base;

         
        t_base.transferFromWithFee(msg.sender, address(this), _amount);
         
        uint256 received = ShufUtils.takeFee(_amount);

         
        bought = _baseToToken(
            t_base,      
            p_token,     
            received,    
            _minTokens,  
            msg.sender,  
            _recipient   
        );
    }

    function tokenToEthSwapInput(
        uint256 _amount,
        uint256 _minEth
    ) external nonReentrant returns (uint256 bought) {
         
        IERC20 t_token = p_token;

         
         
        uint256 received = t_token.safeTransferFrom(msg.sender, address(this), _amount);

         
         
        uint256 baseBought = ShufUtils.takeFee(
            _tokenToBase(
                p_base,        
                t_token,       
                received,      
                0,             
                msg.sender,    
                address(this)  
            )
        );

         
        bought = baseBought != 0 ? p_uniswap.tokenToEthTransferInput(
            baseBought,  
            1,           
            uint(-1),    
            msg.sender   
        ) : 0;

         
        require(bought >= _minEth, "defswap: eth bought is below _minEth");
    }

    function tokenToEthTransferInput(
        uint256 _amount,
        uint256 _minEth,
        address _recipient
    ) external nonReentrant returns (uint256 bought) {
         
        IERC20 t_token = p_token;

         
         
        uint256 received = t_token.safeTransferFrom(msg.sender, address(this), _amount);

         
         
        uint256 baseBought = ShufUtils.takeFee(
            _tokenToBase(
                p_base,        
                t_token,       
                received,      
                0,             
                msg.sender,    
                address(this)  
            )
        );

         
        bought = baseBought != 0 ? p_uniswap.tokenToEthTransferInput(
            baseBought,  
            1,           
            uint(-1),    
            _recipient   
        ) : 0;

         
        require(bought >= _minEth, "defswap: eth bought is below _minEth");
    }

    function tokenToEthExchangeTransferInput(
        uint256 _amount,
        uint256 _minTokens,
        address _recipient,
        address _exchangeAddr
    ) external nonReentrant returns (uint256 bought) {
         
        IERC20 t_token = p_token;

         
         
        uint256 received = t_token.safeTransferFrom(msg.sender, address(this), _amount);

         
         
        uint256 baseBought = ShufUtils.takeFee(
            _tokenToBase(
                p_base,        
                t_token,       
                received,      
                0,             
                msg.sender,    
                address(this)  
            )
        );

         
         
        uint256 ethBought = baseBought != 0 ? p_uniswap.tokenToEthSwapInput(
            baseBought,  
            1,           
            uint(-1)     
        ) : 0;

         
        bought = ethBought != 0 ? IUniswapExchange(_exchangeAddr).ethToTokenTransferInput.value(
            ethBought    
        )(
            1,           
            uint(-1),    
            _recipient   
        ) : 0;

         
         
         
        require(bought >= _minTokens, "defswap: tokens bought is below _minTokens");
    }

    function tokenToBaseSwapInput(
        uint256 _amount,
        uint256 _minBase
    ) external nonReentrant returns (uint256 bought) {
         
        IERC20 t_token = p_token;

         
         
        uint256 received = t_token.safeTransferFrom(msg.sender, address(this), _amount);

         
        bought = _tokenToBase(
            p_base,      
            t_token,     
            received,    
            _minBase,    
            msg.sender,  
            msg.sender   
        );
    }

    function tokenToBaseTransferInput(
        uint256 _amount,
        uint256 _minBase,
        address _recipient
    ) external nonReentrant returns (uint256 bought) {
         
        IERC20 t_token = p_token;

         
         
        uint256 received = t_token.safeTransferFrom(msg.sender, address(this), _amount);

         
        bought = _tokenToBase(
            p_base,      
            t_token,     
            received,    
            _minBase,    
            msg.sender,  
            _recipient   
        );
    }

    function tokenToBaseExchangeTransferInput(
        uint256 _amount,
        uint256 _minTokens,
        address _recipient,
        address _exchangeAddr
    ) external nonReentrant returns (uint256 bought) {
         
         
        require(_exchangeAddr != address(p_uniswap), "defswap: _exchange can't be Uniswap");

         
        IERC20 t_token = p_token;
        IERC20 t_base = p_base;

         
         
        uint256 received = t_token.safeTransferFrom(msg.sender, address(this), _amount);

         
        uint256 tokenReserve = t_token.balanceOf(address(this)).sub(received);
        uint256 baseReserve = t_base.balanceOf(address(this));

         
         
        uint256 baseBought = _getInputPrice(received, tokenReserve, baseReserve);
        emit BasePurchase(msg.sender, received, baseBought, tokenReserve, baseReserve, _exchangeAddr);

         
         
         
        t_base.approve(_exchangeAddr, baseBought);
        bought = IDefswapExchange(_exchangeAddr).baseToTokenTransferInput(
            baseBought,  
            _minTokens,  
            _recipient   
        );

         
        t_base.approve(_exchangeAddr, 0);
    }

    function _getInputPrice(
        uint256 _inputAmount,
        uint256 _inputReserve,
        uint256 _outputReserve
    ) private pure returns (uint256) {
        require(_inputReserve != 0 && _outputReserve != 0, "defswap: one reserve is empty");
        uint256 inputAmountWithFee = _inputAmount.mul(997);
        uint256 numerator = inputAmountWithFee.mul(_outputReserve);
        uint256 denominator = _inputReserve.mul(1000).add(inputAmountWithFee);
        return numerator / denominator;
    }

    function _baseToToken(
        IERC20 t_base,
        IERC20 t_token,
        uint256 _amount,
        uint256 _minTokens,
        address _buyer,
        address _recipient
    ) private returns (uint256 tokensBought) {
         
        uint256 tokenReserve = t_token.balanceOf(address(this));
        uint256 baseReserve = t_base.balanceOf(address(this)).sub(_amount);

         
        tokensBought = _getInputPrice(_amount, baseReserve, tokenReserve);

         
        require(tokensBought >= _minTokens, "defswap: bought tokens below _minTokens");
        require(t_token.safeTransfer(_recipient, tokensBought) != 0 || tokensBought == 0, "defswap: error sending tokens");

        emit TokenPurchase(_buyer, _amount, tokensBought, baseReserve, tokenReserve, _recipient);
    }

    function _tokenToBase(
        IERC20 t_base,
        IERC20 t_token,
        uint256 _amount,
        uint256 _minBase,
        address _buyer,
        address _recipient
    ) private returns (uint256 baseBought) {
         
        uint256 tokenReserve = t_token.balanceOf(address(this)).sub(_amount);
        uint256 baseReserve = t_base.balanceOf(address(this));

         
        baseBought = _getInputPrice(_amount, tokenReserve, baseReserve);

         
        require(baseBought >= _minBase, "defswap: bought base below _minBase");
        t_base.transferWithFee(_recipient, baseBought);

        emit BasePurchase(_buyer, _amount, baseBought, tokenReserve, baseReserve, _recipient);
    }

    function() external payable {
         
        require(msg.sender != tx.origin, "defswap: ETH rejected");
    }
}

 

pragma solidity ^0.5.12;


contract DefswapFactory {
    using IsContract for address;

    IUniswapExchange public uniswap;
    IERC20 public base;

    event CreatedExchange(address indexed _token, address indexed _exchange);

    address[] private p_tokens;
    mapping(address => address) public tokenToExchange;
    mapping(address => address) public exchangeToToken;

    constructor(IERC20 _base, IUniswapExchange _uniswap) public {
        require(_uniswap.tokenAddress() == address(_base), "defswap-factory: uniswap token doesn't match");

        base = _base;
        uniswap = _uniswap;
    }

    function getToken(uint256 _i) external view returns (address) {
        require(_i < p_tokens.length, "defswap-factory: array out of bounds");
        return p_tokens[_i];
    }

    function getExchange(uint256 _i) external view returns (address) {
        require(_i < p_tokens.length, "defswap-factory: array out of bounds");
        return tokenToExchange[p_tokens[_i]];
    }

    function createExchange(address _token) external returns (address exchange) {
        require(tokenToExchange[_token] == address(0), "defswap-factory: exchange already exists");
        require(_token.isContract(), "defswap-factory: _token has to be a contract");

        exchange = address(
            new DefswapExchange(
                base,
                IERC20(_token),
                uniswap
            )
        );

        emit CreatedExchange(_token, exchange);

        tokenToExchange[_token] = exchange;
        exchangeToToken[exchange] = _token;
        p_tokens.push(_token);
    }
}