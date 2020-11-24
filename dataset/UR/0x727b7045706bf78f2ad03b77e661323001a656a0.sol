 

pragma solidity ^0.4.23;

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
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

 

 
contract Contactable is Ownable{

    string public contactInformation;

     
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
     }
}

 

 
contract MonethaUsers is Contactable {

    using SafeMath for uint256;

    string constant VERSION = "0.1";

    struct User {
        string name;
        uint256 starScore;
        uint256 reputationScore;
        uint256 signedDealsCount;
        string nickname;
        bool isVerified;
    }

    mapping (address => User) public users;

    event UpdatedSignedDealsCount(address indexed _userAddress, uint256 _newSignedDealsCount);
    event UpdatedStarScore(address indexed _userAddress, uint256 _newStarScore);
    event UpdatedReputationScore(address indexed _userAddress, uint256 _newReputationScore);
    event UpdatedNickname(address indexed _userAddress, string _newNickname);
    event UpdatedIsVerified(address indexed _userAddress, bool _newIsVerified);
    event UpdatedName(address indexed _userAddress, string _newName);
    event UpdatedTrustScore(address indexed _userAddress, uint256 _newStarScore, uint256 _newReputationScore);
    event UserRegistered(address indexed _userAddress, string _name, uint256 _starScore, uint256 _reputationScore, uint256 _signedDealsCount, string _nickname, bool _isVerified);
    event UpdatedUserDetails(address indexed _userAddress, uint256 _newStarScore, uint256 _newReputationScore, uint256 _newSignedDealsCount, bool _newIsVerified);
    event UpdatedUser(address indexed _userAddress, string _name, uint256 _newStarScore, uint256 _newReputationScore, uint256 _newSignedDealsCount, string _newNickname, bool _newIsVerified);

     
    function registerUser(address _userAddress, string _name, uint256 _starScore, uint256 _reputationScore, uint256 _signedDealsCount, string _nickname, bool _isVerified)
        external onlyOwner
    {
        User storage user = users[_userAddress];

        user.name = _name;
        user.starScore = _starScore;
        user.reputationScore = _reputationScore;
        user.signedDealsCount = _signedDealsCount;
        user.nickname = _nickname;
        user.isVerified = _isVerified;

        emit UserRegistered(_userAddress, _name, _starScore, _reputationScore, _signedDealsCount, _nickname, _isVerified);
    }

     
    function updateStarScore(address _userAddress, uint256 _updatedStars)
        external onlyOwner
    {
        users[_userAddress].starScore = _updatedStars;

        emit UpdatedStarScore(_userAddress, _updatedStars);
    }

     
    function updateStarScoreInBulk(address[] _userAddresses, uint256[] _starScores)
        external onlyOwner
    {
        require(_userAddresses.length == _starScores.length);

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].starScore = _starScores[i];

            emit UpdatedStarScore(_userAddresses[i], _starScores[i]);
        }
    }

     
    function updateReputationScore(address _userAddress, uint256 _updatedReputation)
        external onlyOwner
    {
        users[_userAddress].reputationScore = _updatedReputation;

        emit UpdatedReputationScore(_userAddress, _updatedReputation);
    }

     
    function updateReputationScoreInBulk(address[] _userAddresses, uint256[] _reputationScores)
        external onlyOwner
    {
        require(_userAddresses.length == _reputationScores.length);

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].reputationScore = _reputationScores[i];

            emit UpdatedReputationScore(_userAddresses[i],  _reputationScores[i]);
        }
    }

     
    function updateTrustScore(address _userAddress, uint256 _updatedStars, uint256 _updatedReputation)
        external onlyOwner
    {
        users[_userAddress].starScore = _updatedStars;
        users[_userAddress].reputationScore = _updatedReputation;

        emit UpdatedTrustScore(_userAddress, _updatedStars, _updatedReputation);
    }

      
    function updateTrustScoreInBulk(address[] _userAddresses, uint256[] _starScores, uint256[] _reputationScores)
        external onlyOwner
    {
        require(_userAddresses.length == _starScores.length);
        require(_userAddresses.length == _reputationScores.length);

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].starScore = _starScores[i];
            users[_userAddresses[i]].reputationScore = _reputationScores[i];

            emit UpdatedTrustScore(_userAddresses[i], _starScores[i], _reputationScores[i]);
        }
    }

     
    function updateSignedDealsCount(address _userAddress, uint256 _updatedSignedDeals)
        external onlyOwner
    {
        users[_userAddress].signedDealsCount = _updatedSignedDeals;

        emit UpdatedSignedDealsCount(_userAddress, _updatedSignedDeals);
    }

     
    function updateSignedDealsCountInBulk(address[] _userAddresses, uint256[] _updatedSignedDeals)
        external onlyOwner
    {
        require(_userAddresses.length == _updatedSignedDeals.length);

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].signedDealsCount = _updatedSignedDeals[i];

            emit UpdatedSignedDealsCount(_userAddresses[i], _updatedSignedDeals[i]);
        }
    }

     
    function updateNickname(address _userAddress, string _updatedNickname)
        external onlyOwner
    {
        users[_userAddress].nickname = _updatedNickname;

        emit UpdatedNickname(_userAddress, _updatedNickname);
    }

     
    function updateIsVerified(address _userAddress, bool _isVerified)
        external onlyOwner
    {
        users[_userAddress].isVerified = _isVerified;

        emit UpdatedIsVerified(_userAddress, _isVerified);
    }

     
    function updateIsVerifiedInBulk(address[] _userAddresses, bool[] _updatedIsVerfied)
        external onlyOwner
    {
        require(_userAddresses.length == _updatedIsVerfied.length);

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].isVerified = _updatedIsVerfied[i];

            emit UpdatedIsVerified(_userAddresses[i], _updatedIsVerfied[i]);
        }
    }

     
    function updateUserDetailsInBulk(address[] _userAddresses, uint256[] _starScores, uint256[] _reputationScores, uint256[] _signedDealsCount, bool[] _isVerified)
        external onlyOwner
    {
        require(_userAddresses.length == _starScores.length);
        require(_userAddresses.length == _reputationScores.length);
        require(_userAddresses.length == _signedDealsCount.length);
        require(_userAddresses.length == _isVerified.length);

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].starScore = _starScores[i];
            users[_userAddresses[i]].reputationScore = _reputationScores[i];
            users[_userAddresses[i]].signedDealsCount = _signedDealsCount[i];
            users[_userAddresses[i]].isVerified = _isVerified[i];

            emit UpdatedUserDetails(_userAddresses[i], _starScores[i], _reputationScores[i], _signedDealsCount[i], _isVerified[i]);
        }
    }

     
    function updateName(address _userAddress, string _updatedName)
        external onlyOwner
    {
        users[_userAddress].name = _updatedName;

        emit UpdatedName(_userAddress, _updatedName);
    }

     
    function updateUser(address _userAddress, string _updatedName, uint256 _updatedStarScore, uint256 _updatedReputationScore, uint256 _updatedSignedDealsCount, string _updatedNickname, bool _updatedIsVerified)
        external onlyOwner
    {
        users[_userAddress].name = _updatedName;
        users[_userAddress].starScore = _updatedStarScore;
        users[_userAddress].reputationScore = _updatedReputationScore;
        users[_userAddress].signedDealsCount = _updatedSignedDealsCount;
        users[_userAddress].nickname = _updatedNickname;
        users[_userAddress].isVerified = _updatedIsVerified;

        emit UpdatedUser(_userAddress, _updatedName, _updatedStarScore, _updatedReputationScore, _updatedSignedDealsCount, _updatedNickname, _updatedIsVerified);
    }
}