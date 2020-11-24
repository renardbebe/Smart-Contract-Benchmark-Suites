 

pragma solidity ^0.5.8;

contract ERC20Interface {

    function name() public view returns (string memory);

    function symbol() public view returns (string memory);

    function decimals() public view returns (uint8);

    function totalSupply() public view returns (uint);

    function balanceOf(address tokenOwner) public view returns (uint balance);

    function allowance(address tokenOwner, address spender) public view returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    function burn(uint256 amount) public;


    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract MerkleDrop {

    bytes32 public root;
    ERC20Interface public droppedToken;
    uint public decayStartTime;
    uint public decayDurationInSeconds;

    uint public initialBalance;
    uint public remainingValue;   
    uint public spentTokens;   

    mapping (address => bool) public withdrawn;

    event Withdraw(address recipient, uint value, uint originalValue);
    event Burn(uint value);

    constructor(ERC20Interface _droppedToken, uint _initialBalance, bytes32 _root, uint _decayStartTime, uint _decayDurationInSeconds) public {
         
        droppedToken = _droppedToken;
        initialBalance = _initialBalance;
        remainingValue = _initialBalance;
        root = _root;
        decayStartTime = _decayStartTime;
        decayDurationInSeconds = _decayDurationInSeconds;
    }

    function withdraw(uint value, bytes32[] memory proof) public {
        require(verifyEntitled(msg.sender, value, proof), "The proof could not be verified.");
        require(! withdrawn[msg.sender], "You have already withdrawn your entitled token.");

        burnUnusableTokens();

        uint valueToSend = decayedEntitlementAtTime(value, now, false);
        assert(valueToSend <= value);
        require(droppedToken.balanceOf(address(this)) >= valueToSend, "The MerkleDrop does not have tokens to drop yet / anymore.");
        require(valueToSend != 0, "The decayed entitled value is now zero.");

        withdrawn[msg.sender] = true;
        remainingValue -= value;
        spentTokens += valueToSend;

        require(droppedToken.transfer(msg.sender, valueToSend));
        emit Withdraw(msg.sender, valueToSend, value);
    }

    function verifyEntitled(address recipient, uint value, bytes32[] memory proof) public view returns (bool) {
         
         
        bytes32 leaf = keccak256(abi.encodePacked(recipient, value));
        return verifyProof(leaf, proof);
    }

    function decayedEntitlementAtTime(uint value, uint time, bool roundUp) public view returns (uint) {
        if (time <= decayStartTime) {
            return value;
        } else if (time >= decayStartTime + decayDurationInSeconds) {
            return 0;
        } else {
            uint timeDecayed = time - decayStartTime;
            uint valueDecay = decay(value, timeDecayed, decayDurationInSeconds, !roundUp);
            assert(valueDecay <= value);
            return value - valueDecay;
        }
    }

    function burnUnusableTokens() public {
        if (now <= decayStartTime) {
            return;
        }

         
        uint targetBalance = decayedEntitlementAtTime(remainingValue, now, true);

         
        uint currentBalance = initialBalance - spentTokens;
        assert(targetBalance <= currentBalance);
        uint toBurn = currentBalance - targetBalance;

        spentTokens += toBurn;
        burn(toBurn);
    }

    function deleteContract() public {
        require(now >= decayStartTime + decayDurationInSeconds, "The storage cannot be deleted before the end of the merkle drop.");
        burnUnusableTokens();

        selfdestruct(address(0));
    }

    function verifyProof(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        bytes32 currentHash = leaf;

        for (uint i = 0; i < proof.length; i += 1) {
            currentHash = parentHash(currentHash, proof[i]);
        }

        return currentHash == root;
    }

    function parentHash(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        if (a < b) {
            return keccak256(abi.encode(a, b));
        } else {
            return keccak256(abi.encode(b, a));
        }
    }

    function burn(uint value) internal {
        if (value == 0) {
            return;
        }
        emit Burn(value);
        droppedToken.burn(value);
    }

    function decay(uint value, uint timeToDecay, uint totalDecayTime, bool roundUp) internal pure returns (uint) {
        uint decay;

        if (roundUp) {
            decay = (value*timeToDecay+totalDecayTime-1)/totalDecayTime;
        } else {
            decay = value*timeToDecay/totalDecayTime;
        }
        return decay >= value ? value : decay;
    }
}