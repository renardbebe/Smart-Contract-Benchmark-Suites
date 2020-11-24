 

pragma solidity >=0.5.1 <0.6.0;

contract crossword_reward {
    bytes32 solution_hash;
    
     
    constructor () public {
        solution_hash = 0x2d64478620cf2836ecf1a6ef9ec90e5a540899939c5e411ae44656ddadc6081e;
    }
    
     
    function claim(bytes20 solution, bytes32 salt) public {
        require(keccak256(abi.encodePacked(solution, salt)) == solution_hash, "Mauvaise solution ou mauvais sel.");
        msg.sender.transfer(address(this).balance);
    }
    
     
    function () external payable {}
}