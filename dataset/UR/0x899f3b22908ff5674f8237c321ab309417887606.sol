 

pragma solidity ^0.4.23;

 

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract TokenDestructible is Ownable {

  function TokenDestructible() public payable { }

   
  function destroy(address[] tokens) onlyOwner public {

     
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

     
    selfdestruct(owner);
  }
}

 

 




 
 
 
interface ERC20Interface {
    function decimals() public constant returns (uint8);
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


 
interface SettingsInterface {
    function registrationFee() external view returns (uint256);
    function activationFee() external view returns (uint256);
    function defaultReputationReward() external view returns (uint256);
    function reputationIRNNodeShare() external view returns (uint256);
    function blockThreshold() external view returns (uint256);
}


 
 
 
 
 
 
contract Atonomi is Pausable, TokenDestructible {
    using SafeMath for uint256;

     
     
     
    ERC20Interface public token;

     
     
    SettingsInterface public settings;

     
     
     
     
     
     
     
    mapping (bytes32 => Device) public devices;

     
     
     
     
     
     
     
    mapping (address => NetworkMember) public network;

     
     
     
     
     
     
    mapping (address => TokenPool) public pools;

     
     
     
     
    mapping (address => uint256) public rewards;

     
     
     
    mapping (bytes32 => address) public manufacturerRewards;

     
     
     
     
    mapping (address => mapping (bytes32 => uint256)) public authorWrites;

     
     
     
    mapping (bytes32 => bytes32) public defaultManufacturerReputations;

     
     
     
     
     
     
     
     
     
     
     
    struct Device {
        bytes32 manufacturerId;
        bytes32 deviceType;
        bool registered;
        bool activated;
        bytes32 reputationScore;
        bytes32 devicePublicKey;
    }

     
     
     
     
    struct TokenPool {
        uint256 balance;
        uint256 rewardAmount;
    }

     
     
     
     
     
     
    struct NetworkMember {
        bool isIRNAdmin;
        bool isManufacturer;
        bool isIRNNode;
        bytes32 memberId;
    }

     
     
     
     
    modifier onlyManufacturer() {
        require(network[msg.sender].isManufacturer, "must be a manufacturer");
        _;
    }

     
    modifier onlyIRNorOwner() {
        require(msg.sender == owner || network[msg.sender].isIRNAdmin, "must be owner or an irn admin");
        _;
    }

     
    modifier onlyIRNNode() {
        require(network[msg.sender].isIRNNode, "must be an irn node");
        _;
    }

     
     
     
    constructor (
        address _token,
        address _settings) public {
        require(_token != address(0), "token address cannot be 0x0");
        require(_settings != address(0), "settings address cannot be 0x0");
        token = ERC20Interface(_token);
        settings = SettingsInterface(_settings);
    }

     
     
     
     
     
     
     
     
     
    event DeviceRegistered(
        address indexed _sender,
        uint256 _fee,
        bytes32 indexed _deviceHashKey,
        bytes32 indexed _manufacturerId,
        bytes32 _deviceType
    );

     
     
     
     
     
     
    event DeviceActivated(
        address indexed _sender,
        uint256 _fee,
        bytes32 indexed _deviceId,
        bytes32 indexed _manufacturerId,
        bytes32 _deviceType
    );

     
     
     
     
     
     
     
     
    event ReputationScoreUpdated(
        bytes32 indexed _deviceId,
        bytes32 _deviceType,
        bytes32 _newScore,
        address indexed _irnNode,
        uint256 _irnReward,
        address indexed _manufacturerWallet,
        uint256 _manufacturerReward
    );

     
     
     
     
    event NetworkMemberAdded(
        address indexed _sender,
        address indexed _member,
        bytes32 indexed _memberId
    );

     
     
     
     
    event NetworkMemberRemoved(
        address indexed _sender,
        address indexed _member,
        bytes32 indexed _memberId
    );

     
     
     
     
    event ManufacturerRewardWalletChanged(
        address indexed _old,
        address indexed _new,
        bytes32 indexed _manufacturerId
    );

     
     
     
    event TokenPoolRewardUpdated(
        address indexed _sender,
        uint256 _newReward
    );

     
     
     
     
     
    event TokensDeposited(
        address indexed _sender,
        bytes32 indexed _manufacturerId,
        address indexed _manufacturer,
        uint256 _amount
    );
    
     
     
     
    event TokensWithdrawn(
        address indexed _sender,
        uint256 _amount
    );

     
     
     
     
    event DefaultReputationScoreChanged(
        address indexed _sender,
        bytes32 indexed _manufacturerId,
        bytes32 _newDefaultScore
    );

     
     
     
     
     
     
     
     
     
     
     
    function registerDevice(
        bytes32 _deviceIdHash,
        bytes32 _deviceType,
        bytes32 _devicePublicKey)
        public onlyManufacturer whenNotPaused returns (bool)
    {
        uint256 registrationFee = settings.registrationFee();
        Device memory d = _registerDevice(msg.sender, _deviceIdHash, _deviceType, _devicePublicKey);
        emit DeviceRegistered(
            msg.sender,
            registrationFee,
            _deviceIdHash,
            d.manufacturerId,
            _deviceType);
        _depositTokens(msg.sender, registrationFee);
        require(token.transferFrom(msg.sender, address(this), registrationFee), "transferFrom failed");
        return true;
    }

     
     
     
     
     
     
     
    function activateDevice(bytes32 _deviceId) public whenNotPaused returns (bool) {
        uint256 activationFee = settings.activationFee();
        Device memory d = _activateDevice(_deviceId);
        emit DeviceActivated(msg.sender, activationFee, _deviceId, d.manufacturerId, d.deviceType);
        address manufacturer = manufacturerRewards[d.manufacturerId];
        require(manufacturer != address(this), "manufacturer is unknown");
        _depositTokens(manufacturer, activationFee);
        require(token.transferFrom(msg.sender, address(this), activationFee), "transferFrom failed");
        return true;
    }

     
     
     
     
     
     
     
     
    function registerAndActivateDevice(
        bytes32 _deviceId,
        bytes32 _deviceType,
        bytes32 _devicePublicKey) 
        public onlyManufacturer whenNotPaused returns (bool)
    {
        uint256 registrationFee = settings.registrationFee();
        uint256 activationFee = settings.activationFee();

        bytes32 deviceIdHash = keccak256(_deviceId);
        Device memory d = _registerDevice(msg.sender, deviceIdHash, _deviceType, _devicePublicKey);
        bytes32 manufacturerId = d.manufacturerId;
        emit DeviceRegistered(msg.sender, registrationFee, deviceIdHash, manufacturerId, _deviceType);

        d = _activateDevice(_deviceId);
        emit DeviceActivated(msg.sender, activationFee, _deviceId, manufacturerId, _deviceType);

        uint256 fee = registrationFee.add(activationFee);
        _depositTokens(msg.sender, fee);
        require(token.transferFrom(msg.sender, address(this), fee), "transferFrom failed");
        return true;
    }

     
     
     
     
     
     
     
     
     
     
     
    function updateReputationScore(
        bytes32 _deviceId,
        bytes32 _reputationScore)
        public onlyIRNNode whenNotPaused returns (bool)
    {
        Device memory d = _updateReputationScore(_deviceId, _reputationScore);

        address _manufacturerWallet = manufacturerRewards[d.manufacturerId];
        require(_manufacturerWallet != address(0), "_manufacturerWallet cannot be 0x0");
        require(_manufacturerWallet != msg.sender, "manufacturers cannot collect the full reward");

        uint256 irnReward;
        uint256 manufacturerReward;
        (irnReward, manufacturerReward) = getReputationRewards(msg.sender, _manufacturerWallet, _deviceId);
        _distributeRewards(_manufacturerWallet, msg.sender, irnReward);
        _distributeRewards(_manufacturerWallet, _manufacturerWallet, manufacturerReward);
        emit ReputationScoreUpdated(
            _deviceId,
            d.deviceType,
            _reputationScore,
            msg.sender,
            irnReward,
            _manufacturerWallet,
            manufacturerReward);
        authorWrites[msg.sender][_deviceId] = block.number;
        return true;
    }

     
     
     
     
     
    function getReputationRewards(
        address author,
        address manufacturer,
        bytes32 deviceId)
        public view returns (uint256 irnReward, uint256 manufacturerReward)
    {
        uint256 lastWrite = authorWrites[author][deviceId];
        uint256 blocks = 0;
        if (lastWrite > 0) {
            blocks = block.number.sub(lastWrite);
        }
        uint256 totalRewards = calculateReward(pools[manufacturer].rewardAmount, blocks);
        irnReward = totalRewards.mul(settings.reputationIRNNodeShare()).div(100);
        manufacturerReward = totalRewards.sub(irnReward);
    }

     
     
     
     
    function calculateReward(uint256 rewardAmount, uint256 blocksSinceLastWrite) public view returns (uint256) {
        uint256 totalReward = rewardAmount;
        uint256 blockThreshold = settings.blockThreshold();
        if (blocksSinceLastWrite > 0 && blocksSinceLastWrite < blockThreshold) {
            uint256 multiplier = 10 ** uint256(token.decimals());
            totalReward = rewardAmount.mul(blocksSinceLastWrite.mul(multiplier)).div(blockThreshold.mul(multiplier));
        }
        return totalReward;
    }

     
     
     
     
     
     
     
     
     
     
     
    function registerDevices(
        bytes32[] _deviceIdHashes,
        bytes32[] _deviceTypes,
        bytes32[] _devicePublicKeys)
        public onlyManufacturer whenNotPaused returns (bool)
    {
        require(_deviceIdHashes.length > 0, "at least one device is required");
        require(
            _deviceIdHashes.length == _deviceTypes.length,
            "device type array needs to be same size as devices"
        );
        require(
            _deviceIdHashes.length == _devicePublicKeys.length,
            "device public key array needs to be same size as devices"
        );

        uint256 runningBalance = 0;
        uint256 registrationFee = settings.registrationFee();
        for (uint256 i = 0; i < _deviceIdHashes.length; i++) {
            bytes32 deviceIdHash = _deviceIdHashes[i];
            bytes32 deviceType = _deviceTypes[i];
            bytes32 devicePublicKey = _devicePublicKeys[i];
            Device memory d = _registerDevice(msg.sender, deviceIdHash, deviceType, devicePublicKey);
            emit DeviceRegistered(msg.sender, registrationFee, deviceIdHash, d.manufacturerId, deviceType);

            runningBalance = runningBalance.add(registrationFee);
        }

        _depositTokens(msg.sender, runningBalance);
        require(token.transferFrom(msg.sender, address(this), runningBalance), "transferFrom failed");
        return true;
    }

     
     
     
     
     
     
     
     
     
     
     
    function addNetworkMember(
        address _member,
        bool _isIRNAdmin,
        bool _isManufacturer,
        bool _isIRNNode,
        bytes32 _memberId)
        public onlyIRNorOwner returns(bool)
    {
        NetworkMember storage m = network[_member];
        require(!m.isIRNAdmin, "already an irn admin");
        require(!m.isManufacturer, "already a manufacturer");
        require(!m.isIRNNode, "already an irn node");
        require(m.memberId == 0, "already assigned a member id");

        m.isIRNAdmin = _isIRNAdmin;
        m.isManufacturer = _isManufacturer;
        m.isIRNNode = _isIRNNode;
        m.memberId = _memberId;

        if (m.isManufacturer) {
            require(_memberId != 0, "manufacturer id is required");

             
            require(manufacturerRewards[m.memberId] == address(0), "manufacturer is already assigned");
            manufacturerRewards[m.memberId] = _member;

             
            if (pools[_member].rewardAmount == 0) {
                pools[_member].rewardAmount = settings.defaultReputationReward();
            }
        }

        emit NetworkMemberAdded(msg.sender, _member, _memberId);

        return true;
    }

     
     
     
     
    function removeNetworkMember(address _member) public onlyIRNorOwner returns(bool) {
        bytes32 memberId = network[_member].memberId;
        if (network[_member].isManufacturer) {
             
            if (pools[_member].balance == 0) {
                delete pools[_member];
            }

             
            delete manufacturerRewards[memberId];
        }

        delete network[_member];

        emit NetworkMemberRemoved(msg.sender, _member, memberId);
        return true;
    }

     
     
     
     
     
     
     
    function changeManufacturerWallet(address _new) public onlyManufacturer returns (bool) {
        require(_new != address(0), "new address cannot be 0x0");

        NetworkMember memory old = network[msg.sender];
        require(old.isManufacturer && old.memberId != 0, "must be a manufacturer");

         
        require(!network[_new].isIRNAdmin, "already an irn admin");
        require(!network[_new].isManufacturer, "already a manufacturer");
        require(!network[_new].isIRNNode, "already an irn node");
        require(network[_new].memberId == 0, "memberId already exists");
        network[_new] = NetworkMember(
            old.isIRNAdmin,
            old.isManufacturer,
            old.isIRNNode,
            old.memberId
        );

         
        require(pools[_new].balance == 0 && pools[_new].rewardAmount == 0, "new token pool already exists");
        pools[_new].balance = pools[msg.sender].balance;
        pools[_new].rewardAmount = pools[msg.sender].rewardAmount;
        delete pools[msg.sender];

         
        manufacturerRewards[old.memberId] = _new;

         
        delete network[msg.sender];

        emit ManufacturerRewardWalletChanged(msg.sender, _new, old.memberId);
        return true;
    }

     
     
     
     
    function setTokenPoolReward(uint256 newReward) public onlyManufacturer returns (bool) {
        require(newReward != 0, "newReward is required");

        TokenPool storage p = pools[msg.sender];
        require(p.rewardAmount != newReward, "newReward should be different");

        p.rewardAmount = newReward;
        emit TokenPoolRewardUpdated(msg.sender, newReward);
        return true;
    }

     
     
     
    function depositTokens(bytes32 manufacturerId, uint256 amount) public returns (bool) {
        require(manufacturerId != 0, "manufacturerId is required");
        require(amount > 0, "amount is required");

        address manufacturer = manufacturerRewards[manufacturerId];
        require(manufacturer != address(0));

        _depositTokens(manufacturer, amount);
        emit TokensDeposited(msg.sender, manufacturerId, manufacturer, amount);

        require(token.transferFrom(msg.sender, address(this), amount));
        return true;
    }

     
     
     
    function withdrawTokens() public whenNotPaused returns (bool) {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "amount is zero");

        rewards[msg.sender] = 0;
        emit TokensWithdrawn(msg.sender, amount);

        require(token.transfer(msg.sender, amount), "token transfer failed");
        return true;
    }

     
     
     
     
     
    function setDefaultReputationForManufacturer(
        bytes32 _manufacturerId,
        bytes32 _newDefaultScore) public onlyOwner returns (bool) {
        require(_manufacturerId != 0, "_manufacturerId is required");
        require(
            _newDefaultScore != defaultManufacturerReputations[_manufacturerId],
            "_newDefaultScore should be different"
        );

        defaultManufacturerReputations[_manufacturerId] = _newDefaultScore;
        emit DefaultReputationScoreChanged(msg.sender, _manufacturerId, _newDefaultScore);
        return true;
    }

     
     
     
     
    function _depositTokens(address _owner, uint256 _amount) internal {
        pools[_owner].balance = pools[_owner].balance.add(_amount);
    }

     
    function _distributeRewards(address _manufacturer, address _owner, uint256 _amount) internal {
        require(_amount > 0, "_amount is required");
        pools[_manufacturer].balance = pools[_manufacturer].balance.sub(_amount);
        rewards[_owner] = rewards[_owner].add(_amount);
    }

     
     
    function _registerDevice(
        address _manufacturer,
        bytes32 _deviceIdHash,
        bytes32 _deviceType,
        bytes32 _devicePublicKey) internal returns (Device) {
        require(_manufacturer != address(0), "manufacturer is required");
        require(_deviceIdHash != 0, "device id hash is required");
        require(_deviceType != 0, "device type is required");
        require(_devicePublicKey != 0, "device public key is required");

        Device storage d = devices[_deviceIdHash];
        require(!d.registered, "device is already registered");
        require(!d.activated, "device is already activated");

        bytes32 manufacturerId = network[_manufacturer].memberId;
        require(manufacturerId != 0, "manufacturer id is unknown");

        d.manufacturerId = manufacturerId;
        d.deviceType = _deviceType;
        d.registered = true;
        d.activated = false;
        d.reputationScore = defaultManufacturerReputations[manufacturerId];
        d.devicePublicKey = _devicePublicKey;
        return d;
    }

     
     
    function _activateDevice(bytes32 _deviceId) internal returns (Device) {
        bytes32 deviceIdHash = keccak256(_deviceId);
        Device storage d = devices[deviceIdHash];
        require(d.registered, "not registered");
        require(!d.activated, "already activated");
        require(d.manufacturerId != 0, "no manufacturer id was found");

        d.activated = true;
        return d;
    }

     
     
    function _updateReputationScore(bytes32 _deviceId, bytes32 _reputationScore) internal returns (Device) {
        require(_deviceId != 0, "device id is empty");

        Device storage d = devices[keccak256(_deviceId)];
        require(d.registered, "not registered");
        require(d.activated, "not activated");
        require(d.reputationScore != _reputationScore, "new score needs to be different");

        d.reputationScore = _reputationScore;
        return d;
    }
}