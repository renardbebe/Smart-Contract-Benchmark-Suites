 

pragma solidity ^0.4.25;

 
contract SafeMath {

     
    function safeSub(uint256 x, uint256 y) internal pure returns (uint256) {
        assert(y <= x);
        uint256 z = x - y;
        return z;
    }

     
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        assert(z >= x);
        return z;
    }
	
	 
    function safeDiv(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x / y;
        return z;
    }
    
     	
    function safeMul(uint256 x, uint256 y) internal pure returns (uint256) {    
        if (x == 0) {
            return 0;
        }
    
        uint256 z = x * y;
        assert(z / x == y);
        return z;
    }

     
    function safePerc(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }
        
        uint256 z = x * y;
        assert(z / x == y);    
        z = z / 10000;  
        return z;
    }

     	
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x <= y ? x : y;
        return z;
    }

     
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x >= y ? x : y;
        return z;
    }
}


 
interface DAppDEXI {

    function updateAgent(address _agent, bool _status) external;

    function setAccountType(address user_, uint256 type_) external;
    function getAccountType(address user_) external view returns(uint256);
    function setFeeType(uint256 type_ , uint256 feeMake_, uint256 feeTake_) external;
    function getFeeMake(uint256 type_ ) external view returns(uint256);
    function getFeeTake(uint256 type_ ) external view returns(uint256);
    function changeFeeAccount(address feeAccount_) external;
    
    function setWhitelistTokens(address token) external;
    function setWhitelistTokens(address token, bool active, uint256 timestamp, bytes32 typeERC) external;
    function depositToken(address token, uint amount) external;
    function tokenFallback(address owner, uint256 amount, bytes data) external returns (bool success);

    function withdraw(uint amount) external;
    function withdrawToken(address token, uint amount) external;

    function balanceOf(address token, address user) external view returns (uint);

    function order(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce) external;
    function trade(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) external;    
    function cancelOrder(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) external;
    function testTrade(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) external view returns(bool);
    function availableVolume(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) external view returns(uint);
    function amountFilled(address tokenBuy, uint amountBuy, address tokenSell, uint amountSell, uint expires, uint nonce, address user) external view returns(uint);
}


 
interface ERC20I {

  function balanceOf(address _owner) external view returns (uint256);

  function totalSupply() external view returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool success);
  
  function allowance(address _owner, address _spender) external view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  function approve(address _spender, uint256 _value) external returns (bool success);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract Ownable {
  
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);
  
   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    assert(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    assert(_newOwner != address(0));      
    newOwner = _newOwner;
  }

   
  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }
  }
}


 
interface SDADI  {	
  function AddToken(address token) external;
  function DelToken(address token) external;
}


 
contract ERC20Base is ERC20I, SafeMath {
	
  uint256 totalSupply_;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 public start = 0;                
  uint256 public period = 30 days;         
  mapping (address => mapping (uint256 => int256)) public ChangeOverPeriod;

  address[] public owners;
  mapping (address => bool) public ownersIndex;

  struct _Prop {
    uint propID;           
    uint endTime;          
  }
  
  _Prop[] public ActiveProposals;   

   
  mapping (uint => mapping (address => uint)) public voted;

     
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

   
  function balanceOf(address _owner, uint _date) public view returns (uint256) {
    require(_date >= start);
    uint256 N1 = (_date - start) / period + 1;    

    uint256 N2 = 1;
    if (block.timestamp > start) {
      N2 = (block.timestamp - start) / period + 1;
    }

    require(N2 >= N1);

    int256 B = int256(balances[_owner]);

    while (N2 > N1) {
      B = B - ChangeOverPeriod[_owner][N2];
      N2--;
    }

    require(B >= 0);
    return uint256(B);
  }

   
  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(_to != address(0));

    uint lock = 0;
    for (uint k = 0; k < ActiveProposals.length; k++) {
      if (ActiveProposals[k].endTime > now) {
        if (lock < voted[ActiveProposals[k].propID][msg.sender]) {
          lock = voted[ActiveProposals[k].propID][msg.sender];
        }
      }
    }

    require(safeSub(balances[msg.sender], lock) >= _value);

    if (ownersIndex[_to] == false && _value > 0) {
      ownersIndex[_to] = true;
      owners.push(_to);
    }
    
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);

    uint256 N = 1;
    if (block.timestamp > start) {
      N = (block.timestamp - start) / period + 1;
    }

    ChangeOverPeriod[msg.sender][N] = ChangeOverPeriod[msg.sender][N] - int256(_value);
    ChangeOverPeriod[_to][N] = ChangeOverPeriod[_to][N] + int256(_value);
   
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_to != address(0));

    uint lock = 0;
    for (uint k = 0; k < ActiveProposals.length; k++) {
      if (ActiveProposals[k].endTime > now) {
        if (lock < voted[ActiveProposals[k].propID][_from]) {
          lock = voted[ActiveProposals[k].propID][_from];
        }
      }
    }
    
    require(safeSub(balances[_from], lock) >= _value);
    
    require(allowed[_from][msg.sender] >= _value);

    if (ownersIndex[_to] == false && _value > 0) {
      ownersIndex[_to] = true;
      owners.push(_to);
    }
    
    balances[_from] = safeSub(balances[_from], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
    
    uint256 N = 1;
    if (block.timestamp > start) {
      N = (block.timestamp - start) / period + 1;
    }

    ChangeOverPeriod[_from][N] = ChangeOverPeriod[_from][N] - int256(_value);
    ChangeOverPeriod[_to][N] = ChangeOverPeriod[_to][N] + int256(_value);

    emit Transfer(_from, _to, _value);
    return true;
  }
  
   
  function approve(address _spender, uint256 _value) public returns (bool success) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function trim(uint offset, uint limit) external returns (bool) { 
    uint k = offset;
    uint ln = limit;
    while (k < ln) {
      if (balances[owners[k]] == 0) {
        ownersIndex[owners[k]] =  false;
        owners[k] = owners[owners.length-1];
        owners.length = owners.length-1;
        ln--;
      } else {
        k++;
      }
    }
    return true;
  }

   
  function getOwnersCount() external view returns (uint256 count) {
    return owners.length;
  }

   
  function getCurrentPeriod() external view returns (uint256 N) {
    if (block.timestamp > start) {
      return (block.timestamp - start) / period;
    } else {
      return 0;
    }
  }

  function addProposal(uint _propID, uint _endTime) internal {
    ActiveProposals.push(_Prop({
      propID: _propID,
      endTime: _endTime
    }));
  }

  function delProposal(uint _propID) internal {
    uint k = 0;
    while (k < ActiveProposals.length){
      if (ActiveProposals[k].propID == _propID) {
        require(ActiveProposals[k].endTime < now);
        ActiveProposals[k] = ActiveProposals[ActiveProposals.length-1];
        ActiveProposals.length = ActiveProposals.length-1;   
      } else {
        k++;
      }
    }    
  }

  function getVoted(uint _propID, address _voter) external view returns (uint) {
    return voted[_propID][_voter];
  }
}


 
contract Dividends is ERC20Base, Ownable {

  DAppDEXI public DEX;

  address[] public tokens;
  mapping (address => uint) public tokensIndex;
  
  mapping (uint => mapping (address => uint)) public dividends;
  mapping (address => mapping (address => uint)) public ownersbal;  
  mapping (uint => mapping (address => mapping (address => bool))) public AlreadyReceived;

  uint public multiplier = 100000;  

  event Payment(address indexed sender, uint amount);
  event setDEXContractEvent(address dex);
   
  function AddToken(address token) public {
    require(msg.sender == address(DEX));
    tokens.push(token);
    tokensIndex[token] = tokens.length-1;
  }

  function DelToken(address token) public {
    require(msg.sender == address(DEX));
    require(tokens[tokensIndex[token]] != 0);    
    tokens[tokensIndex[token]] = tokens[tokens.length-1];
    tokens.length = tokens.length-1;
  }

   
  function TakeProfit(uint offset, uint limit) external {
    require (limit <= tokens.length);
    require (offset < limit);

    uint N = (block.timestamp - start) / period;
    
    require (N > 0);
    
    for (uint k = offset; k < limit; k++) {
      if(dividends[N][tokens[k]] == 0 ) {
          uint amount = DEX.balanceOf(tokens[k], address(this));
          if (k == 0) {
            DEX.withdraw(amount);
            dividends[N][tokens[k]] = amount;
          } else {
            DEX.withdrawToken(tokens[k], amount);
            dividends[N][tokens[k]] = amount;
          }
      }
    }
  }

  function () public payable {
      emit Payment(msg.sender, msg.value);
  }
  
   
  function PayDividends(address token, uint offset, uint limit) external {
     
    require (limit <= owners.length);
    require (offset < limit);

    uint N = (block.timestamp - start) / period;  
    uint date = start + N * period - 1;
    
    require(dividends[N][token] > 0);

    uint share = 0;
    uint k = 0;
    for (k = offset; k < limit; k++) {
      if (!AlreadyReceived[N][token][owners[k]]) {
        share = safeMul(balanceOf(owners[k], date), multiplier);
        share = safeDiv(safeMul(share, 100), totalSupply_);  

        share = safePerc(dividends[N][token], share);
        share = safeDiv(share, safeDiv(multiplier, 100));   
        
        ownersbal[owners[k]][token] = safeAdd(ownersbal[owners[k]][token], share);
        AlreadyReceived[N][token][owners[k]] = true;
      }
    }
  }

   
  function PayDividends(address token) external {
     

    uint N = (block.timestamp - start) / period;  
    uint date = start + N * period - 1;

    require(dividends[N][token] > 0);
    
    if (!AlreadyReceived[N][token][msg.sender]) {      
      uint share = safeMul(balanceOf(msg.sender, date), multiplier);
      share = safeDiv(safeMul(share, 100), totalSupply_);  

      share = safePerc(dividends[N][token], share);
      share = safeDiv(share, safeDiv(multiplier, 100));   
        
      ownersbal[msg.sender][token] = safeAdd(ownersbal[msg.sender][token], share);
      AlreadyReceived[N][token][msg.sender] = true;
    }
  }

   
  function withdraw(address token, uint _value) external {    
    require(ownersbal[msg.sender][token] >= _value);
    ownersbal[msg.sender][token] = safeSub(ownersbal[msg.sender][token], _value);
    if (token == address(0)) {
      msg.sender.transfer(_value);
    } else {
      ERC20I(token).transfer(msg.sender, _value);
    }
  }
  
   
  function withdraw(address token, uint _value, address _receiver) external {    
    require(ownersbal[msg.sender][token] >= _value);
    ownersbal[msg.sender][token] = safeSub(ownersbal[msg.sender][token], _value);
    if (token == address(0)) {
      _receiver.transfer(_value);
    } else {
      ERC20I(token).transfer(_receiver, _value);
    }    
  }

  function setMultiplier(uint _value) external onlyOwner {
    require(_value > 0);
    multiplier = _value;
  }
  
  function getMultiplier() external view returns (uint ) {
    return multiplier;
  }  

   
  function setDEXContract(address _contract) external onlyOwner {
    DEX = DAppDEXI(_contract);
    emit setDEXContractEvent(_contract);
  }
}


 
interface CommonI {
    function transferOwnership(address _newOwner) external;
    function acceptOwnership() external;
    function updateAgent(address _agent, bool _state) external;    
}


 
contract DAO is Dividends {

     
    uint minBalance = 1000000000000; 
     
    uint public minimumQuorum;
     
    uint public debatingPeriodDuration;
     
    uint public requisiteMajority;

    struct _Proposal {
         
        uint endTimeOfVoting;
         
        bool executed;
         
        bool proposalPassed;
         
        uint numberOfVotes;
         
        uint votesSupport;
         
        uint votesAgainst;
        
         
        address recipient;
         
        uint amount;
         
        bytes32 transactionHash;

         
        string desc;
         
        string fullDescHash;
    }

    _Proposal[] public Proposals;

    event ProposalAdded(uint proposalID, address recipient, uint amount, string description, string fullDescHash);
    event Voted(uint proposalID, bool position, address voter, string justification);
    event ProposalTallied(uint proposalID, uint votesSupport, uint votesAgainst, uint quorum, bool active);    
    event ChangeOfRules(uint newMinimumQuorum, uint newdebatingPeriodDuration, uint newRequisiteMajority);
    event Payment(address indexed sender, uint amount);

     
    modifier onlyMembers {
        require(balances[msg.sender] > 0);
        _;
    }

     
    function changeVotingRules(
        uint _minimumQuorum,
        uint _debatingPeriodDuration,
        uint _requisiteMajority
    ) onlyOwner public {
        minimumQuorum = _minimumQuorum;
        debatingPeriodDuration = _debatingPeriodDuration;
        requisiteMajority = _requisiteMajority;

        emit ChangeOfRules(minimumQuorum, debatingPeriodDuration, requisiteMajority);
    }

     
    function addProposal(address _recipient, uint _amount, string _desc, string _fullDescHash, bytes _transactionByteCode, uint _debatingPeriodDuration) onlyMembers public returns (uint) {
        require(balances[msg.sender] > minBalance);

        if (_debatingPeriodDuration == 0) {
            _debatingPeriodDuration = debatingPeriodDuration;
        }

        Proposals.push(_Proposal({      
            endTimeOfVoting: now + _debatingPeriodDuration * 1 minutes,
            executed: false,
            proposalPassed: false,
            numberOfVotes: 0,
            votesSupport: 0,
            votesAgainst: 0,
            recipient: _recipient,
            amount: _amount,
            transactionHash: keccak256(abi.encodePacked(_recipient, _amount, _transactionByteCode)),
            desc: _desc,
            fullDescHash: _fullDescHash
        }));
        
         
        super.addProposal(Proposals.length-1, Proposals[Proposals.length-1].endTimeOfVoting);

        emit ProposalAdded(Proposals.length-1, _recipient, _amount, _desc, _fullDescHash);

        return Proposals.length-1;
    }

     
    function checkProposalCode(uint _proposalID, address _recipient, uint _amount, bytes _transactionByteCode) view public returns (bool) {
        require(Proposals[_proposalID].recipient == _recipient);
        require(Proposals[_proposalID].amount == _amount);
         
        return Proposals[_proposalID].transactionHash == keccak256(abi.encodePacked(_recipient, _amount, _transactionByteCode));
    }

     
    function vote(uint _proposalID, bool _supportsProposal, string _justificationText) onlyMembers public returns (uint) {
         
        _Proposal storage p = Proposals[_proposalID]; 
        require(now <= p.endTimeOfVoting);

         
        uint votes = safeSub(balances[msg.sender], voted[_proposalID][msg.sender]);
        require(votes > 0);

        voted[_proposalID][msg.sender] = safeAdd(voted[_proposalID][msg.sender], votes);

         
        p.numberOfVotes = p.numberOfVotes + votes;
        
        if (_supportsProposal) {
            p.votesSupport = p.votesSupport + votes;
        } else {
            p.votesAgainst = p.votesAgainst + votes;
        }
        
        emit Voted(_proposalID, _supportsProposal, msg.sender, _justificationText);
        return p.numberOfVotes;
    }

     
    function executeProposal(uint _proposalID, bytes _transactionByteCode) public {
         
        _Proposal storage p = Proposals[_proposalID];

        require(now > p.endTimeOfVoting                                                                        
            && !p.executed                                                                                     
            && p.transactionHash == keccak256(abi.encodePacked(p.recipient, p.amount, _transactionByteCode))   
            && p.numberOfVotes >= minimumQuorum);                                                              
         
        if (p.votesSupport > requisiteMajority) {
             
            require(p.recipient.call.value(p.amount)(_transactionByteCode));
            p.proposalPassed = true;
        } else {
             
            p.proposalPassed = false;
        }
        p.executed = true;

         
        super.delProposal(_proposalID);
       
         
        emit ProposalTallied(_proposalID, p.votesSupport, p.votesAgainst, p.numberOfVotes, p.proposalPassed);
    }

     
    function delActiveProposal(uint _proposalID) public onlyOwner {
         
        super.delProposal(_proposalID);   
    }

     
    function transferOwnership(address _contract, address _newOwner) public onlyOwner {
        CommonI(_contract).transferOwnership(_newOwner);
    }

     
    function acceptOwnership(address _contract) public onlyOwner {
        CommonI(_contract).acceptOwnership();        
    }

    function updateAgent(address _contract, address _agent, bool _state) public onlyOwner {
        CommonI(_contract).updateAgent(_agent, _state);        
    }

     
    function setMinBalance(uint _minBalance) public onlyOwner {
        assert(_minBalance > 0);
        minBalance = _minBalance;
    }
}


 
contract Agent is Ownable {

  address public defAgent;

  mapping(address => bool) public Agents;
  
  constructor() public {    
    Agents[msg.sender] = true;
  }
  
  modifier onlyAgent() {
    assert(Agents[msg.sender]);
    _;
  }
  
  function updateAgent(address _agent, bool _status) public onlyOwner {
    assert(_agent != address(0));
    Agents[_agent] = _status;
  }  
}


 
contract SDAD is SDADI, DAO {
	
  uint public initialSupply = 10 * 10**6;  
  uint public decimals = 8;

  string public name;
  string public symbol;

   
  event UpdatedTokenInformation(string _name, string _symbol);

   
  event UpdatedPeriod(uint _period);

  constructor(string _name, string _symbol, uint _start, uint _period, address _dexowner) public {
    name = _name;
    symbol = _symbol;
    start = _start;
    period = _period;

    totalSupply_ = initialSupply*10**decimals;

     
    balances[_dexowner] = totalSupply_;    
    emit Transfer(0x0, _dexowner, balances[_dexowner]);

    ownersIndex[_dexowner] = true;
    owners.push(_dexowner);

    ChangeOverPeriod[_dexowner][1] = int256(balances[_dexowner]);

     
     
     
     
    changeVotingRules(safePerc(totalSupply_, 5000), 1440, safePerc(totalSupply_, 2500));

     
    tokens.push(address(0));
    tokensIndex[address(0)] = tokens.length-1;
  } 

   
  function setTokenInformation(string _name, string _symbol) public onlyOwner {
    name = _name;
    symbol = _symbol;
    emit UpdatedTokenInformation(_name, _symbol);
  }

   
  function setPeriod(uint _period) public onlyOwner {
    period = _period;
    emit UpdatedPeriod(_period);    
  }

   
  function setOwnerToSelf() public onlyOwner {
    owner = address(this);
    emit OwnershipTransferred(msg.sender, address(this));
  }
}