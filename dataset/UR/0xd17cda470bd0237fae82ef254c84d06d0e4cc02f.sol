 

 

pragma solidity ^0.5.0;

 
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
         
         
         
         
         
         
        _notEntered = true;
    }

     
    modifier nonReentrant() {
         
        require(_notEntered, "ReentrancyGuard: reentrant call");

         
        _notEntered = false;

        _;

         
         
        _notEntered = true;
    }
}
 

pragma solidity ^0.5.0;

 
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
 

pragma solidity ^0.5.0;

 
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
 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}
 

pragma solidity ^0.5.0;

 
contract Ownable is Context {
    address payable public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
 

pragma solidity ^0.5.0;






 
 

interface IuniswapFactory {
    function getExchange(address token) external view returns (address exchange);
}


interface IuniswapExchange {
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
}

interface IKyberInterface {
    function swapTokentoToken(IERC20 _srcTokenAddressERC20, IERC20 _dstTokenAddress, uint _slippageValue) external payable returns (uint);
}

interface IChaiContract {
    function join(address dst, uint wad) external;
}


contract UniSwap_ETH_CHAIZap is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    
     
    event ERC20TokenHoldingsOnConversionDaiChai(uint);
    event ERC20TokenHoldingsOnConversionEthDai(uint);
    event LiquidityTokens(uint);

    
     
    uint public balance = address(this).balance;
    

     
    bool private stopped = false;
     
     
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    function toggleContractActive() onlyOwner public {
        stopped = !stopped;
    }
    
     
    IuniswapFactory public UniSwapFactoryAddress = IuniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IKyberInterface public KyberInterfaceAddresss;
    IERC20 public NEWDAI_TOKEN_ADDRESS = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IChaiContract public CHAI_TOKEN_ADDRESS = IChaiContract(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);
    
    function set_KyberInterfaceAddresss(IKyberInterface _new_KyberInterfaceAddresss) public onlyOwner {
        KyberInterfaceAddresss = _new_KyberInterfaceAddresss;
    }
    
    
    function LetsInvest(address _src, address _towhomtoissue, uint _MaxslippageValue) public payable stopInEmergency returns (uint) {
        IERC20 ERC20TokenAddress = IERC20(address(CHAI_TOKEN_ADDRESS));
        IuniswapExchange UniSwapExchangeContractAddress = IuniswapExchange(UniSwapFactoryAddress.getExchange(address(CHAI_TOKEN_ADDRESS)));
        IChaiContract ChaiTokenAddress = IChaiContract(address(CHAI_TOKEN_ADDRESS));

         
        uint conversionPortion = SafeMath.div(SafeMath.mul(msg.value, 505), 1000);
        uint non_conversionPortion = SafeMath.sub(msg.value,conversionPortion);

        KyberInterfaceAddresss.swapTokentoToken.value(conversionPortion)(IERC20(_src), NEWDAI_TOKEN_ADDRESS, _MaxslippageValue);
        uint tokenBalance = NEWDAI_TOKEN_ADDRESS.balanceOf(address(this));
         
        uint qty2approve = SafeMath.mul(tokenBalance, 3);
        require(NEWDAI_TOKEN_ADDRESS.approve(address(ERC20TokenAddress), qty2approve));
        ChaiTokenAddress.join(address(this), tokenBalance);
        uint ERC20TokenHoldings = ERC20TokenAddress.balanceOf(address(this));
        require (ERC20TokenHoldings > 0, "the conversion did not happen as planned");
        emit ERC20TokenHoldingsOnConversionDaiChai(ERC20TokenHoldings);
        NEWDAI_TOKEN_ADDRESS.approve(address(ERC20TokenAddress), 0);
        ERC20TokenAddress.approve(address(UniSwapExchangeContractAddress),ERC20TokenHoldings);

         
        uint max_tokens_ans = getMaxTokens(address(UniSwapExchangeContractAddress), ERC20TokenAddress, non_conversionPortion);
        UniSwapExchangeContractAddress.addLiquidity.value(non_conversionPortion)(1,max_tokens_ans,SafeMath.add(now,1800));
        ERC20TokenAddress.approve(address(UniSwapExchangeContractAddress),0);

         
        uint LiquityTokenHoldings = UniSwapExchangeContractAddress.balanceOf(address(this));
        emit LiquidityTokens(LiquityTokenHoldings);
        UniSwapExchangeContractAddress.transfer(_towhomtoissue, LiquityTokenHoldings);
        ERC20TokenHoldings = ERC20TokenAddress.balanceOf(address(this));
        ERC20TokenAddress.transfer(_towhomtoissue, ERC20TokenHoldings);
        return LiquityTokenHoldings;
    }

    function getMaxTokens(address _UniSwapExchangeContractAddress, IERC20 _ERC20TokenAddress, uint _value) internal view returns (uint) {
        uint contractBalance = address(_UniSwapExchangeContractAddress).balance;
        uint eth_reserve = SafeMath.sub(contractBalance, _value);
        uint token_reserve = _ERC20TokenAddress.balanceOf(_UniSwapExchangeContractAddress);
        uint token_amount = SafeMath.div(SafeMath.mul(_value,token_reserve),eth_reserve) + 1;
        return token_amount;
    }
    
    


    
     
    function withdrawERC20Token (address _TokenContractAddress) public onlyOwner {
        IERC20 ERC20TokenAddress = IERC20(_TokenContractAddress);
        uint StuckERC20Holdings = ERC20TokenAddress.balanceOf(address(this));
        ERC20TokenAddress.transfer(_owner, StuckERC20Holdings);
    }
    
    function set_new_CHAI_TokenContractAddress(address _new_CHAI_TokenContractAddress) public onlyOwner {
        CHAI_TOKEN_ADDRESS = IChaiContract(address(_new_CHAI_TokenContractAddress));
        
    }
    

     
    
     
    function depositETH() public payable  onlyOwner {
        balance += msg.value;
    }
    
     
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            LetsInvest(address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee), msg.sender, 3);
        }
    }
    

    
     
    function withdraw() public onlyOwner {
        _owner.transfer(address(this).balance);
    }
    
    function _selfDestruct() public onlyOwner {
        selfdestruct(_owner);
    }
    
}