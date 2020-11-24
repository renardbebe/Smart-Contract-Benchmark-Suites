 

pragma solidity ^0.5.2;

 

 


 

 

 

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {

        c = a + b;

        require(c >= a);

    }

    function sub(uint a, uint b) internal pure returns (uint c) {

        require(b <= a);

        c = a - b;

    }

    function mul(uint a, uint b) internal pure returns (uint c) {

        c = a * b;

        require(a == 0 || c / a == b);

    }

    function div(uint a, uint b) internal pure returns (uint c) {

        require(b > 0);

        c = a / b;

    }

}



library ExtendedMath {


     
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {

        if(a > b) return b;

        return a;

    }
}



contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);


    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



contract EticaToken is ERC20Interface{

    using SafeMath for uint;
    using ExtendedMath for uint;

    string public name = "Etica";
    string public symbol = "ETI";
    uint public decimals = 18;

    uint public supply;
    uint public inflationrate;  
    uint public  periodrewardtemp;  

    uint public PERIOD_CURATION_REWARD_RATIO = 38196601125;  
    uint public PERIOD_EDITOR_REWARD_RATIO = 61803398875;  

    uint public UNRECOVERABLE_ETI;

     
    string public constant initiatormsg = "Discovering our best Futures. All proposals are made under the Creative Commons license 4.0. Kevin Wad";

    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) allowed;

   

     
    uint public _totalMiningSupply;



     uint public latestDifficultyPeriodStarted;



    uint public epochCount;  


    uint public _BLOCKS_PER_READJUSTMENT = 2016;


     
    uint public  _MINIMUM_TARGET = 2**2;


     
     
     
    uint public  _MAXIMUM_TARGET = 2**220;  


    uint public miningTarget;

    bytes32 public challengeNumber;    


    uint public blockreward;


    address public lastRewardTo;
    uint public lastRewardEthBlockNumber;


    mapping(bytes32 => bytes32) solutionForChallenge;

    uint public tokensMinted;

    bytes32 RANDOMHASH;

     




    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Mint(address indexed from, uint blockreward, uint epochCount, bytes32 newChallengeNumber);


    constructor() public{
      supply = 100 * (10**18);  
      balances[address(this)] = balances[address(this)].add(100 * (10**18));  


     
      
       

       
        
          
          
      periodrewardtemp = 4027393950087164311900;  
       

       
      _totalMiningSupply = 11550000 * 10**uint(decimals);


      tokensMinted = 0;

       
       
       
       
       
      blockreward = 35958874554349681356;

      miningTarget = _MAXIMUM_TARGET;

      latestDifficultyPeriodStarted = block.timestamp;

      _startNewMiningEpoch();
       

     
      

     

       
       
       
       
       
       
       
      inflationrate = 4957512263080183722688891602;   

     


        
        
        
    }


    function allowance(address tokenOwner, address spender) view public returns(uint){
        return allowed[tokenOwner][spender];
    }


     
    function approve(address spender, uint tokens) public returns(bool){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
    function transferFrom(address from, address to, uint tokens) public returns(bool){

      balances[from] = balances[from].sub(tokens);

      allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

      balances[to] = balances[to].add(tokens);

      emit Transfer(from, to, tokens);

      return true;
    }

    function totalSupply() public view returns (uint){
        return supply;
    }

    function accessibleSupply() public view returns (uint){
        return supply.sub(UNRECOVERABLE_ETI);
    }

    function balanceOf(address tokenOwner) public view returns (uint balance){
         return balances[tokenOwner];
     }


    function transfer(address to, uint tokens) public returns (bool success){
         require(tokens > 0);

         balances[msg.sender] = balances[msg.sender].sub(tokens);

         balances[to] = balances[to].add(tokens);

         emit Transfer(msg.sender, to, tokens);

         return true;
     }


      

         function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {


              
             bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

              
             if (digest != challenge_digest) revert();

              
             if(uint256(digest) > miningTarget) revert();


              
              bytes32 solution = solutionForChallenge[challengeNumber];
              solutionForChallenge[challengeNumber] = digest;
              if(solution != 0x0) revert();   

              if(tokensMinted > 1890000 * 10**uint(decimals)){
 
              if(tokensMinted >= 6300000 * 10**uint(decimals)) {
                 
                 
                blockreward = 19977152530194267420;  
                periodrewardtemp = 20136969750435821559600;  
              }

              else if (tokensMinted < 3570000 * 10**uint(decimals)) {
                 
                 
                blockreward = 31963444048310827872;  
                periodrewardtemp = 8054787900174328623800;  
              }
              else if (tokensMinted < 5040000 * 10**uint(decimals)) {
                 
                 
                blockreward = 27968013542271974388;  
                periodrewardtemp = 12082181850261492935800;  
              }
              else {
                 
                blockreward = 23972583036233120904;  
                periodrewardtemp = 16109575800348657247700;  
              }

              }

             tokensMinted = tokensMinted.add(blockreward);
              
             assert(tokensMinted < _totalMiningSupply);

             supply = supply.add(blockreward);
             balances[msg.sender] = balances[msg.sender].add(blockreward);


              
             lastRewardTo = msg.sender;
             lastRewardEthBlockNumber = block.number;


              _startNewMiningEpoch();

               emit Mint(msg.sender, blockreward, epochCount, challengeNumber );
               emit Transfer(address(this), msg.sender,blockreward);

            return true;

         }


      
     function _startNewMiningEpoch() internal {


       epochCount = epochCount.add(1);

        
       if(epochCount % _BLOCKS_PER_READJUSTMENT == 0)
       {
         _reAdjustDifficulty();
       }


        
        
       challengeNumber = blockhash(block.number.sub(1));
       challengeNumber = keccak256(abi.encode(challengeNumber, RANDOMHASH));  

     }




      
     function _reAdjustDifficulty() internal {

         uint _oldtarget = miningTarget;

           
         uint ethTimeSinceLastDifficultyPeriod = block.timestamp.sub(latestDifficultyPeriodStarted);      

          
         uint targetTimePerDiffPeriod = _BLOCKS_PER_READJUSTMENT.mul(10 minutes);  

          
         if( ethTimeSinceLastDifficultyPeriod < targetTimePerDiffPeriod )
         {

               
              miningTarget = miningTarget.mul(ethTimeSinceLastDifficultyPeriod).div(targetTimePerDiffPeriod);

               
              if(miningTarget < _oldtarget.div(4)){

               
              miningTarget = _oldtarget.div(4);

              }

         }else{

                 
                 miningTarget = miningTarget.mul(ethTimeSinceLastDifficultyPeriod).div(targetTimePerDiffPeriod);

                 
                if(miningTarget > _oldtarget.mul(4)){

                  
                 miningTarget = _oldtarget.mul(4);

                }

         }

        

         latestDifficultyPeriodStarted = block.timestamp;

         if(miningTarget < _MINIMUM_TARGET)  
         {
           miningTarget = _MINIMUM_TARGET;
         }

         if(miningTarget > _MAXIMUM_TARGET)  
         {
           miningTarget = _MAXIMUM_TARGET;
         }
     }


      
     function getChallengeNumber() public view returns (bytes32) {
         return challengeNumber;
     }

      
      function getMiningDifficulty() public view returns (uint) {
         return _MAXIMUM_TARGET.div(miningTarget);
     }

     function getMiningTarget() public view returns (uint) {
        return miningTarget;
    }


     
    function getMiningReward() public view returns (uint) {
         if(tokensMinted <= _totalMiningSupply){
          return blockreward;
         }
         else {
          return 0;
         }
         
    }

      
     function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32 digesttest) {

         bytes32 digest = keccak256(abi.encodePacked(challenge_number,msg.sender,nonce));

         return digest;

       }

          
       function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {

           bytes32 digest = keccak256(abi.encodePacked(challenge_number,msg.sender,nonce));

           if(uint256(digest) > testTarget) revert();

           return (digest == challenge_digest);

         }


 

 

 

 

function () payable external {

    revert();

}

}




contract EticaRelease is EticaToken {
   
uint public REWARD_INTERVAL = 7 days;  
uint public STAKING_DURATION = 28 days;  
uint public DEFAULT_VOTING_TIME = 21 days;  
uint public DEFAULT_REVEALING_TIME = 7 days;  
     

 

uint public DISEASE_CREATION_AMOUNT = 100 * 10**uint(decimals);  
uint public PROPOSAL_DEFAULT_VOTE = 10 * 10**uint(decimals);  


uint public APPROVAL_THRESHOLD = 5000;  
uint public PERIODS_PER_THRESHOLD = 5;  
uint public SEVERITY_LEVEL = 4;  
uint public PROPOSERS_INCREASER = 3;  
uint public PROTOCOL_RATIO_TARGET = 7250;  
uint public LAST_PERIOD_COST_UPDATE = 0;


struct Period{
    uint id;
    uint interval;
    uint curation_sum;  
    uint editor_sum;  
    uint reward_for_curation;  
    uint reward_for_editor;  
    uint forprops;  
    uint againstprops;  
}

  struct Stake{
      uint amount;
      uint endTime;  
  }

 

 
  struct Proposal{
      uint id;
      bytes32 proposed_release_hash;  
      bytes32 disease_id;
      uint period_id;
      uint chunk_id;
      address proposer;  
      string title;  
      string description;  
      string freefield;
      string raw_release_hash;
  }

 
  struct ProposalData{

      uint starttime;  
      uint endtime;   
      uint finalized_time;  
      ProposalStatus status;  
      ProposalStatus prestatus;  
      bool istie;   
      uint nbvoters;
      uint slashingratio;  
      uint forvotes;
      uint againstvotes;
      uint lastcuration_weight;  
      uint lasteditor_weight;  
  }

   

     

    struct Chunk{
    uint id;
    bytes32 diseaseid;  
    uint idx;
    string title;
    string desc;
  }

   

   
  struct Vote{
    bytes32 proposal_hash;  
    bool approve;
    bool is_editor;
    uint amount;
    address voter;  
    uint timestamp;  
    bool is_claimed;  
  }

    struct Commit{
    uint amount;
    uint timestamp;  
  }
     

     

  struct Disease{
      bytes32 disease_hash;
      string name;
  }

      

enum ProposalStatus { Rejected, Accepted, Pending, Singlevoter }

mapping(uint => Period) public periods;
uint public periodsCounter;
mapping(uint => uint) public PeriodsIssued;  
uint public PeriodsIssuedCounter;
mapping(uint => uint) public IntervalsPeriods;  
uint public IntervalsPeriodsCounter;

mapping(uint => Disease) public diseases;  
uint public diseasesCounter;
mapping(bytes32 => uint) public diseasesbyIds;  
mapping(string => bytes32) private diseasesbyNames;  

mapping(bytes32 => mapping(uint => bytes32)) public diseaseproposals;  
mapping(bytes32 => uint) public diseaseProposalsCounter;  

 
mapping(bytes32 => Proposal) public proposals;
mapping(uint => bytes32) public proposalsbyIndex;  
uint public proposalsCounter;

mapping(bytes32 => ProposalData) public propsdatas;
 

 
mapping(uint => Chunk) public chunks;
uint public chunksCounter;
mapping(bytes32 => mapping(uint => uint)) public diseasechunks;  
mapping(uint => mapping(uint => bytes32)) public chunkproposals;  
mapping(bytes32 => uint) public diseaseChunksCounter;  
mapping(uint => uint) public chunkProposalsCounter;  
 

 
mapping(bytes32 => mapping(address => Vote)) public votes;
mapping(address => mapping(bytes32 => Commit)) public commits;
 

mapping(address => uint) public bosoms;
mapping(address => mapping(uint => Stake)) public stakes;
mapping(address => uint) public stakesCounters;  
mapping(address => uint) public stakesAmount;  

 
mapping(address => uint) public blockedeticas;

 
event CreatedPeriod(uint indexed period_id, uint interval);
event NewDisease(uint indexed diseaseindex, string title);
event NewProposal(bytes32 proposed_release_hash, address indexed _proposer, bytes32 indexed diseasehash, uint indexed chunkid);
event NewChunk(uint indexed chunkid, bytes32 indexed diseasehash);
event RewardClaimed(address indexed voter, uint amount, bytes32 proposal_hash);
event NewFee(address indexed voter, uint fee, bytes32 proposal_hash);
event NewSlash(address indexed voter, uint duration, bytes32 proposal_hash);
event NewCommit(address indexed _voter, bytes32 votehash);
event NewReveal(address indexed _voter, bytes32 indexed _proposal);
event NewStake(address indexed staker, uint amount);
event StakeClaimed(address indexed staker, uint stakeamount);
 



 

function issue(uint _id) internal returns (bool success) {
   
  require(periodsCounter > 0);

   
  require(_id > 0 && _id <= periodsCounter);

   
  Period storage period = periods[_id];

   
  require(period.id != 0);


 
uint rwd = PeriodsIssued[period.id];
if(rwd != 0x0) revert();   

uint _periodsupply;

 
if(supply >= 21000000 * 10**(decimals)){
_periodsupply = uint((supply.mul(inflationrate)).div(10**(31)));
}
 
else {
  _periodsupply = periodrewardtemp;
}

 
period.reward_for_curation = uint((_periodsupply.mul(PERIOD_CURATION_REWARD_RATIO)).div(10**(11)));
period.reward_for_editor = uint((_periodsupply.mul(PERIOD_EDITOR_REWARD_RATIO)).div(10**(11)));


supply = supply.add(_periodsupply);
balances[address(this)] = balances[address(this)].add(_periodsupply);
PeriodsIssued[period.id] = _periodsupply;
PeriodsIssuedCounter = PeriodsIssuedCounter.add(1);

return true;

}


 
function newPeriod() internal {

  uint _interval = uint((block.timestamp).div(REWARD_INTERVAL));

   
  uint rwd = IntervalsPeriods[_interval];
  if(rwd != 0x0) revert();   


  periodsCounter = periodsCounter.add(1);

   
  periods[periodsCounter] = Period(
    periodsCounter,
    _interval,
    0x0,  
    0x0,  
    0x0,  
    0x0,  
    0x0,  
    0x0  
  );

   
  IntervalsPeriods[_interval] = periodsCounter;
  IntervalsPeriodsCounter = IntervalsPeriodsCounter.add(1);

   
  issue(periodsCounter);


   
  if((periodsCounter.sub(1)) % PERIODS_PER_THRESHOLD == 0 && periodsCounter > 1)
  {
    readjustThreshold();
  }

  emit CreatedPeriod(periodsCounter, _interval);
}

function readjustThreshold() internal {

uint _meanapproval = 0;
uint _totalfor = 0;  
uint _totalagainst = 0;  


 
for(uint _periodidx = periodsCounter.sub(PERIODS_PER_THRESHOLD); _periodidx <= periodsCounter.sub(1);  _periodidx++){
   _totalfor = _totalfor.add(periods[_periodidx].forprops);
   _totalagainst = _totalagainst.add(periods[_periodidx].againstprops); 
}

  if(_totalfor.add(_totalagainst) == 0){
   _meanapproval = 5000;
  }
  else{
   _meanapproval = uint(_totalfor.mul(10000).div(_totalfor.add(_totalagainst)));
  }

 

          
         if( _meanapproval < PROTOCOL_RATIO_TARGET )
         {
           uint shortage_approvals_rate = (PROTOCOL_RATIO_TARGET.sub(_meanapproval));

            
           APPROVAL_THRESHOLD = uint(APPROVAL_THRESHOLD.sub(((APPROVAL_THRESHOLD.sub(4500)).mul(shortage_approvals_rate)).div(10000)));    
         }else{
           uint excess_approvals_rate = uint((_meanapproval.sub(PROTOCOL_RATIO_TARGET)));

            
           APPROVAL_THRESHOLD = uint(APPROVAL_THRESHOLD.add(((10000 - APPROVAL_THRESHOLD).mul(excess_approvals_rate)).div(10000)));    
         }


         if(APPROVAL_THRESHOLD < 4500)  
         {
           APPROVAL_THRESHOLD = 4500;
         }

         if(APPROVAL_THRESHOLD > 9900)  
         {
           APPROVAL_THRESHOLD = 9900;
         }

}

 


 
 
function eticatobosoms(address _staker, uint _amount) public returns (bool success){
  require(msg.sender == _staker);
  require(_amount > 0);  
   
  transfer(address(this), _amount);

   
  bosomget(_staker, _amount);


  return true;

}



 

 
function bosomget (address _staker, uint _amount) internal {

addStake(_staker, _amount);
bosoms[_staker] = bosoms[_staker].add(_amount);

}

 

 

function addStake(address _staker, uint _amount) internal returns (bool success) {

    require(_amount > 0);
    stakesCounters[_staker] = stakesCounters[_staker].add(1);  


     
    stakesAmount[_staker] = stakesAmount[_staker].add(_amount);

    uint endTime = block.timestamp.add(STAKING_DURATION);

     
    stakes[_staker][stakesCounters[_staker]] = Stake(
      _amount,  
      endTime  
    );

    emit NewStake(_staker, _amount);

    return true;
}

function addConsolidation(address _staker, uint _amount, uint _endTime) internal returns (bool success) {

    require(_amount > 0);
    stakesCounters[_staker] = stakesCounters[_staker].add(1);  


     
    stakesAmount[_staker] = stakesAmount[_staker].add(_amount);

     
    stakes[_staker][stakesCounters[_staker]] = Stake(
      _amount,  
      _endTime  
    );

    emit NewStake(_staker, _amount);

    return true;
}

 

 

function splitStake(address _staker, uint _amount, uint _endTime) internal returns (bool success) {

    require(_amount > 0);
    stakesCounters[_staker] = stakesCounters[_staker].add(1);  

     
    stakes[_staker][stakesCounters[_staker]] = Stake(
      _amount,  
      _endTime  
    );


    return true;
}

 


 
 
function stakeclmidx (uint _stakeidx) public {

   
  require(_stakeidx > 0 && _stakeidx <= stakesCounters[msg.sender]);

   
  Stake storage _stake = stakes[msg.sender][_stakeidx];

   
  require(block.timestamp > _stake.endTime);

   
  require(_stake.amount <= stakesAmount[msg.sender].sub(blockedeticas[msg.sender]));

   
  balances[address(this)] = balances[address(this)].sub(_stake.amount);

  balances[msg.sender] = balances[msg.sender].add(_stake.amount);

  emit Transfer(address(this), msg.sender, _stake.amount);
  emit StakeClaimed(msg.sender, _stake.amount);

   
  _deletestake(msg.sender, _stakeidx);

}

 

 

function _deletestake(address _staker,uint _index) internal {
   
  require(_index > 0 && _index <= stakesCounters[_staker]);

   
  stakesAmount[_staker] = stakesAmount[_staker].sub(stakes[_staker][_index].amount);

   
  stakes[_staker][_index] = stakes[_staker][stakesCounters[_staker]];

   
  stakes[_staker][stakesCounters[_staker]] = Stake(
    0x0,  
    0x0  
    );

   
  stakesCounters[_staker] = stakesCounters[_staker].sub(1);

}

 


 

 
 
function stakescsldt(uint _endTime, uint _min_limit, uint _maxidx) public {

 
require(_endTime < block.timestamp.add(730 days));  

 
require(_maxidx <= 50 && _maxidx <= stakesCounters[msg.sender]);

uint newAmount = 0;

uint _nbdeletes = 0;

uint _currentidx = 1;

for(uint _stakeidx = 1; _stakeidx <= _maxidx;  _stakeidx++) {
     
    if(stakesCounters[msg.sender] >= 2){

    if(_stakeidx <= stakesCounters[msg.sender]){
       _currentidx = _stakeidx;
    } 
    else {
       
      _currentidx = _stakeidx.sub(_nbdeletes);  
       
      assert(_currentidx >= 1);  
    }
      
       
       
      if(stakes[msg.sender][_currentidx].endTime <= _endTime && stakes[msg.sender][_currentidx].endTime >= _min_limit) {

        newAmount = newAmount.add(stakes[msg.sender][_currentidx].amount);

        _deletestake(msg.sender, _currentidx);    

        _nbdeletes = _nbdeletes.add(1);

      }  

    }
}

if (newAmount > 0){
 
addConsolidation(msg.sender, newAmount, _endTime);
}

}

 

 

 
 
function stakesnap(uint _stakeidx, uint _snapamount) public {

  require(_snapamount > 0);
  
   
  require(_stakeidx > 0 && _stakeidx <= stakesCounters[msg.sender]);

   
  Stake storage _stake = stakes[msg.sender][_stakeidx];


   
  require(_stake.amount > _snapamount);

   
  uint _restAmount = _stake.amount.sub(_snapamount);
  
   
  _stake.amount = _snapamount;


   
  stakesCounters[msg.sender] = stakesCounters[msg.sender].add(1);

   
  stakes[msg.sender][stakesCounters[msg.sender]] = Stake(
      _restAmount,  
      _stake.endTime  
    );
   

assert(_restAmount > 0);

}

 


function stakescount(address _staker) public view returns (uint slength){
  return stakesCounters[_staker];
}

 


 
function createdisease(string memory _name) public {


   

   
  require(balances[msg.sender] >= DISEASE_CREATION_AMOUNT);
   
  transfer(address(this), DISEASE_CREATION_AMOUNT);

  UNRECOVERABLE_ETI = UNRECOVERABLE_ETI.add(DISEASE_CREATION_AMOUNT);

   


  bytes32 _diseasehash = keccak256(abi.encode(_name));

  diseasesCounter = diseasesCounter.add(1);  

   
   if(diseasesbyIds[_diseasehash] != 0x0) revert();   
   require(diseasesbyNames[_name] == 0);  

    
   diseases[diseasesCounter] = Disease(
     _diseasehash,
     _name
   );

    
   diseasesbyIds[_diseasehash] = diseasesCounter;
   diseasesbyNames[_name] = _diseasehash;

   emit NewDisease(diseasesCounter, _name);

}



function propose(bytes32 _diseasehash, string memory _title, string memory _description, string memory raw_release_hash, string memory _freefield, uint _chunkid) public {

     
     require(diseasesbyIds[_diseasehash] > 0 && diseasesbyIds[_diseasehash] <= diseasesCounter);
     if(diseases[diseasesbyIds[_diseasehash]].disease_hash != _diseasehash) revert();  

    require(_chunkid <= chunksCounter);

     bytes32 _proposed_release_hash = keccak256(abi.encode(raw_release_hash, _diseasehash));
     diseaseProposalsCounter[_diseasehash] = diseaseProposalsCounter[_diseasehash].add(1);
     diseaseproposals[_diseasehash][diseaseProposalsCounter[_diseasehash]] = _proposed_release_hash;

     proposalsCounter = proposalsCounter.add(1);  
     proposalsbyIndex[proposalsCounter] = _proposed_release_hash;

      
      
      bytes32 existing_proposal = proposals[_proposed_release_hash].proposed_release_hash;
      if(existing_proposal != 0x0 || proposals[_proposed_release_hash].id != 0) revert();   

     uint _current_interval = uint((block.timestamp).div(REWARD_INTERVAL));

       
      if(IntervalsPeriods[_current_interval] == 0x0){
        newPeriod();
      }

     Proposal storage proposal = proposals[_proposed_release_hash];

       proposal.id = proposalsCounter;
       proposal.disease_id = _diseasehash;  
       proposal.period_id = IntervalsPeriods[_current_interval];
       proposal.proposed_release_hash = _proposed_release_hash;  
       proposal.proposer = msg.sender;
       proposal.title = _title;
       proposal.description = _description;
       proposal.raw_release_hash = raw_release_hash;
       proposal.freefield = _freefield;


        
       ProposalData storage proposaldata = propsdatas[_proposed_release_hash];
       proposaldata.status = ProposalStatus.Pending;
       proposaldata.istie = true;
       proposaldata.prestatus = ProposalStatus.Pending;
       proposaldata.nbvoters = 0;
       proposaldata.slashingratio = 0;
       proposaldata.forvotes = 0;
       proposaldata.againstvotes = 0;
       proposaldata.lastcuration_weight = 0;
       proposaldata.lasteditor_weight = 0;
       proposaldata.starttime = block.timestamp;
       proposaldata.endtime = block.timestamp.add(DEFAULT_VOTING_TIME);


 

    require(bosoms[msg.sender] >= PROPOSAL_DEFAULT_VOTE);  

     
    bosoms[msg.sender] = bosoms[msg.sender].sub(PROPOSAL_DEFAULT_VOTE);


     
    blockedeticas[msg.sender] = blockedeticas[msg.sender].add(PROPOSAL_DEFAULT_VOTE);


     
    Vote storage vote = votes[proposal.proposed_release_hash][msg.sender];
    vote.proposal_hash = proposal.proposed_release_hash;
    vote.approve = true;
    vote.is_editor = true;
    vote.amount = PROPOSAL_DEFAULT_VOTE;
    vote.voter = msg.sender;
    vote.timestamp = block.timestamp;



       
      proposaldata.prestatus = ProposalStatus.Singlevoter;

       
      uint existing_chunk = chunks[_chunkid].id;
      if(existing_chunk != 0x0 && chunks[_chunkid].diseaseid == _diseasehash) {
        proposal.chunk_id = _chunkid;
         
        chunkProposalsCounter[_chunkid] = chunkProposalsCounter[_chunkid].add(1);
        chunkproposals[_chunkid][chunkProposalsCounter[_chunkid]] = proposal.proposed_release_hash;
      }

   

  RANDOMHASH = keccak256(abi.encode(RANDOMHASH, _proposed_release_hash));  

    emit NewProposal(_proposed_release_hash, msg.sender, proposal.disease_id, _chunkid);

}


 function updatecost() public {

 
require(supply >= 21000000 * 10**(decimals));
 
require(periodsCounter % 52 == 0);
uint _new_disease_cost = supply.mul(47619046).div(10**13);  
uint _new_proposal_vote = supply.mul(47619046).div(10**14);  

PROPOSAL_DEFAULT_VOTE = _new_proposal_vote;
DISEASE_CREATION_AMOUNT = _new_disease_cost;

assert(LAST_PERIOD_COST_UPDATE < periodsCounter);
LAST_PERIOD_COST_UPDATE = periodsCounter;

 }



 function commitvote(uint _amount, bytes32 _votehash) public {

require(_amount > 10);

  
 require(bosoms[msg.sender] >= _amount);  
 bosoms[msg.sender] = bosoms[msg.sender].sub(_amount);

  
 blockedeticas[msg.sender] = blockedeticas[msg.sender].add(_amount);

  
 commits[msg.sender][_votehash].amount = commits[msg.sender][_votehash].amount.add(_amount);
 commits[msg.sender][_votehash].timestamp = block.timestamp;

 RANDOMHASH = keccak256(abi.encode(RANDOMHASH, _votehash));  

emit NewCommit(msg.sender, _votehash);

 }


 function revealvote(bytes32 _proposed_release_hash, bool _approved, string memory _vary) public {
 

 
bytes32 _votehash;
_votehash = keccak256(abi.encode(_proposed_release_hash, _approved, msg.sender, _vary));

require(commits[msg.sender][_votehash].amount > 0);
 

 
Proposal storage proposal = proposals[_proposed_release_hash];
require(proposal.id > 0 && proposal.proposed_release_hash == _proposed_release_hash);


ProposalData storage proposaldata = propsdatas[_proposed_release_hash];

  
 require( commits[msg.sender][_votehash].timestamp <= proposaldata.endtime);

  
 require( block.timestamp > proposaldata.endtime && block.timestamp <= proposaldata.endtime.add(DEFAULT_REVEALING_TIME));

 require(proposaldata.prestatus != ProposalStatus.Pending);  

uint _old_proposal_curationweight = proposaldata.lastcuration_weight;
uint _old_proposal_editorweight = proposaldata.lasteditor_weight;


 
Period storage period = periods[proposal.period_id];


 
 
bytes32 existing_vote = votes[proposal.proposed_release_hash][msg.sender].proposal_hash;
if(existing_vote != 0x0 || votes[proposal.proposed_release_hash][msg.sender].amount != 0) revert();   


  
 Vote storage vote = votes[proposal.proposed_release_hash][msg.sender];
 vote.proposal_hash = proposal.proposed_release_hash;
 vote.approve = _approved;
 vote.is_editor = false;
 vote.amount = commits[msg.sender][_votehash].amount;
 vote.voter = msg.sender;
 vote.timestamp = block.timestamp;

 proposaldata.nbvoters = proposaldata.nbvoters.add(1);

      
     if(_approved){
      proposaldata.forvotes = proposaldata.forvotes.add(commits[msg.sender][_votehash].amount);
     }
     else {
       proposaldata.againstvotes = proposaldata.againstvotes.add(commits[msg.sender][_votehash].amount);
     }


      
     bool _isapproved = false;
     bool _istie = false;
     uint totalVotes = proposaldata.forvotes.add(proposaldata.againstvotes);
     uint _forvotes_numerator = proposaldata.forvotes.mul(10000);  
     uint _ratio_slashing = 0;

     if ((_forvotes_numerator.div(totalVotes)) > APPROVAL_THRESHOLD){
    _isapproved = true;
    }
    if ((_forvotes_numerator.div(totalVotes)) == APPROVAL_THRESHOLD){
        _istie = true;
    }

    proposaldata.istie = _istie;

    if (_isapproved){
    _ratio_slashing = uint(((10000 - APPROVAL_THRESHOLD).mul(totalVotes)).div(10000));
    _ratio_slashing = uint((proposaldata.againstvotes.mul(10000)).div(_ratio_slashing));  
    proposaldata.slashingratio = uint(10000 - _ratio_slashing);
    }
    else{
    _ratio_slashing = uint((totalVotes.mul(APPROVAL_THRESHOLD)).div(10000));
    _ratio_slashing = uint((proposaldata.forvotes.mul(10000)).div(_ratio_slashing));
    proposaldata.slashingratio = uint(10000 - _ratio_slashing);
    }

     
     require(proposaldata.slashingratio >=0 && proposaldata.slashingratio <= 10000);

         
        ProposalStatus _newstatus = ProposalStatus.Rejected;
        if(_isapproved){
         _newstatus = ProposalStatus.Accepted;
        }

        if(proposaldata.prestatus == ProposalStatus.Singlevoter){

          if(_isapproved){
            period.forprops = period.forprops.add(1);
          }
          else {
            period.againstprops = period.againstprops.add(1);
          }
        }
         
        else if(_newstatus != proposaldata.prestatus){

         if(_newstatus == ProposalStatus.Accepted){
          period.againstprops = period.againstprops.sub(1);
          period.forprops = period.forprops.add(1);
         }
          
         else {
          period.forprops = period.forprops.sub(1);
          period.againstprops = period.againstprops.add(1);
         }

        }
         

          
         if (_istie) {
         proposaldata.prestatus =  ProposalStatus.Rejected;
         proposaldata.lastcuration_weight = 0;
         proposaldata.lasteditor_weight = 0;
          
         period.curation_sum = period.curation_sum.sub(_old_proposal_curationweight);
         period.editor_sum = period.editor_sum.sub(_old_proposal_editorweight);
         }
         else {
              
         if (_isapproved){
             proposaldata.prestatus =  ProposalStatus.Accepted;
             proposaldata.lastcuration_weight = proposaldata.forvotes;
             proposaldata.lasteditor_weight = proposaldata.forvotes;
              
             period.curation_sum = period.curation_sum.sub(_old_proposal_curationweight).add(proposaldata.lastcuration_weight);
             period.editor_sum = period.editor_sum.sub(_old_proposal_editorweight).add(proposaldata.lasteditor_weight);
         }
         else{
             proposaldata.prestatus =  ProposalStatus.Rejected;
             proposaldata.lastcuration_weight = proposaldata.againstvotes;
             proposaldata.lasteditor_weight = 0;
              
             period.curation_sum = period.curation_sum.sub(_old_proposal_curationweight).add(proposaldata.lastcuration_weight);
             period.editor_sum = period.editor_sum.sub(_old_proposal_editorweight);
         }
         }
         
         
        _removecommit(_votehash);
        emit NewReveal(msg.sender, proposal.proposed_release_hash);

  }

  function _removecommit(bytes32 _votehash) internal {
        commits[msg.sender][_votehash].amount = 0;
        commits[msg.sender][_votehash].timestamp = 0;
  }


  function clmpropbyhash(bytes32 _proposed_release_hash) public {

    
   Proposal storage proposal = proposals[_proposed_release_hash];
   require(proposal.id > 0 && proposal.proposed_release_hash == _proposed_release_hash);


   ProposalData storage proposaldata = propsdatas[_proposed_release_hash];
    
   require( block.timestamp > proposaldata.endtime.add(DEFAULT_REVEALING_TIME));

   
     
    Vote storage vote = votes[proposal.proposed_release_hash][msg.sender];
    require(vote.proposal_hash == _proposed_release_hash);
    
     
    require(!vote.is_claimed);
    vote.is_claimed = true;



  
     
    blockedeticas[msg.sender] = blockedeticas[msg.sender].sub(vote.amount);


     
    Period storage period = periods[proposal.period_id];

   uint _current_interval = uint((block.timestamp).div(REWARD_INTERVAL));

    
   uint _min_intervals = uint(((DEFAULT_VOTING_TIME.add(DEFAULT_REVEALING_TIME)).div(REWARD_INTERVAL)).add(1));  
   require(_current_interval >= period.interval.add(_min_intervals));  

   
  if (proposaldata.status == ProposalStatus.Pending) {

   
  if (proposaldata.prestatus == ProposalStatus.Accepted) {
            proposaldata.status = ProposalStatus.Accepted;
  }
  else {
    proposaldata.status = ProposalStatus.Rejected;
  }

  proposaldata.finalized_time = block.timestamp;

   

  }


   
  if (!proposaldata.istie) {
   
    
   ProposalStatus voterChoice = ProposalStatus.Rejected;
   if(vote.approve){
     voterChoice = ProposalStatus.Accepted;
   }

   if(voterChoice != proposaldata.status) {
      
     uint _slashRemaining = vote.amount;
     uint _extraTimeInt = uint(STAKING_DURATION.mul(SEVERITY_LEVEL).mul(proposaldata.slashingratio).div(10000));

     if(vote.is_editor){
     _extraTimeInt = uint(_extraTimeInt.mul(PROPOSERS_INCREASER));
     }


 
if(proposaldata.slashingratio > 9000){
     
    uint _feeRemaining = uint(vote.amount.mul(33).div(100));
      if(vote.is_editor){
        _feeRemaining = vote.amount;
      }
    emit NewFee(msg.sender, _feeRemaining, vote.proposal_hash);  
    UNRECOVERABLE_ETI = UNRECOVERABLE_ETI.add(_feeRemaining);  
      
    _slashRemaining = vote.amount.sub(_feeRemaining);

         for(uint _stakeidxa = 1; _stakeidxa <= stakesCounters[msg.sender];  _stakeidxa++) {
       
      if(stakes[msg.sender][_stakeidxa].amount > _feeRemaining) {
 
        stakes[msg.sender][_stakeidxa].amount = stakes[msg.sender][_stakeidxa].amount.sub(_feeRemaining);
        stakesAmount[msg.sender] = stakesAmount[msg.sender].sub(_feeRemaining);
        _feeRemaining = 0;
         break;
      }
      else {
         
          _feeRemaining = _feeRemaining.sub(stakes[msg.sender][_stakeidxa].amount);
          _deletestake(msg.sender, _stakeidxa);
          if(_feeRemaining == 0){
           break;
          }
      }
    }
}



 
if(_slashRemaining > 0){
  emit NewSlash(msg.sender, _slashRemaining, vote.proposal_hash);
         for(uint _stakeidx = 1; _stakeidx <= stakesCounters[msg.sender];  _stakeidx++) {
       
      if(stakes[msg.sender][_stakeidx].amount <= _slashRemaining) {
 
        stakes[msg.sender][_stakeidx].endTime = stakes[msg.sender][_stakeidx].endTime.add(_extraTimeInt);
        _slashRemaining = _slashRemaining.sub(stakes[msg.sender][_stakeidx].amount);
        
       if(_slashRemaining == 0){
         break;
       }
      }
      else {
         
        uint newAmount = stakes[msg.sender][_stakeidx].amount.sub(_slashRemaining);
        uint oldCompletionTime = stakes[msg.sender][_stakeidx].endTime;

         
        stakes[msg.sender][_stakeidx].amount = _slashRemaining;  
        stakes[msg.sender][_stakeidx].endTime = stakes[msg.sender][_stakeidx].endTime.add(_extraTimeInt);  

        if(newAmount > 0){
           
          splitStake(msg.sender, newAmount, oldCompletionTime);
        }

        break;
      }
    }
}
     
   }
   else {

   uint _reward_amount = 0;

    
   require(period.curation_sum > 0);  
    
   if (!vote.is_editor){
   _reward_amount = _reward_amount.add((vote.amount.mul(period.reward_for_curation)).div(period.curation_sum));
   }

        
    if (vote.is_editor && proposaldata.status == ProposalStatus.Accepted){
           
          require( period.editor_sum > 0);  
          _reward_amount = _reward_amount.add((proposaldata.lasteditor_weight.mul(period.reward_for_editor)).div(period.editor_sum));
    }

    require(_reward_amount <= period.reward_for_curation.add(period.reward_for_editor));  

     
    balances[address(this)] = balances[address(this)].sub(_reward_amount);
    balances[msg.sender] = balances[msg.sender].add(_reward_amount);

    emit Transfer(address(this), msg.sender, _reward_amount);
    emit RewardClaimed(msg.sender, _reward_amount, _proposed_release_hash);
   }

  }    
  
  }


    function createchunk(bytes32 _diseasehash, string memory _title, string memory _description) public {

   
  require(diseasesbyIds[_diseasehash] > 0 && diseasesbyIds[_diseasehash] <= diseasesCounter);
  if(diseases[diseasesbyIds[_diseasehash]].disease_hash != _diseasehash) revert();  

   
  uint _cost = DISEASE_CREATION_AMOUNT.div(20);
   
  require(balances[msg.sender] >= _cost);
   
  transfer(address(this), _cost);

   

  chunksCounter = chunksCounter.add(1);  

   
  diseaseChunksCounter[_diseasehash] = diseaseChunksCounter[_diseasehash].add(1);  
  diseasechunks[_diseasehash][diseaseChunksCounter[_diseasehash]] = chunksCounter;
  

   
   chunks[chunksCounter] = Chunk(
     chunksCounter,  
     _diseasehash,  
     diseaseChunksCounter[_diseasehash],  
     _title,
     _description
   );

  UNRECOVERABLE_ETI = UNRECOVERABLE_ETI.add(_cost);
  emit NewChunk(chunksCounter, _diseasehash);

  }


 



 
 
function bosomsOf(address tokenOwner) public view returns (uint _bosoms){
     return bosoms[tokenOwner];
 }

 function getdiseasehashbyName(string memory _name) public view returns (bytes32 _diseasehash){
     return diseasesbyNames[_name];
 }
 

}