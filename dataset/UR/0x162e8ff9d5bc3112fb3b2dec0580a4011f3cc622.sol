 

pragma solidity ^0.4.18;




 
 
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

 
contract ReentrancyGuard {

     
    bool private rentrancy_lock = false;

     
    modifier nonReentrant() {
        require(!rentrancy_lock);
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
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


 
contract FundsRegistry is ArgumentsChecker, MultiownedControlled, ReentrancyGuard {
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
    validAddress(to)
    onlymanyowners(sha3(msg.data))
    requiresState(State.SUCCEEDED)
    {
        require(value > 0 && this.balance >= value);
        to.transfer(value);
        EtherSent(to, value);
    }

     
    function withdrawPayments(address payee)
    external
    nonReentrant
    onlyController
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

    function getInvestorsCount() external constant returns (uint) { return m_investors.length; }


     

     
    uint256 public totalInvested;

     
    State public m_state = State.GATHERING;

     
    mapping(address => uint256) public m_weiBalances;

     
    address[] public m_investors;
}


 
 
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



 
contract MintableToken {
    event Mint(address indexed to, uint256 amount);

     
    function mint(address _to, uint256 _amount) public;
}



 
contract MetropolMintableToken is StandardToken, MintableToken {

    event Mint(address indexed to, uint256 amount);

    function mint(address _to, uint256 _amount) public; 

     
    function mintInternal(address _to, uint256 _amount) internal returns (bool) {
        require(_amount>0);
        require(_to!=address(0));

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);

        return true;
    }

}

 
contract Controlled {

    address public m_controller;

    event ControllerSet(address controller);
    event ControllerRetired(address was);


    modifier onlyController {
        require(msg.sender == m_controller);
        _;
    }

    function setController(address _controller) external;

     
    function setControllerInternal(address _controller) internal {
        m_controller = _controller;
        ControllerSet(m_controller);
    }

     
    function detachController() external onlyController {
        address was = m_controller;
        m_controller = address(0);
        ControllerRetired(was);
    }
}


 
contract MintableControlledToken is MetropolMintableToken, Controlled {

     
    function mint(address _to, uint256 _amount) public onlyController {
        super.mintInternal(_to, _amount);
    }

}


 
contract BurnableToken is StandardToken {

    event Burn(address indexed from, uint256 amount);

    function burn(address _from, uint256 _amount) public returns (bool);

     
    function burnInternal(address _from, uint256 _amount) internal returns (bool) {
        require(_amount>0);
        require(_amount<=balances[_from]);

        totalSupply = totalSupply.sub(_amount);
        balances[_from] = balances[_from].sub(_amount);
        Burn(_from, _amount);
        Transfer(_from, address(0), _amount);

        return true;
    }

}


 
contract BurnableControlledToken is BurnableToken, Controlled {

     
    function burn(address _from, uint256 _amount) public onlyController returns (bool) {
        return super.burnInternal(_from, _amount);
    }

}



 
contract MetropolMultiownedControlled is Controlled, multiowned {


    function MetropolMultiownedControlled(address[] _owners, uint256 _signaturesRequired)
    multiowned(_owners, _signaturesRequired)
    public
    {
         
    }

     
    function setController(address _controller) external onlymanyowners(sha3(msg.data)) {
        super.setControllerInternal(_controller);
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




 
contract CirculatingControlledToken is CirculatingToken, Controlled {

     
    function startCirculation() external onlyController {
        assert(enableCirculation());     
    }
}



 
contract MetropolToken is
    StandardToken,
    Controlled,
    MintableControlledToken,
    BurnableControlledToken,
    CirculatingControlledToken,
    MetropolMultiownedControlled
{
    string internal m_name = '';
    string internal m_symbol = '';
    uint8 public constant decimals = 18;

     
    function MetropolToken(address[] _owners)
        MetropolMultiownedControlled(_owners, 2)
        public
    {
        require(3 == _owners.length);
    }

    function name() public constant returns (string) {
        return m_name;
    }
    function symbol() public constant returns (string) {
        return m_symbol;
    }

    function setNameSymbol(string _name, string _symbol) external onlymanyowners(sha3(msg.data)) {
        require(bytes(m_name).length==0);
        require(bytes(_name).length!=0 && bytes(_symbol).length!=0);

        m_name = _name;
        m_symbol = _symbol;
    }

}


 
 
contract ICrowdsaleStat {

     
    function getWeiCollected() public constant returns (uint);

     
    function getTokenMinted() public constant returns (uint);
}

 
contract IInvestmentsWalletConnector {
     
    function storeInvestment(address investor, uint payment) internal;

     
    function getTotalInvestmentsStored() internal constant returns (uint);

     
    function wcOnCrowdsaleSuccess() internal;

     
    function wcOnCrowdsaleFailure() internal;
}


 
contract SimpleCrowdsaleBase is ArgumentsChecker, ReentrancyGuard, IInvestmentsWalletConnector, ICrowdsaleStat {
    using SafeMath for uint256;

    event FundTransfer(address backer, uint amount, bool isContribution);

    function SimpleCrowdsaleBase(address token)
    validAddress(token)
    {
        m_token = MintableToken(token);
    }


     

     
    function() payable {
        require(0 == msg.data.length);
        buy();   
    }

     
    function buy() public payable {      
        buyInternal(msg.sender, msg.value, 0);
    }


     

     
    function buyInternal(address investor, uint payment, uint extraBonuses)
    internal
    nonReentrant
    {
        require(payment >= getMinInvestment());
        require(getCurrentTime() >= getStartTime() || ! mustApplyTimeCheck(investor, payment)  );
        if (getCurrentTime() >= getEndTime()) {

            finish();
        }

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

         
        uint tokens = calculateTokens(investor, payment, extraBonuses);
        m_token.mint(investor, tokens);
        m_tokensMinted += tokens;

         
        storeInvestment(investor, payment);
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

        if (getWeiCollected() >= getMinimumFunds())
        wcOnCrowdsaleSuccess();
        else
        wcOnCrowdsaleFailure();

        m_finished = true;
    }


     

     
    function mustApplyTimeCheck(address  , uint  ) constant internal returns (bool) {
        return true;
    }

     
    function hasHardCap() constant internal returns (bool) {
        return getMaximumFunds() != 0;
    }

     
    function getCurrentTime() internal constant returns (uint) {
        return now;
    }

     
    function getMaximumFunds() internal constant returns (uint);

     
    function getMinimumFunds() internal constant returns (uint);

     
    function getStartTime() internal constant returns (uint);

     
    function getEndTime() internal constant returns (uint);

     
    function getMinInvestment() public constant returns (uint) {
        return 10 finney;
    }

     
    function calculateTokens(address investor, uint payment, uint extraBonuses) internal constant returns (uint);


     

    function getWeiCollected() public constant returns (uint) {
        return getTotalInvestmentsStored();
    }

     
    function getTokenMinted() public constant returns (uint) {
        return m_tokensMinted;
    }


     

     
    MintableToken public m_token;

    uint m_tokensMinted;

    bool m_finished = false;
}


 
contract SimpleStateful {
    enum State { INIT, RUNNING, PAUSED, FAILED, SUCCEEDED }

    event StateChanged(State _state);

    modifier requiresState(State _state) {
        require(m_state == _state);
        _;
    }

    modifier exceptState(State _state) {
        require(m_state != _state);
        _;
    }

    function changeState(State _newState) internal {
        assert(m_state != _newState);

        if (State.INIT == m_state) {
            assert(State.RUNNING == _newState);
        }
        else if (State.RUNNING == m_state) {
            assert(State.PAUSED == _newState || State.FAILED == _newState || State.SUCCEEDED == _newState);
        }
        else if (State.PAUSED == m_state) {
            assert(State.RUNNING == _newState || State.FAILED == _newState);
        }
        else assert(false);

        m_state = _newState;
        StateChanged(m_state);
    }

    function getCurrentState() internal view returns(State) {
        return m_state;
    }

     
    State public m_state = State.INIT;
}



 
contract MetropolFundsRegistryWalletConnector is IInvestmentsWalletConnector {

    function MetropolFundsRegistryWalletConnector(address _fundsAddress)
    public
    {
        require(_fundsAddress!=address(0));
        m_fundsAddress = FundsRegistry(_fundsAddress);
    }

     
    function storeInvestment(address investor, uint payment) internal
    {
        m_fundsAddress.invested.value(payment)(investor);
    }

     
    function getTotalInvestmentsStored() internal constant returns (uint)
    {
        return m_fundsAddress.totalInvested();
    }

     
    function wcOnCrowdsaleSuccess() internal {
        m_fundsAddress.changeState(FundsRegistry.State.SUCCEEDED);
        m_fundsAddress.detachController();
    }

     
    function wcOnCrowdsaleFailure() internal {
        m_fundsAddress.changeState(FundsRegistry.State.REFUNDING);
    }

     
    FundsRegistry public m_fundsAddress;
}


 
contract StatefulReturnableCrowdsale is
SimpleCrowdsaleBase,
SimpleStateful,
multiowned,
MetropolFundsRegistryWalletConnector
{

     
    uint256 public m_lastFundsAmount;

    event Withdraw(address payee, uint amount);

     
    modifier fundsChecker(address _investor, uint _payment) {
        uint atTheBeginning = getTotalInvestmentsStored();
        if (atTheBeginning < m_lastFundsAmount) {
            changeState(State.PAUSED);
            if (_payment > 0) {
                _investor.transfer(_payment);      
            }
             
        } else {
            _;

            if (getTotalInvestmentsStored() < atTheBeginning) {
                changeState(State.PAUSED);
            } else {
                m_lastFundsAmount = getTotalInvestmentsStored();
            }
        }
    }

     
    modifier timedStateChange() {
        if (getCurrentState() == State.INIT && getCurrentTime() >= getStartTime()) {
            changeState(State.RUNNING);
        }

        _;
    }


     
    function StatefulReturnableCrowdsale(
    address _token,
    address _funds,
    address[] _owners,
    uint _signaturesRequired
    )
    public
    SimpleCrowdsaleBase(_token)
    multiowned(_owners, _signaturesRequired)
    MetropolFundsRegistryWalletConnector(_funds)
    validAddress(_token)
    validAddress(_funds)
    {
    }

    function pauseCrowdsale()
    public
    onlyowner
    requiresState(State.RUNNING)
    {
        changeState(State.PAUSED);
    }
    function continueCrowdsale()
    public
    onlymanyowners(sha3(msg.data))
    requiresState(State.PAUSED)
    {
        changeState(State.RUNNING);

        if (getCurrentTime() >= getEndTime()) {
            finish();
        }
    }
    function failCrowdsale()
    public
    onlymanyowners(sha3(msg.data))
    requiresState(State.PAUSED)
    {
        wcOnCrowdsaleFailure();
        m_finished = true;
    }

    function withdrawPayments()
    public
    nonReentrant
    requiresState(State.FAILED)
    {
        Withdraw(msg.sender, m_fundsAddress.m_weiBalances(msg.sender));
        m_fundsAddress.withdrawPayments(msg.sender);
    }


     
    function buyInternal(address _investor, uint _payment, uint _extraBonuses)
    internal
    timedStateChange
    exceptState(State.PAUSED)
    fundsChecker(_investor, _payment)
    {
        if (!mustApplyTimeCheck(_investor, _payment)) {
            require(State.RUNNING == m_state || State.INIT == m_state);
        }
        else
        {
            require(State.RUNNING == m_state);
        }

        super.buyInternal(_investor, _payment, _extraBonuses);
    }


     
    function wcOnCrowdsaleSuccess() internal {
        super.wcOnCrowdsaleSuccess();

        changeState(State.SUCCEEDED);
    }

     
    function wcOnCrowdsaleFailure() internal {
        super.wcOnCrowdsaleFailure();

        changeState(State.FAILED);
    }

}


 
contract MetropolCrowdsale is StatefulReturnableCrowdsale {

    uint256 public m_startTimestamp;
    uint256 public m_softCap;
    uint256 public m_hardCap;
    uint256 public m_exchangeRate;
    address public m_foundersTokensStorage;
    bool public m_initialSettingsSet = false;

    modifier requireSettingsSet() {
        require(m_initialSettingsSet);
        _;
    }

    function MetropolCrowdsale(address _token, address _funds, address[] _owners)
        public
        StatefulReturnableCrowdsale(_token, _funds, _owners, 2)
    {
        require(3 == _owners.length);

         
        m_startTimestamp = 1893456000;
    }

     
    function setInitialSettings(
            address _foundersTokensStorage,
            uint256 _startTimestamp,
            uint256 _softCapInEther,
            uint256 _hardCapInEther,
            uint256 _tokensForOneEther
        )
        public
        timedStateChange
        requiresState(State.INIT)
        onlymanyowners(sha3(msg.data))
        validAddress(_foundersTokensStorage)
    {
         
         

        require(_startTimestamp!=0);
        require(_softCapInEther!=0);
        require(_hardCapInEther!=0);
        require(_tokensForOneEther!=0);

        m_startTimestamp = _startTimestamp;
        m_softCap = _softCapInEther * 1 ether;
        m_hardCap = _hardCapInEther * 1 ether;
        m_exchangeRate = _tokensForOneEther;
        m_foundersTokensStorage = _foundersTokensStorage;

        m_initialSettingsSet = true;
    }

     
    function setExchangeRate(uint256 _tokensForOneEther)
        public
        timedStateChange
        requiresState(State.INIT)
        onlymanyowners(sha3(msg.data))
    {
        m_exchangeRate = _tokensForOneEther;
    }

     
    function withdrawPayments() public requireSettingsSet {
        getToken().burn(
            msg.sender,
            getToken().balanceOf(msg.sender)
        );

        super.withdrawPayments();
    }


     
     
    function buyInternal(address _investor, uint _payment, uint _extraBonuses)
        internal
        requireSettingsSet
    {
        super.buyInternal(_investor, _payment, _extraBonuses);
    }


     
    function mustApplyTimeCheck(address investor, uint payment) constant internal returns (bool) {
        return !isOwner(investor);
    }

     
    function getMinInvestment() public constant returns (uint) {
        return 1 wei;
    }

     
    function getWeiCollected() public constant returns (uint) {
        return getTotalInvestmentsStored();
    }

     
    function getMinimumFunds() internal constant returns (uint) {
        return m_softCap;
    }

     
    function getMaximumFunds() internal constant returns (uint) {
        return m_hardCap;
    }

     
    function getStartTime() internal constant returns (uint) {
        return m_startTimestamp;
    }

     
    function getEndTime() internal constant returns (uint) {
        return m_startTimestamp + 60 days;
    }

     
    function calculateTokens(address  , uint payment, uint  )
        internal
        constant
        returns (uint)
    {
        uint256 secondMonth = m_startTimestamp + 30 days;
        if (getCurrentTime() <= secondMonth) {
            return payment.mul(m_exchangeRate);
        } else if (getCurrentTime() <= secondMonth + 1 weeks) {
            return payment.mul(m_exchangeRate).mul(100).div(105);
        } else if (getCurrentTime() <= secondMonth + 2 weeks) {
            return payment.mul(m_exchangeRate).mul(100).div(110);
        } else if (getCurrentTime() <= secondMonth + 3 weeks) {
            return payment.mul(m_exchangeRate).mul(100).div(115);
        } else if (getCurrentTime() <= secondMonth + 4 weeks) {
            return payment.mul(m_exchangeRate).mul(100).div(120);
        } else {
            return payment.mul(m_exchangeRate).mul(100).div(125);
        }
    }

     
    function wcOnCrowdsaleSuccess() internal {
        super.wcOnCrowdsaleSuccess();

         
        m_token.mint(
            m_foundersTokensStorage,
            getToken().totalSupply().mul(20).div(80)
        );


        getToken().startCirculation();
        getToken().detachController();
    }

     
    function getToken() internal returns(MetropolToken) {
        return MetropolToken(m_token);
    }
}