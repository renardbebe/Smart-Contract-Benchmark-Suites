 

pragma solidity ^0.4.24;

 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);

        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }
}

 
contract HasOwner {
     
    address public owner;

     
    address public newOwner;

     
    constructor (address _owner) internal {
        owner = _owner;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    event OwnershipTransfer(address indexed _oldOwner, address indexed _newOwner);

     
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);

        emit OwnershipTransfer(owner, newOwner);

        owner = newOwner;
    }
}

 
contract ERC20TokenInterface {
    uint256 public totalSupply;   
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
}

 
contract ERC20Token is ERC20TokenInterface {
    using SafeMath for uint256;

     
    mapping (address => uint256) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    function balanceOf(address _account) public constant returns (uint256 balance) {
        return balances[_account];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] < _value || _value == 0) {

            return false;
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] < _value || allowed[_from][msg.sender] < _value || _value == 0) {
            return false;
        }

        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function () public payable {
        revert();
    }
}

 
contract BonusCloudTokenConfig {
     
    string constant NAME = "BATTest";

     
    string constant SYMBOL = "BATTest";

     
    uint8 constant DECIMALS = 18;

     
    uint256 constant DECIMALS_FACTOR = 10 ** uint(DECIMALS);

     
    uint256 constant TOTAL_SUPPLY = 7000000000 * DECIMALS_FACTOR;

     
    uint constant START_DATE = 1536019200;

     
    uint256 constant TOKENS_LOCKED_CORE_TEAM = 1400 * (10**6) * DECIMALS_FACTOR;

     
    uint256 constant TOKENS_LOCKED_ADVISORS = 2100 * (10**6) * DECIMALS_FACTOR;

     
    uint256 constant TOKENS_LOCKED_ADVISORS_A = 350 * (10**6) * DECIMALS_FACTOR;

     
    uint256 constant TOKENS_LOCKED_ADVISORS_B = 350 * (10**6) * DECIMALS_FACTOR;

     
    uint256 constant TOKENS_LOCKED_ADVISORS_C = 700 * (10**6) * DECIMALS_FACTOR;

     
    uint256 constant TOKENS_LOCKED_ADVISORS_D = 700 * (10**6) * DECIMALS_FACTOR;

     
    uint256 constant TOKEN_FOUNDATION = 700 * (10**6) * DECIMALS_FACTOR;

     
    uint256 constant TOKENS_BOUNTY_PROGRAM = 2800 * (10**6) * DECIMALS_FACTOR;
}

 
contract BonusCloudToken is BonusCloudTokenConfig, HasOwner, ERC20Token {
     
    string public name;

     
    string public symbol;

     
    uint8 public decimals;

     
    constructor() public HasOwner(msg.sender) {
        name = NAME;
        symbol = SYMBOL;
        decimals = DECIMALS;
        totalSupply = TOTAL_SUPPLY;
        balances[owner] = TOTAL_SUPPLY;
    }
}

 
contract TokenSafeVesting is HasOwner {
    using SafeMath for uint256;

     
    uint256 total;
    uint256 lapsedTotal;
    address account;

    uint[] vestingCommencementDates;
    uint[] vestingPercents;

    bool revocable;
    bool revoked;

     
    ERC20TokenInterface token;

     
     constructor (
        address _token,
        address _account,
        uint256 _balanceTotal,
        uint[] _vestingCommencementDates,
        uint[] _vestingPercents,
        bool _revocable) public HasOwner(msg.sender) {

         
        require(_vestingPercents.length > 0);
        require(_vestingCommencementDates.length == _vestingPercents.length);
        uint percentSum;
        for (uint32 i = 0; i < _vestingPercents.length; i++) {
            require(_vestingPercents[i]>=0);
            require(_vestingPercents[i]<=100);
            percentSum = percentSum.add(_vestingPercents[i]);
            require(_vestingCommencementDates[i]>0);
            if (i > 0) {
                require(_vestingCommencementDates[i] > _vestingCommencementDates[i-1]);
            }
        }
        require(percentSum==100);

        token = ERC20TokenInterface(_token);
        account = _account;
        total = _balanceTotal;
        vestingCommencementDates = _vestingCommencementDates;
        vestingPercents = _vestingPercents;
        revocable = _revocable;
    }

     
    function release() public {
        require(!revoked);

        uint256 grant;
        uint percent;
        for (uint32 i = 0; i < vestingCommencementDates.length; i++) {
            if (block.timestamp < vestingCommencementDates[i]) {
            } else {
                percent += vestingPercents[i];
            }
        }
        grant = total.mul(percent).div(100);

        if (grant > lapsedTotal) {
            uint256 tokens = grant.sub(lapsedTotal);
            lapsedTotal = lapsedTotal.add(tokens);
            if (!token.transfer(account, tokens)) {
                revert();
            } else {
            }
        }
    }

     
    function revoke() public onlyOwner {
        require(revocable);
        require(!revoked);

        release();
        revoked = true;
    }
}

contract BonusCloudTokenFoundation is BonusCloudToken {

     
    mapping (address => TokenSafeVesting) vestingTokenPools;

    function addLockedAccount(
        address _account,
        uint256 _balanceTotal,
        uint[] _vestingCommencementDates,
        uint[] _vestingPercents,
        bool _revocable) internal onlyOwner {

        TokenSafeVesting vestingToken = new TokenSafeVesting(
            this,
            _account,
            _balanceTotal,
            _vestingCommencementDates,
            _vestingPercents,
            _revocable);

        vestingTokenPools[_account] = vestingToken;
        transfer(vestingToken, _balanceTotal);
    }

    function releaseAccount(address _account) public {
        TokenSafeVesting vestingToken;
        vestingToken = vestingTokenPools[_account];
        vestingToken.release();
    }

    function revokeAccount(address _account) public onlyOwner {
        TokenSafeVesting vestingToken;
        vestingToken = vestingTokenPools[_account];
        vestingToken.revoke();
    }

    constructor() public {
         
        uint[] memory DFoundation = new uint[](1);
        DFoundation[0] = START_DATE;
        uint[] memory PFoundation = new uint[](1);
        PFoundation[0] = 100;
        addLockedAccount(0x4eE4F2A51EFf3DDDe7d7be6Da37Bb7f3F08771f7, TOKEN_FOUNDATION, DFoundation, PFoundation, false);

        uint[] memory DAdvisorA = new uint[](5);
        DAdvisorA[0] = START_DATE;
        DAdvisorA[1] = START_DATE + 90 days;
        DAdvisorA[2] = START_DATE + 180 days;
        DAdvisorA[3] = START_DATE + 270 days;
        DAdvisorA[4] = START_DATE + 365 days;
        uint[] memory PAdvisorA = new uint[](5);
        PAdvisorA[0] = 35;
        PAdvisorA[1] = 17;
        PAdvisorA[2] = 16;
        PAdvisorA[3] = 16;
        PAdvisorA[4] = 16;
        addLockedAccount(0x67a25099C3958b884687663C17d22e88C83e9F9A, TOKENS_LOCKED_ADVISORS_A, DAdvisorA, PAdvisorA, false);

         
        uint[] memory DAdvisorB = new uint[](5);
        DAdvisorB[0] = START_DATE;
        DAdvisorB[1] = START_DATE + 90 days;
        DAdvisorB[2] = START_DATE + 180 days;
        DAdvisorB[3] = START_DATE + 270 days;
        DAdvisorB[4] = START_DATE + 365 days;
        uint[] memory PAdvisorB = new uint[](5);
        PAdvisorB[0] = 35;
        PAdvisorB[1] = 17;
        PAdvisorB[2] = 16;
        PAdvisorB[3] = 16;
        PAdvisorB[4] = 16;
        addLockedAccount(0x3F756EA6F3a9d0e24f9857506D0E76cCCbAcFd59, TOKENS_LOCKED_ADVISORS_B, DAdvisorB, PAdvisorB, false);

         
        uint[] memory DAdvisorC = new uint[](4);
        DAdvisorC[0] = START_DATE + 90 days;
        DAdvisorC[1] = START_DATE + 180 days;
        DAdvisorC[2] = START_DATE + 270 days;
        DAdvisorC[3] = START_DATE + 365 days;
        uint[] memory PAdvisorC = new uint[](4);
        PAdvisorC[0] = 25;
        PAdvisorC[1] = 25;
        PAdvisorC[2] = 25;
        PAdvisorC[3] = 25;
        addLockedAccount(0x0022F267eb8A8463C241e3bd23184e0C7DC783F3, TOKENS_LOCKED_ADVISORS_C, DAdvisorC, PAdvisorC, false);

         
        uint[] memory DCoreTeam = new uint[](12);
        DCoreTeam[0] = START_DATE + 90 days;
        DCoreTeam[1] = START_DATE + 180 days;
        DCoreTeam[2] = START_DATE + 270 days;
        DCoreTeam[3] = START_DATE + 365 days;
        DCoreTeam[4] = START_DATE + 365 days + 90 days;
        DCoreTeam[5] = START_DATE + 365 days + 180 days;
        DCoreTeam[6] = START_DATE + 365 days + 270 days;
        DCoreTeam[7] = START_DATE + 365 days + 365 days;
        DCoreTeam[8] = START_DATE + 730 days + 90 days;
        DCoreTeam[9] = START_DATE + 730 days + 180 days;
        DCoreTeam[10] = START_DATE + 730 days + 270 days;
        DCoreTeam[11] = START_DATE + 730 days + 365 days;
        uint[] memory PCoreTeam = new uint[](12);
        PCoreTeam[0] = 8;
        PCoreTeam[1] = 8;
        PCoreTeam[2] = 8;
        PCoreTeam[3] = 9;
        PCoreTeam[4] = 8;
        PCoreTeam[5] = 8;
        PCoreTeam[6] = 9;
        PCoreTeam[7] = 9;
        PCoreTeam[8] = 8;
        PCoreTeam[9] = 8;
        PCoreTeam[10] = 8;
        PCoreTeam[11] = 9;
        addLockedAccount(0xaEF494C6Af26ef6D9551E91A36b0502A216fF276, TOKENS_LOCKED_CORE_TEAM, DCoreTeam, PCoreTeam, false);

         
        uint[] memory DTest = new uint[](2);
        DTest[0] = START_DATE + 12 hours;
        DTest[1] = START_DATE + 16 hours;
        uint[] memory PTest = new uint[](2);
        PTest[0] = 50;
        PTest[1] = 50;
        addLockedAccount(0x67a25099C3958b884687663C17d22e88C83e9F9A, 10 * (10**6) * DECIMALS_FACTOR, DTest, PTest, false);
    }
}