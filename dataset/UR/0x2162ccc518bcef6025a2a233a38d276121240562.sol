 

pragma solidity ^0.5.4;
interface IERC20 {
    function balanceOf(address _owner) external view returns (uint);
}

contract Voter {
    IERC20 public token;
    mapping (address => uint256) public isVote;
    uint256 public endTime;
    address[] optionA;
    address[] optionB;
    
    constructor (address _token) public {
        token = IERC20(_token);
        endTime = 1573084800;
    }
    
    function vote(uint256 _option) external {
        require(_option - 1  < 2, "not a valid option");
        require(isVote[msg.sender] == 0, "is vote already");
        require(token.balanceOf(msg.sender) != 0, "you have no avaliable token");
        require(now < endTime, "invalid time");
        if (_option == 1) {
            isVote[msg.sender] = 1;
            optionA.push(msg.sender);
        } else {
            isVote[msg.sender] = 2;
            optionB.push(msg.sender);
        }
    }
    
    function getTotalVote(uint256 _option) external view returns (uint256 result) {
        require(_option - 1< 2, "not a valid option");
        uint256 length;
        uint256 i;
        if (_option == 1) {
            length = optionA.length;
            for (i = 0; i < length; ++i) {
                result += token.balanceOf(optionA[i]);
            }
        } else {
            length = optionB.length;
            for (i = 0; i < length; ++i) {
                result += token.balanceOf(optionB[i]);
            }
        }
    }
}