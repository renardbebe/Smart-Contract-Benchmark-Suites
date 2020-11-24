 

pragma solidity ^0.4.11;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract PylonToken is owned {
     
    string public standard = "Pylon Token - The first decentralized energy exchange platform powered by renewable energy";
    string public name = 'Pylon Token';
    string public symbol = 'PYLNT';
    uint8 public decimals = 18;
    uint256 public totalSupply = 3750000000000000000000000;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

    using SafeMath for uint256;

    address public beneficiary = 0xAE0151Ca8C9b6A1A7B50Ce80Bf7436400E22b535;   
    uint256 public fundingGoal = 21230434782608700000000;      
    uint256 public amountRaised;     
    uint256 public deadline;  
    uint256 public price = 6608695652173910;            

    uint256 public totalTokensToSend = 3250000000000000000000000;  

    uint256 public maxEtherInvestment = 826086956521739000000;  
    uint256 public maxTokens = 297619047619048000000000;  

    uint256 public bonusCap = 750000000000000000000000;  
    uint256 public pylonSelled = 0;

    uint256 public startBlockBonus;

    uint256 public endBlockBonus1;

    uint256 public endBlockBonus2;

    uint256 public endBlockBonus3;

    uint256 public qnt10k = 6578947368421050000000;  

    bool fundingGoalReached = false;  
    bool crowdsaleClosed = false;     

    event GoalReached(address deposit, uint256 amountDeposited);
    event FundTransfer(address backer, uint256 amount, bool isContribution);
    event LogQuantity(uint256 _amount, string _message);

     
    uint256 public startBlock = getBlockNumber();

    bool public paused = false;

     
     

    modifier contributionOpen() {
        require(getBlockNumber() >= startBlock && getBlockNumber() <= deadline);
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }

    function crowdsale() onlyOwner{
        paused = false;
    }

     
    event TokenPurchase(address indexed purchaser, address indexed investor, uint256 value, uint256 amount);

     
    function PylonToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        address centralMinter,
        address ifSuccessfulSendTo,
        uint256 fundingGoalInWeis,
        uint256 durationInMinutes,
        uint256 weisCostOfEachToken
    ) {
        if (centralMinter != 0) owner = centralMinter;

        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             

        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInWeis;
        startBlock = getBlockNumber();
        startBlockBonus = getBlockNumber();
        endBlockBonus1 = getBlockNumber() + 15246 + 12600 + 500;     
        endBlockBonus2 = getBlockNumber() + 30492 + 12600 + 800;     
        endBlockBonus3 = getBlockNumber() + 45738 + 12600 + 1100;    
        deadline = getBlockNumber() + (durationInMinutes * 60 / 17) + 5000;  
        price = weisCostOfEachToken;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                 
        require(balanceOf[_from] >= _value);                 
        require(balanceOf[_to] + _value > balanceOf[_to]);   
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) {
        _transfer(msg.sender, _to, _value);
    }

     
    function burn(uint256 _value) onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) onlyOwner returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        balanceOf[_from] -= _value;                          
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }

     
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }

     
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
    function () payable notPaused{
        buyTokens(msg.sender);
    }

     
    function buyTokens(address investor) payable notPaused {
        require (!crowdsaleClosed);  
        require(investor != 0x0);   
        require(validPurchase());  
        require(maxEtherInvestment >= msg.value);  
        require(balanceOf[investor] <= maxTokens);  
        require(amountRaised <= fundingGoal);  
        require(pylonSelled <= totalTokensToSend);  


         
        if(startBlockBonus <= getBlockNumber() && startBlock <= getBlockNumber() && endBlockBonus3 >= getBlockNumber() && pylonSelled <= bonusCap){
          buyPreIco(investor);
        } else if(deadline >= getBlockNumber()){
          buyIco(investor);
        }

    }

    function buyIco(address investor) internal{
      uint256 weiAmount = msg.value;

       
      uint256 tokens = weiAmount.mul(10**18).div(price);

      require((balanceOf[investor] + tokens) <= maxTokens);          
      require(balanceOf[this] >= tokens);              
      require(pylonSelled + tokens <= totalTokensToSend);  

      balanceOf[this] -= tokens;
      balanceOf[investor] += tokens;
      amountRaised += weiAmount;  
      pylonSelled += tokens;  

      beneficiary.transfer(weiAmount);  

      frozenAccount[investor] = true;
      FrozenFunds(investor, true);

      TokenPurchase(msg.sender, investor, weiAmount, tokens);
    }

    function buyPreIco(address investor) internal{
      uint256 weiAmount = msg.value;

      uint256 bonusPrice = 0;
      uint256 tokens = weiAmount.mul(10**18).div(price);

      if(endBlockBonus1 >= getBlockNumber()){
        if(tokens == qnt10k.mul(19) ){
          bonusPrice = 2775652173913040;
        }else if(tokens >= qnt10k.mul(18) && tokens < qnt10k.mul(19)){
          bonusPrice = 2907826086956520;
        }else if(tokens >= qnt10k.mul(17) && tokens < qnt10k.mul(18)){
          bonusPrice = 3040000000000000;
        }else if(tokens >= qnt10k.mul(16) && tokens < qnt10k.mul(17)){
          bonusPrice = 3172173913043480;
        }else if(tokens >= qnt10k.mul(15) && tokens < qnt10k.mul(16)){
          bonusPrice = 3304347826086960;
        }else if(tokens >= qnt10k.mul(14) && tokens < qnt10k.mul(15)){
          bonusPrice = 3436521739130430;
        }else if(tokens >= qnt10k.mul(13) && tokens < qnt10k.mul(14)){
          bonusPrice = 3568695652173910;
        }else if(tokens >= qnt10k.mul(12) && tokens < qnt10k.mul(13)){
          bonusPrice = 3700869565217390;
        }else if(tokens >= qnt10k.mul(11) && tokens < qnt10k.mul(12)){
          bonusPrice = 3833043478260870;
        }else if(tokens >= qnt10k.mul(10) && tokens < qnt10k.mul(11)){
          bonusPrice = 3965217391304350;
        }else if(tokens >= qnt10k.mul(9) && tokens < qnt10k.mul(10)){
          bonusPrice = 4097391304347830;
        }else if(tokens >= qnt10k.mul(8) && tokens < qnt10k.mul(9)){
          bonusPrice = 4229565217391300;
        }else if(tokens >= qnt10k.mul(7) && tokens < qnt10k.mul(8)){
          bonusPrice = 4361739130434780;
        }else if(tokens >= qnt10k.mul(6) && tokens < qnt10k.mul(7)){
          bonusPrice = 4493913043478260;
        }else if(tokens >= qnt10k.mul(5) && tokens < qnt10k.mul(6)){
          bonusPrice = 4626086956521740;
        }else{
          bonusPrice = 5286956521739130;
        }
      }else if(endBlockBonus2 >= getBlockNumber()){
        if(tokens == qnt10k.mul(19) ){
          bonusPrice = 3436521739130430;
        }else if(tokens >= qnt10k.mul(18) && tokens < qnt10k.mul(19)){
          bonusPrice = 3568695652173910;
        }else if(tokens >= qnt10k.mul(17) && tokens < qnt10k.mul(18)){
          bonusPrice = 3700869565217390;
        }else if(tokens >= qnt10k.mul(16) && tokens < qnt10k.mul(17)){
          bonusPrice = 3833043478260870;
        }else if(tokens >= qnt10k.mul(15) && tokens < qnt10k.mul(16)){
          bonusPrice = 3965217391304350;
        }else if(tokens >= qnt10k.mul(14) && tokens < qnt10k.mul(15)){
          bonusPrice = 4097391304347830;
        }else if(tokens >= qnt10k.mul(13) && tokens < qnt10k.mul(14)){
          bonusPrice = 4229565217391300;
        }else if(tokens >= qnt10k.mul(12) && tokens < qnt10k.mul(13)){
          bonusPrice = 4361739130434780;
        }else if(tokens >= qnt10k.mul(11) && tokens < qnt10k.mul(12)){
          bonusPrice = 4493913043478260;
        }else if(tokens >= qnt10k.mul(10) && tokens < qnt10k.mul(11)){
          bonusPrice = 4626086956521740;
        }else if(tokens >= qnt10k.mul(9) && tokens < qnt10k.mul(10)){
          bonusPrice = 4758260869565220;
        }else if(tokens >= qnt10k.mul(8) && tokens < qnt10k.mul(9)){
          bonusPrice = 4890434782608700;
        }else if(tokens >= qnt10k.mul(7) && tokens < qnt10k.mul(8)){
          bonusPrice = 5022608695652170;
        }else if(tokens >= qnt10k.mul(6) && tokens < qnt10k.mul(7)){
          bonusPrice = 5154782608695650;
        }else if(tokens >= qnt10k.mul(5) && tokens < qnt10k.mul(6)){
          bonusPrice = 5286956521739130;
        }else{
          bonusPrice = 5947826086956520;
        }
      }else{
        if(tokens == qnt10k.mul(19) ){
          bonusPrice = 3766956521739130;
        }else if(tokens >= qnt10k.mul(18) && tokens < qnt10k.mul(19)){
          bonusPrice = 3899130434782610;
        }else if(tokens >= qnt10k.mul(17) && tokens < qnt10k.mul(18)){
          bonusPrice = 4031304347826090;
        }else if(tokens >= qnt10k.mul(16) && tokens < qnt10k.mul(17)){
          bonusPrice = 4163478260869570;
        }else if(tokens >= qnt10k.mul(15) && tokens < qnt10k.mul(16)){
          bonusPrice = 4295652173913040;
        }else if(tokens >= qnt10k.mul(14) && tokens < qnt10k.mul(15)){
          bonusPrice = 4427826086956520;
        }else if(tokens >= qnt10k.mul(13) && tokens < qnt10k.mul(14)){
          bonusPrice = 4560000000000000;
        }else if(tokens >= qnt10k.mul(12) && tokens < qnt10k.mul(13)){
          bonusPrice = 4692173913043480;
        }else if(tokens >= qnt10k.mul(11) && tokens < qnt10k.mul(12)){
          bonusPrice = 4824347826086960;
        }else if(tokens >= qnt10k.mul(10) && tokens < qnt10k.mul(11)){
          bonusPrice = 4956521739130430;
        }else if(tokens >= qnt10k.mul(9) && tokens < qnt10k.mul(10)){
          bonusPrice = 5088695652173910;
        }else if(tokens >= qnt10k.mul(8) && tokens < qnt10k.mul(9)){
          bonusPrice = 5220869565217390;
        }else if(tokens >= qnt10k.mul(7) && tokens < qnt10k.mul(8)){
          bonusPrice = 5353043478260870;
        }else if(tokens >= qnt10k.mul(6) && tokens < qnt10k.mul(7)){
          bonusPrice = 5485217391304350;
        }else if(tokens >= qnt10k.mul(5) && tokens < qnt10k.mul(6)){
          bonusPrice = 5617391304347830;
        }else{
          bonusPrice = 6278260869565220;
        }
      }

      tokens = weiAmount.mul(10**18).div(bonusPrice);

      require(pylonSelled + tokens <= bonusCap);  
      require(balanceOf[investor] + tokens <= maxTokens);  
      require(balanceOf[this] >= tokens);              

      balanceOf[this] -= tokens;
      balanceOf[investor] += tokens;
      amountRaised += weiAmount;  
      pylonSelled += tokens;  

      beneficiary.transfer(weiAmount);  

      frozenAccount[investor] = true;
      FrozenFunds(investor, true);

      TokenPurchase(msg.sender, investor, weiAmount, tokens);

    }

    modifier afterDeadline() { if (now >= deadline) _; }

     
    function checkGoalReached() afterDeadline onlyOwner {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


     
    function validPurchase() internal constant returns (bool) {
        uint256 current = getBlockNumber();
        bool withinPeriod = current >= startBlock && current <= deadline;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

     
     
     

     
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

     
    function pauseContribution() onlyOwner {
        paused = true;
    }

     
    function resumeContribution() onlyOwner {
        paused = false;
    }
}
 
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