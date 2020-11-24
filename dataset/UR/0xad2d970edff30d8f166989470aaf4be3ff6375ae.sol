 

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