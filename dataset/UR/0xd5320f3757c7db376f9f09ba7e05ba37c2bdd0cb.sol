 

 

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




 

interface IuniswapExchange {
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function totalSupply() external view returns (uint256);
}


interface IuniswapExchangeExecution {
    function ConvertETH2SNX() payable external returns (uint);
}


interface IUSKI_SNX {
    function getKeyInfo(uint value) external returns(bool);
    function max_tokens() external returns(uint);
    function min_liquidity() external returns(uint);
}

contract uniswapLiquidityProviderZAP_ETHSNX is Ownable {
    using SafeMath for uint;
    
     
    event SNXReceived(uint);
    event LiquidityTokens(uint);
    
     
    uint256 public price;
    uint public balance = address(this).balance;
    
     
    bool private stopped = false;

    
     
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
     
    IuniswapExchange uniswapExchangeContract = IuniswapExchange(0x3958B4eC427F8fa24eB60F42821760e88d485f7F);
    IuniswapExchangeExecution public uniswapExchangeExecutionContract = IuniswapExchangeExecution(0x8f1Ee1dAD73D1BA09e23318012d972cccC40f040);
    IERC20 public SNX_TOKEN_ADDRESS = IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    IUSKI_SNX public USKIContract = IUSKI_SNX(0x7b055ff2498d0E8e83Ec009292eC24fa8d007097);  
    
    address public uniswapExchangeContract_forBalance = address(uniswapExchangeContract);
    
    
    constructor() public {
        initialRun();
    }
    
    function initialRun() onlyOwner internal {
        SNX_TOKEN_ADDRESS.approve(address(uniswapExchangeContract),100000000000000000000000000000);
    }
    
    
     
    function set_uniswapExchangeContract(IuniswapExchange _new_uniswapExchangeContract) onlyOwner public {
        uniswapExchangeContract = _new_uniswapExchangeContract;
    }
    
     
    function set_uniswapExchangeExecutionContract (IuniswapExchangeExecution _new_uniswapExchangeExecutionContract) onlyOwner public {
        uniswapExchangeExecutionContract = _new_uniswapExchangeExecutionContract;
    }
    
    
     
    function set_USKIContract (IUSKI_SNX _new_USKIContract) onlyOwner public {
        USKIContract = _new_USKIContract;
    }
    
     
    function set_SNX_TOKEN_ADDRESS (IERC20 _new_SNX_TOKEN_ADDRESS) onlyOwner public {
        SNX_TOKEN_ADDRESS = _new_SNX_TOKEN_ADDRESS;
    }
    
    
    function LetsInvest() payable stopInEmergency public returns (bool) {
         
        require (msg.value > 0.001 ether);
        
        uint conversionPortion = SafeMath.div(SafeMath.mul(msg.value, 505), 1000);
        uint non_conversionPortion = SafeMath.sub(msg.value,conversionPortion);
        
         
        uint SNXReceivedAmt = uniswapExchangeExecutionContract.ConvertETH2SNX.value(conversionPortion)();
        emit SNXReceived(SNXReceivedAmt);
        
        
         
        USKIContract.getKeyInfo(non_conversionPortion);
        uint max_tokens_ans = USKIContract.max_tokens();
        uint deadLineToAddLiquidity = SafeMath.add(now,1800);
        uniswapExchangeContract.addLiquidity.value(non_conversionPortion)(1,max_tokens_ans,deadLineToAddLiquidity);

         
        uint holdings = uniswapExchangeContract.balanceOf(address(this));
        emit LiquidityTokens(holdings);
        uniswapExchangeContract.transfer(msg.sender, holdings);
        uint residualSNXHoldings = SNX_TOKEN_ADDRESS.balanceOf(address(this));
        SNX_TOKEN_ADDRESS.transfer(msg.sender, residualSNXHoldings);
        return true;
    }
    
     
    function withdrawSNX() public onlyOwner {
        uint StuckSNXHoldings = SNX_TOKEN_ADDRESS.balanceOf(address(this));
        SNX_TOKEN_ADDRESS.transfer(_owner, StuckSNXHoldings);
    }
    
    
     
    
     
    function depositETH() payable public onlyOwner {
        balance += msg.value;
    }
    
     
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            LetsInvest();
        }
    }
    
     
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }
    
}