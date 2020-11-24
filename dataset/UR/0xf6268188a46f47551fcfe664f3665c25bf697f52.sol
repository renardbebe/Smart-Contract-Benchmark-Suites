 

pragma solidity ^0.4.16;

contract SafeMath{

   
   

  function safeMul(uint256 a, uint256 b) internal returns (uint256){
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  
  function safeDiv(uint256 a, uint256 b) internal returns (uint256){
     
     
     
    return a / b;
  }
  
  function safeSub(uint256 a, uint256 b) internal returns (uint256){
    assert(b <= a);
    return a - b;
  }
  
  function safeAdd(uint256 a, uint256 b) internal returns (uint256){
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

   
   
  modifier onlyPayloadSize(uint numWords){
     assert(msg.data.length >= numWords * 32 + 4);
     _;
  }

}


contract Token{  

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

}


contract StandardToken is Token, SafeMath{

    uint256 public totalSupply;

    function transfer(address _to, uint256 _value) onlyPayloadSize(2) returns (bool success){
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) returns (bool success){
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance){
        return balances[_owner];
    }
    
     
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) returns (bool success){
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) onlyPayloadSize(3) returns (bool success){
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        Approval(msg.sender, _spender, _newValue);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

}


contract EDEX is StandardToken{

     

    string public name = "Equadex";
    string public symbol = "EDEX";
    uint256 public decimals = 18;
    
     
    uint256 public maxSupply = 100000000e18;
    
     
    uint256 public icoStartBlock;
     
    uint256 public icoEndBlock;

     
    address public mainWallet;
    address public secondaryWallet;
    
     
    uint256 public priceUpdateWaitingTime = 1 hours;

    uint256 public previousUpdateTime = 0;
    
     
    PriceEDEX public currentPrice;
    uint256 public minInvestment = 0.01 ether;
    
     
    address public grantVestedEDEXContract;
    bool private grantVestedEDEXSet = false;
    
     
     
    bool public haltICO = false;
    bool public setTrading = false;

     
    mapping (address => Liquidation) public liquidations;
     
    mapping (uint256 => PriceEDEX) public prices;
     
    mapping (address => bool) public verified;

    event Verification(address indexed investor);
    event LiquidationCall(address indexed investor, uint256 amountTokens);
    event Liquidations(address indexed investor, uint256 amountTokens, uint256 etherAmount);
    event Buy(address indexed investor, address indexed beneficiary, uint256 ethValue, uint256 amountTokens);
    event PrivateSale(address indexed investor, uint256 amountTokens);
    event PriceEDEXUpdate(uint256 topInteger, uint256 bottomInteger);
    event AddLiquidity(uint256 etherAmount);
    event RemoveLiquidity(uint256 etherAmount);
    
     
    struct PriceEDEX{
        uint256 topInteger;
        uint256 bottomInteger;
    }

    struct Liquidation{
        uint256 tokens;
        uint256 time;
    }

     
    modifier isSetTrading{
        require(setTrading || msg.sender == mainWallet || msg.sender == grantVestedEDEXContract);
        _;
    }

    modifier onlyVerified{
        require(verified[msg.sender]);
        _;
    }

    modifier onlyMainWallet{
        require(msg.sender == mainWallet);
        _;
    }

    modifier onlyControllingWallets{
        require(msg.sender == secondaryWallet || msg.sender == mainWallet);
        _;
    }

    modifier only_if_secondaryWallet{
        if (msg.sender == secondaryWallet) _;
    }
    modifier require_waited{
        require(safeSub(now, priceUpdateWaitingTime) >= previousUpdateTime);
        _;
    }
    modifier only_if_increase (uint256 newTopInteger){
        if (newTopInteger > currentPrice.topInteger) _;
    }

    function EDEX(address secondaryWalletInput, uint256 priceTopIntegerInput, uint256 startBlockInput, uint256 endBlockInput){
        require(secondaryWalletInput != address(0));
        require(endBlockInput > startBlockInput);
        require(priceTopIntegerInput > 0);
        mainWallet = msg.sender;
        secondaryWallet = secondaryWalletInput;
        verified[mainWallet] = true;
        verified[secondaryWallet] = true;
         
        currentPrice = PriceEDEX(priceTopIntegerInput, 1000);
         
        icoStartBlock = startBlockInput;
         
        icoEndBlock = endBlockInput;
        previousUpdateTime = now;
    }

    function setGrantVestedEDEXContract(address grantVestedEDEXContractInput) external onlyMainWallet{
        require(grantVestedEDEXContractInput != address(0));
        grantVestedEDEXContract = grantVestedEDEXContractInput;
        verified[grantVestedEDEXContract] = true;
        grantVestedEDEXSet = true;
    }

    function updatePriceEDEX(uint256 newTopInteger) external onlyControllingWallets{
        require(newTopInteger > 0);
        require_limited_change(newTopInteger);
        currentPrice.topInteger = newTopInteger;
         
        prices[previousUpdateTime] = currentPrice;
        previousUpdateTime = now;
        PriceEDEXUpdate(newTopInteger, currentPrice.bottomInteger);
    }

    function require_limited_change (uint256 newTopInteger) private only_if_secondaryWallet require_waited only_if_increase(newTopInteger){
        uint256 percentage_diff = 0;
        percentage_diff = safeMul(newTopInteger, 100) / currentPrice.topInteger;
        percentage_diff = safeSub(percentage_diff, 100);
         
        require(percentage_diff <= 20);
    }

    function updatePriceBottomInteger(uint256 newBottomInteger) external onlyMainWallet{
        require(block.number > icoEndBlock);
        require(newBottomInteger > 0);
        currentPrice.bottomInteger = newBottomInteger;
         
        prices[previousUpdateTime] = currentPrice;
        previousUpdateTime = now;
        PriceEDEXUpdate(currentPrice.topInteger, newBottomInteger);
    }

    function tokenAllocation(address investor, uint256 amountTokens) private{
        require(grantVestedEDEXSet);
         
        uint256 teamAllocation = safeMul(amountTokens, 1764705882352941) / 1e16;
        uint256 newTokens = safeAdd(amountTokens, teamAllocation);
        require(safeAdd(totalSupply, newTokens) <= maxSupply);
        totalSupply = safeAdd(totalSupply, newTokens);
        balances[investor] = safeAdd(balances[investor], amountTokens);
        balances[grantVestedEDEXContract] = safeAdd(balances[grantVestedEDEXContract], teamAllocation);
    }

    function privateSaleTokens(address investor, uint amountTokens) external onlyMainWallet{
        require(block.number < icoEndBlock);
        require(investor != address(0));
        verified[investor] = true;
        tokenAllocation(investor, amountTokens);
        Verification(investor);
        PrivateSale(investor, amountTokens);
    }

    function verifyInvestor(address investor) external onlyControllingWallets{
        verified[investor] = true;
        Verification(investor);
    }
    
     
    function removeVerifiedInvestor(address investor) external onlyControllingWallets{
        verified[investor] = false;
        Verification(investor);
    }

    function buy() external payable{
        buyTo(msg.sender);
    }

    function buyTo(address investor) public payable onlyVerified{
        require(!haltICO);
        require(investor != address(0));
        require(msg.value >= minInvestment);
        require(block.number >= icoStartBlock && block.number < icoEndBlock);
        uint256 icoBottomInteger = icoBottomIntegerPrice();
        uint256 tokensToBuy = safeMul(msg.value, currentPrice.topInteger) / icoBottomInteger;
        tokenAllocation(investor, tokensToBuy);
         
        mainWallet.transfer(msg.value);
        Buy(msg.sender, investor, msg.value, tokensToBuy);
    }

     
    function icoBottomIntegerPrice() public constant returns (uint256){
        uint256 icoDuration = safeSub(block.number, icoStartBlock);
        uint256 bottomInteger;
         
        if (icoDuration < 115200){
            return currentPrice.bottomInteger;
        }
         
        else if (icoDuration < 230400 ){
            bottomInteger = safeMul(currentPrice.bottomInteger, 110) / 100;
            return bottomInteger;
        }
        else{
            bottomInteger = safeMul(currentPrice.bottomInteger, 120) / 100;
            return bottomInteger;
        }
    }

     
    function changeIcoStartBlock(uint256 newIcoStartBlock) external onlyMainWallet{
        require(block.number < icoStartBlock);
        require(block.number < newIcoStartBlock);
        icoStartBlock = newIcoStartBlock;
    }

    function changeIcoEndBlock(uint256 newIcoEndBlock) external onlyMainWallet{
        require(block.number < icoEndBlock);
        require(block.number < newIcoEndBlock);
        icoEndBlock = newIcoEndBlock;
    }

    function changePriceUpdateWaitingTime(uint256 newPriceUpdateWaitingTime) external onlyMainWallet{
        priceUpdateWaitingTime = newPriceUpdateWaitingTime;
    }

    function requestLiquidation(uint256 amountTokensToLiquidate) external isSetTrading onlyVerified{
        require(block.number > icoEndBlock);
        require(amountTokensToLiquidate > 0);
        address investor = msg.sender;
        require(balanceOf(investor) >= amountTokensToLiquidate);
        require(liquidations[investor].tokens == 0);
        balances[investor] = safeSub(balances[investor], amountTokensToLiquidate);
        liquidations[investor] = Liquidation({tokens: amountTokensToLiquidate, time: previousUpdateTime});
        LiquidationCall(investor, amountTokensToLiquidate);
    }

    function liquidate() external{
        address investor = msg.sender;
        uint256 tokens = liquidations[investor].tokens;
        require(tokens > 0);
        uint256 requestTime = liquidations[investor].time;
         
        PriceEDEX storage price = prices[requestTime];
        require(price.topInteger > 0);
        uint256 liquidationValue = safeMul(tokens, price.bottomInteger) / price.topInteger;
         
        liquidations[investor].tokens = 0;
        if (this.balance >= liquidationValue)
            enact_liquidation_greater_equal(investor, liquidationValue, tokens);
        else
            enact_liquidation_less(investor, liquidationValue, tokens);
    }

    function enact_liquidation_greater_equal(address investor, uint256 liquidationValue, uint256 tokens) private{
        assert(this.balance >= liquidationValue);
        balances[mainWallet] = safeAdd(balances[mainWallet], tokens);
        investor.transfer(liquidationValue);
        Liquidations(investor, tokens, liquidationValue);
    }
    
    function enact_liquidation_less(address investor, uint256 liquidationValue, uint256 tokens) private{
        assert(this.balance < liquidationValue);
        balances[investor] = safeAdd(balances[investor], tokens);
        Liquidations(investor, tokens, 0);
    }

    function checkLiquidationValue(uint256 amountTokensToLiquidate) constant returns (uint256 etherValue){
        require(amountTokensToLiquidate > 0);
        require(balanceOf(msg.sender) >= amountTokensToLiquidate);
        uint256 liquidationValue = safeMul(amountTokensToLiquidate, currentPrice.bottomInteger) / currentPrice.topInteger;
        require(this.balance >= liquidationValue);
        return liquidationValue;
    }

     
    function addLiquidity() external onlyControllingWallets payable{
        require(msg.value > 0);
        AddLiquidity(msg.value);
    }

     
    function removeLiquidity(uint256 amount) external onlyControllingWallets{
        require(amount <= this.balance);
        mainWallet.transfer(amount);
        RemoveLiquidity(amount);
    }

    function changeMainWallet(address newMainWallet) external onlyMainWallet{
        require(newMainWallet != address(0));
        mainWallet = newMainWallet;
    }

    function changeSecondaryWallet(address newSecondaryWallet) external onlyMainWallet{
        require(newSecondaryWallet != address(0));
        secondaryWallet = newSecondaryWallet;
    }

    function enableTrading() external onlyMainWallet{
        require(block.number > icoEndBlock);
        setTrading = true;
    }

    function claimEDEX(address _token) external onlyMainWallet{
        require(_token != address(0));
        Token token = Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(mainWallet, balance);
     }

     
    function transfer(address _to, uint256 _value) isSetTrading returns (bool success){
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) isSetTrading returns (bool success){
        return super.transferFrom(_from, _to, _value);
    }

    function haltICO() external onlyMainWallet{
        haltICO = true;
    }
    
    function unhaltICO() external onlyMainWallet{
        haltICO = false;
    }
    
     
    function() payable{
        require(tx.origin == msg.sender);
        buyTo(msg.sender);
    }
}