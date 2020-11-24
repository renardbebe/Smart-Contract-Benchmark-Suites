 

pragma solidity  0.4.24;

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        _owner = msg.sender;
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public view returns(uint);

    function allowance(address owner, address spender) public view returns(uint);

    function transfer(address to, uint value) public returns(bool ok);

    function transferFrom(address from, address to, uint value) public returns(bool ok);

    function approve(address spender, uint value) public returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}




contract Bounties is Ownable {

    using SafeMath for uint;

    uint public totalTokensToClaim;
    uint public totalBountyUsers;
    uint public claimCount;
    uint public totalClaimed;


    mapping(address => bool) public claimed;  
    Token public token;

    mapping(address => bool) public bountyUsers;
    mapping(address => uint) public bountyUsersAmounts;

    constructor(Token _token) public {
        require(_token != address(0));
        token = Token(_token);
    }

    event TokensClaimed(address backer, uint count);
    event LogBountyUser(address user, uint num);
    event LogBountyUserMultiple(uint num);


     
     
     
    function updateTokenAddress(Token _tokenAddress) external onlyOwner() returns(bool res) {
        token = _tokenAddress;
        return true;
    }

     
    function addBountyUser(address _user, uint _amount) public onlyOwner() returns (bool) {

        require(_amount > 0);

        if (bountyUsers[_user] != true) {
            bountyUsers[_user] = true;
            bountyUsersAmounts[_user] = _amount;
            totalBountyUsers++;
            totalTokensToClaim += _amount;
            emit LogBountyUser(_user, totalBountyUsers);
        }
        return true;
    }

     
    function addBountyUserMultiple(address[] _users, uint[] _amount) external onlyOwner()  returns (bool) {

        for (uint i = 0; i < _users.length; ++i) {

            addBountyUser(_users[i], _amount[i]);
        }
        emit LogBountyUserMultiple(totalBountyUsers);
        return true;
    }

     
     
     
    function () external payable {
        claimTokens();
    }

     
     
    function transferRemainingTokens(address _newAddress) external onlyOwner() returns (bool) {
        require(_newAddress != address(0));
        if (!token.transfer(_newAddress, token.balanceOf(this)))
            revert();  
        return true;
    }


     
     
    function claimTokensForUser(address _backer) external onlyOwner()  returns(bool) {
        require(token != address(0));
        require(bountyUsers[_backer]);
        require(!claimed[_backer]);
        claimCount++;
        claimed[_backer] = true;
        totalClaimed = totalClaimed.add(bountyUsersAmounts[_backer]);

        if (!token.transfer(_backer, bountyUsersAmounts[_backer]))
            revert();  

        emit TokensClaimed(_backer, bountyUsersAmounts[_backer]);
        return true;
    }

     
     
    function claimTokens() public {

        require(token != address(0));
        require(bountyUsers[msg.sender]);
        require(!claimed[msg.sender]);
        claimCount++;
        claimed[msg.sender] = true;
        totalClaimed = totalClaimed.add(bountyUsersAmounts[msg.sender]);

        if (!token.transfer(msg.sender, bountyUsersAmounts[msg.sender]))
            revert();  

        emit TokensClaimed(msg.sender, bountyUsersAmounts[msg.sender]);
    }

}

 
contract Token is ERC20, Ownable {
        function transfer(address _to, uint _value) public  returns(bool);
}