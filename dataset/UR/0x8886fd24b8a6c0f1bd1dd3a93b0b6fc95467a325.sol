 

pragma solidity 0.5.11;

 
library SafeMath 
{
  function mul(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    if (a == 0) 
    {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) 
  {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable 
{
    address public owner;

     
    constructor() public
    {
        owner = msg.sender;
    }

     
    modifier onlyOwner() 
    {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public
    {
        assert(newOwner != address(0));
        owner = newOwner;
    }
}

contract Token
{
   mapping(address => mapping (address => uint256)) allowed;
   function transfer(address to, uint256 value) public returns (bool);
   function transferFrom(address from, address to, uint256 value) public returns (bool);
}

 
 
 
 
 
 
 
 
 

contract CraftrDropper is Ownable
{
    using SafeMath for uint256;
    
    Token CRAFTRToken;
    address contractAddress;

    struct TokenAirdrop 
    {
        address contractAddress;
        uint contractAddressID;  
        address tokenOwner;
        uint airdropDate;
        uint tokenBalance;  
        uint totalDropped;  
        uint usersAtDate;  
    }

    struct User 
    {
        address userAddress;
        uint signupDate;
        uint value;
         
        mapping (address => mapping (uint => uint)) withdrawnBalances;
    }

     
    mapping (address => TokenAirdrop[]) public airdropSupply;

     
    mapping (address => User) public signups;
    uint public userSignupCount = 0;

     
    mapping (address => bool) public admins;

    modifier onlyOwner 
    {
        assert(msg.sender == owner);
        _;
    }

    modifier onlyAdmin 
    {
        assert(msg.sender == owner || admins[msg.sender]);
        _;
    }

    event TokenDeposited(address _contractAddress, address _airdropper,uint _distributionSupply,uint creationDate);
    event UserAdded(address _userAddress, uint _value, uint _signupDate);
    event UsersAdded(address[] _userAddress, uint _value, uint _signupDate);
    event TokenWithdrawn(address _contractAddress, address _userAddress, uint _tokensWithdrawn, uint _withdrawalDate);

    constructor(address _tokenContract) public 
    {
        contractAddress = _tokenContract;
        CRAFTRToken = Token(_tokenContract);
    }

     
     
     

     
    function setAdmin(address _admin, bool isAdmin) public onlyOwner
    {
        admins[_admin] = isAdmin;
    }
    
    function insertUser(address _user, uint _value) public onlyAdmin 
    {
        require(signups[_user].userAddress == address(0));
        _value = _value.mul(10**18);
        signups[_user] = User(_user,now,_value);
        userSignupCount++;
        emit UserAdded(_user,_value,now);
    }

    function insertUsers(address[] memory _users, uint _value) public onlyOwner 
    {
        _value = _value.mul(10**18);
        for (uint i = 0; i < _users.length; i++)
        {
            require(signups[_users[i]].userAddress == address(0));
            signups[_users[i]] = User(_users[i],now,_value);
            userSignupCount++;
        }
        emit UsersAdded(_users,_value,now);
    }

    function deleteUser(address _user) public onlyAdmin
    {
        require(signups[_user].userAddress == _user);
        delete signups[_user];
        userSignupCount--;
    }

    function deleteUsers(address[] memory _users) public onlyOwner
    {
        for (uint i = 0; i < _users.length; i++)
        {
            require(signups[_users[i]].userAddress == _users[i]);
            delete signups[_users[i]];
            userSignupCount--;
        }
    }

      
    function depositTokens(uint _distributionSupply) public onlyOwner
    {
         
        _distributionSupply = _distributionSupply.mul(10**18);

        TokenAirdrop memory ta = TokenAirdrop(contractAddress,airdropSupply[contractAddress].length,msg.sender,now,_distributionSupply,_distributionSupply,userSignupCount);
        airdropSupply[contractAddress].push(ta);

         
        CRAFTRToken.transferFrom(msg.sender,address(this),_distributionSupply);

        emit TokenDeposited(contractAddress,ta.tokenOwner,ta.totalDropped,ta.airdropDate);
    }

     
    function returnTokens() public onlyOwner
    {
        uint tokensToReturn = 0;

        for (uint i = 0; i < airdropSupply[contractAddress].length; i++)
        {
            TokenAirdrop storage ta = airdropSupply[contractAddress][i];
            if(msg.sender == ta.tokenOwner)
            {
                tokensToReturn = tokensToReturn.add(ta.tokenBalance);
                ta.tokenBalance = 0;
            }
        }
        CRAFTRToken.transfer(msg.sender,tokensToReturn);
        emit TokenWithdrawn(contractAddress,msg.sender,tokensToReturn,now);
    }

     
     
     

     
    function getTokensAvailableToMe(address myAddress) view public returns (uint)
    {
         
        User storage user = signups[myAddress];
        require(user.userAddress != address(0));

        uint totalTokensAvailable = 0;
        for (uint i = 0; i < airdropSupply[contractAddress].length; i++)
        {
            uint _withdrawnBalance = user.withdrawnBalances[contractAddress][i];

             
            if(_withdrawnBalance < user.value)
            {
                totalTokensAvailable = totalTokensAvailable.add(user.value);
            }
        }
         
        totalTokensAvailable = totalTokensAvailable.div(10**18);
        return totalTokensAvailable;
    }

     
    function withdrawTokens() public 
    {
         
        User storage user = signups[msg.sender];
         
        require(user.userAddress != address(0));

        uint totalTokensToTransfer = 0;

         
        for (uint i = 0; i < airdropSupply[contractAddress].length; i++)
        {
            TokenAirdrop storage ta = airdropSupply[contractAddress][i];

            uint _withdrawnBalance = user.withdrawnBalances[contractAddress][i];

             
            if(_withdrawnBalance < user.value)
            {
                 
                user.withdrawnBalances[contractAddress][i] = user.value;

                 
                ta.tokenBalance = ta.tokenBalance.sub(user.value);

                 
                totalTokensToTransfer = totalTokensToTransfer.add(user.value);
            }
        }

         
        CRAFTRToken.transfer(msg.sender,totalTokensToTransfer);

        delete signups[msg.sender];
        userSignupCount--;

        emit TokenWithdrawn(contractAddress,msg.sender,totalTokensToTransfer,now);
    }
}