 

pragma solidity ^0.4.11;


 
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


 
contract Ownable {
    address public owner;

     
    function Ownable() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner {
        assert(newOwner != address(0));
        owner = newOwner;
    }
}


 
contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        assert(!halted);
        _;
    }

    modifier onlyInEmergency {
        assert(halted);
        _;
    }

     
    function halt() external onlyOwner {
        halted = true;
    }

     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }
}


 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    modifier onlyPayloadSize(uint size) {
        assert (msg.data.length >= size + 4);
        _;
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
         
         
         
         
        assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


 
contract MintableToken is StandardToken, Ownable {
    using SafeMath for uint;

    uint256 public mintableSupply;

     
    mapping(address => bool) public mintAgents;

    event MintingAgentChanged(address addr, bool state);

     
    function mint(address receiver, uint256 amount) onlyPayloadSize(2 * 32) onlyMintAgent canMint public {
        mintableSupply = mintableSupply.sub(amount);
        balances[receiver] = balances[receiver].add(amount);
         
         
        Transfer(0, receiver, amount);
    }

     
    function setMintAgent(address addr, bool state) onlyOwner canMint public {
        mintAgents[addr] = state;
        MintingAgentChanged(addr, state);
    }

    modifier onlyMintAgent() {
         
        assert (mintAgents[msg.sender]);
        _;
    }

     
    modifier canMint() {
        assert(mintableSupply > 0);
        _;
    }

     
    modifier onlyPayloadSize(uint size) {
        assert (msg.data.length >= size + 4);
        _;
    }
}


 
contract ReleasableToken is ERC20, Ownable {
    address public releaseAgent;
    bool public released = false;

     
    function releaseToken() public onlyReleaseAgent {
        released = true;
    }

     
    function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
        releaseAgent = addr;
    }

    function transfer(address _to, uint _value) inReleaseState(true) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) inReleaseState(true) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    modifier inReleaseState(bool releaseState) {
        assert(releaseState == released);
        _;
    }

     
    modifier onlyReleaseAgent() {
        assert(msg.sender == releaseAgent);
        _;
    }
}


 
contract EventChain is ReleasableToken, MintableToken {
    string public name = "EventChain";
    string public symbol = "EVC";
    uint8 public decimals = 18;
    
    function EventChain() {
         
        totalSupply = 84000000 ether;
        mintableSupply = totalSupply;
         
        setReleaseAgent(msg.sender);
        setMintAgent(msg.sender, true);
    }
}


 
contract EventChainCrowdsale is Haltable {
    using SafeMath for uint256;

    enum State{Preparing, Prepared, Presale, Phase1, Phase2, Closed}

    uint256 constant public PRESALE_SUPPLY = 11000000 ether;
    uint256 constant public PHASE1_SUPPLY = 36000000 ether;
    uint256 constant public PHASE2_SUPPLY = 7600000 ether;

    uint256 constant public PRESALE_RATE = 570;
    uint256 constant public PHASE1_RATE = 460;
    uint256 constant public PHASE2_RATE = 230;

    uint256 constant public MIN_INVEST = 10 finney;
    uint256 constant public PRESALE_MIN_INVEST = 10 ether;
    uint256 constant public BTWO_CLAIM_PERCENT = 3;

    EventChain public evc;
    address public beneficiary;
    address public beneficiaryTwo;
    uint256 public totalRaised;

    State public currentState;
    uint256 public currentRate;
    uint256 public currentSupply;
    uint256 public currentTotalSupply;

    event StateChanged(State from, State to);
    event PresaleClaimed(uint256 claim);
    event InvestmentMade(
        address investor,
        uint256 weiAmount,
        uint256 tokenAmount,
        string crowdsalePhase,
        bytes calldata
    );

    function EventChainCrowdsale(EventChain _evc, address _beneficiary, address _beneficiaryTwo) {
        assert(address(_evc) != 0x0);
        assert(address(_beneficiary) != 0x0);
        assert(address(_beneficiaryTwo) != 0x0);
        beneficiary = _beneficiary;
        beneficiaryTwo = _beneficiaryTwo;
        evc = _evc;
    }

    function() payable onlyWhenCrowdsaleIsOpen requiresMinimumInvest stopInEmergency external {
        assert(msg.data.length <= 68);  
        uint256 tokens = msg.value.mul(currentRate);
        currentSupply = currentSupply.sub(tokens);
        evc.mint(msg.sender, tokens);
        totalRaised = totalRaised.add(msg.value);
        InvestmentMade(
            msg.sender,
            msg.value,
            tokens,
            currentStateToString(),
            msg.data
        );
    }

    function mintFounderTokens() onlyOwner inState(State.Preparing) external {
        assert(evc.mintAgents(this));
         
        evc.mint(beneficiary, 29400000 ether);
        currentState = State.Prepared;
        StateChanged(State.Preparing, currentState);
    }

    function startPresale() onlyOwner inState(State.Prepared) external {
        currentTotalSupply = PRESALE_SUPPLY;
        currentSupply = currentTotalSupply;
        currentRate = PRESALE_RATE;
        currentState = State.Presale;
        StateChanged(State.Prepared, currentState);
    }

    function startPhase1() onlyOwner inState(State.Presale) external {
        currentTotalSupply = currentSupply.add(PHASE1_SUPPLY);
        currentSupply = currentTotalSupply;
        currentRate = PHASE1_RATE;
        currentState = State.Phase1;
        uint256 claim = this.balance;
        beneficiary.transfer(claim);
        PresaleClaimed(claim);
        StateChanged(State.Presale, currentState);
    }

    function startPhase2() onlyOwner inState(State.Phase1) external {
        currentTotalSupply = currentSupply.add(PHASE2_SUPPLY);
        currentSupply = currentTotalSupply;
        currentRate = PHASE2_RATE;
        currentState = State.Phase2;
        StateChanged(State.Phase1, currentState);
    }

    function closeCrowdsale() onlyOwner inState(State.Phase2) external {
        uint256 beneficiaryTwoClaim = totalRaised.div(100).mul(BTWO_CLAIM_PERCENT);
        beneficiaryTwo.transfer(beneficiaryTwoClaim);
        beneficiary.transfer(this.balance);
        currentTotalSupply = 0;
        currentSupply = 0;
        currentRate = 0;
        currentState = State.Closed;
        StateChanged(State.Phase2, currentState);
    }

    function currentStateToString() constant returns (string) {
        if (currentState == State.Preparing) {
            return "Preparing";
        } else if (currentState == State.Prepared) {
            return "Prepared";
        } else if (currentState == State.Presale) {
            return "Presale";
        } else if (currentState == State.Phase1) {
            return "Phase 1";
        } else if (currentState == State.Phase2) {
            return "Phase 2";
        } else {
            return "Closed";
        }
    }

    modifier inState(State _state) {
        assert(currentState == _state);
        _;
    }

    modifier onlyWhenCrowdsaleIsOpen() {
        assert(currentState == State.Presale || currentState == State.Phase1 || currentState == State.Phase2);
        _;
    }

    modifier requiresMinimumInvest() {
        if (currentState == State.Presale) {
            assert(msg.value >= PRESALE_MIN_INVEST);
        } else {
            assert(msg.value >= MIN_INVEST);
        }
        _;
    }
}