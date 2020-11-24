 

pragma solidity ^0.4.24;


contract Ownable {

  address public owner;
  
  mapping(address => uint8) public operators;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() 
    public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier onlyOperator() {
    require(operators[msg.sender] == uint8(1)); 
    _;
  }

   
  function operatorManager(address[] _operators,uint8 flag) 
    public 
    onlyOwner 
    returns(bool){
      for(uint8 i = 0; i< _operators.length; i++) {
        if(flag == uint8(0)){
          operators[_operators[i]] = 1;
        } else {
          delete operators[_operators[i]];
        }
      }
  }

   
  function transferOwnership(address newOwner) 
    public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
  }

}


 
contract Pausable is Ownable {

  event Pause();

  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused 
    returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

   
  function unpause() public onlyOwner whenPaused 
    returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}


 
contract ERC20Token {

    function balanceOf(address _owner) constant public returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);
}


 
contract GuessBaseBiz is Pausable {
    
   
  address public mosContractAddress = 0x420a43153DA24B9e2aedcEC2B8158A8653a3317e;
   
  address public platformAddress = 0xe0F969610699f88612518930D88C0dAB39f67985;
   
  uint256 public serviceChargeRate = 5;
   
  uint256 public maintenanceChargeRate = 0;
   
  uint256 public upperLimit = 1000 * 10 ** 18;
   
  uint256 public lowerLimit = 1 * 10 ** 18;
  
  
  ERC20Token MOS;
  
   
    
   
  event CreateGuess(uint256 indexed id, address indexed creator);

 
 

   
  event DepositAgent(address indexed participant, uint256 indexed id, uint256 optionId, uint256 totalBean);

   
  event PublishOption(uint256 indexed id, uint256 indexed optionId, uint256 odds);

   
  event Abortive(uint256 indexed id);
  
  constructor() public {
      MOS = ERC20Token(mosContractAddress);
  }

  struct Guess {
     
    uint256 id;
     
    address creator;
     
    string title;
     
    string source;
     
    string category;
     
    uint8 disabled;
     
    bytes desc;
     
    uint256 startAt;
     
    uint256 endAt; 
     
    uint8 finished; 
     
    uint8 abortive; 
     
     
     
     
  }

 
 
 
 
 

   
  struct AgentOrder {
    address participant;
    string ipfsBase58;
    string dataHash;
    uint256 bean;
  }
  
  struct Option {
     
    uint256 id;
     
    bytes32 name;
  } 
  

   
  mapping (uint256 => Guess) public guesses;
   
  mapping (uint256 => Option[]) public options;

   
 

   
  mapping (uint256 => mapping (uint256 => AgentOrder[])) public agentOrders;
  
   
  mapping (uint256 => uint256) public guessTotalBean;
  
   
  mapping (uint256 => mapping(uint256 => uint256)) public optionTotalBean;

   
 

   
  enum GuessStatus {
     
    NotStarted, 
     
    Progress,
     
    Deadline,
     
    Finished,
     
    Abortive
  }

   
  function disabled(uint256 id) public view returns(bool) {
      if(guesses[id].disabled == 0){
          return false;
      }else {
          return true;
      }
  }

  
  function getGuessStatus(uint256 guessId) 
    internal 
    view
    returns(GuessStatus) {
      GuessStatus gs;
      Guess memory guess = guesses[guessId];
      uint256 _now = now; 
      if(guess.startAt > _now) {
        gs = GuessStatus.NotStarted;
      } else if((guess.startAt <= _now && _now <= guess.endAt)
                 && guess.finished == 0 
                 && guess.abortive == 0 ) {
        gs = GuessStatus.Progress;
      } else if(_now > guess.endAt && guess.finished == 0) {
        gs = GuessStatus.Deadline;
      } else if(_now > guess.endAt && guess.finished == 1 && guess.abortive == 0) {
        gs = GuessStatus.Finished;  
      } else if(guess.abortive == 1 && guess.finished == 1){
        gs = GuessStatus.Abortive; 
      }
    return gs;
  }
  
   
  function optionExist(uint256 guessId,uint256 optionId)
    internal
    view
    returns(bool){
      Option[] memory _options = options[guessId];
      for (uint8 i = 0; i < _options.length; i++) {
         if(optionId == _options[i].id){
            return true;
         }
      }
      return false;
  }
    
  function() public payable {
  }

   
  function modifyVariable
    (
        address _platformAddress, 
        uint256 _serviceChargeRate, 
        uint256 _maintenanceChargeRate,
        uint256 _upperLimit,
        uint256 _lowerLimit
    ) 
    public 
    onlyOwner {
      platformAddress = _platformAddress;
      serviceChargeRate = _serviceChargeRate;
      maintenanceChargeRate = _maintenanceChargeRate;
      upperLimit = _upperLimit * 10 ** 18;
      lowerLimit = _lowerLimit * 10 ** 18;
  }
  
    
  function createGuess(
       uint256 _id, 
       string _title,
       string _source, 
       string _category,
       uint8 _disabled,
       bytes _desc, 
       uint256 _startAt, 
       uint256 _endAt,
       uint256[] _optionId, 
       bytes32[] _optionName
       ) 
       public 
       whenNotPaused {
        require(guesses[_id].id == uint256(0), "The current guess already exists !!!");
        require(_optionId.length == _optionName.length, "please check options !!!");
        
        guesses[_id] = Guess(_id,
              msg.sender,
              _title,
              _source,
              _category,
              _disabled,
              _desc,
              _startAt,
              _endAt,
              0,
              0
            );
            
        Option[] storage _options = options[_id];
        for (uint8 i = 0;i < _optionId.length; i++) {
            require(!optionExist(_id,_optionId[i]),"The current optionId already exists !!!");
            _options.push(Option(_optionId[i],_optionName[i]));
        }
    
    emit CreateGuess(_id, msg.sender);
  }


     
    function auditGuess
    (
        uint256 _id,
        string _title,
        uint8 _disabled,
        bytes _desc, 
        uint256 _endAt) 
        public 
        onlyOwner
    {
        require(guesses[_id].id != uint256(0), "The current guess not exists !!!");
        require(getGuessStatus(_id) == GuessStatus.NotStarted, "The guess cannot audit !!!");
        Guess storage guess = guesses[_id];
        guess.title = _title;
        guess.disabled = _disabled;
        guess.desc = _desc;
        guess.endAt = _endAt;
   }

    
 
 
 
 
 
 
 
 
      
 
 
 
 
 
 
 
 
    
 
 
 

    
  function depositAgent
  (
      uint256 id, 
      uint256 optionId, 
      string ipfsBase58,
      string dataHash,
      uint256 totalBean
  ) 
    public
    onlyOperator
    whenNotPaused
    returns (bool) {
    require(guesses[id].id != uint256(0), "The current guess not exists !!!");
    require(optionExist(id, optionId),"The current optionId not exists !!!");
    require(!disabled(id), "The guess disabled!!!");
    require(getGuessStatus(id) == GuessStatus.Deadline, "The guess cannot participate !!!");
    
     
    AgentOrder[] storage _agentOrders = agentOrders[id][optionId];
    
     AgentOrder memory agentOrder = AgentOrder(msg.sender,ipfsBase58,dataHash,totalBean);
    _agentOrders.push(agentOrder);
   
    MOS.transferFrom(msg.sender, address(this), totalBean);
    
     
     
     
    optionTotalBean[id][optionId] += totalBean;
     
    guessTotalBean[id] += totalBean;
    
    emit DepositAgent(msg.sender, id, optionId, totalBean);
    return true;
  }
  

      
    function publishOption(uint256 id, uint256 optionId) 
      public 
      onlyOwner
      whenNotPaused
      returns (bool) {
      require(guesses[id].id != uint256(0), "The current guess not exists !!!");
      require(optionExist(id, optionId),"The current optionId not exists !!!");
      require(!disabled(id), "The guess disabled!!!");
      require(getGuessStatus(id) == GuessStatus.Deadline, "The guess cannot publish !!!");
      Guess storage guess = guesses[id];
      guess.finished = 1;
       
      uint256 totalBean = guessTotalBean[id];
       
      uint256 _optionTotalBean = optionTotalBean[id][optionId];
       
      uint256 odds = totalBean * (100 - serviceChargeRate - maintenanceChargeRate) / _optionTotalBean;
      
      AgentOrder[] memory _agentOrders = agentOrders[id][optionId];
      if(odds >= uint256(100)){
         
        uint256 platformFee = totalBean * (serviceChargeRate + maintenanceChargeRate) / 100;
        MOS.transfer(platformAddress, platformFee);
        
        for(uint8 i = 0; i< _agentOrders.length; i++){
            MOS.transfer(_agentOrders[i].participant, (totalBean - platformFee) 
                        * _agentOrders[i].bean 
                        / _optionTotalBean);
        }
      } else {
         
        for(uint8 j = 0; j< _agentOrders.length; j++){
            MOS.transfer(_agentOrders[j].participant, totalBean
                        * _agentOrders[j].bean
                        / _optionTotalBean);
        }
      }

      emit PublishOption(id, optionId, odds);
      return true;
    }
    
    
     
    function abortive(uint256 id) 
        public 
        onlyOwner
        returns(bool) {
        require(guesses[id].id != uint256(0), "The current guess not exists !!!");
        require(getGuessStatus(id) == GuessStatus.Progress ||
                getGuessStatus(id) == GuessStatus.Deadline, "The guess cannot abortive !!!");
    
        Guess storage guess = guesses[id];
        guess.abortive = 1;
        guess.finished = 1;
         
        Option[] memory _options = options[id];
        
        for(uint8 i = 0; i< _options.length;i ++){
             
            AgentOrder[] memory _agentOrders = agentOrders[id][_options[i].id];
            for(uint8 j = 0; j < _agentOrders.length; j++){
                uint256 _bean = _agentOrders[j].bean;
                MOS.transfer(_agentOrders[j].participant, _bean);
            }
        }
        emit Abortive(id);
        return true;
    }
    
     
     
     
     
     
     
    
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    
    
     
     
     
     
     
     
     
     
        
     
     
     
     
     
     

}


contract MosesContract is GuessBaseBiz {
 
 
 
 
 
 
 
 
 
 
 
 
  
  
  constructor(address[] _operators) public {
    for(uint8 i = 0; i< _operators.length; i++) {
        operators[_operators[i]] = uint8(1);
    }
  }

     
    function collectEtherBack(address collectorAddress) public onlyOwner {
        uint256 b = address(this).balance;
        require(b > 0);
        require(collectorAddress != 0x0);

        collectorAddress.transfer(b);
    }

     
    function collectOtherTokens(address tokenContract, address collectorAddress) onlyOwner public returns (bool) {
        ERC20Token t = ERC20Token(tokenContract);

        uint256 b = t.balanceOf(address(this));
        return t.transfer(collectorAddress, b);
    }

}