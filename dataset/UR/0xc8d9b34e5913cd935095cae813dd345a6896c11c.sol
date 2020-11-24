 

 
 

pragma solidity ^ 0.4.15;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns(uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract ERC20 {
    uint256 public totalSupply = 0;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    function balanceOf(address _owner) public constant returns(uint256);
    function transfer(address _to, uint256 _value) public returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
    function approve(address _spender, uint256 _value) public returns(bool);
    function allowance(address _owner, address _spender) public constant returns(uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract AppicsICO {
     
    AppicsToken public XAP = new AppicsToken(this);
    using SafeMath for uint256;
    mapping (address => string) public  keys;

     
     
    uint256 public Rate_Eth = 700;  
    uint256 public Tokens_Per_Dollar_Numerator = 20; 
    uint256 public Tokens_Per_Dollar_Denominator = 3; 
    
     
    uint256 constant AppicsPart = 20;  
    uint256 constant EcosystemPart = 20;  
    uint256 constant SteemitPart = 5;  
    uint256 constant BountyPart = 5;  
    uint256 constant icoPart = 50;  
    uint256 constant PreSaleHardCap = 12500000*1e18;
    uint256 constant RoundAHardCap = 25000000*1e18;
    uint256 constant RoundBHardCap = 30000000*1e18;
    uint256 constant RoundCHardCap = 30000000*1e18;
    uint256 constant RoundDHardCap = 22500000*1e18;
    uint256 public PreSaleSold = 0;
    uint256 public RoundASold = 0;
    uint256 public RoundBSold = 0;
    uint256 public RoundCSold = 0;
    uint256 public RoundDSold = 0;        
    uint256 constant TENTHOUSENDLIMIT = 66666666666666666666666;
     
    address public Company;
    address public AppicsFund;
    address public EcosystemFund;
    address public SteemitFund;
    address public BountyFund;
    address public Manager;  
    address public Controller_Address1;  
    address public Controller_Address2;  
    address public Controller_Address3;  
    address public Oracle;  

     
    enum StatusICO {
        Created,
        PreSaleStarted,
        PreSalePaused,
        PreSaleFinished,
        RoundAStarted,
        RoundAPaused,
        RoundAFinished,
        RoundBStarted,
        RoundBPaused,
        RoundBFinished,
        RoundCStarted,
        RoundCPaused,
        RoundCFinished,
        RoundDStarted,
        RoundDPaused,
        RoundDFinished
    }

    StatusICO statusICO = StatusICO.Created;

     
    event LogStartPreSaleRound();
    event LogPausePreSaleRound();
    event LogFinishPreSaleRound(
        address AppicsFund, 
        address EcosystemFund,
        address SteemitFund,
        address BountyFund
    );
    event LogStartRoundA();
    event LogPauseRoundA();
    event LogFinishRoundA(
        address AppicsFund, 
        address EcosystemFund,
        address SteemitFund,
        address BountyFund
    );
    event LogStartRoundB();
    event LogPauseRoundB();
    event LogFinishRoundB(
        address AppicsFund, 
        address EcosystemFund,
        address SteemitFund,
        address BountyFund
    );
    event LogStartRoundC();
    event LogPauseRoundC();
    event LogFinishRoundC(
        address AppicsFund, 
        address EcosystemFund,
        address SteemitFund,
        address BountyFund
    );
    event LogStartRoundD();
    event LogPauseRoundD();
    event LogFinishRoundD(
        address AppicsFund, 
        address EcosystemFund,
        address SteemitFund,
        address BountyFund
    );
    event LogBuyForInvestor(address investor, uint256 aidValue, string txHash);
    event LogRegister(address investor, string key);

     
     
    modifier oracleOnly {
        require(msg.sender == Oracle);
        _;
    }
     
    modifier managerOnly {
        require(msg.sender == Manager);
        _;
    }
     
    modifier controllersOnly {
        require(
            (msg.sender == Controller_Address1) || 
            (msg.sender == Controller_Address2) || 
            (msg.sender == Controller_Address3)
        );
        _;
    }
     
    modifier startedOnly {
        require(
            (statusICO == StatusICO.PreSaleStarted) || 
            (statusICO == StatusICO.RoundAStarted) || 
            (statusICO == StatusICO.RoundBStarted) ||
            (statusICO == StatusICO.RoundCStarted) ||
            (statusICO == StatusICO.RoundDStarted)
        );
        _;
    }
     
    modifier finishedOnly {
        require(
            (statusICO == StatusICO.PreSaleFinished) || 
            (statusICO == StatusICO.RoundAFinished) || 
            (statusICO == StatusICO.RoundBFinished) ||
            (statusICO == StatusICO.RoundCFinished) ||
            (statusICO == StatusICO.RoundDFinished)
        );
        _;
    }


    
    function AppicsICO(
        address _Company,
        address _AppicsFund,
        address _EcosystemFund,
        address _SteemitFund,
        address _BountyFund,
        address _Manager,
        address _Controller_Address1,
        address _Controller_Address2,
        address _Controller_Address3,
        address _Oracle
    )
        public {
        Company = _Company;
        AppicsFund = _AppicsFund;
        EcosystemFund = _EcosystemFund;
        SteemitFund = _SteemitFund;
        BountyFund = _BountyFund;
        Manager = _Manager;
        Controller_Address1 = _Controller_Address1;
        Controller_Address2 = _Controller_Address2;
        Controller_Address3 = _Controller_Address3;
        Oracle = _Oracle;
    }

    
    function setRate(uint256 _RateEth) external oracleOnly {
        Rate_Eth = _RateEth;
    }

    
    function startPreSaleRound() external managerOnly {
        require(statusICO == StatusICO.Created || statusICO == StatusICO.PreSalePaused);
        statusICO = StatusICO.PreSaleStarted;
        LogStartPreSaleRound();
    }

    
    function pausePreSaleRound() external managerOnly {
        require(statusICO == StatusICO.PreSaleStarted);
        statusICO = StatusICO.PreSalePaused;
        LogPausePreSaleRound();
    }


    
    function finishPreSaleRound() external managerOnly {
        require(statusICO == StatusICO.PreSaleStarted || statusICO == StatusICO.PreSalePaused);
        uint256 totalAmount = PreSaleSold.mul(100).div(icoPart);
        XAP.mintTokens(AppicsFund, AppicsPart.mul(totalAmount).div(100));
        XAP.mintTokens(EcosystemFund, EcosystemPart.mul(totalAmount).div(100));
        XAP.mintTokens(SteemitFund, SteemitPart.mul(totalAmount).div(100));
        XAP.mintTokens(BountyFund, BountyPart.mul(totalAmount).div(100));
        statusICO = StatusICO.PreSaleFinished;
        LogFinishPreSaleRound(AppicsFund, EcosystemFund, SteemitFund, BountyFund);

    }
   
    
    function startRoundA() external managerOnly {
        require(statusICO == StatusICO.PreSaleFinished || statusICO == StatusICO.RoundAPaused);
        statusICO = StatusICO.RoundAStarted;
        LogStartRoundA();
    }

    
    function pauseRoundA() external managerOnly {
        require(statusICO == StatusICO.RoundAStarted);
        statusICO = StatusICO.RoundAPaused;
        LogPauseRoundA();
    }


    
    function finishRoundA() external managerOnly {
        require(statusICO == StatusICO.RoundAStarted || statusICO == StatusICO.RoundAPaused);
        uint256 totalAmount = RoundASold.mul(100).div(icoPart);
        XAP.mintTokens(AppicsFund, AppicsPart.mul(totalAmount).div(100));
        XAP.mintTokens(EcosystemFund, EcosystemPart.mul(totalAmount).div(100));
        XAP.mintTokens(SteemitFund, SteemitPart.mul(totalAmount).div(100));
        XAP.mintTokens(BountyFund, BountyPart.mul(totalAmount).div(100));
        statusICO = StatusICO.RoundAFinished;
        LogFinishRoundA(AppicsFund, EcosystemFund, SteemitFund, BountyFund);
    }

    
    function startRoundB() external managerOnly {
        require(statusICO == StatusICO.RoundAFinished || statusICO == StatusICO.RoundBPaused);
        statusICO = StatusICO.RoundBStarted;
        LogStartRoundB();
    }

    
    function pauseRoundB() external managerOnly {
        require(statusICO == StatusICO.RoundBStarted);
        statusICO = StatusICO.RoundBPaused;
        LogPauseRoundB();
    }


    
    function finishRoundB() external managerOnly {
        require(statusICO == StatusICO.RoundBStarted || statusICO == StatusICO.RoundBPaused);
        uint256 totalAmount = RoundBSold.mul(100).div(icoPart);
        XAP.mintTokens(AppicsFund, AppicsPart.mul(totalAmount).div(100));
        XAP.mintTokens(EcosystemFund, EcosystemPart.mul(totalAmount).div(100));
        XAP.mintTokens(SteemitFund, SteemitPart.mul(totalAmount).div(100));
        XAP.mintTokens(BountyFund, BountyPart.mul(totalAmount).div(100));
        statusICO = StatusICO.RoundBFinished;
        LogFinishRoundB(AppicsFund, EcosystemFund, SteemitFund, BountyFund);
    }

    
    function startRoundC() external managerOnly {
        require(statusICO == StatusICO.RoundBFinished || statusICO == StatusICO.RoundCPaused);
        statusICO = StatusICO.RoundCStarted;
        LogStartRoundC();
    }

    
    function pauseRoundC() external managerOnly {
        require(statusICO == StatusICO.RoundCStarted);
        statusICO = StatusICO.RoundCPaused;
        LogPauseRoundC();
    }


    
    function finishRoundC() external managerOnly {
        require(statusICO == StatusICO.RoundCStarted || statusICO == StatusICO.RoundCPaused);
        uint256 totalAmount = RoundCSold.mul(100).div(icoPart);
        XAP.mintTokens(AppicsFund, AppicsPart.mul(totalAmount).div(100));
        XAP.mintTokens(EcosystemFund, EcosystemPart.mul(totalAmount).div(100));
        XAP.mintTokens(SteemitFund, SteemitPart.mul(totalAmount).div(100));
        XAP.mintTokens(BountyFund, BountyPart.mul(totalAmount).div(100));
        statusICO = StatusICO.RoundCFinished;
        LogFinishRoundC(AppicsFund, EcosystemFund, SteemitFund, BountyFund);
    }

    
    function startRoundD() external managerOnly {
        require(statusICO == StatusICO.RoundCFinished || statusICO == StatusICO.RoundDPaused);
        statusICO = StatusICO.RoundDStarted;
        LogStartRoundD();
    }

    
    function pauseRoundD() external managerOnly {
        require(statusICO == StatusICO.RoundDStarted);
        statusICO = StatusICO.RoundDPaused;
        LogPauseRoundD();
    }


    
    function finishRoundD() external managerOnly {
        require(statusICO == StatusICO.RoundDStarted || statusICO == StatusICO.RoundDPaused);
        uint256 totalAmount = RoundDSold.mul(100).div(icoPart);
        XAP.mintTokens(AppicsFund, AppicsPart.mul(totalAmount).div(100));
        XAP.mintTokens(EcosystemFund, EcosystemPart.mul(totalAmount).div(100));
        XAP.mintTokens(SteemitFund, SteemitPart.mul(totalAmount).div(100));
        XAP.mintTokens(BountyFund, BountyPart.mul(totalAmount).div(100));
        statusICO = StatusICO.RoundDFinished;
        LogFinishRoundD(AppicsFund, EcosystemFund, SteemitFund, BountyFund);
    }    


    
    function unfreeze() external managerOnly {
        XAP.defrostTokens();
    }

    
    function freeze() external managerOnly {
        XAP.frostTokens();
    }

    
    function() external payable {
        uint256 tokens; 
        tokens = msg.value.mul(Tokens_Per_Dollar_Numerator).mul(Rate_Eth);
         
        tokens = tokens.div(Tokens_Per_Dollar_Denominator);
        buyTokens(msg.sender, tokens);
    }

    
    function buyForInvestor(
        address _investor,
        uint256 _xapValue,
        string _txHash
    )
        external
        controllersOnly
        startedOnly {
        buyTokens(_investor, _xapValue);        
        LogBuyForInvestor(_investor, _xapValue, _txHash);
    }


    
    function buyTokens(address _investor, uint256 _xapValue) internal startedOnly {
        require(_xapValue > 0);
        uint256 bonus = getBonus(_xapValue);
        uint256 total = _xapValue.add(bonus);
        if (statusICO == StatusICO.PreSaleStarted) {
            require (PreSaleSold.add(total) <= PreSaleHardCap);
            require(_xapValue > TENTHOUSENDLIMIT);
            PreSaleSold = PreSaleSold.add(total);
        }
        if (statusICO == StatusICO.RoundAStarted) {
            require (RoundASold.add(total) <= RoundAHardCap);
            RoundASold = RoundASold.add(total);
        }
        if (statusICO == StatusICO.RoundBStarted) {
            require (RoundBSold.add(total) <= RoundBHardCap);
            RoundBSold = RoundBSold.add(total);
        }
        if (statusICO == StatusICO.RoundCStarted) {
            require (RoundCSold.add(total) <= RoundCHardCap);
            RoundCSold = RoundCSold.add(total);
        }
        if (statusICO == StatusICO.RoundDStarted) {
            require (RoundDSold.add(total) <= RoundDHardCap);
            RoundDSold = RoundDSold.add(total);
        }
        XAP.mintTokens(_investor, total);
    }

    
    function getBonus(uint256 _value)
        public
        constant
        returns(uint256)
    {
        uint256 bonus = 0;
        if (statusICO == StatusICO.PreSaleStarted) {
            bonus = _value.mul(20).div(100);
        }
        if (statusICO == StatusICO.RoundAStarted) {
            bonus = _value.mul(15).div(100); 
        }
        if (statusICO == StatusICO.RoundBStarted) {
            bonus = _value.mul(10).div(100); 
        }
        if (statusICO == StatusICO.RoundCStarted) {
            bonus = _value.mul(5).div(100); 
        }
        return bonus;
    }
    
    function register(string _key) public {
        keys[msg.sender] = _key;
        LogRegister(msg.sender, _key);
    }


    
    function withdrawEther() external managerOnly finishedOnly{
        Company.transfer(this.balance);
    }

}


 
contract AppicsToken is ERC20 {
    using SafeMath for uint256;
    string public name = "Appics";
    string public symbol = "XAP";
    uint256 public decimals = 18;

     
    address public ico;
    event Burn(address indexed from, uint256 value);

     
    bool public tokensAreFrozen = true;

     
    modifier icoOnly {
        require(msg.sender == ico);
        _;
    }

    
    function AppicsToken(address _ico) public {
        ico = _ico;
    }

    
    function mintTokens(address _holder, uint256 _value) external icoOnly {
        require(_value > 0);
        balances[_holder] = balances[_holder].add(_value);
        totalSupply = totalSupply.add(_value);
        Transfer(0x0, _holder, _value);
    }

    
    function defrostTokens() external icoOnly {
      tokensAreFrozen = false;
    }

     
    function frostTokens() external icoOnly {
      tokensAreFrozen = true;
    }

    
    function burnTokens(address _investor, uint256 _value) external icoOnly {
        require(balances[_investor] > 0);
        totalSupply = totalSupply.sub(_value);
        balances[_investor] = balances[_investor].sub(_value);
        Burn(_investor, _value);
    }

    
    function balanceOf(address _owner) public constant returns(uint256) {
      return balances[_owner];
    }

    
    function transfer(address _to, uint256 _amount) public returns(bool) {
        require(!tokensAreFrozen);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool) {
        require(!tokensAreFrozen);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

    
    function approve(address _spender, uint256 _amount) public returns(bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    
    function allowance(address _owner, address _spender) public constant returns(uint256) {
        return allowed[_owner][_spender];
    }
}