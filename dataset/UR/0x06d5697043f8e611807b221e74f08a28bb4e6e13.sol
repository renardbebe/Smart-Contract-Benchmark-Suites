 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 
 


 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;
    
    address public ownerAPI;
    address public newOwnerAPI;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event OwnershipAPITransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        ownerAPI = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerAPI {
        require(msg.sender == ownerAPI);
        _;
    }

    modifier onlyOwnerOrOwnerAPI {
        require(msg.sender == owner || msg.sender == ownerAPI);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function transferAPIOwnership(address _newOwnerAPI) public onlyOwner {
        newOwnerAPI = _newOwnerAPI;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    function acceptOwnershipAPI() public {
        require(msg.sender == newOwnerAPI);
        emit OwnershipAPITransferred(ownerAPI, newOwnerAPI);
        ownerAPI = newOwnerAPI;
        newOwnerAPI = address(0);
    }
}

 
contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public isPaused = false;

  function paused() public view returns (bool currentlyPaused) {
      return isPaused;
  }

   
  modifier whenNotPaused() {
    require(!isPaused);
    _;
  }

   
  modifier whenPaused() {
    require(isPaused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    isPaused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    isPaused = false;
    emit Unpause();
  }
}


 
 
 
 
contract KaasyToken is ERC20Interface, Pausable, SafeMath {
    string public symbol = "KAAS";
    string public  name  = "KAASY.AI Token";
    uint8 public decimals = 18;
    uint public _totalSupply;
    uint public startDate;
    uint public bonusEnd20;
    uint public bonusEnd10;
    uint public bonusEnd05;
    uint public endDate;
    uint public tradingDate;
    uint public exchangeRate = 30000;  
    uint256 public maxSupply;
    uint256 public soldSupply;
    uint256 public maxSellable;
    uint8 private teamWOVestingPercentage = 5;
    
    uint256 public minAmountETH;
    uint256 public maxAmountETH;
    
    address public currentRunningAddress;

    mapping(address => uint256) balances;  
    mapping(address => uint256) ethDeposits;  
    mapping(address => bool) kycAddressState;  
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) burnedBalances;  

     
    
    event MintingFinished(uint indexed moment);
    bool isMintingFinished = false;
    
    event OwnBlockchainLaunched(uint indexed moment);
    event TokensBurned(address indexed exOwner, uint256 indexed amount, uint indexed moment);
    bool isOwnBlockchainLaunched = false;
    uint momentOwnBlockchainLaunched = 0;
    
    uint8 public versionIndex = 1;
    
    address addrUniversity;
    address addrEarlySkills;
    address addrHackathons;
    address addrLegal;
    address addrMarketing;

     
     
     
    constructor() public {
        maxSupply = 500000000 * (10 ** 18);
        maxSellable = maxSupply * 60 / 100;
        
        currentRunningAddress = address(this);
        
        soldSupply = 0;
        
        startDate = 1535760000;   
        bonusEnd20 = 1536969600;  
        bonusEnd10 = 1538179200;  
        bonusEnd05 = 1539388800;  
        endDate = 1542240000;     
        tradingDate = 1543536000; 
        
        minAmountETH = safeDiv(1 ether, 10);
        maxAmountETH = safeMul(1 ether, 5000);
        
        uint256 teamAmount = maxSupply * 150 / 1000;
        
        balances[address(this)] = teamAmount * (100 - teamWOVestingPercentage) / 100;  
        emit Transfer(address(0), address(this), balances[address(this)]);
        
        balances[owner] = teamAmount * teamWOVestingPercentage / 100;  
        kycAddressState[owner] = true;
        emit Transfer(address(0), owner, balances[owner]);
        
        addrUniversity = 0x7a0De4748E5E0925Bf80989A7951E15a418e4326;
        balances[addrUniversity] =  maxSupply * 50 / 1000;  
        kycAddressState[addrUniversity] = true;
        emit Transfer(address(0), addrUniversity, balances[addrUniversity]);
        
        addrEarlySkills = 0xe1e0769b37c1C66889BdFE76eaDfE878f98aa4cd;
        balances[addrEarlySkills] = maxSupply * 50 / 1000;  
        kycAddressState[addrEarlySkills] = true;
        emit Transfer(address(0), addrEarlySkills, balances[addrEarlySkills]);
        
        addrHackathons = 0xe9486863859b0facB9C62C46F7e3B70C476bc838;
        balances[addrHackathons] =  maxSupply * 45 / 1000;  
        kycAddressState[addrHackathons] = true;
        emit Transfer(address(0), addrHackathons, balances[addrHackathons]);
        
        addrLegal = 0xDcdb9787ead2E0D3b12ED0cf8200Bc91F9Aaa045;
        balances[addrLegal] =       maxSupply * 30 / 1000;  
        kycAddressState[addrLegal] = true;
        emit Transfer(address(0), addrLegal, balances[addrLegal]);
        
        addrMarketing = 0x4f11859330D389F222476afd65096779Eb1aDf25;
        balances[addrMarketing] =   maxSupply * 75 / 1000;  
        kycAddressState[addrMarketing] = true;
        emit Transfer(address(0), addrMarketing, balances[addrMarketing]);
        
        _totalSupply = maxSupply * 40 / 100;
        
        
    }

     
     
     
    function () public payable whenNotPaused {
        if(now > endDate && isMintingFinished == false) {
            finishMinting();
            msg.sender.transfer(msg.value);  
        } else {
            require(now >= startDate && now <= endDate && isMintingFinished == false);
            
            require(msg.value >= minAmountETH && msg.value <= maxAmountETH);
            require(msg.value + ethDeposits[msg.sender] <= maxAmountETH);
            
            require(kycAddressState[msg.sender] == true);
            
            uint tokens = getAmountToIssue(msg.value);
            require(safeAdd(soldSupply, tokens) <= maxSellable);
            
            soldSupply = safeAdd(soldSupply, tokens);
            _totalSupply = safeAdd(_totalSupply, tokens);
            balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
            ethDeposits[msg.sender] = safeAdd(ethDeposits[msg.sender], msg.value);
            emit Transfer(address(0), msg.sender, tokens);
            
            owner.transfer(msg.value * 15 / 100);    
        }
    }
    
     
     
     
    function BurnMyTokensAndSetAmountForNewBlockchain() public  {
        require(isOwnBlockchainLaunched);
        
        uint senderBalance = balances[msg.sender];
        burnedBalances[msg.sender] = safeAdd(burnedBalances[msg.sender], senderBalance);
        balances[msg.sender] = 0;
        emit TokensBurned(msg.sender, senderBalance, now);
    }
    
     
     
     
    function BurnTokensAndSetAmountForNewBlockchain(address exOwner) onlyOwnerOrOwnerAPI public {
        require(isOwnBlockchainLaunched);
        
        uint exBalance = balances[exOwner];
        burnedBalances[exOwner] = safeAdd(burnedBalances[exOwner], exBalance);
        balances[exOwner] = 0;
        emit TokensBurned(exOwner, exBalance, now);
    }
    
     
     
     
    function SetNewBlockchainEnabled() onlyOwner public {
        require(isMintingFinished && isOwnBlockchainLaunched == false);
        isOwnBlockchainLaunched = true;
        momentOwnBlockchainLaunched = now;
        emit OwnBlockchainLaunched(now);
    }

     
     
     
    function finishMinting() public returns (bool finished) {
        if(now > endDate && isMintingFinished == false) {
            internalFinishMinting();
            return true;
        } else if (_totalSupply >= maxSupply) {
            internalFinishMinting();
            return true;
        }
        if(now > endDate && address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
        return false;
    }
    
     
     
     
     
     
     
    function internalFinishMinting() internal {
        tradingDate = now + 3600; 
        isMintingFinished = true;
        emit MintingFinished(now);
        owner.transfer(address(this).balance);  
    }

     
     
     
     
    function getAmountToIssue(uint256 ethAmount) public view returns(uint256) {
         
        uint256 euroAmount = exchangeEthToEur(ethAmount);
        uint256 ret = euroAmount / 10;  
        ret = ret * (uint256)(10) ** (uint256)(decimals);
        if(now < bonusEnd20) {
            ret = euroAmount * 12;           
            
        } else if(now < bonusEnd10) {
            ret = euroAmount * 11;           
            
        } else if(now < bonusEnd05) {
            ret = euroAmount * 105 / 10;     
            
        }
        
        if(euroAmount >= 50000) {
            ret = ret * 13 / 10;
            
        } else if(euroAmount >= 10000) {
            ret = ret * 12 / 10;
        }
        
        return ret;
    }
    
     
     
     
    function exchangeEthToEur(uint256 ethAmount) internal view returns(uint256 rate) {
        return safeDiv(safeMul(ethAmount, exchangeRate), 1 ether);
    }
    
     
     
     
    function exchangeEurToEth(uint256 eurAmount) internal view returns(uint256 rate) {
        return safeDiv(safeMul(safeDiv(safeMul(eurAmount, 1000000000000000000), exchangeRate), 1 ether), 1000000000000000000);
    }
    
     
     
     
    function transferVestingMonthlyAmount(address destination) public onlyOwner returns (bool) {
        require(destination != address(0));
        uint monthsSinceLaunch = (now - tradingDate) / 3600 / 24 / 30;
        uint256 totalAmountInVesting = maxSupply * 15 / 100 * (100 - teamWOVestingPercentage) / 100;  
        uint256 releaseableUpToToday = (monthsSinceLaunch + 1) * totalAmountInVesting / 24;  
        
         
        uint256 alreadyReleased = totalAmountInVesting - balances[address(this)];
        uint256 releaseableNow = releaseableUpToToday - alreadyReleased;
        require (releaseableNow > 0);
        transferFrom(address(this), destination, releaseableNow);
        
        return true;
    }
    
     
     
     
    function setAddressKYC(address depositer, bool isAllowed) public onlyOwnerOrOwnerAPI returns (bool) {
        kycAddressState[depositer] = isAllowed;
         
        return true;
    }
    
     
     
     
    function getAddressKYCState(address depositer) public view returns (bool) {
        return kycAddressState[depositer];
    }
    
     
     
     
    function name() public view returns (string) {
        return name;
    }
    
     
     
     
    function symbol() public view returns (string) {
        return symbol;
    }
    
     
     
     
    function decimals() public view returns (uint8) {
        return decimals;
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];  
    }
    
     
     
     
    function circulatingSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)] - balances[address(this)];  
    }

     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    
     
     
     
    function depositsOf(address depositer) public constant returns (uint balance) {
        return ethDeposits[depositer];
    }
    
     
     
     
    function burnedBalanceOf(address exOwner) public constant returns (uint balance) {
        return burnedBalances[exOwner];
    }

     
     
     
     
     
     
    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        if(now > endDate && isMintingFinished == false) {
            finishMinting();
        }
        require(now >= tradingDate || kycAddressState[to] == true);  
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
     
     
     
    
     
     
     
    
     
    function approve(address destination, uint amount) public returns (bool success) {
        allowed[msg.sender][destination] = amount;
        emit Approval(msg.sender, destination, amount);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
        if(now > endDate && isMintingFinished == false) {
            finishMinting();
        }
        require(now >= tradingDate || kycAddressState[to] == true);  
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address requester) public constant returns (uint remaining) {
        return allowed[tokenOwner][requester];
    }

     
     
     
     
     
    function approveAndCall(address requester, uint tokens, bytes data) public whenNotPaused returns (bool success) {
        allowed[msg.sender][requester] = tokens;
        emit Approval(msg.sender, requester, tokens);
        ApproveAndCallFallBack(requester).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
     
     
     
    function transferAllERC20Token(address tokenAddress, uint tokens) public onlyOwnerOrOwnerAPI returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
     
     
     
    function transferAnyERC20Token(address tokenAddress) public onlyOwnerOrOwnerAPI returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, ERC20Interface(tokenAddress).balanceOf(this));
    }
    
     
     
     
    function updateExchangeRate(uint newEthEurRate) public onlyOwnerOrOwnerAPI returns (bool success) {
        exchangeRate = newEthEurRate;
        return true;
    }
    
     
     
     
    function getExchangeRate() public view returns (uint256 rate) {
        return exchangeRate;
    }
    
     
     
     
    function updateEndDate(uint256 newDate) public onlyOwnerOrOwnerAPI returns (bool success) {
        require(!isMintingFinished);
        require(!isOwnBlockchainLaunched);
        
        endDate = newDate;
        
        return true;
    }
    
     
     
     
    function updateTokenNameSymbolAddress(string newTokenName, string newSymbol, address newContractAddress) public whenPaused onlyOwnerOrOwnerAPI returns (bool success) {
        name = newTokenName;
        symbol = newSymbol;
        currentRunningAddress = newContractAddress;
        
        return true;
    }
    
}