 

pragma solidity ^0.4.24;

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

contract Owned {
    address public owner;

    event LogNew(address indexed old, address indexed current);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        emit LogNew(owner, _newOwner);
        owner = _newOwner;
    }
}

contract IMoneyManager {
    function payTo(address _participant, uint256 _revenue) payable public returns(bool);
}

contract Game is Owned {
    using SafeMath for uint256;
    
     
    address public ownerWallet;
     
    mapping(address => bool) internal activator;
    
     
    uint256 public constant BET = 10 finney;  
    uint8 public constant ODD = 1;
    uint8 public constant EVEN = 2;
    uint8 public constant noBets = 3;
    uint256 public constant COMMISSION_PERCENTAGE = 10;
    uint256 public constant END_DURATION_BETTING_BLOCK = 5520;
    uint256 public constant TARGET_DURATION_BETTING_BLOCK = 5760;
	
	uint256 public constant CONTRACT_VERSION = 201805311200;
    
     
    address public moneyManager;
    
     
    uint256[] targetBlocks;
    
     
    mapping(address => Participant) public participants;

    mapping(uint256 => mapping(uint256 => uint256)) oddAndEvenBets;  

    mapping(uint256 => uint256) blockResult;  
    mapping(uint256 => bytes32) blockHash;  

    mapping(uint256 => uint256) blockRevenuePerTicket;  
    mapping(uint256 => bool) isBlockRevenueCalculated;  

    mapping(uint256 => uint256) comissionsAtBlock;  
    
     
    uint256 public _startBetBlock;
    uint256 public _endBetBlock;

    uint256 public _targetBlock;
    
     
    modifier afterBlock(uint256 _blockNumber) {
        require(block.number >= _blockNumber);
        _;
    }

    modifier onlyActivator(address _activator) {
        require(activator[_activator] == true);
        _;
    }
    
     
    struct Participant {
        mapping(uint256 => Bet) bets;
        bool isParticipated;
    }

    struct Bet {
        uint256 ODDBets;
		uint256 EVENBets;
        bool isRevenuePaid;
    }
    
     
    constructor(address _moneyManager, address _ownerWallet) public {
        setMoneyManager(_moneyManager);
        setOwnerWallet(_ownerWallet);
    }
    
     
    function() payable public {
        bet(getBlockHashOddOrEven(block.number - 128), msg.value.div(BET));
    }
    
     
    function activateCycle(uint256 _startBlock) public onlyActivator(msg.sender) returns (bool _success) {
        if (_startBlock == 0) {
            _startBlock = block.number;
        }
        require(block.number >= _endBetBlock);

        _startBetBlock = _startBlock;
        _endBetBlock = _startBetBlock.add(END_DURATION_BETTING_BLOCK);

        _targetBlock = _startBetBlock.add(TARGET_DURATION_BETTING_BLOCK);
        targetBlocks.push(_targetBlock);

        return true;
    }
    
     
    event LogBet(address indexed participant, uint256 blockNumber, uint8 oddOrEven, uint256 betAmount);
    event LogNewParticipant(address indexed _newParticipant);
    
     
    function bet(uint8 oddOrEven, uint256 betsAmount) public payable returns (bool _success) {
		require(betsAmount > 0);
		uint256 participantBet = betsAmount.mul(BET);
		require(msg.value == participantBet);
        require(oddOrEven == ODD || oddOrEven == EVEN);
        require(block.number <= _endBetBlock && block.number >= _startBetBlock);

		 
		if (participants[msg.sender].isParticipated == false) {
			 
			Participant memory newParticipant;
			newParticipant.isParticipated = true;
			 
			participants[msg.sender] = newParticipant;
			emit LogNewParticipant(msg.sender);
		}
		
		uint256 betTillNowODD = participants[msg.sender].bets[_targetBlock].ODDBets;
		uint256 betTillNowEVEN = participants[msg.sender].bets[_targetBlock].EVENBets;
		if(oddOrEven == ODD) {
			betTillNowODD = betTillNowODD.add(participantBet);
		} else {
			betTillNowEVEN = betTillNowEVEN.add(participantBet);
		}
		Bet memory newBet = Bet({ODDBets : betTillNowODD, EVENBets: betTillNowEVEN, isRevenuePaid : false});
	
         
        participants[msg.sender].bets[_targetBlock] = newBet;
         
        oddAndEvenBets[_targetBlock][oddOrEven] = oddAndEvenBets[_targetBlock][oddOrEven].add(msg.value);
        address(moneyManager).transfer(msg.value);
        emit LogBet(msg.sender, _targetBlock, oddOrEven, msg.value);

        return true;
    }
    
     
    function calculateRevenueAtBlock(uint256 _blockNumber) public afterBlock(_blockNumber) {
        require(isBlockRevenueCalculated[_blockNumber] == false);
        if(oddAndEvenBets[_blockNumber][ODD] > 0 || oddAndEvenBets[_blockNumber][EVEN] > 0) {
            blockResult[_blockNumber] = getBlockHashOddOrEven(_blockNumber);
            require(blockResult[_blockNumber] == ODD || blockResult[_blockNumber] == EVEN);
            if (blockResult[_blockNumber] == ODD) {
                calculateRevenue(_blockNumber, ODD, EVEN);
            } else if (blockResult[_blockNumber] == EVEN) {
                calculateRevenue(_blockNumber, EVEN, ODD);
            }
        } else {
            isBlockRevenueCalculated[_blockNumber] = true;
            blockResult[_blockNumber] = noBets;
        }
    }

    event LogOddOrEven(uint256 blockNumber, bytes32 blockHash, uint256 oddOrEven);
    
     
    function getBlockHashOddOrEven(uint256 _blockNumber) internal returns (uint8 oddOrEven) {
        blockHash[_blockNumber] = blockhash(_blockNumber);
        uint256 result = uint256(blockHash[_blockNumber]);
        uint256 lastChar = (result * 2 ** 252) / (2 ** 252);
        uint256 _oddOrEven = lastChar % 2;

        emit LogOddOrEven(_blockNumber, blockHash[_blockNumber], _oddOrEven);

        if (_oddOrEven == 1) {
            return ODD;
        } else if (_oddOrEven == 0) {
            return EVEN;
        }
    }

    event LogRevenue(uint256 blockNumber, uint256 winner, uint256 revenue);
    
     
    function calculateRevenue(uint256 _blockNumber, uint256 winner, uint256 loser) internal {
        uint256 revenue = oddAndEvenBets[_blockNumber][loser];
        if (oddAndEvenBets[_blockNumber][ODD] != 0 && oddAndEvenBets[_blockNumber][EVEN] != 0) {
            uint256 comission = (revenue.div(100)).mul(COMMISSION_PERCENTAGE);
            revenue = revenue.sub(comission);
            comissionsAtBlock[_blockNumber] = comission;
            IMoneyManager(moneyManager).payTo(ownerWallet, comission);
            uint256 winners = oddAndEvenBets[_blockNumber][winner].div(BET);
            blockRevenuePerTicket[_blockNumber] = revenue.div(winners);
        }
        isBlockRevenueCalculated[_blockNumber] = true;
        emit LogRevenue(_blockNumber, winner, revenue);
    }

    event LogpayToRevenue(address indexed participant, uint256 blockNumber, bool revenuePaid);
    
     
    function withdrawRevenue(uint256 _blockNumber) public returns (bool _success) {
        require(participants[msg.sender].bets[_blockNumber].ODDBets > 0 || participants[msg.sender].bets[_blockNumber].EVENBets > 0);
        require(participants[msg.sender].bets[_blockNumber].isRevenuePaid == false);
        require(isBlockRevenueCalculated[_blockNumber] == true);

        if (oddAndEvenBets[_blockNumber][ODD] == 0 || oddAndEvenBets[_blockNumber][EVEN] == 0) {
			if(participants[msg.sender].bets[_blockNumber].ODDBets > 0) {
				IMoneyManager(moneyManager).payTo(msg.sender, participants[msg.sender].bets[_blockNumber].ODDBets);
			}else{
				IMoneyManager(moneyManager).payTo(msg.sender, participants[msg.sender].bets[_blockNumber].EVENBets);
			}
            participants[msg.sender].bets[_blockNumber].isRevenuePaid = true;
            emit LogpayToRevenue(msg.sender, _blockNumber, participants[msg.sender].bets[_blockNumber].isRevenuePaid);

            return participants[msg.sender].bets[_blockNumber].isRevenuePaid;
        }
         
        uint256 _revenue = 0;
        uint256 counter = 0;
		uint256 totalPayment = 0;
        if (blockResult[_blockNumber] == ODD) {
			counter = (participants[msg.sender].bets[_blockNumber].ODDBets).div(BET);
            _revenue = _revenue.add(blockRevenuePerTicket[_blockNumber].mul(counter));
        } else if (blockResult[_blockNumber] == EVEN) {
			counter = (participants[msg.sender].bets[_blockNumber].EVENBets).div(BET);
           _revenue = _revenue.add(blockRevenuePerTicket[_blockNumber].mul(counter));
        }
		totalPayment = _revenue.add(BET.mul(counter));
         
        IMoneyManager(moneyManager).payTo(msg.sender, totalPayment);
        participants[msg.sender].bets[_blockNumber].isRevenuePaid = true;

        emit LogpayToRevenue(msg.sender, _blockNumber, participants[msg.sender].bets[_blockNumber].isRevenuePaid);
        return participants[msg.sender].bets[_blockNumber].isRevenuePaid;
    }
    
     
    function setActivator(address _newActivator) onlyOwner public returns(bool) {
        require(activator[_newActivator] == false);
        activator[_newActivator] = true;
        return activator[_newActivator];
    }
    
     
    function removeActivator(address _Activator) onlyOwner public returns(bool) {
        require(activator[_Activator] == true);
        activator[_Activator] = false;
        return true;
    }
    
     
    function setOwnerWallet(address _newOwnerWallet) public onlyOwner {
        emit LogNew(ownerWallet, _newOwnerWallet);
        ownerWallet = _newOwnerWallet;
    }
    
     
    function setMoneyManager(address _moneyManager) public onlyOwner {
        emit LogNew(moneyManager, _moneyManager);
        moneyManager = _moneyManager;
    }
    
    function getActivator(address _isActivator) public view returns(bool) {
        return activator[_isActivator];
    }
    
     
    function getblock() public view returns (uint256 _blockNumber){
        return block.number;
    }

     
    function getCycleInfo() public view returns (uint256 startBetBlock, uint256 endBetBlock, uint256 targetBlock){
        return (
        _startBetBlock,
        _endBetBlock,
        _targetBlock);
    }
    
     
    function getBlockHash(uint256 _blockNumber) public view returns (bytes32 _blockHash) {
        return blockHash[_blockNumber];
    }
    
     
    function getBetAt(address _participant, uint256 _blockNumber) public view returns (uint256 _oddBets, uint256 _evenBets){
        return (participants[_participant].bets[_blockNumber].ODDBets, participants[_participant].bets[_blockNumber].EVENBets);
    }
    
     
    function getBlockResult(uint256 _blockNumber) public view returns (uint256 _oddOrEven){
        return blockResult[_blockNumber];
    }
    
     
    function getoddAndEvenBets(uint256 _blockNumber, uint256 _blockOddOrEven) public view returns (uint256 _weiAmountAtStage) {
        return oddAndEvenBets[_blockNumber][_blockOddOrEven];
    }
    
     
    function getIsParticipate(address _participant, uint256 _blockNumber) public view returns (bool _isParticipate) {
        return (participants[_participant].bets[_blockNumber].ODDBets > 0 || participants[_participant].bets[_blockNumber].EVENBets > 0);
    }
    
      
    function getblockRevenuePerTicket(uint256 _blockNumber) public view returns (uint256 _revenue) {
        return blockRevenuePerTicket[_blockNumber];
    }
    
     
    function getIsBlockRevenueCalculated(uint256 _blockNumber) public view returns (bool _isCalculated) {
        return isBlockRevenueCalculated[_blockNumber];
    }
    
     
    function getIsRevenuePaid(address _participant, uint256 _blockNumber) public view returns (bool _isPaid) {
        return participants[_participant].bets[_blockNumber].isRevenuePaid;
    }
    
     
    function getBlockComission(uint256 _blockNumber) public view returns (uint256 _comission) {
        return comissionsAtBlock[_blockNumber];
    }
    
     
    function getBetsEvenAndODD(uint256 _blockNumber) public view returns (uint256 _ODDBets, uint256 _EVENBets) {
        return (oddAndEvenBets[_blockNumber][ODD], oddAndEvenBets[_blockNumber][EVEN]);
    }

     
    function getTargetBlockLength() public view returns (uint256 _targetBlockLenght) {
        return targetBlocks.length;
    }
    
     
    function getTargetBlocks() public view returns (uint256[] _targetBlocks) {
        return targetBlocks;
    }
    
     
    function getTargetBlock(uint256 _index) public view returns (uint256 _targetBlockNumber) {
        return targetBlocks[_index];
    }
}