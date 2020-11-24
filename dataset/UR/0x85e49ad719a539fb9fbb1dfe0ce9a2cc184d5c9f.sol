 

pragma solidity ^0.4.13;

contract ERC20Basic {

  function balanceOf(address who) public constant returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

}

contract ERC20 is ERC20Basic {

  function allowance(address owner, address spender) public constant returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract ERC223 is ERC20 {



    function name() constant returns (string _name);

    function symbol() constant returns (string _symbol);

    function decimals() constant returns (uint8 _decimals);



    function transfer(address to, uint256 value, bytes data) returns (bool);



}

contract ERC223ReceivingContract {

    function tokenFallback(address _from, uint256 _value, bytes _data);

}

contract KnowledgeTokenInterface is ERC223{

    event Mint(address indexed to, uint256 amount);



    function changeMinter(address newAddress) returns (bool);

    function mint(address _to, uint256 _amount) returns (bool);

}

contract Ownable {

  address public owner;





  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





   

  function Ownable() {

    owner = msg.sender;

  }





   

  modifier onlyOwner() {

    require(msg.sender == owner);

    _;

  }





   

  function transferOwnership(address newOwner) onlyOwner public {

    require(newOwner != address(0));

    OwnershipTransferred(owner, newOwner);

    owner = newOwner;

  }



}

library SafeMath {

  function mul(uint256 a, uint256 b) internal constant returns (uint256) {

    uint256 c = a * b;

    assert(a == 0 || c / a == b);

    return c;

  }



  function div(uint256 a, uint256 b) internal constant returns (uint256) {

     

    uint256 c = a / b;

     

    return c;

  }



  function sub(uint256 a, uint256 b) internal constant returns (uint256) {

    assert(b <= a);

    return a - b;

  }



  function add(uint256 a, uint256 b) internal constant returns (uint256) {

    uint256 c = a + b;

    assert(c >= a);

    return c;

  }

}

contract WitcoinCrowdsale is Ownable {

    using SafeMath for uint256;



     

    WitCoin public token;



     

    RefundVault public vault;



     

    uint256 public goal;



     

    uint256 public startTime;

    uint256 public startPresale;

    uint256 public endTime;

    uint256 public endRefundingingTime;



     

    address public wallet;



     

    uint256 public rate;



     

    uint256 public weiRaised;



     

    uint256 public tokensSold;



     

    uint256 public tokensDistributed;



     

    uint256 public decimals;



     

    uint256 public totalTokensPresale;



     

    uint256 public totalTokensSale;



     

    uint256 public minimumWitcoins;



     

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);



    function WitcoinCrowdsale(address witAddress, address receiver) {

        token = WitCoin(witAddress);

        decimals = token.decimals();

        startTime = 1508137200;  

        startPresale = 1507618800;  

        endTime = 1509973200;  

        endRefundingingTime = 1527840776;  

        rate = 880;  

        wallet = receiver;

        goal = 1000000 * (10 ** decimals);  



        totalTokensPresale = 1000000 * (10 ** decimals) * 65 / 100;  

        totalTokensSale = 8000000 * (10 ** decimals) * 65 / 100;  

        minimumWitcoins = 100 * (10 ** decimals);  

        tokensDistributed = 0;



        vault = new RefundVault(wallet);

    }



     

    function () payable {

        buyTokens(msg.sender);

    }



     

    function buyTokens(address beneficiary) public payable {

        require(beneficiary != 0x0);



        uint256 weiAmount = msg.value;



         

        uint256 tokens = weiAmount.mul(rate)/1000000000000000000;

        tokens = tokens * (10 ** decimals);



         

        tokens = calculateBonus(tokens);



        require(validPurchase(tokens));



         

        weiRaised = weiRaised.add(weiAmount);

        tokensSold = tokensSold.add(tokens);



        token.mint(beneficiary, tokens);

        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);



        forwardFunds();

    }



     

    function buyTokensAltercoins(address beneficiary, uint256 tokens) onlyOwner public {

        require(beneficiary != 0x0);



         

        uint256 tokensBonused = calculateBonus(tokens);



        require(validPurchase(tokensBonused));



         

        tokensSold = tokensSold.add(tokensBonused);



        token.mint(beneficiary, tokensBonused);

        TokenPurchase(msg.sender, beneficiary, 0, tokensBonused);

    }



     

    function forwardFunds() internal {

        vault.deposit.value(msg.value)(msg.sender);

    }



     

    function calculateBonus(uint256 tokens) internal returns (uint256) {

        uint256 bonusedTokens = tokens;



         

        if (presale()) {

            if (tokensSold <= 250000 * (10 ** decimals)) bonusedTokens = bonusedTokens.mul(130)/100;

            else if (tokensSold <= 500000 * (10 ** decimals)) bonusedTokens = bonusedTokens.mul(125)/100;

            else if (tokensSold <= 750000 * (10 ** decimals)) bonusedTokens = bonusedTokens.mul(120)/100;

            else if (tokensSold <= 1000000 * (10 ** decimals)) bonusedTokens = bonusedTokens.mul(115)/100;

        }



         

        if (sale()) {

            if (bonusedTokens > 2500 * (10 ** decimals)) {

                if (bonusedTokens <= 80000 * (10 ** decimals)) bonusedTokens = bonusedTokens.mul(105)/100;

                else if (bonusedTokens <= 800000 * (10 ** decimals)) bonusedTokens = bonusedTokens.mul(110)/100;

                else if (bonusedTokens > 800000 * (10 ** decimals)) bonusedTokens = bonusedTokens.mul(120)/100;

            }

        }



        return bonusedTokens;

    }



     

    function validPurchase(uint256 tokens) internal returns (bool) {

        bool withinPeriod = presale() || sale();

        bool underLimits = (presale() && tokensSold + tokens <= totalTokensPresale) || (sale() && tokensSold + tokens <= totalTokensSale);

        bool overMinimum = tokens >= minimumWitcoins;

        return withinPeriod && underLimits && overMinimum;

    }



    function validPurchaseBonus(uint256 tokens) public returns (bool) {

        uint256 bonusedTokens = calculateBonus(tokens);

        return validPurchase(bonusedTokens);

    }



     

    function presale() public returns(bool) {

        return now >= startPresale && now < startTime;

    }



     

    function sale() public returns(bool) {

        return now >= startTime && now <= endTime;

    }



     

    function finalize() onlyOwner public {

        require(now > endTime);



        if (tokensSold < goal) {

            vault.enableRefunds();

        } else {

            vault.close();

        }

    }



    function finalized() public returns(bool) {

        return vault.finalized();

    }



     

    function claimRefund() public returns(bool) {

        vault.refund(msg.sender);

    }



    function finalizeRefunding() onlyOwner public {

        require(now > endRefundingingTime);



        vault.finalizeEnableRefunds();

    }



     

     

     

     

     

     

    function distributeTokens() onlyOwner public {

        require(tokensSold >= goal);

        require(tokensSold - tokensDistributed > 100);



        uint256 toDistribute = tokensSold - tokensDistributed;



        address bounties = 0x057Afd5422524d5Ca20218d07048300832323360;

        address nirvana = 0x094d57AdaBa2278de6D1f3e2F975f14248C3775F;

        address team = 0x7eC9d37163F4F1D1fD7E92B79B73d910088Aa2e7;

        address club = 0xb2c032aF1336A1482eB2FE1815Ef301A2ea4fE0A;



        uint256 bTokens = toDistribute * 1 / 65;

        uint256 nTokens = toDistribute * 5 / 65;

        uint256 tTokens = toDistribute * 10 / 65;

        uint256 cTokens = toDistribute * 19 / 65;



        token.mint(bounties, bTokens);

        token.mint(nirvana, nTokens);

        token.mint(team, tTokens);

        token.mint(club, cTokens);



        tokensDistributed = tokensDistributed.add(toDistribute);

    }



}

contract RefundVault is Ownable {

  using SafeMath for uint256;



  enum State { Active, Refunding, Closed }



  mapping (address => uint256) public deposited;

  address public wallet;

  State public state;



  event Closed();

  event RefundsEnabled();

  event Refunded(address indexed beneficiary, uint256 weiAmount);



  function RefundVault(address _wallet) {

    require(_wallet != 0x0);



    wallet = _wallet;

    state = State.Active;

  }



  function deposit(address investor) onlyOwner public payable {

    require(state == State.Active);

    deposited[investor] = deposited[investor].add(msg.value);

  }



  function close() onlyOwner public {

    require(state == State.Active);



    state = State.Closed;

    Closed();

    wallet.transfer(this.balance);

  }



  function enableRefunds() onlyOwner public {

    require(state == State.Active);



    state = State.Refunding;

    RefundsEnabled();

  }



  function finalizeEnableRefunds() onlyOwner public {

    require(state == State.Refunding);

    state = State.Closed;

    Closed();

    wallet.transfer(this.balance);

  }



  function refund(address investor) onlyOwner public {

    require(state == State.Refunding);



    uint256 depositedValue = deposited[investor];

    deposited[investor] = 0;

    investor.transfer(depositedValue);

    Refunded(investor, depositedValue);

  }



  function finalized() public returns(bool) {

    return state != State.Active;

  }

}

contract ERC20BasicToken is ERC20Basic {

  using SafeMath for uint256;



  mapping(address => uint256) balances;

  uint256 public totalSupply;



   

  function transfer(address _to, uint256 _value) public returns (bool) {

    require(_to != address(0));



     

    balances[msg.sender] = balances[msg.sender].sub(_value);

    balances[_to] = balances[_to].add(_value);

    Transfer(msg.sender, _to, _value);

    return true;

  }



   

  function balanceOf(address _owner) public constant returns (uint256 balance) {

    return balances[_owner];

  }



  function totalSupply() constant returns (uint256 _totalSupply) {

    return totalSupply;

  }



}

contract ERC20Token is ERC20, ERC20BasicToken {



  mapping (address => mapping (address => uint256)) allowed;



   

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

    require(_to != address(0));



    uint256 _allowance = allowed[_from][msg.sender];



     

     



    balances[_from] = balances[_from].sub(_value);

    balances[_to] = balances[_to].add(_value);

    allowed[_from][msg.sender] = _allowance.sub(_value);

    Transfer(_from, _to, _value);

    return true;

  }



   

  function approve(address _spender, uint256 _value) public returns (bool) {

    allowed[msg.sender][_spender] = _value;

    Approval(msg.sender, _spender, _value);

    return true;

  }



   

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {

    return allowed[_owner][_spender];

  }



   

  function increaseApproval (address _spender, uint _addedValue)

    returns (bool success) {

    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;

  }



  function decreaseApproval (address _spender, uint _subtractedValue)

    returns (bool success) {

    uint oldValue = allowed[msg.sender][_spender];

    if (_subtractedValue > oldValue) {

      allowed[msg.sender][_spender] = 0;

    } else {

      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

    }

    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;

  }



}

contract ERC223Token is ERC223, ERC20Token {

    using SafeMath for uint256;



    string public name;



    string public symbol;



    uint8 public decimals;





     

    function name() constant returns (string _name) {

        return name;

    }

     

    function symbol() constant returns (string _symbol) {

        return symbol;

    }

     

    function decimals() constant returns (uint8 _decimals) {

        return decimals;

    }





     

    function transfer(address _to, uint256 _value, bytes _data) returns (bool success) {

        if (isContract(_to)) {

            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);

            receiver.tokenFallback(msg.sender, _value, _data);

        }

        return super.transfer(_to, _value);

    }



     

     

    function transfer(address _to, uint256 _value) returns (bool success) {

        if (isContract(_to)) {

            bytes memory empty;

            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);

            receiver.tokenFallback(msg.sender, _value, empty);

        }

        return super.transfer(_to, _value);

    }



     

    function isContract(address _addr) private returns (bool is_contract) {

        uint length;

        assembly {

            length := extcodesize(_addr)

        }

        return (length > 0);

    }



}

contract KnowledgeToken is KnowledgeTokenInterface, Ownable, ERC223Token {



    address public minter;



    modifier onlyMinter() {

         

        require (msg.sender == minter);

        _;

    }



    function mint(address _to, uint256 _amount) onlyMinter public returns (bool) {

        totalSupply = totalSupply.add(_amount);

        balances[_to] = balances[_to].add(_amount);

        Transfer(0x0, _to, _amount);

        Mint(_to, _amount);

        return true;

    }



    function changeMinter(address newAddress) public onlyOwner returns (bool)

    {

        minter = newAddress;

    }

}

contract WitCoin is KnowledgeToken{



    function WitCoin() {

        totalSupply = 0;

        name = "Witcoin";

        symbol = "WIT";

        decimals = 8;

    }



}