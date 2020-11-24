 

pragma solidity ^0.4.16;

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

contract Base {
    modifier only(address allowed) {
        require(msg.sender == allowed);
        _;
    }
}

contract Owned is Base {

    address public owner;
    address newOwner;

    function Owned() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) only(owner) public {
        newOwner = _newOwner;
    }

    function acceptOwnership() only(newOwner) public {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);

}

contract ERC20 is Owned {
    using SafeMath for uint;

    bool public isStarted = false;

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
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) isStartedOnly public returns (bool success) {
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint balance) {
        return balances[_owner];
    }

    function approve_fixed(address _spender, uint _currentValue, uint _value) isStartedOnly public returns (bool success) {
        if(allowed[msg.sender][_spender] == _currentValue){
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint _value) isStartedOnly public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    uint public totalSupply;
}

contract Token is ERC20 {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;


    function Token(string _name, string _symbol, uint8 _decimals) public {
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
        Transfer(msg.sender, _to, _amount);
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

    string public name;
    string public symbol;
    uint8 public decimals;

    uint public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function TokenWithoutStart(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint balance) {
        return balances[_owner];
    }

    function approve_fixed(address _spender, uint _currentValue, uint _value) public returns (bool success) {
        if(allowed[msg.sender][_spender] == _currentValue){
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    function mint(address _to, uint _amount) public only(owner) returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
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

contract ICOContract {
    
    address public projectWallet;  
    address public operator = 0x4C67EB86d70354731f11981aeE91d969e3823c39;  

    uint public constant waitPeriod = 7 days;  

    address[] public pendingInvestContracts = [0x0];  
    mapping(address => uint) public pendingInvestContractsIndices;

    address[] public investContracts = [0x0];  
    mapping(address => uint) public investContractsIndices;

    uint public minimalInvestment = 5 ether;
    
    uint public totalEther;  
    uint public totalToken;  

    uint public tokenLeft;
    uint public etherLeft;

    Token public token;
    
     
    uint public minimumCap;  
    uint public maximumCap;   

     
    struct Milestone {
        uint etherAmount;  
        uint tokenAmount;  
        uint startTime;  
        uint finishTime;  
        uint duration;  
        string description; 
        string results;
    }

    Milestone[] public milestones;
    uint public currentMilestone;
    uint public sealTimestamp;  

    
    modifier only(address _sender) {
        require(msg.sender == _sender);
        _;
    }

    modifier notSealed() {
        require(now <= sealTimestamp);
        _;
    }

    modifier sealed() {
        require(now > sealTimestamp);
        _;
    }

     
     
     
     
     
     
    function ICOContract(address _tokenAddress, address _projectWallet, uint _sealTimestamp, uint _minimumCap,
                         uint _maximumCap) public {
        token = Token(_tokenAddress);
        projectWallet = _projectWallet;
        sealTimestamp = _sealTimestamp;
        minimumCap = _minimumCap;
        maximumCap = _maximumCap;
    }

     
  
     
     
     
     
     
     
     
    function addMilestone(uint _etherAmount, uint _tokenAmount, uint _startTime, uint _duration, string _description, string _result)        
    notSealed only(operator)
    public returns(uint) {
        totalEther += _etherAmount;
        totalToken += _tokenAmount;
        return milestones.push(Milestone(_etherAmount, _tokenAmount, _startTime, 0, _duration, _description, _result));
    }

     
     
     
     
     
     
     
     
    function editMilestone(uint _id, uint _etherAmount, uint _tokenAmount, uint _startTime, uint _duration, string _description, string _results) 
    notSealed only(operator)
    public {
        require(_id < milestones.length);
        totalEther = totalEther - milestones[_id].etherAmount + _etherAmount;
        totalToken = totalToken - milestones[_id].tokenAmount + _tokenAmount;
        milestones[_id].etherAmount = _etherAmount;
        milestones[_id].tokenAmount = _tokenAmount;
        milestones[_id].startTime = _startTime;
        milestones[_id].duration = _duration;
        milestones[_id].description = _description;
        milestones[_id].results = _results;
    }

     
     
    function seal() only(operator) notSealed() public { 
        assert(milestones.length > 0);
         
        sealTimestamp = now;
        etherLeft = totalEther;
        tokenLeft = totalToken;
    }

    function finishMilestone(string _results) only(operator) public {
        var milestone = getCurrentMilestone();
        milestones[milestone].finishTime = now;
        milestones[milestone].results = _results;
    }

    function startNextMilestone() public only(operator) {
        uint milestone = getCurrentMilestone();
        require(milestones[currentMilestone].finishTime == 0);
        currentMilestone +=1;
        milestones[currentMilestone].startTime = now;
        for(uint i=1; i < investContracts.length; i++) {
                InvestContract investContract =  InvestContract(investContracts[i]); 
                investContract.milestoneStarted(milestone);
        }
    }

     
    function getCurrentMilestone() public constant returns(uint) {
         
        return currentMilestone;
    }
   
     
    function milestonesLength() public view returns(uint) {
        return milestones.length;
    }

     
    function createInvestContract(address _investor, uint _etherAmount, uint _tokenAmount) public 
        sealed only(operator)
        returns(address)
    {
        require(_etherAmount >= minimalInvestment);
         
         
         
        address investContract = new InvestContract(address(this), _investor, _etherAmount, _tokenAmount);
        pendingInvestContracts.push(investContract);
        pendingInvestContractsIndices[investContract]=(pendingInvestContracts.length-1);  
        return(investContract);
    }

     
    function investContractDeposited() public {
         
        uint index = pendingInvestContractsIndices[msg.sender];
        assert(index > 0);
        uint len = pendingInvestContracts.length;
        InvestContract investContract = InvestContract(pendingInvestContracts[index]);
        pendingInvestContracts[index] = pendingInvestContracts[len-1];
        pendingInvestContracts.length = len-1;
        investContracts.push(msg.sender);
        investContractsIndices[msg.sender]=investContracts.length-1;  

        uint investmentToken = investContract.tokenAmount();
        uint investmentEther = investContract.etherAmount();

        etherLeft -= investmentEther;
        tokenLeft -= investmentToken;
        assert(token.transfer(msg.sender, investmentToken)); 
    }

    function returnTokens() public only(operator) {
        uint balance = token.balanceOf(address(this));
        token.transfer(projectWallet, balance);
    }

}


contract Pullable {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;

   
  function withdrawPayment() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    payments[payee] = 0;

    assert(payee.send(payment));
  }

   
  function asyncSend(address _destination, uint256 _amount) internal {
    payments[_destination] = payments[_destination].add(_amount);
  }
}

contract TokenPullable {
  using SafeMath for uint256;
  Token public token;

  mapping(address => uint256) public tokenPayments;

  function TokenPullable(address _ico) public {
      ICOContract icoContract = ICOContract(_ico);
      token = icoContract.token();
  }

   
  function withdrawTokenPayment() public {
    address tokenPayee = msg.sender;
    uint256 tokenPayment = tokenPayments[tokenPayee];

    require(tokenPayment != 0);
    require(token.balanceOf(address(this)) >= tokenPayment);

    tokenPayments[tokenPayee] = 0;

    assert(token.transfer(tokenPayee, tokenPayment));
  }

  function asyncTokenSend(address _destination, uint _amount) internal {
    tokenPayments[_destination] = tokenPayments[_destination].add(_amount);
  }
}

contract InvestContract is TokenPullable, Pullable {

    address public projectWallet;  
    address public investor; 

    uint public arbiterAcceptCount = 0;
    uint public quorum;

    ICOContract public icoContract;
     

    uint[] public etherPartition;  
    uint[] public tokenPartition;  

     
    struct ArbiterInfo { 
        uint index;
        bool accepted;
        uint voteDelay;
    }

    mapping(address => ArbiterInfo) public arbiters;  
    address[] public arbiterList = [0x0];  


     
    struct Dispute {
        uint timestamp;
        string reason;
        address[5] voters;
        mapping(address => address) votes; 
        uint votesProject;
        uint votesInvestor;
    }

    mapping(uint => Dispute) public disputes;

    uint public etherAmount;  
    uint public tokenAmount;  

    bool public disputing=false;
    uint public amountToPay;  
    
     
    modifier only(address _sender) {
        require(msg.sender == _sender);
        _;
    }

    modifier onlyArbiter() {
        require(arbiters[msg.sender].voteDelay > 0);
        _;
    }
  
    function InvestContract(address _ICOContractAddress, address _investor,  uint
                           _etherAmount, uint _tokenAmount) TokenPullable(_ICOContractAddress)
    public {
        icoContract = ICOContract(_ICOContractAddress);
        token = icoContract.token();
		etherAmount = _etherAmount;
        tokenAmount = _tokenAmount;
        projectWallet = icoContract.projectWallet();
        investor = _investor;
        amountToPay = etherAmount*101/100;  
        quorum = 3;
         
        addAcceptedArbiter(0x42efbba0563AE5aa2312BeBce1C18C6722B67857, 1);  
        addAcceptedArbiter(0x37D5953c24a2efD372C97B06f22416b68e896eaf, 1); 
        addAcceptedArbiter(0xd0D2e05Fd34d566612529512F7Af1F8a60EDAb6C, 1); 
        addAcceptedArbiter(0xB6508aFaCe815e481bf3B3Fa9B4117D46C963Ec3, 1); 
        addAcceptedArbiter(0x73380dc12B629FB7fBD221E05D25E42f5f3FAB11, 1); 

        arbiterAcceptCount = 5;

		uint milestoneEtherAmount;  
		uint milestoneTokenAmount;  

		uint milestoneEtherTarget;  
		uint milestoneTokenTarget;  

		uint totalEtherInvestment; 
		uint totalTokenInvestment;
		for(uint i=0; i<icoContract.milestonesLength(); i++) {
			(milestoneEtherTarget, milestoneTokenTarget, , , , , ) = icoContract.milestones(i);
			milestoneEtherAmount = _etherAmount * milestoneEtherTarget / icoContract.totalEther();  
			milestoneTokenAmount = _tokenAmount * milestoneTokenTarget / icoContract.totalToken();
			totalEtherInvestment += milestoneEtherAmount;  
			totalTokenInvestment += milestoneTokenAmount;  
			etherPartition.push(milestoneEtherAmount);  
			tokenPartition.push(milestoneTokenAmount);
		}
		etherPartition[0] += _etherAmount - totalEtherInvestment;  
		tokenPartition[0] += _tokenAmount - totalTokenInvestment;  
    }

    function() payable public only(investor) { 
        require(arbiterAcceptCount >= quorum);
        require(msg.value == amountToPay);
        require(getCurrentMilestone() == 0);  
        icoContract.investContractDeposited();
    } 

     
    function addAcceptedArbiter(address _arbiter, uint _delay) internal {
        require(token.balanceOf(address(this))==0);  
        require(_delay > 0);  
        var index = arbiterList.push(_arbiter);
        arbiters[_arbiter] = ArbiterInfo(index, true, _delay);
    }

     

    function vote(address _voteAddress) public onlyArbiter {   
        require(_voteAddress == investor || _voteAddress == projectWallet);
        require(disputing);
        uint milestone = getCurrentMilestone();
        require(milestone > 0);
        require(disputes[milestone].votes[msg.sender] == 0); 
        require(now - disputes[milestone].timestamp >= arbiters[msg.sender].voteDelay);  
        disputes[milestone].votes[msg.sender] = _voteAddress;
        disputes[milestone].voters[disputes[milestone].votesProject+disputes[milestone].votesInvestor] = msg.sender;
        if (_voteAddress == projectWallet) {
            disputes[milestone].votesProject += 1;
        } else if (_voteAddress == investor) {
            disputes[milestone].votesInvestor += 1;
        } else { 
            revert();
        }

        if (disputes[milestone].votesProject >= quorum) {
            executeVerdict(true);
        }
        if (disputes[milestone].votesInvestor >= quorum) {
            executeVerdict(false);
        }
    }

    function executeVerdict(bool _projectWon) internal {
         
        disputing = false;
        if (_projectWon) {
             
        } else  {
		 
		 
             
        }
    }

    function openDispute(string _reason) public only(investor) {
        assert(!disputing);
        var milestone = getCurrentMilestone();
        assert(milestone > 0);
        disputing = true;
        disputes[milestone].timestamp = now;
        disputes[milestone].reason = _reason;
    }

	function milestoneStarted(uint _milestone) public only(address(icoContract)) {
        require(!disputing);
		var etherToSend = etherPartition[_milestone];
		var tokensToSend = tokenPartition[_milestone];

		 
		asyncSend(projectWallet, etherToSend);
		asyncTokenSend(investor, tokensToSend);

    }

    function getCurrentMilestone() public constant returns(uint) {
        return icoContract.getCurrentMilestone();
    }

}