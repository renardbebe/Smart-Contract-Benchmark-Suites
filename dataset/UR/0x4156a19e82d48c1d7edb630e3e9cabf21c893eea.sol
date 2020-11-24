 

pragma solidity 0.4.15;

 
 

 
 
 
 
 
 
 
 



 
 
contract multiowned {

	 

     
    struct MultiOwnedOperationPendingState {
         
        uint yetNeeded;

         
        uint ownersDone;

         
        uint index;
    }

	 

    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    event FinalConfirmation(address owner, bytes32 operation);

     
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);

     
    event RequirementChanged(uint newRequirement);

	 

     
    modifier onlyowner {
        require(isOwner(msg.sender));
        _;
    }
     
     
     
    modifier onlymanyowners(bytes32 _operation) {
        if (confirmAndCheck(_operation)) {
            _;
        }
         
         
         
    }

    modifier validNumOwners(uint _numOwners) {
        require(_numOwners > 0 && _numOwners <= c_maxOwners);
        _;
    }

    modifier multiOwnedValidRequirement(uint _required, uint _numOwners) {
        require(_required > 0 && _required <= _numOwners);
        _;
    }

    modifier ownerExists(address _address) {
        require(isOwner(_address));
        _;
    }

    modifier ownerDoesNotExist(address _address) {
        require(!isOwner(_address));
        _;
    }

    modifier multiOwnedOperationIsActive(bytes32 _operation) {
        require(isOperationActive(_operation));
        _;
    }

	 

     
     
    function multiowned(address[] _owners, uint _required)
        validNumOwners(_owners.length)
        multiOwnedValidRequirement(_required, _owners.length)
    {
        assert(c_maxOwners <= 255);

        m_numOwners = _owners.length;
        m_multiOwnedRequired = _required;

        for (uint i = 0; i < _owners.length; ++i)
        {
            address owner = _owners[i];
             
            require(0 != owner && !isOwner(owner)  );

            uint currentOwnerIndex = checkOwnerIndex(i + 1  );
            m_owners[currentOwnerIndex] = owner;
            m_ownerIndex[owner] = currentOwnerIndex;
        }

        assertOwnersAreConsistent();
    }

     
     
     
     
    function changeOwner(address _from, address _to)
        external
        ownerExists(_from)
        ownerDoesNotExist(_to)
        onlymanyowners(sha3(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[_from]);
        m_owners[ownerIndex] = _to;
        m_ownerIndex[_from] = 0;
        m_ownerIndex[_to] = ownerIndex;

        assertOwnersAreConsistent();
        OwnerChanged(_from, _to);
    }

     
     
     
    function addOwner(address _owner)
        external
        ownerDoesNotExist(_owner)
        validNumOwners(m_numOwners + 1)
        onlymanyowners(sha3(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        m_numOwners++;
        m_owners[m_numOwners] = _owner;
        m_ownerIndex[_owner] = checkOwnerIndex(m_numOwners);

        assertOwnersAreConsistent();
        OwnerAdded(_owner);
    }

     
     
     
    function removeOwner(address _owner)
        external
        ownerExists(_owner)
        validNumOwners(m_numOwners - 1)
        multiOwnedValidRequirement(m_multiOwnedRequired, m_numOwners - 1)
        onlymanyowners(sha3(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[_owner]);
        m_owners[ownerIndex] = 0;
        m_ownerIndex[_owner] = 0;
         
        reorganizeOwners();

        assertOwnersAreConsistent();
        OwnerRemoved(_owner);
    }

     
     
     
    function changeRequirement(uint _newRequired)
        external
        multiOwnedValidRequirement(_newRequired, m_numOwners)
        onlymanyowners(sha3(msg.data))
    {
        m_multiOwnedRequired = _newRequired;
        clearPending();
        RequirementChanged(_newRequired);
    }

     
     
    function getOwner(uint ownerIndex) public constant returns (address) {
        return m_owners[ownerIndex + 1];
    }

     
     
    function getOwners() public constant returns (address[]) {
        address[] memory result = new address[](m_numOwners);
        for (uint i = 0; i < m_numOwners; i++)
            result[i] = getOwner(i);

        return result;
    }

     
     
     
    function isOwner(address _addr) public constant returns (bool) {
        return m_ownerIndex[_addr] > 0;
    }

     
     
     
     
    function amIOwner() external constant onlyowner returns (bool) {
        return true;
    }

     
     
    function revoke(bytes32 _operation)
        external
        multiOwnedOperationIsActive(_operation)
        onlyowner
    {
        uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
        var pending = m_multiOwnedPending[_operation];
        require(pending.ownersDone & ownerIndexBit > 0);

        assertOperationIsConsistent(_operation);

        pending.yetNeeded++;
        pending.ownersDone -= ownerIndexBit;

        assertOperationIsConsistent(_operation);
        Revoke(msg.sender, _operation);
    }

     
     
     
    function hasConfirmed(bytes32 _operation, address _owner)
        external
        constant
        multiOwnedOperationIsActive(_operation)
        ownerExists(_owner)
        returns (bool)
    {
        return !(m_multiOwnedPending[_operation].ownersDone & makeOwnerBitmapBit(_owner) == 0);
    }

     

    function confirmAndCheck(bytes32 _operation)
        private
        onlyowner
        returns (bool)
    {
        if (512 == m_multiOwnedPendingIndex.length)
             
             
             
             
            clearPending();

        var pending = m_multiOwnedPending[_operation];

         
        if (! isOperationActive(_operation)) {
             
            pending.yetNeeded = m_multiOwnedRequired;
             
            pending.ownersDone = 0;
            pending.index = m_multiOwnedPendingIndex.length++;
            m_multiOwnedPendingIndex[pending.index] = _operation;
            assertOperationIsConsistent(_operation);
        }

         
        uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
         
        if (pending.ownersDone & ownerIndexBit == 0) {
             
            assert(pending.yetNeeded > 0);
            if (pending.yetNeeded == 1) {
                 
                delete m_multiOwnedPendingIndex[m_multiOwnedPending[_operation].index];
                delete m_multiOwnedPending[_operation];
                FinalConfirmation(msg.sender, _operation);
                return true;
            }
            else
            {
                 
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
                assertOperationIsConsistent(_operation);
                Confirmation(msg.sender, _operation);
            }
        }
    }

     
     
    function reorganizeOwners() private {
        uint free = 1;
        while (free < m_numOwners)
        {
             
            while (free < m_numOwners && m_owners[free] != 0) free++;

             
            while (m_numOwners > 1 && m_owners[m_numOwners] == 0) m_numOwners--;

             
            if (free < m_numOwners && m_owners[m_numOwners] != 0 && m_owners[free] == 0)
            {
                 
                m_owners[free] = m_owners[m_numOwners];
                m_ownerIndex[m_owners[free]] = free;
                m_owners[m_numOwners] = 0;
            }
        }
    }

    function clearPending() private onlyowner {
        uint length = m_multiOwnedPendingIndex.length;
        for (uint i = 0; i < length; ++i) {
            if (m_multiOwnedPendingIndex[i] != 0)
                delete m_multiOwnedPending[m_multiOwnedPendingIndex[i]];
        }
        delete m_multiOwnedPendingIndex;
    }

    function checkOwnerIndex(uint ownerIndex) private constant returns (uint) {
        assert(0 != ownerIndex && ownerIndex <= c_maxOwners);
        return ownerIndex;
    }

    function makeOwnerBitmapBit(address owner) private constant returns (uint) {
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[owner]);
        return 2 ** ownerIndex;
    }

    function isOperationActive(bytes32 _operation) private constant returns (bool) {
        return 0 != m_multiOwnedPending[_operation].yetNeeded;
    }


    function assertOwnersAreConsistent() private constant {
        assert(m_numOwners > 0);
        assert(m_numOwners <= c_maxOwners);
        assert(m_owners[0] == 0);
        assert(0 != m_multiOwnedRequired && m_multiOwnedRequired <= m_numOwners);
    }

    function assertOperationIsConsistent(bytes32 _operation) private constant {
        var pending = m_multiOwnedPending[_operation];
        assert(0 != pending.yetNeeded);
        assert(m_multiOwnedPendingIndex[pending.index] == _operation);
        assert(pending.yetNeeded <= m_multiOwnedRequired);
    }


   	 

    uint constant c_maxOwners = 250;

     
    uint public m_multiOwnedRequired;


     
    uint public m_numOwners;

     
     
     
    address[256] internal m_owners;

     
    mapping(address => uint) internal m_ownerIndex;


     
    mapping(bytes32 => MultiOwnedOperationPendingState) internal m_multiOwnedPending;
    bytes32[] internal m_multiOwnedPendingIndex;
}


library FixedTimeBonuses {

    struct Bonus {
        uint endTime;
        uint bonus;
    }

    struct Data {
        Bonus[] bonuses;
    }

     
     
     
    function validate(Data storage self, bool shouldDecrease) constant {
        uint length = self.bonuses.length;
        require(length > 0);

        Bonus storage last = self.bonuses[0];
        for (uint i = 1; i < length; i++) {
            Bonus storage current = self.bonuses[i];
            require(current.endTime > last.endTime);
            if (shouldDecrease)
                require(current.bonus < last.bonus);
            last = current;
        }
    }

     
     
    function getLastTime(Data storage self) constant returns (uint) {
        return self.bonuses[self.bonuses.length - 1].endTime;
    }

     
     
     
    function getBonus(Data storage self, uint time) constant returns (uint) {
         
        uint length = self.bonuses.length;
        for (uint i = 0; i < length; i++) {
            if (self.bonuses[i].endTime >= time)
                return self.bonuses[i].bonus;
        }
        assert(false);   
    }
}



 
contract MultiownedControlled is multiowned {

    event ControllerSet(address controller);
    event ControllerRetired(address was);


    modifier onlyController {
        require(msg.sender == m_controller);
        _;
    }


     

    function MultiownedControlled(address[] _owners, uint _signaturesRequired, address _controller)
        multiowned(_owners, _signaturesRequired)
    {
        m_controller = _controller;
        ControllerSet(m_controller);
    }

     
    function setController(address _controller) external onlymanyowners(sha3(msg.data)) {
        m_controller = _controller;
        ControllerSet(m_controller);
    }

     
    function detachController() external onlyController {
        address was = m_controller;
        m_controller = address(0);
        ControllerRetired(was);
    }


     

     
    address public m_controller;
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

 
contract ReentrancyGuard {

   
  bool private rentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }

}



 
contract FundsRegistry is MultiownedControlled, ReentrancyGuard {
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


     

    function FundsRegistry(address[] _owners, uint _signaturesRequired, address _controller)
        MultiownedControlled(_owners, _signaturesRequired, _controller)
    {
    }

     
    function changeState(State _newState)
        external
        onlyController
    {
        assert(m_state != _newState);

        if (State.GATHERING == m_state) {   assert(State.REFUNDING == _newState || State.SUCCEEDED == _newState); }
        else assert(false);

        m_state = _newState;
        StateChanged(m_state);
    }

     
    function invested(address _investor)
        external
        payable
        onlyController
        requiresState(State.GATHERING)
    {
        uint256 amount = msg.value;
        require(0 != amount);
        assert(_investor != m_controller);

         
        if (0 == m_weiBalances[_investor])
            m_investors.push(_investor);

         
        totalInvested = totalInvested.add(amount);
        m_weiBalances[_investor] = m_weiBalances[_investor].add(amount);

        Invested(_investor, amount);
    }

     
    function sendEther(address to, uint value)
        external
        onlymanyowners(sha3(msg.data))
        requiresState(State.SUCCEEDED)
    {
        require(0 != to);
        require(value > 0 && this.balance >= value);
        to.transfer(value);
        EtherSent(to, value);
    }

     
    function withdrawPayments()
        external
        nonReentrant
        requiresState(State.REFUNDING)
    {
        address payee = msg.sender;
        uint256 payment = m_weiBalances[payee];

        require(payment != 0);
        require(this.balance >= payment);

        totalInvested = totalInvested.sub(payment);
        m_weiBalances[payee] = 0;

        payee.transfer(payment);
        RefundSent(payee, payment);
    }

    function getInvestorsCount() external constant returns (uint) { return m_investors.length; }


     

     
    uint256 public totalInvested;

     
    State public m_state = State.GATHERING;

     
    mapping(address => uint256) public m_weiBalances;

     
    address[] public m_investors;
}

pragma solidity 0.4.15;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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



 
contract MintableMultiownedToken is MultiownedControlled, StandardToken {

     
    struct EmissionInfo {
         
        uint256 created;

         
        uint256 totalSupplyWas;
    }

    event Mint(address indexed to, uint256 amount);
    event Emission(uint256 tokensCreated, uint256 totalSupplyWas, uint256 time);
    event Dividend(address indexed to, uint256 amount);


     

    function MintableMultiownedToken(address[] _owners, uint _signaturesRequired, address _minter)
        MultiownedControlled(_owners, _signaturesRequired, _minter)
    {
        dividendsPool = this;    

         
        m_emissions.push(EmissionInfo({created: 0, totalSupplyWas: 0}));
    }

     
    function requestDividends() external {
        payDividendsTo(msg.sender);
    }

     
    function transfer(address _to, uint256 _value) returns (bool) {
        payDividendsTo(msg.sender);
        payDividendsTo(_to);
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        payDividendsTo(_from);
        payDividendsTo(_to);
        return super.transferFrom(_from, _to, _value);
    }

     
     
     
     
     
     
     
     


     
    function mint(address _to, uint256 _amount) external onlyController {
        require(m_externalMintingEnabled);
        payDividendsTo(_to);
        mintInternal(_to, _amount);
    }

     
    function disableMinting() external onlyController {
        require(m_externalMintingEnabled);
        m_externalMintingEnabled = false;
    }


     

     
    function emissionInternal(uint256 _tokensCreated) internal {
        require(0 != _tokensCreated);
        require(_tokensCreated < totalSupply / 2);   

        uint256 totalSupplyWas = totalSupply;

        m_emissions.push(EmissionInfo({created: _tokensCreated, totalSupplyWas: totalSupplyWas}));
        mintInternal(dividendsPool, _tokensCreated);

        Emission(_tokensCreated, totalSupplyWas, now);
    }

    function mintInternal(address _to, uint256 _amount) internal {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
    }

     
    function payDividendsTo(address _to) internal {
        var (hasNewDividends, dividends) = calculateDividendsFor(_to);
        if (!hasNewDividends)
            return;

        if (0 != dividends) {
            balances[dividendsPool] = balances[dividendsPool].sub(dividends);
            balances[_to] = balances[_to].add(dividends);
        }
        m_lastAccountEmission[_to] = getLastEmissionNum();
    }

     
     
    function calculateDividendsFor(address _for) constant internal returns (bool hasNewDividends, uint dividends) {
        assert(_for != dividendsPool);   

        uint256 lastEmissionNum = getLastEmissionNum();
        uint256 lastAccountEmissionNum = m_lastAccountEmission[_for];
        assert(lastAccountEmissionNum <= lastEmissionNum);
        if (lastAccountEmissionNum == lastEmissionNum)
            return (false, 0);

        uint256 initialBalance = balances[_for];     
        if (0 == initialBalance)
            return (true, 0);

        uint256 balance = initialBalance;
        for (uint256 emissionToProcess = lastAccountEmissionNum + 1; emissionToProcess <= lastEmissionNum; emissionToProcess++) {
            EmissionInfo storage emission = m_emissions[emissionToProcess];
            assert(0 != emission.created && 0 != emission.totalSupplyWas);

            uint256 dividend = balance.mul(emission.created).div(emission.totalSupplyWas);
            Dividend(_for, dividend);

            balance = balance.add(dividend);
        }

        return (true, balance.sub(initialBalance));
    }

    function getLastEmissionNum() private constant returns (uint256) {
        return m_emissions.length - 1;
    }


     

     
    bool public m_externalMintingEnabled = true;

     
    address dividendsPool;

     
    EmissionInfo[] public m_emissions;

     
    mapping(address => uint256) m_lastAccountEmission;
}


 
contract STQToken is CirculatingToken, MintableMultiownedToken {


     

    function STQToken(address[] _owners)
        MintableMultiownedToken(_owners, 2,   address(0))
    {
        require(3 == _owners.length);
    }

     
    function startCirculation() external onlyController {
        assert(enableCirculation());     
    }

     
     
    function emission(uint256 _tokensCreatedInSTQ) external onlymanyowners(sha3(msg.data)) {
        emissionInternal(_tokensCreatedInSTQ.mul(uint256(10) ** uint256(decimals)));
    }


     

    string public constant name = 'Storiqa Token';
    string public constant symbol = 'STQ';
    uint8 public constant decimals = 18;
}


 

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}



 
contract STQCrowdsale is multiowned, ReentrancyGuard {
    using Math for uint256;
    using SafeMath for uint256;
    using FixedTimeBonuses for FixedTimeBonuses.Data;

    uint internal constant MSK2UTC_DELTA = 3600 * 3;

    enum IcoState { INIT, ICO, PAUSED, FAILED, SUCCEEDED }


    event StateChanged(IcoState _state);
    event FundTransfer(address backer, uint amount, bool isContribution);


    modifier requiresState(IcoState _state) {
        require(m_state == _state);
        _;
    }

     
     
    modifier timedStateChange() {
        if (IcoState.INIT == m_state && getCurrentTime() >= getStartTime())
            changeState(IcoState.ICO);

        if (IcoState.ICO == m_state && getCurrentTime() > getEndTime()) {
            finishICO();

            if (msg.value > 0)
                msg.sender.transfer(msg.value);
             
        } else {
            _;
        }
    }

     
    modifier fundsChecker() {
        assert(m_state == IcoState.ICO);

        uint atTheBeginning = m_funds.balance;
        if (atTheBeginning < m_lastFundsAmount) {
            changeState(IcoState.PAUSED);
            if (msg.value > 0)
                msg.sender.transfer(msg.value);  
             
        } else {
            _;

            if (m_funds.balance < atTheBeginning) {
                changeState(IcoState.PAUSED);
            } else {
                m_lastFundsAmount = m_funds.balance;
            }
        }
    }


     

    function STQCrowdsale(address[] _owners, address _token, address _funds)
        multiowned(_owners, 2)
    {
        require(3 == _owners.length);
        require(address(0) != address(_token) && address(0) != address(_funds));

        m_token = STQToken(_token);
        m_funds = FundsRegistry(_funds);

        m_bonuses.bonuses.push(FixedTimeBonuses.Bonus({endTime: 1505681999 + MSK2UTC_DELTA, bonus: 50}));
        m_bonuses.bonuses.push(FixedTimeBonuses.Bonus({endTime: 1505768399 + MSK2UTC_DELTA, bonus: 25}));
        m_bonuses.bonuses.push(FixedTimeBonuses.Bonus({endTime: 1505941199 + MSK2UTC_DELTA, bonus: 20}));
        m_bonuses.bonuses.push(FixedTimeBonuses.Bonus({endTime: 1506200399 + MSK2UTC_DELTA, bonus: 15}));
        m_bonuses.bonuses.push(FixedTimeBonuses.Bonus({endTime: 1506545999 + MSK2UTC_DELTA, bonus: 10}));
        m_bonuses.bonuses.push(FixedTimeBonuses.Bonus({endTime: 1506891599 + MSK2UTC_DELTA, bonus: 5}));
        m_bonuses.bonuses.push(FixedTimeBonuses.Bonus({endTime: 1508360399 + MSK2UTC_DELTA, bonus: 0}));
        m_bonuses.validate(true);
    }


     

     
    function() payable {
        buy();   
    }

     
     
    function buy()
        public
        payable
        nonReentrant
        timedStateChange
        requiresState(IcoState.ICO)
        fundsChecker
        returns (uint)
    {
        address investor = msg.sender;
        uint256 payment = msg.value;
        require(payment >= c_MinInvestment);

        uint startingInvariant = this.balance.add(m_funds.balance);

         
        uint fundsAllowed = getMaximumFunds().sub(m_funds.totalInvested());
        assert(0 != fundsAllowed);   
        payment = fundsAllowed.min256(payment);
        uint256 change = msg.value.sub(payment);

         
        uint stq = calcSTQAmount(payment);
        m_token.mint(investor, stq);

         
        m_funds.invested.value(payment)(investor);
        FundTransfer(investor, payment, true);

         
        if (change > 0)
        {
            assert(getMaximumFunds() == m_funds.totalInvested());
            finishICO();

             
            investor.transfer(change);
            assert(startingInvariant == this.balance.add(m_funds.balance).add(change));
        }
        else
            assert(startingInvariant == this.balance.add(m_funds.balance));

        return stq;
    }


     

     
    function pause()
        external
        timedStateChange
        requiresState(IcoState.ICO)
        onlyowner
    {
        changeState(IcoState.PAUSED);
    }

     
    function unpause()
        external
        timedStateChange
        requiresState(IcoState.PAUSED)
        onlymanyowners(sha3(msg.data))
    {
        changeState(IcoState.ICO);
        checkTime();
    }

     
    function fail()
        external
        timedStateChange
        requiresState(IcoState.PAUSED)
        onlymanyowners(sha3(msg.data))
    {
        changeState(IcoState.FAILED);
    }

     
    function setToken(address _token)
        external
        timedStateChange
        requiresState(IcoState.PAUSED)
        onlymanyowners(sha3(msg.data))
    {
        require(address(0) != _token);
        m_token = STQToken(_token);
    }

     
    function setFundsRegistry(address _funds)
        external
        timedStateChange
        requiresState(IcoState.PAUSED)
        onlymanyowners(sha3(msg.data))
    {
        require(address(0) != _funds);
        m_funds = FundsRegistry(_funds);
    }

     
    function checkTime()
        public
        timedStateChange
        onlyowner
    {
    }


     

    function finishICO() private {
        if (m_funds.totalInvested() < getMinFunds())
            changeState(IcoState.FAILED);
        else
            changeState(IcoState.SUCCEEDED);
    }

     
    function changeState(IcoState _newState) private {
        assert(m_state != _newState);

        if (IcoState.INIT == m_state) {        assert(IcoState.ICO == _newState); }
        else if (IcoState.ICO == m_state) {    assert(IcoState.PAUSED == _newState || IcoState.FAILED == _newState || IcoState.SUCCEEDED == _newState); }
        else if (IcoState.PAUSED == m_state) { assert(IcoState.ICO == _newState || IcoState.FAILED == _newState); }
        else assert(false);

        m_state = _newState;
        StateChanged(m_state);

         
        if (IcoState.SUCCEEDED == m_state) {
            onSuccess();
        } else if (IcoState.FAILED == m_state) {
            onFailure();
        }
    }

    function onSuccess() private {
         
        uint tokensPerOwner = m_token.totalSupply().mul(4).div(m_numOwners);
        for (uint i = 0; i < m_numOwners; i++)
            m_token.mint(getOwner(i), tokensPerOwner);

        m_funds.changeState(FundsRegistry.State.SUCCEEDED);
        m_funds.detachController();

        m_token.disableMinting();
        m_token.startCirculation();
        m_token.detachController();
    }

    function onFailure() private {
        m_funds.changeState(FundsRegistry.State.REFUNDING);
        m_funds.detachController();
    }


     
    function calcSTQAmount(uint _wei) private constant returns (uint) {
        uint stq = _wei.mul(c_STQperETH);

         
        stq = stq.mul(m_bonuses.getBonus(getCurrentTime()).add(100)).div(100);

        return stq;
    }

     
    function getStartTime() private constant returns (uint) {
        return c_startTime;
    }

     
    function getEndTime() private constant returns (uint) {
        return m_bonuses.getLastTime();
    }

     
    function getCurrentTime() internal constant returns (uint) {
        return now;
    }

     
    function getMinFunds() internal constant returns (uint) {
        return c_MinFunds;
    }

     
    function getMaximumFunds() internal constant returns (uint) {
        return c_MaximumFunds;
    }


     

     
    uint public constant c_STQperETH = 100;

     
    uint public constant c_MinInvestment = 10 finney;

     
    uint public constant c_MinFunds = 5000 ether;

     
    uint public constant c_MaximumFunds = 500000 ether;

     
    uint public constant c_startTime = 1505541600;

     
    FixedTimeBonuses.Data m_bonuses;

     
    IcoState public m_state = IcoState.INIT;

     
    STQToken public m_token;

     
    FundsRegistry public m_funds;

     
    uint256 public m_lastFundsAmount;
}