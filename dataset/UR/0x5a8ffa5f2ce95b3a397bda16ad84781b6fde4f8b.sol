 

 
 
pragma solidity ^0.4.15;

 

library SafeMath {

  function mul(uint a, uint b) internal constant returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal constant returns(uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal constant returns(uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal constant returns(uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

 

contract ERC20 {
    uint public totalSupply = 0;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    function balanceOf(address _owner) constant returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

} 

 
contract DatariusICO {
     
    using SafeMath for uint;
    DatariusToken public DTRC = new DatariusToken(this);
    ERC20 public preSaleToken;

     
     
    uint public tokensPerDollar = 100;
    uint public rateEth = 1176;  
    uint public tokenPrice = tokensPerDollar * rateEth;  
    uint public DatToDtrcNumerator = 4589059589;
    uint public DatToDtrcDenominator = 100000000;

     
    uint constant softCap = 1000000 * tokensPerDollar * 1e18; 
    uint constant hardCap = 51000000 * tokensPerDollar * 1e18;
    uint constant bountyPart = 2;  
    uint constant partnersPart = 5;  
    uint constant teamPart = 5;  
    uint constant reservePart = 15;  
    uint constant publicIcoPart = 73;  
    uint public soldAmount = 0;
    uint startTime = 0;
     
    address public Company;
    address public BountyFund;
    address public PartnersFund;
    address public TeamFund;
    address public ReserveFund;
    address public Manager;  
    address public ReserveManager;  
    address public Controller_Address1;  
    address public Controller_Address2;  
    address public Controller_Address3;  
    address public RefundManager;  
    address public Oracle;  

     
    enum StatusICO {
        Created,
        Started,
        Paused,
        Finished
    }
    StatusICO statusICO = StatusICO.Created;
    
     
    mapping(address => uint) public investmentsInEth;  
    mapping(address => uint) public tokensEth;  
    mapping(address => uint) public tokensOtherCrypto;  
    mapping(address => bool) public swaped;
     
    event LogStartICO();
    event LogPause();
    event LogFinishICO();
    event LogBuyForInvestor(address investor, uint DTRCValue, string txHash);
    event LogSwapTokens(address investor, uint tokensAmount);
    event LogReturnEth(address investor, uint eth);
    event LogReturnOtherCrypto(address investor, string logString);

     
     
    modifier managersOnly { 
        require(
            (msg.sender == Manager) ||
            (msg.sender == ReserveManager)
        );
        _; 
     }
     
    modifier refundManagersOnly { 
        require(msg.sender == RefundManager);
        _; 
     }
     
    modifier oracleOnly { 
        require(msg.sender == Oracle);
        _; 
     }
     
    modifier controllersOnly {
        require(
            (msg.sender == Controller_Address1)||
            (msg.sender == Controller_Address2)||
            (msg.sender == Controller_Address3)
        );
        _;
    }

    
    function DatariusICO(
        address _preSaleToken,
        address _Company,
        address _BountyFund,
        address _PartnersFund,
        address _ReserveFund,
        address _TeamFund,
        address _Manager,
        address _ReserveManager,
        address _Controller_Address1,
        address _Controller_Address2,
        address _Controller_Address3,
        address _RefundManager,
        address _Oracle
        ) public {
        preSaleToken = ERC20(_preSaleToken);
        Company = _Company;
        BountyFund = _BountyFund;
        PartnersFund = _PartnersFund;
        ReserveFund = _ReserveFund;
        TeamFund = _TeamFund;
        Manager = _Manager;
        ReserveManager = _ReserveManager;
        Controller_Address1 = _Controller_Address1;
        Controller_Address2 = _Controller_Address2;
        Controller_Address3 = _Controller_Address3;
        RefundManager = _RefundManager;
        Oracle = _Oracle;
    }

    
    function setRate(uint _rateEth) external oracleOnly {
        rateEth = _rateEth;
        tokenPrice = tokensPerDollar.mul(rateEth);
    }

    
    function startIco() external managersOnly {
        require(statusICO == StatusICO.Created || statusICO == StatusICO.Paused);
        if(statusICO == StatusICO.Created) {
          startTime = now;
        }
        statusICO = StatusICO.Started;
        LogStartICO();
    }

    
    function pauseIco() external managersOnly {
       require(statusICO == StatusICO.Started);
       statusICO = StatusICO.Paused;
       LogPause();
    }

    
    function finishIco() external managersOnly {
        require(statusICO == StatusICO.Started || statusICO == StatusICO.Paused);
        uint alreadyMinted = DTRC.totalSupply();
        uint totalAmount = alreadyMinted.mul(100).div(publicIcoPart);
        DTRC.mintTokens(BountyFund, bountyPart.mul(totalAmount).div(100));
        DTRC.mintTokens(PartnersFund, partnersPart.mul(totalAmount).div(100));
        DTRC.mintTokens(TeamFund, teamPart.mul(totalAmount).div(100));
        DTRC.mintTokens(ReserveFund, reservePart.mul(totalAmount).div(100));
        if (soldAmount >= softCap) {
            DTRC.defrost();
        }
        statusICO = StatusICO.Finished;
        LogFinishICO();
    }

    
    function swapTokens(address _investor) external managersOnly {
         require(!swaped[_investor] && statusICO != StatusICO.Finished);
         swaped[_investor] = true;
         uint tokensToSwap = preSaleToken.balanceOf(_investor);
         uint DTRCTokens = tokensToSwap.mul(DatToDtrcNumerator).div(DatToDtrcDenominator);
         DTRC.mintTokens(_investor, DTRCTokens);
         LogSwapTokens(_investor, tokensToSwap);
    }
    
    function() external payable {
        buy(msg.sender, msg.value.mul(tokenPrice));
        investmentsInEth[msg.sender] = investmentsInEth[msg.sender].add(msg.value); 
    }

    

    function buyForInvestor(
        address _investor, 
        uint _DTRCValue, 
        string _txHash
    ) 
        external 
        controllersOnly {
        require(statusICO == StatusICO.Started);
        require(soldAmount + _DTRCValue <= hardCap);
        uint bonus = getBonus(_DTRCValue);
        uint total = _DTRCValue.add(bonus);
        DTRC.mintTokens(_investor, total);
        soldAmount = soldAmount.add(_DTRCValue);
        tokensOtherCrypto[_investor] = tokensOtherCrypto[_investor].add(total); 
        LogBuyForInvestor(_investor, total, _txHash);
    }

    
    function buy(address _investor, uint _DTRCValue) internal {
        require(statusICO == StatusICO.Started);
        require(soldAmount + _DTRCValue <= hardCap);
        uint bonus = getBonus(_DTRCValue);
        uint total = _DTRCValue.add(bonus);
        DTRC.mintTokens(_investor, total);
        soldAmount = soldAmount.add(_DTRCValue);
        tokensEth[msg.sender] = tokensEth[msg.sender].add(total); 
    }

    
    function getBonus(uint _value) public constant returns (uint) {
        uint bonus = 0;
        if(now <= startTime + 6 hours) {
            bonus = _value.mul(30).div(100);
            return bonus;
        }
        if(now <= startTime + 12 hours) {
            bonus = _value.mul(25).div(100);
            return bonus;
        }
        if(now <= startTime + 24 hours) {
            bonus = _value.mul(20).div(100);
            return bonus;
        }
        if(now <= startTime + 48 hours) {
            bonus = _value.mul(15).div(100);
            return bonus;
        }
        if(now <= startTime + 15 days) {
            bonus = _value.mul(10).div(100);
            return bonus;
        }
    return bonus;
    }

    
    function refundEther() public {
        require(
            statusICO == StatusICO.Finished && 
            soldAmount < softCap && 
            investmentsInEth[msg.sender] > 0
        );
        uint ethToRefund = investmentsInEth[msg.sender];
        investmentsInEth[msg.sender] = 0;
        uint tokensToBurn = tokensEth[msg.sender];
        tokensEth[msg.sender] = 0;
        DTRC.burnTokens(msg.sender, tokensToBurn);
        msg.sender.transfer(ethToRefund);
        LogReturnEth(msg.sender, ethToRefund);
    }

    
    function refundOtherCrypto(
        address _investor, 
        string _logString
    ) 
        public
        refundManagersOnly {
        require(
            statusICO == StatusICO.Finished && 
            soldAmount < softCap
        );
        uint tokensToBurn = tokensOtherCrypto[_investor];
        tokensOtherCrypto[_investor] = 0;
        DTRC.burnTokens(_investor, tokensToBurn);
        LogReturnOtherCrypto(_investor, _logString);
    }

    
    function withdrawEther() external managersOnly {
        require(statusICO == StatusICO.Finished && soldAmount >= softCap);
        Company.transfer(this.balance);
    }

}

 
contract DatariusToken is ERC20 {
    using SafeMath for uint;
    string public name = "Datarius Credit";
    string public symbol = "DTRC";
    uint public decimals = 18;

     
    address public ico;
    event Burn(address indexed from, uint value);
    
     
    bool public tokensAreFrozen = true;

     
    modifier icoOnly { 
        require(msg.sender == ico); 
        _; 
    }

    
    function DatariusToken(address _ico) public {
       ico = _ico;
    }

    
    function mintTokens(address _holder, uint _value) external icoOnly {
       require(_value > 0);
       balances[_holder] = balances[_holder].add(_value);
       totalSupply = totalSupply.add(_value);
       Transfer(0x0, _holder, _value);
    }


    
    function defrost() external icoOnly {
       tokensAreFrozen = false;
    }


    
    function burnTokens(address _holder, uint _value) external icoOnly {
        require(balances[_holder] > 0);
        totalSupply = totalSupply.sub(_value);
        balances[_holder] = balances[_holder].sub(_value);
        Burn(_holder, _value);
    }

    
    function balanceOf(address _holder) constant returns (uint) {
         return balances[_holder];
    }

    
    function transfer(address _to, uint _amount) public returns (bool) {
        require(!tokensAreFrozen);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        require(!tokensAreFrozen);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
     }


    
    function approve(address _spender, uint _amount) public returns (bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    
    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }
}