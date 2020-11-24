 

pragma solidity ^0.4.13;

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

contract ArgumentsChecker {

     
    modifier payloadSizeIs(uint size) {
       require(msg.data.length == size + 4  );
       _;
    }

     
    modifier validAddress(address addr) {
        require(addr != address(0));
        _;
    }
}

contract ReentrancyGuard {

   
  bool private rentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }

}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract CrowdsaleBase is ArgumentsChecker, ReentrancyGuard {
    using SafeMath for uint256;

    event FundTransfer(address backer, uint amount, bool isContribution);

    function CrowdsaleBase(address owner80, address owner20, string token_name, string token_symbol)
        public
    {
        m_funds = new LightFundsRegistry(owner80, owner20);
        m_token = new TokenBase(token_name, token_symbol);

        assert(! hasHardCap() || getMaximumFunds() >= getMinimumFunds());
    }


     

     
    function()
        public
        payable
    {
        require(0 == msg.data.length);
        buy();   
    }

     
    function buy()
        public   
        payable
    {
        buyInternal(msg.sender, msg.value);
    }


     
    function withdrawPayments()
        external
    {
        m_funds.withdrawPayments(msg.sender);
    }


     

     
    function buyInternal(address investor, uint payment)
        internal
        nonReentrant
    {
        require(payment >= getMinInvestment());
        if (getCurrentTime() >= getEndTime())
            finish();

        if (m_finished) {
             
            investor.transfer(payment);
            return;
        }

        uint startingWeiCollected = getWeiCollected();
        uint startingInvariant = this.balance.add(startingWeiCollected);

        uint change;
        if (hasHardCap()) {
             
            uint paymentAllowed = getMaximumFunds().sub(getWeiCollected());
            assert(0 != paymentAllowed);

            if (paymentAllowed < payment) {
                change = payment.sub(paymentAllowed);
                payment = paymentAllowed;
            }
        }

         
        require(m_token.mint(investor, calculateTokens(payment)));

         
        m_funds.invested.value(payment)(investor);

        assert((!hasHardCap() || getWeiCollected() <= getMaximumFunds()) && getWeiCollected() > startingWeiCollected);
        FundTransfer(investor, payment, true);

        if (hasHardCap() && getWeiCollected() == getMaximumFunds())
            finish();

        if (change > 0)
            investor.transfer(change);

        assert(startingInvariant == this.balance.add(getWeiCollected()).add(change));
    }

    function finish() internal {
        if (m_finished)
            return;

        if (getWeiCollected() >= getMinimumFunds()) {
             
            m_funds.changeState(LightFundsRegistry.State.SUCCEEDED);
            m_token.ICOSuccess();
        }
        else {
             
            m_funds.changeState(LightFundsRegistry.State.REFUNDING);
        }

        m_finished = true;
    }


     
    function hasHardCap() internal constant returns (bool) {
        return getMaximumFunds() != 0;
    }

     
    function getCurrentTime() internal constant returns (uint) {
        return now;
    }

     
    function getMaximumFunds() internal constant returns (uint) {
        return euroCents2wei(getMaximumFundsInEuroCents());
    }

     
    function getMinimumFunds() internal constant returns (uint) {
        return euroCents2wei(getMinimumFundsInEuroCents());
    }

     
    function getEndTime() public pure returns (uint) {
        return 1521331200;
    }

     
    function getMinInvestment() public pure returns (uint) {
        return 10 finney;
    }

     
    function tokenWeiInToken() internal constant returns (uint) {
        return uint(10) ** uint(m_token.decimals());
    }

     
    function calculateTokens(uint payment) internal constant returns (uint) {
        return wei2euroCents(payment).mul(tokenWeiInToken()).div(tokenPriceInEuroCents());
    }


     

    function wei2euroCents(uint wei_) public view returns (uint) {
        return wei_.mul(euroCentsInOneEther()).div(1 ether);
    }


    function euroCents2wei(uint euroCents) public view returns (uint) {
        return euroCents.mul(1 ether).div(euroCentsInOneEther());
    }


     

     
    function getEuroCollected() public constant returns (uint) {
        return wei2euroCents(getWeiCollected()).div(100);
    }

     
    function getWeiCollected() public constant returns (uint) {
        return m_funds.totalInvested();
    }

     
    function getTokenMinted() public constant returns (uint) {
        return m_token.totalSupply();
    }


     

     
    function getMaximumFundsInEuroCents() public constant returns (uint);

     
    function getMinimumFundsInEuroCents() public constant returns (uint);

     
    function euroCentsInOneEther() public constant returns (uint);

     
    function tokenPriceInEuroCents() public constant returns (uint);


     

     
    LightFundsRegistry public m_funds;

     
    TokenBase public m_token;

    bool m_finished = false;
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract CirculatingToken is StandardToken {

    event CirculationEnabled();

    modifier requiresCirculation {
        require(m_isCirculating);
        _;
    }


     

    function transfer(address _to, uint256 _value) requiresCirculation returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) requiresCirculation returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) requiresCirculation returns (bool) {
        return super.approve(_spender, _value);
    }


     

    function enableCirculation() internal returns (bool) {
        if (m_isCirculating)
            return false;

        m_isCirculating = true;
        CirculationEnabled();
        return true;
    }


     

     
    bool public m_isCirculating;
}

contract TokenBase is MintableToken, CirculatingToken {

    event Burn(address indexed from, uint256 amount);


    string m_name;
    string m_symbol;
    uint8 public constant decimals = 18;


    function TokenBase(string _name, string _symbol) public {
        require(bytes(_name).length > 0 && bytes(_name).length <= 32);
        require(bytes(_symbol).length > 0 && bytes(_symbol).length <= 32);

        m_name = _name;
        m_symbol = _symbol;
    }


    function burn(uint256 _amount) external returns (bool) {
        address _from = msg.sender;
        require(_amount>0);
        require(_amount<=balances[_from]);

        totalSupply = totalSupply.sub(_amount);
        balances[_from] = balances[_from].sub(_amount);
        Burn(_from, _amount);
        Transfer(_from, address(0), _amount);

        return true;
    }


    function name() public view returns (string) {
        return m_name;
    }

    function symbol() public view returns (string) {
        return m_symbol;
    }


    function ICOSuccess()
        external
        onlyOwner
    {
        assert(finishMinting());
        assert(enableCirculation());
    }
}

contract LightFundsRegistry is ArgumentsChecker, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    enum State {
         
        GATHERING,
         
        REFUNDING,
         
        SUCCEEDED
    }

    event StateChanged(State _state);
    event Invested(address indexed investor, uint256 amount);
    event EtherSent(address indexed to, uint value);
    event RefundSent(address indexed to, uint value);


    modifier requiresState(State _state) {
        require(m_state == _state);
        _;
    }


     

    function LightFundsRegistry(address owner80, address owner20)
        public
        validAddress(owner80)
        validAddress(owner20)
    {
        m_owner80 = owner80;
        m_owner20 = owner20;
    }

     
    function changeState(State _newState)
        external
        onlyOwner
    {
        assert(m_state != _newState);

        if (State.GATHERING == m_state) {   assert(State.REFUNDING == _newState || State.SUCCEEDED == _newState); }
        else assert(false);

        m_state = _newState;
        StateChanged(m_state);

        if (State.SUCCEEDED == _newState) {
            uint _80percent = this.balance.mul(80).div(100);
            m_owner80.transfer(_80percent);
            EtherSent(m_owner80, _80percent);

            uint _20percent = this.balance;
            m_owner20.transfer(_20percent);
            EtherSent(m_owner20, _20percent);
        }
    }

     
    function invested(address _investor)
        external
        payable
        onlyOwner
        requiresState(State.GATHERING)
    {
        uint256 amount = msg.value;
        require(0 != amount);

         
        if (0 == m_weiBalances[_investor])
            m_investors.push(_investor);

         
        totalInvested = totalInvested.add(amount);
        m_weiBalances[_investor] = m_weiBalances[_investor].add(amount);

        Invested(_investor, amount);
    }

     
    function withdrawPayments(address payee)
        external
        nonReentrant
        onlyOwner
        requiresState(State.REFUNDING)
    {
        uint256 payment = m_weiBalances[payee];

        require(payment != 0);
        require(this.balance >= payment);

        totalInvested = totalInvested.sub(payment);
        m_weiBalances[payee] = 0;

        payee.transfer(payment);
        RefundSent(payee, payment);
    }

    function getInvestorsCount() external view returns (uint) { return m_investors.length; }


     

     
    uint256 public totalInvested;

     
    State public m_state = State.GATHERING;

     
    mapping(address => uint256) public m_weiBalances;

     
    address[] public m_investors;

    address public m_owner80;
    address public m_owner20;
}

contract EESTSale is CrowdsaleBase {

    function EESTSale() public
        CrowdsaleBase(
              address(0xd9ab6c63ae5dc8b4d766352b9f666f6e02dba26e),
              address(0xa46e5704057f9432d10919196c3c671cfafa2030),
            "Electronic exchange sign-token", "EEST")
    {
    }


     
    function getMaximumFundsInEuroCents() public constant returns (uint) {
        return 36566900000;
    }

     
    function getMinimumFundsInEuroCents() public constant returns (uint) {
        return 36566900000;
    }

     
    function euroCentsInOneEther() public constant returns (uint) {
        return 58000;
    }

     
    function tokenPriceInEuroCents() public constant returns (uint) {
        return 1000;
    }
}