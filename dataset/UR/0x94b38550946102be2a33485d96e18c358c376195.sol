 

 
 
pragma solidity ^0.4.21;


 

library SafeMath {

    function mul(uint a, uint b) internal constant returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal constant returns(uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal constant returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal constant returns(uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

 

contract ERC20 {
    uint public totalSupply = 0;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    function balanceOf(address _owner) constant returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}


 
contract HumanToken is ERC20 {
    using SafeMath for uint;
    string public name = "Human";
    string public symbol = "Human";
    uint public decimals = 18;
    uint public voteCost = 10**18;

     
    address public owner;
    address public eventManager;

    mapping (address => bool) isActiveEvent;
            
     
    event EventAdded(address _event);
    event Contribute(address _event, address _contributor, uint _amount);
    event Vote(address _event, address _contributor, bool _proposal);
    
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyEventManager {
        require(msg.sender == eventManager);
        _;
    }

    
    modifier onlyActive(address _event) {
        require(isActiveEvent[_event]);
        _;
    }


    
    function HumanToken(address _owner, address _eventManager) public {
       owner = _owner;
       eventManager = _eventManager;
    }


       
    function  addEvent(address _event) external onlyEventManager {
        require (!isActiveEvent[_event]);
        isActiveEvent[_event] = true;
        EventAdded(_event);
    }

    
    function setVoteCost(uint _voteCost) external onlyEventManager {
        voteCost = _voteCost;
    }
    
    
    function donate(address _event, uint _amount) public onlyActive(_event) {
        require (transfer(_event, _amount));
        require (HumanEvent(_event).contribute(msg.sender, _amount));
        Contribute(_event, msg.sender, _amount);
        
    }

    
    function vote(address _event, bool _proposal) public onlyActive(_event) {
        require(transfer(_event, voteCost));
        require(HumanEvent(_event).vote(msg.sender, _proposal));
        Vote(_event, msg.sender, _proposal);
    }
    
    


    
    function mintTokens(address _holder, uint _value) external onlyOwner {
       require(_value > 0);
       balances[_holder] = balances[_holder].add(_value);
       totalSupply = totalSupply.add(_value);
       Transfer(0x0, _holder, _value);
    }

  
    
    function balanceOf(address _holder) constant returns (uint) {
         return balances[_holder];
    }

    
    function transfer(address _to, uint _amount) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }


    
    function approve(address _spender, uint _amount) public returns (bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    
    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }

     
    function transferAnyTokens(address tokenAddress, uint tokens) 
        public
        onlyOwner 
        returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
}

 contract HumanEvent {
    using SafeMath for uint;    
    uint public totalRaised;
    uint public softCap;
    uint public positiveVotes;
    uint public negativeVotes;

    address public alternative;
    address public owner;
    HumanToken public human;

    mapping (address => uint) public contributions;
    mapping (address => bool) public voted;
    mapping (address => bool) public claimed;
    


     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyHuman {
        require(msg.sender == address(human));
        _;
    }


     
    enum StatusEvent {
        Created,
        Fundraising,
        Failed,
        Evaluating,
        Voting,
        Finished
    }
    StatusEvent public statusEvent = StatusEvent.Created;

    
    function HumanEvent(
        address _owner, 
        uint _softCap,
        address _alternative,
        address _human
    ) public {
        owner = _owner;
        softCap = _softCap;
        alternative = _alternative;
        human = HumanToken(_human);
    }

    function startFundraising() public onlyOwner {
        require(statusEvent == StatusEvent.Created);
        statusEvent = StatusEvent.Fundraising;
        
    }
    

    function startEvaluating() public onlyOwner {
        require(statusEvent == StatusEvent.Fundraising);
        
        if (totalRaised >= softCap) {
            statusEvent = StatusEvent.Evaluating;
        } else {
            statusEvent = StatusEvent.Failed;
        }
    }

    function startVoting() public onlyOwner {
        require(statusEvent == StatusEvent.Evaluating);
        statusEvent = StatusEvent.Voting;
    }

    function finish() public onlyOwner {
        require(statusEvent == StatusEvent.Voting);
        if (positiveVotes >= negativeVotes) {
            statusEvent = StatusEvent.Finished;
        } else {
            statusEvent = StatusEvent.Failed;
        }
    }
    
    
    function claim() public {
        require(!claimed[msg.sender]);        
        claimed[msg.sender] = true;
        uint contribution;

        if (statusEvent == StatusEvent.Failed) {
            contribution = contribution.add(contributions[msg.sender]);
            contributions[msg.sender] = 0;
        }

        if(voted[msg.sender] && statusEvent != StatusEvent.Voting) {
            uint _voteCost = human.voteCost();
            contribution = contribution.add(_voteCost);
        }
        require(contribution > 0);
        require(human.transfer(msg.sender, contribution));
    }

    
    function vote(address _voter, bool _proposal) external onlyHuman returns (bool) {
        require(!voted[_voter] && statusEvent == StatusEvent.Voting);
        voted[_voter] = true;
        
        if (_proposal) {
            positiveVotes++;
        } else {
            negativeVotes++;
        }
        return true;
    }


    function contribute(address _contributor, uint _amount) external onlyHuman returns(bool) {
        require (statusEvent == StatusEvent.Fundraising);
        contributions[_contributor] =  contributions[_contributor].add(_amount);
        totalRaised = totalRaised.add(_amount);
        return true;
    }
    
    function  withdraw() external onlyOwner {
        require (statusEvent == StatusEvent.Finished);
        require (human.transfer(alternative, totalRaised));
    }

}