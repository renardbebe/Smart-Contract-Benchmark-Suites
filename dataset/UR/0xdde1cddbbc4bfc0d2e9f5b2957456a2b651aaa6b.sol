 

pragma solidity ^0.4.20;

 

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal  pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal  pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Owned {

    address public owner;
    address newOwner;

    modifier only(address _allowed) {
        require(msg.sender == _allowed);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) only(owner) public {
        newOwner = _newOwner;
    }

    function acceptOwnership() only(newOwner) public {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);

}

contract ERC20 is Owned {
    using SafeMath for uint;

    uint public totalSupply;
    bool public isStarted = false;
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    modifier isStartedOnly() {
        require(isStarted);
        _;
    }

    modifier isNotStartedOnly() {
        require(!isStarted);
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function transfer(address _to, uint _value) isStartedOnly public returns (bool success) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) isStartedOnly public returns (bool success) {
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve_fixed(address _spender, uint _currentValue, uint _value) isStartedOnly public returns (bool success) {
        if(allowed[msg.sender][_spender] == _currentValue){
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint _value) isStartedOnly public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

contract Token is ERC20 {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function start() public only(owner) isNotStartedOnly {
        isStarted = true;
    }

     
    function mint(address _to, uint _amount) public only(owner) isNotStartedOnly returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function multimint(address[] dests, uint[] values) public only(owner) isNotStartedOnly returns (uint) {
        uint i = 0;
        while (i < dests.length) {
           mint(dests[i], values[i]);
           i += 1;
        }
        return(i);
    }
}

contract TokenWithoutStart is Owned {
    using SafeMath for uint;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve_fixed(address _spender, uint _currentValue, uint _value) public returns (bool success) {
        if(allowed[msg.sender][_spender] == _currentValue){
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function mint(address _to, uint _amount) public only(owner) returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function multimint(address[] dests, uint[] values) public only(owner) returns (uint) {
        uint i = 0;
        while (i < dests.length) {
           mint(dests[i], values[i]);
           i += 1;
        }
        return(i);
    }

}

 

 
contract ICO {
     

    string public name;

    address public operator;  
    address public projectWallet;  
    Token public token;  
    address public juryOnlineWallet;  
    address public arbitrationAddress;  
    uint public currentCycle;  

    struct Cycle {
        bool exists;
        bool approved;
        address icoRoundAddress;
    }

    mapping(uint => Cycle) public cycles;  

     
     
     
     
     
     
     
    constructor(string _name, address _operator, address _projectWallet, address _tokenAddress, address _arbitrationAddress, address _juryOnlineWallet) public {
        name = _name;
        operator = _operator;
        projectWallet = _projectWallet;
        token = Token(_tokenAddress);
        arbitrationAddress = _arbitrationAddress;
        juryOnlineWallet = _juryOnlineWallet;
    }

     
    function addRound() public {
        cycles[currentCycle].exists = true;
        cycles[currentCycle].icoRoundAddress = msg.sender;
    }

     
    function approveRound(address _icoRoundAddress) public {
        require(msg.sender == operator);
        require(cycles[currentCycle].icoRoundAddress == _icoRoundAddress);
        currentCycle +=1;
    }

}
 
contract Cycle {

    using SafeMath for uint;

     

    address public juryOperator;  
    address public operator;  
    address public icoAddress;  
    address public juryOnlineWallet;  
    address public projectWallet;  
    address public arbitrationAddress;  
    Token public token;  

    address public jotter;  

    bool public saveMe;  

    struct Milestone {
        uint etherAmount;  
        uint tokenAmount;  
        uint startTime;  
        uint finishTime;  
        uint duration;  
        string description;
        string result;
    }

    Milestone[] public milestones;  
    uint public currentMilestone;

    uint public sealTimestamp;  

    uint public ethForMilestone;  
    uint public postDisputeEth;  

     
     
    struct Investor {
        bool disputing;
        uint tokenAllowance;
        uint etherUsed;
        uint sumEther;
        uint sumToken;
        bool verdictForProject;
        bool verdictForInvestor;
        uint numberOfDeals;
    }

    struct Deal {
        address investor;
        uint etherAmount;
        uint tokenAmount;
        bool accepted;
    }

    mapping(address => Investor) public deals;  
    address[] public dealsList;  
    mapping(address => mapping(uint => Deal)) public offers;  

     
     
     
     
     
     
    uint[] public commissionEth;
    uint[] public commissionJot;
    uint public commissionOnInvestmentEth;
    uint public commissionOnInvestmentJot;
    uint public etherAllowance;  
    uint public jotAllowance;  

    uint public totalEther;  
    uint public totalToken;  

    uint public promisedTokens;  
    uint public raisedEther;  

    uint public rate;  
    bool public tokenReleaseAtStart;  
    uint public currentFundingRound;

    bool public roundFailedToStart;

     
    mapping(address => uint[]) public etherPartition;
    mapping(address => uint[]) public tokenPartition;

     
    struct FundingRound {
        uint startTime;
        uint endTime;
        uint rate;
        bool hasWhitelist;
    }

    FundingRound[] public roundPrices;   
    mapping(uint => mapping(address => bool)) public whitelist;  

     
     
    modifier onlyOperator() {
        require(msg.sender == operator || msg.sender == juryOperator);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == operator || msg.sender == juryOperator);
        _;
    }

    modifier sealed() {
        require(sealTimestamp != 0);
         
        _;
    }

    modifier notSealed() {
        require(sealTimestamp == 0);
         
        _;
    }
     
     
     
     
     
     
     
     
     
    constructor( address _icoAddress,
                 address _operator,
                 uint _rate,
                 address _jotter,
                 uint[] _commissionEth,
                 uint[] _commissionJot,
                 uint _commissionOnInvestmentEth,
                 uint _commissionOnInvestmentJot
                 ) public {
        require(_commissionEth.length == _commissionJot.length);
        juryOperator = msg.sender;
        icoAddress = _icoAddress;
        operator = _operator;
        rate = _rate;
        jotter = _jotter;
        commissionEth = _commissionEth;
        commissionJot = _commissionJot;
        roundPrices.push(FundingRound(0,0,0,false));
        tokenReleaseAtStart = true;
        commissionOnInvestmentEth = _commissionOnInvestmentEth;
        commissionOnInvestmentJot = _commissionOnInvestmentJot;
    }

     
    function setJotter(address _jotter) public {
        require(msg.sender == juryOperator);
        jotter = _jotter;
    }

     
     
    function activate() onlyAdmin notSealed public {
        ICO icoContract = ICO(icoAddress);
        require(icoContract.operator() == operator);
        juryOnlineWallet = icoContract.juryOnlineWallet();
        projectWallet = icoContract.projectWallet();
        arbitrationAddress = icoContract.arbitrationAddress();
        token = icoContract.token();
        icoContract.addRound();
    }

     
     
     
    function withdrawEther() public {
        if (roundFailedToStart == true) {
            require(msg.sender.send(deals[msg.sender].sumEther));
        }
        if (msg.sender == operator) {
            require(projectWallet.send(ethForMilestone+postDisputeEth));
            ethForMilestone = 0;
            postDisputeEth = 0;
        }
        if (msg.sender == juryOnlineWallet) {
            require(juryOnlineWallet.send(etherAllowance));
            require(jotter.call.value(jotAllowance)(abi.encodeWithSignature("swapMe()")));
            etherAllowance = 0;
            jotAllowance = 0;
        }
        if (deals[msg.sender].verdictForInvestor == true) {
            require(msg.sender.send(deals[msg.sender].sumEther - deals[msg.sender].etherUsed));
        }
    }

     
    function withdrawToken() public {
        require(token.transfer(msg.sender,deals[msg.sender].tokenAllowance));
        deals[msg.sender].tokenAllowance = 0;
    }

     
    function addRoundPrice(uint _startTime,uint _endTime, uint _price, address[] _whitelist) public onlyOperator {
        if (_whitelist.length == 0) {
            roundPrices.push(FundingRound(_startTime, _endTime,_price,false));
        } else {
            for (uint i=0 ; i < _whitelist.length ; i++ ) {
                whitelist[roundPrices.length][_whitelist[i]] = true;
            }
            roundPrices.push(FundingRound(_startTime, _endTime,_price,true));
        }
    }

     
    function setRate(uint _rate) onlyOperator public {
        rate = _rate;
    }

     
    function setCurrentFundingRound(uint _fundingRound) public onlyOperator {
        require(roundPrices.length > _fundingRound);
        currentFundingRound = _fundingRound;
        rate = roundPrices[_fundingRound].rate;
    }

     
    function () public payable {
        require(msg.value > 0);
        if (roundPrices[currentFundingRound].hasWhitelist == true) {
            require(whitelist[currentFundingRound][msg.sender] == true);
        }
        uint dealNumber = deals[msg.sender].numberOfDeals;
        offers[msg.sender][dealNumber].investor = msg.sender;
        offers[msg.sender][dealNumber].etherAmount = msg.value;
        deals[msg.sender].numberOfDeals += 1;
    }

     
    function withdrawOffer(uint _offerNumber) public {
        require(offers[msg.sender][_offerNumber].accepted == false);
        require(msg.sender.send(offers[msg.sender][_offerNumber].etherAmount));
        offers[msg.sender][_offerNumber].etherAmount = 0;
         
    }

     
     
    function disputeOpened(address _investor) public {
        require(msg.sender == arbitrationAddress);
        deals[_investor].disputing = true;
    }

     
    function verdictExecuted(address _investor, bool _verdictForInvestor,uint _milestoneDispute) public {
        require(msg.sender == arbitrationAddress);
        require(deals[_investor].disputing == true);
        if (_verdictForInvestor) {
            deals[_investor].verdictForInvestor = true;
        } else {
            deals[_investor].verdictForProject = true;
            for (uint i = _milestoneDispute; i < currentMilestone; i++) {
                postDisputeEth += etherPartition[_investor][i];
                deals[_investor].etherUsed += etherPartition[_investor][i];
            }
        }
        deals[_investor].disputing = false;
    }

     
     
    function addMilestone(uint _etherAmount, uint _tokenAmount, uint _startTime, uint _duration, string _description) public notSealed onlyOperator returns(uint) {
        totalEther = totalEther.add(_etherAmount);
        totalToken = totalToken.add(_tokenAmount);
        return milestones.push(Milestone(_etherAmount, _tokenAmount, _startTime, 0, _duration, _description, ""));
    }

     
    function editMilestone(uint _id, uint _etherAmount, uint _tokenAmount, uint _startTime, uint _duration, string _description) public notSealed onlyOperator {
        assert(_id < milestones.length);
        totalEther = (totalEther - milestones[_id].etherAmount).add(_etherAmount);  
        totalToken = (totalToken - milestones[_id].tokenAmount).add(_tokenAmount);
        milestones[_id].etherAmount = _etherAmount;
        milestones[_id].tokenAmount = _tokenAmount;
        milestones[_id].startTime = _startTime;
        milestones[_id].duration = _duration;
        milestones[_id].description = _description;
    }

     
    function seal() public notSealed onlyOperator {
        require(milestones.length > 0);
        require(token.balanceOf(address(this)) >= totalToken);
        sealTimestamp = now;
    }

     
    function acceptOffer(address _investor, uint _offerNumber) public sealed onlyOperator {
         
        require(offers[_investor][_offerNumber].etherAmount > 0);
        require(offers[_investor][_offerNumber].accepted != true);
         
        offers[_investor][_offerNumber].accepted = true;
         
        uint  _etherAmount = offers[_investor][_offerNumber].etherAmount;
        uint _tokenAmount = offers[_investor][_offerNumber].tokenAmount;
        require(token.balanceOf(address(this)) >= promisedTokens + _tokenAmount);
         
        if (commissionOnInvestmentEth > 0 || commissionOnInvestmentJot > 0) {
            uint etherCommission = _etherAmount.mul(commissionOnInvestmentEth).div(100);
            uint jotCommission = _etherAmount.mul(commissionOnInvestmentJot).div(100);
            _etherAmount = _etherAmount.sub(etherCommission).sub(jotCommission);
            offers[_investor][_offerNumber].etherAmount = _etherAmount;

            etherAllowance += etherCommission;
            jotAllowance += jotCommission;
        }
        assignPartition(_investor, _etherAmount, _tokenAmount);
        if (!(deals[_investor].sumEther > 0)) dealsList.push(_investor);
        if (tokenReleaseAtStart == true) {
            deals[_investor].tokenAllowance = _tokenAmount;
        }

        deals[_investor].sumEther += _etherAmount;
        deals[_investor].sumToken += _tokenAmount;
    	 
    	promisedTokens += _tokenAmount;
    	raisedEther += _etherAmount;
    }

     
    function startMilestone() public sealed onlyOperator {
         
         
         
        if (currentMilestone != 0 ) {require(milestones[currentMilestone-1].finishTime > 0);}
        for (uint i=0; i < dealsList.length ; i++) {
            address investor = dealsList[i];
            if (deals[investor].disputing == false) {
                if (deals[investor].verdictForInvestor != true) {
                    ethForMilestone += etherPartition[investor][currentMilestone];
                    deals[investor].etherUsed += etherPartition[investor][currentMilestone];
                    if (tokenReleaseAtStart == false) {
                        deals[investor].tokenAllowance += tokenPartition[investor][currentMilestone];
                    }
                }
            }
        }
        milestones[currentMilestone].startTime = now;
        currentMilestone +=1;
        ethForMilestone = payCommission();
	 
    }

     
    function payCommission() internal returns(uint) {
        if (commissionEth.length >= currentMilestone) {
            uint ethCommission = raisedEther.mul(commissionEth[currentMilestone-1]).div(100);
            uint jotCommission = raisedEther.mul(commissionJot[currentMilestone-1]).div(100);
            etherAllowance += ethCommission;
            jotAllowance += jotCommission;
            return ethForMilestone.sub(ethCommission).sub(jotCommission);
        } else {
            return ethForMilestone;
        }
    }

     
    function finishMilestone(string _result) public onlyOperator {
        require(milestones[currentMilestone-1].finishTime == 0);
        uint interval = now - milestones[currentMilestone-1].startTime;
        require(interval > 1 weeks);
        milestones[currentMilestone-1].finishTime = now;
        milestones[currentMilestone-1].result = _result;
    }
     
     
     
    function failSafe() public onlyAdmin {
        if (msg.sender == operator) {
            saveMe = true;
        }
        if (msg.sender == juryOperator) {
            require(saveMe == true);
            require(juryOperator.send(address(this).balance));
            uint allTheLockedTokens = token.balanceOf(this);
            require(token.transfer(juryOperator,allTheLockedTokens));
        }
    }

    function milestonesLength() public view returns(uint) {
        return milestones.length;
    }

    function assignPartition(address _investor, uint _etherAmount, uint _tokenAmount) internal {
        uint milestoneEtherAmount;  
		uint milestoneTokenAmount;  
		uint milestoneEtherTarget;  
		uint milestoneTokenTarget;  
		uint totalEtherInvestment;
		uint totalTokenInvestment;
        for(uint i=currentMilestone; i<milestones.length; i++) {
			milestoneEtherTarget = milestones[i].etherAmount;
            milestoneTokenTarget = milestones[i].tokenAmount;
			milestoneEtherAmount = _etherAmount.mul(milestoneEtherTarget).div(totalEther);
			milestoneTokenAmount = _tokenAmount.mul(milestoneTokenTarget).div(totalToken);
			totalEtherInvestment = totalEtherInvestment.add(milestoneEtherAmount);  
			totalTokenInvestment = totalTokenInvestment.add(milestoneTokenAmount);  
            if (deals[_investor].sumEther > 0) {
                etherPartition[_investor][i] += milestoneEtherAmount;
    			tokenPartition[_investor][i] += milestoneTokenAmount;
            } else {
                etherPartition[_investor].push(milestoneEtherAmount);
    			tokenPartition[_investor].push(milestoneTokenAmount);
            }

		}
         
		etherPartition[_investor][currentMilestone] += _etherAmount - totalEtherInvestment;  
		tokenPartition[_investor][currentMilestone] += _tokenAmount - totalTokenInvestment;  
    }

     
    function isDisputing(address _investor) public view returns(bool) {
        return deals[_investor].disputing;
    }

    function investorExists(address _investor) public view returns(bool) {
        if (deals[_investor].sumEther > 0) return true;
        else return false;
    }

}

contract Arbitration is Owned {

    address public operator;

    uint public quorum = 3;

    struct Dispute {
        address icoRoundAddress;
        address investorAddress;
        bool pending;
        uint timestamp;
        uint milestone;
        string reason;
        uint votesForProject;
        uint votesForInvestor;
         
         
        mapping(address => bool) voters;
    }
    mapping(uint => Dispute) public disputes;

    uint public disputeLength;

    mapping(address => mapping(address => bool)) public arbiterPool;

    modifier only(address _allowed) {
        require(msg.sender == _allowed);
        _;
    }

    constructor() public {
        operator = msg.sender;
    }

     
    function setArbiters(address _icoRoundAddress, address[] _arbiters) only(owner) public {
        for (uint i = 0; i < _arbiters.length ; i++) {
            arbiterPool[_icoRoundAddress][_arbiters[i]] = true;
        }
    }

     
    function vote(uint _disputeId, bool _voteForInvestor) public {
        require(disputes[_disputeId].pending == true);
        require(arbiterPool[disputes[_disputeId].icoRoundAddress][msg.sender] == true);
        require(disputes[_disputeId].voters[msg.sender] != true);
        if (_voteForInvestor == true) { disputes[_disputeId].votesForInvestor += 1; }
        else { disputes[_disputeId].votesForProject += 1; }
        if (disputes[_disputeId].votesForInvestor == quorum) {
            executeVerdict(_disputeId,true);
        }
        if (disputes[_disputeId].votesForProject == quorum) {
            executeVerdict(_disputeId,false);
        }
        disputes[_disputeId].voters[msg.sender] == true;
    }

     
    function openDispute(address _icoRoundAddress, string _reason) public {
        Cycle icoRound = Cycle(_icoRoundAddress);
        uint milestoneDispute = icoRound.currentMilestone();
        require(milestoneDispute > 0);
        require(icoRound.investorExists(msg.sender) == true);
        disputes[disputeLength].milestone = milestoneDispute;

        disputes[disputeLength].icoRoundAddress = _icoRoundAddress;
        disputes[disputeLength].investorAddress = msg.sender;
        disputes[disputeLength].timestamp = now;
        disputes[disputeLength].reason = _reason;
        disputes[disputeLength].pending = true;

        icoRound.disputeOpened(msg.sender);
        disputeLength +=1;
    }

     
    function executeVerdict(uint _disputeId, bool _verdictForInvestor) internal {
        disputes[_disputeId].pending = false;
        uint milestoneDispute = disputes[_disputeId].milestone;
        Cycle icoRound = Cycle(disputes[_disputeId].icoRoundAddress);
        icoRound.verdictExecuted(disputes[_disputeId].investorAddress,_verdictForInvestor,milestoneDispute);
         
    }

    function isPending(uint _disputedId) public view returns(bool) {
        return disputes[_disputedId].pending;
    }

}

contract Jotter {
     
    Token public token;
    uint public ethToJot = 2443;
    address public owner;

    constructor(address _jotAddress) public {
        owner = msg.sender;
        token = Token(_jotAddress);
    }

    function swapMe() public payable {
        uint jot = msg.value * ethToJot;
        require(token.transfer(owner,jot));
    }
     
     
    function setEth(uint _newEth) public {
        require(msg.sender == owner);
        ethToJot = _newEth;
    }

}

contract SwapperX {

     
     

    Token public proxyToken;
    Token public token;

    address public owner;

    struct Swap {
        address _from;
        uint _amount;
    }

    Swap[] public swaps;

    constructor(address _tokenAddress, address _proxyTokenAddress) public {
        owner = msg.sender;
        token = Token(_tokenAddress);
        proxyToken = Token(_proxyTokenAddress);
    }

     
    function swapMe() public {
        uint allowance = proxyToken.allowance(msg.sender,address(this));
        require(token.balanceOf(address(this)) >= allowance);
        require(token.transfer(msg.sender, allowance));
        require(proxyToken.transferFrom(msg.sender,address(this),allowance));
        swaps.push(Swap(msg.sender,allowance));
    }

     
    function returnMe() public {
        uint allowance = proxyToken.allowance(msg.sender,address(this));
        require(proxyToken.transferFrom(msg.sender,address(this),allowance));
        require(proxyToken.transfer(msg.sender, allowance));
    }

}