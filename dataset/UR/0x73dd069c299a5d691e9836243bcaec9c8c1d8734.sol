 

pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
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


contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) {

     
     
     
     
    if (_value != 0) require(allowed[msg.sender][_spender] == 0);

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract Transmutable {
  function transmute(address to, uint256 value) returns (bool, uint256);
  event Transmuted(address indexed who, address baseContract, address transmutedContract, uint256 sourceQuantity, uint256 destQuantity);
}

 
contract TransmutableInterface {
  function transmuted(uint256 _value) returns (bool, uint256);
}



contract ERC20Mineable is StandardToken, ReentrancyGuard  {

   uint256 public constant divisible_units = 10000000;
   uint256 public constant decimals = 8;

   uint256 public constant initial_reward = 100;

    
   uint256 public maximumSupply;

    
   uint256 public currentDifficultyWei;

    
   uint256 public minimumDifficultyThresholdWei;

    
   uint256 public blockCreationRate;

    
   uint256 public difficultyAdjustmentPeriod;

    
   uint256 public lastDifficultyAdjustmentEthereumBlock;

    
   uint256 public constant difficultyScaleMultiplierLimit = 4;

    
   uint256 public totalBlocksMined;

    

   uint256 public rewardAdjustmentPeriod; 

    
   uint256 public totalWeiCommitted;
    
   uint256 public totalWeiExpected;

    
   address public burnAddress;

    

   struct InternalBlock {
      uint256 targetDifficultyWei;
      uint256 blockNumber;
      uint256 totalMiningWei;
      uint256 totalMiningAttempts;
      uint256 currentAttemptOffset;
      bool payed;
      address payee;
      bool isCreated;
   }

    
   struct MiningAttempt {
      uint256 projectedOffset;
      uint256 value;
      bool isCreated;
   }

    
   mapping (uint256 => InternalBlock) public blockData;
   mapping (uint256 => mapping (address => MiningAttempt)) public miningAttempts;

    

   function resolve_block_hash(uint256 _blockNum) public constant returns (bytes32) {
       return block.blockhash(_blockNum);
   }

   function current_external_block() public constant returns (uint256) {
       return block.number;
   }

   function external_to_internal_block_number(uint256 _externalBlockNum) public constant returns (uint256) {
       
      return _externalBlockNum / blockCreationRate;
   }

    
   function get_internal_block_number() public constant returns (uint256) {
     return external_to_internal_block_number(current_external_block());
   }

    
    

   function getContractState() external constant
     returns (uint256,   
              uint256,   
              uint256,   
              uint256,   
              uint256,   
              uint256,   
              uint256,   
              uint256,   
              uint256,   
              uint256,   
              uint256,   
              uint256,   
              uint256   
              ) {
    InternalBlock memory b;
    uint256 _blockNumber = external_to_internal_block_number(current_external_block());
    if (!blockData[_blockNumber].isCreated) {
        b = InternalBlock(
                       {targetDifficultyWei: currentDifficultyWei,
                       blockNumber: _blockNumber,
                       totalMiningWei: 0,
                       totalMiningAttempts: 0,
                       currentAttemptOffset: 0,
                       payed: false,
                       payee: 0,
                       isCreated: true
                       });
    } else {
         b = blockData[_blockNumber];
    }
    return (currentDifficultyWei,
            minimumDifficultyThresholdWei,
            _blockNumber,
            blockCreationRate,
            difficultyAdjustmentPeriod,
            rewardAdjustmentPeriod,
            lastDifficultyAdjustmentEthereumBlock,
            totalBlocksMined,
            totalWeiCommitted,
            totalWeiExpected,
            b.targetDifficultyWei,
            b.totalMiningWei,
            b.currentAttemptOffset);
   }

   function getBlockData(uint256 _blockNum) public constant returns (uint256, uint256, uint256, uint256, uint256, bool, address, bool) {
    InternalBlock memory iBlock = blockData[_blockNum];
    return (iBlock.targetDifficultyWei,
    iBlock.blockNumber,
    iBlock.totalMiningWei,
    iBlock.totalMiningAttempts,
    iBlock.currentAttemptOffset,
    iBlock.payed,
    iBlock.payee,
    iBlock.isCreated);
   }

   function getMiningAttempt(uint256 _blockNum, address _who) public constant returns (uint256, uint256, bool) {
     if (miningAttempts[_blockNum][_who].isCreated) {
        return (miningAttempts[_blockNum][_who].projectedOffset,
        miningAttempts[_blockNum][_who].value,
        miningAttempts[_blockNum][_who].isCreated);
     } else {
        return (0, 0, false);
     }
   }

    

   modifier blockCreated(uint256 _blockNum) {
     require(blockData[_blockNum].isCreated);
     _;
   }

   modifier blockRedeemed(uint256 _blockNum) {
     require(_blockNum != current_external_block());
      
     require(blockData[_blockNum].isCreated);
     require(!blockData[_blockNum].payed);
     _;
   }

   modifier initBlock(uint256 _blockNum) {
     require(_blockNum != current_external_block());

     if (!blockData[_blockNum].isCreated) {
        
       adjust_difficulty();

        
       blockData[_blockNum] = InternalBlock(
                                     {targetDifficultyWei: currentDifficultyWei,
                                      blockNumber: _blockNum,
                                      totalMiningWei: 0,
                                      totalMiningAttempts: 0,
                                      currentAttemptOffset: 0,
                                      payed: false,
                                      payee: 0,
                                      isCreated: true
                                      });
     }
     _;
   }

   modifier isValidAttempt() {
      
     uint256 minimum_wei = currentDifficultyWei / divisible_units; 
     require (msg.value >= minimum_wei);

      
     require(msg.value <= (1000000 ether));
     _;
   }

   modifier alreadyMined(uint256 blockNumber, address sender) {
     require(blockNumber != current_external_block()); 
     
    
     
    require(!checkMiningAttempt(blockNumber, sender));
    _;
   }

   function checkMiningActive() public constant returns (bool) {
      return (totalSupply < maximumSupply);
   }

   modifier isMiningActive() {
      require(checkMiningActive());
      _;
   }

   function burn(uint256 value) internal {
       
      bool ret = burnAddress.send(value);
       
      require (ret);
   }

   event MiningAttemptEvent(
       address indexed _from,
       uint256 _value,
       uint256 indexed _blockNumber,
       uint256 _totalMinedWei,
       uint256 _targetDifficultyWei
   );

   event LogEvent(
       string _info
   );

    

   function mine() external payable 
                           nonReentrant
                           isValidAttempt
                           isMiningActive
                           initBlock(external_to_internal_block_number(current_external_block()))
                           blockRedeemed(external_to_internal_block_number(current_external_block()))
                           alreadyMined(external_to_internal_block_number(current_external_block()), msg.sender) returns (bool) {
       
      uint256 internalBlockNum = external_to_internal_block_number(current_external_block());
      miningAttempts[internalBlockNum][msg.sender] =
                     MiningAttempt({projectedOffset: blockData[internalBlockNum].currentAttemptOffset,
                                    value: msg.value,
                                    isCreated: true});

       
      blockData[internalBlockNum].totalMiningAttempts += 1;
      blockData[internalBlockNum].totalMiningWei += msg.value;
      totalWeiCommitted += msg.value;

       
      blockData[internalBlockNum].currentAttemptOffset += msg.value;
      MiningAttemptEvent(msg.sender,
                         msg.value,
                         internalBlockNum,
                         blockData[internalBlockNum].totalMiningWei,
                         blockData[internalBlockNum].targetDifficultyWei
                         );
       
      burn(msg.value);
      return true;
   }

    

   modifier userMineAttempted(uint256 _blockNum, address _user) {
      require(checkMiningAttempt(_blockNum, _user));
      _;
   }
   
   modifier isBlockMature(uint256 _blockNumber) {
      require(_blockNumber != current_external_block());
      require(checkBlockMature(_blockNumber, current_external_block()));
      require(checkRedemptionWindow(_blockNumber, current_external_block()));
      _;
   }

    
    
   modifier isBlockReadable(uint256 _blockNumber) {
      InternalBlock memory iBlock = blockData[_blockNumber];
      uint256 targetBlockNum = targetBlockNumber(_blockNumber);
      require(resolve_block_hash(targetBlockNum) != 0);
      _;
   }

   function calculate_difficulty_attempt(uint256 targetDifficultyWei,
                                         uint256 totalMiningWei,
                                         uint256 value) public constant returns (uint256) {
       
       
      uint256 selectedDifficultyWei = 0;
      if (totalMiningWei > targetDifficultyWei) {
         selectedDifficultyWei = totalMiningWei;
      } else {
         selectedDifficultyWei = targetDifficultyWei; 
      }

       

      uint256 intermediate = ((value * divisible_units) / selectedDifficultyWei);
      uint256 max_int = 0;
       
      max_int = max_int - 1;

      if (intermediate >= divisible_units) {
         return max_int;
      } else {
         return intermediate * (max_int / divisible_units);
      }
   }

   function calculate_range_attempt(uint256 difficulty, uint256 offset) public constant returns (uint256, uint256) {
        
       require(offset + difficulty >= offset);
       return (offset, offset+difficulty);
   }

    
    
   function calculate_proportional_reward(uint256 _baseReward, uint256 _userContributionWei, uint256 _totalCommittedWei) public constant returns (uint256) {
   require(_userContributionWei <= _totalCommittedWei);
   require(_userContributionWei > 0);
   require(_totalCommittedWei > 0);
      uint256 intermediate = ((_userContributionWei * divisible_units) / _totalCommittedWei);

      if (intermediate >= divisible_units) {
         return _baseReward;
      } else {
         return intermediate * (_baseReward / divisible_units);
      }
   }

   function calculate_base_mining_reward(uint256 _totalBlocksMined) public constant returns (uint256) {
       
      uint256 mined_block_period = 0;
      if (_totalBlocksMined < 210000) {
           mined_block_period = 210000;
      } else {
           mined_block_period = _totalBlocksMined;
      }

       
       
      uint256 total_reward = initial_reward * (10 ** decimals); 
      uint256 i = 1;
      uint256 rewardperiods = mined_block_period / 210000;
      if (mined_block_period % 210000 > 0) {
         rewardperiods += 1;
      }
      for (i=1; i < rewardperiods; i++) {
          total_reward = total_reward / 2;
      }
      return total_reward;
   }

    
    
   function calculate_next_expected_wei(uint256 _totalWeiCommitted,
                                        uint256 _totalWeiExpected,
                                        uint256 _minimumDifficultyThresholdWei,
                                        uint256 _difficultyScaleMultiplierLimit) public constant
                                        returns (uint256) {
          
           
          uint256 lowerBound = _totalWeiExpected / _difficultyScaleMultiplierLimit;
          uint256 upperBound = _totalWeiExpected * _difficultyScaleMultiplierLimit;

          if (_totalWeiCommitted < lowerBound) {
              _totalWeiExpected = lowerBound;
          } else if (_totalWeiCommitted > upperBound) {
              _totalWeiExpected = upperBound;
          } else {
              _totalWeiExpected = _totalWeiCommitted;
          }

           
          if (_totalWeiExpected < _minimumDifficultyThresholdWei) {
              _totalWeiExpected = _minimumDifficultyThresholdWei;
          }

          return _totalWeiExpected;
    }

   function adjust_difficulty() internal {
       

      if ((current_external_block() - lastDifficultyAdjustmentEthereumBlock) > (difficultyAdjustmentPeriod * blockCreationRate)) {

           
          totalWeiExpected = calculate_next_expected_wei(totalWeiCommitted, totalWeiExpected, minimumDifficultyThresholdWei * difficultyAdjustmentPeriod, difficultyScaleMultiplierLimit);

          currentDifficultyWei = totalWeiExpected / difficultyAdjustmentPeriod;

           
          totalWeiCommitted = 0;

           
          lastDifficultyAdjustmentEthereumBlock = current_external_block();

      }
   }

   event BlockClaimedEvent(
       address indexed _from,
       address indexed _forCreditTo,
       uint256 _reward,
       uint256 indexed _blockNumber
   );

   modifier onlyWinner(uint256 _blockNumber) {
      require(checkWinning(_blockNumber));
      _;
   }


    
   function calculate_reward(uint256 _totalBlocksMined, address _sender, uint256 _blockNumber) public constant returns (uint256) {
      return calculate_proportional_reward(calculate_base_mining_reward(_totalBlocksMined), miningAttempts[_blockNumber][_sender].value, blockData[_blockNumber].totalMiningWei); 
   }

    
   function claim(uint256 _blockNumber, address forCreditTo)
                  nonReentrant
                  blockRedeemed(_blockNumber)
                  isBlockMature(_blockNumber)
                  isBlockReadable(_blockNumber)
                  userMineAttempted(_blockNumber, msg.sender)
                  onlyWinner(_blockNumber)
                  external returns (bool) {
       
      blockData[_blockNumber].payed = true;
      blockData[_blockNumber].payee = msg.sender;
      totalBlocksMined = totalBlocksMined + 1;

      uint256 proportional_reward = calculate_reward(totalBlocksMined, msg.sender, _blockNumber);
      balances[forCreditTo] = balances[forCreditTo].add(proportional_reward);
      totalSupply += proportional_reward;
      BlockClaimedEvent(msg.sender, forCreditTo,
                        proportional_reward,
                        _blockNumber);
       
       
      Transfer(this, forCreditTo, proportional_reward);
      return true;
   }

    
   function isBlockRedeemed(uint256 _blockNum) constant public returns (bool) {
     if (!blockData[_blockNum].isCreated) {
         return false;
     } else {
         return blockData[_blockNum].payed;
     }
   }

    
   function targetBlockNumber(uint256 _blockNum) constant public returns (uint256) {
      return ((_blockNum + 1) * blockCreationRate);
   }

    
   function checkBlockMature(uint256 _blockNum, uint256 _externalblock) constant public returns (bool) {
     return (_externalblock >= targetBlockNumber(_blockNum));
   }

    

   function checkRedemptionWindow(uint256 _blockNum, uint256 _externalblock) constant public returns (bool) {
       uint256 _targetblock = targetBlockNumber(_blockNum);
       return _externalblock >= _targetblock && _externalblock < (_targetblock + 256);
   }

    
   function checkMiningAttempt(uint256 _blockNum, address _sender) constant public returns (bool) {
       return miningAttempts[_blockNum][_sender].isCreated;
   }

    
   function checkWinning(uint256 _blockNum) constant public returns (bool) {
     if (checkMiningAttempt(_blockNum, msg.sender) && checkBlockMature(_blockNum, current_external_block())) {

      InternalBlock memory iBlock = blockData[_blockNum];
      uint256 targetBlockNum = targetBlockNumber(iBlock.blockNumber);
      MiningAttempt memory attempt = miningAttempts[_blockNum][msg.sender];

      uint256 difficultyAttempt = calculate_difficulty_attempt(iBlock.targetDifficultyWei, iBlock.totalMiningWei, attempt.value);
      uint256 beginRange;
      uint256 endRange;
      uint256 targetBlockHashInt;

      (beginRange, endRange) = calculate_range_attempt(difficultyAttempt,
          calculate_difficulty_attempt(iBlock.targetDifficultyWei, iBlock.totalMiningWei, attempt.projectedOffset)); 
      targetBlockHashInt = uint256(keccak256(resolve_block_hash(targetBlockNum)));
   
       
      if ((beginRange < targetBlockHashInt) && (endRange >= targetBlockHashInt))
      {
        return true;
      }
     
     }

     return false;
     
   }

}



contract Bitcoineum is ERC20Mineable, Transmutable {

 string public constant name = "Bitcoineum";
 string public constant symbol = "BTE";
 uint256 public constant decimals = 8;
 uint256 public constant INITIAL_SUPPLY = 0;

  
 uint256 public constant MAX_SUPPLY = 21000000 * (10**8);
 
 function Bitcoineum() {

    totalSupply = INITIAL_SUPPLY;
    maximumSupply = MAX_SUPPLY;

     
     
     
    currentDifficultyWei = 100 szabo;
    minimumDifficultyThresholdWei = 100 szabo;
    
     
     
    blockCreationRate = 50;

     
    difficultyAdjustmentPeriod = 2016;

     

    rewardAdjustmentPeriod = 210000;

     
    totalBlocksMined = 0;

    totalWeiExpected = difficultyAdjustmentPeriod * currentDifficultyWei;

     
     
    burnAddress = 0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD;

    lastDifficultyAdjustmentEthereumBlock = block.number; 
 }


    

  function transmute(address to, uint256 value) nonReentrant returns (bool, uint256) {
    require(value > 0);
    require(balances[msg.sender] >= value);
    require(totalSupply >= value);
    balances[msg.sender] = balances[msg.sender].sub(value);
    totalSupply = totalSupply.sub(value);
    TransmutableInterface target = TransmutableInterface(to);
    bool _result = false;
    uint256 _total = 0;
    (_result, _total) = target.transmuted(value);
    require (_result);
    Transmuted(msg.sender, this, to, value, _total);
    return (_result, _total);
  }

 }