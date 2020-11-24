 

pragma solidity ^0.4.13;

library ECRecovery {

     
    function recover(bytes32 hash, bytes sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (sig.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

         
        if (v < 27) {
            v += 27;
        }

         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
             
            return ecrecover(hash, v, r, s);
        }
    }

     
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
         
         
        return keccak256(
            "\x19Ethereum Signed Message:\n32",
            hash
        );
    }
}

contract Htlc {
    using ECRecovery for bytes32;

     

    struct Multisig {  
        address owner;  
        address authority;  
        uint deposit;  
        uint unlockTime;  
    }

    struct AtomicSwap {  
        address initiator;  
        address beneficiary;  
        uint amount;  
        uint fee;  
        uint expirationTime;  
        bytes32 hashedSecret;  
    }

     

    address constant FEE_RECIPIENT = 0x0E5cB767Cce09A7F3CA594Df118aa519BE5e2b5A;
    mapping (bytes32 => Multisig) public hashIdToMultisig;
    mapping (bytes32 => AtomicSwap) public hashIdToSwap;

     

     

     

     

     
    function spendFromMultisig(bytes32 msigId, uint amount, address recipient)
        internal
    {
         
        require(amount <= hashIdToMultisig[msigId].deposit);
        hashIdToMultisig[msigId].deposit -= amount;
        if (hashIdToMultisig[msigId].deposit == 0) {
             
            delete hashIdToMultisig[msigId];
            assert(hashIdToMultisig[msigId].deposit == 0);
        }
         
        recipient.transfer(amount);
    }

     
    function spendFromSwap(bytes32 swapId, uint amount, address recipient)
        internal
    {
         
        require(amount <= hashIdToSwap[swapId].amount);
        hashIdToSwap[swapId].amount -= amount;
        if (hashIdToSwap[swapId].amount == 0) {
             
            delete hashIdToSwap[swapId];
            assert(hashIdToSwap[swapId].amount == 0);
        }
         
        recipient.transfer(amount);
    }

     

     
    function initialiseMultisig(address authority, uint unlockTime)
        public
        payable
        returns (bytes32 msigId)
    {
         
        require(msg.sender != authority);
        require(msg.value > 0);
        msigId = keccak256(
            msg.sender,
            authority,
            msg.value,
            unlockTime
        );

        Multisig storage multisig = hashIdToMultisig[msigId];
        if (multisig.deposit == 0) {  
             
            multisig.owner = msg.sender;
            multisig.authority = authority;
        }
         
        reparametrizeMultisig(msigId, unlockTime);
    }

     
    function reparametrizeMultisig(bytes32 msigId, uint unlockTime)
        public
        payable
    {
        Multisig storage multisig = hashIdToMultisig[msigId];
        assert(
            multisig.deposit + msg.value >=
            multisig.deposit
        );  
        multisig.deposit += msg.value;
        assert(multisig.unlockTime <= unlockTime);  
        multisig.unlockTime = unlockTime;
    }

     
     
    function convertIntoHtlc(bytes32 msigId, address beneficiary, uint amount, uint fee, uint expirationTime, bytes32 hashedSecret)
        public
        returns (bytes32 swapId)
    {
         
        require(hashIdToMultisig[msigId].owner == msg.sender);
        require(hashIdToMultisig[msigId].deposit >= amount + fee);  
        require(now <= expirationTime && expirationTime <= now + 86400);  
        require(amount > 0);  
         
        hashIdToMultisig[msigId].deposit -= amount + fee;
        swapId = keccak256(
            msg.sender,
            beneficiary,
            amount,
            fee,
            expirationTime,
            hashedSecret
        );
         
        AtomicSwap storage swap = hashIdToSwap[swapId];
        swap.initiator = msg.sender;
        swap.beneficiary = beneficiary;
        swap.amount = amount;
        swap.fee = fee;
        swap.expirationTime = expirationTime;
        swap.hashedSecret = hashedSecret;
         
        hashIdToMultisig[msigId].authority.transfer(fee);
    }

     
     
    function batchRegularTransfer(bytes32[] swapIds, bytes32[] secrets)
        public
    {
        for (uint i = 0; i < swapIds.length; ++i)
            regularTransfer(swapIds[i], secrets[i]);
    }

     
    function regularTransfer(bytes32 swapId, bytes32 secret)
        public
    {
         
        require(sha256(secret) == hashIdToSwap[swapId].hashedSecret);
         
        spendFromSwap(swapId, hashIdToSwap[swapId].amount, hashIdToSwap[swapId].beneficiary);
        spendFromSwap(swapId, hashIdToSwap[swapId].fee, FEE_RECIPIENT);
    }

     
    function batchReclaimExpiredSwaps(bytes32 msigId, bytes32[] swapIds)
        public
    {
        for (uint i = 0; i < swapIds.length; ++i)
            reclaimExpiredSwaps(msigId, swapIds[i]);
    }

     
    function reclaimExpiredSwaps(bytes32 msigId, bytes32 swapId)
        public
    {
         
        require(
            hashIdToMultisig[msigId].owner == msg.sender ||
            hashIdToMultisig[msigId].authority == msg.sender
        );
         
         
        require(now >= hashIdToSwap[swapId].expirationTime);
        uint amount = hashIdToSwap[swapId].amount;
        assert(hashIdToMultisig[msigId].deposit + amount >= amount);  
        delete hashIdToSwap[swapId];
        hashIdToMultisig[msigId].deposit += amount;
    }

     
    function earlyResolve(bytes32 msigId, uint amount, bytes32 hashedMessage, bytes sig)
        public
    {
         
        require(
            hashIdToMultisig[msigId].owner == msg.sender ||
            hashIdToMultisig[msigId].authority == msg.sender
        );
         
        address otherAuthority = hashIdToMultisig[msigId].owner == msg.sender ?
            hashIdToMultisig[msigId].authority :
            hashIdToMultisig[msigId].owner;
        require(otherAuthority == hashedMessage.recover(sig));

        spendFromMultisig(msigId, amount, hashIdToMultisig[msigId].owner);
    }

     
    function timeoutResolve(bytes32 msigId, uint amount)
        public
    {
         
        require(hashIdToMultisig[msigId].deposit >= amount);
        require(now >= hashIdToMultisig[msigId].unlockTime);

        spendFromMultisig(msigId, amount, hashIdToMultisig[msigId].owner);
    }

     
}