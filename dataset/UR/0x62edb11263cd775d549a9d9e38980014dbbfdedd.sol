 

pragma solidity ^0.4.17;

 
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

contract Hasher {

     
    function hashUuid(
        string _symbol,
        string _name,
        uint256 _chainIdValue,
        uint256 _chainIdUtility,
        address _openSTUtility,
        uint256 _conversionRate,
        uint8 _conversionRateDecimals)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            _symbol,
            _name,
            _chainIdValue,
            _chainIdUtility,
            _openSTUtility,
            _conversionRate,
            _conversionRateDecimals);
    }

    function hashStakingIntent(
        bytes32 _uuid,
        address _account,
        uint256 _accountNonce,
        address _beneficiary,
        uint256 _amountST,
        uint256 _amountUT,
        uint256 _escrowUnlockHeight)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            _uuid,
            _account,
            _accountNonce,
            _beneficiary,
            _amountST,
            _amountUT,
            _escrowUnlockHeight);
    }

    function hashRedemptionIntent(
        bytes32 _uuid,
        address _account,
        uint256 _accountNonce,
        address _beneficiary,
        uint256 _amountUT,
        uint256 _escrowUnlockHeight)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            _uuid,
            _account,
            _accountNonce,
            _beneficiary,
            _amountUT,
            _escrowUnlockHeight);
    }
}

 
contract Owned {

    address public owner;
    address public proposedOwner;

    event OwnershipTransferInitiated(address indexed _proposedOwner);
    event OwnershipTransferCompleted(address indexed _newOwner);


    function Owned() public {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }


    function isOwner(address _address) internal view returns (bool) {
        return (_address == owner);
    }


    function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool) {
        proposedOwner = _proposedOwner;

        OwnershipTransferInitiated(_proposedOwner);

        return true;
    }


    function completeOwnershipTransfer() public returns (bool) {
        require(msg.sender == proposedOwner);

        owner = proposedOwner;
        proposedOwner = address(0);

        OwnershipTransferCompleted(owner);

        return true;
    }
}

 
contract OpsManaged is Owned {

    address public opsAddress;
    address public adminAddress;

    event AdminAddressChanged(address indexed _newAddress);
    event OpsAddressChanged(address indexed _newAddress);


    function OpsManaged() public
        Owned()
    {
    }


    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }


    modifier onlyAdminOrOps() {
        require(isAdmin(msg.sender) || isOps(msg.sender));
        _;
    }


    modifier onlyOwnerOrAdmin() {
        require(isOwner(msg.sender) || isAdmin(msg.sender));
        _;
    }


    modifier onlyOps() {
        require(isOps(msg.sender));
        _;
    }


    function isAdmin(address _address) internal view returns (bool) {
        return (adminAddress != address(0) && _address == adminAddress);
    }


    function isOps(address _address) internal view returns (bool) {
        return (opsAddress != address(0) && _address == opsAddress);
    }


    function isOwnerOrOps(address _address) internal view returns (bool) {
        return (isOwner(_address) || isOps(_address));
    }


     
    function setAdminAddress(address _adminAddress) external onlyOwnerOrAdmin returns (bool) {
        require(_adminAddress != owner);
        require(_adminAddress != address(this));
        require(!isOps(_adminAddress));

        adminAddress = _adminAddress;

        AdminAddressChanged(_adminAddress);

        return true;
    }


     
    function setOpsAddress(address _opsAddress) external onlyOwnerOrAdmin returns (bool) {
        require(_opsAddress != owner);
        require(_opsAddress != address(this));
        require(!isAdmin(_opsAddress));

        opsAddress = _opsAddress;

        OpsAddressChanged(_opsAddress);

        return true;
    }
}

 
contract EIP20Interface {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);

    function balanceOf(address _owner) public view returns (uint256 balance);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract CoreInterface {
    
    function registrar() public view returns (address  );

    function chainIdRemote() public view returns (uint256  );
    function openSTRemote() public view returns (address  );
}

contract ProtocolVersioned {

     
    event ProtocolTransferInitiated(address indexed _existingProtocol, address indexed _proposedProtocol, uint256 _activationHeight);
    event ProtocolTransferRevoked(address indexed _existingProtocol, address indexed _revokedProtocol);
    event ProtocolTransferCompleted(address indexed _newProtocol);

     
     
     
     
     
     
    uint256 constant private PROTOCOL_TRANSFER_BLOCKS_TO_WAIT = 40320;
    
     
     
    address public openSTProtocol;
     
    address public proposedProtocol;
     
    uint256 public earliestTransferHeight;

     
    modifier onlyProtocol() {
        require(msg.sender == openSTProtocol);
        _;
    }

    modifier onlyProposedProtocol() {
        require(msg.sender == proposedProtocol);
        _;
    }

    modifier afterWait() {
        require(earliestTransferHeight <= block.number);
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }
    
     
     
     

     
     
    function ProtocolVersioned(address _protocol) 
        public
        notNull(_protocol)
    {
        openSTProtocol = _protocol;
    }

     
    function initiateProtocolTransfer(
        address _proposedProtocol)
        public 
        onlyProtocol
        notNull(_proposedProtocol)
        returns (bool)
    {
        require(_proposedProtocol != openSTProtocol);
        require(proposedProtocol == address(0));

        earliestTransferHeight = block.number + blocksToWaitForProtocolTransfer();
        proposedProtocol = _proposedProtocol;

        ProtocolTransferInitiated(openSTProtocol, _proposedProtocol, earliestTransferHeight);

        return true;
    }

     
     
    function completeProtocolTransfer()
        public
        onlyProposedProtocol
        afterWait
        returns (bool) 
    {
        openSTProtocol = proposedProtocol;
        proposedProtocol = address(0);
        earliestTransferHeight = 0;

        ProtocolTransferCompleted(openSTProtocol);

        return true;
    }

     
     
    function revokeProtocolTransfer()
        public
        onlyProtocol
        returns (bool)
    {
        require(proposedProtocol != address(0));

        address revokedProtocol = proposedProtocol;
        proposedProtocol = address(0);
        earliestTransferHeight = 0;

        ProtocolTransferRevoked(openSTProtocol, revokedProtocol);

        return true;
    }

    function blocksToWaitForProtocolTransfer() public pure returns (uint256) {
        return PROTOCOL_TRANSFER_BLOCKS_TO_WAIT;
    }
}

 
 
 
contract SimpleStake is ProtocolVersioned {
    using SafeMath for uint256;

     
    event ReleasedStake(address indexed _protocol, address indexed _to, uint256 _amount);

     
     
    EIP20Interface public eip20Token;
     
    bytes32 public uuid;

     
     
     
     
     
    function SimpleStake(
        EIP20Interface _eip20Token,
        address _openSTProtocol,
        bytes32 _uuid)
        ProtocolVersioned(_openSTProtocol)
        public
    {
        eip20Token = _eip20Token;
        uuid = _uuid;
    }

     
     
     
     
     
     
     
    function releaseTo(address _to, uint256 _amount) 
        public 
        onlyProtocol
        returns (bool)
    {
        require(_to != address(0));
        require(eip20Token.transfer(_to, _amount));
        
        ReleasedStake(msg.sender, _to, _amount);

        return true;
    }

     
     
     
     
     
     
    function getTotalStake()
        public
        view
        returns (uint256)
    {
        return eip20Token.balanceOf(this);
    }
}

 
contract AM1OpenSTValue is OpsManaged, Hasher {
    using SafeMath for uint256;
    
     
    event UtilityTokenRegistered(bytes32 indexed _uuid, address indexed stake,
        string _symbol, string _name, uint8 _decimals, uint256 _conversionRate, uint8 _conversionRateDecimals,
        uint256 _chainIdUtility, address indexed _stakingAccount);

    event StakingIntentDeclared(bytes32 indexed _uuid, address indexed _staker,
        uint256 _stakerNonce, address _beneficiary, uint256 _amountST,
        uint256 _amountUT, uint256 _unlockHeight, bytes32 _stakingIntentHash,
        uint256 _chainIdUtility);

    event ProcessedStake(bytes32 indexed _uuid, bytes32 indexed _stakingIntentHash,
        address _stake, address _staker, uint256 _amountST, uint256 _amountUT);

    event RevertedStake(bytes32 indexed _uuid, bytes32 indexed _stakingIntentHash,
        address _staker, uint256 _amountST, uint256 _amountUT);

    event RedemptionIntentConfirmed(bytes32 indexed _uuid, bytes32 _redemptionIntentHash,
        address _redeemer, address _beneficiary, uint256 _amountST, uint256 _amountUT, uint256 _expirationHeight);

    event ProcessedUnstake(bytes32 indexed _uuid, bytes32 indexed _redemptionIntentHash,
        address stake, address _redeemer, address _beneficiary, uint256 _amountST);

    event RevertedUnstake(bytes32 indexed _uuid, bytes32 indexed _redemptionIntentHash,
        address _redeemer, address _beneficiary, uint256 _amountST);

     
    uint8 public constant TOKEN_DECIMALS = 18;
    uint256 public constant DECIMALSFACTOR = 10**uint256(TOKEN_DECIMALS);
     
    uint256 private constant BLOCKS_TO_WAIT_LONG = 120960;
     
    uint256 private constant BLOCKS_TO_WAIT_SHORT = 17280;

     
    struct UtilityToken {
        string  symbol;
        string  name;
        uint256 conversionRate;
        uint8 conversionRateDecimals;
        uint8   decimals;
        uint256 chainIdUtility;
        SimpleStake simpleStake;
        address stakingAccount;
    }

    struct Stake {
        bytes32 uuid;
        address staker;
        address beneficiary;
        uint256 nonce;
        uint256 amountST;
        uint256 amountUT;
        uint256 unlockHeight;
    }

    struct Unstake {
        bytes32 uuid;
        address redeemer;
        address beneficiary;
        uint256 amountST;
         
        uint256 amountUT;
        uint256 expirationHeight;
    }

     
    uint256 public chainIdValue;
    EIP20Interface public valueToken;
    address public registrar;
    bytes32[] public uuids;
    bool public deactivated;
    mapping(uint256   => CoreInterface) internal cores;
    mapping(bytes32   => UtilityToken) public utilityTokens;
     
     
     
     
     
    mapping(address   => uint256) internal nonces;
     
    mapping(bytes32   => Stake) public stakes;
    mapping(bytes32   => Unstake) public unstakes;

     
    modifier onlyRegistrar() {
         
        require(msg.sender == registrar);
        _;
    }

    function AM1OpenSTValue(
        uint256 _chainIdValue,
        EIP20Interface _eip20token,
        address _registrar)
        public
        OpsManaged()
    {
        require(_chainIdValue != 0);
        require(_eip20token != address(0));
        require(_registrar != address(0));

        chainIdValue = _chainIdValue;
        valueToken = _eip20token;
         
         
        registrar = _registrar;
        deactivated = false;
    }

     
     
     
     
    function stake(
        bytes32 _uuid,
        uint256 _amountST,
        address _beneficiary)
        external
        returns (
        uint256 amountUT,
        uint256 nonce,
        uint256 unlockHeight,
        bytes32 stakingIntentHash)
         
    {
        require(!deactivated);
         
         
         
         
        require(_amountST > 0);
         
         
         
         
        require(valueToken.allowance(tx.origin, address(this)) >= _amountST);

        require(utilityTokens[_uuid].simpleStake != address(0));
        require(_beneficiary != address(0));

        UtilityToken storage utilityToken = utilityTokens[_uuid];

         
         
         
        if (utilityToken.stakingAccount != address(0)) require(msg.sender == utilityToken.stakingAccount);
        require(valueToken.transferFrom(tx.origin, address(this), _amountST));

        amountUT = (_amountST.mul(utilityToken.conversionRate))
            .div(10**uint256(utilityToken.conversionRateDecimals));
        unlockHeight = block.number + blocksToWaitLong();

        nonces[tx.origin]++;
        nonce = nonces[tx.origin];

        stakingIntentHash = hashStakingIntent(
            _uuid,
            tx.origin,
            nonce,
            _beneficiary,
            _amountST,
            amountUT,
            unlockHeight
        );

        stakes[stakingIntentHash] = Stake({
            uuid:         _uuid,
            staker:       tx.origin,
            beneficiary:  _beneficiary,
            nonce:        nonce,
            amountST:     _amountST,
            amountUT:     amountUT,
            unlockHeight: unlockHeight
        });

        StakingIntentDeclared(_uuid, tx.origin, nonce, _beneficiary,
            _amountST, amountUT, unlockHeight, stakingIntentHash, utilityToken.chainIdUtility);

        return (amountUT, nonce, unlockHeight, stakingIntentHash);
         
    }

    function processStaking(
        bytes32 _stakingIntentHash)
        external
        returns (address stakeAddress)
    {
        require(_stakingIntentHash != "");

        Stake storage stake = stakes[_stakingIntentHash];

         
         
         
         
         
         
        require(stake.staker == msg.sender || registrar == msg.sender);
         
         
         

        UtilityToken storage utilityToken = utilityTokens[stake.uuid];
        stakeAddress = address(utilityToken.simpleStake);
        require(stakeAddress != address(0));

        assert(valueToken.balanceOf(address(this)) >= stake.amountST);
        require(valueToken.transfer(stakeAddress, stake.amountST));

        ProcessedStake(stake.uuid, _stakingIntentHash, stakeAddress, stake.staker,
            stake.amountST, stake.amountUT);

        delete stakes[_stakingIntentHash];

        return stakeAddress;
    }

    function revertStaking(
        bytes32 _stakingIntentHash)
        external
        returns (
        bytes32 uuid,
        uint256 amountST,
        address staker)
    {
        require(_stakingIntentHash != "");

        Stake storage stake = stakes[_stakingIntentHash];

         
        require(stake.unlockHeight > 0);
        require(stake.unlockHeight <= block.number);

        assert(valueToken.balanceOf(address(this)) >= stake.amountST);
         
        require(valueToken.transfer(stake.staker, stake.amountST));

        uuid = stake.uuid;
        amountST = stake.amountST;
        staker = stake.staker;

        RevertedStake(stake.uuid, _stakingIntentHash, stake.staker,
            stake.amountST, stake.amountUT);

        delete stakes[_stakingIntentHash];

        return (uuid, amountST, staker);
    }

    function confirmRedemptionIntent(
        bytes32 _uuid,
        address _redeemer,
        uint256 _redeemerNonce,
        address _beneficiary,
        uint256 _amountUT,
        uint256 _redemptionUnlockHeight,
        bytes32 _redemptionIntentHash)
        external
        onlyRegistrar
        returns (
        uint256 amountST,
        uint256 expirationHeight)
    {
        require(utilityTokens[_uuid].simpleStake != address(0));
        require(_amountUT > 0);
        require(_beneficiary != address(0));
         
         
        require(_redemptionUnlockHeight > 0);
        require(_redemptionIntentHash != "");

        require(nonces[_redeemer] + 1 == _redeemerNonce);
        nonces[_redeemer]++;

        bytes32 redemptionIntentHash = hashRedemptionIntent(
            _uuid,
            _redeemer,
            nonces[_redeemer],
            _beneficiary,
            _amountUT,
            _redemptionUnlockHeight
        );

        require(_redemptionIntentHash == redemptionIntentHash);

        expirationHeight = block.number + blocksToWaitShort();

        UtilityToken storage utilityToken = utilityTokens[_uuid];
         
        require(_amountUT >= (utilityToken.conversionRate.div(10**uint256(utilityToken.conversionRateDecimals))));
        amountST = (_amountUT
            .mul(10**uint256(utilityToken.conversionRateDecimals))).div(utilityToken.conversionRate);

        require(valueToken.balanceOf(address(utilityToken.simpleStake)) >= amountST);

        unstakes[redemptionIntentHash] = Unstake({
            uuid:         _uuid,
            redeemer:     _redeemer,
            beneficiary:  _beneficiary,
            amountUT:     _amountUT,
            amountST:     amountST,
            expirationHeight: expirationHeight
        });

        RedemptionIntentConfirmed(_uuid, redemptionIntentHash, _redeemer,
            _beneficiary, amountST, _amountUT, expirationHeight);

        return (amountST, expirationHeight);
    }

    function processUnstaking(
        bytes32 _redemptionIntentHash)
        external
        returns (
        address stakeAddress)
    {
        require(_redemptionIntentHash != "");

        Unstake storage unstake = unstakes[_redemptionIntentHash];
        require(unstake.redeemer == msg.sender);

         
         
         
        require(unstake.expirationHeight > block.number);

        UtilityToken storage utilityToken = utilityTokens[unstake.uuid];
        stakeAddress = address(utilityToken.simpleStake);
        require(stakeAddress != address(0));

        require(utilityToken.simpleStake.releaseTo(unstake.beneficiary, unstake.amountST));

        ProcessedUnstake(unstake.uuid, _redemptionIntentHash, stakeAddress,
            unstake.redeemer, unstake.beneficiary, unstake.amountST);

        delete unstakes[_redemptionIntentHash];

        return stakeAddress;
    }

    function revertUnstaking(
        bytes32 _redemptionIntentHash)
        external
        returns (
        bytes32 uuid,
        address redeemer,
        address beneficiary,
        uint256 amountST)
    {
        require(_redemptionIntentHash != "");

        Unstake storage unstake = unstakes[_redemptionIntentHash];

         
         
        require(unstake.expirationHeight > 0);
        require(unstake.expirationHeight <= block.number);

        uuid = unstake.uuid;
        redeemer = unstake.redeemer;
        beneficiary = unstake.beneficiary;
        amountST = unstake.amountST;

        delete unstakes[_redemptionIntentHash];

        RevertedUnstake(uuid, _redemptionIntentHash, redeemer, beneficiary, amountST);

        return (uuid, redeemer, beneficiary, amountST);
    }

    function core(
        uint256 _chainIdUtility)
        external
        view
        returns (address   )
    {
        return address(cores[_chainIdUtility]);
    }

     
    function getNextNonce(
        address _account)
        public
        view
        returns (uint256  )
    {
        return (nonces[_account] + 1);
    }

    function blocksToWaitLong() public pure returns (uint256) {
        return BLOCKS_TO_WAIT_LONG;
    }

    function blocksToWaitShort() public pure returns (uint256) {
        return BLOCKS_TO_WAIT_SHORT;
    }

     
     
    function getUuidsSize() public view returns (uint256) {
        return uuids.length;
    }

     
    function addCore(
        CoreInterface _core)
        public
        onlyRegistrar
        returns (bool  )
    {
        require(address(_core) != address(0));
         
        require(registrar == _core.registrar());
         
        uint256 chainIdUtility = _core.chainIdRemote();
        require(chainIdUtility != 0);
         
        require(cores[chainIdUtility] == address(0));

        cores[chainIdUtility] = _core;

        return true;
    }

    function registerUtilityToken(
        string _symbol,
        string _name,
        uint256 _conversionRate,
        uint8 _conversionRateDecimals,
        uint256 _chainIdUtility,
        address _stakingAccount,
        bytes32 _checkUuid)
        public
        onlyRegistrar
        returns (bytes32 uuid)
    {
        require(bytes(_name).length > 0);
        require(bytes(_symbol).length > 0);
        require(_conversionRate > 0);
        require(_conversionRateDecimals <= 5);

        address openSTRemote = cores[_chainIdUtility].openSTRemote();
        require(openSTRemote != address(0));

        uuid = hashUuid(
            _symbol,
            _name,
            chainIdValue,
            _chainIdUtility,
            openSTRemote,
            _conversionRate,
            _conversionRateDecimals);

        require(uuid == _checkUuid);

        require(address(utilityTokens[uuid].simpleStake) == address(0));

        SimpleStake simpleStake = new SimpleStake(
            valueToken, address(this), uuid);

        utilityTokens[uuid] = UtilityToken({
            symbol:         _symbol,
            name:           _name,
            conversionRate: _conversionRate,
            conversionRateDecimals: _conversionRateDecimals,
            decimals:       TOKEN_DECIMALS,
            chainIdUtility: _chainIdUtility,
            simpleStake:    simpleStake,
            stakingAccount: _stakingAccount
        });
        uuids.push(uuid);

        UtilityTokenRegistered(uuid, address(simpleStake), _symbol, _name,
            TOKEN_DECIMALS, _conversionRate, _conversionRateDecimals, _chainIdUtility, _stakingAccount);

        return uuid;
    }

     
    function initiateProtocolTransfer(
        ProtocolVersioned _simpleStake,
        address _proposedProtocol)
        public
        onlyAdmin
        returns (bool)
    {
        _simpleStake.initiateProtocolTransfer(_proposedProtocol);

        return true;
    }

     
     

     
    function revokeProtocolTransfer(
        ProtocolVersioned _simpleStake)
        public
        onlyAdmin
        returns (bool)
    {
        _simpleStake.revokeProtocolTransfer();

        return true;
    }

    function deactivate()
        public
        onlyAdmin
        returns (
        bool result)
    {
        deactivated = true;
        return deactivated;
    }
}