 

pragma solidity ^0.4.21;

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

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract Withdrawable is Ownable {
     
    function withdrawEther(address to) public onlyOwner {
        to.transfer(address(this).balance);
    }

     
    function withdrawERC20Token(address tokenAddress, address to) public onlyOwner {
        ERC20Basic token = ERC20Basic(tokenAddress);
        token.transfer(to, token.balanceOf(address(this)));
    }
}

contract RaindropClient is Withdrawable {
     
    event UserSignUp(string userName, address userAddress, bool delegated);
    event UserDeleted(string userName);

     
    address public hydroTokenAddress;
    uint public minimumHydroStakeUser;
    uint public minimumHydroStakeDelegatedUser;

     
    struct User {
        string userName;
        address userAddress;
        bool delegated;
        bool _initialized;
    }

     
    mapping (bytes32 => User) internal userDirectory;
     
    mapping (address => bytes32) internal nameDirectory;

     
    modifier requireStake(address _address, uint stake) {
        ERC20Basic hydro = ERC20Basic(hydroTokenAddress);
        require(hydro.balanceOf(_address) >= stake);
        _;
    }

     
    function signUpDelegatedUser(string userName, address userAddress, uint8 v, bytes32 r, bytes32 s)
        public
        requireStake(msg.sender, minimumHydroStakeDelegatedUser)
    {
        require(isSigned(userAddress, keccak256("Create RaindropClient Hydro Account"), v, r, s));
        _userSignUp(userName, userAddress, true);
    }

     
    function signUpUser(string userName) public requireStake(msg.sender, minimumHydroStakeUser) {
        return _userSignUp(userName, msg.sender, false);
    }

     
    function deleteUser() public {
        bytes32 userNameHash = nameDirectory[msg.sender];
        require(userDirectory[userNameHash]._initialized);

        string memory userName = userDirectory[userNameHash].userName;

        delete nameDirectory[msg.sender];
        delete userDirectory[userNameHash];

        emit UserDeleted(userName);
    }

     
    function setHydroTokenAddress(address _hydroTokenAddress) public onlyOwner {
        hydroTokenAddress = _hydroTokenAddress;
    }

     
    function setMinimumHydroStakes(uint newMinimumHydroStakeUser, uint newMinimumHydroStakeDelegatedUser) public {
        ERC20Basic hydro = ERC20Basic(hydroTokenAddress);
        require(newMinimumHydroStakeUser <= (hydro.totalSupply() / 100 / 10));  
        require(newMinimumHydroStakeDelegatedUser <= (hydro.totalSupply() / 100));  
        minimumHydroStakeUser = newMinimumHydroStakeUser;
        minimumHydroStakeDelegatedUser = newMinimumHydroStakeDelegatedUser;
    }

     
    function userNameTaken(string userName) public view returns (bool taken) {
        bytes32 userNameHash = keccak256(userName);
        return userDirectory[userNameHash]._initialized;
    }

     
    function getUserByName(string userName) public view returns (address userAddress, bool delegated) {
        bytes32 userNameHash = keccak256(userName);
        User storage _user = userDirectory[userNameHash];
        require(_user._initialized);

        return (_user.userAddress, _user.delegated);
    }

     
    function getUserByAddress(address _address) public view returns (string userName, bool delegated) {
        bytes32 userNameHash = nameDirectory[_address];
        User storage _user = userDirectory[userNameHash];
        require(_user._initialized);

        return (_user.userName, _user.delegated);
    }

     
    function isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) {
        return (_isSigned(_address, messageHash, v, r, s) || _isSignedPrefixed(_address, messageHash, v, r, s));
    }

     
    function _isSigned(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        return ecrecover(messageHash, v, r, s) == _address;
    }

     
    function _isSignedPrefixed(address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedMessageHash = keccak256(prefix, messageHash);

        return ecrecover(prefixedMessageHash, v, r, s) == _address;
    }

     
    function _userSignUp(string userName, address userAddress, bool delegated) internal {
        require(bytes(userName).length < 100);
        bytes32 userNameHash = keccak256(userName);
        require(!userDirectory[userNameHash]._initialized);

        userDirectory[userNameHash] = User(userName, userAddress, delegated, true);
        nameDirectory[userAddress] = userNameHash;

        emit UserSignUp(userName, userAddress, delegated);
    }
}