 

pragma solidity 0.4.18;

contract Token {  

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SafeMath {

  function safeMul(uint a, uint b) pure internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function safeSub(uint a, uint b) pure internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function safeAdd(uint a, uint b) pure internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  function safeNumDigits(uint number) pure internal returns (uint8) {
    uint8 digits = 0;
    while (number != 0) {
        number /= 10;
        digits++;
    }
    return digits;
}

   
   
   
  modifier onlyPayloadSize(uint numWords) {
     assert(msg.data.length >= numWords * 32 + 4);
     _;
  }

}

contract StandardToken is Token, SafeMath {

    uint256 public totalSupply;

    function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);

        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
     
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) public onlyPayloadSize(3) returns (bool success) {
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        Approval(msg.sender, _spender, _newValue);

        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

}

contract GRO is StandardToken {
     
    string public name = "Gron Digital";
    string public symbol = "GRO";
    uint256 public decimals = 18;
    string public version = "11.0";

     
    uint256 public tokenCap = 950000000 * 10**18;

     
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;

     
    address public vestingContract;
    bool private vestingSet = false;

     
    address public fundWallet;
     
    address public controlWallet;
     
    uint256 public waitTime = 5 hours;

     
     
    bool public halted = false;
    bool public tradeable = false;

     
     

    uint256 public previousUpdateTime = 0;
    Price public currentPrice;
    uint256 public minAmount;  

     
    mapping (address => Withdrawal) public withdrawals;
     
    mapping (uint256 => Price) public prices;
     
    mapping (address => bool) public whitelist;

     

    struct Price {  
        uint256 numerator;
    }

    struct Withdrawal {
        uint256 tokens;
        uint256 time;  
    }

     

    event Buy(address indexed participant, address indexed beneficiary, uint256 weiValue, uint256 amountTokens);
    event AllocatePresale(address indexed participant, uint256 amountTokens);
    event BonusAllocation(address indexed participant, string participant_addr, string txnHash, uint256 bonusTokens);
    event Mint(address indexed to, uint256 amount);
    event Whitelist(address indexed participant);
    event PriceUpdate(uint256 numerator);
    event AddLiquidity(uint256 ethAmount);
    event RemoveLiquidity(uint256 ethAmount);
    event WithdrawRequest(address indexed participant, uint256 amountTokens);
    event Withdraw(address indexed participant, uint256 amountTokens, uint256 etherAmount);

     

    modifier isTradeable {  
        require(tradeable || msg.sender == fundWallet || msg.sender == vestingContract);
        _;
    }

    modifier onlyWhitelist {
        require(whitelist[msg.sender]);
        _;
    }

    modifier onlyFundWallet {
        require(msg.sender == fundWallet);
        _;
    }

    modifier onlyManagingWallets {
        require(msg.sender == controlWallet || msg.sender == fundWallet);
        _;
    }

    modifier only_if_controlWallet {
        if (msg.sender == controlWallet) _;
    }
    modifier require_waited {
      require(safeSub(currentTime(), waitTime) >= previousUpdateTime);
        _;
    }
    modifier only_if_decrease (uint256 newNumerator) {
        if (newNumerator < currentPrice.numerator) _;
    }

     
    function GRO() public {
        fundWallet = msg.sender;
        whitelist[fundWallet] = true;
        previousUpdateTime = currentTime();
    }

     
     
     
    function initialiseContract(address controlWalletInput, uint256 priceNumeratorInput, uint256 startBlockInput, uint256 endBlockInput) external onlyFundWallet {
      require(controlWalletInput != address(0));
      require(priceNumeratorInput > 0);
      require(endBlockInput > startBlockInput);
      controlWallet = controlWalletInput;
      whitelist[controlWallet] = true;
      currentPrice = Price(priceNumeratorInput);
      fundingStartBlock = startBlockInput;
      fundingEndBlock = endBlockInput;
      previousUpdateTime = currentTime();
      minAmount = 0.05 ether;  
    }

     

    function setVestingContract(address vestingContractInput) external onlyFundWallet {
        require(vestingContractInput != address(0));
        vestingContract = vestingContractInput;
        whitelist[vestingContract] = true;
        vestingSet = true;
    }

     
    function updatePrice(uint256 newNumerator) external onlyManagingWallets {
        require(newNumerator > 0);
        require_limited_change(newNumerator);
         
        currentPrice.numerator = newNumerator;
         
        prices[previousUpdateTime] = currentPrice;
        previousUpdateTime = currentTime();
        PriceUpdate(newNumerator);
    }

    function require_limited_change (uint256 newNumerator)
      private
      view
      only_if_controlWallet
      require_waited
      only_if_decrease(newNumerator)
    {
        uint256 percentage_diff = 0;
        percentage_diff = safeMul(newNumerator, 100) / currentPrice.numerator;
        percentage_diff = safeSub(100, percentage_diff);
         
        require(percentage_diff <= 20);
    }

    function mint(address participant, uint256 amountTokens) private {
        require(vestingSet);
         

	 
	 
	 
	 
	uint256 precision = 10**18;
	uint256 allocationRatio = safeMul(amountTokens, precision) / safeMul(570000000, precision);
        uint256 developmentAllocation = safeMul(allocationRatio, safeMul(380000000, precision)) / precision;
         
        uint256 newTokens = safeAdd(amountTokens, developmentAllocation);
        require(safeAdd(totalSupply, newTokens) <= tokenCap);
         
        totalSupply = safeAdd(totalSupply, newTokens);
        balances[participant] = safeAdd(balances[participant], amountTokens);
        balances[vestingContract] = safeAdd(balances[vestingContract], developmentAllocation);

	Mint(fundWallet, newTokens);
	Transfer(fundWallet, participant, amountTokens);
	Transfer(fundWallet, vestingContract, developmentAllocation);
    }

     
     
    function allocatePresaleTokens(
			       address participant_address,
			       string participant_str,
			       uint256 amountTokens,
			       string txnHash
			       )
      external onlyFundWallet {

      require(currentBlock() < fundingEndBlock);
      require(participant_address != address(0));
     
      uint256 bonusTokens = 0;
      uint256 totalTokens = safeMul(amountTokens, 10**18);  

      if (firstDigit(txnHash) == firstDigit(participant_str)) {
	   
	  bonusTokens = safeMul(totalTokens, 10) / 100;
	  totalTokens = safeAdd(totalTokens, bonusTokens);
      }
        
        mint(participant_address, totalTokens);
	 
        AllocatePresale(participant_address, totalTokens);
	BonusAllocation(participant_address, participant_str, txnHash, bonusTokens);
    }

     
     
    function firstDigit(string s) pure public returns(byte){
	bytes memory strBytes = bytes(s);
	return strBytes[2];
      }

    function verifyParticipant(address participant) external onlyManagingWallets {
        whitelist[participant] = true;
        Whitelist(participant);
    }

     
    function() payable public {
      require(tx.origin == msg.sender);
      buyTo(msg.sender);
    }

    function buy() external payable {
        buyTo(msg.sender);
    }

    function buyTo(address participant) public payable {
      require(!halted);
      require(participant != address(0));
      require(msg.value >= minAmount);
      require(currentBlock() < fundingEndBlock);
       
      uint256 baseAmountTokens = safeMul(msg.value, currentPrice.numerator);
       
      uint256 lotteryAmount = blockLottery(baseAmountTokens);
      uint256 icoAmount = safeMul(msg.value, icoNumeratorPrice());

      uint256 tokensToBuy = safeAdd(icoAmount, lotteryAmount);
      mint(participant, tokensToBuy);
       
      fundWallet.transfer(msg.value);
       
      Buy(msg.sender, participant, msg.value, tokensToBuy);
    }

     
    function icoNumeratorPrice() public constant returns (uint256) {

      if (currentBlock() < fundingStartBlock){
	return 14000;
      }
      
      uint256 icoDuration = safeSub(currentBlock(), fundingStartBlock);

      uint256 firstBlockPhase = 80640;  
      uint256 secondBlockPhase = 161280;  
      uint256 thirdBlockPhase = 241920;  

      if (icoDuration < firstBlockPhase ) {
	return  13000;	  
      } else if (icoDuration < secondBlockPhase ) { 
	return  12000;	    
      } else if (icoDuration < thirdBlockPhase ) { 
	return 11000;	    
      } else {
	return 10000;
      }
    }

    function currentBlock() private constant returns(uint256 _currentBlock) {
      return block.number;
    }

    function currentTime() private constant returns(uint256 _currentTime) {
      return now;
    }

    function blockLottery(uint256 _amountTokens) private constant returns(uint256) {
      uint256 divisor = 10;
      uint256 winning_digit = 0;
      uint256 tokenWinnings = 0;

      if (currentBlock() % divisor == winning_digit) {
	tokenWinnings = safeMul(_amountTokens, 10) / 100;
      }
      
      return tokenWinnings;	
    }

    function requestWithdrawal(uint256 amountTokensToWithdraw) external isTradeable onlyWhitelist {
      require(currentBlock() > fundingEndBlock);
        require(amountTokensToWithdraw > 0);
        address participant = msg.sender;
        require(balanceOf(participant) >= amountTokensToWithdraw);
        require(withdrawals[participant].tokens == 0);  
        balances[participant] = safeSub(balances[participant], amountTokensToWithdraw);
        withdrawals[participant] = Withdrawal({tokens: amountTokensToWithdraw, time: previousUpdateTime});
        WithdrawRequest(participant, amountTokensToWithdraw);
    }

    function withdraw() external {
        address participant = msg.sender;
        uint256 tokens = withdrawals[participant].tokens;
        require(tokens > 0);  
        uint256 requestTime = withdrawals[participant].time;
         
        Price price = prices[requestTime];
        require(price.numerator > 0);  
        uint256 withdrawValue = tokens / price.numerator;
         
        withdrawals[participant].tokens = 0;
        if (this.balance >= withdrawValue) {
            enact_withdrawal_greater_equal(participant, withdrawValue, tokens);
	}
        else {
            enact_withdrawal_less(participant, withdrawValue, tokens);
	}
    }

    function enact_withdrawal_greater_equal(address participant, uint256 withdrawValue, uint256 tokens)
        private
    {
        assert(this.balance >= withdrawValue);
        balances[fundWallet] = safeAdd(balances[fundWallet], tokens);
        participant.transfer(withdrawValue);
        Withdraw(participant, tokens, withdrawValue);
    }
    function enact_withdrawal_less(address participant, uint256 withdrawValue, uint256 tokens)
        private
    {
        assert(this.balance < withdrawValue);
        balances[participant] = safeAdd(balances[participant], tokens);
        Withdraw(participant, tokens, 0);  
    }

     
     
     
    function checkWithdrawValue(uint256 amountTokensInSubunit) public constant returns (uint256 weiValue) {
        require(amountTokensInSubunit > 0);
        require(balanceOf(msg.sender) >= amountTokensInSubunit);
        uint256 withdrawValue = amountTokensInSubunit / currentPrice.numerator;
        require(this.balance >= withdrawValue);
        return withdrawValue;
    }

     
    function addLiquidity() external onlyManagingWallets payable {
        require(msg.value > 0);
        AddLiquidity(msg.value);
    }

     
    function removeLiquidity(uint256 amount) external onlyManagingWallets {
        require(amount <= this.balance);
        fundWallet.transfer(amount);
        RemoveLiquidity(amount);
    }

    function changeFundWallet(address newFundWallet) external onlyFundWallet {
        require(newFundWallet != address(0));
        fundWallet = newFundWallet;
    }

    function changeControlWallet(address newControlWallet) external onlyFundWallet {
        require(newControlWallet != address(0));
        controlWallet = newControlWallet;
    }

    function changeWaitTime(uint256 newWaitTime) external onlyFundWallet {
        waitTime = newWaitTime;
    }

     
    function changeMinAmount(uint256 newMinAmount) external onlyFundWallet {
      minAmount = newMinAmount;
    }

    function updateFundingStartBlock(uint256 newFundingStartBlock) external onlyFundWallet {
      require(currentBlock() < fundingStartBlock);
        require(currentBlock() < newFundingStartBlock);
        fundingStartBlock = newFundingStartBlock;
    }

    function updateFundingEndBlock(uint256 newFundingEndBlock) external onlyFundWallet {
        require(currentBlock() < fundingEndBlock);
        require(currentBlock() < newFundingEndBlock);
        fundingEndBlock = newFundingEndBlock;
    }

    function halt() external onlyFundWallet {
        halted = true;
    }
    function unhalt() external onlyFundWallet {
        halted = false;
    }

    function enableTrading() external onlyFundWallet {
        require(currentBlock() > fundingEndBlock);
        tradeable = true;
    }

    function claimTokens(address _token) external onlyFundWallet {
        require(_token != address(0));
        Token token = Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(fundWallet, balance);
     }

     
    function transfer(address _to, uint256 _value) public isTradeable returns (bool success) {
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public isTradeable returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }
}