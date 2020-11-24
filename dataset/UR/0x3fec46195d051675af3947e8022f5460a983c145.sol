 

pragma solidity ^0.5.11;

contract TeamManage {    
    address public  owner;
    mapping (address => bool) public  status;  
    mapping (address => address) public  referee;  
    mapping (address => mapping (uint256 => address)) public  teamMembers;  
    mapping (address => uint256) public  teamMembersNumber;  
    uint256 public numbers;  

     
    constructor () public {  
        owner = msg.sender;
        referee[owner] = address(0x0);
        status[owner] = true;
        numbers = 1;
    }

     
    function addReferee(address _add) public returns (bool success) {
        require (_add != address(0x0) && status[_add] == true && status[msg.sender] == false) ;
        referee[msg.sender] = _add ;
        status[msg.sender] = true;
        teamMembers[_add][teamMembersNumber[_add]] = msg.sender;
        teamMembersNumber[_add] = teamMembersNumber[_add] + 1;
        numbers = numbers + 1;
        return true;
    }


     
    function changeOwner(address payable _add) public returns (bool success) {
        require (msg.sender == owner) ;
        require (_add != address(0x0)) ;
        owner = _add ;
        return true;
    }

     
    function queryTeamMembers(uint256 _start,address _add) public view returns (address[1000] memory _address) {
        for (uint i = _start; i < _start + 1000 && i < teamMembersNumber[_add]; i++) {
            _address[i - _start] = teamMembers[_add][i];
        }
        return  _address;
    }
}