 

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


contract LinTokenMint is ERC223Token {
    
    string public constant name = "LinToken";    
    string public constant symbol = "LIN";   
    uint256 public constant decimals = 18;   
    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));     
    uint256 public totalSupply = INITIAL_SUPPLY;     
    uint256 internal Percent = INITIAL_SUPPLY.div(100);  
    
    uint256 public ICOSupply = Percent.mul(50);  
    uint256 internal LinNetOperationSupply = Percent.mul(30);    
    uint256 internal LinTeamSupply = Percent.mul(10);    
    uint256 internal SympoSiumSupply = Percent.mul(5);   
    uint256 internal BountySupply = Percent.mul(5).div(2);   
    uint256 internal preICOSupply = Percent.mul(5).div(2);   
    
    address internal LinNetOperation = 0x48a240d2aB56FE372e9867F19C7Ba33F60cB32fc;   
    address internal LinTeam = 0xF55f80d09e551c35735ed4af107f6d361a7eD623;   
    address internal SympoSium = 0x5761DB2F09A0DF0b03A885C61E618CFB4Da7492D;     
    address internal Bounty = 0x76e1173022e0fD87D15AA90270828b1a6a54Eac1;    
    address internal preICO = 0x2bfdf8B830DAaf54d0b538aF1E62A192Bf291B5d;    

    event InitSupply(uint256 owner, uint256 LinNetOperation, uint256 LinTeam, uint256 SympoSium, uint256 Bounty, uint256 preICO);
    
      
    
    constructor() public {
       
        emit InitSupply(ICOSupply, LinNetOperationSupply, LinTeamSupply, SympoSiumSupply, BountySupply, preICOSupply);
        
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


 
 
contract LinCrowdSale is LinTokenMint, WhitelistedCrowdsale {
    
     
   
    uint constant Month = 60*60*24*30;
    uint constant SixMonth = 6 * Month;
    uint constant Year = 12 * Month;
    
     
    
    uint public StartTime = now;
    uint public EndTime = StartTime + SixMonth;

     

    uint public PrivateSaleEndTime = StartTime.add(Month);
    uint public PreSaleEndTime = PrivateSaleEndTime.add(Month);
    
      
    
    bool public SoftCapReached = false;
    bool public HardCapReached = false;
    bool public SaleClosed = false;
    
    bool private rentrancy_lock = false;  
    
    uint public constant Private_rate = 2000;  
    uint public constant Pre_rate = 1500;  
    uint public constant Public = 1200;  
    

    uint public MinInvestMent = 2 * (10 ** decimals);  
    uint public HardCap = 500000000 * (10 ** decimals);   
    uint public SoftCap =  10000000 * (10 ** decimals);  
    
     
     
    uint public TotalAmountETH;
    uint public SaleAmountLIN;
    uint public RefundAmount;
    
    uint public InvestorNum;     
    
    
     
     
    event SuccessCoreAccount(uint256 InvestorNum);
    event Burn(address burner, uint256 value);
    event SuccessInvestor(address RequestAddress, uint256 amount);
    event SuccessSoftCap(uint256 SaleAmountLin, uint256 time);
    event SuccessHardCap(uint256 SaleAmountLin, uint256 time);
    event SucessWithdraw(address who, uint256 AmountEth, uint256 time);
    event SuccessEthToOwner(address owner, uint256 AmountEth, uint256 time);
    
    event linTokenToInvestors(address InverstorAddress, uint256 Amount, uint256 now);
    event linTokenToCore(address CoreAddress, uint256 Amount, uint256 now);
    event FailsafeWithdrawal(address InverstorAddress, uint256 Amount, uint256 now);
    event FaillinTokenToInvestors(address InverstorAddress, uint256 Amount, uint256 now, uint256 ReleaseTime);
    event FaillinTokenToCore(address CoreAddress, uint256 Amount, uint256 now, uint256 ReleaseTime);
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
    	uint256 LinTokenAmount;
    	uint256 LockupTime;
    	bool    LinTokenWithdraw;
    	
    }
    
    
    mapping (address => Investor) public Inverstors;     
    mapping (uint256 => address) public InverstorList;   
    
    
    constructor() public {
        
         
     
        Inverstors[LinNetOperation].EthAmount = 0;
        Inverstors[LinNetOperation].LockupTime = Year;
        Inverstors[LinNetOperation].LinTokenAmount = LinNetOperationSupply;
        Inverstors[LinNetOperation].LinTokenWithdraw = false; 
        InverstorList[InvestorNum] = LinNetOperation;
        InvestorNum++;
        
        Inverstors[LinTeam].EthAmount = 0;
        Inverstors[LinTeam].LockupTime = Year;
        Inverstors[LinTeam].LinTokenAmount = LinTeamSupply;
        Inverstors[LinTeam].LinTokenWithdraw = false; 
        InverstorList[InvestorNum] = LinTeam;
        InvestorNum++;
        
        Inverstors[SympoSium].EthAmount = 0;
        Inverstors[SympoSium].LockupTime = Year;
        Inverstors[SympoSium].LinTokenAmount = SympoSiumSupply;
        Inverstors[SympoSium].LinTokenWithdraw = false; 
        InverstorList[InvestorNum] = SympoSium;
        InvestorNum++;
        
        Inverstors[Bounty].EthAmount = 0;
        Inverstors[Bounty].LockupTime = Month.mul(4);
        Inverstors[Bounty].LinTokenAmount = BountySupply;
        Inverstors[Bounty].LinTokenWithdraw = false; 
        InverstorList[InvestorNum] = Bounty;
        InvestorNum++;
        
        Inverstors[preICO].EthAmount = 0;
        Inverstors[preICO].LockupTime = Year;
        Inverstors[preICO].LinTokenAmount = preICOSupply;
        Inverstors[preICO].LinTokenWithdraw = false; 
        InverstorList[InvestorNum] = preICO;
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

        Inverstors[RequestAddress].LockupTime = StartTime.add(SixMonth);  
        
        Inverstors[RequestAddress].LinTokenWithdraw = false;     
        
        TotalAmountETH = TotalAmountETH.add(amount);  
        
       
         
       
        if(CurrentTime<PrivateSaleEndTime) {
            
            rate = Private_rate;
            
        } else if(CurrentTime<PreSaleEndTime) {
            
            rate = Pre_rate;
            
        } else {
            
            rate = Public;
            
        }


        uint NumLinToken = amount.mul(rate);     
        
        ICOSupply = ICOSupply.sub(NumLinToken);  
        
        
        if(ICOSupply > 0) {     
        
         
        Inverstors[RequestAddress].LinTokenAmount =  Inverstors[RequestAddress].LinTokenAmount.add(NumLinToken);
        
        SaleAmountLIN = SaleAmountLIN.add(NumLinToken);  
        
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

            if (SaleAmountLIN >= HardCap) {

                HardCapReached = true;

                SaleClosed = true;
                
                emit SuccessSoftCap(SaleAmountLIN, now);

            }
        }
    }   
    
     
     
    function CheckSoftCap() internal {

        if (!SoftCapReached) {

            if (SaleAmountLIN >= SoftCap) {

                SoftCapReached = true;
                
                emit SuccessHardCap(SaleAmountLIN, now);

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
                
                revert(); 
                
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
     
     
     
    function LinTokenToInvestors() public onlyOwner afterDeadline nonReentrant {
        
        require(SoftCapReached);

        for(uint256 i=5; i<InvestorNum; i++) {
                
            uint256 ReleaseTime = Inverstors[InverstorList[i]].LockupTime;
            
            address InverstorAddress = InverstorList[i];
            
            uint256 Amount = Inverstors[InverstorAddress].LinTokenAmount;
               
                
            if(now>ReleaseTime && Amount>0) {
                    
                balances[InverstorAddress] = Amount;
                    
                Inverstors[InverstorAddress].LinTokenAmount = Inverstors[InverstorAddress].LinTokenAmount.sub(Amount);
                    
                Inverstors[InverstorAddress].LinTokenWithdraw = true;
                
                emit linTokenToInvestors(InverstorAddress, Amount, now);
                
            } else {
                
                emit FaillinTokenToInvestors(InverstorAddress, Amount, now, ReleaseTime);
                
                revert();
            }
                
        }
  
    }
  
     
  
    function LinTokenToCore() public onlyOwner afterDeadline nonReentrant {
        
        require(SoftCapReached);

        for(uint256 i=0; i<5; i++) {
                
            uint256 ReleaseTime = Inverstors[InverstorList[i]].LockupTime;
            
            address CoreAddress = InverstorList[i];
            
            uint256 Amount = Inverstors[CoreAddress].LinTokenAmount;
            
                
            if(now>ReleaseTime && Amount>0) {
                    
                balances[CoreAddress] = Amount;
                    
                Inverstors[CoreAddress].LinTokenAmount = Inverstors[CoreAddress].LinTokenAmount.sub(Amount);
                
                Inverstors[CoreAddress].LinTokenWithdraw = true;
                    
                emit linTokenToCore(CoreAddress, Amount, now);
                
            } else {
                
                emit FaillinTokenToCore(CoreAddress, Amount, now, ReleaseTime);
                
                revert();
            }
                
        }
  
    }
  
}