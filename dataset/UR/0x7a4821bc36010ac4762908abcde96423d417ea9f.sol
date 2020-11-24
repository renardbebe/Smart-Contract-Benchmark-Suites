 

pragma solidity ^0.5.0;


 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
      
    function max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }
    
}


 
 
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



 
 
 
 
 
 
 
 
 
 
 
contract VaultPOC is Owned {
    using SafeMath for uint;

    uint public constant initialSupply = 1000000000000000000000;

    uint public constant etherPeg = 300;
    uint8 public constant burnRate = 1;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    ERC20Interface inchWormContract;
    ERC20Interface daiContract;
    address deployer;  
    
     
     
    
     
    function initialize(address _inchwormAddress, address _daiAddress) external onlyOwner {
        inchWormContract = ERC20Interface(_inchwormAddress);
        daiContract = ERC20Interface(_daiAddress);
        deployer = owner;
    }

     
    
    
    
    
     
     


     
    function depositWeiForInch() external payable {
        uint _percentOfInchRemaining = inchWormContract.totalSupply().mul(100).div(initialSupply);
        uint _tokensToWithdraw = msg.value.mul(etherPeg);
        _tokensToWithdraw = _tokensToWithdraw.mul(_percentOfInchRemaining).div(100);
        inchWormContract.transfer(msg.sender, _tokensToWithdraw);
    }
    
      
    function depositDaiForInch(uint _daiToDeposit) external {
        uint _percentOfInchRemaining = inchWormContract.totalSupply().mul(100).div(initialSupply);
        uint _tokensToWithdraw = _daiToDeposit.mul(_percentOfInchRemaining).div(100);
        
        inchWormContract.transfer(msg.sender, _tokensToWithdraw);
        daiContract.transferFrom(msg.sender, address(this), _daiToDeposit);
    }
    
     
    function withdrawWei(uint _weiToWithdraw) external {
        uint _inchToDeposit = _weiToWithdraw.mul(etherPeg).mul((initialSupply.div(inchWormContract.totalSupply())));
        inchWormContract.transferFrom(msg.sender, address(this), _inchToDeposit); 
        uint _inchToBurn = _inchToDeposit.mul(burnRate).div(100);
        inchWormContract.transfer(address(0), _inchToBurn);
        msg.sender.transfer(1 wei * _weiToWithdraw);
    }
    
     
    function withdrawDai(uint _daiToWithdraw) external {
        uint _inchToDeposit = _daiToWithdraw.mul(initialSupply.div(inchWormContract.totalSupply()));
        inchWormContract.transferFrom(msg.sender, address(this), _inchToDeposit); 
        uint _inchToBurn = _inchToDeposit.mul(burnRate).div(100);
        inchWormContract.transfer(address(0), _inchToBurn);
        daiContract.transfer(msg.sender, _daiToWithdraw); 
    }
    
     
    
    
    
    
     
     
    
     
     
    function getInchDaiRate() public view returns(uint) {
        return initialSupply.div(inchWormContract.totalSupply());
    }
    
     
     
    function getInchEthRate() public view returns(uint) {
        etherPeg.mul((initialSupply.div(inchWormContract.totalSupply())));
    }
    
     
     
    function getEthBalance() public view returns(uint) {
        return address(this).balance;
    }
    
     
     
    function getInchBalance() public view returns(uint) {
        return inchWormContract.balanceOf(address(this));
    }
    
     
     
    function getDaiBalance() public view returns(uint) {
        return daiContract.balanceOf(address(this));
    }
    
     
     
     
    function getPercentOfInchRemaining() external view returns(uint) {
       return inchWormContract.totalSupply().mul(100).div(initialSupply);
    }
    
     



     
     
    
     
    function transferAccidentalERC20Tokens(address tokenAddress, uint tokens) external returns (bool success) {
        require(msg.sender == deployer);
        require(tokenAddress != address(inchWormContract));
        require(tokenAddress != address(daiContract));
        
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
     
    function () external payable {
        revert();
    }
    
     
    
}