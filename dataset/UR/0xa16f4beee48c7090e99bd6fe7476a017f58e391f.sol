 

pragma solidity ^0.4.11;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
 }

   
  function transferOwnership(address newOwner) onlyOwner {
      owner = newOwner;
  }
 
}
  
contract ERC20 {

    function totalSupply() constant returns (uint256);
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value);
    function transferFrom(address from, address to, uint256 value);
    function approve(address spender, uint256 value);
    function allowance(address owner, address spender) constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract CTCToken is Ownable, ERC20 {

    using SafeMath for uint256;

     
    string public name = "ChainTrade Coin";
    string public symbol = "CTC";
    uint256 public decimals = 18;

    uint256 public initialPrice = 1000;
    uint256 public _totalSupply = 225000000e18;
    uint256 public _icoSupply = 200000000e18;

     
    mapping (address => uint256) balances;
    
    
     
    mapping (address => uint256) balancesWaitingKYC;

     
    mapping (address => mapping(address => uint256)) allowed;
    
     
    uint256 public startTime = 1507334400; 
    uint256 public endTime = 1514764799; 

     
    address public multisig;

     
    uint256 public RATE;

    uint256 public minContribAmount = 0.01 ether;
    uint256 public kycLevel = 15 ether;
    uint256 minCapBonus = 200 ether;

    uint256 public hardCap = 200000000e18;
    
     
    uint256 public totalNumberTokenSold=0;

    bool public mintingFinished = false;

    bool public tradable = true;

    bool public active = true;

    event MintFinished();
    event StartTradable();
    event PauseTradable();
    event HaltTokenAllOperation();
    event ResumeTokenAllOperation();
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier canTradable() {
        require(tradable);
        _;
    }

    modifier isActive() {
        require(active);
        _;
    }
    
    modifier saleIsOpen(){
        require(startTime <= getNow() && getNow() <=endTime);
        _;
    }

     
     
     
    function CTCToken(address _multisig) {
        require(_multisig != 0x0);
        multisig = _multisig;
        RATE = initialPrice;

        balances[multisig] = _totalSupply;

        owner = msg.sender;
    }

     
     
    function () external payable {
        
        if (!validPurchase()){
            refundFunds(msg.sender);
        }
        
        tokensale(msg.sender);
    }

     
     
     
        function tokensale(address recipient) canMint isActive saleIsOpen payable {
        require(recipient != 0x0);
        
        uint256 weiAmount = msg.value;
        uint256 nbTokens = weiAmount.mul(RATE).div(1 ether);
        
        
        require(_icoSupply >= nbTokens);
        
        bool percentageBonusApplicable = weiAmount >= minCapBonus;
        if (percentageBonusApplicable) {
            nbTokens = nbTokens.mul(11).div(10);
        }
        
        totalNumberTokenSold=totalNumberTokenSold.add(nbTokens);

        _icoSupply = _icoSupply.sub(nbTokens);

        TokenPurchase(msg.sender, recipient, weiAmount, nbTokens);

         if(weiAmount< kycLevel) {
            updateBalances(recipient, nbTokens);
         } else {
            balancesWaitingKYC[recipient] = balancesWaitingKYC[recipient].add(nbTokens); 
         }
         forwardFunds();  
        
    }
    
    function updateBalances(address receiver, uint256 tokens) internal {
        balances[multisig] = balances[multisig].sub(tokens);
        balances[receiver] = balances[receiver].add(tokens);
    }
    
     
     function refundFunds(address origin) internal {
        origin.transfer(msg.value);
    }

     
     
    function forwardFunds() internal {
        multisig.transfer(msg.value);
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = getNow() >= startTime && getNow() <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool minContribution = minContribAmount <= msg.value;
        bool notReachedHardCap = hardCap >= totalNumberTokenSold;
        return withinPeriod && nonZeroPurchase && minContribution && notReachedHardCap;
    }

     
    function hasEnded() public constant returns (bool) {
        return getNow() > endTime;
    }

    function getNow() public constant returns (uint) {
        return now;
    }

     
    function changeMultiSignatureWallet (address _multisig) onlyOwner isActive {
        multisig = _multisig;
    }

     
    function changeTokenRate(uint _tokenPrice) onlyOwner isActive {
        RATE = _tokenPrice;
    }

     
    function finishMinting() onlyOwner isActive {
        mintingFinished = true;
        MintFinished();
    }

     
    function startTradable(bool _tradable) onlyOwner isActive {
        tradable = _tradable;
        if (tradable)
            StartTradable();
        else
            PauseTradable();
    }

     
    function updateICODate(uint256 _startTime, uint256 _endTime) public onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
    }
    
     
    function changeStartTime(uint256 _startTime) onlyOwner {
        startTime = _startTime;
    }

     
    function changeEndTime(uint256 _endTime) onlyOwner {
        endTime = _endTime;
    }

     
    function totalSupply() constant returns (uint256) {
        return _totalSupply;
    }
    
     
    function totalNumberTokenSold() constant returns (uint256) {
        return totalNumberTokenSold;
    }


     
    function changeTotalSupply(uint256 totalSupply) onlyOwner {
        _totalSupply = totalSupply;
    }


     
     
     
    function balanceOf(address who) constant returns (uint256) {
        return balances[who];
    }

     
     
     
    function balanceOfKyCToBeApproved(address who) constant returns (uint256) {
        return balancesWaitingKYC[who];
    }
    

    function approveBalancesWaitingKYC(address[] listAddresses) onlyOwner {
         for (uint256 i = 0; i < listAddresses.length; i++) {
             address client = listAddresses[i];
             balances[multisig] = balances[multisig].sub(balancesWaitingKYC[client]);
             balances[client] = balances[client].add(balancesWaitingKYC[client]);
             totalNumberTokenSold=totalNumberTokenSold.add(balancesWaitingKYC[client]);
             _icoSupply = _icoSupply.sub(balancesWaitingKYC[client]);
             balancesWaitingKYC[client] = 0;
        }
    }

    function addBonusForOneHolder(address holder, uint256 bonusToken) onlyOwner{
         require(holder != 0x0); 
         balances[multisig] = balances[multisig].sub(bonusToken);
         balances[holder] = balances[holder].add(bonusToken);
         totalNumberTokenSold=totalNumberTokenSold.add(bonusToken);
         _icoSupply = _icoSupply.sub(bonusToken);
    }

    
    function addBonusForMultipleHolders(address[] listAddresses, uint256[] bonus) onlyOwner {
        require(listAddresses.length == bonus.length); 
         for (uint256 i = 0; i < listAddresses.length; i++) {
                require(listAddresses[i] != 0x0); 
                balances[listAddresses[i]] = balances[listAddresses[i]].add(bonus[i]);
                balances[multisig] = balances[multisig].sub(bonus[i]);
                totalNumberTokenSold=totalNumberTokenSold.add(bonus[i]);
                _icoSupply = _icoSupply.sub(bonus[i]);
         }
    }
    
   
    
    function modifyCurrentHardCap(uint256 _hardCap) onlyOwner isActive {
        hardCap = _hardCap;
    }

     
     
     
     
    function transfer(address to, uint256 value) canTradable isActive {
        require (
            balances[msg.sender] >= value && value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) canTradable isActive {
        require (
            allowed[from][msg.sender] >= value && balances[from] >= value && value > 0
        );
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
    }

     
     
     
     
     
    function approve(address spender, uint256 value) isActive {
        require (
            balances[msg.sender] >= value && value > 0
        );
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
    }

     
     
     
     
    function allowance(address _owner, address spender) constant returns (uint256) {
        return allowed[_owner][spender];
    }

     
     
    function getRate() constant returns (uint256 result) {
      return RATE;
    }
    
    function getTokenDetail() public constant returns (string, string, uint256, uint256, uint256, uint256, uint256) {
        return (name, symbol, startTime, endTime, _totalSupply, _icoSupply, totalNumberTokenSold);
    }
}