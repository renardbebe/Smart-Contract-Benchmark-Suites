 

pragma solidity ^0.4.17;

 


contract ProfitChain {

    using SafeMath256 for uint256;
    using SafeMath32 for uint32;
    
     
    
    struct Investment {
        address investor;                
        uint256 sum;                     
        uint256 time;                    
    }
    
    struct Round {
        mapping(uint32 => Investment) investments;       
        mapping (address => uint32) investorMapping;     
        uint32 totalInvestors;           
        uint256 totalInvestment;         
        address winner;                  
        uint256 lastBlock;               
    }
    
    struct GroupMember {
        uint256 joinTime;                
        address invitor;                 
    }

    struct Group {
        string name;                     
        uint32 roundSize;                
        uint256 investment;              
        uint32 blocksBeforeWinCheck;     
        uint32 securityFactor;           
        uint32 invitationFee;            
        uint32 ownerFee;                 
        uint32 invitationFeePeriod;      
        uint8 invitationFeeDepth;        
        bool active;                     
        mapping (address => GroupMember) members;    
        mapping(uint32 => Round) rounds;             
        uint32 currentRound;             
        uint32 firstUnwonRound;          
    }
    
    
     
    string public contractName = "ProfitChain 1.0";
    uint256 public contractBlock;                
    address public owner;                        
    mapping (address => uint256) balances;       
    Group[] groups;                              
    mapping (string => bool) groupNames;         

     
    modifier onlyOwner() {require(msg.sender == owner); _;}
    
     
    event GroupCreated(uint32 indexed group, uint256 timestamp);
    event GroupClosed(uint32 indexed group, uint256 timestamp);
    event NewInvestor(address indexed investor, uint32 indexed group, uint256 timestamp);
    event Invest(address indexed investor, uint32 indexed group, uint32 indexed round, uint256 timestamp);
    event Winner(address indexed payee, uint32 indexed group, uint32 indexed round, uint256 timestamp);
    event Deposit(address indexed payee, uint256 sum, uint256 timestamp);
    event Withdraw(address indexed payee, uint256 sum, uint256 timestamp);

     
    
     
    function ProfitChain () public {
        owner = msg.sender;
        contractBlock = block.number;
    }

     
    function   () public payable {
        revert();
    } 

     
    function newGroup (
        string _groupName, 
        uint32 _roundSize,
        uint256 _investment,
        uint32 _blocksBeforeWinCheck,
        uint32 _securityFactor,
        uint32 _invitationFee,
        uint32 _ownerFee,
        uint32 _invitationFeePeriod,
        uint8 _invitationFeeDepth
    ) public onlyOwner 
    {
         
        require(_roundSize > 0);
        require(_investment > 0);
        require(_invitationFee.add(_ownerFee) < 1000);
        require(_securityFactor > _roundSize);
         
        require(!groupNameExists(_groupName));
        
         
        Group memory group;
        group.name = _groupName;
        group.roundSize = _roundSize;
        group.investment = _investment;
        group.blocksBeforeWinCheck = _blocksBeforeWinCheck;
        group.securityFactor = _securityFactor;
        group.invitationFee = _invitationFee;
        group.ownerFee = _ownerFee;
        group.invitationFeePeriod = _invitationFeePeriod;
        group.invitationFeeDepth = _invitationFeeDepth;
        group.active = true;
         
         
        
        groups.push(group);
        groupNames[_groupName] = true;

         
        GroupCreated(uint32(groups.length).sub(1), block.timestamp);
    }

     
    function closeGroup(uint32 _group) onlyOwner public {
         
        require(groupExists(_group));
        require(groups[_group].active);
        
        groups[_group].active = false;

         
        GroupClosed(_group, block.timestamp);
    } 
    
    
     
     
    function joinGroupAndInvest(uint32 _group, address _invitor) payable public {
        address investor = msg.sender;
         
        require(msg.sender != owner);
         
        Group storage thisGroup = groups[_group];
        require(thisGroup.roundSize > 0);
        require(thisGroup.members[_invitor].joinTime > 0 || _invitor == owner);
        require(thisGroup.members[investor].joinTime == 0);
         
        require(msg.value == thisGroup.investment);
        
         
        thisGroup.members[investor].joinTime = block.timestamp;
        thisGroup.members[investor].invitor = _invitor;
        
         
        NewInvestor(investor, _group, block.timestamp);
        
         
        invest(_group);
    }

     
    function invest(uint32 _group) payable public {
        address investor = msg.sender;
        Group storage thisGroup = groups[_group];
        uint32 round = thisGroup.currentRound;
        Round storage thisRound = thisGroup.rounds[round];
        
         
        require(thisGroup.active || thisRound.totalInvestors > 0);
        
         
        require(msg.value == thisGroup.investment);
         
        require(thisGroup.members[investor].joinTime > 0);
         
        require(! isInvestorInRound(thisRound, investor));
        
         
        Invest(investor, _group, round, block.timestamp);

         
        uint256 ownerFee = msg.value.mul(thisGroup.ownerFee).div(1000);
        balances[owner] = balances[owner].add(ownerFee);
        Deposit(owner, ownerFee, block.timestamp);
                
        uint256 investedSumLessOwnerFee = msg.value.sub(ownerFee);

        uint256 invitationFee = payAllInvitors(thisGroup, investor, block.timestamp, investedSumLessOwnerFee, 0);

        uint256 investedNetSum = investedSumLessOwnerFee.sub(invitationFee);
        
         
        thisRound.investorMapping[investor] = thisRound.totalInvestors;
        thisRound.investments[thisRound.totalInvestors] = Investment({
            investor: investor,
            sum: investedNetSum,
            time: block.timestamp});
        
        thisRound.totalInvestors = thisRound.totalInvestors.add(1);
        thisRound.totalInvestment = thisRound.totalInvestment.add(investedNetSum);
        
         
        if (thisRound.totalInvestors == thisGroup.roundSize) {
            thisGroup.currentRound = thisGroup.currentRound.add(1);
            thisRound.lastBlock = block.number;
        }

         
        address winner;
        string memory reason;
        (winner, reason) = checkWinnerInternal(thisGroup);
        if (winner != 0)
            declareWinner(_group, winner);
    }

    
     
    function withdraw(uint256 sum) public {
        address withdrawer = msg.sender;
         
        require(balances[withdrawer] >= sum);

         
        Withdraw(withdrawer, sum, block.timestamp);
        
         
        balances[withdrawer] = balances[withdrawer].sub(sum);
        withdrawer.transfer(sum);
    }
    
     
    function checkWinner(uint32 _group) public constant returns (bool foundWinner, string reason) {
        Group storage thisGroup = groups[_group];
        require(thisGroup.roundSize > 0);
        address winner;
        (winner, reason) = checkWinnerInternal(thisGroup);
        foundWinner = winner != 0;
    }
    
     

    function checkAndDeclareWinner(uint32 _group) public {
        Group storage thisGroup = groups[_group];
        require(thisGroup.roundSize > 0);
        address winner;
        string memory reason;
        (winner, reason) = checkWinnerInternal(thisGroup);
         
        require(winner != 0);
         
        declareWinner(_group, winner);
    }

     

    function declareWinner(uint32 _group, address _winner) internal {
         
        Group storage thisGroup = groups[_group];
        Round storage unwonRound = thisGroup.rounds[thisGroup.firstUnwonRound];
    
        unwonRound.winner = _winner;
        
         
        Winner(_winner, _group, thisGroup.firstUnwonRound, block.timestamp);
        uint256 wonSum = unwonRound.totalInvestment;
        
        wonSum = wonSum.sub(payAllInvitors(thisGroup, _winner, block.timestamp, wonSum, 0));
        
        balances[_winner] = balances[_winner].add(wonSum);
        
        Deposit(_winner, wonSum, block.timestamp);
            
         
        thisGroup.firstUnwonRound = thisGroup.firstUnwonRound.add(1);
    }

     
    function checkWinnerInternal(Group storage thisGroup) internal constant returns (address winner, string reason) {
        winner = 0;  
         
         
        if (thisGroup.currentRound == 0) {
            reason = 'Still in first round';
            return;
        }
         
        if (thisGroup.currentRound == thisGroup.firstUnwonRound) {
            reason = 'No unwon finished rounds';
            return;
        }
     
        Round storage unwonRound = thisGroup.rounds[thisGroup.firstUnwonRound];
        
         
        uint256 firstBlock = unwonRound.lastBlock.add(thisGroup.blocksBeforeWinCheck);
         
         
        if (block.number > 255 && firstBlock < block.number.sub(255))
            firstBlock = block.number.sub(255);
         
        uint256 lastBlock = block.number.sub(1);

        for (uint256 thisBlock = firstBlock; thisBlock <= lastBlock; thisBlock = thisBlock.add(1)) {
            uint256 latestHash = uint256(block.blockhash(thisBlock));
             
            uint32 drawn = uint32(latestHash % thisGroup.securityFactor);
            if (drawn < thisGroup.roundSize) {
                 
                winner = unwonRound.investments[drawn].investor;
                return;
            }
        }
        reason = 'No winner picked';
    } 
    
     
    function payAllInvitors(Group storage thisGroup, address _payer, uint256 _relevantTime, uint256 _amount, uint32 _depth) internal returns (uint256 invitationFee) {

        address invitor = thisGroup.members[_payer].invitor;
         
        if (
         
            invitor == owner ||
         
            _amount == 0 ||
         
            _depth >= thisGroup.invitationFeeDepth ||
         
            _relevantTime > thisGroup.members[_payer].joinTime.add(thisGroup.invitationFeePeriod.mul(1 days))
        ) {
            return;
        }

         
        invitationFee = _amount.mul(thisGroup.invitationFee).div(1000);
        
         
        if (invitationFee == 0) return;

         
        uint256 invitorFee = payAllInvitors(thisGroup, invitor, _relevantTime,  invitationFee, _depth.add(1));
        
         
        uint256 paid = invitationFee.sub(invitorFee);
        
         
        balances[invitor] = balances[invitor].add(paid);
        
         
        Deposit(invitor, paid, block.timestamp);
    }


    
     
    function isInvestorInRound(Round storage _round, address _investor) internal constant returns (bool investorInRound) {
        return (_round.investments[_round.investorMapping[_investor]].investor == _investor);
    }
    
    
     
    function balanceOf(address investor) public constant returns (uint256 balance) {
        balance = balances[investor];
    }
    
     
     
    function groupsCount() public constant returns (uint256 count) {
        count = groups.length;
    }
     
      
    function groupInfo(uint32 _group) public constant returns (
        string name,
        uint32 roundSize,
        uint256 investment,
        uint32 blocksBeforeWinCheck,
        uint32 securityFactor,
        uint32 invitationFee,
        uint32 ownerFee,
        uint32 invitationFeePeriod,
        uint8 invitationFeeDepth,
        bool active,
        uint32 currentRound,
        uint32 firstUnwonRound
    ) {
        require(groupExists(_group));
        Group storage thisGroup = groups[_group];
        name = thisGroup.name;
        roundSize = thisGroup.roundSize;
        investment = thisGroup.investment;
        blocksBeforeWinCheck = thisGroup.blocksBeforeWinCheck;
        securityFactor = thisGroup.securityFactor;
        invitationFee = thisGroup.invitationFee;
        ownerFee = thisGroup.ownerFee;
        invitationFeePeriod = thisGroup.invitationFeePeriod;
        invitationFeeDepth = thisGroup.invitationFeeDepth;
        active = thisGroup.active;
        currentRound = thisGroup.currentRound;
        firstUnwonRound = thisGroup.firstUnwonRound;
    }
    
     
     
    function groupMemberInfo (uint32 _group, address investor) public constant returns (
        uint256 joinTime,
        address invitor
    ) {
        require(groupExists(_group));
        GroupMember storage groupMember = groups[_group].members[investor];
        joinTime = groupMember.joinTime;
        invitor = groupMember.invitor;
    }
    
     
    function roundInfo (uint32 _group, uint32 _round) public constant returns (
        uint32 totalInvestors,
        uint256 totalInvestment,
        address winner,
        uint256 lastBlock
    ) {
        require(groupExists(_group));
        Round storage round = groups[_group].rounds[_round];
        totalInvestors = round.totalInvestors;
        totalInvestment = round.totalInvestment;
        winner = round.winner;
        lastBlock = round.lastBlock;
    } 
    
     
    function roundInvestorInfoByAddress (uint32 _group, uint32 _round, address investor) public constant returns (
        bool inRound,
        uint32 index
    ) {
        require(groupExists(_group));
        index = groups[_group].rounds[_round].investorMapping[investor];
        inRound = isInvestorInRound(groups[_group].rounds[_round], investor);
    }
    
     
    function roundInvestorInfoByIndex (uint32 _group, uint32 _round, uint32 _index) public constant returns (
        address investor,
        uint256 sum,
        uint256 time
    ) {
        require(groupExists(_group));
        require(groups[_group].rounds[_round].totalInvestors > _index);
        Investment storage investment = groups[_group].rounds[_round].investments[_index];
        investor = investment.investor;
        sum = investment.sum;
        time = investment.time;
    }

     
    function groupNameExists(string _groupName) internal constant returns (bool exists) {
        return groupNames[_groupName];
    }

    function groupExists(uint32 _group) internal constant returns (bool exists) {
        return _group < groups.length;
    }

}





library SafeMath256 {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

library SafeMath32 {
  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
     
    uint32 c = a / b;
     
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    require(c >= a);
    return c;
  }
}