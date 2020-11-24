 

pragma solidity ^0.4.23;

interface tokenRecipient {
    function receiveApproval (address from, uint256 value, address token, bytes extraData) external;
}

 
contract Pasadena {

    string public name;
    string public symbol;
    uint8 public decimals = 6;  
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => mapping(uint => bool)) public usedSigIds;  
    address public tokenDistributor;  
    address public rescueAccount;  

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    bytes public ethSignedMessagePrefix = "\x19Ethereum Signed Message:\n";
    enum sigStandard { typed, personal, stringHex }
    enum sigDestination { transfer, approve, approveAndCall, transferFrom }
    bytes32 public sigDestinationTransfer = keccak256(
        "address Token Contract Address",
        "address Sender's Address",
        "address Recipient's Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    );  
    bytes32 public sigDestinationTransferFrom = keccak256(
        "address Token Contract Address",
        "address Address Approved for Withdraw",
        "address Account to Withdraw From",
        "address Withdrawal Recipient Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    );  
    bytes32 public sigDestinationApprove = keccak256(
        "address Token Contract Address",
        "address Withdrawal Approval Address",
        "address Withdrawal Recipient Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    );  
    bytes32 public sigDestinationApproveAndCall = keccak256(  
        "address Token Contract Address",
        "address Withdrawal Approval Address",
        "address Withdrawal Recipient Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "bytes Data to Transfer",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    );  

    constructor (string tokenName, string tokenSymbol) public {
        name = tokenName;
        symbol = tokenSymbol;
        rescueAccount = tokenDistributor = msg.sender;
    }

     
    function internalTransfer (address from, address to, uint value) internal {
         
        require(to != 0x0 && balanceOf[from] >= value && balanceOf[to] + value >= balanceOf[to]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

     
    function internalDoubleTransfer (address from, address to1, uint value1, address to2, uint value2) internal {
        require(  
            to1 != 0x0 && to2 != 0x0 && value1 + value2 >= value1 && balanceOf[from] >= value1 + value2
            && balanceOf[to1] + value1 >= balanceOf[to1] && balanceOf[to2] + value2 >= balanceOf[to2]
        );
        balanceOf[from] -= value1 + value2;
        balanceOf[to1] += value1;
        emit Transfer(from, to1, value1);
        if (value2 > 0) {
            balanceOf[to2] += value2;
            emit Transfer(from, to2, value2);
        }
    }

     
    function requireSignature (
        bytes32 data, address signer, uint256 deadline, uint256 sigId, bytes sig, sigStandard std, sigDestination signDest
    ) internal {
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
        require(block.timestamp <= deadline && !usedSigIds[signer][sigId]);  
        if (std == sigStandard.typed) {  
            require(
                signer == ecrecover(
                    keccak256(
                        signDest == sigDestination.transfer
                            ? sigDestinationTransfer
                            : signDest == sigDestination.approve
                                ? sigDestinationApprove
                                : signDest == sigDestination.approveAndCall
                                    ? sigDestinationApproveAndCall
                                    : sigDestinationTransferFrom,
                        data
                    ),
                    v, r, s
                )
            );
        } else if (std == sigStandard.personal) {  
            require(
                signer == ecrecover(keccak256(ethSignedMessagePrefix, "32", data), v, r, s)  
                ||
                signer == ecrecover(keccak256(ethSignedMessagePrefix, "\x20", data), v, r, s)  
            );
        } else {  
            require(
                signer == ecrecover(keccak256(ethSignedMessagePrefix, "64", hexToString(data)), v, r, s)  
                ||
                signer == ecrecover(keccak256(ethSignedMessagePrefix, "\x40", hexToString(data)), v, r, s)  
            );
        }
        usedSigIds[signer][sigId] = true;
    }

     
    function hexToString (bytes32 sig) internal pure returns (bytes) {  
        bytes memory str = new bytes(64);
        for (uint8 i = 0; i < 32; ++i) {
            str[2 * i] = byte((uint8(sig[i]) / 16 < 10 ? 48 : 87) + uint8(sig[i]) / 16);
            str[2 * i + 1] = byte((uint8(sig[i]) % 16 < 10 ? 48 : 87) + (uint8(sig[i]) % 16));
        }
        return str;
    }

     
    function transfer (address to, uint256 value) public returns (bool) {
        internalTransfer(msg.sender, to, value);
        return true;
    }

     
    function transferViaSignature (
        address     from,
        address     to,
        uint256     value,
        uint256     fee,
        uint256     deadline,
        uint256     sigId,
        bytes       sig,
        sigStandard sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(address(this), from, to, value, fee, deadline, sigId),
            from, deadline, sigId, sig, sigStd, sigDestination.transfer
        );
        internalDoubleTransfer(from, to, value, msg.sender, fee);
        return true;
    }

     
    function approve (address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function approveViaSignature (
        address     from,
        address     spender,
        uint256     value,
        uint256     fee,
        uint256     deadline,
        uint256     sigId,
        bytes       sig,
        sigStandard sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(address(this), from, spender, value, fee, deadline, sigId),
            from, deadline, sigId, sig, sigStd, sigDestination.approve
        );
        allowance[from][spender] = value;
        emit Approval(from, spender, value);
        internalTransfer(from, msg.sender, fee);
        return true;
    }

     
    function transferFrom (address from, address to, uint256 value) public returns (bool) {
        require(value <= allowance[from][msg.sender]);  
        allowance[from][msg.sender] -= value;
        internalTransfer(from, to, value);
        return true;
    }

     
    function transferFromViaSignature (
        address     signer,
        address     from,
        address     to,
        uint256     value,
        uint256     fee,
        uint256     deadline,
        uint256     sigId,
        bytes       sig,
        sigStandard sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(address(this), signer, from, to, value, fee, deadline, sigId),
            signer, deadline, sigId, sig, sigStd, sigDestination.transferFrom
        );
        require(value <= allowance[from][signer] && value >= fee);
        allowance[from][signer] -= value;
        internalDoubleTransfer(from, to, value - fee, msg.sender, fee);
        return true;
    }

     
    function approveAndCall (address spender, uint256 value, bytes extraData) public returns (bool) {
        approve(spender, value);
        tokenRecipient(spender).receiveApproval(msg.sender, value, this, extraData);
        return true;
    }

     
    function approveAndCallViaSignature (
        address     from,
        address     spender,
        uint256     value,
        bytes       extraData,
        uint256     fee,
        uint256     deadline,
        uint256     sigId,
        bytes       sig,
        sigStandard sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(address(this), from, spender, value, extraData, fee, deadline, sigId),
            from, deadline, sigId, sig, sigStd, sigDestination.approveAndCall
        );
        allowance[from][spender] = value;
        emit Approval(from, spender, value);
        tokenRecipient(spender).receiveApproval(from, value, this, extraData);
        internalTransfer(from, msg.sender, fee);
        return true;
    }

     
    function multiMint (address[] recipients, uint256[] amounts) external {
        
         
        require(tokenDistributor != 0x0 && tokenDistributor == msg.sender && recipients.length == amounts.length);

        uint total = 0;

        for (uint i = 0; i < recipients.length; ++i) {
            balanceOf[recipients[i]] += amounts[i];
            total += amounts[i];
            emit Transfer(0x0, recipients[i], amounts[i]);
        }

        totalSupply += total;
        
    }

     
    function lastMint () external {

        require(tokenDistributor != 0x0 && tokenDistributor == msg.sender && totalSupply > 0);

        uint256 remaining = totalSupply * 40 / 60;  

         
        uint256 fractionalPart = (remaining + totalSupply) % (uint256(10) ** decimals);
        if (fractionalPart <= remaining)
            remaining -= fractionalPart;  

        balanceOf[tokenDistributor] += remaining;
        emit Transfer(0x0, tokenDistributor, remaining);

        totalSupply += remaining;
        tokenDistributor = 0x0;  

    }

     
    function rescueTokens (Pasadena tokenContract, uint256 value) public {
        require(msg.sender == rescueAccount);
        tokenContract.approve(rescueAccount, value);
    }

     
    function changeRescueAccount (address newRescueAccount) public {
        require(msg.sender == rescueAccount);
        rescueAccount = newRescueAccount;
    }

}