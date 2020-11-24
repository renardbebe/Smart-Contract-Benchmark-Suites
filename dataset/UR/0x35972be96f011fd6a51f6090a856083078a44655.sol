 

 

pragma solidity 0.5.2;

contract Owned {

    address public owner;

    event NewOwner(address indexed old, address indexed current);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _new)
        public
        onlyOwner
    {
        require(_new != address(0));
        owner = _new;
        emit NewOwner(owner, _new);
    }
}

interface RigoToken {

     
    event TokenMinted(address indexed recipient, uint256 amount);

     
    function mintToken(address _recipient, uint256 _amount) external;
    function changeMintingAddress(address _newAddress) external;
    function changeRigoblockAddress(address _newAddress) external;
    
    function balanceOf(address _who) external view returns (uint256);
}

interface Authority {

     
    event AuthoritySet(address indexed authority);
    event WhitelisterSet(address indexed whitelister);
    event WhitelistedUser(address indexed target, bool approved);
    event WhitelistedRegistry(address indexed registry, bool approved);
    event WhitelistedFactory(address indexed factory, bool approved);
    event WhitelistedVault(address indexed vault, bool approved);
    event WhitelistedDrago(address indexed drago, bool isWhitelisted);
    event NewDragoEventful(address indexed dragoEventful);
    event NewVaultEventful(address indexed vaultEventful);
    event NewNavVerifier(address indexed navVerifier);
    event NewExchangesAuthority(address indexed exchangesAuthority);

     
    function setAuthority(address _authority, bool _isWhitelisted) external;
    function setWhitelister(address _whitelister, bool _isWhitelisted) external;
    function whitelistUser(address _target, bool _isWhitelisted) external;
    function whitelistDrago(address _drago, bool _isWhitelisted) external;
    function whitelistVault(address _vault, bool _isWhitelisted) external;
    function whitelistRegistry(address _registry, bool _isWhitelisted) external;
    function whitelistFactory(address _factory, bool _isWhitelisted) external;
    function setDragoEventful(address _dragoEventful) external;
    function setVaultEventful(address _vaultEventful) external;
    function setNavVerifier(address _navVerifier) external;
    function setExchangesAuthority(address _exchangesAuthority) external;

     
    function isWhitelistedUser(address _target) external view returns (bool);
    function isAuthority(address _authority) external view returns (bool);
    function isWhitelistedRegistry(address _registry) external view returns (bool);
    function isWhitelistedDrago(address _drago) external view returns (bool);
    function isWhitelistedVault(address _vault) external view returns (bool);
    function isWhitelistedFactory(address _factory) external view returns (bool);
    function getDragoEventful() external view returns (address);
    function getVaultEventful() external view returns (address);
    function getNavVerifier() external view returns (address);
    function getExchangesAuthority() external view returns (address);
}

contract SafeMath {

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

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

interface InflationFace {

     
    function mintInflation(address _thePool, uint256 _reward) external returns (bool);
    function setInflationFactor(address _group, uint256 _inflationFactor) external;
    function setMinimumRigo(uint256 _minimum) external;
    function setRigoblock(address _newRigoblock) external;
    function setAuthority(address _authority) external;
    function setProofOfPerformance(address _pop) external;
    function setPeriod(uint256 _newPeriod) external;

     
    function canWithdraw(address _thePool) external view returns (bool);
    function timeUntilClaim(address _thePool) external view returns (uint256);
    function getInflationFactor(address _group) external view returns (uint256);
}

 
 
 
contract Inflation is
    SafeMath,
    InflationFace
{
    address public RIGOTOKENADDRESS;

    uint256 public period = 1 days;
    uint256 public minimumGRG = 0;
    address public proofOfPerformance;
    address public authority;
    address public rigoblockDao;

    mapping(address => Performer) performers;
    mapping(address => Group) groups;

    struct Performer {
        uint256 claimedTokens;
        mapping(uint256 => bool) claim;
        uint256 startTime;
        uint256 endTime;
        uint256 epoch;
    }

    struct Group {
        uint256 epochReward;
    }

     
    modifier minimumRigo(address _ofPool) {
        RigoToken rigoToken = RigoToken(RIGOTOKENADDRESS);
        require(
            rigoToken.balanceOf(getPoolOwner(_ofPool)) >= minimumGRG,
            "BELOW_MINIMUM_GRG"
        );
        _;
    }

    modifier onlyRigoblockDao {
        require(
            msg.sender == rigoblockDao,
            "ONLY_RIGOBLOCK_DAO"
        );
        _;
    }

    modifier onlyProofOfPerformance {
        require(
            msg.sender == proofOfPerformance,
            "ONLY_POP_CONTRACT"
        );
        _;
    }

    modifier isApprovedFactory(address _factory) {
        Authority auth = Authority(authority);
        require(
            auth.isWhitelistedFactory(_factory),
            "NOT_APPROVED_AUTHORITY"
        );
        _;
    }

    modifier timeAtLeast(address _thePool) {
        require(
            now >= performers[_thePool].endTime,
            "TIME_NOT_ENOUGH"
        );
        _;
    }

    constructor(
        address _rigoTokenAddress,
        address _proofOfPerformance,
        address _authority)
        public
    {
        RIGOTOKENADDRESS = _rigoTokenAddress;
        rigoblockDao = msg.sender;
        proofOfPerformance = _proofOfPerformance;
        authority = _authority;
    }

     
     
     
     
     
    function mintInflation(address _thePool, uint256 _reward)
        external
        onlyProofOfPerformance
        minimumRigo(_thePool)
        timeAtLeast(_thePool)
        returns (bool)
    {
        performers[_thePool].startTime = now;
        performers[_thePool].endTime = now + period;
        ++performers[_thePool].epoch;
        uint256 reward = _reward * 95 / 100;  
        uint256 rigoblockReward = safeSub(_reward, reward);
        RigoToken rigoToken = RigoToken(RIGOTOKENADDRESS);
        rigoToken.mintToken(getPoolOwner(_thePool), reward);
        rigoToken.mintToken(rigoblockDao, rigoblockReward);
        return true;
    }

     
     
     
    function setInflationFactor(address _group, uint256 _inflationFactor)
        external
        onlyRigoblockDao
        isApprovedFactory(_group)
    {
        groups[_group].epochReward = _inflationFactor;
    }

     
     
    function setMinimumRigo(uint256 _minimum)
        external
        onlyRigoblockDao
    {
        minimumGRG = _minimum;
    }

     
     
    function setRigoblock(address _newRigoblock)
        external
        onlyRigoblockDao
    {
        rigoblockDao = _newRigoblock;
    }

     
     
    function setAuthority(address _authority)
        external
        onlyRigoblockDao
    {
        authority = _authority;
    }

     
     
    function setProofOfPerformance(address _pop)
        external
        onlyRigoblockDao
    {
        proofOfPerformance = _pop;
    }

     
     
     
    function setPeriod(uint256 _newPeriod)
        external
        onlyRigoblockDao
    {
        period = _newPeriod;
    }

     
     
     
     
    function canWithdraw(address _thePool)
        external
        view
        returns (bool)
    {
        if (now >= performers[_thePool].endTime) {
            return true;
        }
    }

     
     
     
    function timeUntilClaim(address _thePool)
        external
        view
        returns (uint256)
    {
        if (now < performers[_thePool].endTime) {
            return (performers[_thePool].endTime);
        }
    }

     
     
     
    function getInflationFactor(address _group)
        external
        view
        returns (uint256)
    {
        return groups[_group].epochReward;
    }

     
     
     
     
    function getPoolOwner(address _ofPool)
        internal
        view
        returns (address)
    {
        return Owned(_ofPool).owner();
    }
}