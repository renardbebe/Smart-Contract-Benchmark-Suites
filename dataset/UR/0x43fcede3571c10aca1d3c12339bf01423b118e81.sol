 

pragma solidity 0.5.1;

contract HumanityDAO {
    function isHuman(address who) public view returns (bool) {}
}

contract FundingVote {
    
    uint256 public yes;
    uint256 public no;
    
    HumanityDAO dao;
    
    mapping (address => bool) public voted;
    
    constructor() public {
        dao = HumanityDAO(0x4EE46dc4962C2c2F6bcd4C098a0E2b28f66A5E90);
    }
    
    function voteYes() public onlyHuman notVoted {
        yes = yes + 1;
        voted[msg.sender] = true;
    }
    
    function voteNo() public onlyHuman notVoted {
        no = no + 1;
        voted[msg.sender] = true;
    }
    
    modifier onlyHuman() {
        require(dao.isHuman(msg.sender), "Only callable by a human!");
        _;
    }
    
    modifier notVoted() {
        require(!voted[msg.sender], "Must not have voted");
        _;
    }
}