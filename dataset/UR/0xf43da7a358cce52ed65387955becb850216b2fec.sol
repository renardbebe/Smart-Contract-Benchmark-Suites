 

pragma solidity ^0.5.2;

 
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


pragma solidity ^0.5.2;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

pragma solidity ^0.5.2;


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



contract Crowdsale is ReentrancyGuard {
    using SafeMath for uint256;
    
    address public manager;
    address payable public returnWallet;
    uint256 public etherEuroRate;
    uint256 public safetyLimit = 300000*10**18;
    ERC20Interface private _token;
    uint256 public minWeiValue = 10**17;

    constructor (
            uint256 rate, 
            address payable wallet, 
            address contractManager, 
            ERC20Interface token
                ) public {
        require(rate > 0);
        require(wallet != address(0));
        require(contractManager != address(0));
        require(address(token) != address(0));

        manager = contractManager;
        etherEuroRate = rate;
        returnWallet = wallet;
        _token = token;
    }
    
    modifier restricted(){
        require(msg.sender == manager );
        _;
    }

    
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 tokens = (weiAmount.div(2)).mul(etherEuroRate);
        require(tokens>0);
        require(weiAmount>minWeiValue);
        _forwardFunds();
        _token.transfer(beneficiary,tokens);
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0));
        require(weiAmount != 0);
        require(weiAmount < safetyLimit);
    }

    function setManager(address newManager) public restricted {
        require(msg.sender == manager);
        require(newManager != address(0));
        manager=newManager;
    }
    
    function updateRate(uint256 newEtherEuroRate) public restricted{
        require(newEtherEuroRate > 0);
        etherEuroRate=newEtherEuroRate;
    }
    
     
    function setSafeLimit(uint256 limitEther) public restricted{
        require(limitEther>0);
        safetyLimit=limitEther.mul(10**18);
    }
    
    function getNumberOfWeiTokenPerWei(uint256 weiToConvert) public view returns(uint256){
        require(weiToConvert > 0);
        require(weiToConvert < safetyLimit);
        return weiToConvert.mul(etherEuroRate.div(2));
    }
    
    function setMinWeiValue(uint256 minWei) public restricted{
        require(minWei > 10);
        minWeiValue = minWei;
    }
    
    function _forwardFunds() internal {
        returnWallet.transfer(msg.value);
    }
    
    function setReturnWallet(address payable _wallet) public restricted{
        require(_wallet != address(0));
        returnWallet=_wallet;
    }
    
    function reclaimToken() public restricted{
        require(manager!=address(0));
        _token.transfer(manager,_token.balanceOf(address(this)));
    }
    
    function getContractBalance() public view returns(uint256){
        return (_token.balanceOf(address(this)));
    }
    
    function getCurrentTokenContract() public view returns(address){
        return address(_token);
    }
    
}