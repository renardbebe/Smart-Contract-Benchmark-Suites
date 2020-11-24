 

 

 

pragma solidity 0.4.25;

 
contract Owned {
    address public owner;
    address public nominatedOwner;

     
    constructor(address _owner)
        public
    {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

     
    function nominateNewOwner(address _owner)
        external
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

     
    function acceptOwnership()
        external
    {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

 


 
contract SelfDestructible is Owned {
    
    uint public initiationTime;
    bool public selfDestructInitiated;
    address public selfDestructBeneficiary;
    uint public constant SELFDESTRUCT_DELAY = 4 weeks;

     
    constructor(address _owner)
        Owned(_owner)
        public
    {
        require(_owner != address(0), "Owner must not be zero");
        selfDestructBeneficiary = _owner;
        emit SelfDestructBeneficiaryUpdated(_owner);
    }

     
    function setSelfDestructBeneficiary(address _beneficiary)
        external
        onlyOwner
    {
        require(_beneficiary != address(0), "Beneficiary must not be zero");
        selfDestructBeneficiary = _beneficiary;
        emit SelfDestructBeneficiaryUpdated(_beneficiary);
    }

     
    function initiateSelfDestruct()
        external
        onlyOwner
    {
        initiationTime = now;
        selfDestructInitiated = true;
        emit SelfDestructInitiated(SELFDESTRUCT_DELAY);
    }

     
    function terminateSelfDestruct()
        external
        onlyOwner
    {
        initiationTime = 0;
        selfDestructInitiated = false;
        emit SelfDestructTerminated();
    }

     
    function selfDestruct()
        external
        onlyOwner
    {
        require(selfDestructInitiated, "Self Destruct not yet initiated");
        require(initiationTime + SELFDESTRUCT_DELAY < now, "Self destruct delay not met");
        address beneficiary = selfDestructBeneficiary;
        emit SelfDestructed(beneficiary);
        selfdestruct(beneficiary);
    }

    event SelfDestructTerminated();
    event SelfDestructed(address beneficiary);
    event SelfDestructInitiated(uint selfDestructDelay);
    event SelfDestructBeneficiaryUpdated(address newBeneficiary);
}


 


 
contract Pausable is Owned {
    
    uint public lastPauseTime;
    bool public paused;

     
    constructor(address _owner)
        Owned(_owner)
        public
    {
         
    }

     
    function setPaused(bool _paused)
        external
        onlyOwner
    {
         
        if (_paused == paused) {
            return;
        }

         
        paused = _paused;
        
         
        if (paused) {
            lastPauseTime = now;
        }

         
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}


 
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


 


 
library SafeDecimalMath {

    using SafeMath for uint;

     
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

     
    uint public constant UNIT = 10 ** uint(decimals);

     
    uint public constant PRECISE_UNIT = 10 ** uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10 ** uint(highPrecisionDecimals - decimals);

     
    function unit()
        external
        pure
        returns (uint)
    {
        return UNIT;
    }

     
    function preciseUnit()
        external
        pure 
        returns (uint)
    {
        return PRECISE_UNIT;
    }

     
    function multiplyDecimal(uint x, uint y)
        internal
        pure
        returns (uint)
    {
         
        return x.mul(y) / UNIT;
    }

     
    function _multiplyDecimalRound(uint x, uint y, uint precisionUnit)
        private
        pure
        returns (uint)
    {
         
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

     
    function multiplyDecimalRoundPrecise(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

     
    function multiplyDecimalRound(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _multiplyDecimalRound(x, y, UNIT);
    }

     
    function divideDecimal(uint x, uint y)
        internal
        pure
        returns (uint)
    {
         
        return x.mul(UNIT).div(y);
    }

     
    function _divideDecimalRound(uint x, uint y, uint precisionUnit)
        private
        pure
        returns (uint)
    {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

     
    function divideDecimalRound(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _divideDecimalRound(x, y, UNIT);
    }

     
    function divideDecimalRoundPrecise(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

     
    function decimalToPreciseDecimal(uint i)
        internal
        pure
        returns (uint)
    {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

     
    function preciseDecimalToDecimal(uint i)
        internal
        pure
        returns (uint)
    {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

}


 
contract IERC20 {
    function totalSupply() public view returns (uint);

    function balanceOf(address owner) public view returns (uint);

    function allowance(address owner, address spender) public view returns (uint);

    function transfer(address to, uint value) public returns (bool);

    function approve(address spender, uint value) public returns (bool);

    function transferFrom(address from, address to, uint value) public returns (bool);

     
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);

    event Transfer(
      address indexed from,
      address indexed to,
      uint value
    );

    event Approval(
      address indexed owner,
      address indexed spender,
      uint value
    );
}


 
interface IExchangeRates {
    function effectiveValue(bytes4 sourceCurrencyKey, uint sourceAmount, bytes4 destinationCurrencyKey) external view returns (uint);

    function rateForCurrency(bytes4 currencyKey) external view returns (uint);
    function ratesForCurrencies(bytes4[] currencyKeys) external view returns (uint[] memory);

    function rateIsStale(bytes4 currencyKey) external view returns (bool);
    function anyRateIsStale(bytes4[] currencyKeys) external view returns (bool);
}

 


contract ArbRewarder is SelfDestructible, Pausable {

    using SafeMath for uint;
    using SafeDecimalMath for uint;

     
    uint off_peg_min = 100;

     
    uint acceptable_slippage = 100;

     
    uint max_delay = 600;

     
    uint constant divisor = 10000;

     
    address public seth_exchange_addr = 0x4740C758859D4651061CC9CDEFdBa92BDc3a845d;
    address public snx_erc20_addr = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;

    IExchangeRates public synthetix_rates = IExchangeRates(0x457eec906f9Dcb609b9F2c7dC0f58E182F24C350);
    IUniswapExchange public seth_uniswap_exchange = IUniswapExchange(seth_exchange_addr);

    IERC20 public seth_erc20 = IERC20(0xAb16cE44e6FA10F3d5d0eC69EB439c6815f37a24);
    IERC20 public snx_erc20 = IERC20(snx_erc20_addr);

    
     

     
    constructor(address _owner)
         
        SelfDestructible(_owner)
        Pausable(_owner)
        public
    {}

     

    function setParams(uint _acceptable_slippage, uint _max_delay, uint _off_peg_min) external onlyOwner {
        require(_off_peg_min < divisor, "_off_peg_min less than divisor");
        require(_acceptable_slippage < divisor, "_acceptable_slippage less than divisor");
        acceptable_slippage = _acceptable_slippage;
        max_delay = _max_delay;
        off_peg_min = _off_peg_min;
    }

    function setSynthetix(address _address) external onlyOwner {
        snx_erc20_addr = _address;
        snx_erc20 = IERC20(snx_erc20_addr);
    }

    function setSynthETHAddress(address _seth_erc20_addr, address _seth_exchange_addr) external onlyOwner {
        seth_exchange_addr = _seth_exchange_addr;
        seth_uniswap_exchange = IUniswapExchange(seth_exchange_addr);

        seth_erc20 = IERC20(_seth_erc20_addr);
        seth_erc20.approve(seth_exchange_addr, uint(-1));
    }

    function setExchangeRates(address _synxthetix_rates_addr) external onlyOwner {
        synthetix_rates = IExchangeRates(_synxthetix_rates_addr);
    }

     

    function recoverETH(address to_addr) external onlyOwner {
        to_addr.transfer(address(this).balance);
    }

    function recoverERC20(address erc20_addr, address to_addr) external onlyOwner {
        IERC20 erc20_interface = IERC20(erc20_addr);
        erc20_interface.transfer(to_addr, erc20_interface.balanceOf(address(this)));
    }

     

     
    function addEth() public payable
        rateNotStale("ETH")
        rateNotStale("SNX")
        notPaused
        returns (uint reward_tokens)
    {
         
        uint seth_in_uniswap = seth_erc20.balanceOf(seth_exchange_addr);
        uint eth_in_uniswap = seth_exchange_addr.balance;
        require(eth_in_uniswap.divideDecimal(seth_in_uniswap) < uint(divisor-off_peg_min).divideDecimal(divisor), "sETH/ETH ratio is too high");

         
        uint max_eth_to_convert = maxConvert(eth_in_uniswap, seth_in_uniswap, divisor, divisor-off_peg_min);
        uint eth_to_convert = min(msg.value, max_eth_to_convert);
        uint unspent_input = msg.value - eth_to_convert;

         
        uint min_seth_bought = expectedOutput(seth_uniswap_exchange, eth_to_convert);
        uint tokens_bought = seth_uniswap_exchange.ethToTokenSwapInput.value(eth_to_convert)(min_seth_bought, now + max_delay);

         
        reward_tokens = rewardCaller(tokens_bought, unspent_input);
    }

     

    function rewardCaller(uint bought, uint unspent_input)
        private
        returns
        (uint reward_tokens)
    {
        uint snx_rate = synthetix_rates.rateForCurrency("SNX");
        uint eth_rate = synthetix_rates.rateForCurrency("ETH");

        reward_tokens = eth_rate.multiplyDecimal(bought).divideDecimal(snx_rate);
        snx_erc20.transfer(msg.sender, reward_tokens);

        if(unspent_input > 0) {
            msg.sender.transfer(unspent_input);
        }
    }

    function expectedOutput(IUniswapExchange exchange, uint input) private view returns (uint output) {
        output = exchange.getTokenToEthInputPrice(input);
        output = applySlippage(output);
    }

    function applySlippage(uint input) private view returns (uint output) {
        output = input - (input * (acceptable_slippage / divisor));
    }

     
    function maxConvert(uint a, uint b, uint n, uint d) private pure returns (uint result) {
        result = (sqrt((a * (9*a*n + 3988000*b*d)) / n) - 1997*a) / 1994;
    }

    function sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function min(uint a, uint b) private pure returns (uint result) {
        result = a > b ? b : a;
    }

     

    modifier rateNotStale(bytes4 currencyKey) {
        require(!synthetix_rates.rateIsStale(currencyKey), "Rate stale or not a synth");
        _;
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