 

pragma solidity ^0.4.25;

 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Pausable is Ownable {
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


 

contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    function transfer(address to, uint value, bytes data) public;
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

 
 
contract ERC223ReceivingContract { 
 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 
 
contract ERC223Token is ERC223Interface, Pausable  {
    using SafeMath for uint;

    mapping(address => uint) balances;  
    
     
     
    function transfer(address _to, uint _value, bytes _data) public whenNotPaused {
         
         
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
    }
    
     
    function transfer(address _to, uint _value) public whenNotPaused {
        uint codeLength;
        bytes memory empty;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value, empty);
    }

    
     
    function balanceOf(address _owner) public whenNotPaused constant returns (uint balance)  {
        return balances[_owner];
    }
}


contract DskTokenMint is ERC223Token {
    
    string public constant name = "DONSCOIN";    
    string public constant symbol = "DSK";   
    uint256 public constant decimals = 18;   
    uint256 public constant INITIAL_SUPPLY = 220000000000 * (10 ** uint256(decimals));     
    uint256 public totalSupply = INITIAL_SUPPLY;     
    uint256 internal Percent = INITIAL_SUPPLY.div(100);  
    
    uint256 public ICOSupply = Percent.mul(30);  
    uint256 public DonscoinOwnerSupply = Percent.mul(70);

    address internal DonscoinOwner = 0x100eAc5b425C1e2527ee55ecdEF2EA2DfA4F904C ;   


    event InitSupply(uint256 owner, uint256 DonscoinOwner);
    
      
    
    constructor() public {
       
        emit InitSupply(ICOSupply, DonscoinOwnerSupply);
        
    }
    
}
contract WhitelistedCrowdsale is Ownable {

    mapping(address => bool) public whitelist;

    event AddWhiteList(address who);
    event DelWhiteList(address who);

     
    modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
    }

   
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
    emit AddWhiteList(_beneficiary);
  }
  
   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
    emit DelWhiteList(_beneficiary);
  }

}


 
 
contract DskCrowdSale is DskTokenMint, WhitelistedCrowdsale {
    
     
    uint constant Day = 60*60*24;
    uint constant Month = 60*60*24*30;
    uint constant SixMonth = 6 * Month;
    uint constant Year = 12 * Month;
    
     
    
    uint public StartTime = 1548374400;
    uint public EndTime = StartTime + SixMonth + 32400;  

     

    uint public PrivateSaleEndTime = StartTime.add(Day * 50);
    uint public PreSaleEndTime = PrivateSaleEndTime.add(Month*2);
    
      
    
    bool public SoftCapReached = false;
    bool public HardCapReached = false;
    bool public SaleClosed = false;
    
    bool private rentrancy_lock = false;  
    
    uint public constant Private_rate = 43875;  
    uint public constant Pre_rate = 38813;  
    uint public constant Public = 35438;  
    

    uint public MinInvestMent = 2 * (10 ** decimals);  
    uint public HardCap = 66000000000 * (10 ** uint256(decimals));   
    uint public SoftCap =  2200000000 * (10 ** uint256(decimals));  

     
     
    uint public TotalAmountETH;
    uint public SaleAmountDSK;
    uint public RefundAmount;
    
    uint public InvestorNum;     
    
    
     
     
    event SuccessCoreAccount(uint256 InvestorNum);
    event Burn(address burner, uint256 value);
    event SuccessInvestor(address RequestAddress, uint256 amount);
    event SuccessSoftCap(uint256 SaleAmountDsk, uint256 time);
    event SuccessHardCap(uint256 SaleAmountDsk, uint256 time);
    event SucessWithdraw(address who, uint256 AmountEth, uint256 time);
    event SuccessEthToOwner(address owner, uint256 AmountEth, uint256 time);
    
    event dskTokenToInvestors(address InverstorAddress, uint256 Amount, uint256 now);
    event dskTokenToCore(address CoreAddress, uint256 Amount, uint256 now);
    event FailsafeWithdrawal(address InverstorAddress, uint256 Amount, uint256 now);
    event FaildskTokenToInvestors(address InverstorAddress, uint256 Amount, uint256 now, uint256 ReleaseTime);
    event FaildskTokenToCore(address CoreAddress, uint256 Amount, uint256 now, uint256 ReleaseTime);
    event FailEthToOwner(address who, uint256 _amount, uint256 now);
    event safeWithdrawalTry(address who);


     
    modifier beforeDeadline()   { require (now < EndTime); _; }
    modifier afterDeadline()    { require (now >= EndTime); _; }
    modifier afterStartTime()   { require (now >= StartTime); _; }
    modifier saleNotClosed()    { require (!SaleClosed); _; }
    
    
     
     
    modifier nonReentrant() {

        require(!rentrancy_lock);

        rentrancy_lock = true;

        _;

        rentrancy_lock = false;

    }
    
     
     
    struct Investor {
    
    	uint256 EthAmount;
    	uint256 DskTokenAmount;
    	uint256 LockupTime;
    	bool    DskTokenWithdraw;
    	
    }
    
    
    mapping (address => Investor) public Inverstors;     
    mapping (uint256 => address) public InverstorList;   
    
    
    constructor() public {
        
         
     
        Inverstors[DonscoinOwner].EthAmount = 0;
        Inverstors[DonscoinOwner].LockupTime = StartTime + (Month*9);
        Inverstors[DonscoinOwner].DskTokenAmount = DonscoinOwnerSupply;
        Inverstors[DonscoinOwner].DskTokenWithdraw = false; 
        InverstorList[InvestorNum] = DonscoinOwner;
        InvestorNum++;
       
        
        emit SuccessCoreAccount(InvestorNum);
        
    }
    
    
     
    
    function() payable public isWhitelisted(msg.sender) whenNotPaused beforeDeadline afterStartTime saleNotClosed nonReentrant {
         
        require(msg.value >= MinInvestMent);     

        uint amount = msg.value;     
        
        uint CurrentTime = now;  
        
        address RequestAddress = msg.sender;     
        
        uint rate;   
        
        uint CurrentInvestMent = Inverstors[RequestAddress].EthAmount;   


        Inverstors[RequestAddress].EthAmount = CurrentInvestMent.add(amount);    

        Inverstors[RequestAddress].LockupTime = StartTime.add(Month*9);  
        
        Inverstors[RequestAddress].DskTokenWithdraw = false;     
        
        TotalAmountETH = TotalAmountETH.add(amount);  
        
       
         
       
        if(CurrentTime<PrivateSaleEndTime) {
            
            rate = Private_rate;
            
        } else if(CurrentTime<PreSaleEndTime) {
            
            rate = Pre_rate;
            
        } else {
            
            rate = Public;
            
        }


        uint NumDskToken = amount.mul(rate);     
        
        ICOSupply = ICOSupply.sub(NumDskToken);  
        
        
        if(ICOSupply > 0) {     
        
         
        Inverstors[RequestAddress].DskTokenAmount =  Inverstors[RequestAddress].DskTokenAmount.add(NumDskToken);
        
        SaleAmountDSK = SaleAmountDSK.add(NumDskToken);  
        
        CheckHardCap();  
        
        CheckSoftCap();  
        
        InverstorList[InvestorNum] = RequestAddress;     
        
        InvestorNum++;   
        
        emit SuccessInvestor(msg.sender, msg.value);     
        
        } else {

            revert();    
             
        }
    }
        
     
         
    function CheckHardCap() internal {

        if (!HardCapReached) {

            if (SaleAmountDSK >= HardCap) {

                HardCapReached = true;

                SaleClosed = true;
                
                emit SuccessSoftCap(SaleAmountDSK, now);

            }
        }
    }   
    
     
     
    function CheckSoftCap() internal {

        if (!SoftCapReached) {

            if (SaleAmountDSK >= SoftCap) {

                SoftCapReached = true;
                
                emit SuccessHardCap(SaleAmountDSK, now);

            } 
        }
    }  
 
     
     
    function safeWithdrawal() external afterDeadline nonReentrant {

        if (!SoftCapReached) {

            uint amount = Inverstors[msg.sender].EthAmount;
            
            Inverstors[msg.sender].EthAmount = 0;
            

            if (amount > 0) {

                msg.sender.transfer(amount);

                RefundAmount = RefundAmount.add(amount);

                emit SucessWithdraw(msg.sender, amount, now);

            } else { 
                
                emit FailsafeWithdrawal(msg.sender, amount, now);
                
                 
                
            }

        } else {
            
            emit safeWithdrawalTry(msg.sender);
            
        } 

    }
    
     
     
    function transferEthToOwner(uint256 _amount) public onlyOwner afterDeadline nonReentrant { 
        
        if(SoftCapReached) {
            
            owner.transfer(_amount); 
        
            emit SuccessEthToOwner(msg.sender, _amount, now);
        
        } else {
            
            emit FailEthToOwner(msg.sender, _amount, now);
            
        }   

    }
    
    
     
     
    function burn(uint256 _value) public onlyOwner afterDeadline nonReentrant {
        
        require(_value <= ICOSupply);

        address burner = msg.sender;
        
        ICOSupply = ICOSupply.sub(_value);
        
        totalSupply = totalSupply.sub(_value);
        
        emit Burn(burner, _value);
        
     }
    
    function DskToOwner() public onlyOwner afterDeadline nonReentrant {
        
        
        address RequestAddress = msg.sender;
        
        Inverstors[RequestAddress].DskTokenAmount =  Inverstors[RequestAddress].DskTokenAmount.add(ICOSupply);
        
        ICOSupply = ICOSupply.sub(ICOSupply);
    }
    

     
     
    function DskTokenToInvestors() public onlyOwner afterDeadline nonReentrant {
        
        require(SoftCapReached);

        for(uint256 i=1; i<InvestorNum; i++) {
                
            uint256 ReleaseTime = Inverstors[InverstorList[i]].LockupTime;
            
            address InverstorAddress = InverstorList[i];
            
            uint256 Amount = Inverstors[InverstorAddress].DskTokenAmount;
               
                
            if(now>ReleaseTime && Amount>0) {
                    
                balances[InverstorAddress] = balances[InverstorAddress] + Amount;
                    
                Inverstors[InverstorAddress].DskTokenAmount = Inverstors[InverstorAddress].DskTokenAmount.sub(Amount);
                    
                Inverstors[InverstorAddress].DskTokenWithdraw = true;
                
                emit dskTokenToInvestors(InverstorAddress, Amount, now);
                
            } else {
                
                emit FaildskTokenToInvestors(InverstorAddress, Amount, now, ReleaseTime);
                
                
            }
                
        }
  
    }
  
     
  
    function DskTokenToCore() public onlyOwner afterDeadline nonReentrant {
        
        require(SoftCapReached);

        for(uint256 i=0; i<1; i++) {
                
            uint256 ReleaseTime = Inverstors[InverstorList[i]].LockupTime;
            
            address CoreAddress = InverstorList[i];
            
            uint256 Amount = Inverstors[CoreAddress].DskTokenAmount;
            
                
            if(now>ReleaseTime && Amount>0) {
                    
                balances[CoreAddress] = balances[CoreAddress] + Amount;
                    
                Inverstors[CoreAddress].DskTokenAmount = Inverstors[CoreAddress].DskTokenAmount.sub(Amount);
                
                Inverstors[CoreAddress].DskTokenWithdraw = true;
                    
                emit dskTokenToCore(CoreAddress, Amount, now);
                
            } else {
                
                emit FaildskTokenToCore(CoreAddress, Amount, now, ReleaseTime);
                
                
            }
                
        }
  
    }
  
}