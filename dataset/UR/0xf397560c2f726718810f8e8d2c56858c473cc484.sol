 

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

interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}





 
interface KyberNetworkProxyInterface {
    function maxGasPrice() public view returns(uint);
    function getUserCapInWei(address user) public view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) public view returns(uint);
    function enabled() public view returns(bool);
    function info(bytes32 id) public view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
        
    function swapEtherToToken(ERC20 token, uint minRate) public payable returns (uint);
    
    function swapTokenToEther(ERC20 token, uint tokenQty, uint minRate) public returns (uint);
    
  
}

interface OrFeedInterface {
  function getExchangeRate ( string fromSymbol, string toSymbol, string venue, uint256 amount ) external view returns ( uint256 );
  function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
  function getTokenAddress ( string symbol ) external view returns ( address );
  function getSynthBytes32 ( string symbol ) external view returns ( bytes32 );
  function getForexAddress ( string symbol ) external view returns ( address );
}





contract Trader{
    
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    KyberNetworkProxyInterface public proxy = KyberNetworkProxyInterface(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    OrFeedInterface orfeed= OrFeedInterface(0x3c1935ebe06ca18964a5b49b8cd55a4a71081de2);
    address daiAddress = 0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359;
    bytes  PERM_HINT = "PERM";
    address owner;
    
      
      
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
    
    
    constructor(){
     owner = msg.sender;   
    }
    
   function swapEtherToToken (KyberNetworkProxyInterface _kyberNetworkProxy, ERC20 token, address destAddress) internal{

    uint minRate;
    (, minRate) = _kyberNetworkProxy.getExpectedRate(ETH_TOKEN_ADDRESS, token, msg.value);

     
    uint destAmount = _kyberNetworkProxy.swapEtherToToken.value(msg.value)(token, minRate);

     
   require(token.transfer(destAddress, destAmount));
   
   
   
    }
    
    function swapTokenToEther1 (KyberNetworkProxyInterface _kyberNetworkProxy, ERC20 token, uint tokenQty, address destAddress) internal returns (uint) {

        uint minRate =1;
         

         
        token.transferFrom(msg.sender, this, tokenQty);

         
         
        
       token.approve(proxy, 0);

         
       token.approve(address(proxy), tokenQty);
      

       uint destAmount = proxy.tradeWithHint(ERC20(daiAddress), tokenQty, ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee), this, 8000000000000000000000000000000000000000000000000000000000000000, 0, 0x0000000000000000000000000000000000000004, PERM_HINT);

    return destAmount;
       

         
      
    }

     function kyberToUniSwapArb(address fromAddress, address uniSwapContract, uint theAmount) public payable onlyOwner returns (bool){

        address theAddress = uniSwapContract;
        UniswapExchangeInterface usi = UniswapExchangeInterface(theAddress);
        
        ERC20 address1 = ERC20(fromAddress);

       uint ethBack = swapTokenToEther1(proxy, address1 , theAmount, msg.sender);
       
       usi.ethToTokenSwapInput.value(ethBack)(1, block.timestamp);
     
        return true;
    }


    function () external payable  {
     
    }
    
    
    
    function withdrawETHAndTokens() onlyOwner{
        
        msg.sender.send(address(this).balance);
         ERC20 daiToken = ERC20(daiAddress);
        uint256 currentTokenBalance = daiToken.balanceOf(this);
        daiToken.transfer(msg.sender, currentTokenBalance);
        
    }
    
    
    
    function getKyberSellPrice() constant returns (uint256){
       uint256 currentPrice =  orfeed.getExchangeRate("ETH", "SAI", "SELL-KYBER-EXCHANGE", 1000000000000000000);
        return currentPrice;
    }
    
    
     function getUniswapBuyPrice() constant returns (uint256){
       uint256 currentPrice =  orfeed.getExchangeRate("ETH", "SAI", "BUY-UNISWAP-EXCHANGE", 1000000000000000000);
        return currentPrice;
    }
    
    
    
    
    
}