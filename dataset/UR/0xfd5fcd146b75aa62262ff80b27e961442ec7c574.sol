 

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

 
 
 
 
 
 
 
 
 
 
 
 
contract InchWormVaultLiveTest is Owned {
    using SafeMath for uint;


    event SellInchForWei(uint inch, uint _wei);
    event SellInchForDai(uint inch, uint dai);
    event BuyInchWithWei(uint inch, uint _wei);
    event BuyInchWithDai(uint inch, uint dai);
    event PremiumIncreased(uint inchSold, uint premiumIncrease);

     
     
     
    uint public premium = 1000000; 
    
     
    uint internal constant premiumDigits = 1000000;
    
     
     
    uint public etherPeg = 300;
    
     
    uint internal constant conserveRate = 9700;  
    uint internal constant conserveRateDigits = 10000;
    
     
    uint public pegMoveCooldown = 12 hours; 
     
    uint public pegMoveReadyTime;
    
    ERC20Interface inchWormContract;  
    ERC20Interface daiContract;  
    
     
     
    address payable deployer; 
    
    
     
    
     
     
     
     
    function increasePremium(uint _inchFeesPaid) external {
         
        inchWormContract.transferFrom(msg.sender, address(this), _inchFeesPaid);
        
        uint _premiumIncrease = _inchFeesPaid.mul(premium).div((inchWormContract.totalSupply().sub(inchWormContract.balanceOf(address(this)))));
        premium = premium.add(_premiumIncrease);
    }
    
    
    
    
    
     
     
    
     
     
     
     
     
    function initialize(address _inchwormAddress, address _daiAddress, address payable _deployer) external onlyOwner {
        inchWormContract = ERC20Interface(_inchwormAddress);
        daiContract = ERC20Interface(_daiAddress);
        deployer = _deployer;
        pegMoveReadyTime = now;
    }
    

     
     
    
    
    
    
    
    
     
     
    
     
     
     
     
    function increasePeg() external {
         
        require (address(this).balance.mul(etherPeg) <= daiContract.balanceOf(address(this)).div(50)); 
         
        require (now > pegMoveReadyTime);
         
        etherPeg = etherPeg.mul(104).div(100);
         
        pegMoveReadyTime = now+pegMoveCooldown;
    }
    
     
     
     
     
    function decreasePeg() external {
          
        require (daiContract.balanceOf(address(this)) <= address(this).balance.mul(etherPeg).div(50));
         
        require (now > pegMoveReadyTime);
         
        etherPeg = etherPeg.mul(96).div(100);
         
        pegMoveReadyTime = now+pegMoveCooldown;
        
        premium = premium.mul(96).div(100);
    }
    
     
     
    
    
    
    
     
     
     

     
     
     
     
     
    function __buyInchWithWei() external payable {
         
        uint _inchToBuy = msg.value.mul(etherPeg).mul(premiumDigits).div(premium);
         
        require(_inchToBuy > 0);
         
        inchWormContract.transfer(msg.sender, _inchToBuy);
        
        emit BuyInchWithWei(_inchToBuy, msg.value);
    }
    
     
     
     
     
     
     
    function __buyInchWithDai(uint _inchToBuy) external {
         
        uint _daiOwed = _inchToBuy.mul(premium).div(premiumDigits);
         
        daiContract.transferFrom(msg.sender, address(this), _daiOwed);
         
        inchWormContract.transfer(msg.sender, _inchToBuy);
        
        emit BuyInchWithDai(_inchToBuy, _daiOwed);
    }
    
    
     
     
     
     
     
     
     
     
     
     
     
     
    function __sellInchForEth(uint _inchToSell) external {
         
        uint _trueInchToSell = _inchToSell.mul(conserveRate).div(conserveRateDigits);
         
        uint _etherToReturn = _trueInchToSell.mul(premium).div(premiumDigits.mul(etherPeg));
       
         
        msg.sender.transfer(_etherToReturn);
         
        inchWormContract.transferFrom(msg.sender, address(this), _inchToSell);
         
        uint _deployerPayment = _inchToSell.mul(100).div(10000).mul(premium).div(premiumDigits.mul(etherPeg));
        deployer.transfer(_deployerPayment);
        
         
         
         
         
         
        uint _premiumIncrease = _inchToSell.sub(_trueInchToSell).mul(premium).div(inchWormContract.totalSupply().sub(inchWormContract.balanceOf(address(this))));
        premium = premium.add(_premiumIncrease);
        
        emit PremiumIncreased(_inchToSell, _premiumIncrease);
        emit SellInchForWei(_inchToSell, _etherToReturn);
    }
    
    
    
     
     
     
     
     
     
     
     
     
     
    function __sellInchForDai(uint _inchToSell) external {
         
         
        uint _trueInchToSell = _inchToSell.mul(conserveRate).div(conserveRateDigits);
         
        uint _daiToReturn = _trueInchToSell.mul(premium).div(premiumDigits);
        
         
        daiContract.transfer(msg.sender, _daiToReturn);
         
        inchWormContract.transferFrom(msg.sender, address(this), _inchToSell);
         
        uint _deployerPayment = _inchToSell.mul(100).div(10000).mul(premium).div(premiumDigits);
        daiContract.transfer(deployer, _deployerPayment);
        
         
         
         
         
         
        uint _premiumIncrease = _inchToSell.sub(_trueInchToSell).mul(premium).div(inchWormContract.totalSupply().sub(inchWormContract.balanceOf(address(this))));
        premium = premium.add(_premiumIncrease);
        
        emit PremiumIncreased(_inchToSell, _premiumIncrease);
        emit SellInchForDai(_inchToSell, _daiToReturn);
    }
    
     
     
    
    
    
    
     
     
    

     
     
    function getPremium() external view returns(uint){
        return premium;
    } 
    
     
    function getFeePercent() external pure returns(uint) {
        return (conserveRateDigits - conserveRate)/100;    
    }
    
    function canPegBeIncreased() external view returns(bool) {
        return (address(this).balance.mul(etherPeg) <= daiContract.balanceOf(address(this)).div(50) && (now > pegMoveReadyTime)); 
    }
    
     
    function canPegBeDecreased() external view returns(bool) {
        return (daiContract.balanceOf(address(this)) <= address(this).balance.mul(etherPeg).div(50) && (now > pegMoveReadyTime));
    }
    
     
    function vzgetCirculatingSupply() public view returns(uint) {
        return inchWormContract.totalSupply().sub(inchWormContract.balanceOf(address(this)));
    }
    
    
     
    function afterFeeEthReturns(uint _inchToSell) public view returns(uint) {
        uint _trueInchToSell = _inchToSell.mul(conserveRate).div(conserveRateDigits);
        return _trueInchToSell.mul(premium).div(premiumDigits.mul(etherPeg));
    }
    
     
    function afterFeeDaiReturns(uint _inchToSell) public view returns(uint) {
        uint _trueInchToSell = _inchToSell.mul(conserveRate).div(conserveRateDigits);
        return _trueInchToSell.mul(premium).div(premiumDigits);
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
    
     
     
     
    function getOwnerInch(address _a) public view returns(uint) {
        return inchWormContract.balanceOf(_a);
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