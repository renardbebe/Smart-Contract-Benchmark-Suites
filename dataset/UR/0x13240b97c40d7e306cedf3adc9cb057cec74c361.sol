 

 

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





 

interface UniSwapAddLiquityV2_General {
    function LetsInvest(address _TokenContractAddress, address _towhomtoissue) external payable returns (uint);
}

contract UniSwap_ETH_MKRZap is Ownable, ReentrancyGuard {
    using SafeMath for uint;

     
    uint public balance = address(this).balance;
    
    
     
    bool private stopped = false;
     
     
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    
    address public MKR_TokenContractAddress;
    UniSwapAddLiquityV2_General public UniSwapAddLiquityV2_GeneralAddress;
    

    constructor(address _MKR_TokenContractAddress, UniSwapAddLiquityV2_General _UniSwapAddLiquityV2_GeneralAddress ) public {
        MKR_TokenContractAddress = _MKR_TokenContractAddress;
        UniSwapAddLiquityV2_GeneralAddress = _UniSwapAddLiquityV2_GeneralAddress;
    }

    function set_new_MKR_TokenContractAddress(address _new_MKR_TokenContractAddress) public onlyOwner {
        MKR_TokenContractAddress = _new_MKR_TokenContractAddress;
    }

    function set_new_UniSwapAddLiquityV2_GeneralAddress(UniSwapAddLiquityV2_General _new_UniSwapAddLiquityV2_GeneralAddress) public onlyOwner {
        UniSwapAddLiquityV2_GeneralAddress = _new_UniSwapAddLiquityV2_GeneralAddress;
    }

    function LetsInvest() public payable stopInEmergency {
        UniSwapAddLiquityV2_GeneralAddress.LetsInvest.value(msg.value)(MKR_TokenContractAddress, address(msg.sender));

    }


     
    function depositETH() public payable  onlyOwner {
        balance += msg.value;
    }
    
     
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            LetsInvest();
        }
    }
    
     
    function withdraw() public onlyOwner {
        _owner.transfer(address(this).balance);
    }


}