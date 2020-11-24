 

pragma solidity ^0.4.2;

contract Likedapp{

     

     

     
    struct Reactions{
        int8 action;
        string message;
    }

     
    struct User {
        uint id;
        uint userReactionCount;
        address user_address;
        string username;
        Reactions[] reactions;
    }

     
    User[] userStore;

     
     
    mapping(address => User) public users;
     
    uint public userCount;

     
    uint price = 0.00015 ether;

     
    address public iown;

     
    event UserCreated(uint indexed id);
    event SentReaction(address user_address);

     
    constructor() public{
        iown = msg.sender;
    }

    function addUser(string _username) public {

         
        require(bytes(_username).length > 1);

         
        require(users[msg.sender].id == 0);

        userCount++;
        userStore.length++;
        User storage u = userStore[userStore.length - 1];
        Reactions memory react = Reactions(0, "Welcome to LikeDapp! :D");
        u.reactions.push(react);
        u.id = userCount;
        u.user_address = msg.sender;
        u.username = _username;
        u.userReactionCount++;
        users[msg.sender] = u;

         
    }


    function getUserReaction(uint _i) external view returns (int8,string){
        require(_i >= 0);
        return (users[msg.sender].reactions[_i].action, users[msg.sender].reactions[_i].message);
    }

    function sendReaction(address _a, int8 _l, string _m) public payable {
         require(_l >= 1 && _l <= 5);
         require(users[_a].id > 0);

        if(bytes(_m).length >= 1){
            buyMessage();
        }

        users[_a].reactions.push(Reactions(_l, _m));
        users[_a].userReactionCount++;

         
    }

    function getUserCount() external view returns (uint){
        return userCount;
    }

    function getUsername() external view returns (string){
        return users[msg.sender].username;
    }

    function getUserReactionCount() external view returns (uint){
        return users[msg.sender].userReactionCount;
    }

     
    function buyMessage() public payable{
        require(msg.value >= price);
    }

    function withdraw() external{
        require(msg.sender == iown);
        iown.transfer(address(this).balance);
    }

    function withdrawAmount(uint amount) external{
        require(msg.sender == iown);
        iown.transfer(amount);
    }

     
    function checkAccount(address _a) external view returns (bool){
        if(users[_a].id == 0){
         return false;
       }
       else{
         return true;
       }
    }

    function amIin() external view returns (bool){
        if(users[msg.sender].id == 0){
            return false;
        }
        else{
            return true;
        }
    }

}