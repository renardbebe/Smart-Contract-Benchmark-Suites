 

pragma solidity ^0.4.8;

 
 
 
 
 
 
 
 

 
contract PromissoryToken {

    event FounderSwitchRequestEvent(address _newFounderAddr);
    event FounderSwitchedEvent(address _newFounderAddr);
    event CofounderSwitchedEvent(address _newCofounderAddr);

    event AddedPrepaidTokensEvent(address backer, uint index, uint price, uint amount);
    event PrepaidTokensClaimedEvent(address backer, uint index, uint price, uint amount);
    event TokensClaimedEvent(address backer, uint index, uint price, uint amount);

    event RedeemEvent(address backer, uint amount);

    event WithdrawalCreatedEvent(uint withdrawalId, uint amount, bytes reason);
    event WithdrawalVotedEvent(uint withdrawalId, address backer, uint backerStakeWeigth, uint totalStakeWeight);
    event WithdrawalApproved(uint withdrawalId, uint stakeWeight, bool isMultiPayment, uint amount, bytes reason);

    address founder;  
    bytes32 founderHash;  
    mapping(address => bytes32) tempHashes;  
    address cofounder; 
    address [] public previousFounders;  
    uint constant discountAmount = 60;  
    uint constant divisor = 100;  

    uint public constant minimumPrepaidClaimedPercent = 65;
    uint public promissoryUnits = 3000000;  
    uint public prepaidUnits = 0;  
    uint public claimedUnits = 0;  
    uint public claimedPrepaidUnits = 0;  
    uint public redeemedTokens = 0;  
    uint public lastPrice = 0;  
    uint public numOfBackers;  

    struct backerData {
       uint tokenPrice;
       uint tokenAmount;
       bytes32 privateHash;
       bool prepaid;
       bool claimed;
       uint backerRank;
    }

    address[] public earlyBackerList;  
    address[] public backersAddresses;  
    mapping(address => backerData[]) public backers; 
    mapping(address => bool) public backersRedeemed;

    struct withdrawalData {
       uint Amount;
       bool approved;
       bool spent;
       bytes reason;
       address[] backerApprovals;
       uint totalStake;
       address[] destination;
    }

    withdrawalData[] public withdrawals;  
    mapping(address => mapping(uint => bool)) public withdrawalsVotes;

     
    function PromissoryToken( bytes32 _founderHash, address _cofounderAddress, uint _numOfBackers){
        founder = msg.sender;
        founderHash = sha3(_founderHash);
        cofounder = _cofounderAddress;
        numOfBackers = _numOfBackers;
    }

     
    function cofounderSwitchAddress(address _newCofounderAddr) external returns (bool success){
        if (msg.sender != cofounder) throw;

        cofounder = _newCofounderAddr;
        CofounderSwitchedEvent(_newCofounderAddr);

        return true;
    }

     
    function founderSwitchRequest(bytes32 _founderHash, bytes32 _oneTimesharedPhrase) returns (bool success){
        if(sha3(_founderHash) != founderHash) throw;

        tempHashes[msg.sender] = sha3(msg.sender, founderHash, _oneTimesharedPhrase);
        FounderSwitchRequestEvent(msg.sender);

        return true;
    }

    
    function cofounderApproveSwitchRequest(address _newFounderAddr, bytes32 _oneTimesharedPhrase) external returns (bool success){
        if(msg.sender != cofounder || sha3(_newFounderAddr, founderHash, _oneTimesharedPhrase) != tempHashes[_newFounderAddr]) throw;

        previousFounders.push(founder);
        founder = _newFounderAddr;
        FounderSwitchedEvent(_newFounderAddr);

        return true;
    }

     
    function setPrepaid(address _backer, uint _tokenPrice, uint _tokenAmount, string _privatePhrase, uint _backerRank)
        external
        founderCall
        returns (uint)
    {
        if (_tokenPrice == 0 || _tokenAmount == 0 || claimedPrepaidUnits>0 ||
            _tokenAmount + prepaidUnits + claimedUnits > promissoryUnits) throw;
        if (earlyBackerList.length == numOfBackers && backers[_backer].length == 0) throw ;
        if (backers[_backer].length == 0) {
            earlyBackerList.push(_backer);
            backersAddresses.push(_backer);
        }
        backers[_backer].push(backerData(_tokenPrice, _tokenAmount, sha3(_privatePhrase, _backer), true, false, _backerRank));

        prepaidUnits +=_tokenAmount;
        lastPrice = _tokenPrice;

        AddedPrepaidTokensEvent(_backer, backers[_backer].length - 1, _tokenPrice, _tokenAmount);

        return backers[_backer].length - 1;
    }

     
    function claimPrepaid(uint _index, uint _boughtTokensPrice, uint _tokenAmount, string _privatePhrase, uint _backerRank)
        external
        EarliestBackersSet
    {
        if(backers[msg.sender][_index].prepaid == true &&
           backers[msg.sender][_index].claimed == false &&
           backers[msg.sender][_index].tokenAmount == _tokenAmount &&
           backers[msg.sender][_index].tokenPrice == _boughtTokensPrice &&
           backers[msg.sender][_index].privateHash == sha3( _privatePhrase, msg.sender) &&
           backers[msg.sender][_index].backerRank == _backerRank)
        {
            backers[msg.sender][_index].claimed = true;
            claimedPrepaidUnits += _tokenAmount;

            PrepaidTokensClaimedEvent(msg.sender, _index, _boughtTokensPrice, _tokenAmount);
        } else {
            throw;
        }
    }

     
    function claim()
        payable
        external
        MinimumBackersClaimed
   {
        if (lastPrice == 0) throw;

         
        if (msg.value == 0) throw;


         
        uint discountPrice = lastPrice * discountAmount / divisor;

        uint tokenAmount = (msg.value / discountPrice); 

        if (tokenAmount + claimedUnits + prepaidUnits > promissoryUnits) throw;

        if (backers[msg.sender].length == 0) {
            backersAddresses.push(msg.sender);
        }
        backers[msg.sender].push(backerData(discountPrice, tokenAmount, sha3(msg.sender), false, true, 0));

        claimedUnits += tokenAmount;

        TokensClaimedEvent(msg.sender, backers[msg.sender].length - 1, discountPrice, tokenAmount);
    }

     
    function checkBalance(address _backerAddress, uint index) constant returns (uint, uint, bytes32, bool, bool){
        return (
            backers[_backerAddress][index].tokenPrice,
            backers[_backerAddress][index].tokenAmount,
            backers[_backerAddress][index].privateHash,
            backers[_backerAddress][index].prepaid,
            backers[_backerAddress][index].claimed
            );
    }

     
    function approveWithdraw(uint _withdrawalID)
        external
        backerCheck(_withdrawalID)
    {
        withdrawalsVotes[msg.sender][_withdrawalID] = true;

        uint backerStake = 0;
        for (uint i = 0; i < backers[msg.sender].length; i++) {
            backerStake += backers[msg.sender][i].tokenAmount;
        }
        withdrawals[_withdrawalID].backerApprovals.push(msg.sender);
        withdrawals[_withdrawalID].totalStake += backerStake;

        WithdrawalVotedEvent(_withdrawalID, msg.sender, backerStake, withdrawals[_withdrawalID].totalStake);

        if(withdrawals[_withdrawalID].totalStake >= (claimedPrepaidUnits + claimedUnits) / 3) {
            uint amountPerAddr;
            bool isMultiPayment = withdrawals[_withdrawalID].destination.length > 1;

            if(isMultiPayment == false){
                amountPerAddr = withdrawals[_withdrawalID].Amount;
            }
            else {
                amountPerAddr = withdrawals[_withdrawalID].Amount / withdrawals[_withdrawalID].destination.length;
            }

            withdrawals[_withdrawalID].approved = true;
            withdrawals[_withdrawalID].spent = true;

            for(i = 0; i < withdrawals[_withdrawalID].destination.length; i++){
                if(!withdrawals[_withdrawalID].destination[i].send(amountPerAddr)) throw;
            }

            WithdrawalApproved(_withdrawalID,
                withdrawals[_withdrawalID].totalStake,
                isMultiPayment,
                withdrawals[_withdrawalID].Amount,
                withdrawals[_withdrawalID].reason);
        }
    }

     
    function withdraw(uint _totalAmount, bytes _reason, address[] _destination)
        external
        founderCall
    {
        if (this.balance < _totalAmount) throw;

        uint withdrawalID = withdrawals.length++;

        withdrawals[withdrawalID].Amount = _totalAmount;
        withdrawals[withdrawalID].reason = _reason;
        withdrawals[withdrawalID].destination = _destination;
        withdrawals[withdrawalID].approved = false;
        withdrawals[withdrawalID].spent = false;

        WithdrawalCreatedEvent(withdrawalID, _totalAmount, _reason);
    }

     
    function redeem(uint _amount, address _backerAddr) returns(bool){
        if (backersRedeemed[_backerAddr] == true) {
            return false;
        }

        uint totalTokens = 0;

        for (uint i = 0; i < backers[_backerAddr].length; i++) {
            if (backers[_backerAddr][i].claimed == false) {
                return false;
            }
            totalTokens += backers[_backerAddr][i].tokenAmount;
        }

        if (totalTokens == _amount){
            backersRedeemed[_backerAddr] = true;

            RedeemEvent(_backerAddr, totalTokens);

            return true;
        }
        else {
            return false;
        }
    }

     
    function getWithdrawalData(uint _withdrawalID) constant public returns (uint, bool, bytes, address[], uint, address[]){
        return (
            withdrawals[_withdrawalID].Amount,
            withdrawals[_withdrawalID].approved,
            withdrawals[_withdrawalID].reason,
            withdrawals[_withdrawalID].backerApprovals,
            withdrawals[_withdrawalID].totalStake,
            withdrawals[_withdrawalID].destination);
    }

    modifier founderCall{
        if (msg.sender != founder) throw;
        _;
    }

    modifier backerCheck(uint _withdrawalID){
        if(backers[msg.sender].length == 0 || withdrawals[_withdrawalID].spent == true || withdrawalsVotes[msg.sender][_withdrawalID] == true) throw;
        _;
    }

    modifier EarliestBackersSet{
       if(earlyBackerList.length < numOfBackers) throw;
       _;
    }

    modifier MinimumBackersClaimed(){
      if(prepaidUnits == 0 ||
        claimedPrepaidUnits == 0 ||
        (claimedPrepaidUnits * divisor / prepaidUnits) < minimumPrepaidClaimedPercent) {
            throw;
        }
      _;
    }

     
    function () {
        throw;
    }

}