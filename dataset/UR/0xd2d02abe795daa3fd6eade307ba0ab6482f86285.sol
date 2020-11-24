 

pragma solidity ^0.5.10;

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
    function maxGasPrice() external view returns(uint);
    function getUserCapInWei(address user) external view returns(uint);
    function getUserCapInTokenWei(address user, IERC20 token) external view returns(uint);
    function enabled() external view returns(bool);
    function info(bytes32 id) external view returns(uint);

    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(IERC20 src, uint srcAmount, IERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes calldata hint) external payable returns(uint);

    function swapEtherToToken(IERC20 token, uint minRate) external payable returns (uint);

    function swapTokenToEther(IERC20 token, uint tokenQty, uint minRate) external returns (uint);
}

interface OrFeedInterface {
    function getExchangeRate ( string calldata fromSymbol, string calldata toSymbol, string calldata venue, uint256 amount ) external view returns ( uint256 );
    function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
    function getTokenAddress ( string calldata symbol ) external view returns ( address );
    function getSynthBytes32 ( string calldata symbol ) external view returns ( bytes32 );
    function getForexAddress ( string calldata symbol ) external view returns ( address );
}

contract Ourbitrage {
    uint256 internal constant _DEFAULT_MAX_RATE = 8000000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant _ETH_UNIT = 1000000000000000000;
    IERC20 internal constant _ETH_TOKEN_ADDRESS = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    bytes internal constant _PERM_HINT = "PERM";

    UniswapExchangeInterface internal _uniswap;
    KyberNetworkProxyInterface internal _kyber;
    OrFeedInterface internal _orfeed;

    address private _owner;
    address internal _fundingToken;  
    address internal _feeCollector;
 

    event Arbitrage(address token, uint profit);

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

    function getKyberBuyPrice1() public view returns (uint256) {
        uint256 currentPrice = _orfeed.getExchangeRate("ETH", "DAI", "BUY-KYBER-EXCHANGE", _ETH_UNIT);
        return currentPrice;
    }

    function getKyberBuyPrice2(string memory tokenSymbol) public view returns (uint256) {
        uint256 currentPrice = _orfeed.getExchangeRate("ETH", tokenSymbol, "BUY-KYBER-EXCHANGE", _ETH_UNIT);
        return currentPrice;
    }

    function getKyberBuyPrice(string memory tokenSymbol) public view returns (uint256) {
        return _orfeed.getExchangeRate("ETH", tokenSymbol, "BUY-KYBER-EXCHANGE", 1 ether);
    }

    function getKyberSellPrice(string memory tokenSymbol) public view returns (uint256) {
        require(address(_orfeed) != address(0), "OrFeed Interface has not been set");
        return _orfeed.getExchangeRate("ETH", tokenSymbol, "SELL-KYBER-EXCHANGE", 1 ether);
    }

    function getUniswapBuyPrice(string memory tokenSymbol) public view returns (uint256) {
        require(address(_orfeed) != address(0), "OrFeed Interface has not been set");
        return _orfeed.getExchangeRate("ETH", tokenSymbol, "BUY-UNISWAP-EXCHANGE", 1 ether);
    }

    function getUniswapSellPrice(string memory tokenSymbol) public view returns (uint256) {
        require(address(_orfeed) != address(0), "OrFeed Interface has not been set");
        return _orfeed.getExchangeRate("ETH", tokenSymbol, "SELL-UNISWAP-EXCHANGE", 1 ether);
    }

    function getExpectedRate(uint tokenAmount) public view returns (uint256 minRate) {
        IERC20 token = IERC20(_fundingToken);
        (, minRate) = _kyber.getExpectedRate(token, _ETH_TOKEN_ADDRESS, tokenAmount);
    }

    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getFundingTokenAddress() public view returns (address) {
        return _fundingToken;
    }

    function getFundingTokenBalance() public view returns (uint256) {
        address ourbitrage = address(this);
        IERC20 token = IERC20(_fundingToken);
        return token.balanceOf(ourbitrage);
    }

     
     
     

    function withdrawAll() public onlyOwner {
        _withdrawETH(msg.sender);
        _withdrawToken(msg.sender);
    }

    function withdrawETH() public onlyOwner {
        _withdrawETH(msg.sender);
    }

    function withdrawToken() public onlyOwner {
        _withdrawToken(msg.sender);
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

 
    function setupFundingToken(address tokenAddress, address uniswapExchangeAddress) public onlyOwner {
         
        if (_fundingToken != address(0)) {
            address ourbitrage = address(this);
            IERC20 oldToken = IERC20(_fundingToken);
            uint256 oldTokenBalance = oldToken.balanceOf(ourbitrage);
            require(oldTokenBalance == 0, "You have an existing token balance");
        }

         
        _fundingToken = tokenAddress;
 
        _uniswap = UniswapExchangeInterface(uniswapExchangeAddress);
    }

    function depositFunds(address tokenAddress, uint tokenAmount) public payable onlyOwner {
        require(_fundingToken != address(0), "Funding Token has not been setup");
        require(_fundingToken != tokenAddress, "Funding Token is not the same as the deposited token type");

        IERC20 token = IERC20(_fundingToken);
        uint256 currentTokenBalance = token.balanceOf(msg.sender);
        require(tokenAmount <= currentTokenBalance, "User does not have enough funds to deposit");

         
        address ourbitrage = address(this);
        require(token.approve(ourbitrage, 0), "Failed to approve Ourbitrage Contract transfer Token Funds");
        token.approve(ourbitrage, tokenAmount);

         
        require(token.transferFrom(msg.sender, ourbitrage, tokenAmount), "Failed to transfer Token Funds into Ourbitrage Contract");
    }

     
     
     
     
    function kyberToUniswap() public payable onlyOwner {
        _kyberToUniswap();
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
     
     

    function _withdrawETH(address payable receiver) internal {
        require(receiver != address(0), "Invalid receiver for withdraw");
        address ourbitrage = address(this);
        receiver.transfer(ourbitrage.balance);
    }

    function _withdrawToken(address receiver) internal {
        require(receiver != address(0), "Invalid receiver for withdraw");
        address ourbitrage = address(this);
        IERC20 token = IERC20(_fundingToken);
        uint256 currentTokenBalance = token.balanceOf(ourbitrage);
        token.transfer(receiver, currentTokenBalance);
    }

     
     
     
     
     
    function _kyberToUniswap() internal {
        require(_fundingToken != address(0), "Funding Token has not been set");
        require(address(_kyber) != address(0), "Kyber Network Exchange Interface has not been set");
        require(address(_orfeed) != address(0), "OrFeed Interface has not been set");

         
        address ourbitrage = address(this);
        IERC20 token = IERC20(_fundingToken);
        uint256 tokenBalance = token.balanceOf(ourbitrage);
        require(tokenBalance > 0, "Insufficient funds to process arbitration");

         
 
 
 
 

         
        uint ethReceived = _swapTokenToEther(token, tokenBalance);   
        _swapEtherToToken(ethReceived);                              

         
        uint profit = (token.balanceOf(ourbitrage) - tokenBalance);
        emit Arbitrage(_fundingToken, profit);
    }

     
    function _swapTokenToEther(IERC20 token, uint tokenAmount) internal returns (uint) {
        address ourbitrage = address(this);
        uint minRate;
        (, minRate) = _kyber.getExpectedRate(token, _ETH_TOKEN_ADDRESS, tokenAmount);

         
        require(token.approve(address(_kyber), 0), "Failed to approve KyberNetwork for token transfer");
        token.approve(address(_kyber), tokenAmount);

         
        return _kyber.tradeWithHint(IERC20(token), tokenAmount, _ETH_TOKEN_ADDRESS, ourbitrage, _DEFAULT_MAX_RATE, minRate, _feeCollector, _PERM_HINT);
    }

     
    function _swapEtherToToken(uint ethAmount) internal returns (bool) {
         
        _uniswap.ethToTokenSwapInput.value(ethAmount)(1, block.timestamp);
        return true;
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        _owner = newOwner;
    }
}