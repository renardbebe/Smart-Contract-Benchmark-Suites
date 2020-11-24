 

pragma solidity 0.4.24;

interface tokenRecipient {
    function receiveApproval (address from, uint256 value, address token, bytes extraData) external;
}

interface ERC20CompatibleToken {
    function transfer (address to, uint256 value) external returns (bool);
}

 
library SafeMath {
    
    function mul (uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div (uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }
    
    function sub (uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add (uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

}

  		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		
contract ZeroGravityToken {

    using SafeMath for uint256;

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

    modifier rescueAccountOnly {require(msg.sender == rescueAccount); _;}
    modifier tokenDistributionPeriodOnly {require(tokenDistributor == msg.sender); _;}

    enum sigStandard { typed, personal, stringHex }
    enum sigDestination { transfer, approve, approveAndCall, transferFrom }

    bytes constant public ethSignedMessagePrefix = "\x19Ethereum Signed Message:\n";
    bytes32 constant public sigDestinationTransfer = keccak256(
        "address Token Contract Address",
        "address Sender's Address",
        "address Recipient's Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "address Account which Receives Fee",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    );  
    bytes32 constant public sigDestinationTransferFrom = keccak256(
        "address Token Contract Address",
        "address Address Approved for Withdraw",
        "address Account to Withdraw From",
        "address Withdrawal Recipient Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "address Account which Receives Fee",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    );  
    bytes32 constant public sigDestinationApprove = keccak256(
        "address Token Contract Address",
        "address Withdrawal Approval Address",
        "address Withdrawal Recipient Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "address Account which Receives Fee",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    );  
    bytes32 constant public sigDestinationApproveAndCall = keccak256(
        "address Token Contract Address",
        "address Withdrawal Approval Address",
        "address Withdrawal Recipient Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "bytes Data to Transfer",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "address Account which Receives Fee",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    );  

     
    constructor (string tokenName, string tokenSymbol) public {
        name = tokenName;
        symbol = tokenSymbol;
        rescueAccount = tokenDistributor = msg.sender;
    } 		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		

     
    function internalTransfer (address from, address to, uint value) internal {
        require(to != 0x0);  
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function internalDoubleTransfer (address from, address to1, uint value1, address to2, uint value2) internal {
        require(to1 != 0x0 && to2 != 0x0);  
        balanceOf[from] = balanceOf[from].sub(value1.add(value2));
        balanceOf[to1] = balanceOf[to1].add(value1);
        emit Transfer(from, to1, value1);
        if (value2 > 0) {
            balanceOf[to2] = balanceOf[to2].add(value2);
            emit Transfer(from, to2, value2);
        }
    }

     
    function requireSignature (
        bytes32 data,
        address signer,
        uint256 deadline,
        uint256 sigId,
        bytes sig,
        sigStandard sigStd,
        sigDestination sigDest
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
        if (sigStd == sigStandard.typed) {  
            require(
                signer == ecrecover(
                    keccak256(
                        sigDest == sigDestination.transfer
                            ? sigDestinationTransfer
                            : sigDest == sigDestination.approve
                                ? sigDestinationApprove
                                : sigDest == sigDestination.approveAndCall
                                    ? sigDestinationApproveAndCall
                                    : sigDestinationTransferFrom,
                        data
                    ),
                    v, r, s
                )
            );
        } else if (sigStd == sigStandard.personal) {  
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
        address     feeRecipient,
        uint256     deadline,
        uint256     sigId,
        bytes       sig,
        sigStandard sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(address(this), from, to, value, fee, feeRecipient, deadline, sigId),
            from, deadline, sigId, sig, sigStd, sigDestination.transfer
        );
        internalDoubleTransfer(from, to, value, feeRecipient, fee);
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
        address     feeRecipient,
        uint256     deadline,
        uint256     sigId,
        bytes       sig,
        sigStandard sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(address(this), from, spender, value, fee, feeRecipient, deadline, sigId),
            from, deadline, sigId, sig, sigStd, sigDestination.approve
        );
        allowance[from][spender] = value;
        emit Approval(from, spender, value);
        internalTransfer(from, feeRecipient, fee);
        return true;
    }

     
    function transferFrom (address from, address to, uint256 value) public returns (bool) {
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        internalTransfer(from, to, value);
        return true;
    }

     
    function transferFromViaSignature (
        address     signer,
        address     from,
        address     to,
        uint256     value,
        uint256     fee,
        address     feeRecipient,
        uint256     deadline,
        uint256     sigId,
        bytes       sig,
        sigStandard sigStd
    ) external returns (bool) { 		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		
        requireSignature(
            keccak256(address(this), from, to, value, fee, feeRecipient, deadline, sigId),
            signer, deadline, sigId, sig, sigStd, sigDestination.transferFrom
        );
        allowance[from][signer] = allowance[from][signer].sub(value);
        internalDoubleTransfer(from, to, value.sub(fee), feeRecipient, fee);
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
        address     feeRecipient,
        uint256     deadline,
        uint256     sigId,
        bytes       sig,
        sigStandard sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(address(this), from, spender, value, extraData, fee, feeRecipient, deadline, sigId),
            from, deadline, sigId, sig, sigStd, sigDestination.approveAndCall
        );
        allowance[from][spender] = value;
        emit Approval(from, spender, value);
        tokenRecipient(spender).receiveApproval(from, value, this, extraData);
        internalTransfer(from, feeRecipient, fee);
        return true;
    } 		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		

     
    function multiMint (address[] recipients, uint256[] amounts) external tokenDistributionPeriodOnly {
        
        require(recipients.length == amounts.length);

        uint total = 0;

        for (uint i = 0; i < recipients.length; ++i) {
            balanceOf[recipients[i]] = balanceOf[recipients[i]].add(amounts[i]);
            total = total.add(amounts[i]);
            emit Transfer(0x0, recipients[i], amounts[i]);
        }

        totalSupply = totalSupply.add(total);
        
    }
 		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		
     
    function lastMint () external tokenDistributionPeriodOnly {

        require(totalSupply > 0);

        uint256 remaining = totalSupply.mul(40).div(60);  

         
        uint256 fractionalPart = remaining.add(totalSupply) % (uint256(10) ** decimals);
        remaining = remaining.sub(fractionalPart);  

        balanceOf[tokenDistributor] = balanceOf[tokenDistributor].add(remaining);
        emit Transfer(0x0, tokenDistributor, remaining);

        totalSupply = totalSupply.add(remaining);
        tokenDistributor = 0x0;  

    }

     
    function rescueLostTokens (ERC20CompatibleToken tokenContract, uint256 value) external rescueAccountOnly {
        tokenContract.transfer(rescueAccount, value);
    }

      		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		
    function changeRescueAccount (address newRescueAccount) external rescueAccountOnly {
        rescueAccount = newRescueAccount;
    }
 		   	  				  	  	      		 			  		 	  	 		 	 		 		 	  	 			 	   		    	  	 			  			 	   		 	 		
}