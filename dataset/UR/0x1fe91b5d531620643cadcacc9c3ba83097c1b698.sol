 

 

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





interface IKyberNetworkProxy {
    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function tradeWithHint(IERC20 src, uint srcAmount, IERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes calldata hint) external payable returns(uint);
    function swapEtherToToken(IERC20 token, uint minRate) external payable returns (uint);
}



interface Compound {
    function approve (address spender, uint256 amount ) external returns ( bool );
    function mint ( uint256 mintAmount ) external returns ( uint256 );
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint _value) external returns (bool success);
}


contract Invest2cDAI_NEW is Ownable {
    using SafeMath for uint;
    
     
     
    IKyberNetworkProxy public kyberNetworkProxyContract = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    IERC20 constant public ETH_TOKEN_ADDRESS = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    IERC20 public NEWDAI_TOKEN_ADDRESS = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    Compound public COMPOUND_TOKEN_ADDRESS = Compound(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    
     
    uint public balance;
    
     
    event UnitsReceivedANDSentToAddress(uint, address);

     
    function set_kyberNetworkProxyContract(IKyberNetworkProxy _kyberNetworkProxyContract) onlyOwner public {
        kyberNetworkProxyContract = _kyberNetworkProxyContract;
    }
    
     
    function set_NEWDAI_TOKEN_ADDRESS(IERC20 _NEWDAI_TOKEN_ADDRESS) onlyOwner public {
        NEWDAI_TOKEN_ADDRESS = _NEWDAI_TOKEN_ADDRESS;
    }
     
    function set_COMPOUND_TOKEN_ADDRESS(Compound _COMPOUND_TOKEN_ADDRESS) onlyOwner public {
        COMPOUND_TOKEN_ADDRESS = _COMPOUND_TOKEN_ADDRESS;
    }
    
    
     
    function LetsInvest(address _towhomtoissue) public payable {
        uint minConversionRate;
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(ETH_TOKEN_ADDRESS, NEWDAI_TOKEN_ADDRESS, msg.value);
        uint destAmount = kyberNetworkProxyContract.swapEtherToToken.value(msg.value)(NEWDAI_TOKEN_ADDRESS, minConversionRate);
        uint qty2approve = SafeMath.mul(destAmount, 3);
        require(NEWDAI_TOKEN_ADDRESS.approve(address(COMPOUND_TOKEN_ADDRESS), qty2approve));
        COMPOUND_TOKEN_ADDRESS.mint(destAmount); 
        uint cDAI2transfer = COMPOUND_TOKEN_ADDRESS.balanceOf(address(this));
        require(COMPOUND_TOKEN_ADDRESS.transfer(_towhomtoissue, cDAI2transfer));
        require(NEWDAI_TOKEN_ADDRESS.approve(address(COMPOUND_TOKEN_ADDRESS), 0));
        emit UnitsReceivedANDSentToAddress(cDAI2transfer, _towhomtoissue);
    }
    
     
    function inCaseDAI_NEWgetsStuck() onlyOwner public {
        uint qty = NEWDAI_TOKEN_ADDRESS.balanceOf(address(this));
        NEWDAI_TOKEN_ADDRESS.transfer(_owner, qty);
    }
    
    function inCaseC_DAIgetsStuck() onlyOwner public {
        uint CDAI_qty = COMPOUND_TOKEN_ADDRESS.balanceOf(address(this));
        COMPOUND_TOKEN_ADDRESS.transfer(_owner, CDAI_qty);
    }
    
    
     
    
     
    function depositETH() payable public onlyOwner returns (uint) {
        balance += msg.value;
    }
    
     
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            LetsInvest(msg.sender);
        }
    }
    
     
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }
 
}