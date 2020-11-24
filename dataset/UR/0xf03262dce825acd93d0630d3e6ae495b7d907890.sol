 

pragma solidity ^0.4.8;

 

 

 
contract PassDao {
    
    struct revision {
         
        address committeeRoom;
         
        address shareManager;
         
        address tokenManager;
         
        uint startDate;
    }
     
    revision[] public revisions;

    struct project {
         
        address contractAddress;
         
        uint startDate;
    }
     
    project[] public projects;

     
    mapping (address => uint) projectID;
    
     
    address metaProject;

    
 

    event Upgrade(uint indexed RevisionID, address CommitteeRoom, address ShareManager, address TokenManager);
    event NewProject(address Project);

 
    
     
    function ActualCommitteeRoom() constant returns (address) {
        return revisions[0].committeeRoom;
    }
    
     
    function MetaProject() constant returns (address) {
        return metaProject;
    }

     
    function ActualShareManager() constant returns (address) {
        return revisions[0].shareManager;
    }

     
    function ActualTokenManager() constant returns (address) {
        return revisions[0].tokenManager;
    }

 

    modifier onlyPassCommitteeRoom {if (msg.sender != revisions[0].committeeRoom  
        && revisions[0].committeeRoom != 0) throw; _;}
    
 

    function PassDao() {
        projects.length = 1;
        revisions.length = 1;
    }
    
 

     
     
     
     
     
    function upgrade(
        address _newCommitteeRoom, 
        address _newShareManager, 
        address _newTokenManager) onlyPassCommitteeRoom returns (uint) {
        
        uint _revisionID = revisions.length++;
        revision r = revisions[_revisionID];

        if (_newCommitteeRoom != 0) r.committeeRoom = _newCommitteeRoom; else r.committeeRoom = revisions[0].committeeRoom;
        if (_newShareManager != 0) r.shareManager = _newShareManager; else r.shareManager = revisions[0].shareManager;
        if (_newTokenManager != 0) r.tokenManager = _newTokenManager; else r.tokenManager = revisions[0].tokenManager;

        r.startDate = now;
        
        revisions[0] = r;
        
        Upgrade(_revisionID, _newCommitteeRoom, _newShareManager, _newTokenManager);
            
        return _revisionID;
    }

     
     
    function addMetaProject(address _projectAddress) onlyPassCommitteeRoom {

        metaProject = _projectAddress;
    }
    
     
     
    function addProject(address _projectAddress) onlyPassCommitteeRoom {

        if (projectID[_projectAddress] == 0) {

            uint _projectID = projects.length++;
            project p = projects[_projectID];
        
            projectID[_projectAddress] = _projectID;
            p.contractAddress = _projectAddress; 
            p.startDate = now;
            
            NewProject(_projectAddress);
        }
    }
    
}

pragma solidity ^0.4.8;

 

 
contract PassProject {

     
    PassDao public passDao;
    
     
    string public name;
     
    string public description;
     
    bytes32 public hashOfTheDocument;
     
    address projectManager;

    struct order {
         
        address contractorAddress;
         
        uint contractorProposalID;
         
        uint amount;
         
        uint orderDate;
    }
     
    order[] public orders;
    
     
    uint public totalAmountOfOrders;

    struct resolution {
         
        string name;
         
        string description;
         
        uint creationDate;
    }
     
    resolution[] public resolutions;
    
 

    event OrderAdded(address indexed Client, address indexed ContractorAddress, uint indexed ContractorProposalID, uint Amount, uint OrderDate);
    event ProjectDescriptionUpdated(address indexed By, string NewDescription, bytes32 NewHashOfTheDocument);
    event ResolutionAdded(address indexed Client, uint indexed ResolutionID, string Name, string Description);

 

     
    function Client() constant returns (address) {
        return passDao.ActualCommitteeRoom();
    }
    
     
    function numberOfOrders() constant returns (uint) {
        return orders.length - 1;
    }
    
     
    function ProjectManager() constant returns (address) {
        return projectManager;
    }

     
    function numberOfResolutions() constant returns (uint) {
        return resolutions.length - 1;
    }
    
 

     
    modifier onlyProjectManager {if (msg.sender != projectManager) throw; _;}

     
    modifier onlyClient {if (msg.sender != Client()) throw; _;}

 

    function PassProject(
        PassDao _passDao, 
        string _name,
        string _description,
        bytes32 _hashOfTheDocument) {

        passDao = _passDao;
        name = _name;
        description = _description;
        hashOfTheDocument = _hashOfTheDocument;
        
        orders.length = 1;
        resolutions.length = 1;
    }
    
 

     
     
     
     
     
    function addOrder(

        address _contractorAddress, 
        uint _contractorProposalID, 
        uint _amount, 
        uint _orderDate) internal {

        uint _orderID = orders.length++;
        order d = orders[_orderID];
        d.contractorAddress = _contractorAddress;
        d.contractorProposalID = _contractorProposalID;
        d.amount = _amount;
        d.orderDate = _orderDate;
        
        totalAmountOfOrders += _amount;
        
        OrderAdded(msg.sender, _contractorAddress, _contractorProposalID, _amount, _orderDate);
    }
    
 

     
     
     
     
     
    function cloneOrder(
        address _contractorAddress, 
        uint _contractorProposalID, 
        uint _orderAmount, 
        uint _lastOrderDate) {
        
        if (projectManager != 0) throw;
        
        addOrder(_contractorAddress, _contractorProposalID, _orderAmount, _lastOrderDate);
    }
    
     
     
     
    function setProjectManager(address _projectManager) returns (bool) {

        if (_projectManager == 0 || projectManager != 0) return;
        
        projectManager = _projectManager;
        
        return true;
    }

 

     
     
     
    function updateDescription(string _projectDescription, bytes32 _hashOfTheDocument) onlyProjectManager {
        description = _projectDescription;
        hashOfTheDocument = _hashOfTheDocument;
        ProjectDescriptionUpdated(msg.sender, _projectDescription, _hashOfTheDocument);
    }

 

     
     
     
     
    function newOrder(
        address _contractorAddress, 
        uint _contractorProposalID, 
        uint _amount) onlyClient {
            
        addOrder(_contractorAddress, _contractorProposalID, _amount, now);
    }
    
     
     
     
    function newResolution(
        string _name, 
        string _description) onlyClient {

        uint _resolutionID = resolutions.length++;
        resolution d = resolutions[_resolutionID];
        
        d.name = _name;
        d.description = _description;
        d.creationDate = now;

        ResolutionAdded(msg.sender, _resolutionID, d.name, d.description);
    }
}

contract PassProjectCreator {
    
    event NewPassProject(PassDao indexed Dao, PassProject indexed Project, string Name, string Description, bytes32 HashOfTheDocument);

     
     
     
     
     
    function createProject(
        PassDao _passDao,
        string _name, 
        string _description, 
        bytes32 _hashOfTheDocument
        ) returns (PassProject) {

        PassProject _passProject = new PassProject(_passDao, _name, _description, _hashOfTheDocument);

        NewPassProject(_passDao, _passProject, _name, _description, _hashOfTheDocument);

        return _passProject;
    }
}
    

pragma solidity ^0.4.8;

 

 
contract PassContractor {
    
     
    PassProject passProject;
    
     
    address public creator;
     
    address public recipient;

     
    uint public smartContractStartDate;

    struct proposal {
         
        uint amount;
         
        string description;
         
        bytes32 hashOfTheDocument;
         
        uint dateOfProposal;
         
        uint submittedAmount;
         
        uint orderAmount;
         
        uint dateOfLastOrder;
    }
     
    proposal[] public proposals;

 

    event RecipientUpdated(address indexed By, address LastRecipient, address NewRecipient);
    event Withdrawal(address indexed By, address indexed Recipient, uint Amount);
    event ProposalAdded(address Creator, uint indexed ProposalID, uint Amount, string Description, bytes32 HashOfTheDocument);
    event ProposalSubmitted(address indexed Client, uint Amount);
    event Order(address indexed Client, uint indexed ProposalID, uint Amount);

 

     
    function Client() constant returns (address) {
        return passProject.Client();
    }

     
    function Project() constant returns (PassProject) {
        return passProject;
    }
    
     
     
     
     
     
    function proposalChecked(
        address _sender,
        uint _proposalID, 
        uint _amount) constant external onlyClient returns (bool) {
        if (_sender != recipient && _sender != creator) return;
        if (_amount <= proposals[_proposalID].amount - proposals[_proposalID].submittedAmount) return true;
    }

     
    function numberOfProposals() constant returns (uint) {
        return proposals.length - 1;
    }


 

     
    modifier onlyContractor {if (msg.sender != recipient) throw; _;}
    
     
    modifier onlyClient {if (msg.sender != Client()) throw; _;}

 

    function PassContractor(
        address _creator, 
        PassProject _passProject, 
        address _recipient,
        bool _restore) { 

        if (address(_passProject) == 0) throw;
        
        creator = _creator;
        if (_recipient == 0) _recipient = _creator;
        recipient = _recipient;
        
        passProject = _passProject;
        
        if (!_restore) smartContractStartDate = now;

        proposals.length = 1;
    }

 

     
     
     
     
     
     
     
     
     
    function cloneProposal(
        uint _amount,
        string _description,
        bytes32 _hashOfTheDocument,
        uint _dateOfProposal,
        uint _orderAmount,
        uint _dateOfOrder,
        bool _cloneOrder
    ) returns (bool success) {
            
        if (smartContractStartDate != 0 || recipient == 0
        || msg.sender != creator) throw;
        
        uint _proposalID = proposals.length++;
        proposal c = proposals[_proposalID];

        c.amount = _amount;
        c.description = _description;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.dateOfProposal = _dateOfProposal;
        c.orderAmount = _orderAmount;
        c.dateOfLastOrder = _dateOfOrder;

        ProposalAdded(msg.sender, _proposalID, _amount, _description, _hashOfTheDocument);
        
        if (_cloneOrder) passProject.cloneOrder(address(this), _proposalID, _orderAmount, _dateOfOrder);
        
        return true;
    }

     
     
    function closeSetup() returns (bool) {
        
        if (smartContractStartDate != 0 
            || (msg.sender != creator && msg.sender != Client())) return;

        smartContractStartDate = now;

        return true;
    }
    
 

     
     
    function updateRecipient(address _newRecipient) onlyContractor {

        if (_newRecipient == 0) throw;

        RecipientUpdated(msg.sender, recipient, _newRecipient);
        recipient = _newRecipient;
    } 

     
    function () payable { }
    
     
     
    function withdraw(uint _amount) onlyContractor {
        if (!recipient.send(_amount)) throw;
        Withdrawal(msg.sender, recipient, _amount);
    }
    
 

     
     
     
    function updateProjectDescription(string _projectDescription, bytes32 _hashOfTheDocument) onlyContractor {
        passProject.updateDescription(_projectDescription, _hashOfTheDocument);
    }
    
 

     
     
     
     
     
     
    function newProposal(
        address _creator,
        uint _amount,
        string _description, 
        bytes32 _hashOfTheDocument
    ) external returns (uint) {
        
        if (msg.sender == Client() && _creator != recipient && _creator != creator) throw;
        if (msg.sender != Client() && msg.sender != recipient && msg.sender != creator) throw;

        if (_amount == 0) throw;
        
        uint _proposalID = proposals.length++;
        proposal c = proposals[_proposalID];

        c.amount = _amount;
        c.description = _description;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.dateOfProposal = now;
        
        ProposalAdded(msg.sender, _proposalID, c.amount, c.description, c.hashOfTheDocument);
        
        return _proposalID;
    }
    
     
     
     
     
    function submitProposal(
        address _sender, 
        uint _proposalID, 
        uint _amount) onlyClient {

        if (_sender != recipient && _sender != creator) throw;    
        proposals[_proposalID].submittedAmount += _amount;
        ProposalSubmitted(msg.sender, _amount);
    }

     
     
     
     
    function order(
        uint _proposalID,
        uint _orderAmount
    ) external onlyClient returns (bool) {
    
        proposal c = proposals[_proposalID];
        
        uint _sum = c.orderAmount + _orderAmount;
        if (_sum > c.amount
            || _sum < c.orderAmount
            || _sum < _orderAmount) return; 

        c.orderAmount = _sum;
        c.dateOfLastOrder = now;
        
        Order(msg.sender, _proposalID, _orderAmount);
        
        return true;
    }
    
}

contract PassContractorCreator {
    
     
    PassDao public passDao;
     
    PassProjectCreator public projectCreator;
    
    struct contractor {
         
        address creator;
         
        PassContractor contractor;
         
        address recipient;
         
        bool metaProject;
         
        PassProject passProject;
         
        string projectName;
         
        string projectDescription;
         
        uint creationDate;
    }
     
    contractor[] public contractors;
    
    event NewPassContractor(address indexed Creator, address indexed Recipient, PassProject indexed Project, PassContractor Contractor);

    function PassContractorCreator(PassDao _passDao, PassProjectCreator _projectCreator) {
        passDao = _passDao;
        projectCreator = _projectCreator;
        contractors.length = 0;
    }

     
    function numberOfContractors() constant returns (uint) {
        return contractors.length;
    }
    
     
     
     
     
     
     
     
     
     
    function createContractor(
        address _creator,
        address _recipient, 
        bool _metaProject,
        PassProject _passProject,
        string _projectName, 
        string _projectDescription,
        bool _restore) returns (PassContractor) {
 
        PassProject _project;

        if (_creator == 0) _creator = msg.sender;
        
        if (_metaProject) _project = PassProject(passDao.MetaProject());
        else if (address(_passProject) == 0) 
            _project = projectCreator.createProject(passDao, _projectName, _projectDescription, 0);
        else _project = _passProject;

        PassContractor _contractor = new PassContractor(_creator, _project, _recipient, _restore);
        if (!_metaProject && address(_passProject) == 0 && !_restore) _project.setProjectManager(address(_contractor));
        
        uint _contractorID = contractors.length++;
        contractor c = contractors[_contractorID];
        c.creator = _creator;
        c.contractor = _contractor;
        c.recipient = _recipient;
        c.metaProject = _metaProject;
        c.passProject = _passProject;
        c.projectName = _projectName;
        c.projectDescription = _projectDescription;
        c.creationDate = now;

        NewPassContractor(_creator, _recipient, _project, _contractor);
 
        return _contractor;
    }
    
}