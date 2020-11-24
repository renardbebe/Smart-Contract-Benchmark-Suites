 

pragma solidity ^ 0.4.17;


 
contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}



 
 
contract WhiteList is Ownable {

    
    mapping(address => bool) public whiteList;
    uint public totalWhiteListed;  

    event LogWhiteListed(address indexed user, uint whiteListedNum);
    event LogWhiteListedMultiple(uint whiteListedNum);
    event LogRemoveWhiteListed(address indexed user);


     
     
    function isWhiteListed(address _user) public view returns (bool) {

        return whiteList[_user]; 
    }

     
     
    function removeFromWhiteList(address _user) onlyOwner() external returns (bool) {
       
        require(whiteList[_user] == true);
        whiteList[_user] = false;
        totalWhiteListed--;
        LogRemoveWhiteListed(_user);
        return true;
    }

     
     
     
    function addToWhiteList(address _user) onlyOwner() external returns (bool) {

        if (whiteList[_user] != true) {
            whiteList[_user] = true;
            totalWhiteListed++;
            LogWhiteListed(_user, totalWhiteListed);            
        }
        return true;
    }

     
     
     
    function addToWhiteListMultiple(address[] _users) onlyOwner() external returns (bool) {

         for (uint i = 0; i < _users.length; ++i) {

            if (whiteList[_users[i]] != true) {
                whiteList[_users[i]] = true;
                totalWhiteListed++;                          
            }           
        }
         LogWhiteListedMultiple(totalWhiteListed); 
         return true;
    }
}