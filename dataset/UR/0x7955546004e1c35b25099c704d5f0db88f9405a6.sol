 

pragma solidity ^0.5.11;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

 
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
interface ISKRA {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}

contract Logic is Ownable {
    using SafeMath for uint256;

    struct Position {
        string name;
        string description;
        string imageUrl;
        string link;
        uint256 capInUSD;
        uint256 votePriceInTokens;
        uint256 voteYes;
        uint256 voteNo;
        bool archived;
        uint256 finishedAt;
        uint256 createdAt;
    }

    Position[] positions;
    ISKRA public iskraToken;
    mapping(address => mapping(uint256 => uint256)) private isVoted;

     
    constructor(address _token) public {
        iskraToken = ISKRA(_token);
    }

     
    function parse64BytesToTwoUint256(bytes memory data) public pure returns(uint256, uint256) {
        uint256 parsed1;
        uint256 parsed2;
        assembly {
	        parsed1 := mload(add(data, 32))
	        parsed2 := mload(add(data, 64))
        }
        return (parsed1, parsed2);
    }

     
    function parseTwoUint256ToBytes(uint256 x, uint256 y) public pure returns (bytes memory b) {
        b = new bytes(64);
        assembly {
            mstore(add(b, 32), x)
            mstore(add(b, 64), y)
        }
    }

     
    function receiveApproval(address _from, uint256 _tokens, address _token, bytes memory _data) public {
        (uint256 toPosition, uint256 voteStatus) = parse64BytesToTwoUint256(_data);
        require(isVoted[_from][toPosition] == 0, "User has already voted");
        require(_tokens == positions[toPosition].votePriceInTokens, "Not enough tokens for this position");
        require(positions[toPosition].finishedAt > now, "Position time is expired");

        ISKRA(_token).transferFrom(_from, address(this), _tokens);
        _vote(toPosition, voteStatus, _from);
    }

     
    function _vote(uint256 toPosition, uint256 voteStatus, address _from) internal {
        require(voteStatus == 1 || voteStatus == 2, "Invalid vote status");
        if (voteStatus == 2) {
            positions[toPosition].voteYes = positions[toPosition].voteYes.add(1);
            isVoted[_from][toPosition] = voteStatus;
        } else {
            positions[toPosition].voteNo = positions[toPosition].voteNo.add(1);
            isVoted[_from][toPosition] = voteStatus;
        }
    }

     
    function addNewPostition(
        string memory _name,
        string memory _description,
        string memory _imageUrl,
        string memory _link,
        uint256 _capInUSD,
        uint256 _votePriceInTokens,
        uint256 _finishedAt
    ) public onlyOwner {
        Position memory newPosition = Position({
            name: _name,
            description: _description,
            imageUrl: _imageUrl,
            link: _link,
            capInUSD: _capInUSD,
            votePriceInTokens: _votePriceInTokens,
            finishedAt: _finishedAt,
            createdAt: block.timestamp,
            voteYes: 0,
            voteNo: 0,
            archived: false
        });
        positions.push(newPosition);
    }

     
    function editPosition(
        uint256 _positionIndex,
        string memory _name,
        string memory _description,
        string memory _imageUrl,
        string memory _link,
        uint256 _capInUSD,
        uint256 _votePriceInTokens,
        uint256 _finishedAt
    ) public onlyOwner {
        positions[_positionIndex].name = _name;
        positions[_positionIndex].description = _description;
        positions[_positionIndex].imageUrl = _imageUrl;
        positions[_positionIndex].link = _link;
        positions[_positionIndex].capInUSD = _capInUSD;
        positions[_positionIndex].votePriceInTokens = _votePriceInTokens;
        positions[_positionIndex].finishedAt = _finishedAt;
    }

     
    function withdrawTokens(address _wallet, uint256 _tokens) public onlyOwner {
        iskraToken.transfer(_wallet, _tokens);
    }

     
    function changeStatus(uint256 toPosition) public onlyOwner {
        positions[toPosition].archived = !positions[toPosition].archived;
    }

     
    function positionAmount() public view returns(uint256) {
        return positions.length;
    }

     
    function positionDetails(uint256 _index) public view returns(
        string memory name,
        string memory description,
        string memory imageUrl,
        string memory link,
        bool archived
    ) {
        return (
            positions[_index].name,
            positions[_index].description,
            positions[_index].imageUrl,
            positions[_index].link,
            positions[_index].archived
        );
    }

     
    function postionNumbers(uint256 _index) public view returns(
        uint256 capInUSD,
        uint256 votePriceInTokens,
        uint256 finishedAt,
        uint256 createdAt,
        uint256 voteYes,
        uint256 voteNo
    ) {
        return (
            positions[_index].capInUSD,
            positions[_index].votePriceInTokens,
            positions[_index].finishedAt,
            positions[_index].createdAt,
            positions[_index].voteYes,
            positions[_index].voteNo
        );
    }

     
    function voterInfo(address _voter, uint256 _position) public view returns(uint256) {
        return isVoted[_voter][_position];
    }
}