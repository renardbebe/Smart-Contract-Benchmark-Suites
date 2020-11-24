 

pragma solidity ^0.4.24;    
 
library     SafeMath
{
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0)     return 0;
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a/b;
    }
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
 
contract    ERC20 
{
    using SafeMath  for uint256;

     

    address public              owner;           
    address public              admin;           

    mapping(address => uint256)                         balances;        
    mapping(address => mapping (address => uint256))    allowances;      

     

    string  public  constant    name     = "Reger Diamond Security Token";
    string  public  constant    symbol   = "RDST";

    uint256 public  constant    decimals = 18;
    
    uint256 public  constant    initSupply       = 60000000 * 10**decimals;         
    uint256 public  constant    supplyReserveVal = 37500000 * 10**decimals;           

     

    uint256 public              totalSupply;
    uint256 public              icoSalesSupply   = 0;                    
    uint256 public              icoReserveSupply = 0;
    uint256 public              softCap =  5000000   * 10**decimals;
    uint256 public              hardCap = 21500000   * 10**decimals;

     

    uint256 public              icoDeadLine = 1533513600;      

    bool    public              isIcoPaused            = false; 
    bool    public              isStoppingIcoOnHardCap = true;

     

    modifier duringIcoOnlyTheOwner()   
    { 
        require( now>icoDeadLine || msg.sender==owner );
        _;
    }

    modifier icoFinished()          { require(now > icoDeadLine);           _; }
    modifier icoNotFinished()       { require(now <= icoDeadLine);          _; }
    modifier icoNotPaused()         { require(isIcoPaused==false);          _; }
    modifier icoPaused()            { require(isIcoPaused==true);           _; }
    modifier onlyOwner()            { require(msg.sender==owner);           _; }
    modifier onlyAdmin()            { require(msg.sender==admin);           _; }

     

    event Transfer(address indexed fromAddr, address indexed toAddr,   uint256 amount);
    event Approval(address indexed _owner,   address indexed _spender, uint256 amount);

             

    event onAdminUserChanged(   address oldAdmin,       address newAdmin);
    event onOwnershipTransfered(address oldOwner,       address newOwner);
    event onIcoDeadlineChanged( uint256 oldIcoDeadLine, uint256 newIcoDeadline);
    event onHardcapChanged(     uint256 hardCap,        uint256 newHardCap);
    event icoIsNowPaused(       uint8 newPauseStatus);
    event icoHasRestarted(      uint8 newPauseStatus);

    event log(string key, string value);
    event log(string key, uint   value);

     
     
    constructor()   public 
    {
        owner       = msg.sender;
        admin       = owner;

        isIcoPaused = false;
        
         

        balances[owner] = initSupply;    
        totalSupply     = initSupply;
        icoSalesSupply  = totalSupply;   

         

        icoSalesSupply   = totalSupply.sub(supplyReserveVal);
        icoReserveSupply = totalSupply.sub(icoSalesSupply);
    }
     
     
     
     
     
    function balanceOf(address walletAddress) public constant returns (uint256 balance) 
    {
        return balances[walletAddress];
    }
     
    function transfer(address toAddr, uint256 amountInWei)  public   duringIcoOnlyTheOwner   returns (bool)      
    {
        require(toAddr!=0x0 && toAddr!=msg.sender && amountInWei>0);      

        uint256 availableTokens = balances[msg.sender];

         

        if (msg.sender==owner && now <= icoDeadLine)                     
        {
            assert(amountInWei<=availableTokens);

            uint256 balanceAfterTransfer = availableTokens.sub(amountInWei);      

            assert(balanceAfterTransfer >= icoReserveSupply);            
        }

         

        balances[msg.sender] = balances[msg.sender].sub(amountInWei);
        balances[toAddr]     = balances[toAddr].add(amountInWei);

        emit Transfer(msg.sender, toAddr, amountInWei);

        return true;
    }
     
    function allowance(address walletAddress, address spender) public constant returns (uint remaining)
    {
        return allowances[walletAddress][spender];
    }
     
    function transferFrom(address fromAddr, address toAddr, uint256 amountInWei)  public  returns (bool) 
    {
        if (amountInWei <= 0)                                   return false;
        if (allowances[fromAddr][msg.sender] < amountInWei)     return false;
        if (balances[fromAddr] < amountInWei)                   return false;

        balances[fromAddr]               = balances[fromAddr].sub(amountInWei);
        balances[toAddr]                 = balances[toAddr].add(amountInWei);
        allowances[fromAddr][msg.sender] = allowances[fromAddr][msg.sender].sub(amountInWei);

        emit Transfer(fromAddr, toAddr, amountInWei);
        return true;
    }
     
    function approve(address spender, uint256 amountInWei) public returns (bool) 
    {
        require((amountInWei == 0) || (allowances[msg.sender][spender] == 0));
        allowances[msg.sender][spender] = amountInWei;
        emit Approval(msg.sender, spender, amountInWei);

        return true;
    }
     
    function() public                       
    {
        assert(true == false);       
    }
     
     
     
    function transferOwnership(address newOwner) public onlyOwner                
    {
        require(newOwner != address(0));

        emit onOwnershipTransfered(owner, newOwner);
        owner = newOwner;
    }
     
     
     
     
    function    changeAdminUser(address newAdminAddress) public onlyOwner
    {
        require(newAdminAddress!=0x0);

        emit onAdminUserChanged(admin, newAdminAddress);
        admin = newAdminAddress;
    }
     
     
    function    changeIcoDeadLine(uint256 newIcoDeadline) public onlyAdmin
    {
        require(newIcoDeadline!=0);

        emit onIcoDeadlineChanged(icoDeadLine, newIcoDeadline);
        icoDeadLine = newIcoDeadline;
    }
     
     
     
    function    changeHardCap(uint256 newHardCap) public onlyAdmin
    {
        require(newHardCap!=0);

        emit onHardcapChanged(hardCap, newHardCap);
        hardCap = newHardCap;
    }
     
    function    isHardcapReached()  public view returns(bool)
    {
        return (isStoppingIcoOnHardCap && initSupply-balances[owner] > hardCap);
    }
     
     
     
    function    pauseICO()  public onlyAdmin
    {
        isIcoPaused = true;
        emit icoIsNowPaused(1);
    }
     
    function    unpauseICO()  public onlyAdmin
    {
        isIcoPaused = false;
        emit icoHasRestarted(0);
    }
     
    function    isPausedICO() public view     returns(bool)
    {
        return (isIcoPaused) ? true : false;
    }
}
 
contract    DateTime 
{
    struct TDateTime 
    {
        uint16 year;    uint8 month;    uint8 day;
        uint8 hour;     uint8 minute;   uint8 second;
        uint8 weekday;
    }
    uint8[] totalDays = [ 0,   31,28,31,30,31,30,  31,31,30,31,30,31];
    uint constant DAY_IN_SECONDS       = 86400;
    uint constant YEAR_IN_SECONDS      = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;
    uint constant HOUR_IN_SECONDS      = 3600;
    uint constant MINUTE_IN_SECONDS    = 60;
    uint16 constant ORIGIN_YEAR        = 1970;
     
    function isLeapYear(uint16 year) public pure returns (bool) 
    {
        if ((year %   4)!=0)    return false;
        if ( year % 100 !=0)    return true;
        if ( year % 400 !=0)    return false;
        return true;
    }
     
    function leapYearsBefore(uint year) public pure returns (uint) 
    {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }
     
    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) 
    {
        uint8   nDay = 30;
             if (month==1)          nDay++;
        else if (month==3)          nDay++;
        else if (month==5)          nDay++;
        else if (month==7)          nDay++;
        else if (month==8)          nDay++;
        else if (month==10)         nDay++;
        else if (month==12)         nDay++;
        else if (month==2) 
        {
                                    nDay = 28;
            if (isLeapYear(year))   nDay++;
        }
        return nDay;
    }
     
    function parseTimestamp(uint timestamp) internal pure returns (TDateTime dt) 
    {
        uint  secondsAccountedFor = 0;
        uint  buf;
        uint8 i;
        uint  secondsInMonth;
        dt.year = getYear(timestamp);
        buf     = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);
        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS   * (dt.year - ORIGIN_YEAR - buf);
        for (i = 1; i <= 12; i++) 
        {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) 
            {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }
        for (i=1; i<=getDaysInMonth(dt.month, dt.year); i++) 
        {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) 
            {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }
        dt.hour    = getHour(timestamp);
        dt.minute  = getMinute(timestamp);
        dt.second  = getSecond(timestamp);
        dt.weekday = getWeekday(timestamp);
    }
     
    function getYear(uint timestamp) public pure returns (uint16) 
    {
        uint secondsAccountedFor = 0;
        uint16 year;
        uint numLeapYears;
        year         = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);
        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);
        while (secondsAccountedFor > timestamp) 
        {
            if (isLeapYear(uint16(year - 1)))   secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            else                                secondsAccountedFor -= YEAR_IN_SECONDS;
            year -= 1;
        }
        return year;
    }
     
    function getMonth(uint timestamp) public pure returns (uint8) 
    {
        return parseTimestamp(timestamp).month;
    }
     
    function getDay(uint timestamp) public pure returns (uint8) 
    {
        return parseTimestamp(timestamp).day;
    }
     
    function getHour(uint timestamp) public pure returns (uint8) 
    {
        return uint8(((timestamp % 86400) / 3600) % 24);
    }
     
    function getMinute(uint timestamp) public pure returns (uint8) 
    {
        return uint8((timestamp % 3600) / 60);
    }
     
    function getSecond(uint timestamp) public pure returns (uint8) 
    {
        return uint8(timestamp % 60);
    }
     
    function getWeekday(uint timestamp) public pure returns (uint8) 
    {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }
     
    function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) 
    {
        return toTimestamp(year, month, day, 0, 0, 0);
    }
     
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) 
    {
        return toTimestamp(year, month, day, hour, 0, 0);
    }
     
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) 
    {
        return toTimestamp(year, month, day, hour, minute, 0);
    }
     
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) 
    {
        uint16 i;
        for (i = ORIGIN_YEAR; i < year; i++) 
        {
            if (isLeapYear(i))  timestamp += LEAP_YEAR_IN_SECONDS;
            else                timestamp += YEAR_IN_SECONDS;
        }
        uint8[12] memory monthDayCounts;
        monthDayCounts[0]  = 31;
        monthDayCounts[1]  = 28;     if (isLeapYear(year))   monthDayCounts[1] = 29;
        monthDayCounts[2]  = 31;
        monthDayCounts[3]  = 30;
        monthDayCounts[4]  = 31;
        monthDayCounts[5]  = 30;
        monthDayCounts[6]  = 31;
        monthDayCounts[7]  = 31;
        monthDayCounts[8]  = 30;
        monthDayCounts[9]  = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;
        for (i=1; i<month; i++) 
        {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }
        timestamp += DAY_IN_SECONDS    * (day - 1);
        timestamp += HOUR_IN_SECONDS   * (hour);
        timestamp += MINUTE_IN_SECONDS * (minute);
        timestamp += second;
        return timestamp;
    }
     
    function getYearDay(uint timestamp) public pure returns (uint16)
    {
        TDateTime memory date = parseTimestamp(timestamp);
        uint16 dayCount=0;
        for (uint8 iMonth=1; iMonth<date.month; iMonth++)
        {
            dayCount += getDaysInMonth(iMonth, date.year);
        }
        dayCount += date.day;   
        return dayCount;         
    }
     
    function getDaysInYear(uint16 year) public pure returns (uint16)
    {
        return (isLeapYear(year)) ? 366:365;
    }
     
    function    dateToTimestamp(uint16 iYear, uint8 iMonth, uint8 iDay) public pure returns(uint)
    {
        uint8 monthDayCount = 30;
        if (iMonth==2)
        {
                                    monthDayCount = 28;
            if (isLeapYear(iYear))  monthDayCount++;
        }
        if (iMonth==4 || iMonth==6 || iMonth==9 || iMonth==11)
        {
            monthDayCount = 31;
        }
        if (iDay<1)           
        {
            iDay = 1;
        }
        else if (iDay>monthDayCount)     
        {
            iDay = 1;        
            iMonth++;
            if (iMonth>12)  
            {
                iMonth=1;
                iYear++;
            }
        }
        return toTimestamp(iYear, iMonth, iDay);
    }
     
}
 
contract    CompoundContract  is  ERC20, DateTime
{
    using SafeMath  for uint256;

        bool private    isLiveTerm = true;

    struct TCompoundItem
    {
        uint        id;                          
        uint        plan;                        
        address     investor;                    
        uint        tokenCapitalInWei;           
        uint        tokenEarningsInWei;          
        uint        earningPerTermInWei;         
        uint        currentlyEarnedInWei;        
        uint        tokenEarnedInWei;            
        uint        overallTokensInWei;          
        uint        contractMonthCount;          
        uint        startTimestamp;
        uint        endTimestamp;                
        uint        interestRate;
        uint        percent;
        bool        isAllPaid;                   
        uint8       termPaidCount;               
        uint8       termCount;                   
        bool        isContractValidated;         
        bool        isCancelled;                 
    }

    mapping(address => uint256)                 lockedCapitals;      
    mapping(address => uint256)                 lockedEarnings;      

    mapping(uint256 => bool)         private    activeContractStatues;       
    mapping(uint => TCompoundItem)   private    contracts;
    mapping(uint256 => uint32[12])   private    compoundPayTimes;    
    mapping(uint256 => uint8[12])    private    compoundPayStatus;           

    event onCompoundContractCompleted(address investor, uint256 compoundId, 
                                                        uint256 capital, 
                                                        uint256 earnedAmount, 
                                                        uint256 total, 
                                                        uint256 timestamp);

    event onCompoundEarnings(address investor,  uint256 compoundId, 
                                                uint256 capital, 
                                                uint256 earnedAmount, 
                                                uint256 earnedSoFarAmount, 
                                                uint32  timestamp,
                                                uint8   paidTermCount,
                                                uint8   totalTermCount);

    event onCompoundContractLocked(address fromAddr, address toAddr, uint256 amountToLockInWei);
    event onPayEarningsDone(uint contractId, uint nPaid, uint paymentCount, uint paidAmountInWei);

    event onCompoundContractCancelled(uint contractId, uint lockedCapital, uint lockedEarnings);
    event onCompoundContractValidated(uint contractId);

     
    function    initCompoundContract(address buyerAddress, uint256 amountInWei, uint256 compoundContractId, uint monthCount)  internal onlyOwner  returns(bool)
    {
        TCompoundItem memory    item;
        uint                    overallTokensInWei; 
        uint                    tokenEarningsInWei;
        uint                    earningPerTermInWei; 
        uint                    percentToUse; 
        uint                    interestRate;
        uint                    i;

        if (activeContractStatues[compoundContractId])
        {
            return false;        
        }

        activeContractStatues[compoundContractId] = true;

         

        (overallTokensInWei, 
         tokenEarningsInWei,
         earningPerTermInWei, 
         percentToUse, 
         interestRate,
         i) = calculateCompoundContract(amountInWei, monthCount);

        item.plan = i;                   

         

        if (percentToUse==0)         
        {
            return false;
        }

         

        generateCompoundTerms(compoundContractId);

         

        item.id                   = compoundContractId;
        item.startTimestamp       = now;

        item.contractMonthCount   = monthCount;
        item.interestRate         = interestRate;
        item.percent              = percentToUse;
        item.investor             = buyerAddress;
        item.isAllPaid            = false;
        item.termCount            = uint8(monthCount/3);
        item.termPaidCount        = 0;

        item.tokenCapitalInWei    = amountInWei;
        item.currentlyEarnedInWei = 0;
        item.overallTokensInWei   = overallTokensInWei;
        item.tokenEarningsInWei   = tokenEarningsInWei;
        item.earningPerTermInWei  = earningPerTermInWei;

        item.isCancelled          = false;
        item.isContractValidated  = false;                       

         

        contracts[compoundContractId] = item;

        return true;
    }
     
    function    generateCompoundTerms(uint256 compoundContractId)    private
    {
        uint16 iYear  =  getYear(now);
        uint8  iMonth = getMonth(now);
        uint   i;

        if (isLiveTerm)
        {
            for (i=0; i<8; i++)              
            {
                iMonth += 3;         
                if (iMonth>12)
                {
                    iYear++;
                    iMonth -= 12;
                }

                compoundPayTimes[compoundContractId][i]  = uint32(dateToTimestamp(iYear, iMonth, getDay(now)));
                compoundPayStatus[compoundContractId][i] = 0;      
            }
        }
        else
        {
            uint timeSum=now;
            for (i=0; i<8; i++)              
            {
                            uint duration = 4*60;     
                if (i>0)         duration = 2*60;

                timeSum += duration;

                compoundPayTimes[compoundContractId][i]  = uint32(timeSum);      
                compoundPayStatus[compoundContractId][i] = 0;      
            }
        }
    }
     
    function    calculateCompoundContract(uint256 capitalInWei, uint contractMonthCount)   public  constant returns(uint, uint, uint, uint, uint, uint)     
    {
         

        uint    plan          = 0;
        uint256 interestRate  = 0;
        uint256 percentToUse  = 0;

        if (contractMonthCount==12)
        {
                 if (capitalInWei<  1000 * 10**18)      { percentToUse=12;  interestRate=1125509;   plan=1; }    
            else if (capitalInWei< 10000 * 10**18)      { percentToUse=15;  interestRate=1158650;   plan=2; }    
            else if (capitalInWei<100000 * 10**18)      { percentToUse=17;  interestRate=1181148;   plan=3; }    
            else                                        { percentToUse=20;  interestRate=1215506;   plan=4; }    
        }
        else if (contractMonthCount==24)
        {
                 if (capitalInWei<  1000 * 10**18)      { percentToUse=15;  interestRate=1342471;   plan=1; }
            else if (capitalInWei< 10000 * 10**18)      { percentToUse=17;  interestRate=1395110;   plan=2; }
            else if (capitalInWei<100000 * 10**18)      { percentToUse=20;  interestRate=1477455;   plan=3; }
            else                                        { percentToUse=30;  interestRate=1783478;   plan=4; }
        }
        else
        {
            return (0,0,0,0,0,0);                    
        }

        uint256 overallTokensInWei  = (capitalInWei *  interestRate         ) / 1000000;
        uint256 tokenEarningsInWei  = overallTokensInWei - capitalInWei;
        uint256 earningPerTermInWei = tokenEarningsInWei / (contractMonthCount/3);       

        return (overallTokensInWei,tokenEarningsInWei,earningPerTermInWei, percentToUse, interestRate, plan);
    }
     
    function    lockMoneyOnCompoundCreation(address toAddr, uint compountContractId)  internal  onlyOwner   returns (bool) 
    {
        require(toAddr!=0x0 && toAddr!=msg.sender);      

        if (isHardcapReached())                                         
        {
            return false;        
        }

        TCompoundItem memory item = contracts[compountContractId];

        if (item.tokenCapitalInWei==0 || item.tokenEarningsInWei==0)    
        {
            return false;        
        }

         

        uint256 amountToLockInWei = item.tokenCapitalInWei + item.tokenEarningsInWei;
        uint256 availableTokens   = balances[owner];

        if (amountToLockInWei <= availableTokens)
        {
            uint256 balanceAfterTransfer = availableTokens.sub(amountToLockInWei);      

            if (balanceAfterTransfer >= icoReserveSupply)        
            {
                lockMoney(toAddr, item.tokenCapitalInWei, item.tokenEarningsInWei);
                return true;
            }
        }

         
        return false;
    }
     
    function    payCompoundTerm(uint contractId, uint8 termId, uint8 isCalledFromOutside)   public onlyOwner returns(int32)         
    {
        uint                    id;
        address                 investor;
        uint                    paidAmount;
        TCompoundItem   memory  item;

        if (!activeContractStatues[contractId])         
        {
            emit log("payCompoundTerm", "Specified contract is not actived (-1)");
            return -1;
        }

        item = contracts[contractId];

         
        if (item.isCancelled)    
        {
            emit log("payCompoundTerm", "Compound contract already cancelled (-2)");
            return -2;
        }

         

        if (item.isAllPaid)                             
        {
            emit log("payCompoundTerm", "All earnings already paid for this contract (-2)");
            return -4;    
        }

        id = item.id;

        if (compoundPayStatus[id][termId]!=0)           
        {
            emit log("payCompoundTerm", "Specified contract's term was already paid (-5)");
            return -5;
        }

        if (now < compoundPayTimes[id][termId])         
        {
            emit log("payCompoundTerm", "It's too early to pay this term (-6)");
            return -6;
        }

        investor = item.investor;                                    

         
         

        if (!item.isContractValidated)                           
        {
            uint    capital  = item.tokenCapitalInWei;
            uint    earnings = item.tokenEarningsInWei;

            contracts[contractId].isCancelled        = true;
            contracts[contractId].tokenCapitalInWei  = 0;        
            contracts[contractId].tokenEarningsInWei = 0;        

             

            lockedCapitals[investor] = lockedCapitals[investor].sub(capital);
            lockedEarnings[investor] = lockedEarnings[investor].sub(earnings);

            balances[owner] = balances[owner].add(capital);
            balances[owner] = balances[owner].add(earnings);

            emit onCompoundContractCancelled(contractId, capital, earnings);
            emit log("payCompoundTerm", "Cancelling compound contract (-3)");
            return -3;
        }

         

        contracts[id].termPaidCount++;
        contracts[id].currentlyEarnedInWei += item.earningPerTermInWei;  

        compoundPayStatus[id][termId] = 1;                           

        unlockEarnings(investor, item.earningPerTermInWei);

        paidAmount = item.earningPerTermInWei;

        if (contracts[id].termPaidCount>=item.termCount && !contracts[item.id].isAllPaid)    
        {
            contracts[id].isAllPaid = true;

            unlockCapital(investor, item.tokenCapitalInWei);

            paidAmount += item.tokenCapitalInWei;
        }

         

        if (isCalledFromOutside==0 && paidAmount>0)
        {
            emit Transfer(owner, investor, paidAmount);
        }

        return 1;        
                         
    }
     
    function    validateCompoundContract(uint contractId) public onlyOwner   returns(uint)
    {
        TCompoundItem memory  item = contracts[contractId];

        if (item.isCancelled==true)
        {
            return 2;        
        }

        contracts[contractId].isCancelled         = false;
        contracts[contractId].isContractValidated = true;

        emit onCompoundContractValidated(contractId);

        return 1;
    }
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function    lockMoney(address investor, uint capitalAmountInWei, uint totalEarningsToReceiveInWei) internal onlyOwner
    {
        uint totalAmountToLockInWei = capitalAmountInWei + totalEarningsToReceiveInWei;

        if (totalAmountToLockInWei <= balances[owner])
        {
            balances[owner] = balances[owner].sub(capitalAmountInWei.add(totalEarningsToReceiveInWei));      

            lockedCapitals[investor] = lockedCapitals[investor].add(capitalAmountInWei);             
            lockedEarnings[investor] = lockedEarnings[investor].add(totalEarningsToReceiveInWei);    

            emit Transfer(owner, investor, capitalAmountInWei);     
        }                                                             
    }
     
    function    unlockCapital(address investor, uint amountToUnlockInWei) internal onlyOwner
    {
        if (amountToUnlockInWei <= lockedCapitals[investor])
        {
            balances[investor]       = balances[investor].add(amountToUnlockInWei);
            lockedCapitals[investor] = lockedCapitals[investor].sub(amountToUnlockInWei);     

             
        }
    }
     
    function    unlockEarnings(address investor, uint amountToUnlockInWei) internal onlyOwner
    {
        if (amountToUnlockInWei <= lockedEarnings[investor])
        {
            balances[investor]       = balances[investor].add(amountToUnlockInWei);
            lockedEarnings[investor] = lockedEarnings[investor].sub(amountToUnlockInWei);     

             
        }
    }
     
    function    lockedCapitalOf(address investor) public  constant  returns(uint256)
    {
        return lockedCapitals[investor];
    }
     
    function    lockedEarningsOf(address investor) public  constant  returns(uint256)
    {
        return lockedEarnings[investor];
    }  
     
    function    lockedBalanceOf(address investor) public  constant  returns(uint256)
    {
        return lockedCapitals[investor] + lockedEarnings[investor];
    }
     
    function    geCompoundTimestampsFor12Months(uint contractId) public view  returns(uint256,uint256,uint256,uint256)
    {
        uint32[12] memory t = compoundPayTimes[contractId];

        return(uint256(t[0]),uint256(t[1]),uint256(t[2]),uint256(t[3]));
    }
     
    function    geCompoundTimestampsFor24Months(uint contractId) public view  returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)
    {
        uint32[12] memory t = compoundPayTimes[contractId];

        return(uint256(t[0]),uint256(t[1]),uint256(t[2]),uint256(t[3]),uint256(t[4]),uint256(t[5]),uint256(t[6]),uint256(t[7]));
    }
     
    function    getCompoundContract(uint contractId) public constant    returns(address investor, 
                                                                        uint capital, 
                                                                        uint profitToGenerate,
                                                                        uint earnedSoFarAmount, 
                                                                        uint percent,
                                                                        uint interestRate,
                                                                        uint paidTermCount,
                                                                        uint isAllPaid,
                                                                        uint monthCount,
                                                                        uint earningPerTerm,
                                                                        uint isCancelled)
    {
        TCompoundItem memory item;

        item = contracts[contractId];

        return
        (
            item.investor,
            item.tokenCapitalInWei,
            item.tokenEarningsInWei,
            item.currentlyEarnedInWei,
            item.percent,
            item.interestRate,
            uint(item.termPaidCount),
            (item.isAllPaid) ? 1:0,
            item.contractMonthCount,
            item.earningPerTermInWei,
            (item.isCancelled) ? 1:0
        );
    }
     
    function    getCompoundPlan(uint contractId) public constant  returns(uint plan)
    {
        return contracts[contractId].plan;
    }
}
 
contract    Token  is  CompoundContract
{
    using SafeMath  for uint256;

     
     
     
     
     
     
     
    function transfer(address toAddr, uint256 amountInWei)  public      returns (bool)      
    {
        require(toAddr!=0x0 && toAddr!=msg.sender && amountInWei>0);     

        uint256 availableTokens = balances[msg.sender];

         

        if (msg.sender==owner && !isHardcapReached())               
        {
            assert(amountInWei<=availableTokens);

            uint256 balanceAfterTransfer = availableTokens.sub(amountInWei);      

            assert(balanceAfterTransfer >= icoReserveSupply);            
        }

         

        balances[msg.sender] = balances[msg.sender].sub(amountInWei);
        balances[toAddr]     = balances[toAddr].add(amountInWei);

        emit Transfer(msg.sender, toAddr, amountInWei);

        return true;
    }
     
     
     
     
     
    function    investFor12Months(address buyerAddress, uint256  amountInWei,
                                                          uint256  compoundContractId)
                                                public onlyOwner  
                                                returns(int)
    {

        uint    monthCount=12;

        if (!isHardcapReached())
        {
            if (initCompoundContract(buyerAddress, amountInWei, compoundContractId, monthCount))
            {
                if (!lockMoneyOnCompoundCreation(buyerAddress, compoundContractId))       
                {
                    return -1;
                }
            }
            else 
            {
                return -2; 
            }
        }
        else         
        {
            Token.transfer(buyerAddress, amountInWei);
            return 2;
        }

        return 1;        
                         
                         
                         
    }
     
    function    investFor24Months(address buyerAddress, uint256  amountInWei,
                                                        uint256  compoundContractId)
                                                public onlyOwner 
                                                returns(int)
    {

        uint    monthCount=24;

        if (!isHardcapReached())
        {
            if (initCompoundContract(buyerAddress, amountInWei, compoundContractId, monthCount))
            {
                if (!lockMoneyOnCompoundCreation(buyerAddress, compoundContractId))     
                {
                    return -1; 
                }
            }
            else { return -2; }
        }
        else         
        {
            Token.transfer(buyerAddress, amountInWei);
            return 2;
        }

        return 1;        
                         
                         
                         
    }
     
     
     
     
}