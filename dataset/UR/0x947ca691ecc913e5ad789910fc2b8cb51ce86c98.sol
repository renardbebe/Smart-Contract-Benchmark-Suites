 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


 
contract IcoStorage is Ownable {

    struct Project {
        bool isValue;  
        string name;  
        address tokenAddress;  
        bool active;     
    }

    mapping(address => Project) public projects;
    address[] public projectsAccts;

    function createProject(
        string _name,
        address _icoContractAddress,
        address _tokenAddress
    ) public onlyOwner returns (bool) {
        Project storage project  = projects[_icoContractAddress];  

        project.isValue = true;  
        project.name = _name;
        project.tokenAddress = _tokenAddress;
        project.active = true;

        projectsAccts.push(_icoContractAddress);

        return true;
    }

    function getProject(address _icoContractAddress) public view returns (string, address, bool) {
        require(projects[_icoContractAddress].isValue);

        return (
            projects[_icoContractAddress].name,
            projects[_icoContractAddress].tokenAddress,
            projects[_icoContractAddress].active
        );
    }

    function activateProject(address _icoContractAddress) public onlyOwner returns (bool) {
        Project storage project  = projects[_icoContractAddress];
        require(project.isValue);  

        project.active = true;

        return true;
    }

    function deactivateProject(address _icoContractAddress) public onlyOwner returns (bool) {
        Project storage project  = projects[_icoContractAddress];
        require(project.isValue);  

        project.active = false;

        return false;
    }

    function getProjects() public view returns (address[]) {
        return projectsAccts;
    }

    function countProjects() public view returns (uint256) {
        return projectsAccts.length;
    }
}