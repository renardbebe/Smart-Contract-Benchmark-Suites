pragma solidity ^0.4.25;

contract Wallet {
    uint[] private bonusCodes;
    address private owner;

    constructor() public {
        bonusCodes = new uint[](0);
        owner = msg.sender;
    }

    function () public payable {
    }

    function PushBonusCode(uint c) public {
        bonusCodes.push(c);
    }

    function PopBonusCode() public {
        require(0 < bonusCodes.length);
        bonusCodes.length--;
    }

    function UpdateBonusCodeAt(uint idx, uint c) public {
        require(idx < bonusCodes.length); //Since you now have to push very codes this is no longer an arbitray write.
        bonusCodes[idx] = c;
    }

    function Destroy() public {
        require(msg.sender == owner);
        selfdestruct(msg.sender);
    }
}
