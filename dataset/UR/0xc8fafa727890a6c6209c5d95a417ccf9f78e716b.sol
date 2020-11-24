 

pragma solidity 0.4.18;

contract Managble {
    address public manager;

    function Managble() {
        manager = msg.sender;
    }

    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

    function changeManager(address newManager) onlyManager {
        if (newManager != address(0)) {
            manager = newManager;
        }
    }
}

contract Pausable is Managble {
    
    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() onlyManager whenNotPaused returns (bool) {
        paused = true;
        Pause();
        return true;
    }

    function unpause() onlyManager whenPaused returns (bool) {
        paused = false;
        Unpause();
        return true;
    }
}

contract SafeMath {
  function assert(bool assertion) internal {
    if (!assertion) throw;
  }

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
}

contract RedPocket is Pausable, SafeMath {

     
    uint public minReward = 20000000000000000;  
    uint public promotionCommisionPercent = 1;  
    
    Promotion[] public allPromotions;
    mapping (uint256 => address) public promotionIndexToHost;  
    mapping (address => uint256) hostingCount;  
    mapping (uint256 => address) public promotionIndexToClaimant;  
    mapping (address => uint256) claimedCount;  

     
    uint32[14] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];


     
    uint[] public finishedPromotionIDs;
    uint public numOfFinishedPromotions;

     
     

     

     
    struct Promotion {
        uint id;
        address host;  
        string name;  
        string msg;  
        string url;

        uint eachRedPocketAmt;  
        uint maxRedPocketNum; 
        uint claimedNum;
        uint moneyPool;

        uint startBlock;  
        uint blockLast;  

        bool finished;
    }

     
    function RedPocket() { }

     
    function newPromotion(
        string _name, 
        string _msg, 
        string _url,
        uint _eachAmt,
        uint _maxNum,
        uint _blockStart,
        uint _blockLast
    ) 
        whenNotPaused
        payable
        returns (uint)
    {
         
        require(_eachAmt > minReward);  

         
        uint256 inputAmt = _eachAmt * _maxNum;  
        require(inputAmt <= msg.value); 

         
        require (manager.send(safeDiv(safeMul(msg.value, promotionCommisionPercent), 100)));
        uint deposit = safeDiv(safeMul(msg.value, 100 - promotionCommisionPercent), 100);

        Promotion memory _promotion = Promotion({
            id: allPromotions.length,
            host: msg.sender,
            name: _name,
            msg: _msg,
            url: _url,
            eachRedPocketAmt: safeDiv(deposit, _maxNum),
            maxRedPocketNum: _maxNum,
            claimedNum: 0,
            moneyPool: deposit,
            startBlock: _blockStart,
            blockLast: _blockLast,
            finished: false
        });
        uint256 newPromotionId = allPromotions.push(_promotion) - 1;  

        promotionIndexToHost[newPromotionId] = msg.sender;
        hostingCount[msg.sender]++;

        return newPromotionId;
    }

     
    function claimReward(uint _promoteID, uint _moneyPool) whenNotPaused {
        Promotion storage p = allPromotions[_promoteID];

         
        require(p.moneyPool == _moneyPool); 

         
        require(p.finished == false);

         
        require(!_claims(msg.sender, _promoteID));

         
        if (msg.sender.send(p.eachRedPocketAmt)) {
            p.moneyPool -= p.eachRedPocketAmt;
            p.claimedNum++;
            promotionIndexToClaimant[_promoteID] = msg.sender;
            claimedCount[msg.sender]++;
        }

         
        if (p.moneyPool < p.eachRedPocketAmt || p.claimedNum >= p.maxRedPocketNum || (block.number - p.startBlock >= p.blockLast)) {
            p.finished = true;
            finishedPromotionIDs.push(_promoteID);
            numOfFinishedPromotions++;
        }
    }

     
    function totalPromotions() public view returns (uint) {
        return allPromotions.length;
    }

     
    function _claims(address _claimant, uint256 _promotionId) internal returns (bool) {
        return promotionIndexToHost[_promotionId] == _claimant;
    }

     
    function numberOfHosting(address _host) public returns (uint256 count) {
        return hostingCount[_host];
    }

     
    function promotionsOfHost(address _host) external view returns(uint256[] promotionIDs) {
        uint256 count = numberOfHosting(_host);

        if (count == 0) {
            return new uint256[](0);  
        } else {
            uint256[] memory result = new uint256[](count);
            uint256 resultIndex = 0;
            uint256 promotionId;

            for (promotionId = 0; promotionId < allPromotions.length; promotionId++) {
                if (promotionIndexToHost[promotionId] == _host) {
                    result[resultIndex] = promotionId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

     
    function numberOfClaimed(address _claimant) public returns (uint256 count) {
        return claimedCount[_claimant];
    }

     
    function promotionsOfClaimant(address _claimant) external view returns(uint256[] promotionIDs) {
        uint256 count = numberOfClaimed(_claimant);

        if (count == 0) {
            return new uint256[](0);  
        } else {
            uint256[] memory result = new uint256[](count);
            uint256 resultIndex = 0;
            uint256 promotionId;

            for (promotionId = 0; promotionId < allPromotions.length; promotionId++) {
                if (promotionIndexToClaimant[promotionId] == _claimant) {
                    result[resultIndex] = promotionId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

     
    function getPromotion(uint256 _id)
        external
        view
        returns (
        uint id,
        address host,
        string name,
        string msg,
        string url,
        uint eachRedPocketAmt,
        uint maxRedPocketNum,
        uint claimedNum,
        uint moneyPool,
        uint startBlock,
        uint blockLast,
        bool finished
    ) {
        Promotion storage p = allPromotions[_id];

        id = p.id;
        host = p.host;
        name = p.name;
        msg = p.msg;
        url = p.url;
        eachRedPocketAmt = p.eachRedPocketAmt;
        maxRedPocketNum = p.maxRedPocketNum;
        claimedNum = p.claimedNum;
        moneyPool = p.moneyPool;
        startBlock = p.startBlock;
        blockLast = p.blockLast;
        finished = p.finished;
    }

     
    function safeWithdraw(uint _promoteID) whenNotPaused {
        Promotion storage p = allPromotions[_promoteID];
        require(p.finished == true);
        
        if (msg.sender.send(p.moneyPool)) {
            p.moneyPool = 0;
        }
    }

     
    function endPromotion(uint _promoteID) {
        Promotion storage p = allPromotions[_promoteID];
        require(msg.sender == p.host || msg.sender == manager);
        p.finished = true;
	}

    function updateCommission(uint _newPercent) whenNotPaused onlyManager {
        promotionCommisionPercent = _newPercent;
    }

    function updateMinReward(uint _newReward) whenNotPaused onlyManager {
        minReward = _newReward;
    }

    function drain() whenPaused onlyManager {
		if (!manager.send(this.balance)) throw;
	}

}