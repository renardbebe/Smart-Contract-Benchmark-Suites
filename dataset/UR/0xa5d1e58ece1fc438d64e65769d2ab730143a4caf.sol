 

pragma solidity ^0.4.11;




 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}




 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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




 
contract ERC20Basic {
  uint256 public totalSupply;

  function balanceOf(address who) constant public returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
}





 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}





contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) constant public returns (uint);

  function name() constant public returns (string _name);
  function symbol() constant public returns (string _symbol);
  function decimals() constant public returns (uint8 _decimals);
  function totalSupply() constant public returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}





 

contract ContractReceiver {

  string public functionName;
  address public sender;
  uint public value;
  bytes public data;

  function tokenFallback(address _from, uint _value, bytes _data) public {

    sender = _from;
    value = _value;
    data = _data;
    functionName = "tokenFallback";
     
     

     
  }

  function customFallback(address _from, uint _value, bytes _data) public {
    tokenFallback(_from, _value, _data);
    functionName = "customFallback";
  }
}







contract RobomedIco is ERC223, ERC20 {

    using SafeMath for uint256;

    string public name = "RobomedToken";

    string public symbol = "RBM";

    uint8 public decimals = 18;

     

     
    address public constant ADDR_OWNER = 0x21F6C4D926B705aD244Ec33271559dA8c562400F;

     
    address public constant ADDR_WITHDRAWAL1 = 0x0dD97e6259a7de196461B36B028456a97e3268bE;

     
    address public constant ADDR_WITHDRAWAL2 = 0x8c5B02144F7664D37FDfd4a2f90148d08A04838D;

     
    address public constant ADDR_BOUNTY_TOKENS_ACCOUNT = 0x6542393623Db0D7F27fDEd83e6feDBD767BfF9b4;

     
    address public constant ADDR_TEAM_TOKENS_ACCOUNT = 0x28c6bCAB2204CEd29677fEE6607E872E3c40d783;



     


     
    uint256 public constant INITIAL_COINS_FOR_VIPPLACEMENT =507937500 * 10 ** 18;

     
    uint256 public constant DURATION_VIPPLACEMENT = 1 seconds; 

     

     

     
    uint256 public constant EMISSION_FOR_PRESALE = 76212500 * 10 ** 18;

     
    uint256 public constant DURATION_PRESALE = 1 days; 

     
    uint256 public constant RATE_PRESALE = 2702;

     

     

     
    uint256 public constant DURATION_SALESTAGES = 10 days;  

     
    uint256 public constant RATE_SALESTAGE1 = 2536;

     
    uint256 public constant EMISSION_FOR_SALESTAGE1 = 40835000 * 10 ** 18;

     

     

     
    uint256 public constant RATE_SALESTAGE2 = 2473;

     
    uint256 public constant EMISSION_FOR_SALESTAGE2 = 40835000 * 10 ** 18;

     

     

     
    uint256 public constant RATE_SALESTAGE3 = 2390;

     
    uint256 public constant EMISSION_FOR_SALESTAGE3 = 40835000 * 10 ** 18;
     

     

     
    uint256 public constant RATE_SALESTAGE4 = 2349;

     
    uint256 public constant EMISSION_FOR_SALESTAGE4 = 40835000 * 10 ** 18;

     


     

     
    uint256 public constant RATE_SALESTAGE5 = 2286;

     
    uint256 public constant EMISSION_FOR_SALESTAGE5 = 40835000 * 10 ** 18;

     



     

     
    uint256 public constant RATE_SALESTAGE6 = 2224;

     
    uint256 public constant EMISSION_FOR_SALESTAGE6 = 40835000 * 10 ** 18;

     


     

     
    uint256 public constant RATE_SALESTAGE7 = 2182;

     
    uint256 public constant EMISSION_FOR_SALESTAGE7 = 40835000 * 10 ** 18;

     


     

     
    uint256 public constant DURATION_SALESTAGELAST = 1 days; 

     
    uint256 public constant RATE_SALESTAGELAST = 2078;

     
    uint256 public constant EMISSION_FOR_SALESTAGELAST = 302505000 * 10 ** 18;
     

     

     
    uint256 public constant DURATION_NONUSETEAM = 180 days; 

     
    uint256 public constant DURATION_BEFORE_RESTORE_UNSOLD = 270 days;

     

     
    uint256 public constant EMISSION_FOR_BOUNTY = 83750000 * 10 ** 18;

     
    uint256 public constant EMISSION_FOR_TEAM = 418750000 * 10 ** 18;

     
    uint256 public constant TEAM_MEMBER_VAL = 2000000 * 10 ** 18;

     
    enum IcoStates {

     
    VipPlacement,

     
    PreSale,

     
    SaleStage1,

     
    SaleStage2,

     
    SaleStage3,

     
    SaleStage4,

     
    SaleStage5,

     
    SaleStage6,

     
    SaleStage7,

     
    SaleStageLast,

     
    PostIco

    }


     
    mapping (address => uint256)  balances;

    mapping (address => mapping (address => uint256))  allowed;

     
    mapping (address => uint256) teamBalances;

     
    address public owner;


     
    address public withdrawal1;

     
    address public withdrawal2;




     
    address public bountyTokensAccount;

     
    address public teamTokensAccount;

     
    address public withdrawalTo;

     
    uint256 public withdrawalValue;

     
    uint256 public bountyTokensNotDistributed;

     
    uint256 public teamTokensNotDistributed;

     
    IcoStates public currentState;

     
    uint256 public totalBalance;

     
    uint256 public freeMoney = 0;

     
    uint256 public totalSupply = 0;

     
    uint256 public totalBought = 0;



     
    uint256 public vipPlacementNotDistributed;

     
    uint256 public endDateOfVipPlacement;

     
    uint256 public endDateOfPreSale = 0;

     
    uint256 public startDateOfSaleStageLast;

     
    uint256 public endDateOfSaleStageLast = 0;


     
    uint256 public remForSalesBeforeStageLast = 0;

     
    uint256 public startDateOfUseTeamTokens = 0;

     
    uint256 public startDateOfRestoreUnsoldTokens = 0;

     
    uint256 public unsoldTokens = 0;

     
    uint256 public rate = 0;


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyWithdrawal1() {
        require(msg.sender == withdrawal1);
        _;
    }

     
    modifier onlyWithdrawal2() {
        require(msg.sender == withdrawal2);
        _;
    }

     
    modifier afterIco() {
        require(uint(currentState) >= uint(IcoStates.PostIco));
        _;
    }


     
    modifier checkForTransfer(address _from, address _to, uint256 _value)  {

         
        require(_value > 0);

         
        require(_to != 0x0 && _to != _from);

         
        require(currentState == IcoStates.PostIco || _from == owner);

         
        require(currentState == IcoStates.PostIco || (_to != bountyTokensAccount && _to != teamTokensAccount));

        _;
    }



     
    event StateChanged(IcoStates state);


     
    event Buy(address beneficiary, uint256 boughtTokens, uint256 ethValue);

     
    function RobomedIco() public {

         
         
         
        require(ADDR_OWNER != 0x0 && ADDR_OWNER != msg.sender);
        require(ADDR_WITHDRAWAL1 != 0x0 && ADDR_WITHDRAWAL1 != msg.sender);
        require(ADDR_WITHDRAWAL2 != 0x0 && ADDR_WITHDRAWAL2 != msg.sender);
        require(ADDR_BOUNTY_TOKENS_ACCOUNT != 0x0 && ADDR_BOUNTY_TOKENS_ACCOUNT != msg.sender);
        require(ADDR_TEAM_TOKENS_ACCOUNT != 0x0 && ADDR_TEAM_TOKENS_ACCOUNT != msg.sender);

        require(ADDR_BOUNTY_TOKENS_ACCOUNT != ADDR_TEAM_TOKENS_ACCOUNT);
        require(ADDR_OWNER != ADDR_TEAM_TOKENS_ACCOUNT);
        require(ADDR_OWNER != ADDR_BOUNTY_TOKENS_ACCOUNT);
        require(ADDR_WITHDRAWAL1 != ADDR_OWNER);
        require(ADDR_WITHDRAWAL1 != ADDR_BOUNTY_TOKENS_ACCOUNT);
        require(ADDR_WITHDRAWAL1 != ADDR_TEAM_TOKENS_ACCOUNT);
        require(ADDR_WITHDRAWAL2 != ADDR_OWNER);
        require(ADDR_WITHDRAWAL2 != ADDR_BOUNTY_TOKENS_ACCOUNT);
        require(ADDR_WITHDRAWAL2 != ADDR_TEAM_TOKENS_ACCOUNT);
        require(ADDR_WITHDRAWAL2 != ADDR_WITHDRAWAL1);

         
         
        owner = ADDR_OWNER;
        withdrawal1 = ADDR_WITHDRAWAL1;
        withdrawal2 = ADDR_WITHDRAWAL2;
        bountyTokensAccount = ADDR_BOUNTY_TOKENS_ACCOUNT;
        teamTokensAccount = ADDR_TEAM_TOKENS_ACCOUNT;

         
        balances[owner] = INITIAL_COINS_FOR_VIPPLACEMENT;
        balances[bountyTokensAccount] = EMISSION_FOR_BOUNTY;
        balances[teamTokensAccount] = EMISSION_FOR_TEAM;

         
        bountyTokensNotDistributed = EMISSION_FOR_BOUNTY;
        teamTokensNotDistributed = EMISSION_FOR_TEAM;
        vipPlacementNotDistributed = INITIAL_COINS_FOR_VIPPLACEMENT;

        currentState = IcoStates.VipPlacement;
        totalSupply = INITIAL_COINS_FOR_VIPPLACEMENT + EMISSION_FOR_BOUNTY + EMISSION_FOR_TEAM;

        endDateOfVipPlacement = now.add(DURATION_VIPPLACEMENT);
        remForSalesBeforeStageLast = 0;


         
        owner = msg.sender;
         
        transferTeam(0xa19DC4c158169bC45b17594d3F15e4dCb36CC3A3, TEAM_MEMBER_VAL);
         
        transferTeam(0xdf66490Fe9F2ada51967F71d6B5e26A9D77065ED, TEAM_MEMBER_VAL);
         
        transferTeam(0xf0215C6A553AD8E155Da69B2657BeaBC51d187c5, TEAM_MEMBER_VAL);
         
        transferTeam(0x6c1666d388302385AE5c62993824967a097F14bC, TEAM_MEMBER_VAL);
         
        transferTeam(0x82D550dC74f8B70B202aB5b63DAbe75E6F00fb36, TEAM_MEMBER_VAL);
        owner = ADDR_OWNER;
    }

     
    function name() public constant returns (string) {
        return name;
    }

     
    function symbol() public constant returns (string) {
        return symbol;
    }

     
    function decimals() public constant returns (uint8) {
        return decimals;
    }


     
    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }

     
    function teamBalanceOf(address _owner) public constant returns (uint256){
        return teamBalances[_owner];
    }

     
    function accrueTeamTokens() public afterIco {
         
        require(startDateOfUseTeamTokens <= now);

         
        totalSupply = totalSupply.add(teamBalances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].add(teamBalances[msg.sender]);
        teamBalances[msg.sender] = 0;
    }

     
    function canRestoreUnsoldTokens() public constant returns (bool) {
         
        if (currentState != IcoStates.PostIco) return false;

         
        if (startDateOfRestoreUnsoldTokens > now) return false;

         
        if (unsoldTokens == 0) return false;

        return true;
    }

     
    function restoreUnsoldTokens(address _to) public onlyOwner {
        require(_to != 0x0);
        require(canRestoreUnsoldTokens());

        balances[_to] = balances[_to].add(unsoldTokens);
        totalSupply = totalSupply.add(unsoldTokens);
        unsoldTokens = 0;
    }

     
    function gotoNextState() public onlyOwner returns (bool)  {

        if (gotoPreSale() || gotoSaleStage1() || gotoSaleStageLast() || gotoPostIco()) {
            return true;
        }
        return false;
    }


     
    function initWithdrawal(address _to, uint256 _value) public afterIco onlyWithdrawal1 {
        withdrawalTo = _to;
        withdrawalValue = _value;
    }

     
    function approveWithdrawal(address _to, uint256 _value) public afterIco onlyWithdrawal2 {
        require(_to != 0x0 && _value > 0);
        require(_to == withdrawalTo);
        require(_value == withdrawalValue);

        totalBalance = totalBalance.sub(_value);
        withdrawalTo.transfer(_value);

        withdrawalTo = 0x0;
        withdrawalValue = 0;
    }



     
    function canGotoState(IcoStates toState) public constant returns (bool){
        if (toState == IcoStates.PreSale) {
            return (currentState == IcoStates.VipPlacement && endDateOfVipPlacement <= now);
        }
        else if (toState == IcoStates.SaleStage1) {
            return (currentState == IcoStates.PreSale && endDateOfPreSale <= now);
        }
        else if (toState == IcoStates.SaleStage2) {
            return (currentState == IcoStates.SaleStage1 && freeMoney == 0 && startDateOfSaleStageLast > now);
        }
        else if (toState == IcoStates.SaleStage3) {
            return (currentState == IcoStates.SaleStage2 && freeMoney == 0 && startDateOfSaleStageLast > now);
        }
        else if (toState == IcoStates.SaleStage4) {
            return (currentState == IcoStates.SaleStage3 && freeMoney == 0 && startDateOfSaleStageLast > now);
        }
        else if (toState == IcoStates.SaleStage5) {
            return (currentState == IcoStates.SaleStage4 && freeMoney == 0 && startDateOfSaleStageLast > now);
        }
        else if (toState == IcoStates.SaleStage6) {
            return (currentState == IcoStates.SaleStage5 && freeMoney == 0 && startDateOfSaleStageLast > now);
        }
        else if (toState == IcoStates.SaleStage7) {
            return (currentState == IcoStates.SaleStage6 && freeMoney == 0 && startDateOfSaleStageLast > now);
        }
        else if (toState == IcoStates.SaleStageLast) {
             
            if (
            currentState != IcoStates.SaleStage1
            &&
            currentState != IcoStates.SaleStage2
            &&
            currentState != IcoStates.SaleStage3
            &&
            currentState != IcoStates.SaleStage4
            &&
            currentState != IcoStates.SaleStage5
            &&
            currentState != IcoStates.SaleStage6
            &&
            currentState != IcoStates.SaleStage7) return false;

             
             
            if (!(currentState == IcoStates.SaleStage7 && freeMoney == 0) && startDateOfSaleStageLast > now) {
                return false;
            }

            return true;
        }
        else if (toState == IcoStates.PostIco) {
            return (currentState == IcoStates.SaleStageLast && endDateOfSaleStageLast <= now);
        }
    }

     
    function() public payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(msg.value != 0);

         
        require(beneficiary != bountyTokensAccount && beneficiary != teamTokensAccount);

         
         
         
         
         
         
         
         
        uint256 remVal = msg.value;

         
        totalBalance = totalBalance.add(msg.value);

         
        uint256 boughtTokens = 0;

        while (remVal > 0) {
             
            require(
            currentState != IcoStates.VipPlacement
            &&
            currentState != IcoStates.PostIco);

             
             
            uint256 tokens = remVal.mul(rate);
            if (tokens > freeMoney) {
                remVal = remVal.sub(freeMoney.div(rate));
                tokens = freeMoney;
            }
            else
            {
                remVal = 0;
                 
                uint256 remFreeTokens = freeMoney.sub(tokens);
                if (0 < remFreeTokens && remFreeTokens < rate) {
                    tokens = freeMoney;
                }
            }
            assert(tokens > 0);

            freeMoney = freeMoney.sub(tokens);
            totalBought = totalBought.add(tokens);
            balances[beneficiary] = balances[beneficiary].add(tokens);
            boughtTokens = boughtTokens.add(tokens);

             
            if (
            uint(currentState) >= uint(IcoStates.SaleStage1)
            &&
            uint(currentState) <= uint(IcoStates.SaleStage7)) {

                 
                remForSalesBeforeStageLast = remForSalesBeforeStageLast.sub(tokens);

                 
                transitionBetweenSaleStages();
            }

        }

        Buy(beneficiary, boughtTokens, msg.value);

    }

     
    function transferBounty(address _to, uint256 _value) public onlyOwner {
         
        require(_to != 0x0 && _to != msg.sender);

         
        bountyTokensNotDistributed = bountyTokensNotDistributed.sub(_value);

         
        balances[_to] = balances[_to].add(_value);
        balances[bountyTokensAccount] = balances[bountyTokensAccount].sub(_value);

        Transfer(bountyTokensAccount, _to, _value);
    }

     
    function transferTeam(address _to, uint256 _value) public onlyOwner {
         
        require(_to != 0x0 && _to != msg.sender);

         
        teamTokensNotDistributed = teamTokensNotDistributed.sub(_value);

         
        teamBalances[_to] = teamBalances[_to].add(_value);
        balances[teamTokensAccount] = balances[teamTokensAccount].sub(_value);

         
        totalSupply = totalSupply.sub(_value);
    }

     
    function transfer(address _to, uint _value, bytes _data) checkForTransfer(msg.sender, _to, _value) public returns (bool) {

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }


     
    function transfer(address _to, uint _value) checkForTransfer(msg.sender, _to, _value) public returns (bool) {

         
         
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

     
    function isContract(address _addr) private view returns (bool) {
        uint length;
        assembly {
         
        length := extcodesize(_addr)
        }
        return (length > 0);
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool) {
        _transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        _transfer(msg.sender, _to, _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) private {
        require(balances[_from] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (currentState != IcoStates.PostIco) {
             
            vipPlacementNotDistributed = vipPlacementNotDistributed.sub(_value);
        }
    }




     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public afterIco returns (bool) {

        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public afterIco returns (bool) {
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function setMoney(uint256 _freeMoney, uint256 _emission, uint256 _rate) private {
        freeMoney = _freeMoney;
        totalSupply = totalSupply.add(_emission);
        rate = _rate;
    }

     
    function gotoPreSale() private returns (bool) {

         
        if (!canGotoState(IcoStates.PreSale)) return false;

         

         
        currentState = IcoStates.PreSale;


         
        setMoney(EMISSION_FOR_PRESALE, EMISSION_FOR_PRESALE, RATE_PRESALE);

         
        endDateOfPreSale = now.add(DURATION_PRESALE);

         
        StateChanged(IcoStates.PreSale);
        return true;
    }

     
    function gotoSaleStage1() private returns (bool) {
         
        if (!canGotoState(IcoStates.SaleStage1)) return false;

         

         
        currentState = IcoStates.SaleStage1;

         
        totalSupply = totalSupply.sub(freeMoney);

         
        setMoney(EMISSION_FOR_SALESTAGE1, EMISSION_FOR_SALESTAGE1, RATE_SALESTAGE1);

         
        remForSalesBeforeStageLast =
        EMISSION_FOR_SALESTAGE1 +
        EMISSION_FOR_SALESTAGE2 +
        EMISSION_FOR_SALESTAGE3 +
        EMISSION_FOR_SALESTAGE4 +
        EMISSION_FOR_SALESTAGE5 +
        EMISSION_FOR_SALESTAGE6 +
        EMISSION_FOR_SALESTAGE7;


         
        startDateOfSaleStageLast = now.add(DURATION_SALESTAGES);

         
        StateChanged(IcoStates.SaleStage1);
        return true;
    }

     
    function transitionBetweenSaleStages() private {
         
        if (
        currentState != IcoStates.SaleStage1
        &&
        currentState != IcoStates.SaleStage2
        &&
        currentState != IcoStates.SaleStage3
        &&
        currentState != IcoStates.SaleStage4
        &&
        currentState != IcoStates.SaleStage5
        &&
        currentState != IcoStates.SaleStage6
        &&
        currentState != IcoStates.SaleStage7) return;

         
        if (gotoSaleStageLast()) {
            return;
        }

         
        if (canGotoState(IcoStates.SaleStage2)) {
            currentState = IcoStates.SaleStage2;
            setMoney(EMISSION_FOR_SALESTAGE2, EMISSION_FOR_SALESTAGE2, RATE_SALESTAGE2);
            StateChanged(IcoStates.SaleStage2);
        }
        else if (canGotoState(IcoStates.SaleStage3)) {
            currentState = IcoStates.SaleStage3;
            setMoney(EMISSION_FOR_SALESTAGE3, EMISSION_FOR_SALESTAGE3, RATE_SALESTAGE3);
            StateChanged(IcoStates.SaleStage3);
        }
        else if (canGotoState(IcoStates.SaleStage4)) {
            currentState = IcoStates.SaleStage4;
            setMoney(EMISSION_FOR_SALESTAGE4, EMISSION_FOR_SALESTAGE4, RATE_SALESTAGE4);
            StateChanged(IcoStates.SaleStage4);
        }
        else if (canGotoState(IcoStates.SaleStage5)) {
            currentState = IcoStates.SaleStage5;
            setMoney(EMISSION_FOR_SALESTAGE5, EMISSION_FOR_SALESTAGE5, RATE_SALESTAGE5);
            StateChanged(IcoStates.SaleStage5);
        }
        else if (canGotoState(IcoStates.SaleStage6)) {
            currentState = IcoStates.SaleStage6;
            setMoney(EMISSION_FOR_SALESTAGE6, EMISSION_FOR_SALESTAGE6, RATE_SALESTAGE6);
            StateChanged(IcoStates.SaleStage6);
        }
        else if (canGotoState(IcoStates.SaleStage7)) {
            currentState = IcoStates.SaleStage7;
            setMoney(EMISSION_FOR_SALESTAGE7, EMISSION_FOR_SALESTAGE7, RATE_SALESTAGE7);
            StateChanged(IcoStates.SaleStage7);
        }
    }

     
    function gotoSaleStageLast() private returns (bool) {
        if (!canGotoState(IcoStates.SaleStageLast)) return false;

         
        currentState = IcoStates.SaleStageLast;

         
        setMoney(remForSalesBeforeStageLast + EMISSION_FOR_SALESTAGELAST, EMISSION_FOR_SALESTAGELAST, RATE_SALESTAGELAST);


         
        endDateOfSaleStageLast = now.add(DURATION_SALESTAGELAST);

        StateChanged(IcoStates.SaleStageLast);
        return true;
    }



     
    function gotoPostIco() private returns (bool) {
        if (!canGotoState(IcoStates.PostIco)) return false;

         
        currentState = IcoStates.PostIco;

         
        startDateOfUseTeamTokens = now + DURATION_NONUSETEAM;

         
        startDateOfRestoreUnsoldTokens = now + DURATION_BEFORE_RESTORE_UNSOLD;

         
        unsoldTokens = freeMoney;

         
        totalSupply = totalSupply.sub(freeMoney);
        setMoney(0, 0, 0);

        StateChanged(IcoStates.PostIco);
        return true;
    }


}