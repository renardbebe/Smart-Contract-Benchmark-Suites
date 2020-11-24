 

pragma solidity ^0.4.24;
contract BasicAccessControl {
    address public owner;
     
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) onlyOwner public {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }
    
    function RemoveModerator(address _oldModerator) onlyOwner public {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) onlyOwner public {
        isMaintaining = _isMaintaining;
    }
}

interface EtheremonMonsterNFT {
    function mintMonster(uint32 _classId, address _trainer, string _name) external returns(uint);
}

interface EtheremonAdventureItem {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getItemInfo(uint _tokenId) constant external returns(uint classId, uint value);
    function spawnItem(uint _classId, uint _value, address _owner) external returns(uint);
}

contract EtheremonReward is BasicAccessControl {
    bytes constant SIG_PREFIX = "\x19Ethereum Signed Message:\n32";
    
    enum RewardType {
        NONE,
        REWARD_EMONA,
        REWARD_EXP_EMOND,
        REWARD_LEVEL_EMOND
    }
    
     
    struct RewardToken {
        uint rId;
        uint rewardType;
        uint rewardValue;
        uint createTime;
    }
    
    uint public levelItemClass = 200;
    uint public expItemClass = 201;
    
    mapping(uint => uint) public emonaLimit;  
    mapping(uint => uint) public expEmondLimit;  
    mapping(uint => uint) public levelEmondLimit;  
    mapping(uint => uint) public requestStatus;  

     
    address public verifyAddress;
    address public adventureItemContract;
    address public monsterNFT;
    
    function setConfig(address _verifyAddress, address _adventureItemContract, address _monsterNFT) onlyModerators public {
        verifyAddress = _verifyAddress;
        adventureItemContract = _adventureItemContract;
        monsterNFT = _monsterNFT;
    }
    
    function setEmonaLimit(uint _monsterClass, uint _limit) onlyModerators public {
        emonaLimit[_monsterClass] = _limit;
    }
    
    function setExpEmondLimit(uint _expValue, uint _limit) onlyModerators public {
        expEmondLimit[_expValue] = _limit;
    }
    
    function setLevelEmondLimit(uint _levelValue, uint _limit) onlyModerators public {
        levelEmondLimit[_levelValue] = _limit;
    }
    
     
    function extractRewardToken(bytes32 _rt) public pure returns(uint rId, uint rewardType, uint rewardValue, uint createTime) {
        createTime = uint32(_rt>>128);
        rewardValue = uint32(_rt>>160);
        rewardType = uint32(_rt>>192);
        rId = uint32(_rt>>224);
    }
    
    function getVerifySignature(address sender, bytes32 _token) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(sender, _token));
    }
    
    function getVerifyAddress(address sender, bytes32 _token, uint8 _v, bytes32 _r, bytes32 _s) public pure returns(address) {
        bytes32 hashValue = keccak256(abi.encodePacked(sender, _token));
        bytes32 prefixedHash = keccak256(abi.encodePacked(SIG_PREFIX, hashValue));
        return ecrecover(prefixedHash, _v, _r, _s);
    }
    
    function requestReward(bytes32 _token, uint8 _v, bytes32 _r, bytes32 _s) isActive external {
        if (verifyAddress == address(0)) revert();
        if (getVerifyAddress(msg.sender, _token, _v, _r, _s) != verifyAddress) revert();
        RewardToken memory rToken;
        
        (rToken.rId, rToken.rewardType, rToken.rewardValue, rToken.createTime) = extractRewardToken(_token);
        if (rToken.rId == 0 || requestStatus[rToken.rId] > 0) revert();
        
        
        EtheremonMonsterNFT monsterContract = EtheremonMonsterNFT(monsterNFT);
        EtheremonAdventureItem item = EtheremonAdventureItem(adventureItemContract);
        if (rToken.rewardType == uint(RewardType.REWARD_EMONA)) {
            if (emonaLimit[rToken.rewardValue] < 1) revert();
            monsterContract.mintMonster(uint32(rToken.rewardValue), msg.sender,  "..name me..");
            emonaLimit[rToken.rewardValue] -= 1;
            
        } else if (rToken.rewardType == uint(RewardType.REWARD_EXP_EMOND)) {
            if (expEmondLimit[rToken.rewardValue] < 1) revert();
            item.spawnItem(expItemClass, rToken.rewardValue, msg.sender);
            expEmondLimit[rToken.rewardValue] -= 1;
            
        } else if (rToken.rewardType == uint(RewardType.REWARD_LEVEL_EMOND)) {
            if (levelEmondLimit[rToken.rewardValue] < 1) revert();
            item.spawnItem(levelItemClass, rToken.rewardValue, msg.sender);
            levelEmondLimit[rToken.rewardValue] -= 1;

        } else {
            revert();
        }
        
        requestStatus[rToken.rId] = 1;
    }
    
    function getRequestStatus(uint _requestId) public view returns(uint) {
        return requestStatus[_requestId];
    }
    
    
}