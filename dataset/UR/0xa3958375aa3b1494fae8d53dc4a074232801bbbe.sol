 

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
        Transfer(this, _to, _amount);
        Mint(_to, _amount);
    }

     
    function payDividendsTo(address _to) internal {
        var (hasNewDividends, dividends) = calculateDividendsFor(_to);
        if (!hasNewDividends)
            return;

        if (0 != dividends) {
            balances[dividendsPool] = balances[dividendsPool].sub(dividends);
            balances[_to] = balances[_to].add(dividends);
            Transfer(dividendsPool, _to, dividends);
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


 
contract IInvestmentsWalletConnector {
     
    function storeInvestment(address investor, uint payment) internal;

     
    function getTotalInvestmentsStored() internal constant returns (uint);

     
    function wcOnCrowdsaleSuccess() internal;

     
    function wcOnCrowdsaleFailure() internal;
}

 
contract ExternalAccountWalletConnector is ArgumentsChecker, IInvestmentsWalletConnector {

    function ExternalAccountWalletConnector(address accountAddress)
        validAddress(accountAddress)
    {
        m_walletAddress = accountAddress;
    }

     
    function storeInvestment(address  , uint payment) internal
    {
        m_wcStored += payment;
        m_walletAddress.transfer(payment);
    }

     
    function getTotalInvestmentsStored() internal constant returns (uint)
    {
        return m_wcStored;
    }

     
    function wcOnCrowdsaleSuccess() internal {
    }

     
    function wcOnCrowdsaleFailure() internal {
    }

     
    address public m_walletAddress;

     
    uint public m_wcStored;
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


 
contract AnalyticProxy {

    function AnalyticProxy() {
        m_analytics = InvestmentAnalytics(msg.sender);
    }

     
    function() payable {
        m_analytics.iaInvestedBy.value(msg.value)(msg.sender);
    }

    InvestmentAnalytics public m_analytics;
}


 
contract InvestmentAnalytics {
    using SafeMath for uint256;

    function InvestmentAnalytics(){
    }

     
    function createMorePaymentChannelsInternal(uint limit) internal returns (uint) {
        uint paymentChannelsCreated;
        for (uint i = 0; i < limit; i++) {
            uint startingGas = msg.gas;
             

            address paymentChannel = new AnalyticProxy();
            m_validPaymentChannels[paymentChannel] = true;
            m_paymentChannels.push(paymentChannel);
            paymentChannelsCreated++;

             
            uint gasPerChannel = startingGas.sub(msg.gas);
            if (gasPerChannel.add(50000) > msg.gas)
                break;   
        }
        return paymentChannelsCreated;
    }


     
    function iaInvestedBy(address investor) external payable {
        address paymentChannel = msg.sender;
        if (m_validPaymentChannels[paymentChannel]) {
             
            uint value = msg.value;
            m_investmentsByPaymentChannel[paymentChannel] = m_investmentsByPaymentChannel[paymentChannel].add(value);
             
            iaOnInvested(investor, value, true);
        } else {
             
             
            iaOnInvested(msg.sender, msg.value, false);
        }
    }

     
    function iaOnInvested(address  , uint  , bool  ) internal {
    }


    function paymentChannelsCount() external constant returns (uint) {
        return m_paymentChannels.length;
    }

    function readAnalyticsMap() external constant returns (address[], uint[]) {
        address[] memory keys = new address[](m_paymentChannels.length);
        uint[] memory values = new uint[](m_paymentChannels.length);

        for (uint i = 0; i < m_paymentChannels.length; i++) {
            address key = m_paymentChannels[i];
            keys[i] = key;
            values[i] = m_investmentsByPaymentChannel[key];
        }

        return (keys, values);
    }

    function readPaymentChannels() external constant returns (address[]) {
        return m_paymentChannels;
    }


    mapping(address => uint256) public m_investmentsByPaymentChannel;
    mapping(address => bool) m_validPaymentChannels;

    address[] public m_paymentChannels;
}


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


 
contract ICrowdsaleStat {

     
    function getWeiCollected() public constant returns (uint);

     
    function getTokenMinted() public constant returns (uint);
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





 
contract SimpleCrowdsaleBase is ArgumentsChecker, ReentrancyGuard, IInvestmentsWalletConnector, ICrowdsaleStat {
    using SafeMath for uint256;

    event FundTransfer(address backer, uint amount, bool isContribution);

    function SimpleCrowdsaleBase(address token)
        validAddress(token)
    {
        m_token = MintableMultiownedToken(token);
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
        if (getCurrentTime() >= getEndTime())
            finish();

        if (m_finished) {
             
            investor.transfer(payment);
            return;
        }

        uint startingWeiCollected = getWeiCollected();
        uint startingInvariant = this.balance.add(startingWeiCollected);

         
        uint paymentAllowed = getMaximumFunds().sub(getWeiCollected());
        assert(0 != paymentAllowed);

        uint change;
        if (paymentAllowed < payment) {
            change = payment.sub(paymentAllowed);
            payment = paymentAllowed;
        }

         
        uint tokens = calculateTokens(investor, payment, extraBonuses);
        m_token.mint(investor, tokens);
        m_tokensMinted += tokens;

         
        storeInvestment(investor, payment);
        assert(getWeiCollected() <= getMaximumFunds() && getWeiCollected() > startingWeiCollected);
        FundTransfer(investor, payment, true);

        if (getWeiCollected() == getMaximumFunds())
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


     

     
    MintableMultiownedToken public m_token;

    uint m_tokensMinted;

    bool m_finished = false;
}



 
contract STQPreICOBase is SimpleCrowdsaleBase, Ownable, InvestmentAnalytics {

    function STQPreICOBase(address token)
        SimpleCrowdsaleBase(token)
    {
    }


     

    function createMorePaymentChannels(uint limit) external onlyOwner returns (uint) {
        return createMorePaymentChannelsInternal(limit);
    }

     
     
     
     
    function amIOwner() external constant onlyOwner returns (bool) {
        return true;
    }


     

     
    function iaOnInvested(address investor, uint payment, bool usingPaymentChannel) internal {
        buyInternal(investor, payment, usingPaymentChannel ? c_paymentChannelBonusPercent : 0);
    }

    function calculateTokens(address  , uint payment, uint extraBonuses) internal constant returns (uint) {
        uint bonusPercent = getPreICOBonus().add(getLargePaymentBonus(payment)).add(extraBonuses);
        uint rate = c_STQperETH.mul(bonusPercent.add(100)).div(100);

        return payment.mul(rate);
    }

    function getLargePaymentBonus(uint payment) private constant returns (uint) {
        if (payment >= 5000 ether) return 20;
        if (payment >= 3000 ether) return 15;
        if (payment >= 1000 ether) return 10;
        if (payment >= 800 ether) return 8;
        if (payment >= 500 ether) return 5;
        if (payment >= 200 ether) return 2;
        return 0;
    }

    function mustApplyTimeCheck(address investor, uint  ) constant internal returns (bool) {
        return investor != owner;
    }

     
    function getPreICOBonus() internal constant returns (uint);


     

     
    uint public constant c_STQperETH = 100000;

     
    uint public constant c_paymentChannelBonusPercent = 2;
}




 
contract STQPreICO3 is STQPreICOBase, ExternalAccountWalletConnector {

    function STQPreICO3(address token, address wallet)
        STQPreICOBase(token)
        ExternalAccountWalletConnector(wallet)
    {

    }


     

    function getWeiCollected() public constant returns (uint) {
        return getTotalInvestmentsStored();
    }

     
    function getMinimumFunds() internal constant returns (uint) {
        return 0;
    }

     
    function getMaximumFunds() internal constant returns (uint) {
        return 100000000 ether;
    }

     
    function getStartTime() internal constant returns (uint) {
        return 1508958000;  
    }

     
    function getEndTime() internal constant returns (uint) {
        return 1511568000;  
    }

     
    function getPreICOBonus() internal constant returns (uint) {
        return 33;
    }
}