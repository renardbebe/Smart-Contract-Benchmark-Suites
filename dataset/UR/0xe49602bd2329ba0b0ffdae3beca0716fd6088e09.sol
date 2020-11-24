 

pragma solidity ^0.4.4;

 
contract ProjectKudos {

     
    uint KUDOS_LIMIT_JUDGE = 1000;

     
    uint KUDOS_LIMIT_USER  = 10;

     
    uint SOCIAL_PROOF_KUDOS = 100;

     
    uint GRANT_REASON_FACEBOOK = 0;
    uint GRANT_REASON_TWITTER = 1;

     
    struct ProjectInfo {
        mapping(address => uint) kudosByUser;
        uint kudosTotal;
    }

     
    struct UserInfo {
        uint kudosLimit;
        uint kudosGiven;
        bool isJudge;
        mapping(uint => bool) grant;
    }

     
     
    struct UserIndex {
        bytes32[] projects;
        uint[] kudos;
        mapping(bytes32 => uint) kudosIdx;
    }

     
    struct VotePeriod {
        uint start;
        uint end;
    }

     
    address owner;

     
    VotePeriod votePeriod;

     
    mapping(address => UserInfo) users;

     
     
    mapping(address => UserIndex) usersIndex;

     
    mapping(bytes32 => ProjectInfo) projects;

     
    event Vote(
         
        address indexed voter,
         
        bytes32 indexed projectCode,
         
        uint indexed count
    );

     
    function ProjectKudos() {

        owner = msg.sender;

        votePeriod = VotePeriod(
            1479996000,      
            1482415200       
        );
    }

     
    function register(address userAddress, bool isJudge) onlyOwner {

        UserInfo user = users[userAddress];

        if (user.kudosLimit > 0) throw;

        if (isJudge)
            user.kudosLimit = KUDOS_LIMIT_JUDGE;
        else
            user.kudosLimit = KUDOS_LIMIT_USER;

        user.isJudge = isJudge;

        users[userAddress] = user;
    }

     
    function giveKudos(bytes32 projectCode, uint kudos) {

         
        if (now < votePeriod.start) throw;
        if (now >= votePeriod.end) throw;        
        
        UserInfo giver = users[msg.sender];

        if (giver.kudosGiven + kudos > giver.kudosLimit) throw;

        ProjectInfo project = projects[projectCode];

        giver.kudosGiven += kudos;
        project.kudosTotal += kudos;
        project.kudosByUser[msg.sender] += kudos;

         
        updateUsersIndex(projectCode, project.kudosByUser[msg.sender]);

        Vote(msg.sender, projectCode, kudos);
    }

              
    function grantKudos(address userToGrant, uint reason) onlyOwner {

        UserInfo user = users[userToGrant];

        if (user.kudosLimit == 0) throw;  

        if (reason != GRANT_REASON_FACEBOOK &&         
            reason != GRANT_REASON_TWITTER) throw;     

         
         
         
        if (user.isJudge) throw;

         
        if (user.grant[reason]) throw;

         
        user.kudosLimit += SOCIAL_PROOF_KUDOS;
        
        user.grant[reason] = true;
    }


     
     
     

     
    function getProjectKudos(bytes32 projectCode) constant returns(uint) {
        ProjectInfo project = projects[projectCode];
        return project.kudosTotal;
    }

     
    function getProjectKudosByUsers(bytes32 projectCode, address[] users) constant returns(uint[]) {
        ProjectInfo project = projects[projectCode];
        mapping(address => uint) kudosByUser = project.kudosByUser;
        uint[] memory userKudos = new uint[](users.length);
        for (uint i = 0; i < users.length; i++) {
            userKudos[i] = kudosByUser[users[i]];
       }

       return userKudos;
    }

     
    function getKudosPerProject(address giver) constant returns (bytes32[] projects, uint[] kudos) {
        UserIndex idx = usersIndex[giver];
        projects = idx.projects;
        kudos = idx.kudos;
    }

     
    function getKudosLeft(address addr) constant returns(uint) {
        UserInfo user = users[addr];
        return user.kudosLimit - user.kudosGiven;
    }

     
    function getKudosGiven(address addr) constant returns(uint) {
        UserInfo user = users[addr];
        return user.kudosGiven;
    }


     
     
     

     
    function updateUsersIndex(bytes32 code, uint kudos) private {

        UserIndex idx = usersIndex[msg.sender];
        uint i = idx.kudosIdx[code];

         
        if (i == 0) {
            i = idx.projects.length + 1;
            idx.projects.length += 1;
            idx.kudos.length += 1;
            idx.projects[i - 1] = code;
            idx.kudosIdx[code] = i;
        }

        idx.kudos[i - 1] = kudos;
    }


     
     
     

     
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }
}