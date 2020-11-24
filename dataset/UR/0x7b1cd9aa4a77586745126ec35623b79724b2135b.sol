 

 

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




interface UniSwapAddLiquidityZap{
    function LetsInvest() external payable returns (bool);
}

contract UniSwap_SNX_DAI_ZAP is Ownable {
    using SafeMath for uint;

    UniSwapAddLiquidityZap UniSNXLiquidityContract = UniSwapAddLiquidityZap(0xD5320F3757C7db376f9f09BA7e05BA37C2BdD0Cb);
    UniSwapAddLiquidityZap UniMKRLiquidityContract = UniSwapAddLiquidityZap(0xC54dF9FBE4212289ccb4D08546BA928Cec7F9426);
    IERC20 public SNX_TOKEN_ADDRESS = IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    IERC20 public MKR_TOKEN_ADDRESS = IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    IERC20 public UniSwapMKRContract = IERC20(0x2C4Bd064b998838076fa341A83d007FC2FA50957);
    IERC20 public UniSwapSNXContract = IERC20(0x3958B4eC427F8fa24eB60F42821760e88d485f7F);


    uint public balance = address(this).balance;
    
     
    bool private stopped = false;

     
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}

     
    function set_UniSNXLiquidityContract(UniSwapAddLiquidityZap _new_UniSNXLiquidityContract) public onlyOwner {
        UniSNXLiquidityContract = _new_UniSNXLiquidityContract;
    }

     
    function set_UniMKRLiquidityContract(UniSwapAddLiquidityZap _new_UniMKRLiquidityContract) public onlyOwner {
        UniMKRLiquidityContract = _new_UniMKRLiquidityContract;
    }

     
    function set_SNX_TOKEN_ADDRESS (IERC20 _new_SNX_TOKEN_ADDRESS) public onlyOwner {
        SNX_TOKEN_ADDRESS = _new_SNX_TOKEN_ADDRESS;
    }

     
    function set_MKR_TOKEN_ADDRESS (IERC20 _new_MKR_TOKEN_ADDRESS) public onlyOwner {
        MKR_TOKEN_ADDRESS = _new_MKR_TOKEN_ADDRESS;
    }


     
    function set_UniSwapMKRContract (IERC20 _new_UniSwapMKRContract) public onlyOwner {
        UniSwapMKRContract = _new_UniSwapMKRContract;
    }

     
    function set_UniSwapSNXContract (IERC20 _new_UniSwapSNXContract) public onlyOwner {
        UniSwapSNXContract = _new_UniSwapSNXContract;
    }

    function LetsInvest() payable stopInEmergency public returns (bool) {
         
        require (msg.value > 0.003 ether);
        
        uint MKRPortion = SafeMath.div(SafeMath.mul(msg.value, 50), 100);
        uint SNXPortion = SafeMath.sub(msg.value,MKRPortion);

        require(UniMKRLiquidityContract.LetsInvest.value(MKRPortion)(), "AddLiquidity MKR Failed");
        require(UniSNXLiquidityContract.LetsInvest.value(SNXPortion)(), "AddLiquidity SNX Failed");

        uint MKRLiquidityTokens = UniSwapMKRContract.balanceOf(address(this));
        UniSwapMKRContract.transfer(msg.sender, MKRLiquidityTokens);

        uint SNXLiquidityTokens = UniSwapSNXContract.balanceOf(address(this));
        UniSwapSNXContract.transfer(msg.sender, SNXLiquidityTokens);

        uint residualMKRHoldings = MKR_TOKEN_ADDRESS.balanceOf(address(this));
        MKR_TOKEN_ADDRESS.transfer(msg.sender, residualMKRHoldings);

        uint residualSNXHoldings = SNX_TOKEN_ADDRESS.balanceOf(address(this));
        SNX_TOKEN_ADDRESS.transfer(msg.sender, residualSNXHoldings);
        return true;
    }

     
    function withdrawMKR() public onlyOwner {
        uint StuckMKRHoldings = MKR_TOKEN_ADDRESS.balanceOf(address(this));
        MKR_TOKEN_ADDRESS.transfer(_owner, StuckMKRHoldings);
    }

    function withdrawSNX() public onlyOwner {
        uint StuckSNXHoldings = SNX_TOKEN_ADDRESS.balanceOf(address(this));
        SNX_TOKEN_ADDRESS.transfer(_owner, StuckSNXHoldings);
    }
    
    function withdrawMKRLiquityTokens() public onlyOwner {
        uint StuckMKRLiquityTokens = UniSwapMKRContract.balanceOf(address(this));
        UniSwapMKRContract.transfer(_owner, StuckMKRLiquityTokens);
    }

   function withdrawSNXLiquityTokens() public onlyOwner {
        uint StuckSNXLiquityTokens = UniSwapSNXContract.balanceOf(address(this));
        UniSwapSNXContract.transfer(_owner, StuckSNXLiquityTokens);
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