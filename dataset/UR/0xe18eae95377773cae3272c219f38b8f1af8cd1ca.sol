 

 

pragma solidity 0.5.7;

library BrokerData {

  struct BrokerOrder {
    address owner;
    bytes32 orderHash;
    uint fillAmountB;
    uint requestedAmountS;
    uint requestedFeeAmount;
    address tokenRecipient;
    bytes extraData;
  }

  struct BrokerApprovalRequest {
    BrokerOrder[] orders;
    address tokenS;
    address tokenB;
    address feeToken;
    uint totalFillAmountB;
    uint totalRequestedAmountS;
    uint totalRequestedFeeAmount;
  }

  struct BrokerInterceptorReport {
    address owner;
    address broker;
    bytes32 orderHash;
    address tokenB;
    address tokenS;
    address feeToken;
    uint fillAmountB;
    uint spentAmountS;
    uint spentFeeAmount;
    address tokenRecipient;
    bytes extraData;
  }

}

 

pragma solidity ^0.5.0;

 
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

 

contract ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) internal _balances;
  mapping (address => mapping (address => uint256)) internal _allowed;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  uint256 internal _totalSupply;

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
    _approve(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
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

  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0));
    require(owner != address(0));

    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function _burnFrom(address account, uint256 value) internal {
    _burn(account, value);
    _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
  }
}

 

pragma solidity ^0.5.0;


interface IUniswapFactory {
  event NewExchange(address indexed token, address indexed exchange);

  function initializeFactory(address template) external;
  function createExchange(address token) external returns (address payable);
  function getExchange(address token) external view returns (address payable);
  function getToken(address token) external view returns (address);
  function getTokenWihId(uint256 token_id) external view returns (address);
}

interface IUniswapExchange {
  event TokenPurchase(address indexed buyer, uint256 indexed eth_sold, uint256 indexed tokens_bought);
  event EthPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed eth_bought);
  event AddLiquidity(address indexed provider, uint256 indexed eth_amount, uint256 indexed token_amount);
  event RemoveLiquidity(address indexed provider, uint256 indexed eth_amount, uint256 indexed token_amount);

  function () external payable;

  function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

  function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

  function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);

  function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns(uint256);

  function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns(uint256);

  function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256);

  function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256);

  function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256);

  function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256);

  function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256);

  function tokenToTokenSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address token_addr) 
    external returns (uint256);

  function tokenToTokenTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    external returns (uint256);

  function tokenToTokenSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address token_addr) 
    external returns (uint256);

  function tokenToTokenTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    external returns (uint256);

  function tokenToExchangeSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address exchange_addr) 
    external returns (uint256);

  function tokenToExchangeTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address recipient, 
    address exchange_addr) 
    external returns (uint256);

  function tokenToExchangeSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address exchange_addr) 
    external returns (uint256);

  function tokenToExchangeTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address recipient, 
    address exchange_addr) 
    external returns (uint256);

  function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256);
  function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);
  function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256);
  function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256);

  function tokenAddress() external view returns (address);
  function factoryAddress() external view returns (address);

  function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
  function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
}

contract UniswapExchange is ERC20 {

   

   
  bytes32 public name;          
  bytes32 public symbol;        
  uint256 public decimals;      
  ERC20 token;                 
  IUniswapFactory factory;      
  
   
  event TokenPurchase(address indexed buyer, uint256 indexed eth_sold, uint256 indexed tokens_bought);
  event EthPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed eth_bought);
  event AddLiquidity(address indexed provider, uint256 indexed eth_amount, uint256 indexed token_amount);
  event RemoveLiquidity(address indexed provider, uint256 indexed eth_amount, uint256 indexed token_amount);


   

   
  function setup(address token_addr) public {
    require( 
      address(factory) == address(0) && address(token) == address(0) && token_addr != address(0), 
      "INVALID_ADDRESS"
    );
    factory = IUniswapFactory(msg.sender);
    token = ERC20(token_addr);
    name = 0x556e697377617020563100000000000000000000000000000000000000000000;
    symbol = 0x554e492d56310000000000000000000000000000000000000000000000000000;
    decimals = 18;
  }


   


   
  function () external payable {
    ethToTokenInput(msg.value, 1, block.timestamp, msg.sender, msg.sender);
  }

  
  function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256) {
    require(input_reserve > 0 && output_reserve > 0, "INVALID_VALUE");
    uint256 input_amount_with_fee = input_amount.mul(997);
    uint256 numerator = input_amount_with_fee.mul(output_reserve);
    uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
    return numerator / denominator;
  }

  
  function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256) {
    require(input_reserve > 0 && output_reserve > 0);
    uint256 numerator = input_reserve.mul(output_amount).mul(1000);
    uint256 denominator = (output_reserve.sub(output_amount)).mul(997);
    return (numerator / denominator).add(1);
  }

  function ethToTokenInput(uint256 eth_sold, uint256 min_tokens, uint256 deadline, address buyer, address recipient) private returns (uint256) {
    require(deadline >= block.timestamp && eth_sold > 0 && min_tokens > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 tokens_bought = getInputPrice(eth_sold, address(this).balance.sub(eth_sold), token_reserve);
    require(tokens_bought >= min_tokens);
    require(token.transfer(recipient, tokens_bought));
    emit TokenPurchase(buyer, eth_sold, tokens_bought);
    return tokens_bought;
  }

    
  function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) public payable returns (uint256) {
    return ethToTokenInput(msg.value, min_tokens, deadline, msg.sender, msg.sender);
  }

   
  function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) public payable returns(uint256) {
    require(recipient != address(this) && recipient != address(0));
    return ethToTokenInput(msg.value, min_tokens, deadline, msg.sender, recipient);
  }

  function ethToTokenOutput(uint256 tokens_bought, uint256 max_eth, uint256 deadline, address payable buyer, address recipient) private returns (uint256) {
    require(deadline >= block.timestamp && tokens_bought > 0 && max_eth > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_sold = getOutputPrice(tokens_bought, address(this).balance.sub(max_eth), token_reserve);
     
    uint256 eth_refund = max_eth.sub(eth_sold);
    if (eth_refund > 0) {
      buyer.transfer(eth_refund);
    }
    require(token.transfer(recipient, tokens_bought));
    emit TokenPurchase(buyer, eth_sold, tokens_bought);
    return eth_sold;
  }

   
  function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) public payable returns(uint256) {
    return ethToTokenOutput(tokens_bought, msg.value, deadline, msg.sender, msg.sender);
  }

   
  function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) public payable returns (uint256) {
    require(recipient != address(this) && recipient != address(0));
    return ethToTokenOutput(tokens_bought, msg.value, deadline, msg.sender, recipient);
  }

  function tokenToEthInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address buyer, address payable recipient) private returns (uint256) {
    require(deadline >= block.timestamp && tokens_sold > 0 && min_eth > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
    uint256 wei_bought = eth_bought;
    require(wei_bought >= min_eth);
    recipient.transfer(wei_bought);
    require(token.transferFrom(buyer, address(this), tokens_sold));
    emit EthPurchase(buyer, tokens_sold, wei_bought);
    return wei_bought;
  }

   
  function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) public returns (uint256) {
    return tokenToEthInput(tokens_sold, min_eth, deadline, msg.sender, msg.sender);
  }

   
  function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address payable recipient) public returns (uint256) {
    require(recipient != address(this) && recipient != address(0));
    return tokenToEthInput(tokens_sold, min_eth, deadline, msg.sender, recipient);
  }

  
  function tokenToEthOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address buyer, address payable recipient) private returns (uint256) {
    require(deadline >= block.timestamp && eth_bought > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 tokens_sold = getOutputPrice(eth_bought, token_reserve, address(this).balance);
     
    require(max_tokens >= tokens_sold);
    recipient.transfer(eth_bought);
    require(token.transferFrom(buyer, address(this), tokens_sold));
    emit EthPurchase(buyer, tokens_sold, eth_bought);
    return tokens_sold;
  }

   
  function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) public returns (uint256) {
    return tokenToEthOutput(eth_bought, max_tokens, deadline, msg.sender, msg.sender);
  }

   
  function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address payable recipient) public returns (uint256) {
    require(recipient != address(this) && recipient != address(0));
    return tokenToEthOutput(eth_bought, max_tokens, deadline, msg.sender, recipient);
  }

  function tokenToTokenInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline,
    address buyer, 
    address recipient, 
    address payable exchange_addr) 
    private returns (uint256) 
  {
    require(deadline >= block.timestamp && tokens_sold > 0 && min_tokens_bought > 0 && min_eth_bought > 0);
    require(exchange_addr != address(this) && exchange_addr != address(0));
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
    uint256 wei_bought = eth_bought;
    require(wei_bought >= min_eth_bought);
    require(token.transferFrom(buyer, address(this), tokens_sold));
    uint256 tokens_bought = IUniswapExchange(exchange_addr).ethToTokenTransferInput.value(wei_bought)(min_tokens_bought, deadline, recipient);
    emit EthPurchase(buyer, tokens_sold, wei_bought);
    return tokens_bought;
  }

   
  function tokenToTokenSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address token_addr) 
    public returns (uint256) 
  {
    address payable exchange_addr = factory.getExchange(token_addr);
    return tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, msg.sender, exchange_addr);
  }

   
  function tokenToTokenTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    public returns (uint256) 
  {
    address payable exchange_addr = factory.getExchange(token_addr);
    return tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, recipient, exchange_addr);
  }

  function tokenToTokenOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address buyer, 
    address recipient, 
    address payable exchange_addr) 
    private returns (uint256) 
  {
    require(deadline >= block.timestamp && (tokens_bought > 0 && max_eth_sold > 0));
    require(exchange_addr != address(this) && exchange_addr != address(0));
    uint256 eth_bought = IUniswapExchange(exchange_addr).getEthToTokenOutputPrice(tokens_bought);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 tokens_sold = getOutputPrice(eth_bought, token_reserve, address(this).balance);
     
    require(max_tokens_sold >= tokens_sold && max_eth_sold >= eth_bought);
    require(token.transferFrom(buyer, address(this), tokens_sold));
    uint256 eth_sold = IUniswapExchange(exchange_addr).ethToTokenTransferOutput.value(eth_bought)(tokens_bought, deadline, recipient);
    emit EthPurchase(buyer, tokens_sold, eth_bought);
    return tokens_sold;
  }

   
  function tokenToTokenSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address token_addr) 
    public returns (uint256) 
  {
    address payable exchange_addr = factory.getExchange(token_addr);
    return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, msg.sender, exchange_addr);
  }

   
  function tokenToTokenTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    public returns (uint256) 
  {
    address payable exchange_addr = factory.getExchange(token_addr);
    return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, recipient, exchange_addr);
  }

   
  function tokenToExchangeSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address payable exchange_addr) 
    public returns (uint256) 
  {
    return tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, msg.sender, exchange_addr);
  }

   
  function tokenToExchangeTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address recipient, 
    address payable exchange_addr) 
    public returns (uint256) 
  {
    require(recipient != address(this));
    return tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, recipient, exchange_addr);
  }

   
  function tokenToExchangeSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address payable exchange_addr) 
    public returns (uint256) 
  {
    return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, msg.sender, exchange_addr);
  }

   
  function tokenToExchangeTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address recipient, 
    address payable exchange_addr) 
    public returns (uint256) 
  {
    require(recipient != address(this));
    return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, recipient, exchange_addr);
  }


   

   
  function getEthToTokenInputPrice(uint256 eth_sold) public view returns (uint256) {
    require(eth_sold > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    return getInputPrice(eth_sold, address(this).balance, token_reserve);
  }

   
  function getEthToTokenOutputPrice(uint256 tokens_bought) public view returns (uint256) {
    require(tokens_bought > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_sold = getOutputPrice(tokens_bought, address(this).balance, token_reserve);
    return eth_sold;
  }

   
  function getTokenToEthInputPrice(uint256 tokens_sold) public view returns (uint256) {
    require(tokens_sold > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
    return eth_bought;
  }

   
  function getTokenToEthOutputPrice(uint256 eth_bought) public view returns (uint256) {
    require(eth_bought > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    return getOutputPrice(eth_bought, token_reserve, address(this).balance);
  }

   
  function tokenAddress() public view returns (address) {
    return address(token);
  }

   
  function factoryAddress() public view returns (address) {
    return address(factory);
  }


   

   
  function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) public payable returns (uint256) {
    require(deadline > block.timestamp && max_tokens > 0 && msg.value > 0, 'UniswapExchange#addLiquidity: INVALID_ARGUMENT');
    uint256 total_liquidity = _totalSupply;

    if (total_liquidity > 0) {
      require(min_liquidity > 0);
      uint256 eth_reserve = address(this).balance.sub(msg.value);
      uint256 token_reserve = token.balanceOf(address(this));
      uint256 token_amount = (msg.value.mul(token_reserve) / eth_reserve).add(1);
      uint256 liquidity_minted = msg.value.mul(total_liquidity) / eth_reserve;
      require(max_tokens >= token_amount && liquidity_minted >= min_liquidity);
      _balances[msg.sender] = _balances[msg.sender].add(liquidity_minted);
      _totalSupply = total_liquidity.add(liquidity_minted);
      require(token.transferFrom(msg.sender, address(this), token_amount));
      emit AddLiquidity(msg.sender, msg.value, token_amount);
      emit Transfer(address(0), msg.sender, liquidity_minted);
      return liquidity_minted;

    } else {
      require(address(factory) != address(0) && address(token) != address(0) && msg.value >= 1000000000, "INVALID_VALUE");
      require(factory.getExchange(address(token)) == address(this));
      uint256 token_amount = max_tokens;
      uint256 initial_liquidity = address(this).balance;
      _totalSupply = initial_liquidity;
      _balances[msg.sender] = initial_liquidity;
      require(token.transferFrom(msg.sender, address(this), token_amount));
      emit AddLiquidity(msg.sender, msg.value, token_amount);
      emit Transfer(address(0), msg.sender, initial_liquidity);
      return initial_liquidity;
    }
  }

   
  function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) public returns (uint256, uint256) {
    require(amount > 0 && deadline > block.timestamp && min_eth > 0 && min_tokens > 0);
    uint256 total_liquidity = _totalSupply;
    require(total_liquidity > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_amount = amount.mul(address(this).balance) / total_liquidity;
    uint256 token_amount = amount.mul(token_reserve) / total_liquidity;
    require(eth_amount >= min_eth && token_amount >= min_tokens);

    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    _totalSupply = total_liquidity.sub(amount);
    msg.sender.transfer(eth_amount);
    require(token.transfer(msg.sender, token_amount));
    emit RemoveLiquidity(msg.sender, eth_amount, token_amount);
    emit Transfer(msg.sender, address(0), amount);
    return (eth_amount, token_amount);
  }


}

 

 

pragma solidity 0.5.7;

contract WETH {
  event Approval(address indexed src, address indexed guy, uint wad);
  event Transfer(address indexed src, address indexed dst, uint wad);

  function totalSupply() public view returns (uint);

  function balanceOf(address guy) public view returns (uint);

  function allowance(address src, address guy) public view returns (uint);

  function approve(address guy, uint wad) public returns (bool);

  function transfer(address dst, uint wad) public returns (bool);

  function transferFrom(address src, address dst, uint wad) public returns (bool);

  function deposit() public payable;

  function withdraw(uint wad) public;
}

 

 

pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;


 
interface IBrokerDelegate {

   
  function brokerRequestAllowance(BrokerData.BrokerApprovalRequest calldata request) external returns (bool);

   
  function onOrderFillReport(BrokerData.BrokerInterceptorReport calldata fillReport) external;

   
  function brokerBalanceOf(address owner, address token) external view returns (uint);
}

 

 




pragma solidity 0.5.7;interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);

  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external;
  function transferFrom(address from, address to, uint256 value) external;
  function approve(address spender, uint256 value) external;
}

library Types {

  struct RequestFee {
    address feeRecipient;
    address feeToken;
    uint feeAmount;
  }

  struct RequestSignature {
    uint8 v; 
    bytes32 r; 
    bytes32 s;
  }

  enum RequestType { Update, Transfer, Approve, Perform }

  struct Request {
    address owner;
    address target;
    RequestType requestType;
    bytes payload;
    uint nonce;
    RequestFee fee;
    RequestSignature signature;
  }

  struct TransferRequest {
    address token;
    address recipient;
    uint amount;
    bool unwrap;
  }
}

interface IDolomiteMarginTradingBroker {
  function brokerMarginRequestApproval(address owner, address token, uint amount) external;
  function brokerMarginGetTrader(address owner, bytes calldata orderData) external view returns (address);
}

interface IVersionable {
  
   
  function versionBeginUsage(
    address owner, 
    address payable depositAddress, 
    address oldVersion, 
    bytes calldata additionalData
  ) external;

   
  function versionEndUsage(
    address owner,
    address payable depositAddress,
    address newVersion,
    bytes calldata additionalData
  ) external;
}

interface IDepositContract {  
  function perform(
    address addr, 
    string calldata signature, 
    bytes calldata encodedParams,
    uint value
  ) external returns (bytes memory);
}

interface IDepositContractRegistry {
  function depositAddressOf(address owner) external view returns (address payable);
  function operatorOf(address owner, address operator) external returns (bool);
}

library DepositContractHelper {

  function wrapAndTransferToken(IDepositContract self, address token, address recipient, uint amount, address wethAddress) internal {
    if (token == wethAddress) {
      uint etherBalance = address(self).balance;
      if (etherBalance > 0) wrapEth(self, token, etherBalance);
    }
    transferToken(self, token, recipient, amount);
  }

  function transferToken(IDepositContract self, address token, address recipient, uint amount) internal {
    self.perform(token, "transfer(address,uint256)", abi.encode(recipient, amount), 0);
  }

  function transferEth(IDepositContract self, address recipient, uint amount) internal {
    self.perform(recipient, "", abi.encode(), amount);
  }

  function approveToken(IDepositContract self, address token, address broker, uint amount) internal {
    self.perform(token, "approve(address,uint256)", abi.encode(broker, amount), 0);
  }

  function wrapEth(IDepositContract self, address wethToken, uint amount) internal {
    self.perform(wethToken, "deposit()", abi.encode(), amount);
  }

  function unwrapWeth(IDepositContract self, address wethToken, uint amount) internal {
    self.perform(wethToken, "withdraw(uint256)", abi.encode(amount), 0);
  }

  function setDydxOperator(IDepositContract self, address dydxContract, address operator) internal {
    bytes memory encodedParams = abi.encode(
      bytes32(0x0000000000000000000000000000000000000000000000000000000000000020),
      bytes32(0x0000000000000000000000000000000000000000000000000000000000000001),
      operator,
      bytes32(0x0000000000000000000000000000000000000000000000000000000000000001)
    );
    self.perform(dydxContract, "setOperators((address,bool)[])", encodedParams, 0);
  }
}

library RequestHelper {

  bytes constant personalPrefix = "\x19Ethereum Signed Message:\n32";

  function getSigner(Types.Request memory self) internal pure returns (address) {
    bytes32 messageHash = keccak256(abi.encode(
      self.owner,
      self.target,
      self.requestType,
      self.payload,
      self.nonce,
      abi.encode(self.fee.feeRecipient, self.fee.feeToken, self.fee.feeAmount)
    ));

    bytes32 prefixedHash = keccak256(abi.encodePacked(personalPrefix, messageHash));
    return ecrecover(prefixedHash, self.signature.v, self.signature.r, self.signature.s);
  }

  function decodeTransferRequest(Types.Request memory self) 
    internal 
    pure 
    returns (Types.TransferRequest memory transferRequest) 
  {
    require(self.requestType == Types.RequestType.Transfer, "INVALID_REQUEST_TYPE");

    (
      transferRequest.token,
      transferRequest.recipient,
      transferRequest.amount,
      transferRequest.unwrap
    ) = abi.decode(self.payload, (address, address, uint, bool));
  }
}

contract Requestable {
  using RequestHelper for Types.Request;

  mapping(address => uint) nonces;

  function validateRequest(Types.Request memory request) internal {
    require(request.target == address(this), "INVALID_TARGET");
    require(request.getSigner() == request.owner, "INVALID_SIGNATURE");
    require(nonces[request.owner] + 1 == request.nonce, "INVALID_NONCE");
    
    if (request.fee.feeAmount > 0) {
      require(balanceOf(request.owner, request.fee.feeToken) >= request.fee.feeAmount, "INSUFFICIENT_FEE_BALANCE");
    }

    nonces[request.owner] += 1;
  }

  function completeRequest(Types.Request memory request) internal {
    if (request.fee.feeAmount > 0) {
      _payRequestFee(request.owner, request.fee.feeToken, request.fee.feeRecipient, request.fee.feeAmount);
    }
  }

  function nonceOf(address owner) public view returns (uint) {
    return nonces[owner];
  }

   
  function balanceOf(address owner, address token) public view returns (uint);
  function _payRequestFee(address owner, address feeToken, address feeRecipient, uint feeAmount) internal;
}

 
contract DolomiteDirectV1 is Requestable, IVersionable, IDolomiteMarginTradingBroker {
  using DepositContractHelper for IDepositContract;
  using SafeMath for uint;

  IDepositContractRegistry public registry;
  address public loopringDelegate;
  address public dolomiteMarginProtocolAddress;
  address public dydxProtocolAddress;
  address public wethTokenAddress;

  constructor(
    address _depositContractRegistry,
    address _loopringDelegate,
    address _dolomiteMarginProtocol,
    address _dydxProtocolAddress,
    address _wethTokenAddress
  ) public {
    registry = IDepositContractRegistry(_depositContractRegistry);
    loopringDelegate = _loopringDelegate;
    dolomiteMarginProtocolAddress = _dolomiteMarginProtocol;
    dydxProtocolAddress = _dydxProtocolAddress;
    wethTokenAddress = _wethTokenAddress;
  }

   
  function balanceOf(address owner, address token) public view returns (uint) {
    address depositAddress = registry.depositAddressOf(owner);
    uint tokenBalance = IERC20(token).balanceOf(depositAddress);
    if (token == wethTokenAddress) tokenBalance = tokenBalance.add(depositAddress.balance);
    return tokenBalance;
  }

   
  function transfer(Types.Request memory request) public {
    validateRequest(request);
    
    Types.TransferRequest memory transferRequest = request.decodeTransferRequest();
    address payable depositAddress = registry.depositAddressOf(request.owner);

    _transfer(
      transferRequest.token, 
      depositAddress, 
      transferRequest.recipient, 
      transferRequest.amount, 
      transferRequest.unwrap
    );

    completeRequest(request);
  }

   

  function _transfer(address token, address payable depositAddress, address recipient, uint amount, bool unwrap) internal {
    IDepositContract depositContract = IDepositContract(depositAddress);
    
    if (token == wethTokenAddress && unwrap) {
      if (depositAddress.balance < amount) {
        depositContract.unwrapWeth(wethTokenAddress, amount.sub(depositAddress.balance));
      }

      depositContract.transferEth(recipient, amount);
      return;
    }

    depositContract.wrapAndTransferToken(token, recipient, amount, wethTokenAddress);
  }

   
   

  function brokerRequestAllowance(BrokerData.BrokerApprovalRequest memory request) public returns (bool) {
    require(msg.sender == loopringDelegate);

    BrokerData.BrokerOrder[] memory mergedOrders = new BrokerData.BrokerOrder[](request.orders.length);
    uint numMergedOrders = 1;

    mergedOrders[0] = request.orders[0];
    
    if (request.orders.length > 1) {
      for (uint i = 1; i < request.orders.length; i++) {
        bool isDuplicate = false;

        for (uint b = 0; b < numMergedOrders; b++) {
          if (request.orders[i].owner == mergedOrders[b].owner) {
            mergedOrders[b].requestedAmountS += request.orders[i].requestedAmountS;
            mergedOrders[b].requestedFeeAmount += request.orders[i].requestedFeeAmount;
            isDuplicate = true;
            break;
          }
        }

        if (!isDuplicate) {
          mergedOrders[numMergedOrders] = request.orders[i];
          numMergedOrders += 1;
        }
      }
    }

    for (uint j = 0; j < numMergedOrders; j++) {
      BrokerData.BrokerOrder memory order = mergedOrders[j];
      address payable depositAddress = registry.depositAddressOf(order.owner);
      
      _transfer(request.tokenS, depositAddress, address(this), order.requestedAmountS, false);
      if (order.requestedFeeAmount > 0) _transfer(request.feeToken, depositAddress, address(this), order.requestedFeeAmount, false);
    }

    return false;  
  }

  function onOrderFillReport(BrokerData.BrokerInterceptorReport memory fillReport) public {
     
  }

  function brokerBalanceOf(address owner, address tokenAddress) public view returns (uint) {
    return balanceOf(owner, tokenAddress);
  }

   
   

  function brokerMarginRequestApproval(address owner, address token, uint amount) public {
    require(msg.sender == dolomiteMarginProtocolAddress);

    address payable depositAddress = registry.depositAddressOf(owner);
    _transfer(token, depositAddress, address(this), amount, false);
  }

  function brokerMarginGetTrader(address owner, bytes memory orderData) public view returns (address) {
    return registry.depositAddressOf(owner);
  }

   
   

  function _payRequestFee(address owner, address feeToken, address feeRecipient, uint feeAmount) internal {
    _transfer(feeToken, registry.depositAddressOf(owner), feeRecipient, feeAmount, false);
  }

   
   

  function versionBeginUsage(
    address owner, 
    address payable depositAddress, 
    address oldVersion, 
    bytes calldata additionalData
  ) external { 
     
    IDepositContract(depositAddress).setDydxOperator(dydxProtocolAddress, dolomiteMarginProtocolAddress);
  }

  function versionEndUsage(
    address owner,
    address payable depositAddress,
    address newVersion,
    bytes calldata additionalData
  ) external {   }


   
   

   
  function enableTrading(address token) external {
    IERC20(token).approve(loopringDelegate, 10**70);
    IERC20(token).approve(dolomiteMarginProtocolAddress, 10**70);
  }
}

 

pragma solidity 0.5.7;


contract MakerBrokerBase {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "NOT_OWNER");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0x0), "ZERO_ADDRESS");
    owner = newOwner;
  }

  function withdrawDust(address token) external {
    require(msg.sender == owner, "UNAUTHORIZED");
    ERC20(token).transfer(msg.sender, ERC20(token).balanceOf(address(this)));
  }

  function withdrawEthDust() external {
    require(msg.sender == owner, "UNAUTHORIZED");
    msg.sender.transfer(address(this).balance);
  }
}

 

 

pragma solidity 0.5.7;




library UniswapFactoryHelper {
  function exchangeOf(IUniswapFactory self, address token) internal returns (IUniswapExchange) {
    return IUniswapExchange(self.getExchange(token));
  }
}

 
contract UniswapMakerBroker is MakerBrokerBase {
  using UniswapFactoryHelper for IUniswapFactory;

  address public wethTokenAddress;
  address public loopringProtocol;
  IUniswapFactory public uniswapFactory;

  mapping(address => address) public tokenToExchange;
  mapping(address => bool) public tokenToIsSetup;

  constructor(address _loopringProtocol, address _uniswapFactory, address _wethTokenAddress) public {
    loopringProtocol = _loopringProtocol;
    wethTokenAddress = _wethTokenAddress;
    uniswapFactory = IUniswapFactory(_uniswapFactory);
  }

  function setupToken(address token, bool setupExchange) public {
    if (setupExchange) {
      IUniswapExchange exchange = uniswapFactory.exchangeOf(token);
      ERC20(token).approve(address(exchange), 10 ** 70);
      tokenToExchange[token] = address(exchange);
    }
    ERC20(token).approve(loopringProtocol, 10 ** 70);
    tokenToIsSetup[token] = true;
  }

  function () external payable {
     
  }

   
   

  function brokerRequestAllowance(BrokerData.BrokerApprovalRequest memory request) public returns (bool) {
    require(msg.sender == loopringProtocol, "Uniswap MakerBroker: Unauthorized caller");
    require(tokenToIsSetup[request.tokenS], "Uniswap MakerBroker: tokenS is not setup yet");

    for (uint i = 0; i < request.orders.length; i++) {
      require(request.orders[i].tokenRecipient == address(this), "Uniswap MakerBroker: Order tokenRecipient must be this broker");
      require(request.orders[i].owner == owner, "Uniswap MakerBroker: Order owner must be the owner of this contract");
    }

    if (request.tokenB == wethTokenAddress) {
       
      WETH(wethTokenAddress).withdraw(request.totalFillAmountB);
    }

     
    bool isTokenBExchangeWrapper = abi.decode(request.orders[0].extraData, (bool));
    IUniswapExchange exchange;
    if (isTokenBExchangeWrapper) {
      exchange = IUniswapExchange(address(uint160(tokenToExchange[request.tokenB])));
    } else {
      exchange = IUniswapExchange(address(uint160(tokenToExchange[request.tokenS])));
    }

    uint deadline = block.timestamp + 1;
    uint exchangeAmount;
    if (request.tokenS == wethTokenAddress) {
      exchangeAmount = exchange.tokenToEthSwapInput(request.totalFillAmountB, request.totalRequestedAmountS, deadline);
    } else if (request.tokenB == wethTokenAddress) {
      exchangeAmount = exchange.ethToTokenSwapInput.value(request.totalFillAmountB)(request.totalRequestedAmountS, deadline);
    } else {
       
      address tokenToBuy;
      if (isTokenBExchangeWrapper) {
        request.tokenS;
      } else {
        request.tokenB;
      }
      exchangeAmount = exchange.tokenToTokenSwapInput(
        request.totalFillAmountB,
        request.totalRequestedAmountS,
        1,  
        deadline,
        tokenToBuy);
    }

    if (request.tokenS == wethTokenAddress) {
       
      WETH(wethTokenAddress).deposit.value(exchangeAmount)();
    }

    return false;
  }

  function onOrderFillReport(BrokerData.BrokerInterceptorReport memory fillReport) public {
     
  }

   
  function brokerBalanceOf(address owner, address tokenAddress) public view returns (uint) {
    return 10 ** 70;
  }

}