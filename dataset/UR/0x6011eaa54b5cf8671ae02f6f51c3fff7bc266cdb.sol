 

pragma solidity 




^0.5.0;

contract Lockbox {

    event PayOut(
        address indexed to,
        uint indexed nonce,
        uint256 amount
    );

    uint constant UINT_MAX = ~uint(0);

    address public owner;  
    address payable public returnFundsAddress;

    mapping(uint256 => bool) usedNonces;

    constructor(address payable returnFunds) public payable {
        owner = msg.sender;
        returnFundsAddress = returnFunds;
    }

     
    function () external payable {
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function claimPayment(uint256 amount, uint nonce, bytes memory sig) public {
        require(!usedNonces[nonce], "Reused nonce");

         
        bytes32 message = prefixed(keccak256(abi.encodePacked(amount, nonce, this)));

         
        require(recoverSigner(message, sig) == owner, "Non-owner signature");
        
        if (nonce == 0) {
            require(amount == 1, "Req. 1 WEI amt for 0 nonce");
        } else {
            usedNonces[nonce] = true;
        }

        emit PayOut(msg.sender, nonce, amount);
        msg.sender.transfer(amount);
    }

    function returnFunds(uint256 amount, uint[] memory nonces) public {
        require(msg.sender == owner, "Non-owner sender");

        for (uint i = 0; i < nonces.length; i++){
            if (nonces[i] != 0)
                usedNonces[nonces[i]] = true;
        }

        emit PayOut(returnFundsAddress, UINT_MAX, amount);
        returnFundsAddress.transfer(amount);
    }

     
    function kill() public {
        require(msg.sender == owner, "Non-owner sender");
        selfdestruct(returnFundsAddress);
    }

     
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65, "Malformed sig");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
             
            r := mload(add(sig, 32))
             
            s := mload(add(sig, 64))
             
            v := byte(0, mload(add(sig, 96)))
        }

         
        if (v < 27) 
            v += 27;

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

     
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}