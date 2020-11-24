 

pragma solidity ^0.4.26;

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

interface KyberNetworkProxyInterface {
    function maxGasPrice() public view returns(uint);
    function getUserCapInWei(address user) public view returns(uint);
    function getUserCapInTokenWei(address user, IERC20 token) public view returns(uint);
    function enabled() public view returns(bool);
    function info(bytes32 id) public view returns(uint);
    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) public view returns (uint expectedRate, uint slippageRate);
    function tradeWithHint(IERC20 src, uint srcAmount, IERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
    function swapEtherToToken(IERC20 token, uint minRate) public payable returns (uint);
    function swapTokenToEther(IERC20 token, uint tokenQty, uint minRate) public returns (uint);
}

interface OrFeedInterface {
    function getExchangeRate ( string fromSymbol, string toSymbol, string venue, uint256 amount ) external view returns ( uint256 );
    function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
    function getTokenAddress ( string symbol ) external view returns ( address );
    function getSynthBytes32 ( string symbol ) external view returns ( bytes32 );
    function getForexAddress ( string symbol ) external view returns ( address );
}

contract Ourbitrage {
    uint256 internal constant _DEFAULT_MAX_RATE = 8 * (10 ** 27);  
    IERC20 internal constant _ETH_TOKEN_ADDRESS = IERC20(0x00EeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);  

    KyberNetworkProxyInterface internal _kyber;
    OrFeedInterface internal _orfeed;

     
    mapping(string => UniswapExchangeInterface) internal _uniswap;

    address internal _owner;
    address internal _feeCollector;

     
    mapping(string => address) internal _fundingToken;

     
    mapping(string => uint) internal _allowedSlippage;

     
 

    event Arbitrage(string arbType, address fundingToken, uint profit, uint loss);

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
     
     

    constructor() public {
        _owner = msg.sender;

 
 
    }

    function () external payable  {}

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function getVersion() public pure returns (string) {
        return "0.0.2";
    }

     
     
     

    function getPrice(string from, string to, string venue, uint256 amount) public view returns (uint256) {
        return _orfeed.getExchangeRate(from, to, venue, amount);
    }

    function uniswapPriceEthForToken(string tokenSymbol, uint tokenAmount) public view returns (uint256) {
        return _uniswap[tokenSymbol].getTokenToEthInputPrice(tokenAmount);
    }

    function uniswapPriceTokenForEth(string tokenSymbol, uint ethAmount) public view returns (uint256) {
        return _uniswap[tokenSymbol].getEthToTokenInputPrice(ethAmount);
    }

    function kyberPriceEthForToken(string tokenSymbol, uint tokenAmount) public view returns (uint expectedRate, uint slippageRate) {
        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
        (expectedRate, slippageRate) = _kyber.getExpectedRate(token, _ETH_TOKEN_ADDRESS, tokenAmount);
    }

    function kyberPriceTokenForEth(string tokenSymbol, uint ethAmount) public view returns (uint expectedRate, uint slippageRate) {
        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
        (expectedRate, slippageRate) = _kyber.getExpectedRate(_ETH_TOKEN_ADDRESS, token, ethAmount);
    }

    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getFundingTokenAddress(string tokenSymbol) public view returns (address) {
        return _fundingToken[tokenSymbol];
    }

    function getFundingTokenBalance(string tokenSymbol) public view returns (uint256) {
        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
        return token.balanceOf(address(this));
    }

    function getWalletTokenBalance(string tokenSymbol) public view returns (uint256) {
        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
        return token.balanceOf(msg.sender);
    }

     
     
     

    function setKyberNetworkProxyInterface(KyberNetworkProxyInterface kyber) public onlyOwner {
        require(address(kyber) != address(0), "Invalid KyberNetworkProxyInterface address");
        _kyber = KyberNetworkProxyInterface(kyber);
    }

    function setOrFeedInterface(OrFeedInterface orfeed) public onlyOwner {
        require(address(orfeed) != address(0), "Invalid OrFeedInterface address");
        _orfeed = OrFeedInterface(orfeed);
    }

    function setFeeCollector(address feeCollector) public onlyOwner {
        require(address(feeCollector) != address(0), "Invalid Fee Collector address");
        _feeCollector = feeCollector;
    }

    function setupFundingToken(string tokenSymbol, address tokenAddress, address uniswapExchangeAddress, uint allowedSlippage) public onlyOwner {
        address ourbitrage = address(this);
        address kyberAddress = address(_kyber);
        IERC20 token = IERC20(tokenAddress);

         
        if (_fundingToken[tokenSymbol] != address(0)) {
            uint256 oldTokenBalance = token.balanceOf(ourbitrage);
            require(oldTokenBalance == 0, "You have an existing token balance");
        }

         
        _fundingToken[tokenSymbol] = tokenAddress;
        _uniswap[tokenSymbol] = UniswapExchangeInterface(uniswapExchangeAddress);
        _allowedSlippage[tokenSymbol] = allowedSlippage;

         
         
        require(token.approve(kyberAddress, 0), "Failed to approve Kyber for token transfer");
        token.approve(kyberAddress, _DEFAULT_MAX_RATE);
        require(token.approve(uniswapExchangeAddress, 0), "Failed to approve Uniswap for token transfer");
        token.approve(uniswapExchangeAddress, _DEFAULT_MAX_RATE);
    }

     
     
     

    function withdrawETH() public onlyOwner {
        _withdrawETH(msg.sender);
    }

    function withdrawToken(string tokenSymbol) public onlyOwner {
        _withdrawToken(tokenSymbol, msg.sender);
    }

    function depositFunds(string tokenSymbol, address tokenAddress, uint tokenAmount) public onlyOwner {
        require(_fundingToken[tokenSymbol] != address(0), "Funding Token has not been setup");
        require(_fundingToken[tokenSymbol] == tokenAddress, "Funding Token is not the same as the deposited token type");

        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
        uint256 currentTokenBalance = token.balanceOf(msg.sender);
        require(tokenAmount <= currentTokenBalance, "User does not have enough funds to deposit");

         
         
 
 

         
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Failed to transfer Token Funds into Ourbitrage Contract");
    }

     
     
     

     
    function arbEthFromKyberToUniswap(string tokenSymbol) public onlyOwner returns (uint, uint) {
        return _arbEthFromKyberToUniswap(tokenSymbol);
    }

     
    function arbEthFromUniswapToKyber(string tokenSymbol) public onlyOwner returns (uint, uint) {
        return _arbEthFromUniswapToKyber(tokenSymbol);
    }

     
     
     

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
     
     

    function _withdrawETH(address receiver) internal {
        require(receiver != address(0), "Invalid receiver for withdraw");
        address ourbitrage = address(this);
        receiver.transfer(ourbitrage.balance);
    }

    function _withdrawToken(string tokenSymbol, address receiver) internal {
        require(_fundingToken[tokenSymbol] != address(0), "Funding Token has not been setup");
        require(receiver != address(0), "Invalid receiver for withdraw");
        address ourbitrage = address(this);
        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
        uint256 currentTokenBalance = token.balanceOf(ourbitrage);
        token.transfer(receiver, currentTokenBalance);
    }

     
     
     

     
     
    function _arbEthFromKyberToUniswap(string tokenSymbol) internal returns (uint profit, uint loss) {
        require(_fundingToken[tokenSymbol] != address(0), "Funding Token has not been set");
        require(address(_kyber) != address(0), "Kyber Network Exchange Interface has not been set");

         
        address ourbitrage = address(this);
        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
        uint256 tokenBalance = token.balanceOf(ourbitrage);
        require(tokenBalance > 0, "Insufficient funds to process arbitration");

         
        uint ethReceived = _buyEthOnKyber(token, tokenBalance);   
        _sellEthOnUniswap(tokenSymbol, ethReceived);              

         
        (profit, loss) = _getProfitLoss(token, tokenBalance);
        emit Arbitrage("ETH-K2U", _fundingToken[tokenSymbol], profit, loss);
    }

     
     
    function _arbEthFromUniswapToKyber(string tokenSymbol) internal returns (uint profit, uint loss) {
        require(_fundingToken[tokenSymbol] != address(0), "Funding Token has not been set");
        require(address(_kyber) != address(0), "Kyber Network Exchange Interface has not been set");

         
        address ourbitrage = address(this);
        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
        uint256 tokenBalance = token.balanceOf(ourbitrage);
        require(tokenBalance > 0, "Insufficient funds to process arbitration");

         
        uint ethReceived = _buyEthOnUniswap(tokenSymbol, tokenBalance);   
        _sellEthOnKyber(token, ethReceived);                              

         
        (profit, loss) = _getProfitLoss(token, tokenBalance);
        emit Arbitrage("ETH-U2K", _fundingToken[tokenSymbol], profit, loss);
    }

     
     
     

     
    function _buyEthOnKyber(IERC20 token, uint tokenAmount) internal returns (uint) {
        address ourbitrage = address(this);
        uint slippageRate;
        (, slippageRate) = _kyber.getExpectedRate(token, _ETH_TOKEN_ADDRESS, tokenAmount);

         
 
 

         
 
        return _kyber.tradeWithHint(IERC20(token), tokenAmount, _ETH_TOKEN_ADDRESS, ourbitrage, _DEFAULT_MAX_RATE, slippageRate, _feeCollector, "PERM");
    }

     
    function _sellEthOnUniswap(string tokenSymbol, uint ethAmount) internal returns (bool) {
 
        uint minReturn = 1;  
        _uniswap[tokenSymbol].ethToTokenSwapInput.value(ethAmount)(minReturn, block.timestamp);
 
        return true;
    }

     
    function _buyEthOnUniswap(string tokenSymbol, uint tokenAmount) internal returns (uint) {
 
 
        uint minEth = 1;  

 
        return _uniswap[tokenSymbol].tokenToEthSwapInput(tokenAmount, minEth, block.timestamp);
    }

     
    function _sellEthOnKyber(IERC20 token, uint ethAmount) internal returns (uint) {
        uint slippageRate;
        (, slippageRate) = _kyber.getExpectedRate(_ETH_TOKEN_ADDRESS, token, ethAmount);

         
        uint tokensReceived = _kyber.swapEtherToToken.value(ethAmount)(token, slippageRate);
 
        return tokensReceived;
    }

     
     
     

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

     
     
     

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        _owner = newOwner;
    }

     
     
     

    function _getProfitLoss(IERC20 token, uint oldBalance) internal view returns (uint profit, uint loss) {
        uint newBalance = token.balanceOf(address(this));
        if (newBalance < oldBalance) {
            profit = 0;
            loss = oldBalance - newBalance;
        } else {
            profit = newBalance - oldBalance;
            loss = 0;
        }
    }

     
     
     
    function _getAllowedSlippage(string tokenSymbol, uint amount) internal view returns (uint) {
        return (amount * _allowedSlippage[tokenSymbol]) / 100000;
    }
}