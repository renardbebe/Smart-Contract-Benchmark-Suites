 

pragma solidity ^0.4.8;

contract SafeMath {

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }

    function safeAddCheck(uint256 x, uint256 y) internal returns(bool) {
      uint256 z = x + y;
      if ((z >= x) && (z >= y)) {
          return true;
      }
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract LeeroyPoints is Token, SafeMath {
    address public owner;
    mapping (address => bool) public controllers;

    string public constant name = "Leeroy Points";
    string public constant symbol = "LRP";
    uint256 public constant decimals = 18;
    string public version = "1.0";
    uint256 public constant baseUnit = 1 * 10**decimals;

    event CreateLRP(address indexed _to, uint256 _value);

    function LeeroyPoints() {
        owner = msg.sender;
    }

    modifier onlyOwner { if (msg.sender != owner) throw; _; }

    modifier onlyController { if (controllers[msg.sender] == false) throw; _; }

    function enableController(address controller) onlyOwner {
        controllers[controller] = true;
    }

    function disableController(address controller) onlyOwner {
        controllers[controller] = false;
    }

    function create(uint num, address targetAddress) onlyController {
        uint points = safeMult(num, baseUnit);
         
         
        bool checked = safeAddCheck(totalSupply, points);
        if (checked) {
            totalSupply = totalSupply + points;
            balances[targetAddress] += points;
            CreateLRP(targetAddress, points);
        }
   }

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract Leeroy {

     
    string public constant name = "Leeroy";

     
    LeeroyPoints public points;

     
    uint pointsPerAction = 1;

     
    event NewUser(bytes32 indexed username);
    event NewPost(bytes32 indexed username, uint id);
    event Reply(bytes32 indexed username, bytes32 indexed target, uint indexed id);
    event Follow(bytes32 indexed username, bytes32 indexed target, bool follow);
    event Like(bytes32 indexed username, bytes32 indexed target, uint indexed id);
    event Repost(bytes32 indexed username, bytes32 indexed target, uint indexed id);
    event ChangeFeed(bytes32 indexed username, uint indexed id);

    function Leeroy(address pointsAddress) {
        points = LeeroyPoints(pointsAddress);
    }

     
    struct User {
        bytes32 username;
        address owner;
        bytes32 detailsHash;
        uint joined;
        uint blockNumber;
        mapping(bytes32 => bool) following;
    }

    mapping (bytes32 => User) public usernames;  
    mapping (address => bytes32) public addresses;  

     
    struct Post {
        bytes32 username;
        bytes32 postHash;
        uint timestamp;
        uint blockNumber;
        uint id;
        mapping(bytes32 => bool) likes;
        mapping(bytes32 => bool) reposts;
        uint repostOf;
        uint inReplyTo;
    }

    Post[] public posts;

    function registerUsername(bytes32 username) {
        var senderUsername = addresses[msg.sender];
        var user = usernames[senderUsername];
        if (usernames[username].owner != 0) throw;  
        if (user.owner != 0) throw;  
        if (!isLowercase(username)) throw;  
        var newUser = User({
            username: username,
            owner: msg.sender,
            detailsHash: "",
            joined: block.timestamp,
            blockNumber: block.number,
        });
        usernames[username] = newUser;
        addresses[msg.sender] = username;
        NewUser(username);
        points.create(pointsPerAction, msg.sender);
    }

    function updateUserDetails(bytes32 detailsHash) {
        var senderUsername = addresses[msg.sender];  
        var user = usernames[senderUsername];  
        if (user.owner == 0) throw;  
        user.detailsHash = detailsHash;
    }

    function follow(bytes32 username) {
        var senderUsername = addresses[msg.sender];
        var user = usernames[senderUsername];
        var target = usernames[username];
        var following = user.following[target.username];
        if (user.owner == 0) throw;  
        if (target.owner == 0) throw;  
        if (user.username == target.username) throw;  
        if (following == true) throw;  
        user.following[target.username] = true;
        Follow(user.username, target.username, true);
    }

    function unfollow(bytes32 username) {
        var senderUsername = addresses[msg.sender];
        var user = usernames[senderUsername];
        var target = usernames[username];
        var following = user.following[target.username];
        if (user.owner == 0) throw;  
        if (target.owner == 0) throw;  
        if (user.username == target.username) throw;  
        if (following == false) throw;  
        user.following[target.username] = false;
        Follow(user.username, target.username, false);
    }

    function post(bytes32 postHash) {
        var senderUsername = addresses[msg.sender];
        var user = usernames[senderUsername];
        if (user.owner == 0) throw;  
         
        var id = posts.length + 1;
        posts.push(Post({
            username: user.username,
            postHash: postHash,
            timestamp: block.timestamp,
            blockNumber: block.number,
            id: id,
            repostOf: 0,
            inReplyTo: 0,
        }));
        NewPost(user.username, id);
        points.create(pointsPerAction, user.owner);
    }

    function reply(bytes32 postHash, uint id) {
        var senderUsername = addresses[msg.sender];
        var user = usernames[senderUsername];
        uint index = id - 1;
        var post = posts[index];
        if (user.owner == 0) throw;  
        if (post.id == 0) throw;  
        var postId = posts.length + 1;
        posts.push(Post({
            username: user.username,
            postHash: postHash,
            timestamp: block.timestamp,
            blockNumber: block.number,
            id: postId,
            repostOf: 0,
            inReplyTo: post.id,
        }));
        Reply(user.username, post.username, post.id);
        ChangeFeed(post.username, post.id);
        NewPost(user.username, postId);
        if (user.username != post.username) {
             
            points.create(pointsPerAction, usernames[post.username].owner);
            points.create(pointsPerAction, user.owner);
        }
    }

    function repost(uint id) {
        var senderUsername = addresses[msg.sender];
        var user = usernames[senderUsername];
        uint index = id - 1;
        var post = posts[index];
        var reposted = post.reposts[user.username];
        if (user.owner == 0) throw;  
        if (post.id == 0) throw;  
        if (reposted == true) throw;  
        post.reposts[user.username] = true;
        var postId = posts.length + 1;
        posts.push(Post({
            username: user.username,
            postHash: "",
            timestamp: block.timestamp,
            blockNumber: block.number,
            id: postId,
            repostOf: post.id,
            inReplyTo: 0,
        }));
        Repost(user.username, post.username, post.id);
        ChangeFeed(post.username, post.id);
        NewPost(user.username, postId);
        if (user.username != post.username) {
            points.create(pointsPerAction, usernames[post.username].owner);
            points.create(pointsPerAction, user.owner);
        }
    }

    function like(uint id) {
        var senderUsername = addresses[msg.sender];
        var user = usernames[senderUsername];
        uint index = id - 1;
        var post = posts[index];
        var liked = post.likes[user.username];
        if (user.owner == 0) throw;  
        if (post.id == 0) throw;  
        if (liked == true) throw;  
        post.likes[user.username] = true;
        Like(user.username, post.username, post.id);
        ChangeFeed(post.username, post.id);
        if (user.username != post.username) {
            points.create(pointsPerAction, usernames[post.username].owner);
            points.create(pointsPerAction, user.owner);
        }
    }

    function isLowercase(bytes32 self) internal constant returns (bool) {
        for (uint i = 0; i < 32; i++) {
            byte char = byte(bytes32(uint(self) * 2 ** (8 * i)));
            if (char >= 0x41 && char <= 0x5A) {
                return false;
            }
        }
        return true;
    }

    function getUserBlockNumber(bytes32 username) constant returns (uint) {
        return usernames[username].blockNumber;
    }

}