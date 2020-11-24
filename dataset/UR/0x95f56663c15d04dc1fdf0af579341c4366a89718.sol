 

 
 
 

pragma solidity 0.5.8;  

 
interface ICERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function mint(uint mintAmount) external returns (uint);

     
    function redeem(uint redeemTokens) external returns (uint);

     
    function redeemUnderlying(uint redeemAmount) external returns (uint);

     
    function exchangeRateCurrent() external returns (uint);

     
    function balanceOfUnderlying(address owner) external returns (uint);
}


 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}



contract FloatifyAccount is Ownable {
    using SafeMath for uint256;
     
     
     

     
     
     
    uint256 public totalDeposited;

     
     
     
    uint256 public totalWithdrawn;

     
    ICERC20 private daiContract;  
    ICERC20 private cdaiContract;  


     
     
     

     
    event Deposit(uint256 indexed daiAmount);

     
    event Withdraw(address indexed destinationAddress, uint256 indexed daiAmount);

      
    event Redeem(uint256 indexed cdaiAmount);

     
    event RedeemUnderlying(uint256 indexed daiAmount);

     
     
     

     
     
    constructor() public {

         
        address _daiAddress = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;  
        address _cdaiAddress = 0xF5DCe57282A584D2746FaF1593d3121Fcac444dC;  
        daiContract = ICERC20(_daiAddress);
        cdaiContract = ICERC20(_cdaiAddress);

         
        bool daiApprovalResult = daiContract.approve(_cdaiAddress, 2**256-1);
        require(daiApprovalResult, "Failed to approve cDAI contract to spend DAI");
    }


     
     
    function deposit() external onlyOwner {
        uint _daiBalance = daiContract.balanceOf(address(this));
        totalDeposited = _daiBalance.add(totalDeposited);
        emit Deposit(_daiBalance);
        require(cdaiContract.mint(_daiBalance) == 0, "Call to mint function failed");
    }

     
     
     
     
     
     
     
     
     
     
     

     
    function withdraw(address _withdrawalAddress) public onlyOwner {
        uint256 _daiBalance = daiContract.balanceOf(address(this));
        emit Withdraw(_withdrawalAddress, _daiBalance);
        require(daiContract.transfer(_withdrawalAddress, _daiBalance), "Withrawal of DAI failed");
    }

     
    function redeemAndWithdrawMax(address _withdrawalAddress) external onlyOwner {
         
         
        uint256 _cdaiBalance = cdaiContract.balanceOf(address(this));
         
        emit Redeem(_cdaiBalance);
         
         
         
        require(cdaiContract.redeem(_cdaiBalance) == 0, "Redemption of all cDAI for DAI failed");
        uint256 _daiBalance = daiContract.balanceOf(address(this));
        totalWithdrawn = _daiBalance.add(totalWithdrawn);  
         
        withdraw(_withdrawalAddress);
    }

     
    function redeemAndWithdrawPartial(address _withdrawalAddress, uint256 _daiAmount) external onlyOwner {
         
         
        emit RedeemUnderlying(_daiAmount);
        require(cdaiContract.redeemUnderlying(_daiAmount) == 0, "Redemption of some cDAI for DAI failed");
         
         
         
        uint256 _daiBalance = daiContract.balanceOf(address(this));
        totalWithdrawn = _daiBalance.add(totalWithdrawn);  
         
        withdraw(_withdrawalAddress);
    }

}