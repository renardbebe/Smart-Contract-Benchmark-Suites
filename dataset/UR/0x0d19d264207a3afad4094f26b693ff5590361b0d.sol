 

pragma solidity 0.4.24;

 
library SafeMath {

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

   
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract StandardToken is ERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;
    mapping (address => mapping (address => uint256)) internal allowed;


   
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

   
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

   
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

   
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

   
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

      
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

   
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

   
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract RotoToken is StandardToken {

    string public constant name = "Roto";  
    string public constant symbol = "ROTO";  
    uint8 public constant decimals = 18;  

    uint256 public constant INITIAL_SUPPLY = 21000000 * (10 ** uint256(decimals));
    address owner;
    address roto = this;
    address manager;

     
     
    mapping (address => mapping (bytes32 => uint256)) stakes;
    uint256 owner_transfer = 2000000 * (10** uint256(decimals));
   

    modifier onlyOwner {
        require(msg.sender==owner);
        _;
    }

    modifier onlyManager {
      require(msg.sender==manager);
      _;
    }

    event ManagerChanged(address _contract);
    event RotoStaked(address _user, uint256 stake);
    event RotoReleased(address _user, uint256 stake);
    event RotoDestroyed(address _user, uint256 stake);
    event RotoRewarded(address _contract, address _user, uint256 reward);

    constructor() public {
        owner = msg.sender;
        totalSupply_ = INITIAL_SUPPLY;
        balances[roto] = INITIAL_SUPPLY;
        emit Transfer(0x0, roto, INITIAL_SUPPLY);
    }

    
     
    function transferFromContract(address _to, uint256 _value) public onlyOwner returns(bool) {
        require(_to!=address(0));
        require(_value<=balances[roto]);
        require(owner_transfer > 0);

        owner_transfer = owner_transfer.sub(_value);
        
        balances[roto] = balances[roto].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(roto, _to, _value);
        return true;
    }

     
    function setManagerContract(address _contract) external onlyOwner returns(bool) {
       
      require(_contract!=address(0)&&_contract!=roto);

       
      uint size;
      assembly { size := extcodesize(_contract) }
      require(size > 0);

      manager = _contract;

      emit ManagerChanged(_contract);
      return true;
    }

     
    function releaseRoto(address _user, bytes32 _tournamentID) external onlyManager returns(bool) {
        require(_user!=address(0));
        uint256 value = stakes[_user][_tournamentID];
        require(value > 0);

        stakes[_user][_tournamentID] = 0;
        balances[_user] = balances[_user].add(value);

        emit RotoReleased(_user, value);
        return true;
    }

     
    function destroyRoto(address _user, bytes32 _tournamentID) external onlyManager returns(bool) {
        require(_user!=address(0));
        uint256 value = stakes[_user][_tournamentID];
        require(value > 0);

        stakes[_user][_tournamentID] = 0;
        balances[roto] = balances[roto].add(value);

        emit RotoDestroyed(_user, value);
        return true;
    }

     
    function stakeRoto(address _user, bytes32 _tournamentID, uint256 _value) external onlyManager returns(bool) {
        require(_user!=address(0));
        require(_value<=balances[_user]);
        require(stakes[_user][_tournamentID] == 0);

        balances[_user] = balances[_user].sub(_value);
        stakes[_user][_tournamentID] = _value;

        emit RotoStaked(_user, _value);
        return true;
    }
    
     
    function rewardRoto(address _user, uint256 _value) external onlyManager returns(bool successful) {
      require(_user!=address(0));
      require(_value<=balances[roto]);

      balances[_user] = balances[_user].add(_value);
      balances[roto] = balances[roto].sub(_value);

      emit Transfer(roto, _user, _value);
      return true;
    }
     
    function canStake(address _user, uint256 _value) public view onlyManager returns(bool) {
      require(_user!=address(0));
      require(_value<=balances[_user]);

      return true;
    }

     
    function getManager() public view returns (address _manager) {
      return manager;
    }

     
    function changeOwner(address _newOwner) public onlyOwner returns(bool) {
      owner = _newOwner;
    }
}

contract RotoBasic {

    mapping (bytes32 => Tournament) public tournaments;   
    
     
    RotoToken token;
    address roto;

     
    address owner;
    address manager;

     
    bool emergency;

    struct Tournament {
        bool open;
         
        uint256 etherPrize;
        uint256 etherLeft;
         
        uint256 rotoPrize;
        uint256 rotoLeft;
         
        uint256 creationTime;
        mapping (address => mapping (bytes32 => Stake)) stakes;   
         
        uint256 userStakes;
        uint256 stakesResolved;
    }

    struct Stake {
        uint256 amount;  
        bool successful;
        bool resolved;
    }

    modifier onlyOwner {
      require(msg.sender==owner);
      _;
    }

    modifier stopInEmergency {
      require(emergency==false);
      _;
    }

     
    event StakeProcessed(address indexed staker, uint256 totalAmountStaked, bytes32 indexed tournamentID);
    event StakeDestroyed(bytes32 indexed tournamentID, address indexed stakerAddress, uint256 rotoLost);
    event StakeReleased(bytes32 indexed tournamentID, address indexed stakerAddress, uint256 etherReward, uint256 rotoStaked);
    event SubmissionRewarded(bytes32 indexed tournamentID, address indexed stakerAddress, uint256 rotoReward);
    
    event TokenChanged(address _contract);
    event TournamentCreated(bytes32 indexed tournamentID, uint256 etherPrize, uint256 rotoPrize);
    event TournamentClosed(bytes32 indexed tournamentID);

     
    function setTokenContract(address _contract) public onlyOwner returns(bool) {
      require(_contract!=address(0)&&_contract!=manager);

       
      uint size;
      assembly { size := extcodesize(_contract) }
      require(size > 0);

      roto = _contract;
      token = RotoToken(roto);

      emit TokenChanged(_contract);
      return true;
    }

     
    function setEmergency(bool _emergency) public onlyOwner returns(bool) {
      emergency = _emergency;
      return true;
    }

     
    function changeOwner(address _newOwner) public onlyOwner returns(bool) {
      owner = _newOwner;
    }

}

contract RotoManager is RotoBasic {

    using SafeMath for uint256;

    constructor() public {
      owner = msg.sender;
      emergency = false;
      manager = this;
    }

     
    function releaseRoto(address _user, bytes32 _tournamentID, uint256 _etherReward) external onlyOwner stopInEmergency returns(bool successful){
        Tournament storage tournament = tournaments[_tournamentID];
        require(tournament.open==true);

        Stake storage user_stake = tournament.stakes[_user][_tournamentID];
        uint256 initial_stake = user_stake.amount;

         
        require(initial_stake > 0);
        require(user_stake.resolved == false);

         
        require(manager.balance > _etherReward);
        require(tournament.etherLeft >= _etherReward);

         
        user_stake.amount = 0;
        assert(token.releaseRoto(_user, _tournamentID));  
        tournament.stakesResolved = tournament.stakesResolved.add(1);
        
        user_stake.resolved = true;
        user_stake.successful = true;

        if(_etherReward > 0) {
          tournament.etherLeft = tournament.etherLeft.sub(_etherReward);
          _user.transfer(_etherReward);
        }

        emit StakeReleased(_tournamentID, _user, _etherReward, initial_stake);
        
        return true;
    }
     
    function rewardRoto(address _user, bytes32 _tournamentID, uint256 _rotoReward) external onlyOwner stopInEmergency returns(bool successful) {
      Tournament storage tournament = tournaments[_tournamentID];
      require(tournament.open==true);

      Stake storage user_stake = tournament.stakes[_user][_tournamentID];
      uint256 initial_stake = user_stake.amount;
      
      require(initial_stake==0);
      require(tournament.rotoLeft >= _rotoReward);
      require(user_stake.resolved == false);

      tournament.rotoLeft = tournament.rotoLeft.sub(_rotoReward);
      assert(token.rewardRoto(_user, _rotoReward));

      user_stake.resolved = true;
      user_stake.successful = true;

      emit SubmissionRewarded(_tournamentID, _user, _rotoReward);

      return true;
    }

     
    function destroyRoto(address _user, bytes32 _tournamentID) external onlyOwner stopInEmergency returns(bool successful) {
        Tournament storage tournament = tournaments[_tournamentID];
        require(tournament.open==true);

        Stake storage user_stake = tournament.stakes[_user][_tournamentID];

        uint256 initial_stake = user_stake.amount;

        require(initial_stake > 0);
        require(user_stake.resolved == false);

        user_stake.amount = 0;
        user_stake.resolved = true;
        user_stake.successful = false;

        assert(token.destroyRoto(_user, _tournamentID));
        tournament.stakesResolved = tournament.stakesResolved.add(1);

        emit StakeDestroyed(_tournamentID, _user, initial_stake);

        return true;
    }

     
    function stake(uint256 _value, bytes32 _tournamentID) external stopInEmergency returns(bool successful) {
        return _stake(msg.sender, _tournamentID, _value);
    }

     
    function _stake(address _staker, bytes32 _tournamentID, uint256 _value) internal returns(bool successful) {
        Tournament storage tournament = tournaments[_tournamentID];

         
        require((tournament.open==true));
        require(tournament.etherPrize>0);
        
        Stake storage user_stake = tournament.stakes[_staker][_tournamentID];
        
        require(user_stake.amount==0);  
        require(_value>0);  
        require(_staker != roto && _staker != owner);  
        
         
        assert(token.canStake(_staker, _value));

        user_stake.amount = _value;
        assert(token.stakeRoto(_staker,_tournamentID,_value));

         
        tournament.userStakes = tournament.userStakes.add(1);

        emit StakeProcessed(_staker, user_stake.amount, _tournamentID);

        return true;
    }

     
    function createTournament(bytes32 _tournamentID, uint256 _etherPrize, uint256 _rotoPrize) external payable onlyOwner returns(bool successful) {
        Tournament storage newTournament = tournaments[_tournamentID];
        require(newTournament.creationTime==0);
        
        newTournament.open = true;
        newTournament.etherPrize = _etherPrize;
        newTournament.etherLeft = _etherPrize;

        newTournament.rotoPrize = _rotoPrize;
        newTournament.rotoLeft = _rotoPrize;
        newTournament.creationTime = block.timestamp;

        emit TournamentCreated(_tournamentID, _etherPrize, _rotoPrize);

        return true;
    }

     
    function closeTournament(bytes32 _tournamentID) external onlyOwner returns(bool successful) {
       Tournament storage tournament = tournaments[_tournamentID];
       
       require(tournament.open==true);

        
       require(tournament.rotoLeft == 0 && tournament.etherLeft == 0);
       
       require(tournament.userStakes == tournament.stakesResolved);
       tournament.open = false;

       emit TournamentClosed(_tournamentID);
       return true;
    }
}