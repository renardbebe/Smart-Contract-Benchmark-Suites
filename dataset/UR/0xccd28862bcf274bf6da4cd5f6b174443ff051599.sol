 

pragma solidity 0.4.25;


  


library Zero {
    function requireNotZero(address addr) internal pure {
        require(addr != address(0), "require not zero address");
    }

    function requireNotZero(uint val) internal pure {
        require(val != 0, "require not zero value");
    }

    function notZero(address addr) internal pure returns(bool) {
        return !(addr == address(0));
    }

    function isZero(address addr) internal pure returns(bool) {
        return addr == address(0);
    }

    function isZero(uint a) internal pure returns(bool) {
        return a == 0;
    }

    function notZero(uint a) internal pure returns(bool) {
        return a != 0;
    }
}

 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library Percent {
    using SafeMath for uint;

     
    struct percent {
        uint num;
        uint den;
    }

    function mul(percent storage p, uint a) internal view returns (uint) {
        if (a == 0) {
            return 0;
        }
        return a.mul(p.num).div(p.den);
    }

    function div(percent storage p, uint a) internal view returns (uint) {
        return a.div(p.num).mul(p.den);
    }

    function sub(percent storage p, uint a) internal view returns (uint) {
        uint b = mul(p, a);
        if (b >= a) {
            return 0;  
        }
        return a.sub(b);
    }

    function add(percent storage p, uint a) internal view returns (uint) {
        return a.add(mul(p, a));
    }

    function toMemory(percent storage p) internal view returns (Percent.percent memory) {
        return Percent.percent(p.num, p.den);
    }

     
    function mmul(percent memory p, uint a) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        return a.mul(p.num).div(p.den);
    }

    function mdiv(percent memory p, uint a) internal pure returns (uint) {
        return a.div(p.num).mul(p.den);
    }

    function msub(percent memory p, uint a) internal pure returns (uint) {
        uint b = mmul(p, a);
        if (b >= a) {
            return 0;
        }
        return a.sub(b);
    }

    function madd(percent memory p, uint a) internal pure returns (uint) {
        return a.add(mmul(p, a));
    }
}

library ToAddress {

    function toAddress(bytes source) internal pure returns(address addr) {
        assembly { addr := mload(add(source, 0x14)) }
        return addr;
    }

    function isNotContract(address addr) internal view returns(bool) {
        uint length;
        assembly { length := extcodesize(addr) }
        return length == 0;
    }
}

contract Accessibility {

    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "access denied");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function disown() internal {
        delete owner;
    }
}

contract InvestorsStorage is Accessibility {
    using SafeMath for uint;

    struct Dividends {
        uint value;      
        uint limit;
        uint deferred;   
    }

    struct Investor {
        uint investment;
        uint paymentTime;
        Dividends dividends;
    }

    uint public size;

    mapping (address => Investor) private investors;

    function isInvestor(address addr) public view returns (bool) {
        return investors[addr].investment > 0;
    }

    function investorInfo(
        address addr
    )
        public
        view
        returns (
            uint investment,
            uint paymentTime,
            uint value,
            uint limit,
            uint deferred
        )
    {
        investment = investors[addr].investment;
        paymentTime = investors[addr].paymentTime;
        value = investors[addr].dividends.value;
        limit = investors[addr].dividends.limit;
        deferred = investors[addr].dividends.deferred;
    }

    function newInvestor(
        address addr,
        uint investment,
        uint paymentTime,
        uint dividendsLimit
    )
        public
        onlyOwner
        returns (
            bool
        )
    {
        Investor storage inv = investors[addr];
        if (inv.investment != 0 || investment == 0) {
            return false;
        }
        inv.investment = investment;
        inv.paymentTime = paymentTime;
        inv.dividends.limit = dividendsLimit;
        size++;
        return true;
    }

    function addInvestment(address addr, uint investment) public onlyOwner returns (bool) {
        if (investors[addr].investment == 0) {
            return false;
        }
        investors[addr].investment = investors[addr].investment.add(investment);
        return true;
    }

    function setPaymentTime(address addr, uint paymentTime) public onlyOwner returns (bool) {
        if (investors[addr].investment == 0) {
            return false;
        }
        investors[addr].paymentTime = paymentTime;
        return true;
    }

    function addDeferredDividends(address addr, uint dividends) public onlyOwner returns (bool) {
        if (investors[addr].investment == 0) {
            return false;
        }
        investors[addr].dividends.deferred = investors[addr].dividends.deferred.add(dividends);
        return true;
    }

    function addDividends(address addr, uint dividends) public onlyOwner returns (bool) {
        if (investors[addr].investment == 0) {
            return false;
        }
        if (investors[addr].dividends.value + dividends > investors[addr].dividends.limit) {
            investors[addr].dividends.value = investors[addr].dividends.limit;
        } else {
            investors[addr].dividends.value = investors[addr].dividends.value.add(dividends);
        }
        return true;
    }

    function setNewInvestment(address addr, uint investment, uint limit) public onlyOwner returns (bool) {
        if (investors[addr].investment == 0) {
            return false;
        }
        investors[addr].investment = investment;
        investors[addr].dividends.limit = limit;
         
        investors[addr].dividends.value = 0;
        investors[addr].dividends.deferred = 0;

        return true;
    }

    function addDividendsLimit(address addr, uint limit) public onlyOwner returns (bool) {
        if (investors[addr].investment == 0) {
            return false;
        }
        investors[addr].dividends.limit = investors[addr].dividends.limit.add(limit);

        return true;
    }
}

contract EthUp is Accessibility {
    using Percent for Percent.percent;
    using SafeMath for uint;
    using Zero for *;
    using ToAddress for *;

     
    InvestorsStorage private m_investors;
    mapping(address => bool) private m_referrals;

     
    address public advertisingAddress;
    address public adminsAddress;
    uint public investmentsNumber;
    uint public constant MIN_INVESTMENT = 10 finney;  
    uint public constant MAX_INVESTMENT = 50 ether;
    uint public constant MAX_BALANCE = 1e5 ether;  

     
    Percent.percent private m_1_percent = Percent.percent(1, 100);           
    Percent.percent private m_1_5_percent = Percent.percent(15, 1000);       
    Percent.percent private m_2_percent = Percent.percent(2, 100);           
    Percent.percent private m_2_5_percent = Percent.percent(25, 1000);       
    Percent.percent private m_3_percent = Percent.percent(3, 100);           
    Percent.percent private m_3_5_percent = Percent.percent(35, 1000);       
    Percent.percent private m_4_percent = Percent.percent(4, 100);           

    Percent.percent private m_refPercent = Percent.percent(5, 100);          
    Percent.percent private m_adminsPercent = Percent.percent(5, 100);       
    Percent.percent private m_advertisingPercent = Percent.percent(1, 10);   

    Percent.percent private m_maxDepositPercent = Percent.percent(15, 10);   
    Percent.percent private m_reinvestPercent = Percent.percent(1, 10);      

     
    event LogSendExcessOfEther(address indexed addr, uint when, uint value, uint investment, uint excess);
    event LogNewInvestor(address indexed addr, uint when);
    event LogNewInvestment(address indexed addr, uint when, uint investment, uint value);
    event LogNewReferral(address indexed addr, address indexed referrerAddr, uint when, uint refBonus);
    event LogReinvest(address indexed addr, uint when, uint investment);
    event LogPayDividends(address indexed addr, uint when, uint value);
    event LogPayReferrerBonus(address indexed addr, uint when, uint value);
    event LogBalanceChanged(uint when, uint balance);
    event LogDisown(uint when);

    modifier balanceChanged() {
        _;
        emit LogBalanceChanged(now, address(this).balance);
    }

    modifier notFromContract() {
        require(msg.sender.isNotContract(), "only externally accounts");
        _;
    }

    modifier checkPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    constructor() public {
        adminsAddress = msg.sender;
        advertisingAddress = msg.sender;

        m_investors = new InvestorsStorage();
        investmentsNumber = 0;
    }

    function() public payable {
         
        if (msg.value.isZero()) {
            getMyDividends();
            return;
        }

         
        doInvest(msg.sender, msg.data.toAddress());
    }

    function doDisown() public onlyOwner {
        disown();
        emit LogDisown(now);
    }

    function investorsNumber() public view returns(uint) {
        return m_investors.size();
    }

    function balanceETH() public view returns(uint) {
        return address(this).balance;
    }

    function percent1() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_1_percent.num, m_1_percent.den);
    }

    function percent1_5() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_1_5_percent.num, m_1_5_percent.den);
    }

    function percent2() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_2_percent.num, m_2_percent.den);
    }

    function percent2_5() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_2_5_percent.num, m_2_5_percent.den);
    }

    function percent3() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_3_percent.num, m_3_percent.den);
    }

    function percent3_5() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_3_5_percent.num, m_3_5_percent.den);
    }

    function percent4() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_4_percent.num, m_4_percent.den);
    }

    function advertisingPercent() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_advertisingPercent.num, m_advertisingPercent.den);
    }

    function adminsPercent() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_adminsPercent.num, m_adminsPercent.den);
    }

    function maxDepositPercent() public view returns(uint numerator, uint denominator) {
        (numerator, denominator) = (m_maxDepositPercent.num, m_maxDepositPercent.den);
    }

    function investorInfo(
        address investorAddr
    )
        public
        view
        returns (
            uint investment,
            uint paymentTime,
            uint dividends,
            uint dividendsLimit,
            uint dividendsDeferred,
            bool isReferral
        )
    {
        (
            investment,
            paymentTime,
            dividends,
            dividendsLimit,
            dividendsDeferred
        ) = m_investors.investorInfo(investorAddr);

        isReferral = m_referrals[investorAddr];
    }

    function getInvestorDividendsAtNow(
        address investorAddr
    )
        public
        view
        returns (
            uint dividends
        )
    {
        dividends = calcDividends(investorAddr);
    }

    function getDailyPercentAtNow(
        address investorAddr
    )
        public
        view
        returns (
            uint numerator,
            uint denominator
        )
    {
        InvestorsStorage.Investor memory investor = getMemInvestor(investorAddr);

        Percent.percent memory p = getDailyPercent(investor.investment);
        (numerator, denominator) = (p.num, p.den);
    }

    function getRefBonusPercentAtNow() public view returns(uint numerator, uint denominator) {
        Percent.percent memory p = getRefBonusPercent();
        (numerator, denominator) = (p.num, p.den);
    }

    function getMyDividends() public notFromContract balanceChanged {
         
        uint dividends = calcDividends(msg.sender);
        require(dividends.notZero(), "cannot to pay zero dividends");

         
        assert(m_investors.setPaymentTime(msg.sender, now));

         
        if (address(this).balance < dividends) {
            dividends = address(this).balance;
        }

         
        assert(m_investors.addDividends(msg.sender, dividends));

         
        msg.sender.transfer(dividends);
        emit LogPayDividends(msg.sender, now, dividends);
    }

     
    function createInvest(
        address investorAddress,
        address referrerAddr
    )
        public
        payable
        notFromContract
        balanceChanged
        onlyOwner
    {
         
        doInvest(investorAddress, referrerAddr);
    }

    function doInvest(
        address investorAddress,
        address referrerAddr
    )
        public
        payable
        notFromContract
        balanceChanged
    {
        uint investment = msg.value;
        uint receivedEther = msg.value;

        require(investment >= MIN_INVESTMENT, "investment must be >= MIN_INVESTMENT");
        require(address(this).balance + investment <= MAX_BALANCE, "the contract eth balance limit");

         
        if (receivedEther > MAX_INVESTMENT) {
            uint excess = receivedEther - MAX_INVESTMENT;
            investment = MAX_INVESTMENT;
            investorAddress.transfer(excess);
            emit LogSendExcessOfEther(investorAddress, now, receivedEther, investment, excess);
        }

         
        uint advertisingCommission = m_advertisingPercent.mul(investment);
        uint adminsCommission = m_adminsPercent.mul(investment);
        advertisingAddress.transfer(advertisingCommission);
        adminsAddress.transfer(adminsCommission);

        bool senderIsInvestor = m_investors.isInvestor(investorAddress);

         
        if (referrerAddr.notZero() &&
            !senderIsInvestor &&
            !m_referrals[investorAddress] &&
            referrerAddr != investorAddress &&
            m_investors.isInvestor(referrerAddr)) {

             
            uint refBonus = getRefBonusPercent().mmul(investment);
            assert(m_investors.addInvestment(referrerAddr, refBonus));  
            investment = investment.add(refBonus);                      
            m_referrals[investorAddress] = true;
            emit LogNewReferral(investorAddress, referrerAddr, now, refBonus);
        }

         
        uint maxDividends = getMaxDepositPercent().mmul(investment);

        if (senderIsInvestor) {
             
            InvestorsStorage.Investor memory investor = getMemInvestor(investorAddress);
            if (investor.dividends.value == investor.dividends.limit) {
                uint reinvestBonus = getReinvestBonusPercent().mmul(investment);
                investment = investment.add(reinvestBonus);
                maxDividends = getMaxDepositPercent().mmul(investment);
                 
                assert(m_investors.setNewInvestment(investorAddress, investment, maxDividends));
                emit LogReinvest(investorAddress, now, investment);
            } else {
                 
                uint dividends = calcDividends(investorAddress);
                if (dividends.notZero()) {
                    assert(m_investors.addDeferredDividends(investorAddress, dividends));
                }
                 
                assert(m_investors.addInvestment(investorAddress, investment));
                assert(m_investors.addDividendsLimit(investorAddress, maxDividends));
            }
            assert(m_investors.setPaymentTime(investorAddress, now));
        } else {
             
            assert(m_investors.newInvestor(investorAddress, investment, now, maxDividends));
            emit LogNewInvestor(investorAddress, now);
        }

        investmentsNumber++;
        emit LogNewInvestment(investorAddress, now, investment, receivedEther);
    }

    function setAdvertisingAddress(address addr) public onlyOwner {
        addr.requireNotZero();
        advertisingAddress = addr;
    }

    function setAdminsAddress(address addr) public onlyOwner {
        addr.requireNotZero();
        adminsAddress = addr;
    }

    function getMemInvestor(
        address investorAddr
    )
        internal
        view
        returns (
            InvestorsStorage.Investor memory
        )
    {
        (
            uint investment,
            uint paymentTime,
            uint dividends,
            uint dividendsLimit,
            uint dividendsDeferred
        ) = m_investors.investorInfo(investorAddr);

        return InvestorsStorage.Investor(
            investment,
            paymentTime,
            InvestorsStorage.Dividends(
                dividends,
                dividendsLimit,
                dividendsDeferred)
        );
    }

    function calcDividends(address investorAddr) internal view returns(uint dividends) {
        InvestorsStorage.Investor memory investor = getMemInvestor(investorAddr);
        uint interval = 1 days;
        uint pastTime = now.sub(investor.paymentTime);

         
        if (investor.investment.isZero() || pastTime < interval) {
            return 0;
        }

         
        if (investor.dividends.value >= investor.dividends.limit) {
            return 0;
        }

        Percent.percent memory p = getDailyPercent(investor.investment);
        Percent.percent memory c = Percent.percent(p.num + p.den, p.den);

        uint intervals = pastTime.div(interval);
        uint totalDividends = investor.dividends.limit.add(investor.investment).sub(investor.dividends.value).sub(investor.dividends.deferred);

        dividends = investor.investment;
        for (uint i = 0; i < intervals; i++) {
            dividends = c.mmul(dividends);
            if (dividends > totalDividends) {
                dividends = totalDividends.add(investor.dividends.deferred);
                break;
            }
        }

        dividends = dividends.sub(investor.investment);

         
         
         
         
    }

    function getMaxDepositPercent() internal view returns(Percent.percent memory p) {
        p = m_maxDepositPercent.toMemory();
    }

    function getDailyPercent(uint value) internal view returns(Percent.percent memory p) {
         
         
         
         
         
         
         

        if (MIN_INVESTMENT <= value && value < 100 finney) {
            p = m_1_percent.toMemory();                      
        } else if (100 finney <= value && value < 1 ether) {
            p = m_1_5_percent.toMemory();                    
        } else if (1 ether <= value && value < 5 ether) {
            p = m_2_percent.toMemory();                      
        } else if (5 ether <= value && value < 10 ether) {
            p = m_2_5_percent.toMemory();                    
        } else if (10 ether <= value && value < 20 ether) {
            p = m_3_percent.toMemory();                      
        } else if (20 ether <= value && value < 30 ether) {
            p = m_3_5_percent.toMemory();                    
        } else if (30 ether <= value && value <= MAX_INVESTMENT) {
            p = m_4_percent.toMemory();                      
        }
    }

    function getRefBonusPercent() internal view returns(Percent.percent memory p) {
        p = m_refPercent.toMemory();
    }

    function getReinvestBonusPercent() internal view returns(Percent.percent memory p) {
        p = m_reinvestPercent.toMemory();
    }
}