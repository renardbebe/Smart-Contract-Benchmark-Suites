 

pragma solidity ^0.4.23;

 

 
 
 
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

 

 
 
 
contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

 

 
 
 
contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 

 
 
 
 
 
 
 


 
 
 
 
contract UncToken is SafeMath, Owned, ERC20 {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

     
    bool private transferEnabled = false;

     
    mapping(address => bool) public transferAdmins;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) internal allowed;

    event Burned(address indexed burner, uint256 value);

     
    modifier canTransfer(address _sender) {
        require(transferEnabled || transferAdmins[_sender]);
        _;
    }

     
     
     
    constructor() public {
        symbol = "UNC";
        name = "Uncloak";
        decimals = 18;
        _totalSupply = 4200000000 * 10**uint(decimals);
        transferAdmins[owner] = true;  
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) canTransfer (msg.sender) public returns (bool success) {
        require(to != address(this));  

         
        if (balances[msg.sender] >= tokens
            && tokens > 0) {

                 
                balances[msg.sender] = safeSub(balances[msg.sender], tokens);
                balances[to] = safeAdd(balances[to], tokens);

                 
                emit Transfer(msg.sender, to, tokens);
                return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
         
         
        require((tokens == 0) || (allowed[msg.sender][spender] == 0));

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) canTransfer(from) public returns (bool success) {
        require(to != address(this));

         
        if (allowed[from][msg.sender] >= tokens
            && balances[from] >= tokens
            && tokens > 0) {

             
            balances[from] = safeSub(balances[from], tokens);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);

             
            emit Transfer(from, to, tokens);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
    function setTransferAdmin(address _addr, bool _canTransfer) onlyOwner public {
        transferAdmins[_addr] = _canTransfer;
    }

     
    function enablesTransfers() public onlyOwner {
        transferEnabled = true;
    }

     
     
     
    function burn(uint256 _value) public onlyOwner {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = safeSub(balances[burner], _value);
        _totalSupply = safeSub(_totalSupply, _value);
        emit Burned(burner, _value);
    }

     
     
     
    function () public payable {
        revert();
    }
}

 

 
 
 
 
contract TimeLock is SafeMath, Owned {

   
  UncToken public token;

   
  address public beneficiary;

   
  uint256 public releaseTime1;
  uint256 public releaseTime2;
  uint256 public releaseTime3;

   
  uint256 public initialBalance;

   
  uint public step = 0;

   
  constructor(UncToken _token, address _beneficiary, uint256 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime1 = _releaseTime;
    releaseTime2 = safeAdd(releaseTime1, 7776000);   
    releaseTime3 = safeAdd(releaseTime1, 15552000);   
  }


   
  function setInitialBalance() public onlyOwner {
  	initialBalance = token.balanceOf(address(this));
  }

   
  function updateReleaseTime(uint256 _releaseTime) public onlyOwner {
  	 
  	require(now < releaseTime1);
  	require(_releaseTime < releaseTime1);

  	 
  	releaseTime1 = _releaseTime;
    releaseTime2 = safeAdd(releaseTime1, 7776000);   
    releaseTime3 = safeAdd(releaseTime1, 15552000);   
  }

   
  function release() public {
    require(now >= releaseTime1);

    uint256 unlockAmount = 0;

     
    uint256 amount = initialBalance;
    require(amount > 0);

     
    if (step == 0 && now > releaseTime1) {
    	unlockAmount = safeDiv(safeMul(amount, 4), 10);  
    }
    else if (step == 1 && now > releaseTime2) {
    	unlockAmount = safeDiv(safeMul(amount, 4), 10);  
    }
    else if (step == 2 && now > releaseTime3) {
    	unlockAmount = token.balanceOf(address(this));
    }
     
    require(unlockAmount != 0);

     
    require(token.transfer(beneficiary, unlockAmount));
    step++;

  }
}

 

 
 
 
 
contract UncTokenSale is SafeMath, Pausable {

	 
	address public beneficiary;

	 
	UncToken  public token;

	 
	uint public hardCap;
    uint public highBonusRate = 115;
    uint public lowBonusRate = 110;
	uint public constant highBonus = 160000000000000000000;  
	uint public constant minContribution = 4000000000000000000;  
	uint public constant preMaxContribution = 200000000000000000000;  
	uint public constant mainMaxContribution = 200000000000000000000;  

	 
	mapping(address => bool) public isVerifier;
	 
	mapping(address => bool) public kycVerified;

	 
	uint public preSaleTime;
	uint public mainSaleTime;
	uint public endSaleTime;

	 
	uint public amountRaised;

	 
	bool public beforeSale = true;
	bool public preSale = false;
	bool public mainSale = false;
	bool public saleEnded = false;
	bool public hardCapReached = false;

	 
	mapping(address => address) public timeLocks;

	 
	uint public rate = 45000;  
	uint public constant lowRate = 10000;
	uint public constant highRate = 1000000;

	 
	mapping(address => uint256) public contributionAmtOf;

	 
	mapping(address => uint256) public tokenBalanceOf;

     
	mapping(address => uint256) public teamTokenBalanceOf;

    event HardReached(address _beneficiary, uint _amountRaised);
    event BalanceTransfer(address _to, uint _amount);
    event AddedOffChain(address indexed _beneficiary, uint256 tokensAllocated);
    event RateChanged(uint newRate);
    event VerifiedKYC(address indexed person);
     

    modifier beforeEnd() { require (now < endSaleTime); _; }
    modifier afterEnd() { require (now >= endSaleTime); _; }
    modifier afterStart() { require (now >= preSaleTime); _; }

    modifier saleActive() { require (!(beforeSale || saleEnded)); _; }

    modifier verifierOnly() { require(isVerifier[msg.sender]); _; }

     
    constructor (
    UncToken  _token,
    address _beneficiary,
    uint _preSaleTime,
    uint _mainSaleTime,
    uint _endSaleTime,
    uint _hardCap
    ) public
    {
     
     

     
    isVerifier[msg.sender] = true;

    	token = _token;
    	beneficiary = _beneficiary;
    	preSaleTime = _preSaleTime;
    	mainSaleTime = _mainSaleTime;
    	endSaleTime = _endSaleTime;
    	hardCap = _hardCap;

    	 

    }


     
    function () public payable whenNotPaused {
    	 
    	uint amount = msg.value;

    	uint newTotalContribution = safeAdd(contributionAmtOf[msg.sender], msg.value);

    	 
    	require(amount >= minContribution);

    	if (preSale) {
    		require(newTotalContribution <= preMaxContribution);
    	}

    	if (mainSale) {
    		require(newTotalContribution <= mainMaxContribution);
    	}

    	 
    	allocateTokens(msg.sender, amount);
    }


     
    function allocateTokens(address investor, uint _amount) internal {
    	 
    	require(kycVerified[investor]);

    	 
    	uint numTokens = safeMul(_amount, rate);

    	 
    	if (preSale) {
    		 
    		if (_amount >= highBonus) {
    			numTokens = safeDiv(safeMul(numTokens, highBonusRate), 100);
    		}

            else {
                numTokens = safeDiv(safeMul(numTokens, lowBonusRate), 100);
            }
    	}
    	else {
    			numTokens = safeDiv(safeMul(numTokens, lowBonusRate), 100);
    		}

    	 
    	require(token.balanceOf(address(this)) >= numTokens);
    	tokenBalanceOf[investor] = safeAdd(tokenBalanceOf[investor], numTokens);

    	 
    	token.transfer(investor, numTokens);

    	 
    	contributionAmtOf[investor] = safeAdd(contributionAmtOf[investor], _amount);
    	amountRaised = safeAdd(amountRaised, _amount);

    	
    }

     
    function tokenTransfer(address recipient, uint numToks) public onlyOwner {
        token.transfer(recipient, numToks);
    }

     
    function beneficiaryWithdrawal() external onlyOwner {
    	uint contractBalance = address(this).balance;
    	 
    	beneficiary.transfer(contractBalance);
    	emit BalanceTransfer(beneficiary, contractBalance);
    }

    	 
    	function terminate() external onlyOwner {
        saleEnded = true;
    }

     
    function setRate(uint _rate) public onlyOwner {
    	require(_rate >= lowRate && _rate <= highRate);
    	rate = _rate;

    	emit RateChanged(rate);
    }


     
     
    function checkHardReached() internal {
    	if(!hardCapReached) {
    		if (token.balanceOf(address(this)) == 0) {
    			hardCapReached = true;
    			saleEnded = true;
    			emit HardReached(beneficiary, amountRaised);
    		}
    	}
    }

     
    function startPreSale() public onlyOwner {
    	beforeSale = false;
    	preSale = true;
    }

     
    function startMainSale() public afterStart onlyOwner {
    	preSale = false;
    	mainSale = true;
    }

     
    function endSale() public afterStart onlyOwner {
    	preSale = false;
    	mainSale = false;
    	saleEnded = true;
    }

     
    function updatePreSaleTime(uint newTime) public onlyOwner {
    	require(beforeSale == true);
    	require(now < preSaleTime);
    	require(now < newTime);

    	preSaleTime = newTime;
    }

     
    function updateMainSaleTime(uint newTime) public onlyOwner {
    	require(mainSale != true);
    	require(now < mainSaleTime);
    	require(now < newTime);

    	mainSaleTime = newTime;
    }

     
    function updateEndSaleTime(uint newTime) public onlyOwner {
    	require(saleEnded != true);
    	require(now < endSaleTime);
    	require(now < newTime);

    	endSaleTime = newTime;
    }

     
    function burnUnsoldTokens() public afterEnd onlyOwner {
    	 
    	uint256 tokensToBurn = token.balanceOf(address(this));
    	token.burn(tokensToBurn);
    }

     
    function addVerifier (address _address) public onlyOwner {
        isVerifier[_address] = true;
    }

     
    function removeVerifier (address _address) public onlyOwner {
        isVerifier[_address] = false;
    }

     
    function verifyKYC(address[] participants) public verifierOnly {
    	require(participants.length > 0);

    	 
    	for (uint256 i = 0; i < participants.length; i++) {
    		kycVerified[participants[i]] = true;
    		emit VerifiedKYC(participants[i]);
    	}
    }

     
    function moveReleaseTime(address person, uint256 newTime) public onlyOwner {
    	require(timeLocks[person] != 0x0);
    	require(now < newTime);

    	 
    	TimeLock lock = TimeLock(timeLocks[person]);

    	lock.updateReleaseTime(newTime);
    }

     
    function releaseLock(address person) public {
    	require(timeLocks[person] != 0x0);

    	 
    	TimeLock lock = TimeLock(timeLocks[person]);

    	 
    	lock.release();
    }

     
    function offChainTrans(address participant, uint256 tokensAllocated, uint256 contributionAmt, bool isFounder) public onlyOwner {
    	uint256 startTime;

         
    	uint256 tokens = tokensAllocated;
    	 
    	require(token.balanceOf(address(this)) >= tokens);

    	 
    	contributionAmtOf[participant] = safeAdd(contributionAmtOf[participant], contributionAmt);

    	 
    	tokenBalanceOf[participant] = safeAdd(tokenBalanceOf[participant], tokens);

    	 
    	if (isFounder) {
             
            startTime = 1559347200;
        }
        else {
             
            startTime = 1540886400;
        }

    	 
    	TimeLock lock;

    	 
    	if (timeLocks[participant] == 0x0) {
    		lock = new TimeLock(token, participant, startTime);
    		timeLocks[participant] = address(lock);
    	} else {
    		lock = TimeLock(timeLocks[participant]);
    	}

    	 
    	token.transfer(lock, tokens);
    	lock.setInitialBalance();

    	 
    	emit AddedOffChain(participant, tokensAllocated);
    }

}