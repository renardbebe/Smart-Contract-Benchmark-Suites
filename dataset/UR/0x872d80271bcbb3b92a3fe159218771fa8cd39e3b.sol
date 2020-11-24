 

pragma solidity ^0.4.21;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 
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


contract Job {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    event MilestoneCreated(uint16 id, uint16 parent, string title);
    event ProposalCreated(uint16 id, uint16 milestone, address contractor, uint256 amount);

    ERC20 public token;
    string public title; 
    string public description; 
    address public escrowAdmin;
    address public customer;
    
    struct Proposal {
        address contractor;              
        uint256 amount;                  
        string description;              
    }
    struct Milestone {
        uint16 parent;                   
        string title;                    
        string description;              
        uint64 deadline;                 
        Proposal[] proposals;            
        int16 acceptedProposal;          
        bool done;                       
        bool approved;                   
        bool customerApproved;           
        bool requiresCustomerApproval;   
        uint256 paid;                    
        uint256 allowance;               
    }
    Milestone[] public milestones;       

    modifier onlyCustomer(){
        require(msg.sender == customer);
        _;
    }

    constructor(ERC20 _token, string _title, string _description, address _escrowAdmin) public {
        token = _token;
        customer = msg.sender;
        title = _title;
        description = _description;
        escrowAdmin = _escrowAdmin;

        pushMilestone(0, "", "", 0, false);
    }

    function addGeneralMilestone(string _title, string _description, uint64 _deadline) onlyCustomer external{
        require(_deadline > now);
        pushMilestone(0, _title, _description, _deadline, false);
    }
    function addSubMilestone(uint16 _parent, string _title, string _description, uint64 _deadline, bool _requiresCustomerApproval) external {
        require(_parent > 0 && _parent < milestones.length);
        Milestone storage parent = milestones[_parent];
        require(parent.acceptedProposal >= 0);
        address generalContractor = parent.proposals[uint16(parent.acceptedProposal)].contractor;
        assert(generalContractor!= address(0));
        require(msg.sender == generalContractor);
        pushMilestone(_parent, _title, _description, _deadline, _requiresCustomerApproval);
    }

    function addProposal(uint16 milestone, uint256 _amount, string _description) external {
        require(milestone < milestones.length);
        require(_amount > 0);
        milestones[milestone].proposals.push(Proposal({
            contractor: msg.sender,
            amount: _amount,
            description: _description
        }));
        emit ProposalCreated( uint16(milestones[milestone].proposals.length-1), milestone, msg.sender, _amount);
    }

    function getProposal(uint16 milestone, uint16 proposal) view public returns(address contractor, uint256 amount, string description){
        require(milestone < milestones.length);
        Milestone storage m = milestones[milestone];
        require(proposal < m.proposals.length);
        Proposal storage p = m.proposals[proposal];
        return (p.contractor, p.amount, p.description);
    }
    function getProposalAmount(uint16 milestone, uint16 proposal) view public returns(uint256){
        require(milestone < milestones.length);
        Milestone storage m = milestones[milestone];
        require(proposal < m.proposals.length);
        Proposal storage p = m.proposals[proposal];
        return p.amount;
    }
    function getProposalContractor(uint16 milestone, uint16 proposal) view public returns(address){
        require(milestone < milestones.length);
        Milestone storage m = milestones[milestone];
        require(proposal < m.proposals.length);
        Proposal storage p = m.proposals[proposal];
        return p.contractor;
    }


    function confirmProposalAndTransferFunds(uint16 milestone, uint16 proposal) onlyCustomer external returns(bool){
        require(milestone < milestones.length);
        Milestone storage m = milestones[milestone];
        require(m.deadline > now);

        require(proposal < m.proposals.length);
        Proposal storage p = m.proposals[proposal];
        m.acceptedProposal = int16(proposal);

        require(token.transferFrom(customer, address(this), p.amount));
        return true;
    }
    function markDone(uint16 _milestone) external {
        require(_milestone < milestones.length);
        Milestone storage m = milestones[_milestone];
        assert(m.acceptedProposal >= 0);
        Proposal storage p = m.proposals[uint16(m.acceptedProposal)];        
        require(msg.sender == p.contractor);
        require(m.done == false);
        m.done = true;
    }
    function approveAndPayout(uint16 _milestone) onlyCustomer external{
        require(_milestone < milestones.length);
        Milestone storage m = milestones[_milestone];
        require(m.acceptedProposal >= 0);
         
        m.customerApproved = true;
        Proposal storage p = m.proposals[uint16(m.acceptedProposal)];

        m.paid = p.amount;
        require(token.transfer(p.contractor, p.amount));
    }   

    function balance() view public returns(uint256) {
        return token.balanceOf(address(this));
    }

    function pushMilestone(uint16 _parent, string _title, string _description, uint64 _deadline, bool _requiresCustomerApproval) private returns(uint16) {
        uint16 id = uint16(milestones.length++);
        milestones[id].parent = _parent;
        milestones[id].title = _title;
        milestones[id].description = _description;
        milestones[id].deadline = _deadline;
        milestones[id].acceptedProposal = -1;
        milestones[id].requiresCustomerApproval = _requiresCustomerApproval;
        emit MilestoneCreated(id, _parent, _title);
        return id;
    }

}