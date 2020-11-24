 

 
 
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

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    function balanceOf(address _owner) constant returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

} 

 
contract Play2liveICO {
     
    using SafeMath for uint;
    LucToken public LUC = new LucToken(this);
    Presale public preSaleToken;

     
     
    uint public tokensPerDollar = 20;
    uint public rateEth = 446;  
    uint public tokenPrice = tokensPerDollar * rateEth;  
     
    uint constant publicIcoPart = 625;  
    uint constant operationsPart = 111;
    uint constant foundersPart = 104;
    uint constant partnersPart = 78;  
    uint constant advisorsPart = 72;
    uint constant bountyPart = 10;  
    uint constant hardCap = 30000000 * tokensPerDollar * 1e18;  
    uint public soldAmount = 0;
     
    address public Company;
    address public OperationsFund;
    address public FoundersFund;
    address public PartnersFund;
    address public AdvisorsFund;
    address public BountyFund;
    address public Manager;  
    address public Controller_Address1;  
    address public Controller_Address2;  
    address public Controller_Address3;  
    address public Oracle;  

     
    enum StatusICO {
        Created,
        PreIcoStarted,
        PreIcoPaused,
        PreIcoFinished,
        IcoStarted,
        IcoPaused,
        IcoFinished
    }
    StatusICO statusICO = StatusICO.Created;
    
     
    mapping(address => bool) public swaped;
    mapping (address => string) public keys;
    
     
    event LogStartPreICO();
    event LogPausePreICO();
    event LogFinishPreICO();
    event LogStartICO();
    event LogPauseICO();
    event LogFinishICO();
    event LogBuyForInvestor(address investor, uint lucValue, string txHash);
    event LogSwapTokens(address investor, uint tokensAmount);
    event LogRegister(address investor, string key);

     
     
    modifier managerOnly { 
        require(msg.sender == Manager);
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


    
    function Play2liveICO(
        address _preSaleToken,
        address _Company,
        address _OperationsFund,
        address _FoundersFund,
        address _PartnersFund,
        address _AdvisorsFund,
        address _BountyFund,
        address _Manager,
        address _Controller_Address1,
        address _Controller_Address2,
        address _Controller_Address3,
        address _Oracle
        ) public {
        preSaleToken = Presale(_preSaleToken);
        Company = _Company;
        OperationsFund = _OperationsFund;
        FoundersFund = _FoundersFund;
        PartnersFund = _PartnersFund;
        AdvisorsFund = _AdvisorsFund;
        BountyFund = _BountyFund;
        Manager = _Manager;
        Controller_Address1 = _Controller_Address1;
        Controller_Address2 = _Controller_Address2;
        Controller_Address3 = _Controller_Address3;
        Oracle = _Oracle;
    }

    
    function setRate(uint _rateEth) external oracleOnly {
        rateEth = _rateEth;
        tokenPrice = tokensPerDollar.mul(rateEth);
    }

    
    function startPreIco() external managerOnly {
        require(statusICO == StatusICO.Created || statusICO == StatusICO.PreIcoPaused);
        statusICO = StatusICO.PreIcoStarted;
        LogStartPreICO();
    }

    
    function pausePreIco() external managerOnly {
       require(statusICO == StatusICO.PreIcoStarted);
       statusICO = StatusICO.PreIcoPaused;
       LogPausePreICO();
    }

    
    function finishPreIco() external managerOnly {
        require(statusICO == StatusICO.PreIcoStarted || statusICO == StatusICO.PreIcoPaused);
        statusICO = StatusICO.PreIcoFinished;
        LogFinishPreICO();
    }

    
    function startIco() external managerOnly {
        require(statusICO == StatusICO.PreIcoFinished || statusICO == StatusICO.IcoPaused);
        statusICO = StatusICO.IcoStarted;
        LogStartICO();
    }

    
    function pauseIco() external managerOnly {
       require(statusICO == StatusICO.IcoStarted);
       statusICO = StatusICO.IcoPaused;
       LogPauseICO();
    }

    
    function finishIco() external managerOnly {
        require(statusICO == StatusICO.IcoStarted || statusICO == StatusICO.IcoPaused);
        uint alreadyMinted = LUC.totalSupply();
        uint totalAmount = alreadyMinted.mul(1000).div(publicIcoPart);
        LUC.mintTokens(OperationsFund, operationsPart.mul(totalAmount).div(1000));
        LUC.mintTokens(FoundersFund, foundersPart.mul(totalAmount).div(1000));
        LUC.mintTokens(PartnersFund, partnersPart.mul(totalAmount).div(1000));
        LUC.mintTokens(AdvisorsFund, advisorsPart.mul(totalAmount).div(1000));
        LUC.mintTokens(BountyFund, bountyPart.mul(totalAmount).div(1000));
        statusICO = StatusICO.IcoFinished;
        LogFinishICO();
    }

    
    function unfreeze() external managerOnly {
        require(statusICO == StatusICO.IcoFinished);
        LUC.defrost();
    }
    
    
    function swapTokens(address _investor) external managerOnly {
         require(statusICO != StatusICO.IcoFinished);
         require(!swaped[_investor]);
         swaped[_investor] = true;
         uint tokensToSwap = preSaleToken.balanceOf(_investor);
         LUC.mintTokens(_investor, tokensToSwap);
         soldAmount = soldAmount.add(tokensToSwap);
         LogSwapTokens(_investor, tokensToSwap);
    }
    
    function() external payable {
        if (statusICO == StatusICO.PreIcoStarted) {
            require(msg.value >= 100 finney);
        }
        buy(msg.sender, msg.value.mul(tokenPrice)); 
    }

    

    function buyForInvestor(
        address _investor, 
        uint _lucValue, 
        string _txHash
    ) 
        external 
        controllersOnly {
        buy(_investor, _lucValue);
        LogBuyForInvestor(_investor, _lucValue, _txHash);
    }

    
    function buy(address _investor, uint _lucValue) internal {
        require(statusICO == StatusICO.PreIcoStarted || statusICO == StatusICO.IcoStarted);
        uint bonus = getBonus(_lucValue);
        uint total = _lucValue.add(bonus);
        require(soldAmount + _lucValue <= hardCap);
        LUC.mintTokens(_investor, total);
        soldAmount = soldAmount.add(_lucValue);
    }



    
    function getBonus(uint _value) public constant returns (uint) {
        uint bonus = 0;
        if (statusICO == StatusICO.PreIcoStarted) {
            if (now < 1517356800) {
                bonus = _value.mul(30).div(100);
                return bonus;
            } else {
                bonus = _value.mul(25).div(100);
                return bonus;                
            }
        }
        if (statusICO == StatusICO.IcoStarted) {
            if (now < 1518652800) {
                bonus = _value.mul(10).div(100);
                return bonus;                   
            }
            if (now < 1518912000) {
                bonus = _value.mul(9).div(100);
                return bonus;                   
            }
            if (now < 1519171200) {
                bonus = _value.mul(8).div(100);
                return bonus;                   
            }
            if (now < 1519344000) {
                bonus = _value.mul(7).div(100);
                return bonus;                   
            }
            if (now < 1519516800) {
                bonus = _value.mul(6).div(100);
                return bonus;                   
            }
            if (now < 1519689600) {
                bonus = _value.mul(5).div(100);
                return bonus;                   
            }
            if (now < 1519862400) {
                bonus = _value.mul(4).div(100);
                return bonus;                   
            }
            if (now < 1520035200) {
                bonus = _value.mul(3).div(100);
                return bonus;                   
            }
            if (now < 1520208000) {
                bonus = _value.mul(2).div(100);
                return bonus;                   
            } else {
                bonus = _value.mul(1).div(100);
                return bonus;                   
            }
        }
        return bonus;
    }

    
    function register(string _key) public {
        keys[msg.sender] = _key;
        LogRegister(msg.sender, _key);
    }

    
    function withdrawEther() external managerOnly {
        Company.transfer(this.balance);
    }

}

 
contract LucToken is ERC20 {
    using SafeMath for uint;
    string public name = "Level Up Coin";
    string public symbol = "LUC";
    uint public decimals = 18;

     
    address public ico;
    
     
    bool public tokensAreFrozen = true;

     
    modifier icoOnly { 
        require(msg.sender == ico); 
        _; 
    }

    
    function LucToken(address _ico) public {
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

    
    function balanceOf(address _holder) constant returns (uint256) {
         return balances[_holder];
    }

    
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(!tokensAreFrozen);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(!tokensAreFrozen);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
     }


    
    function approve(address _spender, uint256 _amount) public returns (bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }
}





contract tokenLUCG {
     
        string public name;
        string public symbol;
        uint8 public decimals;
        uint256 public totalSupply = 0;


        function tokenLUCG (string _name, string _symbol, uint8 _decimals){
            name = _name;
            symbol = _symbol;
            decimals = _decimals;

        }
     
        mapping (address => uint256) public balanceOf;

}

contract Presale is tokenLUCG {

        using SafeMath for uint;
        string name = 'Level Up Coin Gold';
        string symbol = 'LUCG';
        uint8 decimals = 18;
        address manager;
        address public ico;

        function Presale (address _manager) tokenLUCG (name, symbol, decimals){
             manager = _manager;

        }

        event Transfer(address _from, address _to, uint256 amount);
        event Burn(address _from, uint256 amount);

        modifier onlyManager{
             require(msg.sender == manager);
            _;
        }

        modifier onlyIco{
             require(msg.sender == ico);
            _;
        }
        function mintTokens(address _investor, uint256 _mintedAmount) public onlyManager {
             balanceOf[_investor] = balanceOf[_investor].add(_mintedAmount);
             totalSupply = totalSupply.add(_mintedAmount);
             Transfer(this, _investor, _mintedAmount);

        }

        function burnTokens(address _owner) public onlyIco{
             uint  tokens = balanceOf[_owner];
             require(balanceOf[_owner] != 0);
             balanceOf[_owner] = 0;
             totalSupply = totalSupply.sub(tokens);
             Burn(_owner, tokens);
        }

        function setIco(address _ico) onlyManager{
            ico = _ico;
        }
}